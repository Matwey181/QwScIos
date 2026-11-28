import Foundation
import UIKit

// Android 2.9.2 Timeline.kt wire format. Times are milliseconds; translation,
// rotation and scale tracks are relative to the unanimated document.
struct MotionKey:Codable,Equatable {
    var t:Int
    var v:Double=0
    var c:Int64=0
    var s:String=""
    var e:String="lin"
    init(t:Int,v:Double=0,c:Int64=0,s:String="",e:String="lin"){self.t=t;self.v=v;self.c=c;self.s=s;self.e=e}
    init(from decoder:Decoder)throws{
        let a=try decoder.container(keyedBy:CodingKeys.self)
        t=try a.decode(Int.self,forKey:.t);v=try a.decodeIfPresent(Double.self,forKey:.v) ?? 0
        c=try a.decodeIfPresent(Int64.self,forKey:.c) ?? 0;s=try a.decodeIfPresent(String.self,forKey:.s) ?? "";e=try a.decodeIfPresent(String.self,forKey:.e) ?? "lin"
        guard v.isFinite,abs(v)<=1e8,abs(t)<=3_600_000,e.count<4096 else{throw CocoaError(.fileReadCorruptFile)}
    }
}
struct MotionTrack:Codable,Equatable,Identifiable {
    var id=UUID().uuidString
    var group=false
    var ref:String
    var prop:String
    var keys:[MotionKey]=[]
    func segment(_ time:Double)->(MotionKey,MotionKey,Double)? {
        let sorted=keys.sorted{$0.t<$1.t}
        guard let first=sorted.first,let last=sorted.last else{return nil}
        if time<=Double(first.t){return(first,first,0)}
        if time>=Double(last.t){return(last,last,0)}
        for i in 0..<(sorted.count-1) where time<Double(sorted[i+1].t){
            let a=sorted[i],b=sorted[i+1]
            return(a,b,MotionCurve.at(a.e,(time-Double(a.t))/Double(max(1,b.t-a.t))))
        }
        return(last,last,0)
    }
    func value(_ time:Double,_ fallback:Double)->Double{guard let(a,b,p)=segment(time)else{return fallback};return a.v+(b.v-a.v)*p}
}
struct MotionJump:Codable,Equatable {var t:Int;var from:String;var to:String}
struct MotionData:Codable,Equatable {
    var tracks:[MotionTrack]=[]
    var dur=3000
    var loop=true
    var jumps:[MotionJump]=[]
    init(){}
    init(from decoder:Decoder)throws{
        let a=try decoder.container(keyedBy:CodingKeys.self)
        tracks=try a.decodeIfPresent([MotionTrack].self,forKey:.tracks) ?? []
        jumps=try a.decodeIfPresent([MotionJump].self,forKey:.jumps) ?? []
        dur=try a.decodeIfPresent(Int.self,forKey:.dur) ?? 3000;loop=try a.decodeIfPresent(Bool.self,forKey:.loop) ?? true
        guard (1...3_600_000).contains(dur),tracks.count<=2000,jumps.count<=1000,tracks.allSatisfy({$0.keys.count<=10000}) else{throw CocoaError(.fileReadCorruptFile)}
    }
    static let properties:[(String,String)]=[("x","Сдвиг X"),("y","Сдвиг Y"),("sc","Масштаб"),("sx","Масштаб X"),("sy","Масштаб Y"),("rot","Поворот"),("op","Непрозрачность"),("cr","Скругление"),("bl","Размытие"),("w","Ширина"),("h","Высота"),("fill","Цвет"),("shape","Форма")]
}

