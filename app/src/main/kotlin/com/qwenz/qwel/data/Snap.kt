package com.qwenz.qwel.data

import kotlin.math.abs

data class SnapResult(val dx: Float, val dy: Float, val guidesX: List<Float>, val guidesY: List<Float>)

/** Умные направляющие: прилипание краёв/центра к краям/центрам соседей и холста. */
fun snapMove(moving: Box, targets: List<Box>, canvas: Box, threshold: Float): SnapResult {
    val tx = ArrayList<Float>(); val ty = ArrayList<Float>()
    for (b in targets + canvas) { tx += listOf(b.l, b.cx, b.r); ty += listOf(b.t, b.cy, b.b) }
    fun best(m: List<Float>, t: List<Float>): Float {
        var bestD = Float.MAX_VALUE; var res = 0f
        for (a in m) for (c in t) { val d = c - a; if (abs(d) < abs(bestD)) { bestD = d; res = d } }
        return if (abs(bestD) <= threshold) res else 0f
    }
    val dx = best(listOf(moving.l, moving.cx, moving.r), tx)
    val dy = best(listOf(moving.t, moving.cy, moving.b), ty)
    val m = moving.offset(dx, dy)
    val gx = tx.filter { t -> listOf(m.l, m.cx, m.r).any { abs(it - t) < 0.5f } }.distinct()
    val gy = ty.filter { t -> listOf(m.t, m.cy, m.b).any { abs(it - t) < 0.5f } }.distinct()
    return SnapResult(dx, dy, gx, gy)
}
