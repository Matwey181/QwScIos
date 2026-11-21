package com.qwenz.qwel.render

import android.graphics.Bitmap
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Canvas
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.graphics.drawscope.CanvasDrawScope
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import com.qwenz.qwel.data.Node
import com.qwenz.qwel.data.NodeKind
import com.qwenz.qwel.data.Project
import com.qwenz.qwel.shapes.ShapeLibrary
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.util.Locale
import kotlin.math.max
import kotlin.math.min

/** PNG проекта в масштабе [factor] (1 = 1 ед. документа на пиксель). */
fun renderPng(p: Project, factor: Float = 2f): ByteArray {
    val w = (p.width * factor).toInt().coerceIn(1, 8192)
    val h = (p.height * factor).toInt().coerceIn(1, 8192)
    val bitmap = renderUpTo(p, p.nodes.size, w, h)
    val out = ByteArrayOutputStream()
    bitmap.asAndroidBitmap().compress(Bitmap.CompressFormat.PNG, 100, out)
    return out.toByteArray()
}

/** Небольшая картинка проекта для карточек и окна экспорта: то же, что уйдёт в PNG, включая размытие. */
fun renderPreview(p: Project, maxSide: Int): ImageBitmap {
    val k = maxSide / max(p.width, p.height)
    return renderUpTo(p, p.nodes.size, (p.width * k).toInt().coerceAtLeast(1), (p.height * k).toInt().coerceAtLeast(1))
}

/**
 * Рисует фон и первые [count] слоёв проекта в битмап [w]x[h]. Размытие фона считается на процессоре
 * (гауссиана по уже нарисованному ниже), поэтому в PNG оно есть на любой версии Android.
 */
private fun renderUpTo(p: Project, count: Int, w: Int, h: Int): ImageBitmap {
    val bitmap = ImageBitmap(w, h)
    val canvas = Canvas(bitmap)
    val sx = w / p.width
    val sy = h / p.height
    val hasBlur = p.nodes.take(count).any { it.visible && it.blur > 0.5f }
    val backdrop = if (!hasBlur) null else object : Backdrop {
        override fun drawBlurred(scope: DrawScope, index: Int, node: Node, outline: Path) {
            val below = renderUpTo(p, index, w, h)
            val blurred = blurImage(below, node.blur * (sx + sy) / 2f)
            with(scope) {
                clipPath(outline) {
                    rotate(-node.rotation, Offset(node.cx, node.cy)) {
                        scale(1f / sx, 1f / sy, pivot = Offset.Zero) { drawImage(blurred) }
                    }
                }
            }
        }
    }
    CanvasDrawScope().draw(Density(1f), LayoutDirection.Ltr, canvas, Size(w.toFloat(), h.toFloat())) {
        drawRect(Color(p.background))
        scale(sx, sy, pivot = Offset.Zero) { drawNodes(p.nodes.subList(0, count), backdrop = backdrop) }
    }
    return bitmap
}

private fun blurImage(img: ImageBitmap, sigma: Float): ImageBitmap {
    if (sigma < 0.5f) return img
    val src = img.asAndroidBitmap()
    val w = src.width
    val h = src.height
    val px = IntArray(w * h)
    src.getPixels(px, 0, w, 0, 0, w, h)
    val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
    out.setPixels(gaussianBlurArgb(px, w, h, sigma), 0, w, 0, 0, w, h)
    return out.asImageBitmap()
}

private fun f(v: Float): String = String.format(Locale.US, "%.2f", v).trimEnd('0').trimEnd('.').ifEmpty { "0" }

private fun hex(argb: Int): String = String.format(Locale.US, "#%06X", argb and 0xFFFFFF)

private fun alpha(argb: Int, opacity: Float): Float = ((argb ushr 24) and 0xFF) / 255f * opacity

private fun esc(s: String) = s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")

