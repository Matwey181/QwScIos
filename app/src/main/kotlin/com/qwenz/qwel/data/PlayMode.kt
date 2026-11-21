package com.qwenz.qwel.data

import com.qwenz.qwel.i18n.tr
import kotlin.math.PI
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.max
import kotlin.math.sin

/**
 * Режим 'Играть': часть компонентов (слайдер, переключатель, чекбокс, радиокнопка, фильтр-чип) временно работает
 * по-настоящему. Проект не меняется: поверх слоёв считается временное состояние, при выходе оно пропадает.
 * Компонент узнаётся по роли слоя ([Node.widget], "вид:часть") и общей группе.
 */
object PlayMode {
    class Widget(val group: String, val kind: String, val nodes: List<Node>, val all: List<Node> = nodes) {
        fun part(p: String): Node? = nodes.firstOrNull { it.widget.substringAfter(':').substringBefore('/') == p }
        fun parts(p: String): List<Node> = nodes.filter { it.widget.substringAfter(':').substringBefore('/') == p }
        val bounds: Box? get() = boundsOf(all)
    }

    private val kinds = setOf("slider", "switch", "check", "radio", "chip", "pick", "progress", "spin", "focus", "reveal", "counter")

    /** Группа без своих ролей (кнопка, карточка, строка) получает общий отклик на нажатие. */
    private fun autoPress(all: List<Node>): Boolean {
        if (all.size > 60) return false
        val b = boundsOf(all) ?: return false
        return b.w * b.h < 140000f
    }

    fun widgets(nodes: List<Node>): List<Widget> {
        val byGroup = nodes.filter { it.group.isNotEmpty() && it.visible }.groupBy { it.group }
        val first = HashMap<String, Int>()
        nodes.forEachIndexed { i, n -> if (n.group.isNotEmpty()) first.putIfAbsent(n.group, i) }
        val out = ArrayList<Widget>()
        for ((g, all) in byGroup) {
            val tagged = all.filter { it.widget.isNotEmpty() }
            if (tagged.isEmpty()) { if (autoPress(all)) out += Widget(g, "press", all, all); continue }
            val k = tagged.first().widget.substringBefore(':')
            if (k in kinds && tagged.all { it.widget.substringBefore(':') == k }) out += Widget(g, k, tagged, all)
        }
        // одиночный слой со скруглением при нажатии - тоже кнопка, даже без группы
        nodes.forEachIndexed { i, n ->
            if (n.group.isEmpty() && n.visible && n.kind == NodeKind.RECT && n.pressCorner >= 0f) {
                out += Widget("n:" + n.id, "press", listOf(n), listOf(n)); first["n:" + n.id] = i
            }
        }
        return out.sortedBy { first[it.group] ?: 0 }
    }

    fun hasWidgets(nodes: List<Node>): Boolean = widgets(nodes).isNotEmpty()

    /** Верхний слой с действием под точкой (x, y) в координатах листа; [shown] - виден ли слой сейчас (в игре слои можно скрывать). */
    fun actionAt(nodes: List<Node>, x: Float, y: Float, shown: (Node) -> Boolean = { it.visible }): Node? {
        for (n in nodes.asReversed()) {
            if (n.action.isEmpty() || n.isMask || !shown(n)) continue
            val rad = Math.toRadians(-n.rotation.toDouble())
            val dx = x - n.cx; val dy = y - n.cy
            val lx = dx * kotlin.math.cos(rad) - dy * kotlin.math.sin(rad)
            val ly = dx * kotlin.math.sin(rad) + dy * kotlin.math.cos(rad)
            if (kotlin.math.abs(lx) <= n.w / 2f && kotlin.math.abs(ly) <= n.h / 2f) return n
        }
        return null
    }

    /** Верхний компонент под точкой документа; область нажатия чуть шире самого компонента. */
    fun widgetAt(nodes: List<Node>, x: Float, y: Float, pad: Float): Widget? {
        for (w in widgets(nodes).asReversed()) {
            val b = w.bounds ?: continue
            val ph = max(pad, (44f - b.h) / 2f)
            if (x >= b.l - pad && x <= b.r + pad && y >= b.t - ph && y <= b.b + ph) return w
        }
        return null
    }

