import SwiftUI

struct Sprite: Identifiable {
    let id: Int
    let name: String
    let rect: CGRect
    let polygons: [[CGPoint]]
    init?(_ line: String) {
        let parts = line.components(separatedBy: "|")
        guard parts.count >= 8, let id = Int(parts[0]), let x0 = Double(parts[2]), let y0 = Double(parts[3]),
              let x1 = Double(parts[4]), let y1 = Double(parts[5]), [x0, y0, x1, y1].allSatisfy(\.isFinite), x1 > x0, y1 > y0 else { return nil }
        self.id = id; name = parts[1]
        rect = CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
        polygons = parts.count < 9 ? [] : parts[8].components(separatedBy: "~").compactMap { polygon in
            guard let coordinates = polygon.split(separator: ":", maxSplits: 1).last else { return nil }
            let points = coordinates.split(separator: ";").compactMap { point -> CGPoint? in
                let xy = point.split(separator: ",")
                guard xy.count == 2, let x = Double(xy[0]), let y = Double(xy[1]), x.isFinite, y.isFinite else { return nil }
                return CGPoint(x: x, y: y)
            }
            return points.count >= 3 ? points : nil
        }
    }
    func image(from atlas: UIImage) -> UIImage? {
        guard let cg = atlas.cgImage else { return nil }
        let cropRect = rect.integral.intersection(CGRect(x: 0, y: 0, width: CGFloat(cg.width), height: CGFloat(cg.height)))
        guard !cropRect.isNull, cropRect.width > 0, cropRect.height > 0, let cropped = cg.cropping(to: cropRect) else { return nil }
        let image = UIImage(cgImage: cropped)
        guard !polygons.isEmpty else { return image }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = false
        return UIGraphicsImageRenderer(size: cropRect.size, format: format).image { _ in
            let path = UIBezierPath()
            for polygon in polygons {
                guard let first = polygon.first else { continue }
                path.move(to: CGPoint(x: first.x - cropRect.minX, y: first.y - cropRect.minY))
                for point in polygon.dropFirst() { path.addLine(to: CGPoint(x: point.x - cropRect.minX, y: point.y - cropRect.minY)) }
                path.close()
            }
            path.addClip()
            image.draw(in: CGRect(origin: .zero, size: cropRect.size))
        }
    }
}

struct TextureChoice: Identifiable { let id: Int; let label: String }

