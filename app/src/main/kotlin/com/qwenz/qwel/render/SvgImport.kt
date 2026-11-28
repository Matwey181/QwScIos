package com.qwenz.qwel.render

import com.qwenz.qwel.data.Node
import com.qwenz.qwel.data.NodeKind
import com.qwenz.qwel.data.Project
import com.qwenz.qwel.data.newId
import org.w3c.dom.Element
import org.w3c.dom.Node as DomNode
import java.io.ByteArrayInputStream
import java.util.Locale
import javax.xml.parsers.DocumentBuilderFactory
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.math.tan

/**
 * Импорт SVG в слои. Понимает rect, circle, ellipse, line, polyline, polygon, path (все команды, включая дуги),
 * группы и transform, заливку и обводку из атрибутов и style="...".
 * Кривые превращаются в ломаные (слой PATH хранит только отрезки). Градиенты, текст, картинки, use и CSS-классы
 * не переносятся: их число возвращается в [Result.skipped].
 */
object SvgImport {
    /** [width]/[height] - размер листа, на который уложен рисунок; [title] - <title> из файла. */
    class Result(
        val nodes: List<Node>, val skipped: Int, val approximated: Boolean,
        val width: Float = 0f, val height: Float = 0f, val title: String? = null,
    )

    private const val MAX_BYTES = 2_000_000
    private const val MAX_NODES = 400
    private const val MAX_POINTS = 30_000

    private class St(
        val fill: Int = 0xFF000000.toInt(), val stroke: Int = 0, val strokeW: Float = 1f,
        val opacity: Float = 1f, val evenOdd: Boolean = false, val fillOpacity: Float = 1f, val strokeOpacity: Float = 1f,
    )

    /** Аффинная матрица [a b c d e f]: x' = a x + c y + e, y' = b x + d y + f. */
    private class Mat(val a: Double, val b: Double, val c: Double, val d: Double, val e: Double, val f: Double) {
        operator fun times(o: Mat) = Mat(
            a * o.a + c * o.b, b * o.a + d * o.b,
            a * o.c + c * o.d, b * o.c + d * o.d,
            a * o.e + c * o.f + e, b * o.e + d * o.f + f,
        )
        fun x(px: Double, py: Double) = a * px + c * py + e
        fun y(px: Double, py: Double) = b * px + d * py + f
        val scale: Double get() = sqrt(abs(a * d - b * c))
        val axisAligned: Boolean get() = abs(b) < 1e-9 && abs(c) < 1e-9 && a > 0 && d > 0
        companion object { val I = Mat(1.0, 0.0, 0.0, 1.0, 0.0, 0.0) }
    }

    private class Poly(val pts: ArrayList<Float> = ArrayList(), var closed: Boolean = false)

    private class Ctx(val canvasW: Float, val canvasH: Float) {
        val nodes = ArrayList<Node>()
        var skipped = 0
        var approx = false
        var points = 0
    }

    /** null - файл не SVG, слишком большой или повреждён. */
    fun parse(bytes: ByteArray, canvasW: Float, canvasH: Float): Result? = parseCore(bytes, canvasW, canvasH, 1.0)

    /** Рисунок в собственном размере, умноженном на [scale] (лист получается под размер рисунка). */
    fun parseOwnSize(bytes: ByteArray, scale: Double = 1.0): Result? = parseCore(bytes, null, null, scale)

