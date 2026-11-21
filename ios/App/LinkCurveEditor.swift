import SwiftUI

struct LinkCurveEditor:View {
    @Binding var easing:String
    @Environment(\.q) private var q
    @State private var points:[Double]=[0.2,0,0,1]
    private var custom:Bool {easing.hasPrefix("bezier:")}
    private var encoded:String {"bezier:"+points.map{String(format:"%.4f",$0)}.joined(separator:",")}
    var body:some View {
        VStack(alignment:.leading,spacing:12) {
            ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){
                ForEach(InteractionLink.easings,id:\.0){item in QChip(title:item.1,selected:easing==item.0){easing=item.0}}
                QChip(title:"Свой график",selected:custom){easing=encoded}
            }}
            GeometryReader { geometry in
                let size=geometry.size
                ZStack {
                    Canvas { context,size in
                        var grid=Path()
                        for i in 0...4 {let f=CGFloat(i)/4;grid.move(to:CGPoint(x:f*size.width,y:0));grid.addLine(to:CGPoint(x:f*size.width,y:size.height));grid.move(to:CGPoint(x:0,y:f*size.height));grid.addLine(to:CGPoint(x:size.width,y:f*size.height))}
                        context.stroke(grid,with:.color(q.color("outlineVariant").opacity(0.4)),lineWidth:1)
                        var curve=Path()
                        for i in 0...120 {let t=Double(i)/120;let p=CGPoint(x:t*size.width,y:(1-InteractionLink.eased(t,custom ? encoded:easing))*size.height);if i==0{curve.move(to:p)}else{curve.addLine(to:p)}}
                        context.stroke(curve,with:.color(q.color("primary")),style:StrokeStyle(lineWidth:3,lineCap:.round,lineJoin:.round))
                        if custom {
                            var handles=Path();handles.move(to:CGPoint(x:0,y:size.height));handles.addLine(to:CGPoint(x:points[0]*size.width,y:(1-points[1])*size.height));handles.move(to:CGPoint(x:size.width,y:0));handles.addLine(to:CGPoint(x:points[2]*size.width,y:(1-points[3])*size.height))
                            context.stroke(handles,with:.color(q.color("primary").opacity(0.4)),lineWidth:1)
                        }
                    }
                    if custom {
                        ForEach([0,2],id:\.self){index in Circle().fill(q.color("primary")).frame(width:20,height:20).overlay(Circle().stroke(q.color("surface"),lineWidth:3)).frame(width:44,height:44).position(x:points[index]*size.width,y:(1-points[index+1])*size.height).gesture(DragGesture(minimumDistance:0,coordinateSpace:.named("curve")).onChanged{value in points[index]=min(1,max(0,value.location.x/size.width));points[index+1]=min(1,max(0,1-value.location.y/size.height))}.onEnded{_ in easing=encoded})}
                    }
                }.coordinateSpace(name:"curve")
            }.frame(height:145).padding(18).qSurface(20,"surfaceContainerHighest")
            Text(custom ? "Тяните точки, чтобы настроить ускорение и замедление.":"График показывает ход анимации от начала до конца.").font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"))
        }.onAppear{load()}.onChange(of:easing){_,_ in load()}
    }
    private func load(){let values=easing.dropFirst(7).split(separator:",").compactMap{Double($0)};if custom && values.count==4 && values.allSatisfy(\.isFinite){points=values}}
}
