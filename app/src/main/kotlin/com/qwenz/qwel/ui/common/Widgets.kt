package com.qwenz.qwel.ui.common

import com.qwenz.qwel.i18n.tr

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.LocalIndication
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.qwenz.qwel.data.DesignPalette
import com.qwenz.qwel.data.Tone
import com.qwenz.qwel.ui.theme.Motion
import java.util.Locale
import kotlin.math.abs
import kotlin.math.roundToInt

/** Иконка-кнопка с 'живой' формой: круг -> скруглённый квадрат при выборе, ещё круче при нажатии. */
@Composable
fun QIconButton(
    ico: Ico,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    label: String? = null,
    selected: Boolean = false,
    enabled: Boolean = true,
    tonal: Boolean = false,
    size: Dp = 48.dp,
) {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val corner by animateDpAsState(
        targetValue = if (pressed) 10.dp else if (selected) 16.dp else size / 2,
        animationSpec = Motion.spatial(), label = "corner",
    )
    val scheme = MaterialTheme.colorScheme
    val container by animateColorAsState(
        when {
            selected -> scheme.secondaryContainer
            tonal -> scheme.surfaceContainerHighest
            else -> Color.Transparent
        }, label = "container",
    )
    val content = if (selected) scheme.onSecondaryContainer else scheme.onSurfaceVariant
    Box(
        modifier
            .size(size)
            .clip(RoundedCornerShape(corner))
            .background(container)
            .clickable(
                interactionSource = source, indication = LocalIndication.current,
                enabled = enabled, role = Role.Button, onClick = onClick,
            )
            .semantics { if (label != null) contentDescription = label },
        contentAlignment = Alignment.Center,
    ) {
        QIcon(ico, tint = if (enabled) content else content.copy(alpha = 0.38f))
    }
}

@Composable
fun SectionTitle(text: String, modifier: Modifier = Modifier) {
    Text(
        text, modifier.padding(top = 4.dp, bottom = 8.dp),
        style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

private fun fmt(v: Float): String =
    if (abs(v - v.roundToInt()) < 0.005f) v.roundToInt().toString() else String.format(Locale.US, "%.1f", v)

/** Числовое поле: значение применяется по 'Готово' или при потере фокуса. */
@Composable
fun NumberField(label: String, value: Float, onCommit: (Float) -> Unit, modifier: Modifier = Modifier) {
    var text by remember(value) { mutableStateOf(fmt(value)) }
    val focus = LocalFocusManager.current
    fun commit() {
        val v = text.replace(',', '.').toFloatOrNull()
        if (v != null && abs(v - value) > 0.001f) onCommit(v) else text = fmt(value)
    }
    OutlinedTextField(
        value = text, onValueChange = { text = it },
        label = { Text(label) }, singleLine = true,
        modifier = modifier.onFocusChanged { if (!it.isFocused) commit() },
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal, imeAction = ImeAction.Done),
        keyboardActions = KeyboardActions(onDone = { commit(); focus.clearFocus() }),
        shape = RoundedCornerShape(16.dp),
        textStyle = MaterialTheme.typography.bodyMedium,
    )
}

/**
 * Ряд цветов тона проекта + нейтральные + 'свой цвет'.
 * Цвет из тона выдаётся с токеном (слой будет следовать тону), остальные - с token = -1.
 */
@Composable
fun ColorRow(
    title: String, color: Int, tone: Tone, token: Int = -1, modifier: Modifier = Modifier,
    onEyedropper: (() -> Unit)? = null,
    onPick: (argb: Int, token: Int) -> Unit,
) {
    var picker by remember { mutableStateOf(false) }
    val outline = MaterialTheme.colorScheme.outlineVariant
    val primary = MaterialTheme.colorScheme.primary
    Column(modifier) {
        SectionTitle(title)
        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
            item {
                Box(
                    Modifier.size(40.dp).clip(CircleShape)
                        .border(BorderStroke(1.dp, MaterialTheme.colorScheme.outline), CircleShape)
                        .clickable { picker = true }.semantics { contentDescription = tr("custom_color") },
                    contentAlignment = Alignment.Center,
                ) { QIcon(Ico.Fill, size = 22.dp, tint = primary) }
            }
            if (onEyedropper != null) item {
                Box(
                    Modifier.size(40.dp).clip(CircleShape)
                        .border(BorderStroke(1.dp, MaterialTheme.colorScheme.outline), CircleShape)
                        .clickable { onEyedropper() }.semantics { contentDescription = tr("eyedropper") },
                    contentAlignment = Alignment.Center,
                ) { QIcon(Ico.Pipette, size = 22.dp, tint = primary) }
            }
            itemsIndexed(DesignPalette.baseline) { i, sw ->
                val argb = tone.color(i, sw.argb)
                val selected = token == i
                Box(
                    Modifier.size(40.dp).clip(CircleShape).background(Color(argb))
                        .border(BorderStroke(if (selected) 3.dp else 1.dp, if (selected) primary else outline), CircleShape)
                        .clickable { onPick(argb, i) }
                        .semantics { contentDescription = sw.name },
                )
            }
            items(DesignPalette.neutral) { s ->
                val selected = token < 0 && s.argb == color
                Box(
                    Modifier.size(40.dp).clip(CircleShape)
                        .background(if (s.argb == 0) Color.Transparent else Color(s.argb))
                        .border(BorderStroke(if (selected) 3.dp else 1.dp, if (selected) primary else outline), CircleShape)
                        .clickable { onPick(s.argb, -1) }
                        .semantics { contentDescription = s.name },
                ) {
                    if (s.argb == 0) Canvas(Modifier.size(40.dp)) {
                        drawLine(Color(0xFFB3261E), Offset(size.width * 0.2f, size.height * 0.8f), Offset(size.width * 0.8f, size.height * 0.2f), 4f)
                    }
                }
            }
        }
    }
    if (picker) ColorPickerDialog(color, onDismiss = { picker = false }, onConfirm = { onPick(it, -1); picker = false })
}

