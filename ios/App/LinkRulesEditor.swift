import SwiftUI

/// Every layer can trigger multiple independent reactions on any other layer.
/// The same editor is used for fresh and previously saved rules.
struct LinkRulesEditor: View {
    @Environment(\.q) private var q
    @ObservedObject var editor: Editor
    let source: Node
    @State private var adding = false
    @State private var draft = InteractionLink()
    @State private var expandedID: String?

    private var current: [InteractionLink] {
        editor.project.links.filter { $0.sourceID == source.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Связки в режиме игры").font(qfont(20,.semibold))
                Spacer()
                Text("\(current.count)").foregroundStyle(.secondary)
            }
            Text("Нажатие или движение одного слоя может менять любой другой. Несколько связок работают одновременно.")
                .font(qfont(12)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if current.isEmpty && !adding {
                Text("Для этого слоя пока нет связок.")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
            }
            ForEach(current) { link in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button {
                            expandedID = expandedID == link.id ? nil : link.id
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: expandedID == link.id ? "chevron.down" : "chevron.right")
                                Text(summary(link)).lineLimit(2).multilineTextAlignment(.leading)
                            }
                            .font(.system(size: 13, weight: .medium))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { editor.project.links.first(where:{$0.id==link.id})?.enabled ?? false },
                            set: { value in editor.edit { p in
                                if let index=p.links.firstIndex(where:{$0.id==link.id}) { p.links[index].enabled=value }
                            }}
                        )).labelsHidden()
                        Button {
                            var copy=link;copy.id=UUID().uuidString;editor.edit{$0.links.append(copy)};expandedID=copy.id
                        } label:{Image(systemName:"doc.on.doc")}.buttonStyle(.plain).accessibilityLabel("Дублировать связку")
                        Button(role: .destructive) {
                            editor.edit { $0.links.removeAll(where:{$0.id == link.id}) }
                            if expandedID == link.id {expandedID=nil}
                        } label: {Image(systemName:"trash").foregroundStyle(.red)}
                        .buttonStyle(.plain)
                    }
                    if expandedID == link.id {
                        LinkRuleForm(link: binding(for:link.id), layers:editor.project.nodes)
                    }
                }
                .padding(12)
                .qSurface(24,"surfaceContainerHigh")
            }

            if adding {
                LinkRuleForm(link:$draft,layers:editor.project.nodes)
                    .padding(10)
                    .qSurface(24,"surfaceContainerHigh")
                HStack {
                    Button("Отмена") {adding=false}.buttonStyle(.bordered)
                    Button("Сохранить связку") {
                        var link=draft
                        link.sourceID=source.id
                        if link.targetID.isEmpty {link.targetID=source.id}
                        editor.edit {$0.links.append(link)}
                        adding=false
                        expandedID=link.id
                    }
                    .buttonStyle(.borderedProminent).tint(q.color("primary"))
                }
            } else {
                Button {
                    preset("custom")
                } label: {
                    Label("Добавить связку",systemImage:"plus.circle.fill")
                        .frame(maxWidth:.infinity)
                }.buttonStyle(.bordered)
                Text("Быстрые примеры").font(.system(size:12,weight:.medium))
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal,showsIndicators:false) {
                    HStack(spacing:6) {
                        Button("▶ 15 секунд") {preset("progress")}
                        Button("Текст") {preset("text")}
                        Button("Размер от жеста") {preset("scale")}
                        Button("Эхо") {preset("echo")}
                        Button("Форма 5 ↔ 8") {preset("morph")}
                    }
                    .font(.system(size:12))
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func preset(_ kind:String) {
        var new=InteractionLink()
        new.sourceID=source.id
        new.targetID=source.id
        switch kind {
        case "morph":
            new.property="morph";new.shapeID="star-8";new.alternate=true;new.duration=0.5
        case "progress":
            new.event="tap"
            new.mode="animate"
            new.property="progress"
            new.duration=15
            new.easing="linear"
        case "text":
            new.event="tap"
            new.mode="text"
            new.text="Новый текст";new.alternate=true
        case "scale":
            new.event="drag"
            new.mode="bind"
            new.property="scale"
            new.from=0.7
            new.to=1.5
        case "echo":
            new.event="drag"
            new.mode="echo"
            new.duration=1
            new.value=1
        default:break
        }
        draft=new
        adding=true
    }

    private func summary(_ link:InteractionLink)->String {
        let event=InteractionLink.events.first(where:{$0.0==link.event})?.1 ?? link.event
        let effect=InteractionLink.effects.first(where:{$0.0==link.mode})?.1 ?? link.mode
        let target=editor.project.nodes.first(where:{$0.id==link.targetID})?.name ?? "Удалённый слой"
        return "\(event) → \(effect) → \(target)"
    }

    private func binding(for id:String)->Binding<InteractionLink> {
        Binding(
            get: {editor.project.links.first(where:{$0.id==id}) ?? InteractionLink()},
            set: {next in editor.edit { project in
                guard let index=project.links.firstIndex(where:{$0.id==id}) else { return }
                project.links[index]=next
            }}
        )
    }
}