struct EditorView: View {
    @EnvironmentObject private var store: FileStore
    @State private var source: URL?
    @State private var picking = false
    @State private var atlas: UIImage?
    @State private var sprites: [Sprite] = []
    @State private var textures: [TextureChoice] = []
    @State private var textureIndex = 0
    @State private var search = ""
    @State private var message = ""
    @State private var loading = false
    @State private var share: SharePayload?
    @State private var selection: Sprite?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Button { picking = true } label: {
                        Label(source?.lastPathComponent ?? "Открыть SC", systemImage: "folder")
                            .frame(maxWidth: .infinity).padding()
                    }.buttonStyle(.bordered).disabled(store.busy)
                    if loading { ProgressView("Открываю текстуру…").frame(maxWidth: .infinity) }
                    if !message.isEmpty { Text(message).font(.footnote).foregroundStyle(nativeFailed(message) ? .red : .secondary).textSelection(.enabled) }
                    if let source {
                        NavigationLink { ExportsEditor(source: source) } label: { Label("Экспортнеймы", systemImage: "text.cursor") }
                        if let tool = Tool.all.first(where: { $0.id == "GetMovieClips" }) {
                            NavigationLink { ToolView(tool: tool, preset: ["sc": source.path]) } label: { Label("MovieClip", systemImage: "film") }
                        }
                    }
                    if !textures.isEmpty {
                        Picker("Текстура", selection: $textureIndex) {
                            ForEach(textures) { Text($0.label).tag($0.id) }
                        }.pickerStyle(.menu).disabled(store.busy)
                            .onChange(of: textureIndex) { value in Task { await load(texture: value) } }
                    }
                    if let atlas {
                        Text("Атлас · \(Int(atlas.size.width)) × \(Int(atlas.size.height))").font(.headline)
                        NavigationLink { AtlasZoom(image: atlas) } label: {
                            Image(uiImage: atlas).resizable().interpolation(.none).scaledToFit()
                                .frame(maxHeight: 350).frame(maxWidth: .infinity).background(Color.secondary.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        HStack {
                            Button("Сохранить атлас PNG") { saveAtlas(atlas) }
                            Spacer()
                            Button("Все спрайты") { exportSprites(atlas) }.disabled(store.busy)
                        }.font(.footnote)
                        Text("Спрайты · \(sprites.count)").font(.headline)
                        TextField("Имя или ID Shape", text: $search).textFieldStyle(.roundedBorder)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                            ForEach(sprites.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || String($0.id).contains(search) }) { sprite in
                                Button { selection = sprite } label: { SpriteCell(sprite: sprite, atlas: atlas) }.buttonStyle(.plain)
                            }
                        }
                    } else if source == nil {
                        Text("Открой SC, чтобы посмотреть атлас и спрайты, заменить изображения и изменить экспортнеймы.").foregroundStyle(.secondary)
                    }
                }.padding()
            }.navigationTitle("Редактор SC")
                .sheet(isPresented: $picking) {
                    FilePickerSheet(multiple: false) { urls in
                        guard let first = urls.first else { return }
                        source = first; atlas = nil; sprites = []; textures = []; textureIndex = 0
                        Task { await load(texture: nil) }
                    }.environmentObject(store)
                }
                .sheet(item: $share) { ShareSheet(urls: $0.urls) }
                .sheet(item: $selection) { sprite in
                    if let atlas, let source { SpriteDetail(sprite: sprite, atlas: atlas, source: source).environmentObject(store) }
                }
        }
    }
    @MainActor private func load(texture: Int?) async {
        guard !store.busy, let source else { return }
        store.busy = true; loading = true; message = ""
        defer { store.busy = false; loading = false; store.reload() }
        do {
            let folder = try store.resultFolder()
            let result = await Core.run(texture == nil ? "nativeGetScInfo" : "nativeGetScTexture", texture.map { [source.path, folder.path, String($0)] } ?? [source.path, folder.path])
            guard !nativeFailed(result) else { message = result; return }
            let rawFiles = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil).filter { $0.pathExtension == "raw" }
            guard let raw = rawFiles.first else { message = "Error: обработчик не создал атлас"; return }
            atlas = try rawAtlas(at: raw)
            sprites = result.components(separatedBy: "\n").compactMap(Sprite.init)
            if result.hasPrefix("TEXTURES:"), let header = result.components(separatedBy: "\n").first {
                textures = header.dropFirst(9).components(separatedBy: ",").compactMap { value in
                    let parts = value.components(separatedBy: "=")
                    guard parts.count == 2, let index = Int(parts[0]) else { return nil }
                    return TextureChoice(id: index, label: "\(index) · \(parts[1])")
                }
            }
        } catch { message = "Error: " + error.localizedDescription }
    }
    private func saveAtlas(_ image: UIImage) {
        do {
            let url = try store.resultFolder().appendingPathComponent("atlas.png")
            guard let data = image.pngData() else { throw CocoaError(.fileWriteUnknown) }
            try data.write(to: url); store.reload(); share = SharePayload(urls: [url])
        } catch { message = "Error: " + error.localizedDescription }
    }
    private func exportSprites(_ image: UIImage) {
        do {
            let folder = try store.resultFolder()
            var urls: [URL] = []
            for sprite in sprites {
                guard let data = sprite.image(from: image)?.pngData() else { continue }
                let name = sprite.name.map { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" ? $0 : "_" }
                let url = folder.appendingPathComponent("\(sprite.id)_\(String(name).prefix(100)).png")
                try data.write(to: url); urls.append(url)
            }
            store.reload()
            if urls.isEmpty { message = "Нет спрайтов для экспорта" } else { share = SharePayload(urls: urls) }
        } catch { message = "Error: " + error.localizedDescription }
    }
}

struct SpriteCell: View {
    let sprite: Sprite
    let atlas: UIImage
    @State private var thumbnail: UIImage?
    var body: some View {
        VStack {
            Group {
                if let thumbnail { Image(uiImage: thumbnail).resizable().interpolation(.none).scaledToFit() }
                else { Color.clear }
            }.frame(height: 85).frame(maxWidth: .infinity).background(Color.secondary.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 10))
            Text(sprite.name).font(.caption).lineLimit(1)
            Text("ID \(sprite.id)").font(.caption2).foregroundStyle(.secondary)
        }.task(id: atlas) { thumbnail = sprite.image(from: atlas) }
    }
}

struct AtlasZoom: View {
    let image: UIImage
    @State private var scale: CGFloat = 1
    @GestureState private var gestureScale: CGFloat = 1
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Image(uiImage: image).resizable().interpolation(.none)
                .frame(width: image.size.width * scale * gestureScale, height: image.size.height * scale * gestureScale)
                .gesture(MagnificationGesture().updating($gestureScale) { value, state, _ in state = value }.onEnded { scale = min(8, max(0.1, scale * $0)) })
        }.navigationTitle("Атлас").navigationBarTitleDisplayMode(.inline)
            .onAppear { scale = min(1, (UIScreen.main.bounds.width - 32) / image.size.width) }
    }
}

