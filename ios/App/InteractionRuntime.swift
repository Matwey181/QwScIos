import UIKit
import QuartzCore

/// Shared, deterministic link executor used by editor Play mode.
/// Nothing here edits the original design: effects are projected over a copy.
@MainActor final class InteractionRuntime {
    struct Motion {
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
        var colorFrom: Int64
        var colorTo: Int64
    }
    struct EchoPulse {
        var nodeID: String
        var started: Double
        var duration: Double
        var size: Double
        var easing:String = "easeOut"
        var repeats:Bool = false
    }

    private(set) var project = Project()
    private(set) var number: [String: [String: Double]] = [:]
    private(set) var text: [String: String] = [:]
    private(set) var visibility: [String: Bool] = [:]
    private var motions: [Motion] = []
    private var toggled:Set<String>=[]
    private var morphs:[String:LinkMorph]=[:]
    private var echoes: [EchoPulse] = []
    private struct Pending {
        var link:InteractionLink
        var at:Double
        var fraction:Double?
    }
    private var pending:[Pending]=[]
    private var valueEvents:[(String,Double)]=[]
    let playback=PlaybackRuntime()
    var onWidgetProgress: ((String, Double) -> Void)?

    var active: Bool { !motions.isEmpty || !echoes.isEmpty || !pending.isEmpty || playback.active }

    func start(_ document: Project,widgetValues:[String:Double]=[:]) {
        project = document
        toggled=[];morphs=[:];valueEvents=[]
        for rule in document.links where rule.enabled && rule.property=="morph" {
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
    }

    func stop() {
        playback.stop()
        motions.removeAll()
        echoes.removeAll()
        pending.removeAll()
        number.removeAll()
        text.removeAll()
        visibility.removeAll()
    }

    func fire(_ event: String, sourceID: String, fraction: Double? = nil) {
        let group = project.nodes.first(where: {$0.id == sourceID})?.group ?? ""
        let matching = project.links.filter { rule in
            guard rule.enabled && (rule.event == event || event=="drag" && rule.event=="valueChanged") else { return false }
            if event == "start" { return true }
            if rule.sourceID == sourceID { return true }
            return !group.isEmpty &&
                project.nodes.first(where:{$0.id == rule.sourceID})?.group == group
        }
        for link in matching { execute(link, fraction: fraction) }
    }

    private func execute(_ link: InteractionLink, fraction: Double?) {
        guard let node = project.nodes.first(where: { $0.id == link.targetID }) else { return }
        let target = node.id
        let now = CACurrentMediaTime()
        if link.delay > 0 && !["animate","echo"].contains(link.mode) {
            var delayed=link
            delayed.delay=0
            pending.append(Pending(link:delayed,at:now+link.delay,fraction:fraction))
            return
        }
        let returning=link.alternate==true && toggled.contains(link.id)
        if link.alternate==true {if returning{toggled.remove(link.id)}else{toggled.insert(link.id)}}
        let colorProperty=["fill","stroke","fill2","shadowColor"].contains(link.property)
        if ["bind","set","toggle","text"].contains(link.mode) {motions.removeAll{$0.targetID==target && $0.property==link.property}}
        switch link.mode {
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
                echoes.append(EchoPulse(nodeID: target, started: now + max(0,link.delay),
                                        duration: max(0.15,link.duration), size: max(0.1,link.value),easing:link.easing,repeats:link.repeats))
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
            // Progress always fills from zero to one; other properties animate
            // from their currently rendered value.
            let from = link.property == "progress" && link.alternate != true ? 0 : current(node, link.property)
            let to = returning ? baseValue(node,link.property) : colorProperty ? Double(link.color) : ["progress","morph"].contains(link.property) ? 1 : link.value
            motions.removeAll { $0.targetID == target && $0.property == link.property }
            motions.append(Motion(sourceID: link.sourceID, targetID: target,
                                  property: link.property, start: now + max(0,link.delay),
                                  duration: max(0.01,link.duration), from: from, initialFrom: from,
                                  to: to, easing: link.easing, repeats: link.repeats,
                                  colorFrom: Int64(from), colorTo: Int64(to)))
            if link.property == "progress" && link.alternate != true { set(target, "progress", 0) }
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
        case "scale": return 1
        case "visible": return node.visible ? 1 : 0
        case "fontSize": return Double(node.fontSize)
        case "corner": return Double(node.corner)
        case "blur": return Double(node.softBlur)
        case "fill": return Double(node.fill)
        case "progress": return 0
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
        let clockChanged=playback.tick(now)
        let due=pending.filter{$0.at<=now}
        pending.removeAll{$0.at<=now}
        for entry in due {execute(entry.link,fraction:entry.fraction)}
        var finished: [String] = []
        var kept: [Motion] = []
        for var motion in motions {
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
                set(motion.targetID,"fill",Double(Int32(bitPattern:rgba)))
            } else {
                set(motion.targetID,motion.property,motion.from+(motion.to-motion.from)*eased)
            }
            if t>=1 {
                if motion.repeats {
                    motion.start = now
                    // Repeat the full forward animation, not a frozen final frame.
                    motion.from = motion.initialFrom
                    kept.append(motion)
                } else {
                    finished.append(motion.targetID)
                }
            } else { kept.append(motion) }
        }
        motions=kept
        var budget=64
        while !valueEvents.isEmpty && budget>0 {let event=valueEvents.removeFirst();budget-=1;fire("valueChanged",sourceID:event.0,fraction:event.1)}
        valueEvents=[]
        echoes.removeAll { !$0.repeats && now > $0.started+$0.duration }
        // Completion can start new animations, but don't recursively call completion.
        for id in Set(finished) { fire("finished",sourceID:id) }
        return clockChanged || hadMotion || !motions.isEmpty
    }

    func displayed(_ base: Project, at now: Double = CACurrentMediaTime()) -> Project {
        var output=base
        for i in output.nodes.indices {
            var node=output.nodes[i]
            let original=node
            if let v=number[node.id] {
                if let x=v["x"] { node.x=CGFloat(x) }
                if let y=v["y"] { node.y=CGFloat(y) }
                if let w=v["width"] { node.w=max(0,CGFloat(w)) }
                if let h=v["height"] { node.h=max(0,CGFloat(h)) }
                if let r=v["rotation"] { node.rotation=CGFloat(r) }
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
            guard now>=pulse.started,
                  let original=output.nodes.first(where:{$0.id==pulse.nodeID}) else {continue}
            let elapsed=max(0,now-pulse.started)
            let phase=pulse.repeats ? elapsed.truncatingRemainder(dividingBy:pulse.duration)/pulse.duration:elapsed/pulse.duration
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
        return output
    }
}
