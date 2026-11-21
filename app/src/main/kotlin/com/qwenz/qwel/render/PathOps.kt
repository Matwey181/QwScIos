package com.qwenz.qwel.render

import com.qwenz.qwel.i18n.tr

import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.PathMeasure
import android.graphics.RectF
import android.util.LruCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Canvas
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.graphics.asAndroidPath
import androidx.compose.ui.graphics.drawscope.CanvasDrawScope
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import com.qwenz.qwel.data.Node
import com.qwenz.qwel.data.NodeKind
import com.qwenz.qwel.data.boundsOf
import com.qwenz.qwel.data.newId
import com.qwenz.qwel.shapes.ShapeLibrary
import java.util.Locale
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sqrt
import android.graphics.Path as APath
import androidx.compose.ui.graphics.Path as CPath

/** Операции над фигурами, как в графических редакторах. */
enum class BoolOp(private val key: String) {
    UNION("op_union"),
    DIFFERENCE("op_difference"),
    INTERSECT("op_intersect"),
    EXCLUDE("op_exclude"),
    COMBINE("op_combine"),
    DIVIDE("op_divide"),
    FLATTEN("op_flatten");

    /** Название на текущем языке. */
    val title: String get() = tr(key)
}

// ------------------------------------------------------------------ хранение контура

/** Разобранный контур: verbs 0 = M, 1 = L, 2 = Z; coords - пары x, y в единичном квадрате. */
class ParsedPath(val verbs: ByteArray, val coords: FloatArray)

// Кэш большой: у проекта с иконками сотни разных контуров, а с маленьким кэшем они разбирались заново каждый кадр.
private val parsedCache = LruCache<String, ParsedPath>(2048)

fun parsePath(s: String): ParsedPath {
    parsedCache.get(s)?.let { return it }
    var verbs = ByteArray(16); var vn = 0
    var coords = FloatArray(64); var cn = 0
    val n = s.length
    var i = 0
    while (i < n) {
        while (i < n && s[i] == ' ') i++
        if (i >= n) break
        var j = i
        while (j < n && s[j] != ' ') j++
        val c = s[i]
        val v = if (j - i == 1) when (c) { 'M' -> 0; 'L' -> 1; 'Z' -> 2; else -> -1 } else -1
        if (v >= 0) {
            if (vn == verbs.size) verbs = verbs.copyOf(vn * 2)
            verbs[vn++] = v.toByte()
        } else {
            s.substring(i, j).toFloatOrNull()?.let {
                if (cn == coords.size) coords = coords.copyOf(cn * 2)
                coords[cn++] = it
            }
        }
        i = j
    }
    val res = ParsedPath(verbs.copyOf(vn), coords.copyOf(cn))
    parsedCache.put(s, res)
    return res
}

private val unitNonZero = LruCache<String, CPath>(1024)
private val unitEvenOdd = LruCache<String, CPath>(1024)

/** Контур слоя PATH в единичном квадрате: строится один раз, при рисовании только масштабируется (годится для заливки без градиента). */
fun Node.unitPath(): CPath {
    val cache = if (evenOdd) unitEvenOdd else unitNonZero
    cache.get(path)?.let { return it }
    val pp = parsePath(path)
    val p = CPath()
    var ci = 0
    for (v in pp.verbs) {
        when (v.toInt()) {
            0 -> { p.moveTo(pp.coords[ci], pp.coords[ci + 1]); ci += 2 }
            1 -> { p.lineTo(pp.coords[ci], pp.coords[ci + 1]); ci += 2 }
            else -> p.close()
        }
    }
    p.fillType = if (evenOdd) PathFillType.EvenOdd else PathFillType.NonZero
    cache.put(path, p)
    return p
}

