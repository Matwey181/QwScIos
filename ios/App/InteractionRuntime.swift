import UIKit
import QuartzCore

/// Shared, deterministic link executor used by editor Play mode.
/// Nothing here edits the original design: effects are projected over a copy.
@MainActor final class InteractionRuntime {
    struct Motion {
        var owner:String = ""
        var sourceID: String
        var targetID: String
        var property: String
        var start: Double
        var duration: Double
        var from: Double
        var initialFrom: Double
        var to: Double
        var easing: String
        var repeats: Bool
        var repeatGap:Double=0
        var totalDuration:Double?
        var colorFrom: Int64
        var colorTo: Int64
    }
    struct EchoPulse {
        var owner:String = ""
        var nodeID: String
        var started: Double
        var duration: Double
        var size: Double
        var easing:String = "easeOut"
        var repeats:Bool = false
        var repeatGap:Double = 0
    }

    private(set) var project = Project()
    var number: [String: [String: Double]] = [:]
    var text: [String: String] = [:]
    private(set) var visibility: [String: Bool] = [:]
    private var paused:[String:Double]=[:]
    private var motions: [Motion] = []
    private var eventDepth=0
    private var widgetValues:[String:Double]=[:]
    private var scrubbingGroups:Set<String>=[]
    private var toggled:Set<String>=[]
    private var morphs:[String:LinkMorph]=[:]
    private var stateLayers:[String:Node]=[:]
    private var echoes: [EchoPulse] = []
    private struct Pending {
        var link:InteractionLink
        var at:Double
        var fraction:Double?
    }
    private var pending:[Pending]=[]
    private var valueEvents:[(String,Double)]=[]
    var layoutRenderer:DocumentRenderer?
    let playback=PlaybackRuntime()
    lazy var advanced:AdvancedLinkEngine={let engine=AdvancedLinkEngine();engine.runtime=self;return engine}()
    var onNavigate:((String)->Void)?
    var onComponent:((String,String,Double)->Void)?
    var onWidgetProgress: ((String, Double) -> Void)?

    var active: Bool { !motions.isEmpty || !echoes.isEmpty || !pending.isEmpty || playback.active || advanced.active }

    func start(_ document: Project,widgetValues:[String:Double]=[:]) {
        advanced.reset()
        project = document
        self.widgetValues=widgetValues;scrubbingGroups=[]
        paused=[:];toggled=[];morphs=[:];valueEvents=[];stateLayers=[:]
        for rule in document.links.flatMap({[$0]+($0.steps ?? [])}) where rule.enabled && rule.property=="morph" {
            if let node=document.nodes.first(where:{$0.id==rule.targetID}),let target=rule.shapeID {
                morphs[node.id]=LinkMorph(from:node.shapeId,to:target)
            }
        }
        number.removeAll()
        text.removeAll()
        visibility.removeAll()
        motions.removeAll()
        echoes.removeAll()
        pending.removeAll()
        playback.onProgress={ [weak self] id,value in self?.set(id,"progress",value) }
        playback.onText={ [weak self] id,value in self?.text[id]=value }
        playback.start(document,values:widgetValues)
        fire("start", sourceID: "")
        fire("screenEnter",sourceID:"")
    }

    func stop() {
        advanced.reset();playback.stop();stateLayers=[:];paused=[:]
        motions.removeAll()
        echoes.removeAll()
        pending.removeAll()
        number.removeAll()
        text.removeAll()
        visibility.removeAll()
    }

    func fire(_ event: String, sourceID: String, fraction: Double? = nil) {
        guard eventDepth<32 else{return};eventDepth+=1;defer{eventDepth-=1}
        let group = project.nodes.first(where: {$0.id == sourceID})?.group ?? ""
        let matching = project.links.filter { rule in
            guard rule.enabled && (rule.event == event || event=="drag" && rule.event=="valueChanged") else { return false }
            if event == "start" || event=="screenEnter" { return true }
            if rule.sourceID == sourceID { return true }
            return !group.isEmpty &&
                project.nodes.first(where:{$0.id == rule.sourceID})?.group == group
        }
        for link in matching { execute(link, fraction: fraction) }
    }

