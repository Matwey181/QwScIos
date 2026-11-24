import UIKit

enum CapsuleGeometry {
    static let ids:Set<String>=["pill-horizontal","pill-vertical","pill-diagonal"]
    static func path(_ id:String,width:CGFloat,height:CGFloat)->CGPath{
        let w=max(0.001,width),h=max(0.001,height)
        if id=="pill-diagonal"{
            let radius=min(w,h)*0.24
            let line=CGMutablePath()
            line.move(to:CGPoint(x:radius,y:h-radius))
            line.addLine(to:CGPoint(x:w-radius,y:radius))
            return line.copy(strokingWithWidth:radius*2,lineCap:.round,lineJoin:.round,miterLimit:4)
        }
        var rect=CGRect(x:0,y:0,width:w,height:h)
        if id=="pill-horizontal"{rect.size.height=min(h,w*0.4);rect.origin.y=(h-rect.height)/2}
        if id=="pill-vertical"{rect.size.width=min(w,h*0.4);rect.origin.x=(w-rect.width)/2}
        let radius=min(rect.width,rect.height)/2
        return CGPath(roundedRect:rect,cornerWidth:radius,cornerHeight:radius,transform:nil)
    }
    static func unitPath(_ id:String,width:CGFloat,height:CGFloat)->CGPath{
        guard ids.contains(id) else{return VectorPath.parse(Catalog.shared.shapes.first{$0.id==id}?.path ?? "")}
        var scale=CGAffineTransform(scaleX:1/max(0.001,width),y:1/max(0.001,height))
        let source=path(id,width:width,height:height)
        return source.copy(using:&scale) ?? source
    }
    static var catalog:[ShapeItem]{
        var horizontal=CGAffineTransform(translationX:0,y:0.3)
        var vertical=CGAffineTransform(translationX:0.3,y:0)
        let h=path("pill-horizontal",width:1,height:0.4).copy(using:&horizontal)!
        let v=path("pill-vertical",width:0.4,height:1).copy(using:&vertical)!
        return [
            ShapeItem(id:"pill-horizontal",name:"Таблетка · горизонтальная",category:"basic",path:VectorPath.string(h)),
            ShapeItem(id:"pill-vertical",name:"Таблетка · вертикальная",category:"basic",path:VectorPath.string(v)),
            ShapeItem(id:"pill-diagonal",name:"Таблетка · диагональная",category:"basic",path:VectorPath.string(path("pill-diagonal",width:1,height:1)))
        ]
    }
}