/** Контур слоя PATH в координатах документа (без поворота). */
fun Node.composePath(): CPath {
    val pp = parsePath(path)
    val p = CPath()
    var ci = 0
    for (v in pp.verbs) {
        when (v.toInt()) {
            0 -> { p.moveTo(x + pp.coords[ci] * w, y + pp.coords[ci + 1] * h); ci += 2 }
            1 -> { p.lineTo(x + pp.coords[ci] * w, y + pp.coords[ci + 1] * h); ci += 2 }
            else -> p.close()
        }
    }
    p.fillType = if (evenOdd) PathFillType.EvenOdd else PathFillType.NonZero
    return p
}

/** Данные для SVG <path d="...">, в координатах документа (без поворота). */
fun svgPathData(n: Node): String {
    val pp = parsePath(n.path)
    val sb = StringBuilder()
    var ci = 0
    fun num(v: Float) = String.format(Locale.US, "%.2f", v).trimEnd('0').trimEnd('.').ifEmpty { "0" }
    for (v in pp.verbs) {
        when (v.toInt()) {
            0, 1 -> {
                sb.append(if (v.toInt() == 0) "M" else "L")
                    .append(num(n.x + pp.coords[ci] * n.w)).append(' ').append(num(n.y + pp.coords[ci + 1] * n.h)).append(' ')
                ci += 2
            }
            else -> sb.append("Z ")
        }
    }
    return sb.toString().trim()
}

// ------------------------------------------------------------------ геометрия слоёв

/** Контур слоя в координатах документа с учётом поворота. null - слой нельзя использовать. */
fun nodeGeometry(n: Node): APath? {
    val p: APath = when (n.kind) {
        NodeKind.RECT -> APath().apply {
            val r = min(n.corner, min(n.w, n.h) / 2f)
            addRoundRect(RectF(n.x, n.y, n.x + n.w, n.y + n.h), r, r, APath.Direction.CW)
        }
        NodeKind.IMAGE -> APath().apply { addRect(RectF(n.x, n.y, n.x + n.w, n.y + n.h), APath.Direction.CW) }
        NodeKind.ELLIPSE -> APath().apply { addOval(RectF(n.x, n.y, n.x + n.w, n.y + n.h), APath.Direction.CW) }
        NodeKind.SHAPE -> {
            val cubics = ShapeLibrary.get(n.shapeId)?.cubics ?: return null
            cubics.appendTo(CPath(), n.x, n.y, n.w, n.h).asAndroidPath()
        }
        NodeKind.PATH -> if (n.path.isEmpty()) return null else n.composePath().asAndroidPath()
        NodeKind.TEXT -> {
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                textSize = n.fontSize; typeface = Fonts.typeface(n.font, n.weight)
            }
            val fm = paint.fontMetrics
            val lineH = n.fontSize * 1.25f
            val out = APath()
            for ((i, line) in n.text.split('\n').withIndex()) {
                if (line.isBlank()) continue
                val baseline = n.y + (i + 0.5f) * lineH - (fm.ascent + fm.descent) / 2f
                val tmp = APath()
                paint.getTextPath(line, 0, line.length, n.x, baseline, tmp)
                out.addPath(tmp)
            }
            out
        }
    }
    if (n.rotation != 0f) {
        val m = Matrix(); m.setRotate(n.rotation, n.cx, n.cy); p.transform(m)
    }
    return p
}

private fun tiny(p: APath): Boolean {
    if (p.isEmpty) return true
    val r = RectF(); p.computeBounds(r, true)
    return min(r.width(), r.height()) < 0.05f
}

private fun androidOp(op: BoolOp): APath.Op = when (op) {
    BoolOp.UNION -> APath.Op.UNION
    BoolOp.DIFFERENCE -> APath.Op.DIFFERENCE
    BoolOp.INTERSECT -> APath.Op.INTERSECT
    BoolOp.EXCLUDE -> APath.Op.XOR
    else -> APath.Op.UNION
}

// ------------------------------------------------------------------ контур -> слой

