import UIKit
import AVFoundation

@MainActor final class AdvancedLinkEngine {
    weak var runtime:InteractionRuntime?
    var root=FileManager.default.temporaryDirectory
    private var once=Set<String>(),hits:[String:Int]=[:],stages:[String:String]=[:],selected=Set<String>()
    private var held:String?,heldAt=0.0,lastRepeat:[String:Double]=[:],lastPoint=CGPoint.zero
    private var typing:[String:(String,Double,Double,String)]=[:],players:[String:AVAudioPlayer]=[:]
    private var transformStarts:[String:Double]=[:]
    private var replacements:[String:Node]=[:],dragRule:InteractionLink?,dragOrigin=CGPoint.zero
    private var inside:[String:Bool]=[:],followers:[String:InteractionLink]=[:]
    private struct Morph {var rule:InteractionLink;var sources:[Node];var targets:[Node];var paths:[LinkMorph];var start:Double}
    private var morphs:[String:Morph]=[:]
    private var checkpointUndos:[String:[String:()->Void]]=[:]
    private var checkpointOwners:[String:Set<String>]=[:]
    private var activePoints:[String:Set<String>]=[:]
    var needsDisplay=false
    func resumeAfterFreeze(_ delta:Double){
        heldAt+=delta;lastRepeat=lastRepeat.mapValues{$0+delta}
        typing=typing.mapValues{($0.0,$0.1+delta,$0.2,$0.3)}
        for id in Array(morphs.keys){morphs[id]?.start+=delta}
    }
    var active:Bool{held != nil || !typing.isEmpty || morphs.values.contains{CACurrentMediaTime() < $0.start+max(0.01,$0.rule.duration)} || !followers.isEmpty}
    func reset(){checkpointUndos=[:];checkpointOwners=[:];activePoints=[:];transformStarts=[:];once=[];hits=[:];stages=[:];selected=[];held=nil;typing=[:];players.values.forEach{$0.stop()};players=[:];replacements=[:];morphs=[:];followers=[:];inside=[:]}
    func stop(_ id:String){if let owners=checkpointOwners.removeValue(forKey:id){for owner in owners{runtime?.stopAdvancedLink(owner)}};checkpointUndos.removeValue(forKey:id);activePoints.removeValue(forKey:id);typing.removeValue(forKey:id);players[id]?.stop();players.removeValue(forKey:id);morphs.removeValue(forKey:id);followers.removeValue(forKey:id)}
    func permit(_ rule:InteractionLink)->Bool{if rule.advanced?.once==true{return once.insert(rule.id).inserted};return true}
    func tap(_ source:String){guard let r=runtime else{return};let group=r.project.nodes.first{$0.id==source}?.group ?? "";let key=group.isEmpty ? source:group;hits[key,default:0]+=1;let count=hits[key] ?? 1
        for link in r.project.links where link.enabled && ["nthTap","stepTap"].contains(link.event) && matches(link.sourceID,source){let x=link.advanced ?? AdvancedLinkOptions();let n=max(1,x.tapCount);if link.event=="nthTap" ? count%n==0:(count-1)%n+1==max(1,x.tapStep){r.runAdvanced(link)}}
    }
    func press(_ source:String?,at point:CGPoint,down:Bool){guard let r=runtime else{return};if down{if let source{stages.removeValue(forKey:"held-"+source)};held=source;heldAt=CACurrentMediaTime();lastRepeat=[:];lastPoint=point}else{if let id=held,let node=r.project.nodes.first(where:{$0.id==id}),!node.rect.insetBy(dx:-6,dy:-6).contains(point){r.fire("cancelPress",sourceID:id)};held=nil}}
    func matches(_ a:String,_ b:String)->Bool{guard let r=runtime else{return false};if a==b{return true};let group=r.project.nodes.first{$0.id==a}?.group ?? "";return !group.isEmpty && r.project.nodes.first{$0.id==b}?.group==group}
    func selectedValue(_ group:String,_ value:Double){if value>=0.5{selected.insert(group)}else{selected.remove(group)}}
    func handle(_ link:InteractionLink,fraction:Double?)->Bool{
        guard let r=runtime,let node=r.project.nodes.first(where:{$0.id==link.targetID}) else{return false}
        let x=link.advanced ?? AdvancedLinkOptions(),now=CACurrentMediaTime()
        needsDisplay=true
        switch link.mode {
        case "thresholds":
            thresholds(link,fraction:fraction ?? 0)
        case "numberAdd","numberSubtract":let old=number(r.text[node.id] ?? node.text);let value=old+(link.mode=="numberAdd" ? link.value:-link.value);r.text[node.id]=formatted(value,x)
        case "formatNumber":r.text[node.id]=formatted(number(r.text[node.id] ?? node.text),x)
        case "textClear":r.text[node.id]=""
        case "textLimit":r.text[node.id]=String((r.text[node.id] ?? node.text).prefix(max(0,x.maxLength)))
        case "typewriter":typing[link.id]=(link.text,now,max(0.01,link.duration),node.id);r.text[node.id]=""
        case "selectedCount":r.text[node.id]=x.prefix+String(selected.count)+x.suffix
        case "sum":let values=r.project.nodes.filter{x.sourceIDs.contains($0.id) && selected.contains($0.group.isEmpty ? $0.id:$0.group)};let total=values.reduce(0.0){$0+number(r.text[$1.id] ?? $1.text)};r.text[node.id]=formatted(total,x)
        case "stateText":let source=r.project.nodes.first{$0.id==link.sourceID};let value:Double;if let fraction{value=fraction}else if source?.widget.isEmpty==false{value=selected.contains(source?.group ?? "") ? 1:0}else{value=stages[link.id]=="on" ? 0:1;stages[link.id]=value>=0.5 ? "on":"off"};r.text[node.id]=value>=0.5 ? link.text:(link.reverseText ?? node.text)
        case "validate":let value=r.text[node.id] ?? node.text;if !valid(value,x.validation){r.fire("invalidInput",sourceID:node.id)}
        case "keyboard":keyboard(node,x)
        case "haptic":UIImpactFeedbackGenerator(style:.light).impactOccurred()
        case "sound":do{let player=try AVAudioPlayer(contentsOf:root.appendingPathComponent("assets").appendingPathComponent(x.asset));try? AVAudioSession.sharedInstance().setCategory(.ambient,options:.mixWithOthers);player.prepareToPlay();player.play();players[link.id]=player}catch{}
        case "stopLink":r.stopAdvancedLink(x.stopID)
        case "imageSwap":var n=node;n.kind="IMAGE";n.asset=x.asset;replacements[node.id]=n
        case "iconSwap":var n=node;n.kind="PATH";n.path=VectorPath.string(icon(x.icon));replacements[node.id]=n
        case "followSize":followers[link.id]=link
        case "moveObject":dragRule=link;dragOrigin=CGPoint(x:r.number[node.id]?["x"] ?? Double(node.x),y:r.number[node.id]?["y"] ?? Double(node.y))
        case "pinchObject","rotateObject":break
        case "multiMorph":beginMorph(link)
        default:return false
        }
        return true
    }
    private func thresholds(_ link:InteractionLink,fraction:Double){
        guard let r=runtime else{return}
        let points=(link.advanced?.checkpoints ?? []).sorted{a,b in a.percent==b.percent ? a.id<b.id:a.percent<b.percent}
        let percent=min(100,max(0,fraction*100))
        let previous=activePoints[link.id] ?? []
        let eligible=Set(points.filter{$0.percent<=percent}.map(\.id))
        guard previous != eligible else{return}
        activePoints[link.id]=eligible
        let removed=points.reversed().filter{previous.contains($0.id) && !eligible.contains($0.id)}
        for point in removed{
            if point.revertOnRewind ?? true{checkpointUndos[link.id]?[point.id]?()}
        }
        var earlier:[InteractionLink]=[]
        for point in points where eligible.contains(point.id){
            let actions=thresholdActions(link,point).filter(\.enabled)
            if !previous.contains(point.id){
                if checkpointUndos[link.id]?[point.id]==nil{checkpointUndos[link.id,default:[:]][point.id]=r.checkpointSnapshot(actions,previous:earlier)}
                for action in actions{r.runAdvanced(action)}
            }
            earlier+=actions
        }
    }

