package com.qwenz.qwel.i18n

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import org.json.JSONObject
import java.io.File
import java.util.Locale

/** Доступный язык: [code] - имя файла без .json, [name] - поле "_name" из него. */
class Lang(val code: String, val name: String)

/**
 * Локализация без пересборки. Все тексты лежат в JSON-файлах:
 *
 *   app/src/main/assets/lang/<код>.json        - встроенные языки (en - базовый, из него берутся недостающие строки)
 *   <files>/lang/<код>.json                    - языки, добавленные из приложения (Настройки -> Язык -> '+ Язык')
 *   Android/data/<пакет>/files/lang/<код>.json - то же, но можно просто положить файл руками
 *
 * ЧТОБЫ ДОБАВИТЬ ЯЗЫК: скопируйте assets/lang/en.json в assets/lang/de.json, поменяйте "_name" и переведите значения.
 * Приложение найдёт файл само - он появится в списке языков. Ключи переводить не нужно, {0} {1} - места для подстановок.
 * Если ключа нет в выбранном языке, берётся английский, а если нет и там - сам ключ.
 */
object I18n {
    const val AUTO = "auto"

    private var base: Map<String, String> = emptyMap()
    private var cur: Map<String, String> = emptyMap()

    /** Читается в t(): смена языка перерисовывает все экраны, которые показывают текст. */
    private var version by mutableIntStateOf(0)

    /** Выбранный пользователем код: [AUTO] или код языка. */
    var selected: String = AUTO
        private set

    fun init(ctx: Context) {
        selected = prefs(ctx).getString("lang", AUTO) ?: AUTO
        apply(ctx)
    }

    fun setLanguage(ctx: Context, code: String) {
        selected = code
        prefs(ctx).edit().putString("lang", code).apply()
        apply(ctx)
    }

    /** Перечитывает файлы (после добавления нового языка). */
    fun reload(ctx: Context) = apply(ctx)

    private fun apply(ctx: Context) {
        base = load(ctx, "en")
        val code = effectiveCode(ctx)
        cur = if (code == "en") base else load(ctx, code)
        version++
    }

    /** Код реально используемого языка (для [AUTO] - язык системы, если такой файл есть, иначе en). */
    fun effectiveCode(ctx: Context): String {
        if (selected != AUTO) return selected
        val sys = Locale.getDefault().language
        return if (codes(ctx).contains(sys)) sys else "en"
    }

    fun t(key: String): String {
        version // подписка на смену языка
        return cur[key] ?: base[key] ?: key
    }

    fun t(key: String, vararg args: Any?): String = format(t(key), args)

    /** Как [t], но если ключа нет ни в одном языке - [default] (для фигур, добавленных в код). */
    fun tOr(key: String, default: String): String {
        version
        return cur[key] ?: base[key] ?: default
    }

    private fun format(s: String, args: Array<out Any?>): String {
        var r = s
        for (i in args.indices) r = r.replace("{$i}", args[i].toString())
        return r
    }

    /** Все найденные языки: встроенные, добавленные из приложения и лежащие в Android/data. */
    fun languages(ctx: Context): List<Lang> =
        codes(ctx).map { Lang(it, load(ctx, it)["_name"] ?: it) }

    /**
     * Копирует выбранный .json в папку языков приложения. Возвращает код языка или null, если файл не подошёл.
     * Вызывать не на главном потоке.
     */
    fun importLanguage(ctx: Context, uri: Uri): String? = runCatching {
        var display = "lang"
        ctx.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) display = it.getString(0) ?: display
        }
        val text = ctx.contentResolver.openInputStream(uri)?.use { it.bufferedReader().readText() } ?: return@runCatching null
        val json = JSONObject(text)
        if (json.length() == 0) return@runCatching null
        val code = (json.optString("_code").ifBlank { display.substringBeforeLast('.') })
            .replace(Regex("[^A-Za-z0-9_-]"), "").lowercase().ifBlank { return@runCatching null }
        File(ctx.filesDir, "lang").apply { mkdirs() }.resolve("$code.json").writeText(text)
        reload(ctx)
        code
    }.getOrNull()

    // ---------------------------------------------------------------- загрузка

    private fun prefs(ctx: Context) = ctx.applicationContext.getSharedPreferences("qwel_lang", Context.MODE_PRIVATE)

    private fun internalDir(ctx: Context) = File(ctx.filesDir, "lang")
    private fun externalDir(ctx: Context): File? = runCatching { ctx.getExternalFilesDir("lang") }.getOrNull()

    private fun codes(ctx: Context): List<String> {
        val set = LinkedHashSet<String>()
        runCatching { ctx.assets.list("lang")?.forEach { if (it.endsWith(".json")) set.add(it.removeSuffix(".json")) } }
        runCatching { internalDir(ctx).listFiles()?.forEach { if (it.name.endsWith(".json")) set.add(it.name.removeSuffix(".json")) } }
        runCatching { externalDir(ctx)?.listFiles()?.forEach { if (it.name.endsWith(".json")) set.add(it.name.removeSuffix(".json")) } }
        return set.sortedWith(compareBy({ it != "en" }, { it }))
    }

    /** Порядок слоёв: assets -> внутренняя папка -> Android/data; поздние переопределяют ранние. */
    private fun load(ctx: Context, code: String): Map<String, String> {
        val map = HashMap<String, String>()
        runCatching { ctx.assets.open("lang/$code.json").use { map.putAll(parse(it.bufferedReader().readText())) } }
        runCatching { File(internalDir(ctx), "$code.json").takeIf { it.exists() }?.let { map.putAll(parse(it.readText())) } }
        runCatching { externalDir(ctx)?.let { File(it, "$code.json") }?.takeIf { it.exists() }?.let { map.putAll(parse(it.readText())) } }
        return map
    }

    private fun parse(text: String): Map<String, String> {
        val out = HashMap<String, String>()
        runCatching {
            val o = JSONObject(text)
            val keys = o.keys()
            while (keys.hasNext()) { val k = keys.next(); out[k] = o.optString(k) }
        }
        return out
    }
}

/** Короткий вызов: tr("ключ") или tr("ключ", аргумент0, аргумент1) для {0}, {1}. */
fun tr(key: String): String = I18n.t(key)
fun tr(key: String, vararg args: Any?): String = I18n.t(key, *args)
fun trOr(key: String, default: String): String = I18n.tOr(key, default)
