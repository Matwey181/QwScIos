package com.qwenz.qwel.data

import java.util.Locale
import kotlin.math.abs
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Превращает слои в код Jetpack Compose.
 *
 * Компоненты из панели 'Компоненты' (их группы помечены id заготовки) выходят настоящими виджетами Material 3:
 * Button, Switch, Slider, NavigationBar, TopAppBar и т.д., с состоянием (remember), иконками-векторами и подписями.
 * Если компонент правили (другие цвета, слои добавлены или удалены), он выходит слоями, чтобы не потерять дизайн.
 * Компоненты без прямого аналога в Material 3 выходят отдельной функцией со слоями по координатам.
 * Остальные слои ставятся как на холсте: offset + size внутри одного Box. Цвета с токенами - MaterialTheme.colorScheme.*.
 */
object ComposeCode {
    /** Имена цветов темы по номеру токена. */
    val tokens: List<String> get() = tokenNames

    private val tokenNames = listOf(
        "primary", "onPrimary", "primaryContainer", "onPrimaryContainer",
        "secondary", "secondaryContainer", "onSecondaryContainer",
        "tertiary", "tertiaryContainer", "onTertiaryContainer",
        "error", "errorContainer",
        "surface", "surfaceContainerLow", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest",
        "onSurface", "onSurfaceVariant", "outline", "outlineVariant", "inverseSurface",
    )

    /** Id фигуры в нашей библиотеке -> имя в MaterialShapes. */
    private val materialShapes = mapOf(
        "circle" to "Circle", "square" to "Square", "slanted" to "Slanted", "arch" to "Arch", "fan" to "Fan",
        "arrow" to "Arrow", "semicircle" to "SemiCircle", "oval" to "Oval", "pill" to "Pill", "triangle" to "Triangle",
        "diamond" to "Diamond", "clamshell" to "ClamShell", "pentagon" to "Pentagon", "gem" to "Gem",
        "cookie-4" to "Cookie4Sided", "cookie-6" to "Cookie6Sided", "cookie-7" to "Cookie7Sided",
        "cookie-9" to "Cookie9Sided", "cookie-12" to "Cookie12Sided",
        "sunny" to "Sunny", "very-sunny" to "VerySunny", "burst" to "Burst", "soft-burst" to "SoftBurst",
        "boom" to "Boom", "soft-boom" to "SoftBoom",
        "clover-4" to "Clover4Leaf", "clover-8" to "Clover8Leaf", "flower" to "Flower", "puffy" to "Puffy",
        "puffy-diamond" to "PuffyDiamond",
        "ghostish" to "Ghostish", "bun" to "Bun", "heart" to "Heart", "pixel-circle" to "PixelCircle",
        "pixel-triangle" to "PixelTriangle",
    )

    private fun num(v: Float): String {
        val r = (v * 100f).roundToInt() / 100f
        return if (r == r.toInt().toFloat()) r.toInt().toString() else String.format(Locale.US, "%.2f", r).trimEnd('0').trimEnd('.')
    }

    private fun dp(v: Float) = "${num(v)}.dp"

    private fun hex(argb: Int) = "Color(0x" + String.format(Locale.US, "%08X", argb) + ")"

    private fun colorExpr(argb: Int, token: Int): String {
        if (token in tokenNames.indices) return "MaterialTheme.colorScheme.${tokenNames[token]}"
        return when (argb) {
            0xFF000000.toInt() -> "Color.Black"
            0xFFFFFFFF.toInt() -> "Color.White"
            0 -> "Color.Transparent"
            else -> hex(argb)
        }
    }

    private fun esc(s: String) = s.replace("\\", "\\\\").replace("\"", "\\\"").replace("$", "\\$").replace("\n", "\\n")

    /** Имя функции из названия проекта: латиница и цифры, с заглавной; иначе "Screen". */
    fun functionName(title: String): String {
        val words = title.split(Regex("[^A-Za-z0-9]+")).filter { it.isNotEmpty() }
        val name = words.joinToString("") { it.replaceFirstChar { c -> c.uppercase() } }
        return if (name.isEmpty() || name[0].isDigit()) "Screen$name" else name
    }

    private fun pascal(s: String): String {
        val name = s.split(Regex("[^A-Za-z0-9]+")).filter { it.isNotEmpty() }.joinToString("") { it.replaceFirstChar { c -> c.uppercase() } }
        return if (name.isEmpty() || name[0].isDigit()) "X$name" else name
    }

    /** Построчный вывод кода с отступом. */
    private class Src(var depth: Int) {
        val sb = StringBuilder()
        fun a(s: String) { sb.append("    ".repeat(depth)).append(s).append('\n') }
        fun raw(s: String) { sb.append(s) }
        fun inc() { depth++ }
        fun dec() { depth-- }

        /** head(\n args \n) { body }  (или без тела). */
        fun call(head: String, args: List<String>, body: (Src.() -> Unit)? = null) {
            a("$head(")
            inc()
            for (x in args) a("$x,")
            dec()
            if (body == null) a(")") else {
                a(") {")
                inc(); body(); dec()
                a("}")
            }
        }

        /** Лямбда-аргумент: name = { ... }, */
        fun slot(name: String, body: Src.() -> Unit) {
            a("$name = {")
            inc(); body(); dec()
            a("},")
        }
    }

    /** Общие данные одного прохода: векторы иконок, фигуры по контуру, вспомогательный код, счётчики имён. */
    private class Ctx {
        val states = ArrayList<String>()
        val vectors = LinkedHashMap<String, String>()
        val vectorSrc = ArrayList<String>()
        val pathShapes = LinkedHashMap<String, String>()
        val pathSrc = ArrayList<String>()
        val fallbacks = ArrayList<String>()
        var needPathHelper = false
        var needAngle = false
        var usesImage = false
        var opts: ExportOpts? = null
        private var uriDeclared = false
        /** Слои, которые действием 'показать или скрыть' включаются в игре: id слоя -> имя состояния. */
        val toggles = HashMap<String, String>()

        fun uri(): String {
            if (!uriDeclared) { uriDeclared = true; states += "val uriHandler = LocalUriHandler.current" }
            return "uriHandler"
        }
        private val counters = HashMap<String, Int>()

        fun next(prefix: String): String {
            val n = (counters[prefix] ?: 0) + 1
            counters[prefix] = n
            return prefix + n
        }

        fun state(prefix: String, init: String): String {
            val n = next(prefix)
            states += "var $n by remember { mutableStateOf($init) }"
            return n
        }

        /** Имя val с фигурой по контуру [n] (null - контур слишком велик для строкового литерала). */
        fun pathShape(n: Node): String? {
            val d = n.path.trim()
            if (d.isEmpty() || d.length > 60000) return null
            val key = d + "|" + n.evenOdd
            return pathShapes.getOrPut(key) {
                needPathHelper = true
                val name = "VexelPath" + (pathShapes.size + 1)
                val sb = StringBuilder("private val $name = GenericShape { s, _ ->\n")
                if (n.evenOdd) sb.append("    fillType = PathFillType.EvenOdd\n")
                sb.append("    addPath(vexelPath(\"").append(d).append("\", s.width, s.height))\n}\n")
                pathSrc += sb.toString()
                name
            }
        }

