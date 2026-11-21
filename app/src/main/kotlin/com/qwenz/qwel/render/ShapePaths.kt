package com.qwenz.qwel.render

import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import androidx.graphics.shapes.Cubic

/** Дописывает контур из кубических кривых единичного квадрата в [path], масштабируя в (x, y, w, h). */
fun List<Cubic>.appendTo(path: Path, x: Float, y: Float, w: Float, h: Float): Path {
    if (isEmpty()) return path
    path.moveTo(x + first().anchor0X * w, y + first().anchor0Y * h)
    for (c in this) {
        path.cubicTo(
            x + c.control0X * w, y + c.control0Y * h,
            x + c.control1X * w, y + c.control1Y * h,
            x + c.anchor1X * w, y + c.anchor1Y * h,
        )
    }
    path.close()
    return path
}

/** Compose Shape из кривых - для clip/background (кнопки, превью). */
class CubicsShape(private val cubics: List<Cubic>) : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline =
        Outline.Generic(cubics.appendTo(Path(), 0f, 0f, size.width, size.height))
}
