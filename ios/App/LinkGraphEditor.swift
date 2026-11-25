import SwiftUI

private struct LinkGraphNode:Identifiable,Equatable {
    enum Kind {case source,event,action,target}
    let id:String
    let kind:Kind
    let title:String
    let subtitle:String
    let icon:String
    let ruleID:String?
    var position:CGPoint
    var size:CGSize {
        switch kind {case .source:return CGSize(width:196,height:92);case .event:return CGSize(width:206,height:104);case .action:return CGSize(width:226,height:116);case .target:return CGSize(width:196,height:92)}
    }
}

private struct LinkGraphEdge:Identifiable,Equatable {
    let id:String
    let from:String
    let to:String
    let colorRole:String
}

private enum LinkGraphSheet:String,Identifiable {case inspector,states,timeline,sets;var id:String{rawValue}}

struct LinkGraphEditor:View {
    @ObservedObject var editor:Editor
    let source:Node
    @Environment(\.q) private var q
    @State private var positions:[String:CGPoint]=[:]
    @State private var pan=CGSize(width:64,height:40)
    @State private var panStart:CGSize?
    @State private var zoom:CGFloat=0.78
    @State private var magnifyStart:CGFloat?
    @State private var selectedID:String?
    @State private var sheet:LinkGraphSheet?
    @State private var sceneVisible=false
    @State private var wireProgress:CGFloat=0
    @State private var draggingID:String?
    @State private var dragStart:CGPoint?
    @State private var showHelp=true

    private var rules:[InteractionLink] {editor.links(for:source)}
    private var graph:(nodes:[LinkGraphNode],edges:[LinkGraphEdge]) {buildGraph()}

    var body:some View {
        GeometryReader{proxy in
            ZStack{
                LinkGraphGrid(pan:pan,zoom:zoom).contentShape(Rectangle()).gesture(canvasDrag).onTapGesture{selectedID=nil}
                wires(size:proxy.size)
                ForEach(Array(graph.nodes.enumerated()),id:\.element.id){index,node in graphNode(node,order:index)}
                if rules.isEmpty{emptyState}
                if showHelp{helpCard}
                controls(size:proxy.size)
            }
            .clipped()
            .simultaneousGesture(magnification)
            .onAppear{
                fit(in:proxy.size)
                DispatchQueue.main.asyncAfter(deadline:.now()+0.08){
                    withAnimation(.spring(response:0.72,dampingFraction:0.86)){sceneVisible=true}
                    withAnimation(.easeInOut(duration:0.9).delay(0.12)){wireProgress=1}
                }
            }
            .onChange(of:rules.map(\.id)){_,_ in withAnimation(.spring(response:0.55,dampingFraction:0.84)){seedMissingPositions()}}
            .sheet(item:$sheet){kind in sheetView(kind)}
        }
        .background(q.color("surface"))
    }

