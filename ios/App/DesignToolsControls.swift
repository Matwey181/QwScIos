import SwiftUI
import UniformTypeIdentifiers

struct AppearanceActions:View {
    @ObservedObject var editor:Editor
    var body:some View {HStack(spacing:8){QChip(title:"Копировать стиль"){editor.copyAppearance()};QChip(title:"Вставить стиль"){editor.pasteAppearance()}.disabled(AppearanceClipboard.node==nil)}}
}
struct NudgeControls:View {
    @ObservedObject var editor:Editor
    @State private var step:CGFloat=1
    var body:some View {VStack(spacing:12){HStack{QChip(title:"1 px",selected:step==1){step=1};QChip(title:"10 px",selected:step==10){step=10}}
        HStack{QChip(title:"←"){editor.nudge(-step,0)};QChip(title:"↑"){editor.nudge(0,-step)};QChip(title:"↓"){editor.nudge(0,step)};QChip(title:"→"){editor.nudge(step,0)}}
    }.disabled(editor.selection.isEmpty)}
}
struct AutoLayoutControls:View {
    @ObservedObject var editor:Editor
    private var frame:AutoLayoutFrame?{(editor.project.studio?.layouts ?? []).first{!Set($0.children+[$0.backgroundID].compactMap{$0}).isDisjoint(with:editor.selection)}}
    var body:some View {VStack(alignment:.leading,spacing:12){
        if let frame=frame{
            QToggle("Автоматическая раскладка",isOn:flag(frame.id))
            QToggle("Сохранять внутренние группы",isOn:Binding(get:{frame.groupItems ?? false},set:{v in update(frame.id){$0.groupItems=v}}))
            LinkChoiceField(title:"Направление",selection:text(frame.id,\.axis),items:[("horizontal","В ряд"),("vertical","В столбик")])
            LinkChoiceField(title:"Выравнивание",selection:text(frame.id,\.alignment),items:[("start","По началу"),("center","По центру"),("end","По концу")])
            HStack{QNumber(title:"Отступ внутри",value:number(frame.id,\.padding));QNumber(title:"Между элементами",value:number(frame.id,\.gap))}
            LinkChoiceField(title:"Ширина контейнера",selection:text(frame.id,\.widthMode),items:[("hug","По содержимому"),("fixed","Заданная"),("fill","По ширине экрана")])
            if frame.widthMode=="fixed"{QNumber(title:"Ширина",value:number(frame.id,\.width))}
            LinkChoiceField(title:"Высота контейнера",selection:text(frame.id,\.heightMode),items:[("hug","По содержимому"),("fixed","Заданная")])
            if frame.heightMode=="fixed"{QNumber(title:"Высота",value:number(frame.id,\.height))}
            Button("Убрать раскладку",role:.destructive){editor.studio{$0.layouts?.removeAll{$0.id==frame.id}}}.font(qfont(14))
        }else{
            Text("Выделите фон кнопки, иконку и текст либо несколько элементов. Самый большой прямоугольник станет фоном.").font(qfont(13))
            LinkPill(title:"Собрать из выделения",icon:"rectangle.3.group",prominent:true){editor.createAutoLayout()}.disabled(editor.selected.count<2)
        }
    }}
    private func update(_ id:String,_ change:(inout AutoLayoutFrame)->Void){editor.studio{studio in if let i=studio.layouts?.firstIndex(where:{$0.id==id}){change(&studio.layouts![i])}}}
    private func text(_ id:String,_ key:WritableKeyPath<AutoLayoutFrame,String>)->Binding<String>{Binding(get:{frame?[keyPath:key] ?? ""},set:{v in update(id){$0[keyPath:key]=v}})}
    private func number(_ id:String,_ key:WritableKeyPath<AutoLayoutFrame,CGFloat>)->Binding<CGFloat>{Binding(get:{frame?[keyPath:key] ?? 0},set:{v in update(id){$0[keyPath:key]=max(0,v)}})}
    private func flag(_ id:String)->Binding<Bool>{Binding(get:{frame?.enabled ?? false},set:{v in update(id){$0.enabled=v}})}
}
struct ScreenConstraintControls:View {
    @ObservedObject var editor:Editor
    private var node:Node?{editor.selected.first}
    var body:some View {VStack(spacing:12){
        LinkChoiceField(title:"По горизонтали при смене экрана",selection:value(\.anchorX,"left"),items:[("left","Держать слева"),("center","По центру"),("right","Держать справа"),("stretch","Растягивать")])
        LinkChoiceField(title:"По вертикали при смене экрана",selection:value(\.anchorY,"top"),items:[("top","Держать сверху"),("center","По центру"),("bottom","Держать снизу"),("stretch","Растягивать")])
    }.disabled(editor.selection.isEmpty)}
    private func value(_ key:WritableKeyPath<LayerExtras,String?>,_ fallback:String)->Binding<String>{Binding(get:{node?.extras?[keyPath:key] ?? fallback},set:{v in editor.extras{$0[keyPath:key]=v}})}
}
struct ReferenceControls:View {
    @ObservedObject var editor:Editor
    @State private var importing=false
    private var reference:Node?{editor.project.nodes.first{$0.extras?.reference==true}}
    var body:some View {VStack(spacing:12){
        LinkPill(title:reference==nil ? "Добавить скриншот":"Заменить референс",icon:"photo"){importing=true}
        if let reference=reference{
            QToggle("Показывать референс",isOn:Binding(get:{reference.visible},set:{v in change(reference.id){$0.visible=v}}))
            QSlider(value:Binding(get:{Double(reference.opacity)},set:{v in change(reference.id){$0.opacity=CGFloat(v)}}))
            Button("Удалить референс",role:.destructive){editor.edit{$0.nodes.removeAll{$0.id==reference.id}}}
        }
        Text("Референс лежит под дизайном, заблокирован и не попадает в экспорт.").font(qfont(12))
    }.fileImporter(isPresented:$importing,allowedContentTypes:[.image]){result in do{let url=try result.get(),access=url.startAccessingSecurityScopedResource();defer{if access{url.stopAccessingSecurityScopedResource()}};try editor.addReference(Data(contentsOf:url))}catch{editor.error=error.localizedDescription}}}
    private func change(_ id:String,_ block:(inout Node)->Void){editor.edit{p in if let i=p.nodes.firstIndex(where:{$0.id==id}){block(&p.nodes[i])}}}
}
struct OverlapLayerPicker:View {
    @ObservedObject var editor:Editor
    @Environment(\.q) private var q
    var body:some View {VStack(spacing:16){HStack{Text("Слой под пальцем").font(qfont(22,.semibold));Spacer();Button("Закрыть"){editor.showLayerPicker=false}}.padding(16)
        ScrollView{VStack(spacing:10){ForEach(editor.overlapIDs,id:\.self){id in if let node=editor.project.nodes.first(where:{$0.id==id}){
            Button{editor.selection=[id];editor.showLayerPicker=false}label:{HStack{EffectPreview(nodes:[node],renderer:editor.renderer).frame(width:52,height:52);Text(node.name).font(qfont(16));Spacer();if editor.selection.contains(id){Image(systemName:"checkmark")}}.padding(12).qSurface(22,"surfaceContainerHigh")}.buttonStyle(.plain)
        }}}.padding(16)}
    }.background(q.color("surfaceContainer").ignoresSafeArea())}
}
