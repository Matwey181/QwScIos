package com.qwenz.qwel.ui.common

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.material3.LocalContentColor
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.PathOperation
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** Набор иконок, нарисованных кодом (без зависимости от material-icons). Сетка 24x24. */
enum class Ico {
    Back, Add, Close, Undo, Redo, Layers, Style, Align, Multi, Duplicate, Delete, Lock, Unlock, Eye, EyeOff, More,
    Forward, Backward, Group, Ungroup, Mask, AlignLeft, AlignHCenter, AlignRight, AlignTop, AlignVCenter, AlignBottom,
    DistributeH, DistributeV, SameWidth, SameHeight, Grid, Guides, Export, Edit, Settings, Text, Rect, Ellipse,
    Shapes, Check, Fit, Select, Components,
    Search, List, Import,
    Font, FontSize, Fill, Stroke, Opacity, Corner,
    Image, Bool, BoolUnion, BoolDiff, BoolIntersect, BoolExclude, BoolCombine, BoolDivide, BoolFlatten,
    Pipette, Screens, Code, Gradient, Shadow, Blur, Play, Stop,
}

@Composable
fun QIcon(ico: Ico, modifier: Modifier = Modifier, tint: Color = LocalContentColor.current, size: Dp = 24.dp) {
    Canvas(modifier.size(size)) { paintIcon(ico, tint) }
}

