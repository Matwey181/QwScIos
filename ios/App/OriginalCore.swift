import Foundation
import JavaScriptCore
import UIKit

@MainActor final class OriginalCore {
    static let shared=OriginalCore()
    private let context:JSContext
    private let function:JSValue
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
        func restore(_ node:Node)->Node {var n=node;n.textAlign=textAlignments[n.id] ?? n.textAlign;return n}
        decoded.nodes=decoded.nodes.map(restore)
        for i in decoded.pages.indices {decoded.pages[i].nodes=decoded.pages[i].nodes.map(restore)}
        return decoded
    }
    func compose(_ project:Project) throws -> String { try request(["op":"compose"],project:project)["code"] as? String ?? "" }
}

@MainActor final class OriginalPlayRuntime:NSObject {
    weak var editor:Editor?
    var target:[String:Double]=[:]
    let links = InteractionRuntime()
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
            links.start(editor.project)
            refresh()
            let link=CADisplayLink(target:self,selector:#selector(frame));link.preferredFramesPerSecond=30;link.add(to:.main,forMode:.common);self.link=link
        } catch { editor.error=error.localizedDescription }
    }
    func stop() {
        link?.invalidate();link=nil
        activeSourceID=nil
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
            if kinds[group]=="press",(shown[group] ?? 0)>0.9,value>0.5 { target[group]=0 }
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
    func hit(_ p:CGPoint)->[String:Any] { (try? OriginalCore.shared.request(["op":"hit","x":p.x,"y":p.y,"pad":8])) ?? [:] }
    func tap(_ p:CGPoint) {
        guard let editor else { return }
        if let n=editor.project.nodes.reversed().first(where:{ n in (n.visible || visibility[n.id]==true) && visibility[n.id] != false && !n.mask && n.contains(p) && (!n.action.isEmpty || linked(n,events:["tap"]))}) {
            links.fire("tap",sourceID:n.id)
            refresh()
            if n.action.hasPrefix("goto:"),let i=editor.project.pages.firstIndex(where:{$0.id==String(n.action.dropFirst(5))}) { let previous=editor.project.active;stop();back.append(previous);editor.page(i);start();return }
            if n.action=="back",let page=back.popLast() { stop();editor.page(page);start();return }
            if n.action.hasPrefix("toggle:") { let id=String(n.action.dropFirst(7));let old=visibility[id] ?? editor.project.nodes.first(where:{$0.id==id})?.visible ?? false;visibility[id] = !old;refresh();return }
            if n.action.hasPrefix("url:"),let url=URL(string:String(n.action.dropFirst(4))),["http","https"].contains(url.scheme) { UIApplication.shared.open(url);return }
        }
        let widget=hit(p)
        guard let group=widget["group"] as? String else { return }
        if ["slider","progress"].contains(widget["kind"] as? String ?? "") { target[group]=(widget["value"] as? NSNumber)?.doubleValue ?? 0;shown[group]=target[group];refresh();return }
        do { let result=try OriginalCore.shared.request(["op":"tap","group":group,"x":p.x,"y":p.y,"shown":target]);target=result.compactMapValues{($0 as? NSNumber)?.doubleValue} } catch { editor.error=error.localizedDescription }
    }
    private func dragFraction(_ p:CGPoint, sourceID:String)->Double? {
        guard let editor,let source=editor.project.nodes.first(where:{$0.id==sourceID}) else {return nil}
        let group: [Node] = source.group.isEmpty ? [source] :
            editor.project.nodes.filter{$0.group == source.group}
        let x0=group.map(\.x).min() ?? source.x
        let x1=group.map{$0.x+$0.w}.max() ?? source.x+source.w
        return Double(min(1,max(0,(p.x-x0)/max(1,x1-x0))))
    }
    func begin(_ p:CGPoint) {
        activeHit=hit(p);initial=p;lastStep=0
        activeSourceID=editor?.project.nodes.reversed().first(where: { n in
            n.visible && !n.mask && n.contains(p) && linked(n,events:["dragStart","drag","dragEnd"])
        })?.id
        if let id=activeSourceID {links.fire("dragStart",sourceID:id,fraction:dragFraction(p,sourceID:id));refresh()}
        if ["slider","progress"].contains(activeHit?["kind"] as? String ?? "") { tap(p) }
    }
    func drag(_ p:CGPoint) {
        if let id=activeSourceID {
            links.fire("drag",sourceID:id,fraction:dragFraction(p,sourceID:id))
            refresh()
        }
        guard let widget=activeHit,let group=widget["group"] as? String,let kind=widget["kind"] as? String else { return }
        if ["slider","progress"].contains(kind) {
            // Reuse the original component captured at touch-down even when the
            // finger goes outside its bounds.
            var clamped=p
            let left=CGFloat((widget["x"] as? NSNumber)?.doubleValue ?? 0),width=CGFloat((widget["w"] as? NSNumber)?.doubleValue ?? 1)
            let top=CGFloat((widget["y"] as? NSNumber)?.doubleValue ?? 0),height=CGFloat((widget["h"] as? NSNumber)?.doubleValue ?? 1)
            clamped.x=min(left+width,max(left,p.x));clamped.y=min(top+height,max(top,p.y))
            let new=hit(clamped)
            if new["group"] as? String==group { target[group]=(new["value"] as? NSNumber)?.doubleValue ?? 0;shown[group]=target[group];refresh() }
        } else if kind=="pick" {
            let step=Int((initial.x-p.x)/40)
            if step != lastStep { let d=step>lastStep ? 1:-1;lastStep=step;if let result=try? OriginalCore.shared.request(["op":"swipe","group":group,"direction":d,"shown":target]) { target=result.compactMapValues{($0 as? NSNumber)?.doubleValue} } }
        }
    }
    func end(_ p:CGPoint) {
        if let id=activeSourceID {
            links.fire("dragEnd",sourceID:id,fraction:dragFraction(p,sourceID:id))
            refresh()
        }
        activeSourceID=nil
        activeHit=nil
    }
}
