package com.qwenz.qwel.ui.common

import android.os.Build
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.qwenz.qwel.AppController
import com.qwenz.qwel.i18n.tr
import com.qwenz.qwel.render.Fonts
import com.qwenz.qwel.ui.editor.SeedPresets

/** Тема, акцент и шрифт интерфейса. Одни и те же настройки в 'Настройках' и в обучении. Изменения видны сразу. */
@Composable
fun AppearanceSettings(controller: AppController, showFont: Boolean = true) {
    var picker by remember { mutableStateOf(false) }
    val canDynamic = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Column {
            SectionTitle(tr("app_theme"))
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(
                    0 to tr("theme_system"), 1 to tr("theme_light"), 2 to tr("theme_dark"),
                    3 to tr("theme_amoled"), 4 to tr("theme_amoled_light"),
                ).forEach { (mode, label) ->
                    FilterChip(selected = controller.themeMode == mode, onClick = { controller.updateThemeMode(mode) }, label = { Text(label) })
                }
            }
        }
        Column {
            SectionTitle(tr("accent_title"))
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(selected = controller.accent == 0, onClick = { controller.updateAccent(0) }, label = { Text(tr("accent_vexel")) })
                FilterChip(
                    selected = controller.accent == 1 && canDynamic, onClick = { controller.updateAccent(1) },
                    enabled = canDynamic, label = { Text(tr("accent_dynamic")) },
                )
                FilterChip(selected = controller.accent == 2, onClick = { controller.updateAccent(2) }, label = { Text(tr("accent_custom")) })
            }
            Text(
                when {
                    controller.accent == 1 && canDynamic -> tr("dynamic_colors_desc")
                    !canDynamic -> tr("accent_dynamic_unavailable")
                    else -> tr("accent_hint")
                },
                Modifier.padding(top = 6.dp), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            if (controller.accent == 2) {
                Row(Modifier.padding(top = 10.dp).horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    for (c in SeedPresets) {
                        val selected = controller.accentSeed == c
                        androidx.compose.foundation.layout.Box(
                            Modifier.size(40.dp).background(Color(c), CircleShape)
                                .border(BorderStroke(if (selected) 3.dp else 1.dp, if (selected) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.outline), CircleShape)
                                .clickable { controller.updateAccentSeed(c) }.semantics { contentDescription = tr("accent_custom") },
                        )
                    }
                    FilterChip(selected = false, onClick = { picker = true }, label = { Text(tr("accent_pick")) })
                }
            }
        }
        if (showFont) Column {
            SectionTitle(tr("ui_font"))
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                for (f in Fonts.uiFontFamilies) {
                    FilterChip(selected = controller.uiFont == f, onClick = { controller.updateUiFont(f) }, label = { Text(Fonts.familyLabel(f)) })
                }
                FilterChip(selected = controller.uiFont.isEmpty(), onClick = { controller.updateUiFont("") }, label = { Text(tr("font_system")) })
            }
        }
    }
    if (picker) ColorPickerDialog(controller.accentSeed, onDismiss = { picker = false }, onConfirm = { controller.updateAccentSeed(it); picker = false })
}