        /** Имя ImageVector для иконки-контура [n] (в единичном квадрате). */
        fun vector(n: Node): String? {
            val d = n.path.trim()
            if (d.isEmpty() || d.length > 60000) return null
            val key = d + "|" + n.evenOdd
            return vectors.getOrPut(key) {
                val name = "Vexel" + pascal(n.name.ifBlank { "Icon" }) + (vectors.size + 1)
                val sb = StringBuilder("private val $name: ImageVector = ImageVector.Builder(\n")
                sb.append("    name = \"").append(esc(n.name)).append("\",\n")
                sb.append("    defaultWidth = 24.dp, defaultHeight = 24.dp, viewportWidth = 1f, viewportHeight = 1f,\n")
                sb.append(").addPath(\n")
                sb.append("    pathData = PathParser().parsePathString(\"").append(d).append("\").toNodes(),\n")
                if (n.evenOdd) sb.append("    pathFillType = PathFillType.EvenOdd,\n")
                sb.append("    fill = SolidColor(Color.Black),\n")
                sb.append(").build()\n")
                vectorSrc += sb.toString()
                name
            }
        }
    }

    // ---------------------------------------------------------------- слои

    /** Форма слоя: выражение и пояснение. */
    private fun shapeOf(n: Node, c: Ctx): Pair<String?, String?> {
        var comment: String? = null
        val expr: String? = when (n.kind) {
            NodeKind.RECT -> if (n.corner > 0.5f) "RoundedCornerShape(${dp(min(n.corner, min(n.w, n.h) / 2f))})" else null
            NodeKind.ELLIPSE -> if (abs(n.w - n.h) < 0.5f) "CircleShape" else "GenericShape { s, _ -> addOval(Rect(Offset.Zero, s)) }"
            NodeKind.SHAPE -> {
                val ms = materialShapes[n.shapeId]
                if (ms != null) "MaterialShapes.$ms.toShape()" else {
                    val sides = n.shapeId.substringAfterLast('-').toIntOrNull()
                    when {
                        n.shapeId.startsWith("star-") && sides != null -> "RoundedPolygon.star($sides).toShape()"
                        n.shapeId == "hexagon" -> "RoundedPolygon(6).toShape()"
                        n.shapeId == "octagon" -> "RoundedPolygon(8).toShape()"
                        else -> { comment = "shape \"${n.shapeId}\" is not in MaterialShapes, replace it with your own RoundedPolygon"; "RoundedPolygon(6).toShape()" }
                    }
                }
            }
            NodeKind.PATH -> c.pathShape(n) ?: run { comment = "path is too large to inline, a rectangle is used instead"; null }
            else -> null
        }
        return expr to comment
    }

    private fun gradientBrush(n: Node, c: Ctx, comment: StringBuilder): String {
        val cols = "${colorExpr(n.fill, n.fillToken)}, ${colorExpr(n.fill2, -1)}"
        return when {
            n.gradKind == 2 -> "Brush.radialGradient(listOf($cols))"
            abs(n.gradAngle - 90f) < 1f -> "Brush.verticalGradient(listOf($cols))"
            abs(n.gradAngle) < 1f -> "Brush.horizontalGradient(listOf($cols))"
            else -> { c.needAngle = true; "angledGradient(${num(n.gradAngle)}f, $cols)" }
        }
    }

    /**
     * Код одного слоя. Координаты считаются от ([ox], [oy]); [mask] - маска, обрезающая слой.
     */
    /** Параметры выгрузки проекта целиком: id экранов по порядку (для переходов), имя функции, пакет и пакет R. */
    class ExportOpts(val pageIds: List<String>, val fnName: String, val pkg: String, val rPkg: String, val fonts: Map<String, String> = emptyMap())

    /** Шрифты, которые используют текстовые слои. */
    fun fontsUsed(nodes: List<Node>): List<String> = nodes.filter { it.kind == NodeKind.TEXT && it.font.isNotEmpty() }.map { it.font }.distinct()

    /** Что делает слой при нажатии, в виде кода (null - ничего или это нельзя выразить в таком режиме выгрузки). */
    private fun actionExpr(n: Node, c: Ctx): String? {
        val a = n.action
        return when {
            a.startsWith("goto:") -> c.opts?.pageIds?.indexOf(a.substringAfter(':'))?.takeIf { it >= 0 }?.let { "onGoTo($it)" }
            a == "back" -> if (c.opts != null) "onBack()" else null
            a.startsWith("url:") -> a.substringAfter(':').trim().takeIf { it.isNotEmpty() }?.let { u ->
                val full = if (u.startsWith("http://") || u.startsWith("https://")) u else "https://$u"
                "${c.uri()}.openUri(\"${esc(full)}\")"
            }
            a.startsWith("toggle:") -> c.toggles[a.substringAfter(':')]?.let { "$it = !$it" }
            else -> null
        }
    }

    fun backgroundExpr(p: Project): String = colorExpr(p.background, p.bgToken)

    /** Картинки слоёв: имя файла в хранилище -> имя ресурса drawable (без расширения). */
    fun imageResources(nodes: List<Node>): Map<String, String> =
        nodes.filter { it.kind == NodeKind.IMAGE && it.asset.isNotEmpty() }.associate { it.asset to imageResName(it.asset) }

