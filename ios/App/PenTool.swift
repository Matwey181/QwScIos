import SwiftUI

struct PenKnot:Equatable {var point:CGPoint;var handle:CGPoint = .zero}
@MainActor extension Editor {
    func penPath()->CGPath{
        let path=CGMutablePath();guard let first=penKnots.first else{return path}
        path.move(to:first.point)
        let count=penKnots.count
        guard count>1 else{return path}
        for i in 1..<(count+(penClosed ? 1:0)){
            let a=penKnots[i-1],b=penKnots[i%count]
            if a.handle == .zero && b.handle == .zero{path.addLine(to:b.point)}
            else{path.addCurve(to:b.point,control1:CGPoint(x:a.point.x+a.handle.x,y:a.point.y+a.handle.y),control2:CGPoint(x:b.point.x-b.handle.x,y:b.point.y-b.handle.y))}
        }
        if penClosed{path.closeSubpath()};return path
    }
    func penTap(_ p:CGPoint,threshold:CGFloat){
        if penKnots.count>2,let first=penKnots.first,hypot(p.x-first.point.x,p.y-first.point.y)<threshold{penClosed=true;return}
        penKnots.append(PenKnot(point:p))
    }
    func penBegin(_ p:CGPoint,threshold:CGFloat){
        penDragIndex=penKnots.indices.min(by:{hypot(p.x-penKnots[$0].point.x,p.y-penKnots[$0].point.y)<hypot(p.x-penKnots[$1].point.x,p.y-penKnots[$1].point.y)})
        if let i=penDragIndex,hypot(p.x-penKnots[i].point.x,p.y-penKnots[i].point.y)>threshold{penDragIndex=nil}
        if penDragIndex==nil{penKnots.append(PenKnot(point:p));penDragIndex=penKnots.count-1;penDraggingNew=true}else{penDraggingNew=false}
    }
    func penDrag(_ p:CGPoint){guard let i=penDragIndex,penKnots.indices.contains(i)else{return};if penDraggingNew && penSmooth{penKnots[i].handle=CGPoint(x:p.x-penKnots[i].point.x,y:p.y-penKnots[i].point.y)}else{penKnots[i].point=p}}
    func penEnd(){penDragIndex=nil}
    func commitPen(){
        guard penKnots.count>1 else{return}
        var style=Node();style.fill=penClosed ? (project.tone.colors.first ?? -16749974):0;style.stroke=project.tone.colors.first ?? -16749974;style.strokeWidth=penClosed ? 0:2
        if let node=VectorPath.node(penPath(),style:style){edit{$0.nodes.append(node)};selection=[node.id]}
        penKnots=[];penClosed=false;penActive=false
    }
    func drawPen(in c:CGContext,scale:CGFloat){
        c.saveGState();defer{c.restoreGState()};c.setStrokeColor(UIColor.systemBlue.cgColor);c.setFillColor(UIColor.systemBlue.withAlphaComponent(0.1).cgColor);c.setLineWidth(2/scale);c.addPath(penPath());c.drawPath(using:penClosed ? .fillStroke:.stroke)
        for knot in penKnots{
            if knot.handle != .zero{c.setLineWidth(1/scale);c.move(to:CGPoint(x:knot.point.x-knot.handle.x,y:knot.point.y-knot.handle.y));c.addLine(to:CGPoint(x:knot.point.x+knot.handle.x,y:knot.point.y+knot.handle.y));c.strokePath()}
            c.setFillColor(UIColor.white.cgColor);c.addEllipse(in:CGRect(x:knot.point.x-5/scale,y:knot.point.y-5/scale,width:10/scale,height:10/scale));c.drawPath(using:.fillStroke)
        }
    }
}
struct PenToolbar:View{
    @ObservedObject var editor:Editor
    var body:some View{VStack(spacing:8){Text("Точка: нажатие. Кривая: поставьте точку и потяните. Два пальца перемещают холст.").font(qfont(12)).multilineTextAlignment(.center);HStack(spacing:8){QChip(title:"Отмена"){editor.penActive=false;editor.penKnots=[];editor.penClosed=false};QChip(title:"− Точка"){if !editor.penKnots.isEmpty{editor.penKnots.removeLast()}};QChip(title:"Кривая",selected:editor.penSmooth){editor.penSmooth.toggle()};QChip(title:"Замкнуть",selected:editor.penClosed){editor.penClosed.toggle()}};LinkPill(title:"Готово",icon:"checkmark",prominent:true){editor.commitPen()}.disabled(editor.penKnots.count<2)}.padding(14).qSurface(24,"surfaceContainerHigh")}
}