    /** Волнистая линия для активной части слайдера: ширина [w] документа, длина волны около 28. */
    fun wavePath(w: Float): String {
        val periods = max(w / 28f, 0.5f)
        val steps = max(8, (w / 2f).toInt())
        val sb = StringBuilder()
        for (i in 0..steps) {
            val x = i.toFloat() / steps
            val y = 0.5f + 0.34f * sin(2.0 * PI * periods * x).toFloat()
            sb.append(if (i == 0) "M " else "L ").append("%.4f %.4f ".format(java.util.Locale.US, x, y))
        }
        return sb.toString().trim()
    }

    // ---------------------------------------------------------------- выбор пункта (вкладки, навигация, сегменты)

    private class PItem(val k: Int, val nodes: List<Node>) {
        /** Рамка пункта без скрытых (прозрачных или нулевой ширины) слоёв, чтобы свёрнутые карточки не ловили касания. */
        val box: Box = boundsOf(nodes.filter { it.opacity > 0.05f && it.w > 1f }.ifEmpty { nodes })!!
    }

    private fun extras(role: String, from: Int): List<String> = role.split('/').drop(from)
    private fun floats(v: String): List<Float>? = v.split(';').mapNotNull { it.toFloatOrNull() }.takeIf { it.isNotEmpty() }
    private fun xsOfRole(role: String, from: Int): List<Float>? = extras(role, from).firstOrNull { it != "f" && !it.startsWith("w=") }?.let(::floats)
    private fun wsOfRole(role: String, from: Int): List<Float>? = extras(role, from).firstOrNull { it.startsWith("w=") }?.removePrefix("w=")?.let(::floats)
    private fun fadeOfRole(role: String, from: Int): Boolean = "f" in extras(role, from)

    private fun pickItems(w: Widget): List<PItem> =
        w.nodes.filter { it.widget.startsWith("pick:i") }
            .groupBy { it.widget.substringAfter("pick:i").substringBefore('/').toIntOrNull() ?: -1 }
            .filterKeys { it >= 0 }.toSortedMap()
            .map { (k, l) -> PItem(k, l) }

    fun pickCount(w: Widget): Int = pickItems(w).size

    /** Номер пункта, ближайшего к точке (в порядке расположения). */
    fun pickIndexAt(w: Widget, x: Float, y: Float): Int {
        val items = pickItems(w)
        val best = items.withIndex().minByOrNull { (_, it) ->
            val dx = it.box.cx - x; val dy = it.box.cy - y; dx * dx + dy * dy
        } ?: return 0
        return best.index
    }

    /** Пункт под касанием: точка должна лежать в области пунктов (с запасом), иначе null (например, касание FAB рядом с пунктами). */
    fun pickHit(w: Widget, x: Float, y: Float): Int? {
        val items = pickItems(w)
        val box = boundsOf(items.flatMap { it.nodes }) ?: return null
        if (x < box.l - 32f || x > box.r + 32f || y < box.t - 32f || y > box.b + 32f) return null
        return pickIndexAt(w, x, y)
    }

    private fun initialPick(w: Widget): Float {
        val items = pickItems(w)
        if (items.isEmpty()) return 0f
        val sizes = items.map { it.nodes.first() }
        if (sizes.any { wsOfRole(it.widget, 3) != null }) {
            return sizes.withIndex().maxByOrNull { it.value.w }!!.index.toFloat()   // карусель: главный пункт самый широкий
        }
        val ind = w.part("ind") ?: w.part("fit")
        if (ind != null) {
            return items.withIndex().minByOrNull { (_, it) ->
                val dx = it.box.cx - ind.cx; val dy = it.box.cy - ind.cy; dx * dx + dy * dy
            }!!.index.toFloat()
        }
        val sel = items.indexOfFirst { it.nodes.any { n -> n.fillToken == n.widget.split('/').getOrNull(1)?.toIntOrNull() } }
        return max(sel, 0).toFloat()
    }

