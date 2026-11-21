import Foundation
import SwiftUI
import UniformTypeIdentifiers

func importTrace(_ stage: String) {
    #if DEBUG
    NSLog("[FileImport] %@", stage)
    #endif
}

enum FileImportError: LocalizedError {
    case busy, cancelled, timedOut, notAFile(String)
    var errorDescription: String? {
        switch self {
        case .busy: return "Дождись завершения текущей операции."
        case .cancelled: return "Импорт отменён."
        case .timedOut: return "Источник файлов не ответил за 60 секунд. Сохрани файлы в «На iPhone» и попробуй снова."
        case .notAFile(let name): return "Не удалось прочитать файл «\(name)»."
        }
    }
}

// Coordination and reads may wait for a File Provider. Never run them on the UI
// thread. A timeout/cancel releases the UI even if that provider stops responding.
final class FileImportSession: @unchecked Sendable {
    private let lock = NSLock()
    private var finished = false
    private var coordinator: NSFileCoordinator?
    private var completion: ((Result<[URL], Error>) -> Void)?

    func checkActive() throws {
        lock.lock(); let active = !finished; lock.unlock()
        if !active { throw FileImportError.cancelled }
    }
    func use(_ coordinator: NSFileCoordinator) throws {
        lock.lock()
        if finished { lock.unlock(); throw FileImportError.cancelled }
        self.coordinator = coordinator
        lock.unlock()
    }
    @discardableResult private func finish(_ result: Result<[URL], Error>) -> Bool {
        lock.lock()
        if finished { lock.unlock(); return false }
        finished = true
        let callback = completion
        completion = nil
        lock.unlock()
        callback?(result)
        return true
    }
    func cancel(_ error: Error = FileImportError.cancelled) {
        if finish(.failure(error)) {
            lock.lock(); let current = coordinator; lock.unlock()
            current?.cancel()
        }
    }
    func run(timeout: TimeInterval = 60, abandoned: @escaping @Sendable () -> Void = {},
             operation: @escaping @Sendable (FileImportSession) throws -> [URL]) async throws -> [URL] {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            if finished { lock.unlock(); continuation.resume(throwing: FileImportError.cancelled); return }
            completion = { continuation.resume(with: $0) }
            lock.unlock()
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout) { [weak self] in
                self?.cancel(FileImportError.timedOut)
            }
            DispatchQueue.global(qos: .userInitiated).async {
                let result = Result { try operation(self) }
                if !self.finish(result) { abandoned() }
            }
        }
    }
}

enum CoordinatedFileImport {
    static func copy(_ urls: [URL], to folder: URL, session: FileImportSession,
                     progress: @escaping @Sendable (String) -> Void) throws -> [URL] {
        dispatchPrecondition(condition: .notOnQueue(.main))
        let manager = FileManager.default
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        do {
            var copies: [URL] = []
            var seen: Set<URL> = []
            let unique = urls.filter { seen.insert($0.standardizedFileURL).inserted }
            for (index, source) in unique.enumerated() {
                try session.checkActive()
                progress("Файл \(index + 1) из \(unique.count): \(source.lastPathComponent)")
                let scoped = source.startAccessingSecurityScopedResource()
                defer { if scoped { source.stopAccessingSecurityScopedResource() } }
                let coordinator = NSFileCoordinator()
                try session.use(coordinator)
                var destination = folder.appendingPathComponent(source.lastPathComponent)
                var suffix = 2
                while manager.fileExists(atPath: destination.path) {
                    let stem = source.deletingPathExtension().lastPathComponent
                    let ext = source.pathExtension.isEmpty ? "" : "." + source.pathExtension
                    destination = folder.appendingPathComponent("\(stem) (\(suffix))\(ext)"); suffix += 1
                }
                var coordinationError: NSError?
                var copyError: Error?
                var didCopy = false
                coordinator.coordinate(readingItemAt: source, options: .withoutChanges, error: &coordinationError) { readable in
                    do {
                        try session.checkActive()
                        guard try readable.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else {
                            throw FileImportError.notAFile(source.lastPathComponent)
                        }
                        let input = try FileHandle(forReadingFrom: readable)
                        defer { try? input.close() }
                        guard manager.createFile(atPath: destination.path, contents: nil) else { throw CocoaError(.fileWriteUnknown) }
                        let output = try FileHandle(forWritingTo: destination)
                        defer { try? output.close() }
                        while true {
                            try session.checkActive()
                            guard let data = try input.read(upToCount: 1024 * 1024), !data.isEmpty else { break }
                            try output.write(contentsOf: data)
                        }
                        didCopy = true
                    } catch { copyError = error }
                }
                if let error = copyError { throw error }
                if let error = coordinationError { throw error }
                guard didCopy else { throw FileImportError.notAFile(source.lastPathComponent) }
                copies.append(destination)
            }
            try session.checkActive()
            return copies
        } catch {
            try? manager.removeItem(at: folder)
            throw error
        }
    }
}

