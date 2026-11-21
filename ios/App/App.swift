import SwiftUI
import UniformTypeIdentifiers
import QuickLook

@main struct QwScIosApp: App {
    @StateObject private var store = FileStore()
    var body: some Scene {
        WindowGroup {
            TabView {
                ToolsView().tabItem { Label("Инструменты", systemImage: "square.grid.2x2") }
                EditorView().tabItem { Label("Редактор", systemImage: "slider.horizontal.3") }
                FilesView().tabItem { Label("Файлы", systemImage: "folder") }
                AboutView().tabItem { Label("О программе", systemImage: "info.circle") }
            }.environmentObject(store).tint(.teal)
        }
    }
}

struct ToolsView: View {
    @State private var search = ""
    private let sections = ["Текстуры", "Файлы SC", "Редактирование", "Анимации", "Сборка", "Вставка"]
    var body: some View {
        NavigationStack {
            List {
                ForEach(sections, id: \.self) { name in
                    let tools = Tool.all.filter { $0.section == name && (search.isEmpty || $0.title.localizedCaseInsensitiveContains(search)) }
                    if !tools.isEmpty {
                        Section(name) {
                            ForEach(tools) { tool in
                                NavigationLink { ToolView(tool: tool) } label: { Label(tool.title, systemImage: tool.icon) }
                            }
                        }
                    }
                }
            }.navigationTitle("QwSc iOS").searchable(text: $search, prompt: "Найти инструмент")
        }
    }
}

struct ToolView: View {
    @EnvironmentObject private var store: FileStore
    let tool: Tool
    var preset: [String: String] = [:]
    @State private var values: [String: String] = [:]
    @State private var picking: ToolField?
    @State private var result = ""
    @State private var outputs: [FileItem] = []
    @State private var running = false
    @State private var preview: FileItem?
    @State private var share: SharePayload?
    private func binding(_ field: ToolField) -> Binding<String> {
        Binding(get: { values[field.id] ?? field.initial }, set: { values[field.id] = $0 })
    }
    var body: some View {
        Form {
            if !tool.note.isEmpty { Section { Text(tool.note).font(.footnote).foregroundStyle(.secondary) } }
            ForEach(tool.fields.filter { $0.kind != .output && $0.kind != .constant }) { field in
                Section(field.label) { fieldView(field) }
            }
            Section {
                Button {
                    Task { await execute() }
                } label: {
                    HStack {
                        Spacer()
                        if running { ProgressView() }
                        Text(running ? "Обработка…" : "Выполнить").bold()
                        Spacer()
                    }
                }.disabled(store.busy)
            }
            if !result.isEmpty {
                Section("Результат") {
                    Text(result).font(.system(.footnote, design: .monospaced)).textSelection(.enabled)
                        .foregroundStyle(nativeFailed(result) ? Color.red : Color.primary)
                    if !outputs.isEmpty {
                        Button("Поделиться всеми файлами", systemImage: "square.and.arrow.up") {
                            share = SharePayload(urls: outputs.map(\.url))
                        }
                    }
                    ForEach(outputs) { item in
                        Button(item.title) { preview = item }
                            .contextMenu { ShareLink(item: item.url) }
                    }
                }
            }
        }.navigationTitle(tool.title).navigationBarTitleDisplayMode(.inline)
            .onAppear { if values.isEmpty { values = preset } }
            .sheet(item: $picking) { field in
                FilePickerSheet(multiple: field.kind == .files) { urls in
                    values[field.id] = urls.map(\.path).joined(separator: "|")
                }.environmentObject(store)
            }
            .sheet(item: $preview) { Preview(url: $0.url) }
            .sheet(item: $share) { ShareSheet(urls: $0.urls) }
    }
    @ViewBuilder private func fieldView(_ field: ToolField) -> some View {
        switch field.kind {
        case .file, .files:
            Button {
                picking = field
            } label: {
                let selected = values[field.id] ?? ""
                if selected.isEmpty { Label("Выбрать файл", systemImage: "folder") }
                else {
                    VStack(alignment: .leading) {
                        ForEach(selected.components(separatedBy: "|"), id: \.self) { path in Text(URL(fileURLWithPath: path).lastPathComponent).lineLimit(2) }
                        Text("Нажми, чтобы изменить").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }.disabled(store.busy)
        case .choice:
            Picker(field.label, selection: binding(field)) {
                ForEach(field.choices, id: \.self) { Text($0).tag($0) }
            }
        case .integer:
            TextField(field.label, text: binding(field)).keyboardType(.numbersAndPunctuation)
        case .text:
            TextField(field.label, text: binding(field), axis: .vertical).textInputAutocapitalization(.never).autocorrectionDisabled()
        default: EmptyView()
        }
    }
    @MainActor private func execute() async {
        guard !store.busy else { return }
        do {
            for field in tool.fields where field.kind != .output && field.kind != .constant {
                let value = values[field.id] ?? field.initial
                if field.required && value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result = "Error: заполни поле «\(field.label)»"; return
                }
                if field.kind == .integer {
                    guard let n = Int32(value), n >= (field.id == "shape" ? -1 : 0), n <= 65535 else {
                        result = "Error: недопустимое число в поле «\(field.label)»"; return
                    }
                    if ["fps", "side", "screen"].contains(field.id) && n == 0 {
                        result = "Error: значение должно быть больше нуля"; return
                    }
                    if field.id == "fps" && n > 120 { result = "Error: FPS должен быть от 1 до 120"; return }
                    if ["side", "screen"].contains(field.id) && n > 4096 { result = "Error: максимум 4096 px"; return }
                }
            }
            let folder = try store.resultFolder()
            let args = tool.fields.map { $0.kind == .output ? folder.path : (values[$0.id] ?? $0.initial) }
            store.busy = true; running = true; outputs = []; result = ""
            defer { store.busy = false; running = false; store.reload() }
            result = await Core.run(tool.operation, args)
            outputs = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.isRegularFileKey]))?
                .filter { (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true && $0.pathExtension != "raw" }
                .map { FileItem(url: $0) }.sorted { $0.title < $1.title } ?? []
        } catch { result = "Error: " + error.localizedDescription }
    }
}

