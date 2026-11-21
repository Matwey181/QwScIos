package com.qwenz.qwel.ui.projects

import android.content.Context
import android.graphics.BitmapFactory
import android.util.LruCache
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.FastOutLinearInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.runtime.withFrameNanos
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.qwenz.qwel.AppController
import com.qwenz.qwel.data.Project
import com.qwenz.qwel.data.Tone
import com.qwenz.qwel.i18n.tr
import com.qwenz.qwel.render.SvgImport
import com.qwenz.qwel.ui.common.ProjectThumb
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlin.random.Random

/** Картинки раздела 'Смешнявки': лежат в assets/fun (см. README.txt там же). Если файла нет, показывается заглушка. */
internal object FunAssets {
    private val cache = object : LruCache<String, ImageBitmap>(16 * 1024) {
        override fun sizeOf(key: String, value: ImageBitmap): Int = value.width * value.height * 4 / 1024
    }
    private val raster = setOf("png", "jpg", "jpeg", "webp")

    private fun list(ctx: Context): List<String> =
        runCatching { ctx.assets.list("fun")?.toList() }.getOrNull().orEmpty().sorted()

    /** Файлы с именем, начинающимся на manul. */
    fun manuls(ctx: Context): List<String> =
        list(ctx).filter { it.lowercase().startsWith("manul") && it.substringAfterLast('.').lowercase() in raster }

    /** Файл персонажа по базовому имени (png, jpg, webp или svg), null - нет. */
    fun find(ctx: Context, base: String, svgFirst: Boolean): String? {
        val all = list(ctx)
        val order = if (svgFirst) listOf("svg") + raster else raster.toList() + "svg"
        for (ext in order) all.firstOrNull { it.equals("$base.$ext", ignoreCase = true) }?.let { return it }
        return null
    }

    fun bitmap(ctx: Context, name: String, maxSide: Int): ImageBitmap? {
        val key = "$name|$maxSide"
        cache.get(key)?.let { return it }
        return runCatching {
            val o = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            ctx.assets.open("fun/$name").use { BitmapFactory.decodeStream(it, null, o) }
            var sample = 1
            while (maxOf(o.outWidth, o.outHeight) / sample > maxSide * 2) sample *= 2
            val o2 = BitmapFactory.Options().apply { inSampleSize = sample }
            val bmp = ctx.assets.open("fun/$name").use { BitmapFactory.decodeStream(it, null, o2) }?.asImageBitmap()
            if (bmp != null) cache.put(key, bmp)
            bmp
        }.getOrNull()
    }

    /** SVG как проект, чтобы нарисовать его обычным отрисовщиком редактора. */
    fun svg(ctx: Context, name: String): Project? = runCatching {
        val bytes = ctx.assets.open("fun/$name").use { it.readBytes() }
        val r = SvgImport.parseOwnSize(bytes, 1.0) ?: return null
        val w = if (r.width > 0f) r.width else 512f
        val h = if (r.height > 0f) r.height else 512f
        Project("fun-$name", name, w, h, 0, r.nodes, 0L, 0L, Tone.Baseline)
    }.getOrNull()
}

private class Character(val id: String, val svgFirst: Boolean)

private val characters = listOf(
    Character("linus", false), Character("stallman", false), Character("tux", true), Character("manul", false),
)