struct SpriteDetail: View {
    @EnvironmentObject private var store: FileStore
    @Environment(\.dismiss) private var dismiss
    let sprite: Sprite
    let atlas: UIImage
    let source: URL
    @State private var share: SharePayload?
    @State private var error = ""
    var body: some View {
        NavigationStack {
            List {
                if let image = sprite.image(from: atlas) {
                    Image(uiImage: image).resizable().interpolation(.none).scaledToFit().frame(maxHeight: 300)
                    Button("Экспорт PNG") {
                        do {
                            let url = try store.resultFolder().appendingPathComponent("sprite_\(sprite.id).png")
                            guard let data = image.pngData() else { throw CocoaError(.fileWriteUnknown) }
                            try data.write(to: url); store.reload(); share = SharePayload(urls: [url])
                        } catch { self.error = error.localizedDescription }
                    }
                }
                Text("Shape ID: \(sprite.id)")
                if let tool = Tool.all.first(where: { $0.id == "Png2Sc" }) {
                    NavigationLink("Заменить спрайт") { ToolView(tool: tool, preset: ["sc": source.path, "shape": String(sprite.id)]) }
                }
                if !error.isEmpty { Text(error).foregroundStyle(.red) }
            }.navigationTitle(sprite.name).navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Готово") { dismiss() } }
                .sheet(item: $share) { ShareSheet(urls: $0.urls) }
        }
    }
}

struct ExportEntry: Identifiable { let id = UUID(); let index: Int; var objectID: String; var name: String; var deleted = false; var added = false }
struct ExportsEditor: View {
    @EnvironmentObject private var store: FileStore
    let source: URL
    @State private var entries: [ExportEntry] = []
    @State private var message = ""
    @State private var loaded = false
    @State private var share: SharePayload?
    var body: some View {
        Form {
            if !message.isEmpty { Text(message).font(.footnote).textSelection(.enabled) }
            ForEach($entries) { $entry in
                if !entry.deleted {
                    Section("Индекс \(entry.index)") {
                        if entry.added { TextField("Object ID", text: $entry.objectID).keyboardType(.numberPad) }
                        else { Text("Object ID: \(entry.objectID)").font(.caption).foregroundStyle(.secondary) }
                        TextField("Экспортнейм", text: $entry.name).autocorrectionDisabled().textInputAutocapitalization(.never)
                        Button("Удалить", role: .destructive) { entry.deleted = true }
                    }
                }
            }
            Button("Добавить экспортнейм") { entries.append(ExportEntry(index: entries.count, objectID: "", name: "", added: true)) }.disabled(store.busy || !loaded)
            Button("Сохранить копию SC") { Task { await save() } }.disabled(store.busy || !loaded)
        }.navigationTitle("Экспортнеймы").navigationBarTitleDisplayMode(.inline)
            .task { if !loaded { await load() } }
            .sheet(item: $share) { ShareSheet(urls: $0.urls) }
    }
    @MainActor private func load() async {
        guard !store.busy else { message = "Дождись завершения обработки"; return }
        store.busy = true; defer { store.busy = false }
        let result = await Core.run("nativeGetExports", [source.path])
        if nativeFailed(result) { message = result; return }
        entries = result.components(separatedBy: "\n").enumerated().compactMap { index, line in
            let parts = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2, Int(parts[0]) != nil else { return nil }
            return ExportEntry(index: index, objectID: String(parts[0]), name: String(parts[1]))
        }
        loaded = true
    }
    @MainActor private func save() async {
        guard !store.busy else { return }
        do {
            var lines: [String] = []
            for entry in entries {
                if entry.added && entry.deleted { continue }
                if entry.deleted { lines.append("D\t\(entry.index)"); continue }
                guard !entry.name.isEmpty, !entry.name.contains("\n"), !entry.name.contains("\t"), !entry.name.contains("/"), !entry.name.contains("\\") else {
                    message = "Error: недопустимое имя"; return
                }
                if entry.added {
                    guard let id = Int(entry.objectID), id >= 0, id <= 65535 else { message = "Error: Object ID должен быть от 0 до 65535"; return }
                    lines.append("A\t\(id)\t\(entry.name)")
                } else { lines.append("R\t\(entry.index)\t\(entry.name)") }
            }
            guard !lines.isEmpty else { return }
            let folder = try store.resultFolder()
            let ops = folder.appendingPathComponent("export_changes.txt")
            try lines.joined(separator: "\n").write(to: ops, atomically: true, encoding: .utf8)
            store.busy = true; defer { store.busy = false; store.reload() }
            message = await Core.run("nativeEditExports", [ops.path, source.path, folder.path])
            if !nativeFailed(message) {
                try store.preserveCompanions(for: source, in: folder)
                let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil).filter { $0.pathExtension == "sc" }
                if !files.isEmpty { share = SharePayload(urls: files) }
            }
        } catch { message = "Error: " + error.localizedDescription }
    }
}
