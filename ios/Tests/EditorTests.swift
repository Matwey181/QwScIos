import XCTest
import UIKit
import QuartzCore
import ZIPFoundation
@testable import QwelIos

final class EditorTests:XCTestCase {
    @MainActor func testReversibleAndroidShapeMorphAndPortableCurve() throws {
        var source=Node();source.name="Кнопка"
        var star=Node();star.kind="SHAPE";star.shapeId="star-5"
        var label=Node();label.kind="TEXT";label.text="Старт"
        var morph=InteractionLink();morph.sourceID=source.id;morph.targetID=star.id
        morph.property="morph";morph.shapeID="star-8";morph.alternate=true;morph.duration=0.4;morph.easing="bezier:0.2,0,0,1"
        var words=InteractionLink();words.sourceID=source.id;words.targetID=label.id;words.mode="text";words.text="Пауза";words.alternate=true
        var p=Project();p.nodes=[source,star,label];p.links=[morph,words]
        let runtime=InteractionRuntime();runtime.start(p)
        runtime.fire("tap",sourceID:source.id)
        runtime.tick(at:CACurrentMediaTime()+1)
        let first=runtime.displayed(p)
        XCTAssertEqual(first.nodes[2].text,"Пауза")
        let expected=try XCTUnwrap(LinkMorph(from:"star-5",to:"star-8"))
        XCTAssertEqual(first.nodes[1].path,expected.svg(1))
        runtime.fire("tap",sourceID:source.id)
        runtime.tick(at:CACurrentMediaTime()+1)
        let second=runtime.displayed(p)
        XCTAssertEqual(second.nodes[2].text,"Старт")
        XCTAssertEqual(second.nodes[1].path,expected.svg(0))
        XCTAssertEqual(InteractionLink.eased(0,morph.easing),0)
        XCTAssertEqual(InteractionLink.eased(1,morph.easing),1)
        XCTAssertGreaterThan(InteractionLink.eased(0.5,morph.easing),0.5)
        let old=try JSONDecoder().decode(InteractionLink.self,from:JSONEncoder().encode(InteractionLink()))
        XCTAssertNil(old.alternate)
        let root=FileManager.default.temporaryDirectory
        let code=SwiftExport.make(p,root:root)
        XCTAssertTrue(code.contains("morphFrom: ["));XCTAssertTrue(code.contains("alternate: true"))
        try code.write(to:root.appendingPathComponent("QwelMorphValidation.swift"),atomically:true,encoding:.utf8)
    }
    @MainActor func testColorBindingCancelsAnimationAndBoundEchoAppears() {
        var source=Node();var target=Node();target.kind="RECT";target.fill = -16777216
        var color=InteractionLink();color.sourceID=source.id;color.targetID=target.id;color.mode="bind";color.event="drag";color.property="fill";color.color = -1;color.easing="linear"
        var echo=color;echo.id=UUID().uuidString;echo.property="echo";echo.from=0;echo.to=1
        var p=Project();p.nodes=[source,target];p.links=[color,echo]
        let runtime=InteractionRuntime();runtime.start(p)
        runtime.fire("drag",sourceID:source.id,fraction:0.5)
        let shown=runtime.displayed(p)
        XCTAssertEqual(UInt32(truncatingIfNeeded:shown.nodes.first{$0.id==target.id}!.fill)&0xffffff,0x808080)
        XCTAssertGreaterThan(shown.nodes.count,p.nodes.count)
        runtime.stop();XCTAssertEqual(runtime.displayed(p),p)
    }
    @MainActor func testSwiftExportSource() throws {
        var project=try XCTUnwrap(Catalog.shared.components.first{$0.id=="slider"}).project
        for kind in ["TEXT","IMAGE","ELLIPSE","RECT","SHAPE","PATH"] {
            var n=Node();n.kind=kind;n.text="Quote \" \\ and newline\nNext";n.textAlign="center";n.gradKind=1;n.strokeWidth=2;n.shadowBlur=4
            n.path="M0 0L1 0L1 1Z";n.shapeId=Catalog.shared.shapes.first?.id ?? ""
            project.nodes.append(n)
        }
        let source=project.nodes.first!.id
        let destination=project.nodes.last!.id
        var textRule=InteractionLink()
        textRule.sourceID=source
        textRule.event="tap"
        textRule.mode="text"
        textRule.targetID=destination
        textRule.text="Переключено"
        var slideRule=InteractionLink()
        slideRule.sourceID=source
        slideRule.event="drag"
        slideRule.mode="bind"
        slideRule.property="opacity"
        slideRule.targetID=destination
        slideRule.from=0
        slideRule.to=1
        project.links=[textRule,slideRule]
        let code=SwiftExport.make(project,root:FileManager.default.temporaryDirectory)
        XCTAssertTrue(code.contains("public struct QwelExportedView"))
        XCTAssertTrue(code.contains("QwelExportRuntime"))
        XCTAssertTrue(code.contains("graph.emit"))
        XCTAssertTrue(code.contains("dragChanged"))
        XCTAssertTrue(code.contains("Переключено"))
        XCTAssertTrue(code.contains("multilineTextAlignment(.center)"))
        try code.write(to:FileManager.default.temporaryDirectory.appendingPathComponent("QwelExportValidation.swift"),atomically:true,encoding:.utf8)
    }
    @MainActor func testRuleGraphPersistsAndRunsInPlayMode() throws {
        let source=Node()
        var destination=Node()
        destination.kind="TEXT"
        destination.text="До"
        destination.x=120
        var document=Project()
        document.nodes=[source,destination]

        var tap=InteractionLink()
        tap.sourceID=source.id
        tap.targetID=destination.id
        tap.event="tap"
        tap.mode="text"
        tap.text="После"

        var drag=InteractionLink()
        drag.sourceID=source.id
        drag.targetID=destination.id
        drag.event="drag"
        drag.mode="bind"
        drag.property="opacity"
        drag.from=0
        drag.to=1

        document.links=[tap,drag]
        let data=try JSONEncoder().encode(document)
        let restored=try JSONDecoder().decode(Project.self,from:data)
        XCTAssertEqual(restored.links.count,2)
        XCTAssertEqual(restored.links[0].text,"После")

        let runtime=InteractionRuntime()
        runtime.start(restored)
        runtime.fire("tap",sourceID:source.id)
        XCTAssertEqual(runtime.displayed(document).nodes[1].text,"После")
        runtime.fire("drag",sourceID:source.id,fraction:0.25)
        XCTAssertEqual(Double(runtime.displayed(document).nodes[1].opacity),0.25,accuracy:0.001)
        runtime.stop()
        XCTAssertEqual(runtime.displayed(document).nodes[1].text,"До")
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
    @MainActor func testAndroidTemplatesKeepTheirTextPositionsAndExplicitLineBreaks() throws {
        let templates=Catalog.shared.templates
        XCTAssertEqual(templates.count,15)
        var total=0
        for item in templates {
            let original=item.project
            let rendered=DocumentRenderer(root:FileManager.default.temporaryDirectory)
            XCTAssertNotNil(rendered.png(original,scale:0.2),item.id)
            for node in original.nodes where node.kind=="TEXT" && !node.text.isEmpty {
                total += 1
                XCTAssertTrue(TextLayout.isAndroidCatalogText(node),"\(item.id): \(node.text)")
                let font=rendered.font(node)
                let layout=TextLayout(node,font:font)
                XCTAssertEqual(layout.lines.count,node.text.components(separatedBy:"\n").count,
                               "\(item.id): unexpected wrapped line in \(node.text)")
            }
            let exported=SwiftExport.make(original,root:FileManager.default.temporaryDirectory)
            XCTAssertTrue(exported.contains("fixedSize(horizontal: true, vertical: true)"),
                          item.id)
        }
        XCTAssertGreaterThan(total,150)
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

    @MainActor func testLinkedModeTapDragTextAndExport() throws {
        var p=Project()
        var button=Node()
        button.kind="RECT";button.name="Кнопка";button.x=10;button.y=10;button.w=100;button.h=40
        var target=Node()
        target.kind="TEXT";target.name="Надпись";target.text="Было"
        p.nodes=[button,target]

        var textRule=InteractionLink()
        textRule.sourceID=button.id
        textRule.targetID=target.id
        textRule.event="tap"
        textRule.mode="text"
        textRule.text="Стало"
        var dragRule=InteractionLink()
        dragRule.sourceID=button.id
        dragRule.targetID=target.id
        dragRule.event="drag"
        dragRule.mode="bind"
        dragRule.property="rotation"
        dragRule.from=0
        dragRule.to=180
        p.links=[textRule,dragRule]

        let copy=try JSONDecoder().decode(Project.self,from:JSONEncoder().encode(p))
        XCTAssertEqual(copy.links.count,2)
        let runtime=InteractionRuntime()
        runtime.start(copy)
        runtime.fire("tap",sourceID:button.id)
        XCTAssertEqual(runtime.displayed(copy).nodes[1].text,"Стало")
        runtime.fire("drag",sourceID:button.id,fraction:0.5)
        XCTAssertEqual(runtime.displayed(copy).nodes[1].rotation,90,accuracy:0.001)

        let exported=SwiftExport.make(copy,root:FileManager.default.temporaryDirectory)
        XCTAssertTrue(exported.contains("QwelRule(source:"))
        XCTAssertTrue(exported.contains("DragGesture(minimumDistance: 2)"))
        XCTAssertTrue(exported.contains("QwelExportRuntime"))
    }
    @MainActor func testTimedProgressAndEchoBindings() throws {
        var p=Project()
        var source=Node()
        source.kind="RECT"
        var target=Node()
        target.kind="RECT";target.w=200;target.h=30
        p.nodes=[source,target]
        var timed=InteractionLink()
        timed.sourceID=source.id
        timed.targetID=target.id
        timed.event="tap"
        timed.mode="animate"
        timed.property="progress"
        timed.duration=15
        var echo=InteractionLink()
        echo.sourceID=source.id
        echo.targetID=target.id
        echo.event="tap"
        echo.mode="echo"
        echo.duration=1
        var follow=InteractionLink();follow.sourceID=target.id;follow.targetID=source.id
        follow.event="valueChanged";follow.mode="bind";follow.property="rotation";follow.from=0;follow.to=180;follow.easing="linear"
        p.links=[timed,echo,follow]
        let runtime=InteractionRuntime()
        runtime.start(p)
        runtime.fire("tap",sourceID:source.id)
        let echoed=runtime.displayed(p,at:CACurrentMediaTime()+0.3)
        XCTAssertGreaterThan(echoed.nodes.count,2)
        runtime.tick(at:CACurrentMediaTime()+7.5)
        let middle=runtime.displayed(p,at:CACurrentMediaTime()+7.5)
        let animated=try XCTUnwrap(middle.nodes.first(where:{$0.id==target.id}))
        XCTAssertLessThan(animated.w,200)
        XCTAssertGreaterThan(animated.w,0)
        XCTAssertEqual(middle.nodes.first{$0.id==source.id}!.rotation,90,accuracy:1)
    }
}