private fun paintAttrs(n: Node): String {
    val sb = StringBuilder()
    if (n.hasGradient) sb.append(" fill=\"url(#g_").append(n.id).append(")\"")
    else if ((n.fill ushr 24) == 0) sb.append(" fill=\"none\"")
    else {
        sb.append(" fill=\"").append(hex(n.fill)).append('"')
        val a = alpha(n.fill, n.opacity)
        if (a < 0.999f) sb.append(" fill-opacity=\"").append(f(a)).append('"')
    }
    if ((n.stroke ushr 24) != 0 && n.strokeWidth > 0f) {
        sb.append(" stroke=\"").append(hex(n.stroke)).append("\" stroke-width=\"").append(f(n.strokeWidth)).append('"')
        val a = alpha(n.stroke, n.opacity)
        if (a < 0.999f) sb.append(" stroke-opacity=\"").append(f(a)).append('"')
    }
    if (n.hasShadow || n.softBlur > 0.5f) sb.append(" filter=\"url(#s_").append(n.id).append(")\"")
    return sb.toString()
}

/** Градиенты и тени слоёв: <defs> для SVG. */
private fun svgDefs(nodes: List<Node>): String {
    val sb = StringBuilder()
    for (n in nodes) {
        if (!n.visible) continue
        if (n.hasGradient) {
            val a1 = f(alpha(n.fill, n.opacity)); val a2 = f(alpha(n.fill2, n.opacity))
            val stops = "<stop offset=\"0\" stop-color=\"${hex(n.fill)}\" stop-opacity=\"$a1\"/>" +
                "<stop offset=\"1\" stop-color=\"${hex(n.fill2)}\" stop-opacity=\"$a2\"/>"
            if (n.gradKind == 2) {
                sb.append("    <radialGradient id=\"g_${n.id}\" gradientUnits=\"userSpaceOnUse\" cx=\"${f(n.cx)}\" cy=\"${f(n.cy)}\" r=\"${f(maxOf(n.w, n.h) / 2f)}\">")
            } else {
                val rad = Math.toRadians(n.gradAngle.toDouble())
                val dx = Math.cos(rad).toFloat(); val dy = Math.sin(rad).toFloat()
                val half = (Math.abs(dx) * n.w + Math.abs(dy) * n.h) / 2f
                sb.append("    <linearGradient id=\"g_${n.id}\" gradientUnits=\"userSpaceOnUse\" x1=\"${f(n.cx - dx * half)}\" y1=\"${f(n.cy - dy * half)}\" x2=\"${f(n.cx + dx * half)}\" y2=\"${f(n.cy + dy * half)}\">")
            }
            sb.append(stops).append(if (n.gradKind == 2) "</radialGradient>\n" else "</linearGradient>\n")
        }
        if (n.softBlur > 0.5f) {
            sb.append("    <filter id=\"s_${n.id}\" x=\"-100%\" y=\"-100%\" width=\"300%\" height=\"300%\">")
                .append("<feGaussianBlur stdDeviation=\"${f(n.softBlur * 0.58f)}\"/>")
            if (n.hasShadow) sb.append("<feDropShadow dx=\"${f(n.shadowDx)}\" dy=\"${f(n.shadowDy)}\" stdDeviation=\"${f(n.shadowBlur / 2f)}\" flood-color=\"${hex(n.shadowColor)}\" flood-opacity=\"${f(alpha(n.shadowColor, n.opacity))}\"/>")
            sb.append("</filter>\n")
        } else if (n.hasShadow) {
            sb.append("    <filter id=\"s_${n.id}\" x=\"-60%\" y=\"-60%\" width=\"220%\" height=\"220%\">")
                .append("<feDropShadow dx=\"${f(n.shadowDx)}\" dy=\"${f(n.shadowDy)}\" stdDeviation=\"${f(n.shadowBlur / 2f)}\" ")
                .append("flood-color=\"${hex(n.shadowColor)}\" flood-opacity=\"${f(alpha(n.shadowColor, n.opacity))}\"/></filter>\n")
        }
    }
    return sb.toString()
}

