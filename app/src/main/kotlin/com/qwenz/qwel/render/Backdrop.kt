package com.qwenz.qwel.render

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlurEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.TileMode
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.layer.drawLayer
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.layer.GraphicsLayer
import androidx.compose.ui.unit.IntSize
import androidx.graphics.shapes.Cubic
import com.qwenz.qwel.data.Node
import kotlin.math.ceil

/** Сколько слоёв с размытием фона одновременно показывается в редакторе (остальные рисуются без размытия). */
const val MAX_BLUR_LAYERS = 8

/**
 * Источник размытого 'фона под слоем'. [drawBlurred] вызывается из drawNode внутри поворота слоя
 * и должен нарисовать размытое содержимое всего, что лежит ниже слоя [index], обрезанное по [outline].
 */
interface Backdrop {
    fun drawBlurred(scope: DrawScope, index: Int, node: Node, outline: Path)
}

/**
 * Живое размытие в редакторе (Android 12+): всё, что лежит ниже слоя, записывается в GraphicsLayer
 * с RenderEffect-размытием и рисуется внутри контура слоя. Слой графики - по одному на размытый слой.
 */
class LayerBackdrop(
    private val layers: List<GraphicsLayer>,
    private val nodes: List<Node>,
    private val override: (Node) -> List<Cubic>?,
    private val background: Color,
    private val width: Float,
    private val height: Float,
) : Backdrop {
    private val assigned = HashMap<Int, GraphicsLayer>()

    override fun drawBlurred(scope: DrawScope, index: Int, node: Node, outline: Path) {
        val layer = assigned.getOrPut(index) { layers.getOrNull(assigned.size) ?: return }
        val size = IntSize(ceil(width).toInt().coerceAtLeast(1), ceil(height).toInt().coerceAtLeast(1))
        with(scope) {
            layer.renderEffect = BlurEffect(node.blur, node.blur, TileMode.Clamp)
            // запись идёт в координатах документа, поэтому размытие масштабируется вместе с листом
            layer.record(this, layoutDirection, size) {
                drawRect(background, Offset.Zero, Size(width, height))
                drawNodes(nodes.subList(0, index), override, this@LayerBackdrop)
            }
            clipPath(outline) {
                // drawNode уже повернул систему координат вместе со слоем, а записанный фон - не повёрнутый
                rotate(-node.rotation, Offset(node.cx, node.cy)) { drawLayer(layer) }
            }
        }
    }
}
