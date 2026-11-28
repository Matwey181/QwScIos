@file:OptIn(ExperimentalMaterial3Api::class)

package com.qwenz.qwel.ui.projects

import com.qwenz.qwel.i18n.I18n
import kotlinx.coroutines.delay
import androidx.compose.runtime.LaunchedEffect
import com.qwenz.qwel.i18n.tr

import android.os.Build
import android.widget.Toast
import com.qwenz.qwel.render.SvgImport
import java.io.ByteArrayInputStream
import android.provider.OpenableColumns
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.runtime.produceState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.LocalIndication
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.border
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.qwenz.qwel.AppController
import com.qwenz.qwel.data.Project
import com.qwenz.qwel.data.ProjectArchive
import com.qwenz.qwel.data.ProjectTemplate
import com.qwenz.qwel.data.Templates
import com.qwenz.qwel.data.Tone
import com.qwenz.qwel.render.Gallery
import com.qwenz.qwel.ui.common.ProjectThumb
import com.qwenz.qwel.render.renderPng
import com.qwenz.qwel.ui.common.QwelLogo
import com.qwenz.qwel.ui.common.rememberGallerySaver
import com.qwenz.qwel.ui.editor.SeedPresets
import com.qwenz.qwel.ui.editor.dynamicTone
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import com.qwenz.qwel.ui.common.Ico
import com.qwenz.qwel.ui.common.MorphingShape
import com.qwenz.qwel.ui.common.NumberField
import com.qwenz.qwel.ui.common.QIcon
import com.qwenz.qwel.ui.common.QIconButton
import com.qwenz.qwel.ui.common.AppearanceSettings
import com.qwenz.qwel.ui.common.SectionTitle
import com.qwenz.qwel.ui.theme.Motion
import kotlin.math.roundToInt

private val Presets get() = listOf(
    Triple(tr("preset_phone"), 360f, 800f), Triple(tr("preset_compact"), 360f, 640f), Triple(tr("preset_tablet"), 834f, 1194f),
    Triple(tr("preset_square"), 512f, 512f), Triple(tr("preset_desktop"), 1280f, 800f),
)

