package com.qwenz.qwel.ui.editor

import androidx.activity.compose.BackHandler
import com.qwenz.qwel.shapes.ShapeLibrary
import com.qwenz.qwel.render.CubicsShape
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.qwenz.qwel.AppController
import com.qwenz.qwel.data.Node
import com.qwenz.qwel.data.NodeKind
import com.qwenz.qwel.data.Project
import com.qwenz.qwel.data.Tok
import com.qwenz.qwel.data.Tone
import com.qwenz.qwel.data.newId
import com.qwenz.qwel.i18n.tr
import com.qwenz.qwel.ui.common.Ico
import com.qwenz.qwel.ui.common.QIcon
import com.qwenz.qwel.ui.common.QwelLogo
import com.qwenz.qwel.ui.theme.Motion
import kotlinx.coroutines.delay

// =============================================================== настройки жестов

/** Переключатели жестов по одному + кнопка 'пройти обучение заново'. */
@Composable
fun GestureSettingsDialog(gestures: Gestures, onTutorial: () -> Unit, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tr("gestures_settings")) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Text(tr("gestures_note"), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                for (g in Gesture.values().filter { it.toggleable }) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text(tr(g.titleKey), style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.onSurface)
                            Text(tr(g.descKey), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Spacer(Modifier.width(12.dp))
                        Switch(checked = gestures.isOn(g), onCheckedChange = { gestures.set(g, it) })
                    }
                }
                TextButton(onClick = { onDismiss(); onTutorial() }) { Text(tr("tut_replay")) }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text(tr("done")) } },
    )
}

// =============================================================== обучение

private class Step(val gesture: Gesture, val textKey: String)

private val Steps = listOf(
    Step(Gesture.TAP, "tut_s_tap"),
    Step(Gesture.DRAG, "tut_s_drag"),
    Step(Gesture.PINCH, "tut_s_pinch"),
    Step(Gesture.UNDO_TAP, "tut_s_undo"),
    Step(Gesture.REDO_TAP, "tut_s_redo"),
    Step(Gesture.DOUBLE_FIT, "tut_s_fit"),
    Step(Gesture.LONG_LAYER, "tut_s_long_layer"),
    Step(Gesture.LONG_EMPTY, "tut_s_long_empty"),
)

/**
 * Первый запуск: приветствие -> короткий обзор всех возможностей -> практика жестов на пробном листе -> итог.
 * Любую часть можно пропустить; жест можно отключить прямо в практике.
 */
@Composable
fun TutorialFlow(controller: AppController) {
    // Первый запуск не должен превращаться в обязательный курс.
    var step by remember { mutableIntStateOf(0) }
    // приветствие -> цвета и шрифт -> обзор возможностей -> практика жестов; любую часть можно пропустить
    BackHandler { if (step in 1..2) step-- else controller.finishTutorial() }
    Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.surface) {
        when (step) {
            0 -> TutorialWelcome(onStart = { step = 1 })
            1 -> TutorialLook(controller, onDone = { step = 2 })
            2 -> TutorialTour(onFinish = { step = 3 }, onSkip = { controller.finishTutorial() })
            else -> TutorialPractice(controller, onDone = { controller.finishTutorial() }, onSkip = { controller.finishTutorial() })
        }
    }
}

/** Внешний вид: тема, акцент, шрифт - и вопрос про динамические цвета. Всё применяется сразу, можно смотреть вживую. */
@Composable
private fun TutorialLook(controller: AppController, onDone: () -> Unit) {
    val canDynamic = android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S
    Column(
        Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()
            .verticalScroll(rememberScrollState()).padding(horizontal = 24.dp, vertical = 24.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        Text(tr("tut_look_title"), style = MaterialTheme.typography.headlineMedium)
        Text(tr("tut_look_body"), style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
        if (canDynamic) Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.secondaryContainer)) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(tr("tut_dyn_q"), style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSecondaryContainer)
                Text(tr("tut_dyn_desc"), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSecondaryContainer)
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    if (controller.accent == 1) Button(onClick = { controller.updateAccent(1) }) { Text(tr("tut_dyn_yes")) }
                    else androidx.compose.material3.OutlinedButton(onClick = { controller.updateAccent(1) }) { Text(tr("tut_dyn_yes")) }
                    if (controller.accent != 1) Button(onClick = { controller.updateAccent(0) }) { Text(tr("tut_dyn_no")) }
                    else androidx.compose.material3.OutlinedButton(onClick = { controller.updateAccent(0) }) { Text(tr("tut_dyn_no")) }
                }
            }
        }
        com.qwenz.qwel.ui.common.AppearanceSettings(controller)
        Button(onClick = onDone, modifier = Modifier.fillMaxWidth()) { Text(tr("tut_next")) }
    }
}

