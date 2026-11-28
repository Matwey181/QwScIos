import SwiftUI
import Combine

struct MotionPresetCatalog:Decodable {
    struct Template:Decodable,Identifiable{var id:String;var name:String;var category:String;var duration:Int;var tracks:[MotionTrack]}
    struct Curve:Decodable,Identifiable{var id:String;var name:String;var group:String;var curve:String}
    var templates:[Template];var curves:[Curve]
    static let shared:Self={
        guard let url=Bundle.main.url(forResource:"motion-presets",withExtension:"json"),let data=try? Data(contentsOf:url),let value=try? JSONDecoder().decode(Self.self,from:data)else{fatalError("Missing motion presets")};return value
    }()
}

struct MotionPanel:View {
    @ObservedObject var editor:Editor
    @Environment(\.dismiss) private var dismiss
    @Environment(\.q) private var q
    @State private var time=0.0
    @State private var playing=false
    @State private var lastDate:Date?
    @State private var tab="tracks"
    @State private var property="x"
    @State private var target=""
    @State private var group=false
    @State private var trackID:String?
    @State private var keyTime:Int?
    @State private var exportVideo=false
    private let timer=Timer.publish(every:1/60,on:.main,in:.common).autoconnect()
    private var data:MotionData{editor.project.motion ?? MotionData()}
    private var selectedTrack:MotionTrack?{data.tracks.first{$0.id==trackID}}
    private var selectedKey:MotionKey?{selectedTrack?.keys.first{$0.t==keyTime}}
    var body:some View {
        VStack(spacing:0){
            HStack{QIconButton(icon:"Back",label:"Готово"){dismiss()};Text("Анимация").font(qfont(22,.semibold));Spacer();QIconButton(icon:"Export",label:"Видео"){playing=false;exportVideo=true}}
            MotionPreview(project:MotionEvaluator.frame(editor.project,time:time),renderer:editor.renderer).frame(maxHeight:230).padding(10)
            HStack(spacing:12){
                QIconButton(icon:playing ? "Stop":"Play",label:"Воспроизведение"){playing.toggle();lastDate=nil;if time>=Double(data.dur){time=0}}
                Text(String(format:"%.2f / %.2f с",time/1000,Double(data.dur)/1000)).font(qfont(14,.semibold)).monospacedDigit()
                Spacer()
                Button{previousKey()}label:{Image(systemName:"backward.end.fill")}
                Button{nextKey()}label:{Image(systemName:"forward.end.fill")}
                Button{addKey()}label:{Image(systemName:"diamond.fill")}.disabled(target.isEmpty)
            }.padding(.horizontal,16)
            Slider(value:$time,in:0...Double(max(1,data.dur)),onEditingChanged:{if $0{playing=false}}).tint(q.color("primary")).padding(.horizontal,20)
            HStack{ForEach([("tracks","Свойства"),("templates","Шаблоны"),("curve","Кривая"),("more","Ещё")],id:\.0){id,title in QChip(title:title,selected:tab==id){tab=id}}}.padding(12)
            ScrollView{VStack(alignment:.leading,spacing:16){
                if tab=="tracks"{tracksContent}
                if tab=="templates"{templatesContent}
                if tab=="curve"{curveContent}
                if tab=="more"{settingsContent}
            }.padding(16)}
        }
        .background(q.color("surface"))
        .onAppear{target=editor.selected.first?.id ?? editor.project.nodes.first?.id ?? ""}
        .onReceive(timer){date in
            guard playing else{lastDate=nil;return}
            let delta=lastDate.map{date.timeIntervalSince($0)*1000} ?? 0;lastDate=date;time+=min(100,delta)
            if time>Double(data.dur){if data.loop{time=time.truncatingRemainder(dividingBy:Double(data.dur))}else{time=Double(data.dur);playing=false}}
        }
        .sheet(isPresented:$exportVideo){MotionVideoPanel(editor:editor).modifier(OriginalTheme())}
    }
    private var tracksContent:some View{
        VStack(alignment:.leading,spacing:14){
            LinkChoiceField(title:"Объект",selection:$target,items:editor.project.nodes.map{($0.id,$0.name.isEmpty ? "Слой":$0.name)})
            if let n=editor.project.nodes.first(where:{$0.id==target}),!n.group.isEmpty{QToggle("Анимировать всю группу",isOn:$group)}
            LinkChoiceField(title:"Свойство",selection:$property,items:MotionData.properties)
            LinkPill(title:"Добавить ключ в текущей позиции",icon:"diamond.fill",prominent:true){addKey()}.disabled(target.isEmpty)
            ForEach(data.tracks){tr in
                VStack(alignment:.leading,spacing:8){
                    HStack{
                        Text((MotionData.properties.first{$0.0==tr.prop}?.1 ?? tr.prop)+" · "+targetName(tr)).font(qfont(14,.semibold));Spacer()
                        Button(role:.destructive){edit{$0.tracks.removeAll{$0.id==tr.id}}}label:{Image(systemName:"trash")}
                    }
                    GeometryReader{g in
                        ZStack(alignment:.leading){
                            Capsule().fill(q.color("outlineVariant")).frame(height:2)
                            Rectangle().fill(q.color("primary")).frame(width:2,height:28).offset(x:max(0,g.size.width-16)*time/Double(max(1,data.dur))+7)
                            ForEach(Array(tr.keys.enumerated()),id:\.offset){_,key in
                                Button{playing=false;trackID=tr.id;keyTime=key.t;time=Double(key.t);property=tr.prop;target=tr.group ? (editor.project.nodes.first{$0.group==tr.ref}?.id ?? target):tr.ref;group=tr.group}label:{Image(systemName:trackID==tr.id && keyTime==key.t ? "diamond.fill":"diamond").font(.system(size:16)).foregroundStyle(q.color("primary"))}
                                    .offset(x:max(0,g.size.width-16)*Double(key.t)/Double(max(1,data.dur)))
                            }
                        }.frame(height:32)
                    }.frame(height:32)
                }.padding(12).qSurface(18,trackID==tr.id ? "secondaryContainer":"surfaceContainer")
            }
            if let key=selectedKey,let tr=selectedTrack{
                StudioCard(title:"Ключ \(key.t) мс"){
                    QNumber(title:"Время, мс",value:Binding(get:{CGFloat(key.t)},set:{v in updateKey{ $0.t=min(data.dur,max(0,Int(v)));keyTime=$0.t }}))
                    if tr.prop=="fill"{ColorPicker("Цвет",selection:Binding(get:{Color(argb:key.c)},set:{v in updateKey{$0.c=UIColor(v).argb}}))}
                    else if tr.prop=="shape"{LinkChoiceField(title:"Форма",selection:Binding(get:{key.s},set:{v in updateKey{$0.s=v}}),items:Catalog.shared.shapes.map{($0.id,$0.name)})}
                    else{QNumber(title:"Значение",value:Binding(get:{CGFloat(key.v)},set:{v in updateKey{$0.v=Double(v)}}))}
                    Button("Настроить кривую"){tab="curve"}
                    Button("Удалить ключ",role:.destructive){edit{m in if let i=m.tracks.firstIndex(where:{$0.id==tr.id}){m.tracks[i].keys.removeAll{$0.t==key.t}}};keyTime=nil}
                }
            }
        }
    }
    private var templatesContent:some View{
        VStack(alignment:.leading,spacing:14){
            Text("Шаблон добавляется к выбранному объекту с текущего времени.").font(qfont(13))
            ForEach([("enter","Появление"),("exit","Исчезновение"),("attention","Акцент"),("loop","Циклы"),("ui","Интерфейс"),("shape","Формы")],id:\.0){category,title in
                Text(title).font(qfont(18,.semibold))
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:8){ForEach(MotionPresetCatalog.shared.templates.filter{$0.category==category}){preset in
                    Button{apply(preset)}label:{Text(presetTitle(preset)).font(qfont(14,.medium)).frame(maxWidth:.infinity,minHeight:48).qSurface(16,"surfaceContainerHigh")}.buttonStyle(QPressStyle()).disabled(target.isEmpty)
                }}
            }
        }
    }
    private var curveContent:some View{
        VStack(alignment:.leading,spacing:14){
            if let key=selectedKey{
                MotionCurvePreview(curve:key.e).frame(height:150).padding(16).qSurface(24,"surfaceContainer")
                Text("Кривая действует от выбранного ключа до следующего.").font(qfont(13))
                LinkChoiceField(title:"Тип кривой",selection:Binding(get:{String(key.e.split(separator:":").first ?? "lin")},set:{v in updateKey{$0.e=["lin":"lin","bz":"bz:0.2,0,0,1","sp":"sp:380,0.8","bn":"bn:3,0.5","el":"el:2.5,9","st":"st:4,1","ch":MotionCurve.emphasized][v] ?? "lin"}}),items:[("lin","Линейная"),("bz","Кубическая Безье"),("sp","Пружина"),("bn","Отскок"),("el","Эластичная"),("st","Ступени"),("ch","Material 3 Emphasized")])
                curveParameters(key.e)
                ForEach(Array(Dictionary(grouping:MotionPresetCatalog.shared.curves,by:\.group).keys.sorted()),id:\.self){group in
                    Text(group).font(qfont(16,.semibold))
                    ForEach(MotionPresetCatalog.shared.curves.filter{$0.group==group}){curve in
                        QChip(title:curve.name,selected:key.e==curve.curve){updateKey{$0.e=curve.curve}}
                    }
                }
            }else{Text("Выберите ромб ключа на вкладке «Свойства».").font(qfont(16))}
        }
    }
    @ViewBuilder private func curveParameters(_ encoded:String)->some View{
        let bits=encoded.split(separator:":",maxSplits:1),type=String(bits.first ?? "lin")
        let values=bits.count>1 ? bits[1].split(separator:",").compactMap{Double($0)}:[]
        let names=["bz":["X1","Y1","X2","Y2"],"sp":["Жёсткость","Демпфирование"],"bn":["Отскоков","Упругость"],"el":["Циклы","Затухание"],"st":["Ступеней","В конце: 1 / в начале: 0"]][type] ?? []
        ForEach(Array(names.enumerated()),id:\.offset){index,title in
            if values.indices.contains(index){QNumber(title:title,value:Binding(get:{CGFloat(values[index])},set:{v in var p=values;p[index]=Double(v);updateKey{$0.e=type+":"+p.map{String($0)}.joined(separator:",")}}))}
        }
    }
    private var settingsContent:some View{
        VStack(alignment:.leading,spacing:16){
            QNumber(title:"Длительность, мс",value:Binding(get:{CGFloat(data.dur)},set:{v in edit{$0.dur=min(3_600_000,max(100,Int(v)))};time=min(time,Double(data.dur))}))
            QToggle("Повторять",isOn:Binding(get:{data.loop},set:{v in edit{$0.loop=v}}))
            if editor.project.pages.count>1{
                Text("Переход по времени").font(qfont(18,.semibold))
                ForEach(editor.project.pages){page in Button("В \(String(format:"%.2f",time/1000)) с → \(page.name)"){edit{$0.jumps.append(MotionJump(t:Int(time),from:editor.project.pages[editor.project.active].id,to:page.id))}}.font(qfont(14))
                ForEach(Array(data.jumps.enumerated()),id:\.offset){index,jump in HStack{Text("\(jump.t) мс → \(editor.project.pages.first{$0.id==jump.to}?.name ?? jump.to)");Spacer();Button(role:.destructive){edit{$0.jumps.remove(at:index)}}label:{Image(systemName:"trash")}}}
            }
            LinkPill(title:"Экспорт MP4 / последовательности PNG",icon:"film"){playing=false;exportVideo=true}
            Button("Удалить всю анимацию",role:.destructive){editor.edit{$0.motion=nil};time=0;playing=false}
        }
    }
    private func edit(_ change:(inout MotionData)->Void){editor.edit{p in var m=p.motion ?? MotionData();change(&m);p.motion=m}}
    private func targetName(_ tr:MotionTrack)->String{tr.group ? "Группа":editor.project.nodes.first{$0.id==tr.ref}?.name ?? "Слой"}
    private func updateKey(_ change:(inout MotionKey)->Void){guard let id=trackID,let t=keyTime else{return};edit{m in guard let i=m.tracks.firstIndex(where:{$0.id==id}),let j=m.tracks[i].keys.firstIndex(where:{$0.t==t})else{return};change(&m.tracks[i].keys[j]);m.tracks[i].keys.sort{$0.t<$1.t}}}
    private func addKey(){
        guard let node=editor.project.nodes.first(where:{$0.id==target})else{return}
        let isGroup=group && !node.group.isEmpty,ref=isGroup ? node.group:node.id,t=Int(time.rounded())
        var track=data.tracks.first{$0.ref==ref && $0.group==isGroup && $0.prop==property} ?? MotionTrack(ref:ref,prop:property)
        track.group=isGroup
        let rest:[String:Double]=["sc":1,"sx":1,"sy":1,"op":1,"cr":Double(node.corner),"w":Double(node.w),"h":Double(node.h),"bl":Double(node.softBlur)]
        let key=MotionKey(t:t,v:track.value(time,rest[property] ?? 0),c:node.fill,s:node.shapeId,e:MotionCurve.standard)
        track.keys.removeAll{$0.t==t};track.keys.append(key);track.keys.sort{$0.t<$1.t}
        edit{m in if let i=m.tracks.firstIndex(where:{$0.id==track.id}){m.tracks[i]=track}else{m.tracks.append(track)}}
        trackID=track.id;keyTime=t
    }
    private func previousKey(){playing=false;time=Double(data.tracks.flatMap(\.keys).map(\.t).filter{Double($0)<time-0.5}.max() ?? 0)}
    private func nextKey(){playing=false;time=Double(data.tracks.flatMap(\.keys).map(\.t).filter{Double($0)>time+0.5}.min() ?? data.dur)}
    private func presetTitle(_ p:MotionPresetCatalog.Template)->String{let key="tpl_"+p.id.replacingOccurrences(of:"-",with:"_");let value=tr(key);return value==key ? p.name:value}
    private func apply(_ preset:MotionPresetCatalog.Template){
        guard let node=editor.project.nodes.first(where:{$0.id==target})else{return}
        if preset.id=="morph" && node.kind != "SHAPE"{return}
        if ["corner-pop","press"].contains(preset.id) && node.kind != "RECT"{return}
        let start=Int(time),isGroup=group && !node.group.isEmpty
        let tracks=preset.tracks.map{original in var tr=original;tr.id=UUID().uuidString;tr.ref=isGroup ? node.group:node.id;tr.group=isGroup;tr.keys=tr.keys.map{key in var k=key;k.t+=start;if tr.prop=="cr"{k.v=k.v/16*Double(node.corner)};if tr.prop=="shape",k.s=="circle"{k.s=node.shapeId};return k};return tr}
        edit{m in m.tracks+=tracks;m.dur=max(m.dur,start+preset.duration)}
        trackID=tracks.first?.id;keyTime=tracks.first?.keys.first?.t;playing=true;lastDate=nil
    }
}

