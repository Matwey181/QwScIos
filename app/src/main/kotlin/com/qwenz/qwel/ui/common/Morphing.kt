package com.qwenz.qwel.ui.common

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.material3.MaterialTheme
import com.qwenz.qwel.render.appendTo
import com.qwenz.qwel.shapes.ShapeLibrary
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch

/**
 * Фирменный 'живой' элемент: фигура вращается и перетекает в следующую
 * (порядок и пружина - как у Loading Indicator из MD3 Expressive).
 */
@Composable
fun MorphingShape(
    modifier: Modifier = Modifier,
    color: Color = MaterialTheme.colorScheme.primary,
    ids: List<String> = ShapeLibrary.loaderOrder,
) {
    var index by remember { mutableIntStateOf(0) }
    val progress = remember { Animatable(0f) }
    val rotation = remember { Animatable(0f) }
    val morphs = remember(ids) { ids.indices.mapNotNull { ShapeLibrary.morph(ids[it], ids[(it + 1) % ids.size]) } }

    LaunchedEffect(morphs) {
        if (morphs.isEmpty()) return@LaunchedEffect
        while (true) {
            progress.snapTo(0f)
            val target = rotation.value + 50f
            coroutineScope {
                launch { progress.animateTo(1f, spring(dampingRatio = 0.55f, stiffness = 170f)) }
                launch { rotation.animateTo(target, spring(dampingRatio = 0.7f, stiffness = 120f)) }
            }
            index = (index + 1) % morphs.size
        }
    }
    Canvas(modifier) {
        val morph = morphs.getOrNull(index) ?: return@Canvas
        val s = size.minDimension * 0.92f
        val path = morph.asCubics(progress.value).appendTo(
            Path(), (size.width - s) / 2f, (size.height - s) / 2f, s, s,
        )
        rotate(rotation.value, pivot = Offset(size.width / 2f, size.height / 2f)) { drawPath(path, color) }
    }
}
