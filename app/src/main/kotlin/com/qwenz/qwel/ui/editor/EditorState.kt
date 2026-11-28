package com.qwenz.qwel.ui.editor

import com.qwenz.qwel.i18n.tr

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.unit.IntSize
import com.qwenz.qwel.data.AlignMode
import com.qwenz.qwel.data.AlignTo
import com.qwenz.qwel.data.Axis
import com.qwenz.qwel.data.Box
import com.qwenz.qwel.data.Echo
import com.qwenz.qwel.data.EchoParams
import com.qwenz.qwel.data.MatchDim
import com.qwenz.qwel.data.Node
import com.qwenz.qwel.data.Page
import com.qwenz.qwel.data.NodeKind
import com.qwenz.qwel.data.Project
import com.qwenz.qwel.data.Tone
import com.qwenz.qwel.data.withTone
import com.qwenz.qwel.data.alignNodes
import com.qwenz.qwel.data.boundsOf
import com.qwenz.qwel.data.distributeNodes
import com.qwenz.qwel.data.matchSize
import com.qwenz.qwel.data.newId
import com.qwenz.qwel.render.BoolOp
import com.qwenz.qwel.render.applyBoolOp
import com.qwenz.qwel.render.blendNodes
import com.qwenz.qwel.shapes.ShapeLibrary
import kotlin.math.min

/** Всё состояние открытого проекта: слои, выделение, вьюпорт, история. */
class EditorState(initial: Project) {
    val id: String = initial.id
    val created: Long = initial.created

    var name by mutableStateOf(initial.name)
    var width by mutableFloatStateOf(initial.width)
    var height by mutableFloatStateOf(initial.height)
    var background by mutableIntStateOf(initial.background)
    var nodes by mutableStateOf(initial.nodes)
    /** Тон проекта и токен фона (-1 - фон обычного цвета). */
    var tone by mutableStateOf(initial.tone)
    // --- режим 'Играть': временное состояние компонентов, в проект попадает только то, что осталось выставленным
    var play by mutableStateOf(false)
    val playTarget = androidx.compose.runtime.mutableStateMapOf<String, Float>()
    val playShown = androidx.compose.runtime.mutableStateMapOf<String, Float>()
    val playKind = HashMap<String, String>()
    var playTime by mutableStateOf(0f)
    var playHasSpin = false

    fun startPlay() {
        clearSelection()
        playTarget.clear(); playShown.clear(); playKind.clear(); playTime = 0f
        for (w in com.qwenz.qwel.data.PlayMode.widgets(nodes)) {
            val v = com.qwenz.qwel.data.PlayMode.initial(w)
            playTarget[w.group] = v; playShown[w.group] = v; playKind[w.group] = w.kind
        }
        playHasSpin = playKind.values.any { it == "spin" }
        playVis.clear()
        play = true
    }

    /** Выход из режима: то, что выставили в игре (слайдеры, переключатели, выбор), остаётся в проекте одним шагом отмены. */
    fun stopPlay() {
        val pm = com.qwenz.qwel.data.PlayMode
        val ws = pm.widgets(nodes).associateBy { it.group }
        val touched = playTarget.filter { (g, v) -> ws[g]?.let { pm.persistent(it) && kotlin.math.abs(pm.initial(it) - v) > 0.001f } == true }
        val final = pm.apply(nodes, touched, tone)
        val changed = final != nodes
        play = false; playTarget.clear(); playShown.clear(); playKind.clear(); playVis.clear()
        if (changed) edit(null) { final }
    }

    /** Слои, которые в игре показали или скрыли действием "показать/скрыть слой": id -> виден ли. */
    val playVis = androidx.compose.runtime.mutableStateMapOf<String, Boolean>()
    private val playBack = ArrayList<Int>()
    /** Ссылка, которую действие просит открыть; экран открывает её и обнуляет. */
    var playUrl by mutableStateOf<String?>(null)

    fun playShown(n: Node): Boolean = playVis[n.id] ?: n.visible

    /** Выполняет действие слоя [n] по нажатию в режиме "Играть". */
    fun playAction(n: Node) {
        val a = n.action
        when {
            a.startsWith("goto:") -> {
                val i = pagesWithCurrent().indexOfFirst { it.id == a.substringAfter(':') }
                if (i >= 0 && i != activePage) { playBack.add(activePage); playGoto(i) }
            }
            a == "back" -> playBack.removeLastOrNull()?.let { playGoto(it) }
            a.startsWith("toggle:") -> {
                val id = a.substringAfter(':')
                val cur = playVis[id] ?: nodes.firstOrNull { it.id == id }?.visible ?: return
                playVis[id] = !cur
            }
            a.startsWith("url:") -> playUrl = a.substringAfter(':').trim().takeIf { it.isNotEmpty() }
        }
    }

