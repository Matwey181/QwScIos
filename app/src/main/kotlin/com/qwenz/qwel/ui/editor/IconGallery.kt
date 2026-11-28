package com.qwenz.qwel.ui.editor

import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.Button
import androidx.compose.material3.FilterChip
import androidx.compose.material3.TextButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.qwenz.qwel.data.Node
import com.qwenz.qwel.data.NodeKind
import com.qwenz.qwel.data.Tok
import com.qwenz.qwel.data.newId
import com.qwenz.qwel.i18n.tr
import com.qwenz.qwel.render.IconLibrary
import com.qwenz.qwel.render.SvgImport
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** Вкладка 'Иконки' в панели вставки: поиск, стиль (Outlined, Rounded, Sharp) и залитый вариант. */
@Composable
fun IconGallery(state: EditorState) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var rev by remember { mutableStateOf(0) }
    var busy by remember { mutableStateOf(false) }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri == null) return@rememberLauncherForActivityResult
        busy = true
        scope.launch {
            val n = withContext(Dispatchers.IO) { runCatching { com.qwenz.qwel.render.IconImport.import(context, uri) }.getOrDefault(0) }
            busy = false; rev++
            Toast.makeText(context, if (n > 0) tr("icons_imported", n) else tr("icons_import_failed"), Toast.LENGTH_LONG).show()
        }
    }
    val pick = { picker.launch(arrayOf("application/zip", "application/gzip", "application/x-gzip", "application/x-compressed-tar", "application/octet-stream", "*/*")) }
    if (rev < 0 || IconLibrary.isEmpty()) {
        Column(Modifier.fillMaxWidth().padding(vertical = 8.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(tr("icons_empty_title"), style = MaterialTheme.typography.titleMedium)
            Text(tr("icons_empty_body"), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Button(onClick = pick, enabled = !busy, modifier = Modifier.fillMaxWidth()) { Text(if (busy) tr("icons_importing") else tr("icons_import")) }
        }
        return
    }
    var query by remember { mutableStateOf("") }
    var style by remember(rev) { mutableStateOf(IconLibrary.styles.firstOrNull() ?: "outlined") }
    var fill by remember { mutableStateOf(false) }
    val all = remember(style, rev) { IconLibrary.names(style) }
    val shown = remember(style, query, rev) {
        val q = query.trim().lowercase().replace(' ', '_')
        if (q.isEmpty()) all else all.filter { it.contains(q) }
    }
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        OutlinedTextField(
            value = query, onValueChange = { query = it }, singleLine = true, modifier = Modifier.fillMaxWidth(),
            placeholder = { Text(tr("icons_search")) }, shape = RoundedCornerShape(28.dp),
        )
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            for (s in IconLibrary.styles) FilterChip(selected = style == s, onClick = { style = s }, label = { Text(tr("icon_style_$s")) })
            if (IconLibrary.hasFilled(style)) FilterChip(selected = fill, onClick = { fill = !fill }, label = { Text(tr("icon_filled")) })
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(tr("icons_count", shown.size), style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.weight(1f))
            TextButton(onClick = pick, enabled = !busy) { Text(if (busy) tr("icons_importing") else tr("icons_import_more")) }
            if (IconLibrary.hasImported()) TextButton(onClick = { IconLibrary.clearImported(); rev++ }) { Text(tr("icons_remove")) }
        }
        LazyVerticalGrid(
            columns = GridCells.Fixed(4), modifier = Modifier.fillMaxWidth().height(340.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            items(shown, key = { it }) { name ->
                IconTile(style, name, fill) {
                    val ok = insertIcon(state, style, name, fill)
                    if (!ok) Toast.makeText(context, tr("icon_insert_failed"), Toast.LENGTH_SHORT).show()
                }
            }
        }
    }
}

@Composable
private fun IconTile(style: String, name: String, fill: Boolean, onClick: () -> Unit) {
    val shape by produceState<com.qwenz.qwel.render.IconShape?>(null, style, name, fill) {
        value = withContext(Dispatchers.IO) { IconLibrary.shape(style, name, fill) }
    }
    val color = MaterialTheme.colorScheme.onSurface
    Column(
        Modifier.aspectRatio(0.85f).clip(RoundedCornerShape(20.dp)).background(MaterialTheme.colorScheme.surfaceContainerHighest)
            .clickable(onClick = onClick).padding(6.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center,
    ) {
        Canvas(Modifier.size(32.dp)) {
            val s = shape ?: return@Canvas
            val k = minOf(size.width / s.box.width, size.height / s.box.height)
            translate(-s.box.left * k, -s.box.top * k) { scale(k, k, pivot = Offset.Zero) { drawPath(s.path, color) } }
        }
        Text(
            IconLibrary.label(name), style = MaterialTheme.typography.labelSmall, maxLines = 1, overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center, modifier = Modifier.padding(top = 4.dp),
        )
    }
}

/** Иконка попадает на лист как обычный слой-контур (цвет из токена, можно красить, масштабировать, объединять). */
private fun insertIcon(state: EditorState, style: String, name: String, fill: Boolean): Boolean {
    val bytes = IconLibrary.bytes(style, name, fill) ?: return false
    // иконка Material Symbols занимает область 960 x 960 - вписываем её в 64 x 64
    val res = SvgImport.parseOwnSize(bytes, 64.0 / 960.0) ?: return false
    if (res.nodes.isEmpty()) return false
    var c = state.viewCenterDoc()
    if (c.x < 0f || c.y < 0f || c.x > state.width || c.y > state.height) c = Offset(state.width / 2f, state.height / 2f)
    val dx = c.x - res.width / 2f; val dy = c.y - res.height / 2f
    val group = if (res.nodes.size > 1) newId() else ""
    val color = state.tone.color(Tok.ON_SURFACE, 0xFF1D1B20.toInt())
    state.addNodes(res.nodes.map { n ->
        n.copy(
            x = n.x + dx, y = n.y + dy, name = IconLibrary.label(name), group = group, ratioLock = true,
            fill = if (n.kind == NodeKind.PATH) color else n.fill, fillToken = if (n.kind == NodeKind.PATH) Tok.ON_SURFACE else n.fillToken,
        )
    })
    return true
}