    /**
     * Новый проект из SVG: лист по размеру рисунка (мелкие иконки увеличиваются до ~512, огромные уменьшаются до 4096),
     * прямоугольник во весь лист снизу становится фоном проекта. Пара (проект, результат); null - это не SVG.
     */
    fun toProject(bytes: ByteArray, fallbackName: String): Pair<Project, Result>? {
        var r = parseOwnSize(bytes) ?: return null
        val side = max(r.width, r.height)
        val k = when { side < 256f -> 512.0 / side; side > 4096f -> 4096.0 / side; else -> 1.0 }
        if (k != 1.0) r = parseOwnSize(bytes, k) ?: return null
        val nodes = r.nodes.toMutableList()
        var bg = 0xFFFFFFFF.toInt()
        nodes.firstOrNull()?.let { n ->
            val covers = n.kind == NodeKind.RECT && n.corner == 0f && n.rotation == 0f && n.strokeWidth == 0f &&
                abs(n.x) < 0.5f && abs(n.y) < 0.5f && abs(n.w - r.width) < 0.5f && abs(n.h - r.height) < 0.5f &&
                n.opacity >= 0.999f && (n.fill ushr 24) == 0xFF
            if (covers) { bg = n.fill; nodes.removeAt(0) }
        }
        val now = System.currentTimeMillis()
        val p = Project(newId(), r.title?.takeIf { it.isNotBlank() } ?: fallbackName, r.width, r.height, bg, nodes, now, now)
        return p to r
    }

    private fun parseCore(bytes: ByteArray, canvasW: Float?, canvasH: Float?, scale: Double): Result? {
        if (bytes.size > MAX_BYTES) return null
        val text = bytes.toString(Charsets.UTF_8)
        if (text.contains("<!ENTITY", ignoreCase = true)) return null
        val root = runCatching {
            val f = DocumentBuilderFactory.newInstance()
            f.isNamespaceAware = false
            runCatching { f.setFeature("http://apache.org/xml/features/disallow-doctype-decl", false) }
            f.newDocumentBuilder().parse(ByteArrayInputStream(bytes)).documentElement
        }.getOrNull() ?: return null
        if (root.tagName.substringAfter(':') != "svg") return null

        // размер исходного рисунка и перенос его в центр листа
        val vb = root.getAttribute("viewBox").split(Regex("[,\\s]+")).mapNotNull { it.toDoubleOrNull() }
        val (vx, vy, vw, vh) = if (vb.size == 4 && vb[2] > 0 && vb[3] > 0) vb
        else listOf(0.0, 0.0, length(root.getAttribute("width")) ?: 100.0, length(root.getAttribute("height")) ?: 100.0)
        val own = canvasW == null || canvasH == null
        val s = if (own) scale else min(canvasW!! * 0.9 / vw, canvasH!! * 0.9 / vh).coerceIn(0.01, 8.0)
        val sheetW = if (own) vw * s else canvasW!!.toDouble()
        val sheetH = if (own) vh * s else canvasH!!.toDouble()
        val ox = (sheetW - vw * s) / 2.0
        val oy = (sheetH - vh * s) / 2.0
        val m0 = Mat(s, 0.0, 0.0, s, ox - vx * s, oy - vy * s)

        var title: String? = null
        var c = root.firstChild
        while (c != null) {
            if (c.nodeType == DomNode.ELEMENT_NODE && (c as Element).tagName.substringAfter(':') == "title" && title == null) {
                title = c.textContent?.trim()?.takeIf { it.isNotEmpty() }
            }
            c = c.nextSibling
        }

        val ctx = Ctx(sheetW.toFloat(), sheetH.toFloat())
        walk(root, m0, St(), ctx, root = true)
        return Result(ctx.nodes, ctx.skipped, ctx.approx, sheetW.toFloat(), sheetH.toFloat(), title)
    }

    private fun length(s: String): Double? =
        Regex("^\\s*(-?[0-9]*\\.?[0-9]+(?:[eE][-+]?[0-9]+)?)").find(s)?.groupValues?.get(1)?.toDoubleOrNull()

    private fun attr(e: Element, name: String, def: Double = 0.0): Double = length(e.getAttribute(name)) ?: def

    // ---------------------------------------------------------------- стили

    private val named = mapOf(
        "black" to 0xFF000000, "white" to 0xFFFFFFFF, "red" to 0xFFFF0000, "green" to 0xFF008000, "blue" to 0xFF0000FF,
        "yellow" to 0xFFFFFF00, "gray" to 0xFF808080, "grey" to 0xFF808080, "orange" to 0xFFFFA500, "purple" to 0xFF800080,
        "pink" to 0xFFFFC0CB, "cyan" to 0xFF00FFFF, "magenta" to 0xFFFF00FF, "brown" to 0xFFA52A2A, "navy" to 0xFF000080,
        "teal" to 0xFF008080, "lime" to 0xFF00FF00, "silver" to 0xFFC0C0C0, "maroon" to 0xFF800000, "gold" to 0xFFFFD700,
    )

