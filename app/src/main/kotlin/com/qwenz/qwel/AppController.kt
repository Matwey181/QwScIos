package com.qwenz.qwel

import com.qwenz.qwel.i18n.tr

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.setValue
import com.qwenz.qwel.data.Project
import com.qwenz.qwel.ui.common.News
import com.qwenz.qwel.data.ProjectTemplate
import com.qwenz.qwel.data.ProjectStore
import com.qwenz.qwel.data.Samples
import com.qwenz.qwel.data.Tok
import com.qwenz.qwel.data.Tone
import com.qwenz.qwel.data.newId
import com.qwenz.qwel.render.Assets
import com.qwenz.qwel.ui.editor.EditorState
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.withContext

/** Список проектов, открытый редактор и настройки приложения. */
class AppController(context: Context) {
    private val store = ProjectStore(context)
    private val prefs = context.getSharedPreferences("qwel", Context.MODE_PRIVATE)

    val projects = mutableStateListOf<Project>()
    var loaded by mutableStateOf(false)
    var editor by mutableStateOf<EditorState?>(null)

    /** Включённые жесты редактора (каждый отключается отдельно). */
    val gestures = com.qwenz.qwel.ui.editor.Gestures(prefs)

    /** Подсказки по ходу работы (по одной, только при первом попадании в нужное место). */
    val hints = com.qwenz.qwel.ui.editor.Hints(prefs)

    /** Приветствие и обучение: само показывается при первом запуске, потом - из настроек. */
    var showTutorial by mutableStateOf(!prefs.getBoolean("onboarded", false))
        private set
    fun startTutorial() { showTutorial = true }

    /** Обучение заново вместе с подсказками. */
    fun replayOnboarding() { hints.reset(); showTutorial = true }
    fun finishTutorial() { showTutorial = false; prefs.edit().putBoolean("onboarded", true).apply() }

    /** Версия приложения из манифеста: по ней решаем, показывать ли 'Что нового'. */
    private val pkgInfo = runCatching { context.packageManager.getPackageInfo(context.packageName, 0) }.getOrNull()
    val versionName: String = pkgInfo?.versionName ?: ""
    private val versionCode: Int = pkgInfo?.let {
        if (android.os.Build.VERSION.SDK_INT >= 28) it.longVersionCode.toInt()
        else @Suppress("DEPRECATION") it.versionCode
    } ?: 0

    /** 'Что нового' показывается один раз после обновления; при первой установке не показывается. */
    var showNews by mutableStateOf(false)
        private set

    init {
        if (!prefs.getBoolean("onboarded", false)) prefs.edit().putInt("news_seen", versionCode).apply()
        else if (prefs.getInt("news_seen", 0) != versionCode && News.has(versionName)) showNews = true
    }

    fun openNews() { showNews = true }
    fun dismissNews() { showNews = false; prefs.edit().putInt("news_seen", versionCode).apply() }

    /** Тема: 0 - как в системе, 1 - акцентная светлая, 2 - акцентная тёмная, 3 - AMOLED, 4 - AMOLED светлая. */
    var themeMode by mutableIntStateOf(prefs.getInt("theme", 2))
        private set
    /** Акцент: 0 - Vexel, 1 - динамический (обои, Android 12+), 2 - свой цвет из [accentSeed]. */
    var accent by mutableIntStateOf(prefs.getInt("accent", if (prefs.getBoolean("dynamic", false)) 1 else 0))
        private set
    var accentSeed by mutableIntStateOf(prefs.getInt("accent_seed", com.qwenz.qwel.data.Tone.BASE_SEED))
        private set
    val dynamicColor: Boolean get() = accent == 1
    /** Шрифт интерфейса: имя встроенного семейства или пустая строка для системного. */
    var uiFont by mutableStateOf(prefs.getString("ui_font", com.qwenz.qwel.render.Fonts.UI_FONT) ?: com.qwenz.qwel.render.Fonts.UI_FONT)
        private set
    fun updateUiFont(family: String) { uiFont = family; prefs.edit().putString("ui_font", family).apply() }
    fun updateAccent(a: Int) { accent = a.coerceIn(0, 2); prefs.edit().putInt("accent", accent).apply() }
    /** Свой акцент: сохраняет цвет и сразу включает его. */
    fun updateAccentSeed(argb: Int) {
        accentSeed = argb or 0xFF000000.toInt(); accent = 2
        prefs.edit().putInt("accent_seed", accentSeed).putInt("accent", 2).apply()
    }

