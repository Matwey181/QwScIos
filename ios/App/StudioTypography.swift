import UIKit

extension TextLayout {
    static func attributed(_ node:Node,font:UIFont)->NSAttributedString {
        let extras=node.extras ?? LayerExtras(),paragraph=NSMutableParagraphStyle()
        paragraph.alignment=node.textAlign=="center" ? .center:node.textAlign=="right" ? .right:.left
        paragraph.lineSpacing=extras.lineSpacing
        let string=NSMutableAttributedString(string:node.text,attributes:[.font:font,.foregroundColor:UIColor(argb:node.fill),.kern:extras.tracking,.paragraphStyle:paragraph])
        for run in extras.runs {
            let start=max(0,min(string.length,run.start)),length=max(0,min(run.length,string.length-start))
            guard length>0 else{continue}
            var traits:UIFontDescriptor.SymbolicTraits=[]
            if run.weight>=600{traits.insert(.traitBold)}
            if run.italic{traits.insert(.traitItalic)}
            let descriptor=font.fontDescriptor.withSymbolicTraits(traits) ?? font.fontDescriptor
            var attributes:[NSAttributedString.Key:Any]=[.font:UIFont(descriptor:descriptor,size:font.pointSize),.foregroundColor:UIColor(argb:run.color ?? node.fill)]
            if let color=run.color{attributes[.foregroundColor]=UIColor(argb:color)}
            string.addAttributes(attributes,range:NSRange(location:start,length:length))
        }
        return string
    }
}

enum StyledSVGText {
    static func line(_ node:Node,range:NSRange,defaultFill:String?=nil)->String {
        let string=node.text as NSString,start=max(0,min(string.length,range.location)),end=max(start,min(string.length,range.location+range.length))
        var boundaries=Set([start,end]);let runs=node.extras?.runs ?? []
        for run in runs {if run.start>start && run.start<end{boundaries.insert(run.start)};let last=run.start+run.length;if last>start && last<end{boundaries.insert(last)}}
        let positions=boundaries.sorted();var output=""
        for i in 0..<max(0,positions.count-1){
            let a=positions[i],b=positions[i+1],text=string.substring(with:NSRange(location:a,length:b-a)).trimmingCharacters(in:.newlines)
            let run=runs.last{$0.start<=a && $0.start+$0.length>a}
            let color=run?.color==nil && defaultFill != nil ? defaultFill!:String(format:"#%06X",UInt32(truncatingIfNeeded:run?.color ?? node.fill)&0xffffff)
            output += "<tspan font-weight=\"\(run?.weight ?? Int(node.weight))\" font-style=\"\(run?.italic==true ? "italic":"normal")\" fill=\"\(color)\">\(xml(text))</tspan>"
        }
        return output
    }
}
