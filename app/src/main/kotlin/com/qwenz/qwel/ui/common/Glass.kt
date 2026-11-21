package com.qwenz.qwel.ui.common

import androidx.compose.foundation.BorderStroke
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.BlurEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.TileMode
import androidx.compose.ui.graphics.addOutline
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.layer.drawLayer
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.layer.GraphicsLayer
import androidx.compose.ui.graphics.rememberGraphicsLayer
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInRoot
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp

/**
 * Содержимое холста, записанное в графический слой: панели с 'матовым стеклом' размывают именно его.
 * [origin] - положение холста в окне, чтобы совместить координаты панели и холста.
 */
class BackdropSource(val layer: GraphicsLayer) {
    var origin: Offset = Offset.Zero
}

/** Не null - значит, панели редактора рисуются стеклом (Android 12+ и включено в настройках). */
val LocalBackdrop = compositionLocalOf<BackdropSource?> { null }

/** Цвет панели: при стекле - полупрозрачный, чтобы размытый холст просвечивал. Где много текста, [alpha] выше. */
@Composable
fun glassColor(base: Color, alpha: Float = 0.78f): Color = if (LocalBackdrop.current != null) base.copy(alpha = alpha) else base

/** Тень на стекле выглядит грязно (просвечивает через панель), поэтому вместо неё - тонкая рамка. */
@Composable
fun glassElevation(normal: Dp): Dp = if (LocalBackdrop.current != null) 0.dp else normal

@Composable
fun glassBorder(): BorderStroke? =
    if (LocalBackdrop.current != null) BorderStroke(0.6.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.7f)) else null

/**
 * Рисует под панелью размытую копию холста, обрезанную по форме панели. Если стекло выключено - ничего не меняет.
 * Ставится на Surface вместе с [glassColor], [glassElevation] и [glassBorder].
 */
@Composable
fun Modifier.frostedGlass(shape: Shape, radius: Dp = 22.dp): Modifier {
    val src = LocalBackdrop.current
    val blurLayer = rememberGraphicsLayer()
    var pos by remember { mutableStateOf(Offset.Zero) }
    val r = with(LocalDensity.current) { radius.toPx() }
    if (src == null) return this
    return this
        .onGloballyPositioned { pos = it.positionInRoot() }
        .drawBehind {
            val w = size.width.toInt().coerceAtLeast(1)
            val h = size.height.toInt().coerceAtLeast(1)
            blurLayer.renderEffect = BlurEffect(r, r, TileMode.Clamp)
            blurLayer.record(this, layoutDirection, IntSize(w, h)) {
                translate(src.origin.x - pos.x, src.origin.y - pos.y) { drawLayer(src.layer) }
            }
            val outline = Path().apply { addOutline(shape.createOutline(size, layoutDirection, this@drawBehind)) }
            clipPath(outline) { drawLayer(blurLayer) }
        }
}
