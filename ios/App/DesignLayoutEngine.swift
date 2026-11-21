import UIKit

/// Deterministic design layout. Editing, screen previews and export use the same geometry.
enum DesignLayoutEngine {
    static func resolve(_ project:inout Project,renderer:DocumentRenderer,applyStyles:Bool=true){
        let colors=project.studio?.colorStyles ?? [],styles=project.studio?.textStyles ?? [],dark=project.tone.dark
        func styled(_ node:Node)->Node {
            var n=node,x=n.extras ?? LayerExtras()
            if applyStyles,let style=colors.first(where:{$0.id==x.colorStyleID}){n.fill=dark ? style.dark:style.light;n.fillToken = -1}
            if applyStyles,n.kind=="TEXT",let style=styles.first(where:{$0.id==x.textStyleID}){n.font=style.font;n.fontSize=style.size;n.weight=style.weight;n.textAlign=style.alignment;x.tracking=style.tracking;x.lineSpacing=style.lineSpacing;n.extras=x}
            if n.kind=="TEXT"{
                if x.hugWidth==true{n.w=measuredWidth(n,renderer:renderer)}
                if x.autoFit != true && x.hugHeight != false{n.h=TextLayout(n,font:renderer.font(n)).height}
            }
            return n
        }
        // Style every page and state, not just the page currently being edited.
        project.nodes=project.nodes.map(styled)
        for i in project.pages.indices{project.pages[i].nodes=project.pages[i].nodes.map(styled)}
        if var studio=project.studio{studio.states=studio.states.map{state in var state=state;state.nodes=state.nodes.map(styled);return state};project.studio=studio}
        for _ in 0..<2 {
            for frame in project.studio?.layouts ?? [] where frame.enabled{layout(frame,in:&project,renderer:renderer)}
        }
        project.syncPage()
    }
    static func measuredWidth(_ node:Node,renderer:DocumentRenderer)->CGFloat {
        let text=TextLayout.attributed(node,font:renderer.font(node))
        return max(1,ceil(text.boundingRect(with:CGSize(width:1_000_000,height:1_000_000),options:[.usesLineFragmentOrigin,.usesFontLeading],context:nil).width)+2)
    }
    private static func layout(_ frame:AutoLayoutFrame,in project:inout Project,renderer:DocumentRenderer){
        let indices=frame.children.compactMap{id in project.nodes.firstIndex{$0.id==id}}
        guard !indices.isEmpty else{return}
        let horizontal=frame.axis=="horizontal",padding=max(0,frame.padding),gap=max(0,frame.gap)
        let width=frame.widthMode=="fill" ? max(1,project.w-frame.x-frame.rightInset):max(1,frame.width)
        if frame.widthMode != "hug"{
            let textIndices=indices.filter{project.nodes[$0].kind=="TEXT"}
            let otherWidth=indices.filter{project.nodes[$0].kind != "TEXT"}.reduce(CGFloat(0)){$0+project.nodes[$1].w}
            let available=max(1,width-padding*2-(horizontal ? otherWidth+gap*CGFloat(max(0,indices.count-1)):0))
            for i in textIndices{
                project.nodes[i].w=horizontal ? min(project.nodes[i].w,available/CGFloat(max(1,textIndices.count))):available
                if project.nodes[i].extras?.autoFit != true{project.nodes[i].h=TextLayout(project.nodes[i],font:renderer.font(project.nodes[i])).height}
            }
        }
        let contentWidth=horizontal ? indices.reduce(CGFloat(0)){$0+project.nodes[$1].w}+gap*CGFloat(max(0,indices.count-1)):(indices.map{project.nodes[$0].w}.max() ?? 0)
        let contentHeight=horizontal ? (indices.map{project.nodes[$0].h}.max() ?? 0):indices.reduce(CGFloat(0)){$0+project.nodes[$1].h}+gap*CGFloat(max(0,indices.count-1))
        let w=frame.widthMode=="hug" ? contentWidth+padding*2:width
        let h=frame.heightMode=="hug" ? contentHeight+padding*2:max(1,frame.height)
        var cursor=horizontal ? frame.x+padding:frame.y+padding
        for i in indices{
            let cross=horizontal ? h: w,child=horizontal ? project.nodes[i].h:project.nodes[i].w
            let offset=frame.alignment=="start" ? padding:frame.alignment=="end" ? cross-padding-child:(cross-child)/2
            if horizontal{project.nodes[i].x=cursor;project.nodes[i].y=frame.y+offset;cursor+=project.nodes[i].w+gap}
            else{project.nodes[i].y=cursor;project.nodes[i].x=frame.x+offset;cursor+=project.nodes[i].h+gap}
        }
        if let i=project.nodes.firstIndex(where:{$0.id==frame.backgroundID}){project.nodes[i].x=frame.x;project.nodes[i].y=frame.y;project.nodes[i].w=w;project.nodes[i].h=h}
    }
    static func resized(_ value:Project,width:CGFloat,height:CGFloat,renderer:DocumentRenderer)->Project {
        var p=value
        let dx=width-p.w,dy=height-p.h
        func anchored(_ node:Node)->Node {
            var n=node
            switch n.extras?.anchorX ?? "left"{case "center":n.x+=dx/2;case "right":n.x+=dx;case "stretch":n.w=max(1,n.w+dx);default:break}
            switch n.extras?.anchorY ?? "top"{case "center":n.y+=dy/2;case "bottom":n.y+=dy;case "stretch":n.h=max(1,n.h+dy);default:break}
            return n
        }
        p.nodes=p.nodes.map(anchored)
        for i in p.pages.indices{p.pages[i].nodes=p.pages[i].nodes.map(anchored)}
        if var studio=p.studio,var frames=studio.layouts {
            for i in frames.indices {
                let member=frames[i].backgroundID ?? frames[i].children.first ?? ""
                let node=value.nodes.first{$0.id==member}
                switch node?.extras?.anchorX ?? "left"{case "center":frames[i].x+=dx/2;case "right":frames[i].x+=dx;case "stretch":frames[i].widthMode="fill";default:break}
                switch node?.extras?.anchorY ?? "top"{case "center":frames[i].y+=dy/2;case "bottom":frames[i].y+=dy;case "stretch":frames[i].heightMode="fixed";frames[i].height=max(1,frames[i].height+dy);default:break}
            }
            studio.layouts=frames;p.studio=studio
        }
        p.w=width;p.h=height;resolve(&p,renderer:renderer);return p
    }
    static func themed(_ value:Project,dark:Bool,renderer:DocumentRenderer)->Project {
        var p=value;let tone=ToneGenerator.scheme(seed:p.tone.seed,dark:dark);p.tone=tone
        func update(_ n:Node)->Node{var n=n;if tone.colors.indices.contains(Int(n.fillToken)){n.fill=tone.colors[Int(n.fillToken)]};if tone.colors.indices.contains(Int(n.strokeToken)){n.stroke=tone.colors[Int(n.strokeToken)]};return n}
        p.nodes=p.nodes.map(update)
        if tone.colors.indices.contains(p.bgToken){p.bg=tone.colors[p.bgToken]}
        resolve(&p,renderer:renderer);return p
    }
}
