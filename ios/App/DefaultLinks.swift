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
            if project.nodes[source].extras?.linkDefaultsVersion==1{continue}
            let n=project.nodes[source],kind=n.widget.components(separatedBy:":").first ?? ""
            let id=componentID ?? n.group.components(separatedBy:"~").last ?? ""
            let button=id.hasPrefix("btn-") || id.hasPrefix("icon-btn") || ["fab","ext-fab","fab-small","fab-large","split-button"].contains(id)
            let interactive = !kind.isEmpty && !["slider","progress","spin"].contains(kind)
            if interactive{var link=rule(n.id,n.id,"tap","component","component",1);link.control="tap";added.append(link)
                if kind=="pick"{for (event,action) in [("swipeLeft","increase"),("swipeRight","decrease")]{var swipe=rule(n.id,n.id,event,"component","component",1);swipe.control=action;added.append(swipe)}}
            }
            if let background=indices.first(where:{project.nodes[$0].pressCorner>=0 || button && project.nodes[$0].kind=="RECT"}){
                let layer=project.nodes[background]
                added.append(rule(n.id,layer.id,"press","animate","opacity",Double(layer.opacity)*0.82))
                added.append(rule(n.id,layer.id,"release","animate","opacity",Double(layer.opacity)))
                if layer.pressCorner>=0 {
                    added.append(rule(n.id,layer.id,"press","animate","corner",Double(layer.pressCorner)))
                    added.append(rule(n.id,layer.id,"release","animate","corner",Double(min(layer.corner,min(layer.w,layer.h)/2))))
                    project.nodes[background].pressCorner = -1
                }
            }
            for i in indices{var x=project.nodes[i].extras ?? LayerExtras();x.linkDefaultsVersion=1;project.nodes[i].extras=x}
        }
        let existing=Set(project.links.map(\.id));project.links += added.filter{!existing.contains($0.id)}
    }
    static func allPages(_ project:inout Project){
        install(&project)
        for i in project.pages.indices where i != project.active{
            var page=Project();page.nodes=project.pages[i].nodes;page.links=[];install(&page)
            project.pages[i].nodes=page.nodes
            let ids=Set(project.links.map(\.id));project.links += page.links.filter{!ids.contains($0.id)}
        }
        project.syncPage()
    }
}
