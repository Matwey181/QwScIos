import Foundation

enum ExportedKeyframeSource {
    static var code:String{
        let core=Bundle.main.url(forResource:"motion-core",withExtension:"txt").flatMap{try? String(contentsOf:$0,encoding:.utf8)} ?? ""
        return core+runtime
    }
    private static let runtime = #"""
private struct QwelTimelineLayer:Decodable {
    var id:String;var x:Double;var y:Double;var w:Double;var h:Double
    var rot:Double;var op:Double;var corner:Double;var fill:Int64;var group:String
}
private struct QwelTimelinePage:Decodable{var nodes:[QwelTimelineLayer]}
private struct QwelTimelineDocument:Decodable{var nodes:[QwelTimelineLayer];var pages:[QwelTimelinePage];var motion:MotionData?}
@MainActor private final class QwelKeyframePlayer {
    private var document:QwelTimelineDocument?
    private var started=CACurrentMediaTime()
    private var fired:Set<Int>=[]
    var values:[String:Double]=[:]
    var paths:[String:Path]=[:]
    var morphs:[String:[Double]]=[:]
    var onNavigate:((String)->Void)?
    var active:Bool{document?.motion.map{!$0.tracks.isEmpty || !$0.jumps.isEmpty} ?? false}
    func configure(_ base64:String,_ morphs:[String:[Double]]){
        document=Data(base64Encoded:base64).flatMap{try? JSONDecoder().decode(QwelTimelineDocument.self,from:$0)}
        self.morphs=morphs;started=CACurrentMediaTime();fired=[]
    }
    func tick(_ now:Double){
        guard let doc=document,let motion=doc.motion else{return}
        let elapsed=max(0,(now-started)*1000),duration=Double(max(1,motion.dur)),t=motion.loop ? elapsed.truncatingRemainder(dividingBy:duration):min(elapsed,duration)
        if motion.loop && t<10{fired=[]}
        for (i,jump) in motion.jumps.enumerated() where Double(jump.t)<=t && !fired.contains(i){fired.insert(i);onNavigate?(jump.to)}
        let all=doc.pages.flatMap(\.nodes)+doc.nodes
        let nodes=Array(Dictionary(all.map{($0.id,$0)},uniquingKeysWith:{_,b in b}).values)
        var next:[String:Double]=[:]
        for n in nodes{
            let own=motion.tracks.filter{!$0.group && $0.ref==n.id},group=motion.tracks.filter{$0.group && $0.ref==n.group && !n.group.isEmpty}
            let x=transform(own,t,n),g=transform(group,t,n)
            let baseW=x["w"] ?? n.w,baseH=x["h"] ?? n.h,sx=(x["sx"] ?? 1)*(g["sx"] ?? 1),sy=(x["sy"] ?? 1)*(g["sy"] ?? 1)
            var cx=n.x+baseW/2+(x["x"] ?? 0),cy=n.y+baseH/2+(x["y"] ?? 0)
            if !group.isEmpty{
                let members=nodes.filter{$0.group==n.group}
                let minX=members.map(\.x).min() ?? n.x,maxX=members.map{$0.x+$0.w}.max() ?? n.x+n.w
                let minY=members.map(\.y).min() ?? n.y,maxY=members.map{$0.y+$0.h}.max() ?? n.y+n.h
                let px=(minX+maxX)/2,py=(minY+maxY)/2,dx=(cx-px)*(g["sx"] ?? 1),dy=(cy-py)*(g["sy"] ?? 1),a=(g["rot"] ?? 0) * .pi/180
                cx=px+dx*cos(a)-dy*sin(a)+(g["x"] ?? 0);cy=py+dx*sin(a)+dy*cos(a)+(g["y"] ?? 0)
            }
            next[n.id+"|x"]=cx-n.w/2;next[n.id+"|y"]=cy-n.h/2
            next[n.id+"|width"]=max(0,baseW*sx);next[n.id+"|height"]=max(0,baseH*sy)
            next[n.id+"|rotation"]=n.rot+(x["rot"] ?? 0)+(g["rot"] ?? 0)
            next[n.id+"|opacity"]=min(1,max(0,n.op*(x["op"] ?? 1)*(g["op"] ?? 1)))
            if let corner=x["cr"]{next[n.id+"|corner"]=max(0,corner)/max(0.001,min(sx,sy))}
            if let blur=x["bl"]{next[n.id+"|blur"]=max(0,blur)/max(0.001,min(sx,sy))}
            for tr in own where tr.prop=="fill"{if let(a,b,p)=tr.segment(t){next[n.id+"|fill"]=Double(color(a.c,b.c,min(1,max(0,p))))}}
            if let tr=own.last(where:{$0.prop=="shape"}),let(a,b,p)=tr.segment(t),let from=morphs[n.id+"|"+a.s+"|"+b.s+"|a"],let to=morphs[n.id+"|"+a.s+"|"+b.s+"|b"],from.count==to.count,from.count>=8{
                let v=zip(from,to).map{$0+($1-$0)*p};var path=Path();path.move(to:CGPoint(x:v[0]*n.w,y:v[1]*n.h))
                for i in stride(from:0,to:v.count-7,by:8){path.addCurve(to:CGPoint(x:v[i+6]*n.w,y:v[i+7]*n.h),control1:CGPoint(x:v[i+2]*n.w,y:v[i+3]*n.h),control2:CGPoint(x:v[i+4]*n.w,y:v[i+5]*n.h))};path.closeSubpath();paths[n.id]=path
            }
        }
        values=next
    }
    private func transform(_ tracks:[MotionTrack],_ t:Double,_ n:QwelTimelineLayer)->[String:Double]{
        var x:[String:Double]=["sx":1,"sy":1,"op":1]
        for tr in tracks{let p=tr.prop
            switch p{
            case "x","y","rot":x[p,default:0]+=tr.value(t,0)
            case "sc":let s=tr.value(t,1);x["sx",default:1]*=s;x["sy",default:1]*=s
            case "sx","sy","op":x[p,default:1]*=tr.value(t,1)
            case "cr","bl","w","h":x[p]=tr.value(t,p=="cr" ? n.corner:p=="w" ? n.w:p=="h" ? n.h:0)
            default:break
            }
        };return x
    }
    private func color(_ a:Int64,_ b:Int64,_ t:Double)->Int64{
        var raw:UInt32=0
        for shift in [0,8,16,24]{let x=Double((UInt32(truncatingIfNeeded:a)>>shift)&255),y=Double((UInt32(truncatingIfNeeded:b)>>shift)&255);raw|=UInt32(min(255,max(0,(x+(y-x)*t).rounded())))<<shift}
        return Int64(Int32(bitPattern:raw))
    }
}
"""#
}