struct MotionCurvePreview:View {
    var curve:String
    @Environment(\.q) private var q
    var body:some View{Canvas{context,size in
        let rect=CGRect(x:10,y:20,width:max(1,size.width-20),height:max(1,size.height-40))
        var grid=Path();for i in 0...4{let f=CGFloat(i)/4;grid.move(to:CGPoint(x:rect.minX+rect.width*f,y:rect.minY));grid.addLine(to:CGPoint(x:rect.minX+rect.width*f,y:rect.maxY));grid.move(to:CGPoint(x:rect.minX,y:rect.minY+rect.height*f));grid.addLine(to:CGPoint(x:rect.maxX,y:rect.minY+rect.height*f))};context.stroke(grid,with:.color(q.color("outlineVariant")),style:StrokeStyle(lineWidth:1,dash:[4,6]))
        var path=Path();for i in 0...240{let t=Double(i)/240,value=MotionCurve.at(curve,t),p=CGPoint(x:rect.minX+rect.width*t,y:rect.maxY-rect.height*value);if i==0{path.move(to:p)}else{path.addLine(to:p)}};context.stroke(path,with:.color(q.color("primary")),style:StrokeStyle(lineWidth:4,lineCap:.round,lineJoin:.round))
    }}
}
struct MotionPreview:UIViewRepresentable {
    var project:Project;var renderer:DocumentRenderer
    func makeUIView(context:Context)->MotionPreviewView{MotionPreviewView()}
    func updateUIView(_ view:MotionPreviewView,context:Context){view.project=project;view.renderer=renderer;view.setNeedsDisplay()}
}
final class MotionPreviewView:UIView {
    var project=Project();var renderer:DocumentRenderer?
    override func draw(_ rect:CGRect){guard let c=UIGraphicsGetCurrentContext(),let renderer else{return};let s=min(bounds.width/project.w,bounds.height/project.h);c.saveGState();c.translateBy(x:(bounds.width-project.w*s)/2,y:(bounds.height-project.h*s)/2);c.scaleBy(x:s,y:s);renderer.draw(project,in:c);c.restoreGState()}
}