    /** ARGB, 0 - 'нет', null - не понял (например, url(#градиент)). */
    private fun color(raw: String, current: Int): Int? {
        val v = raw.trim().lowercase(Locale.US)
        if (v.isEmpty()) return null
        if (v == "none" || v == "transparent") return 0
        if (v == "currentcolor") return current
        named[v]?.let { return it.toInt() }
        if (v.startsWith("#")) {
            val h = v.substring(1)
            val full = when (h.length) {
                3 -> h.map { "$it$it" }.joinToString("")
                4 -> h.map { "$it$it" }.joinToString("")
                6, 8 -> h
                else -> return null
            }
            val n = full.toLongOrNull(16) ?: return null
            return if (full.length == 8) (((n and 0xFF) shl 24) or (n ushr 8)).toInt() else (0xFF000000 or n).toInt()
        }
        if (v.startsWith("rgb")) {
            val parts = v.substringAfter('(').substringBefore(')').split(Regex("[,\\s/]+")).filter { it.isNotEmpty() }
            if (parts.size < 3) return null
            fun ch(t: String): Int? {
                val d = (if (t.endsWith("%")) t.dropLast(1).toDoubleOrNull()?.times(2.55) else t.toDoubleOrNull()) ?: return null
                return d.toInt().coerceIn(0, 255)
            }
            val rr = ch(parts[0]) ?: return null; val gg = ch(parts[1]) ?: return null; val bb = ch(parts[2]) ?: return null
            return (0xFF shl 24) or (rr shl 16) or (gg shl 8) or bb
        }
        return null
    }

    private fun styleOf(el: Element, parent: St, ctx: Ctx): St {
        val props = HashMap<String, String>()
        for (k in listOf("fill", "stroke", "stroke-width", "opacity", "fill-opacity", "stroke-opacity", "fill-rule", "color")) {
            val v = el.getAttribute(k); if (v.isNotEmpty()) props[k] = v
        }
        for (decl in el.getAttribute("style").split(';')) {
            val i = decl.indexOf(':'); if (i > 0) props[decl.substring(0, i).trim()] = decl.substring(i + 1).trim()
        }
        val cur = props["color"]?.let { color(it, parent.fill) } ?: parent.fill
        fun paint(key: String, old: Int): Int {
            val raw = props[key] ?: return old
            return color(raw, cur) ?: run { ctx.approx = true; 0xFF9E9E9E.toInt() }
        }
        return St(
            fill = paint("fill", parent.fill), stroke = paint("stroke", parent.stroke),
            strokeW = props["stroke-width"]?.let { length(it)?.toFloat() } ?: parent.strokeW,
            opacity = parent.opacity * (props["opacity"]?.toFloatOrNull()?.coerceIn(0f, 1f) ?: 1f),
            evenOdd = props["fill-rule"]?.let { it.trim() == "evenodd" } ?: parent.evenOdd,
            fillOpacity = props["fill-opacity"]?.toFloatOrNull()?.coerceIn(0f, 1f) ?: parent.fillOpacity,
            strokeOpacity = props["stroke-opacity"]?.toFloatOrNull()?.coerceIn(0f, 1f) ?: parent.strokeOpacity,
        )
    }

    private fun withAlpha(argb: Int, k: Float): Int {
        if (argb == 0 || k >= 0.999f) return argb
        val a = ((argb ushr 24) * k).toInt().coerceIn(0, 255)
        return (a shl 24) or (argb and 0xFFFFFF)
    }

    // ---------------------------------------------------------------- transform