    private fun patchPick(w: Widget, v: Float, tone: Tone, out: MutableMap<String, Node>) {
        val items = pickItems(w)
        if (items.isEmpty()) return
        val n = items.size
        val vv = v.coerceIn(0f, (n - 1).toFloat())
        val k0 = floor(vv).toInt(); val k1 = min(k0 + 1, n - 1); val f = vv - k0
        fun mixF(a: Float, b: Float) = a + (b - a) * f
        val chosen = vv.roundToInt()
        // положения слоёв считаются от левого края самого компонента (фон), чтобы переживать перенос
        val base = boundsOf(w.all.filter { !it.widget.startsWith("pick:i") }) ?: boundsOf(w.nodes)!!
        fun at(xs: List<Float>): Float = base.l + mixF(xs[min(k0, xs.size - 1)], xs[min(k1, xs.size - 1)])
        for ((idx, it) in items.withIndex()) {
            val weight = (1f - abs(vv - idx)).coerceIn(0f, 1f)
            for (nd in it.nodes) {
                val p = nd.widget.split('/')
                val st = p.getOrNull(1)?.toIntOrNull() ?: continue
                val un = p.getOrNull(2)?.toIntOrNull() ?: continue
                var res = nd.copy(fill = mix(tone.color(un), tone.color(st), weight), fillToken = if (idx == chosen) st else un)
                xsOfRole(nd.widget, 3)?.let { res = res.copy(x = at(it)) }
                wsOfRole(nd.widget, 3)?.let { ws -> res = res.copy(w = mixF(ws[min(k0, ws.size - 1)], ws[min(k1, ws.size - 1)]).coerceAtLeast(0f)) }
                if (fadeOfRole(nd.widget, 3)) res = res.copy(opacity = weight)
                out[nd.id] = res
            }
        }
        val cxs = items.map { it.box.cx }; val cys = items.map { it.box.cy }
        val ind = w.part("ind")
        if (ind != null) {
            val cx = mixF(cxs[k0], cxs[k1]); val cy = mixF(cys[k0], cys[k1])
            val moveX = cxs.max() - cxs.min() > 24f; val moveY = cys.max() - cys.min() > 24f
            val xs = xsOfRole(ind.widget, 1)
            out[ind.id] = ind.copy(
                x = if (xs != null) at(xs) else if (moveX) cx - ind.w / 2f else ind.x,
                y = if (moveY) cy - ind.h / 2f else ind.y,
            )
        }
        val fit = w.part("fit")
        if (fit != null) {
            val gb = boundsOf(w.all.filter { it.id != fit.id }) ?: return
            fun seg(k: Int): Pair<Float, Float> = Pair(
                if (k == 0) gb.l else (cxs[k - 1] + cxs[k]) / 2f,
                if (k == n - 1) gb.r else (cxs[k] + cxs[k + 1]) / 2f,
            )
            val a = seg(k0); val b = seg(k1)
            val l = mixF(a.first, b.first); val r = mixF(a.second, b.second)
            out[fit.id] = fit.copy(x = l + 1f, w = (r - l - 2f).coerceAtLeast(1f))
        }
    }

    // ---------------------------------------------------------------- прогресс, фокус, счётчик, нажатие

    private const val ARC_STEPS = 40

    /** Дуга кольцевого индикатора для доли [v] (0..1), начало сверху, по часовой. */
    fun arcPath(v: Float): String {
        val n = (v.coerceIn(0f, 1f) * ARC_STEPS).roundToInt()
        val sb = StringBuilder()
        for (i in 0..n) {
            val a = (-90.0 + 360.0 * i / ARC_STEPS) * PI / 180.0
            sb.append(if (i == 0) "M " else "L ").append("%.4f %.4f ".format(java.util.Locale.US, 0.5 + 0.5 * cos(a), 0.5 + 0.5 * sin(a)))
        }
        return sb.toString().trim()
    }

    private class Bar(val active: Node, val track: Node?) {
        val left = active.x
        val right = track?.let { it.x + it.w } ?: (active.x + active.w)
        val gap = track?.let { max(it.x - (active.x + active.w), 0f) } ?: 0f
        val total = max(right - left - gap, 1f)
    }

    private fun bar(w: Widget): Bar? = w.part("active")?.let { Bar(it, w.part("track")) }

