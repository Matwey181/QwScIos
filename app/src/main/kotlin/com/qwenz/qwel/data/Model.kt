package com.qwenz.qwel.data

import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

enum class NodeKind { RECT, ELLIPSE, SHAPE, TEXT, PATH, IMAGE }

/** Один слой документа. Координаты - в 'dp документа', вращение вокруг центра. */
data class Node(
    val id: String,
    val kind: NodeKind,
    val name: String,
    val x: Float,
    val y: Float,
    val w: Float,
    val h: Float,
    val rotation: Float = 0f,
    val fill: Int = 0xFF006A6A.toInt(),
    val stroke: Int = 0,
    val strokeWidth: Float = 0f,
    val opacity: Float = 1f,
    val corner: Float = 0f,
    val shapeId: String = "",
    val text: String = "",
    val fontSize: Float = 16f,
    val weight: Int = 400,
    val group: String = "",
    val visible: Boolean = true,
    val locked: Boolean = false,
    val ratioLock: Boolean = false,
    /** PATH: контур в единичном квадрате ("M x y L x y ... Z"), масштабируется в (x, y, w, h). */
    val path: String = "",
    /** PATH: правило заливки even-odd (дырки), иначе non-zero. */
    val evenOdd: Boolean = false,
    /** IMAGE: имя файла в хранилище картинок. */
    val asset: String = "",
    /** TEXT: имя файла своего шрифта ("" - системный). */
    val font: String = "",
    /** Индекс токена цвета заливки/обводки в [Tone] (-1 - обычный цвет). Слой следует тону проекта. */
    val fillToken: Int = -1,
    val strokeToken: Int = -1,
    /** Размытие фона под слоем (радиус в единицах документа, 0 - выключено): 'матовое стекло'. */
    val blur: Float = 0f,
    /** Размытие самого слоя (радиус в единицах документа, 0 - выключено). */
    val softBlur: Float = 0f,
    /** Скругление, в которое слой плавно переходит при нажатии в режиме 'Играть' (-1 - не меняется). */
    val pressCorner: Float = -1f,
    /** Градиент заливки: 0 - сплошной цвет, 1 - линейный, 2 - радиальный. Идёт от [fill] к [fill2]. */
    val gradKind: Int = 0,
    val fill2: Int = 0xFF000000.toInt(),
    /** Угол линейного градиента в градусах (0 - слева направо, 90 - сверху вниз). */
    val gradAngle: Float = 90f,
    /** Тень (или свечение, если без смещения и светлая): размытие, смещение и цвет. Размытие 0 - тени нет. */
    val shadowBlur: Float = 0f,
    val shadowDx: Float = 0f,
    val shadowDy: Float = 4f,
    val shadowColor: Int = 0x59000000,
    /** Маска: фигура (не рисуется сама) обрезает слой, лежащий прямо под ней. */
    val mask: Boolean = false,
    /** Роль в интерактивном компоненте для режима 'Играть': "вид:часть", например "slider:thumb" ("" - обычный слой). */
    val widget: String = "",
    /** Действие при нажатии в режиме "Играть": "" нет, "goto:<id экрана>", "back", "toggle:<id слоя>", "url:<ссылка>". */
    val action: String = "",
) {
    /** Маской может быть только фигура, прямоугольник, эллипс или контур. */
    val canMask: Boolean get() = kind == NodeKind.RECT || kind == NodeKind.ELLIPSE || kind == NodeKind.SHAPE || kind == NodeKind.PATH
    val isMask: Boolean get() = mask && canMask

    val hasShadow: Boolean get() = shadowBlur > 0.5f && (kind == NodeKind.RECT || kind == NodeKind.ELLIPSE || kind == NodeKind.SHAPE || kind == NodeKind.PATH)
    val hasGradient: Boolean get() = gradKind != 0 && (kind == NodeKind.RECT || kind == NodeKind.ELLIPSE || kind == NodeKind.SHAPE || kind == NodeKind.PATH)

    val cx: Float get() = x + w / 2f
    val cy: Float get() = y + h / 2f

    /** Ограничивающий прямоугольник с учётом поворота. */
    fun bounds(): Box {
        if (rotation == 0f) return Box(x, y, x + w, y + h)
        val pts = corners()
        var l = Float.MAX_VALUE; var t = Float.MAX_VALUE
        var r = -Float.MAX_VALUE; var b = -Float.MAX_VALUE
        for (i in 0 until 4) {
            l = min(l, pts[i * 2]); r = max(r, pts[i * 2]); t = min(t, pts[i * 2 + 1]); b = max(b, pts[i * 2 + 1])
        }
        return Box(l, t, r, b)
    }

    /** 4 угла (tl, tr, br, bl) как x0,y0,x1,y1,... в координатах документа. */
    fun corners(): FloatArray {
        val out = FloatArray(8)
        val hx = w / 2f; val hy = h / 2f
        val xs = floatArrayOf(-hx, hx, hx, -hx)
        val ys = floatArrayOf(-hy, -hy, hy, hy)
        for (i in 0 until 4) {
            val p = rotate(xs[i], ys[i], rotation)
            out[i * 2] = cx + p.first; out[i * 2 + 1] = cy + p.second
        }
        return out
    }

    /** Попадает ли точка документа в слой (с запасом [pad]). */
    fun contains(px: Float, py: Float, pad: Float = 0f): Boolean {
        val p = rotate(px - cx, py - cy, -rotation)
        return abs(p.first) <= w / 2f + pad && abs(p.second) <= h / 2f + pad
    }
}

