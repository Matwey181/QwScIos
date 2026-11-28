package com.qwenz.qwel.render

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import android.util.LruCache
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import com.qwenz.qwel.data.newId
import java.io.File

/** Результат импорта картинки: имя файла в хранилище и исходный размер в пикселях. */
class ImportedImage(val name: String, val width: Int, val height: Int)

/** Хранилище картинок проектов: filesDir/assets. Слой IMAGE ссылается на файл по имени. */
object Assets {
    private lateinit var dir: File
    private val cache = object : LruCache<String, ImageBitmap>(48 * 1024) {
        override fun sizeOf(key: String, value: ImageBitmap): Int = value.width * value.height * 4 / 1024
    }
    private val failed = HashSet<String>()
    private const val MAX_SIDE = 2048

    fun init(context: Context) {
        dir = File(context.applicationContext.filesDir, "assets").apply { mkdirs() }
        appContext = context.applicationContext
    }

    private lateinit var appContext: Context

    fun file(name: String): File = File(dir, name)

    /** Копирует выбранную картинку в хранилище. Вызывать не на главном потоке. */
    fun importImage(uri: Uri): ImportedImage? = runCatching {
        val tmp = File(dir, "tmp_${newId()}")
        appContext.contentResolver.openInputStream(uri)?.use { input -> tmp.outputStream().use { input.copyTo(it) } }
            ?: return@runCatching null
        val o = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(tmp.path, o)
        if (o.outWidth <= 0 || o.outHeight <= 0) { tmp.delete(); return@runCatching null }
        val ext = when (o.outMimeType) {
            "image/jpeg" -> "jpg"; "image/webp" -> "webp"; "image/gif" -> "gif"; else -> "png"
        }
        val name = "img_${newId()}.$ext"
        tmp.renameTo(File(dir, name))
        ImportedImage(name, o.outWidth, o.outHeight)
    }.getOrNull()

    /** Сохраняет растр как PNG (для 'объединить слои'). */
    fun saveBitmap(bitmap: Bitmap): String? = runCatching {
        val name = "img_${newId()}.png"
        File(dir, name).outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        name
    }.getOrNull()

    /** Декодированная картинка (уменьшается до 2048 px по большей стороне), с кэшем. */
    fun bitmap(name: String): ImageBitmap? {
        if (name.isEmpty() || name in failed) return null
        cache.get(name)?.let { return it }
        val f = File(dir, name)
        if (!f.exists()) { failed.add(name); return null }
        val bmp = runCatching {
            val o = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(f.path, o)
            var sample = 1
            while (maxOf(o.outWidth, o.outHeight) / sample > MAX_SIDE) sample *= 2
            val o2 = BitmapFactory.Options().apply { inSampleSize = sample }
            BitmapFactory.decodeFile(f.path, o2)?.asImageBitmap()
        }.getOrNull()
        if (bmp == null) failed.add(name) else cache.put(name, bmp)
        return bmp
    }

    /** Кладёт файл картинки из архива проекта (существующие не перезаписываются). */
    fun put(name: String, bytes: ByteArray) {
        val safe = name.substringAfterLast('/').substringAfterLast('\\')
        if (safe.isEmpty() || safe.startsWith(".")) return
        val f = File(dir, safe)
        if (!f.exists()) runCatching { f.writeBytes(bytes) }
    }

    fun bytes(name: String): ByteArray? = runCatching { File(dir, name).readBytes() }.getOrNull()

    fun mime(name: String): String = when (name.substringAfterLast('.').lowercase()) {
        "jpg", "jpeg" -> "image/jpeg"; "webp" -> "image/webp"; "gif" -> "image/gif"; else -> "image/png"
    }

    /** Удаляет файлы, на которые больше никто не ссылается. */
    fun cleanup(used: Set<String>) {
        dir.listFiles()?.forEach { if (it.name !in used) it.delete() }
        cache.evictAll(); failed.clear()
    }
}

