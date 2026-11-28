package com.qwenz.qwel

import android.graphics.Color
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.platform.LocalContext
import com.qwenz.qwel.render.Assets
import com.qwenz.qwel.render.Fonts
import com.qwenz.qwel.render.installTextMetrics
import com.qwenz.qwel.ui.editor.EditorScreen
import com.qwenz.qwel.ui.projects.ProjectsScreen
import com.qwenz.qwel.ui.theme.Motion
import com.qwenz.qwel.ui.theme.QwelTheme
import com.qwenz.qwel.ui.theme.isDarkMode

class MainActivity : ComponentActivity() {
    private lateinit var controller: AppController

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        com.qwenz.qwel.i18n.I18n.init(applicationContext)
        Assets.init(applicationContext)
        Fonts.init(applicationContext)
        com.qwenz.qwel.render.IconLibrary.init(applicationContext)
        installTextMetrics()
        controller = AppController(applicationContext)
        warmUpFonts(controller.uiFont)
        setContent { QwelRoot(controller) }
    }

    // Шрифт интерфейса (несколько OTF по 600 КБ) иначе читается на главном потоке в первом кадре: грузим заранее в фоне.
    // Кэш шрифтов у Compose общий, поэтому первый кадр берёт уже готовое. Если не сработает, ничего не ломается.
    @OptIn(androidx.compose.ui.text.ExperimentalTextApi::class)
    private fun warmUpFonts(family: String) {
        if (family.isEmpty()) return
        val ctx = applicationContext
        Thread({
            runCatching {
                val fam = com.qwenz.qwel.render.Fonts.uiFamily(family) ?: return@runCatching
                val resolver = androidx.compose.ui.text.font.createFontFamilyResolver(ctx)
                kotlinx.coroutines.runBlocking { resolver.preload(fam) }
            }
        }, "fonts-warmup").start()
    }

    override fun onResume() {
        super.onResume()
        requestMaxRefreshRate()
    }

    // Без этого многие телефоны держат приложение на 60 Гц, и анимации выглядят рваными
    private fun requestMaxRefreshRate() {
        try {
            val disp = if (android.os.Build.VERSION.SDK_INT >= 30) display else @Suppress("DEPRECATION") windowManager.defaultDisplay
            if (disp == null) return
            val cur = disp.mode
            val best = disp.supportedModes
                .filter { it.physicalWidth == cur.physicalWidth && it.physicalHeight == cur.physicalHeight }
                .maxByOrNull { it.refreshRate } ?: return
            val lp = window.attributes
            lp.preferredDisplayModeId = best.modeId
            lp.preferredRefreshRate = best.refreshRate
            window.attributes = lp
        } catch (_: Throwable) {
        }
    }

    override fun onPause() {
        super.onPause()
        controller.flush()
    }
}

@Composable
fun QwelRoot(controller: AppController) {
    QwelTheme(controller.themeMode, controller.accent, controller.accentSeed, controller.uiFont) {
        val dark = isDarkMode(controller.themeMode, isSystemInDarkTheme())
        val activity = LocalContext.current as ComponentActivity
        DisposableEffect(dark) {
            val style = SystemBarStyle.auto(Color.TRANSPARENT, Color.TRANSPARENT) { dark }
            activity.enableEdgeToEdge(statusBarStyle = style, navigationBarStyle = style)
            onDispose {}
        }
        LaunchedEffect(Unit) { controller.load() }

        // Surface задаёт цвет содержимого по умолчанию - без него текст на тёмной теме остаётся чёрным
        Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.surface, contentColor = MaterialTheme.colorScheme.onSurface) {
        Box(Modifier.fillMaxSize()) {
        AnimatedContent(
            targetState = controller.editor,
            transitionSpec = {
                if (targetState != null) {
                    // открытие проекта: редактор вырастает поверх списка
                    (fadeIn(Motion.effects()) + scaleIn(Motion.spatial(), initialScale = 0.92f)) togetherWith
                        (fadeOut(Motion.effects()) + scaleOut(Motion.spatial(), targetScale = 1.04f))
                } else {
                    // назад: редактор уходит вглубь, список возвращается
                    (fadeIn(Motion.effects()) + scaleIn(Motion.spatial(), initialScale = 1.04f)) togetherWith
                        (fadeOut(Motion.effects()) + scaleOut(Motion.spatial(), targetScale = 0.92f))
                }.apply { targetContentZIndex = if (targetState != null) 1f else 0f }
            },
            label = "screens",
        ) { editor ->
            if (editor == null) ProjectsScreen(controller) { controller.open(it) }
            else EditorScreen(editor, controller) { controller.close() }
        }
        if (controller.pets > 0) com.qwenz.qwel.ui.projects.ManulPets(controller.pets)
        if (controller.showTutorial) com.qwenz.qwel.ui.editor.TutorialFlow(controller)
        else if (controller.showNews) com.qwenz.qwel.ui.common.NewsDialog(controller)
        }
        }
    }
}
