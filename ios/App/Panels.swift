import SwiftUI

struct InspectorPanel:View {
    @Environment(\.q) var q
    @ObservedObject var editor:Editor
    var importFont:()->Void
    var node:Node? { editor.selected.first }
    func value<T>(_ key:WritableKeyPath<Node,T>,fallback:T)->Binding<T> { Binding(get:{node?[keyPath:key] ?? fallback},set:{v in editor.change { $0[keyPath:key]=v }}) }
    func color(_ key:WritableKeyPath<Node,Int64>)->Binding<Color> { Binding(get:{Color(argb:node?[keyPath:key] ?? 0)},set:{c in editor.change { $0[keyPath:key]=UIColor(c).argb;if key==\Node.fill { $0.fillToken = -1 };if key==\Node.stroke { $0.strokeToken = -1 } }}) }
    var body:some View {
        VStack(alignment:.leading,spacing:14) {
            if let n=node {
                QSection("Слой") { TextField("Название",text:value(\.name,fallback:""));QToggle("Блокировка",isOn:value(\.locked,fallback:false));QToggle("Видимость",isOn:value(\.visible,fallback:true)) }
                transform
                if n.kind=="TEXT" { textStyle }
                QSection("Цвет и заливка") {
                    ColorPicker("Заливка",selection:color(\.fill),supportsOpacity:true)
                    if !["TEXT","IMAGE"].contains(n.kind) {
                        Picker("Градиент",selection:value(\.gradKind,fallback:0)) { Text("Нет").tag(Int64(0));Text("Линейный").tag(Int64(1));Text("Радиальный").tag(Int64(2)) }
                        if n.gradKind != 0 { ColorPicker("Второй цвет",selection:color(\.fill2),supportsOpacity:true);number("Угол градиента",\.gradAngle) }
                    }
                    LabeledContent("Прозрачность",value:"\(Int(n.opacity*100))%")
                    QSlider(value:Binding(get:{Double(node?.opacity ?? 1)},set:{v in editor.change{$0.opacity=CGFloat(v)}}))
                    if editor.project.tone.colors.count==22 {
                        ScrollView(.horizontal,showsIndicators:false) { HStack { ForEach(0..<22,id:\.self) { index in Button { editor.change { $0.fill=editor.project.tone.colors[index];$0.fillToken=Int64(index) } } label:{Circle().fill(Color(argb:editor.project.tone.colors[index])).frame(width:30,height:30).overlay(Circle().stroke(.gray.opacity(0.3)))} } } }
                    }
                }
                QSection("Обводка и форма") {
                    ColorPicker("Цвет обводки",selection:color(\.stroke),supportsOpacity:true)
                    number("Толщина",\.strokeWidth)
                    if n.kind=="RECT" { number("Скругление",\.corner);number("Скругление при нажатии (−1 — выкл.)",\.pressCorner) }
                    QToggle("Маска для нижнего слоя",isOn:value(\.mask,fallback:false))
                    QToggle("Пропорции",isOn:value(\.ratioLock,fallback:false))
                }
                QSection("Эффекты") {
                    number("Размытие слоя",\.softBlur)
                    number("Размытие фона",\.blur)
                    number("Тень: размытие",\.shadowBlur)
                    number("Тень: X",\.shadowDx);number("Тень: Y",\.shadowDy)
                    ColorPicker("Цвет тени",selection:color(\.shadowColor),supportsOpacity:true)

                }
                QSection("Действия в режиме «Играть»") {
                    TextField("goto:ID, back, toggle:ID или url:https://…",text:value(\.action,fallback:"")).font(qfont(12)).textInputAutocapitalization(.never)
                    Text("ID слоя: \(n.id)").font(qfont(12)).textSelection(.enabled)
                }
                QSection {
                    HStack { Button("На передний план") { editor.front(true) };Spacer();Button("На задний план") { editor.front(false) } }
                    HStack { Button("Группа") { editor.group() };Spacer();Button("Разгруппировать") { editor.ungroup() } }
                    Button("Дублировать") { editor.duplicate() }
                    Button("Удалить",role:.destructive) { editor.remove() }
                }
            } else { QSection { Text("Выбери слой на холсте или в панели «Слои».").foregroundStyle(.secondary) } }
        }
    }
    private var transform:some View {
        QSection("Положение и размер") {
            number("X",\.x);number("Y",\.y);number("Ширина",\.w);number("Высота",\.h);number("Поворот",\.rotation)
        }
    }
    private var textStyle:some View {
        QSection("Текст") {
            TextField("Текст",text:value(\.text,fallback:""),axis:.vertical).lineLimit(2...8)
            number("Размер шрифта",\.fontSize)
            Picker("Начертание",selection:value(\.weight,fallback:400)) { Text("Лёгкий").tag(Int64(300));Text("Обычный").tag(Int64(400));Text("Средний").tag(Int64(500));Text("Полужирный").tag(Int64(600));Text("Жирный").tag(Int64(700)) }
            Button("Импорт шрифта .ttf / .otf",action:importFont)
            Button("Системный шрифт") { editor.change { $0.font="" } }
            Button("Подогнать рамку под текст") { editor.change { n in let size=(n.text as NSString).boundingRect(with:CGSize(width:10000,height:10000),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:[.font:editor.renderer.font(n)],context:nil).size;n.w=ceil(size.width+2);n.h=ceil(size.height+2) } }
        }
    }
    private func number(_ title:String,_ key:WritableKeyPath<Node,CGFloat>)->some View {
        HStack { Text(title);Spacer();TextField("0",value:Binding<Double>(get:{Double(node?[keyPath:key] ?? 0)},set:{v in editor.change{$0[keyPath:key]=CGFloat(v)}}),format:.number.precision(.fractionLength(0...2))).keyboardType(.numbersAndPunctuation).multilineTextAlignment(.trailing).frame(maxWidth:120) }
    }
}
struct LayersPanel:View {
    @Environment(\.q) var q
    @ObservedObject var editor:Editor
    var body:some View {
        VStack(alignment:.leading,spacing:4) {
            QSection { QToggle("Выбор нескольких",isOn:$editor.multiSelect) }
            ForEach(editor.project.nodes.reversed()) { n in
                HStack {
                    Button { editor.choose(n) } label:{HStack { QIcon(id:editor.selection.contains(n.id) ? "Check":"Layers",tint:q.color("primary"));VStack(alignment:.leading) { Text(n.name).font(qfont(16,.semibold));Text(n.kind+(n.group.isEmpty ? "":" · группа")).font(qfont(12)).foregroundStyle(.secondary) };Spacer() }}.buttonStyle(.plain)
                    Button { editor.edit { p in if let i=p.nodes.firstIndex(where:{$0.id==n.id}) { p.nodes[i].visible.toggle() } } } label:{QIcon(id:n.visible ? "Eye":"EyeOff")}.buttonStyle(.borderless)
                    Button { editor.edit { p in if let i=p.nodes.firstIndex(where:{$0.id==n.id}) { p.nodes[i].locked.toggle() } } } label:{QIcon(id:n.locked ? "Lock":"Unlock")}.buttonStyle(.borderless)
                }.padding(.vertical,4)
            }.onMove { from,to in editor.edit { p in var reversed=Array(p.nodes.reversed());reversed.move(fromOffsets:from,toOffset:to);p.nodes=Array(reversed.reversed()) } }
            .onDelete { offsets in let list=Array(editor.project.nodes.reversed());let ids=Set(offsets.map{list[$0].id});editor.edit { $0.nodes.removeAll{ids.contains($0.id)} };editor.selection.subtract(ids) }
        }
    }
}
struct AlignPanel:View {
    @Environment(\.q) var q
    @ObservedObject var editor:Editor
    var body:some View {
        VStack(alignment:.leading,spacing:4) {
            QSection("Выравнивание") {
                ForEach([("left","По левому краю"),("centerX","По горизонтальному центру"),("right","По правому краю"),("top","По верхнему краю"),("centerY","По вертикальному центру"),("bottom","По нижнему краю")],id:\.0) { mode,title in Button(title) { editor.align(mode) } }
                Button("Равные промежутки по горизонтали") { editor.distribute(true) };Button("Равные промежутки по вертикали") { editor.distribute(false) }
            }.disabled(editor.selection.isEmpty)
            QSection("Булевы операции") {
                Button("Объединение") { editor.boolean("union") };Button("Пересечение") { editor.boolean("intersection") };Button("Разность") { editor.boolean("subtract") };Button("Исключение") { editor.boolean("xor") }
            }.disabled(editor.selection.count<2)
            QSection { Text("Один выбранный слой выравнивается по холсту. Несколько — по общей рамке.").font(qfont(12)).foregroundStyle(.secondary) }
        }
    }
}
struct DocumentPanel:View {
    @Environment(\.q) var q
    @ObservedObject var editor:Editor
    @State private var seed=Color.teal
    @State private var dark=false
    var body:some View {
        VStack(alignment:.leading,spacing:14) {
            QSection("Холст") {
                TextField("Название",text:Binding(get:{editor.project.name},set:{v in editor.edit{$0.name=v}}))
                HStack { Text("Ширина");TextField("390",value:Binding(get:{Double(editor.project.w)},set:{v in editor.edit{$0.w=CGFloat(min(8192,max(16,v)))}}),format:.number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                HStack { Text("Высота");TextField("844",value:Binding(get:{Double(editor.project.h)},set:{v in editor.edit{$0.h=CGFloat(min(8192,max(16,v)))}}),format:.number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                ColorPicker("Фон",selection:Binding(get:{Color(argb:editor.project.bg)},set:{v in editor.edit{$0.bg=UIColor(v).argb;$0.bgToken = -1}}),supportsOpacity:true)
            }
            QSection("Тон проекта") { ColorPicker("Основной цвет",selection:$seed,supportsOpacity:false);QToggle("Тёмный тон",isOn:$dark);Button("Применить ко всем цветовым токенам") { editor.applyTone(UIColor(seed).argb,dark:dark) } }
            QSection("Экраны") {
                ForEach(Array(editor.project.pages.enumerated()),id:\.element.id) { index,page in
                    Button { editor.page(index) } label:{HStack { Text(page.name);Spacer();if editor.project.active==index { QIcon(id:"Check") } }}
                    Text("ID: \(page.id)").font(qfont(12)).textSelection(.enabled)
                }
                Button("Добавить экран") { editor.addPage() }
            }
        }
    }
}
