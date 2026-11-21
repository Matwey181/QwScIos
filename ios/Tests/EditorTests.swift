import XCTest
import UIKit
import ZIPFoundation
@testable import QwelIos

final class EditorTests:XCTestCase {
    @MainActor func testOriginalCatalogAndRendering() throws {
        let catalog=Catalog.shared
        XCTAssertEqual(catalog.components.count,81);XCTAssertEqual(catalog.templates.count,15);XCTAssertEqual(catalog.shapes.count,42)
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:root) }
        let store=ProjectStore(root:root),renderer=DocumentRenderer(root:root)
        for template in catalog.templates { XCTAssertNotNil(renderer.png(template.project,scale:0.25),template.id) }
        for shape in catalog.shapes {
            let box=VectorPath.parse(shape.path).boundingBoxOfPath
            XCTAssertFalse(box.isNull,shape.id);XCTAssertGreaterThan(box.width,0,shape.id)
            XCTAssertLessThanOrEqual(box.maxX,1.01,shape.id);XCTAssertGreaterThanOrEqual(box.minX,-0.01,shape.id)
        }
        XCTAssertTrue(store.projects.isEmpty)
    }
    @MainActor func testArchiveContainsEveryPageAndPreservesAssets() async throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:root) }
        let store=ProjectStore(root:root)
        let editor=Editor(Project(),store:store)
        let image=UIGraphicsImageRenderer(size:CGSize(width:20,height:12)).image { context in UIColor.red.setFill();context.fill(CGRect(x:0,y:0,width:20,height:12)) }
        try editor.addImage(try XCTUnwrap(image.pngData()),name:"Image")
        editor.addPage();editor.add("RECT");editor.page(0)
        let url=try store.archive(editor.project)
        let zip=try Archive(url:url,accessMode:.read)
        XCTAssertNotNil(zip["project.json"])
        XCTAssertEqual(zip.filter{$0.path.hasPrefix("assets/")}.count,1)
        await store.importFile(url)
        XCTAssertNil(store.error)
        let imported=try XCTUnwrap(store.projects.first)
        XCTAssertEqual(imported.pages.count,2)
        XCTAssertEqual(imported.pages[0].nodes.first?.kind,"IMAGE")
        XCTAssertEqual(imported.pages[1].nodes.first?.kind,"RECT")
        let name=try XCTUnwrap(imported.pages[0].nodes.first?.asset)
        XCTAssertTrue(FileManager.default.fileExists(atPath:store.assets.appendingPathComponent(name).path))
        XCTAssertNotNil(DocumentRenderer(root:root).png(imported,scale:0.2))
    }
    @MainActor func testEditingUndoPersistenceAndBooleans() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:root) }
        let store=ProjectStore(root:root),e=Editor(Project(),store:ProjectStore(root:root))
        e.add("RECT");e.duplicate();e.selection=Set(e.project.nodes.map(\.id));e.boolean("union")
        XCTAssertEqual(e.project.nodes.count,1);XCTAssertEqual(e.project.nodes[0].kind,"PATH")
        e.undo();XCTAssertEqual(e.project.nodes.count,2);e.redo();XCTAssertEqual(e.project.nodes.count,1)
        e.saveNow();store.reload();XCTAssertEqual(store.projects.count,1)
        XCTAssertEqual(store.projects[0].nodes[0].path,e.project.nodes[0].path)
        e.pendingSaveForTestingCleanup()
    }
    func testSVGPathsAndImport() throws {
        let path=VectorPath.parse("M10 10h20v20h-20z M50 50a20 10 30 1 1 30 0")
        XCTAssertGreaterThan(path.boundingBoxOfPath.width,20)
        let data=Data("<svg xmlns='http://www.w3.org/2000/svg'><g transform='translate(10 20)'><rect x='0' y='0' width='30' height='40' fill='#ff0000'/></g><path d='M0 0 L10 0 L10 10 Z'/></svg>".utf8)
        let nodes=try SVGImport.parse(data)
        XCTAssertEqual(nodes.count,2);XCTAssertEqual(nodes[0].x,10);XCTAssertEqual(nodes[0].y,20)
        XCTAssertTrue(SVGExport.make({ var p=Project();p.nodes=nodes;return p }(),root:FileManager.default.temporaryDirectory).contains("#FF0000"))
    }
}
