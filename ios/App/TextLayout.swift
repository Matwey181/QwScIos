import UIKit

/// One layout for canvas, automatic frame height and SVG line wrapping.
final class TextLayout {
    let storage:NSTextStorage
    let manager=NSLayoutManager()
    let container:NSTextContainer
    let lineHeight:CGFloat
    var height:CGFloat { max(lineHeight,ceil(max(manager.usedRect(for:container).maxY,manager.extraLineFragmentRect.maxY))) }
    init(_ node:Node,font:UIFont) {
        lineHeight=max(font.lineHeight,node.fontSize*1.25)
        let paragraph=NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = node.textAlign=="center" ? .center : node.textAlign=="right" ? .right : .left
        paragraph.minimumLineHeight=lineHeight
        paragraph.maximumLineHeight=lineHeight
        storage=NSTextStorage(string:node.text,attributes:[.font:font,.foregroundColor:UIColor(argb:node.fill),.paragraphStyle:paragraph])
        container=NSTextContainer(size:CGSize(width:max(1,node.w),height:1_000_000))
        container.lineFragmentPadding=0
        container.lineBreakMode = .byWordWrapping
        storage.addLayoutManager(manager);manager.addTextContainer(container)
        manager.ensureLayout(for:container)
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
        manager.drawBackground(forGlyphRange:range,at:.zero)
        manager.drawGlyphs(forGlyphRange:range,at:.zero)
    }
}
