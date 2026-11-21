import Foundation
import UIKit
import Combine

enum Core {
    private static let queue = DispatchQueue(label: "com.qwsc.ios.core", qos: .userInitiated)
    static func run(_ operation: String, _ arguments: [String]) async -> String {
        await withCheckedContinuation { continuation in
            queue.async {
                let allocated = arguments.map { strdup($0) }
                defer { allocated.forEach { free($0) } }
                let pointers: [UnsafePointer<CChar>?] = allocated.map { ptr in ptr.map { UnsafePointer($0) } }
                let result: String = pointers.withUnsafeBufferPointer { buffer in
                    guard let output = qw_run(operation, Int32(arguments.count), buffer.baseAddress) else {
                        return "Error: недостаточно памяти"
                    }
                    defer { qw_free(output) }
                    return String(cString: output)
                }
                continuation.resume(returning: result)
            }
        }
    }
}

struct FileItem: Identifiable {
    let url: URL
    var id: String { url.path }
    var title: String { url.lastPathComponent }
}

@MainActor final class FileStore: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var error: String?
    @Published var busy = false
    let documents: URL
    init() {
        documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: documents.appendingPathComponent("Imports"), withIntermediateDirectories: true)
        reload()
    }
    func reload() {
        let keys: [URLResourceKey] = [.isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(at: documents, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]) else { return }
        files = enumerator.compactMap { entry -> FileItem? in
            guard let url = entry as? URL, url.pathExtension != "raw",
                  (try? url.resourceValues(forKeys: Set(keys)).isRegularFile) == true else { return nil }
            return FileItem(url: url)
        }.sorted { $0.url.path > $1.url.path }
    }
    func importFiles(_ urls: [URL]) throws -> [URL] {
        let folder = documents.appendingPathComponent("Imports").appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var copies: [URL] = []
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let destination = folder.appendingPathComponent(url.lastPathComponent)
            try FileManager.default.copyItem(at: url, to: destination)
            copies.append(destination)
        }
        reload()
        return copies
    }
    func resultFolder() throws -> URL {
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let url = documents.appendingPathComponent("Results").appendingPathComponent(stamp + "-" + UUID().uuidString.prefix(6))
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

func nativeFailed(_ text: String) -> Bool {
    text.hasPrefix("Error") || text.hasPrefix("❌") || text.hasPrefix("Unknown")
}

func rawAtlas(at url: URL) throws -> UIImage {
    let data = try Data(contentsOf: url, options: .mappedIfSafe)
    guard data.count >= 8 else { throw CocoaError(.fileReadCorruptFile) }
    let w = data.prefix(4).enumerated().reduce(UInt32(0)) { $0 | UInt32($1.element) << (8 * $1.offset) }
    let h = data.dropFirst(4).prefix(4).enumerated().reduce(UInt32(0)) { $0 | UInt32($1.element) << (8 * $1.offset) }
    guard w > 0, h > 0, w <= 16384, h <= 16384, UInt64(w) * UInt64(h) * 4 <= UInt64(data.count - 8) else { throw CocoaError(.fileReadCorruptFile) }
    let pixels = data.subdata(in: 8..<(8 + Int(w) * Int(h) * 4))
    guard let provider = CGDataProvider(data: pixels as CFData),
          let image = CGImage(width: Int(w), height: Int(h), bitsPerComponent: 8, bitsPerPixel: 32,
                              bytesPerRow: Int(w) * 4, space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                              provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else { throw CocoaError(.fileReadCorruptFile) }
    return UIImage(cgImage: image)
}
