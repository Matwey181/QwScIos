package com.qwenz.qwel.ui.common

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.qwenz.qwel.AppController
import com.qwenz.qwel.i18n.trOr
import com.qwenz.qwel.i18n.tr

/**
 * Заметки об обновлении лежат в файлах языка: ключи news_<версия>_added / _changed / _fixed,
 * версия пишется с подчёркиваниями (1.1 -> news_1_1_added). Каждый ключ - список строк через перевод строки.
 * Для новой версии достаточно добавить эти ключи в ru.json и en.json и поднять versionName/versionCode в module.toml.
 */
object News {
    private val sections = listOf("added" to "news_added", "changed" to "news_changed", "fixed" to "news_fixed")

    private fun key(version: String, part: String) = "news_${version.replace('.', '_')}_$part"

    fun items(version: String, part: String): List<String> =
        trOr(key(version, part), "").split('\n').map { it.trim() }.filter { it.isNotEmpty() }

    fun has(version: String): Boolean = sections.any { items(version, it.first).isNotEmpty() }

    fun sectionTitles(): List<Pair<String, String>> = sections
}

@Composable
fun NewsDialog(controller: AppController) {
    val version = controller.versionName
    AlertDialog(
        onDismissRequest = { controller.dismissNews() },
        title = { Text(tr("news_title", version)) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                var any = false
                for ((part, titleKey) in News.sectionTitles()) {
                    val list = News.items(version, part)
                    if (list.isEmpty()) continue
                    any = true
                    Text(tr(titleKey), style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.primary)
                    for (line in list) {
                        Row(verticalAlignment = Alignment.Top) {
                            Box(Modifier.padding(top = 8.dp).size(6.dp).background(MaterialTheme.colorScheme.primary, CircleShape))
                            Text(line, Modifier.padding(start = 12.dp), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurface)
                        }
                    }
                }
                if (!any) Text(tr("news_empty"), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        },
        confirmButton = { TextButton(onClick = { controller.dismissNews() }) { Text(tr("news_ok")) } },
    )
}
