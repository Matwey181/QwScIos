package com.qwenz.qwel.render

import android.graphics.BlurMaskFilter
import android.graphics.Paint
import android.graphics.Typeface
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.ClipOp
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.asAndroidPath
import androidx.compose.ui.graphics.asComposePath
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.nativeCanvas
import androidx.graphics.shapes.Cubic
import com.qwenz.qwel.data.Node
import com.qwenz.qwel.data.NodeKind
import com.qwenz.qwel.data.Project
import com.qwenz.qwel.data.TextMetrics
import com.qwenz.qwel.data.rotate as rotateXY
import com.qwenz.qwel.shapes.ShapeLibrary
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

fun typefaceFor(weight: Int, font: String = ""): Typeface = Fonts.typeface(font, weight)

/** Подключает реальное измерение текста для авто-размера текстовых слоёв. */
fun installTextMetrics() {
    val measure = Paint(Paint.ANTI_ALIAS_FLAG)
    TextMetrics.widthOf = { text, size, weight, font ->
        synchronized(measure) {
            measure.textSize = size; measure.typeface = typefaceFor(weight, font)
            measure.measureText(text)
        }
    }
}

/** Один Paint на отрисовку текста: рисование идёт в одном потоке, а создавать его на каждый слой в каждом кадре дорого. */
private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)

/** Контуры встроенных фигур в единичном квадрате: строятся один раз, дальше только масштабируются при рисовании. */
private val unitPaths = HashMap<String, Path>()
private fun unitPath(id: String, cubics: List<Cubic>): Path =
    unitPaths.getOrPut(id) { cubics.appendTo(Path(), 0f, 0f, 1f, 1f) }

private fun withOpacity(argb: Int, opacity: Float): Color = Color(argb).let { it.copy(alpha = it.alpha * opacity) }

/** Градиент слоя в координатах документа: линейный под углом (по всей длине слоя вдоль угла) или радиальный от центра. */
fun gradientBrush(n: Node): Brush {
    val c1 = Color(n.fill); val c2 = Color(n.fill2)
    if (n.gradKind == 2) {
        return Brush.radialGradient(listOf(c1, c2), center = Offset(n.cx, n.cy), radius = max(max(n.w, n.h) / 2f, 1f))
    }
    val a = Math.toRadians(n.gradAngle.toDouble())
    val dx = cos(a).toFloat(); val dy = sin(a).toFloat()
    val half = max((abs(dx) * n.w + abs(dy) * n.h) / 2f, 1f)
    return Brush.linearGradient(listOf(c1, c2), start = Offset(n.cx - dx * half, n.cy - dy * half), end = Offset(n.cx + dx * half, n.cy + dy * half))
}

private val shadowPaint = Paint(Paint.ANTI_ALIAS_FLAG)

/**
 * Тень/свечение слоя. Рисуется только снаружи контура: через полупрозрачную заливку ('стекло') тень не просвечивает.
 * Размытие - BlurMaskFilter; на аппаратном канвасе ниже Android 9 оно не работает, поэтому там тень не рисуется
 * (в PNG и SVG она есть всегда).
 */
private fun DrawScope.drawShadow(n: Node, op: Float, shapeCubics: List<Cubic>?) {
    val hard = drawContext.canvas.nativeCanvas.isHardwareAccelerated
    if (hard && android.os.Build.VERSION.SDK_INT < 28) return
    val outline = nodeOutline(n, shapeCubics)
    // смещение задано в осях листа, а мы внутри поворота слоя
    val (dx, dy) = rotateXY(n.shadowDx, n.shadowDy, -n.rotation)
    val c = Color(n.shadowColor).let { it.copy(alpha = it.alpha * op) }
    clipPath(outline, ClipOp.Difference) {
        shadowPaint.color = android.graphics.Color.argb((c.alpha * 255f).toInt().coerceIn(0, 255), (c.red * 255f).toInt(), (c.green * 255f).toInt(), (c.blue * 255f).toInt())
        shadowPaint.maskFilter = BlurMaskFilter(max(n.shadowBlur, 0.5f), BlurMaskFilter.Blur.NORMAL)
        val canvas = drawContext.canvas.nativeCanvas
        canvas.save()
        canvas.translate(dx, dy)
        canvas.drawPath(outline.asAndroidPath(), shadowPaint)
        canvas.restore()
    }
}

private val softPaint = Paint(Paint.ANTI_ALIAS_FLAG)

