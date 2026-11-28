package com.qwenz.qwel.ui.editor

import androidx.compose.foundation.Canvas
import com.qwenz.qwel.data.GlowParams
import com.qwenz.qwel.data.Glow
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.clickable
import androidx.compose.foundation.border
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.unit.dp
import com.qwenz.qwel.data.Echo
import com.qwenz.qwel.data.EchoParams
import com.qwenz.qwel.data.Node
import com.qwenz.qwel.data.boundsOf
import com.qwenz.qwel.i18n.tr
import com.qwenz.qwel.render.blendNodes
import com.qwenz.qwel.render.drawNodes
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/** Рисует [nodes] по центру и по размеру области. */
private fun DrawScope.drawFitted(nodes: List<Node>) {
    val box = boundsOf(nodes) ?: return
    val pad = 14.dp.toPx()
    val s = min((size.width - 2 * pad) / max(box.w, 1f), (size.height - 2 * pad) / max(box.h, 1f))
    translate(size.width / 2f - box.cx * s, size.height / 2f - box.cy * s) {
        scale(s, s, pivot = Offset.Zero) { drawNodes(nodes) }
    }
}

@Composable
private fun PreviewBox(nodes: List<Node>, dark: Boolean = false) {
    Box(Modifier.fillMaxWidth().height(180.dp).clip(RoundedCornerShape(20.dp)).background(if (dark) androidx.compose.ui.graphics.Color(0xFF0B0B10) else MaterialTheme.colorScheme.surfaceContainerHighest)) {
        Canvas(Modifier.fillMaxWidth().height(180.dp)) { drawFitted(nodes) }
    }
}

/** Эхо / дребезг: настройки с живым превью, применяется кнопкой. */
@Composable
fun EchoDialog(state: EditorState, src: Node, onDismiss: () -> Unit) {
    var p by remember { mutableStateOf(EchoParams()) }
    val preview = remember(p, src) { Echo.copies(src, p) + src }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tr("echo")) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                PreviewBox(preview, dark = true)
                LabeledSlider(tr("echo_count"), p.count.toFloat(), 1f..30f, "${p.count}") { p = p.copy(count = it.roundToInt()) }
                LabeledSlider(tr("echo_scale"), p.scaleStep, -15f..15f, "${p.scaleStep.roundToInt()}%") { p = p.copy(scaleStep = it) }
                LabeledSlider(tr("echo_rotate"), p.rotateStep, -30f..30f, "${p.rotateStep.roundToInt()}") { p = p.copy(rotateStep = it) }
                LabeledSlider(tr("echo_fade"), p.fade, 0f..1f, "${(p.fade * 100).roundToInt()}%") { p = p.copy(fade = it) }
                LabeledSlider(tr("echo_spread"), p.spread, -20f..20f, "${p.spread.roundToInt()}") { p = p.copy(spread = it) }
                LabeledSlider(tr("echo_jitter"), p.jitter, 0f..1f, "${(p.jitter * 100).roundToInt()}%") { p = p.copy(jitter = it) }
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text(tr("echo_contour"), Modifier.weight(1f), style = MaterialTheme.typography.bodyMedium)
                    Switch(p.contour, { p = p.copy(contour = it) })
                }
                TextButton({ p = p.copy(seed = (Math.random() * 100000).toInt()) }) { Text(tr("echo_shuffle")) }
            }
        },
        confirmButton = { TextButton({ state.applyEcho(p); onDismiss() }) { Text(tr("apply")) } },
        dismissButton = { TextButton(onDismiss) { Text(tr("cancel")) } },
    )
}

/** Переход между двумя формами: число промежуточных шагов с превью. */
@Composable
fun BlendDialog(state: EditorState, a: Node, b: Node, onDismiss: () -> Unit) {
    var steps by remember { mutableStateOf(5) }
    val mids = remember(steps, a, b) { blendNodes(a, b, steps) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tr("blend")) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                PreviewBox(listOf(a) + mids.orEmpty() + b)
                if (mids == null) Text(tr("effect_failed"), color = MaterialTheme.colorScheme.error)
                LabeledSlider(tr("blend_steps"), steps.toFloat(), 1f..30f, "$steps") { steps = it.roundToInt() }
                Text(tr("blend_note"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        },
        confirmButton = { TextButton({ state.applyBlend(steps); onDismiss() }, enabled = mids != null) { Text(tr("apply")) } },
        dismissButton = { TextButton(onDismiss) { Text(tr("cancel")) } },
    )
}