    private fun transformOf(s: String): Mat {
        var m = Mat.I
        for (r in Regex("(\\w+)\\s*\\(([^)]*)\\)").findAll(s)) {
            val v = r.groupValues[2].split(Regex("[,\\s]+")).mapNotNull { it.toDoubleOrNull() }
            val t = when (r.groupValues[1]) {
                "translate" -> Mat(1.0, 0.0, 0.0, 1.0, v.getOrElse(0) { 0.0 }, v.getOrElse(1) { 0.0 })
                "scale" -> Mat(v.getOrElse(0) { 1.0 }, 0.0, 0.0, v.getOrElse(1) { v.getOrElse(0) { 1.0 } }, 0.0, 0.0)
                "rotate" -> {
                    val a = Math.toRadians(v.getOrElse(0) { 0.0 }); val cs = cos(a); val sn = sin(a)
                    val rot = Mat(cs, sn, -sn, cs, 0.0, 0.0)
                    if (v.size >= 3) Mat(1.0, 0.0, 0.0, 1.0, v[1], v[2]) * rot * Mat(1.0, 0.0, 0.0, 1.0, -v[1], -v[2]) else rot
                }
                "skewX" -> Mat(1.0, 0.0, tan(Math.toRadians(v.getOrElse(0) { 0.0 })), 1.0, 0.0, 0.0)
                "skewY" -> Mat(1.0, tan(Math.toRadians(v.getOrElse(0) { 0.0 })), 0.0, 1.0, 0.0, 0.0)
                "matrix" -> if (v.size == 6) Mat(v[0], v[1], v[2], v[3], v[4], v[5]) else Mat.I
                else -> Mat.I
            }
            m *= t
        }
        return m
    }

    // ---------------------------------------------------------------- обход

    private fun walk(el: Element, parentM: Mat, parentSt: St, ctx: Ctx, root: Boolean = false) {
        if (ctx.nodes.size >= MAX_NODES) { ctx.skipped++; return }
        val tag = el.tagName.substringAfter(':')
        val m = if (root) parentM else parentM * transformOf(el.getAttribute("transform"))
        if (el.getAttribute("display") == "none" || el.getAttribute("visibility") == "hidden") return
        val st = styleOf(el, parentSt, ctx)
        when (tag) {
            "svg", "g", "a" -> {
                var c = el.firstChild
                while (c != null) { if (c.nodeType == DomNode.ELEMENT_NODE) walk(c as Element, m, st, ctx); c = c.nextSibling }
            }
            "defs", "symbol", "clipPath", "mask", "metadata", "title", "desc", "linearGradient", "radialGradient",
            "pattern", "filter", "marker" -> {}
            "style", "script" -> ctx.skipped++
            "rect" -> rect(el, m, st, ctx)
            "circle" -> {
                val r = attr(el, "r"); val cx = attr(el, "cx"); val cy = attr(el, "cy")
                ellipse(cx, cy, r, r, m, st, ctx, "circle")
            }
            "ellipse" -> ellipse(attr(el, "cx"), attr(el, "cy"), attr(el, "rx"), attr(el, "ry"), m, st, ctx, "ellipse")
            "line" -> {
                val p = Poly(); p.pts += listOf(attr(el, "x1").toFloat(), attr(el, "y1").toFloat(), attr(el, "x2").toFloat(), attr(el, "y2").toFloat())
                addPath(listOf(p), m, st.copy0(fill = 0), ctx, "line")
            }
            "polyline", "polygon" -> {
                val nums = el.getAttribute("points").split(Regex("[,\\s]+")).mapNotNull { it.toFloatOrNull() }
                val p = Poly()
                var i = 0
                while (i + 1 < nums.size) { p.pts += nums[i]; p.pts += nums[i + 1]; i += 2 }
                p.closed = tag == "polygon"
                addPath(listOf(p), m, st, ctx, tag)
            }
            "path" -> addPath(parsePathData(el.getAttribute("d"), ctx), m, st, ctx, "path")
            else -> ctx.skipped++
        }
    }

    private fun St.copy0(fill: Int) = St(fill, stroke, strokeW, opacity, evenOdd, fillOpacity, strokeOpacity)

    private fun nodeBase(kind: NodeKind, name: String, st: St, m: Mat) = Node(
        id = newId(), kind = kind, name = name, x = 0f, y = 0f, w = 1f, h = 1f,
        fill = withAlpha(st.fill, st.fillOpacity), stroke = withAlpha(st.stroke, st.strokeOpacity),
        strokeWidth = if ((st.stroke ushr 24) != 0) (st.strokeW * m.scale).toFloat() else 0f,
        opacity = st.opacity, evenOdd = st.evenOdd,
    )

