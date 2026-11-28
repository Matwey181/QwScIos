package com.qwenz.qwel.render

import com.qwenz.qwel.data.Node
import com.qwenz.qwel.data.NodeKind
import com.qwenz.qwel.data.Project

/**
 * Для выгрузки под material3 1.4.0, где MaterialShapes недоступны: каждая фигура из библиотеки (SHAPE)
 * заменяется слоем-контуром (PATH) с тем же видом; поворот запекается в контур.
 */
fun withoutLibraryShapes(p: Project): Project {
    fun conv(list: List<Node>): List<Node> = list.map { n ->
        if (n.kind != NodeKind.SHAPE) return@map n
        val made = nodeGeometry(n)?.let { pathToNode(it, n, n.name) } ?: return@map n
        n.copy(kind = NodeKind.PATH, x = made.x, y = made.y, w = made.w, h = made.h, path = made.path, evenOdd = made.evenOdd, rotation = 0f, shapeId = "")
    }
    return p.copy(nodes = conv(p.nodes), pages = p.pages.map { it.copy(nodes = conv(it.nodes)) })
}
