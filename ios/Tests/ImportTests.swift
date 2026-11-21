import XCTest
import UIKit
import UniformTypeIdentifiers
@testable import QwScIos

final class ImportTests: XCTestCase {
    private func workspace() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ImportTests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    @MainActor func testMultipleFilesPreserveBytesAndSiblingNames() async throws {
        let root = try workspace(); defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("fixture.sc")
        let second = root.appendingPathComponent("fixture_tex.sc")
        let a = Data(repeating: 71, count: 2 * 1024 * 1024 + 37)
        let b = Data(repeating: 29, count: 59)
        try a.write(to: first); try b.write(to: second)
        let store = FileStore(documents: root.appendingPathComponent("Documents"))
        let result = try await store.importFiles([first, second])
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].deletingLastPathComponent(), result[1].deletingLastPathComponent())
        XCTAssertEqual(try Data(contentsOf: result[0]), a)
        XCTAssertEqual(try Data(contentsOf: result[1]), b)
        XCTAssertEqual(Set(store.files.map(\.title)), ["fixture.sc", "fixture_tex.sc"])
        XCTAssertFalse(store.busy); XCTAssertFalse(store.importing)
    }
    @MainActor func testDuplicateNamesAndURLs() async throws {
        let root = try workspace(); defer { try? FileManager.default.removeItem(at: root) }
        let a = root.appendingPathComponent("a"), b = root.appendingPathComponent("b")
        for folder in [a, b] { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) }
        let first = a.appendingPathComponent("image.png"), second = b.appendingPathComponent("image.png")
        try Data([1]).write(to: first); try Data([2]).write(to: second)
        let store = FileStore(documents: root.appendingPathComponent("Documents"))
        let result = try await store.importFiles([first, second, first])
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(Set(result.map(\.lastPathComponent)), ["image.png", "image (2).png"])
        XCTAssertEqual(try result.map { try Data(contentsOf: $0) }, [Data([1]), Data([2])])
    }
    @MainActor func testFailureRollsBackBatchAndAllowsRetry() async throws {
        let root = try workspace(); defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("image.png")
        try Data([1, 2, 3]).write(to: source)
        let store = FileStore(documents: root.appendingPathComponent("Documents"))
        do {
            _ = try await store.importFiles([source, root.appendingPathComponent("missing.png")])
            XCTFail("Missing file was accepted")
        } catch {}
        XCTAssertTrue(store.files.isEmpty)
        XCTAssertFalse(store.busy)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: store.documents.appendingPathComponent("Imports").path).count, 0)
        let result = try await store.importFiles([source])
        XCTAssertEqual(result.count, 1)
    }
    @MainActor func testUnresponsiveProviderTimesOutWithoutBlockingMainThread() async throws {
        let session = FileImportSession()
        let gate = DispatchSemaphore(value: 0)
        defer { gate.signal() }
        let start = Date()
        do {
            _ = try await session.run(timeout: 0.1) { _ in
                XCTAssertFalse(Thread.isMainThread)
                gate.wait()
                return []
            }
            XCTFail("Stalled provider was accepted")
        } catch FileImportError.timedOut {
            XCTAssertLessThan(Date().timeIntervalSince(start), 2)
            XCTAssertTrue(Thread.isMainThread)
        }
    }
    @MainActor func testCancellationReturnsBeforeProviderUnblocks() async throws {
        let session = FileImportSession()
        let started = expectation(description: "Worker started")
        let abandoned = expectation(description: "Late provider response discarded")
        let gate = DispatchSemaphore(value: 0)
        let task = Task {
            try await session.run(timeout: 5, abandoned: { abandoned.fulfill() }) { _ in
                started.fulfill(); gate.wait(); return []
            }
        }
        await fulfillment(of: [started], timeout: 2)
        session.cancel()
        do { _ = try await task.value; XCTFail("Cancellation ignored") }
        catch FileImportError.cancelled {}
        gate.signal()
        await fulfillment(of: [abandoned], timeout: 2)
    }
    @MainActor func testPickerCollectsSelectionCallbacksAndDeliversOnce() async {
        var received: [[URL]] = []
        let ready = expectation(description: "Complete picker selection")
        let coordinator = DocumentPicker.Coordinator { received.append($0); ready.fulfill() }
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: false)
        let urls = [URL(fileURLWithPath: "/a.png"), URL(fileURLWithPath: "/b.png")]
        coordinator.documentPicker(picker, didPickDocumentsAt: [urls[0]])
        coordinator.documentPicker(picker, didPickDocumentsAt: [urls[1]])
        coordinator.documentPicker(picker, didPickDocumentsAt: [urls[0]])
        await fulfillment(of: [ready], timeout: 2)
        coordinator.documentPicker(picker, didPickDocumentsAt: urls)
        XCTAssertEqual(received, [urls])
    }
}
