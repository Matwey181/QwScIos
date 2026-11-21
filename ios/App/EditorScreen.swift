import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import Photos

struct EditorScreen:View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var phase
    @StateObject private var editor:Editor
    @State private var panel:String?
    @State private var shared:SharedFile?
    @State private var importer=false
    @State private var photos:[PhotosPickerItem]=[]
    @State private var exporting=false
    @AppStorage("pngScale") private var pngScale=2.0
    init(project:Project,store:ProjectStore) { _editor=StateObject(wrappedValue:Editor(project,store:store)) }
    var body:some View {
        NavigationStack {
            VStack(spacing:0) {
                if editor.project.pages.count>1 {
                    ScrollView(.horizontal,showsIndicators:false) { HStack { ForEach(Array(editor.project.pages.enumerated()),id:\.element.id) { i,p in Button(p.name) { editor.page(i) }.buttonStyle(.bordered).tint(i==editor.project.active ? .teal:.gray) };Button { editor.addPage() } label:{Image(systemName:"plus")} }.padding(.horizontal).padding(.vertical,6) }
                }
                EditorCanvas(editor:editor).accessibilityIdentifier("editorCanvas")
                if !editor.selection.isEmpty && !editor.playing {
                    HStack { Text("\(editor.selection.count) слоёв").font(.caption);Spacer();Button { editor.duplicate() } label:{Image(systemName:"plus.square.on.square")};Button { editor.group() } label:{Image(systemName:"square.3.layers.3d")};Button(role:.destructive) { editor.remove() } label:{Image(systemName:"trash")} }.padding(12).background(.regularMaterial)
                }
                dock
            }.navigationTitle(editor.project.name).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement:.topBarLeading) { Button { editor.saveNow();dismiss() } label:{Image(systemName:"chevron.left")}.accessibilityLabel("Закрыть редактор") }
                ToolbarItemGroup(placement:.topBarTrailing) {
                    Button { editor.undo() } label:{Image(systemName:"arrow.uturn.backward")}.disabled(editor.undoStack.isEmpty).accessibilityIdentifier("undo")
                    Button { editor.redo() } label:{Image(systemName:"arrow.uturn.forward")}.disabled(editor.redoStack.isEmpty)
                    Menu {
                        Toggle("Играть",isOn:$editor.playing)
                        Toggle("Привязки",isOn:$editor.snap)
                        Button("Вписать холст",systemImage:"arrow.up.left.and.arrow.down.right") { editor.fitVersion += 1 }
                        Button("Новый экран",systemImage:"rectangle.badge.plus") { editor.addPage() }
                        Button("Настройки холста",systemImage:"slider.horizontal.3") { panel="document" }
                        Divider()
                        Button("Сохранить проект .qwel",systemImage:"square.and.arrow.up") { export("qwel") }
                        Button("Экспорт PNG",systemImage:"photo") { export("png") }
                        Button("Экспорт SVG",systemImage:"scribble.variable") { export("svg") }
                        Button("PNG в Фото",systemImage:"photo.badge.arrow.down") { savePhoto() }
                    } label:{Image(systemName:"ellipsis.circle")}
                }
            }
        }
        .sheet(item:Binding(get:{panel.map{PanelID(id:$0)}},set:{panel=$0?.id})) { p in
            NavigationStack {
                Group {
                    switch p.id {
                    case "add":AddPanel(editor:editor,photoItems:$photos,importFile:{ panel=nil;DispatchQueue.main.asyncAfter(deadline:.now()+0.4) { importer=true } })
                    case "style":InspectorPanel(editor:editor,importFont:{panel=nil;DispatchQueue.main.asyncAfter(deadline:.now()+0.4) { importer=true }})
                    case "layers":LayersPanel(editor:editor)
                    case "align":AlignPanel(editor:editor)
                    default:DocumentPanel(editor:editor)
                    }
                }.toolbar { ToolbarItem(placement:.confirmationAction) { Button("Готово") { panel=nil } } }
            }.presentationDetents([.medium,.large]).presentationDragIndicator(.visible)
        }
        .sheet(item:$shared) { ShareSheet(urls:[$0.url]) }
        .fileImporter(isPresented:$importer,allowedContentTypes:[.data],allowsMultipleSelection:false) { result in
            switch result { case .success(let urls):if let url=urls.first { importFile(url) };case .failure(let e):editor.error=e.localizedDescription }
        }
        .onChange(of:photos) { _,items in Task { for item in items { do { if let data=try await item.loadTransferable(type:Data.self) { try editor.addImage(data,name:"Фото") } } catch { editor.error=error.localizedDescription } };photos=[];panel=nil } }
        .onChange(of:phase) { _,phase in if phase != .active { editor.saveNow() } }
        .onDisappear { editor.saveNow() }
        .alert("Не удалось выполнить действие",isPresented:Binding(get:{editor.error != nil},set:{if !$0 { editor.error=nil }})) { Button("OK") { editor.error=nil } } message:{Text(editor.error ?? "")}
        .overlay { if exporting { ProgressView("Экспорт…").padding(24).background(.regularMaterial,in:RoundedRectangle(cornerRadius:24)) } }
    }
    private var dock:some View {
        HStack(spacing:0) {
            dockButton("Добавить","plus","add")
            dockButton("Стиль","paintpalette","style")
            dockButton("Слои","square.3.layers.3d","layers")
            dockButton("Ровно","align.horizontal.center","align")
            Button { editor.playing.toggle();editor.selection=[] } label:{VStack(spacing:5) { Image(systemName:editor.playing ? "stop.fill":"play.fill").font(.title3);Text("Играть").font(.caption2) }.frame(maxWidth:.infinity).padding(.vertical,12)}.tint(editor.playing ? .orange:.teal)
        }.background(.regularMaterial)
    }
    private func dockButton(_ title:String,_ icon:String,_ id:String)->some View {
        Button { panel=id } label:{VStack(spacing:5) { Image(systemName:icon).font(.title3);Text(title).font(.caption2) }.frame(maxWidth:.infinity).padding(.vertical,12)}.accessibilityIdentifier("panel-"+id)
    }
    private func export(_ kind:String) {
        do {
            if kind=="qwel" { shared=SharedFile(url:try editor.store.archive(editor.project));return }
            let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
            let url=folder.appendingPathComponent(safeName(editor.project.name)+"."+kind)
            if kind=="svg" { try SVGExport.make(editor.project,root:editor.store.root).write(to:url,atomically:true,encoding:.utf8) }
            else { guard let data=editor.renderer.png(editor.project,scale:CGFloat(pngScale)) else { throw CocoaError(.fileWriteOutOfSpace) };try data.write(to:url) }
            shared=SharedFile(url:url)
        } catch { editor.error=error.localizedDescription }
    }
    private func savePhoto() {
        guard let data=editor.renderer.png(editor.project,scale:CGFloat(pngScale)) else { editor.error="Холст слишком большой для выбранного масштаба.";return }
        PHPhotoLibrary.requestAuthorization(for:.addOnly) { status in
            guard status == .authorized || status == .limited else { Task { @MainActor in editor.error="Разреши сохранение изображений в настройках Фото." };return }
            PHPhotoLibrary.shared().performChanges { PHAssetCreationRequest.forAsset().addResource(with:.photo,data:data,options:nil) } completionHandler:{ _,error in if let error { Task { @MainActor in editor.error=error.localizedDescription } } }
        }
    }
    private func importFile(_ url:URL) {
        Task { @MainActor in
            do {
                let scoped=url.startAccessingSecurityScopedResource();defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                let data=try await Task.detached { try Data(contentsOf:url) }.value
                guard data.count<=100*1024*1024 else { throw CocoaError(.fileReadTooLarge) }
                let ext=url.pathExtension.lowercased()
                if ["ttf","otf"].contains(ext) { let name=UUID().uuidString+"."+ext;try data.write(to:editor.store.fonts.appendingPathComponent(name));editor.store.registerFonts();editor.change { $0.font=name };panel="style" }
                else if ext=="svg" { let nodes=try SVGImport.parse(data);editor.edit { $0.nodes += nodes };editor.selection=Set(nodes.map(\.id)) }
                else { try editor.addImage(data,name:url.lastPathComponent) }
            } catch { editor.error=error.localizedDescription }
        }
    }
}
struct PanelID:Identifiable { let id:String }
struct AddPanel:View {
    @ObservedObject var editor:Editor
    @Binding var photoItems:[PhotosPickerItem]
    var importFile:()->Void
    @Environment(\.dismiss) var dismiss
    @State private var category=0
    @State private var query=""
    var body:some View {
        VStack {
            Picker("Каталог",selection:$category) { Text("Основа").tag(0);Text("Фигуры").tag(1);Text("Компоненты").tag(2);Text("Иконки").tag(3) }.pickerStyle(.segmented).padding(.horizontal)
            ScrollView {
                if category==0 { VStack(spacing:12) {
                    ForEach([("RECT","Прямоугольник","rectangle"),("ELLIPSE","Эллипс","circle"),("TEXT","Текст","textformat")],id:\.0) { kind,name,icon in Button { editor.add(kind);dismiss() } label:{Label(name,systemImage:icon).padding(10).frame(maxWidth:.infinity)}.buttonStyle(.bordered).accessibilityIdentifier("add-"+kind) }
                    PhotosPicker(selection:$photoItems,maxSelectionCount:12,matching:.images) { Label("Из Фото",systemImage:"photo.on.rectangle").padding(10).frame(maxWidth:.infinity) }.buttonStyle(.bordered)
                    Button(action:importFile) { Label("Картинка, SVG или шрифт",systemImage:"folder").padding(10).frame(maxWidth:.infinity) }.buttonStyle(.bordered)
                }.padding() }
                else if category==1 {
                    LazyVGrid(columns:[GridItem(.adaptive(minimum:90))]) {
                        ForEach(Catalog.shared.shapes.filter{query.isEmpty || $0.name.localizedCaseInsensitiveContains(query)}) { shape in
                            Button { editor.add("SHAPE",shape:shape);dismiss() } label:{VStack { ShapePreview(shape:shape).fill(.teal).frame(width:55,height:55);Text(shape.name).font(.caption).lineLimit(1) }.padding(10)}.buttonStyle(.plain)
                        }
                    }.padding()
                } else if category==2 {
                    LazyVGrid(columns:[GridItem(.adaptive(minimum:150))],spacing:18) {
                        ForEach(Catalog.shared.components.filter{query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.category.localizedCaseInsensitiveContains(query)}) { item in
                            Button { editor.addComponent(item);dismiss() } label:{VStack { ProjectThumbnail(project:item.project,root:editor.store.root).frame(height:90).frame(maxWidth:.infinity).background(Color(uiColor:.secondarySystemBackground),in:RoundedRectangle(cornerRadius:16));Text(item.name).font(.caption).lineLimit(2) }}.buttonStyle(.plain)
                        }
                    }.padding()
                } else {
                    LazyVGrid(columns:[GridItem(.adaptive(minimum:60))]) { ForEach(["house.fill","heart.fill","star.fill","gearshape.fill","person.fill","magnifyingglass","plus","xmark","checkmark","bell.fill","play.fill","pause.fill","message.fill","paperplane.fill","bookmark.fill","cart.fill","camera.fill","photo.fill","music.note","location.fill","sun.max.fill","moon.fill","lock.fill","wifi","battery.100","chevron.left","chevron.right","ellipsis","trash.fill","folder.fill"],id:\.self) { symbol in
                        Button { addSymbol(symbol);dismiss() } label:{Image(systemName:symbol).font(.title2).frame(width:50,height:50)}
                    } }.padding()
                }
            }
        }.navigationTitle("Добавить").navigationBarTitleDisplayMode(.inline).searchable(text:$query,prompt:"Поиск")
    }
    private func addSymbol(_ symbol:String) {
        let config=UIImage.SymbolConfiguration(pointSize:128,weight:.regular)
        guard let im=UIImage(systemName:symbol,withConfiguration:config)?.withTintColor(.black,renderingMode:.alwaysOriginal),let data=im.pngData() else { return }
        do { try editor.addImage(data,name:symbol) } catch { editor.error=error.localizedDescription }
    }
}
struct ShapePreview:Shape {
    let shape:ShapeItem
    func path(in rect:CGRect)->Path { var t=CGAffineTransform(scaleX:rect.width,y:rect.height);return Path(VectorPath.parse(shape.path).copy(using:&t)!) }
}
