import Foundation
import UIKit
import ZIPFoundation

extension OriginalCore {
    func sourceArchive(_ input:Project,root:URL,kind:String,package:String="com.example.myapp.vexel") throws -> URL {
        var project=input;project.syncPage()
        var symbolBytes:[String:Data]=[:]
        func materialized(_ nodes:[Node])->[Node]{nodes.map{node in
            guard let bytes=DocumentRenderer.symbolImage(node)?.pngData() else{return node}
            var n=node;let name="symbol-"+safeName(node.id)+".png";symbolBytes[name]=bytes;n.asset=name;return n
        }}
        project.nodes=materialized(project.nodes)
        for i in project.pages.indices{project.pages[i].nodes=materialized(project.pages[i].nodes)}
        // CodeAssist's stable Material3 API has no MaterialShapes. The original
        // caller converts these to ordinary unit paths before code generation.
        if kind=="codeassist" {
            func plain(_ list:[Node])->[Node]{list.map{n in guard n.kind=="SHAPE",let shape=Catalog.shared.shapes.first(where:{$0.id==n.shapeId})else{return n};var n=n;n.kind="PATH";n.path=shape.path;n.shapeId="";return n}}
            project.nodes=plain(project.nodes);project.pages=project.pages.map{page in var page=page;page.nodes=plain(page.nodes);return page}
        }
        let all=project.nodes+project.pages.flatMap(\.nodes)
        var faces:[String:[[String:Any]]]=[:]
        for n in all where !n.font.isEmpty {
            let ext=URL(fileURLWithPath:n.font).pathExtension.lowercased()
            if ["ttf","otf"].contains(ext){faces[n.font]=[["weight":n.weight,"ext":ext]]}
        }
        let result=try request(["op":"projectExport","kind":kind,"package":package,"faces":faces],project:project)
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        let url=folder.appendingPathComponent(safeName(project.name)+(kind=="codeassist" ? "-CodeAssist.zip":"-Compose.zip"))
        let archive=try Archive(url:url,accessMode:.create)
        func add(_ name:String,_ data:Data)throws{guard !name.hasPrefix("/"),!name.split(separator:"/").contains("..")else{throw CocoaError(.fileWriteInvalidFileName)};try archive.addEntry(with:name,type:.file,uncompressedSize:Int64(data.count),compressionMethod:.deflate){position,size in data.subdata(in:Int(position)..<min(data.count,Int(position)+size))}}
        for (name,text) in result["files"] as? [String:String] ?? [:] {try add(name,Data(text.utf8))}
        for (name,path) in result["images"] as? [String:String] ?? [:] {let file=root.appendingPathComponent("assets").appendingPathComponent(name);try add(path,symbolBytes[name] ?? Data(contentsOf:file))}
        for (path,font) in result["fonts"] as? [String:[String:Any]] ?? [:] {if let name=font["name"] as? String {try add(path,Data(contentsOf:root.appendingPathComponent("fonts").appendingPathComponent(name)))}}
        return url
    }
}
extension VectorPath {
    // Android's PathMeasure is platform-specific. Sample the native CoreGraphics
    // path by length; original Blend.kt performs all matching/interpolation.
    static func sample(_ n:Node,count:Int=96)->[CGFloat] {
        let path=world(n)
        var points:[CGPoint]=[],current=CGPoint.zero,start=CGPoint.zero
        path.applyWithBlock{ptr in let e=ptr.pointee
            switch e.type {
            case .moveToPoint:current=e.points[0];start=current;points.append(current)
            case .addLineToPoint:current=e.points[0];points.append(current)
            case .addQuadCurveToPoint:let a=current,b=e.points[0],c=e.points[1];for i in 1...80{let t=CGFloat(i)/80,u=1-t;points.append(bezierQuad(a,b,c,t))};current=c
            case .addCurveToPoint:let a=current,b=e.points[0],c=e.points[1],d=e.points[2];for i in 1...120{let t=CGFloat(i)/120,u=1-t;points.append(bezierCubic(a,b,c,d,t))};current=d
            case .closeSubpath:points.append(start);current=start
            @unknown default:break
            }
        }
        guard points.count>1 else{return []}
        var lengths:[CGFloat]=[0]
        for i in 1..<points.count{lengths.append(lengths.last!+hypot(points[i].x-points[i-1].x,points[i].y-points[i-1].y))}
        let length=lengths.last!,step=length/CGFloat(count)
        guard length>0 else{return []}
        var result:[CGFloat]=[],segment=1
        for i in 0..<count{let distance=CGFloat(i)*step;while segment<lengths.count-1 && lengths[segment]<distance{segment+=1};let t=(distance-lengths[segment-1])/max(0.000001,lengths[segment]-lengths[segment-1]);let a=points[segment-1],b=points[segment];result += [a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t]}
        return result
    }
}

private func bezierQuad(_ a:CGPoint,_ b:CGPoint,_ c:CGPoint,_ t:CGFloat)->CGPoint {
    let u:CGFloat=1-t
    let a0:CGFloat=u*u, a1:CGFloat=2*u*t, a2:CGFloat=t*t
    let x:CGFloat=a0*a.x+a1*b.x+a2*c.x
    let y:CGFloat=a0*a.y+a1*b.y+a2*c.y
    return CGPoint(x:x,y:y)
}
private func bezierCubic(_ a:CGPoint,_ b:CGPoint,_ c:CGPoint,_ d:CGPoint,_ t:CGFloat)->CGPoint {
    let u:CGFloat=1-t
    let a0:CGFloat=u*u*u, a1:CGFloat=3*u*u*t, a2:CGFloat=3*u*t*t, a3:CGFloat=t*t*t
    let x:CGFloat=a0*a.x+a1*b.x+a2*c.x+a3*d.x
    let y:CGFloat=a0*a.y+a1*b.y+a2*c.y+a3*d.y
    return CGPoint(x:x,y:y)
}
