package com.qwenz.qwel.shapes

import androidx.graphics.shapes.CornerRounding
import androidx.graphics.shapes.Cubic
import androidx.graphics.shapes.Morph
import androidx.graphics.shapes.RoundedPolygon
import androidx.graphics.shapes.circle
import androidx.graphics.shapes.star
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin
import com.qwenz.qwel.i18n.trOr

/**
 * Одна фигура библиотеки. [source] даёт RoundedPolygon в любых координатах -
 * мы нормализуем её в единичный квадрат, поэтому фигуру можно растянуть до любого размера слоя.
 */
class ShapeDef(
    val id: String,
    /** Английское имя по умолчанию; перевод берётся из языкового файла по ключу shape.<id>. */
    val defaultName: String,
    val categories: List<String>,
    source: () -> RoundedPolygon,
) {
    val name: String get() = trOr("shape.$id", defaultName)
    val unit: RoundedPolygon by lazy { source().normalized() }
    val cubics: List<Cubic> get() = unit.cubics
}

/**
 * Библиотека фигур. ЧТОБЫ ДОБАВИТЬ СВОЮ ФИГУРУ - одна строка в блоке init ниже:
 *
 *     add("my-star", "My star", STARS) { RoundedPolygon.star(7, innerRadius = 0.6f, rounding = CornerRounding(0.2f)) }
 *
 * Подойдёт любой RoundedPolygon: из star()/RoundedPolygon(n), или собранный из вершин.
 * Всё остальное (превью, морфинг при смене фигуры, экспорт в SVG, сохранение) подхватится само.
 */
object ShapeLibrary {
    const val LOADER = "loader"
    const val BASIC = "basic"
    const val COOKIES = "cookies"
    const val BURSTS = "bursts"
    const val FLOWERS = "flowers"
    const val SPECIAL = "special"
    const val STARS = "stars"

    /** Подпись категории на текущем языке (ключ cat.<id>). */
    fun categoryName(category: String): String = trOr("cat.$category", category)

    /** Категории в порядке отображения. */
    val categories = listOf(LOADER, BASIC, COOKIES, BURSTS, FLOWERS, STARS, SPECIAL)

    private val defs = ArrayList<ShapeDef>()
    private val byId = HashMap<String, ShapeDef>()
    private val morphs = HashMap<String, Morph>()
    private val noMorph = HashSet<String>()

    val all: List<ShapeDef> get() = defs

    fun get(id: String): ShapeDef? = byId[id]
    fun inCategory(category: String): List<ShapeDef> = defs.filter { category in it.categories }

    /** Регистрирует фигуру. Повторный id заменяет прежнюю. */
    fun add(id: String, name: String, vararg categories: String, source: () -> RoundedPolygon) {
        val def = ShapeDef(id, name, categories.toList(), source)
        byId.put(id, def)?.let { defs.remove(it) }
        defs.add(def)
        morphs.clear()
        noMorph.clear()
    }

    /** Морфинг между двумя фигурами (кэшируется). */
    fun morph(from: String, to: String): Morph? {
        val a = byId[from] ?: return null
        val b = byId[to] ?: return null
        val key = "$from>$to"
        if (key in noMorph) return null
        morphs[key]?.let { return it }
        // на некоторых парах фигур библиотека падает (Progress repeats a value): тогда просто без анимации
        val m = try { Morph(a.unit, b.unit) } catch (e: Exception) { noMorph += key; return null }
        morphs[key] = m
        return m
    }

    /** Порядок фигур индикатора загрузки MD3. */
    val loaderOrder = listOf("soft-burst", "cookie-9", "pentagon", "pill", "sunny", "cookie-4", "oval")

