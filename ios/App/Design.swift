import SwiftUI

struct QPalette {
    var dark=true
    var mode=2
    var seed:Int64=0
    var iosStyle=false
    static let values:[String:[String:Int64]] = load("ui-colors")
    func color(_ key:String)->Color { Color(argb:argb(key)) }
    func argb(_ key:String)->Int64 {
        if iosStyle{
            if ["primary","secondary","tertiary"].contains(key){return dark ? 0xff0a84ff:0xff007aff}
            if key=="onPrimary"{return 0xffffffff}
            if key.hasSuffix("Container") && !key.hasPrefix("surface"){return dark ? 0xff18334f:0xffe0eeff}
            if key=="surface" || key=="surfaceContainerLowest"{return dark ? 0xff000000:0xfff2f2f7}
            if key.hasPrefix("surfaceContainer"){return dark ? 0xff1c1c1e:0xffffffff}
            if key=="onSurface"{return dark ? 0xffffffff:0xff000000}
            if key=="onSurfaceVariant"{return dark ? 0xff98989f:0xff6c6c70}
        }
        if mode==3 || mode==4 {
            let names=["surface","surfaceContainerLowest","surfaceContainerLow","surfaceContainer","surfaceContainerHigh","surfaceContainerHighest"]
            if let i=names.firstIndex(of:key) { return Int64((dark ? [0xff000000,0xff000000,0xff0b0b0b,0xff121212,0xff1a1a1a,0xff232323]:[0xffffffff,0xffffffff,0xfff7f7f7,0xfff1f1f1,0xffebebeb,0xffe5e5e5])[i]) }
        }
        if seed != 0 {
            let keys=["primary","onPrimary","primaryContainer","onPrimaryContainer","secondary","secondaryContainer","onSecondaryContainer","tertiary","tertiaryContainer","onTertiaryContainer","error","errorContainer","surface","surfaceContainerLow","surfaceContainer","surfaceContainerHigh","surfaceContainerHighest","onSurface","onSurfaceVariant","outline","outlineVariant","inverseSurface"]
            if let i=keys.firstIndex(of:key){return ToneGenerator.scheme(seed:seed,dark:dark).colors[i]}
        }
        return Self.values[dark ? "dark":"light"]?[key] ?? 0xffe1e5e5
    }
}
private struct PaletteKey:EnvironmentKey { static let defaultValue=QPalette() }
extension EnvironmentValues { var q:QPalette { get { self[PaletteKey.self] } set { self[PaletteKey.self]=newValue } } }
func load<T:Decodable>(_ name:String)->T { try! JSONDecoder().decode(T.self,from:Data(contentsOf:Bundle.main.url(forResource:name,withExtension:"json")!)) }
func qfont(_ size:CGFloat,_ weight:Font.Weight = .regular)->Font {
    let suffix=weight == .bold ? "Bold":weight == .semibold ? "SemiBold":weight == .medium ? "Medium":weight == .light ? "Light":"Regular"
    let family=UserDefaults.standard.integer(forKey:"uiStyle")==1 ? "InterSA":UserDefaults.standard.string(forKey:"uiFont") ?? "InterSA"
    return family.isEmpty ? .system(size:size,weight:weight):.custom(family+"-"+suffix,fixedSize:size)
}
struct OriginalTheme:ViewModifier {
    @AppStorage("uiStyle") var uiStyle=0
    @AppStorage("appearance") var appearance=2
    @AppStorage("accent") var accent=0
    @AppStorage("accentSeed") var accentSeed:Int=0xff006a6a
    @AppStorage("uiFont") var uiFont="InterSA"
    @Environment(\.colorScheme) var system
    func body(content:Content)->some View {
        let dark=appearance==0 ? system == .dark : appearance==2 || appearance==3
        let palette=QPalette(dark:dark,mode:appearance,seed:accent==2 ? Int64(accentSeed):0,iosStyle:uiStyle==1)
        content.environment(\.q,palette).font(qfont(14)).foregroundStyle(palette.color("onSurface")).tint(palette.color("primary"))
            .preferredColorScheme(appearance==0 ? nil:dark ? .dark:.light)
    }
}
struct IconCommand:Decodable { var op:String;var args:[CGFloat]?;var path:String?;var fill:Bool?;var mode:String?;var dash:[CGFloat]? }
struct QIcon:View {
    let id:String
    var size:CGFloat=24
    var tint:Color?
    @Environment(\.q) var q
    static let icons:[String:[IconCommand]]=load("ui-icons")
    private var symbol:String?{["Back":"chevron.left","Add":"plus","Close":"xmark","Settings":"gearshape","Import":"square.and.arrow.down","Export":"square.and.arrow.up","Text":"textformat","Search":"magnifyingglass","Home":"house","Style":"slider.horizontal.3","Layers":"square.3.layers.3d"][id]}
    var body:some View {
        Group{if q.iosStyle,let symbol{Image(systemName:symbol).font(.system(size:size,weight:.regular)).foregroundStyle(tint ?? q.color("onSurface"))}else{Canvas { context,dimensions in
            var c=context;c.scaleBy(x:dimensions.width/24,y:dimensions.height/24)
            let color=tint ?? q.color("onSurface")
            for command in Self.icons[id] ?? [] {
                let a=command.args ?? [],path:Path,filled:Bool
                switch command.op {
                case "ln":path=Path { $0.move(to:CGPoint(x:a[0],y:a[1]));$0.addLine(to:CGPoint(x:a[2],y:a[3])) };filled=false
                case "rc":path=Path(roundedRect:CGRect(x:a[0],y:a[1],width:a[2],height:a[3]),cornerRadius:a.count>4 ? a[4]:1.5);filled=a.count>5 && a[5]==1
                case "cr":path=Path(ellipseIn:CGRect(x:a[0]-a[2],y:a[1]-a[2],width:a[2]*2,height:a[2]*2));filled=a.count>3 && a[3]==1
                case "boolean":
                    let first=CGPath(roundedRect:CGRect(x:3,y:3,width:12,height:12),cornerWidth:2.5,cornerHeight:2.5,transform:nil),second=CGPath(ellipseIn:CGRect(x:9,y:9,width:12,height:12),transform:nil)
                    let result:CGPath
                    switch command.mode { case "BoolDiff":result=first.subtracting(second,using:.winding);case "BoolIntersect":result=first.intersection(second,using:.winding);case "BoolExclude":result=first.symmetricDifference(second,using:.winding);default:result=first.union(second,using:.winding) }
                    c.fill(Path(result),with:.color(color));c.stroke(Path(first),with:.color(color.opacity(0.55)),lineWidth:1.2);c.stroke(Path(second),with:.color(color.opacity(0.55)),lineWidth:1.2);continue
                default:path=Path(VectorPath.parse(command.path ?? ""));filled=command.fill ?? false
                }
                if filled { c.fill(path,with:.color(color)) } else { c.stroke(path,with:.color(color),style:StrokeStyle(lineWidth:2,lineCap:.round,lineJoin:.round,dash:command.dash ?? [])) }
            }
        }}}.frame(width:size,height:size).accessibilityHidden(true)
    }
}
struct QIconButton:View {
    var icon:String
    var label:String
    var size:CGFloat=48
    var selected=false
    var tonal=false
    var enabled=true
    var action:()->Void
    @Environment(\.q) var q
    var body:some View { Button(action:action) { QIcon(id:icon,tint:q.color(selected ? "onSecondaryContainer":"onSurface")).frame(width:size,height:size).background(selected || tonal ? q.color(selected ? "secondaryContainer":"surfaceContainerHighest"):.clear,in:RoundedRectangle(cornerRadius:selected ? 16:size/2)) }.buttonStyle(QPressStyle()).disabled(!enabled).opacity(enabled ? 1:0.38).accessibilityLabel(label) }
}
struct QPressStyle:ButtonStyle { func makeBody(configuration:Configuration)->some View { configuration.label.opacity(configuration.isPressed ? 0.75:1).scaleEffect(configuration.isPressed ? 0.97:1).animation(.spring(response:0.3,dampingFraction:0.7),value:configuration.isPressed) } }
struct QChip:View {
    var title:String
    var selected=false
    var action:()->Void
    @Environment(\.q) var q
    var body:some View { Button(action:action) { Text(title).font(qfont(14,.medium)).lineLimit(1).padding(.horizontal,16).frame(minHeight:32).frame(maxWidth:.infinity).background(selected ? q.color("secondaryContainer"):.clear,in:RoundedRectangle(cornerRadius:8)).overlay(RoundedRectangle(cornerRadius:8).stroke(selected ? .clear:q.color("outline"),lineWidth:1)) }.buttonStyle(QPressStyle()) }
}
struct QSurface:ViewModifier {
    var radius:CGFloat=28
    var color="surfaceContainerLow"
    var glass=false
    var glassAlpha:Double=0.78
    @AppStorage("glass") var glassOn=true
    @Environment(\.q) var q
    func body(content:Content)->some View {
        content.background { if glass && glassOn { RoundedRectangle(cornerRadius:radius).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius:radius).fill(q.color(color).opacity(glassAlpha))) } else { RoundedRectangle(cornerRadius:radius).fill(q.color(color)) } }
            .overlay(RoundedRectangle(cornerRadius:radius).stroke(glass && glassOn ? q.color("outlineVariant").opacity(0.7):.clear,lineWidth:0.6))
    }
}
extension View { func qSurface(_ radius:CGFloat=28,_ color:String="surfaceContainerLow",glass:Bool=false,alpha:Double=0.78)->some View { modifier(QSurface(radius:radius,color:color,glass:glass,glassAlpha:alpha)) } }
struct LogoPart:Decodable { var path:String;var color:Int64 }
struct QLogo:View {
    static let paths:[LogoPart]=load("ui-logo")
    var body:some View { Canvas { context,size in
        let side=min(size.width,size.height)
        context.fill(Path(roundedRect:CGRect(origin:.zero,size:CGSize(width:side,height:side)),cornerRadius:side*0.3),with:.color(Color(argb:0xff151d1d)))
        var c=context;c.translateBy(x:-26.3/72*side,y:-25.68/72*side);c.scaleBy(x:0.24/72*side,y:0.24/72*side)
        for p in Self.paths { c.fill(Path(VectorPath.parse(p.path)),with:.color(Color(argb:p.color))) }
    } }
}
struct QSlider:View {
    @Binding var value:Double
    var range:ClosedRange<Double>=0...1
    var step:Double=0
    @Environment(\.q) var q
    var body:some View {
        GeometryReader { g in
            let k=min(1,max(0,(value-range.lowerBound)/max(0.000001,range.upperBound-range.lowerBound))),x=12+(g.size.width-24)*k
            ZStack(alignment:.leading) {
                Capsule().fill(q.color("secondaryContainer")).frame(height:16)
                Capsule().fill(q.color("primary")).frame(width:max(0,x-6),height:16)
                Circle().fill(q.color("primary")).frame(width:4,height:4).offset(x:g.size.width-14)
                RoundedRectangle(cornerRadius:2).fill(q.color("primary")).frame(width:4,height:44).overlay(RoundedRectangle(cornerRadius:2).stroke(q.color("surfaceContainerHigh"),lineWidth:1)).offset(x:x-2)
            }.frame(height:44).contentShape(Rectangle()).gesture(DragGesture(minimumDistance:0).onChanged { p in let t=min(1,max(0,(p.location.x-12)/(g.size.width-24)));let v=range.lowerBound+t*(range.upperBound-range.lowerBound);value=step>0 ? (v/step).rounded()*step:v })
        }.frame(height:44).accessibilityElement().accessibilityValue(String(format:"%.0f",value)).accessibilityAdjustableAction { direction in let delta=step>0 ? step:(range.upperBound-range.lowerBound)/20;value=min(range.upperBound,max(range.lowerBound,value+(direction == .increment ? delta:-delta))) }
    }
}
struct QSwitch:View {
    @Binding var on:Bool
    @Environment(\.q) var q
    var body:some View {Group{
        if q.iosStyle{Toggle("",isOn:$on).labelsHidden().tint(.green).frame(width:52)}
        else{Button{withAnimation(.spring(response:0.25,dampingFraction:0.8)){on.toggle()}}label:{Capsule().fill(q.color(on ? "primary":"surfaceContainerHighest")).overlay(Capsule().stroke(on ? .clear:q.color("outline"),lineWidth:2)).overlay(alignment:on ? .trailing:.leading){Circle().fill(q.color(on ? "onPrimary":"outline")).frame(width:on ? 24:16,height:on ? 24:16).padding(.horizontal,on ? 4:8)}.frame(width:52,height:32)}.buttonStyle(.plain)}
    }.accessibilityLabel(on ? "Включено":"Выключено").accessibilityAddTraits(on ? .isSelected:[])}
}
struct QTextField:View {
    var title:String
    @Binding var text:String
    @Environment(\.q) var q
    var body:some View { VStack(alignment:.leading,spacing:2) { Text(title).font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"));TextField("",text:$text).font(qfont(16)).textFieldStyle(.plain) }.padding(.horizontal,16).padding(.vertical,10).frame(minHeight:56).overlay(RoundedRectangle(cornerRadius:16).stroke(q.color("outline"))) }
}
struct QSubHeader:View {
    var title:String
    var back:()->Void
    @Environment(\.q) var q
    var body:some View { HStack(spacing:12) { QIconButton(icon:"Back",label:"Назад",tonal:true,action:back);Text(title).font(qfont(22,.semibold));Spacer() }.padding(.horizontal,12).padding(.vertical,8) }
}
