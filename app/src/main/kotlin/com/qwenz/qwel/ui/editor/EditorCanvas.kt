package com.qwenz.qwel.ui.editor

import androidx.compose.animation.core.Animatable
import androidx.graphics.shapes.Cubic
import com.qwenz.qwel.render.MAX_BLUR_LAYERS
import com.qwenz.qwel.render.LayerBackdrop
import androidx.compose.ui.graphics.rememberGraphicsLayer
import kotlin.math.abs
import kotlin.math.max
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import com.qwenz.qwel.i18n.tr
import androidx.compose.animation.core.AnimationVector1D
import androidx.compose.animation.core.spring
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.waitForUpOrCancellation
import androidx.compose.foundation.gestures.calculateCentroid
import androidx.compose.foundation.gestures.calculatePan
import androidx.compose.foundation.gestures.calculateZoom
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.graphics.shapes.Morph
import com.qwenz.qwel.data.Node
import com.qwenz.qwel.data.NodeKind
import com.qwenz.qwel.data.boundsOf
import com.qwenz.qwel.data.resizeNode
import com.qwenz.qwel.data.scaleNodes
import com.qwenz.qwel.data.rotate
import com.qwenz.qwel.data.rotationFor
import com.qwenz.qwel.data.snapMove
import com.qwenz.qwel.render.drawNodes
import com.qwenz.qwel.shapes.ShapeLibrary
import kotlinx.coroutines.launch

private sealed interface Handle {
    data class Resize(val sx: Int, val sy: Int) : Handle
    object Rotate : Handle
    /** Угловая ручка рамки нескольких слоёв: масштабирует всех вместе. */
    data class Group(val sx: Int, val sy: Int) : Handle
}

private class Spot(val handle: Handle, val pos: Offset)

private class MorphAnim(val morph: Morph, val progress: Animatable<Float, AnimationVector1D>)

/** Четыре угловые ручки общей рамки нескольких слоёв (в координатах экрана). */
private fun groupSpots(state: EditorState, box: com.qwenz.qwel.data.Box): List<Spot> = listOf(
    Spot(Handle.Group(-1, -1), state.toScreen(Offset(box.l, box.t))),
    Spot(Handle.Group(1, -1), state.toScreen(Offset(box.r, box.t))),
    Spot(Handle.Group(-1, 1), state.toScreen(Offset(box.l, box.b))),
    Spot(Handle.Group(1, 1), state.toScreen(Offset(box.r, box.b))),
)

/** Положения ручек выделенного слоя в координатах экрана. [d] - пикселей в dp. */
private fun spots(state: EditorState, n: Node, d: Float): List<Spot> {
    val out = ArrayList<Spot>()
    fun at(lx: Float, ly: Float): Offset {
        val r = rotate(lx, ly, n.rotation)
        return state.toScreen(Offset(n.cx + r.first, n.cy + r.second))
    }
    for (sx in intArrayOf(-1, 1)) for (sy in intArrayOf(-1, 1))
        out += Spot(Handle.Resize(sx, sy), at(sx * n.w / 2f, sy * n.h / 2f))
    if (n.kind != NodeKind.TEXT) {
        if (n.w * state.scale > 56 * d) {
            out += Spot(Handle.Resize(0, -1), at(0f, -n.h / 2f)); out += Spot(Handle.Resize(0, 1), at(0f, n.h / 2f))
        }
        if (n.h * state.scale > 56 * d) {
            out += Spot(Handle.Resize(-1, 0), at(-n.w / 2f, 0f)); out += Spot(Handle.Resize(1, 0), at(n.w / 2f, 0f))
        }
    }
    val up = rotate(0f, -1f, n.rotation)
    out += Spot(Handle.Rotate, at(0f, -n.h / 2f) + Offset(up.first, up.second) * (34 * d))
    return out
}

