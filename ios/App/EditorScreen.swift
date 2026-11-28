import SwiftUI
import PhotosUI
import Photos
import UniformTypeIdentifiers

struct EditorScreen:View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var phase
    @Environment(\.q) private var q
    @StateObject private var editor:Editor
    @State private var panel:String?
    @State private var shared:SharedFile?
    @State private var importer=false
    @State private var photos:[PhotosPickerItem]=[]
    @State private var exporting=false
    @State private var menu=false
    @State private var dockOpen=false
    @State private var dialog:String?
    @State private var history=false
    @State private var preview=false
    @State private var motion=false
    @State private var video=false
    @State private var polygon=false
    @State private var backgroundPhoto:PhotosPickerItem?
    @StateObject private var recorder=CanvasRecorder()
    @AppStorage("pngScale") private var pngScale=2.0
    init(project:Project,store:ProjectStore) { _editor=StateObject(wrappedValue:Editor(project,store:store)) }
    var body:some View {
        ZStack {
            EditorCanvas(editor:editor).accessibilityIdentifier("editorCanvas")
            if editor.project.nodes.isEmpty && panel==nil {
                Text("Лист пуст. Нажмите '+' внизу или задержите палец на листе, чтобы добавить фигуру.").font(qfont(16)).foregroundStyle(q.color("onSurfaceVariant")).multilineTextAlignment(.center).padding(.horizontal,56).allowsHitTesting(false)
            }
            VStack(spacing:0) { topBar;Spacer();bottomBlock }.padding(.horizontal,8).padding(.bottom,8)
            if menu {
                Color.black.opacity(0.001).ignoresSafeArea().onTapGesture{menu=false}
                VStack { HStack { Spacer();menuContent.frame(width:265).padding(.top,62) };Spacer() }.padding(.trailing,8)
            }
            if editor.eyedropTarget != nil { VStack{HStack{Text("Нажмите на цвет на холсте").font(qfont(14));Spacer();QIconButton(icon:"Close",label:"Отмена"){editor.eyedropTarget=nil}}.padding(.leading,18).qSurface(28,"surfaceContainerHigh").padding(.top,72);Spacer()}.padding(.horizontal,16).allowsHitTesting(true) }
            if let dialog {
                Color.black.opacity(0.4).ignoresSafeArea().onTapGesture{self.dialog=nil}
                Group {
                    if dialog=="echo" { EchoPanel(editor:editor){self.dialog=nil} }
                    else if dialog=="blend" { BlendPanel(editor:editor){self.dialog=nil} }
                    else if dialog=="screens" { ScreensPanel(editor:editor){self.dialog=nil} }
                    else if dialog=="text",let id=editor.selected.first?.id { TextEditPanel(editor:editor,nodeID:id){self.dialog=nil} }
                    else { ExportPanel(editor:editor,export:export){self.dialog=nil} }
                }.padding(.horizontal,28)
            }
        }
        .sheet(isPresented:$editor.showLayerPicker){OverlapLayerPicker(editor:editor).modifier(OriginalTheme())}
        .fullScreenCover(isPresented:$preview){DesignPreviewPanel(editor:editor).modifier(OriginalTheme())}
        .fullScreenCover(isPresented:$history){ProjectHistoryPanel(editor:editor).modifier(OriginalTheme())}
        .fullScreenCover(isPresented:$motion){MotionPanel(editor:editor).modifier(OriginalTheme())}
        .sheet(isPresented:$video){MotionVideoPanel(editor:editor).modifier(OriginalTheme())}
        .sheet(isPresented:$polygon){PolygonPanel(editor:editor).modifier(OriginalTheme())}
        .onChange(of:backgroundPhoto){_,item in Task{@MainActor in do{if let data=try await item?.loadTransferable(type:Data.self){try editor.addBackground(data)}}catch{editor.error=error.localizedDescription};backgroundPhoto=nil}}
        .sheet(item:$shared) { ShareSheet(urls:[$0.url]) }
        .fileImporter(isPresented:$importer,allowedContentTypes:[.data],allowsMultipleSelection:false) { result in switch result { case .success(let urls):if let url=urls.first{importFile(url)};case .failure(let e):editor.error=e.localizedDescription } }
        .onChange(of:photos) { _,items in Task { for item in items{do{if let data=try await item.loadTransferable(type:Data.self){try editor.addImage(data,name:"Картинка")}}catch{editor.error=error.localizedDescription}};photos=[] } }
        .onChange(of:editor.requestPanel){_,value in if let value{panel=value;editor.requestPanel=nil}}
        .onChange(of:editor.requestTextEdit){_,id in if let id{editor.selection=[id];panel=nil;dockOpen=false;dialog="text";editor.requestTextEdit=nil}}
        .onChange(of:editor.selection){_,ids in if let isolated=editor.isolatedIDs,!ids.isSubset(of:isolated){editor.isolatedIDs=nil}}
        .onChange(of:phase) { _,phase in if phase != .active { editor.saveNow() } }
        .onDisappear { recorder.cancel();if editor.playing{editor.originalPlay.stop()};editor.saveNow() }
        .onChange(of:editor.playing){_,playing in if !playing && recorder.recording{finishRecording()}}
        .alert("Не удалось выполнить действие",isPresented:Binding(get:{editor.error != nil},set:{if !$0{editor.error=nil}})){Button("OK"){editor.error=nil}}message:{Text(editor.error ?? "")}
    }
    private var topBar:some View {
        HStack(spacing:8) {
            QIconButton(icon:"Back",label:"Закрыть редактор"){editor.saveNow();dismiss()}.qSurface(24,"surfaceContainerHigh")
            Button { panel="document" } label:{Text(editor.project.name+(editor.project.pages.count>1 ? " | \(editor.project.active+1)/\(editor.project.pages.count)":"")).font(qfont(14,.semibold)).lineLimit(1).padding(.horizontal,18).padding(.vertical,13).qSurface(28,"surfaceContainerHigh")}.buttonStyle(.plain)
            Spacer(minLength:0)
            HStack(spacing:0) {
                QIconButton(icon:editor.playing ? "Stop":"Play",label:editor.playing ? "Остановить":"Играть",selected:editor.playing){panel=nil;dockOpen=false;editor.togglePlay()}.accessibilityIdentifier("play")
                QIconButton(icon:"Undo",label:"Отменить",enabled:!editor.undoStack.isEmpty && !editor.playing){editor.undo()}.accessibilityIdentifier("undo")
                QIconButton(icon:"Redo",label:"Повторить",enabled:!editor.redoStack.isEmpty && !editor.playing){editor.redo()}
                QIconButton(icon:"More",label:"Меню"){menu.toggle()}
            }.qSurface(24,"surfaceContainerHigh").layoutPriority(1)
        }.padding(.vertical,6)
    }
    private var bottomBlock:some View {
        VStack(spacing:8) {
            if editor.project.pages.count>1 && !editor.playing { screensStrip }
            HStack(spacing:6) {
                Button { editor.fitVersion += 1 } label:{Text("\(Int(editor.canvasScale*100))%").font(qfont(14,.semibold)).padding(.horizontal,14).padding(.vertical,8).qSurface(25,"surfaceContainerHigh")}.buttonStyle(.plain)
                if editor.project.pages.count<2 && !editor.playing { QIconButton(icon:"Screens",label:"Экраны",size:36){dialog="screens"}.qSurface(20,"surfaceContainerHigh") }
                Spacer()
            }
            if !editor.selection.isEmpty && !editor.playing { SelectionPill(editor:editor,expanded:$dockOpen,openPanel:{panel=$0;dockOpen=false},echo:{dialog=editor.selected.count==2 ? "blend":"echo"}) }
            if let panel,!editor.playing { floatingPanel(panel).transition(.move(edge:.bottom).combined(with:.opacity)) }
            if editor.playing {
                HStack(spacing:8){
                    QChip(title:"Выйти"){editor.togglePlay()}
                    QChip(title:editor.originalPlay.frozen ? "Продолжить":"Заморозить",selected:editor.originalPlay.frozen){editor.originalPlay.toggleFreeze()}
                    QChip(title:recorder.recording ? "Стоп запись":"Запись",selected:recorder.recording){if recorder.recording{finishRecording()}else{do{let edge=UserDefaults.standard.integer(forKey:"recordEdge");try recorder.start(editor,longEdge:[720,1080,1440,2160].contains(edge) ? edge:1080);editor.recordTouch={point in recorder.touch(point)}}catch{editor.error=error.localizedDescription}}}
                }.padding(12).qSurface(28,"surfaceContainerHigh")
            } else if editor.penActive{
                PenToolbar(editor:editor)
            } else { dock }
        }.animation(.spring(response:0.4,dampingFraction:0.75),value:panel)
    }
    private var screensStrip:some View {
        ScrollView(.horizontal,showsIndicators:false) { HStack(spacing:6) {
            ForEach(Array(editor.project.pages.enumerated()),id:\.element.id){index,page in Button {editor.page(index)}label:{Text(page.name).font(qfont(14,.semibold)).padding(.horizontal,14).padding(.vertical,10).qSurface(25,index==editor.project.active ? "secondaryContainer":"surfaceContainerHigh")}.buttonStyle(.plain)}
            HStack(spacing:0){QIconButton(icon:"Add",label:"Новый экран",size:36){editor.addPage()};QIconButton(icon:"Screens",label:"Экраны",size:36){dialog="screens"}}.qSurface(22,"surfaceContainerHigh")
        } }
    }
    private var dock:some View {
        HStack {
            tool("Layers","Слои","layers")
            tool("Style","Стиль","style")
            Button { togglePanel("add") } label:{ZStack{OriginalAddShape(open:panel=="add");QIcon(id:"Add",size:28,tint:q.color("onPrimary")).rotationEffect(.degrees(panel=="add" ? 45:0))}.frame(width:60,height:60)}.buttonStyle(QPressStyle()).accessibilityLabel("Добавить").accessibilityIdentifier("panel-add")
            tool("Align","Выровнять","align")
            VStack(spacing:0){QIconButton(icon:"Multi",label:"Выбор",selected:editor.multiSelect){editor.multiSelect.toggle()};Text("Выбор").font(qfont(11,.medium)).foregroundStyle(q.color("onSurfaceVariant"))}
        }.frame(maxWidth:.infinity).padding(.horizontal,8).padding(.vertical,6).qSurface(50,"surfaceContainerHigh",glass:true)
    }
    private func tool(_ icon:String,_ title:String,_ id:String)->some View {
        VStack(spacing:0){QIconButton(icon:icon,label:title,selected:panel==id){togglePanel(id)}.accessibilityIdentifier("panel-"+id);Text(title).font(qfont(11,.medium)).foregroundStyle(q.color("onSurfaceVariant"))}.frame(maxWidth:.infinity)
    }
    private func togglePanel(_ id:String){dockOpen=false;panel=panel==id ? nil:id}
    private func floatingPanel(_ id:String)->some View {
        VStack(spacing:0) {
            HStack{Text(["add":"Добавить","style":"Стиль","layers":"Слои","align":"Выровнять","document":"Стиль"][id] ?? "Стиль").font(qfont(22,.semibold));Spacer();QIconButton(icon:"Close",label:"Закрыть"){panel=nil}}.contentShape(Rectangle()).gesture(DragGesture().onEnded{if $0.translation.height>48{panel=nil}})
            ScrollView {
                Group {
                    switch id {
                    case "add":AddPanel(editor:editor,photoItems:$photos,importFile:{importer=true})
                    case "style":if editor.selected.isEmpty {DocumentPanel(editor:editor)}else{InspectorPanel(editor:editor,importFont:{importer=true})}
                    case "layers":LayersPanel(editor:editor)
                    case "align":AlignPanel(editor:editor)
                    default:DocumentPanel(editor:editor)
                    }
                }.padding(.trailing,8)
            }.frame(maxHeight:340).fixedSize(horizontal:false,vertical:true)
        }.padding(.leading,16).padding(.trailing,8).padding(.top,8).padding(.bottom,16).qSurface(28,"surfaceContainerLow",glass:true,alpha:0.985)
    }
    private var menuContent:some View {
        ScrollView {VStack(spacing:0) {
            menuItem("Eye","Чистый предпросмотр · экраны и темы"){preview=true}
            menuItem("Play","Анимация · ключи и шаблоны"){panel=nil;motion=true}
            menuItem("Export","Видео MP4 / последовательность PNG"){video=true}
            menuItem("Style","Перо · нарисовать контур"){panel=nil;editor.selection=[];editor.penActive=true}
            menuItem("Shapes","Многоугольник / звезда"){polygon=true}
            PhotosPicker(selection:$backgroundPhoto,matching:.images){HStack(spacing:12){QIcon(id:"Image");Text("Изображение фона").font(qfont(14));Spacer()}.padding(.horizontal,12).frame(height:48)}.buttonStyle(.plain)
            menuItem("Fit","Вписать в экран"){editor.fitVersion += 1}
            menuItem("Grid",editor.showGrid ? "Скрыть сетку":"Показать сетку"){editor.showGrid.toggle()}
            menuItem("Guides",editor.snap ? "Отключить привязки":"Включить привязки"){editor.snap.toggle()}
            menuItem("Multi","Выбрать всё"){editor.selection=Set(editor.project.nodes.map(\.id))}
            menuItem("Screens","Экраны"){dialog="screens"}
            menuItem("Undo","Версии проекта"){history=true}
            menuItem("Style","Тон проекта…"){panel="document"}
            menuItem("Import","Импорт SVG"){importer=true}
            menuItem("Code","Код Compose"){export("kt")}
            menuItem("Code","Код SwiftUI"){export("swift")}
            menuItem("Code","Проект iOS / Xcode"){export("iosProject")}
            menuItem("Code","Проект Compose"){export("module")}
            menuItem("Code","Проект CodeAssist"){export("codeassist")}
            menuItem("Export","Экспорт"){dialog="export"}
            menuItem("Export","Сохранить .qwel"){export("qwel")}
        }}.frame(maxHeight:560).padding(.vertical,8).qSurface(12,"surfaceContainerHigh").shadow(color:.black.opacity(0.2),radius:6,y:3)
    }
    private func menuItem(_ icon:String,_ title:String,_ action:@escaping()->Void)->some View { Button {menu=false;action()}label:{HStack(spacing:12){QIcon(id:icon);Text(title).font(qfont(14));Spacer()}.padding(.horizontal,12).frame(height:48)}.buttonStyle(.plain) }
    private func finishRecording(){editor.recordTouch=nil;Task{@MainActor in do{shared=SharedFile(url:try await recorder.finish())}catch{editor.error=error.localizedDescription}}}
    private func export(_ kind:String) {
        do {
            if kind=="iosProject"{shared=SharedFile(url:try IOSProjectExport.make(editor.project,root:editor.store.root));return}
            if ["module","codeassist"].contains(kind){shared=SharedFile(url:try OriginalCore.shared.sourceArchive(editor.project,root:editor.store.root,kind:kind));return}
            if kind=="qwel" { shared=SharedFile(url:try editor.store.archive(editor.project));return }
            let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
            let url=folder.appendingPathComponent(safeName(editor.project.name)+"."+kind)
            if kind=="kt" { try OriginalCore.shared.compose(editor.project).write(to:url,atomically:true,encoding:.utf8) }
            else if kind=="swift" { try SwiftExport.make(editor.project,root:editor.store.root).write(to:url,atomically:true,encoding:.utf8) }
            else if kind=="svg" { try SVGExport.make(editor.project,root:editor.store.root).write(to:url,atomically:true,encoding:.utf8) }
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
struct ShapePreview:Shape {
    let shape:ShapeItem
    func path(in rect:CGRect)->Path { var t=CGAffineTransform(scaleX:rect.width,y:rect.height);return Path(VectorPath.parse(shape.path).copy(using:&t)!) }
}
