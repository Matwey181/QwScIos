import SwiftUI

/// Editor for connections of the form "event on this layer -> effect on any layer".
/// Every change goes through Editor.edit and is saved to the .qwel archive.
struct InteractionEditorPanel: View {
    @ObservedObject var editor: Editor
    var sourceID: String
    @Environment(\.dismiss) private var dismiss

    private var sourceName: String {
        editor.project.nodes.first(where: { $0.id == sourceID })?.name ?? "Слой"
    }
    private var connections: [InteractionLink] {
        editor.project.links.filter { $0.sourceID == sourceID }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Источник: \(sourceName)")
                    Text("Выберите событие и действие, укажите целевой слой. Можно создавать несколько связок для одной кнопки или ползунка.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                ForEach(connections) { item in
                    InteractionLinkRow(editor: editor, id: item.id)
                }

                Section {
                    Button {
                        var link=InteractionLink()
                        link.sourceID=sourceID
                        link.targetID=sourceID
                        editor.edit { $0.links.append(link) }
                    } label: {
                        Label("Добавить связку", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Связки и анимации")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}

struct InteractionLinkRow: View {
    @ObservedObject var editor: Editor
    let id: String
    @State private var expanded=true

    private var link: InteractionLink? {
        editor.project.links.first(where: { $0.id == id })
    }

    private func update(_ modify: @escaping (inout InteractionLink) -> Void) {
        editor.edit { project in
            guard let index=project.links.firstIndex(where: { $0.id == id }) else { return }
            modify(&project.links[index])
        }
    }
    private func string(_ key: WritableKeyPath<InteractionLink,String>) -> Binding<String> {
        Binding(get: { link?[keyPath:key] ?? "" },
                set: { value in update { $0[keyPath:key]=value } })
    }
    private func number(_ key: WritableKeyPath<InteractionLink,Double>) -> Binding<Double> {
        Binding(get: { link?[keyPath:key] ?? 0 },
                set: { value in update { $0[keyPath:key]=value.isFinite ? value : 0 } })
    }
    private func boolean(_ key: WritableKeyPath<InteractionLink,Bool>) -> Binding<Bool> {
        Binding(get: { link?[keyPath:key] ?? false },
                set: { value in update { $0[keyPath:key]=value } })
    }
    private var targetNodes: [Node] { editor.project.nodes }

    var body: some View {
        if let rule=link {
            Section {
                DisclosureGroup(isExpanded: $expanded) {
                    Toggle("Включена", isOn: boolean(\.enabled))
                    Picker("Когда", selection: string(\.event)) {
                        ForEach(InteractionLink.events,id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                    Picker("Действие", selection: string(\.mode)) {
                        ForEach(InteractionLink.effects,id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                    Picker("Изменить слой",selection: string(\.targetID)) {
                        ForEach(targetNodes) { node in
                            Text(node.name).tag(node.id)
                        }
                    }
                    if ["animate","set","bind"].contains(rule.mode) {
                        Picker("Свойство",selection: string(\.property)) {
                            ForEach(InteractionLink.properties,id: \.0) { option in
                                Text(option.1).tag(option.0)
                            }
                        }
                        if rule.mode == "bind" {
                            HStack {
                                Text("От")
                                Spacer()
                                TextField("0",value:number(\.from),format:.number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            }
                            HStack {
                                Text("До")
                                Spacer()
                                TextField("1",value:number(\.to),format:.number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            }
                        } else if rule.property=="fill" {
                            Text("Цвет цели указывается в ARGB как целое число")
                                .font(.caption).foregroundStyle(.secondary)
                            TextField("ARGB",value:Binding(get:{rule.color},set:{v in update{$0.color=v}}),format:.number)
                                .keyboardType(.numbersAndPunctuation)
                        } else {
                            HStack {
                                Text("Значение")
                                Spacer()
                                TextField("1",value:number(\.value),format:.number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    if rule.mode=="text" {
                        TextField("Новый текст",text:string(\.text),axis:.vertical)
                            .lineLimit(2...5)
                    }
                    if rule.mode=="echo" {
                        HStack {
                            Text("Сила эха")
                            Spacer()
                            TextField("1",value:number(\.value),format:.number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        }
                    }
                    if rule.mode=="animate" || rule.mode=="echo" {
                        HStack {
                            Text("Длительность (сек.)")
                            Spacer()
                            TextField("0.45",value:number(\.duration),format:.number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("Задержка (сек.)")
                            Spacer()
                            TextField("0",value:number(\.delay),format:.number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        }
                        if rule.mode=="animate" {
                            Picker("Плавность", selection: string(\.easing)) {
                                ForEach(InteractionLink.easings,id: \.0) { option in
                                    Text(option.1).tag(option.0)
                                }
                            }
                            Toggle("Повторять",isOn:boolean(\.repeats))
                        }
                    }
                    Button(role:.destructive) {
                        editor.edit { $0.links.removeAll { $0.id==id } }
                    } label: {
                        Label("Удалить связку",systemImage:"trash")
                    }
                } label: {
                    VStack(alignment:.leading,spacing:3) {
                        Text(InteractionLink.events.first(where:{$0.0==rule.event})?.1 ?? rule.event)
                            .font(.headline)
                        Text((InteractionLink.effects.first(where:{$0.0==rule.mode})?.1 ?? rule.mode) + " → " +
                             (editor.project.nodes.first(where:{$0.id==rule.targetID})?.name ?? "слой"))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