/** Размытие слоя делается BlurMaskFilter, как у тени: на аппаратном канвасе ниже Android 9 оно не работает. */
private fun softBlurSupported(scope: DrawScope): Boolean =
    !(scope.drawContext.canvas.nativeCanvas.isHardwareAccelerated && android.os.Build.VERSION.SDK_INT < 28)

/** Слой с размытием самой формы: размывается контур вместе с заливкой, обводкой и градиентом. */
private fun DrawScope.drawSoft(n: Node, op: Float, shapeCubics: List<Cubic>?) {
    val canvas = drawContext.canvas.nativeCanvas
    val sigma = max(n.softBlur, 0.5f)
    val hasFill = (n.fill ushr 24) != 0
    val hasStroke = (n.stroke ushr 24) != 0 && n.strokeWidth > 0f
    softPaint.reset()
    softPaint.isAntiAlias = true
    softPaint.maskFilter = BlurMaskFilter(sigma, BlurMaskFilter.Blur.NORMAL)
    if (n.kind == NodeKind.TEXT) {
        if (!hasFill) return
        softPaint.textSize = n.fontSize
        softPaint.typeface = typefaceFor(n.weight, n.font)
        softPaint.color = n.fill
        softPaint.alpha = (((n.fill ushr 24) and 0xFF) * op).toInt().coerceIn(0, 255)
        val fm = softPaint.fontMetrics
        val lineH = n.fontSize * 1.25f
        for ((i, line) in n.text.split('\n').withIndex()) {
            canvas.drawText(line, n.x, n.y + (i + 0.5f) * lineH - (fm.ascent + fm.descent) / 2f, softPaint)
        }
        return
    }
    val path = nodeOutline(n, shapeCubics).asAndroidPath()
    if (n.hasGradient) {
        val c1 = n.fill; val c2 = n.fill2
        softPaint.shader = if (n.gradKind == 2) {
            android.graphics.RadialGradient(n.cx, n.cy, max(max(n.w, n.h) / 2f, 1f), c1, c2, android.graphics.Shader.TileMode.CLAMP)
        } else {
            val a = Math.toRadians(n.gradAngle.toDouble())
            val dx = cos(a).toFloat(); val dy = sin(a).toFloat()
            val half = max((abs(dx) * n.w + abs(dy) * n.h) / 2f, 1f)
            android.graphics.LinearGradient(n.cx - dx * half, n.cy - dy * half, n.cx + dx * half, n.cy + dy * half, c1, c2, android.graphics.Shader.TileMode.CLAMP)
        }
        softPaint.alpha = (op * 255f).toInt().coerceIn(0, 255)
        canvas.drawPath(path, softPaint)
    } else if (hasFill) {
        softPaint.color = n.fill
        softPaint.alpha = (((n.fill ushr 24) and 0xFF) * op).toInt().coerceIn(0, 255)
        canvas.drawPath(path, softPaint)
    }
    if (hasStroke) {
        softPaint.shader = null
        softPaint.style = Paint.Style.STROKE
        softPaint.strokeWidth = n.strokeWidth
        softPaint.color = n.stroke
        softPaint.alpha = (((n.stroke ushr 24) and 0xFF) * op).toInt().coerceIn(0, 255)
        canvas.drawPath(path, softPaint)
    }
}

/**
 * Рисует один слой в координатах документа.
 * [shapeCubics] - подмена контура (для анимации морфинга).
 */