@Composable
fun ProjectsScreen(controller: AppController, onOpen: (Project) -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val saveToGallery = rememberGallerySaver()
    var query by remember { mutableStateOf("") }
    val q = query.trim()
    val projects = controller.projects
        .filter { q.isEmpty() || it.name.contains(q, ignoreCase = true) }
        .let { list ->
            when (controller.sortMode) {
                1 -> list.sortedBy { it.name.lowercase() }
                2 -> list.sortedByDescending { it.width * it.height }
                else -> list.sortedByDescending { it.updated }
            }
        }
    val gridState = rememberLazyGridState()
    var creating by remember { mutableStateOf(false) }
    var settings by remember { mutableStateOf(false) }
    var renaming by remember { mutableStateOf<Project?>(null) }
    var deleting by remember { mutableStateOf<Project?>(null) }
    var exporting by remember { mutableStateOf<Project?>(null) }

    // --- импорт проекта: .qwel или SVG (тип определяем по содержимому, а не по имени файла)
    val importLauncher = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) scope.launch {
            val displayName = withContext(Dispatchers.IO) {
                runCatching {
                    context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                        ?.use { c -> if (c.moveToFirst()) c.getString(0) else null }
                }.getOrNull()
            }?.substringBeforeLast('.')?.takeIf { it.isNotBlank() } ?: tr("imported_drawing")
            val bytes = withContext(Dispatchers.IO) {
                runCatching { context.contentResolver.openInputStream(uri)?.use { it.readBytes() } }.getOrNull()
            }
            if (bytes == null) {
                Toast.makeText(context, tr("project_open_failed"), Toast.LENGTH_SHORT).show()
                return@launch
            }
            val isZip = bytes.size > 2 && bytes[0] == 'P'.code.toByte() && bytes[1] == 'K'.code.toByte()
            if (isZip) {
                val p = withContext(Dispatchers.Default) { runCatching { ProjectArchive.import(ByteArrayInputStream(bytes)) }.getOrNull() }
                if (p == null) Toast.makeText(context, tr("project_open_failed"), Toast.LENGTH_SHORT).show()
                else { controller.importProject(p); Toast.makeText(context, tr("project_added", p.name), Toast.LENGTH_SHORT).show() }
            } else {
                val made = withContext(Dispatchers.Default) { runCatching { SvgImport.toProject(bytes, displayName) }.getOrNull() }
                when {
                    made == null -> Toast.makeText(context, tr("import_unknown_file"), Toast.LENGTH_LONG).show()
                    made.second.nodes.isEmpty() -> Toast.makeText(context, tr("svg_import_empty"), Toast.LENGTH_LONG).show()
                    else -> {
                        val (p, r) = made
                        controller.importProject(p)
                        val note = (if (r.skipped > 0) " " + tr("svg_skipped", r.skipped) else "") + (if (r.approximated) " " + tr("svg_approx") else "")
                        Toast.makeText(context, tr("project_added", p.name) + note, Toast.LENGTH_LONG).show()
                    }
                }
            }
        }
    }
    val exportLauncher = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/octet-stream")) { uri ->
        val p = exporting
        exporting = null
        if (uri != null && p != null) scope.launch {
            val ok = withContext(Dispatchers.IO) {
                runCatching { context.contentResolver.openOutputStream(uri)?.use { ProjectArchive.export(p, it) } }.isSuccess
            }
            Toast.makeText(context, if (ok) tr("project_saved") else tr("save_failed"), Toast.LENGTH_SHORT).show()
        }
    }

    Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.surface)) {
        LazyVerticalGrid(
            columns = if (controller.viewList) GridCells.Fixed(1) else GridCells.Adaptive(168.dp),
            state = gridState,
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(
                start = 16.dp, end = 16.dp,
                top = WindowInsets.statusBars.asPaddingValues().calculateTopPadding() + 8.dp,
                bottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding() + 112.dp,
            ),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item(span = { GridItemSpan(maxLineSpan) }) {
                Header(
                    onSettings = { settings = true },
                    onImport = { importLauncher.launch(arrayOf("*/*")) },
                )
            }

            if (!controller.loaded) {
                item(span = { GridItemSpan(maxLineSpan) }) {
                    Box(Modifier.fillMaxWidth().height(200.dp), contentAlignment = Alignment.Center) {
                        MorphingShape(Modifier.size(96.dp))
                    }
                }
            } else if (controller.projects.isEmpty()) {
                item(span = { GridItemSpan(maxLineSpan) }) { EmptyState() }
            } else {
                item(span = { GridItemSpan(maxLineSpan) }) {
                    Toolbar(controller, query, { query = it })
                }
                if (projects.isEmpty()) {
                    item(span = { GridItemSpan(maxLineSpan) }) {
                        Text(
                            tr("nothing_found"), Modifier.fillMaxWidth().padding(vertical = 40.dp),
                            style = MaterialTheme.typography.bodyLarge, textAlign = TextAlign.Center,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
                items(projects, key = { it.id }) { p ->
                    ProjectCard(
                        p, list = controller.viewList, onClick = { onOpen(p) },
                        onRename = { renaming = p }, onDuplicate = { controller.duplicate(p.id) }, onDelete = { deleting = p },
                        onSavePng = {
                            saveToGallery(Gallery.safeName(p.name, "png"), "image/png") { renderPng(p, controller.exportScale.toFloat()) }
                        },
                        onExport = { exporting = p; exportLauncher.launch(Gallery.safeName(p.name, "qwel")) },
                    )
                }
            }
        }

        val tutorialOn = controller.showTutorial
        LaunchedEffect(tutorialOn) { if (!tutorialOn) { delay(800); controller.hints.show("projects") } }
        com.qwenz.qwel.ui.editor.HintCard(
            controller.hints,
            Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(start = 12.dp, end = 12.dp, bottom = 88.dp),
        )

        ExtendedFloatingActionButton(
            text = { Text(tr("new_project")) },
            icon = { QIcon(Ico.Add, tint = MaterialTheme.colorScheme.onPrimaryContainer) },
            onClick = { creating = true },
            expanded = !gridState.canScrollBackward || !gridState.canScrollForward,
            shape = RoundedCornerShape(20.dp),
            containerColor = MaterialTheme.colorScheme.primaryContainer,
            contentColor = MaterialTheme.colorScheme.onPrimaryContainer,
            modifier = Modifier.align(Alignment.BottomEnd).navigationBarsPadding().padding(16.dp),
        )
    }

    AnimatedVisibility(creating, enter = slideInHorizontally(tween(260)) { it / 3 } + fadeIn(tween(260)),
        exit = slideOutHorizontally(tween(200)) { it / 3 } + fadeOut(tween(200))) {
        NewProjectSheet(onDismiss = { creating = false }) { name, w, h, tone, tpl -> creating = false; controller.create(name, w, h, tone, tpl) }
    }
    AnimatedVisibility(settings, enter = slideInHorizontally(tween(260)) { it / 3 } + fadeIn(tween(260)),
        exit = slideOutHorizontally(tween(200)) { it / 3 } + fadeOut(tween(200))) {
        SettingsSheet(controller) { settings = false }
    }

    renaming?.let { p ->
        var text by remember(p.id) { mutableStateOf(p.name) }
        AlertDialog(
            onDismissRequest = { renaming = null },
            title = { Text(tr("rename")) },
            text = { OutlinedTextField(text, { text = it }, singleLine = true, shape = RoundedCornerShape(16.dp)) },
            confirmButton = { TextButton({ controller.rename(p.id, text); renaming = null }) { Text(tr("done")) } },
            dismissButton = { TextButton({ renaming = null }) { Text(tr("cancel")) } },
        )
    }
    deleting?.let { p ->
        AlertDialog(
            onDismissRequest = { deleting = null },
            title = { Text(tr("delete_project_q")) },
            text = { Text(tr("delete_project_msg", p.name)) },
            confirmButton = { TextButton({ controller.delete(p.id); deleting = null }) { Text(tr("delete")) } },
            dismissButton = { TextButton({ deleting = null }) { Text(tr("cancel")) } },
        )
    }
}

@Composable
private fun Header(onSettings: () -> Unit, onImport: () -> Unit) {
    Column(Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 4.dp)) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            QwelLogo(Modifier.size(56.dp))
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text("Vexel", style = MaterialTheme.typography.headlineMedium, color = MaterialTheme.colorScheme.onSurface)
                Text(
                    tr("tagline"),
                    style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            QIconButton(Ico.Import, onImport, label = tr("open_project"), tonal = true)
            Spacer(Modifier.width(8.dp))
            QIconButton(Ico.Settings, onSettings, label = tr("settings"), tonal = true)
        }
    }
}

