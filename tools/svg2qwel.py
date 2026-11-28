#!/usr/bin/env python3
"""svg2qwel: convert SVG files into Qwel projects (.qwel).

Needs only Python 3.8+ and the standard library.

    python svg2qwel.py icon.svg                      -> icon.qwel next to the SVG
    python svg2qwel.py a.svg b.svg -o out_dir        -> a.qwel, b.qwel in out_dir
    python svg2qwel.py icon.svg --scale 8            -> 8x bigger canvas (handy for 24px icons)
    python svg2qwel.py icon.svg --size 360x640       -> fit into a 360x640 sheet, like in-app import
    python svg2qwel.py a.svg b.svg c.svg --pages -o app.qwel   -> one project, one screen per SVG

It understands rect, circle, ellipse, line, polyline, polygon, path (all commands, arcs included),
groups, transform, and fill / stroke / opacity from attributes and style="...". Curves are flattened
to polylines (Qwel PATH layers store straight segments only). Gradients, text, images, <use> and CSS
classes are skipped and reported. The conversion logic mirrors the in-app SVG import.
"""
import argparse
import json
import math
import os
import re
import sys
import time
import uuid
import zipfile
import xml.etree.ElementTree as ET
from dataclasses import dataclass, replace

MAX_BYTES = 2_000_000
MAX_NODES = 400
MAX_POINTS = 30_000

# ---------------------------------------------------------------- data

BLACK = 0xFF000000


@dataclass
class St:
    fill: int = BLACK
    stroke: int = 0
    stroke_w: float = 1.0
    opacity: float = 1.0
    even_odd: bool = False
    fill_opacity: float = 1.0
    stroke_opacity: float = 1.0


class Mat:
    __slots__ = ("a", "b", "c", "d", "e", "f")

    def __init__(self, a=1.0, b=0.0, c=0.0, d=1.0, e=0.0, f=0.0):
        self.a, self.b, self.c, self.d, self.e, self.f = a, b, c, d, e, f

    def __mul__(self, o):
        return Mat(
            self.a * o.a + self.c * o.b, self.b * o.a + self.d * o.b,
            self.a * o.c + self.c * o.d, self.b * o.c + self.d * o.d,
            self.a * o.e + self.c * o.f + self.e, self.b * o.e + self.d * o.f + self.f,
        )

    def x(self, px, py):
        return self.a * px + self.c * py + self.e

    def y(self, px, py):
        return self.b * px + self.d * py + self.f

    @property
    def scale(self):
        return math.sqrt(abs(self.a * self.d - self.b * self.c))

    @property
    def axis_aligned(self):
        return abs(self.b) < 1e-9 and abs(self.c) < 1e-9 and self.a > 0 and self.d > 0


class Poly:
    def __init__(self):
        self.pts = []
        self.closed = False


class Ctx:
    def __init__(self):
        self.nodes = []
        self.skipped = 0
        self.approx = False
        self.points = 0


def new_id():
    return uuid.uuid4().hex[:10]


def new_node(kind, name, st, m, **kw):
    n = {
        "id": new_id(), "kind": kind, "name": name, "x": 0.0, "y": 0.0, "w": 1.0, "h": 1.0, "rot": 0.0,
        "fill": with_alpha(st.fill, st.fill_opacity), "stroke": with_alpha(st.stroke, st.stroke_opacity),
        "sw": (st.stroke_w * m.scale) if (st.stroke >> 24) != 0 else 0.0,
        "op": st.opacity, "corner": 0.0, "shape": "", "text": "", "fs": 16.0, "fw": 400,
        "group": "", "vis": True, "lock": False, "ratio": False,
    }
    if st.even_odd:
        n["eo"] = True
    n.update(kw)
    return n


# ---------------------------------------------------------------- colors and styles

NAMED = {
    "black": 0xFF000000, "white": 0xFFFFFFFF, "red": 0xFFFF0000, "green": 0xFF008000, "blue": 0xFF0000FF,
    "yellow": 0xFFFFFF00, "gray": 0xFF808080, "grey": 0xFF808080, "orange": 0xFFFFA500, "purple": 0xFF800080,
    "pink": 0xFFFFC0CB, "cyan": 0xFF00FFFF, "magenta": 0xFFFF00FF, "brown": 0xFFA52A2A, "navy": 0xFF000080,
    "teal": 0xFF008080, "lime": 0xFF00FF00, "silver": 0xFFC0C0C0, "maroon": 0xFF800000, "gold": 0xFFFFD700,
}