    init {
        // --- Базовые ---
        add("circle", "Circle", BASIC) { Mat.Circle }
        add("square", "Square", BASIC) { Mat.Square }
        add("slanted", "Slanted", BASIC) { Mat.Slanted }
        add("arch", "Arch", BASIC) { Mat.Arch }
        add("fan", "Fan", BASIC) { Mat.Fan }
        add("arrow", "Arrow", BASIC) { Mat.Arrow }
        add("semicircle", "Semicircle", BASIC) { Mat.SemiCircle }
        add("oval", "Oval", BASIC, LOADER) { Mat.Oval }
        add("pill", "Pill", BASIC, LOADER) { Mat.Pill }
        add("triangle", "Triangle", BASIC) { Mat.Triangle }
        add("diamond", "Diamond", BASIC) { Mat.Diamond }
        add("clamshell", "Clamshell", BASIC) { Mat.ClamShell }
        add("pentagon", "Pentagon", BASIC, LOADER) { Mat.Pentagon }
        add("gem", "Gem", BASIC) { Mat.Gem }

        // --- Печеньки ---
        add("cookie-4", "Cookie 4", COOKIES, LOADER) { Mat.Cookie4Sided }
        add("cookie-6", "Cookie 6", COOKIES) { Mat.Cookie6Sided }
        add("cookie-7", "Cookie 7", COOKIES) { Mat.Cookie7Sided }
        add("cookie-9", "Cookie 9", COOKIES, LOADER) { Mat.Cookie9Sided }
        add("cookie-12", "Cookie 12", COOKIES) { Mat.Cookie12Sided }

        // --- Вспышки ---
        add("sunny", "Sunny", BURSTS, LOADER) { Mat.Sunny }
        add("very-sunny", "Very sunny", BURSTS) { Mat.VerySunny }
        add("burst", "Burst", BURSTS) { Mat.Burst }
        add("soft-burst", "Soft burst", BURSTS, LOADER) { Mat.SoftBurst }
        add("boom", "Boom", BURSTS) { Mat.Boom }
        add("soft-boom", "Soft boom", BURSTS) { Mat.SoftBoom }

        // --- Цветы и клеверы ---
        add("clover-4", "Clover 4", FLOWERS) { Mat.Clover4Leaf }
        add("clover-8", "Clover 8", FLOWERS) { Mat.Clover8Leaf }
        add("flower", "Flower", FLOWERS) { Mat.Flower }
        add("puffy", "Puffy", FLOWERS) { Mat.Puffy }
        add("puffy-diamond", "Puffy diamond", FLOWERS) { Mat.PuffyDiamond }

        // --- Особые ---
        add("ghostish", "Ghostish", SPECIAL) { Mat.Ghostish }
        add("bun", "Bun", SPECIAL) { Mat.Bun }
        add("heart", "Heart", SPECIAL) { Mat.Heart }
        add("pixel-circle", "Pixel circle", SPECIAL) { Mat.PixelCircle }
        add("pixel-triangle", "Pixel triangle", SPECIAL) { Mat.PixelTriangle }

        // --- Свои параметрические: звёзды и многоугольники ---
        add("hexagon", "Hexagon", STARS, BASIC) {
            RoundedPolygon(numVertices = 6, rounding = CornerRounding(0.2f))
        }
        add("octagon", "Octagon", STARS) {
            RoundedPolygon(numVertices = 8, rounding = CornerRounding(0.15f))
        }
        add("star-4", "Star 4", STARS) {
            RoundedPolygon.star(4, innerRadius = 0.45f, rounding = CornerRounding(0.15f))
        }
        add("star-5", "Star 5", STARS) {
            RoundedPolygon.star(5, innerRadius = 0.5f, rounding = CornerRounding(0.12f))
        }
        add("star-6", "Star 6", STARS) {
            RoundedPolygon.star(6, innerRadius = 0.55f, rounding = CornerRounding(0.12f))
        }
        add("star-8", "Star 8", STARS) {
            RoundedPolygon.star(8, innerRadius = 0.7f, rounding = CornerRounding(0.1f))
        }
        add("star-12", "Star 12", STARS) {
            RoundedPolygon.star(12, innerRadius = 0.8f, rounding = CornerRounding(0.08f))
        }
    }
}

/**
 * Свои реализации форм MD3 Expressive (аналог androidx.compose.material3.MaterialShapes).
 * Не зависят от Expressive-API material3, поэтому собираются в любом компиляторе.
 * Контуры близки к оригиналам, но не побайтно идентичны; правятся прямо здесь.
 */
