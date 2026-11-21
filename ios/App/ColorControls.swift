import SwiftUI

struct QColorRow:View {
    var title:String
    @Binding var color:Int64
    var colors:[Int64]
    var token:Int64 = -1
    var picked:((Int64,Int64)->Void)?
    var eyedrop:(()->Void)?
    @Environment(\.q) var q
    @ObservedObject private var recent=RecentColors.shared
    @State private var picker=false
    var body:some View {
        VStack(alignment:.leading,spacing:8){
            Text(title).font(qfont(14,.semibold)).foregroundStyle(q.color("primary"))
            ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){
                Button{picker=true}label:{QIcon(id:"Fill",size:22,tint:q.color("primary")).frame(width:40,height:40).overlay(Circle().stroke(q.color("outline")))}.buttonStyle(.plain)
                if let eyedrop{Button(action:eyedrop){QIcon(id:"Pipette",size:22,tint:q.color("primary")).frame(width:40,height:40).overlay(Circle().stroke(q.color("outline")))}.buttonStyle(.plain)}
                ForEach(Array(colors.enumerated()),id:\.offset){i,value in swatch(value,Int64(i))}
                ForEach([Int64(-1),Int64(-16777216),0],id:\.self){swatch($0,-1)}
            }}
            if !recent.colors.isEmpty{ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){Text("Недавние").font(qfont(11)).foregroundStyle(q.color("onSurfaceVariant"));ForEach(recent.colors,id:\.self){swatch($0,-1)}}}}
        }.fullScreenCover(isPresented:$picker){ZStack{Color.black.opacity(0.4).ignoresSafeArea().onTapGesture{picker=false};QColorDialog(initial:color,cancel:{picker=false},confirm:{choose($0,-1);picker=false}).padding(.horizontal,28)}.presentationBackground(.clear).modifier(OriginalTheme())}
    }
    private func choose(_ value:Int64,_ index:Int64){if let picked{picked(value,index)}else{color=value};recent.record(value)}
    private func swatch(_ value:Int64,_ index:Int64)->some View{Button{choose(value,index)}label:{Circle().fill(Color(argb:value)).frame(width:40,height:40).overlay(Circle().stroke(color==value ? q.color("primary"):q.color("outlineVariant"),lineWidth:color==value ? 3:1)).overlay{if value==0{QIcon(id:"Close",tint:.red)}}}.buttonStyle(.plain)}
}
struct QColorDialog:View {
    var initial:Int64
    var cancel:()->Void
    var confirm:(Int64)->Void
    @Environment(\.q) var q
    @State private var hue=0.0
    @State private var saturation=1.0
    @State private var brightness=1.0
    @State private var alpha=1.0
    @State private var hex=""
    @FocusState private var editingHex:Bool
    private var parsedHex:Int64? {
        let text=hex.trimmingCharacters(in:.whitespacesAndNewlines).replacingOccurrences(of:"#",with:"")
        guard [6,8].contains(text.count),let value=UInt32(text,radix:16) else{return nil}
        return Int64(text.count==6 ? value|0xff000000:value)
    }
    private var color:UIColor{UIColor(hue:hue/360,saturation:saturation,brightness:brightness,alpha:alpha)}
    var body:some View{VStack(alignment:.leading,spacing:12){Text("Цвет").font(qfont(24,.semibold));GeometryReader{g in ZStack(alignment:.topLeading){LinearGradient(colors:[.white,Color(uiColor:UIColor(hue:hue/360,saturation:1,brightness:1,alpha:1))],startPoint:.leading,endPoint:.trailing);LinearGradient(colors:[.clear,.black],startPoint:.top,endPoint:.bottom);Circle().stroke(.white,lineWidth:2).frame(width:14,height:14).overlay(Circle().stroke(.black,lineWidth:0.75).padding(-1)).position(x:saturation*g.size.width,y:(1-brightness)*g.size.height)}.clipShape(RoundedRectangle(cornerRadius:16)).contentShape(Rectangle()).gesture(DragGesture(minimumDistance:0).onChanged{p in saturation=min(1,max(0,p.location.x/g.size.width));brightness=1-min(1,max(0,p.location.y/g.size.height));updateHex()})}.frame(height:180);Text("Тон: \(Int(hue))°").font(qfont(12,.medium));QSlider(value:$hue,range:0...360).onChange(of:hue){_,_ in updateHex()};Text("Непрозрачность: \(Int((alpha*100).rounded()))%").font(qfont(12,.medium));QSlider(value:$alpha).onChange(of:alpha){_,_ in updateHex()};HStack(spacing:12){Circle().fill(Color(uiColor:color)).frame(width:48,height:48).overlay(Circle().stroke(q.color("outlineVariant")));QTextField(title:"HEX (RRGGBB / AARRGGBB)",text:$hex).textInputAutocapitalization(.characters).autocorrectionDisabled().keyboardType(.asciiCapable).focused($editingHex).onChange(of:hex){_,_ in if editingHex,let value=parsedHex{decode(value)}}.onChange(of:editingHex){_,editing in if !editing,let value=parsedHex{decode(value);updateHex()}}};HStack(spacing:24){Spacer();Button("Отмена",action:cancel);Button("Готово"){if let value=parsedHex{let chosen=editingHex ? value:color.argb;RecentColors.shared.record(chosen);confirm(chosen)}}.disabled(parsedHex==nil)}.font(qfont(14,.semibold)).foregroundStyle(q.color("primary"))}.padding(24).qSurface(28,"surfaceContainerHigh").onAppear{decode(initial);updateHex()}}
    private func updateHex(){guard !editingHex else{return};hex=String(format:"%08X",UInt32(truncatingIfNeeded:color.argb))}
    private func decode(_ value:Int64){var h:CGFloat=0,s:CGFloat=0,b:CGFloat=0,a:CGFloat=0;UIColor(argb:value).getHue(&h,saturation:&s,brightness:&b,alpha:&a);hue=Double(h*360);saturation=Double(s);brightness=Double(b);alpha=Double(a)}
}
struct QNumber:View {
    var title:String
    @Binding var value:CGFloat
    @Environment(\.q) var q
    var body:some View{VStack(alignment:.leading,spacing:2){Text(title).font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"));TextField("",value:Binding<Double>(get:{Double(value)},set:{if $0.isFinite{value=CGFloat($0)}}),format:.number.precision(.fractionLength(0...2))).font(qfont(16)).keyboardType(.numbersAndPunctuation)}.padding(.horizontal,16).padding(.vertical,10).frame(minHeight:56).frame(maxWidth:.infinity,alignment:.leading).overlay(RoundedRectangle(cornerRadius:16).stroke(q.color("outline")))}
}