/** Дискретизирует контуры: прямые остаются точными, углы сохраняются, кривые разбиваются мелко. */
private fun sampleContours(path: APath): List<FloatArray> {
    val result = ArrayList<FloatArray>()
    val pm = PathMeasure(path, false)
    val pos = FloatArray(2); val tan = FloatArray(2)
    do {
        val len = pm.length
        if (len >= 0.01f) {
            val step = (len / 800f).coerceIn(0.35f, 3f)
            val n = ceil(len / step).toInt().coerceIn(8, 4000)
            val px = FloatArray(n); val py = FloatArray(n); val tx = FloatArray(n); val ty = FloatArray(n)
            for (i in 0 until n) {
                pm.getPosTan(len * i / n, pos, tan)
                px[i] = pos[0]; py[i] = pos[1]; tx[i] = tan[0]; ty[i] = tan[1]
            }
            val pts = ArrayList<Float>(n * 2 + 16)
            for (i in 0 until n) {
                pts.add(px[i]); pts.add(py[i])
                val j = (i + 1) % n
                if (tx[i] * tx[j] + ty[i] * ty[j] < 0.99f) {
                    // между двумя отсчётами резко меняется направление - ищем угол
                    var lo = len * i / n; var hi = len * (i + 1) / n
                    repeat(14) {
                        val mid = (lo + hi) / 2f
                        pm.getPosTan(mid, pos, tan)
                        if (tan[0] * tx[i] + tan[1] * ty[i] > 0.9995f) lo = mid else hi = mid
                    }
                    pm.getPosTan(lo, pos, null)
                    pts.add(pos[0]); pts.add(pos[1])
                }
            }
            result.add(simplify(pts.toFloatArray()))
        }
    } while (pm.nextContour())
    return result
}

/** Убирает точки, лежащие на прямой между соседями. */
private fun simplify(pts: FloatArray): FloatArray {
    val n = pts.size / 2
    if (n < 4) return pts
    val keep = ArrayList<Float>(pts.size)
    var ax = pts[0]; var ay = pts[1]
    keep.add(ax); keep.add(ay)
    for (i in 1 until n - 1) {
        val bx = pts[i * 2]; val by = pts[i * 2 + 1]
        val cx = pts[(i + 1) * 2]; val cy = pts[(i + 1) * 2 + 1]
        val dx = cx - ax; val dy = cy - ay
        val len = sqrt(dx * dx + dy * dy)
        val dist = if (len < 1e-6f) 0f else abs((bx - ax) * dy - (by - ay) * dx) / len
        if (dist > 0.002f) { keep.add(bx); keep.add(by); ax = bx; ay = by }
    }
    keep.add(pts[(n - 1) * 2]); keep.add(pts[(n - 1) * 2 + 1])
    return keep.toFloatArray()
}

private fun fmt(v: Float): String = String.format(Locale.US, "%.4f", v).trimEnd('0').trimEnd('.').ifEmpty { "0" }

/** Собирает слой PATH из контура. Стиль берётся у [style]. null - контур пустой. */
fun pathToNode(path: APath, style: Node, name: String): Node? {
    val contours = sampleContours(path).filter { it.size >= 6 }
    if (contours.isEmpty()) return null
    var l = Float.MAX_VALUE; var t = Float.MAX_VALUE; var r = -Float.MAX_VALUE; var b = -Float.MAX_VALUE
    for (c in contours) for (i in 0 until c.size / 2) {
        l = min(l, c[i * 2]); r = max(r, c[i * 2]); t = min(t, c[i * 2 + 1]); b = max(b, c[i * 2 + 1])
    }
    val w = max(r - l, 0.01f); val h = max(b - t, 0.01f)
    val sb = StringBuilder()
    for (c in contours) {
        for (i in 0 until c.size / 2) {
            sb.append(if (i == 0) "M " else "L ")
                .append(fmt((c[i * 2] - l) / w)).append(' ').append(fmt((c[i * 2 + 1] - t) / h)).append(' ')
        }
        sb.append("Z ")
    }
    val evenOdd = path.fillType == APath.FillType.EVEN_ODD || path.fillType == APath.FillType.INVERSE_EVEN_ODD
    return Node(
        id = newId(), kind = NodeKind.PATH, name = name, x = l, y = t, w = w, h = h,
        fill = style.fill, stroke = style.stroke, strokeWidth = style.strokeWidth, opacity = style.opacity,
        path = sb.toString().trim(), evenOdd = evenOdd, group = style.group,
        ratioLock = false,
    )
}