    private func buildGraph()->(nodes:[LinkGraphNode],edges:[LinkGraphEdge]) {
        let count=max(1,rules.count),row:CGFloat=162
        var nodes:[LinkGraphNode]=[];var edges:[LinkGraphEdge]=[]
        let sourceKey="source:"+source.id
        let sourceDefault=CGPoint(x:116,y:CGFloat(count-1)*row/2+120)
        nodes.append(LinkGraphNode(id:sourceKey,kind:.source,title:source.name.isEmpty ? "Источник":source.name,subtitle:"Объект на экране",icon:"square.dashed.inset.filled",ruleID:nil,position:positions[sourceKey] ?? sourceDefault))
        var targetRows:[String:[CGFloat]]=[:]
        for (index,rule) in rules.enumerated(){targetRows[rule.targetID,default:[]].append(CGFloat(index)*row+120)}
        for (index,rule) in rules.enumerated(){
            let y=CGFloat(index)*row+120
            let eventID="event:"+rule.id,actionID="action:"+rule.id,targetID="target:"+rule.targetID
            let event=InteractionLink.events.first{$0.0==rule.event}?.1 ?? rule.event
            let effect=InteractionLink.effects.first{$0.0==rule.mode}?.1 ?? rule.mode
            let property=InteractionLink.properties.first{$0.0==rule.property}?.1 ?? rule.property
            nodes.append(LinkGraphNode(id:eventID,kind:.event,title:event,subtitle:rule.enabled ? "Триггер активен":"Триггер выключен",icon:eventIcon(rule.event),ruleID:rule.id,position:positions[eventID] ?? CGPoint(x:390,y:y)))
            nodes.append(LinkGraphNode(id:actionID,kind:.action,title:effect,subtitle:actionSubtitle(rule,property:property),icon:actionIcon(rule.mode),ruleID:rule.id,position:positions[actionID] ?? CGPoint(x:680,y:y)))
            edges.append(LinkGraphEdge(id:"\(rule.id):source",from:sourceKey,to:eventID,colorRole:"secondary"))
            edges.append(LinkGraphEdge(id:"\(rule.id):event",from:eventID,to:actionID,colorRole:rule.enabled ? "primary":"outline"))
            edges.append(LinkGraphEdge(id:"\(rule.id):target",from:actionID,to:targetID,colorRole:rule.enabled ? "tertiary":"outline"))
        }
        for (target,rows) in targetRows {
            let id="target:"+target,y=rows.reduce(0,+)/CGFloat(rows.count)
            let layer=editor.project.nodes.first{$0.id==target}
            nodes.append(LinkGraphNode(id:id,kind:.target,title:layer?.name ?? "Нет слоя",subtitle:layerSubtitle(layer),icon:layerIcon(layer),ruleID:nil,position:positions[id] ?? CGPoint(x:980,y:y)))
        }
        return (nodes,edges)
    }

    private func screen(_ point:CGPoint)->CGPoint {CGPoint(x:point.x*zoom+pan.width,y:point.y*zoom+pan.height)}

    @ViewBuilder private func wires(size:CGSize)->some View {
        let nodes=Dictionary(uniqueKeysWithValues:graph.nodes.map{($0.id,$0)})
        ForEach(graph.edges){edge in
            if let a=nodes[edge.from],let b=nodes[edge.to]{
                let start=screen(CGPoint(x:a.position.x+a.size.width/2,y:a.position.y))
                let end=screen(CGPoint(x:b.position.x-b.size.width/2,y:b.position.y))
                LinkGraphWire(start:start,end:end,progress:wireProgress).stroke(q.color(edge.colorRole).opacity(0.16),style:StrokeStyle(lineWidth:9*zoom,lineCap:.round)).frame(width:size.width,height:size.height)
                LinkGraphWire(start:start,end:end,progress:wireProgress).stroke(q.color(edge.colorRole),style:StrokeStyle(lineWidth:max(2,3*zoom),lineCap:.round)).frame(width:size.width,height:size.height)
            }
        }
    }

    private func graphNode(_ node:LinkGraphNode,order:Int)->some View {
        let selected=selectedID==node.id
        return Button{
            selectedID=node.id
            if node.ruleID != nil{sheet = .inspector}
        }label:{
            VStack(alignment:.leading,spacing:9){
                HStack(spacing:9){
                    Image(systemName:node.icon).font(.system(size:15,weight:.semibold)).foregroundStyle(q.color(node.kind == .action ? "onPrimaryContainer":"primary")).frame(width:32,height:32).background(q.color(node.kind == .action ? "primaryContainer":"surfaceContainerHighest"),in:RoundedRectangle(cornerRadius:11))
                    Text(kindTitle(node.kind)).font(qfont(11,.semibold)).foregroundStyle(q.color("onSurfaceVariant")).tracking(0.6)
                    Spacer(minLength:0)
                    if node.kind == .action{Circle().fill(ruleEnabled(node.ruleID) ? Color.green:q.color("outline")).frame(width:8,height:8)}
                }
                Text(node.title).font(qfont(15,.semibold)).lineLimit(1)
                Text(node.subtitle).font(qfont(11)).foregroundStyle(q.color("onSurfaceVariant")).lineLimit(1)
            }
            .padding(14)
            .frame(width:node.size.width,height:node.size.height,alignment:.leading)
            .background(q.color(node.kind == .action ? "surfaceContainerHigh":"surfaceContainer"),in:RoundedRectangle(cornerRadius:22))
            .overlay(RoundedRectangle(cornerRadius:22).stroke(selected ? q.color("primary"):q.color("outlineVariant").opacity(0.6),lineWidth:selected ? 2:1))
            .shadow(color:selected ? q.color("primary").opacity(0.22):Color.black.opacity(0.12),radius:selected ? 20:8,y:selected ? 8:4)
            .overlay(alignment:.leading){port(color:"secondary").offset(x:-7)}
            .overlay(alignment:.trailing){port(color:node.kind == .action ? "tertiary":"primary").offset(x:7)}
        }
        .buttonStyle(LinkNodePressStyle())
        .scaleEffect(zoom)
        .position(screen(node.position))
        .opacity(sceneVisible ? 1:0)
        .offset(y:sceneVisible ? 0:26)
        .animation(.spring(response:0.68,dampingFraction:0.82).delay(Double(order)*0.035),value:sceneVisible)
        .zIndex(draggingID==node.id ? 20:selected ? 10:1)
        .simultaneousGesture(nodeDrag(node))
        .accessibilityLabel("\(kindTitle(node.kind)): \(node.title)")
    }

