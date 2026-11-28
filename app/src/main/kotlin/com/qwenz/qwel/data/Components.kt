package com.qwenz.qwel.data

import com.qwenz.qwel.i18n.tr

/** Готовые заготовки MD3-компонентов. Состоят из обычных слоёв с токенами цвета и вставляются одной группой. */
class ComponentDef(
    val id: String,
    val name: String,
    val w: Float,
    val h: Float,
    private val builder: (ox: Float, oy: Float, group: String, tone: Tone) -> List<Node>,
) {
    /** Слои компонента, окрашенные под [tone]; токены сохраняются - при смене тона цвета подстроятся. */
    fun build(ox: Float, oy: Float, group: String, tone: Tone = Tone.Baseline): List<Node> =
        builder(ox, oy, if (group.isEmpty()) group else group + TAG + id, tone)

    companion object {
        /** Разделитель в id группы: после него идёт id заготовки (так экспорт в Compose узнаёт компонент). */
        const val TAG = "~"
    }
}

object Components {
    internal fun rect(t: Tone, name: String, g: String, x: Float, y: Float, w: Float, h: Float, corner: Float,
                     fillTok: Int, strokeTok: Int = -1, sw: Float = 0f) =
        Node(newId(), NodeKind.RECT, name, x, y, w, h,
            fill = if (fillTok >= 0) t.color(fillTok) else 0,
            stroke = if (strokeTok >= 0) t.color(strokeTok) else 0, strokeWidth = sw,
            corner = corner, group = g, fillToken = fillTok, strokeToken = strokeTok)

    internal fun oval(t: Tone, name: String, g: String, x: Float, y: Float, w: Float, h: Float, fillTok: Int) =
        Node(newId(), NodeKind.ELLIPSE, name, x, y, w, h, fill = t.color(fillTok), group = g, fillToken = fillTok)

    /** Текст, центрированный по точке (cx, cy). */
    internal fun label(t: Tone, g: String, text: String, cx: Float, cy: Float, size: Float, weight: Int, tok: Int): Node =
        Node(newId(), NodeKind.TEXT, text, 0f, 0f, 1f, 1f, fill = t.color(tok), text = text,
            fontSize = size, weight = weight, group = g, ratioLock = true, fillToken = tok).withTextSize().let {
            it.copy(x = cx - it.w / 2f, y = cy - it.h / 2f)
        }

    /** Текст, выровненный по левому краю в точке x. */
    internal fun labelLeft(t: Tone, g: String, text: String, x: Float, cy: Float, size: Float, weight: Int, tok: Int): Node =
        label(t, g, text, 0f, cy, size, weight, tok).let { it.copy(x = x) }

    /** Окружность с обводкой без заливки. */
    internal fun ring(t: Tone, name: String, g: String, x: Float, y: Float, d: Float, strokeTok: Int, sw: Float) =
        Node(newId(), NodeKind.ELLIPSE, name, x, y, d, d, fill = 0, stroke = t.color(strokeTok), strokeWidth = sw,
            group = g, strokeToken = strokeTok)

