import UIKit
import CoreImage

// Port of the rounded-edge refraction found in Vexel 2.8.8's LiquidShader.
// Android's RuntimeShader is replaced by Core Image on iOS.
enum LiquidGlassRenderer {
    struct CacheKey:Equatable {
        var id:String
        var kind:String
        var rect:CGRect
        var rotation:CGFloat
        var corner:CGFloat
        var path:String
        var shape:String
        var liquid:CGFloat
        var blur:CGFloat
        var lower:[Node]
        var background:Int64
        var pageSize:CGSize
        var transform:CGAffineTransform
        var mode:Int
    }
    final class Cache {
        struct Entry {var key:CacheKey;var image:CGImage;var region:CGRect}
        private var entries:[String:Entry]=[:]
        private var cost=0
        private(set) var renderCount=0
        private(set) var hits=0
        func image(for key:CacheKey)->Entry? {
            guard let entry=entries[key.id],entry.key==key else{return nil}
            hits+=1;return entry
        }
        func insert(_ image:CGImage,region:CGRect,key:CacheKey){
            renderCount+=1
            if let old=entries.removeValue(forKey:key.id){cost-=old.image.bytesPerRow*old.image.height}
            let bytes=image.bytesPerRow*image.height
            guard bytes<=24*1024*1024 else{return}
            if entries.count>=24 || cost+bytes>24*1024*1024{entries.removeAll(keepingCapacity:true);cost=0}
            entries[key.id]=Entry(key:key,image:image,region:region);cost+=bytes
        }
    }
    static let kernel=CIWarpKernel(source:"""
    kernel vec2 qwelLiquid(vec2 center, vec2 size, float radius, float amount, float angle) {
        vec2 uv=destCoord();
        float c=cos(angle),s=sin(angle);
        vec2 delta=uv-center;
        vec2 p=vec2(c*delta.x+s*delta.y,-s*delta.x+c*delta.y);
        vec2 q=abs(p)-(size*0.5-vec2(radius));
        float distance=length(max(q,vec2(0.0)))+min(max(q.x,q.y),0.0)-radius;
        float band=max(1.0,min(size.x,size.y)*0.22);
        float t=clamp(1.0+distance/band,0.0,1.0);
        vec2 normal=normalize(sign(p)*(max(q,vec2(0.001)))+vec2(0.0001));
        vec2 world=vec2(c*normal.x-s*normal.y,s*normal.x+c*normal.y);
        float bend=(1.0-sqrt(max(0.0,1.0-t*t)))*amount*band*0.55;
        return uv-world*bend;
    }
    """)
    static func draw(_ node:Node,mode:Int,in context:CGContext,using ci:CIContext,cache:Cache,lower:[Node],background:Int64,pageSize:CGSize){
        guard node.liquid>0 || node.blur>0 else{return}
        let t=context.ctm
        let key=CacheKey(id:node.id,kind:node.kind,rect:node.rect,rotation:node.rotation,corner:node.corner,path:node.path,shape:node.shapeId,liquid:node.liquid,blur:node.blur,lower:lower,background:background,pageSize:pageSize,transform:t,mode:mode)
        if let cached=cache.image(for:key){composite(cached.image,region:cached.region,node:node,in:context);return}
        guard let bitmap=context.makeImage() else{return}
        let input=CIImage(cgImage:bitmap),extent=input.extent
        let region=VectorPath.world(node).boundingBoxOfPath.applying(t).integral.intersection(extent)
        guard !region.isNull,!region.isEmpty else{return}
        let sx=hypot(t.a,t.b),sy=hypot(t.c,t.d),scale=max(0.01,min(sx,sy))
        let center=node.center.applying(t),size=CGSize(width:node.w*sx,height:node.h*sy)
        let angle=atan2(t.b,t.a)-node.rotation * .pi/180
        let liquid=min(1,max(0,node.liquid)),simple=mode==2
        let blur=max(node.blur,liquid>0 ? (simple ? 9:3):0)*scale
        var output=input
        if blur>0,let filter=CIFilter(name:"CIGaussianBlur",parameters:[kCIInputImageKey:input.clampedToExtent(),kCIInputRadiusKey:min(150,blur)]),let image=filter.outputImage{output=image.cropped(to:extent)}
        if liquid>0 && !simple,let kernel{
            let radius=node.kind=="ELLIPSE" ? min(size.width,size.height)/2:min(node.corner*scale,min(size.width,size.height)/2)
            let margin=max(size.width,size.height)*0.3
            if let warped=kernel.apply(extent:extent,roiCallback:{_,rect in rect.insetBy(dx:-margin,dy:-margin)},image:output,arguments:[CIVector(x:center.x,y:center.y),CIVector(x:size.width,y:size.height),radius,liquid,angle]){output=warped}
        }
        guard let image=ci.createCGImage(output,from:region) else{return}
        cache.insert(image,region:region,key:key)
        composite(image,region:region,node:node,in:context)
    }
    private static func composite(_ image:CGImage,region:CGRect,node:Node,in context:CGContext){
        let t=context.ctm
        context.saveGState();context.addPath(VectorPath.world(node));context.clip();context.setAlpha(min(1,max(0,node.opacity)))
        context.concatenate(t.inverted());context.draw(image,in:region);context.restoreGState()
    }
    static func rim(_ node:Node,in context:CGContext){
        guard node.liquid>0 else{return}
        let path=VectorPath.local(node),strength=min(1,max(0,node.liquid))
        context.saveGState();context.addPath(path);context.clip()
        if let light=CGGradient(colorsSpace:CGColorSpaceCreateDeviceRGB(),colors:[UIColor.white.withAlphaComponent(0.38*strength).cgColor,UIColor.white.withAlphaComponent(0.02).cgColor,UIColor.black.withAlphaComponent(0.1*strength).cgColor] as CFArray,locations:[0,0.4,1]){
            context.drawLinearGradient(light,start:.zero,end:CGPoint(x:node.w,y:node.h),options:[])
        }
        context.restoreGState();context.addPath(path);context.setStrokeColor(UIColor.white.withAlphaComponent(0.4*strength).cgColor);context.setLineWidth(max(0.5,min(node.w,node.h)*0.01));context.strokePath()
    }
}