    func runAdvanced(_ link:InteractionLink){execute(link,fraction:nil)}
    func setAdvanced(_ id:String,_ property:String,_ value:Double){set(id,property,value)}
    func stopAdvancedLink(_ id:String){motions.removeAll{$0.owner==id};echoes.removeAll{$0.owner==id};pending.removeAll{$0.link.id==id};advanced.stop(id)}
    private func execute(_ input: InteractionLink, fraction: Double?, scheduled:Bool=false) {
        var link=input
        guard let node = project.nodes.first(where: { $0.id == link.targetID }) else { return }
        if !scheduled && !advanced.permit(link){return}
        let target = node.id
        let now = CACurrentMediaTime()
        if link.pauseOnRepeat==true {
            if let stopped=paused.removeValue(forKey:link.id){
                let delta=now-stopped
                for i in motions.indices where motions[i].owner==link.id{motions[i].start+=delta}
                for i in echoes.indices where echoes[i].owner==link.id{echoes[i].started+=delta}
                for i in pending.indices where pending[i].link.id==link.id{pending[i].at+=delta}
                return
            }
            if motions.contains(where:{$0.owner==link.id}) || echoes.contains(where:{$0.owner==link.id}) || pending.contains(where:{$0.link.id==link.id}){paused[link.id]=now;return}
        }
        if let steps=link.steps,!steps.isEmpty {
            pending.removeAll{$0.link.id==link.id};motions.removeAll{$0.owner==link.id};echoes.removeAll{$0.owner==link.id}
            var previousStart=max(0,link.delay),previousEnd=previousStart+actionDuration(link)
            for item in steps where item.enabled {
                let start=(item.stepTiming=="with" ? previousStart:previousEnd)+max(0,item.delay)
                previousStart=start;previousEnd=start+actionDuration(item)
                var action=item;action.id=link.id;action.sourceID=link.sourceID;action.steps=nil;action.delay=0;action.pauseOnRepeat=false;action.alternate=false
                pending.append(Pending(link:action,at:now+start,fraction:fraction))
            }
        }
        link.steps=nil
        if link.delay > 0 && !["animate","echo"].contains(link.mode) {
            var delayed=link
            delayed.delay=0;delayed.pauseOnRepeat=false
            pending.append(Pending(link:delayed,at:now+link.delay,fraction:fraction))
            return
        }
        if advanced.handle(link,fraction:fraction){return}
        let returning=link.alternate==true && toggled.contains(link.id)
        if link.alternate==true {if returning{toggled.remove(link.id)}else{toggled.insert(link.id)}}
        if link.property=="morph",["animate","set"].contains(link.mode) {
            let targetShape=returning ? node.shapeId:(link.shapeID ?? node.shapeId)
            if let destination=Catalog.shared.shapes.first(where:{$0.id==targetShape}){
                let path=morphs[target].map{VectorPath.parse($0.svg(number[target]?["morph"] ?? 0))} ?? VectorPath.parse(Catalog.shared.shapes.first(where:{$0.id==node.shapeId})?.path ?? "")
                morphs[target]=LinkMorph(fromPath:path,toPath:VectorPath.parse(destination.path));number[target,default:[:]]["morph"]=0
            }
        }
        let colorProperty=["fill","stroke","fill2","shadowColor"].contains(link.property)
        if ["bind","set","toggle","text"].contains(link.mode) {motions.removeAll{$0.targetID==target && $0.property==link.property}}
        switch link.mode {
        case "navigate":onNavigate?(link.destination ?? "back")
        case "url":if let url=URL(string:link.destination ?? ""),["https","http"].contains(url.scheme ?? ""){UIApplication.shared.open(url)}
        case "component":onComponent?(target,link.control ?? "tap",link.value)
        case "playerControl":playback.control(target:target,group:node.group,action:link.control ?? "toggle")
        case "visibility":visibility[target]=link.control=="show" ? true:link.control=="hide" ? false:!(visibility[target] ?? node.visible)
        case "state":
            guard let state=project.studio?.states.first(where:{$0.id==link.stateID}) else{return}
            let ids=Set(state.nodes.map(\.id))
            transition(returning ? project.nodes.filter{ids.contains($0.id)}:state.nodes,rule:link,now:now)
        case "playback":
            let source=project.nodes.first{$0.id==link.sourceID}
            let ownSlider=source?.id==node.id || (!node.group.isEmpty && source?.group==node.group)
            if !ownSlider || link.event != "tap" {playback.toggle(link.id,forcePlay:link.event=="start")}
        case "toggle":
            visibility[target] = !(visibility[target] ?? node.visible)
        case "text":
            text[target] = returning ? (link.reverseText ?? node.text):link.text
        case "echo":
            if !(echoes.last(where:{$0.nodeID==target}).map{now-$0.started<0.08} ?? false) {
                echoes.append(EchoPulse(owner:link.id,nodeID: target, started: now + max(0,link.delay),
                                        duration: max(0.15,link.duration), size: max(0.1,link.value),easing:link.easing,repeats:link.repeats,repeatGap:max(0,link.advanced?.repeatGap ?? 0)))
                if echoes.count>24 {echoes.removeFirst(echoes.count-24)}
            }
        case "bind":
            let raw=min(1,max(0,fraction ?? 0))
            let t=link.easing.hasPrefix("mapped:") ? InteractionLink.eased(raw,link.easing):raw
            if colorProperty {set(target,link.property,Double(mixColor(Int64(baseValue(node,link.property)),link.color,t)))}
            else {set(target, link.property, link.from + (link.to-link.from)*t)}
        case "set":
            set(target, link.property, returning ? baseValue(node,link.property):colorProperty ? Double(link.color):link.property=="morph" ? 1:link.value)
        default:
            // Continue from the current rendered value, including a scrubbed slider.
            let existing=current(node,link.property)
            let from = link.property=="progress" && existing>=1 && !returning ? 0:existing
            let to = link.property=="morph" ? 1:returning ? baseValue(node,link.property) : colorProperty ? Double(link.color) : ["progress","morph"].contains(link.property) ? 1 : link.value
            motions.removeAll { $0.targetID == target && $0.property == link.property }
            motions.append(Motion(owner:link.id,sourceID: link.sourceID, targetID: target,
                                  property: link.property, start: now + max(0,link.delay),
                                  duration: max(0.01,link.duration*(link.property=="progress" ? abs(to-from):1)), from: from, initialFrom: from,
                                  to: to, easing: link.easing, repeats: link.repeats,
                                  repeatGap:max(0,link.advanced?.repeatGap ?? 0),totalDuration:link.property=="progress" ? max(0.01,link.duration):nil,colorFrom: Int64(from), colorTo: Int64(to)))

        }
    }

