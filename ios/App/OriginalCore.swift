import Foundation
import JavaScriptCore
import UIKit

@MainActor final class OriginalCore {
    static let shared=OriginalCore()
    private let context:JSContext
    private let function:JSValue
    private var layerExtras:[String:LayerExtras]=[:]
    private var studioDocument:StudioDocument?
    private var savedLinks:[InteractionLink]=[]
    private var textAlignments:[String:String]=[:]
    private init() {
        context=JSContext()!
        let source=try! String(contentsOf:Bundle.main.url(forResource:"qwelcore",withExtension:"js")!,encoding:.utf8)
        context.evaluateScript(source)
        function=context.objectForKeyedSubscript("qwelcore").objectForKeyedSubscript("qwelCore")
        let strings=try! String(contentsOf:Bundle.main.url(forResource:"ru",withExtension:"json")!,encoding:.utf8)
        _ = try? request(["op":"language","strings":strings])
    }
    func request(_ values:[String:Any],project:Project?=nil) throws -> [String:Any] {
        var request=values
        if let project {
            layerExtras=Dictionary((project.pages.flatMap(\.nodes)+project.nodes).compactMap{n in n.extras.map{(n.id,$0)}},uniquingKeysWith:{_,new in new})
            studioDocument=project.studio;savedLinks=project.links
            textAlignments=Dictionary((project.pages.flatMap(\.nodes)+project.nodes).map{($0.id,$0.textAlign)},uniquingKeysWith: { _,new in new })
            request["project"]=try JSONSerialization.jsonObject(with:JSONEncoder().encode(project))
        }
        let data=try JSONSerialization.data(withJSONObject:request,options:[.sortedKeys])
        context.exception=nil
        guard let input=String(data:data,encoding:.utf8),let result=function.call(withArguments:[input]),context.exception==nil,let text=result.toString(),let data=text.data(using:.utf8),let object=try JSONSerialization.jsonObject(with:data) as? [String:Any] else { throw CocoaError(.coderInvalidValue) }
        return object
    }
    func project(_ operation:String,project:Project?=nil,values:[String:Any]=[:]) throws -> Project {
        var request=values;request["op"]=operation
        let output=try self.request(request,project:project)
        var decoded=try JSONDecoder().decode(Project.self,from:JSONSerialization.data(withJSONObject:output))
        func restore(_ node:Node)->Node {var n=node;n.textAlign=textAlignments[n.id] ?? n.textAlign;n.extras=layerExtras[n.id] ?? n.extras;return n}
        decoded.nodes=decoded.nodes.map(restore)
        for i in decoded.pages.indices {decoded.pages[i].nodes=decoded.pages[i].nodes.map(restore)}
        decoded.studio=studioDocument;decoded.links=savedLinks
        return decoded
    }
    func compose(_ project:Project) throws -> String { try request(["op":"compose"],project:project)["code"] as? String ?? "" }
}

