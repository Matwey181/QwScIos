import UIKit

// SVG commands are shared by imported SVGs, original PATH nodes and the exact
// cubic contours exported from Android's ShapeLibrary.
enum VectorPath {
    static func parse(_ string:String) -> CGPath {
        let expression=try! NSRegularExpression(pattern:"[a-zA-Z]|[-+]?(?:[0-9]*\\.[0-9]+|[0-9]+\\.?[0-9]*)(?:[eE][-+]?[0-9]+)?")
        let ns=string as NSString
        let tokens=expression.matches(in:string,range:NSRange(location:0,length:ns.length)).map { ns.substring(with:$0.range) }
        let path=CGMutablePath()
        var i=0,cmd="M",current=CGPoint.zero,start=CGPoint.zero,lastControl=CGPoint.zero,previous=""
        func number()->CGFloat { defer { i += 1 }; return CGFloat(Double(tokens[i]) ?? 0) }
        while i<tokens.count {
            let before=i
            if tokens[i].first?.isLetter==true { cmd=tokens[i];i += 1 }
            let upper=cmd.uppercased(),relative=cmd != upper
            let required=["M":2,"L":2,"H":1,"V":1,"C":6,"S":4,"Q":4,"T":2,"A":7,"Z":0][upper]
            guard let count=required else { break }
            if upper=="Z" { path.closeSubpath();current=start;previous=upper;if i==before { break };continue }
            guard i+count<=tokens.count, tokens[i..<i+count].allSatisfy({Double($0)?.isFinite==true}) else { break }
            let origin=relative ? current : .zero
            func point()->CGPoint { CGPoint(x:number()+origin.x,y:number()+origin.y) }
            switch upper {
            case "M": current=point();path.move(to:current);start=current;cmd=relative ? "l" : "L"
            case "L": current=point();path.addLine(to:current)
            case "H": current.x=number()+origin.x;path.addLine(to:current)
            case "V": current.y=number()+origin.y;path.addLine(to:current)
            case "C": let a=point(),b=point(),end=point();path.addCurve(to:end,control1:a,control2:b);current=end;lastControl=b
            case "S": let a=["C","S"].contains(previous) ? CGPoint(x:2*current.x-lastControl.x,y:2*current.y-lastControl.y) : current
                let b=point(),end=point();path.addCurve(to:end,control1:a,control2:b);current=end;lastControl=b
            case "Q": let a=point(),end=point();path.addQuadCurve(to:end,control:a);current=end;lastControl=a
            case "T": let a=["Q","T"].contains(previous) ? CGPoint(x:2*current.x-lastControl.x,y:2*current.y-lastControl.y) : current
                let end=point();path.addQuadCurve(to:end,control:a);current=end;lastControl=a
            case "A": let rx=number(),ry=number(),angle=number(),large=number() != 0,sweep=number() != 0,end=point()
                arc(path,from:current,to:end,rx:rx,ry:ry,degrees:angle,large:large,sweep:sweep);current=end
            default: break
            }
            previous=upper
            if i<=before { break }
        }
        return path
    }
    private static func arc(_ p:CGMutablePath,from a:CGPoint,to b:CGPoint,rx originalRx:CGFloat,ry originalRy:CGFloat,degrees:CGFloat,large:Bool,sweep:Bool) {
        var rx=abs(originalRx),ry=abs(originalRy)
        guard rx>0,ry>0,a != b else { p.addLine(to:b);return }
        let phi=degrees * .pi/180,c=cos(phi),s=sin(phi)
        let dx=(a.x-b.x)/2,dy=(a.y-b.y)/2,x=c*dx+s*dy,y = -s*dx+c*dy
        let lambda=x*x/(rx*rx)+y*y/(ry*ry)
        if lambda>1 { rx *= sqrt(lambda);ry *= sqrt(lambda) }
        let numerator=max(0,rx*rx*ry*ry-rx*rx*y*y-ry*ry*x*x)
        let denominator=rx*rx*y*y+ry*ry*x*x
        let factor=(large==sweep ? CGFloat(-1):1)*sqrt(numerator/max(denominator,0.00000001))
        let cxp=factor*rx*y/ry,cyp = -factor*ry*x/rx
        let cx=c*cxp-s*cyp+(a.x+b.x)/2,cy=s*cxp+c*cyp+(a.y+b.y)/2
        let u=CGPoint(x:(x-cxp)/rx,y:(y-cyp)/ry),v=CGPoint(x:(-x-cxp)/rx,y:(-y-cyp)/ry)
        let start=atan2(u.y,u.x)
        var delta=atan2(u.x*v.y-u.y*v.x,u.x*v.x+u.y*v.y)
        if !sweep && delta>0 { delta -= 2 * .pi };if sweep && delta<0 { delta += 2 * .pi }
        let steps=max(1,Int(ceil(abs(delta)/(.pi/2))))
        func point(_ t:CGFloat)->CGPoint { CGPoint(x:cx+c*rx*cos(t)-s*ry*sin(t),y:cy+s*rx*cos(t)+c*ry*sin(t)) }
        func derivative(_ t:CGFloat)->CGPoint { CGPoint(x:-c*rx*sin(t)-s*ry*cos(t),y:-s*rx*sin(t)+c*ry*cos(t)) }
        for j in 0..<steps {
            let t=start+delta*CGFloat(j)/CGFloat(steps),end=t+delta/CGFloat(steps),k=4/3*tan((end-t)/4)
            let q0=point(t),q1=point(end),d0=derivative(t),d1=derivative(end)
            p.addCurve(to:j==steps-1 ? b:q1,control1:CGPoint(x:q0.x+k*d0.x,y:q0.y+k*d0.y),control2:CGPoint(x:q1.x-k*d1.x,y:q1.y-k*d1.y))
        }
    }
    static func local(_ n:Node)->CGPath {
        let rect=CGRect(x:0,y:0,width:max(0,n.w),height:max(0,n.h))
        if n.kind=="ELLIPSE" { return CGPath(ellipseIn:rect,transform:nil) }
        if n.kind=="PATH" || n.kind=="SHAPE" {
            let source=n.kind=="PATH" ? n.path : Catalog.shared.shapes.first(where:{$0.id==n.shapeId})?.path ?? ""
            var t=CGAffineTransform(scaleX:n.w,y:n.h)
            return parse(source).copy(using:&t) ?? CGPath(rect:rect,transform:nil)
        }
        let corner=min(max(0,n.corner),min(n.w,n.h)/2)
        return CGPath(roundedRect:rect,cornerWidth:corner,cornerHeight:corner,transform:nil)
    }
    static func world(_ n:Node)->CGPath {
        var t=CGAffineTransform(translationX:n.center.x,y:n.center.y).rotated(by:n.rotation * .pi/180).translatedBy(x:-n.w/2,y:-n.h/2)
        return local(n).copy(using:&t) ?? local(n)
    }
    static func string(_ p:CGPath)->String {
        var parts:[String]=[]
        func pnt(_ p:CGPoint)->String { "\(p.x) \(p.y)" }
        p.applyWithBlock { element in
            let e=element.pointee
            switch e.type {
            case .moveToPoint:parts.append("M "+pnt(e.points[0]))
            case .addLineToPoint:parts.append("L "+pnt(e.points[0]))
            case .addQuadCurveToPoint:parts.append("Q "+pnt(e.points[0])+" "+pnt(e.points[1]))
            case .addCurveToPoint:parts.append("C "+pnt(e.points[0])+" "+pnt(e.points[1])+" "+pnt(e.points[2]))
            case .closeSubpath:parts.append("Z")
            @unknown default:break
            }
        }
        return parts.joined(separator:" ")
    }
    static func node(_ path:CGPath,style:Node)->Node? {
        let box=path.boundingBoxOfPath
        guard !box.isNull,box.width>0.0001,box.height>0.0001 else { return nil }
        var t=CGAffineTransform(a:1/box.width,b:0,c:0,d:1/box.height,tx:-box.minX/box.width,ty:-box.minY/box.height)
        guard let unit=path.copy(using:&t) else { return nil }
        var n=style;n.id=UUID().uuidString;n.kind="PATH";n.name="Контур";n.x=box.minX;n.y=box.minY;n.w=box.width;n.h=box.height;n.rotation=0;n.path=string(unit);n.group="";n.mask=false
        return n
    }
}
