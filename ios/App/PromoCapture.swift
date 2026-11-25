import SwiftUI

/// Deterministic fixtures on the isolated promo branch, never merged into the app.
enum PromoCapture {
    static var enabled:Bool{ProcessInfo.processInfo.arguments.contains("--promo-capture")}
    static var mode:String{let args=ProcessInfo.processInfo.arguments;guard let i=args.firstIndex(of:"--promo-mode"),i+1<args.count else{return "home"};return args[i+1]}
    static var panel:String?{switch mode{case "add","shapes","components":return "add";case "style":return "document";case "layers":return "layers";default:return nil}}
    static func configure(){guard enabled else{return};let d=UserDefaults.standard;d.set(2,forKey:"appearance");d.set(0,forKey:"uiStyle");d.set(2,forKey:"accent");d.set(Int(0xff486eb1),forKey:"accentSeed");d.set(false,forKey:"glass")}
    static func project(_ id:String)->Project {
        var p=Catalog.shared.templates.first{$0.id==id}!.project
        p.id="promo-"+id;p.name=["music":"Плеер","home":"Главная","weather":"Погода","settings":"Настройки"][id] ?? p.name
        p.tone=ToneGenerator.scheme(seed:0xff486eb1,dark:true);p.bg=p.tone.colors[12]
        for i in p.nodes.indices{
            if p.tone.colors.indices.contains(Int(p.nodes[i].fillToken)){p.nodes[i].fill=p.tone.colors[Int(p.nodes[i].fillToken)]}
            if p.tone.colors.indices.contains(Int(p.nodes[i].strokeToken)){p.nodes[i].stroke=p.tone.colors[Int(p.nodes[i].strokeToken)]}
            if p.nodes[i].kind=="TEXT"{let old=p.nodes[i].text;p.nodes[i].text=["Название трека":"Midnight Blue","Название группы":"Vexel Studio"][old] ?? old}
        }
        DefaultLinks.allPages(&p)
        if let shape=p.nodes.first(where:{$0.kind=="SHAPE"}),let source=p.links.first(where:{$0.mode=="playback"})?.sourceID{
            var spin=InteractionLink();spin.sourceID=source;spin.targetID=shape.id;spin.property="rotation";spin.value=360;spin.duration=4;spin.easing="easeInOut";p.links.append(spin)
        }
        if mode=="play"{
            for i in p.links.indices where p.links[i].mode=="playback"{p.links[i].event="start";p.links[i].autoplay=true;p.links[i].duration=16}
            if let shape=p.nodes.first(where:{$0.kind=="SHAPE"}){var spin=InteractionLink();spin.sourceID=shape.id;spin.targetID=shape.id;spin.event="start";spin.property="rotation";spin.value=360;spin.duration=8;spin.easing="linear";spin.repeats=true;p.links.append(spin)}
        }
        p.syncPage();return p
    }
}

struct PromoCaptureRoot:View {
    let store:ProjectStore
    @StateObject private var editor:Editor
    @State private var seeded=false
    init(store:ProjectStore){self.store=store;_editor=StateObject(wrappedValue:Editor(PromoCapture.project("music"),store:store))}
    var body:some View {
        Group{
            switch PromoCapture.mode{
            case "home":ProjectsView()
            case "new":NewProjectView{_ in}
            case "links":InteractionEditorPanel(editor:editor,sourceID:editor.project.links.first(where:{$0.mode=="playback"})?.sourceID ?? editor.project.nodes[0].id)
            case "color":ZStack{EditorCanvas(editor:editor);Color.black.opacity(0.35).ignoresSafeArea();QColorDialog(initial:editor.project.tone.colors[0],cancel:{},confirm:{_ in}).padding(.horizontal,28)}
            default:EditorScreen(project:editor.project,store:store)
            }
        }.task{if PromoCapture.mode=="home" && !seeded{seeded=true;for id in ["home","weather","settings","music"]{try? store.save(PromoCapture.project(id))}}}
    }
}
