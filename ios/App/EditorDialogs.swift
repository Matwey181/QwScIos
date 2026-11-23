import SwiftUI

struct SelectionPill:View {
    @ObservedObject var editor:Editor
    @Binding var expanded:Bool
    var openPanel:(String)->Void
    var echo:()->Void
    @Environment(\.q) var q
    var body:some View {
        VStack(spacing:0) {
            Button {withAnimation(.spring(response:0.4,dampingFraction:0.65)){expanded.toggle()}}label:{HStack(spacing:8){Capsule().fill(q.color("outline")).frame(width:28,height:4);Text("Инструменты").font(qfont(11,.medium)).foregroundStyle(q.color("onSurfaceVariant"))}.padding(.horizontal,14).padding(.vertical,7)}.buttonStyle(.plain).gesture(DragGesture().onEnded{expanded=$0.translation.height < -24})
            if expanded { quickTools.padding(.horizontal,12).padding(.vertical,8).qSurface(28,"surfaceContainerLow",glass:true) }
            else { HStack(spacing:2){
                QIconButton(icon:"Duplicate",label:"Дублировать"){editor.duplicate()}
                Menu {Button("Объединение"){editor.boolean("union")};Button("Разность"){editor.boolean("subtract")};Button("Пересечение"){editor.boolean("intersection")};Button("Исключение"){editor.boolean("xor")}}label:{QIcon(id:"Bool").frame(width:48,height:48)}
                QIconButton(icon:"Forward",label:"Выше"){editor.reorderStep(true)}
                QIconButton(icon:"Backward",label:"Ниже"){editor.reorderStep(false)}
                if editor.selected.count>1 {QIconButton(icon:"Group",label:"Группа"){editor.group()}}
                else if editor.selected.first?.group.isEmpty==false {QIconButton(icon:"Ungroup",label:"Разгруппировать"){editor.ungroup()}}
                if editor.selected.count==1 {QIconButton(icon:"Layers",label:"Эхо",action:echo)}
                else if editor.selected.count==2 {QIconButton(icon:"Shapes",label:"Переход",action:echo)}
                QIconButton(icon:"Delete",label:"Удалить"){editor.remove()}
            }.padding(4).qSurface(40,"surfaceContainerHigh",glass:true) }
        }
    }
    private var quickTools:some View {
        VStack(alignment:.leading,spacing:10) {
            Text(editor.selected.count==1 ? editor.selected[0].name:"Выбрано слоёв: \(editor.selected.count)").font(qfont(16,.semibold)).padding(.horizontal,6)
            ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){quick("Fill","Заливка"){openPanel("style")};quick("Stroke","Обводка"){openPanel("style")};quick("Opacity","Прозрачность"){openPanel("style")};quick("Gradient","Градиент"){openPanel("style")};quick("Shadow","Тень"){openPanel("style")};quick("Blur","Размытие"){openPanel("style")}}}
            if let n=editor.selected.first {QSlider(value:Binding(get:{Double(n.opacity)},set:{v in editor.change{$0.opacity=CGFloat(v)}}))}
            ScrollView(.horizontal,showsIndicators:false){HStack(spacing:2){action("Delete","Удалить"){editor.remove()};action("Duplicate","Копия"){editor.duplicate()};action("Layers","Эхо",echo);action("Align","Выровнять"){openPanel("align")};action("Style","Все свойства"){openPanel("style")};action("Lock","Замок"){editor.change{$0.locked=true};editor.selection=[]}}}
        }
    }
    private func quick(_ icon:String,_ title:String,_ run:@escaping()->Void)->some View {Button(action:run){HStack(spacing:10){QIcon(id:icon);Text(title).font(qfont(14,.semibold))}.padding(.horizontal,16).padding(.vertical,14).qSurface(22,"secondaryContainer")}.buttonStyle(.plain)}
    private func action(_ icon:String,_ title:String,_ run:@escaping()->Void)->some View {Button(action:run){VStack(spacing:6){QIcon(id:icon,size:28,tint:q.color("primary"));Text(title).font(qfont(12,.medium)).lineLimit(1)}.frame(width:84).padding(.vertical,10)}.buttonStyle(.plain)}
}
struct EchoPanel:View {
    @ObservedObject var editor:Editor
    var close:()->Void
    @Environment(\.q) var q
    @State private var count=4.0
    @State private var scale=5.0
    @State private var rotation=3.0
    @State private var fade=0.85
    @State private var spread=0.0
    @State private var jitter=0.2
    @State private var contour=true
    @State private var seed=7
    private var copies:[Node] {guard let n=editor.selected.first else{return []};return (try? OriginalCore.shared.project("echo",project:editor.project,values:["id":n.id,"count":Int(count),"scale":scale,"rotation":rotation,"fade":fade,"spread":spread,"jitter":jitter,"contour":contour,"seed":seed]))?.nodes ?? []}
    var body:some View {
        VStack(alignment:.leading,spacing:16) {
            Text("Эхо / дребезг").font(qfont(24,.semibold))
            ScrollView {
                VStack(spacing:4) {
                    EffectPreview(nodes:copies+editor.selected,renderer:editor.renderer).frame(height:180).background(Color(argb:0xff0b0b10),in:RoundedRectangle(cornerRadius:20))
                    control("Копии",$count,1...30,"\(Int(count))",step:1)
                    control("Размер шага",$scale,-15...15,"\(Int(scale))%")
                    control("Наклон шага",$rotation,-30...30,"\(Int(rotation))")
                    control("Прозрачность",$fade,0...1,"\(Int(fade*100))%")
                    control("Смещение",$spread,-20...20,"\(Int(spread))")
                    control("Дребезг",$jitter,0...1,"\(Int(jitter*100))%")
                    HStack{Text("Только контур").font(qfont(14));Spacer();QSwitch(on:$contour)}.padding(.vertical,8)
                    Button("Перемешать"){seed=Int.random(in:0..<100000)}.font(qfont(14,.semibold)).foregroundStyle(q.color("primary"))
                }
            }.frame(maxHeight:550)
            HStack(spacing:24){Spacer();Button("Отмена",action:close);Button("Применить"){let nodes=copies;if let src=editor.selected.first,let index=editor.project.nodes.firstIndex(where:{$0.id==src.id}){editor.edit{$0.nodes.insert(contentsOf:nodes,at:index)}};close()}}.font(qfont(14,.semibold)).foregroundStyle(q.color("primary"))
        }.padding(24).qSurface(28,"surfaceContainerHigh")
    }
    private func control(_ title:String,_ value:Binding<Double>,_ range:ClosedRange<Double>,_ text:String,step:Double=0)->some View {VStack(spacing:0){HStack{Text(title);Spacer();Text(text)}.font(qfont(14));QSlider(value:value,range:range,step:step)}}
}
struct EffectPreview:View {
    var nodes:[Node]
    var renderer:DocumentRenderer
    var body:some View {
        GeometryReader { g in
            if let box=nodes.reduce(nil as CGRect?,{$0?.union($1.rect) ?? $1.rect}) {
                let k=min((g.size.width-28)/max(1,box.width),(g.size.height-28)/max(1,box.height))
                Canvas{context,size in
                    var p=Project();p.w=g.size.width;p.h=g.size.height;p.bg=0
                    p.nodes=nodes.map{n in var n=n;n.x=(n.x-box.midX)*k+size.width/2;n.y=(n.y-box.midY)*k+size.height/2;n.w*=k;n.h*=k;n.fontSize*=k;n.strokeWidth*=k;return n}
                    if let data=renderer.png(p,scale:1),let image=UIImage(data:data){context.draw(Image(uiImage:image),in:CGRect(origin:.zero,size:size))}
                }
            }
        }
    }
}
struct ScreensPanel:View {
    @ObservedObject var editor:Editor
    var close:()->Void
    @Environment(\.q) var q
    var body:some View {VStack(alignment:.leading,spacing:16){Text("Экраны").font(qfont(24,.semibold));ScrollView{VStack(spacing:2){if editor.project.pages.isEmpty{Text("Экран 1").padding()};ForEach(Array(editor.project.pages.enumerated()),id:\.element.id){i,page in HStack(spacing:12){QIcon(id:"Screens");Button(page.name){editor.page(i);close()}.font(qfont(16,.semibold));Spacer();Menu{Button("Копия"){editor.duplicatePage(i)};Button("Выше"){editor.movePage(i,-1)};Button("Ниже"){editor.movePage(i,1)};Button("Удалить",role:.destructive){editor.deletePage(i)}}label:{QIcon(id:"More").frame(width:40,height:40)}}.padding(.leading,12).padding(.vertical,6).qSurface(16,i==editor.project.active ? "secondaryContainer":"surfaceContainerHigh")}}}.frame(maxHeight:320);HStack{QChip(title:"Новый"){editor.addPage();close()};QChip(title:"Копия"){if editor.project.pages.isEmpty{editor.addPage()}else{editor.duplicatePage(editor.project.active)};close()}};Text("Размер и фон общие для всех экранов. Для перехода выберите действие объекта.").font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"));HStack{Spacer();Button("Закрыть",action:close).font(qfont(14,.semibold)).foregroundStyle(q.color("primary"))}}.padding(24).qSurface(28,"surfaceContainerHigh")}
}
struct ExportPanel:View {
    @ObservedObject var editor:Editor
    var export:(String)->Void
    var close:()->Void
    @Environment(\.q) var q
    @AppStorage("pngScale") var scale=2.0
    var body:some View {VStack(alignment:.leading,spacing:16){Text("Экспорт").font(qfont(24,.semibold));ProjectThumbnail(project:editor.project,root:editor.store.root).frame(height:200).qSurface(20,"surfaceContainerHighest");HStack{Text("Масштаб PNG");Spacer();ForEach([1.0,2,3,4],id:\.self){n in QChip(title:"\(Int(n))x",selected:scale==n){scale=n}}};HStack{QChip(title:"PNG"){close();export("png")};QChip(title:"SVG"){close();export("svg")}};HStack{QChip(title:"Проект .qwel"){close();export("qwel")};QChip(title:"Код Compose"){close();export("kt")}};QChip(title:"Код SwiftUI (.swift)"){close();export("swift")};QChip(title:"Проект iOS / Xcode"){close();export("iosProject")};HStack{Spacer();Button("Закрыть",action:close)}}.font(qfont(14)).padding(24).qSurface(28,"surfaceContainerHigh")}
}
extension Editor {
    func reorderStep(_ forward:Bool){edit{p in let ids=selection;if forward{for i in p.nodes.indices.dropLast().reversed() where ids.contains(p.nodes[i].id) && !ids.contains(p.nodes[i+1].id){p.nodes.swapAt(i,i+1)}}else{for i in p.nodes.indices.dropFirst() where ids.contains(p.nodes[i].id) && !ids.contains(p.nodes[i-1].id){p.nodes.swapAt(i,i-1)}}}}
    func duplicatePage(_ index:Int){guard project.pages.indices.contains(index)else{return};edit{p in p.syncPage();var page=p.pages[index];page.id=UUID().uuidString;page.name += " — копия";page.nodes=page.nodes.map{n in var n=n;n.id=UUID().uuidString;return n};p.pages.insert(page,at:index+1);p.active=index+1;p.nodes=page.nodes};selection=[]}
    func deletePage(_ index:Int){guard project.pages.count>1,project.pages.indices.contains(index)else{return};edit{p in p.syncPage();p.pages.remove(at:index);p.active=min(p.active,p.pages.count-1);p.nodes=p.pages[p.active].nodes};selection=[]}
    func movePage(_ index:Int,_ delta:Int){let next=index+delta;guard project.pages.indices.contains(index),project.pages.indices.contains(next)else{return};edit{p in p.syncPage();let active=p.pages[p.active].id;p.pages.swapAt(index,next);p.active=p.pages.firstIndex{$0.id==active} ?? 0}}
}
