import SwiftUI

struct LinkCurveEditor:View {
    @Binding var easing:String
    var onPreset:((String)->Void)? = nil
    @Environment(\.q) private var q
    @State private var points:[Double]=[0.2,0,0,1]
    @State private var base="linear"
    @State private var advanced=false
    @State private var outside=false
    @State private var holdOn=false
    @State private var hold=0.15
    @State private var stepsOn=false
    @State private var steps=8.0
    private var custom:Bool {base.hasPrefix("bezier:")}
    private var plain:String {custom ? "bezier:"+points.map{String(format:"%.5f",$0)}.joined(separator:","):base}
    private var encoded:String {(holdOn || stepsOn || outside) ? "curve:\(holdOn ? hold:0),\(stepsOn ? steps:0),\(outside ? 1:0)|"+plain:plain}
    var body:some View {
        VStack(alignment:.leading,spacing:14){
            presets
            LinkCurveGraph(easing:encoded,points:$points,custom:custom,outside:outside,commit:save)
                .frame(height:205).padding(12).qSurface(24,"surfaceContainerHighest")
            if custom{Text("Тяните точки. Область сама расширяется, чтобы выход графика оставался виден.").font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"))}
            QToggle("Точная настройка",isOn:$advanced)
            if advanced{options}
        }.onAppear{load()}.onChange(of:easing){_,_ in load()}
    }
    private var presets:some View {
        ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){
            ForEach(InteractionLink.easings,id:\.0){item in QChip(title:item.1,selected:base==item.0){base=item.0;save();onPreset?(item.0)}}
            QChip(title:"Свой график",selected:custom){base="bezier:";save()}
        }}
    }
    private var options:some View {
        VStack(spacing:14){
            QToggle("Выход за 0–100%",isOn:Binding(get:{outside},set:{outside=$0;if !outside{points[1]=min(1,max(0,points[1]));points[3]=min(1,max(0,points[3]))};save()}))
            if custom{HStack(spacing:8){coordinate("X₁",0);coordinate("Y₁",1)};HStack(spacing:8){coordinate("X₂",2);coordinate("Y₂",3)}}
            QToggle("Пауза в начале графика",isOn:Binding(get:{holdOn},set:{holdOn=$0;save()}))
            if holdOn{HStack{Text("Пауза");Spacer();Text("\(Int(hold*100))%")}.font(qfont(13));QSlider(value:Binding(get:{hold},set:{hold=$0;save()}),range:0...0.9)}
            QToggle("Ступенчатый график",isOn:Binding(get:{stepsOn},set:{stepsOn=$0;save()}))
            if stepsOn{HStack{Text("Шаги");Spacer();Text("\(Int(steps))")}.font(qfont(13));QSlider(value:Binding(get:{steps},set:{steps=$0;save()}),range:2...30,step:1)}
            HStack(spacing:8){LinkPill(title:"Сброс",icon:"arrow.counterclockwise"){points=[0.2,0,0,1];base="bezier:";holdOn=false;stepsOn=false;outside=false;save()};LinkPill(title:"Копировать",icon:"doc.on.doc"){UIPasteboard.general.string=encoded}}
        }.padding(14).qSurface(22,"surfaceContainerHigh")
    }
    private func coordinate(_ title:String,_ index:Int)->some View {
        QNumber(title:title,value:Binding(get:{CGFloat(points[index])},set:{value in
            let range:ClosedRange<Double> =index%2==0 ? 0...1 : outside ? -10...10:0...1
            points[index]=min(range.upperBound,max(range.lowerBound,Double(value)));save()
        }))
    }
    private func save(){easing=encoded}
    private func load(){
        var value=easing
        holdOn=false;stepsOn=false;outside=false
        if value.hasPrefix("curve:"),let divider=value.firstIndex(of:"|"){
            let header=value[value.index(value.startIndex,offsetBy:6)..<divider].split(separator:",").compactMap{Double($0)}
            if let h=header.first,h>0{hold=h;holdOn=true}
            if header.count>1 && header[1]>=2{steps=header[1];stepsOn=true}
            if header.count>2{outside=header[2]>0}
            value=String(value[value.index(after:divider)...])
        }
        base=value
        if value.hasPrefix("bezier:"){
            let values=value.dropFirst(7).split(separator:",").compactMap{Double($0)}
            if values.count==4 && values.allSatisfy(\.isFinite){points=values;outside=outside || values[1]<0 || values[1]>1 || values[3]<0 || values[3]>1}
        }
    }
}