    /** Вид списка проектов: false - сетка, true - список. */
    var viewList by mutableStateOf(prefs.getBoolean("list", false))
        private set
    /** Сортировка: 0 - недавние, 1 - по имени, 2 - по размеру листа. */
    var sortMode by mutableIntStateOf(prefs.getInt("sort", 0))
        private set
    /** Сколько манулов-питомцев гуляет по приложению (0-5). */
    var pets by mutableIntStateOf(prefs.getInt("pets", 0))
        private set
    fun updatePets(n: Int) { pets = n.coerceIn(0, 5); prefs.edit().putInt("pets", pets).apply() }

    /** Масштаб PNG-экспорта по умолчанию (1-4). */
    var exportScale by mutableIntStateOf(prefs.getInt("scale", 2))
        private set

    fun updateViewList(v: Boolean) { viewList = v; prefs.edit().putBoolean("list", v).apply() }
    fun updateSortMode(m: Int) { sortMode = m; prefs.edit().putInt("sort", m).apply() }
    fun updateExportScale(k: Int) { exportScale = k.coerceIn(1, 4); prefs.edit().putInt("scale", exportScale).apply() }

    fun updateThemeMode(mode: Int) { themeMode = mode; prefs.edit().putInt("theme", mode).apply() }
    /** 'Матовое стекло' в панелях редактора (нужен Android 12+). */
    var glassUi by mutableStateOf(prefs.getBoolean("glass", true))
        private set
    fun updateGlassUi(on: Boolean) { glassUi = on; prefs.edit().putBoolean("glass", on).apply() }

    fun updateDynamicColor(on: Boolean) { updateAccent(if (on) 1 else 0) }

    suspend fun load() {
        if (loaded) return
        val files = withContext(Dispatchers.IO) { store.files() }
        if (files.isEmpty() && !prefs.getBoolean("seeded", false)) {
            val demo = withContext(Dispatchers.IO) {
                Samples.welcome().also { store.save(it); prefs.edit().putBoolean("seeded", true).apply() }
            }
            projects.clear(); projects.add(demo)
            loaded = true
            return
        }
        // Проекты разбираются параллельно и появляются в списке по мере готовности (самые свежие первыми):
        // раньше список ждал, пока по одному прочитаются все файлы, а тяжёлые проекты (с иконками) читаются долго.
        kotlinx.coroutines.coroutineScope {
            val jobs = files.map { f -> async(Dispatchers.Default) { store.read(f) } }
            projects.clear()
            for (j in jobs) {
                j.await()?.let { p -> if (projects.none { it.id == p.id }) projects.add(p) }
                if (!loaded) loaded = true
            }
            if (jobs.isEmpty()) loaded = true
        }
        projects.sortByDescending { it.updated }
        loaded = true
    }

    private fun put(p: Project) {
        val i = projects.indexOfFirst { it.id == p.id }
        if (i >= 0) projects[i] = p else projects.add(0, p)
    }

    fun create(name: String, w: Float, h: Float, tone: Tone = Tone.Baseline, template: ProjectTemplate? = null) {
        val now = System.currentTimeMillis()
        val title = name.trim().ifEmpty { template?.name ?: tr("untitled") }
        val p = template?.toProject(title, tone, now)
            ?: Project(newId(), title, w, h, tone.color(Tok.SURFACE), emptyList(), now, now, tone, Tok.SURFACE)
        put(p); store.save(p)
        open(p)
    }

    fun open(p: Project) { editor = EditorState(projects.firstOrNull { it.id == p.id } ?: p) }

    fun close() { flush(); editor = null }

    /** Синхронное сохранение (уход в фон, закрытие редактора). */
    fun flush() {
        val e = editor ?: return
        if (e.rev == 0) return
        val p = e.toProject(); put(p); store.save(p)
    }

    /** Автосохранение из редактора: запись на IO-потоке. */
    suspend fun saveEditor() {
        val e = editor ?: return
        val p = e.toProject()
        put(p)
        withContext(Dispatchers.IO) { store.save(p) }
    }

    /** Добавляет импортированный проект (из .qwel) в список. */
    fun importProject(p: Project) { put(p); store.save(p) }

    fun rename(id: String, name: String) {
        val p = projects.firstOrNull { it.id == id } ?: return
        val np = p.copy(name = name.trim().ifEmpty { p.name }, updated = System.currentTimeMillis())
        put(np); store.save(np)
    }

    fun duplicate(id: String) {
        val p = projects.firstOrNull { it.id == id } ?: return
        val now = System.currentTimeMillis()
        val copy = p.copy(id = newId(), name = p.name + tr("copy_suffix"), created = now, updated = now)
        put(copy); store.save(copy)
    }

    fun delete(id: String) {
        projects.removeAll { it.id == id }
        store.delete(id)
        // чистим картинки, на которые больше не ссылается ни один проект
        Assets.cleanup(projects.flatMap { p -> p.nodes.map { it.asset } }.filter { it.isNotEmpty() }.toSet())
    }
}