    private fun layer(n: Node, c: Ctx, ind: String, ox: Float, oy: Float, mask: Node? = null): String {
        val mods = ArrayList<String>()
        mods += "offset(${dp(n.x - ox)}, ${dp(n.y - oy)})"
        if (n.kind != NodeKind.TEXT) mods += "size(${dp(n.w)}, ${dp(n.h)})"
        if (abs(n.rotation) > 0.01f) mods += "rotate(${num(n.rotation)}f)"
        if (n.opacity < 0.999f) mods += "alpha(${num(n.opacity)}f)"

        val (shapeExpr, shapeComment) = shapeOf(n, c)
        val notes = ArrayList<String>()
        shapeComment?.let { notes += it }
        var shapeArg = shapeExpr ?: "RectangleShape"
        val act = actionExpr(n, c)
        // скругление при нажатии: пружина по состоянию 'зажато'
        var pre = ""
        if (n.kind == NodeKind.RECT && n.pressCorner >= 0f) {
            val id = c.next("press")
            val half = min(n.w, n.h) / 2f
            val rest = min(n.corner, half)
            val down = min(n.pressCorner, half)
            pre = "$ind// pressed: the corner goes ${num(rest)} -> ${num(down)} while held\n" +
                "${ind}val ${id}Source = remember { MutableInteractionSource() }\n" +
                "${ind}val ${id}Down by ${id}Source.collectIsPressedAsState()\n" +
                "${ind}val ${id}Corner by animateDpAsState(\n" +
                "$ind    targetValue = if (${id}Down) ${dp(down)} else ${dp(rest)},\n" +
                "$ind    animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessMedium),\n" +
                "$ind    label = \"$id\",\n$ind)\n"
            shapeArg = "RoundedCornerShape(${id}Corner)"
            mods += "clickable(interactionSource = ${id}Source, indication = null, onClick = { ${act ?: ""} })"
        } else if (act != null) {
            mods += "clickable(onClick = { $act })"
        }
        if (n.hasShadow) {
            val col = colorExpr(n.shadowColor, -1)
            mods += "shadow(${dp(n.shadowBlur / 2f)}, $shapeArg, ambientColor = $col, spotColor = $col)"
            if (abs(n.shadowDx) > 0.5f || abs(n.shadowDy - 4f) > 0.5f) {
                notes += "shadow offset (${num(n.shadowDx)}, ${num(n.shadowDy)}): Modifier.shadow has no offset, wrap the layer in a Box with that offset if it matters"
            }
        }
        if (n.softBlur > 0.5f) {
            mods += "blur(${dp(n.softBlur * 0.58f)}, BlurredEdgeTreatment.Unbounded)"
            notes += "layer blur: Modifier.blur works on Android 12 and newer, older versions draw it sharp"
        }
        if (n.blur > 0.5f) notes += "backdrop blur ${num(n.blur)}: not built into Compose, use the Haze library (Modifier.hazeEffect)"

        if (n.kind != NodeKind.TEXT && n.kind != NodeKind.IMAGE) {
            if (n.hasGradient) mods += "background(${gradientBrush(n, c, StringBuilder())}, $shapeArg)"
            else if ((n.fill ushr 24) != 0) mods += "background(${colorExpr(n.fill, n.fillToken)}, $shapeArg)"
            if ((n.stroke ushr 24) != 0 && n.strokeWidth > 0f) mods += "border(${dp(n.strokeWidth)}, ${colorExpr(n.stroke, n.strokeToken)}, $shapeArg)"
        }

        val sb = StringBuilder()
        sb.append(ind).append("// ").append(n.name.ifBlank { n.kind.name.lowercase() }).append('\n')
        for (x in notes) sb.append(ind).append("// ").append(x).append('\n')
        val modifier = mods.joinToString("\n$ind        .", prefix = "Modifier\n$ind        .")

        fun body(): String {
            val b = StringBuilder(pre)
            when (n.kind) {
                NodeKind.TEXT -> {
                    b.append(ind).append("Text(\n")
                        .append(ind).append("    text = \"").append(esc(n.text)).append("\",\n")
                        .append(ind).append("    modifier = ").append(modifier).append(",\n")
                        .append(ind).append("    color = ").append(colorExpr(n.fill, n.fillToken)).append(",\n")
                        .append(ind).append("    fontSize = ").append(num(n.fontSize)).append(".sp,\n")
                        .append(ind).append("    fontWeight = FontWeight.W").append(n.weight).append(",\n")
                        .append(ind).append("    softWrap = false,\n")
                    val fam = c.opts?.fonts?.get(n.font)
                    if (fam != null) b.append(ind).append("    fontFamily = VexelFonts.").append(fam).append(",\n")
                    else if (n.font.isNotEmpty()) b.append(ind).append("    // font \"").append(esc(n.font)).append("\": plug in your own FontFamily\n")
                    b.append(ind).append(")\n")
                }
                NodeKind.IMAGE -> {
                    c.usesImage = true
                    val res = imageResName(n.asset)
                    b.append(ind).append("// copy the picture into res/drawable as ").append(res).append(" (original file: ").append(esc(n.asset)).append(")\n")
                    b.append(ind).append("Image(\n")
                        .append(ind).append("    painter = painterResource(R.drawable.").append(res).append("),\n")
                        .append(ind).append("    contentDescription = null,\n")
                        .append(ind).append("    contentScale = ContentScale.Crop,\n")
                        .append(ind).append("    modifier = ").append(modifier).append(",\n")
                        .append(ind).append(")\n")
                }
                else -> b.append(ind).append("Box(\n").append(ind).append("    ").append(modifier).append(",\n").append(ind).append(")\n")
            }
            return b.toString()
        }

        if (mask == null) return sb.append(body()).toString()

        // маска: слой лежит внутри Box с формой маски и обрезается по ней
        val (mShape, mComment) = shapeOf(mask, c)
        sb.append(ind).append("// clipped by the mask \"").append(mask.name.ifBlank { mask.kind.name.lowercase() }).append("\"")
        if (abs(mask.rotation) > 0.01f) sb.append(" (mask rotation ").append(num(mask.rotation)).append(" is not applied)")
        mComment?.let { sb.append("; ").append(it) }
        sb.append('\n')
        val inner = layer(n, c, "$ind    ", mask.x, mask.y, null)
        sb.append(ind).append("Box(\n")
            .append(ind).append("    Modifier\n")
            .append(ind).append("        .offset(${dp(mask.x - ox)}, ${dp(mask.y - oy)})\n")
            .append(ind).append("        .size(${dp(mask.w)}, ${dp(mask.h)})\n")
            .append(ind).append("        .clip(${mShape ?: "RectangleShape"}),\n")
            .append(ind).append(") {\n")
            .append(inner)
            .append(ind).append("}\n")
        return sb.toString()
    }

    internal fun imageResName(asset: String): String {
        val base = asset.substringBeforeLast('.').lowercase().replace(Regex("[^a-z0-9_]"), "_")
        return if (base.isEmpty() || base[0].isDigit()) "img_$base" else base
    }

    // ---------------------------------------------------------------- компоненты

    /** Компонент: группа слоёв с известным id и слои его заготовки для сравнения. */
    private class Comp(val id: String, val nodes: List<Node>, val tpl: List<Node>, val ox: Float, val oy: Float) {
        val box: Box = boundsOf(nodes) ?: Box(0f, 0f, 0f, 0f)
        val x: Float get() = box.l - ox
        val y: Float get() = box.t - oy
        val w: Float get() = box.w
        val h: Float get() = box.h
        val texts: List<Node> = nodes.filter { it.kind == NodeKind.TEXT }
        private val tplTexts: List<Node> = tpl.filter { it.kind == NodeKind.TEXT }
        val icons: List<Node> = nodes.filter { it.kind == NodeKind.PATH && (it.fill ushr 24) != 0 }
        val first: Node? = nodes.firstOrNull()
        fun role(r: String): Node? = nodes.firstOrNull { it.widget == r }
        fun at(): String = "Modifier.offset(${dp(x)}, ${dp(y)})"
        fun sized(): String = "${at()}.size(${dp(w)}, ${dp(h)})"
        fun wide(): String = "${at()}.width(${dp(w)})"

        /** Текст [i] как аргумент Text(...): стиль добавляется, только если его меняли относительно заготовки. */
        fun text(i: Int, fallback: String = ""): String {
            val n = texts.getOrNull(i) ?: return "Text(\"${esc(fallback)}\")"
            val t = tplTexts.getOrNull(i)
            val extra = StringBuilder()
            if (t != null && abs(n.fontSize - t.fontSize) > 0.01f) extra.append(", fontSize = ${num(n.fontSize)}.sp")
            if (t != null && n.weight != t.weight) extra.append(", fontWeight = FontWeight.W${n.weight}")
            return "Text(\"${esc(n.text)}\"$extra)"
        }

        /** Скругление контейнера: null, если оно совпадает с формой Material по умолчанию. */
        fun shapeArg(defaultCorner: Float): String? {
            val n = first?.takeIf { it.kind == NodeKind.RECT } ?: return null
            val half = min(n.w, n.h) / 2f
            val eff = min(n.corner, half)
            return if (abs(eff - min(defaultCorner, half)) < 0.5f) null else "RoundedCornerShape(${dp(eff)})"
        }
    }

    private fun iconCall(n: Node?, c: Ctx, plain: String, modifier: String? = null): String {
        val vec = n?.let { c.vector(it) }
        val expr = vec ?: plain
        val m = modifier ?: if (n != null && vec != null) "Modifier.size(${dp(n.w)}, ${dp(n.h)})" else null
        return if (m != null) "Icon($expr, contentDescription = null, modifier = $m)" else "Icon($expr, contentDescription = null)"
    }