@Composable
fun EditorCanvas(
    state: EditorState,
    onEditText: (String) -> Unit,
    onOpenStyle: () -> Unit,
    modifier: Modifier = Modifier,
    onLongPressEmpty: () -> Unit = {},
    gestures: Gestures,
    onGesture: (Gesture) -> Unit = {},
) {
    val density = LocalDensity.current.density
    SideEffect { state.density0 = density }

    val scheme = MaterialTheme.colorScheme
    val workspace = scheme.surfaceContainer
    val primary = scheme.primary
    val surface = scheme.surface
    val guideColor = scheme.tertiary
    val gridColor = scheme.outlineVariant
    val gridCache = remember { GridPathCache() }
    val currentEditText by rememberUpdatedState(onEditText)
    val currentOpenStyle by rememberUpdatedState(onOpenStyle)
    val currentLongEmpty by rememberUpdatedState(onLongPressEmpty)
    val currentGesture by rememberUpdatedState(onGesture)
    val haptic = LocalHapticFeedback.current
    // слои для живого размытия фона под слоями (Android 12+); создаются один раз
    val blurLayers = List(MAX_BLUR_LAYERS) { rememberGraphicsLayer() }

    // --- морфинг при смене фигуры слоя
    val active = remember { mutableStateMapOf<String, MorphAnim>() }
    LaunchedEffect(state) {
        val tracked = HashMap<String, String>()
        snapshotFlow { state.nodes.filter { it.kind == NodeKind.SHAPE }.map { it.id to it.shapeId } }
            .collect { list ->
                for ((id, sid) in list) {
                    val prev = tracked.put(id, sid)
                    if (prev != null && prev != sid) {
                        val m = ShapeLibrary.morph(prev, sid) ?: continue
                        val a = MorphAnim(m, Animatable(0f))
                        active[id] = a
                        launch {
                            a.progress.animateTo(1f, spring(dampingRatio = 0.5f, stiffness = 260f))
                            if (active[id] === a) active.remove(id)
                        }
                    }
                }
            }
    }

    // плавные переходы переключателей в режиме 'Играть'
    LaunchedEffect(state.play) {
        if (!state.play) return@LaunchedEffect
        var last = 0L
        while (true) {
            val now = androidx.compose.runtime.withFrameNanos { it }
            if (state.playHasSpin) { if (last != 0L) state.playTime += (now - last) / 1_000_000_000f; last = now }
            for ((g, tg) in state.playTarget.entries.map { it.key to it.value }) {
                val cur = state.playShown[g] ?: tg
                if (cur != tg) {
                    val nx = cur + (tg - cur) * 0.28f
                    state.playShown[g] = if (abs(tg - nx) < 0.01f) tg else nx
                }
                // нажатие: короткая вспышка, после достижения максимума возвращается назад
                if (state.playKind[g] == "press" && (state.playShown[g] ?: 0f) >= 0.9f && tg > 0.5f) state.playTarget[g] = 0f
            }
        }
    }

    Canvas(
        modifier
            .fillMaxSize()
            .onSizeChanged { state.viewSize = it }
            .pointerInput(state) {
                var lastTapTime = 0L
                var lastTapId: String? = null
                var lastEmptyTime = 0L
                var lastEmptyPos = Offset.Zero
                awaitEachGesture {
                    val down = awaitFirstDown(requireUnconsumed = false)
                    if (state.play) { playGesture(state, down); return@awaitEachGesture }
                    // пипетка: тап по листу берёт цвет пикселя, всё остальное в это время не работает
                    val pick = state.eyedrop
                    if (pick != null) {
                        val up = waitForUpOrCancellation()
                        if (up != null) {
                            val doc = state.toDoc(up.position)
                            val argb = state.sampleColor(doc.x, doc.y)
                            if (argb != null) { pick(argb); state.eyedrop = null }
                        }
                        return@awaitEachGesture
                    }
                    val d = this.density
                    val slop = viewConfiguration.touchSlop

                    val single = state.selectedNodes().singleOrNull()?.takeIf { !it.locked && it.visible }
                    var spot: Spot? = null
                    if (single != null) {
                        val near = spots(state, single, d)
                            .filter { (it.pos - down.position).getDistance() <= 26 * d }
                        spot = near.firstOrNull { it.handle is Handle.Rotate }
                            ?: near.minByOrNull { (it.pos - down.position).getDistance() }
                    }
                    // несколько слоёв: ручки на углах общей рамки
                    val multiSel = if (single == null) state.selectedNodes().filter { !it.locked && it.visible }.takeIf { it.size >= 2 } else null
                    if (multiSel != null) {
                        val gb = boundsOf(multiSel)
                        if (gb != null) spot = groupSpots(state, gb)
                            .filter { (it.pos - down.position).getDistance() <= 26 * d }
                            .minByOrNull { (it.pos - down.position).getDistance() }
                    }
                    val grab = if (spot != null) spot.pos - down.position else Offset.Zero
                    val docDown = state.toDoc(down.position)
                    val tol = 6 * d / state.scale
                    val hit: Node? = if (spot == null)
                        state.nodes.lastOrNull { it.visible && !it.locked && it.contains(docDown.x, docDown.y, tol) }
                    else null

                    // 0 - ждём, 1 - перенос, 2 - ресайз, 3 - поворот, 4 - вьюпорт, 5 - долгое нажатие, 6 - масштаб группы
                    var mode = 0
                    var snapTargets: List<com.qwenz.qwel.data.Box>? = null
                    var total = Offset.Zero
                    var moved = false
                    var origNodes: List<Node> = state.nodes
                    var startBox = state.selectionBox()
                    var moveIds: Set<String> = emptySet()
                    var longFired = false
                    var longActed = false
                    var maxPointers = 1
                    var lastUptime = down.uptimeMillis
                    var panDist = 0f
                    var zoomDev = 0f

                    while (true) {
                        // пока палец стоит на месте, ждём долгое нажатие
                        val waitLong = gestures.isOn(Gesture.LONG_EMPTY) || gestures.isOn(Gesture.LONG_LAYER)
                        val ev = if (mode == 0 && !longFired && maxPointers < 2 && waitLong) {
                            val remaining = viewConfiguration.longPressTimeoutMillis - (lastUptime - down.uptimeMillis)
                            withTimeoutOrNull(remaining.coerceAtLeast(1L)) { awaitPointerEvent() }
                        } else awaitPointerEvent()
                        if (ev == null) {
                            longFired = true
                            val allowed = if (hit != null) gestures.isOn(Gesture.LONG_LAYER)
                            else spot == null && gestures.isOn(Gesture.LONG_EMPTY)
                            if (allowed) {
                                longActed = true; mode = 5; moved = true
                                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                if (hit != null) {
                                    if (hit.id !in state.selection) state.select(setOf(hit.id))
                                    currentOpenStyle(); currentGesture(Gesture.LONG_LAYER)
                                } else { currentLongEmpty(); currentGesture(Gesture.LONG_EMPTY) }
                            }
                            continue
                        }
                        val pressedCount = ev.changes.count { it.pressed }
                        if (pressedCount > maxPointers) maxPointers = pressedCount
                        lastUptime = ev.changes.maxOf { it.uptimeMillis }
                        if (pressedCount >= 2) {
                            if (mode != 4) { mode = 4; moved = true; state.guidesX = emptyList(); state.guidesY = emptyList() }
                            val zoom = ev.calculateZoom()
                            val pan = ev.calculatePan()
                            panDist += pan.getDistance(); zoomDev += abs(zoom - 1f)
                            val c = ev.calculateCentroid()
                            if (c != Offset.Unspecified) state.zoomAt(zoom, c)
                            state.pan += pan
                            ev.changes.forEach { it.consume() }
                            continue
                        }
                        val ch = ev.changes.firstOrNull { it.id == down.id } ?: ev.changes.first()
                        if (!ch.pressed) break
                        val delta = ch.position - ch.previousPosition
                        total += delta

                        if (mode == 0 && total.getDistance() > slop) {
                            when {
                                spot?.handle is Handle.Rotate && single != null -> { mode = 3; state.beginGesture(); origNodes = state.nodes }
                                spot != null && single != null -> { mode = 2; state.beginGesture(); origNodes = state.nodes }
                                spot?.handle is Handle.Group && multiSel != null -> {
                                    mode = 6; state.beginGesture(); origNodes = state.nodes
                                    startBox = boundsOf(multiSel); moveIds = multiSel.map { it.id }.toSet()
                                }
                                hit != null -> {
                                    if (hit.id !in state.selection) {
                                        if (state.multi) state.toggle(hit.id) else state.select(setOf(hit.id))
                                    }
                                    mode = 1; state.beginGesture(); currentGesture(Gesture.DRAG)
                                    origNodes = state.nodes; startBox = state.selectionBox(); moveIds = state.selection
                                }
                                else -> mode = 4
                            }
                            moved = true
                        }

                        when (mode) {
                            1 -> {
                                var dx = total.x / state.scale
                                var dy = total.y / state.scale
                                val box = startBox
                                if (state.smartGuides && box != null) {
                                    val targets = snapTargets ?: origNodes.filter { it.id !in moveIds && it.visible }.map { it.bounds() }
                                        .also { snapTargets = it }
                                    val r = snapMove(box.offset(dx, dy), targets, state.canvasBox(), 6 * d / state.scale)
                                    dx += r.dx; dy += r.dy
                                    state.guidesX = r.guidesX; state.guidesY = r.guidesY
                                }
                                val ids = moveIds
                                state.nodes = origNodes.map { if (it.id in ids) it.copy(x = it.x + dx, y = it.y + dy) else it }
                                state.touch(); ch.consume()
                            }
                            2 -> {
                                val orig = single!!
                                val h = spot!!.handle as Handle.Resize
                                val p = state.toDoc(ch.position + grab)
                                val keep = h.sx != 0 && h.sy != 0 && (orig.ratioLock || orig.kind == NodeKind.TEXT)
                                var res = resizeNode(orig, h.sx, h.sy, p.x, p.y, keep)
                                if (orig.kind == NodeKind.TEXT) res = res.copy(fontSize = (orig.fontSize * res.h / orig.h).coerceAtLeast(4f))
                                state.nodes = origNodes.map { if (it.id == orig.id) res else it }
                                state.touch(); ch.consume()
                            }
                            3 -> {
                                val orig = single!!
                                val p = state.toDoc(ch.position)
                                val a = rotationFor(orig, p.x, p.y)
                                state.nodes = origNodes.map { if (it.id == orig.id) it.copy(rotation = a) else it }
                                state.touch(); ch.consume()
                            }
                            4 -> { state.pan += delta; ch.consume() }
                            6 -> {
                                val box = startBox
                                val h = spot?.handle as? Handle.Group
                                if (box != null && h != null) {
                                    val p = state.toDoc(ch.position + grab)
                                    // якорь - противоположный угол рамки; масштаб равномерный, чтобы повёрнутые слои не перекашивало
                                    val ax = if (h.sx < 0) box.r else box.l
                                    val ay = if (h.sy < 0) box.b else box.t
                                    val bw = max(box.w, 1f); val bh = max(box.h, 1f)
                                    val k = max((p.x - ax) * h.sx / bw, (p.y - ay) * h.sy / bh).coerceAtLeast(16f / max(bw, bh))
                                    state.nodes = scaleNodes(origNodes, moveIds, ax, ay, k)
                                    state.touch(); ch.consume()
                                }
                            }
                        }
                    }

                    state.guidesX = emptyList(); state.guidesY = emptyList()

                    // быстрый тап несколькими пальцами: двумя - отменить, тремя - вернуть
                    if (maxPointers >= 2 && !longActed && total.getDistance() < slop && panDist < slop * 1.5f &&
                        zoomDev < 0.04f && lastUptime - down.uptimeMillis < 350
                    ) {
                        if (maxPointers >= 3) {
                            if (gestures.isOn(Gesture.REDO_TAP) && state.redoCount > 0) {
                                state.redo(); state.flashMessage(tr("flash_redo")); currentGesture(Gesture.REDO_TAP)
                            }
                        } else if (gestures.isOn(Gesture.UNDO_TAP) && state.undoCount > 0) {
                            state.undo(); state.flashMessage(tr("flash_undo")); currentGesture(Gesture.UNDO_TAP)
                        }
                    } else if (maxPointers >= 2 && zoomDev > 0.12f) currentGesture(Gesture.PINCH)
                    if (!moved) {
                        if (hit != null) {
                            val now = down.uptimeMillis
                            val isDouble = hit.id == lastTapId && now - lastTapTime < 350
                            // тап по уже выбранной группе/компоненту (или двойной тап) выбирает объект внутри неё
                            val drill = hit.group.isNotEmpty() && !state.multi &&
                                (isDouble || state.enteredGroup == hit.group || hit.id in state.selection)
                            if (state.multi) state.toggle(hit.id)
                            else if (drill) state.selectInside(hit.id)
                            else state.select(setOf(hit.id))
                            currentGesture(Gesture.TAP)
                            if (isDouble && gestures.isOn(Gesture.DOUBLE_LAYER)) {
                                lastTapId = null
                                if (hit.kind == NodeKind.TEXT) currentEditText(hit.id) else currentOpenStyle()
                                currentGesture(Gesture.DOUBLE_LAYER)
                            } else { lastTapId = hit.id; lastTapTime = now }
                        } else if (spot == null) {
                            // двойной тап по пустому месту - вписать лист в экран
                            if (gestures.isOn(Gesture.DOUBLE_FIT) && down.uptimeMillis - lastEmptyTime < 350 &&
                                (down.position - lastEmptyPos).getDistance() < 48 * d
                            ) {
                                lastEmptyTime = 0L; state.fitted = false; currentGesture(Gesture.DOUBLE_FIT)
                            } else { lastEmptyTime = down.uptimeMillis; lastEmptyPos = down.position }
                            if (!state.multi) state.clearSelection()
                        }
                    }
                }
            },
    ) {
        val d = density
        drawRect(workspace)
        val s = state.scale
        val tl = state.toScreen(Offset.Zero)
        val aw = state.width * s
        val ah = state.height * s

        // тень и лист
        drawRoundRect(Color.Black.copy(alpha = 0.10f), tl + Offset(0f, 4 * d), Size(aw, ah), CornerRadius(4 * d))
        drawRoundRect(Color.Black.copy(alpha = 0.08f), tl + Offset(0f, 1 * d), Size(aw, ah), CornerRadius(2 * d))

        withTransform({
            translate(state.pan.x, state.pan.y)
            scale(s, s, Offset.Zero)
        }) {
            drawRect(Color(state.background), Offset.Zero, Size(state.width, state.height))
            if (state.showGrid) {
                var step = 8f
                if (step * s < 7 * d) step = 32f
                if (step * s >= 7 * d) {
                    val gp = gridCache.get(state.width, state.height, step)
                    drawPath(gp, gridColor.copy(alpha = 0.45f), style = Stroke(1f / s))
                }
            }
            val morphOf: (Node) -> List<Cubic>? = { n -> active[n.id]?.let { a -> a.morph.asCubics(a.progress.value) } }
            val shownNodes = if (state.play) com.qwenz.qwel.data.PlayMode.apply(state.nodes, state.playShown, state.tone, state.playTime).let { l -> if (state.playVis.isEmpty()) l else l.map { n -> state.playVis[n.id]?.let { v -> n.copy(visible = v) } ?: n } } else state.nodes
            val backdrop = if (android.os.Build.VERSION.SDK_INT >= 31 && shownNodes.any { it.visible && it.blur > 0.5f }) {
                LayerBackdrop(blurLayers, shownNodes, morphOf, Color(state.background), state.width, state.height)
            } else null
            drawNodes(shownNodes, morphOf, backdrop)
            // маска в документе не видна - в редакторе показываем её контур пунктиром (в экспорт он не попадает)
            for (n in state.nodes) if (!state.play && n.isMask && n.visible) {
                drawPath(
                    com.qwenz.qwel.render.rotatedOutline(n, if (n.kind == NodeKind.SHAPE) morphOf(n) else null), primary,
                    style = Stroke(1.5f * d / s, pathEffect = androidx.compose.ui.graphics.PathEffect.dashPathEffect(floatArrayOf(6f * d / s, 4f * d / s))),
                )
            }
        }
        drawRect(gridColor, tl, Size(aw, ah), style = Stroke(1f * d))

        if (!state.play) {
            drawGuides(state, guideColor, d)
            drawSelection(state, d, primary, surface)
        }
    }
}

