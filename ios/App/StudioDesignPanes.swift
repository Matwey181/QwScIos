import SwiftUI
import UniformTypeIdentifiers

struct StudioComponents:View {
    @ObservedObject var editor:Editor
    @State private var name="Мой компонент"
    @Environment(\.q) private var q
    var body:some View {VStack(spacing:16){
        StudioCard(title:"Свой компонент"){
            Text("Выделите слои на холсте. Сохраняются оформление, внутренние связки и состояния.").font(qfont(13))
            QTextField(title:"Название",text:$name)
            LinkPill(title:"Сохранить выделенное",icon:"square.stack.3d.up",prominent:true){do{try editor.saveReusable(name)}catch{editor.error=error.localizedDescription}}.disabled(editor.selected.isEmpty)
        }
        ForEach(editor.store.components){component in StudioCard(title:component.name){
            ProjectThumbnail(project:component.project,root:editor.store.root).frame(height:140)
            LinkPill(title:"Вставить",icon:"plus"){editor.insertReusable(component)}
            LinkPill(title:"Обновить все копии на экране",icon:"arrow.triangle.2.circlepath"){editor.updateInstances(component)}
            Button("Удалить из библиотеки",role:.destructive){do{try editor.store.deleteComponent(component.id);editor.objectWillChange.send()}catch{editor.error=error.localizedDescription}}.font(qfont(13))
        }}
    }}
}
struct StudioLayout:View {
    @ObservedObject var editor:Editor
    @State private var x:CGFloat=100
    @State private var y:CGFloat=100
    @State private var gap:CGFloat=16
    var body:some View {VStack(spacing:16){
        StudioCard(title:"Умные привязки"){
            QToggle("Привязки к краям и центрам",isOn:$editor.snap)
            QToggle("Равные промежутки",isOn:Binding(get:{editor.project.studio?.spacingSnap ?? true},set:{v in editor.studio{$0.spacingSnap=v}}))
            QToggle("Привязка к сетке",isOn:Binding(get:{editor.project.studio?.gridSnap ?? false},set:{v in editor.studio{$0.gridSnap=v}}))
            QNumber(title:"Шаг сетки",value:Binding(get:{editor.project.studio?.gridSize ?? 8},set:{v in editor.studio{$0.gridSize=max(1,v)}}))
        }
        StudioCard(title:"Направляющие"){
            HStack{QNumber(title:"X",value:$x);QNumber(title:"Y",value:$y)}
            HStack{LinkPill(title:"Добавить X",icon:"plus"){editor.studio{$0.guidesX.append(x)}};LinkPill(title:"Добавить Y",icon:"plus"){editor.studio{$0.guidesY.append(y)}}}
            Button("Очистить направляющие"){editor.studio{$0.guidesX=[];$0.guidesY=[]}}
        }
        StudioCard(title:"Точные промежутки"){
            QNumber(title:"Отступ",value:$gap)
            HStack{LinkPill(title:"По горизонтали",icon:"arrow.left.and.right"){editor.fixedGap(gap,horizontal:true)};LinkPill(title:"По вертикали",icon:"arrow.up.and.down"){editor.fixedGap(gap,horizontal:false)}}.disabled(editor.selected.count<2)
        }
    }}
}
struct StudioText:View {
    @ObservedObject var editor:Editor
    @State private var editing=false
    private var node:Node?{editor.selected.first{$0.kind=="TEXT"}}
    var body:some View {StudioCard(title:"Типографика"){
        if let n=node{
            EffectPreview(nodes:[n],renderer:editor.renderer).frame(height:140)
            QNumber(title:"Межбуквенный интервал",value:value(\.tracking))
            QNumber(title:"Дополнительный интервал строк",value:value(\.lineSpacing))
            QToggle("Подбирать размер внутри рамки",isOn:Binding(get:{node?.extras?.autoFit ?? false},set:{v in editor.extras{$0.autoFit=v}}))
            HStack{QNumber(title:"Ширина",value:Binding(get:{node?.w ?? 180},set:{v in editor.change{$0.w=max(1,v)}}));QNumber(title:"Высота",value:Binding(get:{node?.h ?? 40},set:{v in editor.change{$0.h=max(1,v)}}))}
            LinkPill(title:"Редактировать текст и выделения",icon:"textformat"){editing=true}
        }else{Text("Выделите текстовый слой на холсте.").font(qfont(14))}
    }.sheet(isPresented:$editing){if let n=node{TextEditPanel(editor:editor,nodeID:n.id){editing=false}.padding(16).modifier(OriginalTheme())}}}
    private func value(_ key:WritableKeyPath<LayerExtras,CGFloat>)->Binding<CGFloat>{Binding(get:{(node?.extras ?? LayerExtras())[keyPath:key]},set:{v in editor.extras{$0[keyPath:key]=v}})}
}
struct StudioImage:View {
    @ObservedObject var editor:Editor
    @State private var replacing=false
    private var node:Node?{editor.selected.first{$0.kind=="IMAGE"}}
    var body:some View {StudioCard(title:"Изображение"){
        if let n=node{
            EffectPreview(nodes:[n],renderer:editor.renderer).frame(height:200)
            LinkChoiceField(title:"Как вписать",selection:Binding(get:{node?.extras?.imageMode ?? "stretch"},set:{v in editor.extras{$0.imageMode=v}}),items:[("fill","Заполнить и обрезать"),("fit","Вписать целиком"),("stretch","Растянуть")])
            number("Положение X · 0–1",\.cropX);number("Положение Y · 0–1",\.cropY);number("Масштаб картинки",\.imageZoom)
            LinkPill(title:"Заменить изображение",icon:"photo"){replacing=true}
            LinkPill(title:"Центрировать кадр",icon:"viewfinder"){editor.extras{$0.cropX=0.5;$0.cropY=0.5;$0.imageZoom=1}}
        }else{Text("Выделите изображение на холсте.").font(qfont(14))}
    }.fileImporter(isPresented:$replacing,allowedContentTypes:[.image]){result in
        do{let url=try result.get();let access=url.startAccessingSecurityScopedResource();defer{if access{url.stopAccessingSecurityScopedResource()}};if let id=node?.id{try editor.replaceImage(Data(contentsOf:url),id:id)}}catch{editor.error=error.localizedDescription}
    }}
    private func number(_ title:String,_ key:WritableKeyPath<LayerExtras,CGFloat>)->some View{QNumber(title:title,value:Binding(get:{(node?.extras ?? LayerExtras())[keyPath:key]},set:{v in editor.extras{$0[keyPath:key]=key==\LayerExtras.imageZoom ? min(8,max(0.1,v)):min(1,max(0,v))}}))}
}
