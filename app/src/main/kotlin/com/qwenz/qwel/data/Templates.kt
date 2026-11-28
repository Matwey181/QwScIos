package com.qwenz.qwel.data

import com.qwenz.qwel.i18n.tr

/** Шаблон проекта: готовый экран из слоёв и компонентов, который можно переделать под себя. */
class ProjectTemplate(
    val id: String,
    val name: String,
    val description: String,
    val width: Float,
    val height: Float,
    private val builder: (Tone) -> List<Node>,
) {
    fun build(tone: Tone): List<Node> = builder(tone)

    /** Готовый проект на основе шаблона. */
    fun toProject(name: String, tone: Tone, now: Long = System.currentTimeMillis()): Project =
        Project(newId(), name, width, height, tone.color(Tok.SURFACE), build(tone), now, now, tone, Tok.SURFACE)
}

object Templates {
    // ---------------------------------------------------------------- кирпичики

    private fun text(t: Tone, s: String, x: Float, cy: Float, size: Float, weight: Int, tok: Int): Node =
        Node(newId(), NodeKind.TEXT, s.lineSequence().first().take(24), 0f, 0f, 1f, 1f, fill = t.color(tok), text = s,
            fontSize = size, weight = weight, ratioLock = true, fillToken = tok).withTextSize().let {
            it.copy(x = x, y = cy - it.h / 2f)
        }

    private fun center(t: Tone, s: String, cx: Float, cy: Float, size: Float, weight: Int, tok: Int): Node =
        text(t, s, 0f, cy, size, weight, tok).let { it.copy(x = cx - it.w / 2f) }

    private fun rect(t: Tone, name: String, x: Float, y: Float, w: Float, h: Float, corner: Float, tok: Int,
                     strokeTok: Int = -1, sw: Float = 0f): Node =
        Node(newId(), NodeKind.RECT, name, x, y, w, h, fill = if (tok >= 0) t.color(tok) else 0,
            stroke = if (strokeTok >= 0) t.color(strokeTok) else 0, strokeWidth = sw, corner = corner,
            fillToken = tok, strokeToken = strokeTok)

    private fun circle(t: Tone, name: String, x: Float, y: Float, d: Float, tok: Int): Node =
        Node(newId(), NodeKind.ELLIPSE, name, x, y, d, d, fill = t.color(tok), fillToken = tok)

    private fun shape(t: Tone, id: String, name: String, x: Float, y: Float, w: Float, h: Float, tok: Int, rot: Float = 0f): Node =
        Node(newId(), NodeKind.SHAPE, name, x, y, w, h, rotation = rot, fill = t.color(tok), shapeId = id,
            ratioLock = true, fillToken = tok)

    private fun ringShape(t: Tone, name: String, x: Float, y: Float, d: Float, tok: Int, sw: Float): Node =
        Node(newId(), NodeKind.ELLIPSE, name, x, y, d, d, fill = 0, stroke = t.color(tok), strokeWidth = sw, strokeToken = tok)

    /** Пузырь сообщения: входящие слева, исходящие справа. */
    private fun bubble(t: Tone, msg: String, incoming: Boolean, y: Float, w: Float): List<Node> {
        val x = if (incoming) 56f else 344f - w
        val bg = if (incoming) Tok.SURFACE_HIGHEST else Tok.PRIMARY
        val fg = if (incoming) Tok.ON_SURFACE else Tok.ON_PRIMARY
        val out = ArrayList<Node>()
        if (incoming) out += circle(t, tr("avatar"), 16f, y + 4f, 32f, Tok.TERTIARY_CONTAINER)
        out += rect(t, tr("message"), x, y, w, 44f, 22f, bg)
        out += text(t, msg, x + 16f, y + 22f, 15f, 400, fg)
        return out
    }

    /** Плитка с выключателем: в режиме 'Играть' нажатие меняет и положение выключателя, и фон плитки. */
    private fun switchCard(t: Tone, title: String, ic: String, x: Float, y: Float, on: Boolean): List<Node> {
        val sw = comp(t, if (on) "switch" else "switch-off", x + 20f, y + 76f)
        val g = sw.first().group
        val bg = rect(t, tr("card"), x, y, 156f, 124f, 28f, if (on) Tok.PRIMARY_CONTAINER else Tok.SURFACE_HIGH).copy(group = g, widget = "switch:bg")
        val label = text(t, title, x + 20f, y + 32f, 16f, 500, if (on) Tok.ON_PRIMARY_CONTAINER else Tok.ON_SURFACE).copy(group = g, widget = "switch:title")
        val icon = ico(t, ic, x + 128f, y + 32f, 24f, if (on) Tok.ON_PRIMARY_CONTAINER else Tok.ON_SURFACE).map { it.copy(group = g, widget = "switch:title") }
        return listOf(bg, label) + icon + sw
    }