/** Жест в режиме 'Играть': слайдер тянется, переключатели срабатывают по тапу, остальное - перемещение и масштаб листа. */
private suspend fun androidx.compose.ui.input.pointer.AwaitPointerEventScope.playGesture(
    state: EditorState, down: androidx.compose.ui.input.pointer.PointerInputChange,
) {
    val d = this.density
    val slop = viewConfiguration.touchSlop
    val doc = state.toDoc(down.position)
    val w = com.qwenz.qwel.data.PlayMode.widgetAt(state.nodes, doc.x, doc.y, 8f * d / state.scale)
    val actionNode = com.qwenz.qwel.data.PlayMode.actionAt(state.nodes, doc.x, doc.y) { state.playShown(it) }
    if (w != null && (w.kind == "slider" || w.kind == "progress")) {
        state.playSlide(w.group, com.qwenz.qwel.data.PlayMode.scrubValue(w, doc.x, doc.y))
        down.consume()
        while (true) {
            val ev = awaitPointerEvent()
            val ch = ev.changes.firstOrNull { it.id == down.id } ?: break
            if (!ch.pressed) break
            val p = state.toDoc(ch.position)
            state.playSlide(w.group, com.qwenz.qwel.data.PlayMode.scrubValue(w, p.x, p.y))
            ch.consume()
        }
        return
    }
    var total = Offset.Zero
    var maxPointers = 1
    while (true) {
        val ev = awaitPointerEvent()
        val pressed = ev.changes.count { it.pressed }
        if (pressed > maxPointers) maxPointers = pressed
        if (pressed >= 2) {
            val zoom = ev.calculateZoom(); val pan = ev.calculatePan(); val c = ev.calculateCentroid()
            if (c != Offset.Unspecified) state.zoomAt(zoom, c)
            state.pan += pan
            ev.changes.forEach { it.consume() }
            continue
        }
        val ch = ev.changes.firstOrNull { it.id == down.id } ?: ev.changes.first()
        if (!ch.pressed) break
        val delta = ch.position - ch.previousPosition
        total += delta
        if (w?.kind == "pick") { if (total.getDistance() > slop) ch.consume() }
        else if (total.getDistance() > slop) { state.pan += delta; ch.consume() }
    }
    if (maxPointers == 1) {
        if (w != null) {
            if (total.getDistance() <= slop) state.playTap(w, doc.x, doc.y)
            else if (w.kind == "pick" && kotlin.math.abs(total.x) > 40f * d && kotlin.math.abs(total.x) > kotlin.math.abs(total.y)) {
                state.playSwipe(w, if (total.x < 0f) 1 else -1)   // свайп влево - следующий пункт
            }
        }
        if (actionNode != null && total.getDistance() <= slop) state.playAction(actionNode)
    }
}

