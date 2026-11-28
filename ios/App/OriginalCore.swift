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
    private var modernFields:[String:Node]=[:]
    private var nativeProject:Project?
    private var projectGlassMode:Int?
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
            nativeProject=project
            modernFields=Dictionary((project.pages.flatMap(\.nodes)+project.nodes).map{($0.id,$0)},uniquingKeysWith:{_,b in b});projectGlassMode=project.glassMode
            layerExtras=Dictionary((project.pages.flatMap(\.nodes)+project.nodes).compactMap{n in n.extras.map{(n.id,$0)}},uniquingKeysWith:{_,new in new})
            studioDocument=project.studio;savedLinks=project.links
            textAlignments=Dictionary((project.pages.flatMap(\.nodes)+project.nodes).map{($0.id,$0.textAlign)},uniquingKeysWith: { _,new in new })
            var compatible=project
            func alias(_ node:Node)->Node {
                var n=node
                if n.widget.hasPrefix("switch:itrack"){n.widget=n.widget.replacingOccurrences(of:"switch:itrack",with:"switch:track")}
                if n.widget.hasPrefix("switch:ithumb"){n.widget="switch:thumb"}
                return n
            }
            compatible.nodes=compatible.nodes.map(alias)
            for i in compatible.pages.indices{compatible.pages[i].nodes=compatible.pages[i].nodes.map(alias)}
            request["project"]=try JSONSerialization.jsonObject(with:JSONEncoder().encode(compatible))
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
        func restore(_ node:Node)->Node {
            var n=node;n.textAlign=textAlignments[n.id] ?? n.textAlign;n.extras=layerExtras[n.id] ?? n.extras
            if let old=modernFields[n.id]{
                n.liquid=old.liquid;n.fixW=old.fixW;n.fixH=old.fixH;n.textVAlign=old.textVAlign;n.spans=old.spans
                n.cornerRadii=old.cornerRadii;n.outer=old.outer;n.appear=old.appear;n.appearSpring=old.appearSpring
                n.liquidDepth=old.liquidDepth;n.liquidPower=old.liquidPower;n.liquidHighlight=old.liquidHighlight;n.liquidHighlightWidth=old.liquidHighlightWidth
                if AppleControls.isApple(old){n.widget=old.widget}
            };return n
        }
        decoded.nodes=decoded.nodes.map(restore)
        for i in decoded.pages.indices {decoded.pages[i].nodes=decoded.pages[i].nodes.map(restore)}
        decoded.glassMode=projectGlassMode;decoded.studio=studioDocument;decoded.links=savedLinks;decoded.motion=nativeProject?.motion
        if ["apply","stop"].contains(operation),let base=nativeProject {
            AppleControls.apply(&decoded,base:base,values:values["shown"] as? [String:Double] ?? [:])
            decoded.syncPage()
        }
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
    private var lastFrameTime=0.0
    private var rendered:Project?
    private var activeHit:[String:Any]?
    private var initial=CGPoint.zero
    private var lastStep=0
    private var visibility:[String:Bool]=[:]
    private var back:[Int]=[]
    var frozen=false
    private var freezeTime=0.0
    private var pausedDuration=0.0
    private var lastMotionTime=0.0
    private var firedJumps:Set<Int>=[]
    private let appearances=LayerAppearanceRuntime()
    private var cachedWidgets:Project?
    private var cachedValues:[String:Double]=[:]
    init(editor:Editor) { self.editor=editor }
    var display:Project? { rendered }
    func start() {
        guard let editor else { return }
        do {
            let result=try OriginalCore.shared.request(["op":"set"],project:editor.project)
            target=[:];kinds=[:];visibility=[:]
            for w in result["widgets"] as? [[String:Any]] ?? [] { if let group=w["group"] as? String { target[group]=(w["value"] as? NSNumber)?.doubleValue ?? 0;kinds[group]=w["kind"] as? String } }
            AppleControls.initial(editor.project,values:&target)
            shown=target;startTime=CACurrentMediaTime();lastFrameTime=startTime;editor.selection=[];editor.playing=true
            frozen=false;pausedDuration=0;lastMotionTime=0;firedJumps=[];appearances.reset();cachedWidgets=nil;cachedValues=[:]
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
        do { let final=try OriginalCore.shared.project("stop",values:["shown":frozen ? shown:target]);let nodes=frozen ? (rendered?.nodes ?? final.nodes):final.nodes;if nodes != editor.project.nodes { editor.edit { $0.nodes=nodes } } } catch { editor.error=error.localizedDescription }
        editor.playing=false;target=[:];shown=[:];rendered=nil
        editor.objectWillChange.send()
    }
    @objc private func frame() {
        guard editor != nil else { link?.invalidate();link=nil;return }
        guard !frozen else{return}
        let now=CACurrentMediaTime()
        var changed=advanceWidgetAnimations(by:now-lastFrameTime)
        lastFrameTime=now
        if links.tick() || appearances.active { changed=true }
        if let data=editor?.project.motion,!data.tracks.isEmpty || !data.jumps.isEmpty{changed=true}
        if changed { refresh() }
    }
    func toggleFreeze(){
        let now=CACurrentMediaTime()
        if frozen{pausedDuration+=now-freezeTime;lastFrameTime=now;frozen=false}else{freezeTime=now;frozen=true}
        editor?.objectWillChange.send()
    }
    @discardableResult func advanceWidgetAnimations(by delta:Double)->Bool {
        var changed=kinds.values.contains("spin")
        let fraction=1-exp(-18*min(0.05,max(0,delta)))
        for (group,value) in target {
            let current=shown[group] ?? value
            if current != value {
                let next=current+(value-current)*fraction
                shown[group]=abs(value-next)<0.001 ? value:next
                changed=true
            }
            if kinds[group]=="press",(shown[group] ?? 0)>0.9,value>0.5 {target[group]=0;notifyWidget(group,value:0)}
        }
        return changed
    }
    private func refresh() {
        guard let editor else { return }
        do {
            let elapsed=((frozen ? freezeTime:CACurrentMediaTime())-startTime-pausedDuration)*1000
            var result:Project
            if let cached=cachedWidgets,cachedValues==shown,!kinds.values.contains("spin"){result=cached}
            else{result=try OriginalCore.shared.project("apply",values:["shown":shown,"time":elapsed/1000]);cachedWidgets=result;cachedValues=shown}
            result.nodes=result.nodes.map { n in var n=n;n.visible=visibility[n.id] ?? n.visible;return n }
            result=links.displayed(result)
            if let motion=result.motion {
                let duration=Double(max(1,motion.dur)),time=motion.loop ? elapsed.truncatingRemainder(dividingBy:duration):min(duration,elapsed)
                if time<lastMotionTime{firedJumps=[]};lastMotionTime=time
                for (i,jump) in motion.jumps.enumerated() where Double(jump.t)<=time && !firedJumps.contains(i){
                    firedJumps.insert(i)
                    if jump.from.isEmpty || (editor.project.pages.indices.contains(editor.project.active) && editor.project.pages[editor.project.active].id==jump.from){DispatchQueue.main.async{[weak self] in self?.navigate(jump.to,preserveMotion:true)}}
                }
                result=MotionEvaluator.frame(result,time:time)
            }
            rendered=appearances.frame(result,time:elapsed/1000);editor.objectWillChange.send()
        }
        catch { editor.error=error.localizedDescription;link?.invalidate();link=nil }
    }
    private func linked(_ node:Node,events:[String])->Bool {
        guard let editor else {return false}
        return editor.project.links.contains { rule in
            guard rule.enabled && events.contains(rule.event) else { return false }
            if rule.sourceID == node.id {return true}
            if rule.exactSource==true{return false}
            if !node.group.isEmpty {
                return editor.project.nodes.first(where:{$0.id==rule.sourceID})?.group == node.group
            }
            return false
        }
    }
    func press(_ p:CGPoint,down:Bool){
        guard !frozen else{return}
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
    private func navigate(_ destination:String,preserveMotion:Bool=false){
        guard let editor else{return}
        let clock=startTime,paused=pausedDuration,jumps=firedJumps,time=lastMotionTime
        defer{if preserveMotion{startTime=clock;pausedDuration=paused;firedJumps=jumps;lastMotionTime=time}}
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
        // Keep the current display value so CADisplayLink can animate toward
        // the new target. Direct slider scrubbing still updates immediately.
        notifyWidget(group,value:target[group] ?? 0)
    }
    func tap(_ p:CGPoint) {
        guard !frozen else{return}
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
        guard !frozen else{return}
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
        guard !frozen else{return}
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
        guard !frozen else{return}
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
