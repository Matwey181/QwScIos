package com.qwenz.qwel.ui.theme

import android.os.Build
import androidx.compose.animation.core.FiniteAnimationSpec
import androidx.compose.animation.core.spring
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.text.font.FontFamily
import com.qwenz.qwel.render.Fonts
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Режим темы: 0 - как в системе, 1 - акцентная светлая, 2 - акцентная тёмная, 3 - AMOLED, 4 - AMOLED светлая. */
fun isDarkMode(mode: Int, system: Boolean): Boolean = when (mode) { 1, 4 -> false; 2, 3 -> true; else -> system }

/** Акцент: 0 - Vexel, 1 - динамический, 2 - свой цвет [seed]. Для AMOLED режимов (3, 4) поверхности заменяются на чистые. */
@Composable
fun QwelTheme(themeMode: Int, accent: Int, seed: Int, uiFont: String, content: @Composable () -> Unit) {
    val dark = isDarkMode(themeMode, isSystemInDarkTheme())
    val context = LocalContext.current
    val accented = when {
        accent == 1 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
            if (dark) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        accent == 2 -> remember(seed, dark) { schemeFromSeed(seed, dark) }
        dark -> QwelDark
        else -> QwelLight
    }
    val scheme = if (themeMode == 3 || themeMode == 4) amoledSurfaces(accented, dark) else accented
    val typography = remember(context, uiFont) { qwelTypography(if (uiFont.isEmpty()) null else Fonts.uiFamily(uiFont)) }
    MaterialTheme(
        colorScheme = scheme,
        typography = typography,
        shapes = QwelShapes,
        content = content,
    )
}

val QwelShapes = Shapes(
    extraSmall = RoundedCornerShape(4.dp),
    small = RoundedCornerShape(8.dp),
    medium = RoundedCornerShape(12.dp),
    large = RoundedCornerShape(16.dp),
    extraLarge = RoundedCornerShape(28.dp),
)

/** Дополнительные токены скругления MD3 Expressive. */
object Corners {
    val LargeIncreased = RoundedCornerShape(20.dp)
    val ExtraLargeIncreased = RoundedCornerShape(32.dp)
    val ExtraExtraLarge = RoundedCornerShape(48.dp)
    val SheetTop = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp)
}

private val base = Typography()

/**
 * Expressive-типографика: крупные заголовки плотнее и жирнее, акцентные стили - Medium/Bold.
 * [family] - шрифт интерфейса (Figtree из assets/fonts); null - системный. Кириллицу Figtree не содержит,
 * её Android автоматически дорисовывает системным шрифтом.
 */
fun qwelTypography(family: FontFamily?): Typography {
    val t = if (family == null) base else Typography(
        displayLarge = base.displayLarge.copy(fontFamily = family), displayMedium = base.displayMedium.copy(fontFamily = family),
        displaySmall = base.displaySmall.copy(fontFamily = family), headlineLarge = base.headlineLarge.copy(fontFamily = family),
        headlineMedium = base.headlineMedium.copy(fontFamily = family), headlineSmall = base.headlineSmall.copy(fontFamily = family),
        titleLarge = base.titleLarge.copy(fontFamily = family), titleMedium = base.titleMedium.copy(fontFamily = family),
        titleSmall = base.titleSmall.copy(fontFamily = family), bodyLarge = base.bodyLarge.copy(fontFamily = family),
        bodyMedium = base.bodyMedium.copy(fontFamily = family), bodySmall = base.bodySmall.copy(fontFamily = family),
        labelLarge = base.labelLarge.copy(fontFamily = family), labelMedium = base.labelMedium.copy(fontFamily = family),
        labelSmall = base.labelSmall.copy(fontFamily = family),
    )
    return t.copy(
        displayMedium = t.displayMedium.copy(fontWeight = FontWeight.Bold, letterSpacing = (-0.5).sp),
        displaySmall = t.displaySmall.copy(fontWeight = FontWeight.Bold, letterSpacing = (-0.25).sp),
        headlineMedium = t.headlineMedium.copy(fontWeight = FontWeight.SemiBold),
        headlineSmall = t.headlineSmall.copy(fontWeight = FontWeight.SemiBold),
        titleLarge = t.titleLarge.copy(fontWeight = FontWeight.SemiBold),
        titleMedium = t.titleMedium.copy(fontWeight = FontWeight.SemiBold),
        labelLarge = t.labelLarge.copy(fontWeight = FontWeight.SemiBold),
    )
}

/** Пружины в духе MD3 Expressive: spatial - с лёгким перелётом, effects - без. */
object Motion {
    fun <T> spatial(): FiniteAnimationSpec<T> = spring(dampingRatio = 0.6f, stiffness = 380f)
    fun <T> spatialSlow(): FiniteAnimationSpec<T> = spring(dampingRatio = 0.7f, stiffness = 200f)
    fun <T> effects(): FiniteAnimationSpec<T> = spring(dampingRatio = 1f, stiffness = 1600f)
}