private fun DrawScope.drawGuides(state: EditorState, color: Color, d: Float) {
    val y0 = state.toScreen(Offset(0f, 0f)).y - 8 * d
    val y1 = state.toScreen(Offset(0f, state.height)).y + 8 * d
    val x0 = state.toScreen(Offset(0f, 0f)).x - 8 * d
    val x1 = state.toScreen(Offset(state.width, 0f)).x + 8 * d
    for (gx in state.guidesX) { val x = state.toScreen(Offset(gx, 0f)).x; drawLine(color, Offset(x, y0), Offset(x, y1), 1.5f * d) }
    for (gy in state.guidesY) { val y = state.toScreen(Offset(0f, gy)).y; drawLine(color, Offset(x0, y), Offset(x1, y), 1.5f * d) }
}

private fun DrawScope.drawSelection(state: EditorState, d: Float, primary: Color, surface: Color) {
    val sel = state.selectedNodes().filter { it.visible }
    if (sel.isEmpty()) return
    fun outline(n: Node): Path {
        val c = n.corners()
        val p = Path()
        for (i in 0 until 4) {
            val o = state.toScreen(Offset(c[i * 2], c[i * 2 + 1]))
            if (i == 0) p.moveTo(o.x, o.y) else p.lineTo(o.x, o.y)
        }
        p.close(); return p
    }
    if (sel.size == 1 && !sel[0].locked) {
        val n = sel[0]
        drawPath(outline(n), primary, style = Stroke(2f * d))
        val all = spots(state, n, d)
        val rot = all.first { it.handle is Handle.Rotate }
        val topMid = state.toScreen(Offset(n.cx, n.cy) + Offset(rotate(0f, -n.h / 2f, n.rotation).first, rotate(0f, -n.h / 2f, n.rotation).second))
        drawLine(primary, topMid, rot.pos, 2f * d)
        for (sp in all) {
            when (val h = sp.handle) {
                is Handle.Rotate -> {
                    drawCircle(surface, 10 * d, sp.pos)
                    drawCircle(primary, 10 * d, sp.pos, style = Stroke(2f * d))
                    drawCircle(primary, 3 * d, sp.pos)
                }
                is Handle.Group -> {}
                is Handle.Resize -> {
                    if (h.sx != 0 && h.sy != 0) {
                        val tlp = sp.pos - Offset(7 * d, 7 * d)
                        drawRoundRect(surface, tlp, Size(14 * d, 14 * d), CornerRadius(5 * d))
                        drawRoundRect(primary, tlp, Size(14 * d, 14 * d), CornerRadius(5 * d), style = Stroke(2f * d))
                    } else {
                        rotate(n.rotation + if (h.sx == 0) 0f else 90f, pivot = sp.pos) {
                            val tlp = sp.pos - Offset(10 * d, 4 * d)
                            drawRoundRect(surface, tlp, Size(20 * d, 8 * d), CornerRadius(4 * d))
                            drawRoundRect(primary, tlp, Size(20 * d, 8 * d), CornerRadius(4 * d), style = Stroke(2f * d))
                        }
                    }
                }
            }
        }
    } else {
        for (n in sel) drawPath(outline(n), primary.copy(alpha = 0.7f), style = Stroke(1.5f * d))
        val box = state.selectionBox() ?: return
        val a = state.toScreen(Offset(box.l, box.t)); val b = state.toScreen(Offset(box.r, box.b))
        drawRect(
            primary, a, Size(b.x - a.x, b.y - a.y),
            style = Stroke(2f * d, pathEffect = PathEffect.dashPathEffect(floatArrayOf(10 * d, 8 * d))),
        )
        val live = sel.filter { !it.locked }
        if (live.size >= 2) {
            boundsOf(live)?.let { gb ->
                for (sp in groupSpots(state, gb)) {
                    val tlp = sp.pos - Offset(7 * d, 7 * d)
                    drawRoundRect(surface, tlp, Size(14 * d, 14 * d), CornerRadius(5 * d))
                    drawRoundRect(primary, tlp, Size(14 * d, 14 * d), CornerRadius(5 * d), style = Stroke(2f * d))
                }
            }
        }
    }
}

/** Сетка листа одним контуром (а не сотней drawLine); пересобирается только при смене размера или шага. */
private class GridPathCache {
    private var w = -1f; private var h = -1f; private var step = -1f
    private val path = Path()
    fun get(width: Float, height: Float, st: Float): Path {
        if (width != w || height != h || st != step) {
            w = width; h = height; step = st
            path.reset()
            var x = 0f
            while (x <= width) { path.moveTo(x, 0f); path.lineTo(x, height); x += st }
            var y = 0f
            while (y <= height) { path.moveTo(0f, y); path.lineTo(width, y); y += st }
        }
        return path
    }
}
