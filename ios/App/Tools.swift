import Foundation

struct ToolField: Identifiable {
    enum Kind { case file, files, integer, text, choice, output, constant }
    let id: String
    let label: String
    let kind: Kind
    var initial = ""
    var choices: [String] = []
    var required = true
    static func file(_ id: String, _ label: String) -> Self { .init(id: id, label: label, kind: .file) }
    static func text(_ id: String, _ label: String, _ value: String = "", required: Bool = true) -> Self {
        .init(id: id, label: label, kind: .text, initial: value, required: required)
    }
    static func int(_ id: String, _ label: String, _ value: Int) -> Self {
        .init(id: id, label: label, kind: .integer, initial: String(value))
    }
    static let out = Self(id: "out", label: "", kind: .output)
    static func constant(_ id: String, _ value: String) -> Self { .init(id: id, label: "", kind: .constant, initial: value) }
    static let block = Self(id: "block", label: "Блок ASTC", kind: .choice, initial: "8x8", choices: ["4x4", "5x4", "5x5", "6x5", "6x6", "8x5", "8x6", "8x8", "10x5", "10x6", "10x8", "10x10", "12x10", "12x12"])
}

struct Tool: Identifiable {
    let id: String
    let title: String
    let section: String
    let icon: String
    let fields: [ToolField]
    var note = ""
    var operation: String { "native" + id }
    static let all: [Self] = [
        .init(id: "Sctx2Png", title: "SCTX → PNG", section: "Текстуры", icon: "photo", fields: [.file("input", "Файл SCTX"), .out]),
        .init(id: "Png2Sctx", title: "PNG → SCTX", section: "Текстуры", icon: "photo.badge.arrow.down", fields: [.file("input", "Изображение PNG"), .out]),
        .init(id: "Ktx2Png", title: "KTX → PNG", section: "Текстуры", icon: "photo", fields: [.file("input", "Файл KTX"), .out]),
        .init(id: "Png2Ktx", title: "PNG → KTX", section: "Текстуры", icon: "photo.badge.arrow.down", fields: [.file("input", "Изображение PNG"), .block, .out]),
        .init(id: "Png2Sc", title: "Заменить спрайт / атлас", section: "Текстуры", icon: "arrow.triangle.2.circlepath", fields: [.file("png", "Новое изображение PNG"), .file("sc", "Исходный SC"), .int("shape", "ID Shape (−1: весь атлас SC1)", 0), .constant("rotate", "0"), .out]),
        .init(id: "Png2ScBatch", title: "Пакетная замена спрайтов", section: "Текстуры", icon: "square.stack", fields: [.file("list", "Список замен TXT"), .file("sc", "Исходный SC"), .out], note: "Строка списка: ID Shape, табуляция, полный путь к импортированному PNG. Пути можно скопировать во вкладке «Файлы»."),
        .init(id: "ScInfo", title: "Информация о SC", section: "Файлы SC", icon: "info.circle", fields: [.file("input", "Файл SC")]),
        .init(id: "SplitSc", title: "Разделить SC", section: "Файлы SC", icon: "arrow.triangle.branch", fields: [.file("input", "Файл SC"), .out]),
        .init(id: "JoinSc", title: "Объединить SC", section: "Файлы SC", icon: "arrow.triangle.merge", fields: [.file("logic", "Логика SC"), .file("tex", "Текстура SC"), .out]),
        .init(id: "ExtractKtx", title: "Извлечь KTX", section: "Файлы SC", icon: "square.and.arrow.down", fields: [.file("sc", "Файл SC"), .int("index", "Индекс текстуры", 0), .out]),
        .init(id: "Sc2Png", title: "SC → PNG", section: "Файлы SC", icon: "photo", fields: [.file("sc", "Файл SC"), .int("index", "Индекс текстуры", 0), .out]),
        .init(id: "CutSprites", title: "Извлечь спрайты", section: "Файлы SC", icon: "scissors", fields: [.file("logic", "Логика SC"), .file("tex", "Текстура SC"), .out]),
        .init(id: "Exports", title: "Экспорт ресурсов SC", section: "Файлы SC", icon: "square.and.arrow.up", fields: [.file("sc", "Файл SC"), .out]),
        .init(id: "GetExports", title: "Список экспортнеймов", section: "Редактирование", icon: "list.bullet", fields: [.file("sc", "Файл SC")]),
        .init(id: "EditExports", title: "Изменить экспортнеймы из TXT", section: "Редактирование", icon: "pencil", fields: [.file("ops", "Файл изменений TXT"), .file("sc", "Файл SC"), .out], note: "Поля разделяются табуляцией. R + индекс + имя: переименовать. D + индекс: удалить. A + object ID + имя: добавить."),
        .init(id: "GetMovieClips", title: "Список MovieClip", section: "Анимации", icon: "film", fields: [.file("sc", "Файл SC")]),
        .init(id: "Gif2Sc", title: "GIF → SC", section: "Анимации", icon: "film.stack", fields: [.file("gif", "Анимация GIF"), .text("name", "Экспортнейм", "background"), .int("fps", "Кадров в секунду", 30), .init(id: "screen", label: "Режим экрана (1: 2048 / 2: 1848)", kind: .choice, initial: "1", choices: ["1", "2"]), .text("bg", "Цвет фона RRGGBB", "000000"), .init(id: "format", label: "Формат текстуры (0: ASTC / 1: RGBA)", kind: .choice, initial: "0", choices: ["0", "1"]), .out]),
        .init(id: "Sc2Gif", title: "SC → GIF", section: "Анимации", icon: "film", fields: [.file("sc", "Файл SC"), .text("name", "Экспортнейм (пусто: автоматически)", required: false), .int("side", "Максимальная сторона, px", 512), .int("fps", "Кадров в секунду", 30), .out]),
        .init(id: "Anim2Static", title: "Анимация → статика", section: "Анимации", icon: "pause.rectangle", fields: [.file("sc", "Файл SC"), .out]),
        .init(id: "BuildSc", title: "Создать SC из PNG", section: "Сборка", icon: "hammer", fields: [.init(id: "pngs", label: "Изображения PNG", kind: .files), .text("names", "Экспортнеймы через запятую", required: false), .block, .out]),
        .init(id: "McCopy", title: "Копировать MovieClip", section: "Сборка", icon: "doc.on.doc", fields: [.file("source", "Исходный SC"), .file("destination", "Целевой SC"), .text("names", "Экспортнеймы через запятую"), .out]),
        .init(id: "InjectList", title: "Список для вставки", section: "Вставка", icon: "list.bullet", fields: [.file("sc", "Файл SC")]),
        .init(id: "InjectPreview", title: "Превью для вставки", section: "Вставка", icon: "eye", fields: [.file("sc", "Файл SC"), .out]),
        .init(id: "InjectPut", title: "Вставить спрайт", section: "Вставка", icon: "plus.square", fields: [.file("sc", "Файл SC"), .file("sprite", "Спрайт PNG"), .text("name", "Экспортнейм"), .out])
    ]
}