enum MotionCurve {
    static let standard="bz:0.2,0,0,1"
    static let emphasized="ch:0.05,0,0.133333,0.06,0.166666,0.4,0.208333,0.82,0.25,1,1,1"
    private static let settleCache=NSCache<NSString,NSNumber>()
    static func bez(_ a:Double,_ b:Double,_ c:Double,_ d:Double,_ t:Double)->Double{let u=1-t;return u*u*u*a+3*u*u*t*b+3*u*t*t*c+t*t*t*d}
    static func solve(_ a:Double,_ b:Double,_ c:Double,_ d:Double,_ x:Double)->Double{
        var lo=0.0,hi=1.0
        for _ in 0..<24{let mid=(lo+hi)/2;if bez(a,b,c,d,mid)<x{lo=mid}else{hi=mid}}
        return(lo+hi)/2
    }
    static func spring(_ k:Double,_ z:Double,_ t:Double)->Double{
        let w=sqrt(max(0.01,k)),z=max(0.01,z)
        if z<0.9999{let wd=w*sqrt(1-z*z);return 1-exp(-z*w*t)*(cos(wd*t)+z*w/wd*sin(wd*t))}
        if z<=1.0001{return 1-exp(-w*t)*(w*t+1)}
        let q=w*sqrt(z*z-1),a = -z*w+q,b = -z*w-q
        return 1+(-b/(b-a))*exp(a*t)+(a/(b-a))*exp(b*t)
    }
    static func settle(_ k:Double,_ z:Double)->Double{
        let key="\(k),\(z)" as NSString
        if let v=settleCache.object(forKey:key){return v.doubleValue}
        var last=0.0
        for i in 0..<2880{let t=Double(i)/240;if abs(1-spring(k,z,t))>0.002{last=t}}
        let value=min(12,max(0.05,last+1/240));settleCache.setObject(NSNumber(value:value),forKey:key);return value
    }
    static func at(_ encoded:String,_ progress:Double)->Double{
        let t=min(1,max(0,progress));if t<=0{return 0};if t>=1{return 1}
        let bits=encoded.split(separator:":",maxSplits:1),kind=String(bits.first ?? "lin")
        let p=bits.count>1 ? bits[1].split(separator:",").compactMap{Double($0)}:[]
        guard p.allSatisfy(\.isFinite)else{return t}
        switch kind {
        case "bz" where p.count==4:return bez(0,p[1],p[3],1,solve(0,p[0],p[2],1,t))
        case "ch" where p.count>=6:
            var x=0.0,y=0.0
            for i in stride(from:0,through:p.count-6,by:6){if t<=p[i+4] || i+6>=p.count{return bez(y,p[i+1],p[i+3],p[i+5],solve(x,p[i],p[i+2],p[i+4],t))};x=p[i+4];y=p[i+5]};return t
        case "sp" where p.count==2:return spring(p[0],p[1],t*settle(p[0],p[1]))
        case "el" where p.count==2:return pow(2,-min(20,max(2,p[1]))*t)*sin(min(10,max(0.5,p[0]))*2 * .pi*t - .pi/2)+1
        case "st" where p.count==2:let n=min(120,max(1,p[0]));return min(1,max(0,(floor(t*n)+(p[1]==0 ? 1:0))/n))
        case "bn" where p.count==2:
            let n=min(20,max(1,Int(p[0]))),e=min(0.95,max(0.05,p[1]))
            let total=(1...n).reduce(1.0){$0+2*pow(e,Double($1))}
            var x=t*total;if x<=1{return x*x};x-=1
            for i in 1...n{let size=2*pow(e,Double(i));if x<=size{return 1-pow(e,Double(2*i))+pow(x-size/2,2)};x-=size};return 1
        default:return t
        }
    }
}

