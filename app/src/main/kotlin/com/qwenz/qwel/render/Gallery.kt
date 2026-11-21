package com.qwenz.qwel.render

import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File

/** Сохранение экспорта в общую папку Pictures/Qwel (видна в галерее). */
object Gallery {
    const val FOLDER = "Vexel"
    const val SHOWN = "Pictures/Vexel"

    fun safeName(name: String, ext: String): String {
        val base = name.replace(Regex("[\\\\/:*?\"<>|]"), "_").trim().ifEmpty { "Vexel" }
        return "$base.$ext"
    }

    /** Возвращает Uri сохранённого файла или null. Не вызывать на главном потоке. */
    fun save(context: Context, displayName: String, mime: String, bytes: ByteArray): Uri? = runCatching {
        if (Build.VERSION.SDK_INT >= 29) {
            val resolver = context.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                put(MediaStore.MediaColumns.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/$FOLDER")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return@runCatching null
            val ok = resolver.openOutputStream(uri)?.use { it.write(bytes); true } ?: false
            if (!ok) { resolver.delete(uri, null, null); return@runCatching null }
            val done = ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }
            resolver.update(uri, done, null, null)
            uri
        } else {
            @Suppress("DEPRECATION")
            val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), FOLDER)
            dir.mkdirs()
            var f = File(dir, displayName)
            var i = 1
            val stem = displayName.substringBeforeLast('.'); val ext = displayName.substringAfterLast('.', "")
            while (f.exists()) { f = File(dir, "$stem ($i).$ext"); i++ }
            f.writeBytes(bytes)
            MediaScannerConnection.scanFile(context, arrayOf(f.path), arrayOf(mime), null)
            Uri.fromFile(f)
        }
    }.getOrNull()
}
