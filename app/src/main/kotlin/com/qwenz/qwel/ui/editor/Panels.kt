package com.qwenz.qwel.ui.editor

import com.qwenz.qwel.i18n.tr

import android.content.Context
import android.os.Build
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.material3.Button
import androidx.compose.material3.TextButton
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.qwenz.qwel.data.AlignMode
import com.qwenz.qwel.data.AlignTo
import com.qwenz.qwel.data.Axis
import com.qwenz.qwel.data.ComponentDef
import com.qwenz.qwel.data.Components
import com.qwenz.qwel.data.CornerTokens
import com.qwenz.qwel.data.DesignPalette
import com.qwenz.qwel.data.MatchDim
import com.qwenz.qwel.data.Node
import com.qwenz.qwel.data.NodeKind
import com.qwenz.qwel.data.Tok
import com.qwenz.qwel.data.Tone
import com.qwenz.qwel.data.TypeScale
import com.qwenz.qwel.data.newId
import com.qwenz.qwel.data.withTextSize
import com.qwenz.qwel.render.Assets
import com.qwenz.qwel.render.Fonts
import com.qwenz.qwel.render.ImportedImage
import com.qwenz.qwel.render.appendTo
import com.qwenz.qwel.render.drawNode
import com.qwenz.qwel.render.drawNodes
import com.qwenz.qwel.shapes.ShapeDef
import com.qwenz.qwel.shapes.ShapeLibrary
import com.qwenz.qwel.ui.common.ColorPickerDialog
import com.qwenz.qwel.ui.common.ColorRow
import com.qwenz.qwel.ui.common.Ico
import com.qwenz.qwel.ui.common.NumberField
import com.qwenz.qwel.ui.common.QIcon
import com.qwenz.qwel.ui.common.QIconButton
import com.qwenz.qwel.ui.common.SectionTitle
import com.qwenz.qwel.ui.theme.Motion
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.math.min
import kotlin.math.roundToInt

// =============================================================== вставка

private fun insertionOrigin(state: EditorState, w: Float, h: Float): Offset {
    var c = state.viewCenterDoc()
    if (c.x < 0f || c.y < 0f || c.x > state.width || c.y > state.height) c = Offset(state.width / 2f, state.height / 2f)
    val k = (state.nodes.size % 5) * 8f
    return Offset(c.x - w / 2f + k, c.y - h / 2f + k)
}

private val ON_SURFACE = 0xFF1D1B20.toInt()

private fun insertRect(state: EditorState) {
    val o = insertionOrigin(state, 160f, 96f)
    state.addNodes(listOf(Node(newId(), NodeKind.RECT, tr("rectangle"), o.x, o.y, 160f, 96f,
        fill = state.tone.color(DesignPalette.nextToken(state.nodes.size)), fillToken = DesignPalette.nextToken(state.nodes.size), corner = 16f)))
}

private fun insertEllipse(state: EditorState) {
    val o = insertionOrigin(state, 120f, 120f)
    state.addNodes(listOf(Node(newId(), NodeKind.ELLIPSE, tr("ellipse"), o.x, o.y, 120f, 120f,
        fill = state.tone.color(DesignPalette.nextToken(state.nodes.size)), fillToken = DesignPalette.nextToken(state.nodes.size))))
}

private fun insertText(state: EditorState) {
    val n = Node(newId(), NodeKind.TEXT, tr("text"), 0f, 0f, 1f, 1f, fill = state.tone.color(Tok.ON_SURFACE, ON_SURFACE),
        text = tr("text"), fontSize = 24f, weight = 500, ratioLock = true, fillToken = Tok.ON_SURFACE).withTextSize()
    val o = insertionOrigin(state, n.w, n.h)
    state.addNodes(listOf(n.copy(x = o.x, y = o.y)))
}

private fun insertImage(state: EditorState, img: ImportedImage) {
    val maxSide = (min(state.width, state.height) * 0.6f).coerceAtLeast(64f)
    val k = min(maxSide / img.width, maxSide / img.height).coerceAtMost(1f).let { if (it <= 0f) 1f else it }
    val w = (img.width * k).coerceAtLeast(8f); val h = (img.height * k).coerceAtLeast(8f)
    val o = insertionOrigin(state, w, h)
    state.addNodes(listOf(Node(newId(), NodeKind.IMAGE, tr("image"), o.x, o.y, w, h, asset = img.name, ratioLock = true)))
}

private fun insertShape(state: EditorState, def: ShapeDef) {
    val o = insertionOrigin(state, 128f, 128f)
    state.addNodes(listOf(Node(newId(), NodeKind.SHAPE, def.name, o.x, o.y, 128f, 128f,
        fill = state.tone.color(DesignPalette.nextToken(state.nodes.size)), fillToken = DesignPalette.nextToken(state.nodes.size),
        shapeId = def.id, ratioLock = true)))
}

