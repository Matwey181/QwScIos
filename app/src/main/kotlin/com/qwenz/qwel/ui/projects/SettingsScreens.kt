package com.qwenz.qwel.ui.projects

import android.os.Build
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.qwenz.qwel.AppController
import com.qwenz.qwel.i18n.I18n
import com.qwenz.qwel.i18n.tr
import com.qwenz.qwel.render.Fonts
import com.qwenz.qwel.render.Gallery
import com.qwenz.qwel.ui.common.ColorPickerDialog
import com.qwenz.qwel.ui.common.Ico
import com.qwenz.qwel.ui.common.QIcon
import com.qwenz.qwel.ui.common.QwelLogo
import com.qwenz.qwel.ui.editor.Gesture
import com.qwenz.qwel.ui.editor.SeedPresets
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

// ---------------------------------------------------------------- кирпичики: группы карточек как в Inugram

private val OuterCorner = 28.dp
private val InnerCorner = 6.dp

class SettingsGroupScope {
    internal val items = ArrayList<@Composable () -> Unit>()
    fun item(content: @Composable () -> Unit) { items += content }
}

/** Группа: заголовок акцентным цветом, карточки с узким зазором (крайние - сильно скруглены), подпись снизу. */
@Composable
internal fun SettingsGroup(title: String? = null, footer: String? = null, content: SettingsGroupScope.() -> Unit) {
    val scope = SettingsGroupScope().apply(content)
    Column(Modifier.fillMaxWidth()) {
        if (title != null) Text(
            title, Modifier.padding(start = 20.dp, top = 12.dp, bottom = 8.dp),
            style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary,
        )
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            val n = scope.items.size
            scope.items.forEachIndexed { i, item ->
                val top = if (i == 0) OuterCorner else InnerCorner
                val bottom = if (i == n - 1) OuterCorner else InnerCorner
                Box(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(top, top, bottom, bottom))
                        .background(MaterialTheme.colorScheme.surfaceContainerHigh),
                ) { item() }
            }
        }
        if (footer != null) Text(
            footer, Modifier.padding(horizontal = 20.dp, vertical = 8.dp),
            style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun Chevron() {
    val c = MaterialTheme.colorScheme.onSurfaceVariant
    Canvas(Modifier.size(width = 10.dp, height = 16.dp)) {
        val w = 2.dp.toPx()
        drawLine(c, Offset(size.width * 0.2f, size.height * 0.1f), Offset(size.width * 0.85f, size.height * 0.5f), w, StrokeCap.Round)
        drawLine(c, Offset(size.width * 0.85f, size.height * 0.5f), Offset(size.width * 0.2f, size.height * 0.9f), w, StrokeCap.Round)
    }
}

/** Строка: значок слева, название и пояснение, справа значение, стрелка или свой элемент. */
@Composable
internal fun SettingsRow(
    title: String,
    subtitle: String? = null,
    icon: Ico? = null,
    value: String? = null,
    chevron: Boolean = false,
    enabled: Boolean = true,
    onClick: (() -> Unit)? = null,
    trailing: (@Composable () -> Unit)? = null,
) {
    val scheme = MaterialTheme.colorScheme
    val alpha = if (enabled) 1f else 0.4f
    Row(
        Modifier.fillMaxWidth()
            .then(if (onClick != null && enabled) Modifier.clickable(onClick = onClick) else Modifier)
            .heightIn(min = 56.dp).padding(horizontal = 20.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) {
            QIcon(icon, tint = scheme.onSurfaceVariant.copy(alpha = alpha))
            Spacer(Modifier.width(16.dp))
        }
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyLarge, color = scheme.onSurface.copy(alpha = alpha))
            if (subtitle != null) Text(
                subtitle, style = MaterialTheme.typography.bodyMedium, color = scheme.onSurfaceVariant.copy(alpha = alpha),
            )
        }
        if (value != null) {
            Spacer(Modifier.width(12.dp))
            Text(value, style = MaterialTheme.typography.bodyLarge, color = scheme.primary)
        }
        if (chevron) { Spacer(Modifier.width(12.dp)); Chevron() }
        if (trailing != null) { Spacer(Modifier.width(12.dp)); trailing() }
    }
}

@Composable
internal fun SettingsSwitchRow(title: String, subtitle: String?, checked: Boolean, enabled: Boolean = true, onChange: (Boolean) -> Unit) {
    SettingsRow(
        title, subtitle, enabled = enabled, onClick = { onChange(!checked) },
        trailing = { Switch(checked, null, enabled = enabled) },
    )
}

