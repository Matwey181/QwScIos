import SwiftUI

@MainActor final class RecentColors:ObservableObject {
    static let shared=RecentColors()
    @Published private(set) var colors:[Int64]=(UserDefaults.standard.array(forKey:"designRecentColors") as? [NSNumber] ?? []).map(\.int64Value)
    func record(_ color:Int64){guard colors.first != color else{return};colors.removeAll{$0==color};colors.insert(color,at:0);colors=Array(colors.prefix(12));UserDefaults.standard.set(colors.map{NSNumber(value:$0)},forKey:"designRecentColors")}
}
@MainActor enum AppearanceClipboard {
    static var node:Node? {
        get{guard let data=UserDefaults.standard.data(forKey:"designStyleClipboard") else{return nil};return try? JSONDecoder().decode(Node.self,from:data)}
        set{UserDefaults.standard.set(try? newValue.map{try JSONEncoder().encode($0)},forKey:"designStyleClipboard")}
    }
}
@MainActor extension Editor {
    var editableNodes:[Node]{guard let isolated=isolatedIDs else{return project.nodes};return project.nodes.filter{isolated.contains($0.id)}}
    var canvasProject:Project {var p=project;p.nodes=editableNodes;return p}
    func toggleIsolation(){isolatedIDs=isolatedIDs==nil && !selection.isEmpty ? selection:nil}
    func copyAppearance(){AppearanceClipboard.node=selected.first;objectWillChange.send()}
    func pasteAppearance(){
        guard let source=AppearanceClipboard.node else{return}
        change{n in
            n.fill=source.fill;n.fill2=source.fill2;n.stroke=source.stroke;n.strokeWidth=source.strokeWidth;n.fillToken = -1;n.strokeToken = -1
            n.fillOpacity=source.fillOpacity;n.opacity=source.opacity;n.corner=source.corner;n.gradKind=source.gradKind;n.gradAngle=source.gradAngle;n.shadowColor=source.shadowColor;n.shadowBlur=source.shadowBlur;n.shadowDx=source.shadowDx;n.shadowDy=source.shadowDy;n.liquid=source.liquid;n.blur=source.blur;n.softBlur=source.softBlur
            if n.kind=="TEXT"{n.font=source.font;n.fontSize=source.fontSize;n.weight=source.weight;n.textAlign=source.textAlign;var x=n.extras ?? LayerExtras();x.tracking=source.extras?.tracking ?? 0;x.lineSpacing=source.extras?.lineSpacing ?? 0;x.runs=[];x.textStyleID=nil;n.extras=x}
            if n.extras != nil{n.extras?.colorStyleID=nil}
        }
    }
    func nudge(_ dx:CGFloat,_ dy:CGFloat){
        edit{p in
            var managed=Set<String>()
            if var studio=p.studio,var layouts=studio.layouts{
                for i in layouts.indices where !Set(layouts[i].children+[layouts[i].backgroundID].compactMap{$0}).isDisjoint(with:selection){layouts[i].x+=dx;layouts[i].y+=dy;managed.formUnion(layouts[i].children);if let background=layouts[i].backgroundID{managed.insert(background)}}
                studio.layouts=layouts;p.studio=studio
            }
            for i in p.nodes.indices where selection.contains(p.nodes[i].id) && !managed.contains(p.nodes[i].id){p.nodes[i].x+=dx;p.nodes[i].y+=dy}
        }
    }
    func resizeCanvas(_ width:CGFloat,_ height:CGFloat){edit{$0=DesignLayoutEngine.resized($0,width:width,height:height,renderer:renderer)};fitVersion+=1}
    func createAutoLayout(){
        guard let box=bounds,selected.count>=2 else{return}
        let background=selected.filter{$0.kind=="RECT" && (selected.contains{$0.kind=="TEXT"} || $0.rect.insetBy(dx:-1,dy:-1).contains(box))}.max{$0.w*$0.h<$1.w*$1.h}
        let children=selected.filter{$0.id != background?.id}.sorted{$0.x<$1.x}.map(\.id)
        var frame=AutoLayoutFrame(children:children,backgroundID:background?.id,x:box.minX,y:box.minY,width:box.width,height:box.height)
        frame.rightInset=max(0,project.w-box.maxX)
        let originalGroup=selected.first?.group ?? "",groups=Set(selected.map(\.group))
        frame.groupItems=background==nil || groups.count>1
        edit{p in var studio=p.studio ?? StudioDocument();studio.layouts=(studio.layouts ?? []).filter{Set($0.children).isDisjoint(with:children)}+[frame];p.studio=studio
            let group=originalGroup.isEmpty ? UUID().uuidString:originalGroup
            for i in p.nodes.indices where selection.contains(p.nodes[i].id){if groups.count<=1 && frame.groupItems != true{p.nodes[i].group=group};if p.nodes[i].kind=="TEXT" && (p.nodes[i].group.isEmpty || frame.groupItems != true){var x=p.nodes[i].extras ?? LayerExtras();x.hugWidth=true;p.nodes[i].extras=x}}
        }
    }
    func finishLayoutGesture(original:[Node]){
        guard var studio=project.studio,var frames=studio.layouts else{return}
        let moved=Set(original.map(\.id)),old=original.reduce(CGRect.null){$0.union($1.rect)},new=selected.reduce(CGRect.null){$0.union($1.rect)}
        for i in frames.indices {
            let ids=Set(frames[i].children+[frames[i].backgroundID].compactMap{$0})
            if ids.isSubset(of:moved){frames[i].x+=new.minX-old.minX;frames[i].y+=new.minY-old.minY
                if abs(new.width-old.width)>0.5{frames[i].widthMode="fixed";frames[i].width=new.width}
                if abs(new.height-old.height)>0.5{frames[i].heightMode="fixed";frames[i].height=new.height}
            }else if !ids.isDisjoint(with:moved){let horizontal=frames[i].axis=="horizontal";frames[i].children.sort{a,b in let x=project.nodes.first{$0.id==a},y=project.nodes.first{$0.id==b};return horizontal ? (x?.x ?? 0)<(y?.x ?? 0):(x?.y ?? 0)<(y?.y ?? 0)}}
        }
        studio.layouts=frames;project.studio=studio;DesignLayoutEngine.resolve(&project,renderer:renderer)
    }
    func addReference(_ data:Data) throws {
        guard let image=UIImage(data:data),let png=image.pngData() else{throw CocoaError(.fileReadCorruptFile)}
        let file=UUID().uuidString+".png";try png.write(to:store.assets.appendingPathComponent(file),options:.atomic)
        let scale=min(project.w/image.size.width,project.h/image.size.height)
        var node=Node();node.kind="IMAGE";node.name="Референс";node.asset=file;node.w=image.size.width*scale;node.h=image.size.height*scale;node.x=(project.w-node.w)/2;node.y=(project.h-node.h)/2;node.opacity=0.35;node.locked=true
        var x=LayerExtras();x.reference=true;x.imageMode="fit";node.extras=x
        edit{$0.nodes.removeAll{$0.extras?.reference==true};$0.nodes.insert(node,at:0)}
    }
}