/** Поиск, сортировка и вид списка. */
@Composable
private fun Toolbar(controller: AppController, query: String, onQuery: (String) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        OutlinedTextField(
            value = query, onValueChange = onQuery, singleLine = true,
            placeholder = { Text(tr("search_projects")) },
            leadingIcon = { QIcon(Ico.Search, tint = MaterialTheme.colorScheme.onSurfaceVariant) },
            trailingIcon = { if (query.isNotEmpty()) QIconButton(Ico.Close, { onQuery("") }, label = tr("clear"), size = 40.dp) },
            shape = RoundedCornerShape(28.dp), modifier = Modifier.fillMaxWidth(),
        )
        Row(verticalAlignment = Alignment.CenterVertically) {
            LazyRow(Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items(listOf(tr("sort_recent"), tr("sort_name"), tr("sort_size"))) { t ->
                    val i = when (t) { tr("sort_recent") -> 0; tr("sort_name") -> 1; else -> 2 }
                    FilterChip(selected = controller.sortMode == i, onClick = { controller.updateSortMode(i) }, label = { Text(t) })
                }
            }
            QIconButton(
                if (controller.viewList) Ico.Components else Ico.List,
                { controller.updateViewList(!controller.viewList) },
                label = if (controller.viewList) tr("grid") else tr("list"),
            )
        }
    }
}

