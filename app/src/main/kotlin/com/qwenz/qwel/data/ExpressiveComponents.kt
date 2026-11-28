package com.qwenz.qwel.data

import com.qwenz.qwel.i18n.tr
import java.util.Locale
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

/**
 * Заготовки в духе Material 3 Expressive: крупные размеры кнопок, большие скругления, группы кнопок,
 * плавающая панель инструментов, меню FAB, волнистый индикатор, индикатор загрузки из формы и т.д.
 * Как и остальные, состоят из обычных слоёв с токенами цвета.
 */
object ExpressiveComponents {
    private fun rect(t: Tone, name: String, g: String, x: Float, y: Float, w: Float, h: Float, corner: Float,
                     fillTok: Int, strokeTok: Int = -1, sw: Float = 0f) =
        Components.rect(t, name, g, x, y, w, h, corner, fillTok, strokeTok, sw)

    private fun oval(t: Tone, name: String, g: String, x: Float, y: Float, w: Float, h: Float, fillTok: Int) =
        Components.oval(t, name, g, x, y, w, h, fillTok)

    private fun ring(t: Tone, name: String, g: String, x: Float, y: Float, d: Float, strokeTok: Int, sw: Float) =
        Components.ring(t, name, g, x, y, d, strokeTok, sw)

    private fun label(t: Tone, g: String, text: String, cx: Float, cy: Float, size: Float, weight: Int, tok: Int) =
        Components.label(t, g, text, cx, cy, size, weight, tok)

    private fun labelLeft(t: Tone, g: String, text: String, x: Float, cy: Float, size: Float, weight: Int, tok: Int) =
        Components.labelLeft(t, g, text, x, cy, size, weight, tok)

    /** Слой с мягкой тенью (карточки и плавающие панели). */
    private fun Node.shadowed(blur: Float = 8f, dy: Float = 2f) = copy(shadowBlur = blur, shadowDy = dy, shadowColor = 0x33000000)

    private fun plus(t: Tone, g: String, cx: Float, cy: Float, size: Float, thick: Float, tok: Int) = listOf(
        rect(t, tr("plus_h"), g, cx - size / 2f, cy - thick / 2f, size, thick, thick / 2f, tok),
        rect(t, tr("plus_v"), g, cx - thick / 2f, cy - size / 2f, thick, size, thick / 2f, tok),
    )

    private fun cross(t: Tone, g: String, cx: Float, cy: Float, size: Float, tok: Int) = listOf(
        rect(t, tr("check_1"), g, cx - size / 2f, cy - 1f, size, 2f, 1f, tok).copy(rotation = 45f),
        rect(t, tr("check_2"), g, cx - size / 2f, cy - 1f, size, 2f, 1f, tok).copy(rotation = -45f),
    )

    /** Галочка в квадрате 24 x 24 с левым верхним углом (x, y). */
    private fun check(t: Tone, g: String, x: Float, y: Float, tok: Int) = listOf(
        rect(t, tr("check_1"), g, x + 7f, y + 12f, 6f, 2f, 1f, tok).copy(rotation = 45f),
        rect(t, tr("check_2"), g, x + 9.5f, y + 11f, 9f, 2f, 1f, tok).copy(rotation = -50f),
    )

    private fun chevronDown(t: Tone, g: String, cx: Float, cy: Float, tok: Int) = listOf(
        rect(t, tr("check_1"), g, cx - 6.8f, cy - 1.5f, 8f, 2f, 1f, tok).copy(rotation = 45f),
        rect(t, tr("check_2"), g, cx - 1.2f, cy - 1.5f, 8f, 2f, 1f, tok).copy(rotation = -45f),
    )

    private fun iconDot(t: Tone, g: String, cx: Float, cy: Float, tok: Int, d: Float = 18f) =
        oval(t, tr("icon"), g, cx - d / 2f, cy - d / 2f, d, d, tok)

    private fun bars(t: Tone, g: String, x: Float, cy: Float, tok: Int) = IconNodes.menu(t, g, x + 12f, cy, tok)

    private fun icon(t: Tone, g: String, name: String, cx: Float, cy: Float, tok: Int, d: Float = 24f) =
        IconNodes.icon(t, name, g, cx, cy, d, tok)

    private fun num(v: Float) = String.format(Locale.US, "%.4f", v)

    /** Ломаная в единичном квадрате (формат слоя PATH). */
    private fun polyline(points: List<Pair<Float, Float>>): String {
        val sb = StringBuilder()
        points.forEachIndexed { i, (px, py) -> sb.append(if (i == 0) "M " else "L ").append(num(px)).append(' ').append(num(py)).append(' ') }
        return sb.toString().trim()
    }

    private fun strokePath(t: Tone, name: String, g: String, x: Float, y: Float, w: Float, h: Float, path: String, tok: Int, sw: Float) =
        Node(newId(), NodeKind.PATH, name, x, y, w, h, fill = 0, stroke = t.color(tok), strokeWidth = sw, path = path, group = g, strokeToken = tok)

    private fun shape(t: Tone, name: String, g: String, shapeId: String, x: Float, y: Float, d: Float, tok: Int) =
        Node(newId(), NodeKind.SHAPE, name, x, y, d, d, fill = t.color(tok), shapeId = shapeId, group = g, fillToken = tok, ratioLock = true)

