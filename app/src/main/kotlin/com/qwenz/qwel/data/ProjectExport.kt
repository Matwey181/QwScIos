package com.qwenz.qwel.data

/**
 * Выгрузка проекта как готовых файлов для Android-приложения на Compose: по файлу на каждый экран, общий VexelApp
 * с переходами между экранами, картинки для res/drawable и инструкция. Всё кладётся в ту же структуру папок, что у модуля
 * (src/main/java/..., src/main/res/...), поэтому папку можно слить с модулем приложения.
 */
/** Начертания шрифта: (вес, расширение файла ttf/otf). Пусто - файла нет или формат не подходит для res/font. */
typealias FontFaces = (String) -> List<Pair<Int, String>>

object ProjectExport {
    class Result(
        /** путь внутри архива -> текст */
        val files: Map<String, String>,
        /** имя файла картинки в хранилище -> путь внутри архива (содержимое добавляет вызывающий) */
        val images: Map<String, String>,
        /** путь внутри архива -> (шрифт слоя, вес); байты добавляет вызывающий */
        val fonts: Map<String, Pair<String, Int>> = emptyMap(),
    )

    private val pkgRe = Regex("[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)*")
    const val DEFAULT_PACKAGE = "com.example.myapp.vexel"

    fun cleanPackage(raw: String): String = raw.trim().lowercase().takeIf { pkgRe.matches(it) } ?: DEFAULT_PACKAGE

    /** Уникальные имена функций экранов: из названий, а если название не латиницей или повторяется, то ScreenN. */
    private fun screenNames(names: List<String>): List<String> {
        val used = HashSet<String>().apply { add("VexelApp") }
        return names.mapIndexed { i, n ->
            var f = ComposeCode.functionName(n)
            if (f == "Screen" || f in used) f = "Screen${i + 1}"
            while (f in used) f += "X"
            used += f
            f
        }
    }

    fun build(p: Project, pkgRaw: String, rPkgRaw: String = pkgRaw, faces: FontFaces = { emptyList() }): Result {
        val core = core(p, cleanPackage(pkgRaw), cleanPackage(rPkgRaw), "src/main/java/", "src/main/res/drawable/", "src/main/res/font/", faces)
        val files = core.files
        files["dependencies.txt"] = dependencies(core.code)
        files["README.md"] = readme(p, cleanPackage(pkgRaw), core.names, core.images.isNotEmpty())
        return Result(files, core.images, core.fonts)
    }

    private class Core(val files: LinkedHashMap<String, String>, val images: LinkedHashMap<String, String>, val fonts: LinkedHashMap<String, Pair<String, Int>>, val names: List<String>, val code: String)

    private fun core(p: Project, pkg: String, rPkg: String, srcRoot: String, resRoot: String, fontRoot: String, faces: FontFaces): Core {
        val multi = p.pages.size > 1
        val pageNodes: List<Pair<String, List<Node>>> =
            if (multi) p.pages.map { it.name to it.nodes } else listOf(p.name to p.nodes)
        val ids = if (multi) p.pages.map { it.id } else listOf("")
        val fns = screenNames(pageNodes.map { it.first })

        val dir = srcRoot + pkg.replace('.', '/') + "/"
        val files = LinkedHashMap<String, String>()
        val images = LinkedHashMap<String, String>()
        val allCode = StringBuilder()

        // шрифты: res/font/vx_font<N>_w<вес>.ttf и объект VexelFonts с FontFamily
        val fontFiles = LinkedHashMap<String, Pair<String, Int>>()
        val fontNames = LinkedHashMap<String, String>()
        val fam = StringBuilder()
        for (font in pageNodes.flatMap { ComposeCode.fontsUsed(it.second) }.distinct()) {
            val fs = faces(font).sortedBy { it.first }
            if (fs.isEmpty()) continue
            val id = fontNames.size + 1
            val v = "Font$id"
            fontNames[font] = v
            fam.append("    /** ").append(font.replace("*/", "").replace("\n", " ")).append(" */\n    val ").append(v).append(" = FontFamily(\n")
            for ((w, ext) in fs) {
                val res = "vx_font${id}_w$w"
                fontFiles["$fontRoot$res.$ext"] = font to w
                fam.append("        Font(R.font.").append(res).append(", FontWeight.W").append(w).append("),\n")
            }
            fam.append("    )\n")
        }

        for ((i, pn) in pageNodes.withIndex()) {
            val code = ComposeCode.generate(p, pn.second, pn.first, null, ComposeCode.ExportOpts(ids, fns[i], pkg, rPkg, fontNames))
            files[dir + fns[i] + ".kt"] = code
            allCode.append(code)
            for ((asset, res) in ComposeCode.imageResources(pn.second)) {
                images[asset] = "$resRoot$res.${asset.substringAfterLast('.', "png").lowercase()}"
            }
        }

        files[dir + "VexelApp.kt"] = app(p, pkg, fns)
        if (fontNames.isNotEmpty()) {
            files[dir + "VexelFonts.kt"] = "package $pkg\n\nimport androidx.compose.ui.text.font.Font\nimport androidx.compose.ui.text.font.FontFamily\nimport androidx.compose.ui.text.font.FontWeight\nimport $rPkg.R\n\n/** Fonts used by the screens (files are in res/font). */\nobject VexelFonts {\n$fam}\n"
        }
        return Core(files, images, fontFiles, fns, allCode.toString())
    }