/** <clipPath> для каждой маски: форма маски с её поворотом. */
private fun svgMaskDefs(nodes: List<Node>): String {
    val sb = StringBuilder()
    for ((i, m) in nodes.withIndex()) {
        if (!m.isMask || !m.visible || i == 0) continue
        sb.append("    <clipPath id=\"m_${m.id}\">")
        when (m.kind) {
            NodeKind.RECT -> sb.append("<rect x=\"${f(m.x)}\" y=\"${f(m.y)}\" width=\"${f(m.w)}\" height=\"${f(m.h)}\" rx=\"${f(min(m.corner, min(m.w, m.h) / 2f))}\"${transform(m)}/>")
            NodeKind.ELLIPSE -> sb.append("<ellipse cx=\"${f(m.cx)}\" cy=\"${f(m.cy)}\" rx=\"${f(m.w / 2)}\" ry=\"${f(m.h / 2)}\"${transform(m)}/>")
            NodeKind.SHAPE -> {
                val cubics = ShapeLibrary.get(m.shapeId)?.cubics.orEmpty()
                val d = StringBuilder()
                if (cubics.isNotEmpty()) {
                    d.append("M").append(f(m.x + cubics[0].anchor0X * m.w)).append(' ').append(f(m.y + cubics[0].anchor0Y * m.h))
                    for (c in cubics) {
                        d.append(" C ")
                            .append(f(m.x + c.control0X * m.w)).append(' ').append(f(m.y + c.control0Y * m.h)).append(", ")
                            .append(f(m.x + c.control1X * m.w)).append(' ').append(f(m.y + c.control1Y * m.h)).append(", ")
                            .append(f(m.x + c.anchor1X * m.w)).append(' ').append(f(m.y + c.anchor1Y * m.h))
                    }
                    d.append(" Z")
                }
                sb.append("<path d=\"$d\"${transform(m)}/>")
            }
            else -> sb.append("<path d=\"${svgPathData(m)}\"${if (m.evenOdd) " clip-rule=\"evenodd\"" else ""}${transform(m)}/>")
        }
        sb.append("</clipPath>\n")
    }
    return sb.toString()
}

private fun transform(n: Node): String =
    if (n.rotation == 0f) "" else " transform=\"rotate(${f(n.rotation)} ${f(n.cx)} ${f(n.cy)})\""

