package com.qwenz.qwel.data

import com.qwenz.qwel.render.IconLibrary
import com.qwenz.qwel.render.SvgImport

/**
 * Настоящие иконки Material Symbols внутри компонентов и шаблонов. Если набор иконок не установлен (или такой иконки в нём нет),
 * вместо неё остаётся простая заглушка-кружок, поэтому всё работает и без набора.
 */
object IconNodes {
    /** Иконка [name] в квадрате [size] с центром в (cx, cy); null, если набора или иконки нет. */
    fun make(t: Tone, name: String, g: String, cx: Float, cy: Float, size: Float, tok: Int, fill: Boolean = false): List<Node>? = try {
        val style = IconLibrary.styles.let { s -> if ("outlined" in s) "outlined" else s.firstOrNull() }
        val bytes = style?.let { IconLibrary.bytes(it, name, fill) }
        val res = bytes?.let { SvgImport.parseOwnSize(it, size.toDouble() / 960.0) }
        if (res == null || res.nodes.isEmpty()) null else {
            val dx = cx - res.width / 2f; val dy = cy - res.height / 2f
            val color = t.color(tok, 0xFF1D1B20.toInt())
            res.nodes.map { n ->
                n.copy(
                    id = newId(), x = n.x + dx, y = n.y + dy, name = IconLibrary.label(name), group = g, ratioLock = true,
                    fill = if (n.kind == NodeKind.PATH) color else n.fill, fillToken = if (n.kind == NodeKind.PATH) tok else n.fillToken,
                )
            }
        }
    } catch (e: Throwable) { null }

    /** Иконка или, если её нет, кружок-заглушка. */
    fun icon(t: Tone, name: String, g: String, cx: Float, cy: Float, size: Float, tok: Int, fill: Boolean = false): List<Node> =
        make(t, name, g, cx, cy, size, tok, fill) ?: listOf(
            Node(newId(), NodeKind.ELLIPSE, "icon", cx - size * 0.375f, cy - size * 0.375f, size * 0.75f, size * 0.75f,
                fill = t.color(tok), group = g, fillToken = tok),
        )

    /** Значок 'меню' (три полоски), если иконки нет. */
    fun menu(t: Tone, g: String, cx: Float, cy: Float, tok: Int): List<Node> = make(t, "menu", g, cx, cy, 24f, tok) ?: listOf(-7f, 0f, 7f).map { dy ->
        Node(newId(), NodeKind.RECT, "menu", cx - 9f, cy + dy - 1f, 18f, 2f, fill = t.color(tok), corner = 1f, group = g, fillToken = tok)
    }
}

/** Роль в выборе одного из пунктов (вкладки, навигация): индекс пункта, цвет выбранного и невыбранного. */
fun Node.pick(i: Int, sel: Int, un: Int): Node = copy(widget = "pick:i$i/$sel/$un")
fun List<Node>.pick(i: Int, sel: Int, un: Int): List<Node> = map { it.pick(i, sel, un) }