    private fun clamp01(v: Float) = v.coerceIn(0f, 1f)

    private fun f(v: Float) = num(v) + "f"

    /** Пишет в [s] код компонента как виджета Material 3. false - у компонента нет прямого аналога (ничего не записано). */
    private fun emitMaterial(k: Comp, c: Ctx, s: Src): Boolean {
        when (k.id) {
            "btn-filled", "btn-tonal", "btn-outlined", "btn-elevated", "btn-text", "btn-m", "btn-l", "btn-xl", "btn-square" -> {
                val fn = when (k.id) {
                    "btn-tonal" -> "FilledTonalButton"; "btn-outlined" -> "OutlinedButton"
                    "btn-elevated" -> "ElevatedButton"; "btn-text" -> "TextButton"; else -> "Button"
                }
                val args = arrayListOf("onClick = { }", "modifier = ${k.sized()}")
                k.shapeArg(9999f)?.let { args += "shape = $it" }
                s.call(fn, args) { a(k.text(0, "Button")) }
            }
            "icon-btn", "icon-btn-tonal", "icon-btn-outlined", "icon-btn-square" -> {
                val fn = when (k.id) { "icon-btn-tonal" -> "FilledTonalIconButton"; "icon-btn-outlined" -> "OutlinedIconButton"; else -> "FilledIconButton" }
                val args = arrayListOf("onClick = { }", "modifier = ${k.sized()}")
                k.shapeArg(9999f)?.let { args += "shape = $it" }
                s.call(fn, args) { a(iconCall(k.icons.firstOrNull(), c, "Icons.Filled.Add")) }
            }
            "fab", "fab-small", "fab-large" -> {
                val fn = when (k.id) { "fab-small" -> "SmallFloatingActionButton"; "fab-large" -> "LargeFloatingActionButton"; else -> "FloatingActionButton" }
                val args = arrayListOf("onClick = { }", "modifier = ${k.at()}")
                s.call(fn, args) { a(iconCall(k.icons.firstOrNull(), c, "Icons.Filled.Add")) }
            }
            "ext-fab" -> s.call("ExtendedFloatingActionButton", listOf("onClick = { }", "modifier = ${k.sized()}")) { a(k.text(0, "Create")) }
            "card", "card-elevated", "card-outlined", "card-media", "card-expressive", "stat-card" -> return emitCard(k, c, s)
            "dialog", "bottom-sheet", "menu", "tooltip", "banner" -> return emitSurface(k, c, s)
            "chip" -> {
                val st = c.state("filter", "false")
                s.call("FilterChip", listOf("selected = $st", "onClick = { $st = !$st }", "modifier = ${k.at()}")) { }
                // метка идёт отдельным аргументом
                s.sb.setLength(s.sb.length - 0)
                return emitChipLabel(k, s, st)
            }
            "chip-filter" -> {
                val st = c.state("filter", "true")
                emitFilterChip(k, s, st)
            }
            "chip-assist" -> {
                s.a("AssistChip(")
                s.inc()
                s.a("onClick = { },")
                s.a("label = { ${k.text(0, "Assist")} },")
                s.a("leadingIcon = { ${iconCall(k.icons.firstOrNull(), c, "Icons.Filled.Check", "Modifier.size(AssistChipDefaults.IconSize)")} },")
                s.a("modifier = ${k.at()},")
                s.dec()
                s.a(")")
            }
            "chip-input" -> {
                s.a("InputChip(")
                s.inc()
                s.a("selected = false,")
                s.a("onClick = { },")
                s.a("label = { ${k.text(0, "Input")} },")
                s.a("trailingIcon = { Icon(Icons.Filled.Close, contentDescription = null, modifier = Modifier.size(InputChipDefaults.IconSize)) },")
                s.a("modifier = ${k.at()},")
                s.dec()
                s.a(")")
            }
            "switch", "switch-off", "switch-icon" -> {
                val track = k.role("switch:track") ?: return false
                val thumb = k.role("switch:thumb") ?: return false
                val st = c.state("checked", (thumb.cx > track.cx).toString())
                s.a("Switch(")
                s.inc()
                s.a("checked = $st,")
                s.a("onCheckedChange = { $st = it },")
                s.a("modifier = ${k.at()},")
                if (k.id == "switch-icon") {
                    s.a("thumbContent = if ($st) {")
                    s.inc(); s.a("{ Icon(Icons.Filled.Check, contentDescription = null, modifier = Modifier.size(SwitchDefaults.IconSize)) }"); s.dec()
                    s.a("} else null,")
                }
                s.dec()
                s.a(")")
            }
            "checkbox", "checkbox-off" -> {
                val box = k.role("check:box") ?: return false
                val st = c.state("checked", ((box.fill ushr 24) != 0).toString())
                s.call("Checkbox", listOf("checked = $st", "onCheckedChange = { $st = it }",
                    "modifier = Modifier.offset(${dp(k.x - (40f - k.w) / 2f)}, ${dp(k.y - (40f - k.h) / 2f)})"))
            }
            "radio", "radio-off" -> {
                val st = c.state("selected", (k.role("radio:dot") != null).toString())
                s.call("RadioButton", listOf("selected = $st", "onClick = { $st = !$st }",
                    "modifier = Modifier.offset(${dp(k.x - (40f - k.w) / 2f)}, ${dp(k.y - (40f - k.h) / 2f)})"))
            }
            "slider", "slider-expressive", "slider-wavy" -> {
                val thumb = k.role("slider:thumb") ?: return false
                val st = c.state("value", f(clamp01((thumb.cx - k.box.l) / k.w)))
                s.call("Slider", listOf("value = $st", "onValueChange = { $st = it }",
                    "modifier = Modifier.offset(${dp(k.x)}, ${dp(k.y + k.h / 2f - 24f)}).width(${dp(k.w)})"))
            }
            "progress", "progress-wavy" -> {
                val act = k.role("progress:active") ?: return false
                val v = clamp01(act.w / k.w)
                s.call("LinearProgressIndicator", listOf("progress = { ${f(v)} }", "modifier = ${k.wide()}"))
            }
            "progress-circular" -> s.call("CircularProgressIndicator", listOf("progress = { 0.75f }", "modifier = ${k.sized()}"))
            "loading" -> s.call("CircularProgressIndicator", listOf("modifier = ${k.sized()}"))
            "textfield", "textfield-error", "textfield-filled" -> {
                val st = c.state("text", "\"\"")
                val filled = k.id == "textfield-filled"
                val err = k.id == "textfield-error"
                val fn = if (filled) "TextField" else "OutlinedTextField"
                s.a("$fn(")
                s.inc()
                s.a("value = $st,")
                s.a("onValueChange = { $st = it },")
                s.a("label = { ${k.text(0, "Label")} },")
                if (err) {
                    s.a("isError = true,")
                    if (k.texts.size > 1) s.a("supportingText = { ${k.text(1)} },")
                }
                s.a("modifier = ${k.at()}.width(${dp(k.w)}),")
                s.dec()
                s.a(")")
            }
            "search" -> {
                val st = c.state("query", "\"\"")
                s.a("TextField(")
                s.inc()
                s.a("value = $st,")
                s.a("onValueChange = { $st = it },")
                s.a("placeholder = { ${k.text(0, "Search")} },")
                s.a("leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },")
                s.a("singleLine = true,")
                s.a("shape = CircleShape,")
                s.a("colors = TextFieldDefaults.colors(")
                s.inc()
                s.a("focusedContainerColor = MaterialTheme.colorScheme.surfaceContainerHigh,")
                s.a("unfocusedContainerColor = MaterialTheme.colorScheme.surfaceContainerHigh,")
                s.a("focusedIndicatorColor = Color.Transparent,")
                s.a("unfocusedIndicatorColor = Color.Transparent,")
                s.dec()
                s.a("),")
                s.a("modifier = ${k.sized()},")
                s.dec()
                s.a(")")
            }
            "divider" -> s.call("HorizontalDivider", listOf("modifier = ${k.wide()}"))
            "badge", "badge-large" -> s.call("Badge", listOf("modifier = ${k.at()}")) { a(k.text(0, "3")) }
            "tabs" -> {
                if (k.texts.isEmpty()) return false
                val st = c.state("tab", "0")
                s.a("TabRow(")
                s.inc(); s.a("selectedTabIndex = $st,"); s.a("modifier = ${k.wide()},"); s.dec()
                s.a(") {")
                s.inc()
                for (i in k.texts.indices) {
                    s.a("Tab(")
                    s.inc()
                    s.a("selected = $st == $i,")
                    s.a("onClick = { $st = $i },")
                    s.a("text = { ${k.text(i)} },")
                    s.dec()
                    s.a(")")
                }
                s.dec()
                s.a("}")
            }
            "segmented" -> {
                if (k.texts.isEmpty()) return false
                val st = c.state("segment", "0")
                val n = k.texts.size
                s.a("SingleChoiceSegmentedButtonRow(modifier = ${k.wide()}) {")
                s.inc()
                for (i in 0 until n) {
                    s.a("SegmentedButton(")
                    s.inc()
                    s.a("selected = $st == $i,")
                    s.a("onClick = { $st = $i },")
                    s.a("shape = SegmentedButtonDefaults.itemShape(index = $i, count = $n),")
                    s.a("label = { ${k.text(i)} },")
                    s.dec()
                    s.a(")")
                }
                s.dec()
                s.a("}")
            }
            "nav-bar", "nav-bar-flex" -> {
                if (k.texts.isEmpty()) return false
                val st = c.state("item", "0")
                s.a("NavigationBar(")
                s.inc()
                s.a("modifier = ${k.sized()},")
                s.a("windowInsets = WindowInsets(0, 0, 0, 0),")
                s.dec()
                s.a(") {")
                s.inc()
                for (i in k.texts.indices) {
                    s.a("NavigationBarItem(")
                    s.inc()
                    s.a("selected = $st == $i,")
                    s.a("onClick = { $st = $i },")
                    s.a("icon = { ${iconCall(k.icons.getOrNull(i), c, "Icons.Filled.Check")} },")
                    s.a("label = { ${k.text(i)} },")
                    if (k.id == "nav-bar-flex") s.a("alwaysShowLabel = false,")
                    s.dec()
                    s.a(")")
                }
                s.dec()
                s.a("}")
            }
            "nav-rail" -> {
                if (k.texts.isEmpty()) return false
                val st = c.state("item", "0")
                s.a("NavigationRail(")
                s.inc()
                s.a("modifier = ${k.sized()},")
                s.a("header = { FloatingActionButton(onClick = { }) { Icon(Icons.Filled.Add, contentDescription = null) } },")
                s.a("windowInsets = WindowInsets(0, 0, 0, 0),")
                s.dec()
                s.a(") {")
                s.inc()
                for (i in k.texts.indices) {
                    s.a("NavigationRailItem(")
                    s.inc()
                    s.a("selected = $st == $i,")
                    s.a("onClick = { $st = $i },")
                    s.a("icon = { ${iconCall(k.icons.getOrNull(i), c, "Icons.Filled.Check")} },")
                    s.a("label = { ${k.text(i)} },")
                    s.dec()
                    s.a(")")
                }
                s.dec()
                s.a("}")
            }
            "bottom-bar" -> {
                s.a("BottomAppBar(")
                s.inc()
                s.a("modifier = ${k.sized()},")
                s.a("windowInsets = WindowInsets(0, 0, 0, 0),")
                s.a("actions = {")
                s.inc()
                for (ic in k.icons) {
                    s.a("IconButton(onClick = { }) { ${iconCall(ic, c, "Icons.Filled.Check")} }")
                }
                s.dec()
                s.a("},")
                s.a("floatingActionButton = { FloatingActionButton(onClick = { }) { Icon(Icons.Filled.Add, contentDescription = null) } },")
                s.dec()
                s.a(")")
            }
            "top-bar", "top-bar-center", "top-bar-medium", "top-bar-large" -> {
                val title = k.texts.firstOrNull() ?: return false
                val fn = when (k.id) {
                    "top-bar-center" -> "CenterAlignedTopAppBar"; "top-bar-medium" -> "MediumTopAppBar"
                    "top-bar-large" -> "LargeTopAppBar"; else -> "TopAppBar"
                }
                val bg = k.first!!
                val left = k.icons.filter { it.cx < k.box.cx }
                val right = k.icons.filter { it.cx >= k.box.cx }
                s.a("$fn(")
                s.inc()
                s.a("title = { ${k.text(0, title.text)} },")
                s.a("modifier = ${k.sized()},")
                s.slot("navigationIcon") { a("IconButton(onClick = { }) { ${iconCall(left.firstOrNull(), c, "Icons.Filled.Menu")} }") }
                if (right.isNotEmpty()) s.slot("actions") {
                    for (ic in right) a("IconButton(onClick = { }) { ${iconCall(ic, c, "Icons.Filled.Check")} }")
                }
                s.a("windowInsets = WindowInsets(0, 0, 0, 0),")
                s.a("colors = TopAppBarDefaults.topAppBarColors(containerColor = ${colorExpr(bg.fill, bg.fillToken)}),")
                s.dec()
                s.a(")")
            }
            "list-item", "list-3line", "list-switch", "list-checkbox" -> {
                if (k.texts.isEmpty()) return false
                val avatar = k.nodes.firstOrNull { it.kind == NodeKind.ELLIPSE && it.widget.isEmpty() }
                val sw = k.role("switch:track")
                val cb = k.role("check:box")
                s.a("ListItem(")
                s.inc()
                s.a("headlineContent = { ${k.text(0)} },")
                if (k.texts.size > 1) {
                    if (k.texts.size == 2) s.a("supportingContent = { ${k.text(1)} },")
                    else s.slot("supportingContent") {
                        a("Column {")
                        inc(); for (i in 1 until k.texts.size) a(k.text(i)); dec()
                        a("}")
                    }
                }
                if (avatar != null) s.slot("leadingContent") {
                    a("Box(Modifier.size(${dp(avatar.w)}, ${dp(avatar.h)}).background(${colorExpr(avatar.fill, avatar.fillToken)}, CircleShape))")
                }
                if (cb != null) {
                    val st = c.state("checked", ((cb.fill ushr 24) != 0).toString())
                    s.slot("leadingContent") { a("Checkbox(checked = $st, onCheckedChange = { $st = it })") }
                }
                if (sw != null) {
                    val thumb = k.role("switch:thumb")
                    val st = c.state("checked", (thumb != null && thumb.cx > sw.cx).toString())
                    s.slot("trailingContent") { a("Switch(checked = $st, onCheckedChange = { $st = it })") }
                }
                s.a("modifier = ${k.wide()},")
                s.dec()
                s.a(")")
            }
            "snackbar" -> {
                if (k.texts.isEmpty()) return false
                s.a("Snackbar(")
                s.inc()
                s.a("modifier = ${k.wide()},")
                if (k.texts.size > 1) s.slot("action") { a("TextButton(onClick = { }) { ${k.text(1)} }") }
                s.dec()
                s.a(") {")
                s.inc(); s.a(k.text(0)); s.dec()
                s.a("}")
            }
            else -> return false
        }
        return true
    }