data class Box(val l: Float, val t: Float, val r: Float, val b: Float) {
    val w: Float get() = r - l
    val h: Float get() = b - t
    val cx: Float get() = (l + r) / 2f
    val cy: Float get() = (t + b) / 2f
    fun union(o: Box) = Box(min(l, o.l), min(t, o.t), max(r, o.r), max(b, o.b))
    fun offset(dx: Float, dy: Float) = Box(l + dx, t + dy, r + dx, b + dy)
}

data class Project(
    val id: String,
    val name: String,
    val width: Float,
    val height: Float,
    val background: Int,
    val nodes: List<Node>,
    val created: Long,
    val updated: Long,
    val tone: Tone = Tone.Baseline,
    /** Токен цвета фона листа (-1 - обычный цвет). */
    val bgToken: Int = -1,
    /** Экраны проекта. Пусто - один экран, его слои лежат в [nodes]. Иначе [nodes] - копия слоёв активного экрана. */
    val pages: List<Page> = emptyList(),
    val activePage: Int = 0,
) {
    /** Все экраны проекта как самостоятельные проекты (для экспорта). Размер и фон у экранов общие. */
    fun pageProjects(): List<Project> =
        if (pages.size < 2) listOf(this)
        else pages.map { pg -> copy(name = "$name-${pg.name}", nodes = pg.nodes, pages = emptyList(), activePage = 0) }
}

/** Экран (артборд) проекта. */
data class Page(val id: String, val name: String, val nodes: List<Node>)

fun rotate(x: Float, y: Float, degrees: Float): Pair<Float, Float> {
    if (degrees == 0f) return x to y
    val a = Math.toRadians(degrees.toDouble())
    val c = cos(a).toFloat(); val s = sin(a).toFloat()
    return (x * c - y * s) to (x * s + y * c)
}

fun newId(): String = java.util.UUID.randomUUID().toString().replace("-", "").take(10)

/** Измерение текста подставляется на Android (Paint); здесь - грубая оценка для тестов. */
object TextMetrics {
    var widthOf: (text: String, size: Float, weight: Int, font: String) -> Float =
        { s, size, _, _ -> s.length * size * 0.55f }

    fun size(text: String, fontSize: Float, weight: Int, font: String = ""): Pair<Float, Float> {
        val lines = text.split('\n')
        val w = lines.maxOf { widthOf(it, fontSize, weight, font) }
        return max(1f, w) to max(1f, lines.size * fontSize * 1.25f)
    }
}

fun Node.withTextSize(): Node {
    if (kind != NodeKind.TEXT) return this
    val (nw, nh) = TextMetrics.size(text, fontSize, weight, font)
    return copy(w = nw, h = nh)
}

fun boundsOf(nodes: List<Node>): Box? {
    var res: Box? = null
    for (n in nodes) res = res?.union(n.bounds()) ?: n.bounds()
    return res
}

/** Пометить слой ролью для режима 'Играть'. */
fun Node.w(role: String): Node = copy(widget = role)
