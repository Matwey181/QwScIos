import Foundation

// Visual presets are ordinary layers with editable links, including older projects.
enum DefaultLinks {
    static func install(_ project:inout Project,componentID:String?=nil){
        var added:[InteractionLink]=[]
        func rule(_ source:String,_ target:String,_ event:String,_ mode:String,_ property:String,_ value:Double)->InteractionLink{
            var link=InteractionLink();link.id="default-\(source)-\(event)-\(property)";link.sourceID=source;link.targetID=target;link.event=event;link.mode=mode;link.property=property;link.value=value;link.duration=0.12;link.easing="easeOut";return link
        }
        for i in project.nodes.indices{
            let n=project.nodes[i]
            if !n.action.isEmpty {
                var link=rule(n.id,n.id,"tap","navigate","action",1)
                if n.action.hasPrefix("toggle:"){link.mode="visibility";link.control="toggle";link.targetID=String(n.action.dropFirst(7))}
                else if n.action.hasPrefix("goto:"){link.destination=String(n.action.dropFirst(5))}
                else if n.action.hasPrefix("url:"){link.mode="url";link.destination=String(n.action.dropFirst(4))}
                else{link.destination="back"}
                added.append(link);project.nodes[i].action=""
            }
        }
        let groups=Dictionary(grouping:project.nodes.indices,by:{project.nodes[$0].group.isEmpty ? project.nodes[$0].id:project.nodes[$0].group})
        for indices in groups.values {
            guard let first=indices.first else{continue}
            let source=indices.first(where:{!project.nodes[$0].widget.isEmpty}) ?? first
            let version=project.nodes[source].extras?.linkDefaultsVersion ?? 0
            if version>=3{continue}
            let n=project.nodes[source],kind=n.widget.components(separatedBy:":").first ?? ""
            let id=componentID ?? n.group.components(separatedBy:"~").last ?? ""
            let namedBackground=indices.first{index in
                let layer=project.nodes[index]
                let name=layer.name.lowercased()
                return ["RECT","ELLIPSE"].contains(layer.kind) && ["кнопка","button","fab"].contains(name)
            }
            let plainButton=namedBackground != nil && kind.isEmpty
            let button=plainButton || id.hasPrefix("btn-") || id.hasPrefix("ios-btn-") || id.hasPrefix("icon-btn") || ["fab","ext-fab","fab-small","fab-large","split-button"].contains(id)
            let interactive = !kind.isEmpty && !["slider","progress","spin"].contains(kind)
            if interactive && version<1{var link=rule(n.id,n.id,"tap","component","component",1);link.control="tap";added.append(link)
                if kind=="pick"{for (event,action) in [("swipeLeft","increase"),("swipeRight","decrease")]{var swipe=rule(n.id,n.id,event,"component","component",1);swipe.control=action;added.append(swipe)}}
            }
            let oldBackground=project.links.first{$0.id=="default-\(n.id)-press-opacity"}?.targetID
            let fallback=indices.first{index in
                let layer=project.nodes[index]
                return layer.pressCorner>=0 || (button || layer.id==oldBackground) && ["RECT","ELLIPSE"].contains(layer.kind)
            }
            let background=plainButton ? namedBackground:(fallback ?? (button ? indices.first:nil))
            if let background=background{
                let layer=project.nodes[background]
                project.links.removeAll{$0.id=="default-\(n.id)-press-opacity" || $0.id=="default-\(n.id)-release-opacity"}
                added.append(rule(n.id,layer.id,"press","animate","groupScale",0.96))
                added.append(rule(n.id,layer.id,"release","animate","groupScale",1))
                added.append(rule(n.id,layer.id,"press","animate","groupTint",0.10))
                added.append(rule(n.id,layer.id,"release","animate","groupTint",0))
                if layer.pressCorner>=0 {
                    added.append(rule(n.id,layer.id,"press","animate","corner",Double(layer.pressCorner)))
                    added.append(rule(n.id,layer.id,"release","animate","corner",Double(min(layer.corner,min(layer.w,layer.h)/2))))
                    project.nodes[background].pressCorner = -1
                }
            }
            for i in indices{var x=project.nodes[i].extras ?? LayerExtras();x.linkDefaultsVersion=3;project.nodes[i].extras=x}
        }
        let existing=Set(project.links.map(\.id));project.links += added.filter{!existing.contains($0.id)}
        installPlayerControls(&project)
    }
    private static func installPlayerControls(_ project:inout Project){
        let playIcons=project.nodes.filter{$0.name.lowercased().replacingOccurrences(of:"_",with:" ")=="play arrow" && !$0.group.isEmpty}
        for icon in playIcons {
            let source=project.nodes.first(where:{$0.group==icon.group && ["RECT","ELLIPSE"].contains($0.kind)}) ?? icon
            let members=Set(project.nodes.filter{$0.group==icon.group}.map(\.id))
            // Preserve user-defined tap behavior and don't recreate deleted defaults.
            let key="template-player-"+source.id
            if project.links.contains(where:{$0.id==key}){continue}
            if project.nodes.first(where:{$0.id==source.id})?.extras?.templatePlayerVersion==1{continue}
            if project.links.contains(where:{$0.event=="tap" && members.contains($0.sourceID)}){continue}
            let sliders=project.nodes.filter{$0.widget.hasPrefix("slider:") && !$0.group.isEmpty}
            guard let slider=sliders.min(by:{abs($0.y-source.y)<abs($1.y-source.y)}) else{continue}
            let labels=project.nodes.filter{$0.kind=="TEXT" && $0.y<source.y && $0.y>slider.y && $0.text.contains(":")}
            let elapsed=labels.min(by:{$0.x<$1.x}),end=labels.max(by:{$0.x<$1.x})
            var duration=228.0
            if let label=end{let parts=label.text.split(separator:":").compactMap{Double($0)};if parts.count==2{duration=max(1,parts[0]*60+parts[1])}}
            var play=InteractionLink();play.id=key;play.sourceID=source.id;play.targetID=slider.id;play.mode="playback";play.duration=duration;play.easing="linear";play.autoplay=false;play.resumeAfterSeek=true;play.elapsedEnabled=elapsed != nil;play.elapsedID=elapsed?.id
            project.links.append(play)
            for i in project.nodes.indices where project.nodes[i].group==icon.group{var x=project.nodes[i].extras ?? LayerExtras();x.templatePlayerVersion=1;project.nodes[i].extras=x}
            for (name,value) in [("skip previous",0.0),("skip next",1.0)]{
                let controls=project.nodes.filter{$0.name.lowercased().replacingOccurrences(of:"_",with:" ")==name && !$0.group.isEmpty}
                for control in controls {
                    let button=project.nodes.first(where:{$0.group==control.group && ["RECT","ELLIPSE"].contains($0.kind)}) ?? control
                    let ids=Set(project.nodes.filter{$0.group==button.group}.map(\.id))
                    if project.links.contains(where:{$0.event=="tap" && ids.contains($0.sourceID)}){continue}
                    var link=InteractionLink();link.id="template-skip-"+button.id;link.sourceID=button.id;link.targetID=slider.id;link.mode="component";link.control="set";link.value=value;project.links.append(link)
                }
            }
        }
    }
    static func allPages(_ project:inout Project){
        AppleCatalog.prepare(&project,id:"ios")
        install(&project)
        for i in project.pages.indices where i != project.active{
            let sourceIDs=Set(project.pages[i].nodes.map(\.id))
            var page=Project();page.nodes=project.pages[i].nodes;page.links=project.links.filter{sourceIDs.contains($0.sourceID)};AppleCatalog.prepare(&page,id:"ios");install(&page)
            project.pages[i].nodes=page.nodes
            project.links.removeAll{sourceIDs.contains($0.sourceID)};project.links += page.links
        }
        project.syncPage()
    }
}

@MainActor extension Editor {
    func links(for source:Node)->[InteractionLink]{
        let ids=Set(project.nodes.filter{$0.id==source.id || (!source.group.isEmpty && $0.group==source.group)}.map(\.id))
        return project.links.filter{ids.contains($0.sourceID)}
    }
}