private fun insertComponent(state: EditorState, c: ComponentDef) {
    val o = insertionOrigin(state, c.w, c.h)
    state.addNodes(c.build(o.x, o.y, newId(), state.tone))
}

@Composable
fun InsertPanel(state: EditorState) {
    var tab by remember { mutableIntStateOf(0) }
    var category by remember { mutableStateOf(ShapeLibrary.LOADER) }
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val imagePicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        if (uri != null) scope.launch {
            val img = withContext(Dispatchers.IO) { Assets.importImage(uri) }
            if (img == null) Toast.makeText(context, tr("image_open_failed"), Toast.LENGTH_SHORT).show()
            else insertImage(state, img)
        }
    }
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        val tabNames = listOf(tr("tab_basics"), tr("tab_md3_shapes"), tr("tab_components"), tr("tab_icons"))
        for (rowStart in intArrayOf(0, 2)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                for (i in rowStart until rowStart + 2) {
                    FilterChip(
                        selected = tab == i, onClick = { tab = i }, modifier = Modifier.weight(1f),
                        label = { Text(tabNames[i], Modifier.fillMaxWidth(), textAlign = androidx.compose.ui.text.style.TextAlign.Center) },
                    )
                }
            }
        }
        when (tab) {
            0 -> Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                BasicTile(tr("rectangle"), Ico.Rect, Modifier.weight(1f)) { insertRect(state) }
                BasicTile(tr("ellipse"), Ico.Ellipse, Modifier.weight(1f)) { insertEllipse(state) }
                BasicTile(tr("text"), Ico.Text, Modifier.weight(1f)) { insertText(state) }
                BasicTile(tr("image"), Ico.Image, Modifier.weight(1f)) { imagePicker.launch("image/*") }
            }
            1 -> {
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(ShapeLibrary.categories) { c ->
                        FilterChip(selected = category == c, onClick = { category = c }, label = { Text(ShapeLibrary.categoryName(c)) })
                    }
                }
                val shapes = ShapeLibrary.inCategory(category)
                for (rowShapes in shapes.chunked(4)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        for (def in rowShapes) ShapeTile(def, Modifier.weight(1f)) { insertShape(state, def) }
                        repeat(4 - rowShapes.size) { Spacer(Modifier.weight(1f)) }
                    }
                }
            }
            3 -> IconGallery(state)
            else -> for ((cat, comps) in Components.groups) {
                Text(tr("comp_cat_$cat"), Modifier.padding(top = 8.dp), style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.primary)
                for (rowComps in comps.chunked(2)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        for (c in rowComps) ComponentTile(c, state.tone, Modifier.weight(1f)) { insertComponent(state, c) }
                        if (rowComps.size == 1) Spacer(Modifier.weight(1f))
                    }
                }
            }
        }
    }
}

private object PreviewCache {
    private val map = HashMap<Pair<String, Tone>, List<Node>>()
    fun peek(c: ComponentDef, tone: Tone): List<Node>? = synchronized(map) { map[c.id to tone] }
    suspend fun get(c: ComponentDef, tone: Tone): List<Node> {
        peek(c, tone)?.let { return it }
        val built = withContext(Dispatchers.Default) { c.build(0f, 0f, "", tone) }
        synchronized(map) { map[c.id to tone] = built }
        return built
    }
}

/** Плитка с 'живой' формой: при нажатии скругление растёт. */
@Composable
private fun Tile(modifier: Modifier, onClick: () -> Unit, content: @Composable () -> Unit) {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val corner by animateDpAsState(if (pressed) 32.dp else 20.dp, Motion.spatial(), label = "tile")
    Box(
        modifier.clip(RoundedCornerShape(corner)).background(MaterialTheme.colorScheme.surfaceContainerHighest)
            .clickable(interactionSource = source, indication = androidx.compose.foundation.LocalIndication.current, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) { content() }
}

@Composable
private fun BasicTile(label: String, ico: Ico, modifier: Modifier, onClick: () -> Unit) {
    Tile(modifier.height(88.dp), onClick) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
            QIcon(ico, tint = MaterialTheme.colorScheme.primary, size = 28.dp)
            Text(label, style = MaterialTheme.typography.labelMedium, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}

@Composable
private fun ShapeTile(def: ShapeDef, modifier: Modifier, onClick: () -> Unit) {
    val color = MaterialTheme.colorScheme.primary
    Tile(modifier.aspectRatio(1f), onClick) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Canvas(Modifier.size(44.dp)) {
                drawPath(def.cubics.appendTo(Path(), 0f, 0f, size.width, size.height), color)
            }
            Text(
                def.name, style = MaterialTheme.typography.labelSmall, maxLines = 1, overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 4.dp),
            )
        }
    }
}

