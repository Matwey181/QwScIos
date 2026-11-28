import SwiftUI
import AVFoundation
import ZIPFoundation

@MainActor final class CanvasVideoWriter {
    let url:URL
    let size:CGSize
    private let writer:AVAssetWriter
    private let input:AVAssetWriterInput
    private let adaptor:AVAssetWriterInputPixelBufferAdaptor
    private var cancelled=false
    var ready:Bool{input.isReadyForMoreMediaData && writer.status == .writing}
    init(project:Project,longEdge:Int,fps:Int)throws{
        let scale=CGFloat(longEdge)/max(project.w,project.h)
        size=CGSize(width:max(2,(Int(project.w*scale)/2)*2),height:max(2,(Int(project.h*scale)/2)*2))
        url=FileManager.default.temporaryDirectory.appendingPathComponent("Qwel-\(UUID().uuidString).mp4")
        writer=try AVAssetWriter(outputURL:url,fileType:.mp4)
        let settings:[String:Any]=[AVVideoCodecKey:AVVideoCodecType.h264,AVVideoWidthKey:Int(size.width),AVVideoHeightKey:Int(size.height),AVVideoCompressionPropertiesKey:[AVVideoAverageBitRateKey:Int(size.width*size.height)*fps/6,AVVideoExpectedSourceFrameRateKey:fps,AVVideoMaxKeyFrameIntervalKey:fps*2]]
        input=AVAssetWriterInput(mediaType:.video,outputSettings:settings)
        input.expectsMediaDataInRealTime=false
        adaptor=AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:input,sourcePixelBufferAttributes:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA,kCVPixelBufferWidthKey as String:Int(size.width),kCVPixelBufferHeightKey as String:Int(size.height),kCVPixelBufferCGImageCompatibilityKey as String:true,kCVPixelBufferCGBitmapContextCompatibilityKey as String:true])
        guard writer.canAdd(input)else{throw CocoaError(.featureUnsupported)}
        writer.add(input)
        guard writer.startWriting()else{throw writer.error ?? CocoaError(.fileWriteUnknown)}
        writer.startSession(atSourceTime:.zero)
    }
    func append(_ project:Project,renderer:DocumentRenderer,time:CMTime,touch:CGPoint?=nil)throws{
        guard !cancelled,ready else{throw writer.error ?? CocoaError(.fileWriteUnknown)}
        var buffer:CVPixelBuffer?
        guard let pool=adaptor.pixelBufferPool,CVPixelBufferPoolCreatePixelBuffer(nil,pool,&buffer)==kCVReturnSuccess,let buffer else{throw CocoaError(.fileWriteOutOfSpace)}
        CVPixelBufferLockBaseAddress(buffer,[]);defer{CVPixelBufferUnlockBaseAddress(buffer,[])}
        guard let context=CGContext(data:CVPixelBufferGetBaseAddress(buffer),width:Int(size.width),height:Int(size.height),bitsPerComponent:8,bytesPerRow:CVPixelBufferGetBytesPerRow(buffer),space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue)else{throw CocoaError(.fileWriteUnknown)}
        context.setFillColor(UIColor.black.cgColor);context.fill(CGRect(origin:.zero,size:size))
        context.translateBy(x:0,y:size.height);context.scaleBy(x:size.width/project.w,y:-size.height/project.h)
        UIGraphicsPushContext(context);defer{UIGraphicsPopContext()}
        renderer.draw(project,in:context)
        if let touch{context.setFillColor(UIColor.white.withAlphaComponent(0.22).cgColor);context.setStrokeColor(UIColor.white.withAlphaComponent(0.8).cgColor);context.setLineWidth(1.5);context.addEllipse(in:CGRect(x:touch.x-12,y:touch.y-12,width:24,height:24));context.drawPath(using:.fillStroke)}
        guard adaptor.append(buffer,withPresentationTime:time)else{throw writer.error ?? CocoaError(.fileWriteUnknown)}
    }
    func finish()async throws->URL{
        input.markAsFinished();await writer.finishWriting()
        guard writer.status == .completed else{throw writer.error ?? CocoaError(.fileWriteUnknown)}
        return url
    }
    func waitUntilReady()async throws{
        while !ready{
            try Task.checkCancellation()
            if writer.status == .failed || writer.status == .cancelled{throw writer.error ?? CocoaError(.fileWriteUnknown)}
            try await Task.sleep(for:.milliseconds(2))
        }
    }
    func cancel(){cancelled=true;writer.cancelWriting();try? FileManager.default.removeItem(at:url)}
}