    private func transition(_ nodes:[Node],rule:InteractionLink,now:Double){
        let properties=["x","y","width","height","rotation","opacity","fillOpacity","fill","fill2","stroke","strokeWidth","fontSize","weight","corner","blur","shadowBlur","shadowDx","shadowDy","shadowColor"]
        for target in nodes {
            guard let source=project.nodes.first(where:{$0.id==target.id}) else{continue}
            stateLayers[target.id]=target;text[target.id]=target.text
            if target.visible{visibility[target.id]=true}
            for property in properties{
                let from=current(source,property),to=property=="opacity" && !target.visible ? 0:baseValue(target,property)
                motions.removeAll{$0.targetID==target.id && $0.property==property}
                motions.append(Motion(owner:rule.id,sourceID:rule.sourceID,targetID:target.id,property:property,start:now+max(0,rule.delay),duration:max(0.01,rule.duration),from:from,initialFrom:from,to:to,easing:rule.easing,repeats:false,colorFrom:Int64(from),colorTo:Int64(to)))
            }
            if !target.visible{var hide=rule;hide.id=rule.id;hide.pauseOnRepeat=false;hide.targetID=target.id;hide.mode="set";hide.property="visible";hide.value=0;hide.alternate=false;hide.delay=0;pending.append(Pending(link:hide,at:now+max(0,rule.delay)+max(0.01,rule.duration),fraction:nil))}
            if source.kind=="SHAPE" && target.kind=="SHAPE" && source.shapeId != target.shapeId,let morph=LinkMorph(from:source.shapeId,to:target.shapeId){
                morphs[target.id]=morph;number[target.id,default:[:]]["morph"]=0
                motions.removeAll{$0.targetID==target.id && $0.property=="morph"}
                motions.append(Motion(owner:rule.id,sourceID:rule.sourceID,targetID:target.id,property:"morph",start:now+max(0,rule.delay),duration:max(0.01,rule.duration),from:0,initialFrom:0,to:1,easing:rule.easing,repeats:false,colorFrom:0,colorTo:1))
            }
        }
    }
    private func actionDuration(_ link:InteractionLink)->Double{["animate","echo","state","playback","multiMorph","typewriter"].contains(link.mode) ? max(0.01,link.duration):0}
    func seek(group:String,value:Double){
        playback.seek(group:group,value:value)
        let value=min(1,max(0,value)),now=CACurrentMediaTime();widgetValues[group]=value
        let ids=Set(project.nodes.filter{$0.group==group}.map(\.id))
        for id in ids{number[id,default:[:]]["progress"]=value}
        for i in motions.indices where ids.contains(motions[i].targetID) && motions[i].property=="progress"{
            let total=motions[i].totalDuration ?? motions[i].duration
            motions[i].from=value;motions[i].start=now;motions[i].duration=max(0.01,total*abs(motions[i].to-value))
            if paused[motions[i].owner] != nil{paused[motions[i].owner]=now}
        }
    }
    func scrub(group:String,_ enabled:Bool){
        playback.scrub(group:group,enabled)
        if enabled{scrubbingGroups.insert(group)}else{
            scrubbingGroups.remove(group);seek(group:group,value:widgetValues[group] ?? 0)
            let owners=Set(motions.filter{motion in motion.property=="progress" && project.nodes.first{$0.id==motion.targetID}?.group==group}.map(\.owner))
            for owner in owners{if project.links.first(where:{$0.id==owner})?.resumeAfterSeek==false{paused[owner]=CACurrentMediaTime()}}
        }
    }
    private func mixColor(_ first:Int64,_ last:Int64,_ t:Double)->Int64 {
        let a=UInt32(truncatingIfNeeded:first),b=UInt32(truncatingIfNeeded:last)
        var result:UInt32=0
        for shift in [0,8,16,24] {let av=Double((a>>shift)&255),bv=Double((b>>shift)&255);result |= UInt32(max(0,min(255,(av+(bv-av)*t).rounded()))) << shift}
        return Int64(Int32(bitPattern:result))
    }
    private func baseValue(_ node: Node, _ property: String) -> Double {
        switch property {
        case "disabled":return node.extras?.disabled==true ? 1:0
        case "fillOpacity":return Double(node.fillOpacity)
        case "stroke":return Double(node.stroke)
        case "fill2":return Double(node.fill2)
        case "shadowColor":return Double(node.shadowColor)
        case "weight":return Double(node.weight)
        case "strokeWidth":return Double(node.strokeWidth)
        case "gradAngle":return Double(node.gradAngle)
        case "shadowBlur":return Double(node.shadowBlur)
        case "shadowDx":return Double(node.shadowDx)
        case "shadowDy":return Double(node.shadowDy)
        case "backgroundBlur":return Double(node.blur)
        case "opacity": return Double(node.opacity)
        case "x": return Double(node.x)
        case "y": return Double(node.y)
        case "width": return Double(node.w)
        case "height": return Double(node.h)
        case "rotation": return Double(node.rotation)
        case "scale","groupScale": return 1
        case "visible": return node.visible ? 1 : 0
        case "fontSize": return Double(node.fontSize)
        case "corner": return Double(node.corner)
        case "blur": return Double(node.softBlur)
        case "fill": return Double(node.fill)
        case "progress": return widgetValues[node.group] ?? 0
        default: return 0
        }
    }
    private func current(_ node: Node, _ property: String) -> Double {
        number[node.id]?[property] ?? baseValue(node,property)
    }
    private func set(_ id: String, _ property: String, _ value: Double) {
        guard value.isFinite else { return }
        if property == "visible" { visibility[id] = value >= 0.5; return }
        let previous=number[id]?[property]
        number[id, default: [:]][property] = value
        if property=="progress" && previous != value {valueEvents.append((id,min(1,max(0,value))))}
        if property == "progress",let node = project.nodes.first(where: {$0.id==id}),
           !node.group.isEmpty { onWidgetProgress?(node.group, min(1,max(0,value))) }
    }

