package com.qwenz.qwel.ui.common

import com.qwenz.qwel.i18n.tr

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import com.qwenz.qwel.render.Gallery
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Возвращает функцию 'сохранить в Pictures/Qwel': (имя файла, mime, генератор байтов).
 * На Android 9 и ниже сама запросит разрешение на запись; на 10+ оно не нужно.
 */
@Composable
fun rememberGallerySaver(): (String, String, () -> ByteArray) -> Unit {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var pending by remember { mutableStateOf<(() -> Unit)?>(null) }
    val permission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        val job = pending
        pending = null
        if (granted) job?.invoke()
        else Toast.makeText(context, tr("need_storage_permission"), Toast.LENGTH_LONG).show()
    }
    return remember(context) {
        val save: (String, String, () -> ByteArray) -> Unit = { name, mime, produce ->
            val run: () -> Unit = {
                scope.launch {
                    val uri = withContext(Dispatchers.Default) {
                        runCatching { Gallery.save(context, name, mime, produce()) }.getOrNull()
                    }
                    Toast.makeText(
                        context,
                        if (uri != null) tr("saved_to", Gallery.SHOWN) else tr("save_failed"),
                        Toast.LENGTH_SHORT,
                    ).show()
                }
            }
            if (Build.VERSION.SDK_INT < 29 &&
                context.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED
            ) {
                pending = run
                permission.launch(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            } else run()
        }
        save
    }
}
