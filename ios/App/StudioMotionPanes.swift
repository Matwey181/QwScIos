import SwiftUI

struct StudioStates:View {
    @ObservedObject var editor:Editor
    var sourceID:String?=nil
    @State private var name="Обычно"
    @State private var whole=false
    var body:some View {VStack(spacing:16){
        StudioCard(title:"Снимки оформления"){
            Text("Снимок запоминает вид и расположение слоёв. Измените дизайн, сохраните второй снимок и свяжите переход с кнопкой.").font(qfont(13))
            ScrollView(.horizontal,showsIndicators:false){HStack{ForEach(["Обычно","Нажато","Выбрано","Выключено"],id:\.self){value in QChip(title:value,selected:name==value){name=value}}}}
            QTextField(title:"Название состояния",text:$name)
            QToggle("Запомнить весь экран",isOn:$whole)
            LinkPill(title:"Снять состояние",icon:"camera",prominent:true){editor.captureState(name,wholeScreen:whole)}.disabled(!whole && editor.selected.isEmpty)
        }
        ForEach((editor.project.studio?.states ?? []).filter{state in sourceID==nil || state.nodes.contains{$0.id==sourceID}}){state in StudioCard(title:state.name){
            EffectPreview(nodes:state.nodes,renderer:editor.renderer).frame(height:140)
            HStack{LinkPill(title:"Применить",icon:"checkmark"){editor.applyState(state)};LinkPill(title:"Связать",icon:"link"){var rule=InteractionLink();rule.mode="state";rule.stateID=state.id;rule.targetID=state.nodes.first?.id ?? "";rule.sourceID=editor.selected.first?.id ?? rule.targetID;rule.duration=0.6;rule.alternate=true;editor.edit{$0.links.append(rule)}}}
            Button("Удалить состояние",role:.destructive){editor.studio{$0.states.removeAll{$0.id==state.id}}}
        }}
    }}
}
struct StudioTimeline:View {
    @ObservedObject var editor:Editor
    @Environment(\.q) private var q
    var sourceID:String?=nil
    @State private var selected:String?
    private var animations:[InteractionLink]{editor.project.links.filter{["animate","echo","state","playback"].contains($0.mode) && (sourceID==nil || $0.sourceID==sourceID)}}
    private var extent:Double{max(1,animations.map{max(0,$0.delay)+max(0.01,$0.duration)}.max() ?? 1)}
    var body:some View {VStack(spacing:16){
        StudioCard(title:"Общий таймлайн"){
            EffectPreview(nodes:(editor.originalPlay.display ?? editor.project).nodes,renderer:editor.renderer).frame(height:180)
            LinkPill(title:editor.playing ? "Остановить просмотр":"Просмотр",icon:editor.playing ? "stop.fill":"play.fill",prominent:true){editor.togglePlay()}
            Text("\(animations.count) анимаций · шкала \(Int(extent.rounded(.up))) с").font(qfont(13))
            ForEach(animations){rule in lane(rule)}
            if animations.isEmpty{Text("Создайте анимацию в связках — она появится здесь.").font(qfont(13))}
        }
        if let id=selected,let rule=editor.project.links.first(where:{$0.id==id}){StudioCard(title:"Параметры дорожки"){
            QToggle("Включена",isOn:Binding(get:{rule.enabled},set:{v in update(id){$0.enabled=v}}))
            QNumber(title:"Начало · задержка",value:Binding(get:{CGFloat(rule.delay)},set:{v in update(id){$0.delay=max(0,Double(v))}}))
            QNumber(title:"Длительность",value:Binding(get:{CGFloat(rule.duration)},set:{v in update(id){$0.duration=max(0.01,Double(v))}}))
            LinkCurveEditor(easing:Binding(get:{rule.easing},set:{v in update(id){$0.easing=v}}))
        }}
    }}
    private func lane(_ rule:InteractionLink)->some View {
        Button{selected=rule.id}label:{VStack(alignment:.leading,spacing:7){
            Text(editor.project.nodes.first{$0.id==rule.targetID}?.name ?? "Слой").font(qfont(13,.medium))
            GeometryReader{g in
                ZStack(alignment:.leading){Capsule().fill(q.color("surfaceContainerHighest"));Capsule().fill(q.color(rule.enabled ? "primary":"outline")).frame(width:max(6,g.size.width*CGFloat(max(0.01,rule.duration)/extent))).offset(x:g.size.width*CGFloat(max(0,rule.delay)/extent))}
            }.frame(height:20)
            Text(String(format:"%.2f → %.2f с",rule.delay,rule.delay+rule.duration)).font(qfont(11)).foregroundStyle(q.color("onSurfaceVariant"))
        }.padding(10).qSurface(18,selected==rule.id ? "primaryContainer":"surfaceContainerLow")}.buttonStyle(.plain)
    }
    private func update(_ id:String,_ change:(inout InteractionLink)->Void){editor.edit{p in if let i=p.links.firstIndex(where:{$0.id==id}){change(&p.links[i])}}}
}
struct StudioGraph:View {
    @ObservedObject var editor:Editor
    var sourceID:String?=nil
    @State private var source:String?
    @Environment(\.q) private var q
    private func issue(_ link:InteractionLink)->String?{
        let ids=Set(editor.project.nodes.map(\.id))
        if link.event != "start" && !ids.contains(link.sourceID){return "Источник удалён"}
        if !ids.contains(link.targetID){return "Цель удалена"}
        if link.mode=="state" && !(editor.project.studio?.states.contains{$0.id==link.stateID} ?? false){return "Состояние удалено"}
        if link.enabled && ["animate","bind","set"].contains(link.mode),editor.project.links.contains(where:{$0.id != link.id && $0.enabled && $0.sourceID==link.sourceID && $0.event==link.event && $0.targetID==link.targetID && $0.property==link.property}){return "Два правила меняют одно свойство"}
        return nil
    }
    var body:some View {VStack(spacing:14){
        StudioCard(title:"Схема связок"){
            Text("Источник → реакция → цель. Нажмите карточку для редактирования.").font(qfont(13))
            if editor.project.links.isEmpty{Text("Связок пока нет.").font(qfont(14))}
        }
        ForEach(editor.project.links.filter{sourceID==nil || $0.sourceID==sourceID}){rule in
            StudioCard(title:InteractionLink.events.first{$0.0==rule.event}?.1 ?? rule.event){
                Button{source=rule.sourceID}label:{HStack(spacing:10){node(rule.sourceID);Image(systemName:"arrow.right").foregroundStyle(q.color("primary"));node(rule.targetID)}}.buttonStyle(.plain)
                Text(InteractionLink.effects.first{$0.0==rule.mode}?.1 ?? rule.mode).font(qfont(13)).foregroundStyle(q.color("primary"))
                if let warning=issue(rule){Text(warning).font(qfont(13,.semibold)).foregroundStyle(.orange)}
                QToggle("Включена",isOn:Binding(get:{rule.enabled},set:{v in editor.edit{p in if let i=p.links.firstIndex(where:{$0.id==rule.id}){p.links[i].enabled=v}}}))
            }
        }
    }.sheet(isPresented:Binding(get:{source != nil},set:{if !$0{source=nil}})){InteractionEditorPanel(editor:editor,sourceID:source ?? "").modifier(OriginalTheme())}}
    private func node(_ id:String)->some View{Text(editor.project.nodes.first{$0.id==id}?.name ?? "Нет слоя").font(qfont(14,.medium)).frame(maxWidth:.infinity).padding(14).qSurface(18,"surfaceContainerHighest")}
}
struct StudioHistory:View {
    @ObservedObject var editor:Editor
    @State private var name="Моя версия"
    @State private var refresh=0
    var body:some View {VStack(spacing:16){
        StudioCard(title:"Версии проекта"){
            Text("Сохраняются локально: до 50 версий, автоматические снимки примерно раз в минуту.").font(qfont(13))
            QTextField(title:"Название",text:$name)
            LinkPill(title:"Сохранить версию",icon:"clock.arrow.circlepath",prominent:true){do{try editor.store.checkpoint(editor.project,label:name);refresh+=1}catch{editor.error=error.localizedDescription}}
        }
        ForEach(editor.store.revisions(editor.project.id)){revision in StudioCard(title:revision.label){
            Text(revision.date.formatted(date:.abbreviated,time:.shortened)).font(qfont(13))
            LinkPill(title:"Восстановить",icon:"arrow.uturn.backward"){do{try editor.restore(revision);refresh+=1}catch{editor.error=error.localizedDescription}}
        }}
    }.id(refresh)}
}
struct StudioExport:View {
    @ObservedObject var editor:Editor
    @State private var shared:SharedFile?
    var body:some View {StudioCard(title:"Проект для Xcode"){
        Text("Готовый проект с интерфейсом SwiftUI, ресурсами, шрифтами и исходным .qwel. Можно открыть .xcodeproj и выбрать команду подписи.").font(qfont(14))
        LinkPill(title:"Собрать ZIP проекта iOS",icon:"square.and.arrow.up",prominent:true){do{shared=SharedFile(url:try IOSProjectExport.make(editor.project,root:editor.store.root))}catch{editor.error=error.localizedDescription}}
    }.sheet(item:$shared){ShareSheet(urls:[$0.url])}}
}
