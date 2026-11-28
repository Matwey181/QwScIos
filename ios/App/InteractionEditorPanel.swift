import SwiftUI

/// Full-screen node editor for interaction links. The rules themselves stay in
/// Project.links; the graph is only a spatial, editable representation of them.
struct InteractionEditorPanel:View {
    @ObservedObject var editor:Editor
    var sourceID:String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.q) private var q
    private var source:Node {editor.project.nodes.first{$0.id==sourceID} ?? Node()}
    var body:some View {
        VStack(spacing:0){
            HStack(spacing:12){
                QIconButton(icon:"Back",label:"Закрыть связки"){dismiss()}.qSurface(24,"surfaceContainerHigh")
                VStack(alignment:.leading,spacing:2){
                    Text("Связки").font(qfont(23,.semibold))
                    Text(source.name.isEmpty ? "Объект":source.name).font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"))
                }
                Spacer(minLength:0)
                Text("\(editor.links(for:source).count)").font(qfont(13,.semibold)).foregroundStyle(q.color("onPrimaryContainer")).frame(minWidth:32,minHeight:32).qSurface(16,"primaryContainer")
                Button{dismiss()}label:{Text("Готово").font(qfont(14,.semibold)).padding(.horizontal,18).frame(height:44).foregroundStyle(q.color("onPrimaryContainer")).qSurface(22,"primaryContainer")}.buttonStyle(QPressStyle())
            }.padding(.horizontal,14).padding(.vertical,10).background(q.color("surfaceContainerHigh"))
            LinkGraphEditor(editor:editor,source:source)
        }.background(q.color("surface").ignoresSafeArea()).foregroundStyle(q.color("onSurface"))
    }
}