    /// Advance active animations. Returns true while a frame must be redrawn.
    @discardableResult func tick(at now: Double = CACurrentMediaTime()) -> Bool {
        let hadMotion = active
        let advancedChanged=advanced.needsDisplay;advanced.needsDisplay=false
        advanced.tick(now)
        let clockChanged=playback.tick(now)
        let due=pending.filter{$0.at<=now && paused[$0.link.id]==nil}
        pending.removeAll{$0.at<=now && paused[$0.link.id]==nil}
        var finished: [String] = []
        var kept: [Motion] = []
        for var motion in motions {
            if paused[motion.owner] != nil{kept.append(motion);continue}
            if motion.property=="progress",let group=project.nodes.first(where:{$0.id==motion.targetID})?.group,scrubbingGroups.contains(group){kept.append(motion);continue}
            if now < motion.start { kept.append(motion); continue }
            let t = min(1, max(0,(now-motion.start)/motion.duration))
            let eased = InteractionLink.eased(t,motion.easing)
            if ["fill","stroke","fill2","shadowColor"].contains(motion.property) {
                let from = UInt32(truncatingIfNeeded:motion.colorFrom)
                let to = UInt32(truncatingIfNeeded:motion.colorTo)
                var rgba: UInt32 = 0
                for shift in [0,8,16,24] {
                    let a = Double((from >> shift) & 255), b = Double((to >> shift) & 255)
                    rgba |= UInt32(min(255,max(0,(a+(b-a)*eased).rounded()))) << shift
                }
                set(motion.targetID,motion.property,Double(Int32(bitPattern:rgba)))
            } else {
                set(motion.targetID,motion.property,motion.from+(motion.to-motion.from)*eased)
            }
            if t>=1 {
                if motion.repeats {
                    motion.start = now+motion.repeatGap
                    // Repeat the full forward animation, not a frozen final frame.
                    motion.from = motion.property=="progress" ? 0:motion.initialFrom
                    motion.duration=motion.totalDuration ?? motion.duration
                    kept.append(motion)
                } else {
                    finished.append(motion.targetID)
                }
            } else { kept.append(motion) }
        }
        motions=kept
        for entry in due {execute(entry.link,fraction:entry.fraction,scheduled:true)}
        var budget=64
        while !valueEvents.isEmpty && budget>0 {let event=valueEvents.removeFirst();budget-=1;fire("valueChanged",sourceID:event.0,fraction:event.1)}
        valueEvents=[]
        echoes.removeAll { paused[$0.owner]==nil && !$0.repeats && now > $0.started+$0.duration }
        // Completion can start new animations, but don't recursively call completion.
        for id in Set(finished) { fire("finished",sourceID:id) }
        return advancedChanged || advanced.needsDisplay || clockChanged || hadMotion || !motions.isEmpty
    }

