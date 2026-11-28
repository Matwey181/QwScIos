package com.qwenz.qwel.ui.editor

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.foundation.background
import com.qwenz.qwel.ui.common.QIcon
import androidx.compose.ui.graphics.Color
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.DropdownMenu
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qwenz.qwel.i18n.tr
import com.qwenz.qwel.ui.common.Ico
import com.qwenz.qwel.ui.common.ProjectThumb
import com.qwenz.qwel.ui.common.QIconButton

/** Экраны проекта: список с миниатюрами, переход, новый (пустой или копия), переименование, удаление. */
@Composable
fun ScreensDialog(state: EditorState, onDismiss: () -> Unit) {
    val projects = remember(state.pages, state.rev, state.activePage) { state.toProject().pageProjects() }
    var renaming by remember { mutableStateOf<Int?>(null) }
    var deleting by remember { mutableStateOf<Int?>(null) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tr("screens")) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Column(
                    Modifier.heightIn(max = 320.dp).verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                ) {
                    state.pages.forEachIndexed { i, page ->
                        val active = i == state.activePage
                        var more by remember { mutableStateOf(false) }
                        Row(
                            Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp))
                                .background(if (active) MaterialTheme.colorScheme.secondaryContainer else Color.Transparent)
                                .clickable { state.switchPage(i); onDismiss() }
                                .padding(start = 8.dp, top = 6.dp, bottom = 6.dp, end = 2.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Box(Modifier.size(48.dp).clip(RoundedCornerShape(12.dp)).background(MaterialTheme.colorScheme.surfaceContainerHighest)) {
                                projects.getOrNull(i)?.let { ProjectThumb(it, inset = 4.dp, maxSide = 160) }
                            }
                            Spacer(Modifier.width(12.dp))
                            Column(Modifier.weight(1f)) {
                                Text(page.name, style = MaterialTheme.typography.titleMedium, maxLines = 1, overflow = TextOverflow.Ellipsis)
                                Text(
                                    if (active) tr("screen_current") else tr("screen_layers", projects.getOrNull(i)?.nodes?.size ?: 0),
                                    style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1,
                                )
                            }
                            Box {
                                QIconButton(Ico.More, { more = true }, label = tr("menu"), size = 40.dp)
                                DropdownMenu(expanded = more, onDismissRequest = { more = false }) {
                                    DropdownMenuItem(text = { Text(tr("rename")) }, leadingIcon = { QIcon(Ico.Edit) }, onClick = { more = false; renaming = i })
                                    DropdownMenuItem(text = { Text(tr("duplicate")) }, leadingIcon = { QIcon(Ico.Duplicate) }, onClick = { more = false; state.duplicatePage(i); onDismiss() })
                                    if (i > 0) DropdownMenuItem(text = { Text(tr("screen_earlier")) }, leadingIcon = { QIcon(Ico.Backward) }, onClick = { more = false; state.movePage(i, -1) })
                                    if (i < state.pages.size - 1) DropdownMenuItem(text = { Text(tr("screen_later")) }, leadingIcon = { QIcon(Ico.Forward) }, onClick = { more = false; state.movePage(i, 1) })
                                    if (state.pages.size > 1) DropdownMenuItem(text = { Text(tr("delete")) }, leadingIcon = { QIcon(Ico.Delete) }, onClick = { more = false; deleting = i })
                                }
                            }
                        }
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilledTonalButton({ state.addPage(false); onDismiss() }, Modifier.weight(1f), contentPadding = PaddingValues(horizontal = 12.dp)) { Text(tr("screen_new_s"), maxLines = 1) }
                    OutlinedButton({ state.addPage(true); onDismiss() }, Modifier.weight(1f), contentPadding = PaddingValues(horizontal = 12.dp)) { Text(tr("screen_copy_s"), maxLines = 1) }
                }
                Text(tr("screens_note"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        },
        confirmButton = { TextButton(onDismiss) { Text(tr("close")) } },
    )
    renaming?.let { i ->
        var text by remember(i) { mutableStateOf(state.pages.getOrNull(i)?.name.orEmpty()) }
        AlertDialog(
            onDismissRequest = { renaming = null },
            title = { Text(tr("screen_name")) },
            text = { OutlinedTextField(text, { text = it }, singleLine = true, shape = RoundedCornerShape(16.dp)) },
            confirmButton = { TextButton({ state.renamePage(i, text); renaming = null }) { Text(tr("done")) } },
            dismissButton = { TextButton({ renaming = null }) { Text(tr("cancel")) } },
        )
    }
    deleting?.let { i ->
        AlertDialog(
            onDismissRequest = { deleting = null },
            title = { Text(tr("screen_delete_q", state.pages.getOrNull(i)?.name.orEmpty())) },
            text = { Text(tr("screen_delete_body")) },
            confirmButton = { TextButton({ state.deletePage(i); deleting = null; onDismiss() }) { Text(tr("delete")) } },
            dismissButton = { TextButton({ deleting = null }) { Text(tr("cancel")) } },
        )
    }
}

