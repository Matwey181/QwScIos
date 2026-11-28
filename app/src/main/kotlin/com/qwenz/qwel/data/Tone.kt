package com.qwenz.qwel.data

import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cbrt
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

/** Индексы токенов цвета: порядок совпадает с [DesignPalette.baseline]. */
object Tok {
    const val PRIMARY = 0; const val ON_PRIMARY = 1; const val PRIMARY_CONTAINER = 2; const val ON_PRIMARY_CONTAINER = 3
    const val SECONDARY = 4; const val SECONDARY_CONTAINER = 5; const val ON_SECONDARY_CONTAINER = 6
    const val TERTIARY = 7; const val TERTIARY_CONTAINER = 8; const val ON_TERTIARY_CONTAINER = 9
    const val ERROR = 10; const val ERROR_CONTAINER = 11
    const val SURFACE = 12; const val SURFACE_LOW = 13; const val SURFACE_CONTAINER = 14
    const val SURFACE_HIGH = 15; const val SURFACE_HIGHEST = 16
    const val ON_SURFACE = 17; const val ON_SURFACE_VARIANT = 18
    const val OUTLINE = 19; const val OUTLINE_VARIANT = 20; const val INVERSE_SURFACE = 21
    const val COUNT = 22
}

/**
 * Тон проекта: схема цветов, под которую подстраиваются все слои с токенами.
 * [colors] - 22 цвета в порядке [Tok]. [mode]: 0 - базовая M3, 1 - от своего цвета, 2 - с обоев.
 */
data class Tone(
    val mode: Int = MODE_BASELINE,
    val seed: Int = BASE_SEED,
    val dark: Boolean = false,
    val colors: List<Int> = DesignPalette.baseline.map { it.argb },
) {
    fun color(token: Int, fallback: Int = 0): Int = colors.getOrNull(token) ?: fallback

    companion object {
        const val MODE_BASELINE = 0
        const val MODE_SEED = 1
        const val MODE_DYNAMIC = 2
        const val BASE_SEED = 0xFF006A6A.toInt()

        val Baseline = Tone()

        fun fromSeed(seed: Int, dark: Boolean): Tone = Tone(MODE_SEED, seed or 0xFF000000.toInt(), dark, ToneGen.scheme(seed, dark))

        fun baseline(dark: Boolean): Tone =
            if (!dark) Baseline else Tone(MODE_BASELINE, BASE_SEED, true, ToneGen.scheme(BASE_SEED, true))
    }
}

/** Генерация схемы из одного цвета: тональные палитры в пространстве OKLCH (близко к Material You). */
object ToneGen {
    private fun toLinear(c: Float) = if (c <= 0.04045f) c / 12.92f else ((c + 0.055f) / 1.055f).pow(2.4f)
    private fun fromLinear(c: Float) = if (c <= 0.0031308f) 12.92f * c else 1.055f * c.pow(1f / 2.4f) - 0.055f

    /** (L, C, hue deg) цвета. */
    fun toOklch(argb: Int): Triple<Float, Float, Float> {
        val r = toLinear(((argb shr 16) and 0xFF) / 255f)
        val g = toLinear(((argb shr 8) and 0xFF) / 255f)
        val b = toLinear((argb and 0xFF) / 255f)
        val l = cbrt(0.4122214708f * r + 0.5363325363f * g + 0.0514459929f * b)
        val m = cbrt(0.2119034982f * r + 0.6806995451f * g + 0.1073969566f * b)
        val s = cbrt(0.0883024619f * r + 0.2817188376f * g + 0.6299787005f * b)
        val ll = 0.2104542553f * l + 0.7936177850f * m - 0.0040720468f * s
        val a = 1.9779984951f * l - 2.4285922050f * m + 0.4505937099f * s
        val bb = 0.0259040371f * l + 0.7827717662f * m - 0.8086757660f * s
        var h = Math.toDegrees(atan2(bb.toDouble(), a.toDouble())).toFloat()
        if (h < 0f) h += 360f
        return Triple(ll, sqrt(a * a + bb * bb), h)
    }

