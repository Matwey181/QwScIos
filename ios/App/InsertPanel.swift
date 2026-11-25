import SwiftUI
import PhotosUI

struct AddPanel:View {
    @ObservedObject var editor:Editor
    @Binding var photoItems:[PhotosPickerItem]
    var importFile:()->Void
    @Environment(\.q) var q
    @State private var tab=0
    @State private var category="loader"
    private let loader=["soft-burst","cookie-9","pentagon","pill","sunny","cookie-4","oval"]
    private let categories=[("loader","Загрузка"),("basic","Базовые"),("cookies","Печеньки"),("bursts","Вспышки"),("flowers","Цветы"),("stars","Звёзды"),("special","Особые")]
    var body:some View {
        VStack(alignment:.leading,spacing:12) {
            ForEach([0,2],id:\.self){start in HStack(spacing:8){ForEach(start..<start+2,id:\.self){i in QChip(title:["Основа","Фигуры MD3","Компоненты","Иконки"][i],selected:tab==i){tab=i}}}}
            if tab==0 { basics }
            else if tab==1 { shapes }
            else if tab==2 { components }
            else { ImportedIconPanel(editor:editor,choose:importFile) }
        }
    }
    private var basics:some View {
        HStack(spacing:12) {
            basic("RECT","Прямоугольник","Rect")
            basic("ELLIPSE","Эллипс","Ellipse")
            basic("TEXT","Текст","Text")
            PhotosPicker(selection:$photoItems,maxSelectionCount:12,matching:.images){tile("Картинка","Image")}.buttonStyle(QPressStyle()).simultaneousGesture(LongPressGesture().onEnded{_ in importFile()})
        }.padding(.top,4)
    }
    private func tile(_ title:String,_ icon:String)->some View { VStack(spacing:6){QIcon(id:icon,size:28,tint:q.color("primary"));Text(title).font(qfont(12,.medium)).lineLimit(1)}.frame(maxWidth:.infinity).frame(height:88).qSurface(20,"surfaceContainerHighest") }
    private func basic(_ kind:String,_ title:String,_ icon:String)->some View { Button {editor.add(kind)}label:{tile(title,icon)}.buttonStyle(QPressStyle()).accessibilityIdentifier("add-"+kind) }
    private var shapes:some View {
        VStack(spacing:12) {
            ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){ForEach(categories,id:\.0){id,title in QChip(title:title,selected:category==id){category=id}.fixedSize()}}}
            LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:8),count:4),spacing:8) {
                ForEach(Catalog.shared.shapes.filter{category=="loader" ? loader.contains($0.id):$0.category==category}){shape in Button {editor.add("SHAPE",shape:shape)}label:{VStack(spacing:4){ShapePreview(shape:shape).fill(q.color("primary")).frame(width:44,height:44);Text(shape.name).font(qfont(11,.medium)).lineLimit(1)}.frame(maxWidth:.infinity).aspectRatio(1,contentMode:.fit).qSurface(20,"surfaceContainerHighest")}.buttonStyle(QPressStyle())}
            }
        }
    }
    private var components:some View {
        VStack(alignment:.leading,spacing:8) {
            InlineSection(title:"Мои компоненты · сохранить и вставить"){StudioComponents(editor:editor)}
            ForEach(["apple","actions","navigation","containment","communication","selection","inputs"],id:\.self){category in
                Text(["apple":"Стиль Apple","actions":"Действия","navigation":"Навигация","containment":"Контейнеры","communication":"Сообщения","selection":"Выбор","inputs":"Ввод"][category] ?? category).font(qfont(14,.semibold)).foregroundStyle(q.color("primary")).padding(.top,8)
                LazyVGrid(columns:[GridItem(.flexible(),spacing:8),GridItem(.flexible(),spacing:8)],spacing:8){ForEach(Catalog.shared.components.filter{$0.category==category}){item in
                    Button {editor.addComponent(item)}label:{VStack(spacing:4){ProjectThumbnail(project:preview(AppleCatalog.variant(item,dark:editor.project.tone.dark).project),root:editor.store.root).frame(height:76);Text(item.name).font(qfont(12,.medium)).lineLimit(1).padding(.bottom,8)}.frame(maxWidth:.infinity).qSurface(20,"surfaceContainerHighest")}.buttonStyle(QPressStyle()).accessibilityIdentifier("component-"+item.id)
                }}
            }
        }
    }
    private func preview(_ p:Project)->Project { var p=p;p.nodes=p.nodes.map{n in var n=n;if editor.project.tone.colors.indices.contains(Int(n.fillToken)){n.fill=editor.project.tone.colors[Int(n.fillToken)]};return n};return p }
}
struct QSection<Content:View>:View {
    var title:String?
    var content:Content
    @Environment(\.q) var q
    init(_ title:String?=nil,@ViewBuilder content:()->Content){self.title=title;self.content=content()}
    var body:some View { VStack(alignment:.leading,spacing:12){if let title{Text(title).font(qfont(14,.semibold)).foregroundStyle(q.color("primary"))};content}.padding(.vertical,6).frame(maxWidth:.infinity,alignment:.leading) }
}
struct QToggle:View {
    var title:String
    @Binding var isOn:Bool
    init(_ title:String,isOn:Binding<Bool>){self.title=title;self._isOn=isOn}
    var body:some View { HStack{Text(title).font(qfont(14));Spacer();QSwitch(on:$isOn)}.frame(minHeight:40) }
}