private fun hexOf(argb: Int): String = String.format(Locale.US, "%08X", argb)

@Composable
fun ColorPickerDialog(initial: Int, onDismiss: () -> Unit, onConfirm: (Int) -> Unit) {
    val init = remember { FloatArray(3).also { android.graphics.Color.colorToHSV(initial, it) } }
    var hue by remember { mutableFloatStateOf(init[0]) }
    var sat by remember { mutableFloatStateOf(init[1]) }
    var value by remember { mutableFloatStateOf(init[2]) }
    var alpha by remember { mutableFloatStateOf(if (initial == 0) 1f else (initial ushr 24) / 255f) }
    val argb = android.graphics.Color.HSVToColor((alpha * 255).roundToInt(), floatArrayOf(hue, sat, value))
    var hexText by remember { mutableStateOf(hexOf(argb)) }
    LaunchedEffect(argb) { hexText = hexOf(argb) }
    val hueColor = Color(android.graphics.Color.HSVToColor(floatArrayOf(hue, 1f, 1f)))

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tr("color")) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Canvas(
                    Modifier.fillMaxWidth().height(180.dp).clip(RoundedCornerShape(16.dp))
                        .pointerInput(Unit) {
                            detectTapGestures { p ->
                                sat = (p.x / size.width).coerceIn(0f, 1f); value = 1f - (p.y / size.height).coerceIn(0f, 1f)
                            }
                        }
                        .pointerInput(Unit) {
                            detectDragGestures(onDragStart = { p ->
                                sat = (p.x / size.width).coerceIn(0f, 1f); value = 1f - (p.y / size.height).coerceIn(0f, 1f)
                            }) { change, _ ->
                                sat = (change.position.x / size.width).coerceIn(0f, 1f)
                                value = 1f - (change.position.y / size.height).coerceIn(0f, 1f)
                            }
                        },
                ) {
                    drawRect(Brush.horizontalGradient(listOf(Color.White, hueColor)))
                    drawRect(Brush.verticalGradient(listOf(Color.Transparent, Color.Black)))
                    val c = Offset(sat * size.width, (1f - value) * size.height)
                    drawCircle(Color.White, 14f, c, style = androidx.compose.ui.graphics.drawscope.Stroke(4f))
                    drawCircle(Color.Black, 16f, c, style = androidx.compose.ui.graphics.drawscope.Stroke(1.5f))
                }
                Text(tr("tone"), style = MaterialTheme.typography.labelMedium)
                Slider(hue, { hue = it }, valueRange = 0f..360f)
                Text(tr("opacity"), style = MaterialTheme.typography.labelMedium)
                Slider(alpha, { alpha = it }, valueRange = 0f..1f)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Box(Modifier.size(48.dp).clip(CircleShape).background(Color(argb)).border(1.dp, MaterialTheme.colorScheme.outlineVariant, CircleShape))
                    OutlinedTextField(
                        value = hexText, onValueChange = { t ->
                            hexText = t.uppercase().filter { it in "0123456789ABCDEF" }.take(8)
                            val parsed = when (hexText.length) {
                                6 -> hexText.toLongOrNull(16)?.let { (0xFF000000 or it).toInt() }
                                8 -> hexText.toLongOrNull(16)?.toInt()
                                else -> null
                            }
                            if (parsed != null) {
                                val hsv = FloatArray(3); android.graphics.Color.colorToHSV(parsed, hsv)
                                hue = hsv[0]; sat = hsv[1]; value = hsv[2]; alpha = (parsed ushr 24) / 255f
                            }
                        },
                        label = { Text("HEX (AARRGGBB)") }, singleLine = true, shape = RoundedCornerShape(16.dp),
                        modifier = Modifier.weightFill(),
                    )
                }
            }
        },
        confirmButton = { TextButton({ onConfirm(argb) }) { Text(tr("done")) } },
        dismissButton = { TextButton(onDismiss) { Text(tr("cancel")) } },
    )
}

private fun Modifier.weightFill(): Modifier = this.width(190.dp)