@Composable
private fun ComponentTile(c: ComponentDef, tone: Tone, modifier: Modifier, onClick: () -> Unit) {
    // Сборка читает и разбирает SVG иконок: 80 плиток разом на главном потоке подвешивали слабые телефоны
    val nodes by produceState<List<Node>?>(PreviewCache.peek(c, tone), c, tone) { value = PreviewCache.get(c, tone) }
    Tile(modifier.height(96.dp), onClick) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Canvas(Modifier.fillMaxWidth().height(52.dp).padding(horizontal = 12.dp)) {
                val s = min(size.width / c.w, size.height / c.h).coerceAtMost(1f)
                translate((size.width - c.w * s) / 2f, (size.height - c.h * s) / 2f) {
                    scale(s, s, Offset.Zero) { nodes?.let { drawNodes(it) } }
                }
            }
            Text(c.name, style = MaterialTheme.typography.labelMedium, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}

// =============================================================== выравнивание

@Composable
fun AlignPanel(state: EditorState) {
    val count = state.selection.size
    var toCanvas by remember { mutableStateOf(false) }
    val to = if (toCanvas || count < 2) AlignTo.CANVAS else AlignTo.SELECTION
    val enabled = count > 0
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        if (!enabled) {
            Text(
                tr("align_hint"),
                style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(tr("relative_to"), style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            FilterChip(selected = to == AlignTo.SELECTION, enabled = count >= 2,
                onClick = { toCanvas = false }, label = { Text(tr("selection")) })
            FilterChip(selected = to == AlignTo.CANVAS, onClick = { toCanvas = true }, label = { Text(tr("canvas_of")) })
        }
        ButtonGroupRow(tr("horizontally"), listOf(
            Act(Ico.AlignLeft, tr("left")) { state.align(AlignMode.LEFT, to) },
            Act(Ico.AlignHCenter, tr("center")) { state.align(AlignMode.H_CENTER, to) },
            Act(Ico.AlignRight, tr("right")) { state.align(AlignMode.RIGHT, to) },
        ), enabled)
        ButtonGroupRow(tr("vertically"), listOf(
            Act(Ico.AlignTop, tr("top")) { state.align(AlignMode.TOP, to) },
            Act(Ico.AlignVCenter, tr("center")) { state.align(AlignMode.V_CENTER, to) },
            Act(Ico.AlignBottom, tr("bottom")) { state.align(AlignMode.BOTTOM, to) },
        ), enabled)
        ButtonGroupRow(tr("distribute"), listOf(
            Act(Ico.DistributeH, tr("horizontally")) { state.distribute(Axis.H) },
            Act(Ico.DistributeV, tr("vertically")) { state.distribute(Axis.V) },
        ), count >= 3)
        ButtonGroupRow(tr("same_size"), listOf(
            Act(Ico.SameWidth, tr("width")) { state.matchSize(MatchDim.WIDTH) },
            Act(Ico.SameHeight, tr("height")) { state.matchSize(MatchDim.HEIGHT) },
        ), count >= 2)
        FilledTonalButton(onClick = { state.centerOnCanvas() }, enabled = enabled, modifier = Modifier.fillMaxWidth()) {
            Text(tr("center_on_canvas"))
        }
    }
}

private class Act(val ico: Ico, val label: String, val run: () -> Unit)

/** Соединённая группа кнопок (как Connected button group из MD3 Expressive). */
@Composable
private fun ButtonGroupRow(title: String, items: List<Act>, enabled: Boolean) {
    Column {
        SectionTitle(title)
        Surface(shape = CircleShape, color = MaterialTheme.colorScheme.surfaceContainerHighest) {
            Row(Modifier.padding(4.dp), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                for (a in items) QIconButton(a.ico, a.run, label = a.label, enabled = enabled, size = 52.dp)
            }
        }
    }
}

// =============================================================== слои

@Composable
fun LayersPanel(state: EditorState) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        if (state.nodes.isEmpty()) {
            Text(tr("empty_layers"), style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        for (n in state.nodes.asReversed()) {
            val selected = n.id in state.selection
            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp))
                    .background(if (selected) MaterialTheme.colorScheme.secondaryContainer else Color.Transparent)
                    .clickable { if (state.multi) state.toggle(n.id) else if (n.group.isNotEmpty()) state.selectInside(n.id) else state.select(setOf(n.id)) }
                    .padding(start = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                LayerThumb(n)
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(n.name.ifBlank { tr("layer") }, style = MaterialTheme.typography.bodyLarge, maxLines = 1, overflow = TextOverflow.Ellipsis,
                        color = if (selected) MaterialTheme.colorScheme.onSecondaryContainer else MaterialTheme.colorScheme.onSurface)
                    if (n.isMask) Text(tr("mask_label"), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
                    else if (n.group.isNotEmpty()) Text(tr("in_group"), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                QIconButton(if (n.visible) Ico.Eye else Ico.EyeOff, { state.toggleVisible(n.id) }, label = tr("visibility"), size = 44.dp)
                QIconButton(if (n.locked) Ico.Lock else Ico.Unlock, { state.toggleLock(n.id) }, label = tr("locking"), size = 44.dp)
            }
        }
    }
}

@Composable
private fun LayerThumb(n: Node) {
    Box(Modifier.size(40.dp).clip(RoundedCornerShape(12.dp)).background(MaterialTheme.colorScheme.surfaceContainerHighest)) {
        Canvas(Modifier.size(40.dp).padding(6.dp)) {
            val s = min(size.width / n.w, size.height / n.h)
            translate((size.width - n.w * s) / 2f, (size.height - n.h * s) / 2f) {
                scale(s, s, Offset.Zero) { drawNode(n.copy(x = 0f, y = 0f, rotation = 0f, visible = true, opacity = 1f)) }
            }
        }
    }
}

// =============================================================== стиль

@Composable
fun StylePanel(state: EditorState, onEditText: (String) -> Unit) {
    val sel = state.selectedNodes()
    if (sel.isEmpty()) { CanvasSettings(state); return }
    val n = sel.first()
    val single = sel.size == 1
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        if (single) {
            OutlinedTextField(
                value = n.name, onValueChange = { v -> state.updateNode(n.id, "name") { it.copy(name = v) } },
                label = { Text(tr("layer_name")) }, singleLine = true, shape = RoundedCornerShape(16.dp),
                modifier = Modifier.fillMaxWidth(),
            )
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                NumberField("X", n.x, { v -> state.updateNode(n.id, "x") { it.copy(x = v) } }, Modifier.weight(1f))
                NumberField("Y", n.y, { v -> state.updateNode(n.id, "y") { it.copy(y = v) } }, Modifier.weight(1f))
            }
            if (n.kind != NodeKind.TEXT) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    NumberField(tr("width"), n.w, { v -> resizeTo(state, n, v, null) }, Modifier.weight(1f))
                    NumberField(tr("height"), n.h, { v -> resizeTo(state, n, null, v) }, Modifier.weight(1f))
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                NumberField(tr("rotation"), n.rotation, { v -> state.updateNode(n.id, "rot") { it.copy(rotation = v) } }, Modifier.weight(1f))
                if (n.kind != NodeKind.TEXT) {
                    Row(Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically) {
                        Switch(n.ratioLock, { v -> state.updateNode(n.id, "ratio") { it.copy(ratioLock = v) } })
                        Spacer(Modifier.width(8.dp))
                        Text(tr("proportions"), style = MaterialTheme.typography.labelLarge)
                    }
                }
            }
        } else {
            Text(tr("layers_selected", sel.size), style = MaterialTheme.typography.titleMedium)
        }

        FillControl(state, sel)
        GradientControl(state, sel)
        StrokeControl(state, sel)
        OpacityControl(state, sel)
        ShadowControl(state, sel)
        BlurControl(state, sel)
        if (single && n.kind == NodeKind.RECT) CornerControl(state, n)
        if (single) ActionControl(state, n)
        if (single && com.qwenz.qwel.data.Echo.canEcho(n)) {
            Text(tr("effects"), style = MaterialTheme.typography.titleSmall, modifier = Modifier.padding(top = 4.dp))
            FilledTonalButton(onClick = { state.effect = "echo" }, modifier = Modifier.fillMaxWidth()) { Text(tr("echo")) }
        }
        if (sel.size == 2 && sel.none { it.kind == NodeKind.TEXT || it.kind == NodeKind.IMAGE }) {
            Text(tr("effects"), style = MaterialTheme.typography.titleSmall, modifier = Modifier.padding(top = 4.dp))
            FilledTonalButton(onClick = { state.effect = "blend" }, modifier = Modifier.fillMaxWidth()) { Text(tr("blend")) }
        }
        if (single && n.kind == NodeKind.SHAPE) ShapeControl(state, n)
        if (single && n.kind == NodeKind.TEXT) {
            Button(onClick = { onEditText(n.id) }, modifier = Modifier.fillMaxWidth()) { Text(tr("edit_text")) }
            TextSizeControl(state, n)
            FontPicker(state, n)
            WeightControl(state, n)
        }
    }
}