private object Mat {
    private fun r(radius: Float, smoothing: Float = 0f) = CornerRounding(radius, smoothing)

    /** Многоугольник из пар координат (x0, y0, x1, y1, ...) с общим или поштучным скруглением. */
    private fun poly(
        pts: FloatArray,
        rounding: CornerRounding = CornerRounding.Unrounded,
        per: List<CornerRounding>? = null,
        rotateDeg: Float = 0f,
    ): RoundedPolygon {
        val v = if (rotateDeg == 0f) pts else rotated(pts, rotateDeg)
        return RoundedPolygon(v, rounding, per)
    }

    private fun rotated(pts: FloatArray, deg: Float): FloatArray {
        var cx = 0f; var cy = 0f
        val n = pts.size / 2
        for (i in 0 until n) { cx += pts[2 * i]; cy += pts[2 * i + 1] }
        cx /= n; cy /= n
        val a = deg * PI.toFloat() / 180f
        val c = cos(a); val s = sin(a)
        return FloatArray(pts.size).also { out ->
            for (i in 0 until n) {
                val dx = pts[2 * i] - cx; val dy = pts[2 * i + 1] - cy
                out[2 * i] = cx + dx * c - dy * s
                out[2 * i + 1] = cy + dx * s + dy * c
            }
        }
    }

    /** Правильный n-угольник, первая вершина смотрит вверх. */
    private fun regular(n: Int, rounding: CornerRounding): RoundedPolygon {
        val pts = FloatArray(n * 2)
        for (i in 0 until n) {
            val a = (-PI / 2 + 2 * PI * i / n).toFloat()
            pts[2 * i] = cos(a); pts[2 * i + 1] = sin(a)
        }
        return RoundedPolygon(pts, rounding)
    }

    private fun rect(w: Float, h: Float, tl: Float, tr: Float, br: Float, bl: Float, rotateDeg: Float = 0f) =
        poly(
            floatArrayOf(0f, 0f, w, 0f, w, h, 0f, h),
            per = listOf(r(tl), r(tr), r(br), r(bl)),
            rotateDeg = rotateDeg,
        )

    private fun pixels(vararg xy: Int): RoundedPolygon =
        RoundedPolygon(FloatArray(xy.size) { xy[it] / 8f })

    // --- Базовые ---
    val Circle get() = RoundedPolygon.circle(numVertices = 10)
    val Square get() = rect(1f, 1f, 0.3f, 0.3f, 0.3f, 0.3f)
    val Slanted get() = poly(floatArrayOf(0.25f, 0f, 1f, 0f, 0.75f, 1f, 0f, 1f), r(0.2f, 0.5f))
    val Arch get() = rect(1f, 1.1f, 0.5f, 0.5f, 0.1f, 0.1f)
    val Fan get() = poly(floatArrayOf(0f, 1f, 1f, 1f, 0f, 0f), per = listOf(r(0.06f), r(0.3f), r(0.45f)))
    val Arrow get() = poly(floatArrayOf(0.5f, 0f, 1f, 1f, 0.5f, 0.72f, 0f, 1f), r(0.1f))
    val SemiCircle get() = rect(1f, 0.55f, 0.04f, 0.04f, 0.5f, 0.5f)
    val Oval get() = poly(floatArrayOf(0f, 0f, 1f, 0f, 1f, 0.62f, 0f, 0.62f), r(0.31f, 1f), rotateDeg = -45f)
    val Pill get() = poly(floatArrayOf(0f, 0f, 1.7f, 0f, 1.7f, 0.7f, 0f, 0.7f), r(0.35f), rotateDeg = -45f)
    val Triangle get() = poly(floatArrayOf(0.5f, 0f, 1f, 0.87f, 0f, 0.87f), r(0.12f, 0.3f))
    val Diamond get() = poly(floatArrayOf(0.5f, 0f, 1f, 0.7f, 0.5f, 1.4f, 0f, 0.7f), r(0.08f, 0.5f))
    val ClamShell get() = rect(1.25f, 1f, 0.45f, 0.45f, 0.2f, 0.2f)
    val Pentagon get() = regular(5, r(0.12f, 0.3f))
    val Gem get() = poly(floatArrayOf(0.25f, 0f, 0.75f, 0f, 1f, 0.4f, 0.5f, 1f, 0f, 0.4f), r(0.07f, 0.3f))

