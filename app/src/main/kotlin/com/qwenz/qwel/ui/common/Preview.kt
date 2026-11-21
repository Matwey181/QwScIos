package com.qwenz.qwel.ui.common

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import android.util.LruCache
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.Dp
import com.qwenz.qwel.data.Project
import com.qwenz.qwel.render.drawProjectFit
import com.qwenz.qwel.render.renderPreview
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.sync.withPermit
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.asAndroidBitmap

/** Готовые миниатюры: ключ - проект, время изменения и размер. Переживает прокрутку списка и пересоздание плиток. */
private val thumbCache = object : LruCache<String, ImageBitmap>(16 * 1024) {
    override fun sizeOf(key: String, value: ImageBitmap): Int = value.width * value.height * 4 / 1024
}

/**
 * Миниатюра проекта. Небольшой проект рисуется прямо на канвасе. Большой (много слоёв, например с иконками) или с размытием
 * фона считается один раз в фоне в картинку и кэшируется: иначе при прокрутке списка каждый кадр заново рисуются все контуры,
 * а на слабых телефонах это лаги. Канвас размытие фона не показывает (на Android ниже 12 вообще), картинка его показывает.
 */
@Composable
fun ProjectThumb(p: Project, inset: Dp, modifier: Modifier = Modifier.fillMaxSize(), maxSide: Int = 360, persist: Boolean = false) {
    if (persist) { PersistedThumb(p, inset, modifier, maxSide); return }
    val blurry = p.nodes.any { it.visible && it.blur > 0.5f }
    if (!blurry && p.nodes.size <= 40 && p.pages.size <= 1) {
        Canvas(modifier) { drawProjectFit(p, inset.toPx()) }
    } else {
        val key = "${p.id}|${p.name}|${p.updated}|${p.nodes.size}|${System.identityHashCode(p.nodes)}|$maxSide"
        val img by produceState<ImageBitmap?>(thumbCache.get(key), key) {
            value = thumbCache.get(key) ?: withContext(Dispatchers.Default) { runCatching { renderPreview(p, maxSide) }.getOrNull() }
                ?.also { thumbCache.put(key, it) }
        }
        Box(modifier.padding(inset)) {
            img?.let { Image(it, null, Modifier.fillMaxSize(), contentScale = ContentScale.Fit) }
        }
    }
}

private val renderGate = kotlinx.coroutines.sync.Semaphore(2)

/**
 * Миниатюра карточки проекта: PNG лежит на диске (cache/thumbs/<id>_<время изменения>_<размер>.png), при запуске только читается.
 * Рисуется заново один раз, когда проект изменился; старые файлы этого проекта удаляются.
 */
@Composable
private fun PersistedThumb(p: Project, inset: Dp, modifier: Modifier, maxSide: Int) {
    val ctx = androidx.compose.ui.platform.LocalContext.current.applicationContext
    val key = "${p.id}|${p.updated}|$maxSide"
    val img by produceState<ImageBitmap?>(thumbCache.get(key), key) {
        value = thumbCache.get(key) ?: withContext(Dispatchers.IO) { loadOrRender(ctx, p, maxSide) }?.also { thumbCache.put(key, it) }
    }
    Box(modifier.padding(inset)) {
        img?.let { Image(it, null, Modifier.fillMaxSize(), contentScale = ContentScale.Fit) }
    }
}

private suspend fun loadOrRender(ctx: android.content.Context, p: Project, maxSide: Int): ImageBitmap? {
    val dir = java.io.File(ctx.cacheDir, "thumbs").apply { mkdirs() }
    val f = java.io.File(dir, "${p.id}_${p.updated}_$maxSide.png")
    if (f.exists()) android.graphics.BitmapFactory.decodeFile(f.path)?.let { return it.asImageBitmap() }
    return renderGate.withPermit {
        val img = runCatching { renderPreview(p, maxSide) }.getOrNull() ?: return@withPermit null
        runCatching {
            dir.listFiles { x -> x.name.startsWith(p.id + "_") && x.name != f.name }?.forEach { it.delete() }
            f.outputStream().use { img.asAndroidBitmap().compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it) }
        }
        img
    }
}