// ---------------------------------------------------------------- обзор возможностей

private class TourPage(val titleKey: String, val bodyKey: String, val hero: @Composable () -> Unit)

@Composable
private fun IconRow(vararg icos: Ico) {
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        for (i in icos) {
            Box(
                Modifier.size(56.dp).background(MaterialTheme.colorScheme.secondaryContainer, RoundedCornerShape(18.dp)),
                contentAlignment = Alignment.Center,
            ) { QIcon(i, tint = MaterialTheme.colorScheme.onSecondaryContainer, size = 28.dp) }
        }
    }
}

/** Настоящие фигуры из библиотеки - те же, что в 'Добавить'. */
@Composable
private fun ShapeRow(ids: List<String>) {
    val scheme = MaterialTheme.colorScheme
    val colors = listOf(scheme.primary, scheme.tertiary, scheme.secondary, scheme.primaryContainer, scheme.tertiaryContainer)
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        ids.forEachIndexed { i, id ->
            val cubics = ShapeLibrary.get(id)?.cubics
            val shape: Shape = if (cubics != null) CubicsShape(cubics) else CircleShape
            Box(Modifier.size(56.dp).clip(shape).background(colors[i % colors.size]))
        }
    }
}

@Composable
private fun SwatchRow() {
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        for (c in SeedPresets.take(6)) Box(Modifier.size(40.dp).background(Color(c), CircleShape))
    }
}

/** Три плашки на цветном фоне: левая - чёткая, остальные 'матовые'. Наглядно, что делает размытие. */
@Composable
private fun GlassHero() {
    val scheme = MaterialTheme.colorScheme
    Box(Modifier.size(width = 232.dp, height = 72.dp).clip(RoundedCornerShape(20.dp)).background(scheme.primaryContainer)) {
        Box(Modifier.size(44.dp).align(Alignment.CenterStart).padding(start = 14.dp).clip(CircleShape).background(scheme.primary))
        Box(Modifier.size(44.dp).align(Alignment.Center).clip(CircleShape).background(scheme.tertiary))
        Box(
            Modifier.size(width = 120.dp, height = 72.dp).align(Alignment.CenterEnd)
                .background(scheme.surface.copy(alpha = 0.55f)),
        )
    }
}

private val TourPages = listOf(
    TourPage("tour_0_t", "tour_0_b") { IconRow(Ico.Back, Ico.Undo, Ico.Redo, Ico.More, Ico.Layers) },
    TourPage("tour_1_t", "tour_1_b") { IconRow(Ico.Add, Ico.Search, Ico.List, Ico.Import, Ico.Export) },
    TourPage("tour_2_t", "tour_2_b") { ShapeRow(listOf("cookie-9", "soft-burst", "sunny", "flower", "star-5")) },
    TourPage("tour_3_t", "tour_3_b") { SwatchRow() },
    TourPage("tour_7_t", "tour_7_b") { GlassHero() },
    TourPage("tour_8_t", "tour_8_b") { IconRow(Ico.Gradient, Ico.Shadow, Ico.Pipette, Ico.Blur) },
    TourPage("tour_4_t", "tour_4_b") { IconRow(Ico.AlignLeft, Ico.AlignHCenter, Ico.AlignRight, Ico.DistributeH, Ico.SameWidth) },
    TourPage("tour_5_t", "tour_5_b") { IconRow(Ico.Group, Ico.BoolUnion, Ico.BoolDiff, Ico.Mask, Ico.Lock) },
    TourPage("tour_9_t", "tour_9_b") { IconRow(Ico.Screens, Ico.Add, Ico.Duplicate, Ico.Edit) },
    TourPage("tour_10_t", "tour_10_b") { IconRow(Ico.Code, Ico.Import, Ico.Export) },
    TourPage("tour_6_t", "tour_6_b") { IconRow(Ico.Export, Ico.Undo, Ico.Redo, Ico.Grid, Ico.Guides) },
)

