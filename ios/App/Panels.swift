import SwiftUI

struct InspectorPanel:View {
    @ObservedObject var editor:Editor
    var importFont:()->Void
    @State private var showInteractions=false
    @Environment(\.q) var q
    var node:Node?{editor.selected.first}
    func bind<T>(_ key:WritableKeyPath<Node,T>,_ fallback:T)->Binding<T>{Binding(get:{node?[keyPath:key] ?? fallback},set:{v in editor.change{n in if let d=v as? CGFloat,[\Node.w as AnyKeyPath,\Node.h as AnyKeyPath,\Node.fontSize as AnyKeyPath].contains(key){n[keyPath:key]=max(1,d) as! T}else{n[keyPath:key]=v}}})}
    var body:some View {
        VStack(alignment:.leading,spacing:14) {
            if let n=node {
                if editor.selected.count==1 {
                    QTextField(title:"Имя слоя",text:bind(\.name,""))
                    if n.kind=="TEXT" {
                        TextField("Текст",text:bind(\.text,""),axis:.vertical).lineLimit(2...5).font(qfont(16)).padding(16).overlay(RoundedRectangle(cornerRadius:16).stroke(q.color("outline")))
                        Button("Редактировать текст"){editor.requestTextEdit=n.id}.font(qfont(14,.semibold)).foregroundStyle(q.color("primary"))
                        QNumber(title:"Ширина текста",value:bind(\.w,180))
                        HStack(spacing:8){
                            ForEach(["left","center","right"],id:\.self){alignment in
                                QChip(title:alignment=="left" ? "Слева":alignment=="center" ? "По центру":"Справа",selected:n.textAlign==alignment){editor.change{$0.textAlign=alignment}}
                            }
                        }

                    }
                    HStack(spacing:8){QNumber(title:"X",value:bind(\.x,0));QNumber(title:"Y",value:bind(\.y,0))}
                    if n.kind != "TEXT"{HStack(spacing:8){QNumber(title:"Ширина",value:bind(\.w,100));QNumber(title:"Высота",value:bind(\.h,100))}}
                    HStack(spacing:8){QNumber(title:"Поворот",value:bind(\.rotation,0));if n.kind != "TEXT"{QSwitch(on:bind(\.ratioLock,false));Text("Пропорции").font(qfont(14,.semibold))}}
                }else{Text("Выбрано слоёв: \(editor.selected.count)").font(qfont(16,.semibold))}
                if n.kind != "IMAGE"{row(n.kind=="TEXT" ? "Цвет текста":"Заливка",\.fill,token:n.fillToken)}
                if !["TEXT","IMAGE"].contains(n.kind){
                    title("Градиент")
                    HStack(spacing:8){ForEach(Array(["Нет","Линейный","Радиальный"].enumerated()),id:\.offset){i,text in QChip(title:text,selected:n.gradKind==Int64(i)){editor.change{$0.gradKind=Int64(i)}}}}
                    if n.gradKind != 0{row("Второй цвет",\.fill2);if n.gradKind==1{slider("Угол",\.gradAngle,0...360)}}
                    row("Обводка",\.stroke,token:n.strokeToken)
                    if n.stroke != 0 || n.strokeWidth>0{slider("Толщина",\.strokeWidth,0...16)}
                }
                slider("Непрозрачность",\.opacity,0...1,percent:true)
                if !["TEXT","IMAGE"].contains(n.kind){
                    slider("Тень",\.shadowBlur,0...48)
                    HStack(spacing:8){QChip(title:"Мягкая"){editor.change{$0.shadowBlur=16;$0.shadowDx=0;$0.shadowDy=6;$0.shadowColor=0x40000000}};QChip(title:"Высокая"){editor.change{$0.shadowBlur=28;$0.shadowDx=0;$0.shadowDy=14;$0.shadowColor=0x59000000}};QChip(title:"Свечение"){editor.change{$0.shadowBlur=26;$0.shadowDx=0;$0.shadowDy=0;$0.shadowColor=Int64(Int32(bitPattern:(UInt32(truncatingIfNeeded:$0.fill)&0xffffff)|0x99000000))}}}
                    if n.shadowBlur>0.5{slider("Тень по X",\.shadowDx,-40...40);slider("Тень по Y",\.shadowDy,-40...40);row("Цвет тени",\.shadowColor)}
                    slider("Размытие фона",\.blur,0...48)
                    slider("Размытие слоя",\.softBlur,0...48)
                    if n.kind=="RECT"{title("Скругление");ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){ForEach([CGFloat(0),4,8,12,16,28,48,9999],id:\.self){v in QChip(title:v==9999 ? "Full":"\(Int(v))",selected:n.corner==v){editor.change{$0.corner=v}}.fixedSize()}}};slider("Свой радиус",\.corner,0...min(n.w,n.h)/2);QToggle("Скругление при нажатии",isOn:Binding(get:{n.pressCorner>=0},set:{v in editor.change{$0.pressCorner=v ? min($0.w,$0.h)/2:-1}}));if n.pressCorner>=0{slider("При нажатии",\.pressCorner,0...min(n.w,n.h)/2)}}
                    QToggle("Маска для нижнего слоя",isOn:bind(\.mask,false))
                }
                ActionPanel(editor:editor,node:n)
                Button {
                    showInteractions=true
                } label: {
                    HStack(spacing:8) {
                        Image(systemName:"point.3.connected.trianglepath.dotted")
                        Text("Связки и анимации")
                        Spacer()
                        Text("\(editor.project.links.filter{$0.sourceID == n.id}.count)")
                        Image(systemName:"chevron.right")
                    }
                    .font(qfont(14,.semibold))
                    .padding(14)
                    .qSurface(16,"secondaryContainer")
                }
                .buttonStyle(.plain)
                .sheet(isPresented:$showInteractions) {
                    NavigationStack {
                        ScrollView {
                            LinkRulesEditor(editor:editor,source:n)
                                .padding(16)
                        }
                        .navigationTitle("Связки и анимации")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement:.topBarTrailing) {
                                Button("Готово") {showInteractions=false}
                            }
                        }
                    }
                }
                if n.kind=="SHAPE"{title("Фигура");ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){ForEach(Catalog.shared.shapes){shape in Button{editor.change{$0.shapeId=shape.id}}label:{ShapePreview(shape:shape).fill(q.color(n.shapeId==shape.id ? "onPrimaryContainer":"primary")).frame(width:34,height:34).frame(width:56,height:56).qSurface(n.shapeId==shape.id ? 28:16,n.shapeId==shape.id ? "primaryContainer":"surfaceContainerHighest")}.buttonStyle(.plain)}}}}
                if n.kind=="TEXT"{slider("Размер шрифта",\.fontSize,6...160);title("Шрифт");ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){QChip(title:"Системный",selected:n.font.isEmpty){editor.change{$0.font=""}};QChip(title:"+ Шрифт",action:importFont);ForEach(["InterSA-Regular.otf","Figtree-Regular.ttf"],id:\.self){name in QChip(title:name.components(separatedBy:"-").first ?? name,selected:n.font==name){editor.change{$0.font=name}}}}};HStack(spacing:8){ForEach([Int64(400),500,700],id:\.self){weight in QChip(title:weight==400 ? "Regular":weight==500 ? "Medium":"Bold",selected:n.weight==weight){editor.change{$0.weight=weight}}}}}
            }
        }
    }
    private func title(_ text:String)->some View{Text(text).font(qfont(14,.semibold)).foregroundStyle(q.color("primary"))}
    private func row(_ text:String,_ key:WritableKeyPath<Node,Int64>,token:Int64 = -1)->some View{QColorRow(title:text,color:bind(key,0),colors:editor.project.tone.colors,token:token,picked:{color,t in editor.change{n in n[keyPath:key]=color;if key==\Node.fill{n.fillToken=t};if key==\Node.stroke{n.strokeToken=t;if n.strokeWidth==0 && color != 0{n.strokeWidth=2}}}},eyedrop:{editor.eyedropTarget=key})}
    private func slider(_ text:String,_ key:WritableKeyPath<Node,CGFloat>,_ range:ClosedRange<CGFloat>,percent:Bool=false)->some View{VStack(spacing:0){HStack{Text(text);Spacer();Text("\(Int((node?[keyPath:key] ?? 0)*(percent ? 100:1)))"+(percent ? "%":""))}.font(qfont(14));QSlider(value:Binding(get:{Double(node?[keyPath:key] ?? range.lowerBound)},set:{v in editor.change{$0[keyPath:key]=CGFloat(v)}}),range:Double(range.lowerBound)...Double(range.upperBound))}}
}
struct ActionPanel:View {
    @ObservedObject var editor:Editor
    var node:Node
    @Environment(\.q) var q
    private var type:String{node.action.isEmpty ? "none":node.action.components(separatedBy:":").first ?? "none"}
    var body:some View{VStack(alignment:.leading,spacing:10){Text("Действие при нажатии").font(qfont(14,.semibold)).foregroundStyle(q.color("primary"));ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){ForEach([("none","Нет"),("goto","Перейти"),("back","Назад"),("toggle","Показать / скрыть"),("url","Ссылка")],id:\.0){key,title in QChip(title:title,selected:type==key){editor.change{$0.action=key=="none" ? "":key=="back" ? "back":key+":"}}.fixedSize()}}};if type=="goto"{ForEach(editor.project.pages){page in QChip(title:page.name,selected:node.action=="goto:"+page.id){editor.change{$0.action="goto:"+page.id}}}};if type=="toggle"{ForEach(editor.project.nodes.filter{$0.id != node.id}){layer in QChip(title:layer.name,selected:node.action=="toggle:"+layer.id){editor.change{$0.action="toggle:"+layer.id}}}};if type=="url"{QTextField(title:"Ссылка",text:Binding(get:{String(node.action.dropFirst(4))},set:{v in editor.change{$0.action="url:"+v}})).textInputAutocapitalization(.never)}}}
}
struct LayersPanel:View {
    @ObservedObject var editor:Editor
    @Environment(\.q) var q
    var body:some View{VStack(spacing:4){if editor.project.nodes.isEmpty{Text("Слоёв пока нет").font(qfont(14)).foregroundStyle(q.color("onSurfaceVariant"))};ForEach(editor.project.nodes.reversed()){n in HStack(spacing:0){EffectPreview(nodes:[n],renderer:editor.renderer).frame(width:40,height:40).qSurface(12,"surfaceContainerHighest");VStack(alignment:.leading,spacing:0){Text(n.name.isEmpty ? "Слой":n.name).font(qfont(16)).lineLimit(1);if n.mask{Text("Маска").font(qfont(11,.medium)).foregroundStyle(q.color("primary"))}else if !n.group.isEmpty{Text("В группе").font(qfont(11,.medium)).foregroundStyle(q.color("onSurfaceVariant"))}}.padding(.leading,12).frame(maxWidth:.infinity,alignment:.leading);QIconButton(icon:n.visible ? "Eye":"EyeOff",label:"Видимость",size:44){editor.edit{p in if let i=p.nodes.firstIndex(where:{$0.id==n.id}){p.nodes[i].visible.toggle()}}};QIconButton(icon:n.locked ? "Lock":"Unlock",label:"Блокировка",size:44){editor.edit{p in if let i=p.nodes.firstIndex(where:{$0.id==n.id}){p.nodes[i].locked.toggle()}}}}.padding(.leading,8).background(editor.selection.contains(n.id) ? q.color("secondaryContainer"):.clear,in:RoundedRectangle(cornerRadius:16)).contentShape(Rectangle()).onTapGesture{if editor.multiSelect{if editor.selection.contains(n.id){editor.selection.remove(n.id)}else{editor.selection.insert(n.id)}}else{editor.selection=[n.id]}}}}}
}
struct AlignPanel:View {
    @ObservedObject var editor:Editor
    @Environment(\.q) var q
    @State private var canvas=false
    var body:some View{VStack(alignment:.leading,spacing:14){if editor.selection.isEmpty{Text("Выберите один или несколько слоёв для выравнивания.").font(qfont(14)).foregroundStyle(q.color("onSurfaceVariant"))};HStack(spacing:8){Text("Относительно").font(qfont(14,.semibold));QChip(title:"Выделения",selected:!canvas && editor.selected.count>=2){canvas=false}.disabled(editor.selected.count<2);QChip(title:"Холста",selected:canvas || editor.selected.count<2){canvas=true}};group("По горизонтали",[("AlignLeft","left"),("AlignHCenter","centerX"),("AlignRight","right")]){editor.alignTo($0,canvas:canvas || editor.selected.count<2)};group("По вертикали",[("AlignTop","top"),("AlignVCenter","centerY"),("AlignBottom","bottom")]){editor.alignTo($0,canvas:canvas || editor.selected.count<2)};group("Равные промежутки",[("DistributeH","h"),("DistributeV","v")]){editor.distribute($0=="h")}.disabled(editor.selected.count<3);group("Одинаковый размер",[("SameWidth","w"),("SameHeight","h")]){editor.matchDimension($0=="w")}.disabled(editor.selected.count<2);QChip(title:"В центр холста",selected:true){editor.alignTo("centerX",canvas:true);editor.alignTo("centerY",canvas:true)}}}
    private func group(_ title:String,_ items:[(String,String)],_ run:@escaping(String)->Void)->some View{VStack(alignment:.leading,spacing:8){Text(title).font(qfont(14,.semibold)).foregroundStyle(q.color("primary"));HStack(spacing:4){ForEach(items,id:\.1){icon,id in QIconButton(icon:icon,label:title,size:52,enabled:!editor.selection.isEmpty){run(id)}}}.padding(4).qSurface(40,"surfaceContainerHighest")}}
}
struct DocumentPanel:View {
    @ObservedObject var editor:Editor
    @Environment(\.q) var q
    @State private var custom=false
    var body:some View{VStack(alignment:.leading,spacing:14){Text("Тон проекта").font(qfont(16,.semibold));Text("Цвета из палитры следуют тону проекта, свои цвета остаются без изменений.").font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"));HStack(spacing:8){QChip(title:"Базовая",selected:!custom){custom=false;editor.applyTone(-16749974,dark:editor.project.tone.dark)};QChip(title:"Свой цвет",selected:custom){custom=true}};if custom{ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){ForEach(seedColors,id:\.self){c in Circle().fill(Color(argb:c)).frame(width:40,height:40).onTapGesture{editor.applyTone(c,dark:editor.project.tone.dark)}}}}};HStack{Text("Тёмная схема").font(qfont(16));Spacer();QSwitch(on:Binding(get:{editor.project.tone.dark},set:{editor.applyTone(editor.project.tone.seed,dark:$0)}))};HStack(spacing:6){ForEach([0,2,5,7,12,16,17],id:\.self){i in Circle().fill(Color(argb:editor.project.tone.colors.indices.contains(i) ? editor.project.tone.colors[i]:0)).frame(width:28,height:28).overlay(Circle().stroke(q.color("outlineVariant")))}};Text("Холст").font(qfont(16,.semibold));ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){ForEach(["360x800","360x640","834x1194","512x512","1280x800"],id:\.self){size in QChip(title:size,selected:size=="\(Int(editor.project.w))x\(Int(editor.project.h))"){let v=size.split(separator:"x").compactMap{Double($0)};editor.edit{$0.w=CGFloat(v[0]);$0.h=CGFloat(v[1])};editor.fitVersion+=1}.fixedSize()}}};HStack(spacing:8){QNumber(title:"Ширина",value:Binding(get:{editor.project.w},set:{v in editor.edit{$0.w=max(16,min(4096,v))}}));QNumber(title:"Высота",value:Binding(get:{editor.project.h},set:{v in editor.edit{$0.h=max(16,min(4096,v))}}))};QColorRow(title:"Фон листа",color:Binding(get:{editor.project.bg},set:{v in editor.edit{$0.bg=v;$0.bgToken = -1}}),colors:editor.project.tone.colors,token:Int64(editor.project.bgToken),picked:{c,t in editor.edit{$0.bg=c;$0.bgToken=Int(t)}});QToggle("Сетка 8 dp",isOn:$editor.showGrid);QToggle("Умные направляющие",isOn:$editor.snap)}}
}
extension Editor {
    func alignTo(_ mode:String,canvas:Bool){guard canvas else{align(mode);return};let box=CGRect(x:0,y:0,width:project.w,height:project.h);change{n in switch mode{case "left":n.x=0;case "right":n.x=box.width-n.w;case "top":n.y=0;case "bottom":n.y=box.height-n.h;case "centerX":n.x=(box.width-n.w)/2;case "centerY":n.y=(box.height-n.h)/2;default:break}}}
    func matchDimension(_ width:Bool){guard let max=selected.map({width ? $0.w:$0.h}).max()else{return};change{n in if width{n.w=max}else{n.h=max}}}
}
