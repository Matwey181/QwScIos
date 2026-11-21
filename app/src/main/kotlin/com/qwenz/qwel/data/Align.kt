package com.qwenz.qwel.data

import kotlin.math.max

enum class AlignMode { LEFT, H_CENTER, RIGHT, TOP, V_CENTER, BOTTOM }
enum class AlignTo { SELECTION, CANVAS }
enum class Axis { H, V }
enum class MatchDim { WIDTH, HEIGHT, BOTH }

/** Слои одной группы двигаются как единое целое. */
private fun units(all: List<Node>, selected: Set<String>): List<List<Node>> {
    val sel = all.filter { it.id in selected && it.visible && !it.locked }
    val out = ArrayList<List<Node>>()
    val seen = HashSet<String>()
    for (n in sel) {
        if (n.group.isEmpty()) out.add(listOf(n))
        else if (seen.add(n.group)) out.add(sel.filter { it.group == n.group })
    }
    return out
}

private fun shift(all: List<Node>, moves: Map<String, Pair<Float, Float>>): List<Node> =
    all.map { n -> moves[n.id]?.let { (dx, dy) -> n.copy(x = n.x + dx, y = n.y + dy) } ?: n }

fun alignNodes(all: List<Node>, selected: Set<String>, mode: AlignMode, canvas: Box, to: AlignTo): List<Node> {
    val us = units(all, selected)
    if (us.isEmpty()) return all
    val boxes = us.map { boundsOf(it)!! }
    val ref = if (to == AlignTo.CANVAS || us.size == 1) canvas else boxes.reduce { a, b -> a.union(b) }
    val moves = HashMap<String, Pair<Float, Float>>()
    for ((i, u) in us.withIndex()) {
        val b = boxes[i]
        val d = when (mode) {
            AlignMode.LEFT -> ref.l - b.l to 0f
            AlignMode.H_CENTER -> ref.cx - b.cx to 0f
            AlignMode.RIGHT -> ref.r - b.r to 0f
            AlignMode.TOP -> 0f to ref.t - b.t
            AlignMode.V_CENTER -> 0f to ref.cy - b.cy
            AlignMode.BOTTOM -> 0f to ref.b - b.b
        }
        for (n in u) moves[n.id] = d
    }
    return shift(all, moves)
}

/** Равные промежутки между >=3 объектами; крайние остаются на месте. */
fun distributeNodes(all: List<Node>, selected: Set<String>, axis: Axis): List<Node> {
    val us = units(all, selected)
    if (us.size < 3) return all
    val items = us.map { it to boundsOf(it)!! }
        .sortedBy { if (axis == Axis.H) it.second.l else it.second.t }
    val first = items.first().second; val last = items.last().second
    val span = if (axis == Axis.H) last.r - first.l else last.b - first.t
    val sum = items.sumOf { (if (axis == Axis.H) it.second.w else it.second.h).toDouble() }.toFloat()
    val gap = (span - sum) / (items.size - 1)
    var cursor = if (axis == Axis.H) first.l else first.t
    val moves = HashMap<String, Pair<Float, Float>>()
    for ((u, b) in items) {
        val d = if (axis == Axis.H) (cursor - b.l) to 0f else 0f to (cursor - b.t)
        for (n in u) moves[n.id] = d
        cursor += (if (axis == Axis.H) b.w else b.h) + gap
    }
    return shift(all, moves)
}

/** Уравнять размеры по самому большому из выбранных (одиночные слои, не группы, не текст). */
fun matchSize(all: List<Node>, selected: Set<String>, dim: MatchDim): List<Node> {
    val sel = all.filter { it.id in selected && it.visible && !it.locked && it.group.isEmpty() && it.kind != NodeKind.TEXT }
    if (sel.size < 2) return all
    val tw = sel.maxOf { it.w }; val th = sel.maxOf { it.h }
    return all.map { n ->
        if (n !in sel) n else {
            val nw = if (dim != MatchDim.HEIGHT) tw else n.w
            val nh = if (dim != MatchDim.WIDTH) th else n.h
            n.copy(x = n.cx - nw / 2f, y = n.cy - nh / 2f, w = nw, h = max(1f, nh))
        }
    }
}
