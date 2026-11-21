package com.qwenz.qwel.render

import android.content.Context
import android.net.Uri
import java.io.BufferedInputStream
import java.io.File
import java.io.InputStream
import java.util.zip.GZIPInputStream
import java.util.zip.ZipInputStream

/**
 * Импорт набора иконок Material Symbols из архива, без пересборки приложения.
 * Понимает .zip и .tgz / .tar.gz (формат определяется по содержимому) и две раскладки:
 *  - npm-пакет @material-symbols/svg-400: outlined/home.svg, outlined/home-fill.svg, rounded/..., sharp/...
 *  - репозиторий google/material-design-icons: symbols/web/home/materialsymbolsoutlined/home_24px.svg и home_fill1_24px.svg
 * Берутся только обычные начертания; файлы кладутся в filesDir/icons/<стиль>/.
 */
object IconImport {
    private const val MAX_FILES = 40_000
    private const val MAX_FILE_BYTES = 300_000
    private val styles = setOf("outlined", "rounded", "sharp")
    private val safeName = Regex("^[a-z0-9_]+(-fill)?$")

    /** Куда сохранить файл архива: пара (стиль, имя без расширения) или null, если это не иконка. */
    internal fun target(entryPath: String): Pair<String, String>? {
        val parts = entryPath.replace('\\', '/').split('/')
        val file = parts.lastOrNull() ?: return null
        if (!file.endsWith(".svg", ignoreCase = true)) return null
        val base = file.dropLast(4)
        val dir = parts.getOrNull(parts.size - 2)?.lowercase() ?: return null
        val (style, name) = when {
            dir in styles -> dir to base
            dir.startsWith("materialsymbols") && dir.removePrefix("materialsymbols") in styles -> {
                if (base.contains("_wght") || base.contains("_grad") || base.contains("_opsz")) return null
                val m = Regex("^(.+?)(_fill1)?_24px$").matchEntire(base) ?: return null
                dir.removePrefix("materialsymbols") to (m.groupValues[1] + if (m.groupValues[2].isNotEmpty()) "-fill" else "")
            }
            else -> return null
        }
        return if (safeName.matches(name)) style to name else null
    }

    /** Возвращает число сохранённых иконок. Вызывать не на главном потоке. */
    fun import(context: Context, uri: Uri): Int {
        val root = File(context.filesDir, "icons")
        var saved = 0
        val raw = context.contentResolver.openInputStream(uri) ?: return 0
        BufferedInputStream(raw, 64 * 1024).use { input ->
            input.mark(4)
            val b0 = input.read(); val b1 = input.read()
            input.reset()
            fun write(path: String, data: ByteArray) {
                val (style, name) = target(path) ?: return
                if (saved >= MAX_FILES) return
                val dir = File(root, style).apply { mkdirs() }
                File(dir, "$name.svg").writeBytes(data)
                saved++
            }
            when {
                b0 == 0x50 && b1 == 0x4B -> readZip(input, ::write)
                b0 == 0x1F && b1 == 0x8B -> readTar(GZIPInputStream(input, 64 * 1024), ::write)
                else -> return 0
            }
        }
        IconLibrary.reload()
        return saved
    }

    private fun readZip(input: InputStream, sink: (String, ByteArray) -> Unit) {
        ZipInputStream(input).use { zip ->
            while (true) {
                val e = zip.nextEntry ?: break
                if (e.isDirectory || target(e.name) == null) continue
                val data = zip.readNBytes(MAX_FILE_BYTES + 1)
                if (data.size <= MAX_FILE_BYTES) sink(e.name, data)
            }
        }
    }

    /** Минимальное чтение tar: заголовки по 512 байт, имя в начале (плюс префикс ustar), размер в восьмеричной записи. */
    private fun readTar(input: InputStream, sink: (String, ByteArray) -> Unit) {
        val header = ByteArray(512)
        var longName: String? = null
        while (true) {
            if (!readFully(input, header, 512)) break
            if (header.all { it == 0.toByte() }) break
            var name = cString(header, 0, 100)
            val prefix = cString(header, 345, 155)
            if (prefix.isNotEmpty()) name = "$prefix/$name"
            val size = cString(header, 124, 12).trim().ifEmpty { "0" }.toLongOrNull(8) ?: 0L
            val type = header[156].toInt().toChar()
            val padded = (size + 511) / 512 * 512
            when {
                type == 'L' && size in 1..4096 -> {
                    val data = ByteArray(size.toInt()); readFully(input, data, size.toInt())
                    skip(input, padded - size); longName = cString(data, 0, data.size)
                }
                (type == '0' || type == '\u0000') && size in 1..MAX_FILE_BYTES -> {
                    val data = ByteArray(size.toInt()); if (!readFully(input, data, size.toInt())) break
                    skip(input, padded - size)
                    sink(longName ?: name, data); longName = null
                }
                else -> { skip(input, padded); longName = null }
            }
        }
    }

    private fun cString(b: ByteArray, off: Int, len: Int): String {
        var end = off
        while (end < off + len && b[end] != 0.toByte()) end++
        return String(b, off, end - off, Charsets.UTF_8)
    }

    private fun readFully(input: InputStream, buf: ByteArray, len: Int): Boolean {
        var n = 0
        while (n < len) { val r = input.read(buf, n, len - n); if (r < 0) return false; n += r }
        return true
    }

    private fun skip(input: InputStream, count: Long) {
        var left = count
        val sink = ByteArray(8192)
        while (left > 0) { val r = input.read(sink, 0, minOf(left, sink.size.toLong()).toInt()); if (r < 0) return; left -= r }
    }
}
