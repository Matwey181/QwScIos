package com.qwenz.qwel.ui.editor

import android.content.SharedPreferences
import androidx.compose.runtime.mutableStateMapOf

/**
 * Жесты редактора. Базовые (тап, перетаскивание, масштаб двумя пальцами) отключить нельзя -
 * без них редактор не работает. Остальные включаются и выключаются по одному.
 */
enum class Gesture(val toggleable: Boolean, val titleKey: String, val descKey: String) {
    TAP(false, "g_tap", "g_tap_d"),
    DRAG(false, "g_drag", "g_drag_d"),
    PINCH(false, "g_two", "g_two_d"),
    UNDO_TAP(true, "g_two_tap", "g_two_tap_d"),
    REDO_TAP(true, "g_three_tap", "g_three_tap_d"),
    DOUBLE_FIT(true, "g_dbl_empty", "g_dbl_empty_d"),
    DOUBLE_LAYER(true, "g_dbl_layer", "g_dbl_layer_d"),
    LONG_EMPTY(true, "g_long_empty", "g_long_empty_d"),
    LONG_LAYER(true, "g_long_layer", "g_long_layer_d"),
    PANEL_SWIPE(true, "g_panel", "g_panel_d"),
}

/** Какие жесты включены. Состояние наблюдаемое: переключатель в настройках действует сразу. */
class Gestures(private val prefs: SharedPreferences) {
    private val on = mutableStateMapOf<Gesture, Boolean>().also { m ->
        for (g in Gesture.values()) m[g] = !g.toggleable || prefs.getBoolean("gesture_" + g.name, true)
    }

    fun isOn(g: Gesture): Boolean = !g.toggleable || (on[g] ?: true)

    fun set(g: Gesture, value: Boolean) {
        if (!g.toggleable) return
        on[g] = value
        prefs.edit().putBoolean("gesture_" + g.name, value).apply()
    }
}