    /** Переход на другой экран внутри игры: состояние, выставленное в игре, сохраняется как при выходе, дальше игра продолжается. */
    private fun playGoto(i: Int) {
        stopPlay()
        switchPage(i)
        startPlay()
    }

    fun playSlide(group: String, v: Float) { playTarget[group] = v; playShown[group] = v }

    /** Свайп по выбору пункта (вкладки, карусель): на соседний пункт. */
    fun playSwipe(w: com.qwenz.qwel.data.PlayMode.Widget, dir: Int) {
        if (w.kind != "pick") return
        val n = com.qwenz.qwel.data.PlayMode.pickCount(w)
        val cur = Math.round(playTarget[w.group] ?: 0f)
        playTarget[w.group] = (cur + dir).coerceIn(0, maxOf(n - 1, 0)).toFloat()
    }

    fun playTap(w: com.qwenz.qwel.data.PlayMode.Widget, x: Float, y: Float) {
        val g = w.group
        when (w.kind) {
            "pick" -> com.qwenz.qwel.data.PlayMode.pickHit(w, x, y)?.let { playTarget[g] = it.toFloat() }
            "counter" -> {
                val b = w.bounds ?: return
                val d = if (x < b.cx - b.w * 0.2f) -1 else if (x > b.cx + b.w * 0.2f) 1 else 0
                if (d != 0) playSlide(g, ((playTarget[g] ?: 0f) + d).coerceIn(0f, 99f))
            }
            "press" -> playTarget[g] = 1f
            "radio" -> {
                if ((playTarget[g] ?: 0f) > 0.5f) return
                playTarget[g] = 1f
                // радиокнопки в одном ряду или колонке образуют группу: включение одной выключает остальные
                val mine = w.bounds ?: return
                for (o in com.qwenz.qwel.data.PlayMode.widgets(nodes)) {
                    if (o.kind != "radio" || o.group == g) continue
                    val ob = o.bounds ?: continue
                    val sameRow = kotlin.math.abs(ob.cy - mine.cy) < 12f && kotlin.math.abs(ob.cx - mine.cx) < 240f
                    val sameCol = kotlin.math.abs(ob.cx - mine.cx) < 12f && kotlin.math.abs(ob.cy - mine.cy) < 240f
                    if (sameRow || sameCol) playTarget[o.group] = 0f
                }
            }
            else -> playToggle(g)
        }
    }

    fun playToggle(group: String) { playTarget[group] = if ((playTarget[group] ?: 0f) > 0.5f) 0f else 1f }


    var bgToken by mutableIntStateOf(initial.bgToken)

    /** Экраны проекта. Слои активного экрана живут в [nodes], а в списке его копия обновляется при смене экрана и сохранении. */
    var pages by mutableStateOf(
        if (initial.pages.size > 1) initial.pages else listOf(Page(newId(), tr("screen_n", 1), initial.nodes)),
    )
        private set
    var activePage by mutableIntStateOf(if (initial.pages.size > 1) initial.activePage.coerceIn(0, initial.pages.size - 1) else 0)
        private set

    /** Пипетка: пока не null, тап по холсту берёт цвет и отдаёт его сюда. */
    var eyedrop by mutableStateOf<((Int) -> Unit)?>(null)
    /** Снимок листа для пипетки; рисуется один раз, когда пипетка включена. */
    var eyedropImage by mutableStateOf<ImageBitmap?>(null)

    /** Цвет пикселя листа в точке документа ([x], [y]) или null, если точка вне листа или снимок ещё не готов. */
    fun sampleColor(x: Float, y: Float): Int? {
        val img = eyedropImage ?: return null
        if (x < 0f || y < 0f || x >= width || y >= height) return null
        val px = (x / width * img.width).toInt().coerceIn(0, img.width - 1)
        val py = (y / height * img.height).toInt().coerceIn(0, img.height - 1)
        return img.asAndroidBitmap().getPixel(px, py)
    }

    var selection by mutableStateOf<Set<String>>(emptySet())
    /** Режим 'несколько': тап добавляет/убирает слой из выделения. */
    var multi by mutableStateOf(false)