    private fun emitChipLabel(k: Comp, s: Src, st: String): Boolean {
        // 'chip': переписываем только что выведенный FilterChip(...) с меткой
        val text = s.sb.toString()
        val cut = text.lastIndexOf("FilterChip(")
        val lineStart = text.lastIndexOf('\n', cut) + 1
        s.sb.setLength(lineStart)
        s.a("FilterChip(")
        s.inc()
        s.a("selected = $st,")
        s.a("onClick = { $st = !$st },")
        s.a("label = { ${k.text(0, "Filter")} },")
        s.a("modifier = ${k.at()},")
        s.dec()
        s.a(")")
        return true
    }

    private fun emitFilterChip(k: Comp, s: Src, st: String) {
        s.a("FilterChip(")
        s.inc()
        s.a("selected = $st,")
        s.a("onClick = { $st = !$st },")
        s.a("label = { ${k.text(0, "Filter")} },")
        s.a("leadingIcon = if ($st) {")
        s.inc(); s.a("{ Icon(Icons.Filled.Check, contentDescription = null, modifier = Modifier.size(FilterChipDefaults.IconSize)) }"); s.dec()
        s.a("} else null,")
        s.a("modifier = ${k.at()},")
        s.dec()
        s.a(")")
    }

    /** Остальные слои компонента (кроме контейнера), по координатам внутри контейнера. */
    private fun innerLayers(k: Comp, c: Ctx, s: Src, container: Node) {
        s.a("Box(Modifier.fillMaxSize()) {")
        s.inc()
        for (n in k.nodes) {
            if (n === container || !n.visible) continue
            s.raw(layer(n, c, "    ".repeat(s.depth), container.x, container.y))
        }
        s.dec()
        s.a("}")
    }