    private fun linearRgb(L: Float, C: Float, hue: Float): FloatArray {
        val hr = Math.toRadians(hue.toDouble())
        val a = (C * cos(hr)).toFloat(); val b = (C * sin(hr)).toFloat()
        val l = (L + 0.3963377774f * a + 0.2158037573f * b).let { it * it * it }
        val m = (L - 0.1055613458f * a - 0.0638541728f * b).let { it * it * it }
        val s = (L - 0.0894841775f * a - 1.2914855480f * b).let { it * it * it }
        return floatArrayOf(
            4.0767416621f * l - 3.3077115913f * m + 0.2309699292f * s,
            -1.2684380046f * l + 2.6097574011f * m - 0.3413193965f * s,
            -0.0041960863f * l - 0.7034186147f * m + 1.7076147010f * s,
        )
    }

    /** Цвет по яркости L, насыщенности C и оттенку; при выходе за sRGB насыщенность уменьшается. */
    fun fromOklch(L: Float, C: Float, hue: Float): Int {
        var c = C
        var rgb = linearRgb(L, c, hue)
        var guard = 0
        while (guard++ < 40 && rgb.any { it < -0.0005f || it > 1.0005f }) {
            c *= 0.92f
            rgb = linearRgb(L, c, hue)
        }
        fun ch(v: Float) = (fromLinear(v.coerceIn(0f, 1f)) * 255f).roundToInt().coerceIn(0, 255)
        return (0xFF shl 24) or (ch(rgb[0]) shl 16) or (ch(rgb[1]) shl 8) or ch(rgb[2])
    }

    /** Цвет тональной палитры: tone 0..100 как в Material (светлота по CIE L*). */
    fun tone(hue: Float, chroma: Float, tone: Float): Int {
        val y = if (tone > 8f) ((tone + 16f) / 116f).pow(3) else tone / 903.3f
        return fromOklch(cbrt(y), chroma, hue)
    }

    fun scheme(seed: Int, dark: Boolean): List<Int> {
        val (_, c, h) = toOklch(seed)
        val gray = c < 0.02f
        val cp = if (gray) c else c.coerceIn(0.11f, 0.2f)
        val hs = h
        val ht = (h + 60f) % 360f
        val cn = if (gray) 0f else 0.012f
        val cnv = if (gray) 0f else 0.022f
        fun p(t: Float) = tone(hs, cp, t)
        fun s(t: Float) = tone(hs, cp / 3f, t)
        fun t(tn: Float) = tone(ht, cp * 0.55f, tn)
        fun e(tn: Float) = tone(29f, 0.19f, tn)
        fun n(tn: Float) = tone(hs, cn, tn)
        fun nv(tn: Float) = tone(hs, cnv, tn)
        return if (!dark) listOf(
            p(40f), p(100f), p(90f), p(10f),
            s(40f), s(90f), s(10f),
            t(40f), t(90f), t(10f),
            e(40f), e(90f),
            n(98f), n(96f), n(94f), n(92f), n(90f),
            n(10f), nv(30f), nv(50f), nv(80f), n(20f),
        ) else listOf(
            p(80f), p(20f), p(30f), p(90f),
            s(80f), s(30f), s(90f),
            t(80f), t(30f), t(90f),
            e(80f), e(30f),
            n(6f), n(10f), n(12f), n(17f), n(22f),
            n(90f), nv(80f), nv(60f), nv(30f), n(90f),
        )
    }
}

/** Применяет тон к слоям: слои с токенами получают цвета новой схемы. */
fun List<Node>.withTone(tone: Tone): List<Node> = map { n ->
    if (n.fillToken < 0 && n.strokeToken < 0) n
    else n.copy(
        fill = if (n.fillToken >= 0) tone.color(n.fillToken, n.fill) else n.fill,
        stroke = if (n.strokeToken >= 0) tone.color(n.strokeToken, n.stroke) else n.stroke,
    )
}