enum PageVideoFrames {
    static func frame(_ project:Project,time:Double,allPages:Bool)->Project{
        let duration=Double(project.motion?.dur ?? 3000)
        guard allPages,project.pages.count>1 else{return MotionEvaluator.frame(project,time:time)}
        let index=min(project.pages.count-1,max(0,Int(time/duration))),local=time-Double(index)*duration
        var current=project;current.nodes=project.pages[index].nodes
        if index==project.active{current.nodes=project.nodes}
        let result=MotionEvaluator.frame(current,time:local)
        guard index>0,local<min(700,duration*0.25)else{return result}
        var previous=project;previous.nodes=project.pages[index-1].nodes
        previous=MotionEvaluator.frame(previous,time:duration)
        let p=CGFloat(MotionCurve.at(MotionCurve.emphasized,local/min(700,duration*0.25)))
        var out=result
        let old=Dictionary(previous.nodes.map{($0.id,$0)},uniquingKeysWith:{_,b in b})
        let nextIDs=Set(result.nodes.map(\.id))
        out.nodes=previous.nodes.filter{!nextIDs.contains($0.id)}.map{n in var n=n;n.opacity*=1-p;return n}
        out.nodes+=result.nodes.map{n in
            var n=n
            if let a=old[n.id]{n.x=a.x+(n.x-a.x)*p;n.y=a.y+(n.y-a.y)*p;n.w=a.w+(n.w-a.w)*p;n.h=a.h+(n.h-a.h)*p;n.rotation=a.rotation+(n.rotation-a.rotation)*p;n.corner=a.corner+(n.corner-a.corner)*p;n.opacity=a.opacity+(n.opacity-a.opacity)*p}
            else{n.opacity*=p}
            return n
        }
        return out
    }
}