struct FilePickerSheet: View {
    @EnvironmentObject private var store: FileStore
    @Environment(\.dismiss) private var dismiss
    let multiple: Bool
    let selected: ([URL]) -> Void
    @State private var importing = false
    @State private var chosen: Set<URL> = []
    @State private var search = ""
    @State private var error = ""
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Импортировать из «Файлов»", systemImage: "square.and.arrow.down") { importing = true }
                    Text("SC и связанные *_tex.sc / SCTX импортируй вместе, чтобы сохранить соседние файлы.").font(.caption).foregroundStyle(.secondary)
                }
                if !error.isEmpty { Text(error).foregroundStyle(.red) }
                ForEach(store.files.filter { search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) }) { item in
                    Button {
                        if multiple {
                            if chosen.contains(item.url) { chosen.remove(item.url) } else { chosen.insert(item.url) }
                        } else { selected([item.url]); dismiss() }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.title).foregroundStyle(.primary)
                                Text(item.url.deletingLastPathComponent().lastPathComponent).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if chosen.contains(item.url) { Image(systemName: "checkmark.circle.fill") }
                        }
                    }
                }
            }.navigationTitle("Выбрать файл").searchable(text: $search)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                    if multiple { ToolbarItem(placement: .confirmationAction) { Button("Готово") { selected(chosen.sorted { $0.path < $1.path }); dismiss() }.disabled(chosen.isEmpty) } }
                }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
                    do {
                        let copied = try store.importFiles(result.get())
                        if multiple { chosen.formUnion(copied) }
                        else if copied.count == 1, let first = copied.first { selected([first]); dismiss() }
                    } catch { self.error = error.localizedDescription }
                }
        }
    }
}

struct FilesView: View {
    @EnvironmentObject private var store: FileStore
    @State private var importing = false
    @State private var preview: FileItem?
    @State private var search = ""
    @State private var error = ""
    var body: some View {
        NavigationStack {
            List {
                if !error.isEmpty { Text(error).foregroundStyle(.red) }
                if store.files.isEmpty { Text("Импортируй SC, SCTX, KTX, PNG или GIF. Результаты обработки тоже появятся здесь.").foregroundStyle(.secondary) }
                ForEach(store.files.filter { search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) }) { item in
                    Button { preview = item } label: {
                        Label(item.title, systemImage: ["png", "jpg", "gif"].contains(item.url.pathExtension.lowercased()) ? "photo" : "doc")
                    }.contextMenu {
                        ShareLink(item: item.url)
                        Button("Скопировать путь") { UIPasteboard.general.string = item.url.path }
                    }
                }
            }.navigationTitle("Файлы").searchable(text: $search)
                .refreshable { store.reload() }
                .toolbar { Button { importing = true } label: { Image(systemName: "plus") }.disabled(store.busy) }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
                    do { _ = try store.importFiles(result.get()) } catch { self.error = error.localizedDescription }
                }
                .sheet(item: $preview) { Preview(url: $0.url) }
        }
    }
}

struct SharePayload: Identifiable { let id = UUID(); let urls: [URL] }
struct ShareSheet: UIViewControllerRepresentable {
    let urls: [URL]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: urls, applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
struct Preview: UIViewControllerRepresentable {
    let url: URL
    func makeCoordinator() -> Coordinator { Coordinator(url: url) }
    func makeUIViewController(context: Context) -> UINavigationController {
        let preview = QLPreviewController(); preview.dataSource = context.coordinator
        return UINavigationController(rootViewController: preview)
    }
    func updateUIViewController(_ controller: UINavigationController, context: Context) {}
    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem { url as NSURL }
    }
}

struct AboutView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("QwSc iOS · 0.1") {
                    Text("Инструменты Supercell: SC, SCTX, KTX, PNG и GIF. Неофициальное приложение.")
                    Text("Обработка выполняется на устройстве. Исходные файлы сохраняются; результат записывается отдельно.")
                }
                Section("Ограничения порта") {
                    Text("Downgrade недоступен: исходный проект содержит только Android-библиотеку без исходников этой функции.")
                    Text("Доступ к файлам других приложений ограничен iOS. Используй импорт и меню «Поделиться».")
                }
                Section("Исходники и лицензии") {
                    Link("QwScIos · исходники порта", destination: URL(string: "https://github.com/Matwey181/QwScIos")!)
                    Link("QwScDroid · Cheburek-Qwenz", destination: URL(string: "https://github.com/Cheburek-Qwenz/QwScDroid")!)
                    Text("Код QwScDroid: MPL-2.0. astcenc: Apache-2.0, Arm Limited. Zstandard: BSD-3-Clause, Meta Platforms. stb: MIT / Public Domain, Sean Barrett. Идея GIF ↔ SC: @Ghoul1337i.").font(.footnote)
                    NavigationLink("Полные тексты лицензий") { LicenseView() }
                }
            }.navigationTitle("О программе")
        }
    }
}
struct LicenseView: View {
    var body: some View {
        ScrollView { Text((try? String(contentsOf: Bundle.main.url(forResource: "Licenses", withExtension: "txt")!)) ?? "Лицензии доступны в репозитории исходников.").font(.caption.monospaced()).textSelection(.enabled).padding() }
            .navigationTitle("Лицензии")
    }
}
