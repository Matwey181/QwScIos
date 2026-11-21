package com.qwenz.qwel.i18n
import org.json.JSONObject
import java.io.File
private val strings by lazy { JSONObject(File("app/src/main/assets/lang/ru.json").readText()) }
fun tr(key: String, vararg args: Any): String { var s = strings.optString(key,key); args.forEachIndexed { i,a -> s=s.replace("{$i}",a.toString()) }; return s }
fun trOr(key: String, fallback: String): String = strings.optString(key,fallback)
