import SwiftUI

struct AppleCatalogBundle:Decodable{var light:[CatalogItem];var dark:[CatalogItem];var templates:[CatalogItem]}
enum AppleCatalog{
    static let bundle:AppleCatalogBundle=load("apple-catalog")
    static func variant(_ item:CatalogItem,dark:Bool)->CatalogItem{
        let choices=item.id=="ios" ? bundle.templates:(dark ? bundle.dark:bundle.light)
        guard var result=choices.first(where:{$0.id==item.id && $0.project.tone.dark==dark}) else{return item}
        prepare(&result.project,id:result.id);DefaultLinks.install(&result.project,componentID:result.id);return result
    }
    static func prepare(_ project:inout Project,id:String){
        if id=="ios-slider",project.nodes.count>=3{
            project.nodes[0].widget="slider:track";project.nodes[1].widget="slider:active";project.nodes[2].widget="slider:thumb"
        }
        if id=="ios-segmented",project.nodes.count>=5{
            project.nodes[1].widget="pick:ind"
            for i in 2..<5{project.nodes[i].widget="pick:i\(i-2)/4278190080/4285295728"}
        }
        for i in project.nodes.indices{
            if project.nodes[i].widget.hasPrefix("switch:itrack"){project.nodes[i].widget=project.nodes[i].widget.replacingOccurrences(of:"switch:itrack",with:"switch:track")}
            if project.nodes[i].widget.hasPrefix("switch:ithumb"){project.nodes[i].widget="switch:thumb"}
        }
    }
}
enum AndroidTextSpans{
    static func parse(_ source:String)->[TextRun]{source.split(separator:";").compactMap{part in
        let fields=part.split(separator:",");guard fields.count==3,let start=Int(fields[0]),let end=Int(fields[1]),let color=Int64(fields[2]),start>=0,end>start else{return nil}
        return TextRun(start:start,length:end-start,color:Int64(Int32(truncatingIfNeeded:color)))
    }}
    static func format(_ runs:[TextRun])->String{runs.compactMap{run in guard let color=run.color else{return nil};return "\(run.start),\(run.start+run.length),\(UInt32(truncatingIfNeeded:color))"}.joined(separator:";")}
}
struct LiquidLayerControls:View{
    @ObservedObject var editor:Editor
    let node:Node
    var body:some View{VStack(alignment:.leading,spacing:12){
        QToggle("Жидкое стекло",isOn:Binding(get:{node.liquid>0},set:{value in editor.change{$0.liquid=value ? 0.8:0;if value && $0.fillOpacity>0.7{$0.fillOpacity=0.25}}}))
        if node.liquid>0{
            QSlider(value:Binding(get:{Double(node.liquid)},set:{v in editor.change{$0.liquid=CGFloat(v)}}),range:0...1)
            HStack{Button("Прозрачное"){preset(0.8,3,0.14)};Button("Жидкое"){preset(1,5,0.23)};Button("Матовое"){preset(0.4,22,0.5)}}.font(qfont(13))
            Text("Преломляет фон под слоем. Лучше всего видно поверх картинки или цветных объектов.").font(qfont(12))
        }
    }}
    private func preset(_ liquid:CGFloat,_ blur:CGFloat,_ opacity:CGFloat){editor.change{$0.liquid=liquid;$0.blur=blur;$0.fillOpacity=opacity}}
}
struct ProjectGlassControls:View{
    @ObservedObject var editor:Editor
    var body:some View{LinkChoiceField(title:"Стекло в проекте",selection:Binding(get:{String(editor.project.glassMode ?? -1)},set:{v in editor.edit{$0.glassMode=Int(v)==(-1) ? nil:Int(v)}}),items:[("-1","Как в настройках"),("0","Авто"),("1","Преломление"),("2","Только размытие")])}
}
struct TextFrameControls:View{
    @ObservedObject var editor:Editor
    let node:Node
    var body:some View{VStack(alignment:.leading,spacing:10){
        QToggle("Фиксировать ширину",isOn:Binding(get:{node.fixW},set:{v in editor.change{$0.fixW=v;var x=$0.extras ?? LayerExtras();x.hugWidth = !v;$0.extras=x}}))
        QToggle("Фиксировать высоту и подбирать размер",isOn:Binding(get:{node.fixH},set:{v in editor.change{$0.fixH=v}}))
        if node.fixH{QNumber(title:"Высота рамки",value:Binding(get:{node.h},set:{v in editor.change{$0.h=max(1,v)}}))}
        LinkChoiceField(title:"По вертикали",selection:Binding(get:{String(node.textVAlign)},set:{v in editor.change{$0.textVAlign=Int(v) ?? 0}}),items:[("0","Сверху"),("1","По центру"),("2","Снизу")])
    }}
}
enum AppleControls {
    static func initial(_ project:Project,values:inout [String:Double]){
        let groups=Dictionary(grouping:project.nodes.filter{$0.group.contains("~ios-")},by:\.group)
        for (group,nodes) in groups where group.contains("ios-switch") || group.contains("ios-list-switch"){
            if let track=nodes.first(where:{$0.widget.hasPrefix("switch:track")}),let thumb=nodes.first(where:{$0.widget=="switch:thumb"}){values[group]=thumb.center.x>track.center.x ? 1:0}
        }
    }
    static func apply(_ project:inout Project,base:Project,values:[String:Double]){
        let groups=Dictionary(grouping:base.nodes.filter{$0.group.contains("~ios-")},by:\.group)
        for (group,nodes) in groups{
            let value=min(1,max(0,values[group] ?? 0))
            if let track=nodes.first(where:{$0.widget.hasPrefix("switch:track")}),let thumb=nodes.first(where:{$0.widget=="switch:thumb"}){
                let parts=track.widget.split(separator:"/");let off=parts.count>1 ? Int64(parts[1]) ?? track.fill:track.fill;let on=parts.count>2 ? Int64(parts[2]) ?? track.fill:track.fill
                if let i=project.nodes.firstIndex(where:{$0.id==track.id}){project.nodes[i]=track;project.nodes[i].fill=mix(off,on,value)}
                if let i=project.nodes.firstIndex(where:{$0.id==thumb.id}){project.nodes[i]=thumb;project.nodes[i].x=track.x+2+(track.w-thumb.w-4)*CGFloat(value)}
            }
            if group.hasSuffix("ios-slider"),let track=nodes.first(where:{$0.widget=="slider:track"}),let active=nodes.first(where:{$0.widget=="slider:active"}),let thumb=nodes.first(where:{$0.widget=="slider:thumb"}){
                if let i=project.nodes.firstIndex(where:{$0.id==track.id}){project.nodes[i]=track}
                if let i=project.nodes.firstIndex(where:{$0.id==active.id}){project.nodes[i]=active;project.nodes[i].w=track.w*CGFloat(value)}
                if let i=project.nodes.firstIndex(where:{$0.id==thumb.id}){project.nodes[i]=thumb;project.nodes[i].x=track.x+track.w*CGFloat(value)-thumb.w/2}
            }
        }
    }
    private static func mix(_ a:Int64,_ b:Int64,_ fraction:Double)->Int64{
        let a=UInt32(truncatingIfNeeded:a),b=UInt32(truncatingIfNeeded:b);var color:UInt32=0
        for shift in [0,8,16,24]{let from=Double((a>>shift)&255),to=Double((b>>shift)&255);color |= UInt32(min(255,max(0,from+(to-from)*fraction))) << shift}
        return Int64(Int32(bitPattern:color))
    }
}
