package com.qwenz.qwel.ui.editor

import com.qwenz.qwel.i18n.tr
import com.qwenz.qwel.ui.common.frostedGlass
import com.qwenz.qwel.ui.common.glassBorder
import com.qwenz.qwel.ui.common.glassElevation
import com.qwenz.qwel.ui.common.glassColor

import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.qwenz.qwel.data.Node
import com.qwenz.qwel.data.NodeKind
import com.qwenz.qwel.render.BoolOp
import com.qwenz.qwel.ui.common.Ico
import com.qwenz.qwel.ui.common.QIcon
import com.qwenz.qwel.ui.common.QIconButton
import com.qwenz.qwel.ui.theme.Motion

private enum class QuickTool { FONT, SIZE, WEIGHT, SHAPE, CORNER, FILL, STROKE, OPACITY, GRADIENT, SHADOW, BLUR }

/**
 * Панель над выделением. Свёрнутая - пилюля с основными кнопками; тяните её вверх (или нажмите на ручку) -
 * раскроется большая панель инструментов выбранного слоя: шрифт, размер, цвет, обводка и т. д.
 */
@Composable
fun SelectionDock(
    state: EditorState,
    expanded: Boolean,
    onExpanded: (Boolean) -> Unit,
    onEditText: (String) -> Unit,
    onOpenPanel: (Panel) -> Unit,
) {
    val drag = Modifier.pointerInput(expanded) {
        val threshold = 24.dp.toPx()
        var total = 0f
        detectVerticalDragGestures(
            onDragStart = { total = 0f },
            onDragEnd = { if (total < -threshold) onExpanded(true) else if (total > threshold) onExpanded(false) },
            onDragCancel = {},
        ) { _, dy -> total += dy }
    }
    Column(
        Modifier.animateContentSize(Motion.spatial()),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        DockHandle(drag) { onExpanded(!expanded) }
        if (expanded) ExpandedDock(state, onEditText, onOpenPanel, onExpanded)
        else PillBar(state, drag)
    }
}