    private fun progressInitial(w: Widget): Float {
        val arc = w.part("arc")
        if (arc != null) return ((arc.path.count { it == 'L' }).toFloat() / ARC_STEPS).coerceIn(0f, 1f)
        val b = bar(w) ?: return 0f
        return (b.active.w / b.total).coerceIn(0f, 1f)
    }

    /** Значение полосы или кольца по точке касания. */
    fun scrubValue(w: Widget, x: Float, y: Float): Float {
        if (w.kind == "slider") return sliderValue(w, x)
        val arc = w.part("arc")
        if (arc != null) {
            val a = atan2((x - arc.cx).toDouble(), -(y - arc.cy).toDouble())
            return (((a / (2.0 * PI)) + 1.0) % 1.0).toFloat()
        }
        val b = bar(w) ?: return 0f
        return ((x - b.left) / b.total).coerceIn(0f, 1f)
    }

    private fun patchProgress(w: Widget, v: Float, out: MutableMap<String, Node>) {
        val arc = w.part("arc")
        if (arc != null) { out[arc.id] = arc.copy(path = arcPath(v)); return }
        val b = bar(w) ?: return
        val aw = max(v * b.total, 0.5f)
        out[b.active.id] = if (b.active.kind == NodeKind.PATH) b.active.copy(w = aw, path = wavePath(aw)) else b.active.copy(w = aw)
        b.track?.let { k ->
            val kx = min(b.left + aw + b.gap, b.right)
            out[k.id] = k.copy(x = kx, w = max(b.right - kx, 0f))
        }
    }

    private fun patchFocus(w: Widget, t: Float, tone: Tone, out: MutableMap<String, Node>) {
        val on = t >= 0.5f
        val err = w.part("box")?.widget?.endsWith("/err") == true
        w.part("box")?.let { b ->
            out[b.id] = if (err) b.copy(strokeWidth = 2f + t)
            else b.copy(stroke = mix(tone.color(Tok.OUTLINE), tone.color(Tok.PRIMARY), t), strokeWidth = 1f + t,
                strokeToken = if (on) Tok.PRIMARY else Tok.OUTLINE)
        }
        w.part("line")?.let { l ->
            val bottom = l.y + l.h
            val h = 2f + t
            out[l.id] = l.copy(y = bottom - h, h = h, fill = mix(tone.color(Tok.ON_SURFACE_VARIANT), tone.color(Tok.PRIMARY), t),
                fillToken = if (on) Tok.PRIMARY else Tok.ON_SURFACE_VARIANT)
        }
        if (!err) w.part("label")?.let { l ->
            out[l.id] = l.copy(fill = mix(tone.color(Tok.ON_SURFACE_VARIANT), tone.color(Tok.PRIMARY), t),
                fillToken = if (on) Tok.PRIMARY else Tok.ON_SURFACE_VARIANT)
        }
    }

    private fun patchCounter(w: Widget, v: Float, out: MutableMap<String, Node>) {
        val l = w.part("label") ?: return
        val txt = v.roundToInt().coerceIn(0, 99).toString()
        if (txt == l.text) return
        val nw = if (l.text.isNotEmpty()) l.w * txt.length / l.text.length else l.w
        out[l.id] = l.copy(text = txt, name = txt, w = nw, x = l.x + (l.w - nw) / 2f)
    }

    private fun lum(c: Int): Float {
        val r = ((c shr 16) and 0xFF) / 255f; val g = ((c shr 8) and 0xFF) / 255f; val b = (c and 0xFF) / 255f
        return 0.299f * r + 0.587f * g + 0.114f * b
    }

