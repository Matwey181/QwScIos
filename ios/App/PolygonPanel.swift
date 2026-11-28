import SwiftUI

struct PolygonPanel:View{
    @ObservedObject var editor:Editor
    @Environment(\.dismiss) private var dismiss
    @Environment(\.q) private var q
    @State private var sides=5.0
    @State private var star=false
    @State private var depth=0.5
    private var contour:CGPath{
        let p=CGMutablePath(),n=max(3,Int(sides.rounded())),count=star ? n*2:n
        for i in 0..<count{let a=Double(i)*2 * .pi/Double(count) - .pi/2,r=star && i%2==1 ? depth*0.5:0.5,point=CGPoint(x:0.5+cos(a)*r,y:0.5+sin(a)*r);if i==0{p.move(to:point)}else{p.addLine(to:point)}};p.closeSubpath();return p
    }
    var body:some View{
        NavigationStack{VStack(alignment:.leading,spacing:18){
            GeometryReader{g in let size=min(g.size.width,g.size.height);var transform=CGAffineTransform(scaleX:size,y:size);Path(contour.copy(using:&transform) ?? contour).fill(q.color("primary")).frame(maxWidth:.infinity,maxHeight:.infinity)}.frame(height:220)
            Text("Вершин: \(Int(sides.rounded()))").font(qfont(16,.semibold))
            QSlider(value:$sides,range:3...16)
            QToggle("Звезда",isOn:$star)
            if star{Text("Глубина: \(Int(depth*100))%").font(qfont(14));QSlider(value:$depth,range:0.1...0.9)}
            LinkPill(title:"Добавить",icon:"plus",prominent:true){
                var n=Node();n.kind="PATH";n.name=star ? "Звезда":"Многоугольник";n.path=VectorPath.string(contour);n.w=160;n.h=160;n.x=(editor.project.w-160)/2;n.y=(editor.project.h-160)/2;n.fill=editor.project.tone.colors.first ?? -16749974
                editor.edit{$0.nodes.append(n)};editor.selection=[n.id];dismiss()
            }
            Spacer()
        }.padding(24).background(q.color("surface")).navigationTitle("Многоугольник").toolbar{ToolbarItem(placement:.topBarTrailing){Button("Отмена"){dismiss()}}}}
    }
}
