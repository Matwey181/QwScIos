import Foundation
import CoreGraphics

/// A declarative connection between two layers, persisted inside the .qwel project.
/// Events and effects are strings to allow new combinations without a schema migration.
struct InteractionLink: Codable, Identifiable, Equatable {
    var steps:[InteractionLink]?
    var stepTiming:String?
    var resumeAfterSeek:Bool?
    var pauseOnRepeat:Bool?
    var stateID:String?
    var autoplay:Bool?
    var elapsedEnabled:Bool?
    var remainingEnabled:Bool?
    var elapsedID:String?
    var remainingID:String?
    var clockFormat:String?
    var alternate: Bool?
    var reverseText: String?
    var shapeID: String?
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
        ("tap", "Нажатие"), ("press","Палец на объекте"), ("release","Палец отпущен"), ("valueChanged", "Изменение значения компонента"), ("dragStart", "Начало перетаскивания"),
        ("drag", "Движение пальца"), ("dragEnd", "Отпускание"),
        ("finished", "Завершение анимации"), ("start", "Запуск игры")
    ]
    static let effects: [(String, String)] = [
        ("state", "Перейти в состояние"), ("playback", "Таймер-плеер"), ("animate", "Анимировать свойство"), ("set", "Изменить сразу"),
        ("bind", "Связать с движением"), ("toggle", "Переключить видимость"),
        ("text", "Изменить текст"), ("echo", "Эхо / пульсация")
    ]
    static let properties: [(String, String)] = [
        ("fillOpacity", "Непрозрачность заливки"), ("morph", "Форма / число лучей"), ("echo", "Сила контурного эха"), ("weight", "Толщина шрифта"), ("strokeWidth", "Толщина обводки"), ("stroke", "Цвет обводки"), ("fill2", "Второй цвет"), ("gradAngle", "Угол градиента"), ("shadowBlur", "Размытие тени"), ("shadowDx", "Тень по X"), ("shadowDy", "Тень по Y"), ("shadowColor", "Цвет тени"), ("backgroundBlur", "Размытие фона"), ("opacity", "Непрозрачность"), ("x", "Позиция X"), ("y", "Позиция Y"),
        ("scale", "Масштаб"), ("rotation", "Поворот"),
        ("width", "Ширина"), ("height", "Высота"),
        ("progress", "Значение ползунка / прогресс"), ("fontSize", "Размер текста"),
        ("corner", "Скругление"), ("blur", "Размытие"), ("fill", "Цвет заливки")
    ]
    static let easings: [(String, String)] = [
        ("addButton", "Кнопка +"), ("linear", "Равномерно"), ("easeIn", "Ускорение"), ("easeOut", "Замедление"),
        ("easeInOut", "Плавно"), ("spring", "Пружина")
    ]

    static func eased(_ raw: Double, _ kind: String) -> Double {
        if kind.hasPrefix("mapped:"){return eased(raw,String(kind.dropFirst(7)))}
        if kind.hasPrefix("curve:"),let divider=kind.firstIndex(of:"|") {
            let options=kind[kind.index(kind.startIndex,offsetBy:6)..<divider].split(separator:",").compactMap{Double($0)}
            let hold=min(0.95,max(0,options.first ?? 0))
            let steps=min(240,max(0,options.count>1 ? options[1]:0))
            var time=min(1,max(0,(raw-hold)/(1-hold)))
            if steps>=2 && time<1 {time=floor(time*steps)/steps}
            return eased(time,String(kind[kind.index(after:divider)...]))
        }
        let t = min(1, max(0, raw))
        if kind.hasPrefix("bezier:"),case let points=kind.dropFirst(7).split(separator:",").compactMap({Double($0)}),points.count==4,points.allSatisfy(\.isFinite) {
            func cubic(_ p:Double,_ a:Double,_ b:Double)->Double {3*(1-p)*(1-p)*p*a+3*(1-p)*p*p*b+p*p*p}
            var low=0.0,high=1.0
            for _ in 0..<24 {let mid=(low+high)/2;if cubic(mid,min(1,max(0,points[0])),min(1,max(0,points[2])))<t {low=mid}else{high=mid}}
            return t==0 || t==1 ? t:cubic((low+high)/2,points[1],points[3])
        }
        switch kind {
        case "addButton":
            if t==0 || t==1{return t}
            let omega=2 * Double.pi/0.4,zeta=0.6,time=t*0.8
            let damped=omega*sqrt(1-zeta*zeta)
            return 1-exp(-zeta*omega*time)*(cos(damped*time)+zeta*omega/damped*sin(damped*time))
        case "easeIn": return t * t * t
        case "easeOut": return 1 - pow(1 - t, 3)
        case "easeInOut": return t < 0.5 ? 4*t*t*t : 1 - pow(-2*t+2, 3)/2
        case "spring": return t == 0 || t == 1 ? t : 1 - pow(2, -10*t) * cos((t*10 - 0.75) * 2 * .pi / 3)
        default: return t
        }
    }
}
