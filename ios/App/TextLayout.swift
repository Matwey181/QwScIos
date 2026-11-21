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
    let isAndroidCatalogText: Bool
    private let horizontalOffset: CGFloat

    var height: CGFloat {
        max(lineHeight,ceil(max(manager.usedRect(for:container).maxY,
                                manager.extraLineFragmentRect.maxY)))
    }

    static func isAndroidCatalogText(_ node: Node) -> Bool {
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

    init(_ node: Node,font: UIFont) {
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
            : max(font.lineHeight,node.fontSize*1.25)
        let paragraph=NSMutableParagraphStyle()
        paragraph.lineBreakMode = isAndroidCatalogText ? .byClipping : .byWordWrapping
        paragraph.alignment=node.textAlign=="center" ? .center :
                            node.textAlign=="right" ? .right : .left
        paragraph.minimumLineHeight=lineHeight
        paragraph.maximumLineHeight=lineHeight
        storage=NSTextStorage(string:node.text,attributes:[
            .font:font,
            .foregroundColor:UIColor(argb:node.fill),
            .paragraphStyle:paragraph
        ])
        container=NSTextContainer(size:CGSize(width:width,height:1_000_000))
        container.lineFragmentPadding=0
        container.lineBreakMode=isAndroidCatalogText ? .byClipping : .byWordWrapping
        storage.addLayoutManager(manager)
        manager.addTextContainer(container)
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
        let origin=CGPoint(x:horizontalOffset,y:0)
        manager.drawBackground(forGlyphRange:range,at:origin)
        manager.drawGlyphs(forGlyphRange:range,at:origin)
    }
}
