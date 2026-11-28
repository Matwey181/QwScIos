import SwiftUI

struct SafeAreaControls:View {
    @ObservedObject var editor:Editor
    var body:some View {VStack(alignment:.leading,spacing:12){
        QToggle("Показать безопасную область",isOn:Binding(get:{editor.project.studio?.showSafeArea ?? false},set:{v in editor.studio{$0.showSafeArea=v}}))
        Text("Оранжевые полосы — место для системных элементов. Это подсказка на холсте, в экспорт она не попадает. Значения можно изменить под свой экран.").font(qfont(12))
        if editor.project.studio?.showSafeArea==true {
            HStack{QChip(title:"С вырезом"){preset(59,34)};QChip(title:"Без выреза"){preset(20,0)}}
            HStack{QNumber(title:"Сверху",value:Binding(get:{editor.project.studio?.safeTop ?? 59},set:{v in editor.studio{$0.safeTop=max(0,v)}}));QNumber(title:"Снизу",value:Binding(get:{editor.project.studio?.safeBottom ?? 34},set:{v in editor.studio{$0.safeBottom=max(0,v)}}))}
            Button("Поместить выделенное в безопасную область"){let top=editor.project.studio?.safeTop ?? 59,bottom=editor.project.studio?.safeBottom ?? 34,height=editor.project.h;editor.change{$0.y=max(top,min($0.y,height-bottom-$0.h))}}.font(qfont(14,.semibold)).disabled(editor.selection.isEmpty)
        }
    }}
    private func preset(_ top:CGFloat,_ bottom:CGFloat){editor.studio{$0.safeTop=top;$0.safeBottom=bottom}}
}
struct ComponentStateControls:View {
    @ObservedObject var editor:Editor
    let sourceID:String
    @State private var name="Обычно"
    private var source:Node?{editor.project.nodes.first{$0.id==sourceID}}
    private var members:[Node]{guard let n=source else{return []};return editor.project.nodes.filter{$0.id==sourceID || (!n.group.isEmpty && $0.group==n.group)}}
    private var states:[VisualState]{let ids=Set(members.map(\.id));return (editor.project.studio?.states ?? []).filter{!$0.nodes.isEmpty && Set($0.nodes.map(\.id)).isSubset(of:ids)}}
    var body:some View {VStack(alignment:.leading,spacing:12){
        Text("Настройте вид объекта в «Стиле» и запомните его. Для обычного вида и нажатия можно сразу создать пару реакций.").font(qfont(12))
        LinkChoiceField(title:"Какой вид запомнить",selection:$name,items:[("Обычно","Обычно"),("Нажато","Нажато"),("Выбрано","Выбрано"),("Недоступно","Недоступно")])
        LinkPill(title:"Запомнить текущий вид",icon:"camera"){capture()}
        ForEach(states){state in HStack{Text(state.name).font(qfont(14));Spacer();Button("Применить"){editor.applyState(state)};Button("Удалить",role:.destructive){editor.studio{$0.states.removeAll{$0.id==state.id}}}}.font(qfont(13))}
        if states.contains(where:{$0.name=="Обычно"}) && states.contains(where:{$0.name=="Нажато"}){LinkPill(title:"Менять вид при удержании",icon:"hand.tap"){connect()}}
        QToggle("Объект недоступен в игре",isOn:Binding(get:{source?.extras?.disabled ?? false},set:{v in let ids=Set(members.map(\.id));editor.edit{p in for i in p.nodes.indices where ids.contains(p.nodes[i].id){var x=p.nodes[i].extras ?? LayerExtras();x.disabled=v;p.nodes[i].extras=x}}}))
    }}
    private func capture(){var nodes=members;for i in nodes.indices{var x=nodes[i].extras ?? LayerExtras();x.disabled=name=="Недоступно";nodes[i].extras=x};let ids=Set(nodes.map(\.id));let title=name;editor.studio{studio in studio.states.removeAll{$0.name==title && Set($0.nodes.map(\.id))==ids};studio.states.append(VisualState(name:title,nodes:nodes))}}
    private func connect(){guard let normal=states.first(where:{$0.name=="Обычно"}),let pressed=states.first(where:{$0.name=="Нажато"}) else{return};var down=InteractionLink();down.sourceID=sourceID;down.targetID=sourceID;down.event="press";down.mode="state";down.stateID=pressed.id;down.duration=0.15;var up=down;up.id=UUID().uuidString;up.event="release";up.stateID=normal.id;editor.edit{p in p.links.removeAll{$0.sourceID==sourceID && $0.mode=="state" && ["press","release"].contains($0.event)};p.links += [down,up]}}
}
struct SelectedComponentControls:View {
    @ObservedObject var editor:Editor
    @State private var name="Моя кнопка"
    private var definition:ReusableComponent?{guard let id=editor.selected.first?.extras?.definitionID else{return nil};return editor.store.components.first{$0.id==id}}
    var body:some View {VStack(alignment:.leading,spacing:12){
        if let component=definition {
            Text(component.name).font(qfont(16,.semibold))
            Text("Оформление общее, надписи у копий сохраняются.").font(qfont(12))
            LinkPill(title:"Обновить все копии из выделения",icon:"arrow.triangle.2.circlepath"){save(component.name)}
            LinkPill(title:"Вставить ещё копию",icon:"plus"){editor.insertReusable(component)}
        }else{
            QTextField(title:"Название компонента",text:$name)
            LinkPill(title:"Сделать общим компонентом",icon:"square.stack.3d.up"){save(name)}
            Text("Выделите все части кнопки. Сохранённые компоненты находятся в «Добавить → Свои компоненты».").font(qfont(12))
        }
    }.disabled(editor.selection.isEmpty)}
    private func save(_ title:String){do{try editor.saveReusable(title)}catch{editor.error=error.localizedDescription}}
}
@MainActor extension Editor {
    func fitButtonToText(_ id:String){
        guard let text=project.nodes.first(where:{$0.id==id && $0.kind=="TEXT"}) else{return}
        let candidates=project.nodes.filter{$0.kind=="RECT" && ($0.rect.contains(text.rect) || (!text.group.isEmpty && $0.group==text.group))}
        guard let background=candidates.min(by:{$0.w*$0.h<$1.w*$1.h}) else{extras{$0.hugWidth=true};return}
        selection=[text.id,background.id];createAutoLayout()
    }
}
