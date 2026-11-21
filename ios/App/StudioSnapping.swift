import UIKit

@MainActor extension Editor {
    func snapOffset(_ moving:[Node])->CGPoint {
        guard snap,!moving.isEmpty else{snapGuidesX=[];snapGuidesY=[];return .zero}
        let box=moving.reduce(CGRect.null){$0.union($1.rect)},ids=Set(moving.map(\.id)),threshold=6/max(0.01,canvasScale)
        let others=project.nodes.filter{$0.visible && !ids.contains($0.id)}.map(\.rect)
        let studio=project.studio ?? StudioDocument()
        var xs=[CGFloat(0),project.w/2,project.w]+studio.guidesX
        var ys=[CGFloat(0),project.h/2,project.h]+studio.guidesY
        for rect in others{xs += [rect.minX,rect.midX,rect.maxX];ys += [rect.minY,rect.midY,rect.maxY]}
        if studio.spacingSnap {
            if let left=others.filter({$0.maxX<=box.minX}).max(by:{$0.maxX<$1.maxX}),let right=others.filter({$0.minX>=box.maxX}).min(by:{$0.minX<$1.minX}) {xs.append((left.maxX+right.minX)/2)}
            if let top=others.filter({$0.maxY<=box.minY}).max(by:{$0.maxY<$1.maxY}),let bottom=others.filter({$0.minY>=box.maxY}).min(by:{$0.minY<$1.minY}) {ys.append((top.maxY+bottom.minY)/2)}
        }
        func best(_ anchors:[CGFloat],_ targets:[CGFloat])->(CGFloat,[CGFloat]) {
            var delta=threshold+1,guide:[CGFloat]=[]
            for anchor in anchors{for target in targets{let distance=target-anchor;if abs(distance)<abs(delta){delta=distance;guide=[target]}}}
            return abs(delta)<=threshold ? (delta,guide):(0,[])
        }
        let x=best([box.minX,box.midX,box.maxX],xs),y=best([box.minY,box.midY,box.maxY],ys)
        snapGuidesX=x.1;snapGuidesY=y.1
        var offset=CGPoint(x:x.0,y:y.0)
        if studio.gridSnap {
            let grid=max(1,studio.gridSize)
            if x.1.isEmpty{offset.x=(box.minX/grid).rounded()*grid-box.minX}
            if y.1.isEmpty{offset.y=(box.minY/grid).rounded()*grid-box.minY}
        }
        return offset
    }
    func fixedGap(_ gap:CGFloat,horizontal:Bool){
        let nodes=selected.sorted{horizontal ? $0.x<$1.x:$0.y<$1.y};guard let first=nodes.first else{return}
        var next=horizontal ? first.x:first.y,values:[String:CGFloat]=[:]
        for n in nodes{values[n.id]=next;next+=(horizontal ? n.w:n.h)+gap}
        change{n in if horizontal{n.x=values[n.id] ?? n.x}else{n.y=values[n.id] ?? n.y}}
    }
}