    // вьюпорт: экран = pan + документ * scale (scale - пикселей на единицу документа)
    var scale by mutableFloatStateOf(1f)
    var pan by mutableStateOf(Offset.Zero)
    var viewSize by mutableStateOf(IntSize.Zero)
    var fitted = false

    /** Короткая подсказка поверх холста ('Отменено' и т. п.); сама исчезает через ~1 с. */
    var flash by mutableStateOf<String?>(null)
    var flashId by mutableIntStateOf(0)
    fun flashMessage(text: String) { flash = text; flashId++ }

    var showGrid by mutableStateOf(true)
    var smartGuides by mutableStateOf(true)
    var guidesX by mutableStateOf<List<Float>>(emptyList())
    var guidesY by mutableStateOf<List<Float>>(emptyList())

    /** Растёт при каждом изменении документа - по нему работает автосохранение. */
    var rev by mutableIntStateOf(0)
    var undoCount by mutableIntStateOf(0)
    var redoCount by mutableIntStateOf(0)

    private class Snap(val nodes: List<Node>, val w: Float, val h: Float, val bg: Int, val tone: Tone, val bgToken: Int)
    private val undoStack = ArrayList<Snap>()
    private val redoStack = ArrayList<Snap>()
    private var lastKey: String? = null
    private var lastTime = 0L

    private fun snap() = Snap(nodes, width, height, background, tone, bgToken)

    /** Запись в историю. Одинаковый [key] в пределах ~1 c склеивается (слайдеры, поля). */
    private fun record(key: String?) {
        val now = System.currentTimeMillis()
        if (key == null || key != lastKey || now - lastTime > 1000) {
            undoStack.add(snap())
            if (undoStack.size > 100) undoStack.removeAt(0)
            redoStack.clear()
        }
        lastKey = key; lastTime = now
        undoCount = undoStack.size; redoCount = redoStack.size
    }

    fun touch() { rev++ }

    fun edit(key: String? = null, f: (List<Node>) -> List<Node>) {
        record(key); nodes = f(nodes); touch()
    }

    /** Начало жеста (перетаскивание/ресайз): одна запись в историю на весь жест. */
    fun beginGesture() { record(null) }

    fun undo() {
        if (undoStack.isEmpty()) return
        redoStack.add(snap()); restore(undoStack.removeAt(undoStack.lastIndex))
    }

    fun redo() {
        if (redoStack.isEmpty()) return
        undoStack.add(snap()); restore(redoStack.removeAt(redoStack.lastIndex))
    }

    private fun restore(s: Snap) {
        nodes = s.nodes; width = s.w; height = s.h; background = s.bg; tone = s.tone; bgToken = s.bgToken
        val ids = nodes.map { it.id }.toSet()
        selection = selection.filter { it in ids }.toSet()
        lastKey = null
        undoCount = undoStack.size; redoCount = redoStack.size
        touch()
    }

    // ------------------------------------------------------------ выделение

    /** Группа (компонент), внутрь которой 'вошли': в ней выбирается один объект, а не вся группа. */
    var enteredGroup by mutableStateOf<String?>(null)

    private fun expand(ids: Set<String>): Set<String> {
        val groups = nodes.filter { it.id in ids && it.group.isNotEmpty() }.map { it.group }.toSet()
        return ids + nodes.filter { it.group in groups && it.group.isNotEmpty() }.map { it.id }
    }

    fun select(ids: Set<String>) {
        val eg = enteredGroup
        if (eg != null && ids.isNotEmpty() && nodes.filter { it.id in ids }.all { it.group == eg }) {
            selection = ids; return
        }
        enteredGroup = null
        selection = expand(ids)
    }

    /** Выбрать один объект внутри группы/компонента (без расширения выделения на всю группу). */
    fun selectInside(id: String) {
        val n = nodes.firstOrNull { it.id == id } ?: return
        enteredGroup = n.group.ifEmpty { null }
        selection = setOf(id)
    }

    fun clearSelection() { selection = emptySet(); enteredGroup = null }
    fun selectAll() { selection = nodes.filter { it.visible && !it.locked }.map { it.id }.toSet() }

    fun toggle(id: String) {
        val node = nodes.firstOrNull { it.id == id }
        val ids = if (node != null && enteredGroup != null && node.group == enteredGroup) setOf(id) else expand(setOf(id))
        selection = if (ids.all { it in selection }) selection - ids else selection + ids
    }

