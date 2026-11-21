import SwiftUI

@MainActor final class Editor: ObservableObject {
    @Published var project:Project
    @Published var selection:Set<String>=[]
    @Published var playing=false
    @Published var multiSelect=false
    @Published var snap=true
    @Published var fitVersion=0
    @Published var requestPanel:String?
    @Published var requestTextEdit:String?
    @Published var eyedropTarget:WritableKeyPath<Node,Int64>?
    @Published var showGrid=true
    @Published var canvasScale:CGFloat=1
    @Published var error:String?
    var undoStack:[Project]=[],redoStack:[Project]=[]
    let store:ProjectStore
    let renderer:DocumentRenderer
    lazy var originalPlay=OriginalPlayRuntime(editor:self)
    private var pendingSave:Task<Void,Never>?
    init(_ p:Project,store:ProjectStore) { project=p;self.store=store;renderer=DocumentRenderer(root:store.root) }
    var selected:[Node] { project.nodes.filter { selection.contains($0.id) } }
    var bounds:CGRect? { selected.reduce(nil as CGRect?) { $0?.union($1.rect) ?? $1.rect } }
    func checkpoint() { undoStack.append(project);if undoStack.count>80 { undoStack.removeFirst() };redoStack=[] }
    func saveSoon() {
        pendingSave?.cancel()
        pendingSave=Task { [weak self] in
            try? await Task.sleep(for:.milliseconds(350))
            guard !Task.isCancelled,let self else { return };saveNow()
        }
    }
    func pendingSaveForTestingCleanup() { pendingSave?.cancel() }
    func saveNow() { do { try store.save(project) } catch { self.error=error.localizedDescription } }
    func edit(_ block:(inout Project)->Void) { checkpoint();block(&project);saveSoon() }
    func reflowText(_ node:inout Node) {
        guard node.kind=="TEXT" else{return}
        node.h=TextLayout(node,font:renderer.font(node)).height
    }
    func commitText(_ id:String,text:String) {
        guard let index=project.nodes.firstIndex(where:{$0.id==id && $0.kind=="TEXT"}),project.nodes[index].text != text else{return}
        edit { p in p.nodes[index].text=text;reflowText(&p.nodes[index]) }
    }
    func change(_ block:(inout Node)->Void) {
        edit { p in for i in p.nodes.indices where selection.contains(p.nodes[i].id) {
            let old=p.nodes[i];block(&p.nodes[i]);let n=p.nodes[i]
            if n.kind=="TEXT" && (old.text != n.text || old.w != n.w || old.fontSize != n.fontSize || old.font != n.font || old.weight != n.weight) {reflowText(&p.nodes[i])}
        } }
    }
    func undo() { guard let old=undoStack.popLast() else { return };redoStack.append(project);project=old;selection.formIntersection(Set(project.nodes.map(\.id)));saveSoon() }
    func redo() { guard let next=redoStack.popLast() else { return };undoStack.append(project);project=next;saveSoon() }
    func choose(_ node:Node?) {
        guard let n=node else { if !multiSelect { selection=[] };return }
        let ids=Set(project.nodes.filter { n.group.isEmpty ? $0.id==n.id : $0.group==n.group }.map(\.id))
        if multiSelect { if ids.isSubset(of:selection) { selection.subtract(ids) } else { selection.formUnion(ids) } }
        else { selection = !n.group.isEmpty && ids.isSubset(of:selection) ? [n.id]:ids }
    }
    func add(_ kind:String,shape:ShapeItem?=nil) {
        var n=Node();n.kind=kind;n.name=shape?.name ?? ["RECT":"Прямоугольник","ELLIPSE":"Эллипс","TEXT":"Текст"][kind] ?? "Фигура"
        n.w=kind=="RECT" ? 160:128;n.h=kind=="RECT" ? 96:128;n.corner=kind=="RECT" ? 16:0
        n.fill=project.tone.colors.first ?? -16749974;n.shapeId=shape?.id ?? ""
        if kind=="TEXT" { n.text="Новый текст";n.fontSize=28;n.w=180;n.h=40;n.fill = -14869216 }
        if kind=="TEXT" { n.ratioLock=false;reflowText(&n) }
        n.x=(project.w-n.w)/2;n.y=(project.h-n.h)/2
        edit { $0.nodes.append(n) };selection=[n.id]
        if kind=="TEXT" { requestTextEdit=n.id }
    }
    func addComponent(_ item:CatalogItem) {
        let g=UUID().uuidString+"~"+item.id,ox=(project.w-item.project.w)/2,oy=(project.h-item.project.h)/2
        let nodes=item.project.nodes.map { original in var n=original;n.id=UUID().uuidString;n.x += ox;n.y += oy;n.group=g
            if project.tone.colors.indices.contains(Int(n.fillToken)) { n.fill=project.tone.colors[Int(n.fillToken)] }
            if project.tone.colors.indices.contains(Int(n.strokeToken)) { n.stroke=project.tone.colors[Int(n.strokeToken)] };return n }
        edit { $0.nodes += nodes };selection=Set(nodes.map(\.id))
    }
    func addImage(_ data:Data,name:String) throws {
        guard let image=UIImage(data:data),image.size.width>0,image.size.height>0 else { throw CocoaError(.fileReadCorruptFile) }
        let file=UUID().uuidString+".png"
        guard let png=image.pngData() else { throw CocoaError(.fileReadCorruptFile) }
        try png.write(to:store.assets.appendingPathComponent(file),options:.atomic)
        var n=Node();n.kind="IMAGE";n.name=name;n.asset=file
        let s=min(project.w*0.8/image.size.width,project.h*0.8/image.size.height,1)
        n.w=image.size.width*s;n.h=image.size.height*s;n.x=(project.w-n.w)/2;n.y=(project.h-n.h)/2;n.ratioLock=true
        edit { $0.nodes.append(n) };selection=[n.id]
    }
    func duplicate() {
        var groups:[String:String]=[:]
        let copies=selected.map { old in var n=old;n.id=UUID().uuidString;n.x += 16;n.y += 16
            if !n.group.isEmpty { if groups[n.group]==nil { groups[n.group]=UUID().uuidString+(n.group.contains("~") ? "~"+n.group.components(separatedBy:"~").last! : "") };n.group=groups[n.group]! };return n }
        edit { $0.nodes += copies };selection=Set(copies.map(\.id))
    }
    func remove() { edit { $0.nodes.removeAll { selection.contains($0.id) } };selection=[] }
    func group() { let id=UUID().uuidString;change { $0.group=id } }
    func ungroup() { change { $0.group="" } }
    func front(_ front:Bool) { edit { p in let selected=p.nodes.filter { selection.contains($0.id) };p.nodes.removeAll { selection.contains($0.id) };if front { p.nodes += selected } else { p.nodes=selected+p.nodes } } }
    func align(_ mode:String) {
        guard let box=bounds else { return }
        let target=selected.count==1 ? CGRect(x:0,y:0,width:project.w,height:project.h):box
        change { n in switch mode {
        case "left":n.x=target.minX
        case "right":n.x=target.maxX-n.w
        case "top":n.y=target.minY
        case "bottom":n.y=target.maxY-n.h
        case "centerX":n.x=target.midX-n.w/2
        case "centerY":n.y=target.midY-n.h/2
        default:break
        } }
    }
    func distribute(_ horizontal:Bool) {
        let nodes=selected.sorted { horizontal ? $0.x<$1.x:$0.y<$1.y }
        guard nodes.count>2,let first=nodes.first,let last=nodes.last else { return }
        let total=nodes.reduce(CGFloat(0)) { $0+(horizontal ? $1.w:$1.h) }
        let span=horizontal ? last.x+last.w-first.x:last.y+last.h-first.y
        let gap=(span-total)/CGFloat(nodes.count-1)
        var position=horizontal ? first.x:first.y,positions:[String:CGFloat]=[:]
        for n in nodes { positions[n.id]=position;position += (horizontal ? n.w:n.h)+gap }
        change { n in if let p=positions[n.id] { if horizontal { n.x=p } else { n.y=p } } }
    }
    func boolean(_ op:String) {
        let list=selected.filter { ["RECT","ELLIPSE","SHAPE","PATH"].contains($0.kind) }
        guard list.count>=2 else { return }
        var path=VectorPath.world(list[0])
        for n in list.dropFirst() {
            let other=VectorPath.world(n)
            switch op {
            case "intersection":path=path.intersection(other,using:.winding)
            case "subtract":path=path.subtracting(other,using:.winding)
            case "xor":path=path.symmetricDifference(other,using:.winding)
            default:path=path.union(other,using:.winding)
            }
        }
        guard let node=VectorPath.node(path,style:list[0]) else { remove();return }
        edit { p in p.nodes.removeAll { selection.contains($0.id) };p.nodes.append(node) };selection=[node.id]
    }
    func echo() {
        let list=selected
        edit { p in for src in list {
            guard let index=p.nodes.firstIndex(where:{$0.id==src.id}) else { continue }
            var copies:[Node]=[]
            for i in (1...5).reversed() {
                let f=1+CGFloat(i)*0.06
                var n=src;n.id=UUID().uuidString;n.name += " эхо \(i)";n.w *= f;n.h *= f;n.x=src.center.x-n.w/2;n.y=src.center.y-n.h/2;n.rotation += CGFloat(i)*3;n.opacity *= 1-CGFloat(i)*0.15;n.stroke=n.fill;n.fill=0;n.strokeWidth=1.5;n.fillToken = -1;n.gradKind=0;n.blur=0;n.softBlur=0;n.shadowBlur=0
                copies.append(n)
            };p.nodes.insert(contentsOf:copies,at:index)
        } }
    }
    func page(_ index:Int) { guard project.pages.indices.contains(index) else { return };edit { p in p.syncPage();p.active=index;p.nodes=p.pages[index].nodes };selection=[];fitVersion += 1 }
    func addPage() { edit { p in if p.pages.isEmpty { var first=Page();first.name="Экран 1";first.nodes=p.nodes;p.pages=[first] };p.syncPage();var pg=Page();pg.name="Экран \(p.pages.count+1)";p.pages.append(pg);p.active=p.pages.count-1;p.nodes=[] };selection=[] }
    func applyTone(_ color:Int64,dark:Bool) {
        let tone=ToneGenerator.scheme(seed:color,dark:dark)
        edit { p in p.tone=tone
            func update(_ a:[Node])->[Node] { a.map { n in var n=n;if tone.colors.indices.contains(Int(n.fillToken)) { n.fill=tone.colors[Int(n.fillToken)] };if tone.colors.indices.contains(Int(n.strokeToken)) { n.stroke=tone.colors[Int(n.strokeToken)] };return n } }
            p.nodes=update(p.nodes);p.pages=p.pages.map { pg in var pg=pg;pg.nodes=update(pg.nodes);return pg }
            if p.bgToken>=0 && tone.colors.indices.contains(p.bgToken) { p.bg=tone.colors[p.bgToken] }
        }
    }
    func interact(at point:CGPoint) { originalPlay.tap(point) }
    func togglePlay() { if playing { originalPlay.stop() } else { originalPlay.start() } }
}