// Use open-in-place, rather than asking Files to prepare a whole import batch
// before delivering its delegate callback. Copy only after the picker is closed.
struct DocumentPicker: UIViewControllerRepresentable {
    let selected: ([URL]) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(selected: selected) }
    func makeUIViewController(context: Context) -> Presenter {
        let presenter = Presenter()
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: false)
        picker.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        picker.allowsMultipleSelection = true
        picker.shouldShowFileExtensions = true
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .fullScreen
        presenter.picker = picker
        return presenter
    }
    func updateUIViewController(_ presenter: Presenter, context: Context) {}
    // SwiftUI configures a document picker used directly as sheet content,
    // including its selection mode. Present it from a plain UIKit controller so
    // UIKit owns its complete lifecycle and preserves multiple selection.
    final class Presenter: UIViewController {
        var picker: UIDocumentPickerViewController!
        private var opened = false
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard !opened else { return }; opened = true
            picker.allowsMultipleSelection = true
            picker.shouldShowFileExtensions = true
            present(picker, animated: false)
            importTrace("Presented picker: multiple=\(picker.allowsMultipleSelection)")
        }
    }
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let selected: ([URL]) -> Void
        private var delivered = false
        private var pending: [URL] = []
        private var delivery: DispatchWorkItem?
        init(selected: @escaping ([URL]) -> Void) { self.selected = selected }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            importTrace("Picker callback: \(urls.count) files, delivered=\(delivered)")
            guard !delivered else { return }
            for url in urls where !pending.contains(url) { pending.append(url) }
            // Some providers deliver multiple callbacks. Collect them before
            // closing the picker; never discard later files from the same batch.
            delivery?.cancel()
            let work = DispatchWorkItem {
                guard !self.delivered else { return }
                self.delivered = true; self.delivery = nil
                importTrace("Delivering selection: \(self.pending.count) files")
                self.selected(self.pending)
            }
            delivery = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: work)
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            guard !delivered else { return }; delivered = true
            delivery?.cancel(); delivery = nil; pending = []
            importTrace("Picker cancelled")
            selected([])
        }
    }
}

struct ImportFilesButton: View {
    @EnvironmentObject private var store: FileStore
    var compact = false
    var selected: ([URL]) -> Void = { _ in }
    @State private var presenting = false
    @State private var error: String?
    var body: some View {
        Button { presenting = true } label: {
            if compact { Image(systemName: "plus").accessibilityLabel("Импортировать файлы") }
            else { Label("Импортировать из «Файлов»", systemImage: "square.and.arrow.down") }
        }.disabled(store.busy).accessibilityIdentifier("importFiles")
            .sheet(isPresented: $presenting) {
                DocumentPicker { urls in
                    presenting = false
                    importSelection(urls)
                }
            }
            .alert("Не удалось импортировать", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") { error = nil }
            } message: { Text(error ?? "") }
    }
    private func importSelection(_ urls: [URL]) {
        importTrace("Received selection: \(urls.count) files")
        guard !urls.isEmpty else { return }
        Task { @MainActor in
            // Leave the delegate callback before coordinating any File Provider
            // reads. Capture the URLs directly: onDismiss can observe stale State.
            await Task.yield()
            do {
                let copies = try await store.importFiles(urls)
                importTrace("Imported \(copies.count) files")
                selected(copies)
            }
            catch FileImportError.cancelled {}
            catch { self.error = error.localizedDescription }
        }
    }
}

struct ImportStatusView: View {
    @EnvironmentObject private var store: FileStore
    var body: some View {
        if store.importing {
            HStack(spacing: 12) {
                ProgressView()
                Text(store.importProgress).font(.footnote).lineLimit(2)
                Spacer()
                Button("Отменить") { store.cancelImport() }
            }.padding().background(.regularMaterial).accessibilityIdentifier("importStatus")
        }
    }
}