    private fun emitCard(k: Comp, c: Ctx, s: Src): Boolean {
        val box = k.first?.takeIf { it.kind == NodeKind.RECT && !it.hasGradient } ?: return false
        val fn = when (k.id) { "card-elevated" -> "ElevatedCard"; "card-outlined" -> "OutlinedCard"; else -> "Card" }
        val colors = when (fn) { "ElevatedCard" -> "elevatedCardColors"; "OutlinedCard" -> "outlinedCardColors"; else -> "cardColors" }
        val shape = "RoundedCornerShape(${dp(min(box.corner, min(box.w, box.h) / 2f))})"
        val args = arrayListOf(
            "modifier = ${k.sized()}",
            "shape = $shape",
            "colors = CardDefaults.$colors(containerColor = ${colorExpr(box.fill, box.fillToken)})",
        )
        if (fn == "OutlinedCard" && (box.stroke ushr 24) != 0 && box.strokeWidth > 0f) {
            args += "border = BorderStroke(${dp(box.strokeWidth)}, ${colorExpr(box.stroke, box.strokeToken)})"
        }
        s.call(fn, args) { innerLayers(k, c, this, box) }
        return true
    }

    private fun emitSurface(k: Comp, c: Ctx, s: Src): Boolean {
        val box = k.first?.takeIf { it.kind == NodeKind.RECT && !it.hasGradient } ?: return false
        val args = arrayListOf(
            "modifier = ${k.sized()}",
            "shape = RoundedCornerShape(${dp(min(box.corner, min(box.w, box.h) / 2f))})",
            "color = ${colorExpr(box.fill, box.fillToken)}",
        )
        if (box.hasShadow) args += "shadowElevation = ${dp(box.shadowBlur / 2f)}"
        if ((box.stroke ushr 24) != 0 && box.strokeWidth > 0f) args += "border = BorderStroke(${dp(box.strokeWidth)}, ${colorExpr(box.stroke, box.strokeToken)})"
        s.call("Surface", args) { innerLayers(k, c, this, box) }
        return true
    }

    /** Слои заготовки -> Comp, если группа не менялась (те же слои, те же токены цвета, все видимы). */
    private fun recognise(group: String, members: List<Node>, ox: Float, oy: Float): Comp? {
        val id = group.substringAfter(ComponentDef.TAG, "")
        if (id.isEmpty()) return null
        val def = Components.all.firstOrNull { it.id == id } ?: return null
        val tpl = def.build(0f, 0f, "x", Tone.Baseline)
        if (tpl.size != members.size) return null
        for (i in tpl.indices) {
            val a = tpl[i]; val b = members[i]
            if (a.kind != b.kind || a.fillToken != b.fillToken || a.strokeToken != b.strokeToken) return null
            if (!b.visible || b.mask || b.hasGradient || b.blur > 0.5f || abs(b.rotation - a.rotation) > 0.5f && b.kind == NodeKind.TEXT) return null
        }
        return Comp(id, members, tpl, ox, oy)
    }

    // ---------------------------------------------------------------- импорты

    private val material3Names = listOf(
        "Button", "FilledTonalButton", "OutlinedButton", "ElevatedButton", "TextButton", "IconButton", "FilledIconButton",
        "FilledTonalIconButton", "OutlinedIconButton", "FloatingActionButton", "SmallFloatingActionButton", "LargeFloatingActionButton",
        "ExtendedFloatingActionButton", "Card", "ElevatedCard", "OutlinedCard", "CardDefaults", "Surface", "Text", "Icon",
        "FilterChip", "FilterChipDefaults", "AssistChip", "AssistChipDefaults", "InputChip", "InputChipDefaults", "Switch", "SwitchDefaults",
        "Checkbox", "RadioButton", "Slider", "LinearProgressIndicator", "CircularProgressIndicator", "OutlinedTextField", "TextField",
        "TextFieldDefaults", "HorizontalDivider", "Badge", "TabRow", "Tab", "SingleChoiceSegmentedButtonRow", "SegmentedButton",
        "SegmentedButtonDefaults", "NavigationBar", "NavigationBarItem", "NavigationRail", "NavigationRailItem", "BottomAppBar",
        "TopAppBar", "CenterAlignedTopAppBar", "MediumTopAppBar", "LargeTopAppBar", "TopAppBarDefaults", "ListItem", "Snackbar",
        "MaterialTheme", "MaterialShapes",
    )

    private val experimentalNames = listOf(
        "TopAppBar", "CenterAlignedTopAppBar", "MediumTopAppBar", "LargeTopAppBar", "TopAppBarDefaults",
        "SingleChoiceSegmentedButtonRow", "SegmentedButton", "SegmentedButtonDefaults",
    )