private struct LinkRuleForm: View {
    @Binding var link: InteractionLink
    let layers: [Node]
    @Environment(\.q) private var q
    private var target:Node?{layers.first{$0.id==link.targetID}}
    private var colorProperty:Bool{["fill","stroke","fill2","shadowColor"].contains(link.property)}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            select("Когда",selection:$link.event,items:InteractionLink.events)
            select("Что сделать",selection:$link.mode,items:InteractionLink.effects)
            VStack(alignment: .leading,spacing:6) {
                Text("На каком слое").font(.system(size:13,weight:.medium))
                Picker("Целевой слой", selection:$link.targetID) {
                    ForEach(layers){ layer in
                        Text(layer.name).tag(layer.id)
                    }
                }
                .pickerStyle(.menu)
            }
            if ["set","animate","bind"].contains(link.mode) {
                select("Что менять",selection:$link.property,items:InteractionLink.properties)
                if link.property=="morph" {
                    Text("Плавный переход между исходными фигурами MD3. Например: Звезда 5 ↔ Звезда 8.").font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"))
                    ScrollView(.horizontal,showsIndicators:false){HStack(spacing:10){ForEach(Catalog.shared.shapes){shape in
                        Button{link.shapeID=shape.id}label:{VStack(spacing:6){ShapePreview(shape:shape).fill(q.color("primary")).frame(width:42,height:42);Text(shape.name).font(qfont(11)).lineLimit(1)}.frame(width:85).padding(12).qSurface(20,link.shapeID==shape.id ? "primaryContainer":"surfaceContainerHighest")}.buttonStyle(.plain)
                    }}}
                    if target?.kind != "SHAPE" {Text("Для перехода формы выберите целевую фигуру из раздела MD3.").font(qfont(12)).foregroundStyle(.orange)}
                    if link.mode=="bind"{numeric("При 0%",value:$link.from);numeric("При 100%",value:$link.to)}
                } else if colorProperty {
                    QColorRow(title:"Новый цвет",color:$link.color,colors:[])
                    if link.mode=="bind"{Text("Цвет плавно меняется от исходного к выбранному.").font(qfont(12)).foregroundStyle(.secondary)}
                } else if link.mode == "bind" {
                    numeric("Значение в начале жеста", value:$link.from)
                    numeric("Значение в конце жеста", value:$link.to)
                    Text("Например: потянули ползунок → размер фигуры меняется от 1 до 2.")
                        .font(.system(size:11)).foregroundStyle(.secondary)
                } else if link.property != "progress" {
                    numeric("Итоговое значение",value:$link.value)
                } else {
                    Text("Прогресс от 0 до 100% за указанное время. Подходит для анимированной шкалы.")
                        .font(.system(size:12)).foregroundStyle(.secondary)
                }
            }
            if link.mode == "text" {
                TextField("Текст после действия",text:$link.text,axis:.vertical)
                    .lineLimit(1...4)
                    .padding(10).qSurface(12,"surfaceContainerHighest")
            }
            if ["animate","set","text"].contains(link.mode) {
                QToggle("Повторное нажатие возвращает обратно",isOn:Binding(get:{link.alternate ?? false},set:{link.alternate=$0}))
                if link.mode=="text" && link.alternate==true {TextField("Обратный текст (пусто = исходный)",text:Binding(get:{link.reverseText ?? ""},set:{link.reverseText=$0.isEmpty ? nil:$0}),axis:.vertical).lineLimit(2...4).padding(12).qSurface(16,"surfaceContainerHighest")}
            }
            if ["animate","echo"].contains(link.mode) {
                numeric("Длительность, секунд",value:$link.duration)
                if link.mode == "animate" {
                    LinkCurveEditor(easing:$link.easing)
                    QToggle("Повторять",isOn:$link.repeats)
                } else {
                    numeric("Сила эха",value:$link.value)
                }
            }
            if link.mode=="bind" {LinkCurveEditor(easing:$link.easing)}
            if link.mode != "bind" {
                numeric("Задержка, секунд",value:$link.delay)
            }
            if link.mode == "bind" && link.event != "drag" {
                Text("Для непрерывного управления выбери событие «Движение пальца».")
                    .font(.system(size:12)).foregroundStyle(.orange)
            }
            if link.event == "finished" {
                Text("Срабатывает, когда заканчивается анимация выбранного слоя.")
                    .font(.system(size:12)).foregroundStyle(.secondary)
            }
        }.onChange(of:link.property){_,property in
            if property=="morph" && link.shapeID==nil {link.shapeID="star-8";link.from=0;link.to=1}
        }
    }

    private func select(_ title:String,selection:Binding<String>,items:[(String,String)])->some View {
        VStack(alignment:.leading,spacing:4) {
            Text(title).font(.system(size:13,weight:.medium))
            Picker(title,selection:selection) {
                ForEach(items,id:\.0) { item in Text(item.1).tag(item.0) }
            }.pickerStyle(.menu).tint(q.color("primary")).frame(maxWidth:.infinity,alignment:.leading).padding(10).qSurface(16,"surfaceContainerHighest")
        }
    }
    private func numeric(_ title:String,value:Binding<Double>)->some View {
        HStack {
            Text(title).font(.system(size:13)).fixedSize(horizontal:false,vertical:true)
            Spacer()
            TextField("0",value:value,format:.number)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .padding(10).qSurface(12,"surfaceContainerHighest")
                .frame(width:85)
        }
    }
}