struct MotionVideoPanel:View {
    @ObservedObject var editor:Editor
    @Environment(\.dismiss) private var dismiss
    @Environment(\.q) private var q
    @State private var edge="1080"
    @State private var fps="60"
    @State private var allPages=false
    @State private var format="mp4"
    @State private var progress:Double?
    @State private var shared:SharedFile?
    @State private var task:Task<Void,Never>?
    var body:some View{
        NavigationStack{ScrollView{VStack(alignment:.leading,spacing:20){
            Text("Видео проекта").font(qfont(28,.semibold))
            LinkChoiceField(title:"Формат",selection:$format,items:[("mp4","MP4 · H.264"),("png","Последовательность PNG")])
            LinkChoiceField(title:"Длинная сторона",selection:$edge,items:[("720","720 px"),("1080","1080 px"),("1440","1440 px"),("2160","2160 px")])
            LinkChoiceField(title:"Частота кадров",selection:$fps,items:[("24","24 FPS"),("30","30 FPS"),("60","60 FPS")])
            if editor.project.pages.count>1{QToggle("Все экраны с плавными переходами",isOn:$allPages)}
            Text("Сохраняются ключевые анимации, текст, размытие и стекло. После экспорта файл можно сохранить через «Поделиться».").font(qfont(14))
            if let progress{ProgressView(value:progress);Text("\(Int(progress*100))%").monospacedDigit();Button("Отменить"){task?.cancel()}}
            else{LinkPill(title:"Экспортировать",icon:"film",prominent:true){export()}}
        }.padding(24)}.background(q.color("surface")).toolbar{ToolbarItem(placement:.topBarTrailing){Button("Готово"){dismiss()}.disabled(progress != nil)}}}
        .sheet(item:$shared){ShareSheet(urls:[$0.url])}
        .interactiveDismissDisabled(progress != nil)
        .onDisappear{task?.cancel()}
    }
    private func export(){
        progress=0
        let project=editor.project,framesPerSecond=Int(fps) ?? 60,longEdge=Int(edge) ?? 1080,all=allPages,png=format=="png"
        task=Task{@MainActor in
            var writer:CanvasVideoWriter?
            let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer{try? FileManager.default.removeItem(at:folder);progress=nil}
            do{
                let duration=Double(project.motion?.dur ?? 3000)/1000*Double(all ? max(1,project.pages.count):1)
                let count=max(1,Int(ceil(duration*Double(framesPerSecond))))
                let render=DocumentRenderer(root:editor.store.root)
                if png{try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)}else{writer=try CanvasVideoWriter(project:project,longEdge:longEdge,fps:framesPerSecond)}
                for index in 0..<count{
                    try Task.checkCancellation()
                    let ms=Double(index)*1000/Double(framesPerSecond)
                    let frame=PageVideoFrames.frame(project,time:ms,allPages:all)
                    if png{
                        guard let bytes=render.png(frame,scale:CGFloat(longEdge)/max(project.w,project.h))else{throw CocoaError(.fileWriteUnknown)}
                        try bytes.write(to:folder.appendingPathComponent(String(format:"frame-%06d.png",index)))
                    }else if let writer{try await writer.waitUntilReady();try writer.append(frame,renderer:render,time:CMTime(value:Int64(index),timescale:Int32(framesPerSecond)))}
                    progress=Double(index+1)/Double(count)
                    if index%3==0{await Task.yield()}
                }
                if let writer{shared=SharedFile(url:try await writer.finish())}
                else{let zip=FileManager.default.temporaryDirectory.appendingPathComponent("Qwel-frames-\(UUID().uuidString).zip");try FileManager.default.zipItem(at:folder,to:zip);shared=SharedFile(url:zip)}
            }catch{writer?.cancel();if !(error is CancellationError){editor.error=error.localizedDescription}}
        }
    }
}

@MainActor final class CanvasRecorder:NSObject,ObservableObject {
    @Published private(set) var recording=false
    private var writer:CanvasVideoWriter?
    private var link:CADisplayLink?
    private var started=0.0
    private weak var editor:Editor?
    private var touched:(CGPoint,Double)?
    func touch(_ point:CGPoint){touched=(point,CACurrentMediaTime())}
    func start(_ editor:Editor,longEdge:Int=1080)throws{
        guard !recording else{return}
        self.editor=editor;writer=try CanvasVideoWriter(project:editor.project,longEdge:longEdge,fps:60);started=CACurrentMediaTime();recording=true
        let link=CADisplayLink(target:self,selector:#selector(frame));link.preferredFramesPerSecond=60;link.add(to:.main,forMode:.common);self.link=link
    }
    @objc private func frame(){
        guard let editor,let writer,writer.ready else{return}
        let now=CACurrentMediaTime()
        do{try writer.append(editor.originalPlay.display ?? editor.project,renderer:editor.renderer,time:CMTime(seconds:now-started,preferredTimescale:60000),touch:touched.flatMap{now-$0.1<0.35 ? $0.0:nil})}
        catch{cancel();editor.error=error.localizedDescription}
    }
    func finish()async throws->URL{
        link?.invalidate();link=nil;recording=false
        guard let writer else{throw CocoaError(.fileWriteUnknown)}
        self.writer=nil;return try await writer.finish()
    }
    func cancel(){link?.invalidate();link=nil;writer?.cancel();writer=nil;recording=false}
}
