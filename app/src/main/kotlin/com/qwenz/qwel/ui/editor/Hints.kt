package com.qwenz.qwel.ui.editor

import android.content.SharedPreferences
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.qwenz.qwel.i18n.tr
import com.qwenz.qwel.ui.theme.Motion

/**
 * Подсказки по ходу работы. Каждая показывается один раз, когда человек впервые попадает в нужное место
 * (выбрал слой, открыл панель...). Тексты - в языковых файлах: h_<id>_t (заголовок) и h_<id>_b (текст).
 * Все подсказки отключаются разом; 'Пройти обучение заново' возвращает их.
 */
class Hints(private val prefs: SharedPreferences) {
    var enabled by mutableStateOf(prefs.getBoolean("hints", true))
        private set
    private val seen = HashSet<String>(prefs.getStringSet("hints_seen", emptySet()) ?: emptySet())

    /** Показываемая сейчас подсказка (id) или null. */
    var current by mutableStateOf<String?>(null)
        private set

    fun updateEnabled(value: Boolean) {
        enabled = value
        prefs.edit().putBoolean("hints", value).apply()
        if (!value) current = null
    }

    /** Показать подсказку [id], если подсказки включены, она ещё не показывалась и сейчас нет другой. */
    fun show(id: String) {
        if (enabled && current == null && id !in seen) current = id
    }

    fun dismiss() {
        current?.let { markSeen(it) }
        current = null
    }

    fun hasSeen(id: String): Boolean = id in seen

    fun markSeen(id: String) {
        seen.add(id)
        prefs.edit().putStringSet("hints_seen", HashSet(seen)).apply()
    }

    fun disableAll() { dismiss(); updateEnabled(false) }

    fun reset() {
        seen.clear(); current = null
        prefs.edit().remove("hints_seen").apply()
        updateEnabled(true)
    }
}

/** Карточка подсказки. Ставится в Column/Box экрана; сама плавно появляется и исчезает. */
@Composable
fun HintCard(hints: Hints, modifier: Modifier = Modifier) {
    var shown by remember { mutableStateOf<String?>(null) }
    val cur = hints.current
    LaunchedEffect(cur) { if (cur != null) shown = cur }
    val id = cur ?: shown
    AnimatedVisibility(
        visible = cur != null,
        enter = fadeIn(Motion.effects()) + slideInVertically(Motion.spatial<IntOffset>()) { it / 3 },
        exit = fadeOut(Motion.effects()),
        modifier = modifier,
    ) {
        if (id != null) {
            val on = MaterialTheme.colorScheme.onSecondaryContainer
            Surface(
                shape = RoundedCornerShape(24.dp), color = MaterialTheme.colorScheme.secondaryContainer,
                shadowElevation = 6.dp, modifier = Modifier.fillMaxWidth(),
            ) {
                Column(Modifier.padding(start = 20.dp, end = 12.dp, top = 16.dp, bottom = 6.dp)) {
                    Text(tr("h_${id}_t"), style = MaterialTheme.typography.titleSmall, color = on)
                    Spacer(Modifier.height(6.dp))
                    Text(tr("h_${id}_b"), style = MaterialTheme.typography.bodyMedium, color = on)
                    Row {
                        TextButton(onClick = { hints.dismiss() }, colors = ButtonDefaults.textButtonColors(contentColor = on)) {
                            Text(tr("got_it"))
                        }
                        TextButton(onClick = { hints.disableAll() }, colors = ButtonDefaults.textButtonColors(contentColor = on)) {
                            Text(tr("hints_off"))
                        }
                    }
                }
            }
        }
    }
}