    // --- Печеньки ---
    val Cookie4Sided get() = RoundedPolygon.star(4, innerRadius = 0.7f, rounding = r(0.4f))
    val Cookie6Sided get() = RoundedPolygon.star(6, innerRadius = 0.8f, rounding = r(0.5f))
    val Cookie7Sided get() = RoundedPolygon.star(7, innerRadius = 0.8f, rounding = r(0.5f))
    val Cookie9Sided get() = RoundedPolygon.star(9, innerRadius = 0.8f, rounding = r(0.5f))
    val Cookie12Sided get() = RoundedPolygon.star(12, innerRadius = 0.8f, rounding = r(0.5f))

    // --- Вспышки ---
    val Sunny get() = RoundedPolygon.star(8, innerRadius = 0.8f, rounding = r(0.15f))
    val VerySunny get() = RoundedPolygon.star(8, innerRadius = 0.65f, rounding = r(0.15f))
    val Burst get() = RoundedPolygon.star(12, innerRadius = 0.7f, rounding = r(0.1f))
    val SoftBurst get() = RoundedPolygon.star(10, innerRadius = 0.65f, rounding = r(0.2f), innerRounding = r(0.2f))
    val Boom get() = RoundedPolygon.star(15, innerRadius = 0.55f, rounding = r(0.05f))
    val SoftBoom get() = RoundedPolygon.star(16, innerRadius = 0.7f, rounding = r(0.25f), innerRounding = r(0.1f))

    // --- Цветы и клеверы ---
    val Clover4Leaf get() = RoundedPolygon.star(4, innerRadius = 0.2f, rounding = r(0.4f), innerRounding = r(0.05f))
    val Clover8Leaf get() = RoundedPolygon.star(8, innerRadius = 0.5f, rounding = r(0.4f), innerRounding = r(0.05f))
    val Flower get() = RoundedPolygon.star(8, innerRadius = 0.6f, rounding = r(0.5f), innerRounding = r(0.1f))
    val Puffy get() = RoundedPolygon.star(8, innerRadius = 0.72f, rounding = r(0.5f))
    val PuffyDiamond get() = poly(floatArrayOf(0.5f, 0f, 1f, 0.5f, 0.5f, 1f, 0f, 0.5f), r(0.4f, 1f))

    // --- Особые ---
    val Ghostish get() = poly(
        floatArrayOf(0f, 0f, 1f, 0f, 1f, 1f, 0.75f, 0.8f, 0.5f, 1f, 0.25f, 0.8f, 0f, 1f),
        per = listOf(r(0.5f), r(0.5f), r(0.05f), r(0.05f), r(0.05f), r(0.05f), r(0.05f)),
    )
    val Bun get() = rect(1.3f, 1f, 0.45f, 0.45f, 0.3f, 0.3f)
    val Heart get() = poly(
        floatArrayOf(0.5f, 1f, 0f, 0.38f, 0.25f, 0f, 0.5f, 0.22f, 0.75f, 0f, 1f, 0.38f),
        per = listOf(r(0.04f), r(0.35f), r(0.3f), r(0.05f), r(0.3f), r(0.35f)),
    )
    val PixelCircle get() = pixels(
        2, 0, 6, 0, 6, 1, 7, 1, 7, 2, 8, 2, 8, 6, 7, 6, 7, 7, 6, 7, 6, 8,
        2, 8, 2, 7, 1, 7, 1, 6, 0, 6, 0, 2, 1, 2, 1, 1, 2, 1,
    )
    val PixelTriangle get() = pixels(
        3, 0, 5, 0, 5, 2, 6, 2, 6, 4, 7, 4, 7, 6, 8, 6, 8, 8,
        0, 8, 0, 6, 1, 6, 1, 4, 2, 4, 2, 2, 3, 2,
    )
}
