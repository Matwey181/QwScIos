package com.qwenz.qwel.data

import com.qwenz.qwel.i18n.tr

/** Стартовый проект, который показывается при первом запуске. */
object Samples {
    private fun c(hex: Long) = (0xFF000000 or hex).toInt()

    fun welcome(now: Long = System.currentTimeMillis()): Project {
        val shape = { id: String, name: String, x: Float, y: Float, s: Float, fill: Int, rot: Float ->
            Node(newId(), NodeKind.SHAPE, name, x, y, s, s, rotation = rot, fill = fill, shapeId = id, ratioLock = true)
        }
        fun text(t: String, x: Float, y: Float, size: Float, weight: Int, color: Int) =
            Node(newId(), NodeKind.TEXT, t.take(24), x, y, 1f, 1f, fill = color, text = t, fontSize = size,
                weight = weight, ratioLock = true).withTextSize()

        val nodes = ArrayList<Node>()
        nodes += shape("soft-burst", tr("soft_burst"), -50f, -40f, 230f, Tone.Baseline.color(Tok.TERTIARY_CONTAINER), 12f)
        nodes += shape("cookie-9", tr("cookie"), 200f, 70f, 190f, Tone.Baseline.color(Tok.PRIMARY_CONTAINER), -8f)
        nodes += shape("sunny", tr("sun"), 36f, 250f, 96f, Tone.Baseline.color(Tok.PRIMARY), 0f)
        nodes += shape("pill", tr("pill"), 170f, 300f, 110f, Tone.Baseline.color(Tok.SECONDARY_CONTAINER), -20f).copy(w = 150f, h = 70f, ratioLock = false)
        nodes += text("Vexel", 24f, 380f, 36f, 700, Tone.Baseline.color(Tok.ON_SURFACE))
        nodes += text(tr("sample_headline"), 24f, 436f, 16f, 400, Tone.Baseline.color(Tok.ON_SURFACE_VARIANT))
        nodes += Components.all[0].build(24f, 540f, newId())
        return Project(newId(), tr("welcome"), 360f, 640f, Tone.Baseline.color(Tok.SURFACE), nodes, now, now, Tone.Baseline, Tok.SURFACE)
    }
}
