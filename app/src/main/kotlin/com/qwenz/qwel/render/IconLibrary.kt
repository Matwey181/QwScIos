package com.qwenz.qwel.render

import android.content.Context
import android.util.LruCache
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.vector.PathParser

/** Одна иконка, разобранная из SVG: контур и размеры области (viewBox). */
class IconShape(val box: Rect, val path: Path)

/**
 * Галерея иконок из assets/icons - набор Material Symbols в виде SVG.
 *
 * Раскладка папок (как в npm-пакете @material-symbols/svg-400):
 *   assets/icons/outlined/home.svg, home-fill.svg
 *   assets/icons/rounded/...
 *   assets/icons/sharp/...
 * Нужны не все стили: в галерее появляются только найденные папки. Файл с суффиксом -fill - залитый вариант.
 */
object IconLibrary {
    private lateinit var appContext: Context
    private val known = listOf("outlined", "rounded", "sharp")
    private val names = HashMap<String, List<String>>()
    private val filled = HashMap<String, Set<String>>()
    private val cache = object : LruCache<String, IconShape>(600) {}
    private val failed = HashSet<String>()

    /** Найденные стили в порядке outlined, rounded, sharp. */
    @Volatile private var foundStyles: List<String> = emptyList()
    val styles: List<String> get() { ensure(); return foundStyles }

    @Volatile private var scanned = false
    private val scanLock = Any()

    /** Сканирование папок с тысячами файлов тяжёлое: делаем его в фоне, а кто спросит раньше - дождётся. */
    private fun ensure() {
        if (scanned) return
        synchronized(scanLock) { if (!scanned) reload() }
    }

    /** Папка с набором, который пользователь импортировал из архива в приложении. */
    private fun importedDir(style: String): java.io.File = java.io.File(appContext.filesDir, "icons/$style")

    fun init(context: Context) {
        appContext = context.applicationContext
        Thread({ runCatching { ensure() } }, "icons-scan").start()
    }

    /** Пересканировать иконки: встроенные в assets/icons и импортированные в приложении (они главнее). */
    fun reload() {
        val found = ArrayList<String>()
        val newNames = HashMap<String, List<String>>()
        val newFilled = HashMap<String, Set<String>>()
        for (s in known) {
            val files = HashSet<String>()
            runCatching { appContext.assets.list("icons/$s")?.toList() }.getOrNull().orEmpty().let { files += it }
            importedDir(s).list()?.let { files += it }
            val bases = files.filter { it.endsWith(".svg", ignoreCase = true) }.map { it.removeSuffix(".svg") }
            if (bases.isEmpty()) continue
            newNames[s] = bases.filter { !it.endsWith("-fill") }.sorted()
            newFilled[s] = bases.filter { it.endsWith("-fill") }.map { it.removeSuffix("-fill") }.toSet()
            found += s
        }
        synchronized(this) { names.clear(); names.putAll(newNames); filled.clear(); filled.putAll(newFilled); cache.evictAll(); failed.clear() }
        foundStyles = found
        scanned = true
    }

    /** Есть ли что-то из импортированного (для кнопки 'удалить набор'). */
    fun hasImported(): Boolean = known.any { importedDir(it).list()?.isNotEmpty() == true }

    fun clearImported() {
        for (s in known) importedDir(s).deleteRecursively()
        reload()
    }

    fun isEmpty(): Boolean = styles.isEmpty()
    fun names(style: String): List<String> { ensure(); return names[style].orEmpty() }
    fun hasFilled(style: String): Boolean { ensure(); return filled[style].orEmpty().isNotEmpty() }

    /** Название для людей: home_work -> 'home work'. */
    fun label(name: String): String = name.replace('_', ' ')

    private fun file(style: String, name: String, fill: Boolean): String {
        ensure()
        val useFill = fill && name in filled[style].orEmpty()
        return "icons/$style/$name${if (useFill) "-fill" else ""}.svg"
    }

    fun bytes(style: String, name: String, fill: Boolean): ByteArray? {
        val path = file(style, name, fill)
        val imported = java.io.File(appContext.filesDir, path)
        if (imported.isFile) return runCatching { imported.readBytes() }.getOrNull()
        return runCatching { appContext.assets.open(path).use { it.readBytes() } }.getOrNull()
    }

    /** Контур иконки для плитки в списке. Читается и разбирается по требованию, результат кэшируется. */
    fun shape(style: String, name: String, fill: Boolean): IconShape? {
        val key = file(style, name, fill)
        synchronized(this) { cache.get(key)?.let { return it }; if (key in failed) return null }
        val parsed = bytes(style, name, fill)?.let { parse(it.toString(Charsets.UTF_8)) }
        synchronized(this) { if (parsed == null) failed += key else cache.put(key, parsed) }
        return parsed
    }

    private val viewBoxRe = Regex("viewBox\\s*=\\s*\"([^\"]+)\"")
    private val pathRe = Regex("<path[^>]*?\\sd\\s*=\\s*\"([^\"]+)\"")

    internal fun parse(svg: String): IconShape? {
        val vb = viewBoxRe.find(svg)?.groupValues?.get(1)?.trim()?.split(Regex("[\\s,]+"))?.mapNotNull { it.toFloatOrNull() }
        if (vb == null || vb.size != 4 || vb[2] <= 0f || vb[3] <= 0f) return null
        val total = Path()
        for (m in pathRe.findAll(svg)) {
            val p = runCatching { PathParser().parsePathString(m.groupValues[1]).toPath() }.getOrNull() ?: continue
            total.addPath(p)
        }
        if (total.isEmpty) return null
        return IconShape(Rect(vb[0], vb[1], vb[0] + vb[2], vb[1] + vb[3]), total)
    }
}
