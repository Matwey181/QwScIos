package com.qwenz.qwel.ui.editor

import com.qwenz.qwel.i18n.tr
import com.qwenz.qwel.ui.common.frostedGlass
import com.qwenz.qwel.ui.common.glassBorder
import com.qwenz.qwel.ui.common.glassElevation
import com.qwenz.qwel.ui.common.glassColor
import com.qwenz.qwel.ui.common.LocalBackdrop
import com.qwenz.qwel.ui.common.BackdropSource
import androidx.compose.ui.layout.positionInRoot
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.graphics.layer.drawLayer
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.rememberGraphicsLayer
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.foundation.gestures.detectVerticalDragGestures

import android.widget.Toast
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.FilterChip
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.offset
import androidx.compose.ui.unit.dp
import com.qwenz.qwel.AppController
import com.qwenz.qwel.data.NodeKind
import com.qwenz.qwel.data.withTextSize
import com.qwenz.qwel.render.BoolOp
import com.qwenz.qwel.render.Gallery
import com.qwenz.qwel.render.CubicsShape
import com.qwenz.qwel.render.renderPng
import androidx.compose.material3.Switch
import com.qwenz.qwel.data.ComposeCode
import com.qwenz.qwel.render.SvgImport
import androidx.compose.material3.CircularProgressIndicator
import com.qwenz.qwel.render.renderPreview
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.runtime.produceState
import androidx.compose.ui.layout.ContentScale
import androidx.compose.foundation.Image
import com.qwenz.qwel.render.toSvg
import com.qwenz.qwel.shapes.ShapeLibrary
import com.qwenz.qwel.ui.common.Ico
import com.qwenz.qwel.ui.common.QIcon
import com.qwenz.qwel.ui.common.QIconButton
import com.qwenz.qwel.ui.common.rememberGallerySaver
import com.qwenz.qwel.ui.theme.Motion
import androidx.compose.runtime.snapshotFlow
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.math.roundToInt

enum class Panel(private val key: String) {
    None(""), Layers("layers"), Style("style"), Insert("add"), Align("align");

    /** Заголовок на текущем языке. */
    val title: String get() = if (key.isEmpty()) "" else tr(key)
}