    private fun rect(el: Element, m: Mat, st: St, ctx: Ctx) {
        val x = attr(el, "x"); val y = attr(el, "y"); val w = attr(el, "width"); val h = attr(el, "height")
        if (w <= 0 || h <= 0) return
        var rx = length(el.getAttribute("rx")); var ry = length(el.getAttribute("ry"))
        if (rx == null) rx = ry; if (ry == null) ry = rx
        if (m.axisAligned) {
            ctx.nodes += nodeBase(NodeKind.RECT, "rect", st, m).copy(
                x = m.x(x, y).toFloat(), y = m.y(x, y).toFloat(), w = (w * m.a).toFloat(), h = (h * m.d).toFloat(),
                corner = ((rx ?: 0.0) * m.a).toFloat(),
            )
        } else {
            val p = Poly(closed = true); p.pts += listOf(x, y, x + w, y, x + w, y + h, x, y + h).map { it.toFloat() }
            ctx.approx = ctx.approx || (rx ?: 0.0) > 0.0
            addPath(listOf(p), m, st, ctx, "rect")
        }
    }

    private fun ellipse(cx: Double, cy: Double, rx: Double, ry: Double, m: Mat, st: St, ctx: Ctx, name: String) {
        if (rx <= 0 || ry <= 0) return
        if (m.axisAligned) {
            ctx.nodes += nodeBase(NodeKind.ELLIPSE, name, st, m).copy(
                x = m.x(cx - rx, cy - ry).toFloat(), y = m.y(cx - rx, cy - ry).toFloat(), w = (2 * rx * m.a).toFloat(), h = (2 * ry * m.d).toFloat(),
            )
        } else {
            val p = Poly(closed = true)
            val n = 48
            for (i in 0 until n) { val t = 2 * PI * i / n; p.pts += (cx + rx * cos(t)).toFloat(); p.pts += (cy + ry * sin(t)).toFloat() }
            addPath(listOf(p), m, st, ctx, name)
        }
    }

    /** Подконтуры (в координатах SVG) -> слой PATH в координатах листа. */
    private fun addPath(subs: List<Poly>, m: Mat, st: St, ctx: Ctx, name: String) {
        val polys = subs.filter { it.pts.size >= 4 }
        if (polys.isEmpty()) return
        val total = polys.sumOf { it.pts.size / 2 }
        if (ctx.points + total > MAX_POINTS) { ctx.skipped++; return }
        ctx.points += total
        var l = Float.MAX_VALUE; var t = Float.MAX_VALUE; var r = -Float.MAX_VALUE; var b = -Float.MAX_VALUE
        val tp = polys.map { p ->
            val out = FloatArray(p.pts.size)
            var i = 0
            while (i < p.pts.size) {
                val x = m.x(p.pts[i].toDouble(), p.pts[i + 1].toDouble()).toFloat()
                val y = m.y(p.pts[i].toDouble(), p.pts[i + 1].toDouble()).toFloat()
                out[i] = x; out[i + 1] = y
                l = min(l, x); r = max(r, x); t = min(t, y); b = max(b, y)
                i += 2
            }
            out to p.closed
        }
        // линия нулевой ширины/высоты: даём слою толщину 1, контур остаётся по центру
        var w = r - l; var h = b - t
        var x0 = l; var y0 = t
        if (w < 1f) { x0 = l - (1f - w) / 2f; w = 1f }
        if (h < 1f) { y0 = t - (1f - h) / 2f; h = 1f }
        val sb = StringBuilder()
        fun f(v: Float) = String.format(Locale.US, "%.4f", v)
        for ((pts, closed) in tp) {
            var i = 0
            while (i < pts.size) {
                sb.append(if (i == 0) "M " else "L ").append(f((pts[i] - x0) / w)).append(' ').append(f((pts[i + 1] - y0) / h)).append(' ')
                i += 2
            }
            if (closed) sb.append("Z ")
        }
        val closedAny = tp.any { it.second }
        // у незамкнутого контура без заливки закрывающей линии быть не должно: заливки нет, значит обводка идёт по ломаной
        ctx.nodes += nodeBase(NodeKind.PATH, name, st, m).copy(
            x = x0, y = y0, w = w, h = h, path = sb.toString().trim(),
            fill = if (!closedAny && (st.fill ushr 24) != 0 && name == "line") 0 else withAlpha(st.fill, st.fillOpacity),
        )
    }