private fun DrawScope.paintIcon(ico: Ico, color: Color) {
    val u = size.width / 24f
    val st = Stroke(width = 2f * u, cap = StrokeCap.Round, join = StrokeJoin.Round)
    fun ln(a: Float, b: Float, c: Float, d: Float) =
        drawLine(color, Offset(a * u, b * u), Offset(c * u, d * u), strokeWidth = 2f * u, cap = StrokeCap.Round)
    fun rc(x: Float, y: Float, w: Float, h: Float, r: Float = 1.5f, fill: Boolean = false) =
        drawRoundRect(color, Offset(x * u, y * u), Size(w * u, h * u), CornerRadius(r * u), style = if (fill) Fill else st)
    fun cr(x: Float, y: Float, r: Float, fill: Boolean = false) =
        drawCircle(color, r * u, Offset(x * u, y * u), style = if (fill) Fill else st)
    fun pth(fill: Boolean = false, build: Path.(Float) -> Unit) {
        val p = Path(); p.build(u); drawPath(p, color, style = if (fill) Fill else st)
    }
    fun Path.m(u: Float, x: Float, y: Float) = moveTo(x * u, y * u)
    fun Path.l(u: Float, x: Float, y: Float) = lineTo(x * u, y * u)
    fun Path.c(u: Float, a: Float, b: Float, c: Float, d: Float, e: Float, f: Float) =
        cubicTo(a * u, b * u, c * u, d * u, e * u, f * u)

    when (ico) {
        Ico.Play -> pth(true) { u -> m(u, 8f, 5f); l(u, 19f, 12f); l(u, 8f, 19f); close() }
        Ico.Stop -> rc(6f, 6f, 12f, 12f, 2.5f, true)
        Ico.Back -> { ln(19f, 12f, 5f, 12f); ln(11f, 6f, 5f, 12f); ln(11f, 18f, 5f, 12f) }
        Ico.Add -> { ln(12f, 5f, 12f, 19f); ln(5f, 12f, 19f, 12f) }
        Ico.Close -> { ln(6f, 6f, 18f, 18f); ln(18f, 6f, 6f, 18f) }
        Ico.Undo -> {
            ln(5f, 12f, 9f, 8f); ln(5f, 12f, 9f, 16f)
            pth { u -> m(u, 6f, 12f); l(u, 13f, 12f); c(u, 17f, 12f, 19f, 14.5f, 19f, 18f) }
        }
        Ico.Redo -> {
            ln(19f, 12f, 15f, 8f); ln(19f, 12f, 15f, 16f)
            pth { u -> m(u, 18f, 12f); l(u, 11f, 12f); c(u, 7f, 12f, 5f, 14.5f, 5f, 18f) }
        }
        Ico.Layers -> {
            pth { u -> m(u, 12f, 4f); l(u, 21f, 9f); l(u, 12f, 14f); l(u, 3f, 9f); close() }
            pth { u -> m(u, 3f, 13f); l(u, 12f, 18f); l(u, 21f, 13f) }
        }
        Ico.Style -> {
            ln(4f, 7f, 20f, 7f); ln(4f, 12f, 20f, 12f); ln(4f, 17f, 20f, 17f)
            cr(8f, 7f, 2.3f, true); cr(16f, 12f, 2.3f, true); cr(10f, 17f, 2.3f, true)
        }
        Ico.Align -> { ln(4f, 3f, 4f, 21f); rc(7f, 6f, 13f, 4f); rc(7f, 14f, 8f, 4f) }
        Ico.Multi -> { rc(3.5f, 3.5f, 12f, 12f, 3f); rc(9f, 9f, 11.5f, 11.5f, 3f) }
        Ico.Duplicate -> {
            rc(9f, 9f, 11f, 11f, 2.5f)
            pth { u -> m(u, 5f, 15f); l(u, 5f, 6f); c(u, 5f, 4.8f, 5.8f, 4f, 7f, 4f); l(u, 15f, 4f) }
        }
        Ico.Delete -> {
            ln(4f, 7f, 20f, 7f)
            pth { u -> m(u, 9f, 7f); l(u, 9f, 4.5f); l(u, 15f, 4.5f); l(u, 15f, 7f) }
            pth { u -> m(u, 6.5f, 7f); l(u, 7.5f, 19.5f); l(u, 16.5f, 19.5f); l(u, 17.5f, 7f) }
            ln(10f, 11f, 10f, 16f); ln(14f, 11f, 14f, 16f)
        }
        Ico.Lock -> {
            rc(5.5f, 11f, 13f, 9f, 2.5f)
            pth { u -> m(u, 8f, 11f); l(u, 8f, 8f); c(u, 8f, 2.5f, 16f, 2.5f, 16f, 8f); l(u, 16f, 11f) }
        }
        Ico.Unlock -> {
            rc(5.5f, 11f, 13f, 9f, 2.5f)
            pth { u -> m(u, 8f, 11f); l(u, 8f, 8f); c(u, 8f, 2.5f, 16f, 2.5f, 16f, 6.5f) }
        }
        Ico.Eye -> {
            pth { u -> m(u, 2f, 12f); c(u, 5f, 6f, 19f, 6f, 22f, 12f); c(u, 19f, 18f, 5f, 18f, 2f, 12f); close() }
            cr(12f, 12f, 3f)
        }
        Ico.EyeOff -> {
            pth { u -> m(u, 2f, 12f); c(u, 5f, 6f, 19f, 6f, 22f, 12f); c(u, 19f, 18f, 5f, 18f, 2f, 12f); close() }
            cr(12f, 12f, 3f); ln(4f, 4f, 20f, 20f)
        }
        Ico.More -> { cr(12f, 5f, 1.9f, true); cr(12f, 12f, 1.9f, true); cr(12f, 19f, 1.9f, true) }
        Ico.Forward -> { ln(12f, 19f, 12f, 6f); ln(6.5f, 11f, 12f, 5.5f); ln(17.5f, 11f, 12f, 5.5f); ln(6f, 21f, 18f, 21f) }
        Ico.Backward -> { ln(12f, 5f, 12f, 18f); ln(6.5f, 13f, 12f, 18.5f); ln(17.5f, 13f, 12f, 18.5f); ln(6f, 3f, 18f, 3f) }
        Ico.Mask -> { rc(3f, 3f, 18f, 18f, 3f); cr(12f, 12f, 5f, true) }
        Ico.Group -> { rc(3f, 3f, 18f, 18f, 3f); rc(7f, 7f, 4f, 4f, 1f); rc(13f, 13f, 4f, 4f, 1f) }
        Ico.Ungroup -> { rc(3f, 3f, 8f, 8f, 2f); rc(13f, 13f, 8f, 8f, 2f) }
        Ico.AlignLeft -> { ln(4f, 3f, 4f, 21f); rc(7f, 6f, 13f, 4f); rc(7f, 14f, 8f, 4f) }
        Ico.AlignHCenter -> { ln(12f, 3f, 12f, 21f); rc(5f, 6f, 14f, 4f); rc(8f, 14f, 8f, 4f) }
        Ico.AlignRight -> { ln(20f, 3f, 20f, 21f); rc(4f, 6f, 13f, 4f); rc(9f, 14f, 8f, 4f) }
        Ico.AlignTop -> { ln(3f, 4f, 21f, 4f); rc(6f, 7f, 4f, 13f); rc(14f, 7f, 4f, 8f) }
        Ico.AlignVCenter -> { ln(3f, 12f, 21f, 12f); rc(6f, 5f, 4f, 14f); rc(14f, 8f, 4f, 8f) }
        Ico.AlignBottom -> { ln(3f, 20f, 21f, 20f); rc(6f, 4f, 4f, 13f); rc(14f, 9f, 4f, 8f) }
        Ico.DistributeH -> { ln(4f, 3f, 4f, 21f); ln(20f, 3f, 20f, 21f); rc(9.5f, 7f, 5f, 10f) }
        Ico.DistributeV -> { ln(3f, 4f, 21f, 4f); ln(3f, 20f, 21f, 20f); rc(7f, 9.5f, 10f, 5f) }
        Ico.SameWidth -> { rc(3f, 4f, 18f, 5f); rc(3f, 15f, 18f, 5f); ln(12f, 10.5f, 12f, 13.5f) }
        Ico.SameHeight -> { rc(4f, 3f, 5f, 18f); rc(15f, 3f, 5f, 18f); ln(10.5f, 12f, 13.5f, 12f) }
        Ico.Grid -> { rc(4f, 4f, 16f, 16f, 2f); ln(9.3f, 4f, 9.3f, 20f); ln(14.7f, 4f, 14.7f, 20f); ln(4f, 9.3f, 20f, 9.3f); ln(4f, 14.7f, 20f, 14.7f) }
        Ico.Guides -> { ln(12f, 3f, 12f, 8f); ln(12f, 16f, 12f, 21f); ln(3f, 12f, 8f, 12f); ln(16f, 12f, 21f, 12f); cr(12f, 12f, 2.5f, true) }
        Ico.Export -> {
            pth { u -> m(u, 5f, 13f); l(u, 5f, 19f); l(u, 19f, 19f); l(u, 19f, 13f) }
            ln(12f, 15f, 12f, 4f); ln(8f, 8f, 12f, 4f); ln(16f, 8f, 12f, 4f)
        }
        Ico.Edit -> {
            pth { u -> m(u, 4f, 20f); l(u, 5f, 15f); l(u, 16f, 4f); l(u, 20f, 8f); l(u, 9f, 19f); close() }
            ln(14f, 6f, 18f, 10f)
        }
        Ico.Settings -> { ln(4f, 7f, 20f, 7f); ln(4f, 17f, 20f, 17f); cr(9f, 7f, 2.6f, true); cr(15f, 17f, 2.6f, true) }
        Ico.Text -> { ln(5f, 6f, 19f, 6f); ln(12f, 6f, 12f, 19f); ln(9f, 19f, 15f, 19f) }
        Ico.Rect -> rc(4f, 6f, 16f, 12f, 3f)
        Ico.Ellipse -> cr(12f, 12f, 8f)
        Ico.Shapes -> {
            pth { u -> m(u, 7f, 3.5f); l(u, 11.5f, 11f); l(u, 2.5f, 11f); close() }
            cr(16.5f, 7.5f, 4f); rc(3.5f, 14f, 7f, 7f, 2f)
            pth { u -> m(u, 14f, 20f); c(u, 14f, 16f, 20f, 16f, 20f, 20f); close() }
        }
        Ico.Check -> pth { u -> m(u, 5f, 12.5f); l(u, 10f, 17.5f); l(u, 19f, 7f) }
        Ico.Fit -> {
            pth { u -> m(u, 4f, 9f); l(u, 4f, 4f); l(u, 9f, 4f) }
            pth { u -> m(u, 15f, 4f); l(u, 20f, 4f); l(u, 20f, 9f) }
            pth { u -> m(u, 20f, 15f); l(u, 20f, 20f); l(u, 15f, 20f) }
            pth { u -> m(u, 9f, 20f); l(u, 4f, 20f); l(u, 4f, 15f) }
        }
        Ico.Select -> pth { u -> m(u, 5f, 3f); l(u, 19f, 12f); l(u, 12f, 13.5f); l(u, 9f, 20f); close() }
        Ico.Search -> { cr(10.5f, 10.5f, 6f); ln(15f, 15f, 20f, 20f) }
        Ico.List -> { ln(4f, 6f, 20f, 6f); ln(4f, 12f, 20f, 12f); ln(4f, 18f, 20f, 18f) }
        Ico.Import -> {
            pth { u -> m(u, 5f, 13f); l(u, 5f, 19f); l(u, 19f, 19f); l(u, 19f, 13f) }
            ln(12f, 4f, 12f, 15f); ln(8f, 11f, 12f, 15f); ln(16f, 11f, 12f, 15f)
        }
        Ico.Font -> { ln(3f, 19f, 8.5f, 5f); ln(8.5f, 5f, 14f, 19f); ln(5.2f, 14f, 11.8f, 14f); cr(18f, 16f, 2.8f); ln(20.8f, 13f, 20.8f, 19f) }
        Ico.FontSize -> { ln(2.5f, 19f, 7.5f, 6f); ln(7.5f, 6f, 12.5f, 19f); ln(4.5f, 14f, 10.5f, 14f); ln(15.5f, 9f, 21.5f, 9f); ln(18.5f, 6f, 18.5f, 12f); ln(15.5f, 18f, 21.5f, 18f) }
        Ico.Fill -> pth(true) { u -> m(u, 12f, 3f); c(u, 12f, 3f, 5f, 10.5f, 5f, 15f); c(u, 5f, 18.9f, 8.1f, 21f, 12f, 21f); c(u, 15.9f, 21f, 19f, 18.9f, 19f, 15f); c(u, 19f, 10.5f, 12f, 3f, 12f, 3f); close() }
        Ico.Pipette -> { ln(5f, 19f, 13f, 11f); ln(10f, 6f, 18f, 14f); ln(14f, 4f, 20f, 10f); ln(4f, 20f, 6f, 18f) }
        Ico.Screens -> {
            pth { u -> m(u, 3f, 7f); l(u, 14f, 7f); l(u, 14f, 20f); l(u, 3f, 20f); close() }
            pth { u -> m(u, 9f, 4f); l(u, 20f, 4f); l(u, 20f, 17f); l(u, 17f, 17f) }
        }
        Ico.Code -> { ln(8f, 7f, 3f, 12f); ln(3f, 12f, 8f, 17f); ln(16f, 7f, 21f, 12f); ln(21f, 12f, 16f, 17f); ln(14f, 5f, 10f, 19f) }
        Ico.Gradient -> {
            pth { u -> m(u, 4f, 4f); l(u, 20f, 4f); l(u, 20f, 20f); l(u, 4f, 20f); close() }
            ln(4f, 14f, 14f, 4f); ln(10f, 20f, 20f, 10f)
        }
        Ico.Shadow -> {
            pth { u -> m(u, 4f, 4f); l(u, 15f, 4f); l(u, 15f, 15f); l(u, 4f, 15f); close() }
            ln(19f, 8f, 19f, 19f); ln(19f, 19f, 8f, 19f)
        }
        Ico.Blur -> { ln(4f, 8f, 20f, 8f); ln(6f, 12f, 18f, 12f); ln(8f, 16f, 16f, 16f) }
        Ico.Opacity -> {
            pth { u -> m(u, 12f, 3f); c(u, 12f, 3f, 5f, 10.5f, 5f, 15f); c(u, 5f, 18.9f, 8.1f, 21f, 12f, 21f); c(u, 15.9f, 21f, 19f, 18.9f, 19f, 15f); c(u, 19f, 10.5f, 12f, 3f, 12f, 3f); close() }
            ln(8f, 15f, 16f, 15f)
        }
        Ico.Stroke -> drawCircle(
            color, 8f * u, Offset(12f * u, 12f * u),
            style = Stroke(2f * u, cap = StrokeCap.Round, pathEffect = PathEffect.dashPathEffect(floatArrayOf(3f * u, 3.4f * u))),
        )
        Ico.Corner -> pth { u -> m(u, 4f, 20f); l(u, 4f, 12f); c(u, 4f, 7.6f, 7.6f, 4f, 12f, 4f); l(u, 20f, 4f) }
        Ico.Image -> {
            rc(3f, 4f, 18f, 16f, 3f); cr(9f, 10f, 2f, true)
            pth { u -> m(u, 4f, 18f); l(u, 10f, 13f); l(u, 14f, 17f); l(u, 17f, 14f); l(u, 20f, 17f) }
        }
        Ico.Bool -> { rc(3f, 3f, 12f, 12f, 2.5f); rc(9f, 9f, 12f, 12f, 2.5f) }
        Ico.BoolUnion, Ico.BoolDiff, Ico.BoolIntersect, Ico.BoolExclude -> {
            val a = Path().apply { addRoundRect(RoundRect(3f * u, 3f * u, 15f * u, 15f * u, CornerRadius(2.5f * u))) }
            val b = Path().apply { addOval(Rect(9f * u, 9f * u, 21f * u, 21f * u)) }
            val op = when (ico) {
                Ico.BoolUnion -> PathOperation.Union
                Ico.BoolDiff -> PathOperation.Difference
                Ico.BoolIntersect -> PathOperation.Intersect
                else -> PathOperation.Xor
            }
            drawPath(Path.combine(op, a, b), color)
            drawPath(a, color.copy(alpha = 0.55f), style = Stroke(1.2f * u))
            drawPath(b, color.copy(alpha = 0.55f), style = Stroke(1.2f * u))
        }
        Ico.BoolCombine -> { rc(3f, 3f, 9f, 9f, 2f, true); cr(16.5f, 16.5f, 4.5f, true); ln(10f, 10f, 14f, 14f) }
        Ico.BoolDivide -> {
            val a = Path().apply { addRoundRect(RoundRect(3f * u, 3f * u, 15f * u, 15f * u, CornerRadius(2.5f * u))) }
            val b = Path().apply { addOval(Rect(9f * u, 9f * u, 21f * u, 21f * u)) }
            drawPath(Path.combine(PathOperation.Difference, a, b), color)
            drawPath(Path.combine(PathOperation.Difference, b, a), color)
            drawPath(Path.combine(PathOperation.Intersect, a, b), color.copy(alpha = 0.45f))
        }
        Ico.BoolFlatten -> { rc(3f, 3f, 12f, 12f, 2.5f); rc(9f, 9f, 12f, 12f, 2.5f, true) }
        Ico.Components -> { rc(3f, 3f, 8f, 8f, 2f); rc(13f, 3f, 8f, 8f, 4f); cr(7f, 17f, 4f); rc(13f, 13f, 8f, 8f, 1f) }
    }
}
