import SwiftUI
import UniformTypeIdentifiers

@main struct QwelApp:App {
    @StateObject private var store=ProjectStore()
    init(){PromoCapture.configure()}
    var body:some Scene {
        WindowGroup { Group{if PromoCapture.enabled{PromoCaptureRoot(store:store)}else{ProjectsView()}}.environmentObject(store).modifier(OriginalTheme())
            .onOpenURL { url in Task { await store.importFile(url) } }
        }
    }
}
struct ProjectsView:View {
    @EnvironmentObject var store:ProjectStore
    @Environment(\.q) var q
    @State private var creating=false
    @State private var settings=false
    @State private var importing=false
    @State private var opened:Project?
    @State private var query=""
    @State private var shared:SharedFile?
    @State private var renaming:Project?
    @State private var rename=""
    @State private var deleting:Project?
    @AppStorage("projectSort") private var sort=0
    @AppStorage("projectList") private var list=false
    private var filtered:[Project] {
        let p=store.projects.filter{query.isEmpty || $0.name.localizedCaseInsensitiveContains(query)}
        return sort==1 ? p.sorted{$0.name.localizedCompare($1.name) == .orderedAscending}:sort==2 ? p.sorted{$0.w*$0.h>$1.w*$1.h}:p.sorted{$0.updated>$1.updated}
    }
    var body:some View {
        ZStack(alignment:.bottomTrailing) {
            q.color("surface").ignoresSafeArea()
            ScrollView {
                VStack(spacing:12) {
                    header.padding(.vertical,4)
                    if store.projects.isEmpty { empty }
                    else {
                        searchAndSort
                        LazyVGrid(columns:list ? [GridItem(.flexible())]:[GridItem(.adaptive(minimum:168),spacing:12)],spacing:12) {
                            ForEach(filtered) { project in card(project) }
                        }
                        if filtered.isEmpty { Text("Ничего не найдено").font(qfont(16)).foregroundStyle(q.color("onSurfaceVariant")).padding(.vertical,40) }
                    }
                }.padding(.horizontal,16).padding(.top,12).padding(.bottom,112)
            }
            Button { creating=true } label:{ HStack(spacing:12) { QIcon(id:"Add",tint:q.color("onPrimaryContainer"));Text("Новый проект").font(qfont(14,.semibold)) }.padding(.horizontal,20).frame(height:56).background(q.color("primaryContainer"),in:RoundedRectangle(cornerRadius:20)) }.buttonStyle(QPressStyle()).accessibilityIdentifier("newProject").padding(16)
        }
        .fullScreenCover(isPresented:$creating) { NewProjectView { p in creating=false;DispatchQueue.main.asyncAfter(deadline:.now()+0.35){opened=p} }.environmentObject(store).modifier(OriginalTheme()) }
        .fullScreenCover(isPresented:$settings) { SettingsView().modifier(OriginalTheme()) }
        .fullScreenCover(item:$opened) { p in EditorScreen(project:p,store:store).modifier(OriginalTheme()) }
        .sheet(isPresented:$importing) {
            ProjectDocumentPicker(picked:{url in importing=false;Task{await store.importFile(url)}},cancelled:{importing=false})
                .ignoresSafeArea()
        }
        .sheet(item:$shared) { ShareSheet(urls:[$0.url]) }
        .alert("Переименовать",isPresented:Binding(get:{renaming != nil},set:{if !$0 {renaming=nil}})) { TextField("Название",text:$rename);Button("Готово"){if var p=renaming{p.name=rename;try? store.save(p)};renaming=nil};Button("Отмена",role:.cancel){renaming=nil} }
        .alert("Удалить проект?",isPresented:Binding(get:{deleting != nil},set:{if !$0{deleting=nil}})) { Button("Удалить",role:.destructive){if let p=deleting{store.delete(p)};deleting=nil};Button("Отмена",role:.cancel){deleting=nil} }
        .alert("Не удалось выполнить действие",isPresented:Binding(get:{store.error != nil},set:{if !$0{store.error=nil}})) { Button("OK"){store.error=nil} } message:{Text(store.error ?? "")}
        .overlay { if store.working { ProgressView().padding(24).qSurface() } }
    }
    private var header:some View {
        HStack(spacing:0) {
            QLogo().frame(width:56,height:56)
            VStack(alignment:.leading,spacing:0) { Text("Vexel").font(qfont(28,.semibold));Text("Интерфейсы в стиле Material 3").font(qfont(14)).foregroundStyle(q.color("onSurfaceVariant")).fixedSize(horizontal:false,vertical:true) }.padding(.leading,14).frame(maxWidth:.infinity,alignment:.leading)
            QIconButton(icon:"Import",label:"Открыть проект",tonal:true){importing=true}
            QIconButton(icon:"Settings",label:"Настройки",tonal:true){settings=true}.padding(.leading,8)
        }
    }
    private var searchAndSort:some View {
        VStack(spacing:10) {
            HStack(spacing:16){QIcon(id:"Search",tint:q.color("onSurfaceVariant"));TextField("Поиск проектов",text:$query).font(qfont(16));if !query.isEmpty { QIconButton(icon:"Close",label:"Очистить",size:32){query=""} }}.padding(.horizontal,16).frame(height:56).overlay(Capsule().stroke(q.color("outline")))
            HStack(spacing:0) {
                ScrollView(.horizontal,showsIndicators:false) { HStack(spacing:8) { ForEach(Array(["Недавние","По имени","По размеру"].enumerated()),id:\.offset) { index,title in QChip(title:title,selected:sort==index){sort=index}.fixedSize() } } }
                QIconButton(icon:list ? "Components":"List",label:"Вид списка"){list.toggle()}
            }
        }
    }
    private var empty:some View {
        VStack(spacing:16) {
            if let shape=Catalog.shared.shapes.first(where:{$0.id=="soft-burst"}) { ShapePreview(shape:shape).fill(q.color("tertiary")).frame(width:140,height:140) }
            Text("Пока нет проектов").font(qfont(22,.semibold))
            Text("Создайте первый - холст, фигуры MD3 и выравнивание уже ждут.").font(qfont(14)).foregroundStyle(q.color("onSurfaceVariant")).multilineTextAlignment(.center)
        }.frame(maxWidth:.infinity).padding(.vertical,56)
    }
    private func card(_ p:Project)->some View {
        Group {
            if list {
                HStack(spacing:14) { ProjectThumbnail(project:p,root:store.root).frame(width:72,height:72).qSurface(20,"surfaceContainerHighest");titles(p);projectMenu(p) }.padding(.leading,8).padding(.vertical,8).padding(.trailing,2)
            } else {
                VStack(spacing:0) {
                    ProjectThumbnail(project:p,root:store.root).frame(maxWidth:.infinity).aspectRatio(1,contentMode:.fit).qSurface(20,"surfaceContainerHighest").padding(8)
                    HStack(spacing:0){titles(p);projectMenu(p)}.padding(.leading,14).padding(.trailing,2).padding(.bottom,6)
                }
            }
        }.qSurface(28).contentShape(RoundedRectangle(cornerRadius:28)).onTapGesture{opened=p}.accessibilityElement(children:.contain).accessibilityIdentifier("project-"+p.id)
    }
    private func titles(_ p:Project)->some View { VStack(alignment:.leading,spacing:0){Text(p.name).font(qfont(16,.semibold)).lineLimit(1);Text("\(Int(p.w))x\(Int(p.h)) | \(ago(p.updated))").font(qfont(12,.medium)).foregroundStyle(q.color("onSurfaceVariant")).lineLimit(1)}.frame(maxWidth:.infinity,alignment:.leading) }
    private func projectMenu(_ p:Project)->some View {
        Menu {
            Button("Переименовать"){rename=p.name;renaming=p}
            Button("Дублировать"){store.duplicate(p)}
            Button("Сохранить как .qwel"){do{shared=SharedFile(url:try store.archive(p))}catch{store.error=error.localizedDescription}}
            Button("Удалить",role:.destructive){deleting=p}
        } label:{QIcon(id:"More").frame(width:44,height:44)}
    }
    private func ago(_ time:Int64)->String { let minutes=max(0,(Int64(Date().timeIntervalSince1970*1000)-time)/60000);return minutes<1 ? "только что":minutes<60 ? "\(minutes) мин. назад":minutes<1440 ? "\(minutes/60) ч. назад":"\(minutes/1440) дн. назад" }
}
struct ProjectThumbnail:View {
    var project:Project
    var root:URL
    var inset:CGFloat = 14
    @State private var image:UIImage?
    var body:some View {
        Group { if let image { Image(uiImage:image).resizable().scaledToFit().padding(inset) } else { ProgressView() } }
            .task(id:project.updated) { image=DocumentRenderer(root:root).preview(project) }
    }
}
struct ShareSheet:UIViewControllerRepresentable {
    var urls:[URL]
    func makeUIViewController(context:Context)->UIActivityViewController { UIActivityViewController(activityItems:urls,applicationActivities:nil) }
    func updateUIViewController(_ controller:UIActivityViewController,context:Context) {}
}