    // ---------------------------------------------------------------- данные path

    private class Scan(val s: String) {
        var i = 0
        fun ws() { while (i < s.length && (s[i].isWhitespace() || s[i] == ',')) i++ }
        fun more(): Boolean { ws(); return i < s.length }
        fun peekCmd(): Char? { ws(); return if (i < s.length && s[i].isLetter() && s[i] != 'e' && s[i] != 'E') s[i] else null }
        fun number(): Double? {
            ws()
            val st = i
            if (i < s.length && (s[i] == '-' || s[i] == '+')) i++
            var digits = false
            while (i < s.length && s[i].isDigit()) { i++; digits = true }
            if (i < s.length && s[i] == '.') { i++; while (i < s.length && s[i].isDigit()) { i++; digits = true } }
            if (!digits) { i = st; return null }
            if (i < s.length && (s[i] == 'e' || s[i] == 'E')) {
                val save = i; i++
                if (i < s.length && (s[i] == '-' || s[i] == '+')) i++
                if (i < s.length && s[i].isDigit()) { while (i < s.length && s[i].isDigit()) i++ } else i = save
            }
            return s.substring(st, i).toDoubleOrNull()
        }
        /** Флаг дуги: один символ 0 или 1, число без разделителя ("a1 1 0 01 2 2"). */
        fun flag(): Boolean? { ws(); if (i < s.length && (s[i] == '0' || s[i] == '1')) return s[i++] == '1'; return null }
    }

