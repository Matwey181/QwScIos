import SwiftUI

/// A single styled entry point for all project links; no system Forms or Pickers.
struct InteractionEditorPanel:View {
    @ObservedObject var editor:Editor
    var sourceID:String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.q) private var q
    private var source:Node {editor.project.nodes.first{$0.id==sourceID} ?? Node()}
    var body:some View {
        VStack(spacing:0){
            HStack(spacing:12){
                QIconButton(icon:"Back",label:"Закрыть связки"){dismiss()}.qSurface(26,"surfaceContainerHigh")
                VStack(alignment:.leading,spacing:3){Text("Связки").font(qfont(25,.semibold));Text("Движение и реакции").font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"))}
                Spacer(minLength:0)
                Button{dismiss()}label:{Text("Готово").font(qfont(14,.semibold)).padding(.horizontal,20).padding(.vertical,14).qSurface(26,"primaryContainer")}.buttonStyle(.plain)
            }.padding(16)
            ScrollView{
                VStack(alignment:.leading,spacing:16){
                    LinkRulesEditor(editor:editor,source:source)
                    InlineSection(title:"Состояния и переходы"){StudioStates(editor:editor)}
                    InlineSection(title:"Таймлайн анимаций"){StudioTimeline(editor:editor)}
                    InlineSection(title:"Схема и проблемы связок"){StudioGraph(editor:editor)}
                }.padding(.horizontal,16).padding(.bottom,28)
            }.scrollDismissesKeyboard(.interactively)
        }.background(q.color("surfaceContainer").ignoresSafeArea()).foregroundStyle(q.color("onSurface"))
    }
}
