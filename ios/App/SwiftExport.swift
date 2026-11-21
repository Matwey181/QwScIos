import UIKit

/// Exports editable vector layers and all saved interaction links as one
/// self-contained SwiftUI file. No Qwel runtime is required by the target app.
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

    @MainActor private static func rules(_ project:Project)->String {
        project.links.map { link in
            let all=project.pages.flatMap(\.nodes)+project.nodes
            let source=all.first{$0.id==link.sourceID}
            let aliases=source?.group.isEmpty==false ? Array(Set(all.filter{$0.group==source?.group}.map(\.id))):[]
            let node=all.first{$0.id==link.targetID}
            let morph=link.property=="morph" ? LinkMorph(from:node?.shapeId ?? "",to:link.shapeID ?? "star-8"):nil
            return "QwelRule(source: \(literal(link.sourceID)), event: \(literal(link.event)), target: \(literal(link.targetID)), mode: \(literal(link.mode)), property: \(literal(link.property)), value: \(link.value), from: \(link.from), to: \(link.to), duration: \(link.duration), delay: \(link.delay), easing: \(literal(link.easing)), text: \(literal(link.text)), color: \(link.color), repeats: \(link.repeats), enabled: \(link.enabled), id: \(literal(link.id)), alternate: \(link.alternate ?? false), reverseText: \(link.reverseText.map{literal($0)} ?? "nil"), sourceAliases: [\(aliases.map{literal($0)}.joined(separator:","))], morphFrom: \(morph?.start ?? []), morphTo: \(morph?.end ?? []))"
        }.joined(separator:",\n")
    }
    private static func bases(_ project:Project,_ pages:[[Node]])->String {
        let ids=Set(project.links.map(\.targetID) + project.nodes.compactMap {
            $0.action.hasPrefix("toggle:") ? String($0.action.dropFirst(7)) : nil
        })
        let nodes=pages.flatMap{$0}.filter{ids.contains($0.id)}
        let props: [(String,(Node)->Double)] = [
            ("x",{Double($0.x)}),("y",{Double($0.y)}),
            ("width",{Double($0.w)}),("height",{Double($0.h)}),
            ("rotation",{Double($0.rotation)}),("opacity",{Double($0.opacity)}),
            ("scale",{_ in 1}),("progress",{_ in 0}),
            ("fontSize",{Double($0.fontSize)}),("corner",{Double($0.corner)}),
            ("blur",{Double($0.softBlur)}),("fill",{Double($0.fill)}),
            ("visible",{$0.visible ? 1 : 0}), ("morph",{_ in 0}), ("echo",{_ in 0}),
            ("stroke",{Double($0.stroke)}),("fill2",{Double($0.fill2)}),
            ("shadowColor",{Double($0.shadowColor)}),("weight",{Double($0.weight)}),
            ("strokeWidth",{Double($0.strokeWidth)}),("gradAngle",{Double($0.gradAngle)}),
            ("shadowBlur",{Double($0.shadowBlur)}),("shadowDx",{Double($0.shadowDx)}),
            ("shadowDy",{Double($0.shadowDy)}),("backgroundBlur",{Double($0.blur)})
        ]
        return nodes.flatMap { n in props.map { pair in
            "\(literal(n.id+"|"+pair.0)): \(pair.1(n))"
        }}.joined(separator:",\n")
    }

    @MainActor static func make(_ project:Project,root:URL)->String {
        var pages=project.pages.map(\.nodes)
        if pages.isEmpty {pages=[project.nodes]}
        else if pages.indices.contains(project.active) {pages[project.active]=project.nodes}
        let allNodes=pages.flatMap{$0}
        var functions:[String]=[],cases:[String]=[]
        let rulesSource=rules(project),baseSource=bases(project,pages)
        let dictionarySource=baseSource.isEmpty ? ":" : baseSource

        for (page,nodes) in pages.enumerated() {
            var layers:[String]=[]
            for (i,n) in nodes.enumerated() where !n.mask {
                let name="layer\(page)_\(i)"
                let identifier=literal(n.id)
                let alignment=n.textAlign=="center" ? "center":n.textAlign=="right" ? "trailing":"leading"
                var view:String
                let nodeColor="graph.fill(\(identifier), base: \(n.fill))"
                if n.kind=="TEXT" {
                    let textBase="Text(graph.label(\(identifier), base: \(literal(n.text)))).font(.system(size: CGFloat(graph.value(\(identifier), \"fontSize\", base: \(n.fontSize))), weight: (graph.value(\(identifier), \"weight\", base: \(n.weight)) >= 700 ? .bold : graph.value(\(identifier), \"weight\", base: \(n.weight)) >= 500 ? .medium : .regular))).foregroundStyle(\(nodeColor)).multilineTextAlignment(.\(alignment))"
                    if TextLayout.isAndroidCatalogText(n) {
                        // Android's template text is measured with a 0.55 character
                        // estimate and renders only explicit newlines. Its compact
                        // frame must not cause extra line breaks in exported SwiftUI.
                        view=textBase+".fixedSize(horizontal: true, vertical: true).frame(width: \(n.w), height: \(n.h), alignment: .\(alignment))"
                    } else {
                        view=textBase+".frame(width: \(n.w), alignment: .\(alignment)).fixedSize(horizontal: false, vertical: true)"
                    }
                } else if n.kind=="IMAGE" {
                    let bytes=(try? Data(contentsOf:root.appendingPathComponent("assets").appendingPathComponent(n.asset))) ?? Data()
                    view="embeddedImage(\(literal(bytes.base64EncodedString()))).resizable()"
                } else {
                    let shape=project.links.contains(where:{$0.enabled && $0.targetID==n.id && $0.property=="morph"}) ? "graph.morphPath(\(identifier), base: \(path(n)), width: \(n.w), height: \(n.h))":n.kind=="RECT" ? "RoundedRectangle(cornerRadius: CGFloat(graph.value(\(identifier), \"corner\", base: \(n.corner)))).path(in: CGRect(x: 0, y: 0, width: \(n.w), height: \(n.h)))":path(n)
                    var fill=nodeColor
                    if n.gradKind==2 {fill="RadialGradient(colors: [\(nodeColor), graph.fill(\(identifier), base: \(n.fill2), property: \"fill2\")], center: .center, startRadius: 0, endRadius: \(max(n.w,n.h)/2))"}
                    else if n.gradKind==1 {
                        let angle=n.gradAngle * .pi/180,dx=cos(angle)/2,dy=sin(angle)/2
                        fill="LinearGradient(colors: [\(nodeColor), graph.fill(\(identifier), base: \(n.fill2), property: \"fill2\")], startPoint: graph.gradientPoint(\(identifier), base: \(n.gradAngle), end: false), endPoint: graph.gradientPoint(\(identifier), base: \(n.gradAngle), end: true))"
                    }
                    view="\(shape).fill(\(fill), style: FillStyle(eoFill: \(n.evenOdd)))"
                    if n.strokeWidth>0 || project.links.contains(where:{$0.targetID==n.id && ["stroke","strokeWidth"].contains($0.property)}) {view += ".overlay { \(shape).stroke(graph.fill(\(identifier), base: \(n.stroke), property: \"stroke\"), lineWidth: CGFloat(graph.value(\(identifier), \"strokeWidth\", base: \(n.strokeWidth)))) }"}
                }
                view += ".frame(width: \(n.w), height: \(n.h), alignment: .topLeading)"
                if n.shadowBlur>0 || project.links.contains(where:{$0.targetID==n.id && $0.property.hasPrefix("shadow")}) {view += ".shadow(color: graph.fill(\(identifier), base: \(n.shadowColor), property: \"shadowColor\"), radius: CGFloat(graph.value(\(identifier), \"shadowBlur\", base: \(n.shadowBlur))), x: CGFloat(graph.value(\(identifier), \"shadowDx\", base: \(n.shadowDx))), y: CGFloat(graph.value(\(identifier), \"shadowDy\", base: \(n.shadowDy))))"}
                view += ".blur(radius: CGFloat(graph.value(\(identifier), \"blur\", base: \(n.softBlur))))"
                // Animate all supported geometry directly; never place an invisible
                // rectangle over the exported artwork to fake its gestures.
                let sx="graph.value(\(identifier), \"width\", base: \(n.w)) / \(max(0.001,n.w)) * graph.value(\(identifier), \"scale\", base: 1) * graph.value(\(identifier), \"progress\", base: 1)"
                let sy="graph.value(\(identifier), \"height\", base: \(n.h)) / \(max(0.001,n.h)) * graph.value(\(identifier), \"scale\", base: 1)"
                view += ".scaleEffect(x: CGFloat(\(sx)), y: CGFloat(\(sy)))"
                view += ".rotationEffect(.degrees(graph.value(\(identifier), \"rotation\", base: \(n.rotation))))"
                view += ".opacity(graph.visible(\(identifier), base: \(n.visible)) ? graph.value(\(identifier), \"opacity\", base: \(n.opacity)) : 0)"
                view += ".allowsHitTesting(graph.visible(\(identifier), base: \(n.visible)))"

                // Echo is an animated geometric outline around the original layer.
                if project.links.contains(where:{$0.targetID==n.id && ($0.mode=="echo" || $0.property=="echo")}) {
                    view += ".overlay { if let echo=graph.echo(\(identifier)) { RoundedRectangle(cornerRadius: CGFloat(graph.value(\(identifier), \"corner\", base: \(n.corner)))).stroke(\(nodeColor).opacity(graph.value(\(identifier), \"echo\", base: 0)>0 ? min(1,graph.value(\(identifier), \"echo\", base: 0))*0.3:max(0,1-echo)), lineWidth: 2).scaleEffect(1+echo*0.32) } }"
                }

                var sources=Set([n.id])
                if !n.group.isEmpty {
                    for groupMember in allNodes where groupMember.group==n.group {
                        sources.insert(groupMember.id)
                    }
                }
                let tapRules=project.links.filter{$0.enabled && $0.event=="tap" && sources.contains($0.sourceID)}
                let dragRules=project.links.filter{$0.enabled && ["dragStart","drag","dragEnd","valueChanged"].contains($0.event) && sources.contains($0.sourceID)}
                var tapCalls=Array(Set(tapRules.map(\.sourceID))).sorted().map{
                    "graph.emit(\"tap\", source: \(literal($0)))"
                }
                if n.action=="back" {
                    tapCalls.append("if let last=backPages.popLast() {currentPage=last}")
                } else if n.action.hasPrefix("goto:") {
                    let target=String(n.action.dropFirst(5))
                    if let index=project.pages.firstIndex(where:{$0.id==target}) {
                        tapCalls.append("backPages.append(currentPage); currentPage=\(index)")
                    }
                } else if n.action.hasPrefix("toggle:") {
                    tapCalls.append("graph.toggle(target: \(literal(String(n.action.dropFirst(7)))))")
                } else if n.action.hasPrefix("url:") {
                    let url=String(n.action.dropFirst(4))
                    tapCalls.append("if let u=URL(string: \(literal(url))), [\"http\",\"https\"].contains(u.scheme ?? \"\") {UIApplication.shared.open(u)}")
                }
                if !tapCalls.isEmpty {
                    view += ".contentShape(Rectangle()).onTapGesture { \(tapCalls.joined(separator:"; ")) }"
                }
                if !dragRules.isEmpty {
                    var fractions:[String:String]=[:]
                    for source in Set(dragRules.map(\.sourceID)) {
                        let sourceNode=allNodes.first(where:{$0.id==source}) ?? n
                        let grouped=sourceNode.group.isEmpty ? [sourceNode] :
                            allNodes.filter{$0.group==sourceNode.group}
                        let minX=grouped.map(\.x).min() ?? n.x
                        let maxX=grouped.map{$0.x+$0.w}.max() ?? n.x+n.w
                        fractions[source]="Double(min(1,max(0,(gesture.location.x + \(n.x) - \(minX))/\(max(1,maxX-minX)))))"
                    }
                    let sources=Array(Set(dragRules.map(\.sourceID))).sorted()
                    let change=sources.map { source in
                        "graph.dragChanged(source: \(literal(source)), fraction: \(fractions[source] ?? "0"))"
                    }.joined(separator:"; ")
                    let end=sources.map { source in
                        "graph.dragEnded(source: \(literal(source)), fraction: \(fractions[source] ?? "0"))"
                    }.joined(separator:"; ")
                    view += ".simultaneousGesture(DragGesture(minimumDistance: 2).onChanged { gesture in \(change) }.onEnded { gesture in \(end) })"
                }
                view += ".position(x: CGFloat(graph.value(\(identifier), \"x\", base: \(n.x))) + \(n.w/2), y: CGFloat(graph.value(\(identifier), \"y\", base: \(n.y))) + \(n.h/2))"

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
        import QuartzCore
        // Editable vector layout + fully embedded interaction / animation engine.
        public struct QwelExportedView: View {
            public let page: Int
            @State private var currentPage: Int
            @State private var backPages: [Int] = []
            @StateObject private var graph = QwelExportRuntime()
            public init(page: Int = 0) {
                self.page = page
                _currentPage = State(initialValue: page)
            }
            private var rules: [QwelRule] { [\(rulesSource)] }
            private var initial: [String:Double] { [\(dictionarySource)] }
            public var body: some View {
                Group { switch currentPage { \(cases.joined(separator:"\n"))
                default: Color.white.frame(width: \(project.w), height: \(project.h))
                } }
                .onAppear {graph.start(rules,initial:initial)}
                .onDisappear {graph.stop()}
            }
            private func embeddedImage(_ base64: String) -> Image {
                Image(uiImage: UIImage(data: Data(base64Encoded: base64) ?? Data()) ?? UIImage())
            }
            \(functions.joined(separator:"\n"))
        }
        \(ExportedInteractionSource.code)
        """
    }
}
