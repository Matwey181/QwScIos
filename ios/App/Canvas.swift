import SwiftUI

struct EditorCanvas:UIViewRepresentable {
    @ObservedObject var editor:Editor
    func makeUIView(context:Context)->CanvasView { CanvasView(editor:editor) }
    func updateUIView(_ view:CanvasView,context:Context) {
        if view.lastFit != editor.fitVersion { view.lastFit=editor.fitVersion;view.zoom=1;view.pan = .zero }
        view.setNeedsDisplay()
    }
}
@MainActor final class CanvasView:UIView,UIGestureRecognizerDelegate {
    let editor:Editor
    var zoom:CGFloat=1,pan=CGPoint.zero,lastFit=0
    private var initialZoom:CGFloat=1,initialPan=CGPoint.zero
    private var startNodes:[Node]=[],startPoint=CGPoint.zero
    private var mode="",handle=0
    init(editor:Editor) {
        self.editor=editor;super.init(frame:.zero)
        backgroundColor=UIColor.secondarySystemBackground;isMultipleTouchEnabled=true
        let tap=UITapGestureRecognizer(target:self,action:#selector(tap(_:)));addGestureRecognizer(tap)
        let double=UITapGestureRecognizer(target:self,action:#selector(doubleTap));double.numberOfTapsRequired=2;addGestureRecognizer(double);tap.require(toFail:double)
        let drag=UIPanGestureRecognizer(target:self,action:#selector(drag(_:)));drag.maximumNumberOfTouches=1;addGestureRecognizer(drag)
        let pan=UIPanGestureRecognizer(target:self,action:#selector(panning(_:)));pan.minimumNumberOfTouches=2;pan.delegate=self;addGestureRecognizer(pan)
        let pinch=UIPinchGestureRecognizer(target:self,action:#selector(pinching(_:)));pinch.delegate=self;addGestureRecognizer(pinch)
    }
    required init?(coder:NSCoder) { fatalError() }
    var scale:CGFloat { max(0.01,min((bounds.width-48)/editor.project.w,(bounds.height-64)/editor.project.h))*zoom }
    var origin:CGPoint { CGPoint(x:(bounds.width-editor.project.w*scale)/2+pan.x,y:(bounds.height-editor.project.h*scale)/2+pan.y) }
    func document(_ p:CGPoint)->CGPoint { CGPoint(x:(p.x-origin.x)/scale,y:(p.y-origin.y)/scale) }
    override func draw(_ rect:CGRect) {
        guard let ctx=UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState();ctx.translateBy(x:origin.x,y:origin.y);ctx.scaleBy(x:scale,y:scale)
        let page=CGRect(x:0,y:0,width:editor.project.w,height:editor.project.h)
        ctx.setFillColor(UIColor.white.cgColor);ctx.fill(page)
        ctx.saveGState();ctx.clip(to:page);editor.renderer.draw(editor.project,in:ctx);ctx.restoreGState()
        if !editor.playing,let box=editor.bounds {
            ctx.setLineWidth(1.5/scale);ctx.setStrokeColor(UIColor.systemTeal.cgColor);ctx.stroke(box)
            let corners=[CGPoint(x:box.minX,y:box.minY),CGPoint(x:box.maxX,y:box.minY),CGPoint(x:box.maxX,y:box.maxY),CGPoint(x:box.minX,y:box.maxY)]
            for p in corners { let r=CGRect(x:p.x-5/scale,y:p.y-5/scale,width:10/scale,height:10/scale);ctx.setFillColor(UIColor.white.cgColor);ctx.fillEllipse(in:r);ctx.strokeEllipse(in:r) }
            ctx.move(to:CGPoint(x:box.midX,y:box.minY));ctx.addLine(to:CGPoint(x:box.midX,y:box.minY-26/scale));ctx.strokePath()
            let r=CGRect(x:box.midX-5/scale,y:box.minY-31/scale,width:10/scale,height:10/scale);ctx.fillEllipse(in:r);ctx.strokeEllipse(in:r)
        }
        ctx.restoreGState()
    }
    @objc func doubleTap() { zoom=1;pan = .zero;setNeedsDisplay() }
    @objc func tap(_ g:UITapGestureRecognizer) {
        let point=document(g.location(in:self))
        if editor.playing { editor.interact(at:point) }
        else { editor.choose(editor.project.nodes.reversed().first { $0.visible && !$0.locked && !$0.mask && $0.contains(point) }) }
    }
    @objc func panning(_ g:UIPanGestureRecognizer) {
        if g.state == .began { initialPan=pan }
        let t=g.translation(in:self);pan=CGPoint(x:initialPan.x+t.x,y:initialPan.y+t.y);setNeedsDisplay()
    }
    @objc func pinching(_ g:UIPinchGestureRecognizer) {
        if g.state == .began { initialZoom=zoom }
        zoom=min(12,max(0.15,initialZoom*g.scale));setNeedsDisplay()
    }
    func gestureRecognizer(_ gestureRecognizer:UIGestureRecognizer,shouldRecognizeSimultaneouslyWith otherGestureRecognizer:UIGestureRecognizer)->Bool { true }
    @objc func drag(_ g:UIPanGestureRecognizer) {
        let p=document(g.location(in:self))
        if editor.playing { if g.state == .began || g.state == .changed { editor.interact(at:p) };return }
        if g.state == .began {
            startPoint=p;mode="move";startNodes=editor.selected
            if let box=editor.bounds {
                let corners=[CGPoint(x:box.minX,y:box.minY),CGPoint(x:box.maxX,y:box.minY),CGPoint(x:box.maxX,y:box.maxY),CGPoint(x:box.minX,y:box.maxY)]
                if let i=corners.firstIndex(where:{hypot($0.x-p.x,$0.y-p.y)<18/scale}) { mode="resize";handle=i }
                else if hypot(box.midX-p.x,box.minY-26/scale-p.y)<18/scale { mode="rotate" }
                else if !box.insetBy(dx:-8/scale,dy:-8/scale).contains(p) { editor.choose(editor.project.nodes.reversed().first { $0.visible && !$0.locked && $0.contains(p) });startNodes=editor.selected }
            } else { editor.choose(editor.project.nodes.reversed().first { $0.visible && !$0.locked && $0.contains(p) });startNodes=editor.selected }
            if startNodes.isEmpty { mode="pan";initialPan=pan } else { editor.checkpoint() }
        }
        if g.state == .changed {
            if mode=="pan" { let t=g.translation(in:self);pan=CGPoint(x:initialPan.x+t.x,y:initialPan.y+t.y);setNeedsDisplay();return }
            let dx=p.x-startPoint.x,dy=p.y-startPoint.y
            let box=startNodes.reduce(CGRect.null) { $0.union($1.rect) }
            var out=startNodes
            for i in out.indices {
                switch mode {
                case "resize":
                    var target=box
                    if handle==0 || handle==3 { target.origin.x += dx;target.size.width -= dx } else { target.size.width += dx }
                    if handle<2 { target.origin.y += dy;target.size.height -= dy } else { target.size.height += dy }
                    target.size.width=max(4,target.width);target.size.height=max(4,target.height)
                    if out[i].ratioLock { target.size.height=target.width*box.height/max(1,box.width) }
                    let sx=target.width/max(1,box.width),sy=target.height/max(1,box.height)
                    out[i].x=target.minX+(startNodes[i].x-box.minX)*sx;out[i].y=target.minY+(startNodes[i].y-box.minY)*sy
                    out[i].w=max(1,startNodes[i].w*sx);out[i].h=max(1,startNodes[i].h*sy)
                    if out[i].kind=="TEXT" { out[i].fontSize=startNodes[i].fontSize*min(sx,sy) }
                case "rotate":
                    let center=CGPoint(x:box.midX,y:box.midY)
                    let delta=(atan2(p.y-center.y,p.x-center.x)-atan2(startPoint.y-center.y,startPoint.x-center.x))*180 / .pi
                    let angle=editor.snap ? (delta/15).rounded()*15:delta
                    let rad=angle * .pi/180,x=startNodes[i].center.x-center.x,y=startNodes[i].center.y-center.y
                    out[i].x=center.x+x*cos(rad)-y*sin(rad)-out[i].w/2;out[i].y=center.y+x*sin(rad)+y*cos(rad)-out[i].h/2;out[i].rotation=startNodes[i].rotation+angle
                default:
                    out[i].x=startNodes[i].x+dx;out[i].y=startNodes[i].y+dy
                    if editor.snap {
                        if abs(out[i].center.x-editor.project.w/2)<5/scale { out[i].x=editor.project.w/2-out[i].w/2 }
                        if abs(out[i].center.y-editor.project.h/2)<5/scale { out[i].y=editor.project.h/2-out[i].h/2 }
                    }
                }
            }
            let map=Dictionary(uniqueKeysWithValues:out.map { ($0.id,$0) });editor.project.nodes=editor.project.nodes.map { map[$0.id] ?? $0 }
        }
        if g.state == .ended || g.state == .cancelled { editor.saveSoon();startNodes=[] }
    }
}