/** Библиотека своих шрифтов: filesDir/fonts. Слой TEXT ссылается на файл по имени. */
object Fonts {
    private lateinit var dir: File
    private lateinit var appContext: Context
    private val cache = HashMap<String, Typeface?>()
    private val finalCache = HashMap<String, Typeface>()

    /** Имена файлов импортированных шрифтов (наблюдаемый список для UI). */
    val names = mutableStateListOf<String>()

    // ---- встроенные шрифты: assets/fonts/<Семейство>-<Начертание>.ttf (например Figtree-Bold.ttf)
    // Положите туда новые файлы по этому шаблону - семейство появится в выборе шрифта само.
    private const val BUILTIN = "asset:"
    private val WEIGHTS = mapOf(
        "thin" to 100, "extralight" to 200, "light" to 300, "regular" to 400, "medium" to 500,
        "semibold" to 600, "bold" to 700, "extrabold" to 800, "black" to 900,
    )

    /** Файл встроенного семейства: вес и путь в assets. */
    class BuiltinFace(val weight: Int, val path: String)

    private val builtinFaces = LinkedHashMap<String, MutableList<BuiltinFace>>()

    /** Встроенные семейства; в слое хранятся как "asset:Семейство". */
    val builtinFonts: List<String> get() = builtinFaces.keys.map { BUILTIN + it }

    /** Шрифт интерфейса: семейство [family] из assets/fonts, все его начертания. null - если файлов нет (тогда системный). */
    fun uiFamily(family: String = UI_FONT): FontFamily? {
        val faces = builtinFacesOf(family)
        if (faces.isEmpty()) return null
        return FontFamily(faces.map { Font(it.path, appContext.assets, FontWeight(it.weight)) })
    }

    /** Шрифт интерфейса по умолчанию. Остальные встроенные семейства выбираются в настройках. */
    const val UI_FONT = "InterSA"

    /** Семейства, которые можно выбрать для интерфейса (все из assets/fonts). */
    val uiFontFamilies: List<String> get() = builtinFaces.keys.toList()

    /** Название семейства для списка: InterSA пишется как 'Inter SA'. */
    fun familyLabel(family: String): String = family.replace(Regex("(?<=[a-z])(?=[A-Z])"), " ")

    fun isBuiltin(font: String) = font.startsWith(BUILTIN)

    private fun scanBuiltin() {
        builtinFaces.clear()
        val files = runCatching { appContext.assets.list("fonts")?.toList() }.getOrNull().orEmpty().sorted()
        for (f in files) {
            if (f.substringAfterLast('.').lowercase() !in setOf("ttf", "otf")) continue
            val stem = f.substringBeforeLast('.')
            val family = stem.substringBeforeLast('-', "").ifEmpty { continue }
            val style = stem.substringAfterLast('-').lowercase()
            if (style.contains("italic")) continue          // курсив отдельным начертанием пока не подключаем
            val weight = WEIGHTS[style] ?: continue
            builtinFaces.getOrPut(family) { ArrayList() }.add(BuiltinFace(weight, "fonts/$f"))
        }
    }

    /** Ближайшее по весу начертание встроенного семейства. */
    fun builtinFace(font: String, weight: Int): BuiltinFace? =
        builtinFaces[font.removePrefix(BUILTIN)]?.minByOrNull { kotlin.math.abs(it.weight - weight) }

    /** Все файлы семейства - для FontFamily интерфейса. */
    fun builtinFacesOf(family: String): List<BuiltinFace> = builtinFaces[family].orEmpty()

    /** Байты шрифта для встраивания в SVG: (данные, mime, вес начертания или null). */
    fun embedData(font: String, weight: Int): Triple<ByteArray, String, Int?>? {
        if (isBuiltin(font)) {
            val face = builtinFace(font, weight) ?: return null
            val bytes = runCatching { appContext.assets.open(face.path).use { it.readBytes() } }.getOrNull() ?: return null
            return Triple(bytes, if (face.path.endsWith(".otf")) "font/otf" else "font/ttf", face.weight)
        }
        val f = file(font) ?: return null
        return Triple(f.readBytes(), if (font.lowercase().endsWith(".otf")) "font/otf" else "font/ttf", null)
    }