    fun selectedNodes(): List<Node> = nodes.filter { it.id in selection }
    fun selectionBox(): Box? = boundsOf(selectedNodes())

    // ------------------------------------------------------------ вьюпорт

    fun toDoc(screen: Offset): Offset = (screen - pan) / scale
    fun toScreen(doc: Offset): Offset = doc * scale + pan

    fun zoomAt(factor: Float, focal: Offset) {
        val ns = (scale * factor).coerceIn(0.05f * density0, 16f * density0)
        val k = ns / scale
        pan = focal - (focal - pan) * k
        scale = ns
    }

    /** Базовая плотность (px на dp) - нужна для границ зума; выставляется канвасом. */
    var density0 = 1f

    fun fit(topInset: Float, bottomInset: Float, padding: Float) {
        if (viewSize.width == 0 || viewSize.height == 0) return
        val availW = viewSize.width - 2 * padding
        val availH = viewSize.height - topInset - bottomInset - 2 * padding
        if (availW <= 0 || availH <= 0) return
        val s = min(availW / width, availH / height)
        scale = s
        pan = Offset(
            (viewSize.width - width * s) / 2f,
            topInset + padding + (availH - height * s) / 2f,
        )
        fitted = true
    }

    fun viewCenterDoc(): Offset = toDoc(Offset(viewSize.width / 2f, viewSize.height / 2f))

    fun canvasBox() = Box(0f, 0f, width, height)

    // ------------------------------------------------------------ операции над слоями

    fun addNodes(list: List<Node>) {
        if (list.isEmpty()) return
        edit { it + list }
        select(list.map { it.id }.toSet())
    }

    fun deleteSelected() {
        if (selection.isEmpty()) return
        val sel = selection
        edit { l -> l.filter { it.id !in sel } }
        selection = emptySet()
    }

    fun duplicateSelected() {
        val sel = selectedNodes()
        if (sel.isEmpty()) return
        val selIds = sel.map { it.id }.toSet()
        // новая группа только для групп, выбранных целиком; одиночный объект из компонента копируется без группы
        val fullGroups = sel.map { it.group }.filter { g -> g.isNotEmpty() && nodes.filter { it.group == g }.all { it.id in selIds } }
            .distinct().associateWith { g -> newId() + (if (g.contains('~')) "~" + g.substringAfter('~') else "") }
        val copies = sel.map { it.copy(id = newId(), x = it.x + 16f, y = it.y + 16f, group = fullGroups[it.group] ?: "") }
        addNodes(copies)
    }

    /** Какое окно эффекта открыто: "echo" или "blend" (null - никакого). */
    var effect by mutableStateOf<String?>(null)

    /** 'Эхо': копии выделенного слоя под ним, все вместе в одной группе. */
    fun applyEcho(p: EchoParams) {
        val src = selectedNodes().singleOrNull()?.takeIf { Echo.canEcho(it) } ?: return
        val g = src.group.ifEmpty { newId() }
        val copies = Echo.copies(src, p).map { it.copy(group = g) }
        edit { l ->
            val i = l.indexOfFirst { it.id == src.id }
            if (i < 0) l else l.take(i) + copies + l[i].copy(group = g) + l.drop(i + 1)
        }
        selection = (copies.map { it.id } + src.id).toSet()
    }

    /** 'Переход' между двумя выделенными слоями: промежуточные формы встают сразу над нижним из них. */
    fun applyBlend(steps: Int) {
        val sel = selectedNodes()
        if (sel.size != 2) return
        val mids = blendNodes(sel[0], sel[1], steps)
        if (mids == null) { flashMessage(tr("effect_failed")); return }
        val lowId = sel[0].id
        edit { l ->
            val i = l.indexOfFirst { it.id == lowId }
            if (i < 0) l else l.take(i + 1) + mids + l.drop(i + 1)
        }
        selection = mids.map { it.id }.toSet()
    }

    fun group() {
        val ids = selection
        if (ids.size < 2) return
        val g = newId()
        edit { l -> l.map { if (it.id in ids) it.copy(group = g) else it } }
    }

    fun ungroup() {
        val ids = selection
        edit { l -> l.map { if (it.id in ids) it.copy(group = "") else it } }
    }

    fun hasGroupSelected() = selectedNodes().any { it.group.isNotEmpty() }

