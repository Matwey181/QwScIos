import SwiftUI

/// Every layer can trigger multiple independent reactions on any other layer.
/// The same editor is used for fresh and previously saved rules.
struct LinkRulesEditor: View {
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
            Divider().padding(.vertical, 4)
            HStack {
                Text("Связки в режиме игры").font(.system(size: 16,weight: .semibold))
                Spacer()
                Text("\(current.count)").foregroundStyle(.secondary)
            }
            Text("Нажатие или движение одного слоя может менять любой другой. Несколько связок работают одновременно.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
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
                .background(Color.secondary.opacity(0.07), in:RoundedRectangle(cornerRadius:14))
            }

            if adding {
                LinkRuleForm(link:$draft,layers:editor.project.nodes)
                    .padding(10)
                    .background(Color.secondary.opacity(0.07),in:RoundedRectangle(cornerRadius:14))
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
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Button {
                    var new=InteractionLink()
                    new.sourceID=source.id
                    new.targetID=source.id
                    draft=new
                    adding=true
                } label: {
                    Label("Добавить связку",systemImage:"plus.circle.fill")
                        .frame(maxWidth:.infinity)
                }.buttonStyle(.bordered)
            }
        }
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
                if link.property == "fill" {
                    ColorPicker("Новый цвет",selection:Binding(
                        get:{Color(argb:link.color)},
                        set:{link.color=UIColor($0).argb}
                    ))
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
                    .textFieldStyle(.roundedBorder)
            }
            if ["animate","echo"].contains(link.mode) {
                numeric("Длительность, секунд",value:$link.duration)
                if link.mode == "animate" {
                    select("Плавность",selection:$link.easing,items:InteractionLink.easings)
                    Toggle("Повторять",isOn:$link.repeats)
                } else {
                    numeric("Сила эха",value:$link.value)
                }
            }
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
        }
    }

    private func select(_ title:String,selection:Binding<String>,items:[(String,String)])->some View {
        VStack(alignment:.leading,spacing:4) {
            Text(title).font(.system(size:13,weight:.medium))
            Picker(title,selection:selection) {
                ForEach(items,id:\.0) { item in Text(item.1).tag(item.0) }
            }.pickerStyle(.menu)
        }
    }
    private func numeric(_ title:String,value:Binding<Double>)->some View {
        HStack {
            Text(title).font(.system(size:13)).fixedSize(horizontal:false,vertical:true)
            Spacer()
            TextField("0",value:value,format:.number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .frame(width:85)
        }
    }
}