def length(s):
    m = re.match(r"^\s*(-?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)", s or "")
    return float(m.group(1)) if m else None


def attr(el, name, default=0.0):
    v = length(el.get(name, ""))
    return default if v is None else v


def parse_color(raw, current):
    """ARGB int, 0 for none, None if not understood (e.g. url(#gradient))."""
    v = (raw or "").strip().lower()
    if not v:
        return None
    if v in ("none", "transparent"):
        return 0
    if v == "currentcolor":
        return current
    if v in NAMED:
        return NAMED[v]
    if v.startswith("#"):
        h = v[1:]
        if len(h) in (3, 4):
            h = "".join(c * 2 for c in h)
        if len(h) not in (6, 8):
            return None
        try:
            n = int(h, 16)
        except ValueError:
            return None
        if len(h) == 8:
            return ((n & 0xFF) << 24) | (n >> 8)
        return 0xFF000000 | n
    if v.startswith("rgb"):
        parts = [p for p in re.split(r"[,\s/]+", v[v.index("(") + 1:].split(")")[0]) if p]
        if len(parts) < 3:
            return None

        def ch(t):
            try:
                d = float(t[:-1]) * 2.55 if t.endswith("%") else float(t)
            except ValueError:
                return None
            return max(0, min(255, int(d)))

        rgb = [ch(p) for p in parts[:3]]
        if None in rgb:
            return None
        return (0xFF << 24) | (rgb[0] << 16) | (rgb[1] << 8) | rgb[2]
    return None


def style_of(el, parent, ctx):
    props = {}
    for k in ("fill", "stroke", "stroke-width", "opacity", "fill-opacity", "stroke-opacity", "fill-rule", "color"):
        v = el.get(k)
        if v:
            props[k] = v
    for decl in (el.get("style") or "").split(";"):
        i = decl.find(":")
        if i > 0:
            props[decl[:i].strip()] = decl[i + 1:].strip()
    cur = parse_color(props["color"], parent.fill) if "color" in props else None
    if cur is None:
        cur = parent.fill

    def paint(key, old):
        raw = props.get(key)
        if raw is None:
            return old
        c = parse_color(raw, cur)
        if c is None:
            ctx.approx = True
            return 0xFF9E9E9E
        return c

    def fl(key, default):
        try:
            return max(0.0, min(1.0, float(props[key])))
        except (KeyError, ValueError):
            return default

    sw = length(props["stroke-width"]) if "stroke-width" in props else None
    return St(
        fill=paint("fill", parent.fill), stroke=paint("stroke", parent.stroke),
        stroke_w=parent.stroke_w if sw is None else sw,
        opacity=parent.opacity * fl("opacity", 1.0),
        even_odd=(props["fill-rule"].strip() == "evenodd") if "fill-rule" in props else parent.even_odd,
        fill_opacity=fl("fill-opacity", parent.fill_opacity),
        stroke_opacity=fl("stroke-opacity", parent.stroke_opacity),
    )


def with_alpha(argb, k):
    if argb == 0 or k >= 0.999:
        return argb
    a = max(0, min(255, int((argb >> 24) * k)))
    return (a << 24) | (argb & 0xFFFFFF)


# ---------------------------------------------------------------- transforms

def transform_of(s):
    m = Mat()
    for name, args in re.findall(r"(\w+)\s*\(([^)]*)\)", s or ""):
        v = []
        for t in re.split(r"[,\s]+", args):
            try:
                v.append(float(t))
            except ValueError:
                pass
        g = lambda i, d: v[i] if i < len(v) else d
        if name == "translate":
            t = Mat(1, 0, 0, 1, g(0, 0.0), g(1, 0.0))
        elif name == "scale":
            t = Mat(g(0, 1.0), 0, 0, g(1, g(0, 1.0)), 0, 0)
        elif name == "rotate":
            a = math.radians(g(0, 0.0))
            cs, sn = math.cos(a), math.sin(a)
            rot = Mat(cs, sn, -sn, cs, 0, 0)
            t = Mat(1, 0, 0, 1, v[1], v[2]) * rot * Mat(1, 0, 0, 1, -v[1], -v[2]) if len(v) >= 3 else rot
        elif name == "skewX":
            t = Mat(1, 0, math.tan(math.radians(g(0, 0.0))), 1, 0, 0)
        elif name == "skewY":
            t = Mat(1, math.tan(math.radians(g(0, 0.0))), 0, 1, 0, 0)
        elif name == "matrix":
            t = Mat(*v) if len(v) == 6 else Mat()
        else:
            t = Mat()
        m = m * t
    return m