@OptIn(FlowPreview::class)
@Composable
fun EditorScreen(state: EditorState, controller: AppController, onBack: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val density = LocalDensity.current
    var panel by remember { mutableStateOf(Panel.None) }
    var menu by remember { mutableStateOf(false) }
    var renaming by remember { mutableStateOf(false) }
    var editTextId by remember { mutableStateOf<String?>(null) }
    var dockOpen by remember { mutableStateOf(false) }
    var exportDialog by remember { mutableStateOf(false) }
    var guide by remember { mutableStateOf(false) }
    var exportSvg by remember { mutableStateOf(false) }
    var exportAll by remember { mutableStateOf(false) }
    var screensDialog by remember { mutableStateOf(false) }
    var codeDialog by remember { mutableStateOf<String?>(null) }
    var projectDialog by remember { mutableStateOf<String?>(null) }
    var zipPackage by remember { mutableStateOf("") }
    var zipKind by remember { mutableStateOf("") }
    var codeForSelection by remember { mutableStateOf(false) }
    var exportScale by remember { mutableIntStateOf(controller.exportScale) }
    // Guided first-run coachmarks point to real controls and react to the user's tap.
    var guidedStep by remember { mutableIntStateOf(if (!controller.showTutorial && !controller.hints.hasSeen("guided_add")) 0 else -1) }
    var addTarget by remember { mutableStateOf<Rect?>(null) }
    var insertTarget by remember { mutableStateOf<Rect?>(null) }
    val initialNodeCount = remember(state) { state.nodes.size }
    val saveToGallery = rememberGallerySaver()
    LaunchedEffect(state.selection.isEmpty()) { if (state.selection.isEmpty()) dockOpen = false }

    // --- подсказки по ходу работы: каждая один раз, когда человек впервые оказался в нужном месте
    val hints = controller.hints
    val tutorialOn = controller.showTutorial
    var previousTutorialOn by remember { mutableStateOf(tutorialOn) }
    LaunchedEffect(tutorialOn) {
        if (previousTutorialOn && !tutorialOn && !hints.hasSeen("guided_add")) guidedStep = 0
        previousTutorialOn = tutorialOn
    }
    LaunchedEffect(guidedStep, tutorialOn) {
        if (!tutorialOn && guidedStep < 0) {
            delay(700)
            hints.show("editor_start")
        }
    }
    LaunchedEffect(panel, guidedStep) {
        if (guidedStep == 0 && panel == Panel.Insert) guidedStep = 1
        else if (guidedStep == 1 && panel != Panel.Insert) guidedStep = 0
    }
    LaunchedEffect(state.nodes.size, guidedStep) {
        if (guidedStep == 1 && state.nodes.size > initialNodeCount) {
            hints.markSeen("guided_add")
            guidedStep = -1
        }
    }
    LaunchedEffect(state.selection.size, tutorialOn) {
        if (!tutorialOn && guidedStep < 0 && state.selection.isNotEmpty()) {
            delay(500)
            hints.show(if (state.selection.size >= 2) "select_multi" else "select")
        }
    }
    LaunchedEffect(panel, tutorialOn) {
        if (!tutorialOn && guidedStep < 0 && panel != Panel.None) {
            delay(350)
            when (panel) {
                Panel.Insert -> hints.show("panel_insert")
                Panel.Align -> hints.show("panel_align")
                Panel.Layers -> hints.show("panel_layers")
                Panel.Style -> hints.show(if (state.selection.isEmpty()) "style_project" else "style_layer")
                else -> {}
            }
        }
    }
    val anyBlur = state.nodes.any { it.visible && it.blur > 0.5f }
    LaunchedEffect(anyBlur, tutorialOn, guidedStep) { if (anyBlur && !tutorialOn && guidedStep < 0) hints.show("style_blur") }
    LaunchedEffect(state.multi, tutorialOn, guidedStep) { if (!tutorialOn && guidedStep < 0 && state.multi) hints.show("multi_mode") }

    val statusTop = WindowInsets.statusBars.getTop(density)
    val navBottom = with(density) { WindowInsets.navigationBars.getBottom(this) }

    // --- вписать лист в экран при открытии
    LaunchedEffect(state.viewSize, state.fitted) {
        if (!state.fitted && state.viewSize.width > 0) {
            val d = density.density
            state.fit(topInset = statusTop + 64 * d, bottomInset = navBottom + 96 * d, padding = 24 * d)
        }
    }

    // --- автосохранение (debounce: новый rev отменяет ожидание)
    // rev читается только внутри snapshotFlow: экран не перекомпонуется на каждый кадр перетаскивания
    LaunchedEffect(state) {
        snapshotFlow { state.rev }
            .drop(1)
            .debounce(700)
            .collect { controller.saveEditor() }
    }

    if (guide) GestureSettingsDialog(controller.gestures, onTutorial = { controller.replayOnboarding() }) { guide = false }

    // --- экспорт
    val pngLauncher = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("image/png")) { uri ->
        if (uri != null) scope.launch {
            val project = state.toProject()
            val ok = withContext(Dispatchers.Default) {
                runCatching {
                    val bytes = renderPng(project, exportScale.toFloat())
                    context.contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
                }.isSuccess
            }
            Toast.makeText(context, if (ok) tr("png_saved") else tr("save_failed"), Toast.LENGTH_SHORT).show()
        }
    }
    // проект целиком: файлы Kotlin по экранам, VexelApp, картинки в res/drawable, README и зависимости
    val zipLauncher = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/zip")) { uri ->
        if (uri != null) scope.launch {
            val project = state.toProject()
            val pkg = zipPackage
            val ok = withContext(Dispatchers.Default) {
                runCatching {
                    val ca = zipKind == "ca"
                    val r = if (ca) com.qwenz.qwel.data.ProjectExport.buildCodeAssist(com.qwenz.qwel.render.withoutLibraryShapes(project), pkg, com.qwenz.qwel.render.Fonts::exportFaces)
                    else com.qwenz.qwel.data.ProjectExport.build(project, pkg, pkg, com.qwenz.qwel.render.Fonts::exportFaces)
                    val root = com.qwenz.qwel.data.ComposeCode.functionName(project.name).let { if (it.startsWith("Screen") && it.length <= 6) "vexel-export" else it.lowercase() + (if (ca) "-codeassist" else "-vexel") } + "/"
                    context.contentResolver.openOutputStream(uri)?.use { out ->
                        java.util.zip.ZipOutputStream(out.buffered()).use { zip ->
                            for ((path, text) in r.files) {
                                zip.putNextEntry(java.util.zip.ZipEntry(root + path)); zip.write(text.toByteArray(Charsets.UTF_8)); zip.closeEntry()
                            }
                            for ((asset, path) in r.images) {
                                val f = com.qwenz.qwel.render.Assets.file(asset)
                                if (!f.exists()) continue
                                zip.putNextEntry(java.util.zip.ZipEntry(root + path)); zip.write(f.readBytes()); zip.closeEntry()
                            }
                            for ((path, fw) in r.fonts) {
                                val d = com.qwenz.qwel.render.Fonts.embedData(fw.first, fw.second) ?: continue
                                zip.putNextEntry(java.util.zip.ZipEntry(root + path)); zip.write(d.first); zip.closeEntry()
                            }
                        }
                    }
                }.isSuccess
            }
            Toast.makeText(context, if (ok) tr("compose_project_saved") else tr("save_failed"), Toast.LENGTH_SHORT).show()
        }
    }
    val svgLauncher = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("image/svg+xml")) { uri ->
        if (uri != null) scope.launch {
            val project = state.toProject()
            val ok = withContext(Dispatchers.Default) {
                runCatching {
                    val bytes = toSvg(project).toByteArray()
                    context.contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
                }.isSuccess
            }
            Toast.makeText(context, if (ok) tr("svg_saved") else tr("save_failed"), Toast.LENGTH_SHORT).show()
        }
    }

    val svgImportLauncher = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) scope.launch {
            val w = state.width; val h = state.height
            val res = withContext(Dispatchers.IO) {
                runCatching {
                    context.contentResolver.openInputStream(uri)?.use { it.readBytes() }?.let { SvgImport.parse(it, w, h) }
                }.getOrNull()
            }
            when {
                res == null -> Toast.makeText(context, tr("svg_import_failed"), Toast.LENGTH_LONG).show()
                res.nodes.isEmpty() -> Toast.makeText(context, tr("svg_import_empty"), Toast.LENGTH_LONG).show()
                else -> {
                    state.addNodes(res.nodes)
                    panel = Panel.None
                    val msg = tr("svg_imported", res.nodes.size) +
                        (if (res.skipped > 0) " " + tr("svg_skipped", res.skipped) else "") +
                        (if (res.approximated) " " + tr("svg_approx") else "")
                    Toast.makeText(context, msg, Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    // пипетка: пока она включена, прячем панели и один раз рисуем снимок листа, по которому берём цвета
    val eyedropOn = state.eyedrop != null
    LaunchedEffect(eyedropOn) {
        if (eyedropOn) {
            panel = Panel.None; dockOpen = false
            val project = state.toProject()
            state.eyedropImage = withContext(Dispatchers.Default) { runCatching { renderPreview(project, 1200) }.getOrNull() }
        } else state.eyedropImage = null
    }

    BackHandler {
        when {
            state.play -> state.stopPlay()
            state.eyedrop != null -> state.eyedrop = null
            dockOpen -> dockOpen = false
            panel != Panel.None -> panel = Panel.None
            state.selection.isNotEmpty() -> state.clearSelection()
            else -> onBack()
        }
    }

    // содержимое холста пишется в графический слой - панели-'стекло' размывают именно его
    val backdropLayer = rememberGraphicsLayer()
    val backdropSource = remember(backdropLayer) { BackdropSource(backdropLayer) }
    // смена экрана проекта: холст чуть съезжает в сторону перехода и возвращается пружиной
    val pageSlide = remember { androidx.compose.animation.core.Animatable(0f) }
    var lastPage by remember { mutableStateOf(state.activePage) }
    LaunchedEffect(state.activePage) {
        if (state.activePage != lastPage) {
            val dir = if (state.activePage > lastPage) 1f else -1f
            lastPage = state.activePage
            pageSlide.snapTo(0.12f * dir)
            pageSlide.animateTo(0f, Motion.spatial())
        }
    }
    val glass = controller.glassUi && android.os.Build.VERSION.SDK_INT >= 31
    CompositionLocalProvider(LocalBackdrop provides (if (glass) backdropSource else null)) {
    Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.surfaceContainer)) {
        EditorCanvas(
            state = state,
            onEditText = { editTextId = it },
            onOpenStyle = { panel = Panel.Style },
            onLongPressEmpty = { panel = Panel.Insert },
            gestures = controller.gestures,
            modifier = Modifier
                .graphicsLayer { translationX = pageSlide.value * size.width; alpha = (1f - kotlin.math.abs(pageSlide.value) * 2f).coerceIn(0f, 1f) }
                .onGloballyPositioned { backdropSource.origin = it.positionInRoot() }
                .drawWithContent {
                    if (glass) {
                        backdropLayer.record(
                            this, layoutDirection, IntSize(size.width.toInt().coerceAtLeast(1), size.height.toInt().coerceAtLeast(1)),
                        ) { this@drawWithContent.drawContent() }
                        drawLayer(backdropLayer)
                    } else drawContent()
                },
        )

        // ------------------------------------------------ верхняя панель
        Row(
            Modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = 8.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Surface(shape = CircleShape, color = MaterialTheme.colorScheme.surfaceContainerHigh, shadowElevation = 2.dp) {
                QIconButton(Ico.Back, onBack, label = tr("back"))
            }
            Surface(
                shape = CircleShape, color = MaterialTheme.colorScheme.surfaceContainerHigh, shadowElevation = 2.dp,
                modifier = Modifier.weight(1f, fill = false).clip(CircleShape).clickable { renaming = true },
            ) {
                Text(
                    if (state.pages.size > 1) "${state.name} | ${state.activePage + 1}/${state.pages.size}" else state.name,
                    Modifier.padding(horizontal = 18.dp, vertical = 13.dp),
                    style = MaterialTheme.typography.titleSmall, maxLines = 1, overflow = TextOverflow.Ellipsis,
                )
            }
            Box(Modifier.weight(0.01f))
            Surface(shape = CircleShape, color = MaterialTheme.colorScheme.surfaceContainerHigh, shadowElevation = 2.dp) {
                Row {
                    QIconButton(
                        if (state.play) Ico.Stop else Ico.Play,
                        {
                            if (state.play) state.stopPlay() else {
                                panel = Panel.None; dockOpen = false
                                if (!com.qwenz.qwel.data.PlayMode.hasWidgets(state.nodes) && state.nodes.none { it.action.isNotEmpty() }) {
                                    Toast.makeText(context, tr("play_none"), Toast.LENGTH_LONG).show()
                                }
                                state.startPlay()
                            }
                        },
                        label = tr(if (state.play) "play_stop" else "play"), selected = state.play,
                    )
                    QIconButton(Ico.Undo, { state.undo() }, label = tr("undo"), enabled = state.undoCount > 0 && !state.play)
                    QIconButton(Ico.Redo, { state.redo() }, label = tr("redo"), enabled = state.redoCount > 0 && !state.play)
                    Box {
                        QIconButton(Ico.More, { menu = true }, label = tr("menu"))
                        DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                            DropdownMenuItem(
                                text = { Text(tr("fit_screen")) }, leadingIcon = { QIcon(Ico.Fit) },
                                onClick = { menu = false; state.fitted = false },
                            )
                            DropdownMenuItem(
                                text = { Text(tr("grid_8")) }, leadingIcon = { QIcon(Ico.Grid) },
                                trailingIcon = { if (state.showGrid) QIcon(Ico.Check) },
                                onClick = { state.showGrid = !state.showGrid },
                            )
                            DropdownMenuItem(
                                text = { Text(tr("smart_guides")) }, leadingIcon = { QIcon(Ico.Guides) },
                                trailingIcon = { if (state.smartGuides) QIcon(Ico.Check) },
                                onClick = { state.smartGuides = !state.smartGuides },
                            )
                            DropdownMenuItem(
                                text = { Text(tr("select_all")) }, leadingIcon = { QIcon(Ico.Select) },
                                onClick = { menu = false; state.selectAll() },
                            )
                            DropdownMenuItem(
                                text = { Text(tr("gestures_settings")) }, leadingIcon = { QIcon(Ico.Select) },
                                onClick = { menu = false; guide = true },
                            )
                            DropdownMenuItem(
                                text = { Text(tr("project_tone_menu")) }, leadingIcon = { QIcon(Ico.Style) },
                                onClick = { menu = false; state.clearSelection(); panel = Panel.Style },
                            )
                            DropdownMenuItem(
                                text = { Text(tr("canvas_size_menu")) }, leadingIcon = { QIcon(Ico.Settings) },
                                onClick = { menu = false; state.clearSelection(); panel = Panel.Style },
                            )
                            DropdownMenuItem(
                                text = { Text(tr("screens")) }, leadingIcon = { QIcon(Ico.Screens) },
                                onClick = { menu = false; screensDialog = true },
                            )
                            DropdownMenuItem(
                                text = { Text(tr("import_svg")) }, leadingIcon = { QIcon(Ico.Import) },
                                onClick = { menu = false; svgImportLauncher.launch(arrayOf("*/*")) },
                            )
                            DropdownMenuItem(
                                text = { Text(tr("compose_code")) }, leadingIcon = { QIcon(Ico.Code) },
                                onClick = {
                                    menu = false
                                    val sel = state.selectedNodes()
                                    val project = state.toProject()
                                    val title = state.pages.getOrNull(state.activePage)?.name?.takeIf { state.pages.size > 1 } ?: state.name
                                    codeForSelection = sel.isNotEmpty()
                                    codeDialog = if (sel.isNotEmpty()) ComposeCode.generate(project, sel, title, state.selectionBox())
                                    else ComposeCode.generate(project, project.nodes, title)
                                },
                            )
                            DropdownMenuItem(
                                text = { Text(tr("compose_project")) }, leadingIcon = { QIcon(Ico.Code) },
                                onClick = { menu = false; projectDialog = "module" },
                            )
                            DropdownMenuItem(
                                text = { Text(tr("codeassist_project")) }, leadingIcon = { QIcon(Ico.Code) },
                                onClick = { menu = false; projectDialog = "ca" },
                            )
                            DropdownMenuItem(
                                text = { Text(tr("export_menu")) }, leadingIcon = { QIcon(Ico.Export) },
                                onClick = { menu = false; exportDialog = true },
                            )
                        }
                    }
                }
            }
        }

        if (state.eyedrop != null) {
            Surface(
                shape = RoundedCornerShape(20.dp), color = MaterialTheme.colorScheme.inverseSurface, shadowElevation = 4.dp,
                modifier = Modifier.align(Alignment.TopCenter).statusBarsPadding().padding(top = 72.dp, start = 16.dp, end = 16.dp),
            ) {
                Row(Modifier.padding(start = 18.dp, end = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(tr("eyedrop_hint"), color = MaterialTheme.colorScheme.inverseOnSurface, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f, fill = false))
                    TextButton({ state.eyedrop = null }) { Text(tr("cancel"), color = MaterialTheme.colorScheme.inversePrimary) }
                }
            }
        }

        // ------------------------------------------------ подсказки поверх холста
        LaunchedEffect(state.flashId) { if (state.flash != null) { delay(1100); state.flash = null } }
        AnimatedVisibility(
            visible = state.flash != null,
            enter = fadeIn(Motion.effects()), exit = fadeOut(Motion.effects()),
            modifier = Modifier.align(Alignment.TopCenter).statusBarsPadding().padding(top = 72.dp),
        ) {
            Surface(shape = CircleShape, color = MaterialTheme.colorScheme.inverseSurface, shadowElevation = 4.dp) {
                Text(
                    state.flash.orEmpty(), Modifier.padding(horizontal = 18.dp, vertical = 10.dp),
                    style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.inverseOnSurface,
                )
            }
        }
        if (state.nodes.isEmpty() && panel == Panel.None) {
            Text(
                tr("empty_canvas_hint"), Modifier.align(Alignment.Center).padding(horizontal = 56.dp),
                style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )
        }

        // ------------------------------------------------ нижний блок
        Column(
            Modifier.align(Alignment.BottomCenter).fillMaxWidth()
                .navigationBarsPadding().imePadding()
                .padding(start = 8.dp, end = 8.dp, bottom = 8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            HintCard(hints)

            // экраны проекта: показываем, когда их больше одного, либо маленькую кнопку для первого добавления
            if (state.pages.size > 1 && !state.play) ScreenStrip(state, { screensDialog = true }, Modifier.fillMaxWidth())

            // масштаб
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                Surface(
                    shape = CircleShape, color = MaterialTheme.colorScheme.surfaceContainerHigh, shadowElevation = 2.dp,
                    modifier = Modifier.clip(CircleShape).clickable { state.fitted = false },
                ) {
                    Text(
                        "${(state.scale / density.density * 100).roundToInt()}%",
                        Modifier.padding(horizontal = 14.dp, vertical = 8.dp), style = MaterialTheme.typography.labelLarge,
                    )
                }
                if (state.pages.size == 1 && !state.play) {
                    Surface(shape = CircleShape, color = MaterialTheme.colorScheme.surfaceContainerHigh, shadowElevation = 2.dp) {
                        QIconButton(Ico.Screens, { screensDialog = true }, label = tr("screens"), size = 36.dp)
                    }
                }
            }

            AnimatedVisibility(
                visible = state.selection.isNotEmpty() && !state.play,
                enter = fadeIn(Motion.effects()) + scaleIn(Motion.spatial(), initialScale = 0.85f) + slideInVertically(Motion.spatial<IntOffset>()) { it / 2 },
                exit = fadeOut(Motion.effects()) + scaleOut(Motion.effects(), targetScale = 0.9f),
                modifier = Modifier.align(Alignment.CenterHorizontally),
            ) {
                SelectionDock(
                    state = state, expanded = dockOpen, onExpanded = { dockOpen = it },
                    onEditText = { editTextId = it }, onOpenPanel = { panel = it; dockOpen = false },
                )
            }

            AnimatedVisibility(
                visible = panel != Panel.None,
                enter = fadeIn(Motion.effects()) + slideInVertically(Motion.spatial<IntOffset>()) { it },
                exit = fadeOut(Motion.effects()) + slideOutVertically(Motion.effects<IntOffset>()) { it },
            ) {
                Surface(
                    shape = RoundedCornerShape(28.dp), color = glassColor(MaterialTheme.colorScheme.surfaceContainerLow, 0.985f),
                    shadowElevation = glassElevation(6.dp), border = glassBorder(),
                    modifier = Modifier.fillMaxWidth().frostedGlass(RoundedCornerShape(28.dp))
                        .onGloballyPositioned { insertTarget = it.boundsInRoot() },
                ) {
                    Column(Modifier.padding(start = 16.dp, end = 8.dp, top = 8.dp, bottom = 16.dp)) {
                        // шапку можно потянуть вниз, чтобы закрыть панель
                        Row(
                            Modifier.fillMaxWidth().pointerInput(Unit) {
                                var acc = 0f
                                detectVerticalDragGestures(
                                    onDragStart = { acc = 0f },
                                    onDragEnd = { if (acc > 48.dp.toPx() && controller.gestures.isOn(Gesture.PANEL_SWIPE)) panel = Panel.None },
                                    onDragCancel = { acc = 0f },
                                    onVerticalDrag = { _, dy -> acc += dy },
                                )
                            },
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(panel.title, Modifier.weight(1f), style = MaterialTheme.typography.titleLarge)
                            QIconButton(Ico.Close, { panel = Panel.None }, label = tr("close"))
                        }
                        Column(
                            Modifier.heightIn(max = 340.dp).verticalScroll(rememberScrollState()).padding(end = 8.dp),
                        ) {
                            when (panel) {
                                Panel.Layers -> LayersPanel(state)
                                Panel.Style -> StylePanel(state) { editTextId = it }
                                Panel.Insert -> InsertPanel(state)
                                Panel.Align -> AlignPanel(state)
                                Panel.None -> {}
                            }
                        }
                    }
                }
            }

            if (state.play) {
                Surface(
                    shape = CircleShape, color = MaterialTheme.colorScheme.primaryContainer,
                    modifier = Modifier.align(Alignment.CenterHorizontally).clip(CircleShape).clickable { state.stopPlay() },
                ) {
                    Text(
                        tr("play_banner"), Modifier.padding(horizontal = 20.dp, vertical = 14.dp),
                        style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.onPrimaryContainer,
                    )
                }
            } else Toolbar(
                state, panel,
                onAddBounds = { addTarget = it },
            ) { p -> dockOpen = false; panel = if (panel == p) Panel.None else p }
        }

        // Spotlight over the exact control. It does not consume taps, so the target stays clickable.
        val target = when (guidedStep) {
            0 -> addTarget
            1 -> insertTarget
            else -> null
        }
        if (guidedStep in 0..1) {
            GuidedCoachmark(
                target = target,
                title = tr(if (guidedStep == 0) "guide_add_title" else "guide_insert_title"),
                body = tr(if (guidedStep == 0) "guide_add_body" else "guide_insert_body"),
                skip = tr("guide_skip"),
                onSkip = { hints.markSeen("guided_add"); guidedStep = -1 },
            )
        }
    }
    }

    // ------------------------------------------------ диалоги
    if (renaming) {
        var text by remember { mutableStateOf(state.name) }
        AlertDialog(
            onDismissRequest = { renaming = false },
            title = { Text(tr("project_name")) },
            text = { OutlinedTextField(text, { text = it }, singleLine = true, shape = RoundedCornerShape(16.dp)) },
            confirmButton = { TextButton({ state.rename(text); renaming = false }) { Text(tr("done")) } },
            dismissButton = { TextButton({ renaming = false }) { Text(tr("cancel")) } },
        )
    }
    state.playUrl?.let { raw ->
        LaunchedEffect(raw) {
            val url = if (raw.startsWith("http://") || raw.startsWith("https://")) raw else "https://$raw"
            runCatching { context.startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(url)).addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)) }
            state.playUrl = null
        }
    }
    if (screensDialog) ScreensDialog(state) { screensDialog = false }
    state.effect?.let { kind ->
        val sel = state.selectedNodes()
        when {
            kind == "echo" && sel.size == 1 -> EchoDialog(state, sel[0]) { state.effect = null }
            kind == "blend" && sel.size == 2 -> BlendDialog(state, sel[0], sel[1]) { state.effect = null }
            else -> LaunchedEffect(kind) { state.effect = null }
        }
    }
    projectDialog?.let { kind ->
        ProjectExportDialog(kind == "ca", { projectDialog = null }) { pkg -> zipPackage = pkg; zipKind = kind; zipLauncher.launch(if (kind == "ca") "vexel-codeassist.zip" else "vexel-project.zip") }
    }
    codeDialog?.let { code -> ComposeCodeDialog(code, codeForSelection) { codeDialog = null } }
    if (exportDialog) {
        AlertDialog(
            onDismissRequest = { exportDialog = false },
            title = { Text(tr("export")) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    val snapshot = remember { state.toProject() }
                    val hasBlur = snapshot.nodes.any { it.visible && it.blur > 0.5f }
                    val shot by produceState<ImageBitmap?>(null) {
                        value = withContext(Dispatchers.Default) { runCatching { renderPreview(snapshot, 640) }.getOrNull() }
                    }
                    Box(
                        Modifier.fillMaxWidth().heightIn(min = 120.dp, max = 240.dp).clip(RoundedCornerShape(20.dp))
                            .background(MaterialTheme.colorScheme.surfaceContainerHighest),
                        contentAlignment = Alignment.Center,
                    ) {
                        val img = shot
                        if (img == null) CircularProgressIndicator(Modifier.size(28.dp), strokeWidth = 3.dp)
                        else Image(img, null, Modifier.fillMaxWidth().heightIn(max = 240.dp).padding(8.dp), contentScale = ContentScale.Fit)
                    }
                    if (state.pages.size > 1) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            Switch(exportAll, { exportAll = it })
                            Text(tr("export_all_screens", state.pages.size), style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
                        }
                    }
                    if (exportSvg && hasBlur) {
                        Text(tr("svg_no_blur"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.error)
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        FilterChip(selected = !exportSvg, onClick = { exportSvg = false }, label = { Text("PNG") })
                        FilterChip(selected = exportSvg, onClick = { exportSvg = true }, label = { Text("SVG") })
                    }
                    if (!exportSvg) {
                        Text(tr("scale"), style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            for (k in 1..4) FilterChip(selected = exportScale == k, onClick = { exportScale = k }, label = { Text("${k}x") })
                        }
                        Text(
                            "${(state.width * exportScale).roundToInt()}x${(state.height * exportScale).roundToInt()} px",
                            style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    Button(
                        onClick = {
                            exportDialog = false
                            val project = state.toProject()
                            val targets = if (exportAll && state.pages.size > 1) project.pageProjects()
                            else listOf(project.copy(pages = emptyList(), activePage = 0))
                            for (pr in targets) {
                                if (exportSvg) saveToGallery(Gallery.safeName(pr.name, "svg"), "image/svg+xml") { toSvg(pr).toByteArray() }
                                else saveToGallery(Gallery.safeName(pr.name, "png"), "image/png") { renderPng(pr, exportScale.toFloat()) }
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                    ) { Text(tr("to_gallery", Gallery.SHOWN)) }
                    OutlinedButton(
                        onClick = {
                            exportDialog = false
                            if (exportSvg) svgLauncher.launch("${state.name}.svg") else pngLauncher.launch("${state.name}.png")
                        },
                        modifier = Modifier.fillMaxWidth(),
                    ) { Text(tr("to_folder")) }
                }
            },
            confirmButton = { TextButton({ exportDialog = false }) { Text(tr("close")) } },
        )
    }
    editTextId?.let { id ->
        val node = state.nodes.firstOrNull { it.id == id && it.kind == NodeKind.TEXT }
        if (node == null) editTextId = null else {
            var text by remember(id) { mutableStateOf(node.text) }
            AlertDialog(
                onDismissRequest = { editTextId = null },
                title = { Text(tr("text")) },
                text = { OutlinedTextField(text, { text = it }, minLines = 2, shape = RoundedCornerShape(16.dp)) },
                confirmButton = {
                    TextButton({
                        val t = text.ifEmpty { " " }
                        state.updateNode(id) { it.copy(text = t, name = if (it.name == it.text) t.take(24) else it.name).withTextSize() }
                        editTextId = null
                    }) { Text(tr("done")) }
                },
                dismissButton = { TextButton({ editTextId = null }) { Text(tr("cancel")) } },
            )
        }
    }
}

@Composable
private fun Toolbar(state: EditorState, panel: Panel, onAddBounds: (Rect) -> Unit, onPanel: (Panel) -> Unit) {
    Surface(
        shape = CircleShape, color = glassColor(MaterialTheme.colorScheme.surfaceContainerHigh), shadowElevation = glassElevation(6.dp),
        border = glassBorder(), modifier = Modifier.fillMaxWidth().frostedGlass(CircleShape),
    ) {
        Row(
            Modifier.padding(horizontal = 8.dp, vertical = 6.dp).fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            ToolButton(Ico.Layers, tr("layers"), panel == Panel.Layers) { onPanel(Panel.Layers) }
            ToolButton(Ico.Style, tr("style"), panel == Panel.Style) { onPanel(Panel.Style) }
            AddButton(open = panel == Panel.Insert, onBounds = onAddBounds) { onPanel(Panel.Insert) }
            ToolButton(Ico.Align, tr("align_short"), panel == Panel.Align) { onPanel(Panel.Align) }
            ToolButton(Ico.Multi, tr("multi_short"), state.multi) { state.multi = !state.multi }
        }
    }
}

/** Кнопка нижней панели с подписью - по иконке одной не всегда понятно, что она делает. */
@Composable
private fun ToolButton(ico: Ico, label: String, selected: Boolean, onClick: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        QIconButton(ico, onClick, label = label, selected = selected)
        Text(
            label, style = MaterialTheme.typography.labelSmall, maxLines = 1,
            color = if (selected) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

/** Главная кнопка: 'печенька' превращается в 'мягкую вспышку', плюс поворачивается в крестик. */
@Composable
private fun AddButton(open: Boolean, onBounds: (Rect) -> Unit, onClick: () -> Unit) {
    val p by animateFloatAsState(if (open) 1f else 0f, Motion.spatial(), label = "add")
    val morph = remember { ShapeLibrary.morph("cookie-9", "soft-burst") }
    val shape: Shape = morph?.let { CubicsShape(it.asCubics(p)) } ?: CircleShape
    Box(
        Modifier.size(60.dp).onGloballyPositioned { onBounds(it.boundsInRoot()) }.clip(shape).background(MaterialTheme.colorScheme.primary).clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        QIcon(
            Ico.Add, Modifier.graphicsLayer { rotationZ = 45f * p },
            tint = MaterialTheme.colorScheme.onPrimary, size = 28.dp,
        )
    }
}


@Composable
private fun GuidedCoachmark(
    target: Rect?,
    title: String,
    body: String,
    skip: String,
    onSkip: () -> Unit,
) {
    val density = LocalDensity.current
    Box(Modifier.fillMaxSize()) {
        if (target != null) {
            val left = with(density) { target.left.toDp() }
            val top = with(density) { target.top.toDp() }
            val width = with(density) { target.width.toDp() }
            val height = with(density) { target.height.toDp() }
            Box(
                Modifier.offset(x = left - 7.dp, y = top - 7.dp)
                    .size(width = width + 14.dp, height = height + 14.dp)
                    .border(3.dp, MaterialTheme.colorScheme.primary, RoundedCornerShape(24.dp))
                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.09f), RoundedCornerShape(24.dp)),
            )
        }
        Surface(
            modifier = Modifier.align(Alignment.TopCenter).statusBarsPadding()
                .padding(horizontal = 20.dp).padding(top = 84.dp).fillMaxWidth(),
            shape = MaterialTheme.shapes.extraLarge,
            color = MaterialTheme.colorScheme.secondaryContainer,
            tonalElevation = 3.dp,
            shadowElevation = 5.dp,
        ) {
            Column(Modifier.padding(start = 18.dp, end = 10.dp, top = 14.dp, bottom = 8.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    QIcon(Ico.Select, tint = MaterialTheme.colorScheme.onSecondaryContainer, size = 20.dp)
                    Text(title, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSecondaryContainer)
                }
                Text(body, Modifier.padding(top = 6.dp), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSecondaryContainer)
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                    TextButton(onClick = onSkip) { Text(skip) }
                }
            }
        }
    }
}
