import SwiftUI

/// Shared sections embedded in the editor's existing controls.
struct StudioCard<Content:View>:View {
    let title:String
    @ViewBuilder var content:()->Content
    @Environment(\.q) private var q
    var body:some View {VStack(alignment:.leading,spacing:14){Text(title).font(qfont(20,.semibold));content()}.frame(maxWidth:.infinity,alignment:.leading).padding(18).qSurface(28,"surfaceContainerHigh")}
}
struct InlineSection<Content:View>:View {
    let title:String
    @ViewBuilder var content:()->Content
    @Environment(\.q) private var q
    @State private var expanded=false
    var body:some View {
        VStack(alignment:.leading,spacing:12){
            Button{withAnimation(.spring(response:0.35,dampingFraction:0.85)){expanded.toggle()}}label:{
                HStack{Text(title).font(qfont(15,.semibold));Spacer();Image(systemName:expanded ? "chevron.up":"chevron.down").font(.system(size:12,weight:.semibold))}.foregroundStyle(q.color("primary")).padding(16).frame(maxWidth:.infinity).qSurface(22,"surfaceContainerHighest")
            }.buttonStyle(.plain)
            if expanded{content()}
        }
    }
}
struct ProjectHistoryPanel:View {
    @ObservedObject var editor:Editor
    @Environment(\.dismiss) private var dismiss
    @Environment(\.q) private var q
    var body:some View {
        VStack(spacing:12){
            HStack{QIconButton(icon:"Back",label:"Назад"){dismiss()};Text("Версии проекта").font(qfont(23,.semibold));Spacer();Button("Готово"){dismiss()}.font(qfont(15,.semibold))}.padding(.horizontal,12)
            ScrollView{StudioHistory(editor:editor).padding(16)}.scrollDismissesKeyboard(.interactively)
        }.padding(.top,12).background(q.color("surfaceContainer").ignoresSafeArea())
    }
}