// ----------------------------------------------------- отдельные блоки стиля (их же использует быстрая панель)

@Composable
fun FillControl(state: EditorState, sel: List<Node>) {
    if (sel.isEmpty() || sel.all { it.kind == NodeKind.IMAGE }) return
    val n = sel.first()
    ColorRow(
        if (n.kind == NodeKind.TEXT) tr("text_color") else tr("fill"), n.fill, state.tone, n.fillToken,
        onEyedropper = { state.eyedrop = { c -> state.updateSelected("fill") { it.copy(fill = c, fillToken = -1) } } },
    ) { c, t ->
        state.updateSelected("fill") { it.copy(fill = c, fillToken = t) }
    }
}

private fun lighten(argb: Int, k: Float): Int {
    fun ch(v: Int) = (v + (255 - v) * k).toInt().coerceIn(0, 255)
    return (argb and 0xFF000000.toInt()) or (ch((argb shr 16) and 0xFF) shl 16) or (ch((argb shr 8) and 0xFF) shl 8) or ch(argb and 0xFF)
}

private fun supportsEffects(n: Node) =
    n.kind == NodeKind.RECT || n.kind == NodeKind.ELLIPSE || n.kind == NodeKind.SHAPE || n.kind == NodeKind.PATH

/** Градиент заливки: от основного цвета ко второму. Линейный - с углом, радиальный - от центра. */
@Composable
fun GradientControl(state: EditorState, sel: List<Node>) {
    val n = sel.firstOrNull() ?: return
    if (!supportsEffects(n)) return
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        SectionTitle(tr("gradient"))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            for ((k, label) in listOf(0 to tr("grad_none"), 1 to tr("grad_linear"), 2 to tr("grad_radial"))) {
                FilterChip(
                    selected = n.gradKind == k, label = { Text(label) },
                    onClick = {
                        state.updateSelected("gk") {
                            // при первом включении второй цвет - осветлённый основной, чтобы переход сразу был виден
                            val second = if (k != 0 && it.gradKind == 0 && it.fill2 == 0xFF000000.toInt()) lighten(it.fill, 0.45f) else it.fill2
                            it.copy(gradKind = k, fill2 = second)
                        }
                    },
                )
            }
        }
        if (n.gradKind != 0) {
            ColorRow(
                tr("grad_to"), n.fill2, state.tone,
                onEyedropper = { state.eyedrop = { c -> state.updateSelected("f2") { it.copy(fill2 = c) } } },
            ) { c, _ -> state.updateSelected("f2") { it.copy(fill2 = c) } }
            if (n.gradKind == 1) {
                LabeledSlider(tr("grad_angle"), n.gradAngle, 0f..360f, "${n.gradAngle.roundToInt()} deg") { v ->
                    state.updateSelected("ga") { it.copy(gradAngle = v) }
                }
            }
        }
    }
}