    /** Слои одной кнопки или карточки собираются в группу, чтобы в режиме 'Играть' они откликались вместе. */
    private fun List<Node>.grp(): List<Node> { val g = newId(); return map { it.copy(group = g) } }

    /** Настоящая иконка (если набор установлен) или кружок; несколько слоёв иконки собираются в группу. */
    private fun ico(t: Tone, name: String, cx: Float, cy: Float, size: Float, tok: Int, fill: Boolean = false): List<Node> {
        val l = IconNodes.icon(t, name, "", cx, cy, size, tok, fill)
        if (l.size < 2) return l
        val g = newId()
        return l.map { it.copy(group = g) }
    }

    /** Круглая кнопка-FAB с иконкой. */
    private fun fabIcon(t: Tone, x: Float, y: Float, name: String, size: Float = 56f): List<Node> =
        listOf(rect(t, "FAB", x, y, size, size, size * 0.29f, Tok.PRIMARY_CONTAINER)) + ico(t, name, x + size / 2f, y + size / 2f, size * 0.43f, Tok.ON_PRIMARY_CONTAINER)

    /** Расширенный FAB: иконка и подпись. */
    private fun extFab(t: Tone, x: Float, y: Float, name: String, label: String): List<Node> {
        val tx = text(t, label, 0f, y + 28f, 16f, 500, Tok.ON_PRIMARY_CONTAINER)
        val w = 16f + 24f + 12f + tx.w + 20f
        return listOf(rect(t, "FAB", x, y, w, 56f, 16f, Tok.PRIMARY_CONTAINER)) +
            ico(t, name, x + 16f + 12f, y + 28f, 24f, Tok.ON_PRIMARY_CONTAINER) + tx.copy(x = x + 52f)
    }

    /** Компонент по id, левый верхний угол в (x, y). Слои компонента остаются группой. */
    private fun comp(t: Tone, id: String, x: Float, y: Float): List<Node> =
        Components.all.first { it.id == id }.build(x, y, newId(), t)

    // ---------------------------------------------------------------- шаблоны