/** Готовый код Compose в окне с горизонтальной и вертикальной прокруткой и кнопкой 'Копировать'. */
@Composable
fun ComposeCodeDialog(code: String, forSelection: Boolean, onDismiss: () -> Unit) {
    val context = LocalContext.current
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tr("compose_code")) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    if (forSelection) tr("code_of_selection") else tr("code_of_screen"),
                    style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Box(
                    Modifier.fillMaxWidth().heightIn(max = 340.dp).clip(RoundedCornerShape(16.dp))
                        .background(MaterialTheme.colorScheme.surfaceContainerHighest)
                        .verticalScroll(rememberScrollState()).horizontalScroll(rememberScrollState()).padding(12.dp),
                ) {
                    Text(code, fontFamily = FontFamily.Monospace, fontSize = 11.sp, lineHeight = 15.sp, softWrap = false)
                }
                Text(tr("code_note"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        },
        confirmButton = {
            TextButton({
                val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                cm.setPrimaryClip(ClipData.newPlainText("Vexel Compose", code))
                Toast.makeText(context, tr("code_copied"), Toast.LENGTH_SHORT).show()
                onDismiss()
            }) { Text(tr("copy")) }
        },
        dismissButton = { TextButton(onDismiss) { Text(tr("close")) } },
    )
}

/** Полоска экранов над нижним блоком: переключение в один тап, плюс для нового экрана, многоточие открывает полный список. */
@Composable
fun ScreenStrip(state: EditorState, onMore: () -> Unit, modifier: Modifier = Modifier) {
    val scheme = MaterialTheme.colorScheme
    val list = androidx.compose.foundation.lazy.rememberLazyListState()
    androidx.compose.runtime.LaunchedEffect(state.activePage) { list.animateScrollToItem(state.activePage) }
    androidx.compose.foundation.lazy.LazyRow(
        modifier, state = list,
        horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        itemsIndexed(state.pages, key = { _, p -> p.id }) { i, page ->
            val active = i == state.activePage
            val bg by androidx.compose.animation.animateColorAsState(
                if (active) scheme.primaryContainer else scheme.surfaceContainerHigh, com.qwenz.qwel.ui.theme.Motion.effects(), label = "chip",
            )
            androidx.compose.material3.Surface(
                shape = androidx.compose.foundation.shape.CircleShape, color = bg, shadowElevation = 2.dp,
                modifier = Modifier.animateItem().clip(androidx.compose.foundation.shape.CircleShape).clickable { state.switchPage(i) },
            ) {
                Text(
                    page.name, Modifier.widthIn(max = 120.dp).padding(horizontal = 14.dp, vertical = 8.dp),
                    style = MaterialTheme.typography.labelLarge, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    color = if (active) scheme.onPrimaryContainer else scheme.onSurface,
                )
            }
        }
        item {
            androidx.compose.material3.Surface(
                shape = androidx.compose.foundation.shape.CircleShape, color = scheme.surfaceContainerHigh, shadowElevation = 2.dp,
            ) {
                Row {
                    QIconButton(Ico.Add, { state.addPage(false) }, label = tr("screen_add"), size = 36.dp)
                    QIconButton(Ico.Screens, onMore, label = tr("screens"), size = 36.dp)
                }
            }
        }
    }
}

/** Выгрузка проекта целиком в ZIP: спрашивает пакет, в котором будет код. */
@Composable
fun ProjectExportDialog(codeAssist: Boolean, onDismiss: () -> Unit, onSave: (String) -> Unit) {
    var pkg by androidx.compose.runtime.saveable.rememberSaveable { mutableStateOf(com.qwenz.qwel.data.ProjectExport.DEFAULT_PACKAGE) }
    val valid = com.qwenz.qwel.data.ProjectExport.cleanPackage(pkg) == pkg.trim().lowercase()
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tr(if (codeAssist) "codeassist_project" else "compose_project")) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(tr(if (codeAssist) "codeassist_project_note" else "compose_project_note"), style = MaterialTheme.typography.bodyMedium)
                androidx.compose.material3.OutlinedTextField(
                    value = pkg, onValueChange = { pkg = it }, singleLine = true, modifier = Modifier.fillMaxWidth(),
                    label = { Text(tr(if (codeAssist) "codeassist_project_pkg" else "compose_project_pkg")) }, isError = !valid,
                    supportingText = { if (!valid) Text(tr("compose_project_pkg_bad")) },
                )
            }
        },
        confirmButton = { TextButton({ onSave(pkg); onDismiss() }, enabled = valid) { Text(tr("compose_project_save")) } },
        dismissButton = { TextButton(onDismiss) { Text(tr("cancel")) } },
    )
}
