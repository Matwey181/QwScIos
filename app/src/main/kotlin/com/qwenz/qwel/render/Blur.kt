package com.qwenz.qwel.render

import kotlin.math.floor
import kotlin.math.sqrt

/**
 * Гауссово размытие ARGB-пикселей (три прохода коробочного фильтра), края - 'продлением' (как TileMode.Clamp).
 * Нужно для PNG-экспорта: там нет аппаратного RenderEffect, зато работает на любой версии Android.
 * [sigma] - в пикселях; то же значение, что радиус у BlurEffect.
 */
fun gaussianBlurArgb(src: IntArray, w: Int, h: Int, sigma: Float): IntArray {
    if (sigma < 0.5f || w <= 0 || h <= 0) return src.copyOf()
    val sizes = boxSizes(sigma, 3)
    var a = src.copyOf()
    var b = IntArray(src.size)
    for (box in sizes) {
        val r = (box - 1) / 2
        if (r <= 0) continue
        boxPass(a, b, w, h, r, horizontal = true)
        boxPass(b, a, w, h, r, horizontal = false)
    }
    return a
}

/** Ширины коробок, дающие в сумме гауссиану с заданной сигмой (классическая формула). */
private fun boxSizes(sigma: Float, n: Int): IntArray {
    val ideal = sqrt(12f * sigma * sigma / n + 1f)
    var wl = floor(ideal).toInt()
    if (wl % 2 == 0) wl--
    val wu = wl + 2
    val m = Math.round((12f * sigma * sigma - n * wl * wl - 4f * n * wl - 3f * n) / (-4f * wl - 4f))
    return IntArray(n) { if (it < m) wl else wu }
}

/** Один проход скользящего окна радиуса [r] по строкам или столбцам; за краем берётся крайний пиксель. */
private fun boxPass(src: IntArray, dst: IntArray, w: Int, h: Int, r: Int, horizontal: Boolean) {
    val lines = if (horizontal) h else w
    val len = if (horizontal) w else h
    val stride = if (horizontal) 1 else w
    val div = 2 * r + 1
    val half = div / 2 // округление, чтобы картинка не темнела на каждом проходе
    for (line in 0 until lines) {
        val base = if (horizontal) line * w else line
        val first = src[base]
        // окно для позиции 0: r пикселей слева (все = first), сам пиксель и r справа
        var sa = (first ushr 24) * (r + 1)
        var sr = ((first shr 16) and 0xFF) * (r + 1)
        var sg = ((first shr 8) and 0xFF) * (r + 1)
        var sb = (first and 0xFF) * (r + 1)
        for (i in 1..r) {
            val p = src[base + minOf(i, len - 1) * stride]
            sa += p ushr 24; sr += (p shr 16) and 0xFF; sg += (p shr 8) and 0xFF; sb += p and 0xFF
        }
        for (i in 0 until len) {
            dst[base + i * stride] = (((sa + half) / div) shl 24) or (((sr + half) / div) shl 16) or (((sg + half) / div) shl 8) or ((sb + half) / div)
            val add = src[base + (if (i + r + 1 < len) i + r + 1 else len - 1) * stride]
            val sub = src[base + (if (i - r >= 0) i - r else 0) * stride]
            sa += (add ushr 24) - (sub ushr 24)
            sr += ((add shr 16) and 0xFF) - ((sub shr 16) and 0xFF)
            sg += ((add shr 8) and 0xFF) - ((sub shr 8) and 0xFF)
            sb += (add and 0xFF) - (sub and 0xFF)
        }
    }
}
