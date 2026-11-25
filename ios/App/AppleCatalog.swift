import SwiftUI

struct AppleCatalogBundle:Decodable{var light:[CatalogItem];var dark:[CatalogItem];var templates:[CatalogItem]}
enum AppleCatalog{
    static let bundle:AppleCatalogBundle=load("apple-catalog")
    static func variant(_ item:CatalogItem,dark:Bool)->CatalogItem{
        let choices=item.id=="ios" ? bundle.templates:(dark ? bundle.dark:bundle.light)
        guard var result=choices.first(where:{$0.id==item.id && $0.project.tone.dark==dark}) else{return item}
        prepare(&result.project,id:result.id);DefaultLinks.install(&result.project,componentID:result.id);return result
    }
    // v0.10 saved the Material engine's geometry into Apple switches. Repair
    // that specific signature once when reopening an affected project.
    static func repairLegacySwitches(_ project:inout Project){
        let groups=Dictionary(grouping:project.nodes.indices.filter{project.nodes[$0].group.contains("~ios-")},by:{project.nodes[$0].group})
        for indices in groups.values {
            guard let rail=indices.first(where:{project.nodes[$0].widget.hasPrefix("switch:track/")}),
                  let knob=indices.first(where:{project.nodes[$0].widget=="switch:thumb"}),
                  [Int64(0),16].contains(project.nodes[rail].fillToken) else{continue}
            var track=project.nodes[rail],thumb=project.nodes[knob]
            let on=track.fillToken==0
            if on{track.x+=1;track.y+=1;track.w=max(1,track.w-2);track.h=max(1,track.h-2)}
            let scale=track.h/28,colors=track.widget.split(separator:"/")
            if colors.count>2,let color=Int64(colors[on ? 2:1]){track.fill=Int64(Int32(truncatingIfNeeded:color))}
            track.fillToken = -1;track.strokeToken = -1;track.strokeWidth=0;track.stroke=0;track.corner=track.h/2
            track.widget=track.widget.replacingOccurrences(of:"switch:track",with:"switch:itrack")
            let source=(project.tone.dark ? bundle.dark:bundle.light).first{$0.id=="ios-switch-on"}?.project.nodes.first{$0.widget.hasPrefix("switch:ithumb")}
            thumb.kind="RECT";thumb.w=40*scale;thumb.h=24*scale;thumb.corner=12*scale
            thumb.x=track.x+2*scale+(on ? track.w-thumb.w-4*scale:0);thumb.y=track.y+2*scale
            thumb.fill=source?.fill ?? -251658241;thumb.fillToken = -1;thumb.strokeToken = -1
            thumb.stroke=source?.stroke ?? -2130706433;thumb.strokeWidth=0.5*scale
            thumb.widget="switch:ithumb/0/0"
            project.nodes[rail]=track;project.nodes[knob]=thumb
        }
    }
    static func prepare(_ project:inout Project,id:String){
        guard id=="ios" || id.hasPrefix("ios-") else{return}
        repairLegacySwitches(&project)
        if id=="ios-slider",project.nodes.count>=3{
            project.nodes[0].widget="slider:track";project.nodes[1].widget="slider:active";project.nodes[2].widget="slider:thumb"
        }
        if id=="ios-segmented",project.nodes.count>=5{
            project.nodes[1].widget="pick:ind"
            for i in 2..<5{project.nodes[i].widget="pick:i\(i-2)/4278190080/4285295728"}
        }
        // Keep the APK's iOS widget roles: the shared v44 engine only understands
        // Material roles, so compatibility aliases belong at the bridge boundary.
        let renderer=DocumentRenderer(root:FileManager.default.temporaryDirectory)
        for i in project.nodes.indices where project.nodes[i].kind=="TEXT" && (id != "ios" || project.nodes[i].group.contains("~ios-")) {
            var n=project.nodes[i]
            guard n.extras?.appleTextPrepared != true else{continue}
            let component=id=="ios" ? (n.group.components(separatedBy:"~").last ?? id):id
            let oldWidth=n.w
            let groupX=project.nodes.filter{$0.group==n.group}.map(\.x).min() ?? 0
            if ["search","dialog_text","message","cancel","ok"].contains(n.text){n.text=tr(n.text)}
            let font=renderer.font(n)
            n.w=max(1,ceil(n.text.components(separatedBy:"\n").map{($0 as NSString).size(withAttributes:[.font:font]).width}.max() ?? 0)+2)
            n.h=max(1,CGFloat(n.text.components(separatedBy:"\n").count)*n.fontSize*1.25)
            let centered=component.hasPrefix("ios-btn-") || ["ios-segmented","ios-nav-bar","ios-tab-bar","ios-alert","ios-action-sheet","ios-app-icon"].contains(component) || component=="ios-sheet" && n.x-groupX>40
            if centered {n.x+=(oldWidth-n.w)/2}
            else if component=="ios-list-group",n.x-groupX>100{n.x+=oldWidth-n.w}
            var extras=n.extras ?? LayerExtras();extras.appleTextPrepared=true;extras.hugHeight=false;n.extras=extras
            project.nodes[i]=n
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
    static func isApple(_ node:Node)->Bool {
        node.group.contains("~ios-") || node.group=="apple" || node.widget.hasPrefix("switch:i")
    }
    static func isTrack(_ node:Node)->Bool {node.widget.hasPrefix("switch:track") || node.widget.hasPrefix("switch:itrack")}
    static func isThumb(_ node:Node)->Bool {node.widget=="switch:thumb" || node.widget.hasPrefix("switch:ithumb")}
    static func initial(_ project:Project,values:inout [String:Double]){
        let groups=Dictionary(grouping:project.nodes.filter(isApple),by:\.group)
        for (group,nodes) in groups {
            if let track=nodes.first(where:isTrack),let thumb=nodes.first(where:isThumb){values[group]=thumb.center.x>track.center.x ? 1:0}
        }
    }
    static func apply(_ project:inout Project,base:Project,values:[String:Double]){
        let groups=Dictionary(grouping:base.nodes.filter(isApple),by:\.group)
        let indices=Dictionary(project.nodes.indices.map{(project.nodes[$0].id,$0)},uniquingKeysWith:{a,_ in a})
        for (group,nodes) in groups {
            guard let raw=values[group] else{continue}
            let value=min(1,max(0,raw))
            if let track=nodes.first(where:isTrack),let thumb=nodes.first(where:isThumb){
                let parts=track.widget.split(separator:"/")
                let off=parts.count>1 ? Int64(parts[1]) ?? track.fill:track.fill
                let on=parts.count>2 ? Int64(parts[2]) ?? track.fill:track.fill
                if let i=indices[track.id]{project.nodes[i]=track;project.nodes[i].fill=mix(off,on,value)}
                if let i=indices[thumb.id]{
                    // The APK stretches the thumb by four dp halfway through the
                    // transition. Scale those dimensions with the component.
                    let scale=track.h/28,inset=2*scale,t=CGFloat(value)
                    let stretch=(1-abs(2*t-1))*4*scale
                    project.nodes[i]=thumb
                    project.nodes[i].x=track.x+inset+(track.w-thumb.w-2*inset)*t-t*stretch
                    project.nodes[i].w=thumb.w+stretch
                }
            }
            let pickNodes=nodes.filter{$0.widget.hasPrefix("pick:i") && !$0.widget.hasPrefix("pick:ind")}
            let items=Dictionary(grouping:pickNodes,by:{Int($0.widget.dropFirst(6).split(separator:"/").first ?? "") ?? 0})
            if !items.isEmpty {
                let selection=min(Double(max(0,items.count-1)),max(0,raw))
                let boxes=items.mapValues{members in members.reduce(CGRect.null){$0.union($1.rect)}}
                let low=Int(floor(selection)),high=min(items.count-1,low+1),fraction=CGFloat(selection-Double(low))
                if let indicator=nodes.first(where:{$0.widget=="pick:ind"}),let i=indices[indicator.id],let a=boxes[low],let b=boxes[high]{
                    project.nodes[i]=indicator
                    project.nodes[i].x=a.midX+(b.midX-a.midX)*fraction-indicator.w/2
                }
                for (index,members) in items {
                    for member in members {
                        let colors=member.widget.split(separator:"/")
                        guard colors.count>2,let on=Int64(colors[1]),let off=Int64(colors[2]),let i=indices[member.id] else{continue}
                        project.nodes[i]=member
                        project.nodes[i].fill=mix(off,on,max(0,1-abs(selection-Double(index))))
                    }
                }
            }
            if let track=nodes.first(where:{$0.widget=="slider:track"}),let active=nodes.first(where:{$0.widget=="slider:active"}),let thumb=nodes.first(where:{$0.widget=="slider:thumb"}){
                if let i=indices[track.id]{project.nodes[i]=track}
                if let i=indices[active.id]{project.nodes[i]=active;project.nodes[i].w=track.w*CGFloat(value)}
                if let i=indices[thumb.id]{project.nodes[i]=thumb;project.nodes[i].x=track.x+track.w*CGFloat(value)-thumb.w/2}
            }
        }
    }
    private static func mix(_ a:Int64,_ b:Int64,_ fraction:Double)->Int64{
        let a=UInt32(truncatingIfNeeded:a),b=UInt32(truncatingIfNeeded:b);var color:UInt32=0
        for shift in [0,8,16,24]{let from=Double((a>>shift)&255),to=Double((b>>shift)&255);color |= UInt32(min(255,max(0,from+(to-from)*fraction))) << shift}
        return Int64(Int32(bitPattern:color))
    }
}
