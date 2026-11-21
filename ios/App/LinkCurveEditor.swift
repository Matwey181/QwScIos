import SwiftUI

struct LinkCurveEditor:View {
    @Binding var easing:String
    @Environment(\.q) private var q
    @State private var points:[Double]=[0.2,0,0,1]
    private var custom:Bool {easing.hasPrefix("bezier:")}
    private var encoded:String {"bezier:"+points.map{String(format:"%.4f",$0)}.joined(separator:",")}
    var body:some View {
        VStack(alignment:.leading,spacing:12) {
            presets
            LinkCurveGraph(easing:custom ? encoded:easing,points:$points,custom:custom,commit:{easing=encoded})
                .frame(height:145).padding(18).qSurface(20,"surfaceContainerHighest")
            Text(custom ? "Тяните точки, чтобы настроить ускорение и замедление.":"График показывает ход анимации от начала до конца.")
                .font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"))
        }.onAppear{load()}.onChange(of:easing){_,_ in load()}
    }
    private var presets:some View {
        ScrollView(.horizontal,showsIndicators:false) {
            HStack(spacing:8) {
                ForEach(InteractionLink.easings,id:\.0){item in
                    QChip(title:item.1,selected:easing==item.0){easing=item.0}
                }
                QChip(title:"Свой график",selected:custom){easing=encoded}
            }
        }
    }
    private func load(){let values=easing.dropFirst(7).split(separator:",").compactMap{Double($0)};if custom && values.count==4 && values.allSatisfy(\.isFinite){points=values}}
}

private struct LinkCurveGraph:View {
    let easing:String
    @Binding var points:[Double]
    let custom:Bool
    var commit:()->Void
    @Environment(\.q) private var q
    var body:some View {
        GeometryReader { geometry in
            ZStack {
                Canvas { context,size in draw(&context,size:size) }
                if custom {
                    handle(0,size:geometry.size)
                    handle(2,size:geometry.size)
                }
            }.coordinateSpace(name:"curve")
        }
    }
    private func point(_ index:Int,_ size:CGSize)->CGPoint {
        CGPoint(x:CGFloat(points[index])*size.width,y:CGFloat(1-points[index+1])*size.height)
    }
    private func handle(_ index:Int,size:CGSize)->some View {
        Circle().fill(q.color("primary"))
            .frame(width:20,height:20)
            .overlay(Circle().stroke(q.color("surface"),lineWidth:3))
            .frame(width:44,height:44)
            .position(point(index,size))
            .gesture(DragGesture(minimumDistance:0,coordinateSpace:.named("curve"))
                .onChanged{value in
                    points[index]=Double(min(1,max(0,value.location.x/max(1,size.width))))
                    points[index+1]=Double(min(1,max(0,1-value.location.y/max(1,size.height))))
                }.onEnded{_ in commit()})
    }
    private func draw(_ context:inout GraphicsContext,size:CGSize) {
        var grid=Path()
        for i in 0...4 {
            let f=CGFloat(i)/4
            grid.move(to:CGPoint(x:f*size.width,y:0));grid.addLine(to:CGPoint(x:f*size.width,y:size.height))
            grid.move(to:CGPoint(x:0,y:f*size.height));grid.addLine(to:CGPoint(x:size.width,y:f*size.height))
        }
        context.stroke(grid,with:.color(q.color("outlineVariant").opacity(0.4)),lineWidth:1)
        var curve=Path()
        for i in 0...120 {
            let t=Double(i)/120
            let value=InteractionLink.eased(t,easing)
            let p=CGPoint(x:CGFloat(t)*size.width,y:CGFloat(1-value)*size.height)
            if i==0{curve.move(to:p)}else{curve.addLine(to:p)}
        }
        context.stroke(curve,with:.color(q.color("primary")),style:StrokeStyle(lineWidth:3,lineCap:.round,lineJoin:.round))
        if custom {
            var handles=Path()
            handles.move(to:CGPoint(x:0,y:size.height));handles.addLine(to:point(0,size))
            handles.move(to:CGPoint(x:size.width,y:0));handles.addLine(to:point(2,size))
            context.stroke(handles,with:.color(q.color("primary").opacity(0.4)),lineWidth:1)
        }
    }
}
