import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

@main struct QwelApp:App {
    @StateObject private var store=ProjectStore()
    @AppStorage("appearance") private var appearance=0
    var body:some Scene {
        WindowGroup { ProjectsView().environmentObject(store).tint(Color(red:0.0,green:0.47,blue:0.45))
            .preferredColorScheme(appearance==0 ? nil:appearance==1 ? .light:.dark)
            .onOpenURL { url in Task { await store.importFile(url) } }
        }
    }
}
struct ProjectsView:View {
    @EnvironmentObject var store:ProjectStore
    @State private var creating=false
    @State private var settings=false
    @State private var importing=false
    @State private var opened:Project?
    @State private var query=""
    @State private var shared:SharedFile?
    var body:some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:24) {
                    HStack {
                        VStack(alignment:.leading,spacing:4) { Text("Твои идеи, в форме.").font(.largeTitle.bold());Text("Создавай интерфейсы вместе с Qwel").foregroundStyle(.secondary) }
                        Spacer()
                    }.padding(.top,8)
                    if store.projects.isEmpty { ContentUnavailableView("Первый чистый лист",systemImage:"square.and.pencil",description:Text("Создай проект или открой файл .qwel")) }
                    LazyVGrid(columns:[GridItem(.adaptive(minimum:155),spacing:16)],spacing:16) {
                        ForEach(store.projects.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }) { p in
                            Button { opened=p } label: {
                                VStack(alignment:.leading,spacing:10) {
                                    ProjectThumbnail(project:p,root:store.root).frame(height:160).frame(maxWidth:.infinity).background(Color(uiColor:.tertiarySystemBackground)).clipShape(RoundedRectangle(cornerRadius:24))
                                    Text(p.name).font(.headline).foregroundStyle(.primary).lineLimit(1)
                                    Text("\(Int(p.w)) × \(Int(p.h)) · \(p.nodes.count) слоёв").font(.caption).foregroundStyle(.secondary)
                                }
                            }.buttonStyle(.plain).accessibilityIdentifier("project-"+p.id)
                            .contextMenu {
                                Button("Открыть",systemImage:"pencil") { opened=p }
                                Button("Дублировать",systemImage:"plus.square.on.square") { store.duplicate(p) }
                                Button("Поделиться .qwel",systemImage:"square.and.arrow.up") { do { shared=SharedFile(url:try store.archive(p)) } catch { store.error=error.localizedDescription } }
                                Button("Удалить",systemImage:"trash",role:.destructive) { store.delete(p) }
                            }
                        }
                    }
                }.padding(20)
            }.background(Color(uiColor:.systemGroupedBackground))
            .navigationTitle("Qwel").navigationBarTitleDisplayMode(.inline)
            .searchable(text:$query,prompt:"Поиск проектов")
            .toolbar {
                ToolbarItem(placement:.topBarLeading) { Button { settings=true } label:{Image(systemName:"gearshape")} }
                ToolbarItem(placement:.topBarTrailing) { Menu { Button("Открыть .qwel",systemImage:"folder") { importing=true };Button("Новый проект",systemImage:"plus") { creating=true } } label:{Image(systemName:"ellipsis.circle")} }
            }
            .safeAreaInset(edge:.bottom) { Button { creating=true } label:{Label("Новый проект",systemImage:"plus").font(.headline).padding(.vertical,12).frame(maxWidth:.infinity)}.buttonStyle(.borderedProminent).buttonBorderShape(.capsule).padding().background(.ultraThinMaterial).accessibilityIdentifier("newProject") }
        }
        .sheet(isPresented:$creating) { NewProjectView { p in creating=false;opened=p }.environmentObject(store) }
        .sheet(isPresented:$settings) { SettingsView() }
        .fullScreenCover(item:$opened) { p in EditorScreen(project:p,store:store) }
        .fileImporter(isPresented:$importing,allowedContentTypes:[.data],allowsMultipleSelection:false) { result in
            switch result { case .success(let urls):if let url=urls.first { Task { await store.importFile(url) } };case .failure(let e):store.error=e.localizedDescription }
        }
        .sheet(item:$shared) { ShareSheet(urls:[$0.url]) }
        .overlay { if store.working { ProgressView("Открываю проект…").padding(24).background(.regularMaterial,in:RoundedRectangle(cornerRadius:24)) } }
        .alert("Не удалось выполнить действие",isPresented:Binding(get:{store.error != nil},set:{if !$0 { store.error=nil }})) { Button("OK") { store.error=nil } } message:{Text(store.error ?? "")}
    }
}
struct ProjectThumbnail:View {
    var project:Project
    var root:URL
    @State private var image:UIImage?
    var body:some View {
        Group { if let image { Image(uiImage:image).resizable().scaledToFit().padding(12) } else { ProgressView() } }
            .task(id:project.updated) { image=DocumentRenderer(root:root).preview(project) }
    }
}
struct NewProjectView:View {
    @EnvironmentObject var store:ProjectStore
    @Environment(\.dismiss) var dismiss
    var created:(Project)->Void
    @State private var name="Новый проект"
    @State private var width:Double=390
    @State private var height:Double=844
    @State private var template:String=""
    var body:some View {
        NavigationStack {
            Form {
                Section("Чистый лист") {
                    TextField("Название",text:$name).accessibilityIdentifier("projectName")
                    HStack { Text("Ширина");Spacer();TextField("390",value:$width,format:.number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("Высота");Spacer();TextField("844",value:$height,format:.number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { ForEach(["iPhone","Квадрат","Экран"],id:\.self) { size in Button(size) { template="";if size=="iPhone" { width=390;height=844 } else if size=="Квадрат" { width=1080;height=1080 } else { width=1920;height=1080 } }.buttonStyle(.bordered) } }
                }
                Section("Шаблоны из Qwel") {
                    Button { template="" } label:{HStack { Text("Без шаблона");Spacer();if template.isEmpty { Image(systemName:"checkmark") } }}
                    ForEach(Catalog.shared.templates) { item in
                        Button { template=item.id;name=item.name } label: { HStack { ProjectThumbnail(project:item.project,root:store.root).frame(width:55,height:80);VStack(alignment:.leading) { Text(item.name);Text(item.category).font(.caption).foregroundStyle(.secondary) };Spacer();if template==item.id { Image(systemName:"checkmark.circle.fill") } } }
                    }
                }
            }.navigationTitle("Новый проект")
            .toolbar { ToolbarItem(placement:.cancellationAction) { Button("Отмена") { dismiss() } };ToolbarItem(placement:.confirmationAction) { Button("Создать") { do { let t=Catalog.shared.templates.first{$0.id==template}?.project;created(try store.create(name:name,width:CGFloat(min(8192,max(16,width))),height:CGFloat(min(8192,max(16,height))),template:t)) } catch { store.error=error.localizedDescription } }.accessibilityIdentifier("createProject") } }
        }
    }
}
struct SettingsView:View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("appearance") var appearance=0
    @AppStorage("pngScale") var pngScale=2.0
    var body:some View { NavigationStack { Form {
        Section { HStack { Image(systemName:"square.stack.3d.up.fill").font(.largeTitle).foregroundStyle(.teal);VStack(alignment:.leading) { Text("Qwel для iOS").font(.title2.bold());Text("Порт исходников v44 · сборка 0.1").foregroundStyle(.secondary) } } }
        Section("Внешний вид") { Picker("Тема",selection:$appearance) { Text("Системная").tag(0);Text("Светлая").tag(1);Text("Тёмная").tag(2) } }
        Section("Экспорт") { Picker("Масштаб PNG",selection:$pngScale) { ForEach([1.0,2.0,3.0],id:\.self) { Text("\(Int($0))×").tag($0) } } }
        Section("Жесты") { Text("Один палец — выбор и перенос. Два пальца — панорамирование. Щипок — масштаб. Углы рамки — размер, верхняя ручка — поворот. Двойной тап — вписать холст.") }
    }.navigationTitle("Настройки").toolbar { Button("Готово") { dismiss() } } } }
}
struct ShareSheet:UIViewControllerRepresentable {
    var urls:[URL]
    func makeUIViewController(context:Context)->UIActivityViewController { UIActivityViewController(activityItems:urls,applicationActivities:nil) }
    func updateUIViewController(_ controller:UIActivityViewController,context:Context) {}
}
