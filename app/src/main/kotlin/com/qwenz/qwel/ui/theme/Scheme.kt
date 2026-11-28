package com.qwenz.qwel.ui.theme

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.graphics.lerp
import com.qwenz.qwel.data.Tok
import com.qwenz.qwel.data.ToneGen

private fun on(c: Color) = if (c.luminance() > 0.4f) Color(0xFF101414) else Color.White

/** Схема интерфейса из одного своего цвета: те же тональные палитры, что у тона проекта ([ToneGen]). */
fun schemeFromSeed(seed: Int, dark: Boolean): ColorScheme {
    val t = ToneGen.scheme(seed, dark).map { Color(it) }
    val other = ToneGen.scheme(seed, !dark).map { Color(it) }
    val base = if (dark) darkColorScheme() else lightColorScheme()
    val surface = t[Tok.SURFACE]
    return base.copy(
        primary = t[Tok.PRIMARY], onPrimary = t[Tok.ON_PRIMARY],
        primaryContainer = t[Tok.PRIMARY_CONTAINER], onPrimaryContainer = t[Tok.ON_PRIMARY_CONTAINER],
        secondary = t[Tok.SECONDARY], onSecondary = on(t[Tok.SECONDARY]),
        secondaryContainer = t[Tok.SECONDARY_CONTAINER], onSecondaryContainer = t[Tok.ON_SECONDARY_CONTAINER],
        tertiary = t[Tok.TERTIARY], onTertiary = on(t[Tok.TERTIARY]),
        tertiaryContainer = t[Tok.TERTIARY_CONTAINER], onTertiaryContainer = t[Tok.ON_TERTIARY_CONTAINER],
        error = t[Tok.ERROR], onError = on(t[Tok.ERROR]),
        errorContainer = t[Tok.ERROR_CONTAINER], onErrorContainer = on(t[Tok.ERROR_CONTAINER]),
        background = surface, onBackground = t[Tok.ON_SURFACE],
        surface = surface, onSurface = t[Tok.ON_SURFACE],
        surfaceVariant = t[Tok.SURFACE_HIGH], onSurfaceVariant = t[Tok.ON_SURFACE_VARIANT],
        outline = t[Tok.OUTLINE], outlineVariant = t[Tok.OUTLINE_VARIANT],
        inverseSurface = t[Tok.INVERSE_SURFACE], inverseOnSurface = surface, inversePrimary = other[Tok.PRIMARY],
        surfaceTint = t[Tok.PRIMARY],
        surfaceDim = if (dark) surface else t[Tok.SURFACE_HIGHEST],
        surfaceBright = if (dark) t[Tok.SURFACE_HIGHEST] else surface,
        surfaceContainerLowest = if (dark) lerp(surface, Color.Black, 0.4f) else Color.White,
        surfaceContainerLow = t[Tok.SURFACE_LOW], surfaceContainer = t[Tok.SURFACE_CONTAINER],
        surfaceContainerHigh = t[Tok.SURFACE_HIGH], surfaceContainerHighest = t[Tok.SURFACE_HIGHEST],
    )
}

/** AMOLED: чёрные (тёмная) или белые (светлая) поверхности, акцентные цвета остаются от выбранной схемы. */
fun amoledSurfaces(s: ColorScheme, dark: Boolean): ColorScheme = if (dark) s.copy(
    background = Color.Black, surface = Color.Black, surfaceDim = Color.Black, surfaceContainerLowest = Color.Black,
    surfaceContainerLow = Color(0xFF0B0B0B), surfaceContainer = Color(0xFF121212), surfaceContainerHigh = Color(0xFF1A1A1A),
    surfaceContainerHighest = Color(0xFF232323), surfaceBright = Color(0xFF2A2A2A),
    surfaceVariant = Color(0xFF1F1F1F), outlineVariant = Color(0xFF333333),
) else s.copy(
    background = Color.White, surface = Color.White, surfaceBright = Color.White, surfaceContainerLowest = Color.White,
    surfaceDim = Color(0xFFE6E6E6), surfaceContainerLow = Color(0xFFF7F7F7), surfaceContainer = Color(0xFFF1F1F1),
    surfaceContainerHigh = Color(0xFFEBEBEB), surfaceContainerHighest = Color(0xFFE5E5E5),
    surfaceVariant = Color(0xFFEDEDED),
)