    private val simpleImports = listOf(
        Regex("\\bModifier\\b") to "androidx.compose.ui.Modifier",
        Regex("\\.offset\\(") to "androidx.compose.foundation.layout.offset",
        Regex("\\.size\\(") to "androidx.compose.foundation.layout.size",
        Regex("\\.width\\(") to "androidx.compose.foundation.layout.width",
        Regex("\\bfillMaxSize\\(") to "androidx.compose.foundation.layout.fillMaxSize",
        Regex("\\bBox\\(") to "androidx.compose.foundation.layout.Box",
        Regex("\\bColumn\\b") to "androidx.compose.foundation.layout.Column",
        Regex("\\bWindowInsets\\(") to "androidx.compose.foundation.layout.WindowInsets",
        Regex("\\.background\\(") to "androidx.compose.foundation.background",
        Regex("\\.border\\(") to "androidx.compose.foundation.border",
        Regex("\\bBorderStroke\\(") to "androidx.compose.foundation.BorderStroke",
        Regex("\\.clip\\(") to "androidx.compose.ui.draw.clip",
        Regex("\\.rotate\\(") to "androidx.compose.ui.draw.rotate",
        Regex("\\.alpha\\(") to "androidx.compose.ui.draw.alpha",
        Regex("\\.shadow\\(") to "androidx.compose.ui.draw.shadow",
        Regex("\\bColor[.(]") to "androidx.compose.ui.graphics.Color",
        Regex("\\bRectangleShape\\b") to "androidx.compose.ui.graphics.RectangleShape",
        Regex("\\bRoundedCornerShape\\(") to "androidx.compose.foundation.shape.RoundedCornerShape",
        Regex("\\bCircleShape\\b") to "androidx.compose.foundation.shape.CircleShape",
        Regex("\\bGenericShape\\b") to "androidx.compose.foundation.shape.GenericShape",
        Regex("\\bRect\\(") to "androidx.compose.ui.geometry.Rect",
        Regex("\\bOffset\\b") to "androidx.compose.ui.geometry.Offset",
        Regex("\\bSize\\b") to "androidx.compose.ui.geometry.Size",
        Regex("\\bBrush\\b") to "androidx.compose.ui.graphics.Brush",
        Regex("\\bShaderBrush\\b") to "androidx.compose.ui.graphics.ShaderBrush",
        Regex("\\bShader\\b") to "androidx.compose.ui.graphics.Shader",
        Regex("\\bLinearGradientShader\\b") to "androidx.compose.ui.graphics.LinearGradientShader",
        Regex("\\bSolidColor\\b") to "androidx.compose.ui.graphics.SolidColor",
        Regex("\\bPath\\b") to "androidx.compose.ui.graphics.Path",
        Regex("\\bPathFillType\\b") to "androidx.compose.ui.graphics.PathFillType",
        Regex("\\bImageVector\\b") to "androidx.compose.ui.graphics.vector.ImageVector",
        Regex("\\bPathParser\\b") to "androidx.compose.ui.graphics.vector.PathParser",
        Regex("\\.dp\\b") to "androidx.compose.ui.unit.dp",
        Regex("\\.sp\\b") to "androidx.compose.ui.unit.sp",
        Regex("\\bFontWeight\\b") to "androidx.compose.ui.text.font.FontWeight",
        Regex("\\bImage\\(") to "androidx.compose.foundation.Image",
        Regex("\\bpainterResource\\(") to "androidx.compose.ui.res.painterResource",
        Regex("\\bContentScale\\b") to "androidx.compose.ui.layout.ContentScale",
        Regex("\\bComposable\\b") to "androidx.compose.runtime.Composable",
        Regex("\\bremember\\b") to "androidx.compose.runtime.remember",
        Regex("\\bmutableStateOf\\b") to "androidx.compose.runtime.mutableStateOf",
        Regex("\\b(val|var) \\w+ by ") to "androidx.compose.runtime.getValue",
        Regex("\\.blur\\(") to "androidx.compose.ui.draw.blur",
        Regex("\\bBlurredEdgeTreatment\\b") to "androidx.compose.ui.draw.BlurredEdgeTreatment",
        Regex("\\.clickable\\(") to "androidx.compose.foundation.clickable",
        Regex("\\bLocalUriHandler\\b") to "androidx.compose.ui.platform.LocalUriHandler",
        Regex("\\bMutableInteractionSource\\b") to "androidx.compose.foundation.interaction.MutableInteractionSource",
        Regex("\\bcollectIsPressedAsState\\b") to "androidx.compose.foundation.interaction.collectIsPressedAsState",
        Regex("\\banimateDpAsState\\b") to "androidx.compose.animation.core.animateDpAsState",
        Regex("\\bSpring\\.") to "androidx.compose.animation.core.Spring",
        Regex("\\bspring\\(") to "androidx.compose.animation.core.spring",
        Regex("\\bvar \\w+ by remember") to "androidx.compose.runtime.setValue",
        Regex("\\.toShape\\(") to "androidx.compose.material3.toShape",
        Regex("\\bRoundedPolygon\\b") to "androidx.graphics.shapes.RoundedPolygon",
        Regex("\\.star\\(") to "androidx.graphics.shapes.star",
        Regex("\\b(cos|sin|abs)\\(") to "",
    )

    private fun importsFor(code: String): List<String> {
        // литералы строк не считаются: слова в подписях не должны тянуть лишние импорты
        val bare = code.replace(Regex("\"(\\\\.|[^\"\\\\])*\""), "\"\"").replace(Regex("//[^\n]*"), "")
        val out = sortedSetOf<String>()
        for ((re, imp) in simpleImports) if (imp.isNotEmpty() && re.containsMatchIn(bare)) out += imp
        if (Regex("\\bcos\\(").containsMatchIn(bare)) out += "kotlin.math.cos"
        if (Regex("\\bsin\\(").containsMatchIn(bare)) out += "kotlin.math.sin"
        if (Regex("\\babs\\(").containsMatchIn(bare)) out += "kotlin.math.abs"
        for (n in material3Names) if (Regex("\\b$n\\b").containsMatchIn(bare)) out += "androidx.compose.material3.$n"
        if (Regex("\\bExperimentalMaterial3Api\\b").containsMatchIn(bare)) out += "androidx.compose.material3.ExperimentalMaterial3Api"
        if (Regex("\\bExperimentalMaterial3ExpressiveApi\\b").containsMatchIn(bare)) out += "androidx.compose.material3.ExperimentalMaterial3ExpressiveApi"
        for (m in Regex("Icons\\.Filled\\.(\\w+)").findAll(bare)) {
            out += "androidx.compose.material.icons.Icons"
            out += "androidx.compose.material.icons.filled.${m.groupValues[1]}"
        }
        return out.toList()
    }

    private fun optIn(code: String): String {
        val bare = code.replace(Regex("\"(\\\\.|[^\"\\\\])*\""), "\"\"").replace(Regex("//[^\n]*"), "")
        val list = ArrayList<String>()
        if (experimentalNames.any { Regex("\\b$it\\b").containsMatchIn(bare) }) list += "ExperimentalMaterial3Api::class"
        if (Regex("\\bMaterialShapes\\b|\\.toShape\\(").containsMatchIn(bare)) list += "ExperimentalMaterial3ExpressiveApi::class"
        return if (list.isEmpty()) "" else "@OptIn(${list.joinToString(", ")})\n"
    }