// ------------------------------------------------------------------ операции

/**
 * Применяет [op] к слоям [nodes] (в порядке снизу вверх). Возвращает новые слои или null при ошибке.
 * Для FLATTEN результат - один слой-картинка.
 */
fun applyBoolOp(nodes: List<Node>, op: BoolOp): List<Node>? {
    if (nodes.isEmpty()) return null
    if (op == BoolOp.FLATTEN) return flattenNodes(nodes)?.let { listOf(it) }
    val geoms = nodes.map { nodeGeometry(it) ?: return null }
    val base = nodes.first()
    return when (op) {
        BoolOp.UNION, BoolOp.DIFFERENCE, BoolOp.INTERSECT, BoolOp.EXCLUDE -> {
            if (nodes.size < 2) return null
            var acc = APath(geoms[0])
            for (i in 1 until geoms.size) {
                val next = APath(acc)
                if (!next.op(geoms[i], androidOp(op))) return null
                acc = next
            }
            pathToNode(acc, base, op.title)?.let { listOf(it) }
        }
        BoolOp.COMBINE -> {
            val all = APath().apply { fillType = APath.FillType.EVEN_ODD; for (g in geoms) addPath(g) }
            pathToNode(all, base, op.title)?.let { listOf(it) }
        }
        BoolOp.DIVIDE -> {
            if (nodes.size < 2) return null
            class Piece(val path: APath, val src: Node)
            var pieces = ArrayList<Piece>()
            for ((idx, n) in nodes.withIndex()) {
                val g = geoms[idx]
                val next = ArrayList<Piece>()
                val remainder = APath(g)
                for (pc in pieces) {
                    val inter = APath(pc.path)
                    if (inter.op(g, APath.Op.INTERSECT) && !tiny(inter)) next.add(Piece(inter, n))
                    val rest = APath(pc.path)
                    if (rest.op(g, APath.Op.DIFFERENCE) && !tiny(rest)) next.add(Piece(rest, pc.src))
                    remainder.op(pc.path, APath.Op.DIFFERENCE)
                }
                if (!tiny(remainder)) next.add(Piece(remainder, n))
                pieces = next
            }
            val out = pieces.mapIndexedNotNull { i, pc -> pathToNode(pc.path, pc.src, tr("part_n", i + 1)) }
            out.ifEmpty { null }
        }
        BoolOp.FLATTEN -> null
    }
}

/** 'Объединить слои': сливает слои в одну картинку. */
fun flattenNodes(sel: List<Node>): Node? {
    val box = boundsOf(sel.filter { it.visible }) ?: return null
    val bw = max(box.w, 1f); val bh = max(box.h, 1f)
    val factor = min(3f, 4096f / max(bw, bh))
    val pw = (bw * factor).roundToInt().coerceAtLeast(1)
    val ph = (bh * factor).roundToInt().coerceAtLeast(1)
    val bitmap = ImageBitmap(pw, ph)
    val canvas = Canvas(bitmap)
    CanvasDrawScope().draw(Density(1f), LayoutDirection.Ltr, canvas, Size(pw.toFloat(), ph.toFloat())) {
        scale(pw / bw, ph / bh, pivot = Offset.Zero) {
            translate(-box.l, -box.t) { drawNodes(sel) }
        }
    }
    val name = Assets.saveBitmap(bitmap.asAndroidBitmap()) ?: return null
    return Node(newId(), NodeKind.IMAGE, tr("merged_layer"), box.l, box.t, bw, bh, asset = name)
}