    fun reorder(forward: Boolean, toEnd: Boolean) {
        val ids = selection
        if (ids.isEmpty()) return
        edit { l ->
            if (toEnd) {
                val (s, rest) = l.partition { it.id in ids }
                if (forward) rest + s else s + rest
            } else {
                val m = l.toMutableList()
                if (forward) {
                    for (i in m.size - 2 downTo 0) if (m[i].id in ids && m[i + 1].id !in ids) { val t = m[i]; m[i] = m[i + 1]; m[i + 1] = t }
                } else {
                    for (i in 1 until m.size) if (m[i].id in ids && m[i - 1].id !in ids) { val t = m[i]; m[i] = m[i - 1]; m[i - 1] = t }
                }
                m
            }
        }
    }

    fun updateSelected(key: String? = null, f: (Node) -> Node) {
        val ids = selection
        if (ids.isEmpty()) return
        edit(key) { l -> l.map { if (it.id in ids) f(it) else it } }
    }

    fun updateNode(id: String, key: String? = null, f: (Node) -> Node) {
        edit(key) { l -> l.map { if (it.id == id) f(it) else it } }
    }

    fun toggleVisible(id: String) = updateNode(id) { it.copy(visible = !it.visible) }
    fun toggleLock(id: String) = updateNode(id) { it.copy(locked = !it.locked) }

    /**
     * Маска: один выделенный слой-фигура (под ним есть слой, либо он уже маска - чтобы снять) или два выделенных слоя,
     * где верхний - фигура. Во втором случае фигура сама ставится вплотную над нижним слоем (например над картинкой).
     */
    fun canMaskSelection(): Boolean {
        val ids = selection
        if (ids.size == 2) {
            val two = nodes.filter { it.id in ids }
            return two.size == 2 && two[1].canMask
        }
        val id = ids.singleOrNull() ?: return false
        val i = nodes.indexOfFirst { it.id == id }
        val n = nodes.getOrNull(i) ?: return false
        return n.canMask && (n.mask || i > 0)
    }
    fun selectionIsMask(): Boolean = selectedNodes().singleOrNull()?.isMask == true
    fun toggleMask() {
        if (!canMaskSelection()) return
        val ids = selection
        if (ids.size == 1) { updateSelected { it.copy(mask = !it.mask) }; return }
        edit { l ->
            val two = l.filter { it.id in ids }
            val target = two.first(); val m = two.last()
            val rest = l.filter { it.id != m.id }.toMutableList()
            rest.add(rest.indexOfFirst { it.id == target.id } + 1, m.copy(mask = true))
            rest
        }
    }

    fun setShape(shapeId: String) {
        val def = ShapeLibrary.get(shapeId) ?: return
        updateSelected { if (it.kind == NodeKind.SHAPE) it.copy(shapeId = shapeId, name = def.name) else it }
    }

    fun align(mode: AlignMode, to: AlignTo) { val ids = selection; edit { alignNodes(it, ids, mode, canvasBox(), to) } }
    fun distribute(axis: Axis) { val ids = selection; edit { distributeNodes(it, ids, axis) } }
    fun matchSize(dim: MatchDim) { val ids = selection; edit { matchSize(it, ids, dim) } }

    fun centerOnCanvas() {
        val ids = selection
        edit { l ->
            val h = alignNodes(l, ids, AlignMode.H_CENTER, canvasBox(), AlignTo.CANVAS)
            alignNodes(h, ids, AlignMode.V_CENTER, canvasBox(), AlignTo.CANVAS)
        }
    }

    fun setCanvasSize(w: Float, h: Float) {
        if (w < 16f || h < 16f) return
        record("canvas"); width = w; height = h; touch()
    }

    fun updateBackground(argb: Int, token: Int = -1) { record("bg"); background = argb; bgToken = token; touch() }

    /** Меняет тон проекта: все слои и фон с токенами перекрашиваются под новую схему. */
    fun applyTone(t: Tone) {
        if (t == tone) return
        record("tone")
        tone = t
        nodes = nodes.withTone(t)
        // на остальных экранах слои тоже следуют тону
        pages = pages.mapIndexed { i, p -> if (i == activePage) p else p.copy(nodes = p.nodes.withTone(t)) }
        if (bgToken >= 0) background = t.color(bgToken, background)
        touch()
    }
    fun rename(newName: String) { name = newName.ifBlank { tr("untitled") }; touch() }

    // ------------------------------------------------------------ булевы операции

