import UIKit

final class SVGImport:NSObject,XMLParserDelegate {
    private var nodes:[Node]=[]
    private var transforms:[CGAffineTransform]=[.identity]
    private var styles:[[String:String]]=[[:]]
    private var ignored=0
    private var textNode:Node?
    private var failure=false
    static func parse(_ data:Data) throws -> [Node] {
        guard data.count<=4*1024*1024 else { throw CocoaError(.fileReadTooLarge) }
        let delegate=SVGImport(),parser=XMLParser(data:data);parser.shouldResolveExternalEntities=false;parser.delegate=delegate
        guard parser.parse(),!delegate.failure,!delegate.nodes.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
        return delegate.nodes
    }
    func parser(_ parser:XMLParser,didStartElement elementName:String,namespaceURI:String?,qualifiedName:String?,attributes:[String:String]) {
        let tag=elementName.lowercased()
        if ignored>0 { ignored += 1;return }
        if ["defs","script","style","metadata","clippath","mask","symbol"].contains(tag) { ignored=1;return }
        var style=styles.last ?? [:]
        for (key,value) in attributes { style[key]=value }
        for item in (attributes["style"] ?? "").split(separator:";") { let pair=item.split(separator:":",maxSplits:1);if pair.count==2 { style[pair[0].trimmingCharacters(in:.whitespaces)]=pair[1].trimmingCharacters(in:.whitespaces) } }
        let transform=(transforms.last ?? .identity).concatenating(Self.transform(attributes["transform"] ?? ""))
        transforms.append(transform);styles.append(style)
        guard nodes.count<1000 else { failure=true;parser.abortParsing();return }
        func number(_ name:String,_ fallback:CGFloat=0)->CGFloat { Self.number(style[name]) ?? fallback }
        var path:CGPath?
        switch tag {
        case "rect": let rect=CGRect(x:number("x"),y:number("y"),width:max(0,number("width")),height:max(0,number("height")));path=CGPath(roundedRect:rect,cornerWidth:number("rx"),cornerHeight:number("ry",number("rx")),transform:nil)
        case "circle": let r=number("r");path=CGPath(ellipseIn:CGRect(x:number("cx")-r,y:number("cy")-r,width:r*2,height:r*2),transform:nil)
        case "ellipse": let rx=number("rx"),ry=number("ry");path=CGPath(ellipseIn:CGRect(x:number("cx")-rx,y:number("cy")-ry,width:rx*2,height:ry*2),transform:nil)
        case "line":let p=CGMutablePath();p.move(to:CGPoint(x:number("x1"),y:number("y1")));p.addLine(to:CGPoint(x:number("x2"),y:number("y2")));path=p
        case "path":path=VectorPath.parse(style["d"] ?? "")
        case "polygon","polyline":let values=Self.numbers(style["points"] ?? ""),p=CGMutablePath();if values.count>=4 { p.move(to:CGPoint(x:values[0],y:values[1]));for i in stride(from:2,to:values.count-1,by:2) { p.addLine(to:CGPoint(x:values[i],y:values[i+1])) };if tag=="polygon" { p.closeSubpath() };path=p }
        case "text":var n=Node();n.kind="TEXT";n.x=number("x");n.y=number("y")-number("font-size",16);n.fontSize=number("font-size",16);n.w=300;n.h=n.fontSize*1.5;n.fill=Self.color(style["fill"] ?? "black");n.name="Текст SVG";textNode=n
        default:break
        }
        if let path {
            var n=Node();n.fill=Self.color(style["fill"] ?? "black");n.stroke=Self.color(style["stroke"] ?? "none");n.strokeWidth=number("stroke-width",1);n.opacity=number("opacity",1);n.evenOdd=style["fill-rule"]=="evenodd"
            let fa=min(1,max(0,number("fill-opacity",1))),sa=min(1,max(0,number("stroke-opacity",1)))
            func multiply(_ c:Int64,_ a:CGFloat)->Int64 { let c=UInt32(truncatingIfNeeded:c);let alpha=UInt32(CGFloat(c>>24)*a);return Int64(Int32(bitPattern:(c&0xffffff)|(alpha<<24))) }
            n.fill=multiply(n.fill,fa);n.stroke=multiply(n.stroke,sa)
            var t=transform
            if let world=path.copy(using:&t),var made=VectorPath.node(world,style:n) {
                made.name=attributes["id"] ?? "SVG \(tag)";made.strokeWidth *= sqrt(abs(transform.a*transform.d-transform.b*transform.c));nodes.append(made)
            }
        }
    }
    func parser(_ parser:XMLParser,foundCharacters string:String) { if textNode != nil { textNode?.text += string } }
    func parser(_ parser:XMLParser,didEndElement elementName:String,namespaceURI:String?,qualifiedName:String?) {
        if ignored>0 { ignored -= 1;return }
        if elementName.lowercased()=="text",let text=textNode { nodes.append(text);textNode=nil }
        if transforms.count>1 { transforms.removeLast() };if styles.count>1 { styles.removeLast() }
    }
    private static func number(_ value:String?)->CGFloat? { guard let s=value else { return nil };return numbers(s).first }
    static func numbers(_ s:String)->[CGFloat] {
        let re=try! NSRegularExpression(pattern:"[-+]?(?:[0-9]*\\.[0-9]+|[0-9]+\\.?[0-9]*)(?:[eE][-+]?[0-9]+)?"),ns=s as NSString
        return re.matches(in:s,range:NSRange(location:0,length:ns.length)).compactMap { Double(ns.substring(with:$0.range)) }.filter(\.isFinite).map(CGFloat.init)
    }
    private static func color(_ value:String)->Int64 {
        let s=value.trimmingCharacters(in:.whitespaces).lowercased()
        if s=="none" || s=="transparent" { return 0 }
        if s.hasPrefix("#") { var hex=String(s.dropFirst());if hex.count==3 { hex=hex.map{String(repeating:String($0),count:2)}.joined() };if let v=UInt32(hex,radix:16) { return Int64(Int32(bitPattern:0xff000000|v)) } }
        if s.hasPrefix("rgb") { let a=numbers(s);if a.count>=3 { let alpha=a.count>3 ? min(1,max(0,a[3])):1;return Int64(Int32(bitPattern:UInt32(alpha*255)<<24|UInt32(min(255,max(0,a[0])))<<16|UInt32(min(255,max(0,a[1])))<<8|UInt32(min(255,max(0,a[2]))))) } }
        let named:[String:UInt32]=["black":0x000000,"white":0xffffff,"red":0xff0000,"green":0x008000,"blue":0x0000ff,"yellow":0xffff00,"gray":0x808080,"grey":0x808080,"purple":0x800080,"orange":0xffa500,"teal":0x008080]
        return Int64(Int32(bitPattern:0xff000000|(named[s] ?? 0)))
    }
    private static func transform(_ s:String)->CGAffineTransform {
        let re=try! NSRegularExpression(pattern:"([a-zA-Z]+)\\s*\\(([^)]*)\\)"),ns=s as NSString
        var t=CGAffineTransform.identity
        for match in re.matches(in:s,range:NSRange(location:0,length:ns.length)) {
            let name=ns.substring(with:match.range(at:1)),a=numbers(ns.substring(with:match.range(at:2)))
            switch name {
            case "matrix":if a.count>=6 { t=t.concatenating(CGAffineTransform(a:a[0],b:a[1],c:a[2],d:a[3],tx:a[4],ty:a[5])) }
            case "translate":if let x=a.first { t=t.translatedBy(x:x,y:a.count>1 ? a[1]:0) }
            case "scale":if let x=a.first { t=t.scaledBy(x:x,y:a.count>1 ? a[1]:x) }
            case "rotate":if let angle=a.first { if a.count>=3 { t=t.translatedBy(x:a[1],y:a[2]).rotated(by:angle * .pi/180).translatedBy(x:-a[1],y:-a[2]) } else { t=t.rotated(by:angle * .pi/180) } }
            default:break
            }
        };return t
    }
}
