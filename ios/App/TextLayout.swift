import UIKit

/// Common text layout used by the canvas, text editing and SVG output.
/// Android catalog templates were generated on the JVM with an approximate
/// width (0.55 × font size × characters) but Android renders each explicit
/// newline without implicit wrapping. Preserve that geometry on iOS while
/// keeping normal word wrapping for text created/resized in the editor.
final class TextLayout {
    let storage: NSTextStorage
    let manager = NSLayoutManager()
    let container: NSTextContainer
    let lineHeight: CGFloat
    let resolvedFont:UIFont
    let isAndroidCatalogText: Bool
    private let horizontalOffset: CGFloat
    private let node:Node
    private let frameHeight:CGFloat

    var height: CGFloat {
        max(lineHeight,ceil(max(manager.usedRect(for:container).maxY,
                                manager.extraLineFragmentRect.maxY)))
    }

    static func isAndroidCatalogText(_ node: Node) -> Bool {
        if node.fixW || node.fixH{return false}
        if let extras=node.extras,extras.tracking != 0 || extras.lineSpacing != 0 || extras.autoFit || !extras.runs.isEmpty{return false}
        guard node.kind == "TEXT", !node.text.isEmpty, node.fontSize > 0 else { return false }
        let lines=node.text.components(separatedBy:"\n")
        let longest=lines.map { $0.utf16.count }.max() ?? 0
        let estimated=CGFloat(longest) * node.fontSize * 0.55
        let expectedHeight=CGFloat(lines.count) * node.fontSize * 1.25
        // Compare both values; a regular text layer with a narrow frame
        // must still wrap. Also recognizes templates created in older versions.
        return abs(node.w-estimated) <= max(0.2, estimated * 0.0002) &&
               abs(node.h-expectedHeight) <= max(0.2, expectedHeight * 0.0002)
    }

    init(_ node: Node,font sourceFont: UIFont) {
        self.node=node;frameHeight=node.h
        var font=sourceFont
        if node.extras?.autoFit==true || node.fixH {
            var low:CGFloat=4,high=max(4,sourceFont.pointSize)
            for _ in 0..<12 {
                let mid=(low+high)/2,candidate=sourceFont.withSize(mid)
                let text=Self.attributed(node,font:candidate)
                let bounds=text.boundingRect(with:CGSize(width:max(1,node.w),height:1_000_000),options:[.usesLineFragmentOrigin,.usesFontLeading],context:nil)
                if bounds.height<=node.h && bounds.width<=node.w+1{low=mid}else{high=mid}
            }
            font=sourceFont.withSize(low)
        }
        resolvedFont=font
        isAndroidCatalogText=Self.isAndroidCatalogText(node)
        let explicitLines=node.text.components(separatedBy:"\n")
        let measuredWidth=explicitLines.map {
            ($0 as NSString).size(withAttributes:[.font:font]).width
        }.max() ?? 0
        let width=isAndroidCatalogText
            ? max(node.w,ceil(measuredWidth)+4)
            : max(1,node.w)
        horizontalOffset=isAndroidCatalogText
            ? (node.textAlign=="center" ? (node.w-width)/2 :
               node.textAlign=="right" ? (node.w-width) : 0)
            : 0
        lineHeight=isAndroidCatalogText
            ? node.fontSize * 1.25
            : max(font.lineHeight,font.pointSize*1.25)
        let paragraph=NSMutableParagraphStyle()
        paragraph.lineBreakMode = isAndroidCatalogText ? .byClipping : .byWordWrapping
        paragraph.alignment=node.textAlign=="center" ? .center :
                            node.textAlign=="right" ? .right : .left
        paragraph.minimumLineHeight=lineHeight
        paragraph.maximumLineHeight=lineHeight
        paragraph.lineSpacing=node.extras?.lineSpacing ?? 0
        storage=NSTextStorage(attributedString:Self.attributed(node,font:font))
        storage.addAttribute(.paragraphStyle,value:paragraph,range:NSRange(location:0,length:storage.length))
        container=NSTextContainer(size:CGSize(width:width,height:1_000_000))
        container.lineFragmentPadding=0
        container.lineBreakMode=isAndroidCatalogText ? .byClipping : .byWordWrapping
        storage.addLayoutManager(manager)
        manager.addTextContainer(container)
        manager.ensureLayout(for:container)
    }

    var ranges:[NSRange]{
        var result:[NSRange]=[]
        manager.enumerateLineFragments(forGlyphRange:manager.glyphRange(for:container)){_,_,_,range,_ in result.append(self.manager.characterRange(forGlyphRange:range,actualGlyphRange:nil))}
        return result
    }
    var lines:[String] {
        var result:[String]=[]
        manager.enumerateLineFragments(forGlyphRange:manager.glyphRange(for:container)) { _,_,_,range,_ in
            let chars=self.manager.characterRange(forGlyphRange:range,actualGlyphRange:nil)
            result.append((self.storage.string as NSString).substring(with:chars).trimmingCharacters(in:.newlines))
        }
        return result
    }

    func draw() {
        let range=manager.glyphRange(for:container)
        let y=node.textVAlign==1 ? max(0,(frameHeight-height)/2):node.textVAlign==2 ? max(0,frameHeight-height):0
        let origin=CGPoint(x:horizontalOffset,y:y)
        guard let context=UIGraphicsGetCurrentContext(),node.gradKind != 0 else{manager.drawBackground(forGlyphRange:range,at:origin);manager.drawGlyphs(forGlyphRange:range,at:origin);return}
        context.saveGState();context.beginTransparencyLayer(auxiliaryInfo:nil)
        manager.drawGlyphs(forGlyphRange:range,at:origin)
        context.setBlendMode(.sourceIn)
        if let gradient=CGGradient(colorsSpace:CGColorSpaceCreateDeviceRGB(),colors:[UIColor(argb:node.fill).cgColor,UIColor(argb:node.fill2).cgColor] as CFArray,locations:[0,1]){
            if node.gradKind==2{context.drawRadialGradient(gradient,startCenter:CGPoint(x:node.w/2,y:frameHeight/2),startRadius:0,endCenter:CGPoint(x:node.w/2,y:frameHeight/2),endRadius:max(node.w,frameHeight)/2,options:[.drawsAfterEndLocation])}
            else{let angle=node.gradAngle * .pi/180,dx=cos(angle)*node.w/2,dy=sin(angle)*frameHeight/2;context.drawLinearGradient(gradient,start:CGPoint(x:node.w/2-dx,y:frameHeight/2-dy),end:CGPoint(x:node.w/2+dx,y:frameHeight/2+dy),options:[.drawsBeforeStartLocation,.drawsAfterEndLocation])}
        }
        context.endTransparencyLayer();context.restoreGState()
    }
}
