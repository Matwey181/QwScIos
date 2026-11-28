package com.qwenz.qwel.render

import android.graphics.PathMeasure
import androidx.compose.ui.graphics.asAndroidPath
import com.qwenz.qwel.data.Node
import com.qwenz.qwel.data.NodeKind
import com.qwenz.qwel.data.newId
import java.util.Locale
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

private const val BLEND_POINTS = 96

/** Контур слоя в виде [BLEND_POINTS] точек, равномерно по длине, с учётом поворота слоя (x0,y0,x1,y1,...). */
private fun samplePoly(n: Node): FloatArray? {
    val pm = PathMeasure(nodeOutline(n).asAndroidPath(), false)
    val len = pm.length
    if (len < 0.01f) return null
    val out = FloatArray(BLEND_POINTS * 2)
    val pos = FloatArray(2)
    val rad = Math.toRadians(n.rotation.toDouble())
    val c = cos(rad).toFloat(); val s = sin(rad).toFloat()
    for (i in 0 until BLEND_POINTS) {
        pm.getPosTan(len * i / BLEND_POINTS, pos, null)
        val dx = pos[0] - n.cx; val dy = pos[1] - n.cy
        out[i * 2] = n.cx + dx * c - dy * s
        out[i * 2 + 1] = n.cy + dx * s + dy * c
    }
    return out
}

private fun area(p: FloatArray): Float {
    var a = 0f
    for (i in 0 until BLEND_POINTS) {
        val j = (i + 1) % BLEND_POINTS
        a += p[i * 2] * p[j * 2 + 1] - p[j * 2] * p[i * 2 + 1]
    }
    return a
}

private fun lerpArgb(a: Int, b: Int, t: Float): Int {
    fun ch(sh: Int) = (((a ushr sh) and 255) + (((b ushr sh) and 255) - ((a ushr sh) and 255)) * t).toInt().coerceIn(0, 255)
    return (ch(24) shl 24) or (ch(16) shl 16) or (ch(8) shl 8) or ch(0)
}

private fun num(v: Float) = String.format(Locale.US, "%.4f", v)

/**
 * 'Переход' между двумя слоями: [steps] промежуточных контуров, форма плавно превращается из [a] в [b],
 * вместе с ней меняются цвет, обводка и прозрачность. Результат - слои PATH. null - не удалось получить контур.
 */
fun blendNodes(a: Node, b: Node, steps: Int): List<Node>? {
    if (a.kind == NodeKind.TEXT || a.kind == NodeKind.IMAGE || b.kind == NodeKind.TEXT || b.kind == NodeKind.IMAGE) return null
    val pa = samplePoly(a) ?: return null
    var pb = samplePoly(b) ?: return null
    // обходим контур в одну сторону
    if ((area(pa) < 0f) != (area(pb) < 0f)) {
        val r = FloatArray(pb.size)
        for (i in 0 until BLEND_POINTS) { val k = BLEND_POINTS - 1 - i; r[i * 2] = pb[k * 2]; r[i * 2 + 1] = pb[k * 2 + 1] }
        pb = r
    }
    // начало контура выбираем так, чтобы точки пары были как можно ближе
    var best = 0; var bestD = Float.MAX_VALUE
    for (s in 0 until BLEND_POINTS) {
        var d = 0f
        for (i in 0 until BLEND_POINTS) {
            val k = (i + s) % BLEND_POINTS
            val dx = pa[i * 2] - pb[k * 2]; val dy = pa[i * 2 + 1] - pb[k * 2 + 1]
            d += dx * dx + dy * dy
        }
        if (d < bestD) { bestD = d; best = s }
    }
    val count = steps.coerceIn(1, 40)
    val out = ArrayList<Node>(count)
    val pts = FloatArray(BLEND_POINTS * 2)
    for (k in 1..count) {
        val t = k / (count + 1f)
        var l = Float.MAX_VALUE; var tp = Float.MAX_VALUE; var r = -Float.MAX_VALUE; var bt = -Float.MAX_VALUE
        for (i in 0 until BLEND_POINTS) {
            val j = (i + best) % BLEND_POINTS
            val x = pa[i * 2] + (pb[j * 2] - pa[i * 2]) * t
            val y = pa[i * 2 + 1] + (pb[j * 2 + 1] - pa[i * 2 + 1]) * t
            pts[i * 2] = x; pts[i * 2 + 1] = y
            l = min(l, x); r = max(r, x); tp = min(tp, y); bt = max(bt, y)
        }
        val w = max(r - l, 0.01f); val h = max(bt - tp, 0.01f)
        val sb = StringBuilder()
        for (i in 0 until BLEND_POINTS) {
            sb.append(if (i == 0) "M " else "L ").append(num((pts[i * 2] - l) / w)).append(' ').append(num((pts[i * 2 + 1] - tp) / h)).append(' ')
        }
        sb.append("Z")
        out.add(
            Node(
                id = newId(), kind = NodeKind.PATH, name = "${a.name} - ${b.name} $k",
                x = l, y = tp, w = w, h = h,
                fill = lerpArgb(a.fill, b.fill, t), stroke = lerpArgb(a.stroke, b.stroke, t),
                strokeWidth = a.strokeWidth + (b.strokeWidth - a.strokeWidth) * t,
                opacity = a.opacity + (b.opacity - a.opacity) * t,
                fillToken = if (a.fillToken == b.fillToken) a.fillToken else -1,
                strokeToken = if (a.strokeToken == b.strokeToken) a.strokeToken else -1,
                path = sb.toString(),
            ),
        )
    }
    return out
}
