import SwiftUI

struct OriginalMorph:Shape {
    var start:[CGFloat]
    var end:[CGFloat]
    var progress:CGFloat
    var animatableData:CGFloat {get{progress}set{progress=newValue}}
    func path(in rect:CGRect)->Path {
        guard start.count==end.count,start.count>=8 else{return Path(ellipseIn:rect)}
        var path=Path()
        func point(_ i:Int)->CGPoint{CGPoint(x:(start[i]+(end[i]-start[i])*progress)*rect.width,y:(start[i+1]+(end[i+1]-start[i+1])*progress)*rect.height)}
        path.move(to:point(0))
        for i in stride(from:0,to:start.count-7,by:8){path.addCurve(to:point(i+6),control1:point(i+2),control2:point(i+4))}
        path.closeSubpath();return path
    }
}
struct OriginalAddShape:View {
    var open:Bool
    @Environment(\.q) var q
    @State private var start:[CGFloat]=[]
    @State private var end:[CGFloat]=[]
    var body:some View {OriginalMorph(start:start,end:end,progress:open ? 1:0).fill(q.color("primary")).animation(.spring(response:0.4,dampingFraction:0.6),value:open).task {if let result=try? OriginalCore.shared.request(["op":"morph","from":"cookie-9","to":"soft-burst"]),let a=result["start"] as? [NSNumber],let b=result["end"] as? [NSNumber]{start=a.map{CGFloat(truncating:$0)};end=b.map{CGFloat(truncating:$0)}}}}
}
struct BlendPanel:View {
    @ObservedObject var editor:Editor
    var close:()->Void
    @Environment(\.q) var q
    @State private var steps=5.0
    private var mids:[Node]{let nodes=editor.selected;guard nodes.count==2 else{return []};let a=nodes[0],b=nodes[1];return (try? OriginalCore.shared.project("blend",project:editor.project,values:["a":a.id,"b":b.id,"steps":Int(steps),"samples":[a.id:VectorPath.sample(a),b.id:VectorPath.sample(b)]]))?.nodes ?? []}
    var body:some View{VStack(alignment:.leading,spacing:16){Text("Переход между формами").font(qfont(24,.semibold));EffectPreview(nodes:editor.selected+mids,renderer:editor.renderer).frame(height:180).qSurface(20,"surfaceContainerHighest");HStack{Text("Промежуточные шаги");Spacer();Text("\(Int(steps))")}.font(qfont(14));QSlider(value:$steps,range:1...30,step:1);Text("Промежуточные фигуры станут обычными слоями.").font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"));HStack(spacing:24){Spacer();Button("Отмена",action:close);Button("Применить"){let nodes=mids;editor.edit{$0.nodes+=nodes};close()}.disabled(mids.isEmpty)}.font(qfont(14,.semibold)).foregroundStyle(q.color("primary"))}.padding(24).qSurface(28,"surfaceContainerHigh")}
}