    private fun parsePathData(d: String, ctx: Ctx): List<Poly> {
        val out = ArrayList<Poly>()
        val sc = Scan(d)
        var cur: Poly? = null
        var cx = 0.0; var cy = 0.0; var sx = 0.0; var sy = 0.0
        var lcx = 0.0; var lcy = 0.0 // последняя контрольная точка для S/T
        var prev = ' '
        var cmd = ' '
        fun line(x: Double, y: Double) { cur?.pts?.let { it += x.toFloat(); it += y.toFloat() }; cx = x; cy = y }
        fun begin(x: Double, y: Double) { cur = Poly().also { out += it; it.pts += x.toFloat(); it.pts += y.toFloat() }; cx = x; cy = y; sx = x; sy = y }
        fun cubic(x1: Double, y1: Double, x2: Double, y2: Double, x: Double, y: Double) {
            val len = abs(x1 - cx) + abs(y1 - cy) + abs(x2 - x1) + abs(y2 - y1) + abs(x - x2) + abs(y - y2)
            val n = ceil(len / 2.0 - 1e-9).toInt().coerceIn(6, 40)
            val x0 = cx; val y0 = cy
            for (k in 1..n) {
                val t = k.toDouble() / n; val u = 1 - t
                line(u * u * u * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t * t * t * x,
                    u * u * u * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t * t * t * y)
            }
            lcx = x2; lcy = y2
        }
        fun quad(x1: Double, y1: Double, x: Double, y: Double) {
            cubic(cx + 2.0 / 3 * (x1 - cx), cy + 2.0 / 3 * (y1 - cy), x + 2.0 / 3 * (x1 - x), y + 2.0 / 3 * (y1 - y), x, y)
            lcx = x1; lcy = y1
        }
        fun arc(rx0: Double, ry0: Double, rot: Double, large: Boolean, sweep: Boolean, x: Double, y: Double) {
            var rx = abs(rx0); var ry = abs(ry0)
            if (rx == 0.0 || ry == 0.0 || (x == cx && y == cy)) { line(x, y); return }
            val phi = Math.toRadians(rot); val cp = cos(phi); val sp = sin(phi)
            val dx = (cx - x) / 2; val dy = (cy - y) / 2
            val x1 = cp * dx + sp * dy; val y1 = -sp * dx + cp * dy
            val lam = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
            if (lam > 1) { val k = sqrt(lam); rx *= k; ry *= k }
            val num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
            val den = rx * rx * y1 * y1 + ry * ry * x1 * x1
            var co = if (den == 0.0) 0.0 else sqrt(max(0.0, num / den))
            if (large == sweep) co = -co
            val cxp = co * rx * y1 / ry; val cyp = -co * ry * x1 / rx
            val ccx = cp * cxp - sp * cyp + (cx + x) / 2; val ccy = sp * cxp + cp * cyp + (cy + y) / 2
            val th1 = atan2((y1 - cyp) / ry, (x1 - cxp) / rx)
            var dth = atan2((-y1 - cyp) / ry, (-x1 - cxp) / rx) - th1
            if (sweep && dth < 0) dth += 2 * PI else if (!sweep && dth > 0) dth -= 2 * PI
            val n = ceil(abs(dth) / (PI / 16) - 1e-9).toInt().coerceIn(4, 64)
            for (k in 1..n) {
                val th = th1 + dth * k / n
                val px = rx * cos(th); val py = ry * sin(th)
                line(cp * px - sp * py + ccx, sp * px + cp * py + ccy)
            }
            cx = x; cy = y
        }

        var guard = 0
        while (sc.more() && guard++ < 200_000) {
            val c = sc.peekCmd()
            if (c != null) { sc.i++; cmd = c } else if (cmd == ' ') break
            // после Z без новой M рисование продолжается из начальной точки подконтура
            if (cur == null && cmd.uppercaseChar() != 'M' && cmd.uppercaseChar() != 'Z') begin(cx, cy)
            val rel = cmd.isLowerCase()
            val ox = if (rel) cx else 0.0; val oy = if (rel) cy else 0.0
            when (cmd.uppercaseChar()) {
                'M' -> {
                    val x = sc.number() ?: break; val y = sc.number() ?: break
                    begin(ox + x, oy + y); cmd = if (rel) 'l' else 'L'
                }
                'L' -> { val x = sc.number() ?: break; val y = sc.number() ?: break; line(ox + x, oy + y) }
                'H' -> { val x = sc.number() ?: break; line(ox + x, cy) }
                'V' -> { val y = sc.number() ?: break; line(cx, oy + y) }
                'C' -> {
                    val a = DoubleArray(6) { sc.number() ?: return out }
                    cubic(ox + a[0], oy + a[1], ox + a[2], oy + a[3], ox + a[4], oy + a[5])
                }
                'S' -> {
                    val a = DoubleArray(4) { sc.number() ?: return out }
                    val (rx1, ry1) = if (prev in "CcSs") (2 * cx - lcx) to (2 * cy - lcy) else cx to cy
                    cubic(rx1, ry1, ox + a[0], oy + a[1], ox + a[2], oy + a[3])
                }
                'Q' -> { val a = DoubleArray(4) { sc.number() ?: return out }; quad(ox + a[0], oy + a[1], ox + a[2], oy + a[3]) }
                'T' -> {
                    val a = DoubleArray(2) { sc.number() ?: return out }
                    val (rx1, ry1) = if (prev in "QqTt") (2 * cx - lcx) to (2 * cy - lcy) else cx to cy
                    quad(rx1, ry1, ox + a[0], oy + a[1])
                }
                'A' -> {
                    val rx = sc.number() ?: return out; val ry = sc.number() ?: return out; val rot = sc.number() ?: return out
                    val large = sc.flag() ?: return out; val sweep = sc.flag() ?: return out
                    val x = sc.number() ?: return out; val y = sc.number() ?: return out
                    arc(rx, ry, rot, large, sweep, ox + x, oy + y)
                }
                'Z' -> { cur?.closed = true; cx = sx; cy = sy; cur = null }
                else -> break
            }
            prev = cmd
        }
        return out
    }
}