    private const val PATH_HELPER = """/** Контур в единичном квадрате ("M x y L x y C ... Z") -> Path размера w x h. */
private fun vexelPath(data: String, w: Float, h: Float): Path {
    val p = Path()
    val t = data.split(' ').filter { it.isNotEmpty() }
    var i = 0
    while (i < t.size) {
        when (t[i]) {
            "M" -> { p.moveTo(t[i + 1].toFloat() * w, t[i + 2].toFloat() * h); i += 3 }
            "L" -> { p.lineTo(t[i + 1].toFloat() * w, t[i + 2].toFloat() * h); i += 3 }
            "Q" -> { p.quadraticTo(t[i + 1].toFloat() * w, t[i + 2].toFloat() * h, t[i + 3].toFloat() * w, t[i + 4].toFloat() * h); i += 5 }
            "C" -> { p.cubicTo(t[i + 1].toFloat() * w, t[i + 2].toFloat() * h, t[i + 3].toFloat() * w, t[i + 4].toFloat() * h, t[i + 5].toFloat() * w, t[i + 6].toFloat() * h); i += 7 }
            "Z" -> { p.close(); i += 1 }
            else -> i += 1
        }
    }
    return p
}
"""

    private const val ANGLE_HELPER = """/** Линейный градиент под любым углом (0 - слева направо, 90 - сверху вниз) на всю площадь слоя. */
private fun angledGradient(angle: Float, vararg colors: Color): Brush = object : ShaderBrush() {
    override fun createShader(size: Size): Shader {
        val r = Math.toRadians(angle.toDouble())
        val dx = cos(r).toFloat()
        val dy = sin(r).toFloat()
        val half = (abs(size.width * dx) + abs(size.height * dy)) / 2f
        val cx = size.width / 2f
        val cy = size.height / 2f
        return LinearGradientShader(Offset(cx - dx * half, cy - dy * half), Offset(cx + dx * half, cy + dy * half), colors.toList())
    }
}
"""

    // ---------------------------------------------------------------- сборка

    /**
     * Код для [nodes]. Если [crop] задан, слои сдвигаются так, чтобы эта рамка стала левым верхним углом
     * (так выгружается выделение), а размер корневого Box равен рамке.
     */
    fun generate(p: Project, nodes: List<Node> = p.nodes, title: String = p.name, crop: Box? = null, opts: ExportOpts? = null): String {
        val c = Ctx()
        c.opts = opts
        // слои, которые включаются и выключаются нажатием: состояние объявляется заранее, слой оборачивается в if
        for (a in nodes) {
            if (!a.action.startsWith("toggle:")) continue
            val t = nodes.firstOrNull { it.id == a.action.substringAfter(':') && it.group.isEmpty() } ?: continue
            if (t.id !in c.toggles) c.toggles[t.id] = c.state("show", t.visible.toString())
        }
        val ox = crop?.l ?: 0f
        val oy = crop?.t ?: 0f
        val rootW = crop?.w ?: p.width
        val rootH = crop?.h ?: p.height
        val body = Src(2)

        val byGroup = nodes.filter { it.group.isNotEmpty() }.groupBy { it.group }
        val recognised = HashMap<String, Comp?>()
        val done = HashSet<String>()

        for ((idx, n) in nodes.withIndex()) {
            if (n.group.isNotEmpty()) {
                val comp = recognised.getOrPut(n.group) { recognise(n.group, byGroup[n.group].orEmpty(), ox, oy) }
                if (comp != null) {
                    if (!done.add(n.group)) continue
                    emitComponent(comp, c, body)
                    continue
                }
            }
            val tog = c.toggles[n.id]
            if (n.isMask || (!n.visible && tog == null)) continue
            val mask = nodes.getOrNull(idx + 1)?.takeIf { it.isMask && it.visible }
            if (tog != null) {
                val inner = layer(n, c, "            ", ox, oy, mask)
                body.raw("        if ($tog) {\n$inner        }\n")
            } else body.raw(layer(n, c, "        ", ox, oy, mask))
        }

        val rootBg = if (crop != null) null else colorExpr(p.background, p.bgToken)
        val fnName = opts?.fnName ?: functionName(title)
        val main = StringBuilder()
        main.append("@Composable\nfun ").append(fnName).append("(modifier: Modifier = Modifier")
        if (opts != null) main.append(", onGoTo: (Int) -> Unit = {}, onBack: () -> Unit = {}")
        main.append(") {\n")
        for (st in c.states) main.append("    ").append(st).append('\n')
        if (c.states.isNotEmpty()) main.append('\n')
        main.append("    Box(\n        modifier\n            .size(${dp(rootW)}, ${dp(rootH)})")
        if (rootBg != null) main.append("\n            .background($rootBg)")
        main.append("\n    ) {\n")
        main.append(body.sb)
        main.append("    }\n}\n")

        val parts = ArrayList<String>()
        parts += optIn(main.toString()) + main
        for (fb in c.fallbacks) parts += optIn(fb) + fb
        val tail = StringBuilder()
        if (c.pathSrc.isNotEmpty() || c.vectorSrc.isNotEmpty()) tail.append("// ---- shapes and icons used above\n\n")
        for (x in c.pathSrc) tail.append(x).append('\n')
        for (x in c.vectorSrc) tail.append(x).append('\n')
        if (c.needPathHelper) tail.append(PATH_HELPER).append('\n')
        if (c.needAngle) tail.append(ANGLE_HELPER).append('\n')

        val code = parts.joinToString("\n") + (if (tail.isNotEmpty()) "\n" + tail else "")
        val out = StringBuilder()
        out.append("// Generated by Vexel. Components from the Components tab are real Material 3 widgets (state is kept with remember);\n")
        out.append("// other layers are placed by coordinates like on the canvas. Colors go through MaterialTheme.colorScheme.\n")
        if (c.usesImage && opts == null) out.append("// Pictures use R.drawable: add `import your.app.package.R` and copy the files into res/drawable.\n")
        out.append('\n')
        if (opts != null) out.append("package ").append(opts.pkg).append("\n\n")
        val imps = importsFor(code).toMutableList()
        if (opts != null && c.usesImage) imps += opts.rPkg + ".R"
        for (i in imps.sorted()) out.append("import ").append(i).append('\n')
        out.append('\n')
        out.append(code)
        return out.toString()
    }

    /** Компонент: виджет Material 3 или, если аналога нет, отдельная функция со слоями по координатам. */
    private fun emitComponent(k: Comp, c: Ctx, body: Src) {
        body.a("// ${k.id}")
        val probe = Src(body.depth)
        val stateMark = c.states.size
        val ok = emitMaterial(k, c, probe)
        if (ok) {
            var text = probe.sb.toString()
            k.nodes.firstOrNull { it.action.isNotEmpty() }?.let { an ->
                actionExpr(an, c)?.let { a -> text = text.replaceFirst("onClick = { }", "onClick = { $a }") }
            }
            body.raw(text)
            return
        }
        // чистый откат состояния, если виджет начал писать и отказался
        while (c.states.size > stateMark) c.states.removeAt(c.states.size - 1)
        val name = "Vexel" + pascal(k.id) + c.next("_").removePrefix("_")
        val fb = StringBuilder()
        fb.append("/** ${k.id}: no direct Material 3 widget, so the layers are placed by coordinates. */\n")
        fb.append("@Composable\nprivate fun $name(modifier: Modifier = Modifier) {\n")
        fb.append("    Box(modifier.size(${dp(k.w)}, ${dp(k.h)})) {\n")
        for (n in k.nodes) {
            if (!n.visible) continue
            fb.append(layer(n, c, "        ", k.box.l, k.box.t))
        }
        fb.append("    }\n}\n")
        c.fallbacks += fb.toString()
        body.a("$name(${k.at()})")
    }
}
