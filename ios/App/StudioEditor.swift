import SwiftUI

@MainActor extension Editor {
    func extras(_ change:(inout LayerExtras)->Void){self.change{node in var value=node.extras ?? LayerExtras();change(&value);node.extras=value}}
    func studio(_ change:(inout StudioDocument)->Void){edit{p in var value=p.studio ?? StudioDocument();change(&value);p.studio=value}}
    func captureState(_ name:String,wholeScreen:Bool){
        let nodes=wholeScreen ? project.nodes:selected
        guard !nodes.isEmpty else{return}
        let pageID=project.pages.indices.contains(project.active) ? project.pages[project.active].id:""
        studio{$0.states.append(VisualState(name:name.isEmpty ? "Состояние":name,nodes:nodes,pageID:pageID))}
    }
    func applyState(_ state:VisualState){
        let map=Dictionary(uniqueKeysWithValues:state.nodes.map{($0.id,$0)})
        edit{p in p.nodes=p.nodes.map{map[$0.id] ?? $0}}
    }
    func replaceImage(_ data:Data,id:String) throws {
        guard let image=UIImage(data:data),let png=image.pngData(),let i=project.nodes.firstIndex(where:{$0.id==id}) else{throw CocoaError(.fileReadCorruptFile)}
        let file=UUID().uuidString+".png";try png.write(to:store.assets.appendingPathComponent(file),options:.atomic)
        edit{$0.nodes[i].asset=file}
    }
    func restore(_ revision:ProjectRevision) throws {
        try store.checkpoint(project,label:"Перед восстановлением")
        let restored=try store.readRevision(revision,projectID:project.id)
        edit{$0=restored};selection=[];fitVersion+=1
    }
    func saveReusable(_ name:String) throws {
        guard let box=bounds,!selected.isEmpty else{return}
        let ids=selection
        var p=Project();p.name=name.isEmpty ? "Мой компонент":name;p.w=max(1,box.width);p.h=max(1,box.height)
        let definitions=Set(selected.compactMap{$0.extras?.definitionID})
        let instances=Set(selected.compactMap{$0.extras?.instanceID})
        let existing=definitions.count==1 && instances.count==1 && selected.allSatisfy{$0.extras?.definitionID != nil} ? definitions.first:nil
        let canonical=Dictionary(uniqueKeysWithValues:selected.map{($0.id,existing==nil ? $0.id:($0.extras?.sourceLayerID ?? $0.id))})
        p.nodes=selected.map{n in var n=n;n.id=canonical[n.id] ?? n.id;n.x-=box.minX;n.y-=box.minY;return n}
        p.links=project.links.filter{ids.contains($0.sourceID) && ids.contains($0.targetID)}.map{r in var r=r;r.sourceID=canonical[r.sourceID] ?? r.sourceID;r.targetID=canonical[r.targetID] ?? r.targetID;r.elapsedID=r.elapsedID.map{canonical[$0] ?? $0};r.remainingID=r.remainingID.map{canonical[$0] ?? $0};return r}
        var studio=StudioDocument();studio.states=(project.studio?.states ?? []).filter{!$0.nodes.isEmpty && $0.nodes.allSatisfy{ids.contains($0.id)}}.map{state in var s=state;s.nodes=s.nodes.map{n in var n=n;n.id=canonical[n.id] ?? n.id;n.x-=box.minX;n.y-=box.minY;return n};return s};studio.colorStyles=project.studio?.colorStyles;studio.textStyles=project.studio?.textStyles
        studio.layouts=(project.studio?.layouts ?? []).filter{Set($0.children+[$0.backgroundID].compactMap{$0}).isSubset(of:ids)}.map{f in var f=f;f.x-=box.minX;f.y-=box.minY;f.children=f.children.map{canonical[$0] ?? $0};f.backgroundID=f.backgroundID.map{canonical[$0] ?? $0};return f}
        p.studio=studio
        var component=ReusableComponent(name:p.name,project:p)
        if let existing{component.id=existing}
        try store.saveComponent(component)
        let instance=existing==nil ? UUID().uuidString:(selected.first?.extras?.instanceID ?? UUID().uuidString)
        change{node in var extras=node.extras ?? LayerExtras();extras.definitionID=component.id;extras.instanceID=instance;extras.sourceLayerID=canonical[node.id] ?? node.id;node.extras=extras}
    }
    func insertReusable(_ component:ReusableComponent,at origin:CGPoint?=nil){
        let origin=origin ?? CGPoint(x:(project.w-component.project.w)/2,y:(project.h-component.project.h)/2)
        let result=remapComponent(component,origin:origin,instance:UUID().uuidString,existing:[:])
        edit{p in p.nodes+=result.nodes;p.links+=result.links;var studio=p.studio ?? StudioDocument();studio.states+=result.studio?.states ?? []
            studio.layouts=(studio.layouts ?? [])+(result.studio?.layouts ?? [])
            for style in result.studio?.colorStyles ?? [] where !(studio.colorStyles ?? []).contains(where:{$0.id==style.id}){studio.colorStyles=(studio.colorStyles ?? [])+[style]}
            for style in result.studio?.textStyles ?? [] where !(studio.textStyles ?? []).contains(where:{$0.id==style.id}){studio.textStyles=(studio.textStyles ?? [])+[style]}
            p.studio=studio}
        selection=Set(result.nodes.map(\.id))
    }
    func updateInstances(_ component:ReusableComponent){
        let instances=Dictionary(grouping:project.nodes.filter{$0.extras?.definitionID==component.id},by:{$0.extras?.instanceID ?? ""})
        edit{p in for (id,nodes) in instances where !id.isEmpty {
            let box=nodes.reduce(CGRect.null){$0.union($1.rect)}
            let existing=Dictionary(nodes.compactMap{n in n.extras?.sourceLayerID.map{($0,n.id)}},uniquingKeysWith:{first,_ in first})
            let result=remapComponent(component,origin:box.origin,instance:id,existing:existing)
            let oldIDs=Set(nodes.map(\.id));p.nodes.removeAll{oldIDs.contains($0.id)};p.nodes+=result.nodes
            p.links.removeAll{oldIDs.contains($0.sourceID) && oldIDs.contains($0.targetID)};p.links+=result.links
            var studio=p.studio ?? StudioDocument();studio.states.removeAll{!$0.nodes.isEmpty && $0.nodes.allSatisfy{oldIDs.contains($0.id)}};studio.states+=result.studio?.states ?? [];studio.layouts=(studio.layouts ?? []).filter{Set($0.children).isDisjoint(with:oldIDs)}+(result.studio?.layouts ?? []);p.studio=studio
        }}
    }
    private func remapComponent(_ component:ReusableComponent,origin:CGPoint,instance:String,existing:[String:String])->Project {
        var p=component.project
        let ids=Dictionary(uniqueKeysWithValues:p.nodes.map{($0.id,existing[$0.id] ?? UUID().uuidString)})
        var groups:[String:String]=[:]
        for n in p.nodes where !n.group.isEmpty{groups[n.group]=UUID().uuidString+(n.group.contains("~") ? "~"+(n.group.split(separator:"~").last.map(String.init) ?? ""):"")}
        var states:[String:String]=[:];for state in p.studio?.states ?? []{states[state.id]=UUID().uuidString}
        func node(_ source:Node)->Node {var n=source;n.id=ids[source.id] ?? source.id;n.x+=origin.x;n.y+=origin.y;n.group=groups[source.group] ?? source.group
            if n.action.hasPrefix("toggle:"){n.action="toggle:"+(ids[String(n.action.dropFirst(7))] ?? String(n.action.dropFirst(7)))}
            var x=n.extras ?? LayerExtras();x.definitionID=component.id;x.instanceID=instance;x.sourceLayerID=source.id;n.extras=x;return n}
        p.nodes=p.nodes.map(node)
        p.links=p.links.map{original in var link=original;link.id=UUID().uuidString;link.sourceID=ids[link.sourceID] ?? link.sourceID;link.targetID=ids[link.targetID] ?? link.targetID;link.elapsedID=link.elapsedID.map{ids[$0] ?? $0};link.remainingID=link.remainingID.map{ids[$0] ?? $0};link.stateID=link.stateID.map{states[$0] ?? $0};return link}
        if var studio=p.studio{studio.layouts=studio.layouts?.map{f in var f=f;f.id=UUID().uuidString;f.x+=origin.x;f.y+=origin.y;f.children=f.children.map{ids[$0] ?? $0};f.backgroundID=f.backgroundID.map{ids[$0] ?? $0};return f};studio.states=studio.states.map{original in var state=original;state.id=states[state.id] ?? state.id;state.nodes=state.nodes.map(node);return state};p.studio=studio}
        return p
    }
}
