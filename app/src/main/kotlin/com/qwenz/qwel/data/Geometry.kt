package com.qwenz.qwel.data

import kotlin.math.atan2
import kotlin.math.max
import kotlin.math.roundToInt

const val MIN_SIZE = 4f

/**
 * Ресайз за ручку (sx, sy in {-1,0,1}) с учётом поворота; противоположная сторона остаётся на месте.
 * [px],[py] - положение пальца в координатах документа.
 */
fun resizeNode(orig: Node, sx: Int, sy: Int, px: Float, py: Float, keepAspect: Boolean): Node {
    val aLocalX = -sx * orig.w / 2f
    val aLocalY = -sy * orig.h / 2f
    val ar = rotate(aLocalX, aLocalY, orig.rotation)
    val ax = orig.cx + ar.first; val ay = orig.cy + ar.second
    val d = rotate(px - ax, py - ay, -orig.rotation)
    var nw = if (sx != 0) max(MIN_SIZE, d.first * sx) else orig.w
    var nh = if (sy != 0) max(MIN_SIZE, d.second * sy) else orig.h
    if (keepAspect && sx != 0 && sy != 0) {
        val s = max(nw / orig.w, nh / orig.h)
        nw = max(MIN_SIZE, orig.w * s); nh = max(MIN_SIZE, orig.h * s)
    }
    val off = rotate(sx * nw / 2f, sy * nh / 2f, orig.rotation)
    val ncx = ax + off.first; val ncy = ay + off.second
    return orig.copy(x = ncx - nw / 2f, y = ncy - nh / 2f, w = nw, h = nh)
}

/** Угол поворота (в градусах, -180..180) для пальца в (px,py); шаг 15 deg с 'прилипанием'. */
fun rotationFor(orig: Node, px: Float, py: Float, snap: Boolean = true): Float {
    var a = Math.toDegrees(atan2((py - orig.cy).toDouble(), (px - orig.cx).toDouble())).toFloat() + 90f
    if (snap) {
        val s = (a / 15f).roundToInt() * 15f
        if (kotlin.math.abs(s - a) < 3f) a = s
    }
    while (a > 180f) a -= 360f
    while (a <= -180f) a += 360f
    return a
}

/**
 * Групповое масштабирование: слои [ids] равномерно увеличиваются в [k] раз относительно точки ([ax], [ay]).
 * Вместе с размером растут скругление, обводка, размытие, тень и размер шрифта; поворот не меняется.
 */
fun scaleNodes(nodes: List<Node>, ids: Set<String>, ax: Float, ay: Float, k: Float): List<Node> =
    nodes.map { n ->
        if (n.id !in ids) n
        else {
            val ncx = ax + (n.cx - ax) * k
            val ncy = ay + (n.cy - ay) * k
            val nw = max(1f, n.w * k)
            val nh = max(1f, n.h * k)
            n.copy(
                x = ncx - nw / 2f, y = ncy - nh / 2f, w = nw, h = nh,
                corner = n.corner * k, strokeWidth = n.strokeWidth * k,
                fontSize = if (n.kind == NodeKind.TEXT) max(4f, n.fontSize * k) else n.fontSize,
                blur = n.blur * k, softBlur = n.softBlur * k, pressCorner = if (n.pressCorner >= 0f) n.pressCorner * k else n.pressCorner, shadowBlur = n.shadowBlur * k, shadowDx = n.shadowDx * k, shadowDy = n.shadowDy * k,
            )
        }
    }