@MainActor final class OriginalPlayRuntime:NSObject {
    weak var editor:Editor?
    var target:[String:Double]=[:]
    let links = InteractionRuntime()
    private var lastTapPoint=CGPoint.zero
    private var lastTapGroup=""
    private var pressedSourceID:String?
    private var activeSourceID: String?
    var shown:[String:Double]=[:]
    private var kinds:[String:String]=[:]
    private var link:CADisplayLink?
    private var startTime=0.0
    private var rendered:Project?
    private var activeHit:[String:Any]?
    private var initial=CGPoint.zero
    private var lastStep=0
    private var visibility:[String:Bool]=[:]
    private var back:[Int]=[]
    init(editor:Editor) { self.editor=editor }
    var display:Project? { rendered }
    func start() {
        guard let editor else { return }
        do {
            let result=try OriginalCore.shared.request(["op":"set"],project:editor.project)
            target=[:];kinds=[:];visibility=[:]
            for w in result["widgets"] as? [[String:Any]] ?? [] { if let group=w["group"] as? String { target[group]=(w["value"] as? NSNumber)?.doubleValue ?? 0;kinds[group]=w["kind"] as? String } }
            shown=target;startTime=CACurrentMediaTime();editor.selection=[];editor.playing=true
            links.onWidgetProgress = { [weak self] group,value in
                guard let self else {return}
                self.target[group]=value
                self.shown[group]=value
            }
            links.onNavigate={ [weak self] destination in DispatchQueue.main.async{self?.navigate(destination)} }
            links.onComponent={ [weak self] target,action,value in self?.component(target,action:action,value:value) }
            links.advanced.root=editor.store.root
            links.layoutRenderer=editor.renderer
            links.start(editor.project,widgetValues:shown)
            refresh()
            let link=CADisplayLink(target:self,selector:#selector(frame));link.preferredFramesPerSecond=60;link.add(to:.main,forMode:.common);self.link=link
        } catch { editor.error=error.localizedDescription }
    }
    func stop() {
        link?.invalidate();link=nil
        activeSourceID=nil;pressedSourceID=nil
        links.stop()
        guard let editor else { return }
        do { let final=try OriginalCore.shared.project("stop",values:["shown":target]);if final.nodes != editor.project.nodes { editor.edit { $0.nodes=final.nodes } } } catch { editor.error=error.localizedDescription }
        editor.playing=false;target=[:];shown=[:];rendered=nil
        editor.objectWillChange.send()
    }
    @objc private func frame() {
        guard editor != nil else { link?.invalidate();link=nil;return }
        var changed=kinds.values.contains("spin")
        for (group,value) in target {
            let current=shown[group] ?? value
            if abs(value-current)>0.001 { shown[group]=current+(value-current)*0.4;changed=true }
            if kinds[group]=="press",(shown[group] ?? 0)>0.9,value>0.5 { target[group]=0;notifyWidget(group,value:0) }
        }
        if links.tick() { changed=true }
        if changed { refresh() }
    }
    private func refresh() {
        guard let editor else { return }
        do { var result=try OriginalCore.shared.project("apply",values:["shown":shown,"time":CACurrentMediaTime()-startTime]);result.nodes=result.nodes.map { n in var n=n;n.visible=visibility[n.id] ?? n.visible;return n };rendered=links.displayed(result);editor.objectWillChange.send() }
        catch { editor.error=error.localizedDescription;link?.invalidate();link=nil }
    }
    private func linked(_ node:Node,events:[String])->Bool {
        guard let editor else {return false}
        return editor.project.links.contains { rule in
            guard rule.enabled && events.contains(rule.event) else { return false }
            if rule.sourceID == node.id {return true}
            if !node.group.isEmpty {
                return editor.project.nodes.first(where:{$0.id==rule.sourceID})?.group == node.group
            }
            return false
        }
    }
    func press(_ p:CGPoint,down:Bool){
        if down {
            guard let node=(rendered?.nodes ?? editor?.project.nodes ?? []).reversed().first(where:{$0.visible && $0.extras?.disabled != true && !$0.mask && $0.contains(p) && linked($0,events:["press","release","longPress","holdRepeat","cancelPress"])}) else{return}
            pressedSourceID=node.id;links.advanced.press(node.id,at:p,down:true);links.fire("press",sourceID:node.id)
        }else if let id=pressedSourceID{pressedSourceID=nil;links.advanced.press(id,at:p,down:false);links.fire("release",sourceID:id)}
        refresh()
    }
    func gesture(_ event:String,at point:CGPoint,value:Double?=nil,began:Bool=false){
        guard let editor,let node=(rendered?.nodes ?? editor.project.nodes).reversed().first(where:{candidate in candidate.visible && candidate.extras?.disabled != true && candidate.contains(point) && (linked(candidate,events:[event]) || editor.project.links.contains{r in links.advanced.matches(r.sourceID,candidate.id) && (event=="pinch" && r.mode=="pinchObject" || event=="rotate" && r.mode=="rotateObject")} )}) else{return}
        if let value{links.advanced.transform(event,source:node.id,value:value,began:began)}
        links.fire(event,sourceID:node.id);refresh()
    }
    func hit(_ p:CGPoint)->[String:Any] { (try? OriginalCore.shared.request(["op":"hit","x":p.x,"y":p.y,"pad":8])) ?? [:] }
    private func navigate(_ destination:String){
        guard let editor else{return}
        if destination=="back"{guard let page=back.popLast() else{return};stop();editor.page(page);start()}
        else if let page=editor.project.pages.firstIndex(where:{$0.id==destination}){let previous=editor.project.active;stop();back.append(previous);editor.page(page);start()}
    }
    private func component(_ id:String,action:String,value:Double){
        guard let editor,let node=editor.project.nodes.first(where:{$0.id==id}),!node.group.isEmpty else{return}
        let group=node.group
        if action=="tap" {
            do{let result=try OriginalCore.shared.request(["op":"tap","group":group,"x":lastTapGroup==group ? lastTapPoint.x:node.center.x,"y":lastTapGroup==group ? lastTapPoint.y:node.center.y,"shown":target]);target=result.compactMapValues{($0 as? NSNumber)?.doubleValue}}
            catch{editor.error=error.localizedDescription}
        }else{let current=target[group] ?? 0;target[group]=action=="increase" ? current+value:action=="decrease" ? current-value:value}
        if kinds[group]=="pick"{let count=Set(editor.project.nodes.filter{$0.group==group && $0.widget.hasPrefix("pick:i")}.compactMap{Int($0.widget.dropFirst(6).split(separator:"/").first ?? "")}).count;target[group]=min(Double(max(0,count-1)),max(0,target[group] ?? 0))}
        shown[group]=target[group] ?? 0;notifyWidget(group,value:target[group] ?? 0)
    }
    func tap(_ p:CGPoint) {
        guard let editor else{return}
        let widget=hit(p)
        lastTapPoint=p;lastTapGroup=widget["group"] as? String ?? ""
        if let group=widget["group"] as? String {
            if (rendered?.nodes ?? editor.project.nodes).contains(where:{$0.group==group && $0.extras?.disabled==true}){return}
            if ["slider","progress"].contains(widget["kind"] as? String ?? ""){
                let value=(widget["value"] as? NSNumber)?.doubleValue ?? 0
                target[group]=value;shown[group]=value;notifyWidget(group,value:value)
            }
        }
        if let node=(rendered?.nodes ?? editor.project.nodes).reversed().first(where:{$0.visible && $0.extras?.disabled != true && !$0.mask && $0.contains(p) && linked($0,events:["tap","nthTap","stepTap"])}){links.advanced.tap(node.id);links.fire("tap",sourceID:node.id);refresh();return}
        if let group=widget["group"] as? String,let node=editor.project.nodes.first(where:{$0.group==group && linked($0,events:["tap","nthTap","stepTap"])}){links.advanced.tap(node.id);links.fire("tap",sourceID:node.id)}
        refresh()
    }
    private func notifyWidget(_ group:String,value:Double) {
        guard let node=editor?.project.nodes.first(where:{$0.group==group}) else{return}
        links.advanced.selectedValue(group,kinds[group]=="pick" ? 1:value)
        links.seek(group:group,value:value)
        var fraction=value
        if kinds[group]=="pick",let nodes=editor?.project.nodes {
            let indices=Set(nodes.filter{$0.group==group && $0.widget.hasPrefix("pick:i")}.compactMap{Int($0.widget.dropFirst(6).split(separator:"/").first ?? "")})
            fraction=value/Double(max(1,indices.count-1))
        }
        links.fire("valueChanged",sourceID:node.id,fraction:fraction)
    }
    private func widgetFraction(_ p:CGPoint,_ widget:[String:Any])->Double {
        let x=CGFloat((widget["x"] as? NSNumber)?.doubleValue ?? 0),y=CGFloat((widget["y"] as? NSNumber)?.doubleValue ?? 0)
        let w=CGFloat((widget["w"] as? NSNumber)?.doubleValue ?? 1),h=CGFloat((widget["h"] as? NSNumber)?.doubleValue ?? 1)
        let point=CGPoint(x:min(x+w,max(x,p.x)),y:min(y+h,max(y,p.y)))
        let state=hit(point)
        if state["group"] as? String==widget["group"] as? String {return (state["value"] as? NSNumber)?.doubleValue ?? 0}
        return Double(min(1,max(0,(p.x-x)/max(1,w))))
    }
    private func dragFraction(_ p:CGPoint, sourceID:String)->Double? {
        if let widget=activeHit,["slider","progress"].contains(widget["kind"] as? String ?? "") {return widgetFraction(p,widget)}
        guard let editor,let source=editor.project.nodes.first(where:{$0.id==sourceID}) else {return nil}
        let group: [Node] = source.group.isEmpty ? [source] :
            editor.project.nodes.filter{$0.group == source.group}
        let x0=group.map(\.x).min() ?? source.x
        let x1=group.map{$0.x+$0.w}.max() ?? source.x+source.w
        return Double(min(1,max(0,(p.x-x0)/max(1,x1-x0))))
    }
    func begin(_ p:CGPoint) {
        activeHit=hit(p);initial=p;lastStep=0
        if let group=activeHit?["group"] as? String,(rendered?.nodes ?? []).contains(where:{$0.group==group && $0.extras?.disabled==true}){activeHit=nil;activeSourceID=nil;return}
        if let group=activeHit?["group"] as? String{links.scrub(group:group,true)}
        let events=["dragStart","drag","dragEnd","valueChanged","swipeLeft","swipeRight","swipeUp","swipeDown"]
        if let group=activeHit?["group"] as? String {
            activeSourceID=editor?.project.nodes.first(where:{$0.group==group && linked($0,events:events)})?.id
        } else {activeSourceID=nil}
        if activeSourceID==nil {
            activeSourceID=(rendered?.nodes ?? editor?.project.nodes ?? []).reversed().first(where: { n in
                n.visible && n.extras?.disabled != true && !n.mask && n.contains(p) && linked(n,events:events)
            })?.id
        }
        if let id=activeSourceID {links.fire("dragStart",sourceID:id,fraction:dragFraction(p,sourceID:id));refresh()}
        if ["slider","progress"].contains(activeHit?["kind"] as? String ?? "") { tap(p) }
    }
    func drag(_ p:CGPoint) {
        links.advanced.drag(CGPoint(x:p.x-initial.x,y:p.y-initial.y))
        if let id=activeSourceID {
            links.fire("drag",sourceID:id,fraction:dragFraction(p,sourceID:id))
            refresh()
        }
        guard let widget=activeHit,let group=widget["group"] as? String,let kind=widget["kind"] as? String else { return }
        if ["slider","progress"].contains(kind) {
            // Keep the captured component even when the finger leaves its bounds.
            let value=widgetFraction(p,widget)
            target[group]=value;shown[group]=value
            links.seek(group:group,value:value)
            if activeSourceID==nil {notifyWidget(group,value:value)}
            refresh()
        } else if kind=="pick" {
            let step=Int((initial.x-p.x)/40)
            if step != lastStep {let event=step>lastStep ? "swipeLeft":"swipeRight";lastStep=step;if let node=editor?.project.nodes.first(where:{$0.group==group}){links.fire(event,sourceID:node.id);refresh()}}
        }
    }
    func end(_ p:CGPoint) {
        links.advanced.endDrag()
        let dx=p.x-initial.x,dy=p.y-initial.y
        if let id=activeSourceID,abs(dx)>35 || abs(dy)>35{links.fire(abs(dx)>=abs(dy) ? (dx<0 ? "swipeLeft":"swipeRight"):(dy<0 ? "swipeUp":"swipeDown"),sourceID:id)}
        if let group=activeHit?["group"] as? String{links.scrub(group:group,false)}
        if let id=activeSourceID {
            links.fire("dragEnd",sourceID:id,fraction:dragFraction(p,sourceID:id))
            refresh()
        }
        activeSourceID=nil
        activeHit=nil
    }
}
