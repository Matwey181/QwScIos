import UIKit
import CoreImage
import CoreText

final class DocumentRenderer {
    let root:URL
    private let images=NSCache<NSString,UIImage>()
    private let ci=CIContext(options:[.cacheIntermediates:false])
    init(root:URL) { self.root=root }
    func font(_ n:Node)->UIFont {
        if !n.font.isEmpty, let provider=CGDataProvider(url:root.appendingPathComponent("fonts").appendingPathComponent(n.font) as CFURL),let cg=CGFont(provider) {
            return CTFontCreateWithGraphicsFont(cg,max(1,n.fontSize),nil,nil) as UIFont
        }
        let weight:UIFont.Weight = n.weight>=700 ? .bold : n.weight>=600 ? .semibold : n.weight>=500 ? .medium : n.weight<=300 ? .light : .regular
        return UIFont.systemFont(ofSize:max(1,n.fontSize),weight:weight)
    }
    func image(_ name:String)->UIImage? {
        if let im=images.object(forKey:name as NSString) { return im }
        guard !name.contains("/"),let im=UIImage(contentsOfFile:root.appendingPathComponent("assets").appendingPathComponent(name).path) else { return nil }
        images.setObject(im,forKey:name as NSString,cost:Int(im.size.width*im.size.height*4));return im
    }
    func draw(_ p:Project,in ctx:CGContext,background:Bool=true,includeReferences:Bool=false) {
        UIGraphicsPushContext(ctx);defer { UIGraphicsPopContext() }
        if background { ctx.setFillColor(UIColor(argb:p.bg).cgColor);ctx.fill(CGRect(x:0,y:0,width:p.w,height:p.h)) }
        var i=0
        while i<p.nodes.count {
            let n=p.nodes[i]
            guard n.visible && (includeReferences || n.extras?.reference != true) else { i += 1;continue }
            if n.mask { i += 1;continue }
            ctx.saveGState()
            if i+1<p.nodes.count,p.nodes[i+1].mask,p.nodes[i+1].visible {
                ctx.addPath(VectorPath.world(p.nodes[i+1]));ctx.clip(using:p.nodes[i+1].evenOdd ? .evenOdd:.winding)
            }
            if n.blur>0,let snapshot=ctx.makeImage() {
                let input=CIImage(cgImage:snapshot)
                if let filter=CIFilter(name:"CIGaussianBlur",parameters:[kCIInputImageKey:input,kCIInputRadiusKey:min(100,n.blur)]),let result=filter.outputImage,let blurred=ci.createCGImage(result,from:input.extent) {
                    ctx.saveGState();ctx.addPath(VectorPath.world(n));ctx.clip();ctx.saveGState()
                    // Bitmap snapshots use pixel coordinates; map them back to
                    // the current document coordinate system before clipping.
                    let bounds=ctx.boundingBoxOfClipPath
                    ctx.translateBy(x:0,y:bounds.maxY+bounds.minY);ctx.scaleBy(x:1,y:-1)
                    ctx.draw(blurred,in:bounds);ctx.restoreGState();ctx.restoreGState()
                }
            }
            draw(n,in:ctx)
            ctx.restoreGState();i += 1
        }
    }
    func draw(_ n:Node,in ctx:CGContext,applyBlur:Bool=true) {
        guard n.w>0,n.h>0 else { return }
        ctx.saveGState();defer { ctx.restoreGState() }
        ctx.setAlpha(min(1,max(0,n.opacity)))
        ctx.translateBy(x:n.center.x,y:n.center.y);ctx.rotate(by:n.rotation * .pi/180);ctx.translateBy(x:-n.w/2,y:-n.h/2)
        if n.shadowBlur>0 { ctx.setShadow(offset:CGSize(width:n.shadowDx,height:n.shadowDy),blur:n.shadowBlur,color:UIColor(argb:n.shadowColor).cgColor) }
        if applyBlur && n.softBlur>0 && n.w*n.h<16_000_000 {
            let margin=min(200,n.softBlur*3)
            let format=UIGraphicsImageRendererFormat();format.scale=1
            let im=UIGraphicsImageRenderer(size:CGSize(width:n.w+2*margin,height:n.h+2*margin),format:format).image { target in
                target.cgContext.translateBy(x:margin-n.x,y:margin-n.y)
                var copy=n;copy.rotation=0;copy.softBlur=0;copy.opacity=1
                draw(copy,in:target.cgContext,applyBlur:false)
            }
            if let cg=im.cgImage {
                let input=CIImage(cgImage:cg)
                if let f=CIFilter(name:"CIGaussianBlur",parameters:[kCIInputImageKey:input,kCIInputRadiusKey:min(100,n.softBlur)]),let result=f.outputImage,let output=ci.createCGImage(result,from:input.extent) {
                    UIImage(cgImage:output).draw(in:CGRect(x:-margin,y:-margin,width:n.w+2*margin,height:n.h+2*margin));return
                }
            }
        }
        let rect=CGRect(x:0,y:0,width:n.w,height:n.h)
        if n.kind=="TEXT" {
            TextLayout(n,font:font(n)).draw()
            return
        }
        if n.kind=="IMAGE" {
            if let image=image(n.asset){
                let extras=n.extras ?? LayerExtras()
                if extras.imageMode=="stretch"{image.draw(in:rect)}else{
                    let sx=n.w/max(1,image.size.width),sy=n.h/max(1,image.size.height)
                    let ratio=(extras.imageMode=="fit" ? min(sx,sy):max(sx,sy))*max(0.1,extras.imageZoom)
                    let size=CGSize(width:image.size.width*ratio,height:image.size.height*ratio)
                    let target=CGRect(x:(n.w-size.width)*extras.cropX,y:(n.h-size.height)*extras.cropY,width:size.width,height:size.height)
                    ctx.clip(to:rect);image.draw(in:target)
                }
            };return
        }
        let path=VectorPath.local(n)
        if n.shadowBlur>0 && n.fillOpacity<1 {
            ctx.saveGState()
            let margin=max(100,n.shadowBlur*4+abs(n.shadowDx)+abs(n.shadowDy))
            ctx.addRect(rect.insetBy(dx:-margin,dy:-margin));ctx.addPath(path);ctx.clip(using:.evenOdd)
            ctx.addPath(path);ctx.setFillColor(UIColor(argb:n.fill).cgColor);ctx.fillPath();ctx.restoreGState()
            ctx.setShadow(offset:.zero,blur:0,color:nil)
        }
        ctx.setAlpha(min(1,max(0,n.opacity))*n.fillOpacity)
        ctx.addPath(path)
        if n.gradKind != 0,let gradient=CGGradient(colorsSpace:CGColorSpaceCreateDeviceRGB(),colors:[UIColor(argb:n.fill).cgColor,UIColor(argb:n.fill2).cgColor] as CFArray,locations:[0,1]) {
            ctx.saveGState();ctx.clip(using:n.evenOdd ? .evenOdd:.winding)
            if n.gradKind==2 { ctx.drawRadialGradient(gradient,startCenter:CGPoint(x:n.w/2,y:n.h/2),startRadius:0,endCenter:CGPoint(x:n.w/2,y:n.h/2),endRadius:max(n.w,n.h)/2,options:[.drawsAfterEndLocation]) }
            else { let a=n.gradAngle * .pi/180,dx=cos(a)*n.w/2,dy=sin(a)*n.h/2
                ctx.drawLinearGradient(gradient,start:CGPoint(x:n.w/2-dx,y:n.h/2-dy),end:CGPoint(x:n.w/2+dx,y:n.h/2+dy),options:[.drawsBeforeStartLocation,.drawsAfterEndLocation]) }
            ctx.restoreGState()
        } else { ctx.setFillColor(UIColor(argb:n.fill).cgColor);ctx.drawPath(using:n.evenOdd ? .eoFill:.fill) }
        ctx.setAlpha(min(1,max(0,n.opacity)))
        if n.strokeWidth>0 { ctx.addPath(path);ctx.setStrokeColor(UIColor(argb:n.stroke).cgColor);ctx.setLineWidth(n.strokeWidth);ctx.setLineJoin(.round);ctx.setLineCap(.round);ctx.strokePath() }
    }
    func sample(_ p:Project,at point:CGPoint)->Int64? {
        guard point.x>=0,point.y>=0,point.x<p.w,point.y<p.h,let data=png(p,scale:1,includeReferences:true),let cg=UIImage(data:data)?.cgImage,let crop=cg.cropping(to:CGRect(x:floor(point.x),y:floor(point.y),width:1,height:1)) else{return nil}
        var bytes=[UInt8](repeating:0,count:4)
        guard let context=CGContext(data:&bytes,width:1,height:1,bitsPerComponent:8,bytesPerRow:4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else{return nil}
        context.draw(crop,in:CGRect(x:0,y:0,width:1,height:1))
        let a=UInt32(bytes[3]);func channel(_ i:Int)->UInt32{a==0 ? 0:min(255,UInt32(bytes[i])*255/a)}
        return Int64(Int32(bitPattern:a<<24|channel(0)<<16|channel(1)<<8|channel(2)))
    }
    func png(_ p:Project,scale:CGFloat=2,includeReferences:Bool=false)->Data? {
        guard p.w*p.h*scale*scale<=40_000_000 else { return nil }
        let f=UIGraphicsImageRendererFormat();f.scale=scale;f.opaque=false
        return UIGraphicsImageRenderer(size:CGSize(width:p.w,height:p.h),format:f).pngData { target in draw(p,in:target.cgContext,includeReferences:includeReferences) }
    }
    func preview(_ p:Project)->UIImage {
        let scale=min(1,320/max(p.w,p.h)),f=UIGraphicsImageRendererFormat();f.scale=1
        return UIGraphicsImageRenderer(size:CGSize(width:max(1,p.w*scale),height:max(1,p.h*scale)),format:f).image { target in target.cgContext.scaleBy(x:scale,y:scale);draw(p,in:target.cgContext) }
    }
}