    /** Начертания для выгрузки в res/font: встроенное семейство даёт все веса, свой шрифт - один файл (ttc не подходит). */
    fun exportFaces(font: String): List<Pair<Int, String>> {
        if (isBuiltin(font)) {
            return builtinFaces[font.removePrefix(BUILTIN)].orEmpty().map { it.weight to it.path.substringAfterLast('.').lowercase() }
        }
        val f = file(font) ?: return emptyList()
        val ext = f.extension.lowercase()
        return if (ext == "ttf" || ext == "otf") listOf(400 to ext) else emptyList()
    }

    fun init(context: Context) {
        appContext = context.applicationContext
        dir = File(appContext.filesDir, "fonts").apply { mkdirs() }
        scanBuiltin()
        refresh()
    }

    private fun refresh() {
        val list = dir.listFiles()
            ?.filter { it.extension.lowercase() in setOf("ttf", "otf", "ttc") }
            ?.map { it.name }?.sorted().orEmpty()
        names.clear(); names.addAll(list)
    }

    /** Кладёт шрифт из архива проекта (существующие не перезаписываются). */
    fun put(name: String, bytes: ByteArray) {
        val safe = name.substringAfterLast('/').substringAfterLast('\\')
        if (safe.isEmpty() || safe.startsWith(".") || safe.substringAfterLast('.').lowercase() !in setOf("ttf", "otf", "ttc")) return
        val f = File(dir, safe)
        if (!f.exists()) { runCatching { f.writeBytes(bytes) }; refresh() }
    }

    fun displayName(font: String): String =
        if (isBuiltin(font)) font.removePrefix(BUILTIN) else font.substringBeforeLast('.')

    fun file(font: String): File? = font.takeIf { it.isNotEmpty() && !isBuiltin(it) }?.let { File(dir, it).takeIf { f -> f.exists() } }

    /** Копирует шрифт в библиотеку и проверяет, что он загружается. Не на главном потоке. */
    fun import(uri: Uri): String? = runCatching {
        var display = "font"
        appContext.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) display = it.getString(0) ?: display
        }
        val base = display.substringBeforeLast('.').replace(Regex("[^\\p{L}\\p{N} _.-]"), "_").ifBlank { "font" }
        val ext = display.substringAfterLast('.', "ttf").lowercase().let { if (it in setOf("ttf", "otf", "ttc")) it else "ttf" }
        var name = "$base.$ext"
        var i = 2
        while (File(dir, name).exists()) { name = "$base $i.$ext"; i++ }
        val target = File(dir, name)
        appContext.contentResolver.openInputStream(uri)?.use { input -> target.outputStream().use { input.copyTo(it) } }
            ?: return@runCatching null
        val ok = runCatching { Typeface.createFromFile(target); true }.getOrDefault(false)
        if (!ok) { target.delete(); return@runCatching null }
        refresh()
        name
    }.getOrNull()

    @Synchronized
    fun typeface(font: String, weight: Int): Typeface {
        var base: Typeface = Typeface.DEFAULT
        if (isBuiltin(font)) {
            // точный файл нужного веса - без синтетического утолщения
            val face = builtinFace(font, weight)
            if (face != null) {
                val key = face.path
                if (!cache.containsKey(key)) {
                    cache[key] = runCatching { Typeface.createFromAsset(appContext.assets, face.path) }.getOrNull()
                }
                cache[key]?.let { return it }
            }
        } else if (font.isNotEmpty()) {
            if (!cache.containsKey(font)) {
                cache[font] = file(font)?.let { f -> runCatching { Typeface.createFromFile(f) }.getOrNull() }
            }
            cache[font]?.let { base = it }
        }
        return finalCache.getOrPut("$font|$weight") {
            if (Build.VERSION.SDK_INT >= 28) Typeface.create(base, weight, false)
            else Typeface.create(base, if (weight >= 600) Typeface.BOLD else Typeface.NORMAL)
        }
    }
}