    val all: List<ProjectTemplate> = listOf(
        ProjectTemplate("login", tr("tpl_login"), tr("tpl_login_desc"), 360f, 800f) { t ->
            val n = ArrayList<Node>()
            n += shape(t, "cookie-9", tr("logo"), 136f, 80f, 88f, 88f, Tok.PRIMARY_CONTAINER)
            n += ico(t, "lock", 180f, 124f, 36f, Tok.ON_PRIMARY_CONTAINER)
            n += center(t, tr("welcome"), 180f, 212f, 28f, 600, Tok.ON_SURFACE)
            n += center(t, tr("sign_in_to_continue"), 180f, 244f, 14f, 400, Tok.ON_SURFACE_VARIANT)
            n += comp(t, "textfield-filled", 40f, 292f).map { it.rename("Email") }
            n += comp(t, "textfield-filled", 40f, 364f).map { it.rename(tr("password")) }
            n += ico(t, "visibility", 292f, 392f, 24f, Tok.ON_SURFACE_VARIANT)
            n += comp(t, "checkbox-off", 36f, 440f)
            n += text(t, tr("t_remember"), 68f, 452f, 14f, 400, Tok.ON_SURFACE)
            n += text(t, tr("forgot_password"), 212f, 452f, 14f, 500, Tok.PRIMARY)
            n += listOf(rect(t, tr("button"), 40f, 496f, 280f, 56f, 9999f, Tok.PRIMARY),
                center(t, tr("sign_in"), 180f, 524f, 16f, 500, Tok.ON_PRIMARY)).grp()
            n += rect(t, tr("line"), 40f, 592f, 112f, 1f, 0f, Tok.OUTLINE_VARIANT)
            n += center(t, tr("t_or"), 180f, 592f, 14f, 400, Tok.ON_SURFACE_VARIANT)
            n += rect(t, tr("line"), 208f, 592f, 112f, 1f, 0f, Tok.OUTLINE_VARIANT)
            n += listOf(rect(t, tr("button"), 40f, 624f, 280f, 56f, 9999f, -1, Tok.OUTLINE, 1f),
                center(t, tr("t_google"), 180f, 652f, 16f, 500, Tok.ON_SURFACE)).grp()
            n += center(t, tr("no_account"), 180f, 740f, 14f, 400, Tok.ON_SURFACE_VARIANT)
            n
        },
        ProjectTemplate("home", tr("home"), tr("tpl_feed_desc"), 360f, 800f) { t ->
            val n = ArrayList<Node>()
            n += text(t, tr("t_hello"), 16f, 64f, 14f, 400, Tok.ON_SURFACE_VARIANT)
            n += text(t, tr("t_discover"), 16f, 96f, 28f, 600, Tok.ON_SURFACE)
            n += ico(t, "notifications", 328f, 76f, 28f, Tok.ON_SURFACE_VARIANT)
            n += comp(t, "search", 16f, 128f)
            n += ico(t, "search", 44f, 156f, 24f, Tok.ON_SURFACE_VARIANT)
            n += comp(t, "chip-filter", 16f, 200f).map { it.rename(tr("t_cat_1")) }
            n += comp(t, "chip-assist", 128f, 200f).map { it.rename(tr("t_cat_2")) }
            n += comp(t, "chip-assist", 240f, 200f).map { it.rename(tr("t_cat_3")) }
            for (i in 0 until 3) {
                val y = 252f + i * 136f
                val card = ArrayList<Node>()
                card += rect(t, tr("card_n", i + 1), 16f, y, 328f, 120f, 28f, Tok.SURFACE_HIGHEST)
                card += shape(t, listOf("soft-burst", "cookie-9", "sunny")[i], tr("preview_n", i + 1), 28f, y + 14f, 92f, 92f,
                    listOf(Tok.PRIMARY_CONTAINER, Tok.TERTIARY_CONTAINER, Tok.SECONDARY_CONTAINER)[i])
                card += text(t, tr("title_n", i + 1), 136f, y + 38f, 16f, 500, Tok.ON_SURFACE)
                card += text(t, tr("card_short_desc"), 136f, y + 62f, 14f, 400, Tok.ON_SURFACE_VARIANT)
                card += text(t, tr("more"), 136f, y + 94f, 14f, 500, Tok.PRIMARY)
                card += ico(t, "favorite", 320f, y + 28f, 22f, Tok.ON_SURFACE_VARIANT)
                n += card.grp()
            }
            n += fabIcon(t, 288f, 652f, "add").grp()
            n += comp(t, "nav-bar", 0f, 720f)
            n
        },
        ProjectTemplate("music", tr("tpl_music"), tr("tpl_music_desc"), 360f, 800f) { t ->
            val n = ArrayList<Node>()
            n += center(t, tr("t_now_playing"), 180f, 68f, 14f, 500, Tok.ON_SURFACE_VARIANT)
            n += rect(t, tr("t_cover"), 32f, 100f, 296f, 296f, 56f, Tok.PRIMARY_CONTAINER)
            n += shape(t, "cookie-9", tr("shape"), 90f, 158f, 180f, 180f, Tok.PRIMARY)
            n += text(t, tr("t_song"), 32f, 436f, 24f, 600, Tok.ON_SURFACE)
            n += text(t, tr("t_artist"), 32f, 470f, 16f, 400, Tok.ON_SURFACE_VARIANT)
            n += comp(t, "slider-wavy", 30f, 504f)
            n += text(t, "1:24", 32f, 568f, 12f, 400, Tok.ON_SURFACE_VARIANT)
            val end = text(t, "3:48", 0f, 568f, 12f, 400, Tok.ON_SURFACE_VARIANT)
            n += end.copy(x = 328f - end.w)
            n += ico(t, "favorite", 312f, 452f, 28f, Tok.PRIMARY)
            n += ico(t, "arrow_back", 32f, 68f, 24f, Tok.ON_SURFACE)
            n += ico(t, "more_vert", 328f, 68f, 24f, Tok.ON_SURFACE)
            // назад / пуск / вперёд
            n += (listOf(circle(t, tr("button"), 40f, 620f, 64f, Tok.SECONDARY_CONTAINER)) +
                ico(t, "skip_previous", 72f, 652f, 32f, Tok.ON_SECONDARY_CONTAINER, true)).grp()
            n += (listOf(rect(t, tr("button"), 132f, 604f, 96f, 96f, 32f, Tok.PRIMARY)) +
                ico(t, "play_arrow", 180f, 652f, 48f, Tok.ON_PRIMARY, true)).grp()
            n += (listOf(circle(t, tr("button"), 256f, 620f, 64f, Tok.SECONDARY_CONTAINER)) +
                ico(t, "skip_next", 288f, 652f, 32f, Tok.ON_SECONDARY_CONTAINER, true)).grp()
            n += comp(t, "toolbar-floating", 30f, 724f)
            n
        },
        ProjectTemplate("weather", tr("tpl_weather"), tr("tpl_weather_desc"), 360f, 800f) { t ->
            val n = ArrayList<Node>()
            val city = center(t, tr("t_city"), 180f, 72f, 20f, 500, Tok.ON_SURFACE)
            n += city
            n += ico(t, "location_on", city.x - 18f, 72f, 24f, Tok.PRIMARY)
            n += shape(t, "sunny", tr("t_sun"), 100f, 108f, 160f, 160f, Tok.TERTIARY_CONTAINER)
            val temp = center(t, "24", 180f, 330f, 80f, 300, Tok.ON_SURFACE)
            n += temp
            n += ringShape(t, tr("t_degree"), temp.x + temp.w + 4f, temp.y + 14f, 14f, Tok.ON_SURFACE, 3f)
            n += center(t, tr("t_clear"), 180f, 392f, 16f, 400, Tok.ON_SURFACE_VARIANT)
            for (i in 0 until 5) {
                val x = 16f + i * 66f
                val hc = ArrayList<Node>()
                hc += rect(t, tr("card_n", i + 1), x, 428f, 58f, 104f, 29f, if (i == 0) Tok.PRIMARY_CONTAINER else Tok.SURFACE_HIGH)
                hc += center(t, "${12 + i * 3}:00", x + 29f, 450f, 12f, 500, Tok.ON_SURFACE_VARIANT)
                hc += ico(t, listOf("sunny", "partly_cloudy_day", "cloud", "rainy", "partly_cloudy_day")[i], x + 29f, 478f, 26f, if (i == 0) Tok.PRIMARY else Tok.ON_SURFACE_VARIANT)
                hc += center(t, "${24 - i}", x + 29f, 512f, 16f, 600, Tok.ON_SURFACE)
                n += hc.grp()
            }
            n += rect(t, tr("card"), 16f, 556f, 328f, 204f, 28f, Tok.SURFACE_HIGH)
            val days = listOf(tr("t_today"), tr("t_tomorrow"), tr("t_day_after"))
            for ((i, d) in days.withIndex()) {
                val y = 556f + 34f + i * 66f
                n += text(t, d, 36f, y, 16f, 500, Tok.ON_SURFACE)
                n += ico(t, listOf("sunny", "partly_cloudy_day", "rainy")[i], 180f, y, 28f, Tok.PRIMARY)
                n += text(t, "${24 - i * 2} / ${15 - i}", 270f, y, 16f, 400, Tok.ON_SURFACE_VARIANT)
            }
            n
        },
        ProjectTemplate("chat", tr("tpl_chat"), tr("tpl_chat_desc"), 360f, 800f) { t ->
            val n = ArrayList<Node>()
            n += comp(t, "top-bar", 0f, 36f).map { it.rename(tr("t_chat_name")) }
            n += ico(t, "call", 296f, 68f, 24f, Tok.ON_SURFACE_VARIANT)
            n += ico(t, "more_vert", 332f, 68f, 24f, Tok.ON_SURFACE_VARIANT)
            val msgs = listOf(
                Triple("t_msg_1", true, 224f), Triple("t_msg_2", false, 232f), Triple("t_msg_3", true, 188f), Triple("t_msg_4", false, 156f),
                Triple("t_msg_5", true, 256f), Triple("t_msg_6", false, 212f), Triple("t_msg_7", true, 176f), Triple("t_msg_8", false, 244f),
            )
            for ((i, m) in msgs.withIndex()) n += bubble(t, tr(m.first), m.second, 128f + i * 68f, m.third).grp()
            n += (listOf(rect(t, tr("field"), 16f, 724f, 260f, 56f, 28f, Tok.SURFACE_HIGH),
                text(t, tr("t_message_hint"), 36f, 752f, 15f, 400, Tok.ON_SURFACE_VARIANT)) +
                ico(t, "attach_file", 248f, 752f, 24f, Tok.ON_SURFACE_VARIANT)).grp()
            n += fabIcon(t, 288f, 724f, "send").grp()
            n
        },
        ProjectTemplate("fitness", tr("tpl_fitness"), tr("tpl_fitness_desc"), 360f, 800f) { t ->
            val n = ArrayList<Node>()
            n += text(t, tr("t_today"), 16f, 76f, 32f, 600, Tok.ON_SURFACE)
            n += comp(t, "card-expressive", 16f, 112f).map { if (it.kind == NodeKind.TEXT) it.rename(if (it.fontSize > 20f) tr("t_steps_value") else tr("t_steps")) else it }
            n += (listOf(rect(t, tr("card"), 16f, 292f, 160f, 120f, 28f, Tok.SECONDARY_CONTAINER)) +
                ico(t, "local_fire_department", 148f, 324f, 28f, Tok.ON_SECONDARY_CONTAINER, true) +
                listOf(text(t, "482", 36f, 346f, 32f, 600, Tok.ON_SECONDARY_CONTAINER), text(t, tr("t_kcal"), 36f, 382f, 14f, 400, Tok.ON_SECONDARY_CONTAINER))).grp()
            n += (listOf(rect(t, tr("card"), 184f, 292f, 160f, 120f, 28f, Tok.TERTIARY_CONTAINER)) +
                ico(t, "directions_walk", 316f, 324f, 28f, Tok.ON_TERTIARY_CONTAINER, true) +
                listOf(text(t, "7,4", 204f, 346f, 32f, 600, Tok.ON_TERTIARY_CONTAINER), text(t, tr("t_km"), 204f, 382f, 14f, 400, Tok.ON_TERTIARY_CONTAINER))).grp()
            val goals = listOf(tr("t_goal_move"), tr("t_goal_water"), tr("t_goal_sleep"))
            for ((i, g) in goals.withIndex()) {
                val y = 452f + i * 72f
                n += ico(t, listOf("directions_run", "water_drop", "bedtime")[i], 52f, y, 22f, Tok.PRIMARY)
                n += text(t, g, 72f, y, 14f, 500, Tok.ON_SURFACE)
                n += comp(t, "progress-wavy", 40f, y + 22f)
            }
            n += extFab(t, 204f, 696f, "play_arrow", tr("t_start")).grp()
            n
        },
        ProjectTemplate("cart", tr("tpl_cart"), tr("tpl_cart_desc"), 360f, 800f) { t ->
            val n = ArrayList<Node>()
            n += comp(t, "top-bar", 0f, 36f).map { it.rename(tr("t_cart")) }
            for (i in 0 until 3) {
                val y = 116f + i * 120f
                val item = ArrayList<Node>()
                item += rect(t, tr("card_n", i + 1), 16f, y, 328f, 108f, 24f, Tok.SURFACE_HIGH)
                item += shape(t, listOf("cookie-9", "flower", "soft-burst")[i], tr("preview_n", i + 1), 28f, y + 18f, 72f, 72f,
                    listOf(Tok.PRIMARY_CONTAINER, Tok.TERTIARY_CONTAINER, Tok.SECONDARY_CONTAINER)[i])
                item += text(t, tr("title_n", i + 1), 116f, y + 26f, 16f, 500, Tok.ON_SURFACE)
                item += text(t, "${(i + 1) * 1290} RUB", 116f, y + 50f, 14f, 400, Tok.ON_SURFACE_VARIANT)
                item += ico(t, "delete", 320f, y + 28f, 22f, Tok.ON_SURFACE_VARIANT)
                n += item.grp()
                n += comp(t, "quantity", 216f, y + 56f)
            }
            n += rect(t, tr("card"), 16f, 488f, 328f, 164f, 28f, Tok.SURFACE_CONTAINER)
            val rows = listOf(tr("t_subtotal") to "7 740 RUB", tr("t_delivery") to "0 RUB", tr("t_total") to "7 740 RUB")
            for ((i, r) in rows.withIndex()) {
                val y = 520f + i * 40f
                val bold = i == 2
                n += text(t, r.first, 36f, y, if (bold) 18f else 14f, if (bold) 600 else 400, Tok.ON_SURFACE)
                val v = text(t, r.second, 0f, y, if (bold) 18f else 14f, if (bold) 600 else 400, Tok.ON_SURFACE)
                n += v.copy(x = 324f - v.w)
            }
            val co = center(t, tr("t_checkout"), 180f, 716f, 18f, 500, Tok.ON_PRIMARY)
            n += (listOf(rect(t, tr("button"), 16f, 684f, 328f, 64f, 9999f, Tok.PRIMARY), co) +
                ico(t, "shopping_cart", co.x - 22f, 716f, 24f, Tok.ON_PRIMARY)).grp()
            n
        },
        ProjectTemplate("tasks", tr("tpl_tasks"), tr("tpl_tasks_desc"), 360f, 800f) { t ->
            val n = ArrayList<Node>()
            n += comp(t, "top-bar-medium", 0f, 36f).map { it.rename(tr("t_tasks")) }
            n += comp(t, "chip-filter", 16f, 164f).map { it.rename(tr("t_all")) }
            n += comp(t, "chip", 128f, 164f).map { it.rename(tr("t_active")) }
            n += comp(t, "chip", 232f, 164f).map { it.rename(tr("t_done")) }
            val items = listOf(tr("t_task_1"), tr("t_task_2"), tr("t_task_3"), tr("t_task_4"), tr("t_task_5"), tr("t_task_6"))
            for ((i, s) in items.withIndex()) {
                val y = 224f + i * 64f
                n += listOf(rect(t, tr("card_n", i + 1), 16f, y, 328f, 56f, 20f, Tok.SURFACE_HIGH)).grp()
                n += comp(t, if (i % 3 == 1) "checkbox" else "checkbox-off", 28f, y + 16f)
                n += text(t, s, 68f, y + 28f, 16f, 400, Tok.ON_SURFACE)
                n += ico(t, "star", 322f, y + 28f, 22f, if (i == 0) Tok.PRIMARY else Tok.ON_SURFACE_VARIANT, i == 0).grp()
            }
            n += extFab(t, 168f, 716f, "add", tr("t_new_task")).grp()
            n
        },
        ProjectTemplate("smarthome", tr("tpl_home_ctrl"), tr("tpl_home_ctrl_desc"), 360f, 800f) { t ->
            val n = ArrayList<Node>()
            n += text(t, tr("t_my_home"), 16f, 76f, 32f, 600, Tok.ON_SURFACE)
            val devices = listOf(tr("t_dev_light"), tr("t_dev_ac"), tr("t_dev_tv"), tr("t_dev_lock"))
            for ((i, d) in devices.withIndex()) {
                val x = 16f + (i % 2) * 172f
                val y = 120f + (i / 2) * 140f
                n += switchCard(t, d, listOf("lightbulb", "ac_unit", "tv", "lock")[i], x, y, i % 2 == 0)
            }
            n += text(t, tr("t_brightness"), 20f, 440f, 16f, 500, Tok.ON_SURFACE)
            n += comp(t, "slider-wavy", 30f, 468f)
            n += text(t, tr("t_volume"), 20f, 556f, 16f, 500, Tok.ON_SURFACE)
            n += comp(t, "slider", 40f, 584f)
            n += text(t, tr("t_mode"), 20f, 652f, 16f, 500, Tok.ON_SURFACE)
            n += comp(t, "radio", 20f, 676f)
            n += text(t, tr("t_mode_home"), 56f, 688f, 16f, 400, Tok.ON_SURFACE)
            n += comp(t, "radio-off", 20f, 716f)
            n += text(t, tr("t_mode_away"), 56f, 728f, 16f, 400, Tok.ON_SURFACE)
            n
        },
        ProjectTemplate("settings", tr("settings"), tr("tpl_settings_desc"), 360f, 800f) { t ->
            val n = ArrayList<Node>()
            n += comp(t, "top-bar", 0f, 40f)
            val rows = listOf(tr("notifications"), tr("dark_theme"), tr("sync"), tr("autosave"), tr("sound"))
            for ((i, title) in rows.withIndex()) {
                val y = 120f + i * 76f
                n += ico(t, listOf("notifications", "dark_mode", "sync", "save", "volume_up")[i], 36f, y + 36f, 24f, Tok.PRIMARY)
                n += text(t, title, 68f, y + 24f, 16f, 400, Tok.ON_SURFACE)
                n += text(t, tr("param_desc"), 68f, y + 48f, 14f, 400, Tok.ON_SURFACE_VARIANT)
                n += comp(t, if (i % 2 == 0) "switch" else "switch-icon", 292f, y + 20f)
                n += rect(t, tr("divider"), 16f, y + 75f, 328f, 1f, 0f, Tok.OUTLINE_VARIANT)
            }
            n += ico(t, "volume_up", 36f, 524f, 24f, Tok.PRIMARY)
            n += text(t, tr("t_volume"), 68f, 524f, 16f, 500, Tok.ON_SURFACE)
            n += comp(t, "slider", 40f, 552f)
            n
        },
        ProjectTemplate("profile", tr("profile"), tr("tpl_profile_desc"), 360f, 800f) { t ->
            val n = ArrayList<Node>()
            n += rect(t, tr("header"), 0f, 0f, 360f, 180f, 0f, Tok.SURFACE_HIGH)
            n += circle(t, tr("avatar"), 124f, 100f, 112f, Tok.PRIMARY_CONTAINER)
            n += ico(t, "person", 180f, 156f, 64f, Tok.ON_PRIMARY_CONTAINER, true)
            n += ico(t, "settings", 328f, 40f, 24f, Tok.ON_SURFACE_VARIANT)
            n += center(t, tr("sample_name"), 180f, 242f, 24f, 600, Tok.ON_SURFACE)
            n += center(t, tr("sample_role"), 180f, 270f, 14f, 400, Tok.ON_SURFACE_VARIANT)
            val stats = listOf("128" to tr("projects_count"), "4,2K" to tr("followers"), "312" to tr("likes"))
            for ((i, st) in stats.withIndex()) {
                val cx = 60f + i * 120f
                n += center(t, st.first, cx, 326f, 20f, 600, Tok.ON_SURFACE)
                n += center(t, st.second, cx, 350f, 12f, 400, Tok.ON_SURFACE_VARIANT)
            }
            n += comp(t, "btn-filled", 40f, 392f)
            n += comp(t, "btn-outlined", 200f, 392f)
            n += comp(t, "divider", 16f, 456f)
            n += comp(t, "list-item", 0f, 472f)
            n += comp(t, "list-item", 0f, 544f)
            n += comp(t, "list-item", 0f, 616f)
            n
        },
        ProjectTemplate("onboarding", tr("tpl_onboarding"), tr("tpl_onboarding_desc"), 360f, 800f) { t ->
            val n = ArrayList<Node>()
            n += shape(t, "soft-burst", tr("shape"), 40f, 96f, 280f, 280f, Tok.SECONDARY_CONTAINER, 12f)
            n += shape(t, "cookie-9", tr("shape_2"), 96f, 152f, 168f, 168f, Tok.PRIMARY_CONTAINER)
            n += ico(t, "rocket_launch", 180f, 236f, 80f, Tok.ON_PRIMARY_CONTAINER, true)
            n += center(t, tr("onb_title"), 180f, 450f, 28f, 600, Tok.ON_SURFACE)
            n += center(t, tr("onb_text"), 180f, 506f, 16f, 400, Tok.ON_SURFACE_VARIANT)
            for (i in 0 until 3) n += circle(t, tr("dot_n", i + 1), 162f + i * 16f, 580f, 8f, if (i == 0) Tok.PRIMARY else Tok.OUTLINE_VARIANT)
            n += listOf(rect(t, tr("button"), 40f, 664f, 280f, 56f, 9999f, Tok.PRIMARY), center(t, tr("start"), 180f, 692f, 16f, 500, Tok.ON_PRIMARY)).grp()
            n += listOf(center(t, tr("skip"), 180f, 752f, 14f, 500, Tok.PRIMARY)).grp()
            n
        },
        ProjectTemplate("product", tr("tpl_product"), tr("tpl_product_desc"), 360f, 800f) { t ->
            val n = ArrayList<Node>()
            n += rect(t, tr("photo"), 0f, 0f, 360f, 360f, 0f, Tok.SURFACE_HIGH)
            n += shape(t, "flower", tr("product"), 80f, 80f, 200f, 200f, Tok.TERTIARY_CONTAINER)
            n += (listOf(circle(t, tr("button"), 16f, 40f, 44f, Tok.SURFACE)) + ico(t, "arrow_back", 38f, 62f, 24f, Tok.ON_SURFACE)).grp()
            n += (listOf(circle(t, tr("button"), 300f, 40f, 44f, Tok.SURFACE)) + ico(t, "favorite", 322f, 62f, 24f, Tok.PRIMARY)).grp()
            n += text(t, tr("product_name"), 16f, 396f, 24f, 600, Tok.ON_SURFACE)
            n += text(t, "4 990 RUB", 16f, 436f, 22f, 500, Tok.PRIMARY)
            n += text(t, tr("product_desc"), 16f, 490f, 14f, 400, Tok.ON_SURFACE_VARIANT)
            n += comp(t, "chip-filter", 16f, 548f).map { it.rename("S") }
            n += comp(t, "chip", 128f, 548f).map { it.rename("M") }
            n += comp(t, "chip", 232f, 548f).map { it.rename("L") }
            val ac = center(t, tr("add_to_cart"), 180f, 732f, 16f, 500, Tok.ON_PRIMARY)
            n += (listOf(rect(t, tr("button"), 16f, 704f, 328f, 56f, 9999f, Tok.PRIMARY), ac) +
                ico(t, "shopping_cart", ac.x - 22f, 732f, 24f, Tok.ON_PRIMARY)).grp()
            n
        },
        ProjectTemplate("poster", tr("tpl_post"), tr("tpl_post_desc"), 512f, 512f) { t ->
            val n = ArrayList<Node>()
            n += rect(t, tr("background"), 0f, 0f, 512f, 512f, 0f, Tok.SURFACE)
            n += shape(t, "cookie-9", tr("shape_1"), 236f, -72f, 340f, 340f, Tok.SECONDARY_CONTAINER, 8f)
            n += shape(t, "soft-burst", tr("shape_2"), 340f, 330f, 220f, 220f, Tok.TERTIARY_CONTAINER, -10f)
            n += listOf(rect(t, tr("label"), 40f, 56f, 132f, 40f, 9999f, Tok.PRIMARY), center(t, tr("new_badge"), 106f, 76f, 14f, 600, Tok.ON_PRIMARY)).grp()
            n += text(t, tr("big_title"), 40f, 250f, 56f, 700, Tok.ON_SURFACE)
            n += text(t, tr("caption_cta"), 40f, 392f, 20f, 400, Tok.ON_SURFACE_VARIANT)
            n
        },
        ProjectTemplate("dashboard", tr("tpl_dashboard"), tr("tpl_dashboard_desc"), 834f, 1194f) { t ->
            val n = ArrayList<Node>()
            n += text(t, tr("overview"), 32f, 72f, 32f, 600, Tok.ON_SURFACE)
            val kpi = listOf(tr("revenue") to tr("revenue_value"), tr("orders") to "3 820", tr("customers") to "912")
            for ((i, k) in kpi.withIndex()) {
                val x = 32f + i * 260f
                n += (listOf(rect(t, tr("metric_n", i + 1), x, 120f, 244f, 120f, 20f, Tok.SURFACE_HIGH),
                    text(t, k.first, x + 20f, 156f, 14f, 400, Tok.ON_SURFACE_VARIANT), text(t, k.second, x + 20f, 196f, 30f, 600, Tok.ON_SURFACE)) +
                    ico(t, listOf("payments", "shopping_bag", "group")[i], x + 244f - 36f, 156f, 24f, Tok.PRIMARY)).grp()
            }
            n += rect(t, tr("chart"), 32f, 264f, 770f, 360f, 24f, Tok.SURFACE_CONTAINER)
            n += text(t, tr("monthly_trend"), 56f, 300f, 18f, 500, Tok.ON_SURFACE)
            val bars = floatArrayOf(120f, 180f, 150f, 230f, 200f, 270f, 240f)
            for ((i, h) in bars.withIndex()) {
                n += rect(t, tr("bar_n", i + 1), 72f + i * 100f, 592f - h, 56f, h, 12f, if (i == bars.size - 1) Tok.PRIMARY else Tok.PRIMARY_CONTAINER)
            }
            n += comp(t, "list-item", 32f, 656f)
            n += comp(t, "list-item", 32f, 728f)
            n += comp(t, "list-item", 32f, 800f)
            n
        },
    )

    private fun Node.rename(newName: String): Node = if (kind == NodeKind.TEXT) copy(text = newName, name = newName).withTextSize() else this
}