    private fun xml(s: String) = s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "\\'")

    private fun hex8(argb: Int) = "0x" + String.format(java.util.Locale.US, "%08X", argb)

    /**
     * Готовый проект для CodeAssist: app/module.toml, манифест, MainActivity, тема из палитры проекта, ресурсы и экраны.
     * Зависимости и версии те же, что у самого Vexel (material3 1.4.0), поэтому в коде нет Expressive-API:
     * фигуры из библиотеки Material перед выгрузкой превращаются в контуры (это делает вызывающий).
     */
    fun buildCodeAssist(p: Project, appIdRaw: String, faces: FontFaces = { emptyList() }): Result {
        val pkg = cleanPackage(appIdRaw)
        val core = core(p, pkg, pkg, "app/src/main/kotlin/", "app/src/main/res/drawable/", "app/src/main/res/font/", faces)
        val f = core.files
        val code = core.code
        val name = p.name.ifBlank { "Vexel" }

        f["app/module.toml"] = moduleToml(pkg, code)
        f["app/proguard-rules.pro"] = "# Rules for release builds. Nothing special is needed for the generated screens.\n"
        f["app/src/main/AndroidManifest.xml"] = """<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="$pkg">
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/Theme.App">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:configChanges="orientation|screenSize|screenLayout|smallestScreenSize|keyboardHidden|uiMode|density|fontScale">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
"""
        val dir = "app/src/main/kotlin/" + pkg.replace('.', '/') + "/"
        f[dir + "MainActivity.kt"] = """package $pkg

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { VexelTheme { VexelApp() } }
    }
}
"""
        f[dir + "VexelTheme.kt"] = theme(p, pkg)
        f["app/src/main/res/values/strings.xml"] = "<resources>\n    <string name=\"app_name\">${xml(name)}</string>\n</resources>\n"
        f["app/src/main/res/values/themes.xml"] = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.App" parent="android:Theme.Material.Light.NoActionBar">
        <item name="android:windowBackground">@color/window_background</item>
    </style>
</resources>
"""
        f["app/src/main/res/values/colors.xml"] = "<resources>\n    <color name=\"window_background\">#${String.format(java.util.Locale.US, "%08X", p.background)}</color>\n    <color name=\"ic_launcher_background\">#FF${String.format(java.util.Locale.US, "%06X", p.tone.color(0, 0xFF6750A4.toInt()) and 0xFFFFFF)}</color>\n</resources>\n"
        f["app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml"] = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
"""
        f["app/src/main/res/drawable/ic_launcher_foreground.xml"] = """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#FFFFFFFF" android:pathData="M34,34h40a6,6 0 0 1 6,6v28a6,6 0 0 1 -6,6h-40a6,6 0 0 1 -6,-6v-28a6,6 0 0 1 6,-6z"/>
</vector>
"""
        f[".gitignore"] = "build/\n.gradle/\n*.iml\nlocal.properties\n"
        f["README.md"] = readmeCodeAssist(p, pkg, core.names, core.images.isNotEmpty())
        return Result(f, core.images, core.fonts)
    }

    private fun moduleToml(pkg: String, code: String): String {
        val deps = arrayListOf(
            "kotlin-stdlib", "androidx.activity:activity-compose:1.13.0", "androidx.compose.ui:ui:1.11.2",
            "androidx.compose.foundation:foundation:1.11.2", "androidx.compose.material3:material3:1.4.0",
            "androidx.compose.ui:ui-tooling-preview:1.11.2",
        )
        if (code.contains("androidx.compose.material.icons")) deps += "androidx.compose.material:material-icons-extended:1.7.8"
        if (code.contains("androidx.graphics.shapes")) deps += "androidx.graphics:graphics-shapes:1.1.0"
        val list = deps.joinToString(", ") { "\"$it\"" }
        return """version = 2

[module]
type = "android-app"
name = "app"
languageLevel = "JAVA_8"
output = "build/classes"

[sourceSets.main]
scope = "IMPLEMENTATION"
aidl = ["src/main/aidl"]
assets = ["src/main/assets"]
java = ["src/main/java", "src/main/kotlin"]
jniLibs = ["src/main/jniLibs"]
res = ["src/main/res"]
resources = ["src/main/resources"]

[sourceSets.debug]
scope = "IMPLEMENTATION"
aidl = ["src/debug/aidl"]
assets = ["src/debug/assets"]
java = ["src/debug/java", "src/debug/kotlin"]
jniLibs = ["src/debug/jniLibs"]
res = ["src/debug/res"]
resources = ["src/debug/resources"]

[sourceSets.release]
scope = "IMPLEMENTATION"
aidl = ["src/release/aidl"]
assets = ["src/release/assets"]
java = ["src/release/java", "src/release/kotlin"]
jniLibs = ["src/release/jniLibs"]
res = ["src/release/res"]
resources = ["src/release/resources"]

[dependencies]
implementation = [$list]

[android]
namespace = "$pkg"
compileSdk = 36
minSdk = 26
targetSdk = 36
manifest = "src/main/AndroidManifest.xml"
versionCode = 1
versionName = "1.0"
isApplication = true
manifestPlaceholders = []
buildConfigFields = []
buildTypes = [{ name = "debug", debuggable = true, minifyEnabled = false, shrinkResources = false }, { name = "release", debuggable = false, minifyEnabled = false, shrinkResources = false, proguardFiles = ["proguard-android-optimize.txt", "proguard-rules.pro"] }]
compose = true
"""
    }

    /** Тема приложения: цвета токенов берутся из палитры проекта, поэтому экраны выглядят как в Vexel. */
    private fun theme(p: Project, pkg: String): String {
        val b = StringBuilder()
        b.append("package ").append(pkg).append("\n\n")
        b.append("import androidx.compose.material3.MaterialTheme\n")
        b.append("import androidx.compose.material3.").append(if (p.tone.dark) "darkColorScheme" else "lightColorScheme").append("\n")
        b.append("import androidx.compose.runtime.Composable\n")
        b.append("import androidx.compose.ui.graphics.Color\n\n")
        b.append("/** Colors of the Vexel project palette (${if (p.tone.dark) "dark" else "light"}). Change them here to restyle every screen. */\n")
        b.append("private val VexelColors = ").append(if (p.tone.dark) "darkColorScheme" else "lightColorScheme").append("(\n")
        for ((i, n) in ComposeCode.tokens.withIndex()) {
            val c = p.tone.color(i, 0)
            if ((c ushr 24) == 0) continue
            b.append("    ").append(n).append(" = Color(").append(hex8(c)).append("),\n")
            if (n == "surface") b.append("    background = Color(").append(hex8(c)).append("),\n")
        }
        b.append(")\n\n")
        b.append("@Composable\nfun VexelTheme(content: @Composable () -> Unit) {\n    MaterialTheme(colorScheme = VexelColors, content = content)\n}\n")
        return b.toString()
    }

    private fun readmeCodeAssist(p: Project, pkg: String, fns: List<String>, hasImages: Boolean): String {
        val screens = fns.mapIndexed { i, f -> "- `$f` (screen ${i + 1})" }.joinToString("\n")
        return """# ${p.name}: CodeAssist project from Vexel

A ready Android app on Jetpack Compose. Unpack the archive, open the folder in CodeAssist (open project) and run.

## Structure
- `app/module.toml` : module config; package (namespace) is `$pkg`.
- `app/src/main/kotlin/${pkg.replace('.', '/')}/` : `MainActivity`, `VexelTheme` (colors of your project), `VexelApp` (switches screens) and one file per screen.
${if (hasImages) "- `app/src/main/res/drawable/` : pictures used by the screens.\n" else ""}- `app/src/main/res/` : launcher icon, theme and the app name (`values/strings.xml`).

Screens:
$screens

## Notes
- Dependencies are the same versions as in Vexel itself (material3 1.4.0), written in `app/module.toml`. If CodeAssist cannot resolve one, change the version there.
- Shapes from the Material library are exported as plain outlines, because Expressive APIs are not public in material3 1.4.0.
- Components from the Components tab are real Material 3 widgets with state; other layers are placed by coordinates like on the canvas. Actions (go to screen, back, link, show or hide) are wired in.
- To use these screens in another app instead, take the screen files and `VexelApp.kt` and call `VexelApp()` inside your theme.
- The code was generated, not compiled in your project. If something does not resolve, check versions in `app/module.toml`.
"""
    }

    private fun app(p: Project, pkg: String, fns: List<String>): String {
        val w = fmt(p.width); val h = fmt(p.height)
        val cases = fns.mapIndexed { i, f -> "                    $i -> $f(onGoTo = goTo, onBack = back)" }.joinToString("\n")
        return """// Generated by Vexel.
package $pkg

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp

/**
 * All screens of the project with the transitions you set in Vexel (go to screen, back).
 * Call it inside your MaterialTheme: setContent { MyTheme { VexelApp() } }.
 * The design is ${w} x ${h} dp; it is scaled to fit the window and centered.
 */
@Composable
fun VexelApp(modifier: Modifier = Modifier) {
    var current by rememberSaveable { mutableIntStateOf(0) }
    val history = remember { mutableStateListOf<Int>() }
    val goTo: (Int) -> Unit = { history.add(current); current = it }
    val back: () -> Unit = { if (history.isNotEmpty()) current = history.removeAt(history.lastIndex) }
    BackHandler(enabled = history.isNotEmpty(), onBack = back)

    AnimatedContent(
        targetState = current,
        modifier = modifier.fillMaxSize().background(MaterialTheme.colorScheme.background),
        transitionSpec = { fadeIn() togetherWith fadeOut() },
        label = "vexel-screen",
    ) { index ->
        BoxWithConstraints(Modifier.fillMaxSize()) {
            val scale = minOf(maxWidth / ${w}.dp, maxHeight / ${h}.dp)
            Box(
                Modifier
                    .align(Alignment.Center)
                    .requiredSize(${w}.dp, ${h}.dp)
                    .graphicsLayer { scaleX = scale; scaleY = scale },
            ) {
                when (index) {
$cases
                    else -> {}
                }
            }
        }
    }
}
"""
    }

    private fun fmt(v: Float): String = if (v == v.toInt().toFloat()) v.toInt().toString() else "%.1f".format(java.util.Locale.US, v)

    private fun dependencies(code: String): String {
        val b = StringBuilder()
        b.append("// Add to the module build.gradle.kts (dependencies { ... }). Versions come from your Compose BOM.\n")
        b.append("implementation(platform(\"androidx.compose:compose-bom:<your BOM version>\"))\n")
        b.append("implementation(\"androidx.compose.ui:ui\")\n")
        b.append("implementation(\"androidx.compose.foundation:foundation\")\n")
        b.append("implementation(\"androidx.compose.material3:material3\")\n")
        b.append("implementation(\"androidx.activity:activity-compose\")\n")
        if (code.contains("androidx.compose.material.icons")) {
            b.append("implementation(\"androidx.compose.material:material-icons-extended\")\n")
        }
        if (code.contains("androidx.graphics.shapes")) {
            b.append("implementation(\"androidx.graphics:graphics-shapes:<version>\")\n")
        }
        if (code.contains("ExperimentalMaterial3ExpressiveApi") || code.contains("MaterialShapes")) {
            b.append("// Expressive APIs (MaterialShapes and others) need a material3 1.5.0 alpha or newer; check your version in the release notes.\n")
        }
        return b.toString()
    }

    private fun readme(p: Project, pkg: String, fns: List<String>, hasImages: Boolean): String {
        val screens = fns.mapIndexed { i, f -> "- `$f` (screen ${i + 1})" }.joinToString("\n")
        return """# ${p.name}: Compose export from Vexel

## What is inside
- `src/main/java/${pkg.replace('.', '/')}/` : one file per screen plus `VexelApp.kt` (switches between screens).
${if (hasImages) "- `src/main/res/drawable/` : pictures used by the screens.\n" else ""}- `dependencies.txt` : what to add to build.gradle.kts.

Screens:
$screens

## How to add it to your app
1. Copy the `src` folder into your app module (it merges with the existing `src/main`).
2. Add the lines from `dependencies.txt` to your module dependencies.
3. If the package of your app differs from `$pkg`, either keep this package (it does not have to match the app id) or change the `package` lines.
4. Show it: `setContent { YourTheme { VexelApp() } }` or call a single screen, for example `${fns.first()}()`.
${if (hasImages) "5. Pictures refer to `R.drawable`; the files in the first lines of each screen file say which `import <your app id>.R` it needs. The generated import uses `$pkg.R`: change it to your app R package if they differ.\n" else ""}
## Notes
- Colors go through `MaterialTheme.colorScheme`, so the screens follow your theme.
- Components from the Components tab are real Material 3 widgets with state; other layers are placed by coordinates like on the canvas.
- Actions (go to screen, back, link, show or hide) are wired in. Backdrop blur is not part of Compose (use the Haze library).
- The code was generated, not compiled in your project. If something does not resolve, check the versions in `dependencies.txt`.
"""
    }
}
