import Foundation

/// Source copied verbatim into exported standalone SwiftUI files.
/// A generated view does not need Qwel or any other framework at runtime.
enum ExportedInteractionSource {
    static let code = #"""
private struct QwelRule {
    var source: String
    var event: String
    var target: String
    var mode: String
    var property: String
    var value: Double
    var from: Double
    var to: Double
    var duration: Double
    var delay: Double
    var easing: String
    var text: String
    var color: Int64
    var repeats: Bool
    var enabled: Bool
    var id: String = ""
    var alternate: Bool = false
    var reverseText: String? = nil
    var sourceAliases: [String] = []
    var morphFrom: [Double] = []
    var morphTo: [Double] = []
}
private struct QwelMotion {
    var source: String
    var target: String
    var property: String
    var from: Double
    var to: Double
    var start: Double
    var duration: Double
    var ease: String
    var repeats: Bool
}
private struct QwelPending {
    var rule:QwelRule
    var at:Double
    var fraction:Double?
}
private struct QwelEcho: Identifiable {
    var id = UUID()
    var target: String
    var start: Double
    var duration: Double
    var strength: Double
}
@MainActor private final class QwelExportRuntime: NSObject, ObservableObject {
    @Published private var version: Int = 0
    private var rules: [QwelRule] = []
    private var toggled:Set<String>=[]
    private var base: [String:Double] = [:]
    private var current: [String:Double] = [:]
    private var textValues: [String:String] = [:]
    private var visibility: [String:Bool] = [:]
    private var motions: [QwelMotion] = []
    private var echoes: [QwelEcho] = []
    private var pending: [QwelPending] = []
    private var clock: CADisplayLink?
    private var running = false
    private var updating = false
    private var emittedThisFrame = 0
    private var draggingSources: Set<String> = []

