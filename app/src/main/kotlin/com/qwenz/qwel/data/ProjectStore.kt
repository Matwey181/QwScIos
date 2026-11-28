package com.qwenz.qwel.data

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/** Проекты хранятся как JSON-файлы в filesDir/projects/<id>.json. */
class ProjectStore(context: Context) {
    private val dir = File(context.filesDir, "projects").apply { mkdirs() }

    /** Файлы проектов, свежие первыми (по времени изменения файла). */
    fun files(): List<File> =
        (dir.listFiles { f -> f.extension == "json" } ?: emptyArray()).sortedByDescending { it.lastModified() }

    fun read(f: File): Project? = runCatching { decode(JSONObject(f.readText())) }.getOrNull()

    fun loadAll(): List<Project> =
        (dir.listFiles { f -> f.extension == "json" } ?: emptyArray())
            .mapNotNull { f -> runCatching { decode(JSONObject(f.readText())) }.getOrNull() }
            .sortedByDescending { it.updated }

    fun save(p: Project) {
        val tmp = File(dir, "${p.id}.json.tmp")
        tmp.writeText(encode(p).toString())
        tmp.renameTo(File(dir, "${p.id}.json"))
    }

    fun delete(id: String) {
        File(dir, "$id.json").delete()
    }

    companion object {
        fun encode(p: Project): JSONObject = JSONObject().apply {
            put("v", 1)
            put("id", p.id); put("name", p.name)
            put("w", p.width.toDouble()); put("h", p.height.toDouble())
            put("bg", p.background)
            put("created", p.created); put("updated", p.updated)
            put("bgToken", p.bgToken)
            put("tone", JSONObject().apply {
                put("mode", p.tone.mode); put("seed", p.tone.seed); put("dark", p.tone.dark)
                put("colors", JSONArray().also { a -> p.tone.colors.forEach { a.put(it) } })
            })
            put("nodes", JSONArray().also { arr -> p.nodes.forEach { arr.put(encodeNode(it)) } })
            if (p.pages.size > 1) {
                put("active", p.activePage)
                put("pages", JSONArray().also { arr ->
                    p.pages.forEach { pg ->
                        arr.put(JSONObject().apply {
                            put("id", pg.id); put("name", pg.name)
                            put("nodes", JSONArray().also { a -> pg.nodes.forEach { a.put(encodeNode(it)) } })
                        })
                    }
                })
            }
        }

        fun decode(o: JSONObject): Project {
            val arr = o.getJSONArray("nodes")
            val nodes = (0 until arr.length()).map { decodeNode(arr.getJSONObject(it)) }
            val pagesArr = o.optJSONArray("pages")
            val pages = if (pagesArr == null) emptyList() else (0 until pagesArr.length()).map { i ->
                val po = pagesArr.getJSONObject(i)
                val na = po.getJSONArray("nodes")
                Page(po.optString("id", newId()), po.optString("name"), (0 until na.length()).map { decodeNode(na.getJSONObject(it)) })
            }
            val active = o.optInt("active", 0).coerceIn(0, (pages.size - 1).coerceAtLeast(0))
            return Project(
                id = o.getString("id"), name = o.getString("name"),
                width = o.getDouble("w").toFloat(), height = o.getDouble("h").toFloat(),
                background = o.getInt("bg"), nodes = nodes,
                created = o.optLong("created"), updated = o.optLong("updated"),
                tone = o.optJSONObject("tone")?.let { decodeTone(it) } ?: Tone.Baseline,
                bgToken = o.optInt("bgToken", -1),
                pages = pages, activePage = active,
            )
        }

        private fun decodeTone(o: JSONObject): Tone {
            val arr = o.optJSONArray("colors")
            val colors = if (arr != null && arr.length() == Tok.COUNT) (0 until arr.length()).map { arr.getInt(it) }
            else Tone.Baseline.colors
            return Tone(o.optInt("mode", 0), o.optInt("seed", Tone.BASE_SEED), o.optBoolean("dark", false), colors)
        }

        private fun encodeNode(n: Node) = JSONObject().apply {
            put("id", n.id); put("kind", n.kind.name); put("name", n.name)
            put("x", n.x.toDouble()); put("y", n.y.toDouble()); put("w", n.w.toDouble()); put("h", n.h.toDouble())
            put("rot", n.rotation.toDouble())
            put("fill", n.fill); put("stroke", n.stroke); put("sw", n.strokeWidth.toDouble())
            put("op", n.opacity.toDouble()); put("corner", n.corner.toDouble())
            put("shape", n.shapeId); put("text", n.text)
            put("fs", n.fontSize.toDouble()); put("fw", n.weight)
            put("group", n.group); put("vis", n.visible); put("lock", n.locked); put("ratio", n.ratioLock)
            if (n.path.isNotEmpty()) put("path", n.path)
            if (n.evenOdd) put("eo", true)
            if (n.asset.isNotEmpty()) put("asset", n.asset)
            if (n.font.isNotEmpty()) put("font", n.font)
            if (n.fillToken >= 0) put("ft", n.fillToken)
            if (n.strokeToken >= 0) put("st", n.strokeToken)
            if (n.blur > 0f) put("blur", n.blur.toDouble())
            if (n.softBlur > 0f) put("sb", n.softBlur.toDouble())
            if (n.pressCorner >= 0f) put("pc", n.pressCorner.toDouble())
            if (n.action.isNotEmpty()) put("ac", n.action)
            if (n.mask) put("mask", true)
            if (n.widget.isNotEmpty()) put("wd", n.widget)
            if (n.gradKind != 0) { put("gk", n.gradKind); put("f2", n.fill2); put("ga", n.gradAngle.toDouble()) }
            if (n.shadowBlur > 0f) {
                put("shb", n.shadowBlur.toDouble()); put("shx", n.shadowDx.toDouble())
                put("shy", n.shadowDy.toDouble()); put("shc", n.shadowColor)
            }
        }

        private fun decodeNode(o: JSONObject) = Node(
            id = o.getString("id"),
            kind = runCatching { NodeKind.valueOf(o.getString("kind")) }.getOrDefault(NodeKind.RECT),
            name = o.optString("name"),
            x = o.getDouble("x").toFloat(), y = o.getDouble("y").toFloat(),
            w = o.getDouble("w").toFloat(), h = o.getDouble("h").toFloat(),
            rotation = o.optDouble("rot", 0.0).toFloat(),
            fill = o.optInt("fill"), stroke = o.optInt("stroke"), strokeWidth = o.optDouble("sw", 0.0).toFloat(),
            opacity = o.optDouble("op", 1.0).toFloat(), corner = o.optDouble("corner", 0.0).toFloat(),
            shapeId = o.optString("shape"), text = o.optString("text"),
            fontSize = o.optDouble("fs", 16.0).toFloat(), weight = o.optInt("fw", 400),
            group = o.optString("group"), visible = o.optBoolean("vis", true),
            locked = o.optBoolean("lock", false), ratioLock = o.optBoolean("ratio", false),
            path = o.optString("path"), evenOdd = o.optBoolean("eo", false),
            asset = o.optString("asset"), font = o.optString("font"),
            fillToken = o.optInt("ft", -1), strokeToken = o.optInt("st", -1),
            blur = o.optDouble("blur", 0.0).toFloat(),
            softBlur = o.optDouble("sb", 0.0).toFloat(),
            pressCorner = o.optDouble("pc", -1.0).toFloat(),
            action = o.optString("ac", ""),
            mask = o.optBoolean("mask", false),
            widget = o.optString("wd", ""),
            gradKind = o.optInt("gk", 0), fill2 = o.optInt("f2", 0xFF000000.toInt()),
            gradAngle = o.optDouble("ga", 90.0).toFloat(),
            shadowBlur = o.optDouble("shb", 0.0).toFloat(), shadowDx = o.optDouble("shx", 0.0).toFloat(),
            shadowDy = o.optDouble("shy", 4.0).toFloat(), shadowColor = o.optInt("shc", 0x59000000),
        )
    }
}