fun DrawScope.drawNode(n: Node, shapeCubics: List<Cubic>? = null, backdrop: Backdrop? = null, index: Int = -1) {
    if (!n.visible) return
    val op = n.opacity.coerceIn(0f, 1f)
    val hasFill = (n.fill ushr 24) != 0
    val hasStroke = (n.stroke ushr 24) != 0 && n.strokeWidth > 0f
    rotate(n.rotation, pivot = Offset(n.cx, n.cy)) {
        if (n.hasShadow && op > 0.01f) drawShadow(n, op, shapeCubics)
        // 'матовое стекло': сначала размытый фон под слоем, поверх - обычная (обычно полупрозрачная) заливка
        if (n.blur > 0.5f && op > 0.01f && backdrop != null && index >= 0) {
            backdrop.drawBlurred(this, index, n, nodeOutline(n, shapeCubics))
        }
        if (n.softBlur > 0.5f && op > 0.01f && softBlurSupported(this) && n.kind != NodeKind.IMAGE) {
            drawSoft(n, op, shapeCubics)
        } else when (n.kind) {
            NodeKind.RECT -> {
                val r = min(n.corner, min(n.w, n.h) / 2f)
                if (n.hasGradient) drawRoundRect(gradientBrush(n), Offset(n.x, n.y), Size(n.w, n.h), CornerRadius(r), alpha = op)
                else if (hasFill) drawRoundRect(withOpacity(n.fill, op), Offset(n.x, n.y), Size(n.w, n.h), CornerRadius(r))
                if (hasStroke) drawRoundRect(
                    withOpacity(n.stroke, op), Offset(n.x, n.y), Size(n.w, n.h), CornerRadius(r),
                    style = Stroke(n.strokeWidth),
                )
            }
            NodeKind.ELLIPSE -> {
                if (n.hasGradient) drawOval(gradientBrush(n), Offset(n.x, n.y), Size(n.w, n.h), alpha = op)
                else if (hasFill) drawOval(withOpacity(n.fill, op), Offset(n.x, n.y), Size(n.w, n.h))
                if (hasStroke) drawOval(withOpacity(n.stroke, op), Offset(n.x, n.y), Size(n.w, n.h), style = Stroke(n.strokeWidth))
            }
            NodeKind.SHAPE -> {
                val cubics = shapeCubics ?: ShapeLibrary.get(n.shapeId)?.cubics
                if (cubics != null) {
                    if (n.hasGradient) {
                        drawPath(cubics.appendTo(Path(), n.x, n.y, n.w, n.h), gradientBrush(n), alpha = op)
                    } else if (hasFill) {
                        if (shapeCubics == null) {
                            val unit = unitPath(n.shapeId, cubics)
                            translate(n.x, n.y) { scale(n.w, n.h, pivot = Offset.Zero) { drawPath(unit, withOpacity(n.fill, op)) } }
                        } else drawPath(cubics.appendTo(Path(), n.x, n.y, n.w, n.h), withOpacity(n.fill, op))
                    }
                    if (hasStroke) drawPath(cubics.appendTo(Path(), n.x, n.y, n.w, n.h), withOpacity(n.stroke, op), style = Stroke(n.strokeWidth))
                }
            }
            NodeKind.TEXT -> drawNodeText(n, op)
            NodeKind.PATH -> if (n.path.isNotEmpty()) {
                if (!n.hasGradient && !hasStroke) {
                    // самый частый случай (иконки): готовый контур единичного квадрата, без пересборки пути каждый кадр
                    if (hasFill) translate(n.x, n.y) { scale(n.w, n.h, pivot = Offset.Zero) { drawPath(n.unitPath(), withOpacity(n.fill, op)) } }
                    return@rotate
                }
                val path = n.composePath()
                if (n.hasGradient) drawPath(path, gradientBrush(n), alpha = op)
                else if (hasFill) drawPath(path, withOpacity(n.fill, op))
                if (hasStroke) drawPath(path, withOpacity(n.stroke, op), style = Stroke(n.strokeWidth))
            }
            NodeKind.IMAGE -> {
                val bmp = Assets.bitmap(n.asset)
                if (bmp != null && bmp.width > 0 && bmp.height > 0) {
                    translate(n.x, n.y) {
                        scale(n.w / bmp.width, n.h / bmp.height, pivot = Offset.Zero) { drawImage(bmp, alpha = op) }
                    }
                } else {
                    drawRect(Color(0x33888888), Offset(n.x, n.y), Size(n.w, n.h))
                }
            }
        }
    }
}

private fun DrawScope.drawNodeText(n: Node, opacity: Float) {
    if ((n.fill ushr 24) == 0) return
    val paint = textPaint
    paint.textSize = n.fontSize
    paint.typeface = typefaceFor(n.weight, n.font)
    paint.color = n.fill
    paint.alpha = (((n.fill ushr 24) and 0xFF) * opacity).toInt().coerceIn(0, 255)
    val fm = paint.fontMetrics
    val lineH = n.fontSize * 1.25f
    val lines = n.text.split('\n')
    val canvas = drawContext.canvas.nativeCanvas
    for ((i, line) in lines.withIndex()) {
        val baseline = n.y + (i + 0.5f) * lineH - (fm.ascent + fm.descent) / 2f
        canvas.drawText(line, n.x, baseline, paint)
    }
}

/**
 * Рисует слои снизу вверх. Слой-маска сам не рисуется: он обрезает только слой, лежащий прямо под ним
 * (следующий в списке ниже), - например картинка в форме звезды.
 */