/** Обзор всего, что умеет редактор: 6 коротких экранов. Листаются кнопками или свайпом. */
@Composable
private fun TutorialTour(onFinish: () -> Unit, onSkip: () -> Unit) {
    var idx by remember { mutableIntStateOf(0) }
    val last = idx == TourPages.lastIndex
    fun next() { if (idx >= TourPages.lastIndex) onFinish() else idx++ }
    fun prev() { if (idx > 0) idx-- }
    BackHandler(enabled = idx > 0) { prev() }

    Column(
        Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()
            .pointerInput(idx) {
                var acc = 0f
                detectHorizontalDragGestures(
                    onDragStart = { acc = 0f },
                    onDragEnd = { if (acc < -60.dp.toPx()) next() else if (acc > 60.dp.toPx()) prev() },
                    onDragCancel = { acc = 0f },
                ) { _, dx -> acc += dx }
            }
            .padding(horizontal = 28.dp),
    ) {
        Row(Modifier.fillMaxWidth().padding(top = 12.dp), verticalAlignment = Alignment.CenterVertically) {
            Row(Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                for (i in TourPages.indices) {
                    Box(
                        Modifier.size(8.dp).background(
                            if (i == idx) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant, CircleShape,
                        ),
                    )
                }
            }
            TextButton(onClick = onSkip) { Text(tr("tut_skip")) }
        }
        AnimatedContent(
            targetState = idx, modifier = Modifier.weight(1f).fillMaxWidth(),
            transitionSpec = { fadeIn(Motion.effects()) togetherWith fadeOut(Motion.effects()) },
            label = "tour",
        ) { i ->
            val page = TourPages[i]
            Column(
                Modifier.fillMaxSize().verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.Center,
            ) {
                page.hero()
                Spacer(Modifier.height(28.dp))
                Text(tr(page.titleKey), style = MaterialTheme.typography.headlineSmall)
                for (line in tr(page.bodyKey).split('\n')) {
                    Spacer(Modifier.height(12.dp))
                    Text(line, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
        Row(Modifier.fillMaxWidth().padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
            if (idx > 0) TextButton(onClick = { prev() }) { Text(tr("back")) }
            Spacer(Modifier.weight(1f))
            Button(onClick = { next() }) { Text(if (last) tr("tour_to_gestures") else tr("tut_next")) }
        }
    }
}

@Composable
private fun TutorialWelcome(onStart: () -> Unit) {
    Column(
        Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()
            .verticalScroll(rememberScrollState()).padding(horizontal = 24.dp, vertical = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        QwelLogo(Modifier.size(76.dp))
        Spacer(Modifier.height(20.dp))
        Text(tr("tut_welcome_title"), style = MaterialTheme.typography.headlineMedium, textAlign = TextAlign.Center)
        Spacer(Modifier.height(8.dp))
        Text(
            tr("tut_welcome_body"), style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(28.dp))
        Button(onClick = onStart, modifier = Modifier.fillMaxWidth()) { Text(tr("tut_next")) }
    }
}

private fun sandboxProject(): Project {
    fun c(hex: Long) = (0xFF000000 or hex).toInt()
    fun shape(id: String, name: String, x: Float, y: Float, w: Float, h: Float, fill: Int) =
        Node(newId(), NodeKind.SHAPE, name, x, y, w, h, fill = fill, shapeId = id, ratioLock = true)
    val nodes = listOf(
        shape("cookie-9", "1", 30f, 60f, 170f, 170f, Tone.Baseline.color(Tok.PRIMARY_CONTAINER)),
        shape("soft-burst", "2", 170f, 230f, 130f, 130f, Tone.Baseline.color(Tok.TERTIARY_CONTAINER)),
        shape("pill", "3", 30f, 380f, 150f, 64f, Tone.Baseline.color(Tok.PRIMARY)),
    )
    val now = System.currentTimeMillis()
    return Project(newId(), "", 320f, 480f, Tone.Baseline.color(Tok.SURFACE), nodes, now, now, Tone.Baseline, Tok.SURFACE)
}

@Composable
private fun TutorialPractice(controller: AppController, onDone: () -> Unit, onSkip: () -> Unit) {
    val gestures = controller.gestures
    val density = LocalDensity.current
    val sandbox = remember { EditorState(sandboxProject()).also { it.showGrid = false } }
    var step by remember { mutableIntStateOf(0) }
    var stepDone by remember { mutableStateOf(false) }
    val statusTop = WindowInsets.statusBars.getTop(density)
    val navBottom = WindowInsets.navigationBars.getBottom(density)

    fun advance() { if (step + 1 >= Steps.size) onDone() else step++ }
    fun nudge() { sandbox.nodes.firstOrNull()?.let { n -> sandbox.updateNode(n.id) { it.copy(x = it.x + 24f) } } }

    // лист вписан между шапкой и карточкой с заданием
    LaunchedEffect(sandbox.viewSize, sandbox.fitted) {
        if (!sandbox.fitted && sandbox.viewSize.width > 0) {
            val d = density.density
            sandbox.fit(topInset = statusTop + 88 * d, bottomInset = navBottom + 210 * d, padding = 16 * d)
        }
    }

    // подготовка шага: чтобы отмена и возврат было что отменять и возвращать, даже если шаги выше пропустили
    LaunchedEffect(step) {
        when (Steps.getOrNull(step)?.gesture) {
            Gesture.UNDO_TAP -> if (sandbox.undoCount == 0) nudge()
            Gesture.REDO_TAP -> if (sandbox.redoCount == 0) { if (sandbox.undoCount == 0) nudge(); sandbox.undo() }
            Gesture.LONG_LAYER, Gesture.LONG_EMPTY -> sandbox.fitted = false
            else -> {}
        }
    }

    // шаг засчитан - коротко показываем 'Получилось' и идём дальше
    LaunchedEffect(stepDone) {
        if (stepDone) { delay(900); stepDone = false; advance() }
    }

    Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.surfaceContainer)) {
        EditorCanvas(
            state = sandbox, onEditText = {}, onOpenStyle = {},
            gestures = gestures,
            onGesture = { g -> if (!stepDone && Steps.getOrNull(step)?.gesture == g) stepDone = true },
        )

        Row(
            Modifier.align(Alignment.TopCenter).fillMaxWidth().statusBarsPadding().padding(start = 20.dp, end = 8.dp, top = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f)) {
                Text(tr("tut_step_n", step + 1, Steps.size), style = MaterialTheme.typography.labelLarge)
                Spacer(Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    for (i in Steps.indices) {
                        Box(
                            Modifier.size(8.dp).background(
                                if (i <= step && (i < step || stepDone)) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant,
                                CircleShape,
                            ),
                        )
                    }
                }
            }
            TextButton(onClick = onSkip) { Text(tr("tut_skip")) }
        }

        Surface(
            modifier = Modifier.align(Alignment.BottomCenter).fillMaxWidth().navigationBarsPadding().padding(12.dp),
            shape = MaterialTheme.shapes.extraLarge,
            color = MaterialTheme.colorScheme.surfaceContainerLow,
            tonalElevation = 2.dp,
        ) {
            val s = Steps[step]
            val on = gestures.isOn(s.gesture)
            Column(Modifier.padding(20.dp).heightIn(min = 96.dp), verticalArrangement = Arrangement.Center) {
                when {
                    stepDone -> Row(verticalAlignment = Alignment.CenterVertically) {
                        QIcon(Ico.Check, tint = MaterialTheme.colorScheme.primary)
                        Spacer(Modifier.width(12.dp))
                        Text(tr("tut_ok"), style = MaterialTheme.typography.titleMedium)
                    }
                    !on -> {
                        Text(tr("tut_off"), style = MaterialTheme.typography.titleMedium)
                        Row {
                            TextButton(onClick = { gestures.set(s.gesture, true) }) { Text(tr("tut_enable")) }
                            TextButton(onClick = { advance() }) { Text(tr("tut_next")) }
                        }
                    }
                    else -> {
                        Text(tr(s.textKey), style = MaterialTheme.typography.titleMedium)
                        Row {
                            TextButton(onClick = { advance() }) { Text(tr("tut_skip_step")) }
                            if (s.gesture.toggleable) {
                                TextButton(onClick = { gestures.set(s.gesture, false); advance() }) { Text(tr("tut_disable")) }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun TutorialDone(onFinish: () -> Unit) {
    Column(
        Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(horizontal = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center,
    ) {
        Text(tr("tut_done_title"), style = MaterialTheme.typography.headlineMedium, textAlign = TextAlign.Center)
        Spacer(Modifier.height(12.dp))
        Text(
            tr("tut_done_body"), style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(32.dp))
        Button(onClick = onFinish, modifier = Modifier.fillMaxWidth()) { Text(tr("tut_finish")) }
    }
}