@Composable
internal fun SettingsChoiceRow(title: String, subtitle: String? = null, selected: Boolean, enabled: Boolean = true, onClick: () -> Unit) {
    SettingsRow(title, subtitle, enabled = enabled, onClick = onClick, trailing = { RadioButton(selected, null, enabled = enabled) })
}

/** Прокручиваемая страница настроек с отступами по краям. */
@Composable
internal fun SettingsPage(content: @Composable () -> Unit) {
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).navigationBarsPadding()
            .padding(horizontal = 16.dp).padding(bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) { content() }
}

// ---------------------------------------------------------------- экраны

/** Настройки: главная и вложенные страницы (внешний вид, язык, жесты, экспорт) - каждая отдельным экраном поверх предыдущего. */
@Composable
internal fun SettingsSheet(controller: AppController, onDismiss: () -> Unit) {
    var page by remember { mutableStateOf("") }
    var shown by remember { mutableStateOf("look") }
    Box(Modifier.fillMaxSize()) {
        SubScreen(tr("settings"), onDismiss) { SettingsRoot(controller, onDismiss) { page = it; shown = it } }
        AnimatedVisibility(
            page.isNotEmpty(),
            enter = slideInHorizontally(tween(260)) { it / 3 } + fadeIn(tween(260)),
            exit = slideOutHorizontally(tween(200)) { it / 3 } + fadeOut(tween(200)),
        ) {
            when (shown) {
                "look" -> SubScreen(tr("settings_look"), { page = "" }) { LookPage(controller) }
                "lang" -> SubScreen(tr("language"), { page = "" }) { LanguagePage() }
                "gest" -> SubScreen(tr("gestures_settings"), { page = "" }) {
                    GesturesPage(controller) { page = ""; onDismiss(); controller.replayOnboarding() }
                }
                "funny" -> SubScreen(tr("funny"), { page = "" }) { FunnyPage(controller) }
                else -> SubScreen(tr("settings_export"), { page = "" }) { ExportPage(controller) }
            }
        }
    }
}