enum MotionEvaluator {
    struct Transform {
        var x=0.0,y=0.0,sx=1.0,sy=1.0,rot=0.0,op=1.0
        var corner:Double?,blur:Double?,w:Double?,h:Double?,fill:Int64?
    }
    static func collect(_ tracks:[MotionTrack],_ time:Double,_ node:Node?)->Transform{
        var x=Transform()
        for tr in tracks{
            switch tr.prop {
            case "x":x.x+=tr.value(time,0)
            case "y":x.y+=tr.value(time,0)
            case "sc":let s=tr.value(time,1);x.sx*=s;x.sy*=s
            case "sx":x.sx*=tr.value(time,1)
            case "sy":x.sy*=tr.value(time,1)
            case "rot":x.rot+=tr.value(time,0)
            case "op":x.op*=tr.value(time,1)
            case "cr":if let n=node{x.corner=max(0,tr.value(time,Double(n.corner)))}
            case "bl":if let n=node{x.blur=max(0,tr.value(time,Double(n.softBlur)))}
            case "w":if let n=node{x.w=max(0,tr.value(time,Double(n.w)))}
            case "h":if let n=node{x.h=max(0,tr.value(time,Double(n.h)))}
            case "fill":if let(a,b,p)=tr.segment(time){let p=min(1,max(0,p));var result:UInt32=0;for shift in [0,8,16,24]{let a=Double((UInt32(truncatingIfNeeded:a.c)>>shift)&255),b=Double((UInt32(truncatingIfNeeded:b.c)>>shift)&255);result|=UInt32(min(255,max(0,(a+(b-a)*p).rounded())))<<shift};x.fill=Int64(Int32(bitPattern:result))}
            default:break
            }
        }
        return x
    }
    static func frame(_ source:Project,time:Double)->Project{
        guard let data=source.motion,!data.tracks.isEmpty else{return source}
        let t=min(Double(data.dur),max(0,time)),tracks=data.tracks.filter{!$0.keys.isEmpty}
        let nodeTracks=Dictionary(grouping:tracks.filter{!$0.group},by: \.ref)
        let groupTracks=Dictionary(grouping:tracks.filter{ $0.group},by: \.ref)
        let pivots=Dictionary(grouping:source.nodes.filter{!$0.group.isEmpty},by: \.group).mapValues{nodes in nodes.reduce(CGRect.null){$0.union($1.rect)}}
        let groups=groupTracks.mapValues{collect($0,t,nil)}
        var result=source
        result.nodes=source.nodes.map{n in
            let own=nodeTracks[n.id] ?? [],x=collect(own,t,n)
            var out=n
            var w=CGFloat(x.w ?? Double(n.w)),h=CGFloat(x.h ?? Double(n.h))
            var cx=n.x+w/2+CGFloat(x.x),cy=n.y+h/2+CGFloat(x.y)
            w*=CGFloat(x.sx);h*=CGFloat(x.sy)
            out.rotation+=CGFloat(x.rot);out.opacity*=CGFloat(x.op)
            var s=CGFloat(min(x.sx,x.sy))
            out.corner=CGFloat(x.corner ?? Double(n.corner*s));out.softBlur=CGFloat(x.blur ?? Double(n.softBlur*s))
            out.fill=x.fill ?? n.fill
            if let g=groups[n.group],let pivot=pivots[n.group]{
                let dx=(cx-pivot.midX)*CGFloat(g.sx),dy=(cy-pivot.midY)*CGFloat(g.sy),a=CGFloat(g.rot) * .pi/180
                cx=pivot.midX+dx*cos(a)-dy*sin(a)+CGFloat(g.x);cy=pivot.midY+dx*sin(a)+dy*cos(a)+CGFloat(g.y)
                w*=CGFloat(g.sx);h*=CGFloat(g.sy);out.rotation+=CGFloat(g.rot);out.opacity*=CGFloat(g.op)
                let gs=CGFloat(min(g.sx,g.sy));s*=gs;out.corner*=gs;out.softBlur*=gs
            }
            out.w=max(0,w);out.h=max(0,h);out.x=cx-out.w/2;out.y=cy-out.h/2;out.opacity=min(1,max(0,out.opacity))
            out.fontSize*=max(0,s);out.strokeWidth*=max(0,s);out.shadowBlur*=max(0,s);out.shadowDx*=s;out.shadowDy*=s
            out.cornerRadii=out.cornerRadii?.map{$0 < 0 ? $0:$0*max(0,s)}
            if let track=own.last(where:{$0.prop=="shape"}),let(a,b,p)=track.segment(t),n.kind=="SHAPE"{
                if a.s==b.s{out.shapeId=a.s}
                else if let morph=LinkMorph(from:a.s,to:b.s,size:CGSize(width:out.w,height:out.h)){out.kind="PATH";out.path=morph.svg(p);out.shapeId=""}
            }
            return out
        }
        return result
    }
}