    /** Применяет операцию к выделенным слоям. false - операция невозможна (мало слоёв или ошибка геометрии). */
    fun applyBool(op: BoolOp): Boolean {
        val ids = selection
        val operands = nodes.filter { it.id in ids && it.visible }
        val need = when (op) { BoolOp.COMBINE, BoolOp.FLATTEN -> 1; else -> 2 }
        if (operands.size < need) return false
        val result = runCatching { applyBoolOp(operands, op) }.getOrNull()
        if (result.isNullOrEmpty()) return false
        val sharedGroup = operands.map { it.group }.distinct().singleOrNull().orEmpty()
        val fixed = result.map { it.copy(group = if (op == BoolOp.FLATTEN) "" else sharedGroup) }
        val operandIds = operands.map { it.id }.toSet()
        val top = nodes.indexOfLast { it.id in operandIds }
        edit { l ->
            val out = ArrayList<Node>()
            for ((i, n) in l.withIndex()) {
                if (n.id !in operandIds) out.add(n)
                if (i == top) out.addAll(fixed)
            }
            out
        }
        enteredGroup = null
        selection = fixed.map { it.id }.toSet()
        return true
    }

    // ------------------------------------------------------------ экраны

    private fun pagesWithCurrent(): List<Page> = pages.mapIndexed { i, p -> if (i == activePage) p.copy(nodes = nodes) else p }

    /** История отмены каждого экрана: при возврате на экран она продолжается, а не начинается заново. */
    private val pageHistory = HashMap<String, Pair<List<Snap>, List<Snap>>>()

    private fun loadPage(i: Int, list: List<Page>) {
        pages.getOrNull(activePage)?.let { pageHistory[it.id] = undoStack.toList() to redoStack.toList() }
        pages = list; activePage = i; nodes = list[i].nodes
        selection = emptySet(); enteredGroup = null
        undoStack.clear(); redoStack.clear(); lastKey = null
        pageHistory[list[i].id]?.let { undoStack.addAll(it.first); redoStack.addAll(it.second) }
        pageHistory.keys.retainAll(list.map { it.id }.toSet())
        undoCount = undoStack.size; redoCount = redoStack.size
        touch()
    }

    fun switchPage(i: Int) {
        if (i == activePage || i !in pages.indices) return
        loadPage(i, pagesWithCurrent())
    }

    /** Новый экран: пустой или копия текущего. Открывается сразу. */
    fun addPage(copyCurrent: Boolean) {
        val list = pagesWithCurrent()
        val fresh = Page(newId(), tr("screen_n", list.size + 1), if (copyCurrent) nodes.map { it.copy(id = newId()) } else emptyList())
        loadPage(list.size, list + fresh)
    }

    /** Копия экрана [i] сразу после него; открывается. */
    fun duplicatePage(i: Int) {
        val list = pagesWithCurrent()
        val src = list.getOrNull(i) ?: return
        val copy = Page(newId(), "${src.name} 2", src.nodes.map { it.copy(id = newId()) })
        loadPage(i + 1, list.take(i + 1) + copy + list.drop(i + 1))
    }

    /** Сдвигает экран [i] на [delta] позиций (-1 раньше, 1 позже); открытый экран остаётся открытым. */
    fun movePage(i: Int, delta: Int) {
        val j = i + delta
        if (i !in pages.indices || j !in pages.indices) return
        val list = pagesWithCurrent().toMutableList()
        val activeId = list[activePage].id
        list.add(j, list.removeAt(i))
        pages = list; activePage = list.indexOfFirst { it.id == activeId }
        touch()
    }

    fun deletePage(i: Int) {
        val list = pagesWithCurrent()
        if (list.size < 2 || i !in list.indices) return
        val rest = list.filterIndexed { k, _ -> k != i }
        val next = when {
            i < activePage -> activePage - 1
            i == activePage -> i.coerceAtMost(rest.size - 1)
            else -> activePage
        }
        loadPage(next, rest)
    }

    fun renamePage(i: Int, newName: String) {
        if (i !in pages.indices) return
        pages = pages.mapIndexed { k, p -> if (k == i) p.copy(name = newName.ifBlank { tr("screen_n", i + 1) }) else p }
        touch()
    }

    fun toProject(now: Long = System.currentTimeMillis()) =
        Project(
            id, name, width, height, background, nodes, created, now, tone, bgToken,
            pages = if (pages.size > 1) pagesWithCurrent() else emptyList(), activePage = activePage,
        )
}