private struct LinkCurveGraph:View {
    let easing:String
    @Binding var points:[Double]
    let custom:Bool
    let outside:Bool
    var commit:()->Void
    @Environment(\.q) private var q
    private var bounds:ClosedRange<Double>{
        var values=(0...100).map{InteractionLink.eased(Double($0)/100,easing)}+[0,1]
        if custom{values += [points[1],points[3]]}
        let low=values.min() ?? 0,high=values.max() ?? 1,padding=max(0.12,(high-low)*0.12)
        return (low-padding)...(high+padding)
    }
    var body:some View {
        GeometryReader{geometry in
            ZStack{
                Canvas{context,size in draw(&context,size:size)}
                if custom{handle(0,size:geometry.size);handle(2,size:geometry.size)}
            }.coordinateSpace(name:"curve")
        }
    }
    private func position(_ x:Double,_ y:Double,_ size:CGSize,domain:ClosedRange<Double>?=nil)->CGPoint {
        let range=domain ?? bounds
        return CGPoint(x:32+CGFloat(x)*max(1,size.width-48),y:12+CGFloat((range.upperBound-y)/(range.upperBound-range.lowerBound))*max(1,size.height-28))
    }
    private func point(_ i:Int,_ size:CGSize)->CGPoint{position(points[i],points[i+1],size)}
    private func handle(_ i:Int,size:CGSize)->some View {
        Circle().fill(q.color("primary")).frame(width:18,height:18).overlay(Circle().stroke(q.color("surface"),lineWidth:3)).frame(width:44,height:44).position(point(i,size))
            .gesture(DragGesture(minimumDistance:0,coordinateSpace:.named("curve")).onChanged{value in
                let domain=bounds
                points[i]=Double(min(1,max(0,(value.location.x-32)/max(1,size.width-48))))
                let y=domain.upperBound-Double((value.location.y-12)/max(1,size.height-28))*(domain.upperBound-domain.lowerBound)
                points[i+1]=min(outside ? 10:1,max(outside ? -10:0,y))
            }.onEnded{_ in commit()})
    }
    private func draw(_ context:inout GraphicsContext,size:CGSize){
        let domain=bounds
        func p(_ x:Double,_ y:Double,_ size:CGSize)->CGPoint{position(x,y,size,domain:domain)}
        var grid=Path()
        for i in 0...4{let x=Double(i)/4;grid.move(to:p(x,bounds.lowerBound,size));grid.addLine(to:p(x,bounds.upperBound,size))}
        for y in [0.0,0.5,1]{grid.move(to:p(0,y,size));grid.addLine(to:p(1,y,size))}
        context.stroke(grid,with:.color(q.color("outlineVariant").opacity(0.5)),style:StrokeStyle(lineWidth:1,dash:[3,4]))
        for y in [0.0,1]{let text=Text("\(Int(y*100))%").font(qfont(10)).foregroundStyle(q.color("onSurfaceVariant"));context.draw(text,at:CGPoint(x:13,y:p(0,y,size).y))}
        var curve=Path()
        for i in 0...160{let t=Double(i)/160,p=p(t,InteractionLink.eased(t,easing),size);if i==0{curve.move(to:p)}else{curve.addLine(to:p)}}
        context.stroke(curve,with:.color(q.color("primary")),style:StrokeStyle(lineWidth:3,lineCap:.round,lineJoin:.round))
        if custom{var handles=Path();handles.move(to:p(0,0,size));handles.addLine(to:point(0,size));handles.move(to:p(1,1,size));handles.addLine(to:point(2,size));context.stroke(handles,with:.color(q.color("primary").opacity(0.4)),lineWidth:1)}
    }
}
