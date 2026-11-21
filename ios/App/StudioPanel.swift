import SwiftUI

struct StudioPanel:View {
    @ObservedObject var editor:Editor
    @Environment(\.dismiss) private var dismiss
    @Environment(\.q) private var q
    @State private var tab="components"
    private let tabs=[("components","Компоненты"),("layout","Привязки"),("text","Текст"),("states","Состояния"),("timeline","Таймлайн"),("graph","Схема"),("image","Изображения"),("history","Версии"),("export","iOS-проект")]
    var body:some View {
        VStack(spacing:12){
            HStack{QIconButton(icon:"Back",label:"Закрыть студию"){dismiss()};Text("Студия").font(qfont(25,.semibold));Spacer();Button("Готово"){editor.saveNow();dismiss()}.font(qfont(15,.semibold))}.padding(.horizontal,12)
            ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){ForEach(tabs,id:\.0){item in QChip(title:item.1,selected:tab==item.0){tab=item.0}}}.padding(.horizontal,16)}
            ScrollView {content.padding(16)}.scrollDismissesKeyboard(.interactively)
        }.padding(.top,12).background(q.color("surfaceContainer").ignoresSafeArea()).foregroundStyle(q.color("onSurface"))
    }
    @ViewBuilder private var content:some View {
        switch tab {
        case "components":StudioComponents(editor:editor)
        case "layout":StudioLayout(editor:editor)
        case "text":StudioText(editor:editor)
        case "states":StudioStates(editor:editor)
        case "timeline":StudioTimeline(editor:editor)
        case "graph":StudioGraph(editor:editor)
        case "image":StudioImage(editor:editor)
        case "history":StudioHistory(editor:editor)
        default:StudioExport(editor:editor)
        }
    }
}
struct StudioCard<Content:View>:View {
    let title:String
    @ViewBuilder var content:()->Content
    @Environment(\.q) private var q
    var body:some View {VStack(alignment:.leading,spacing:14){Text(title).font(qfont(20,.semibold));content()}.frame(maxWidth:.infinity,alignment:.leading).padding(18).qSurface(28,"surfaceContainerHigh")}
}