/** Чистый SVG: прямоугольники, эллипсы, <path> для фигур MD3, <text> для текста. */
fun toSvg(p: Project): String {
    val sb = StringBuilder()
    sb.append("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"${f(p.width)}\" height=\"${f(p.height)}\" viewBox=\"0 0 ${f(p.width)} ${f(p.height)}\">\n")
    sb.append("  <title>${esc(p.name)}</title>\n")
    val usedFonts = p.nodes.filter { it.visible && it.kind == NodeKind.TEXT && it.font.isNotEmpty() }
        .map { it.font to it.weight }.distinct()
    val faces = StringBuilder()
    val written = HashSet<String>()
    for ((fnt, weight) in usedFonts) {
        val (bytes, mime, faceWeight) = Fonts.embedData(fnt, weight) ?: continue
        // встроенные семейства - по файлу на вес; импортированные - один файл на все веса
        val id = fnt + "/" + (faceWeight ?: 0)
        if (!written.add(id)) continue
        faces.append("    @font-face { font-family: '${esc(Fonts.displayName(fnt))}';")
        if (faceWeight != null) faces.append(" font-weight: $faceWeight;")
        faces.append(" src: url(data:$mime;base64,").append(Base64.encodeToString(bytes, Base64.NO_WRAP)).append("); }\n")
    }
    if (faces.isNotEmpty()) sb.append("  <defs><style>\n").append(faces).append("  </style></defs>\n")
    val defs = svgDefs(p.nodes) + svgMaskDefs(p.nodes)
    if (defs.isNotEmpty()) sb.append("  <defs>\n").append(defs).append("  </defs>\n")
    if ((p.background ushr 24) != 0)
        sb.append("  <rect width=\"${f(p.width)}\" height=\"${f(p.height)}\" fill=\"${hex(p.background)}\"/>\n")
    for ((idx, n) in p.nodes.withIndex()) {
        if (!n.visible || n.isMask) continue
        // слой под маской заворачивается в <g clip-path>
        val masked = p.nodes.getOrNull(idx + 1)?.takeIf { it.isMask && it.visible }
        sb.append("  ")
        if (masked != null) sb.append("<g clip-path=\"url(#m_${masked.id})\">")
        when (n.kind) {
            NodeKind.RECT -> {
                val r = min(n.corner, min(n.w, n.h) / 2f)
                sb.append("<rect x=\"${f(n.x)}\" y=\"${f(n.y)}\" width=\"${f(n.w)}\" height=\"${f(n.h)}\" rx=\"${f(r)}\"")
                    .append(paintAttrs(n)).append(transform(n)).append("/>")
            }
            NodeKind.ELLIPSE -> {
                sb.append("<ellipse cx=\"${f(n.cx)}\" cy=\"${f(n.cy)}\" rx=\"${f(n.w / 2)}\" ry=\"${f(n.h / 2)}\"")
                    .append(paintAttrs(n)).append(transform(n)).append("/>")
            }
            NodeKind.SHAPE -> {
                val cubics = ShapeLibrary.get(n.shapeId)?.cubics.orEmpty()
                val d = StringBuilder()
                if (cubics.isNotEmpty()) {
                    d.append("M").append(f(n.x + cubics[0].anchor0X * n.w)).append(' ').append(f(n.y + cubics[0].anchor0Y * n.h))
                    for (c in cubics) {
                        d.append(" C ")
                            .append(f(n.x + c.control0X * n.w)).append(' ').append(f(n.y + c.control0Y * n.h)).append(", ")
                            .append(f(n.x + c.control1X * n.w)).append(' ').append(f(n.y + c.control1Y * n.h)).append(", ")
                            .append(f(n.x + c.anchor1X * n.w)).append(' ').append(f(n.y + c.anchor1Y * n.h))
                    }
                    d.append(" Z")
                }
                sb.append("<path d=\"$d\"").append(paintAttrs(n)).append(transform(n)).append("/>")
            }
            NodeKind.PATH -> {
                sb.append("<path d=\"${svgPathData(n)}\"").append(paintAttrs(n))
                    .append(if (n.evenOdd) " fill-rule=\"evenodd\"" else "").append(transform(n)).append("/>")
            }
            NodeKind.IMAGE -> {
                val bytes = Assets.bytes(n.asset)
                if (bytes != null) {
                    sb.append("<image x=\"${f(n.x)}\" y=\"${f(n.y)}\" width=\"${f(n.w)}\" height=\"${f(n.h)}\" preserveAspectRatio=\"none\"")
                        .append(if (n.opacity < 0.999f) " opacity=\"${f(n.opacity)}\"" else "")
                        .append(transform(n)).append(" href=\"data:${Assets.mime(n.asset)};base64,")
                        .append(Base64.encodeToString(bytes, Base64.NO_WRAP)).append("\"/>")
                }
            }
            NodeKind.TEXT -> {
                val lh = n.fontSize * 1.25f
                val family = if (n.font.isNotEmpty()) "'${esc(Fonts.displayName(n.font))}', Roboto, sans-serif" else "Roboto, sans-serif"
                sb.append("<text font-family=\"$family\" font-size=\"${f(n.fontSize)}\" font-weight=\"${n.weight}\"")
                    .append(paintAttrs(n)).append(transform(n)).append(">")
                for ((i, line) in n.text.split('\n').withIndex()) {
                    sb.append("<tspan x=\"${f(n.x)}\" y=\"${f(n.y + (i + 0.5f) * lh)}\" dominant-baseline=\"central\">${esc(line)}</tspan>")
                }
                sb.append("</text>")
            }
        }
        if (masked != null) sb.append("</g>")
        sb.append('\n')
    }
    sb.append("</svg>\n")
    return sb.toString()
}
