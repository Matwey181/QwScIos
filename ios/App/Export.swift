import UIKit

func xml(_ s:String)->String { s.replacingOccurrences(of:"&",with:"&amp;").replacingOccurrences(of:"<",with:"&lt;").replacingOccurrences(of:">",with:"&gt;").replacingOccurrences(of:"\"",with:"&quot;") }
enum SVGExport {
    static func make(_ p:Project,root:URL)->String {
        func color(_ value:Int64)->String { String(format:"#%06X",UInt32(truncatingIfNeeded:value)&0xffffff) }
        func alpha(_ value:Int64)->Double { Double((UInt32(truncatingIfNeeded:value)>>24)&255)/255 }
        var definitions="",body=""
        if alpha(p.bg)>0 { body += "<rect width=\"100%\" height=\"100%\" fill=\"\(color(p.bg))\" fill-opacity=\"\(alpha(p.bg))\"/>" }
        for (i,n) in p.nodes.enumerated() where n.visible && !n.mask && n.extras?.reference != true {
            let key="n\(i)",transform="translate(\(n.center.x) \(n.center.y)) rotate(\(n.rotation)) translate(\(-n.w/2) \(-n.h/2))"
            var fill=color(n.fill),filter="",clip=""
            if n.gradKind != 0 {
                if n.gradKind==2 { definitions += "<radialGradient id=\"g\(key)\"><stop stop-color=\"\(color(n.fill))\" stop-opacity=\"\(alpha(n.fill))\"/><stop offset=\"1\" stop-color=\"\(color(n.fill2))\" stop-opacity=\"\(alpha(n.fill2))\"/></radialGradient>" }
                else { let a=n.gradAngle * .pi/180,dx=cos(a)*0.5,dy=sin(a)*0.5
                    definitions += "<linearGradient id=\"g\(key)\" x1=\"\(0.5-dx)\" y1=\"\(0.5-dy)\" x2=\"\(0.5+dx)\" y2=\"\(0.5+dy)\"><stop stop-color=\"\(color(n.fill))\" stop-opacity=\"\(alpha(n.fill))\"/><stop offset=\"1\" stop-color=\"\(color(n.fill2))\" stop-opacity=\"\(alpha(n.fill2))\"/></linearGradient>" }
                fill="url(#g\(key))"
            }
            if n.softBlur>0 || n.shadowBlur>0 {
                definitions += "<filter id=\"f\(key)\" x=\"-100%\" y=\"-100%\" width=\"300%\" height=\"300%\">"
                if n.shadowBlur>0 { definitions += "<feDropShadow dx=\"\(n.shadowDx)\" dy=\"\(n.shadowDy)\" stdDeviation=\"\(n.shadowBlur/2)\" flood-color=\"\(color(n.shadowColor))\" flood-opacity=\"\(alpha(n.shadowColor))\"/>" }
                if n.softBlur>0 { definitions += "<feGaussianBlur stdDeviation=\"\(n.softBlur)\"/>" }
                definitions += "</filter>";filter=" filter=\"url(#f\(key))\""
            }
            if i+1<p.nodes.count,p.nodes[i+1].mask,p.nodes[i+1].visible {
                definitions += "<clipPath id=\"c\(key)\"><path d=\"\(VectorPath.string(VectorPath.world(p.nodes[i+1])))\"/></clipPath>";clip=" clip-path=\"url(#c\(key))\""
            }
            var content=""
            if n.kind=="TEXT" {
                var family="sans-serif"
                if !n.font.isEmpty,let bytes=try? Data(contentsOf:root.appendingPathComponent("fonts").appendingPathComponent(n.font)) {
                    family="q\(key)";definitions += "<style>@font-face{font-family:'\(family)';src:url(data:font/ttf;base64,\(bytes.base64EncodedString()))}</style>"
                }
                let font=DocumentRenderer(root:root).font(n),layout=TextLayout(n,font:DocumentRenderer(root:root).font(n))
                let anchor=n.textAlign=="center" ? "middle":n.textAlign=="right" ? "end":"start"
                let x:CGFloat=n.textAlign=="center" ? n.w/2:n.textAlign=="right" ? n.w:0
                content="<text text-anchor=\"\(anchor)\" xml:space=\"preserve\" font-family=\"\(family)\" letter-spacing=\"\(n.extras?.tracking ?? 0)\" font-size=\"\(layout.resolvedFont.pointSize)\" font-weight=\"\(n.weight)\">"+layout.lines.enumerated().map { index,line in "<tspan x=\"\(x)\" y=\"\(layout.resolvedFont.ascender+CGFloat(index)*(layout.lineHeight+(n.extras?.lineSpacing ?? 0)))\">\(StyledSVGText.line(n,range:layout.ranges.indices.contains(index) ? layout.ranges[index]:NSRange(location:0,length:0)))</tspan>" }.joined()+"</text>"
            } else if n.kind=="IMAGE" {
                if let data=try? Data(contentsOf:root.appendingPathComponent("assets").appendingPathComponent(n.asset)) {
                    let mime=n.asset.lowercased().hasSuffix("jpg") ? "image/jpeg":"image/png"
                    content="<image width=\"\(n.w)\" height=\"\(n.h)\" preserveAspectRatio=\"none\" href=\"data:\(mime);base64,\(data.base64EncodedString())\"/>"
                }
            } else { content="<path d=\"\(VectorPath.string(VectorPath.local(n)))\" fill-rule=\"\(n.evenOdd ? "evenodd":"nonzero")\"/>" }
            body += "<g\(clip)><g transform=\"\(transform)\" opacity=\"\(n.opacity)\" fill=\"\(fill)\" fill-opacity=\"\(n.gradKind==0 ? alpha(n.fill):1)\" stroke=\"\(color(n.stroke))\" stroke-opacity=\"\(alpha(n.stroke))\" stroke-width=\"\(n.strokeWidth)\" stroke-linejoin=\"round\"\(filter)>\(content)</g></g>"
        }
        return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(p.w)\" height=\"\(p.h)\" viewBox=\"0 0 \(p.w) \(p.h)\"><defs>\(definitions)</defs>\(body)</svg>"
    }
}
struct SharedFile:Identifiable { let id=UUID();let url:URL }
