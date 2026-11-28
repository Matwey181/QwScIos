package com.qwenz.qwel.data

/** Цвета, которые можно применять к слоям. Это содержимое документа, а не тема приложения. */
data class Swatch(val name: String, val argb: Int)

object DesignPalette {
    private fun c(hex: Long) = (0xFF000000 or hex).toInt()

    /** Базовая схема Vexel (светлая): бирюзовый, как на иконке. Цвета считает [ToneGen]. */
    private val baselineNames = listOf(
        "primary", "on-primary", "primary-container", "on-primary-container", "secondary", "secondary-container", "on-secondary-container", "tertiary", "tertiary-container", "on-tertiary-container", "error", "error-container", "surface", "surface-container-low", "surface-container", "surface-container-high", "surface-container-highest", "on-surface", "on-surface-variant", "outline", "outline-variant", "inverse-surface"
    )
    val baseline: List<Swatch> by lazy { baselineNames.zip(ToneGen.scheme(Tone.BASE_SEED, false)).map { (n, argb) -> Swatch(n, argb) } }

    /** Фирменная схема Qwel (светлая). */
    val qwel = listOf(
        Swatch("primary", c(0x644ABE)), Swatch("primary-container", c(0xE9DDFF)),
        Swatch("secondary", c(0x635885)), Swatch("secondary-container", c(0xE9DDFF)),
        Swatch("tertiary", c(0xAA3523)), Swatch("tertiary-container", c(0xFFDAD2)),
        Swatch("surface", c(0xFBF8FF)), Swatch("surface-container", c(0xEFEDF4)),
    )

    val neutral = listOf(
        Swatch("white", c(0xFFFFFF)), Swatch("black", c(0x000000)),
        Swatch("none", 0),
    )

    /** Цвета, по кругу выдаваемые новым фигурам. */
    val cycle: IntArray by lazy {
        intArrayOf(Tok.PRIMARY, Tok.TERTIARY_CONTAINER, Tok.PRIMARY_CONTAINER, Tok.TERTIARY, Tok.SECONDARY_CONTAINER, Tok.ERROR).map { baseline[it].argb }.toIntArray()
    }
    fun next(i: Int): Int = cycle[i % cycle.size]

    /** Токены тех же цветов (primary, tertiary-container, primary-container, tertiary, secondary-container, error). */
    val cycleTokens = intArrayOf(Tok.PRIMARY, Tok.TERTIARY_CONTAINER, Tok.PRIMARY_CONTAINER, Tok.TERTIARY, Tok.SECONDARY_CONTAINER, Tok.ERROR)
    fun nextToken(i: Int): Int = cycleTokens[i % cycleTokens.size]
}

/** Токены скругления MD3 для прямоугольников. */
val CornerTokens = listOf(
    "0" to 0f, "XS 4" to 4f, "S 8" to 8f, "M 12" to 12f, "L 16" to 16f,
    "XL 28" to 28f, "XXL 48" to 48f, "Full" to 9999f,
)

/** Типографическая шкала MD3: (название, размер sp). */
val TypeScale = listOf(
    "Label S" to 11f, "Label M" to 12f, "Body M" to 14f, "Body L" to 16f,
    "Title L" to 22f, "Headline S" to 24f, "Headline M" to 28f, "Display S" to 36f,
)