/** Картинка персонажа: png/jpg/webp или svg; пока грузится или файла нет - пусто. [index] - какое фото манула; [wiggle] - Тукс переваливается с боку на бок. */
@Composable
private fun CharacterPicture(id: String, svgFirst: Boolean, modifier: Modifier, maxSide: Int, index: Int = 0, wiggle: Boolean = false) {
    val ctx = LocalContext.current
    val loaded by produceState<Any?>(null, id, index) {
        value = withContext(Dispatchers.IO) {
            val file = if (id == "manul") FunAssets.manuls(ctx).let { l -> if (l.isEmpty()) null else l[index % l.size] } else FunAssets.find(ctx, id, svgFirst)
            when {
                file == null -> null
                file.endsWith(".svg", ignoreCase = true) -> FunAssets.svg(ctx, file)
                else -> FunAssets.bitmap(ctx, file, maxSide)
            }
        }
    }
    val sway by rememberInfiniteTransition(label = "sway").animateFloat(
        -7f, 7f, infiniteRepeatable(tween(420, easing = FastOutSlowInEasing), RepeatMode.Reverse), label = "sway",
    )
    val m = if (wiggle) modifier.graphicsLayer { rotationZ = sway; transformOrigin = androidx.compose.ui.graphics.TransformOrigin(0.5f, 1f) } else modifier
    when (val v = loaded) {
        is ImageBitmap -> Image(v, null, m, contentScale = ContentScale.Fit)
        is Project -> Box(m) { ProjectThumb(v, inset = 0.dp, maxSide = maxSide) }
        else -> Box(m, contentAlignment = Alignment.Center) {
            Text("?", style = MaterialTheme.typography.headlineMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
internal fun FunnyPage(controller: AppController) {
    var open by remember { mutableStateOf<String?>(null) }
    SettingsPage {
        SettingsGroup(tr("funny_chars")) {
            item {
                Column(Modifier.fillMaxWidth().padding(12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    for (row in characters.chunked(2)) {
                        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            for (c in row) CharacterTile(c, Modifier.weight(1f)) { open = c.id }
                        }
                    }
                }
            }
        }
        SettingsGroup(tr("funny_pets")) {
            item {
                Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()).padding(horizontal = 16.dp, vertical = 10.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    for (n in 0..5) FilterChip(
                        selected = controller.pets == n, onClick = { controller.updatePets(n) },
                        label = { Text(if (n == 0) tr("pets_off") else n.toString()) },
                    )
                }
            }
        }
    }
    open?.let { id ->
        val c = characters.first { it.id == id }
        AlertDialog(
            onDismissRequest = { open = null },
            title = { Text(tr("char_$id")) },
            text = {
                Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    val scope = rememberCoroutineScope()
                    val density = LocalDensity.current
                    val lift = remember { Animatable(0f) }
                    val spin = remember { Animatable(0f) }
                    var photo by remember { mutableStateOf(0) }
                    val up = with(density) { 48.dp.toPx() }
                    CharacterPicture(
                        id, c.svgFirst,
                        Modifier.fillMaxWidth().height(220.dp)
                            .graphicsLayer { translationY = -lift.value; rotationZ = spin.value }
                            .clickable(remember { MutableInteractionSource() }, null) {
                                if (id == "manul") photo++
                                scope.launch {
                                    launch { lift.animateTo(up, tween(180, easing = FastOutSlowInEasing)); lift.animateTo(0f, spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessLow)) }
                                    if (id == "tux" || id == "manul") { spin.snapTo(0f); spin.animateTo(360f, tween(520, easing = FastOutSlowInEasing)); spin.snapTo(0f) }
                                }
                            },
                        640, index = photo, wiggle = id == "tux",
                    )
                    Text(tr("fact_$id"), style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center)
                }
            },
            confirmButton = { TextButton({ open = null }) { Text(tr("close")) } },
        )
    }
}

@Composable
private fun CharacterTile(c: Character, modifier: Modifier, onClick: () -> Unit) {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val corner by animateDpAsState(if (pressed) 32.dp else 20.dp, spring(stiffness = Spring.StiffnessMedium), label = "char")
    Column(
        modifier.clip(RoundedCornerShape(corner)).background(MaterialTheme.colorScheme.surfaceContainerHighest)
            .clickable(source, null, onClick = onClick).padding(10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        CharacterPicture(c.id, c.svgFirst, Modifier.fillMaxWidth().aspectRatio(1f), 320, wiggle = c.id == "tux")
        Text(tr("char_" + c.id), Modifier.padding(top = 6.dp), style = MaterialTheme.typography.titleSmall, maxLines = 1)
    }
}

/** Один питомец: положение (y - высота над полом, вверх), скорость и характер. Двигает всех общий цикл [stepPets]. */
private class PetBody(val photo: ImageBitmap, val kind: Int, rnd: Random, val w: Float, val h: Float, dp: Float) {
    var x by mutableFloatStateOf(0f)
    var y by mutableFloatStateOf(0f)
    var facing by mutableFloatStateOf(1f)
    var spin by mutableFloatStateOf(0f)
    var asleep by mutableStateOf(false)
    var say by mutableStateOf<String?>(null)
    var dragging by mutableStateOf(false)
    var vx = 0f
    var vy = 0f
    var mode = 0 // 0 - стоит, 1 - идёт прыжками, 2 - спит
    var timer = 1f
    var target = 0f
    var sayT = 0f
    var spinT = -1f
    var estX = 0f
    var estY = 0f

    // характер: 0 - непоседа, 1 - соня, 2 - проказник
    private val j = 0.85f + rnd.nextFloat() * 0.3f
    val speed = dp * j * when (kind) { 0 -> 200f; 1 -> 80f; else -> 135f }
    val hopV = dp * j * when (kind) { 0 -> 430f; 1 -> 290f; else -> 370f }
    val sleepChance = when (kind) { 0 -> 0.05f; 1 -> 0.45f; else -> 0.15f }
    val leapChance = when (kind) { 0 -> 0.15f; 1 -> 0.03f; else -> 0.4f }
    private val restMin = when (kind) { 0 -> 0.3f; 1 -> 2f; else -> 0.8f }
    private val restMax = when (kind) { 0 -> 1.2f; 1 -> 5f; else -> 2.5f }
    fun rest(rnd: Random) = restMin + rnd.nextFloat() * (restMax - restMin)
}

private class PetWorld(val dp: Float, var maxX: Float, var maxY: Float, val rnd: Random = Random(System.nanoTime()))

private fun stepPets(pets: List<PetBody>, wd: PetWorld, dtRaw: Float) {
    val dt = dtRaw.coerceIn(0.001f, 0.05f)
    val dp = wd.dp
    val g = 2600f * dp
    val rnd = wd.rnd
    for (p in pets) {
        if (p.sayT > 0f) { p.sayT -= dt; if (p.sayT <= 0f) p.say = null }
        if (p.spinT >= 0f) {
            p.spinT += dt / 0.55f
            if (p.spinT >= 1f) { p.spinT = -1f; p.spin = 0f } else { val t = 1f - p.spinT; p.spin = 360f * (1f - t * t * t) }
        }
        if (p.dragging) continue
        val air = p.y > 0.5f || p.vy > 0f
        if (air) {
            p.vy -= g * dt
            p.x += p.vx * dt
            p.y += p.vy * dt
            if (p.y <= 0f) {
                p.y = 0f
                if (abs(p.vy) > 220f * dp) { p.vy = -p.vy * 0.42f; p.vx *= 0.85f } else p.vy = 0f
            }
            if (p.y > wd.maxY) { p.y = wd.maxY; p.vy = -abs(p.vy) * 0.3f }
        } else {
            p.timer -= dt
            when (p.mode) {
                0 -> {
                    p.vx *= (1f - 10f * dt).coerceAtLeast(0f)
                    p.x += p.vx * dt
                    if (p.timer <= 0f) {
                        val r = rnd.nextFloat()
                        val dir = if (rnd.nextBoolean()) 1f else -1f
                        when {
                            r < p.sleepChance -> { p.mode = 2; p.asleep = true; p.timer = 4f + rnd.nextFloat() * 5f }
                            r < p.sleepChance + p.leapChance -> {
                                p.facing = dir; p.vy = 700f * dp; p.vx = dir * p.speed * 1.4f; p.spinT = 0f; p.timer = p.rest(rnd)
                            }
                            else -> { p.mode = 1; p.target = rnd.nextFloat() * wd.maxX }
                        }
                    }
                }
                2 -> {
                    p.vx = 0f
                    if (p.timer <= 0f) { p.mode = 0; p.asleep = false; p.timer = 0.3f }
                }
                else -> {
                    val d = p.target - p.x
                    if (abs(d) < 14f * dp) { p.mode = 0; p.vx = 0f; p.timer = p.rest(rnd) }
                    else { val dir = if (d > 0f) 1f else -1f; p.facing = dir; p.vy = p.hopV; p.vx = dir * p.speed }
                }
            }
        }
        if (p.x < 0f) { p.x = 0f; p.vx = abs(p.vx) * 0.6f; if (p.mode == 1) p.target = rnd.nextFloat() * wd.maxX }
        if (p.x > wd.maxX) { p.x = wd.maxX; p.vx = -abs(p.vx) * 0.6f; if (p.mode == 1) p.target = rnd.nextFloat() * wd.maxX }
    }
    // питомцы не пролетают друг сквозь друга: расталкиваются, будятся и разбегаются
    for (a in 0 until pets.size) for (b in a + 1 until pets.size) {
        val p = pets[a]; val q = pets[b]
        val dx = (p.x + p.w / 2f) - (q.x + q.w / 2f)
        val ox = (p.w + q.w) / 2f * 0.8f - abs(dx)
        if (ox <= 0f || abs(p.y - q.y) >= minOf(p.h, q.h) * 0.7f) continue
        val sg = if (dx >= 0f) 1f else -1f
        if (!p.dragging) p.x += sg * ox / 2f
        if (!q.dragging) q.x -= sg * ox / 2f
        for ((m, dir) in listOf(p to sg, q to -sg)) {
            if (m.dragging) continue
            m.vx = dir * maxOf(abs(m.vx), 110f * dp) * 0.8f
            m.facing = dir
            if (m.mode == 2) { m.mode = 0; m.asleep = false; m.timer = 0.5f }
            if (m.mode == 1) m.target = (m.x + dir * (120f + rnd.nextFloat() * 200f) * dp).coerceIn(0f, wd.maxX)
            if (m.y <= 0.5f && m.vy <= 0f) m.vy = 220f * dp
        }
    }
}

/** Манулы-питомцы по всему приложению: у каждого свой характер, их можно схватить и бросить, они отскакивают от стен и друг от друга. */
@Composable
internal fun ManulPets(count: Int) {
    val ctx = LocalContext.current
    val photos by produceState<List<ImageBitmap>>(emptyList()) {
        value = withContext(Dispatchers.IO) { FunAssets.manuls(ctx).mapNotNull { FunAssets.bitmap(ctx, it, 200) } }
    }
    if (photos.isEmpty()) return
    val density = LocalDensity.current
    val floorPx = WindowInsets.navigationBars.getBottom(density).toFloat()
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val dp = density.density
        val totalW = constraints.maxWidth.toFloat()
        val totalH = constraints.maxHeight.toFloat()
        val pets = remember(photos, count, totalW) {
            val rnd = Random(System.nanoTime())
            val kinds = (0..2).shuffled(rnd)
            List(count) { i ->
                val ph = photos[i % photos.size]
                val hDp = 54f + rnd.nextFloat() * 20f
                val wDp = (hDp * ph.width / ph.height).coerceIn(40f, 110f)
                PetBody(ph, kinds[i % 3], rnd, wDp * dp, hDp * dp, dp).also { it.x = (i + 0.5f) / count * (totalW - it.w) }
            }
        }
        val world = remember(pets) { PetWorld(dp, 0f, 0f) }
        world.maxX = totalW
        world.maxY = totalH - floorPx
        LaunchedEffect(pets) {
            var last = 0L
            while (true) withFrameNanos { t ->
                if (last != 0L) stepPets(pets, world, (t - last) / 1e9f)
                last = t
            }
        }
        val says = listOf(tr("pet_say_1"), tr("pet_say_2"), tr("pet_say_3"))
        val breathe = rememberInfiniteTransition(label = "breathe").animateFloat(
            0.94f, 1f, infiniteRepeatable(tween(1100, easing = FastOutSlowInEasing), RepeatMode.Reverse), label = "breathe",
        )
        for (p in pets) {
            // границы для каждого питомца свои: ширина самого питомца вычитается
            Box(
                Modifier
                    .offset { IntOffset(p.x.coerceIn(0f, totalW - p.w).roundToInt(), (totalH - floorPx - p.h - p.y).roundToInt()) }
                    .size(with(density) { p.w.toDp() }, with(density) { p.h.toDp() }),
            ) {
                Image(
                    p.photo, null,
                    Modifier.fillMaxSize()
                        .graphicsLayer {
                            val b = if (p.asleep) breathe.value else 1f
                            scaleX = b * p.facing; scaleY = b; rotationZ = p.spin * p.facing
                        }
                        .pointerInput(p) {
                            detectTapGestures {
                                p.asleep = false; p.mode = 0; p.timer = 1.2f
                                p.say = says.random(); p.sayT = 1.3f
                                p.vy = 760f * dp; p.spinT = 0f
                            }
                        }
                        .pointerInput(p) {
                            detectDragGestures(
                                onDragStart = { p.dragging = true; p.asleep = false; p.mode = 0; p.vx = 0f; p.vy = 0f; p.estX = 0f; p.estY = 0f },
                                onDrag = { change, amount ->
                                    change.consume()
                                    val dt = ((change.uptimeMillis - change.previousUptimeMillis) / 1000f).coerceAtLeast(0.001f)
                                    p.estX = p.estX * 0.6f + amount.x / dt * 0.4f
                                    p.estY = p.estY * 0.6f + (-amount.y / dt) * 0.4f
                                    p.x = (p.x + amount.x).coerceIn(0f, world.maxX - p.w)
                                    p.y = (p.y - amount.y).coerceIn(0f, world.maxY - p.h)
                                },
                                onDragEnd = {
                                    p.dragging = false; p.timer = 1.5f
                                    val cap = 3500f * dp
                                    p.vx = p.estX.coerceIn(-cap, cap); p.vy = p.estY.coerceIn(-cap, cap)
                                    if (abs(p.vx) > 40f * dp) p.facing = if (p.vx > 0f) 1f else -1f
                                },
                                onDragCancel = { p.dragging = false; p.timer = 1f },
                            )
                        },
                    contentScale = ContentScale.Fit,
                )
                val label = if (p.asleep) "z z" else p.say
                if (label != null) {
                    Text(
                        label,
                        Modifier.align(Alignment.TopCenter).offset(y = (-22).dp)
                            .clip(RoundedCornerShape(10.dp)).background(MaterialTheme.colorScheme.tertiaryContainer).padding(horizontal = 6.dp, vertical = 2.dp),
                        style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onTertiaryContainer, maxLines = 1, softWrap = false,
                    )
                }
            }
        }
    }
}