    private fun patchPress(w: Widget, t: Float, out: MutableMap<String, Node>) {
        if (t <= 0.001f) return
        val b = w.bounds ?: return
        val s = 1f - 0.05f * t
        val big = w.all.filter { it.kind != NodeKind.TEXT && (it.fill ushr 24) != 0 }.maxByOrNull { it.w * it.h }
        for (n in w.all) {
            var r = n.copy(x = b.cx + (n.x - b.cx) * s, y = b.cy + (n.y - b.cy) * s, w = n.w * s, h = n.h * s,
                fontSize = if (n.kind == NodeKind.TEXT) n.fontSize * s else n.fontSize)
            if (n.kind == NodeKind.RECT && n.pressCorner >= 0f) {
                // скругление считаем от того, что реально видно (9999 у 'таблетки' - это половина высоты)
                val half = min(n.w, n.h) / 2f
                val from = min(n.corner, half)
                val to = min(n.pressCorner, half)
                r = r.copy(corner = (from + (to - from) * t) * s)
            }
            if (n.id == big?.id) {
                val over = if (lum(n.fill) > 0.55f) 0xFF000000.toInt() else 0xFFFFFFFF.toInt()
                r = r.copy(fill = mix(n.fill, (n.fill and 0xFF000000.toInt()) or (over and 0x00FFFFFF), 0.14f * t))
            }
            out[n.id] = r
        }
    }

    // ---------------------------------------------------------------- слайдер

    private class Slider(val thumb: Node, val active: Node, val track: Node) {
        val left = active.x
        val right = max(track.x + track.w, thumb.x + thumb.w)
        val span = (right - left - thumb.w).coerceAtLeast(1f)
        fun value(x: Float) = ((x - left - thumb.w / 2f) / span).coerceIn(0f, 1f)
    }

    private fun slider(w: Widget): Slider? {
        val t = w.part("thumb") ?: return null
        val a = w.part("active") ?: return null
        val k = w.part("track") ?: return null
        return Slider(t, a, k)
    }

    /** Значение слайдера (0..1) по горизонтальной позиции в документе. */
    fun sliderValue(w: Widget, docX: Float): Float = slider(w)?.value(docX) ?: 0f

    /** Начальное состояние: положение слайдера 0..1 или 0/1 у переключателей. */
    fun initial(w: Widget): Float = when (w.kind) {
        "slider" -> slider(w)?.let { it.value(it.thumb.cx) } ?: 0f
        "switch" -> if (w.part("track")?.fillToken == Tok.PRIMARY) 1f else 0f
        "check" -> if (w.part("box")?.fillToken?.let { it >= 0 } == true) 1f else 0f
        "radio" -> if ((w.part("dot")?.w ?: 0f) > 1f) 1f else 0f
        "chip" -> if (w.part("bg")?.fillToken?.let { it >= 0 } == true) 1f else 0f
        "pick" -> initialPick(w)
        "progress" -> progressInitial(w)
        "focus" -> if ((w.part("box")?.let { it.strokeWidth > (if (it.widget.endsWith("/err")) 2.5f else 1.5f) } == true) ||
            w.part("line")?.fillToken == Tok.PRIMARY) 1f else 0f
        "reveal" -> if ((w.parts("item").firstOrNull()?.opacity ?: 1f) > 0.5f) 1f else 0f
        "counter" -> w.part("label")?.text?.trim()?.toIntOrNull()?.toFloat() ?: 0f
        "press", "spin" -> 0f
        else -> 0f
    }

    fun isToggle(w: Widget) = w.kind != "slider" && w.kind != "progress" && w.kind != "counter"

    /** Состояние, которое остаётся в проекте после игры (нажатия и вращение - нет). */
    fun persistent(w: Widget) = w.kind != "press" && w.kind != "spin"

    // ---------------------------------------------------------------- применение состояния

    private fun mix(a: Int, b: Int, t: Float): Int {
        val k = t.coerceIn(0f, 1f)
        fun ch(shift: Int): Int {
            val x = (a ushr shift) and 0xFF; val y = (b ushr shift) and 0xFF
            return (x + (y - x) * k).toInt().coerceIn(0, 255) shl shift
        }
        return ch(24) or ch(16) or ch(8) or ch(0)
    }

    private fun clear(c: Int) = c and 0x00FFFFFF