/** Тень и свечение. Тень рисуется только снаружи слоя, поэтому на стекле и прозрачных заливках она не просвечивает. */
@Composable
fun ShadowControl(state: EditorState, sel: List<Node>) {
    val n = sel.firstOrNull() ?: return
    if (!supportsEffects(n)) return
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        LabeledSlider(tr("shadow"), n.shadowBlur, 0f..48f, if (n.shadowBlur < 0.5f) tr("blur_off") else "${n.shadowBlur.roundToInt()}") { v ->
            state.updateSelected("shb") { it.copy(shadowBlur = v) }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            FilterChip(selected = false, label = { Text(tr("shadow_soft")) }, onClick = {
                state.updateSelected { it.copy(shadowBlur = 16f, shadowDx = 0f, shadowDy = 6f, shadowColor = 0x40000000) }
            })
            FilterChip(selected = false, label = { Text(tr("shadow_lift")) }, onClick = {
                state.updateSelected { it.copy(shadowBlur = 28f, shadowDx = 0f, shadowDy = 14f, shadowColor = 0x59000000) }
            })
            FilterChip(selected = false, label = { Text(tr("shadow_glow")) }, onClick = {
                state.updateSelected { it.copy(shadowBlur = 26f, shadowDx = 0f, shadowDy = 0f, shadowColor = (it.fill and 0xFFFFFF) or 0x99000000.toInt()) }
            })
        }
        if (n.shadowBlur >= 0.5f) {
            LabeledSlider(tr("shadow_x"), n.shadowDx, -40f..40f, "${n.shadowDx.roundToInt()}") { v ->
                state.updateSelected("shx") { it.copy(shadowDx = v) }
            }
            LabeledSlider(tr("shadow_y"), n.shadowDy, -40f..40f, "${n.shadowDy.roundToInt()}") { v ->
                state.updateSelected("shy") { it.copy(shadowDy = v) }
            }
            ColorRow(tr("shadow_color"), n.shadowColor, state.tone) { c, _ -> state.updateSelected("shc") { it.copy(shadowColor = c) } }
            if (android.os.Build.VERSION.SDK_INT < 28) {
                Text(tr("shadow_old_android"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
fun StrokeControl(state: EditorState, sel: List<Node>) {
    if (sel.isEmpty() || sel.any { it.kind == NodeKind.TEXT || it.kind == NodeKind.IMAGE }) return
    val n = sel.first()
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        ColorRow(
            tr("stroke"), n.stroke, state.tone, n.strokeToken,
            onEyedropper = { state.eyedrop = { c -> state.updateSelected("stroke") { it.copy(stroke = c, strokeToken = -1, strokeWidth = if (it.strokeWidth == 0f) 2f else it.strokeWidth) } } },
        ) { c, t ->
            state.updateSelected("stroke") {
                it.copy(stroke = c, strokeToken = t, strokeWidth = if (it.strokeWidth == 0f && c != 0) 2f else it.strokeWidth)
            }
        }
        if (n.stroke != 0 || n.strokeWidth > 0f) {
            LabeledSlider(tr("stroke_width"), n.strokeWidth, 0f..16f, "${n.strokeWidth.roundToInt()}") { v ->
                state.updateSelected("sw") { it.copy(strokeWidth = v) }
            }
        }
    }
}

@Composable
fun OpacityControl(state: EditorState, sel: List<Node>) {
    val n = sel.firstOrNull() ?: return
    LabeledSlider(tr("opacity"), n.opacity, 0f..1f, "${(n.opacity * 100).roundToInt()}%") { v ->
        state.updateSelected("op") { it.copy(opacity = v) }
    }
}

/** Размытие фона под слоем ('матовое стекло'). Заметно, когда у заливки есть прозрачность. */
@Composable
fun BlurControl(state: EditorState, sel: List<Node>) {
    val n = sel.firstOrNull() ?: return
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        LabeledSlider(tr("backdrop_blur"), n.blur, 0f..48f, if (n.blur < 0.5f) tr("blur_off") else "${n.blur.roundToInt()}") { v ->
            state.updateSelected("blur") { it.copy(blur = v) }
        }
        if (n.blur >= 0.5f) {
            Text(
                tr("blur_hint"), style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        LabeledSlider(tr("layer_blur"), n.softBlur, 0f..48f, if (n.softBlur < 0.5f) tr("blur_off") else "${n.softBlur.roundToInt()}") { v ->
            state.updateSelected("softblur") { it.copy(softBlur = v) }
        }
        if (android.os.Build.VERSION.SDK_INT < 31) {
            Text(tr("blur_old_android"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
fun CornerControl(state: EditorState, n: Node) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Column {
            SectionTitle(tr("corner_tokens"))
            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items(CornerTokens) { (label, v) ->
                    FilterChip(
                        selected = (n.corner >= 9000f && v >= 9000f) || n.corner == v,
                        onClick = { state.updateNode(n.id) { it.copy(corner = v) } },
                        label = { Text(label) },
                    )
                }
            }
        }
        val maxC = min(n.w, n.h) / 2f
        LabeledSlider(tr("radius"), n.corner.coerceAtMost(maxC), 0f..maxC.coerceAtLeast(1f), "${min(n.corner, maxC).roundToInt()}") { v ->
            state.updateNode(n.id, "corner") { it.copy(corner = v) }
        }
        val pc = n.pressCorner
        LabeledSlider(tr("press_corner"), if (pc < 0f) n.corner.coerceAtMost(maxC) else pc.coerceAtMost(maxC), 0f..maxC.coerceAtLeast(1f),
            if (pc < 0f) tr("blur_off") else "${min(pc, maxC).roundToInt()}") { v ->
            state.updateNode(n.id, "presscorner") { it.copy(pressCorner = v) }
        }
        if (pc >= 0f) {
            TextButton(onClick = { state.updateNode(n.id) { it.copy(pressCorner = -1f) } }) { Text(tr("press_corner_off")) }
        }
        Text(tr("press_corner_hint"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
fun ShapeControl(state: EditorState, n: Node) {
    Column {
        SectionTitle(tr("shape_morph"))
        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            items(ShapeLibrary.all) { def ->
                val color = if (def.id == n.shapeId) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.primary
                Box(
                    Modifier.size(56.dp).clip(RoundedCornerShape(if (def.id == n.shapeId) 28.dp else 16.dp))
                        .background(if (def.id == n.shapeId) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceContainerHighest)
                        .clickable { state.setShape(def.id) },
                    contentAlignment = Alignment.Center,
                ) {
                    Canvas(Modifier.size(34.dp)) { drawPath(def.cubics.appendTo(Path(), 0f, 0f, size.width, size.height), color) }
                }
            }
        }
    }
}

@Composable
fun TextSizeControl(state: EditorState, n: Node) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        SectionTitle(tr("size_scale"))
        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            items(TypeScale) { (label, size) ->
                FilterChip(selected = n.fontSize == size, onClick = { setFont(state, n, size, null) }, label = { Text("$label | ${size.roundToInt()}") })
            }
        }
        LabeledSlider(tr("custom_size"), n.fontSize.coerceIn(6f, 160f), 6f..160f, "${n.fontSize.roundToInt()}") { v ->
            state.updateNode(n.id, "fs") { it.copy(fontSize = v.roundToInt().toFloat()).withTextSize() }
        }
    }
}

@Composable
fun WeightControl(state: EditorState, n: Node) {
    Column {
        SectionTitle(tr("weight"))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf("Regular" to 400, "Medium" to 500, "Bold" to 700).forEach { (label, w) ->
                FilterChip(selected = n.weight == w, onClick = { setFont(state, n, null, w) }, label = { Text(label) })
            }
        }
    }
}

/** Выбор шрифта: системный или один из импортированных; кнопка добавляет свой .ttf/.otf. */
@Composable
fun FontPicker(state: EditorState, n: Node) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        if (uri != null) scope.launch {
            val name = withContext(Dispatchers.IO) { Fonts.import(uri) }
            if (name == null) Toast.makeText(context, tr("font_load_failed"), Toast.LENGTH_LONG).show()
            else state.updateNode(n.id) { it.copy(font = name).withTextSize() }
        }
    }
    Column {
        SectionTitle(tr("font"))
        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            item {
                FilterChip(selected = n.font.isEmpty(), onClick = { state.updateNode(n.id) { it.copy(font = "").withTextSize() } },
                    label = { Text(tr("system_font")) })
            }
            items(Fonts.builtinFonts) { f ->
                FilterChip(selected = n.font == f, onClick = { state.updateNode(n.id) { it.copy(font = f).withTextSize() } },
                    label = { Text(Fonts.displayName(f)) })
            }
            items(Fonts.names.toList()) { f ->
                FilterChip(selected = n.font == f, onClick = { state.updateNode(n.id) { it.copy(font = f).withTextSize() } },
                    label = { Text(Fonts.displayName(f)) })
            }
            item {
                FilterChip(selected = false, onClick = { picker.launch("*/*") }, label = { Text(tr("add_font")) })
            }
        }
    }
}

private fun setFont(state: EditorState, n: Node, size: Float?, weight: Int?) {
    state.updateNode(n.id) { it.copy(fontSize = size ?: it.fontSize, weight = weight ?: it.weight).withTextSize() }
}

/** Смена ширины/высоты из полей: центр остаётся на месте; при включённых пропорциях - второй размер подстраивается. */
private fun resizeTo(state: EditorState, n: Node, w: Float?, h: Float?) {
    state.updateNode(n.id) { o ->
        var nw = w ?: o.w; var nh = h ?: o.h
        if (o.ratioLock) { if (w != null) nh = o.h * nw / o.w else nw = o.w * nh / o.h }
        nw = nw.coerceAtLeast(1f); nh = nh.coerceAtLeast(1f)
        o.copy(x = o.cx - nw / 2f, y = o.cy - nh / 2f, w = nw, h = nh)
    }
}

@Composable
fun LabeledSlider(title: String, value: Float, range: ClosedFloatingPointRange<Float>, shown: String, onChange: (Float) -> Unit) {
    Column {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(title, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(shown, style = MaterialTheme.typography.labelLarge)
        }
        Slider(value = value.coerceIn(range), onValueChange = onChange, valueRange = range)
    }
}

// =============================================================== тон проекта

val SeedPresets = listOf(
    0xFF6750A4, 0xFF0B57D0, 0xFF006A6A, 0xFF2E7D32, 0xFF7C5800, 0xFFB3261E, 0xFFAD1457, 0xFF4E5B92,
).map { it.toInt() }

/** Схема цветов с обоев (Material You). Требует Android 12+. */
fun dynamicTone(context: Context, dark: Boolean): Tone {
    val cs = if (dark) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
    val colors = listOf(
        cs.primary, cs.onPrimary, cs.primaryContainer, cs.onPrimaryContainer,
        cs.secondary, cs.secondaryContainer, cs.onSecondaryContainer,
        cs.tertiary, cs.tertiaryContainer, cs.onTertiaryContainer,
        cs.error, cs.errorContainer,
        cs.surface, cs.surfaceContainerLow, cs.surfaceContainer, cs.surfaceContainerHigh, cs.surfaceContainerHighest,
        cs.onSurface, cs.onSurfaceVariant, cs.outline, cs.outlineVariant, cs.inverseSurface,
    ).map { it.toArgb() }
    return Tone(Tone.MODE_DYNAMIC, cs.primary.toArgb(), dark, colors)
}

/** Тон проекта: базовая схема, схема от выбранного цвета или от обоев. Все слои с токенами перекрашиваются сразу. */
@Composable
fun ToneSection(state: EditorState) {
    val context = LocalContext.current
    val tone = state.tone
    val canDynamic = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
    var picker by remember { mutableStateOf(false) }
    fun rebuild(mode: Int, dark: Boolean, seed: Int = tone.seed) {
        state.applyTone(
            when {
                mode == Tone.MODE_DYNAMIC && canDynamic -> dynamicTone(context, dark)
                mode == Tone.MODE_SEED || mode == Tone.MODE_DYNAMIC -> Tone.fromSeed(seed, dark)
                else -> Tone.baseline(dark)
            },
        )
    }
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(tr("project_tone"), style = MaterialTheme.typography.titleMedium)
        Text(
            tr("tone_hint"),
            style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            FilterChip(selected = tone.mode == Tone.MODE_BASELINE, onClick = { rebuild(Tone.MODE_BASELINE, tone.dark) }, label = { Text(tr("tone_base")) })
            FilterChip(selected = tone.mode == Tone.MODE_SEED, onClick = { rebuild(Tone.MODE_SEED, tone.dark) }, label = { Text(tr("custom_color")) })
            FilterChip(selected = tone.mode == Tone.MODE_DYNAMIC, enabled = canDynamic,
                onClick = { rebuild(Tone.MODE_DYNAMIC, tone.dark) }, label = { Text(tr("tone_wallpaper")) })
        }
        if (tone.mode == Tone.MODE_SEED) {
            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                item {
                    Box(
                        Modifier.size(40.dp).clip(CircleShape).background(MaterialTheme.colorScheme.surfaceContainerHighest)
                            .clickable { picker = true },
                        contentAlignment = Alignment.Center,
                    ) { QIcon(Ico.Fill, size = 22.dp, tint = MaterialTheme.colorScheme.primary) }
                }
                items(SeedPresets) { c ->
                    val selected = (tone.seed or 0xFF000000.toInt()) == c
                    Box(
                        Modifier.size(40.dp).clip(CircleShape).background(Color(c))
                            .border(if (selected) 3.dp else 1.dp,
                                if (selected) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.outlineVariant, CircleShape)
                            .clickable { rebuild(Tone.MODE_SEED, tone.dark, c) },
                    )
                }
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(tr("dark_scheme"), Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
            Switch(tone.dark, { rebuild(tone.mode, it) })
        }
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            for (t in intArrayOf(Tok.PRIMARY, Tok.PRIMARY_CONTAINER, Tok.SECONDARY_CONTAINER, Tok.TERTIARY, Tok.SURFACE, Tok.SURFACE_HIGHEST, Tok.ON_SURFACE)) {
                Box(
                    Modifier.size(28.dp).clip(CircleShape).background(Color(tone.color(t)))
                        .border(1.dp, MaterialTheme.colorScheme.outlineVariant, CircleShape),
                )
            }
        }
    }
    if (picker) ColorPickerDialog(tone.seed, onDismiss = { picker = false }, onConfirm = { rebuild(Tone.MODE_SEED, tone.dark, it); picker = false })
}

// =============================================================== холст

private val CanvasPresets get() = listOf(
    Triple(tr("preset_phone"), 360f, 800f), Triple(tr("preset_compact"), 360f, 640f), Triple(tr("preset_tablet"), 834f, 1194f),
    Triple(tr("preset_square"), 512f, 512f), Triple(tr("preset_desktop"), 1280f, 800f),
)

@Composable
private fun CanvasSettings(state: EditorState) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        ToneSection(state)
        Text(tr("canvas"), style = MaterialTheme.typography.titleMedium)
        SectionTitle(tr("size_dp"))
        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            items(CanvasPresets) { (label, w, h) ->
                FilterChip(
                    selected = state.width == w && state.height == h,
                    onClick = { state.setCanvasSize(w, h); state.fitted = false },
                    label = { Text("$label ${w.roundToInt()}x${h.roundToInt()}") },
                )
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            NumberField(tr("width"), state.width, { state.setCanvasSize(it, state.height) }, Modifier.weight(1f))
            NumberField(tr("height"), state.height, { state.setCanvasSize(state.width, it) }, Modifier.weight(1f))
        }
        ColorRow(tr("sheet_background"), state.background, state.tone, state.bgToken) { c, t -> state.updateBackground(c, t) }
        Row(verticalAlignment = Alignment.CenterVertically) {
            QIcon(Ico.Grid); Spacer(Modifier.width(12.dp))
            Text(tr("grid_8"), Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
            Switch(state.showGrid, { state.showGrid = it })
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            QIcon(Ico.Guides); Spacer(Modifier.width(12.dp))
            Text(tr("smart_guides"), Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
            Switch(state.smartGuides, { state.smartGuides = it })
        }
    }
}