# ---------------------------------------------------------------- walking the document

SKIP_SILENT = {"defs", "symbol", "clippath", "mask", "metadata", "title", "desc", "lineargradient",
               "radialgradient", "pattern", "filter", "marker"}


def local(tag):
    return tag.rsplit("}", 1)[-1].split(":")[-1]


def walk(el, parent_m, parent_st, ctx, root=False):
    if len(ctx.nodes) >= MAX_NODES:
        ctx.skipped += 1
        return
    tag = local(el.tag)
    m = parent_m if root else parent_m * transform_of(el.get("transform"))
    if el.get("display") == "none" or el.get("visibility") == "hidden":
        return
    st = style_of(el, parent_st, ctx)
    low = tag.lower()
    if tag in ("svg", "g", "a"):
        for c in el:
            if isinstance(c.tag, str):
                walk(c, m, st, ctx)
    elif low in SKIP_SILENT:
        return
    elif tag in ("style", "script"):
        ctx.skipped += 1
    elif tag == "rect":
        rect(el, m, st, ctx)
    elif tag == "circle":
        r = attr(el, "r")
        ellipse(attr(el, "cx"), attr(el, "cy"), r, r, m, st, ctx, "circle")
    elif tag == "ellipse":
        ellipse(attr(el, "cx"), attr(el, "cy"), attr(el, "rx"), attr(el, "ry"), m, st, ctx, "ellipse")
    elif tag == "line":
        p = Poly()
        p.pts += [attr(el, "x1"), attr(el, "y1"), attr(el, "x2"), attr(el, "y2")]
        add_path([p], m, replace(st, fill=0), ctx, "line")
    elif tag in ("polyline", "polygon"):
        nums = []
        for t in re.split(r"[,\s]+", el.get("points") or ""):
            try:
                nums.append(float(t))
            except ValueError:
                pass
        p = Poly()
        for i in range(0, len(nums) - 1, 2):
            p.pts += [nums[i], nums[i + 1]]
        p.closed = tag == "polygon"
        add_path([p], m, st, ctx, tag)
    elif tag == "path":
        add_path(parse_path_data(el.get("d") or ""), m, st, ctx, "path")
    else:
        ctx.skipped += 1


def rect(el, m, st, ctx):
    x, y, w, h = attr(el, "x"), attr(el, "y"), attr(el, "width"), attr(el, "height")
    if w <= 0 or h <= 0:
        return
    rx, ry = length(el.get("rx", "")), length(el.get("ry", ""))
    if rx is None:
        rx = ry
    if ry is None:
        ry = rx
    if m.axis_aligned:
        ctx.nodes.append(new_node(
            "RECT", "rect", st, m, x=m.x(x, y), y=m.y(x, y), w=w * m.a, h=h * m.d, corner=(rx or 0.0) * m.a))
    else:
        p = Poly()
        p.closed = True
        p.pts += [x, y, x + w, y, x + w, y + h, x, y + h]
        ctx.approx = ctx.approx or (rx or 0.0) > 0.0
        add_path([p], m, st, ctx, "rect")


def ellipse(cx, cy, rx, ry, m, st, ctx, name):
    if rx <= 0 or ry <= 0:
        return
    if m.axis_aligned:
        ctx.nodes.append(new_node(
            "ELLIPSE", name, st, m, x=m.x(cx - rx, cy - ry), y=m.y(cx - rx, cy - ry), w=2 * rx * m.a, h=2 * ry * m.d))
    else:
        p = Poly()
        p.closed = True
        n = 48
        for i in range(n):
            t = 2 * math.pi * i / n
            p.pts += [cx + rx * math.cos(t), cy + ry * math.sin(t)]
        add_path([p], m, st, ctx, name)