    private fun button(id: String, title: String, container: Int, content: Int, strokeTok: Int = -1): ComponentDef =
        ComponentDef(id, title, 120f, 40f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("container"), g, ox, oy, 120f, 40f, 9999f, container, strokeTok, if (strokeTok >= 0) 1f else 0f),
                label(t, g, "Button", ox + 60f, oy + 20f, 14f, 500, content),
            )
        }

    private val classic: List<ComponentDef> = listOf(
        button("btn-filled", "Filled button", Tok.PRIMARY, Tok.ON_PRIMARY),
        button("btn-tonal", "Tonal button", Tok.SECONDARY_CONTAINER, Tok.ON_SECONDARY_CONTAINER),
        button("btn-outlined", "Outlined button", -1, Tok.PRIMARY, Tok.OUTLINE),
        ComponentDef("fab", "FAB", 56f, 56f) { ox, oy, g, t ->
            listOf(
                rect(t, "FAB", g, ox, oy, 56f, 56f, 16f, Tok.PRIMARY_CONTAINER),
                rect(t, tr("plus_h"), g, ox + 16f, oy + 27f, 24f, 2f, 1f, Tok.ON_PRIMARY_CONTAINER),
                rect(t, tr("plus_v"), g, ox + 27f, oy + 16f, 2f, 24f, 1f, Tok.ON_PRIMARY_CONTAINER),
            )
        },
        ComponentDef("ext-fab", "Extended FAB", 140f, 56f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("container"), g, ox, oy, 140f, 56f, 16f, Tok.PRIMARY_CONTAINER),
                label(t, g, tr("create"), ox + 70f, oy + 28f, 14f, 500, Tok.ON_PRIMARY_CONTAINER),
            )
        },
        ComponentDef("card", "Card (filled)", 328f, 120f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("card"), g, ox, oy, 328f, 120f, 12f, Tok.SURFACE_HIGHEST),
                labelLeft(t, g, tr("title"), ox + 16f, oy + 28f, 16f, 500, Tok.ON_SURFACE),
                labelLeft(t, g, tr("supporting_text"), ox + 16f, oy + 52f, 14f, 400, Tok.ON_SURFACE_VARIANT),
            )
        },
        ComponentDef("chip", "Chip", 96f, 32f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("chip"), g, ox, oy, 96f, 32f, 8f, -1, Tok.OUTLINE_VARIANT, 1f).w("chip:bg"),
                label(t, g, "Filter", ox + 48f, oy + 16f, 14f, 500, Tok.ON_SURFACE_VARIANT).w("chip:label"),
            )
        },
        ComponentDef("switch", "Switch", 52f, 32f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("track"), g, ox, oy, 52f, 32f, 9999f, Tok.PRIMARY).w("switch:track"),
                oval(t, tr("thumb"), g, ox + 24f, oy + 4f, 24f, 24f, Tok.ON_PRIMARY).w("switch:thumb"),
            )
        },
        ComponentDef("textfield", "Outlined text field", 280f, 56f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("field"), g, ox, oy, 280f, 56f, 4f, -1, Tok.OUTLINE, 1f).w("focus:box"),
                labelLeft(t, g, "Label", ox + 16f, oy + 28f, 16f, 400, Tok.ON_SURFACE_VARIANT).w("focus:label"),
            )
        },
        ComponentDef("top-bar", "Top app bar", 360f, 64f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("background"), g, ox, oy, 360f, 64f, 0f, Tok.SURFACE),
                labelLeft(t, g, tr("title"), ox + 64f, oy + 32f, 22f, 400, Tok.ON_SURFACE),
            ) + IconNodes.menu(t, g, ox + 28f, oy + 32f, Tok.ON_SURFACE)
        },
        ComponentDef("nav-bar", "Navigation bar", 360f, 80f) { ox, oy, g, t ->
            val out = ArrayList<Node>()
            out += rect(t, tr("background"), g, ox, oy, 360f, 80f, 0f, Tok.SURFACE_CONTAINER)
            out += rect(t, tr("indicator"), g, ox + 28f, oy + 12f, 64f, 32f, 9999f, Tok.SECONDARY_CONTAINER).w("pick:ind")
            val names = listOf(tr("home"), tr("search"), tr("profile"))
            val icons = listOf("home", "search", "person")
            for (i in 0 until 3) {
                val cx = ox + 60f + i * 120f
                out += IconNodes.icon(t, icons[i], g, cx, oy + 28f, 24f, if (i == 0) Tok.ON_SECONDARY_CONTAINER else Tok.ON_SURFACE_VARIANT)
                    .pick(i, Tok.ON_SECONDARY_CONTAINER, Tok.ON_SURFACE_VARIANT)
                out += label(t, g, names[i], cx, oy + 58f, 12f, if (i == 0) 700 else 500,
                    if (i == 0) Tok.ON_SURFACE else Tok.ON_SURFACE_VARIANT).pick(i, Tok.ON_SURFACE, Tok.ON_SURFACE_VARIANT)
            }
            out
        },
        ComponentDef("radio", "Radio button", 24f, 24f) { ox, oy, g, t ->
            listOf(
                ring(t, tr("ring"), g, ox + 2f, oy + 2f, 20f, Tok.PRIMARY, 2f).w("radio:ring"),
                oval(t, tr("dot"), g, ox + 7f, oy + 7f, 10f, 10f, Tok.PRIMARY).w("radio:dot"),
            )
        },
        ComponentDef("checkbox", "Checkbox", 24f, 24f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("box"), g, ox + 3f, oy + 3f, 18f, 18f, 2f, Tok.PRIMARY).w("check:box"),
                rect(t, tr("check_1"), g, ox + 7f, oy + 12f, 6f, 2f, 1f, Tok.ON_PRIMARY).copy(rotation = 45f).w("check:mark"),
                rect(t, tr("check_2"), g, ox + 9.5f, oy + 11f, 9f, 2f, 1f, Tok.ON_PRIMARY).copy(rotation = -50f).w("check:mark"),
            )
        },
        ComponentDef("slider", "Slider", 280f, 20f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("track"), g, ox, oy + 8f, 280f, 4f, 9999f, Tok.SECONDARY_CONTAINER).w("slider:track"),
                rect(t, tr("active_part"), g, ox, oy + 8f, 150f, 4f, 9999f, Tok.PRIMARY).w("slider:active"),
                oval(t, tr("slider"), g, ox + 140f, oy, 20f, 20f, Tok.PRIMARY).w("slider:thumb"),
            )
        },
        ComponentDef("progress", "Linear progress", 280f, 4f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("track"), g, ox, oy, 280f, 4f, 9999f, Tok.SECONDARY_CONTAINER).w("progress:track"),
                rect(t, tr("progress"), g, ox, oy, 168f, 4f, 9999f, Tok.PRIMARY).w("progress:active"),
            )
        },
        ComponentDef("divider", "Divider", 328f, 1f) { ox, oy, g, t ->
            listOf(rect(t, tr("divider"), g, ox, oy, 328f, 1f, 0f, Tok.OUTLINE_VARIANT))
        },
        ComponentDef("badge", "Badge", 16f, 16f) { ox, oy, g, t ->
            listOf(
                oval(t, tr("badge"), g, ox, oy, 16f, 16f, Tok.ERROR),
                label(t, g, "3", ox + 8f, oy + 8f, 10f, 500, Tok.ON_PRIMARY),
            )
        },
        ComponentDef("search", "Search bar", 328f, 56f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("search"), g, ox, oy, 328f, 56f, 9999f, Tok.SURFACE_HIGH),
                ring(t, tr("lens"), g, ox + 16f, oy + 17f, 16f, Tok.ON_SURFACE_VARIANT, 2f),
                rect(t, tr("lens_handle"), g, ox + 30f, oy + 33f, 8f, 2f, 1f, Tok.ON_SURFACE_VARIANT).copy(rotation = 45f),
                labelLeft(t, g, tr("search"), ox + 52f, oy + 28f, 16f, 400, Tok.ON_SURFACE_VARIANT),
            )
        },
        ComponentDef("list-item", "List item", 360f, 72f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("background"), g, ox, oy, 360f, 72f, 0f, Tok.SURFACE),
                oval(t, tr("avatar"), g, ox + 16f, oy + 16f, 40f, 40f, Tok.PRIMARY_CONTAINER),
                labelLeft(t, g, tr("title"), ox + 72f, oy + 28f, 16f, 400, Tok.ON_SURFACE),
                labelLeft(t, g, tr("supporting_text"), ox + 72f, oy + 48f, 14f, 400, Tok.ON_SURFACE_VARIANT),
            )
        },
        ComponentDef("tabs", "Tabs", 360f, 48f) { ox, oy, g, t ->
            val out = ArrayList<Node>()
            out += rect(t, tr("background"), g, ox, oy, 360f, 48f, 0f, Tok.SURFACE)
            out += rect(t, tr("line"), g, ox, oy + 47f, 360f, 1f, 0f, Tok.OUTLINE_VARIANT)
            val names = listOf(tr("first"), tr("second"), tr("third"))
            for (i in 0 until 3) {
                out += label(t, g, names[i], ox + 60f + i * 120f, oy + 22f, 14f, 500,
                    if (i == 0) Tok.PRIMARY else Tok.ON_SURFACE_VARIANT).pick(i, Tok.PRIMARY, Tok.ON_SURFACE_VARIANT)
            }
            out += rect(t, tr("indicator"), g, ox + 20f, oy + 45f, 80f, 3f, 1.5f, Tok.PRIMARY).w("pick:ind")
            out
        },
        ComponentDef("segmented", "Segmented button", 288f, 40f) { ox, oy, g, t ->
            val out = ArrayList<Node>()
            out += rect(t, tr("outline"), g, ox, oy, 288f, 40f, 9999f, -1, Tok.OUTLINE, 1f)
            out += rect(t, tr("selected"), g, ox + 1f, oy + 1f, 95f, 38f, 9999f, Tok.SECONDARY_CONTAINER).w("pick:fit")
            val names = listOf(tr("day"), tr("week"), tr("month"))
            for (i in 0 until 3) {
                out += label(t, g, names[i], ox + 48f + i * 96f, oy + 20f, 14f, 500,
                    if (i == 0) Tok.ON_SECONDARY_CONTAINER else Tok.ON_SURFACE).pick(i, Tok.ON_SECONDARY_CONTAINER, Tok.ON_SURFACE)
            }
            out
        },
        ComponentDef("snackbar", "Snackbar", 328f, 48f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("background"), g, ox, oy, 328f, 48f, 4f, Tok.INVERSE_SURFACE),
                labelLeft(t, g, tr("message"), ox + 16f, oy + 24f, 14f, 400, Tok.SURFACE),
                label(t, g, tr("cancel"), ox + 280f, oy + 24f, 14f, 500, Tok.PRIMARY_CONTAINER),
            )
        },
        ComponentDef("dialog", "Dialog", 312f, 192f) { ox, oy, g, t ->
            listOf(
                rect(t, tr("window"), g, ox, oy, 312f, 192f, 28f, Tok.SURFACE_HIGH),
                labelLeft(t, g, tr("title"), ox + 24f, oy + 40f, 24f, 400, Tok.ON_SURFACE),
                labelLeft(t, g, tr("dialog_text"), ox + 24f, oy + 80f, 14f, 400, Tok.ON_SURFACE_VARIANT),
                label(t, g, tr("cancel"), ox + 200f, oy + 156f, 14f, 500, Tok.PRIMARY),
                label(t, g, tr("ok"), ox + 270f, oy + 156f, 14f, 500, Tok.PRIMARY),
            )
        },
    )

    /** Все заготовки: классические MD3 и заготовки в духе Material 3 Expressive. */
    val all: List<ComponentDef> = classic + ExpressiveComponents.list

    private val byId: Map<String, ComponentDef> by lazy { all.associateBy { it.id } }

    /** Разделы панели 'Компоненты': ключ раздела и идентификаторы заготовок в нужном порядке. */
    private val groupIds = listOf(
        "actions" to listOf("btn-filled", "btn-tonal", "btn-outlined", "btn-elevated", "btn-text", "btn-m", "btn-l", "btn-xl", "btn-square",
            "btn-morph", "btn-morph-square", "btn-morph-tonal",
            "icon-btn", "icon-btn-tonal", "icon-btn-outlined", "icon-btn-square", "fab", "ext-fab", "fab-small", "fab-large", "fab-menu",
            "split-button", "button-group", "toolbar-floating"),
        "navigation" to listOf("top-bar", "top-bar-center", "top-bar-medium", "top-bar-large", "nav-bar", "nav-bar-flex", "bottom-bar",
            "nav-rail", "nav-drawer", "tabs", "search", "menu"),
        "containment" to listOf("card", "card-elevated", "card-outlined", "card-media", "card-expressive", "bottom-sheet", "carousel",
            "list-item", "list-3line", "list-segmented", "list-switch", "list-checkbox", "dialog", "divider", "avatar-stack", "stat-card"),
        "communication" to listOf("snackbar", "tooltip", "badge", "badge-large", "loading", "progress", "progress-circular", "progress-wavy", "banner"),
        "selection" to listOf("chip", "chip-filter", "chip-assist", "chip-input", "segmented", "switch", "switch-off", "switch-icon",
            "checkbox", "checkbox-off", "radio", "radio-off", "slider", "slider-expressive", "slider-wavy", "date-picker"),
        "inputs" to listOf("textfield", "textfield-filled", "textfield-error", "quantity"),
    )

    val groups: List<Pair<String, List<ComponentDef>>> by lazy {
        val placed = HashSet<String>()
        val out = groupIds.map { (key, ids) -> key to ids.mapNotNull { byId[it] }.also { l -> placed += l.map { it.id } } }
        // всё, что не попало в разделы, показываем в конце, чтобы заготовка не потерялась
        val rest = all.filter { it.id !in placed }
        if (rest.isEmpty()) out else out + ("actions" to rest)
    }
}