    private func thresholdActions(_ link:InteractionLink,_ point:SliderCheckpoint)->[InteractionLink]{
        let actions=link.actions(at:point).map{input in var a=input;a.id=link.id+"|"+point.id+"|"+input.id;a.sourceID=link.sourceID;return a}
        checkpointOwners[link.id,default:[]].formUnion(actions.map(\.id))
        return actions
    }
    func checkpointVisualSnapshot(_ ids:Set<String>)->()->Void{
        let before=replacements
        return { [weak self] in guard let self else{return};for id in ids{self.replacements[id]=before[id]};self.needsDisplay=true }
    }
    func drag(_ translation:CGPoint){guard let link=dragRule,let r=runtime,let n=r.project.nodes.first(where:{$0.id==link.targetID}) else{return};let x=link.advanced ?? AdvancedLinkOptions();var point=CGPoint(x:dragOrigin.x+(x.axis=="y" ? 0:translation.x),y:dragOrigin.y+(x.axis=="x" ? 0:translation.y));if let area=r.project.nodes.first(where:{$0.id==x.areaID}){point.x=max(area.x,min(point.x,area.x+area.w-n.w));point.y=max(area.y,min(point.y,area.y+area.h-n.h))};r.setAdvanced(n.id,"x",Double(point.x));r.setAdvanced(n.id,"y",Double(point.y))}
    func endDrag(){dragRule=nil}
    func transform(_ event:String,source:String,value:Double,began:Bool=false){guard let r=runtime else{return};for rule in r.project.links where rule.enabled && matches(rule.sourceID,source) && (event=="pinch" && rule.mode=="pinchObject" || event=="rotate" && rule.mode=="rotateObject"){let property=event=="pinch" ? "scale":"rotation";let node=r.project.nodes.first{$0.id==rule.targetID};if began || transformStarts[rule.id]==nil{transformStarts[rule.id]=r.number[rule.targetID]?[property] ?? (event=="pinch" ? 1:Double(node?.rotation ?? 0))};let initial=transformStarts[rule.id] ?? 1;r.setAdvanced(rule.targetID,property,event=="pinch" ? max(0.01,initial*value):initial+value)}}
    func tick(_ now:Double){guard let r=runtime else{return}
        if let source=held{
            if now-heldAt>=0.5,stages["held-"+source] != "long"{stages["held-"+source]="long";r.fire("longPress",sourceID:source)}
            for rule in r.project.links where rule.enabled && rule.event=="holdRepeat" && matches(rule.sourceID,source){let gap=max(0.04,rule.advanced?.holdInterval ?? 0.15);if now-(lastRepeat[rule.id] ?? heldAt)>=gap{lastRepeat[rule.id]=now;r.runAdvanced(rule)}}
        }else{stages=stages.filter{!$0.key.hasPrefix("held-")}}
        for (id,item) in Array(typing){let t=min(1,max(0,(now-item.1)/item.2));r.text[item.3]=String(item.0.prefix(Int(Double(item.0.count)*t)));if t>=1{typing.removeValue(forKey:id);r.fire("finished",sourceID:item.3)}}
        for (id,morph) in Array(morphs) where now>=morph.start+max(0.01,morph.rule.duration) && stages["morph-"+id] != "done"{stages["morph-"+id]="done";needsDisplay=true;r.fire("finished",sourceID:morph.rule.targetID)}
        for rule in followers.values{guard let n=r.project.nodes.first(where:{$0.id==rule.advanced?.otherID}) else{continue};let padding=max(0,rule.advanced?.padding ?? 0);r.setAdvanced(rule.targetID,"width",(r.number[n.id]?["width"] ?? Double(n.w))+padding*2);r.setAdvanced(rule.targetID,"height",(r.number[n.id]?["height"] ?? Double(n.h))+padding*2)}
        for rule in r.project.links where rule.enabled && ["enterArea","exitArea","collision"].contains(rule.event){guard let source=r.project.nodes.first(where:{$0.id==rule.sourceID}),let area=r.project.nodes.first(where:{$0.id==rule.advanced?.areaID}) else{continue};var rect=source.rect;rect.origin.x=CGFloat(r.number[source.id]?["x"] ?? Double(rect.minX));rect.origin.y=CGFloat(r.number[source.id]?["y"] ?? Double(rect.minY));let hit=rule.event=="collision" ? rect.intersects(area.rect):area.rect.contains(CGPoint(x:rect.midX,y:rect.midY));let previous=inside[rule.id] ?? false;inside[rule.id]=hit;if rule.event=="exitArea" ? previous && !hit:!previous && hit{r.runAdvanced(rule)}}
    }
    private func beginMorph(_ link:InteractionLink){guard let r=runtime else{return};let x=link.advanced ?? AdvancedLinkOptions();let source=r.project.nodes.filter{x.sourceIDs.contains($0.id)},target=r.project.nodes.filter{x.targetIDs.contains($0.id)}.map{node in var n=node;n.visible=true;return n};guard !source.isEmpty,!target.isEmpty else{return};let count=max(source.count,target.count);var paths:[LinkMorph]=[];for i in 0..<count{var a=source[i%source.count],b=target[i%target.count];a.w=1;a.h=1;b.w=1;b.h=1;paths.append(LinkMorph(fromPath:VectorPath.local(a),toPath:VectorPath.local(b)))};stages.removeValue(forKey:"morph-"+link.id);morphs[link.id]=Morph(rule:link,sources:source,targets:target,paths:paths,start:CACurrentMediaTime())}
    func apply(_ input:Project,at now:Double)->Project{var p=input
        for i in p.nodes.indices{if let n=replacements[p.nodes[i].id]{p.nodes[i].kind=n.kind;p.nodes[i].asset=n.asset;p.nodes[i].path=n.path}}
        for morph in morphs.values{
            let raw=min(1,max(0,(now-morph.start)/max(0.01,morph.rule.duration))),t=InteractionLink.eased(raw,morph.rule.easing)
            let ids=Set((morph.sources+morph.targets).map(\.id));p.nodes=p.nodes.filter{!ids.contains($0.id)}
            if raw>=1{p.nodes+=morph.targets;continue}
            for i in morph.paths.indices{let a=morph.sources[i%morph.sources.count],b=morph.targets[i%morph.targets.count];var n=a;n.id="morph-\(morph.rule.id)-\(i)";n.kind="PATH";n.path=morph.paths[i].svg(t);n.group="";n.x=a.x+(b.x-a.x)*t;n.y=a.y+(b.y-a.y)*t;n.w=a.w+(b.w-a.w)*t;n.h=a.h+(b.h-a.h)*t;n.rotation=a.rotation+(b.rotation-a.rotation)*t;n.opacity=min(a.opacity,b.opacity);p.nodes.append(n)}
        }
        return Self.markers(p)
    }
    static func markers(_ input:Project)->Project{var p=input
        for rule in input.links where rule.enabled && rule.mode=="thresholds"{let x=rule.advanced ?? AdvancedLinkOptions();guard x.showMarkers,let source=input.nodes.first(where:{$0.id==rule.sourceID}) else{continue};let members=source.group.isEmpty ? [source]:input.nodes.filter{$0.group==source.group};let box=members.reduce(CGRect.null){$0.union($1.rect)};let scale=max(0.1,x.markerScale)
            for point in x.checkpoints{let center=box.minX+box.width*CGFloat(min(100,max(0,point.percent))/100);if x.showMarkerBar{var n=Node();n.id="marker-"+point.id;n.kind="RECT";n.fill=x.markerColor;n.w=CGFloat(max(1,x.markerWidth)*scale);n.h=CGFloat(max(1,x.markerHeight)*scale);n.x=center-n.w/2;n.y=box.midY-n.h/2;n.corner=n.w/2;p.nodes.append(n)};if x.showMarkerShape{var n=Node();n.id="marker-shape-"+point.id;n.kind="SHAPE";n.shapeId=point.shapeID;n.fill=x.markerColor;n.w=CGFloat(max(1,x.markerShapeSize)*scale);n.h=n.w;n.x=center-n.w/2;n.y=box.midY-CGFloat(max(1,x.markerHeight)*scale)/2-n.h-8;p.nodes.append(n)}}
        };return p
    }
    private func number(_ value:String)->Double{let s=value.replacingOccurrences(of:",",with:".").filter{"0123456789.-".contains($0)};return Double(s) ?? 0}
    private func formatted(_ value:Double,_ x:AdvancedLinkOptions)->String{let f=NumberFormatter();f.numberStyle = .decimal;f.minimumFractionDigits=min(8,max(0,x.decimals));f.maximumFractionDigits=f.minimumFractionDigits;let text=f.string(from:NSNumber(value:value)) ?? String(value);return x.prefix+text+(x.format=="percent" ? "%":x.format=="currency" && x.suffix.isEmpty ? " ₴":x.suffix)}
    private func valid(_ value:String,_ kind:String)->Bool{switch kind{case "email":return value.range(of:"^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$",options:.regularExpression) != nil;case "number":return Double(value.replacingOccurrences(of:",",with:".")) != nil;case "phone":return value.filter(\.isNumber).count>=7;default:return true}}
    private func keyboard(_ node:Node,_ x:AdvancedLinkOptions){guard let r=runtime else{return};var controller=UIApplication.shared.connectedScenes.compactMap{($0 as? UIWindowScene)?.keyWindow?.rootViewController}.first;while let next=controller?.presentedViewController{controller=next};let alert=UIAlertController(title:node.name,message:nil,preferredStyle:.alert);alert.addTextField{field in field.text=r.text[node.id] ?? node.text;field.keyboardType=x.validation=="number" ? .decimalPad:x.validation=="email" ? .emailAddress:.default;field.addAction(UIAction{[weak self,weak field] _ in guard let self,let field else{return};let value=String((field.text ?? "").prefix(max(0,x.maxLength)));field.text=value;self.needsDisplay=true;self.runtime?.text[node.id]=value;self.runtime?.fire("inputChanged",sourceID:node.id)},for:.editingChanged)};alert.addAction(UIAlertAction(title:"Готово",style:.default){[weak self] _ in let value=alert.textFields?.first?.text ?? "";self?.needsDisplay=true;self?.runtime?.text[node.id]=value;self?.runtime?.fire(self?.valid(value,x.validation)==true ? "inputDone":"invalidInput",sourceID:node.id)});alert.addAction(UIAlertAction(title:"Отмена",style:.cancel));controller?.present(alert,animated:true)}
    private func icon(_ id:String)->CGPath{let result=CGMutablePath();for command in QIcon.icons[id] ?? []{let a=command.args ?? [];let path=CGMutablePath();switch command.op{case "ln":if a.count>=4{path.move(to:CGPoint(x:a[0],y:a[1]));path.addLine(to:CGPoint(x:a[2],y:a[3]))};case "cr":if a.count>=3{path.addEllipse(in:CGRect(x:a[0]-a[2],y:a[1]-a[2],width:a[2]*2,height:a[2]*2))};case "rc":if a.count>=4{path.addRoundedRect(in:CGRect(x:a[0],y:a[1],width:a[2],height:a[3]),cornerWidth:a.count>4 ? a[4]:1,cornerHeight:a.count>4 ? a[4]:1)};default:path.addPath(VectorPath.parse(command.path ?? ""))};let filled=command.fill==true || command.op=="cr" && a.count>3 && a[3]==1 || command.op=="rc" && a.count>5 && a[5]==1;result.addPath(filled ? path:path.copy(strokingWithWidth:2,lineCap:.round,lineJoin:.round,miterLimit:4))};var transform=CGAffineTransform(scaleX:1/24,y:1/24);return result.copy(using:&transform) ?? result}
}