    private fun def(id: String, name: String, w: Float, h: Float, b: (Float, Float, String, Tone) -> List<Node>) =
        ComponentDef(id, name, w, h, b)

    /** Кнопка заданной высоты с полностью скруглёнными краями (или [corner]). */
    private fun sizedButton(id: String, title: String, w: Float, h: Float, text: Float, corner: Float = 9999f) =
        def(id, title, w, h) { ox, oy, g, t ->
            listOf(
                rect(t, tr("container"), g, ox, oy, w, h, corner, Tok.PRIMARY),
                label(t, g, "Button", ox + w / 2f, oy + h / 2f, text, 600, Tok.ON_PRIMARY),
            )
        }

    private fun iconButton(id: String, title: String, fillTok: Int, glyphTok: Int, outline: Boolean = false, corner: Float = 9999f) =
        def(id, title, 40f, 40f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("container"), g, ox, oy, 40f, 40f, corner, if (outline) -1 else fillTok, if (outline) Tok.OUTLINE else -1, if (outline) 1f else 0f))
                addAll(plus(t, g, ox + 20f, oy + 20f, 16f, 2f, glyphTok))
            }
        }

    private fun listRow(t: Tone, g: String, x: Float, y: Float, w: Float, h: Float, corner: Float, bgTok: Int, title: String, sub: String): List<Node> = listOf(
        rect(t, tr("container"), g, x, y, w, h, corner, bgTok),
        oval(t, tr("avatar"), g, x + 16f, y + (h - 40f) / 2f, 40f, 40f, Tok.PRIMARY_CONTAINER),
        labelLeft(t, g, title, x + 72f, y + h / 2f - 10f, 16f, 500, Tok.ON_SURFACE),
        labelLeft(t, g, sub, x + 72f, y + h / 2f + 12f, 14f, 400, Tok.ON_SURFACE_VARIANT),
    )

    val list: List<ComponentDef> = listOf(
        // ---- действия
        def("btn-elevated", "Elevated button", 120f, 40f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("container"), g, ox, oy, 120f, 40f, 9999f, Tok.SURFACE_LOW).shadowed(6f, 2f),
                label(t, g, "Button", ox + 60f, oy + 20f, 14f, 500, Tok.PRIMARY),
            )
        },
        def("btn-text", "Text button", 100f, 40f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("container"), g, ox, oy, 100f, 40f, 9999f, -1),
                label(t, g, "Button", ox + 50f, oy + 20f, 14f, 500, Tok.PRIMARY),
            )
        },
        sizedButton("btn-m", "Button M (56)", 160f, 56f, 16f),
        sizedButton("btn-l", "Button L (96)", 220f, 96f, 24f),
        sizedButton("btn-xl", "Button XL (136)", 300f, 136f, 32f),
        sizedButton("btn-square", "Button M (square)", 160f, 56f, 16f, corner = 16f),
        def("btn-morph", "Button (pill to square on press)", 160f, 56f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("container"), g, ox, oy, 160f, 56f, 9999f, Tok.PRIMARY).copy(pressCorner = 12f),
                label(t, g, "Button", ox + 80f, oy + 28f, 16f, 600, Tok.ON_PRIMARY),
            )
        },
        def("btn-morph-square", "Button (square to circle on press)", 72f, 72f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("container"), g, ox, oy, 72f, 72f, 16f, Tok.PRIMARY).copy(pressCorner = 36f))
                addAll(plus(t, g, ox + 36f, oy + 36f, 24f, 3f, Tok.ON_PRIMARY))
            }
        },
        def("btn-morph-tonal", "Button (circle to square on press)", 72f, 72f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("container"), g, ox, oy, 72f, 72f, 36f, Tok.SECONDARY_CONTAINER).copy(pressCorner = 16f))
                addAll(plus(t, g, ox + 36f, oy + 36f, 24f, 3f, Tok.ON_SECONDARY_CONTAINER))
            }
        },
        iconButton("icon-btn", "Icon button", Tok.PRIMARY, Tok.ON_PRIMARY),
        iconButton("icon-btn-tonal", "Icon button (tonal)", Tok.SECONDARY_CONTAINER, Tok.ON_SECONDARY_CONTAINER),
        iconButton("icon-btn-outlined", "Icon button (outlined)", -1, Tok.ON_SURFACE_VARIANT, outline = true),
        iconButton("icon-btn-square", "Icon button (square)", Tok.PRIMARY, Tok.ON_PRIMARY, corner = 12f),
        def("fab-small", "Small FAB", 40f, 40f) { ox, oy, g, t ->
            buildList {
                add(rect(t, "FAB", g, ox, oy, 40f, 40f, 12f, Tok.PRIMARY_CONTAINER))
                addAll(plus(t, g, ox + 20f, oy + 20f, 16f, 2f, Tok.ON_PRIMARY_CONTAINER))
            }
        },
        def("fab-large", "Large FAB", 96f, 96f) { ox, oy, g, t ->
            buildList {
                add(rect(t, "FAB", g, ox, oy, 96f, 96f, 28f, Tok.PRIMARY_CONTAINER).shadowed(10f, 3f))
                addAll(plus(t, g, ox + 48f, oy + 48f, 36f, 4f, Tok.ON_PRIMARY_CONTAINER))
            }
        },
        def("fab-menu", "FAB menu", 200f, 248f) { ox, oy, g, t ->
            buildList {
                for (i in 0 until 3) {
                    val y = oy + i * 64f
                    add(rect(t, tr("menu_item"), g, ox, y, 200f, 56f, 9999f, Tok.PRIMARY_CONTAINER).w("reveal:item"))
                    addAll(icon(t, g, listOf("edit", "share", "bookmark")[i], ox + 32f, y + 28f, Tok.ON_PRIMARY_CONTAINER).map { it.w("reveal:item") })
                    add(labelLeft(t, g, tr("menu_item"), ox + 60f, y + 28f, 16f, 500, Tok.ON_PRIMARY_CONTAINER).w("reveal:item"))
                }
                add(rect(t, "FAB", g, ox + 144f, oy + 192f, 56f, 56f, 9999f, Tok.PRIMARY).shadowed(8f, 2f))
                addAll(cross(t, g, ox + 172f, oy + 220f, 22f, Tok.ON_PRIMARY))
            }
        },
        def("split-button", "Split button", 152f, 40f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("container"), g, ox, oy, 102f, 40f, 9999f, Tok.PRIMARY))
                add(rect(t, tr("container"), g, ox + 62f, oy, 40f, 40f, 4f, Tok.PRIMARY))
                add(label(t, g, "Save", ox + 48f, oy + 20f, 14f, 500, Tok.ON_PRIMARY))
                add(rect(t, tr("container"), g, ox + 104f, oy, 48f, 40f, 9999f, Tok.PRIMARY))
                add(rect(t, tr("container"), g, ox + 104f, oy, 24f, 40f, 4f, Tok.PRIMARY))
                addAll(chevronDown(t, g, ox + 128f, oy + 21f, Tok.ON_PRIMARY))
            }
        },
        def("button-group", "Button group (connected)", 304f, 40f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("container"), g, ox, oy, 304f, 40f, 9999f, Tok.SECONDARY_CONTAINER))
                add(rect(t, tr("selected"), g, ox + 102f, oy, 100f, 40f, 9999f, Tok.PRIMARY).w("pick:fit"))
                add(label(t, g, tr("day"), ox + 50f, oy + 20f, 14f, 500, Tok.ON_SECONDARY_CONTAINER).pick(0, Tok.ON_PRIMARY, Tok.ON_SECONDARY_CONTAINER))
                add(label(t, g, tr("week"), ox + 152f, oy + 20f, 14f, 600, Tok.ON_PRIMARY).pick(1, Tok.ON_PRIMARY, Tok.ON_SECONDARY_CONTAINER))
                add(label(t, g, tr("month"), ox + 254f, oy + 20f, 14f, 500, Tok.ON_SECONDARY_CONTAINER).pick(2, Tok.ON_PRIMARY, Tok.ON_SECONDARY_CONTAINER))
            }
        },
        def("toolbar-floating", "Floating toolbar", 300f, 64f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("container"), g, ox, oy, 232f, 64f, 9999f, Tok.SURFACE_HIGH).shadowed(10f, 3f))
                for (i in 0 until 4) addAll(icon(t, g, listOf("edit", "share", "bookmark", "more_vert")[i], ox + 40f + i * 51f, oy + 32f,
                    if (i == 0) Tok.PRIMARY else Tok.ON_SURFACE_VARIANT).pick(i, Tok.PRIMARY, Tok.ON_SURFACE_VARIANT))
                add(rect(t, "FAB", g, ox + 244f, oy + 4f, 56f, 56f, 16f, Tok.PRIMARY_CONTAINER))
                addAll(plus(t, g, ox + 272f, oy + 32f, 22f, 2f, Tok.ON_PRIMARY_CONTAINER))
            }
        },

        // ---- навигация
        def("top-bar-center", "Top app bar (centered)", 360f, 64f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("background"), g, ox, oy, 360f, 64f, 0f, Tok.SURFACE))
                addAll(bars(t, g, ox + 16f, oy + 32f, Tok.ON_SURFACE))
                add(label(t, g, tr("title"), ox + 180f, oy + 32f, 22f, 500, Tok.ON_SURFACE))
                addAll(icon(t, g, "more_vert", ox + 332f, oy + 32f, Tok.ON_SURFACE_VARIANT))
            }
        },
        def("top-bar-medium", "Top app bar (medium)", 360f, 112f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("background"), g, ox, oy, 360f, 112f, 0f, Tok.SURFACE_CONTAINER))
                addAll(bars(t, g, ox + 16f, oy + 32f, Tok.ON_SURFACE))
                addAll(icon(t, g, "more_vert", ox + 332f, oy + 32f, Tok.ON_SURFACE_VARIANT))
                add(labelLeft(t, g, tr("title"), ox + 16f, oy + 84f, 24f, 600, Tok.ON_SURFACE))
            }
        },
        def("top-bar-large", "Top app bar (large)", 360f, 152f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("background"), g, ox, oy, 360f, 152f, 0f, Tok.SURFACE_CONTAINER))
                addAll(bars(t, g, ox + 16f, oy + 32f, Tok.ON_SURFACE))
                addAll(icon(t, g, "more_vert", ox + 332f, oy + 32f, Tok.ON_SURFACE_VARIANT))
                add(labelLeft(t, g, tr("title"), ox + 16f, oy + 118f, 32f, 600, Tok.ON_SURFACE))
            }
        },
        def("nav-bar-flex", "Navigation bar (flexible)", 360f, 64f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("background"), g, ox, oy, 360f, 64f, 0f, Tok.SURFACE_CONTAINER))
                // выбранный пункт широкий (136) с иконкой и подписью, остальные узкие (72) только с иконкой
                fun slot(j: Int, sel: Int): Float = 40f + (0 until j).sumOf { (if (it == sel) 136 else 72).toDouble() }.toFloat()
                fun fmt(v: Float) = String.format(Locale.US, "%.2f", v)
                add(rect(t, tr("indicator"), g, ox + slot(0, 0) + 4f, oy + 12f, 128f, 40f, 9999f, Tok.SECONDARY_CONTAINER)
                    .w("pick:ind/" + (0 until 3).joinToString(";") { fmt(slot(it, it) + 4f) }))
                val names = listOf(tr("home"), tr("search"), tr("profile"))
                val icons = listOf("home", "search", "person")
                for (j in 0 until 3) {
                    // центр иконки пункта j при выборе k
                    fun iconC(k: Int) = if (j == k) slot(j, k) + 4f + 32f else slot(j, k) + 36f
                    val ic = icon(t, g, icons[j], ox + iconC(0), oy + 32f, if (j == 0) Tok.ON_SECONDARY_CONTAINER else Tok.ON_SURFACE_VARIANT)
                    for (n in ic) add(n.copy(widget = "pick:i$j/${Tok.ON_SECONDARY_CONTAINER}/${Tok.ON_SURFACE_VARIANT}/" +
                        (0 until 3).joinToString(";") { k -> fmt(n.x - ox + iconC(k) - iconC(0)) }))
                    val lb = labelLeft(t, g, names[j], ox + slot(j, 0) + 4f + 56f, oy + 32f, 13f, 700, Tok.ON_SECONDARY_CONTAINER)
                    add(lb.copy(opacity = if (j == 0) 1f else 0f, widget = "pick:i$j/${Tok.ON_SECONDARY_CONTAINER}/${Tok.ON_SURFACE_VARIANT}/" +
                        (0 until 3).joinToString(";") { k -> fmt(slot(j, k) + 4f + 56f) } + "/f"))
                }
            }
        },
        def("bottom-bar", "Bottom app bar", 360f, 80f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("background"), g, ox, oy, 360f, 80f, 0f, Tok.SURFACE_CONTAINER))
                for (i in 0 until 3) addAll(icon(t, g, listOf("menu", "search", "favorite")[i], ox + 40f + i * 56f, oy + 40f,
                    if (i == 0) Tok.PRIMARY else Tok.ON_SURFACE_VARIANT).pick(i, Tok.PRIMARY, Tok.ON_SURFACE_VARIANT))
                add(rect(t, "FAB", g, ox + 284f, oy + 12f, 56f, 56f, 16f, Tok.PRIMARY_CONTAINER))
                addAll(plus(t, g, ox + 312f, oy + 40f, 22f, 2f, Tok.ON_PRIMARY_CONTAINER))
            }
        },
        def("nav-rail", "Navigation rail", 80f, 360f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("background"), g, ox, oy, 80f, 360f, 0f, Tok.SURFACE))
                add(rect(t, "FAB", g, ox + 12f, oy + 16f, 56f, 56f, 16f, Tok.PRIMARY_CONTAINER))
                addAll(plus(t, g, ox + 40f, oy + 44f, 22f, 2f, Tok.ON_PRIMARY_CONTAINER))
                val names = listOf(tr("home"), tr("search"), tr("profile"))
                for (i in 0 until 3) {
                    val top = oy + 104f + i * 84f
                    if (i == 0) add(rect(t, tr("indicator"), g, ox + 12f, top, 56f, 32f, 9999f, Tok.SECONDARY_CONTAINER).w("pick:ind"))
                    addAll(icon(t, g, listOf("home", "search", "person")[i], ox + 40f, top + 16f,
                        if (i == 0) Tok.ON_SECONDARY_CONTAINER else Tok.ON_SURFACE_VARIANT).pick(i, Tok.ON_SECONDARY_CONTAINER, Tok.ON_SURFACE_VARIANT))
                    add(label(t, g, names[i], ox + 40f, top + 44f, 12f, if (i == 0) 700 else 500, if (i == 0) Tok.ON_SURFACE else Tok.ON_SURFACE_VARIANT)
                        .pick(i, Tok.ON_SURFACE, Tok.ON_SURFACE_VARIANT))
                }
            }
        },
        def("nav-drawer", "Navigation drawer", 360f, 300f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("container"), g, ox, oy, 360f, 300f, 16f, Tok.SURFACE_LOW))
                add(labelLeft(t, g, tr("title"), ox + 28f, oy + 40f, 14f, 500, Tok.ON_SURFACE_VARIANT))
                val names = listOf(tr("home"), tr("search"), tr("profile"))
                for (i in 0 until 3) {
                    val y = oy + 68f + i * 60f
                    if (i == 0) add(rect(t, tr("indicator"), g, ox + 12f, y, 336f, 56f, 9999f, Tok.SECONDARY_CONTAINER).w("pick:ind"))
                    addAll(icon(t, g, listOf("home", "search", "person")[i], ox + 40f, y + 28f,
                        if (i == 0) Tok.ON_SECONDARY_CONTAINER else Tok.ON_SURFACE_VARIANT).pick(i, Tok.ON_SECONDARY_CONTAINER, Tok.ON_SURFACE_VARIANT))
                    add(labelLeft(t, g, names[i], ox + 68f, y + 28f, 14f, 500, if (i == 0) Tok.ON_SECONDARY_CONTAINER else Tok.ON_SURFACE_VARIANT)
                        .pick(i, Tok.ON_SECONDARY_CONTAINER, Tok.ON_SURFACE_VARIANT))
                }
            }
        },

        // ---- контейнеры
        def("card-elevated", "Card (elevated)", 328f, 120f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("card"), g, ox, oy, 328f, 120f, 12f, Tok.SURFACE_LOW).shadowed(8f, 2f),
                labelLeft(t, g, tr("title"), ox + 16f, oy + 28f, 16f, 500, Tok.ON_SURFACE),
                labelLeft(t, g, tr("supporting_text"), ox + 16f, oy + 52f, 14f, 400, Tok.ON_SURFACE_VARIANT),
            )
        },
        def("card-outlined", "Card (outlined)", 328f, 120f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("card"), g, ox, oy, 328f, 120f, 12f, Tok.SURFACE, Tok.OUTLINE_VARIANT, 1f),
                labelLeft(t, g, tr("title"), ox + 16f, oy + 28f, 16f, 500, Tok.ON_SURFACE),
                labelLeft(t, g, tr("supporting_text"), ox + 16f, oy + 52f, 14f, 400, Tok.ON_SURFACE_VARIANT),
            )
        },
        def("card-media", "Card (media)", 328f, 300f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("card"), g, ox, oy, 328f, 300f, 28f, Tok.SURFACE_LOW))
                add(rect(t, tr("media"), g, ox + 8f, oy + 8f, 312f, 170f, 20f, Tok.TERTIARY_CONTAINER))
                add(shape(t, tr("media"), g, "cookie-9", ox + 116f, oy + 41f, 96f, Tok.ON_TERTIARY_CONTAINER))
                add(labelLeft(t, g, tr("title"), ox + 20f, oy + 208f, 22f, 600, Tok.ON_SURFACE))
                add(labelLeft(t, g, tr("supporting_text"), ox + 20f, oy + 236f, 14f, 400, Tok.ON_SURFACE_VARIANT))
                add(rect(t, tr("container"), g, ox + 20f, oy + 254f, 96f, 36f, 9999f, Tok.PRIMARY))
                add(label(t, g, "Button", ox + 68f, oy + 272f, 14f, 500, Tok.ON_PRIMARY))
            }
        },
        def("card-expressive", "Card (expressive)", 328f, 160f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("card"), g, ox, oy, 328f, 160f, 48f, Tok.PRIMARY_CONTAINER),
                shape(t, tr("media"), g, "flower", ox + 220f, oy + 20f, 96f, Tok.TERTIARY_CONTAINER),
                labelLeft(t, g, tr("title"), ox + 28f, oy + 100f, 28f, 700, Tok.ON_PRIMARY_CONTAINER),
                labelLeft(t, g, tr("supporting_text"), ox + 28f, oy + 130f, 14f, 400, Tok.ON_PRIMARY_CONTAINER),
            )
        },
        def("bottom-sheet", "Bottom sheet", 360f, 240f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("container"), g, ox, oy, 360f, 240f, 28f, Tok.SURFACE_LOW).shadowed(12f, -2f))
                add(rect(t, tr("handle"), g, ox + 164f, oy + 12f, 32f, 4f, 2f, Tok.ON_SURFACE_VARIANT))
                add(labelLeft(t, g, tr("title"), ox + 24f, oy + 48f, 22f, 500, Tok.ON_SURFACE))
                for (i in 0 until 2) {
                    addAll(icon(t, g, listOf("share", "delete")[i], ox + 36f, oy + 100f + i * 56f, Tok.ON_SURFACE_VARIANT))
                    add(labelLeft(t, g, tr("menu_item"), ox + 68f, oy + 100f + i * 56f, 16f, 400, Tok.ON_SURFACE))
                }
            }
        },
        def("carousel", "Carousel", 360f, 160f) { ox, oy, g, t ->
            buildList {
                // пункт k главный: широкий (224), два следующих узкие (56), остальные свёрнуты; крайние положения считаем заранее
                fun cardX(j: Int, k: Int): Float = if (j <= k) 0f else if (j - k <= 2) 232f + (j - k - 1) * 64f else 360f
                fun cardW(j: Int, k: Int): Float = if (j < k) 0f else if (j == k) 224f else if (j - k <= 2) 56f else 0f
                fun fmt(v: Float) = String.format(Locale.US, "%.2f", v)
                val tokens = listOf(Tok.PRIMARY_CONTAINER, Tok.SECONDARY_CONTAINER, Tok.TERTIARY_CONTAINER, Tok.SURFACE_HIGHEST, Tok.PRIMARY_CONTAINER)
                val onTokens = listOf(Tok.ON_PRIMARY_CONTAINER, Tok.ON_SECONDARY_CONTAINER, Tok.ON_TERTIARY_CONTAINER, Tok.ON_SURFACE, Tok.ON_PRIMARY_CONTAINER)
                for (j in 0 until 5) {
                    val role = "pick:i$j/${tokens[j]}/${tokens[j]}/" + (0 until 5).joinToString(";") { fmt(cardX(j, it)) } +
                        "/w=" + (0 until 5).joinToString(";") { fmt(cardW(j, it)) }
                    add(rect(t, tr("card"), g, ox + cardX(j, 0), oy, cardW(j, 0), 160f, 28f, tokens[j]).copy(widget = role))
                    val lb = label(t, g, tr("title"), 0f, oy + 80f, 22f, 600, onTokens[j])
                    fun lx(k: Int) = minOf(cardX(j, k) + 112f - lb.w / 2f, 360f - lb.w)
                    add(lb.copy(x = ox + lx(0), opacity = if (j == 0) 1f else 0f,
                        widget = "pick:i$j/${onTokens[j]}/${onTokens[j]}/" + (0 until 5).joinToString(";") { fmt(lx(it)) } + "/f"))
                }
            }
        },
        def("list-3line", "List item (3 lines)", 360f, 88f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("background"), g, ox, oy, 360f, 88f, 0f, Tok.SURFACE),
                oval(t, tr("avatar"), g, ox + 16f, oy + 16f, 40f, 40f, Tok.PRIMARY_CONTAINER),
                labelLeft(t, g, tr("title"), ox + 72f, oy + 24f, 16f, 500, Tok.ON_SURFACE),
                labelLeft(t, g, tr("supporting_text"), ox + 72f, oy + 46f, 14f, 400, Tok.ON_SURFACE_VARIANT),
                labelLeft(t, g, tr("supporting_text"), ox + 72f, oy + 64f, 14f, 400, Tok.ON_SURFACE_VARIANT),
            )
        },
        def("list-segmented", "List (segmented)", 360f, 220f) { ox, oy, g, t ->
            buildList {
                for (i in 0 until 3) addAll(listRow(t, g, ox, oy + i * 74f, 360f, 72f, if (i == 1) 8f else 24f, Tok.SURFACE_CONTAINER, tr("title"), tr("supporting_text")))
            }
        },

        // ---- обратная связь
        def("tooltip", "Tooltip", 120f, 32f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("container"), g, ox, oy, 120f, 32f, 8f, Tok.INVERSE_SURFACE),
                label(t, g, tr("message"), ox + 60f, oy + 16f, 12f, 500, Tok.SURFACE),
            )
        },
        def("badge-large", "Badge (large)", 28f, 16f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("badge"), g, ox, oy, 28f, 16f, 9999f, Tok.ERROR),
                label(t, g, "99+", ox + 14f, oy + 8f, 10f, 600, Tok.ON_PRIMARY),
            )
        },
        def("loading", "Loading indicator", 48f, 48f) { ox, oy, g, t ->
            listOf(
                oval(t, tr("container"), g, ox, oy, 48f, 48f, Tok.SECONDARY_CONTAINER),
                shape(t, tr("indicator"), g, "cookie-9", ox + 8f, oy + 8f, 32f, Tok.PRIMARY).w("spin:rot"),
            )
        },
        def("progress-circular", "Circular progress", 48f, 48f) { ox, oy, g, t ->
            listOf(
                ring(t, tr("track"), g, ox + 4f, oy + 4f, 40f, Tok.SECONDARY_CONTAINER, 4f),
                strokePath(t, tr("arc"), g, ox + 4f, oy + 4f, 40f, 40f, PlayMode.arcPath(0.75f), Tok.PRIMARY, 4f).w("progress:arc"),
            )
        },
        def("progress-wavy", "Wavy progress", 280f, 16f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("track"), g, ox + 176f, oy + 6f, 104f, 4f, 2f, Tok.SECONDARY_CONTAINER).w("progress:track"),
                strokePath(t, tr("wave"), g, ox, oy + 2f, 168f, 12f, PlayMode.wavePath(168f), Tok.PRIMARY, 4f).w("progress:active"),
                oval(t, tr("dot"), g, ox + 274f, oy + 6f, 4f, 4f, Tok.PRIMARY),
            )
        },

        // ---- выбор
        def("chip-filter", "Filter chip (selected)", 104f, 32f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("chip"), g, ox, oy, 104f, 32f, 8f, Tok.SECONDARY_CONTAINER).w("chip:bg"))
                addAll(check(t, g, ox + 4f, oy + 4f, Tok.ON_SECONDARY_CONTAINER).map { it.w("chip:mark") })
                add(label(t, g, "Filter", ox + 62f, oy + 16f, 14f, 500, Tok.ON_SECONDARY_CONTAINER).w("chip:label"))
            }
        },
        def("chip-assist", "Assist chip", 104f, 32f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("chip"), g, ox, oy, 104f, 32f, 8f, -1, Tok.OUTLINE_VARIANT, 1f),
                *icon(t, g, "event", ox + 18f, oy + 16f, Tok.PRIMARY, 18f).toTypedArray(),
                label(t, g, "Assist", ox + 62f, oy + 16f, 14f, 500, Tok.ON_SURFACE),
            )
        },
        def("chip-input", "Input chip", 112f, 32f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("chip"), g, ox, oy, 112f, 32f, 8f, -1, Tok.OUTLINE_VARIANT, 1f))
                add(label(t, g, "Input", ox + 42f, oy + 16f, 14f, 500, Tok.ON_SURFACE_VARIANT))
                addAll(cross(t, g, ox + 92f, oy + 16f, 12f, Tok.ON_SURFACE_VARIANT))
            }
        },
        def("switch-off", "Switch (off)", 52f, 32f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("track"), g, ox + 1f, oy + 1f, 50f, 30f, 9999f, Tok.SURFACE_HIGHEST, Tok.OUTLINE, 2f).w("switch:track"),
                oval(t, tr("thumb"), g, ox + 8f, oy + 8f, 16f, 16f, Tok.OUTLINE).w("switch:thumb"),
            )
        },
        def("switch-icon", "Switch (with icon)", 52f, 32f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("track"), g, ox, oy, 52f, 32f, 9999f, Tok.PRIMARY).w("switch:track"))
                add(oval(t, tr("thumb"), g, ox + 24f, oy + 4f, 24f, 24f, Tok.ON_PRIMARY).w("switch:thumb"))
                addAll(check(t, g, ox + 24f, oy + 4f, Tok.PRIMARY).map { it.w("switch:icon") })
            }
        },
        def("checkbox-off", "Checkbox (off)", 24f, 24f) { ox, oy, g, t ->
            listOf(rect(t, tr("box"), g, ox + 3f, oy + 3f, 18f, 18f, 2f, -1, Tok.ON_SURFACE_VARIANT, 2f).w("check:box"))
        },
        def("radio-off", "Radio button (off)", 24f, 24f) { ox, oy, g, t ->
            listOf(ring(t, tr("ring"), g, ox + 2f, oy + 2f, 20f, Tok.ON_SURFACE_VARIANT, 2f).w("radio:ring"))
        },
        def("slider-expressive", "Slider (expressive)", 300f, 44f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("track"), g, ox + 180f, oy + 2f, 120f, 40f, 12f, Tok.SECONDARY_CONTAINER).w("slider:track"),
                rect(t, tr("active_part"), g, ox, oy + 2f, 168f, 40f, 12f, Tok.PRIMARY).w("slider:active"),
                rect(t, tr("handle"), g, ox + 172f, oy, 4f, 44f, 2f, Tok.PRIMARY).w("slider:thumb"),
            )
        },

        def("slider-wavy", "Slider (wavy)", 300f, 44f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("track"), g, ox + 182f, oy + 20f, 118f, 4f, 2f, Tok.SECONDARY_CONTAINER).w("slider:track"),
                strokePath(t, tr("wave"), g, ox, oy + 14f, 164f, 16f, PlayMode.wavePath(164f), Tok.PRIMARY, 4f).w("slider:active"),
                rect(t, tr("handle"), g, ox + 172f, oy + 6f, 4f, 32f, 2f, Tok.PRIMARY).w("slider:thumb"),
            )
        },

        def("menu", "Menu", 200f, 160f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("container"), g, ox, oy, 200f, 160f, 12f, Tok.SURFACE_CONTAINER).shadowed(12f, 4f))
                add(rect(t, tr("selected"), g, ox + 8f, oy + 8f, 184f, 48f, 8f, Tok.SECONDARY_CONTAINER).w("pick:ind"))
                for (i in 0 until 3) {
                    val y = oy + 32f + i * 48f
                    val on = i == 0
                    addAll(icon(t, g, listOf("edit", "share", "delete")[i], ox + 32f, y,
                        if (on) Tok.ON_SECONDARY_CONTAINER else Tok.ON_SURFACE_VARIANT, 20f).pick(i, Tok.ON_SECONDARY_CONTAINER, Tok.ON_SURFACE_VARIANT))
                    add(labelLeft(t, g, tr("menu_item"), ox + 56f, y, 16f, 400,
                        if (on) Tok.ON_SECONDARY_CONTAINER else Tok.ON_SURFACE).pick(i, Tok.ON_SECONDARY_CONTAINER, Tok.ON_SURFACE))
                }
            }
        },
        def("date-picker", "Date picker", 328f, 384f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("container"), g, ox, oy, 328f, 384f, 28f, Tok.SURFACE_HIGH))
                add(labelLeft(t, g, tr("cal_month"), ox + 24f, oy + 32f, 16f, 500, Tok.ON_SURFACE))
                for (i in 0 until 7) add(label(t, g, tr("wd_${i + 1}"), ox + 32f + i * 44f, oy + 76f, 12f, 500, Tok.ON_SURFACE_VARIANT))
                val selected = 13
                add(oval(t, tr("selected"), g, ox + 32f + ((6 + selected) % 7) * 44f - 20f, oy + 114f + ((6 + selected) / 7) * 44f - 20f, 40f, 40f, Tok.PRIMARY).w("pick:ind"))
                for (d in 0 until 30) {
                    val cell = 6 + d
                    add(label(t, g, "${d + 1}", ox + 32f + (cell % 7) * 44f, oy + 114f + (cell / 7) * 44f, 14f, 400,
                        if (d == selected) Tok.ON_PRIMARY else Tok.ON_SURFACE).pick(d, Tok.ON_PRIMARY, Tok.ON_SURFACE))
                }
            }
        },
        def("banner", "Banner", 360f, 104f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("container"), g, ox, oy, 360f, 104f, 0f, Tok.SURFACE_LOW))
                add(oval(t, tr("avatar"), g, ox + 16f, oy + 16f, 40f, 40f, Tok.PRIMARY_CONTAINER))
                addAll(icon(t, g, "info", ox + 36f, oy + 36f, Tok.ON_PRIMARY_CONTAINER))
                add(labelLeft(t, g, tr("banner_title"), ox + 72f, oy + 28f, 16f, 500, Tok.ON_SURFACE))
                add(labelLeft(t, g, tr("banner_body"), ox + 72f, oy + 52f, 14f, 400, Tok.ON_SURFACE_VARIANT))
                add(label(t, g, tr("cancel"), ox + 262f, oy + 84f, 14f, 500, Tok.PRIMARY))
                add(label(t, g, tr("more"), ox + 326f, oy + 84f, 14f, 500, Tok.PRIMARY))
            }
        },
        def("quantity", "Quantity stepper", 120f, 40f) { ox, oy, g, t ->
            buildList {
                add(rect(t, tr("container"), g, ox, oy, 120f, 40f, 9999f, -1, Tok.OUTLINE, 1f))
                add(rect(t, tr("minus"), g, ox + 14f, oy + 19f, 12f, 2f, 1f, Tok.ON_SURFACE))
                add(label(t, g, "1", ox + 60f, oy + 20f, 16f, 500, Tok.ON_SURFACE).w("counter:label"))
                addAll(plus(t, g, ox + 100f, oy + 20f, 12f, 2f, Tok.ON_SURFACE))
            }
        },
        def("list-switch", "List item (switch)", 360f, 72f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("background"), g, ox, oy, 360f, 72f, 0f, Tok.SURFACE),
                labelLeft(t, g, tr("title"), ox + 16f, oy + 28f, 16f, 400, Tok.ON_SURFACE),
                labelLeft(t, g, tr("supporting_text"), ox + 16f, oy + 49f, 14f, 400, Tok.ON_SURFACE_VARIANT),
                rect(t, tr("track"), g, ox + 292f, oy + 20f, 52f, 32f, 9999f, Tok.PRIMARY).w("switch:track"),
                oval(t, tr("thumb"), g, ox + 316f, oy + 24f, 24f, 24f, Tok.ON_PRIMARY).w("switch:thumb"),
            )
        },
        def("list-checkbox", "List item (checkbox)", 360f, 56f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("background"), g, ox, oy, 360f, 56f, 0f, Tok.SURFACE),
                rect(t, tr("box"), g, ox + 19f, oy + 19f, 18f, 18f, 2f, -1, Tok.ON_SURFACE_VARIANT, 2f).w("check:box"),
                labelLeft(t, g, tr("title"), ox + 60f, oy + 28f, 16f, 400, Tok.ON_SURFACE),
            )
        },
        def("textfield-error", "Text field (error)", 280f, 80f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("field"), g, ox, oy, 280f, 56f, 4f, -1, Tok.ERROR, 2f).w("focus:box/err"),
                labelLeft(t, g, "Email", ox + 16f, oy + 28f, 16f, 400, Tok.ERROR),
                labelLeft(t, g, tr("field_error"), ox + 16f, oy + 70f, 12f, 400, Tok.ERROR),
            )
        },
        def("avatar-stack", "Avatar stack", 124f, 40f) { ox, oy, g, t ->
            listOf(
                oval(t, tr("avatar"), g, ox, oy, 40f, 40f, Tok.PRIMARY_CONTAINER),
                oval(t, tr("avatar"), g, ox + 28f, oy, 40f, 40f, Tok.TERTIARY_CONTAINER),
                oval(t, tr("avatar"), g, ox + 56f, oy, 40f, 40f, Tok.SECONDARY_CONTAINER),
                oval(t, tr("avatar"), g, ox + 84f, oy, 40f, 40f, Tok.SURFACE_HIGHEST),
                label(t, g, "+5", ox + 104f, oy + 20f, 13f, 600, Tok.ON_SURFACE),
            )
        },
        def("stat-card", "Stat card", 160f, 120f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("card"), g, ox, oy, 160f, 120f, 28f, Tok.SURFACE_HIGH),
                labelLeft(t, g, tr("revenue"), ox + 20f, oy + 32f, 14f, 400, Tok.ON_SURFACE_VARIANT),
                labelLeft(t, g, tr("revenue_value"), ox + 20f, oy + 68f, 28f, 600, Tok.ON_SURFACE),
                rect(t, tr("chip"), g, ox + 20f, oy + 84f, 56f, 24f, 9999f, Tok.PRIMARY_CONTAINER),
                label(t, g, "+12%", ox + 48f, oy + 96f, 12f, 600, Tok.ON_PRIMARY_CONTAINER),
            )
        },

        // ---- ввод текста
        def("textfield-filled", "Filled text field", 280f, 56f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("field"), g, ox, oy, 280f, 56f, 4f, Tok.SURFACE_HIGHEST),
                rect(t, tr("line"), g, ox, oy + 54f, 280f, 2f, 0f, Tok.ON_SURFACE_VARIANT).w("focus:line"),
                labelLeft(t, g, "Label", ox + 16f, oy + 28f, 16f, 400, Tok.ON_SURFACE_VARIANT).w("focus:label"),
            )
        },
    )
}