@Composable
private fun EmptyState() {
    Column(
        Modifier.fillMaxWidth().padding(vertical = 56.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        MorphingShape(Modifier.size(140.dp), color = MaterialTheme.colorScheme.tertiary)
        Text(tr("no_projects"), style = MaterialTheme.typography.titleLarge)
        Text(
            tr("no_projects_hint"),
            style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun ProjectCard(
    p: Project, list: Boolean, onClick: () -> Unit, onRename: () -> Unit, onDuplicate: () -> Unit,
    onDelete: () -> Unit, onSavePng: () -> Unit, onExport: () -> Unit,
) {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    // 'живая' форма: при нажатии карточка становится круглее
    val corner by animateDpAsState(if (pressed) 40.dp else 28.dp, Motion.spatial(), label = "card")
    var menu by remember { mutableStateOf(false) }
    val scheme = MaterialTheme.colorScheme

    @Composable
    fun Menu() {
        Box {
            QIconButton(Ico.More, { menu = true }, label = tr("actions"), size = 44.dp)
            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                DropdownMenuItem(text = { Text(tr("rename")) }, leadingIcon = { QIcon(Ico.Edit) }, onClick = { menu = false; onRename() })
                DropdownMenuItem(text = { Text(tr("duplicate")) }, leadingIcon = { QIcon(Ico.Duplicate) }, onClick = { menu = false; onDuplicate() })
                DropdownMenuItem(text = { Text(tr("png_to_pictures")) }, leadingIcon = { QIcon(Ico.Export) }, onClick = { menu = false; onSavePng() })
                DropdownMenuItem(text = { Text(tr("save_as_qwel")) }, leadingIcon = { QIcon(Ico.Export) }, onClick = { menu = false; onExport() })
                DropdownMenuItem(text = { Text(tr("delete")) }, leadingIcon = { QIcon(Ico.Delete) }, onClick = { menu = false; onDelete() })
            }
        }
    }

    @Composable
    fun Titles(mod: Modifier) {
        Column(mod) {
            Text(
                p.name, style = MaterialTheme.typography.titleMedium, color = scheme.onSurface,
                maxLines = 1, overflow = TextOverflow.Ellipsis,
            )
            Text(
                "${p.width.roundToInt()}x${p.height.roundToInt()} | ${ago(p.updated)}",
                style = MaterialTheme.typography.labelMedium, color = scheme.onSurfaceVariant,
                maxLines = 1, overflow = TextOverflow.Ellipsis,
            )
        }
    }

    if (list) {
        Row(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(corner)).background(scheme.surfaceContainerLow)
                .clickable(interactionSource = source, indication = LocalIndication.current, onClick = onClick)
                .padding(start = 8.dp, top = 8.dp, bottom = 8.dp, end = 2.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(Modifier.size(72.dp).clip(RoundedCornerShape(20.dp)).background(scheme.surfaceContainerHighest)) {
                ProjectThumb(p, inset = 8.dp, persist = true)
            }
            Spacer(Modifier.width(14.dp))
            Titles(Modifier.weight(1f))
            Menu()
        }
    } else {
        Column(
            Modifier.clip(RoundedCornerShape(corner)).background(scheme.surfaceContainerLow)
                .clickable(interactionSource = source, indication = LocalIndication.current, onClick = onClick),
        ) {
            Box(
                Modifier.fillMaxWidth().aspectRatio(1f).padding(8.dp).clip(RoundedCornerShape(20.dp))
                    .background(scheme.surfaceContainerHighest),
            ) {
                ProjectThumb(p, inset = 14.dp, persist = true)
            }
            Row(Modifier.padding(start = 14.dp, end = 2.dp, bottom = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                Titles(Modifier.weight(1f))
                Menu()
            }
        }
    }
}

private fun ago(t: Long): String {
    val m = (System.currentTimeMillis() - t) / 60000
    return when {
        m < 1 -> tr("just_now")
        m < 60 -> tr("min_ago", m)
        m < 60 * 24 -> tr("hours_ago", m / 60)
        m < 60 * 24 * 30 -> tr("days_ago", m / (60 * 24))
        else -> java.text.SimpleDateFormat("d MMM yyyy", java.util.Locale.getDefault()).format(java.util.Date(t))
    }
}

@Composable
private fun NewProjectSheet(onDismiss: () -> Unit, onCreate: (String, Float, Float, Tone, ProjectTemplate?) -> Unit) {
    val context = LocalContext.current
    var name by remember { mutableStateOf(tr("new_project")) }
    var w by remember { mutableFloatStateOf(360f) }
    var h by remember { mutableFloatStateOf(800f) }
    var dark by remember { mutableStateOf(false) }
    var seed by remember { mutableStateOf<Int?>(null) }   // null - базовая схема
    var dynamic by remember { mutableStateOf(false) }
    var template by remember { mutableStateOf<ProjectTemplate?>(null) }
    val canDynamic = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
    val tone = when {
        dynamic && canDynamic -> dynamicTone(context, dark)
        seed != null -> Tone.fromSeed(seed!!, dark)
        else -> Tone.baseline(dark)
    }
    SubScreen(tr("new_project"), onDismiss) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).navigationBarsPadding().imePadding()
                .padding(horizontal = 24.dp).padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            OutlinedTextField(
                name, { name = it }, label = { Text(tr("name")) }, singleLine = true,
                shape = RoundedCornerShape(16.dp), modifier = Modifier.fillMaxWidth(),
            )
            Column {
                SectionTitle(tr("template_hint"))
                LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    item {
                        TemplateTile(tr("blank"), template == null, null) {
                            if (name == template?.name) name = tr("new_project")
                            template = null
                        }
                    }
                    items(Templates.all, key = { it.id }) { tpl ->
                        val preview by produceState<Project?>(null, tpl.id, tone) {
                            value = withContext(Dispatchers.Default) { runCatching { tpl.toProject(tpl.name, tone) }.getOrNull() }
                        }
                        TemplateTile(tpl.name, template?.id == tpl.id, preview) {
                            if (name == tr("new_project") || name == template?.name) name = tpl.name
                            template = tpl; w = tpl.width; h = tpl.height
                        }
                    }
                }
                template?.let {
                    Text(it.description, Modifier.padding(top = 6.dp), style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            if (template == null) Column {
                SectionTitle(tr("canvas_size_dp"))
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(Presets) { (label, pw, ph) ->
                        FilterChip(
                            selected = w == pw && h == ph, onClick = { w = pw; h = ph },
                            label = { Text("$label ${pw.roundToInt()}x${ph.roundToInt()}") },
                        )
                    }
                }
            }
            if (template == null) Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                NumberField(tr("width"), w, { w = it.coerceIn(16f, 4096f) }, Modifier.weight(1f))
                NumberField(tr("height"), h, { h = it.coerceIn(16f, 4096f) }, Modifier.weight(1f))
            }
            Column {
                SectionTitle(tr("project_tone"))
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    item {
                        FilterChip(selected = seed == null && !dynamic, onClick = { seed = null; dynamic = false }, label = { Text(tr("tone_base")) })
                    }
                    if (canDynamic) item {
                        FilterChip(selected = dynamic, onClick = { dynamic = true; seed = null }, label = { Text(tr("tone_wallpaper")) })
                    }
                    items(SeedPresets) { c ->
                        val selected = !dynamic && seed == c
                        Box(
                            Modifier.size(36.dp).clip(CircleShape).background(Color(c))
                                .border(if (selected) 3.dp else 1.dp,
                                    if (selected) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.outlineVariant, CircleShape)
                                .clickable { seed = c; dynamic = false },
                        )
                    }
                }
                Row(Modifier.padding(top = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(tr("dark_scheme"), Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurface)
                    Switch(dark, { dark = it })
                }
                Row(Modifier.padding(top = 8.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    for (t in intArrayOf(0, 2, 5, 7, 12, 16, 17)) {
                        Box(
                            Modifier.size(26.dp).clip(CircleShape).background(Color(tone.color(t)))
                                .border(1.dp, MaterialTheme.colorScheme.outlineVariant, CircleShape),
                        )
                    }
                }
            }
            Button(onClick = { onCreate(name, w, h, tone, template) }, modifier = Modifier.fillMaxWidth().height(56.dp)) { Text(tr("create")) }
        }
    }
}

/** Отдельный экран поверх списка проектов: верхняя строка с кнопкой назад и содержимое. Системная кнопка 'назад' тоже закрывает. */
@Composable
internal fun SubScreen(title: String, onBack: () -> Unit, content: @Composable () -> Unit) {
    androidx.activity.compose.BackHandler(onBack = onBack)
    androidx.compose.material3.Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.surface) {
        Column(Modifier.fillMaxSize().statusBarsPadding()) {
            Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                QIconButton(Ico.Back, onBack, label = tr("back"), tonal = true)
                Spacer(Modifier.width(12.dp))
                Text(title, style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onSurface)
            }
            Box(Modifier.weight(1f).fillMaxWidth()) { content() }
        }
    }
}

/** Плитка шаблона: превью проекта и название. [preview] = null - пустой холст. */
@Composable
private fun TemplateTile(title: String, selected: Boolean, preview: Project?, onClick: () -> Unit) {
    val scheme = MaterialTheme.colorScheme
    Column(
        Modifier.width(104.dp).clip(RoundedCornerShape(20.dp))
            .border(if (selected) 3.dp else 1.dp, if (selected) scheme.primary else scheme.outlineVariant, RoundedCornerShape(20.dp))
            .background(scheme.surfaceContainerLow).clickable(onClick = onClick).padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Box(Modifier.fillMaxWidth().height(120.dp).clip(RoundedCornerShape(14.dp)).background(scheme.surfaceContainerHighest), contentAlignment = Alignment.Center) {
            if (preview != null) ProjectThumb(preview, inset = 6.dp, maxSide = 200)
            else QIcon(Ico.Add, tint = scheme.onSurfaceVariant, size = 32.dp)
        }
        Text(title, style = MaterialTheme.typography.labelMedium, color = scheme.onSurface, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}