    /** Слои с учётом временного состояния компонентов: [shown] - группа -> текущее значение (для переключателей 0..1 с плавным переходом). */
    fun apply(nodes: List<Node>, shown: Map<String, Float>, tone: Tone, time: Float = 0f): List<Node> {
        if (shown.isEmpty()) return nodes
        val ws = widgets(nodes).filter { it.group in shown }
        if (ws.isEmpty()) return nodes
        val patched = HashMap<String, Node>()
        val extra = HashMap<String, List<Node>>()
        for (w in ws) {
            val v = shown[w.group] ?: continue
            when (w.kind) {
                "slider" -> patchSlider(w, v, patched)
                "switch" -> patchSwitch(w, v, tone, patched)
                "check" -> patchCheck(w, v, tone, patched, extra)
                "radio" -> patchRadio(w, v, tone, patched, extra)
                "chip" -> patchChip(w, v, tone, patched)
                "pick" -> patchPick(w, v, tone, patched)
                "progress" -> patchProgress(w, v, patched)
                "focus" -> patchFocus(w, v, tone, patched)
                "reveal" -> for (n in w.parts("item")) patched[n.id] = n.copy(opacity = v)
                "counter" -> patchCounter(w, v, patched)
                "spin" -> for (n in w.parts("rot")) patched[n.id] = n.copy(rotation = (time * 220f) % 360f)
                "press" -> patchPress(w, v, patched)
            }
        }
        val out = ArrayList<Node>(nodes.size + extra.size * 2)
        for (n in nodes) { out += patched[n.id] ?: n; extra[n.id]?.let { out += it } }
        return out
    }

    private fun patchSlider(w: Widget, v: Float, out: MutableMap<String, Node>) {
        val s = slider(w) ?: return
        val c0 = s.thumb.cx
        val aOff = c0 - (s.active.x + s.active.w)
        val c = s.left + s.thumb.w / 2f + v * s.span
        out[s.thumb.id] = s.thumb.copy(x = c - s.thumb.w / 2f)
        val aw = max(c - aOff - s.left, 1f)
        out[s.active.id] = if (s.active.kind == NodeKind.PATH) s.active.copy(w = aw, path = wavePath(aw)) else s.active.copy(w = aw)
        if (s.track.x > s.active.x + 1f) {
            val kx = minOf(c + (s.track.x - c0), s.right)
            out[s.track.id] = s.track.copy(x = kx, w = max(s.right - kx, 0f))
        }
    }

    private fun patchSwitch(w: Widget, t: Float, tone: Tone, out: MutableMap<String, Node>) {
        val tr = w.part("track") ?: return
        val th = w.part("thumb") ?: return
        val baseOn = tr.fillToken == Tok.PRIMARY
        val e = if (baseOn) 0f else 1f
        val tb = Box(tr.x - e, tr.y - e, tr.x + tr.w + e, tr.y + tr.h + e)
        val inset = 1f - t
        val on = t >= 0.5f
        out[tr.id] = tr.copy(
            fillToken = if (on) Tok.PRIMARY else Tok.SURFACE_HIGHEST, strokeToken = if (on) -1 else Tok.OUTLINE,
            x = tb.l + inset, y = tb.t + inset, w = tb.w - 2f * inset, h = tb.h - 2f * inset,
            fill = mix(tone.color(Tok.SURFACE_HIGHEST), tone.color(Tok.PRIMARY), t),
            stroke = tone.color(Tok.OUTLINE), strokeWidth = 2f * (1f - t),
        )
        val size = 16f + 8f * t
        val offC = tb.l + tb.h / 2f; val onC = tb.r - tb.h / 2f
        val cx = offC + (onC - offC) * t
        out[th.id] = th.copy(x = cx - size / 2f, y = tb.cy - size / 2f, w = size, h = size,
            fill = mix(tone.color(Tok.OUTLINE), tone.color(Tok.ON_PRIMARY), t), fillToken = if (on) Tok.ON_PRIMARY else Tok.OUTLINE)
        for (b in w.parts("bg")) out[b.id] = b.copy(
            fill = mix(tone.color(Tok.SURFACE_HIGH), tone.color(Tok.PRIMARY_CONTAINER), t),
            fillToken = if (on) Tok.PRIMARY_CONTAINER else Tok.SURFACE_HIGH)
        for (b in w.parts("title")) out[b.id] = b.copy(
            fill = mix(tone.color(Tok.ON_SURFACE), tone.color(Tok.ON_PRIMARY_CONTAINER), t),
            fillToken = if (on) Tok.ON_PRIMARY_CONTAINER else Tok.ON_SURFACE)
        val dx = cx - th.cx
        for (ic in w.parts("icon")) out[ic.id] = ic.copy(x = ic.x + dx, opacity = t)
    }

