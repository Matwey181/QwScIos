import SwiftUI
import UIKit

struct RichTextInput:UIViewRepresentable {
    @Binding var text:String
    @Binding var runs:[TextRun]
    @Binding var selection:NSRange
    var node:Node
    var font:UIFont
    func makeCoordinator()->Coordinator{Coordinator(self)}
    func makeUIView(context:Context)->UITextView {
        let view=UITextView();view.backgroundColor = .clear;view.delegate=context.coordinator
        view.textContainerInset=UIEdgeInsets(top:10,left:8,bottom:10,right:8)
        view.accessibilityIdentifier="textEditorInput"
        DispatchQueue.main.async{view.becomeFirstResponder()};return view
    }
    func updateUIView(_ view:UITextView,context:Context){
        context.coordinator.parent=self;context.coordinator.updating=true
        var node=node;node.text=text;var extras=node.extras ?? LayerExtras();extras.runs=runs;node.extras=extras
        let attributed=TextLayout.attributed(node,font:font)
        if !view.attributedText.isEqual(to:attributed){view.attributedText=attributed;view.selectedRange=NSRange(location:min(selection.location,attributed.length),length:min(selection.length,max(0,attributed.length-selection.location)))}
        view.typingAttributes=attributed.length>0 ? attributed.attributes(at:max(0,min(attributed.length-1,view.selectedRange.location-1)),effectiveRange:nil):[.font:font,.foregroundColor:UIColor(argb:node.fill)]
        context.coordinator.updating=false
    }
    final class Coordinator:NSObject,UITextViewDelegate {
        var parent:RichTextInput
        var updating=false
        init(_ parent:RichTextInput){self.parent=parent}
        func textViewDidChangeSelection(_ view:UITextView){if !updating{parent.selection=view.selectedRange}}
        func textViewDidChange(_ view:UITextView){
            guard !updating else{return};parent.text=view.text;parent.selection=view.selectedRange
            var runs:[TextRun]=[]
            view.attributedText.enumerateAttributes(in:NSRange(location:0,length:view.attributedText.length)){attributes,range,_ in
                let font=attributes[.font] as? UIFont ?? self.parent.font
                let traits=font.fontDescriptor.symbolicTraits
                let color=(attributes[.foregroundColor] as? UIColor)?.argb
                runs.append(TextRun(start:range.location,length:range.length,weight:traits.contains(.traitBold) ? 700:400,italic:traits.contains(.traitItalic),color:color==self.parent.node.fill ? nil:color))
            }
            parent.runs=runs
        }
    }
}
