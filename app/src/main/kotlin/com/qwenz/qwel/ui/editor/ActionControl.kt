package com.qwenz.qwel.ui.editor

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.qwenz.qwel.data.Node
import com.qwenz.qwel.i18n.tr
import com.qwenz.qwel.ui.common.SectionTitle

private val kinds = listOf("", "goto", "back", "toggle", "url")

private fun kindOf(a: String): String = if (a.isEmpty()) "" else a.substringBefore(':')

/** Действие слоя при нажатии (работает в режиме 'Играть'): перейти на экран, назад, показать или скрыть слой, открыть ссылку. */
@Composable
fun ActionControl(state: EditorState, n: Node) {
    val kind = kindOf(n.action)
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        SectionTitle(tr("action"))
        Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            for (k in kinds) {
                FilterChip(
                    selected = kind == k,
                    onClick = {
                        // при смене вида подставляем разумное значение по умолчанию
                        val a = when (k) {
                            "goto" -> state.pages.firstOrNull { it.id != state.pages.getOrNull(state.activePage)?.id }?.let { "goto:${it.id}" } ?: ""
                            "back" -> "back"
                            "toggle" -> state.nodes.firstOrNull { it.id != n.id }?.let { "toggle:${it.id}" } ?: ""
                            "url" -> "url:"
                            else -> ""
                        }
                        state.updateSelected("action") { it.copy(action = a) }
                    },
                    label = { Text(tr(if (k.isEmpty()) "action_none" else "action_$k")) },
                )
            }
        }
        when (kind) {
            "goto" -> Picker(
                current = state.pages.firstOrNull { "goto:${it.id}" == n.action }?.name ?: tr("action_pick"),
                items = state.pages.filter { it.id != state.pages.getOrNull(state.activePage)?.id }.map { it.name to "goto:${it.id}" },
            ) { a -> state.updateSelected("action") { it.copy(action = a) } }
            "toggle" -> Picker(
                current = state.nodes.firstOrNull { "toggle:${it.id}" == n.action }?.name ?: tr("action_pick"),
                items = state.nodes.filter { it.id != n.id }.map { it.name.ifBlank { tr("layer") } to "toggle:${it.id}" },
            ) { a -> state.updateSelected("action") { it.copy(action = a) } }
            "url" -> OutlinedTextField(
                value = n.action.removePrefix("url:"), singleLine = true, modifier = Modifier.fillMaxWidth(),
                onValueChange = { v -> state.updateSelected("action") { it.copy(action = "url:$v") } },
                label = { Text(tr("action_url_hint")) },
            )
        }
        Text(
            tr("action_hint"), style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun Picker(current: String, items: List<Pair<String, String>>, onPick: (String) -> Unit) {
    var open by remember { mutableStateOf(false) }
    androidx.compose.foundation.layout.Box {
        OutlinedButton(onClick = { open = true }, modifier = Modifier.fillMaxWidth()) { Text(current, maxLines = 1) }
        DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
            for ((name, value) in items) DropdownMenuItem(text = { Text(name, maxLines = 1) }, onClick = { open = false; onPick(value) })
        }
    }
}
