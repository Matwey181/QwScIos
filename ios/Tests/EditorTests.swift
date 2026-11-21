import XCTest
import UIKit
import ZIPFoundation
@testable import QwelIos

final class EditorTests:XCTestCase {
    @MainActor func testSwiftExportSource() throws {
        var project=try XCTUnwrap(Catalog.shared.components.first{$0.id=="slider"}).project
        for kind in ["TEXT","IMAGE","ELLIPSE","RECT","SHAPE","PATH"] {
            var n=Node();n.kind=kind;n.text="Quote \" \\ and newline\nNext";n.textAlign="center";n.gradKind=1;n.strokeWidth=2;n.shadowBlur=4
            n.path="M0 0L1 0L1 1Z";n.shapeId=Catalog.shared.shapes.first?.id ?? ""
            project.nodes.append(n)
        }
        let code=SwiftExport.make(project,root:FileManager.default.temporaryDirectory)
        XCTAssertTrue(code.contains("public struct QwelExportedView"))
        XCTAssertTrue(code.contains("multilineTextAlignment(.center)"))
        try code.write(to:FileManager.default.temporaryDirectory.appendingPathComponent("QwelExportValidation.swift"),atomically:true,encoding:.utf8)
    }
    @MainActor func testTextAlignmentPersistsThroughArchiveAndOriginalCore() throws {
        var node=Node();node.kind="TEXT";node.text="Test";node.w=240;node.textAlign="center"
        var project=Project();project.nodes=[node]
        let decoded=try JSONDecoder().decode(Project.self,from:JSONEncoder().encode(project))
        XCTAssertEqual(decoded.nodes[0].textAlign,"center")
        let font=UIFont.systemFont(ofSize:node.fontSize)
        let centered=TextLayout(node,font:font)
        let centerX=centered.manager.boundingRect(forGlyphRange:NSRange(location:0,length:1),in:centered.container).minX
        node.textAlign="right"
        let right=TextLayout(node,font:font)
        XCTAssertGreaterThan(right.manager.boundingRect(forGlyphRange:NSRange(location:0,length:1),in:right.container).minX,centerX)
        XCTAssertTrue(SVGExport.make(project,root:FileManager.default.temporaryDirectory).contains("text-anchor=\"middle\""))
        _ = try OriginalCore.shared.request(["op":"set"],project:project)
        XCTAssertEqual(try OriginalCore.shared.project("apply",values:["shown":[:]]).nodes[0].textAlign,"center")
        let old=try JSONDecoder().decode(Node.self,from:Data("{\"kind\":\"TEXT\"}".utf8))
        XCTAssertEqual(old.textAlign,"left")
    }
    @MainActor func testTextReflowsWithoutShrinkingAndUndoRestoresEdit() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let e=Editor(Project(),store:ProjectStore(root:root))
        defer{e.pendingSaveForTestingCleanup();try? FileManager.default.removeItem(at:root)}
        e.add("TEXT")
        let id=try XCTUnwrap(e.selected.first?.id)
        XCTAssertEqual(e.requestTextEdit,id)
        let original=e.selected[0].text
        e.commitText(id,text:"Первая строка и ещё несколько слов для проверки переноса текста")
        e.undo();XCTAssertEqual(e.selected[0].text,original)
        e.redo()
        e.change{$0.w=260}
        let wide=e.selected[0]
        e.change{$0.w=80}
        let narrow=e.selected[0]
        XCTAssertEqual(narrow.fontSize,wide.fontSize)
        XCTAssertGreaterThan(narrow.h,wide.h)
        let layout=TextLayout(narrow,font:e.renderer.font(narrow))
        XCTAssertGreaterThan(layout.lines.count,1)
        XCTAssertEqual(narrow.h,layout.height)
        let svg=SVGExport.make(e.project,root:root)
        XCTAssertEqual(svg.components(separatedBy:"<tspan ").count-1,layout.lines.count)
        XCTAssertNotNil(e.renderer.png(e.project,scale:0.25))
    }
    @MainActor func testNewShapesAreCenteredAndNotSquashed() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let e=Editor(Project(),store:ProjectStore(root:root))
        defer{e.pendingSaveForTestingCleanup();try? FileManager.default.removeItem(at:root)}
        for kind in ["ELLIPSE","SHAPE"] {
            e.add(kind)
            let node=try XCTUnwrap(e.selected.first)
            XCTAssertEqual(node.w,node.h)
            XCTAssertEqual(node.center.x,e.project.w/2)
            XCTAssertEqual(node.center.y,e.project.h/2)
        }
    }
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
    @MainActor func testOriginalKotlinSliderAndPersistentState() throws {
        let component=try XCTUnwrap(Catalog.shared.components.first{$0.id=="slider"})
        let project=component.project
        let core=OriginalCore.shared
        let result=try core.request(["op":"set"],project:project)
        let widgets=try XCTUnwrap(result["widgets"] as? [[String:Any]])
        let group=try XCTUnwrap(widgets.first?["group"] as? String)
        let first=try core.project("apply",values:["shown":[group:0.0]])
        let last=try core.project("apply",values:["shown":[group:1.0]])
        let left=try XCTUnwrap(first.nodes.first{$0.widget=="slider:thumb"})
        let right=try XCTUnwrap(last.nodes.first{$0.widget=="slider:thumb"})
        XCTAssertGreaterThan(right.x-left.x,200)
        let persisted=try core.project("stop",values:["shown":[group:1.0]])
        XCTAssertEqual(persisted.nodes.first{$0.widget=="slider:thumb"}?.x,right.x)
        let code=try core.compose(project)
        XCTAssertTrue(code.contains("Slider("))
    }
    @MainActor func testOriginalSwitchMovesThumbWithoutDestroyingLayers() throws {
        let p=try XCTUnwrap(Catalog.shared.components.first{$0.id=="switch"}).project
        let result=try OriginalCore.shared.request(["op":"set"],project:p)
        let widgets=try XCTUnwrap(result["widgets"] as? [[String:Any]])
        let group=try XCTUnwrap(widgets.first?["group"] as? String)
        let off=try OriginalCore.shared.project("apply",values:["shown":[group:0.0]])
        let on=try OriginalCore.shared.project("apply",values:["shown":[group:1.0]])
        XCTAssertEqual(off.nodes.count,on.nodes.count)
        XCTAssertNotEqual(off.nodes.first{$0.widget=="switch:thumb"}?.x,on.nodes.first{$0.widget=="switch:thumb"}?.x)
    }
    @MainActor func testOriginalMorphAndSourceProjectArchive() throws {
        let result=try OriginalCore.shared.request(["op":"morph","from":"cookie-9","to":"soft-burst"])
        let start=try XCTUnwrap(result["start"] as? [NSNumber]),end=try XCTUnwrap(result["end"] as? [NSNumber])
        XCTAssertEqual(start.count,end.count);XCTAssertGreaterThan(start.count,8)
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:root)}
        let store=ProjectStore(root:root)
        XCTAssertNotNil(UIFont(name:"InterSA-Regular",size:16))
        let p=try XCTUnwrap(Catalog.shared.templates.first).project
        let url=try OriginalCore.shared.sourceArchive(p,root:store.root,kind:"codeassist")
        let archive=try Archive(url:url,accessMode:.read)
        XCTAssertNotNil(archive["app/module.toml"])
        XCTAssertNotNil(archive["app/src/main/AndroidManifest.xml"])
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
