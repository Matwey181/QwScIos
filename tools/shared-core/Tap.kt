package com.qwenz.qwel.data
class TapState(val nodes:List<Node>,val playTarget:MutableMap<String,Float>) {
fun playSlide(group:String,v:Float) { playTarget[group]=v }
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
}