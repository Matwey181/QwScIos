import Foundation
import CoreGraphics

/// A declarative connection between two layers, persisted inside the .qwel project.
/// Events and effects are strings to allow new combinations without a schema migration.
struct InteractionLink: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var sourceID: String = ""
    var event: String = "tap"            // start, tap, dragStart, drag, dragEnd, finished
    var targetID: String = ""
    var mode: String = "animate"         // set, animate, bind, toggle, text, echo
    var property: String = "opacity"     // opacity, x, y, width, height, rotation, scale,
                                        // fill, visible, progress, fontSize, corner, blur
    var value: Double = 1
    var from: Double = 0
    var to: Double = 1
    var duration: Double = 0.45
    var delay: Double = 0
    var easing: String = "easeInOut"    // linear, easeIn, easeOut, easeInOut, spring
    var text: String = "Новый текст"
    var color: Int64 = -16749974
    var repeats: Bool = false
    var enabled: Bool = true

    static let events: [(String, String)] = [
        ("tap", "Нажатие"), ("dragStart", "Начало перетаскивания"),
        ("drag", "Движение пальца"), ("dragEnd", "Отпускание"),
        ("finished", "Завершение анимации"), ("start", "Запуск игры")
    ]
    static let effects: [(String, String)] = [
        ("animate", "Анимировать свойство"), ("set", "Изменить сразу"),
        ("bind", "Связать с движением"), ("toggle", "Переключить видимость"),
        ("text", "Изменить текст"), ("echo", "Эхо / пульсация")
    ]
    static let properties: [(String, String)] = [
        ("opacity", "Непрозрачность"), ("x", "Позиция X"), ("y", "Позиция Y"),
        ("scale", "Масштаб"), ("rotation", "Поворот"),
        ("width", "Ширина"), ("height", "Высота"),
        ("progress", "Прогресс (0–1)"), ("fontSize", "Размер текста"),
        ("corner", "Скругление"), ("blur", "Размытие"), ("fill", "Цвет заливки")
    ]
    static let easings: [(String, String)] = [
        ("linear", "Равномерно"), ("easeIn", "Ускорение"), ("easeOut", "Замедление"),
        ("easeInOut", "Плавно"), ("spring", "Пружина")
    ]

    static func eased(_ raw: Double, _ kind: String) -> Double {
        let t = min(1, max(0, raw))
        switch kind {
        case "easeIn": return t * t * t
        case "easeOut": return 1 - pow(1 - t, 3)
        case "easeInOut": return t < 0.5 ? 4*t*t*t : 1 - pow(-2*t+2, 3)/2
        case "spring": return t == 0 || t == 1 ? t : 1 - pow(2, -10*t) * cos((t*10 - 0.75) * 2 * .pi / 3)
        default: return t
        }
    }
}
