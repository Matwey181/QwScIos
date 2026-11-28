package com.qwenz.qwel.data

import java.util.Random
import kotlin.math.abs

/**
 * Эффект 'эхо / дребезг': вокруг слоя - стопка его копий с разным размером, контуром, прозрачностью и наклоном.
 * Копии - обычные слои, поэтому правятся, экспортируются и попадают в код Compose как любые другие.
 */
data class EchoParams(
    val count: Int = 4,
    /** Изменение размера на каждую копию, в процентах (отрицательное - копии меньше, положительное - больше). */
    val scaleStep: Float = 5f,
    /** Поворот на каждую копию, в градусах. */
    val rotateStep: Float = 3f,
    /** Насколько последняя копия прозрачнее оригинала (0..1). */
    val fade: Float = 0.85f,
    /** Только контур: заливка копий убирается, остаётся обводка цвета заливки. */
    val contour: Boolean = true,
    /** Смещение центра на каждую копию. */
    val spread: Float = 0f,
    /** Случайность размера, наклона, прозрачности и толщины обводки (0..1). */
    val jitter: Float = 0.2f,
    val seed: Int = 7,
)

object Echo {
    fun canEcho(n: Node): Boolean =
        n.kind == NodeKind.RECT || n.kind == NodeKind.ELLIPSE || n.kind == NodeKind.SHAPE || n.kind == NodeKind.PATH

    /** Копии [src] снизу вверх: самые дальние лежат ниже всех. Сам [src] в список не входит. */
    fun copies(src: Node, p: EchoParams): List<Node> {
        val rnd = Random(p.seed.toLong())
        fun j() = (rnd.nextFloat() * 2f - 1f) * p.jitter
        val n = p.count.coerceIn(1, 40)
        val hasLine = src.strokeWidth > 0f && (src.stroke ushr 24) != 0
        val lineColor = if (hasLine) src.stroke else src.fill
        val lineToken = if (hasLine) src.strokeToken else src.fillToken
        val out = ArrayList<Node>(n)
        for (i in 1..n) {
            val t = i / n.toFloat()
            val f = (1f + p.scaleStep / 100f * i + j() * 0.25f).coerceAtLeast(0.05f)
            val w = src.w * f
            val h = src.h * f
            val dx = p.spread * i * (1f + j() * 0.5f)
            val dy = p.spread * i * j() * 0.5f
            val rot = src.rotation + p.rotateStep * i + j() * abs(p.rotateStep) * 0.5f
            val op = (src.opacity * (1f - p.fade * t) * (1f + j() * 0.3f)).coerceIn(0.04f, 1f)
            val line = (if (src.strokeWidth > 0f) src.strokeWidth else 1.2f) * (0.6f + rnd.nextFloat() * 1.2f)
            var c = src.copy(
                id = newId(), name = "${src.name} $i",
                x = src.cx - w / 2f + dx, y = src.cy - h / 2f + dy, w = w, h = h,
                rotation = rot, opacity = op, corner = src.corner * f,
                shadowBlur = 0f, softBlur = 0f, blur = 0f, mask = false, widget = "", locked = false, pressCorner = -1f,
            )
            if (p.contour) {
                c = c.copy(fill = 0, fillToken = -1, gradKind = 0, stroke = lineColor, strokeToken = lineToken, strokeWidth = line)
            }
            out.add(c)
        }
        out.reverse()
        return out
    }
}