def add_path(subs, m, st, ctx, name):
    polys = [p for p in subs if len(p.pts) >= 4]
    if not polys:
        return
    total = sum(len(p.pts) // 2 for p in polys)
    if ctx.points + total > MAX_POINTS:
        ctx.skipped += 1
        return
    ctx.points += total
    l = t = float("inf")
    r = b = float("-inf")
    tp = []
    for p in polys:
        out = []
        for i in range(0, len(p.pts), 2):
            x = m.x(p.pts[i], p.pts[i + 1])
            y = m.y(p.pts[i], p.pts[i + 1])
            out += [x, y]
            l, r, t, b = min(l, x), max(r, x), min(t, y), max(b, y)
        tp.append((out, p.closed))
    w, h = r - l, b - t
    x0, y0 = l, t
    # a line of zero width or height gets thickness 1, the contour stays centered
    if w < 1.0:
        x0 = l - (1.0 - w) / 2.0
        w = 1.0
    if h < 1.0:
        y0 = t - (1.0 - h) / 2.0
        h = 1.0
    parts = []
    for pts, closed in tp:
        for i in range(0, len(pts), 2):
            parts.append("%s %.4f %.4f" % ("M" if i == 0 else "L", (pts[i] - x0) / w, (pts[i + 1] - y0) / h))
        if closed:
            parts.append("Z")
    closed_any = any(c for _, c in tp)
    fill = with_alpha(st.fill, st.fill_opacity)
    if not closed_any and (st.fill >> 24) != 0 and name == "line":
        fill = 0
    n = new_node("PATH", name, st, m, x=x0, y=y0, w=w, h=h, path=" ".join(parts))
    n["fill"] = fill
    ctx.nodes.append(n)


# ---------------------------------------------------------------- path data

class Scan:
    NUM = re.compile(r"[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?")

    def __init__(self, s):
        self.s, self.i = s, 0

    def ws(self):
        s = self.s
        while self.i < len(s) and (s[self.i].isspace() or s[self.i] == ","):
            self.i += 1

    def more(self):
        self.ws()
        return self.i < len(self.s)

    def peek_cmd(self):
        self.ws()
        if self.i < len(self.s) and self.s[self.i].isalpha() and self.s[self.i] not in "eE":
            return self.s[self.i]
        return None

    def number(self):
        self.ws()
        m = self.NUM.match(self.s, self.i)
        if not m:
            return None
        self.i = m.end()
        return float(m.group(0))

    def flag(self):
        self.ws()
        if self.i < len(self.s) and self.s[self.i] in "01":
            self.i += 1
            return self.s[self.i - 1] == "1"
        return None


def parse_path_data(d):
    out = []
    sc = Scan(d)
    st = {"cur": None, "cx": 0.0, "cy": 0.0, "sx": 0.0, "sy": 0.0, "lcx": 0.0, "lcy": 0.0}

    def line(x, y):
        if st["cur"] is not None:
            st["cur"].pts += [x, y]
        st["cx"], st["cy"] = x, y

    def begin(x, y):
        p = Poly()
        out.append(p)
        p.pts += [x, y]
        st["cur"] = p
        st["cx"] = st["sx"] = x
        st["cy"] = st["sy"] = y

    def cubic(x1, y1, x2, y2, x, y):
        cx, cy = st["cx"], st["cy"]
        ln = abs(x1 - cx) + abs(y1 - cy) + abs(x2 - x1) + abs(y2 - y1) + abs(x - x2) + abs(y - y2)
        n = max(6, min(40, math.ceil(ln / 2.0 - 1e-9)))
        for k in range(1, n + 1):
            t = k / n
            u = 1 - t
            line(u * u * u * cx + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t * t * t * x,
                 u * u * u * cy + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t * t * t * y)
        st["lcx"], st["lcy"] = x2, y2

    def quad(x1, y1, x, y):
        cx, cy = st["cx"], st["cy"]
        cubic(cx + 2.0 / 3 * (x1 - cx), cy + 2.0 / 3 * (y1 - cy), x + 2.0 / 3 * (x1 - x), y + 2.0 / 3 * (y1 - y), x, y)
        st["lcx"], st["lcy"] = x1, y1

    def arc(rx, ry, rot, large, sweep, x, y):
        cx, cy = st["cx"], st["cy"]
        rx, ry = abs(rx), abs(ry)
        if rx == 0.0 or ry == 0.0 or (x == cx and y == cy):
            line(x, y)
            return
        phi = math.radians(rot)
        cp, sp = math.cos(phi), math.sin(phi)
        dx, dy = (cx - x) / 2, (cy - y) / 2
        x1 = cp * dx + sp * dy
        y1 = -sp * dx + cp * dy
        lam = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
        if lam > 1:
            k = math.sqrt(lam)
            rx *= k
            ry *= k
        num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        den = rx * rx * y1 * y1 + ry * ry * x1 * x1
        co = 0.0 if den == 0.0 else math.sqrt(max(0.0, num / den))
        if large == sweep:
            co = -co
        cxp = co * rx * y1 / ry
        cyp = -co * ry * x1 / rx
        ccx = cp * cxp - sp * cyp + (cx + x) / 2
        ccy = sp * cxp + cp * cyp + (cy + y) / 2
        th1 = math.atan2((y1 - cyp) / ry, (x1 - cxp) / rx)
        dth = math.atan2((-y1 - cyp) / ry, (-x1 - cxp) / rx) - th1
        if sweep and dth < 0:
            dth += 2 * math.pi
        elif not sweep and dth > 0:
            dth -= 2 * math.pi
        n = max(4, min(64, math.ceil(abs(dth) / (math.pi / 16) - 1e-9)))
        for k in range(1, n + 1):
            th = th1 + dth * k / n
            px, py = rx * math.cos(th), ry * math.sin(th)
            line(cp * px - sp * py + ccx, sp * px + cp * py + ccy)
        st["cx"], st["cy"] = x, y

    cmd = " "
    prev = " "
    guard = 0
    while sc.more() and guard < 200_000:
        guard += 1
        c = sc.peek_cmd()
        if c is not None:
            sc.i += 1
            cmd = c
        elif cmd == " ":
            break
        up = cmd.upper()
        # after Z without a new M drawing continues from the start point of the subpath
        if st["cur"] is None and up not in ("M", "Z"):
            begin(st["cx"], st["cy"])
        rel = cmd.islower()
        ox = st["cx"] if rel else 0.0
        oy = st["cy"] if rel else 0.0
        if up == "M":
            x, y = sc.number(), sc.number()
            if x is None or y is None:
                break
            begin(ox + x, oy + y)
            cmd = "l" if rel else "L"
        elif up == "L":
            x, y = sc.number(), sc.number()
            if x is None or y is None:
                break
            line(ox + x, oy + y)
        elif up == "H":
            x = sc.number()
            if x is None:
                break
            line(ox + x, st["cy"])
        elif up == "V":
            y = sc.number()
            if y is None:
                break
            line(st["cx"], oy + y)
        elif up == "C":
            a = [sc.number() for _ in range(6)]
            if None in a:
                return out
            cubic(ox + a[0], oy + a[1], ox + a[2], oy + a[3], ox + a[4], oy + a[5])
        elif up == "S":
            a = [sc.number() for _ in range(4)]
            if None in a:
                return out
            if prev in "CcSs":
                r1 = (2 * st["cx"] - st["lcx"], 2 * st["cy"] - st["lcy"])
            else:
                r1 = (st["cx"], st["cy"])
            cubic(r1[0], r1[1], ox + a[0], oy + a[1], ox + a[2], oy + a[3])
        elif up == "Q":
            a = [sc.number() for _ in range(4)]
            if None in a:
                return out
            quad(ox + a[0], oy + a[1], ox + a[2], oy + a[3])
        elif up == "T":
            a = [sc.number() for _ in range(2)]
            if None in a:
                return out
            if prev in "QqTt":
                r1 = (2 * st["cx"] - st["lcx"], 2 * st["cy"] - st["lcy"])
            else:
                r1 = (st["cx"], st["cy"])
            quad(r1[0], r1[1], ox + a[0], oy + a[1])
        elif up == "A":
            rx, ry, rot = sc.number(), sc.number(), sc.number()
            if None in (rx, ry, rot):
                return out
            large, sweep = sc.flag(), sc.flag()
            if large is None or sweep is None:
                return out
            x, y = sc.number(), sc.number()
            if x is None or y is None:
                return out
            arc(rx, ry, rot, large, sweep, ox + x, oy + y)
        elif up == "Z":
            if st["cur"] is not None:
                st["cur"].closed = True
            st["cx"], st["cy"] = st["sx"], st["sy"]
            st["cur"] = None
        else:
            break
        prev = cmd
    return out


# ---------------------------------------------------------------- converting a document

class Result:
    def __init__(self, nodes, width, height, title, skipped, approx):
        self.nodes, self.width, self.height = nodes, width, height
        self.title, self.skipped, self.approx = title, skipped, approx


def import_svg(data, canvas=None, scale=1.0):
    """Parse SVG bytes. canvas=None keeps the drawing's own size times `scale`;
    canvas=(w, h) fits it into that sheet at 90% and centers it, like the in-app import."""
    if len(data) > MAX_BYTES:
        raise ValueError("file is larger than 2 MB")
    text = data.decode("utf-8", errors="replace")
    if "<!ENTITY" in text.upper():
        raise ValueError("DTD entities are not supported")
    try:
        root = ET.fromstring(data)
    except ET.ParseError as e:
        raise ValueError("not a valid XML/SVG file: %s" % e)
    if local(root.tag) != "svg":
        raise ValueError("the root element is not <svg>")
    vb = []
    for t in re.split(r"[,\s]+", root.get("viewBox", "").strip()):
        try:
            vb.append(float(t))
        except ValueError:
            pass
    if len(vb) == 4 and vb[2] > 0 and vb[3] > 0:
        vx, vy, vw, vh = vb
    else:
        vx = vy = 0.0
        vw = length(root.get("width", "")) or 100.0
        vh = length(root.get("height", "")) or 100.0
    if canvas is None:
        s = scale
        cw, ch = vw * s, vh * s
        ox, oy = -vx * s, -vy * s
    else:
        cw, ch = canvas
        s = max(0.01, min(8.0, min(cw * 0.9 / vw, ch * 0.9 / vh)))
        ox = (cw - vw * s) / 2.0 - vx * s
        oy = (ch - vh * s) / 2.0 - vy * s
    ctx = Ctx()
    walk(root, Mat(s, 0, 0, s, ox, oy), St(), ctx, root=True)
    title = None
    for c in root:
        if isinstance(c.tag, str) and local(c.tag) == "title" and (c.text or "").strip():
            title = c.text.strip()
            break
    return Result(ctx.nodes, cw, ch, title, ctx.skipped, ctx.approx)


def s32(v):
    v &= 0xFFFFFFFF
    return v - (1 << 32) if v >= (1 << 31) else v


def parse_hex_color(s):
    s = s.strip().lstrip("#")
    if len(s) == 3:
        s = "".join(c * 2 for c in s)
    if len(s) == 6:
        return 0xFF000000 | int(s, 16)
    if len(s) == 8:  # rrggbbaa
        n = int(s, 16)
        return ((n & 0xFF) << 24) | (n >> 8)
    raise ValueError("bad color: %r (use #rgb, #rrggbb or #rrggbbaa)" % s)


def pull_background(res, bg_opt):
    """Decide the project background. 'auto' turns a full-sheet rectangle at the bottom into the background."""
    if bg_opt == "transparent":
        return 0x00000000
    if bg_opt not in ("auto", "none"):
        return parse_hex_color(bg_opt)
    if bg_opt == "auto" and res.nodes:
        n = res.nodes[0]
        covers = (n["kind"] == "RECT" and n["corner"] == 0 and n["rot"] == 0 and n["sw"] == 0
                  and abs(n["x"]) < 0.5 and abs(n["y"]) < 0.5 and abs(n["w"] - res.width) < 0.5
                  and abs(n["h"] - res.height) < 0.5 and n["op"] >= 0.999 and (n["fill"] >> 24) == 0xFF)
        if covers:
            res.nodes.pop(0)
            return n["fill"]
    return 0xFFFFFFFF


def encode_node(n):
    o = dict(n)
    for k in ("fill", "stroke"):
        o[k] = s32(o[k])
    o["ft"] = -1
    o["st"] = -1
    o["x"], o["y"], o["w"], o["h"] = (round(float(o[k]), 3) for k in ("x", "y", "w", "h"))
    o["sw"] = round(float(o["sw"]), 3)
    o["corner"] = round(float(o["corner"]), 3)
    return o


def build_project(name, width, height, background, pages):
    """pages: list of (page_name, nodes). One page -> plain project; several -> screens."""
    now = int(time.time() * 1000)
    p = {
        "v": 1, "id": new_id(), "name": name, "w": round(width, 3), "h": round(height, 3),
        "bg": s32(background), "created": now, "updated": now, "bgToken": -1,
        "nodes": [encode_node(n) for n in pages[0][1]],
    }
    if len(pages) > 1:
        p["active"] = 0
        p["pages"] = [{"id": new_id(), "name": pn, "nodes": [encode_node(n) for n in nodes]} for pn, nodes in pages]
    return p


def write_qwel(path, project):
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("project.json", json.dumps(project, ensure_ascii=False))


# ---------------------------------------------------------------- command line

def parse_size(s):
    m = re.fullmatch(r"(\d+(?:\.\d+)?)[xXx](\d+(?:\.\d+)?)", s.strip())
    if not m:
        raise argparse.ArgumentTypeError("size must look like 360x640")
    return float(m.group(1)), float(m.group(2))


def report(path, res, nodes_count):
    msg = "%s: %d layers" % (os.path.basename(path), nodes_count)
    if res.skipped:
        msg += ", skipped %d (text, images, use, CSS)" % res.skipped
    if res.approx:
        msg += ", approximated (gradients became gray)"
    print(msg)


def main(argv=None):
    ap = argparse.ArgumentParser(
        prog="svg2qwel", description="Convert SVG files to Qwel projects (.qwel).",
        formatter_class=argparse.RawDescriptionHelpFormatter, epilog=__doc__.split("\n\n", 1)[1])
    ap.add_argument("inputs", nargs="+", help="SVG files")
    ap.add_argument("-o", "--out", help="output file (one input, or --pages) or directory (several inputs)")
    ap.add_argument("--name", help="project name (default: <title> from the SVG, else the file name)")
    ap.add_argument("--scale", type=float, default=1.0, help="canvas scale relative to the SVG size (default 1)")
    ap.add_argument("--size", type=parse_size, metavar="WxH", help="fit the drawing into a WxH sheet instead of using its own size")
    ap.add_argument("--bg", default="auto", metavar="COLOR",
                    help="background: auto (full-sheet rect becomes the background, else white), none (keep that rect as a layer, white sheet), "
                         "transparent, or #rrggbb / #rrggbbaa")
    ap.add_argument("--pages", action="store_true", help="put all inputs into one project, one screen per SVG")
    args = ap.parse_args(argv)

    if args.pages:
        out = args.out or os.path.splitext(args.inputs[0])[0] + ".qwel"
        pages, canvas, background, title0 = [], None, None, None
        for idx, path in enumerate(args.inputs):
            try:
                data = open(path, "rb").read()
                if idx == 0:
                    res = import_svg(data, args.size, args.scale)
                    canvas = (res.width, res.height)  # every screen shares the size of the first one
                    background = pull_background(res, args.bg)
                    title0 = res.title
                else:
                    res = import_svg(data, canvas) if args.size else import_svg(data, None, args.scale)
                    if abs(res.width - canvas[0]) > 0.5 or abs(res.height - canvas[1]) > 0.5:
                        res = import_svg(data, canvas)  # different size: fit into the first screen's sheet
                    pull_background(res, args.bg)  # drops a full-sheet rectangle here as well
            except (OSError, ValueError) as e:
                print("%s: %s" % (path, e), file=sys.stderr)
                return 1
            pages.append((res.title or os.path.splitext(os.path.basename(path))[0], res.nodes))
            report(path, res, len(res.nodes))
        name = args.name or title0 or os.path.splitext(os.path.basename(out))[0]
        write_qwel(out, build_project(name, canvas[0], canvas[1], background, pages))
        print("-> %s (%d screens)" % (out, len(pages)))
        return 0

    if len(args.inputs) > 1 and args.out and not os.path.isdir(args.out):
        os.makedirs(args.out, exist_ok=True)
    status = 0
    for path in args.inputs:
        try:
            res = import_svg(open(path, "rb").read(), args.size, args.scale)
        except (OSError, ValueError) as e:
            print("%s: %s" % (path, e), file=sys.stderr)
            status = 1
            continue
        background = pull_background(res, args.bg)
        base = os.path.splitext(os.path.basename(path))[0]
        if len(args.inputs) == 1 and args.out:
            out = args.out
        elif args.out:
            out = os.path.join(args.out, base + ".qwel")
        else:
            out = os.path.splitext(path)[0] + ".qwel"
        name = args.name if len(args.inputs) == 1 and args.name else (res.title or base)
        write_qwel(out, build_project(name, res.width, res.height, background, [(name, res.nodes)]))
        report(path, res, len(res.nodes))
        print("-> %s" % out)
    return status


if __name__ == "__main__":
    sys.exit(main())
