import UIKit

/// Standalone SwiftUI source for the document's visual layers and pages.
enum SwiftExport {
    static func literal(_ text:String)->String {
        "\""+text.unicodeScalars.map { c -> String in
            switch c.value {
            case 34:return "\\\""
            case 92:return "\\\\"
            case 10:return "\\n"
            case 13:return "\\r"
            case 9:return "\\t"
            case 0..<32:return "\\u{\(String(c.value,radix:16))}"
            default:return String(c)
            }
        }.joined()+"\""
    }
    static func color(_ value:Int64)->String {
        let v=UInt32(truncatingIfNeeded:value)
        return "Color(.sRGB, red: \(Double((v>>16)&255)/255), green: \(Double((v>>8)&255)/255), blue: \(Double(v&255)/255), opacity: \(Double(v>>24)/255))"
    }
    static func path(_ node:Node)->String {
        var commands:[String]=[]
        func point(_ p:CGPoint)->String {"CGPoint(x: \(p.x), y: \(p.y))"}
        VectorPath.local(node).applyWithBlock { pointer in
            let e=pointer.pointee,p=e.points
            switch e.type {
            case .moveToPoint:commands.append("p.move(to: \(point(p[0])))")
            case .addLineToPoint:commands.append("p.addLine(to: \(point(p[0])))")
            case .addQuadCurveToPoint:commands.append("p.addQuadCurve(to: \(point(p[1])), control: \(point(p[0])))")
            case .addCurveToPoint:commands.append("p.addCurve(to: \(point(p[2])), control1: \(point(p[0])), control2: \(point(p[1])))")
            case .closeSubpath:commands.append("p.closeSubpath()")
            @unknown default:break
            }
        }
        return "Path { p in "+commands.joined(separator:"; ")+" }"
    }
    static func make(_ project:Project,root:URL)->String {
        var pages=project.pages.map(\.nodes)
        if pages.isEmpty {pages=[project.nodes]} else if pages.indices.contains(project.active){pages[project.active]=project.nodes}
        var functions:[String]=[],cases:[String]=[]
        for (page,nodes) in pages.enumerated() {
            var layers:[String]=[]
            for (i,n) in nodes.enumerated() where n.visible && !n.mask {
                let name="layer\(page)_\(i)",alignment=n.textAlign=="center" ? "center":n.textAlign=="right" ? "trailing":"leading"
                var view:String
                if n.kind=="TEXT" {
                    view="Text(\(literal(n.text))).font(.system(size: \(n.fontSize), weight: \(n.weight>=700 ? ".bold":n.weight>=500 ? ".medium":".regular"))).foregroundStyle(\(color(n.fill))).multilineTextAlignment(.\(alignment)).frame(width: \(n.w), alignment: .\(alignment)).fixedSize(horizontal: false, vertical: true)"
                } else if n.kind=="IMAGE" {
                    let bytes=(try? Data(contentsOf:root.appendingPathComponent("assets").appendingPathComponent(n.asset))) ?? Data()
                    view="embeddedImage(\(literal(bytes.base64EncodedString()))).resizable()"
                } else {
                    let shape=path(n)
                    var fill=color(n.fill)
                    if n.gradKind==2 {fill="RadialGradient(colors: [\(color(n.fill)), \(color(n.fill2))], center: .center, startRadius: 0, endRadius: \(max(n.w,n.h)/2))"}
                    else if n.gradKind==1 {
                        let angle=n.gradAngle * .pi/180,dx=cos(angle)/2,dy=sin(angle)/2
                        fill="LinearGradient(colors: [\(color(n.fill)), \(color(n.fill2))], startPoint: UnitPoint(x: \(0.5-dx), y: \(0.5-dy)), endPoint: UnitPoint(x: \(0.5+dx), y: \(0.5+dy)))"
                    }
                    view="\(shape).fill(\(fill), style: FillStyle(eoFill: \(n.evenOdd)))"
                    if n.strokeWidth>0 {view += ".overlay { \(shape).stroke(\(color(n.stroke)), lineWidth: \(n.strokeWidth)) }"}
                }
                view += ".frame(width: \(n.w), height: \(n.h), alignment: .topLeading)"
                if n.shadowBlur>0 {view += ".shadow(color: \(color(n.shadowColor)), radius: \(n.shadowBlur), x: \(n.shadowDx), y: \(n.shadowDy))"}
                if n.softBlur>0 {view += ".blur(radius: \(n.softBlur))"}
                view += ".rotationEffect(.degrees(\(n.rotation))).opacity(\(n.opacity)).position(x: \(n.center.x), y: \(n.center.y))"
                if i+1<nodes.count,nodes[i+1].mask,nodes[i+1].visible {
                    let mask=nodes[i+1]
                    view += ".frame(width: \(project.w), height: \(project.h)).mask { \(path(mask)).fill(style: FillStyle(eoFill: \(mask.evenOdd))).frame(width: \(mask.w), height: \(mask.h)).rotationEffect(.degrees(\(mask.rotation))).position(x: \(mask.center.x), y: \(mask.center.y)) }"
                }
                functions.append("private var \(name): some View { \(view) }")
                layers.append(name)
            }
            cases.append("case \(page): ZStack(alignment: .topLeading) { \(color(project.bg)); \(layers.joined(separator:"; ")) }.frame(width: \(project.w), height: \(project.h)).clipped()")
        }
        return """
        import SwiftUI
        import UIKit
        // Exported visual layout. Widget actions and backdrop blur require app code.
        public struct QwelExportedView: View {
            public var page: Int
            public init(page: Int = 0) { self.page = page }
            public var body: some View {
                Group { switch page { \(cases.joined(separator:"\n"))
                default: Color.clear.frame(width: \(project.w), height: \(project.h))
                } }
            }
            private func embeddedImage(_ base64: String) -> Image {
                Image(uiImage: UIImage(data: Data(base64Encoded: base64) ?? Data()) ?? UIImage())
            }
            \(functions.joined(separator:"\n"))
        }
        """
    }
}
