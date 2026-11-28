package com.qwenz.qwel.data

import com.qwenz.qwel.render.Assets
import com.qwenz.qwel.render.Fonts
import org.json.JSONObject
import java.io.InputStream
import java.io.OutputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

/** Файл проекта .qwel: zip с project.json, картинками (assets/) и шрифтами (fonts/). */
object ProjectArchive {
    fun export(p: Project, out: OutputStream) {
        ZipOutputStream(out).use { z ->
            z.putNextEntry(ZipEntry("project.json"))
            z.write(ProjectStore.encode(p).toString().toByteArray())
            z.closeEntry()
            for (name in p.nodes.map { it.asset }.filter { it.isNotEmpty() }.distinct()) {
                val bytes = Assets.bytes(name) ?: continue
                z.putNextEntry(ZipEntry("assets/$name")); z.write(bytes); z.closeEntry()
            }
            for (font in p.nodes.map { it.font }.filter { it.isNotEmpty() }.distinct()) {
                val bytes = Fonts.file(font)?.readBytes() ?: continue
                z.putNextEntry(ZipEntry("fonts/$font")); z.write(bytes); z.closeEntry()
            }
        }
    }

    /** Читает .qwel; проект получает новый id, чтобы не затереть существующий. null - файл не подходит. */
    fun import(input: InputStream): Project? = runCatching {
        var json: String? = null
        ZipInputStream(input).use { z ->
            var e = z.nextEntry
            while (e != null) {
                val name = e.name
                if (!e.isDirectory) {
                    val bytes = z.readBytes()
                    when {
                        name == "project.json" -> json = String(bytes)
                        name.startsWith("assets/") -> Assets.put(name.removePrefix("assets/"), bytes)
                        name.startsWith("fonts/") -> Fonts.put(name.removePrefix("fonts/"), bytes)
                    }
                }
                e = z.nextEntry
            }
        }
        val p = ProjectStore.decode(JSONObject(json ?: return@runCatching null))
        val now = System.currentTimeMillis()
        p.copy(id = newId(), created = now, updated = now)
    }.getOrNull()
}