    private func key(_ node:String,_ property:String)->String {
        node + "|" + property
    }
    func start(_ links:[QwelRule], initial:[String:Double]) {
        guard !running else {return}
        running = true
        rules=links
        toggled=[]
        base=initial
        current=[:]
        textValues=[:]
        visibility=[:]
        motions=[]
        echoes=[]
        pending=[]
        draggingSources=[]
        emit("start",source:"")
        let ticker=CADisplayLink(target:self,selector:#selector(frame))
        ticker.preferredFramesPerSecond=60
        ticker.add(to:.main,forMode:.common)
        clock=ticker
    }
    func stop() {
        clock?.invalidate()
        clock=nil
        running=false
        motions=[]
        echoes=[]
        draggingSources=[]
    }
    @objc private func frame() {
        let now=CACurrentMediaTime()
        let due=pending.filter{$0.at<=now}
        pending.removeAll{$0.at<=now}
        for item in due {apply(item.rule,fraction:item.fraction,now:now)}
        emittedThisFrame=0
        let progressEvents=motions.filter{$0.property=="progress"}.map{($0.target,value($0.target,"progress",base:0))}
        for event in progressEvents {emit("valueChanged",source:event.0,fraction:event.1)}
        let completed=motions.filter { !$0.repeats && now >= $0.start + $0.duration }
        for m in completed {
            current[key(m.target,m.property)]=m.to
        }
        motions.removeAll { !$0.repeats && now >= $0.start + $0.duration }
        for i in motions.indices where motions[i].repeats &&
                now >= motions[i].start + motions[i].duration {
            let m=motions[i]
            motions[i].start=now
            current[key(m.target,m.property)]=m.from
        }
        echoes.removeAll { now > $0.start + $0.duration }
        emittedThisFrame=0
        for id in Set(completed.map(\.target)) {
            emit("finished",source:id)
        }
        if !motions.isEmpty || !echoes.isEmpty || !completed.isEmpty || !due.isEmpty {
            version &+= 1
        }
    }
    func dragChanged(source:String,fraction:Double) {
        if draggingSources.insert(source).inserted {
            emit("dragStart",source:source,fraction:fraction)
        }
        emit("drag",source:source,fraction:fraction)
    }
    func dragEnded(source:String,fraction:Double) {
        emit("dragEnd",source:source,fraction:fraction)
        draggingSources.remove(source)
    }
    func toggle(target id:String) {
        visibility[id] = !(visibility[id] ?? ((base[key(id,"visible")] ?? 1) > 0.5))
        version &+= 1
    }
    func emit(_ event:String, source:String, fraction:Double?=nil) {
        guard emittedThisFrame < 64 else {return}
        emittedThisFrame += 1
        let now=CACurrentMediaTime()
        for rule in rules where rule.enabled && (rule.event == event || event=="drag" && rule.event=="valueChanged") &&
                (rule.source == source || rule.sourceAliases.contains(source) || event == "start") {
            if rule.delay>0 && !["animate","echo"].contains(rule.mode) {
                var waiting=rule
                waiting.delay=0
                pending.append(QwelPending(rule:waiting,at:now+rule.delay,fraction:fraction))
            } else {
                apply(rule,fraction:fraction,now:now)
            }
        }
        version &+= 1
    }
    private func apply(_ rule:QwelRule,fraction:Double?,now:Double) {
            let id=rule.target, property=rule.property
            let idKey=key(id,property)
            let returning=rule.alternate && toggled.contains(rule.id)
            if rule.alternate {if returning{toggled.remove(rule.id)}else{toggled.insert(rule.id)}}
            let isColor=["fill","stroke","fill2","shadowColor"].contains(property)
            switch rule.mode {
            case "toggle":
                visibility[id] = !(visibility[id] ?? ((base[key(id,"visible")] ?? 1) > 0.5))
            case "text":
                textValues[id]=returning ? rule.reverseText:rule.text
            case "echo":
                if !(echoes.last(where:{$0.target==id}).map{now-$0.start<0.08} ?? false) {
                    echoes.append(QwelEcho(target:id,start:now+max(0,rule.delay),
                                           duration:max(0.1,rule.duration),
                                           strength:max(0.01,rule.value)))
                    if echoes.count>24 {echoes.removeFirst(echoes.count-24)}
                }
            case "bind":
                let t=ease(min(1,max(0,fraction ?? 0)),rule.easing)
                motions.removeAll {$0.target==id && $0.property==property}
                current[idKey]=isColor ? Double(mixColor(Int64(base[idKey] ?? 0),rule.color,t)):rule.from + (rule.to-rule.from)*t
            case "set":
                motions.removeAll {$0.target==id && $0.property==property}
                current[idKey]=returning ? (base[idKey] ?? 0):isColor ? Double(rule.color):property=="morph" ? 1:rule.value
            default:
                let origin=property=="progress" && !rule.alternate ? 0 : value(id,property,base:base[idKey] ?? 0)
                let dest=returning ? (base[idKey] ?? 0):["progress","morph"].contains(property) ? 1 :
                         isColor ? Double(rule.color) : rule.value
                motions.removeAll {$0.target==id && $0.property==property}
                motions.append(QwelMotion(source:rule.source,target:id,property:property,
                                          from:origin,to:dest,start:now+max(0,rule.delay),
                                          duration:max(0.01,rule.duration),
                                          ease:rule.easing,repeats:rule.repeats))
                if property == "progress" && !rule.alternate {current[idKey]=0}
            }
    }
    func value(_ id:String,_ property:String,base fallback:Double)->Double {
        // Access to this property establishes an observable dependency for SwiftUI.
        _ = version
        let idKey=key(id,property)
        if let m=motions.last(where:{$0.target==id && $0.property==property}) {
            let t=min(1,max(0,(CACurrentMediaTime()-m.start)/m.duration))
            let eased=ease(t,m.ease)
            if ["fill","stroke","fill2","shadowColor"].contains(property) {return Double(mixColor(Int64(m.from),Int64(m.to),eased))}
            return m.from + (m.to-m.from)*eased
        }
        return current[idKey] ?? fallback
    }
    func label(_ id:String,base fallback:String)->String {
        _ = version
        return textValues[id] ?? fallback
    }
    func visible(_ id:String,base fallback:Bool)->Bool {
        _ = version
        return visibility[id] ?? fallback
    }
    func fill(_ id:String,base fallback:Int64,property:String="fill")->Color {
        let raw=Int64(value(id,property,base:Double(fallback)))
        let value=UInt32(truncatingIfNeeded:raw)
        return Color(.sRGB,red:Double((value>>16)&255)/255,
                     green:Double((value>>8)&255)/255,
                     blue:Double(value&255)/255,
                     opacity:Double(value>>24)/255)
    }
    func echo(_ id:String)->Double? {
        _ = version
        let now=CACurrentMediaTime()
        guard let pulse=echoes.last(where:{$0.target==id && now >= $0.start}) else {let strength=value(id,"echo",base:0);return strength>0 ? min(1,strength):nil}
        return min(1,max(0,(now-pulse.start)/pulse.duration))
    }
    func gradientPoint(_ id:String,base:Double,end:Bool)->UnitPoint {
        let angle=value(id,"gradAngle",base:base) * .pi/180,k=end ? 0.5 : -0.5
        return UnitPoint(x:0.5+cos(angle)*k,y:0.5+sin(angle)*k)
    }
    func morphPath(_ id:String,base:Path,width:CGFloat,height:CGFloat)->Path {
        guard let rule=rules.last(where:{$0.enabled && $0.target==id && $0.property=="morph"}),rule.morphFrom.count==rule.morphTo.count,rule.morphFrom.count>=8 else{return base}
        let t=value(id,"morph",base:0),a=rule.morphFrom,b=rule.morphTo
        func point(_ i:Int)->CGPoint {CGPoint(x:(a[i]+(b[i]-a[i])*t)*width,y:(a[i+1]+(b[i+1]-a[i+1])*t)*height)}
        var path=Path();path.move(to:point(0))
        for i in stride(from:0,to:a.count-7,by:8){path.addCurve(to:point(i+6),control1:point(i+2),control2:point(i+4))}
        path.closeSubpath();return path
    }
    private func ease(_ raw:Double,_ kind:String)->Double {
        let t=min(1,max(0,raw))
        if kind.hasPrefix("bezier:"),case let points=kind.dropFirst(7).split(separator:",").compactMap({Double($0)}),points.count==4,points.allSatisfy(\.isFinite) {
            func cubic(_ p:Double,_ a:Double,_ b:Double)->Double {3*(1-p)*(1-p)*p*a+3*(1-p)*p*p*b+p*p*p}
            var low=0.0,high=1.0
            for _ in 0..<24 {let mid=(low+high)/2;if cubic(mid,min(1,max(0,points[0])),min(1,max(0,points[2])))<t {low=mid}else{high=mid}}
            return t==0 || t==1 ? t:cubic((low+high)/2,points[1],points[3])
        }
        switch kind {
        case "easeIn":return t*t*t
        case "easeOut":return 1-pow(1-t,3)
        case "easeInOut":return t<0.5 ? 4*t*t*t : 1-pow(-2*t+2,3)/2
        case "spring":return t == 0 || t == 1 ? t : 1-pow(2,-10*t)*cos((t*10-0.75)*2 * .pi / 3)
        default:return t
        }
    }
    private func mixColor(_ first:Int64,_ last:Int64,_ t:Double)->Int64 {
        let a=UInt32(truncatingIfNeeded:first),b=UInt32(truncatingIfNeeded:last)
        var result:UInt32=0
        for shift in [0,8,16,24] {
            let av=Double((a>>shift)&255),bv=Double((b>>shift)&255)
            result |= UInt32(max(0,min(255,(av+(bv-av)*t).rounded()))) << shift
        }
        return Int64(Int32(bitPattern:result))
    }
}
"""#
}
