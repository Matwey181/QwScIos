import SwiftUI

// Match contours by distance and winding, avoiding twists when vertex counts differ.
struct LinkMorph {
    let start:[Double]
    let end:[Double]
    @MainActor private static var cache:[String:LinkMorph]=[:]
    private init(start:[Double],end:[Double]){self.start=start;self.end=end}
    @MainActor init?(from:String,to:String,size:CGSize=CGSize(width:1,height:1)) {
        let key=from+">"+to+"@\(size.width)x\(size.height)"
        if let cached=Self.cache[key]{self=cached;return}
        guard let a=Catalog.shared.shapes.first(where:{$0.id==from}),let b=Catalog.shared.shapes.first(where:{$0.id==to}) else{return nil}
        self.init(fromPath:CapsuleGeometry.unitPath(a.id,width:size.width,height:size.height),toPath:CapsuleGeometry.unitPath(b.id,width:size.width,height:size.height))
        Self.cache[key]=self
    }
    init(fromPath:CGPath,toPath:CGPath){
        let a=Self.samples(fromPath),original=Self.samples(toPath)
        var b=original
        func area(_ points:[CGPoint])->CGFloat{var sum:CGFloat=0;for i in points.indices{let j=(i+1)%points.count;sum+=points[i].x*points[j].y-points[j].x*points[i].y};return sum}
        if area(a)*area(b)<0{b.reverse()}
        var best=CGFloat.greatestFiniteMagnitude,offset=0
        for shift in b.indices{var distance:CGFloat=0;for i in a.indices{let p=b[(i+shift)%b.count];let dx=a[i].x-p.x,dy=a[i].y-p.y;distance+=dx*dx+dy*dy};if distance<best{best=distance;offset=shift}}
        let matched=b.indices.map{b[($0+offset)%b.count]}
        start=Self.cubics(a);end=Self.cubics(matched)
    }
    private static func mix(_ a:CGPoint,_ b:CGPoint,_ t:CGFloat)->CGPoint{CGPoint(x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t)}
    private static func samples(_ path:CGPath)->[CGPoint]{
        var points:[CGPoint]=[],current=CGPoint.zero,first=CGPoint.zero
        path.applyWithBlock{pointer in let e=pointer.pointee,p=e.points
            switch e.type {
            case .moveToPoint:current=p[0];first=current;points.append(current)
            case .addLineToPoint:current=p[0];points.append(current)
            case .addQuadCurveToPoint:
                let a=current,b=p[0],c=p[1]
                for i in 1...32{let t=CGFloat(i)/32;let ab=Self.mix(a,b,t),bc=Self.mix(b,c,t);points.append(Self.mix(ab,bc,t))}
                current=c
            case .addCurveToPoint:
                let a=current,b=p[0],c=p[1],d=p[2]
                for i in 1...40{
                    let t=CGFloat(i)/40
                    let ab=Self.mix(a,b,t),bc=Self.mix(b,c,t),cd=Self.mix(c,d,t)
                    let left=Self.mix(ab,bc,t),right=Self.mix(bc,cd,t)
                    points.append(Self.mix(left,right,t))
                }
                current=d
            case .closeSubpath:points.append(first);current=first
            @unknown default:break
            }
        }
        if let first=points.first,let last=points.last,first != last{points.append(first)}
        guard points.count>1 else{return Array(repeating:.zero,count:192)}
        var lengths:[CGFloat]=[0]
        for i in 1..<points.count{lengths.append(lengths.last!+hypot(points[i].x-points[i-1].x,points[i].y-points[i-1].y))}
        let total=lengths.last!;var segment=1,result:[CGPoint]=[]
        for i in 0..<192{let distance=total*CGFloat(i)/192;while segment<lengths.count-1 && lengths[segment]<distance{segment+=1};let t=(distance-lengths[segment-1])/max(0.000001,lengths[segment]-lengths[segment-1]),a=points[segment-1],b=points[segment];result.append(CGPoint(x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t))}
        return result
    }
    private static func cubics(_ points:[CGPoint])->[Double]{
        var result:[Double]=[]
        for i in points.indices{let a=points[i],b=points[(i+1)%points.count];result += [Double(a.x),Double(a.y),Double(a.x+(b.x-a.x)/3),Double(a.y+(b.y-a.y)/3),Double(a.x+(b.x-a.x)*2/3),Double(a.y+(b.y-a.y)*2/3),Double(b.x),Double(b.y)]}
        return result
    }
    func svg(_ progress:Double)->String {
        func pair(_ i:Int)->String {"\(start[i]+(end[i]-start[i])*progress) \(start[i+1]+(end[i+1]-start[i+1])*progress)"}
        return "M \(pair(0)) "+stride(from:0,to:start.count-7,by:8).map{"C \(pair($0+2)) \(pair($0+4)) \(pair($0+6))"}.joined(separator:" ")+" Z"
    }
}
