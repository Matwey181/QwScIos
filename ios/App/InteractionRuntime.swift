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
    }

    private(set) var project = Project()
    private(set) var number: [String: [String: Double]] = [:]
    private(set) var text: [String: String] = [:]
    private(set) var visibility: [String: Bool] = [:]
    private var motions: [Motion] = []
    private var echoes: [EchoPulse] = []
    var onWidgetProgress: ((String, Double) -> Void)?

    var active: Bool { !motions.isEmpty || !echoes.isEmpty }

    func start(_ document: Project) {
        project = document
        number.removeAll()
        text.removeAll()
        visibility.removeAll()
        motions.removeAll()
        echoes.removeAll()
        fire("start", sourceID: "")
    }

    func stop() {
        motions.removeAll()
        echoes.removeAll()
        number.removeAll()
        text.removeAll()
        visibility.removeAll()
    }

    func fire(_ event: String, sourceID: String, fraction: Double? = nil) {
        let group = project.nodes.first(where: {$0.id == sourceID})?.group ?? ""
        let matching = project.links.filter { rule in
            guard rule.enabled && rule.event == event else { return false }
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
        switch link.mode {
        case "toggle":
            visibility[target] = !(visibility[target] ?? node.visible)
        case "text":
            text[target] = link.text
        case "echo":
            echoes.append(EchoPulse(nodeID: target, started: now + max(0,link.delay),
                                    duration: max(0.15,link.duration), size: max(0.1,link.value)))
        case "bind":
            let t = min(1, max(0, fraction ?? 0))
            set(target, link.property, link.from + (link.to-link.from)*t)
        case "set":
            set(target, link.property, link.property == "fill" ? Double(link.color) : link.value)
        default:
            // Progress always fills from zero to one; other properties animate
            // from their currently rendered value.
            let from = link.property == "progress" ? 0 : current(node, link.property)
            let to = link.property == "fill" ? Double(link.color) :
                     link.property == "progress" ? 1 : link.value
            motions.removeAll { $0.targetID == target && $0.property == link.property }
            motions.append(Motion(sourceID: link.sourceID, targetID: target,
                                  property: link.property, start: now + max(0,link.delay),
                                  duration: max(0.01,link.duration), from: from, initialFrom: from,
                                  to: to, easing: link.easing, repeats: link.repeats,
                                  colorFrom: Int64(from), colorTo: Int64(to)))
            if link.property == "progress" { set(target, "progress", 0) }
        }
    }

    private func baseValue(_ node: Node, _ property: String) -> Double {
        switch property {
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
        number[id, default: [:]][property] = value
        if property == "progress",let node = project.nodes.first(where: {$0.id==id}),
           !node.group.isEmpty { onWidgetProgress?(node.group, min(1,max(0,value))) }
    }

    /// Advance active animations. Returns true while a frame must be redrawn.
    @discardableResult func tick(at now: Double = CACurrentMediaTime()) -> Bool {
        let hadMotion = !motions.isEmpty || !echoes.isEmpty
        var finished: [String] = []
        var kept: [Motion] = []
        for var motion in motions {
            if now < motion.start { kept.append(motion); continue }
            let t = min(1, max(0,(now-motion.start)/motion.duration))
            let eased = InteractionLink.eased(t,motion.easing)
            if motion.property == "fill" {
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
        echoes.removeAll { now > $0.started+$0.duration }
        // Completion can start new animations, but don't recursively call completion.
        for id in Set(finished) { fire("finished",sourceID:id) }
        return hadMotion || !motions.isEmpty
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
            }
            if let value=text[node.id],node.kind=="TEXT" { node.text=value }
            if let value=visibility[node.id] { node.visible=value }
            output.nodes[i]=node
        }
        for pulse in echoes {
            guard now>=pulse.started,
                  let original=output.nodes.first(where:{$0.id==pulse.nodeID}) else {continue}
            let progress=min(1,max(0,(now-pulse.started)/pulse.duration))
            for index in 1...3 {
                let stagger=max(0, progress-Double(index-1)*0.13)
                guard stagger>0 else { continue }
                let size=1+CGFloat(stagger*pulse.size*0.3)
                var copy=original
                copy.id = "echo-\(original.id)-\(index)"
                copy.name = "Эхо"
                copy.w *= size;copy.h *= size
                copy.x=original.center.x-copy.w/2;copy.y=original.center.y-copy.h/2
                copy.opacity *= CGFloat(max(0, (1-stagger)*0.25))
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