    private func port(color:String)->some View {Circle().fill(q.color(color)).frame(width:14,height:14).overlay(Circle().stroke(q.color("surface"),lineWidth:3)).shadow(color:q.color(color).opacity(0.35),radius:5)}

    private func controls(size:CGSize)->some View {
        VStack{Spacer();HStack(spacing:10){
            Button{addRule()}label:{Label("Связка",systemImage:"plus").font(qfont(14,.semibold)).padding(.horizontal,18).frame(height:52).foregroundStyle(q.color("onPrimary")).background(q.color("primary"),in:Capsule())}.buttonStyle(QPressStyle())
            Spacer()
            graphControl("square.stack.3d.up"){sheet = .sets}
            graphControl("circle.grid.cross"){withAnimation(.spring(response:0.6,dampingFraction:0.84)){fit(in:size)}}
            graphControl("timeline.selection"){sheet = .timeline}
            graphControl("camera.filters"){sheet = .states}
        }.padding(12).background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:29)).overlay(RoundedRectangle(cornerRadius:29).stroke(q.color("outlineVariant").opacity(0.55))).padding(14)}
    }

    private func graphControl(_ icon:String,action:@escaping()->Void)->some View {Button(action:action){Image(systemName:icon).font(.system(size:17,weight:.semibold)).frame(width:48,height:48).foregroundStyle(q.color("onSurface")).background(q.color("surfaceContainerHighest").opacity(0.82),in:Circle())}.buttonStyle(QPressStyle())}

    private var helpCard:some View {
        VStack{
            HStack(alignment:.top,spacing:10){
                Image(systemName:"hand.draw").foregroundStyle(q.color("primary"))
                VStack(alignment:.leading,spacing:3){
                    Text("Свободное полотно").font(qfont(13,.semibold))
                    Text("Тяните фон, двигайте узлы и меняйте масштаб двумя пальцами.").font(qfont(11)).foregroundStyle(q.color("onSurfaceVariant"))
                }
                Button{withAnimation{showHelp=false}}label:{Image(systemName:"xmark").font(.system(size:11,weight:.bold)).frame(width:28,height:28)}.buttonStyle(.plain)
            }.padding(13).frame(maxWidth:310).qSurface(20,"surfaceContainerHigh",glass:true,alpha:0.86).padding(14)
            Spacer()
        }.frame(maxWidth:.infinity,alignment:.trailing)
    }

    private var emptyState:some View {VStack(spacing:10){Image(systemName:"point.3.filled.connected.trianglepath.dotted").font(.system(size:30)).foregroundStyle(q.color("primary"));Text("Добавьте первую связку").font(qfont(17,.semibold));Text("Она появится на полотне как цепочка узлов.").font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"));Button("Создать"){addRule()}.buttonStyle(.borderedProminent)}.padding(24).qSurface(26,"surfaceContainerHigh")}

    private var canvasDrag:some Gesture {DragGesture(minimumDistance:2).onChanged{value in if panStart==nil{panStart=pan};if let start=panStart{pan=CGSize(width:start.width+value.translation.width,height:start.height+value.translation.height)}}.onEnded{_ in panStart=nil}}
    private var magnification:some Gesture {MagnificationGesture().onChanged{value in if magnifyStart==nil{magnifyStart=zoom};zoom=min(1.35,max(0.42,(magnifyStart ?? zoom)*value))}.onEnded{_ in magnifyStart=nil}}
    private func nodeDrag(_ node:LinkGraphNode)->some Gesture {DragGesture(minimumDistance:4).onChanged{value in draggingID=node.id;if dragStart==nil{dragStart=node.position};if let start=dragStart{positions[node.id]=CGPoint(x:start.x+value.translation.width/zoom,y:start.y+value.translation.height/zoom)}}.onEnded{_ in withAnimation(.spring(response:0.42,dampingFraction:0.82)){draggingID=nil};dragStart=nil}}

    private func fit(in size:CGSize){
        let base=buildGraph().nodes
        guard !base.isEmpty else{return}
        let minX=base.map{$0.position.x-$0.size.width/2}.min() ?? 0,maxX=base.map{$0.position.x+$0.size.width/2}.max() ?? 1
        let minY=base.map{$0.position.y-$0.size.height/2}.min() ?? 0,maxY=base.map{$0.position.y+$0.size.height/2}.max() ?? 1
        let next=min(1.0,max(0.42,min((size.width-56)/max(1,maxX-minX),(size.height-120)/max(1,maxY-minY))))
        zoom=next;pan=CGSize(width:size.width/2-(minX+maxX)/2*next,height:size.height/2-(minY+maxY)/2*next-10)
    }
    private func seedMissingPositions(){for node in buildGraph().nodes where positions[node.id]==nil{positions[node.id]=node.position}}
    private func addRule(){var link=InteractionLink();link.sourceID=source.id;link.targetID=source.id;editor.edit{$0.links.append(link)};selectedID="action:"+link.id;sheet = .inspector}
    private func ruleEnabled(_ id:String?)->Bool {guard let id else{return true};return editor.project.links.first{$0.id==id}?.enabled ?? false}

    @ViewBuilder private func sheetView(_ kind:LinkGraphSheet)->some View {
        NavigationStack{
            ScrollView{VStack(alignment:.leading,spacing:16){
                switch kind {
                case .inspector:
                    if let id=selectedID?.split(separator:":",maxSplits:1).last.map(String.init),let rule=editor.project.links.first(where:{$0.id==id}){LinkGraphInspector(editor:editor,rule:rule,close:{sheet=nil})}
                case .states:StudioStates(editor:editor,sourceID:source.id)
                case .timeline:StudioTimeline(editor:editor,sourceID:source.id)
                case .sets:MyLinkSetsPanel(editor:editor,source:source)
                }
            }.padding(16)}
            .background(q.color("surfaceContainer").ignoresSafeArea())
            .toolbar{ToolbarItem(placement:.topBarTrailing){Button("Готово"){sheet=nil}.font(qfont(14,.semibold))}}
        }.modifier(OriginalTheme()).presentationDetents(kind == .inspector ? [.medium,.large]:[.large]).presentationDragIndicator(.visible)
    }

    private func kindTitle(_ kind:LinkGraphNode.Kind)->String {switch kind{case .source:return "ИСТОЧНИК";case .event:return "СОБЫТИЕ";case .action:return "ДЕЙСТВИЕ";case .target:return "ЦЕЛЬ"}}
    private func eventIcon(_ event:String)->String {switch event{case "tap":return "hand.tap.fill";case "press","release":return "hand.point.up.left.fill";case "valueChanged","drag":return "slider.horizontal.3";case "start":return "play.fill";default:return "bolt.fill"}}
    private func actionIcon(_ mode:String)->String {switch mode{case "animate":return "sparkles";case "bind":return "link";case "text","typewriter":return "textformat";case "navigate":return "arrow.right.circle.fill";case "state":return "camera.filters";case "echo":return "wave.3.right";default:return "wand.and.stars"}}
    private func layerIcon(_ node:Node?)->String {switch node?.kind{case "TEXT":return "textformat";case "IMAGE":return "photo";case "SHAPE":return "seal.fill";default:return "square.fill"}}
    private func layerSubtitle(_ node:Node?)->String {guard let node else{return "Удалённый объект"};return node.kind == "TEXT" ? "Текстовый слой":node.kind == "IMAGE" ? "Изображение":"Слой проекта"}
    private func actionSubtitle(_ rule:InteractionLink,property:String)->String {if rule.mode=="animate" || rule.mode=="bind"{return "\(property) · \(String(format:"%.2f",rule.duration)) с"};return rule.enabled ? "Нажмите, чтобы настроить":"Связка выключена"}
}

private struct LinkGraphInspector:View {
    @ObservedObject var editor:Editor
    let rule:InteractionLink
    let close:()->Void
    @Environment(\.q) private var q
    var body:some View {VStack(alignment:.leading,spacing:16){
        HStack{VStack(alignment:.leading,spacing:3){Text("Настройка узла").font(qfont(22,.semibold));Text(InteractionLink.events.first{$0.0==rule.event}?.1 ?? rule.event).font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"))};Spacer();QSwitch(on:Binding(get:{current.enabled},set:{v in update{$0.enabled=v}}))}
        HStack(spacing:10){LinkPill(title:"Дублировать",icon:"doc.on.doc"){var copy=current;copy.id=UUID().uuidString;editor.edit{$0.links.append(copy)}};LinkPill(title:"Удалить",icon:"trash"){editor.edit{$0.links.removeAll{$0.id==rule.id}};close()}}
        LinkRuleForm(link:binding,layers:editor.project.nodes,states:editor.project.studio?.states ?? [],pages:editor.project.pages,root:editor.store.root,stopChoices:editor.project.links.map{($0.id,$0.bundleName ?? $0.mode)})
    }}
    private var current:InteractionLink{editor.project.links.first{$0.id==rule.id} ?? rule}
    private var binding:Binding<InteractionLink>{Binding(get:{current},set:{next in update{$0=next}})}
    private func update(_ change:(inout InteractionLink)->Void){editor.edit{p in if let i=p.links.firstIndex(where:{$0.id==rule.id}){change(&p.links[i])}}}
}

private struct LinkGraphGrid:View {
    let pan:CGSize
    let zoom:CGFloat
    @Environment(\.q) private var q
    var body:some View {Canvas{context,size in
        let spacing=max(18,34*zoom),radius=max(0.7,1.2*zoom)
        var x=pan.width.truncatingRemainder(dividingBy:spacing)
        while x<size.width{var y=pan.height.truncatingRemainder(dividingBy:spacing);while y<size.height{context.fill(Path(ellipseIn:CGRect(x:x-radius,y:y-radius,width:radius*2,height:radius*2)),with:.color(q.color("outlineVariant").opacity(0.45)));y += spacing};x += spacing}
    }.background(q.color("surface"))}
}

private struct LinkGraphWire:Shape {
    let start:CGPoint
    let end:CGPoint
    var progress:CGFloat
    var animatableData:CGFloat {get{progress}set{progress=newValue}}
    func path(in rect:CGRect)->Path {var path=Path();path.move(to:start);let distance=max(70,abs(end.x-start.x)*0.48);path.addCurve(to:end,control1:CGPoint(x:start.x+distance,y:start.y),control2:CGPoint(x:end.x-distance,y:end.y));return path.trimmedPath(from:0,to:max(0,min(1,progress)))}
}

private struct LinkNodePressStyle:ButtonStyle {
    func makeBody(configuration:Configuration)->some View {configuration.label.scaleEffect(configuration.isPressed ? 0.965:1).brightness(configuration.isPressed ? -0.04:0).animation(.spring(response:0.28,dampingFraction:0.7),value:configuration.isPressed)}
}