fun DrawScope.drawNodes(nodes: List<Node>, override: (Node) -> List<Cubic>? = { null }, backdrop: Backdrop? = null) {
    // то, что целиком за пределами видимой области, не рисуем (при увеличении на большом проекте это большая часть слоёв)
    val clip = runCatching { drawContext.canvas.nativeCanvas.clipBounds }.getOrNull()?.takeIf { !it.isEmpty }
    for ((i, n) in nodes.withIndex()) {
        if (n.isMask) continue
        if (clip != null && outside(n, clip)) continue
        val cubics = if (n.kind == NodeKind.SHAPE) override(n) else null
        val m = nodes.getOrNull(i + 1)?.takeIf { it.isMask && it.visible }
        if (m == null) drawNode(n, cubics, backdrop, i)
        else drawMasked(m, if (m.kind == NodeKind.SHAPE) override(m) else null) { drawNode(n, cubics, backdrop, i) }
    }
}

/** Слой точно не попадает в [clip] (в координатах документа). Берём запас на тень, размытие и обводку; текст не отсекаем. */
private fun outside(n: Node, clip: android.graphics.Rect): Boolean {
    if (n.kind == NodeKind.TEXT) return false
    var r = kotlin.math.hypot(abs(n.w), abs(n.h)) / 2f + n.strokeWidth + 4f
    if (n.hasShadow) r += n.shadowBlur * 2f + kotlin.math.hypot(n.shadowDx, n.shadowDy)
    if (n.softBlur > 0f) r += n.softBlur * 3f
    if (n.blur > 0f) r += 8f
    return n.cx + r < clip.left || n.cx - r > clip.right || n.cy + r < clip.top || n.cy - r > clip.bottom
}

/** Контур слоя с учётом его поворота - в координатах документа. */
fun rotatedOutline(n: Node, shapeCubics: List<Cubic>? = null): Path {
    val p = nodeOutline(n, shapeCubics)
    if (n.rotation == 0f) return p
    val ap = android.graphics.Path(p.asAndroidPath())
    ap.transform(android.graphics.Matrix().apply { setRotate(n.rotation, n.cx, n.cy) })
    return ap.asComposePath()
}

/** Отдельный слой с содержимым, из которого форма маски оставляет только своё внутри: края гладкие на любом Android. */
private fun DrawScope.drawMasked(mask: Node, maskCubics: List<Cubic>?, content: DrawScope.() -> Unit) {
    val path = rotatedOutline(mask, maskCubics)
    val bounds = path.getBounds().inflate(2f)
    val canvas = drawContext.canvas
    // Слой 1 - содержимое. Слой 2 (форма маски) при склейке работает как DstIn по всей рамке: где формы нет, содержимое стирается.
    // Просто рисовать форму с DstIn нельзя: режим действует только там, где рисуют, и снаружи формы ничего бы не обрезалось.
    canvas.saveLayer(bounds, androidx.compose.ui.graphics.Paint())
    content()
    canvas.saveLayer(bounds, androidx.compose.ui.graphics.Paint().apply { blendMode = BlendMode.DstIn })
    drawPath(path, Color.Black)
    canvas.restore()
    canvas.restore()
}

/** Контур слоя в координатах документа (без поворота) - по нему обрезается размытый фон. */
fun nodeOutline(n: Node, shapeCubics: List<Cubic>? = null): Path {
    fun rect() = Path().apply { addRect(Rect(n.x, n.y, n.x + n.w, n.y + n.h)) }
    return when (n.kind) {
        NodeKind.RECT -> Path().apply {
            val r = min(n.corner, min(n.w, n.h) / 2f)
            addRoundRect(RoundRect(n.x, n.y, n.x + n.w, n.y + n.h, CornerRadius(r)))
        }
        NodeKind.ELLIPSE -> Path().apply { addOval(Rect(n.x, n.y, n.x + n.w, n.y + n.h)) }
        NodeKind.SHAPE -> (shapeCubics ?: ShapeLibrary.get(n.shapeId)?.cubics)?.appendTo(Path(), n.x, n.y, n.w, n.h) ?: rect()
        NodeKind.PATH -> if (n.path.isNotEmpty()) n.composePath() else rect()
        else -> rect()
    }
}

/** Превью проекта целиком, вписанное в текущий размер DrawScope (карточки проектов). */
fun DrawScope.drawProjectFit(p: Project, inset: Float = 0f) {
    val s = min((size.width - 2 * inset) / p.width, (size.height - 2 * inset) / p.height)
    val ox = (size.width - p.width * s) / 2f
    val oy = (size.height - p.height * s) / 2f
    translate(ox, oy) {
        scale(s, s, pivot = Offset.Zero) {
            drawRect(Color(p.background), size = Size(p.width, p.height))
            clipRect(0f, 0f, p.width, p.height) { drawNodes(p.nodes) }
        }
    }
}