@Composable
private fun DockHandle(drag: Modifier, onClick: () -> Unit) {
    Row(
        Modifier.then(drag).clip(CircleShape).clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 7.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Box(Modifier.width(28.dp).size(width = 28.dp, height = 4.dp).clip(CircleShape).background(MaterialTheme.colorScheme.outline))
        Text(tr("dock_tools"), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

/** Меню булевых операций (как в графических редакторах). */
@Composable
fun BoolMenu(state: EditorState, open: Boolean, onDismiss: () -> Unit) {
    val context = LocalContext.current
    DropdownMenu(expanded = open, onDismissRequest = onDismiss) {
        val count = state.selectedNodes().count { it.visible }
        val groups = listOf(
            listOf(BoolOp.UNION to Ico.BoolUnion, BoolOp.DIFFERENCE to Ico.BoolDiff,
                BoolOp.INTERSECT to Ico.BoolIntersect, BoolOp.EXCLUDE to Ico.BoolExclude),
            listOf(BoolOp.COMBINE to Ico.BoolCombine, BoolOp.DIVIDE to Ico.BoolDivide, BoolOp.FLATTEN to Ico.BoolFlatten),
        )
        for ((gi, group) in groups.withIndex()) {
            if (gi > 0) HorizontalDivider()
            for ((op, ico) in group) {
                val need = if (op == BoolOp.COMBINE || op == BoolOp.FLATTEN) 1 else 2
                DropdownMenuItem(
                    text = { Text(op.title) }, leadingIcon = { QIcon(ico) }, enabled = count >= need,
                    onClick = {
                        onDismiss()
                        if (!state.applyBool(op)) Toast.makeText(context, tr("op_failed"), Toast.LENGTH_SHORT).show()
                    },
                )
            }
        }
    }
}

@Composable
private fun PillBar(state: EditorState, drag: Modifier) {
    var boolMenu by remember { mutableStateOf(false) }
    Surface(
        shape = CircleShape, color = glassColor(MaterialTheme.colorScheme.surfaceContainerHigh), shadowElevation = glassElevation(6.dp),
        border = glassBorder(), modifier = drag.frostedGlass(CircleShape),
    ) {
        Row(Modifier.padding(horizontal = 4.dp, vertical = 4.dp), horizontalArrangement = Arrangement.spacedBy(2.dp)) {
            QIconButton(Ico.Duplicate, { state.duplicateSelected() }, label = tr("duplicate"))
            Box {
                QIconButton(Ico.Bool, { boolMenu = true }, label = tr("combine_shapes"))
                BoolMenu(state, boolMenu) { boolMenu = false }
            }
            QIconButton(Ico.Forward, { state.reorder(forward = true, toEnd = false) }, label = tr("up"))
            QIconButton(Ico.Backward, { state.reorder(forward = false, toEnd = false) }, label = tr("down"))
            if (state.canMaskSelection()) QIconButton(Ico.Mask, { state.toggleMask() }, label = tr(if (state.selectionIsMask()) "mask_off" else "mask_below"))
            if (state.hasGroupSelected()) QIconButton(Ico.Ungroup, { state.ungroup() }, label = tr("ungroup"))
            else if (state.selection.size > 1) QIconButton(Ico.Group, { state.group() }, label = tr("group"))
            // эффекты: эхо для одной фигуры, переход для двух. Место общее с замком (замок остаётся в раскрытой панели)
            val picked = state.selectedNodes()
            if (picked.size == 1 && com.qwenz.qwel.data.Echo.canEcho(picked[0])) {
                QIconButton(Ico.Layers, { state.effect = "echo" }, label = tr("echo"))
            }
            else if (picked.size == 2 && picked.none { it.kind == NodeKind.TEXT || it.kind == NodeKind.IMAGE })
                QIconButton(Ico.Shapes, { state.effect = "blend" }, label = tr("blend"))
            else QIconButton(Ico.Lock, { state.updateSelected { it.copy(locked = true) }; state.clearSelection() }, label = tr("lock"))
            QIconButton(Ico.Delete, { state.deleteSelected() }, label = tr("delete"))
        }
    }
}

@Composable
private fun ExpandedDock(
    state: EditorState,
    onEditText: (String) -> Unit,
    onOpenPanel: (Panel) -> Unit,
    onExpanded: (Boolean) -> Unit,
) {
    val sel = state.selectedNodes()
    val n = sel.firstOrNull() ?: return
    val single = sel.size == 1
    var tool by remember(state.selection) { mutableStateOf<QuickTool?>(null) }
    var boolMenu by remember { mutableStateOf(false) }
    fun pick(t: QuickTool) { tool = if (tool == t) null else t }

    Surface(
        shape = RoundedCornerShape(28.dp), color = glassColor(MaterialTheme.colorScheme.surfaceContainerLow, 0.88f),
        shadowElevation = glassElevation(6.dp), border = glassBorder(),
        modifier = Modifier.fillMaxWidth().frostedGlass(RoundedCornerShape(28.dp)),
    ) {
        Column(
            Modifier.heightIn(max = 380.dp).verticalScroll(rememberScrollState()).padding(horizontal = 12.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                if (single) n.name.ifBlank { tr("layer") } else tr("layers_selected", sel.size),
                style = MaterialTheme.typography.titleMedium, maxLines = 1, overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(horizontal = 6.dp),
            )

            // --- инструменты слоя
            if (single && n.kind == NodeKind.TEXT) {
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    item { ToolChip(tr("edit"), false, { QIcon(Ico.Edit) }) { onEditText(n.id) } }
                    item { ToolChip(tr("font"), tool == QuickTool.FONT, { QIcon(Ico.Font) }) { pick(QuickTool.FONT) } }
                    item { ToolChip(tr("size"), tool == QuickTool.SIZE, { QIcon(Ico.FontSize) }) { pick(QuickTool.SIZE) } }
                    item { ToolChip(tr("weight"), tool == QuickTool.WEIGHT, { QIcon(Ico.Text) }) { pick(QuickTool.WEIGHT) } }
                }
            }
            if (single && n.kind == NodeKind.SHAPE) {
                LazyRow { item { ToolChip(tr("shape"), tool == QuickTool.SHAPE, { QIcon(Ico.Shapes) }) { pick(QuickTool.SHAPE) } } }
            }
            if (single && n.kind == NodeKind.RECT) {
                LazyRow { item { ToolChip(tr("corner"), tool == QuickTool.CORNER, { QIcon(Ico.Corner) }) { pick(QuickTool.CORNER) } } }
            }

            // --- внешний вид
            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                if (sel.any { it.kind != NodeKind.IMAGE }) {
                    item {
                        ToolChip(if (n.kind == NodeKind.TEXT) tr("color") else tr("fill"), tool == QuickTool.FILL, { Swatch(n.fill) }) { pick(QuickTool.FILL) }
                    }
                }
                if (sel.none { it.kind == NodeKind.TEXT || it.kind == NodeKind.IMAGE }) {
                    item { ToolChip(tr("stroke"), tool == QuickTool.STROKE, { QIcon(Ico.Stroke) }) { pick(QuickTool.STROKE) } }
                }
                item { ToolChip(tr("transparency"), tool == QuickTool.OPACITY, { QIcon(Ico.Opacity) }) { pick(QuickTool.OPACITY) } }
                item { ToolChip(tr("gradient"), tool == QuickTool.GRADIENT, { QIcon(Ico.Gradient) }) { pick(QuickTool.GRADIENT) } }
                item { ToolChip(tr("shadow"), tool == QuickTool.SHADOW, { QIcon(Ico.Shadow) }) { pick(QuickTool.SHADOW) } }
                item { ToolChip(tr("blur_short"), tool == QuickTool.BLUR, { QIcon(Ico.Blur) }) { pick(QuickTool.BLUR) } }
            }

            // --- область выбранного инструмента
            AnimatedVisibility(visible = tool != null) {
                Surface(shape = RoundedCornerShape(20.dp), color = MaterialTheme.colorScheme.surfaceContainerHighest) {
                    Column(Modifier.fillMaxWidth().padding(12.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        when (tool) {
                            QuickTool.FONT -> FontPicker(state, n)
                            QuickTool.SIZE -> TextSizeControl(state, n)
                            QuickTool.WEIGHT -> WeightControl(state, n)
                            QuickTool.SHAPE -> ShapeControl(state, n)
                            QuickTool.CORNER -> CornerControl(state, n)
                            QuickTool.FILL -> FillControl(state, sel)
                            QuickTool.STROKE -> StrokeControl(state, sel)
                            QuickTool.OPACITY -> OpacityControl(state, sel)
                            QuickTool.GRADIENT -> GradientControl(state, sel)
                            QuickTool.SHADOW -> ShadowControl(state, sel)
                            QuickTool.BLUR -> BlurControl(state, sel)
                            null -> {}
                        }
                    }
                }
            }

            // --- действия
            LazyRow(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                item { ActionItem(Ico.Delete, tr("delete")) { state.deleteSelected() } }
                item { ActionItem(Ico.Duplicate, tr("duplicate")) { state.duplicateSelected() } }
                item { ActionItem(Ico.Forward, tr("up")) { state.reorder(forward = true, toEnd = false) } }
                item { ActionItem(Ico.Backward, tr("down")) { state.reorder(forward = false, toEnd = false) } }
                if (state.canMaskSelection()) item { ActionItem(Ico.Mask, tr(if (state.selectionIsMask()) "mask_off_short" else "mask_short")) { state.toggleMask() } }
                if (state.hasGroupSelected()) item { ActionItem(Ico.Ungroup, tr("ungroup_short")) { state.ungroup() } }
                else if (sel.size > 1) item { ActionItem(Ico.Group, tr("group_name")) { state.group() } }
                item {
                    Box {
                        ActionItem(Ico.Bool, tr("combine_short")) { boolMenu = true }
                        BoolMenu(state, boolMenu) { boolMenu = false }
                    }
                }
                if (sel.size == 1 && com.qwenz.qwel.data.Echo.canEcho(sel[0])) item { ActionItem(Ico.Layers, tr("echo_short")) { state.effect = "echo"; onExpanded(false) } }
                if (sel.size == 2 && sel.none { it.kind == NodeKind.TEXT || it.kind == NodeKind.IMAGE }) item { ActionItem(Ico.Shapes, tr("blend_short")) { state.effect = "blend"; onExpanded(false) } }
                item { ActionItem(Ico.Align, tr("align_short")) { onOpenPanel(Panel.Align) } }
                item { ActionItem(Ico.Style, tr("all_properties")) { onOpenPanel(Panel.Style) } }
                item { ActionItem(Ico.Lock, tr("lock_short")) { state.updateSelected { it.copy(locked = true) }; state.clearSelection(); onExpanded(false) } }
            }
        }
    }
}

@Composable
private fun Swatch(argb: Int) {
    Box(
        Modifier.size(24.dp).clip(CircleShape).background(if (argb == 0) Color.Transparent else Color(argb))
            .border(1.dp, MaterialTheme.colorScheme.outline, CircleShape),
    )
}

/** Крупная плашка инструмента: значок + подпись. */
@Composable
private fun ToolChip(label: String, selected: Boolean, icon: @Composable () -> Unit, onClick: () -> Unit) {
    val scheme = MaterialTheme.colorScheme
    Surface(
        shape = RoundedCornerShape(if (selected) 16.dp else 22.dp),
        color = if (selected) scheme.primaryContainer else scheme.secondaryContainer,
        contentColor = if (selected) scheme.onPrimaryContainer else scheme.onSecondaryContainer,
        modifier = Modifier.clip(RoundedCornerShape(22.dp)).clickable(onClick = onClick),
    ) {
        Row(
            Modifier.padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            icon()
            Text(label, style = MaterialTheme.typography.titleSmall, maxLines = 1)
        }
    }
}

/** Действие: значок над подписью. */
@Composable
private fun ActionItem(ico: Ico, label: String, onClick: () -> Unit) {
    Column(
        Modifier.width(84.dp).clip(RoundedCornerShape(16.dp)).clickable(onClick = onClick).padding(vertical = 10.dp, horizontal = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        QIcon(ico, tint = MaterialTheme.colorScheme.primary, size = 28.dp)
        Text(
            label, style = MaterialTheme.typography.labelMedium, maxLines = 1, overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurface,
        )
    }
}