@Composable
private fun SettingsRoot(controller: AppController, onDismiss: () -> Unit, open: (String) -> Unit) {
    val context = LocalContext.current
    val langName = remember(I18n.selected) {
        if (I18n.selected == I18n.AUTO) tr("language_auto") else I18n.languages(context).firstOrNull { it.code == I18n.selected }?.name.orEmpty()
    }
    SettingsPage {
        Column(Modifier.fillMaxWidth().padding(top = 8.dp, bottom = 12.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            QwelLogo(Modifier.size(88.dp))
            Text("Vexel", Modifier.padding(top = 12.dp), style = MaterialTheme.typography.headlineMedium, color = MaterialTheme.colorScheme.onSurface)
            Text(controller.versionName, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        SettingsGroup {
            item { SettingsRow(tr("settings_look"), tr("settings_look_desc"), icon = Ico.Style, chevron = true, onClick = { open("look") }) }
            item { SettingsRow(tr("language"), icon = Ico.Text, value = langName, onClick = { open("lang") }) }
        }
        SettingsGroup(tr("settings_editor")) {
            item { SettingsRow(tr("gestures_settings"), tr("gestures_settings_desc"), icon = Ico.Select, chevron = true, onClick = { open("gest") }) }
            item { SettingsSwitchRow(tr("hints_setting"), tr("hints_setting_desc"), controller.hints.enabled) { controller.hints.updateEnabled(it) } }
            item { SettingsRow(tr("default_png_scale"), icon = Ico.Export, value = "${controller.exportScale}x", onClick = { open("export") }) }
        }
        SettingsGroup(tr("settings_other")) {
            item { SettingsRow(tr("funny"), tr("funny_desc"), icon = Ico.Shapes, chevron = true, onClick = { open("funny") }) }
            item { SettingsRow(tr("news_entry"), tr("news_entry_desc"), icon = Ico.Shapes, chevron = true, onClick = { onDismiss(); controller.openNews() }) }
        }
    }
}

/** Жесты по одному и 'пройти обучение заново' - на странице, не в окошке. */
@Composable
private fun GesturesPage(controller: AppController, onTutorial: () -> Unit) {
    SettingsPage {
        SettingsGroup(footer = tr("gestures_note")) {
            for (g in Gesture.values().filter { it.toggleable }) item {
                SettingsSwitchRow(tr(g.titleKey), tr(g.descKey), controller.gestures.isOn(g)) { controller.gestures.set(g, it) }
            }
        }
        SettingsGroup {
            item { SettingsRow(tr("tut_replay"), onClick = onTutorial) }
        }
    }
}

@Composable
private fun LookPage(controller: AppController) {
    val canDynamic = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
    val glassOk = Build.VERSION.SDK_INT >= 31
    var picker by remember { mutableStateOf(false) }
    SettingsPage {
        SettingsGroup(tr("app_theme")) {
            for ((mode, label) in listOf(
                0 to tr("theme_system"), 1 to tr("theme_light"), 2 to tr("theme_dark"), 3 to tr("theme_amoled"), 4 to tr("theme_amoled_light"),
            )) item { SettingsChoiceRow(label, selected = controller.themeMode == mode) { controller.updateThemeMode(mode) } }
        }
        SettingsGroup(
            tr("accent_title"),
            footer = when {
                controller.accent == 1 && canDynamic -> tr("dynamic_colors_desc")
                !canDynamic -> tr("accent_dynamic_unavailable")
                else -> tr("accent_hint")
            },
        ) {
            item { SettingsChoiceRow(tr("accent_vexel"), selected = controller.accent == 0) { controller.updateAccent(0) } }
            item { SettingsChoiceRow(tr("accent_dynamic"), selected = controller.accent == 1 && canDynamic, enabled = canDynamic) { controller.updateAccent(1) } }
            item { SettingsChoiceRow(tr("accent_custom"), selected = controller.accent == 2) { controller.updateAccent(2) } }
            if (controller.accent == 2) item {
                Row(
                    Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()).padding(horizontal = 20.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically,
                ) {
                    for (c in SeedPresets) {
                        val selected = controller.accentSeed == c
                        Box(
                            Modifier.size(40.dp).background(Color(c), CircleShape)
                                .border(if (selected) 3.dp else 1.dp, if (selected) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.outline, CircleShape)
                                .clickable { controller.updateAccentSeed(c) },
                        )
                    }
                    FilterChip(selected = false, onClick = { picker = true }, label = { Text(tr("accent_pick")) })
                }
            }
        }
        SettingsGroup(tr("ui_font")) {
            for (f in Fonts.uiFontFamilies) item { SettingsChoiceRow(Fonts.familyLabel(f), selected = controller.uiFont == f) { controller.updateUiFont(f) } }
            item { SettingsChoiceRow(tr("font_system"), selected = controller.uiFont.isEmpty()) { controller.updateUiFont("") } }
        }
        SettingsGroup(tr("settings_interface")) {
            item {
                SettingsSwitchRow(
                    tr("glass_ui"), if (glassOk) tr("glass_ui_desc") else tr("unavailable_android"),
                    controller.glassUi && glassOk, enabled = glassOk,
                ) { controller.updateGlassUi(it) }
            }
        }
    }
    if (picker) ColorPickerDialog(controller.accentSeed, onDismiss = { picker = false }, onConfirm = { controller.updateAccentSeed(it); picker = false })
}

/** Выбор языка: 'Авто', найденные файлы из assets/lang и импорт своего файла. */
@Composable
private fun LanguagePage() {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var rev by remember { mutableIntStateOf(0) }
    val langs = remember(rev) { I18n.languages(context) }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        if (uri != null) scope.launch {
            val code = withContext(Dispatchers.IO) { I18n.importLanguage(context, uri) }
            if (code == null) Toast.makeText(context, tr("language_import_failed"), Toast.LENGTH_LONG).show()
            else { rev++; I18n.setLanguage(context, code) }
        }
    }
    SettingsPage {
        SettingsGroup(footer = tr("language_hint")) {
            item { SettingsChoiceRow(tr("language_auto"), selected = I18n.selected == I18n.AUTO) { I18n.setLanguage(context, I18n.AUTO) } }
            for (l in langs) item { SettingsChoiceRow(l.name, selected = I18n.selected == l.code) { I18n.setLanguage(context, l.code) } }
            item { SettingsRow(tr("add_language"), onClick = { picker.launch("*/*") }) }
        }
    }
}

@Composable
private fun ExportPage(controller: AppController) {
    SettingsPage {
        SettingsGroup(tr("default_png_scale"), footer = tr("export_saved_in", Gallery.SHOWN)) {
            for (k in 1..4) item { SettingsChoiceRow("${k}x", selected = controller.exportScale == k) { controller.updateExportScale(k) } }
        }
    }
}
