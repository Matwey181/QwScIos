import SwiftUI

struct TextEditPanel:View {
    @ObservedObject var editor:Editor
    let nodeID:String
    var close:()->Void
    @Environment(\.q) private var q
    @State private var draft=""
    @FocusState private var focused:Bool
    var body:some View {
        VStack(alignment:.leading,spacing:16) {
            Text("Редактировать текст").font(qfont(22,.semibold))
            TextEditor(text:$draft).font(qfont(18)).scrollContentBackground(.hidden)
                .focused($focused).accessibilityIdentifier("textEditorInput")
                .padding(10).frame(height:160)
                .overlay(RoundedRectangle(cornerRadius:16).stroke(q.color("outline")))
            HStack {
                Button("Отмена",action:close)
                Spacer()
                Button("Готово"){editor.commitText(nodeID,text:draft);close()}
                    .accessibilityIdentifier("textEditorDone")
            }.font(qfont(16,.semibold)).foregroundStyle(q.color("primary")).frame(minHeight:44)
        }.padding(24).qSurface(28,"surfaceContainerHigh")
        .onAppear{draft=editor.project.nodes.first{$0.id==nodeID}?.text ?? "";focused=true}
    }
}