    static func pressColor(_ value:Int64,_ strength:Double)->Int64 {
        guard strength>0 else{return value}
        let v=UInt32(truncatingIfNeeded:value),alpha=v & 0xff000000
        let red=Double((v>>16)&255),green=Double((v>>8)&255),blue=Double(v&255)
        let target=(red*0.2126+green*0.7152+blue*0.0722)>128 ? 0.0:255.0
        func channel(_ n:Double)->UInt32{UInt32(min(255,max(0,(n+(target-n)*strength).rounded())))}
        return Int64(Int32(bitPattern:alpha | channel(red)<<16 | channel(green)<<8 | channel(blue)))
    }
    func displayed(_ base: Project, at now: Double = CACurrentMediaTime()) -> Project {
        var output=base
        for i in output.nodes.indices {
            var node=output.nodes[i]
            if let state=stateLayers[node.id]{node.kind=state.kind;node.asset=state.asset;node.font=state.font;node.textAlign=state.textAlign;node.extras=state.extras;node.path=state.path;node.shapeId=state.shapeId;node.gradKind=state.gradKind}
            let original=node
            if let v=number[node.id] {
                if let x=v["x"] { node.x=CGFloat(x) }
                if let y=v["y"] { node.y=CGFloat(y) }
                if let w=v["width"] { node.w=max(0,CGFloat(w)) }
                if let h=v["height"] { node.h=max(0,CGFloat(h)) }
                if let r=v["rotation"] { node.rotation=CGFloat(r) }
                if let disabled=v["disabled"]{var x=node.extras ?? LayerExtras();x.disabled=disabled>=0.5;node.extras=x}
                if let alpha=v["fillOpacity"]{node.fillOpacity=CGFloat(alpha)}
                if let o=v["opacity"] { node.opacity=min(1,max(0,CGFloat(o))) }
                if let z=v["scale"] {
                    let k=max(0.001,min(100,CGFloat(z)))
                    node.w *= k;node.h *= k
                    node.x=original.center.x-node.w/2
                    node.y=original.center.y-node.h/2
                }
                if let p=v["progress"],node.group.isEmpty {
                    node.w *= min(1,max(0,CGFloat(p)))
                }
                if let b=v["blur"] { node.softBlur=max(0,CGFloat(b)) }
                if let c=v["corner"] { node.corner=max(0,CGFloat(c)) }
                if let size=v["fontSize"] { node.fontSize=max(1,CGFloat(size)) }
                if let fill=v["fill"] { node.fill=Int64(fill) }
                if let value=v["stroke"]{node.stroke=Int64(value)}
                if let value=v["fill2"]{node.fill2=Int64(value)}
                if let value=v["shadowColor"]{node.shadowColor=Int64(value)}
                if let value=v["weight"]{node.weight=Int64(min(1000,max(100,value)))}
                if let value=v["strokeWidth"]{node.strokeWidth=max(0,CGFloat(value))}
                if let value=v["gradAngle"]{node.gradAngle=CGFloat(value)}
                if let value=v["shadowBlur"]{node.shadowBlur=max(0,CGFloat(value))}
                if let value=v["shadowDx"]{node.shadowDx=CGFloat(value)}
                if let value=v["shadowDy"]{node.shadowDy=CGFloat(value)}
                if let value=v["backgroundBlur"]{node.blur=max(0,CGFloat(value))}
                if let value=v["morph"],let morph=morphs[node.id]{node.kind="PATH";node.path=morph.svg(value);node.shapeId=""}
            }
            if let value=text[node.id],node.kind=="TEXT" { node.text=value }
            if let value=visibility[node.id] { node.visible=value }
            output.nodes[i]=node
        }
        if let renderer=layoutRenderer,!(output.studio?.layouts ?? []).isEmpty || output.nodes.contains(where:{$0.extras?.hugWidth==true}) {
            if var studio=output.studio,var frames=studio.layouts {
                for i in frames.indices where frames[i].children.contains(where:{id in number[id]?.keys.contains(where:{["x","y","width","height","scale"].contains($0)}) ?? false}){frames[i].enabled=false}
                studio.layouts=frames;output.studio=studio
            }
            for i in output.nodes.indices {
                if number[output.nodes[i].id]?["width"] != nil{var x=output.nodes[i].extras ?? LayerExtras();x.hugWidth=false;output.nodes[i].extras=x}
                if number[output.nodes[i].id]?["height"] != nil{var x=output.nodes[i].extras ?? LayerExtras();x.hugHeight=false;output.nodes[i].extras=x}
            }
            DesignLayoutEngine.resolve(&output,renderer:renderer,applyStyles:false)
        }
        // Scale every part around one shared center; tint remains relative to the current theme.
        var transformedGroups=Set<String>()
        for (id,values) in number {
            guard values["groupScale"] != nil || values["groupTint"] != nil,let anchor=base.nodes.first(where:{$0.id==id}) else{continue}
            let key=anchor.group.isEmpty ? anchor.id:anchor.group
            guard transformedGroups.insert(key).inserted else{continue}
            let members=base.nodes.filter{anchor.group.isEmpty ? $0.id==id:$0.group==anchor.group}
            let box=members.reduce(CGRect.null){$0.union($1.rect)},center=CGPoint(x:box.midX,y:box.midY)
            let scale=CGFloat(max(0.01,values["groupScale"] ?? 1)),tint=min(1,max(0,values["groupTint"] ?? 0))
            for i in output.nodes.indices where anchor.group.isEmpty ? output.nodes[i].id==id:output.nodes[i].group==anchor.group {
                var n=output.nodes[i]
                let c=n.center
                n.w*=scale;n.h*=scale;n.x=center.x+(c.x-center.x)*scale-n.w/2;n.y=center.y+(c.y-center.y)*scale-n.h/2
                if n.kind=="TEXT"{n.fontSize*=scale;var x=n.extras ?? LayerExtras();x.tracking*=scale;x.lineSpacing*=scale;n.extras=x}
                n.strokeWidth*=scale
                n.fill=Self.pressColor(n.fill,tint);n.fill2=Self.pressColor(n.fill2,tint);n.stroke=Self.pressColor(n.stroke,tint)
                output.nodes[i]=n
            }
        }
        for original in output.nodes {
            guard let strength=number[original.id]?["echo"],strength>0 else{continue}
            for index in 1...3 {
                var copy=original;let k=1+CGFloat(min(4,strength))*CGFloat(index)*0.12
                copy.id="bound-echo-\(original.id)-\(index)";copy.w*=k;copy.h*=k
                copy.x=original.center.x-copy.w/2;copy.y=original.center.y-copy.h/2
                copy.fill=0;copy.stroke=original.fill;copy.strokeWidth=max(1,original.strokeWidth)
                copy.opacity*=CGFloat(min(1,strength))*0.25/CGFloat(index);copy.shadowBlur=0
                if let at=output.nodes.firstIndex(where:{$0.id==original.id}){output.nodes.insert(copy,at:at)}
            }
        }
        for pulse in echoes {
            let now=paused[pulse.owner] ?? now
            guard now>=pulse.started,
                  let original=output.nodes.first(where:{$0.id==pulse.nodeID}) else {continue}
            let elapsed=max(0,now-pulse.started)
            let phase=pulse.repeats ? elapsed.truncatingRemainder(dividingBy:pulse.duration+pulse.repeatGap)/pulse.duration:elapsed/pulse.duration
            if phase>1{continue}
            let progress=min(1,max(0,phase))
            let curved=InteractionLink.eased(progress,pulse.easing)
            for index in 1...3 {
                let stagger=max(0, progress-Double(index-1)*0.13)
                guard stagger>0 else { continue }
                let size=1+CGFloat(max(0,curved-Double(index-1)*0.13)*pulse.size*0.3)
                var copy=original
                copy.id = "echo-\(original.id)-\(index)"
                copy.name = "Эхо"
                copy.w *= size;copy.h *= size
                copy.x=original.center.x-copy.w/2;copy.y=original.center.y-copy.h/2
                let fadeIn=min(1,stagger*6)
                copy.opacity *= CGFloat(max(0,fadeIn*(1-stagger)*0.25))
                copy.stroke=original.fill
                copy.fill=0
                copy.strokeWidth=max(1,original.strokeWidth)
                copy.shadowBlur=0
                copy.softBlur=0
                // Insert behind the source so it never blocks the foreground.
                if let at=output.nodes.firstIndex(where:{$0.id==original.id}) {
                    output.nodes.insert(copy,at:at)
                }
            }
        }
        return advanced.apply(output,at:now)
    }
}