    private fun patchCheck(w: Widget, t: Float, tone: Tone, out: MutableMap<String, Node>, extra: MutableMap<String, List<Node>>) {
        val box = w.part("box") ?: return
        val on = tone.color(Tok.PRIMARY)
        val isOn = t >= 0.5f
        out[box.id] = box.copy(
            fill = mix(clear(on), on, t), stroke = tone.color(Tok.ON_SURFACE_VARIANT), strokeWidth = 2f * (1f - t),
            fillToken = if (isOn) Tok.PRIMARY else -1, strokeToken = if (isOn) -1 else Tok.ON_SURFACE_VARIANT,
        )
        val marks = w.parts("mark")
        if (marks.isNotEmpty()) { for (m in marks) out[m.id] = m.copy(opacity = t); return }
        if (t <= 0.001f) return
        val k = box.w / 18f
        val c = tone.color(Tok.ON_PRIMARY)
        extra[box.id] = listOf(
            Node("play-${box.id}-1", NodeKind.RECT, tr("check_1"), box.x + 4f * k, box.y + 9f * k, 6f * k, 2f * k, rotation = 45f, fill = c, corner = k,
                opacity = t, group = box.group, widget = "check:mark", fillToken = Tok.ON_PRIMARY),
            Node("play-${box.id}-2", NodeKind.RECT, tr("check_2"), box.x + 6.5f * k, box.y + 8f * k, 9f * k, 2f * k, rotation = -50f, fill = c, corner = k,
                opacity = t, group = box.group, widget = "check:mark", fillToken = Tok.ON_PRIMARY),
        )
    }

    private fun patchRadio(w: Widget, t: Float, tone: Tone, out: MutableMap<String, Node>, extra: MutableMap<String, List<Node>>) {
        val ring = w.part("ring") ?: return
        val on = tone.color(Tok.PRIMARY)
        out[ring.id] = ring.copy(stroke = mix(tone.color(Tok.ON_SURFACE_VARIANT), on, t),
            strokeToken = if (t >= 0.5f) Tok.PRIMARY else Tok.ON_SURFACE_VARIANT)
        val d = ring.w * 0.5f * t
        val dot = w.part("dot")
        if (dot != null) { out[dot.id] = dot.copy(x = ring.cx - d / 2f, y = ring.cy - d / 2f, w = d, h = d); return }
        if (t <= 0.001f) return
        extra[ring.id] = listOf(Node("play-${ring.id}-dot", NodeKind.ELLIPSE, tr("dot"), ring.cx - d / 2f, ring.cy - d / 2f, d, d, fill = on,
            group = ring.group, widget = "radio:dot", fillToken = Tok.PRIMARY))
    }

    private fun patchChip(w: Widget, t: Float, tone: Tone, out: MutableMap<String, Node>) {
        val bg = w.part("bg") ?: return
        val sec = tone.color(Tok.SECONDARY_CONTAINER)
        val on = t >= 0.5f
        out[bg.id] = bg.copy(fill = mix(clear(sec), sec, t), stroke = tone.color(Tok.OUTLINE_VARIANT), strokeWidth = 1f * (1f - t),
            fillToken = if (on) Tok.SECONDARY_CONTAINER else -1, strokeToken = if (on) -1 else Tok.OUTLINE_VARIANT)
        val marks = w.parts("mark")
        val label = w.part("label")
        if (label != null) {
            val b0 = initial(w)
            val shift = if (marks.isNotEmpty()) 10f * (b0 - t) else 0f
            out[label.id] = label.copy(x = label.x + shift, fill = mix(tone.color(Tok.ON_SURFACE_VARIANT), tone.color(Tok.ON_SECONDARY_CONTAINER), t),
                fillToken = if (on) Tok.ON_SECONDARY_CONTAINER else Tok.ON_SURFACE_VARIANT)
        }
        for (m in marks) out[m.id] = m.copy(opacity = t)
    }
}
