import SwiftUI

struct EditorCanvas:UIViewRepresentable {
    @ObservedObject var editor:Editor
    @Environment(\.q) var q
    func makeUIView(context:Context)->CanvasView { CanvasView(editor:editor) }
    func updateUIView(_ view:CanvasView,context:Context) {
        if view.lastFit != editor.fitVersion { view.lastFit=editor.fitVersion;view.zoom=1;view.pan = .zero }
        view.palette=q;view.backgroundColor=UIColor(argb:q.argb("surfaceContainer"));view.setNeedsDisplay();view.setNeedsLayout()
    }
}
@MainActor final class CanvasView:UIView,UIGestureRecognizerDelegate {
    var palette=QPalette()
    let editor:Editor
    var zoom:CGFloat=1,pan=CGPoint.zero,lastFit=0
    private var initialZoom:CGFloat=1,initialPan=CGPoint.zero
    private var startNodes:[Node]=[],startPoint=CGPoint.zero
    private var mode="",handle=0
    private let ratioButton=UIButton(type:.system)
    init(editor:Editor) {
        self.editor=editor;super.init(frame:.zero)
        backgroundColor=UIColor.secondarySystemBackground;isMultipleTouchEnabled=true
        ratioButton.addTarget(self,action:#selector(toggleRatio),for:.touchUpInside);ratioButton.layer.cornerRadius=18;ratioButton.accessibilityLabel="Сохранение пропорций";addSubview(ratioButton)
        let tap=UITapGestureRecognizer(target:self,action:#selector(tap(_:)));addGestureRecognizer(tap)
        let double=UITapGestureRecognizer(target:self,action:#selector(doubleTap(_:)));double.numberOfTapsRequired=2;addGestureRecognizer(double);tap.require(toFail:double)
        let long=UILongPressGestureRecognizer(target:self,action:#selector(longPress(_:)));addGestureRecognizer(long)
        let undo=UITapGestureRecognizer(target:self,action:#selector(twoTap));undo.numberOfTouchesRequired=2;addGestureRecognizer(undo)
        let redo=UITapGestureRecognizer(target:self,action:#selector(threeTap));redo.numberOfTouchesRequired=3;addGestureRecognizer(redo)
        let drag=UIPanGestureRecognizer(target:self,action:#selector(drag(_:)));drag.maximumNumberOfTouches=1;addGestureRecognizer(drag)
        let pan=UIPanGestureRecognizer(target:self,action:#selector(panning(_:)));pan.minimumNumberOfTouches=2;pan.delegate=self;addGestureRecognizer(pan)
        let pinch=UIPinchGestureRecognizer(target:self,action:#selector(pinching(_:)));pinch.delegate=self;addGestureRecognizer(pinch)
        // A two/three-finger tap must lose to any canvas navigation gesture.
        for tap in [undo,redo] {tap.require(toFail:pinch);tap.require(toFail:pan)}
        for recognizer in gestureRecognizers ?? []{recognizer.delegate=self}
    }
    required init?(coder:NSCoder) { fatalError() }
    var scale:CGFloat { max(0.01,min((bounds.width-48)/editor.project.w,(bounds.height-240)/editor.project.h))*zoom }
    var origin:CGPoint { CGPoint(x:(bounds.width-editor.project.w*scale)/2+pan.x,y:88+(bounds.height-240-editor.project.h*scale)/2+pan.y) }
    func document(_ p:CGPoint)->CGPoint { CGPoint(x:(p.x-origin.x)/scale,y:(p.y-origin.y)/scale) }
    override func draw(_ rect:CGRect) {
        guard let ctx=UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState();ctx.translateBy(x:origin.x,y:origin.y);ctx.scaleBy(x:scale,y:scale)
        let page=CGRect(x:0,y:0,width:editor.project.w,height:editor.project.h)
        ctx.setFillColor(UIColor(argb:editor.project.bg).cgColor);ctx.fill(page)
        ctx.saveGState();ctx.clip(to:page)
        if editor.showGrid && !editor.playing {
            let step:CGFloat = 8*scale<7 ? 32:8
            if step*scale>=7 {
                ctx.setStrokeColor(UIColor(argb:palette.argb("outlineVariant")).withAlphaComponent(0.45).cgColor);ctx.setLineWidth(1/scale)
                for x in stride(from:CGFloat(0),through:editor.project.w,by:step) {ctx.move(to:CGPoint(x:x,y:0));ctx.addLine(to:CGPoint(x:x,y:editor.project.h))}
                for y in stride(from:CGFloat(0),through:editor.project.h,by:step) {ctx.move(to:CGPoint(x:0,y:y));ctx.addLine(to:CGPoint(x:editor.project.w,y:y))};ctx.strokePath()
            }
        }
        if !editor.playing {
            ctx.saveGState();ctx.setStrokeColor(UIColor(argb:palette.argb("primary")).cgColor);ctx.setLineWidth(1/scale)
            for x in (editor.project.studio?.guidesX ?? [])+editor.snapGuidesX{ctx.move(to:CGPoint(x:x,y:0));ctx.addLine(to:CGPoint(x:x,y:editor.project.h))}
            for y in (editor.project.studio?.guidesY ?? [])+editor.snapGuidesY{ctx.move(to:CGPoint(x:0,y:y));ctx.addLine(to:CGPoint(x:editor.project.w,y:y))}
            ctx.strokePath();ctx.restoreGState()
        }
        editor.renderer.draw(editor.playing ? (editor.originalPlay.display ?? editor.project):editor.canvasProject,in:ctx,background:false,includeReferences:!editor.playing);ctx.restoreGState()
        ctx.setStrokeColor(UIColor(argb:palette.argb("outlineVariant")).cgColor);ctx.setLineWidth(1/scale);ctx.stroke(page)
        if !editor.playing,let box=editor.bounds {
            ctx.setLineWidth(2/scale);ctx.setStrokeColor(UIColor(argb:palette.argb("primary")).cgColor);ctx.setFillColor(UIColor(argb:palette.argb("surface")).cgColor);ctx.stroke(box)
            let corners=[CGPoint(x:box.minX,y:box.minY),CGPoint(x:box.maxX,y:box.minY),CGPoint(x:box.maxX,y:box.maxY),CGPoint(x:box.minX,y:box.maxY)]
            for p in corners { let r=CGRect(x:p.x-7/scale,y:p.y-7/scale,width:14/scale,height:14/scale);let path=CGPath(roundedRect:r,cornerWidth:5/scale,cornerHeight:5/scale,transform:nil);ctx.addPath(path);ctx.drawPath(using:.fillStroke) }
            for (index,p) in [CGPoint(x:box.midX,y:box.minY),CGPoint(x:box.maxX,y:box.midY),CGPoint(x:box.midX,y:box.maxY),CGPoint(x:box.minX,y:box.midY)].enumerated(){let horizontal=index%2==0;let r=CGRect(x:p.x-(horizontal ? 10:4)/scale,y:p.y-(horizontal ? 4:10)/scale,width:(horizontal ? 20:8)/scale,height:(horizontal ? 8:20)/scale);ctx.addPath(CGPath(roundedRect:r,cornerWidth:4/scale,cornerHeight:4/scale,transform:nil));ctx.drawPath(using:.fillStroke)}
            ctx.move(to:CGPoint(x:box.midX,y:box.minY));ctx.addLine(to:CGPoint(x:box.midX,y:box.minY-36/scale));ctx.strokePath()
            let r=CGRect(x:box.midX-10/scale,y:box.minY-46/scale,width:20/scale,height:20/scale);ctx.fillEllipse(in:r);ctx.strokeEllipse(in:r)
            ctx.setFillColor(UIColor(argb:palette.argb("primary")).cgColor);ctx.fillEllipse(in:CGRect(x:box.midX-3/scale,y:box.minY-39/scale,width:6/scale,height:6/scale))
        }
        if abs(editor.canvasScale-scale)>0.001 { let value=scale;DispatchQueue.main.async{[weak self] in self?.editor.canvasScale=value} }
        ctx.restoreGState();positionRatioButton()
    }
    override func layoutSubviews(){super.layoutSubviews();positionRatioButton()}
    private func positionRatioButton(){
        guard !editor.playing,let box=editor.bounds,editor.selected.count != 1 || editor.selected.first?.kind != "TEXT" else{ratioButton.isHidden=true;return}
        ratioButton.isHidden=false
        ratioButton.frame=CGRect(x:min(max(8,origin.x+box.maxX*scale-36),bounds.width-48),y:min(max(74,origin.y+box.minY*scale-42),bounds.height-50),width:40,height:36)
        let locked=editor.selected.allSatisfy(\.ratioLock)
        ratioButton.setImage(UIImage(systemName:locked ? "lock.fill":"lock.open"),for:.normal)
        ratioButton.tintColor=UIColor(argb:palette.argb("primary"));ratioButton.backgroundColor=UIColor(argb:palette.argb("surfaceContainerHighest"))
        ratioButton.accessibilityValue=locked ? "Включено":"Выключено"
    }
    @objc private func toggleRatio(){let lock = !editor.selected.allSatisfy(\.ratioLock);editor.change{$0.ratioLock=lock};positionRatioButton()}
    private func gestureOn(_ id:String)->Bool {(UserDefaults.standard.object(forKey:"gesture_"+id) as? Bool) ?? true}
    @objc func twoTap(){if gestureOn("UNDO_TAP"){editor.undo()}}
    @objc func threeTap(){if gestureOn("REDO_TAP"){editor.redo()}}
    @objc func longPress(_ g:UILongPressGestureRecognizer){
        guard g.state == .began,!editor.playing else{return}
        let point=document(g.location(in:self)),hits=editor.editableNodes.reversed().filter{$0.visible && !$0.locked && !$0.mask && $0.contains(point)}
        if hits.count>1{editor.overlapIDs=hits.map(\.id);editor.showLayerPicker=true}
        else if let hit=hits.first,gestureOn("LONG_LAYER"){editor.choose(hit);editor.requestPanel="style"}
        else if hits.isEmpty,gestureOn("LONG_EMPTY"){editor.requestPanel="add"}
    }
    @objc func doubleTap(_ g:UITapGestureRecognizer) {let p=document(g.location(in:self));if let hit=editor.editableNodes.reversed().first(where:{$0.visible && !$0.locked && $0.contains(p)}),gestureOn("DOUBLE_LAYER"){editor.selection=[hit.id];if hit.kind=="TEXT"{editor.requestTextEdit=hit.id}else{editor.requestPanel="style"}}else if gestureOn("DOUBLE_FIT"){zoom=1;pan = .zero;setNeedsDisplay()}}
    @objc func tap(_ g:UITapGestureRecognizer) {
        let point=document(g.location(in:self))
        if let key=editor.eyedropTarget {
            if let color=editor.renderer.sample(editor.canvasProject,at:point){RecentColors.shared.record(color);editor.change{n in n[keyPath:key]=color;if key==\Node.fill{n.fillToken = -1};if key==\Node.stroke{n.strokeToken = -1}}}
            editor.eyedropTarget=nil;return
        }
        if editor.playing { editor.interact(at:point) }
        else { editor.choose(editor.editableNodes.reversed().first { $0.visible && !$0.locked && !$0.mask && $0.contains(point) }) }
    }
    @objc func panning(_ g:UIPanGestureRecognizer) {
        if g.state == .began { initialPan=pan }
        let t=g.translation(in:self);pan=CGPoint(x:initialPan.x+t.x,y:initialPan.y+t.y);setNeedsDisplay()
    }
    @objc func pinching(_ g:UIPinchGestureRecognizer) {
        if g.state == .began { initialZoom=zoom }
        zoom=min(12,max(0.15,initialZoom*g.scale));setNeedsDisplay()
    }
    func gestureRecognizer(_ gestureRecognizer:UIGestureRecognizer,shouldReceive touch:UITouch)->Bool {!(touch.view?.isDescendant(of:ratioButton) ?? false)}
    func gestureRecognizer(_ gestureRecognizer:UIGestureRecognizer,shouldRecognizeSimultaneouslyWith otherGestureRecognizer:UIGestureRecognizer)->Bool {
        let pair=[gestureRecognizer,otherGestureRecognizer]
        return pair.contains{$0 is UIPinchGestureRecognizer} && pair.contains{($0 as? UIPanGestureRecognizer)?.minimumNumberOfTouches==2}
    }
    @objc func drag(_ g:UIPanGestureRecognizer) {
        let p=document(g.location(in:self))
        if editor.playing { if g.state == .began { editor.originalPlay.begin(p) };if g.state == .changed { editor.originalPlay.drag(p) };if g.state == .ended || g.state == .cancelled { editor.originalPlay.end(p) };return }
        if g.state == .began {
            startPoint=p;mode="move";startNodes=editor.selected
            if let box=editor.bounds {
                let corners=[CGPoint(x:box.minX,y:box.minY),CGPoint(x:box.maxX,y:box.minY),CGPoint(x:box.maxX,y:box.maxY),CGPoint(x:box.minX,y:box.maxY),CGPoint(x:box.midX,y:box.minY),CGPoint(x:box.maxX,y:box.midY),CGPoint(x:box.midX,y:box.maxY),CGPoint(x:box.minX,y:box.midY)]
                if let i=corners.firstIndex(where:{hypot($0.x-p.x,$0.y-p.y)<18/scale}) { mode="resize";handle=i }
                else if hypot(box.midX-p.x,box.minY-36/scale-p.y)<18/scale { mode="rotate" }
                else if !box.insetBy(dx:-8/scale,dy:-8/scale).contains(p) { editor.choose(editor.editableNodes.reversed().first { $0.visible && !$0.locked && $0.contains(p) });startNodes=editor.selected }
            } else { editor.choose(editor.editableNodes.reversed().first { $0.visible && !$0.locked && $0.contains(p) });startNodes=editor.selected }
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
                    if [0,3,7].contains(handle) { target.origin.x += dx;target.size.width -= dx } else if [1,2,5].contains(handle) { target.size.width += dx }
                    if [0,1,4].contains(handle) { target.origin.y += dy;target.size.height -= dy } else if [2,3,6].contains(handle) { target.size.height += dy }
                    target.size.width=max(4,target.width);target.size.height=max(4,target.height)
                    if out[i].ratioLock && !(out[i].kind=="TEXT" && startNodes.count==1) { target.size.height=target.width*box.height/max(1,box.width) }
                    let sx=target.width/max(1,box.width),sy=target.height/max(1,box.height)
                    out[i].x=target.minX+(startNodes[i].x-box.minX)*sx;out[i].y=target.minY+(startNodes[i].y-box.minY)*sy
                    out[i].w=max(1,startNodes[i].w*sx);out[i].h=max(1,startNodes[i].h*sy)
                    if out[i].kind=="TEXT" {
                        if startNodes.count>1 {out[i].fontSize=startNodes[i].fontSize*min(sx,sy)}
                        editor.reflowText(&out[i])
                    }
                case "rotate":
                    let center=CGPoint(x:box.midX,y:box.midY)
                    let delta=(atan2(p.y-center.y,p.x-center.x)-atan2(startPoint.y-center.y,startPoint.x-center.x))*180 / .pi
                    let angle=editor.snap ? (delta/15).rounded()*15:delta
                    let rad=angle * .pi/180,x=startNodes[i].center.x-center.x,y=startNodes[i].center.y-center.y
                    out[i].x=center.x+x*cos(rad)-y*sin(rad)-out[i].w/2;out[i].y=center.y+x*sin(rad)+y*cos(rad)-out[i].h/2;out[i].rotation=startNodes[i].rotation+angle
                default:
                    out[i].x=startNodes[i].x+dx;out[i].y=startNodes[i].y+dy

                }
            }
            if mode=="move" && editor.snap {
                let offset=editor.snapOffset(out)
                for i in out.indices{out[i].x+=offset.x;out[i].y+=offset.y}
            }
            let map=Dictionary(uniqueKeysWithValues:out.map { ($0.id,$0) });editor.project.nodes=editor.project.nodes.map { map[$0.id] ?? $0 }
        }
        if g.state == .cancelled && !startNodes.isEmpty {
            let originals=Dictionary(uniqueKeysWithValues:startNodes.map{($0.id,$0)})
            editor.project.nodes=editor.project.nodes.map{originals[$0.id] ?? $0}
            _ = editor.undoStack.popLast()
        }
        if g.state == .ended{editor.finishLayoutGesture(original:startNodes)}
        if g.state == .ended || g.state == .cancelled { editor.saveSoon();startNodes=[];editor.snapGuidesX=[];editor.snapGuidesY=[] }
    }
}
