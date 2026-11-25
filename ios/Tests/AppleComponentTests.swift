import XCTest
import UIKit
import QuartzCore
@testable import QwelIos

final class AppleComponentTests:XCTestCase {
    @MainActor func testAppleSwitchKeepsDesignAfterRepeatedPlayAndArchive() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:root)}
        let store=ProjectStore(root:root)
        for dark in [false,true] {
            for id in ["ios-switch-on","ios-switch-off","ios-list-switch"] {
                let item=try XCTUnwrap(Catalog.shared.components.first{$0.id==id})
                var base=AppleCatalog.variant(item,dark:dark).project
                let thumb=try XCTUnwrap(base.nodes.first(where:AppleControls.isThumb))
                let track=try XCTUnwrap(base.nodes.first(where:AppleControls.isTrack))
                let group=track.group
                for value in [0.0,1,0,1] {
                    _ = try OriginalCore.shared.request(["op":"set"],project:base)
                    let midpoint=try OriginalCore.shared.project("apply",values:["shown":[group:0.5]])
                    let stretched=try XCTUnwrap(midpoint.nodes.first{$0.id==thumb.id})
                    XCTAssertGreaterThan(stretched.w,thumb.w)
                    let stopped=try OriginalCore.shared.project("stop",values:["shown":[group:value]])
                    let result=try XCTUnwrap(stopped.nodes.first{$0.id==thumb.id})
                    let rail=try XCTUnwrap(stopped.nodes.first{$0.id==track.id})
                    XCTAssertEqual(result.kind,thumb.kind)
                    XCTAssertEqual(result.w,thumb.w,accuracy:0.001)
                    XCTAssertEqual(result.h,thumb.h,accuracy:0.001)
                    XCTAssertEqual(result.liquid,thumb.liquid)
                    XCTAssertEqual(result.widget,thumb.widget)
                    XCTAssertEqual(rail.rect,track.rect)
                    XCTAssertEqual(rail.fillToken,track.fillToken)
                    XCTAssertTrue(rail.widget.hasPrefix("switch:itrack"))
                    base=try JSONDecoder().decode(Project.self,from:JSONEncoder().encode(stopped))
                }
            }
        }
        _ = store
    }
    @MainActor func testTapProducesIntermediateFramesAndStopPreservesAppleStyle() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:root)}
        let editor=Editor(Project(),store:ProjectStore(root:root))
        defer{editor.pendingSaveForTestingCleanup()}
        editor.addComponent(try XCTUnwrap(Catalog.shared.components.first{$0.id=="ios-switch-off"}))
        let track=try XCTUnwrap(editor.project.nodes.first(where:AppleControls.isTrack))
        let thumb=try XCTUnwrap(editor.project.nodes.first(where:AppleControls.isThumb))
        let runtime=editor.originalPlay
        runtime.start()
        XCTAssertEqual(runtime.shown[track.group],0)
        runtime.tap(track.center)
        XCTAssertEqual(runtime.target[track.group],1)
        XCTAssertEqual(runtime.shown[track.group],0)
        runtime.advanceWidgetAnimations(by:1.0/60)
        let middle=try XCTUnwrap(runtime.shown[track.group])
        XCTAssertGreaterThan(middle,0);XCTAssertLessThan(middle,1)
        for _ in 0..<60{runtime.advanceWidgetAnimations(by:1.0/60)}
        XCTAssertEqual(runtime.shown[track.group],1)
        runtime.stop()
        let final=try XCTUnwrap(editor.project.nodes.first{$0.id==thumb.id})
        XCTAssertEqual(final.w,thumb.w,accuracy:0.001)
        XCTAssertEqual(final.h,thumb.h,accuracy:0.001)
        XCTAssertEqual(final.liquid,thumb.liquid)
        XCTAssertGreaterThan(final.x,thumb.x)
        editor.undo()
        XCTAssertEqual(editor.project.nodes.first{$0.id==thumb.id}?.x,thumb.x)
    }
    @MainActor func testNativeLabelsUseSystemFontAndKeepAlignment() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:root)}
        let store=ProjectStore(root:root),renderer=DocumentRenderer(root:root)
        for dark in [false,true] {
            for item in AppleCatalog.bundle.light {
                let prepared=AppleCatalog.variant(item,dark:dark).project
                for node in prepared.nodes where node.kind=="TEXT" && !node.text.isEmpty {
                    let font=renderer.font(node)
                    XCTAssertTrue(node.font.isEmpty)
                    XCTAssertEqual(font.fontName,UIFont.systemFont(ofSize:node.fontSize,weight:node.weight>=700 ? .bold:node.weight>=600 ? .semibold:node.weight>=500 ? .medium:node.weight<=300 ? .light:.regular).fontName)
                    let layout=TextLayout(node,font:font)
                    XCTAssertEqual(layout.lines.count,node.text.components(separatedBy:"\n").count,"\(item.id): \(node.text)")
                }
            }
        }
        let raw=try XCTUnwrap(AppleCatalog.bundle.light.first{$0.id=="ios-btn-filled"})
        let prepared=AppleCatalog.variant(raw,dark:false)
        XCTAssertEqual(try XCTUnwrap(raw.project.nodes.first{$0.kind=="TEXT"}).center.x,
                       try XCTUnwrap(prepared.project.nodes.first{$0.kind=="TEXT"}).center.x,accuracy:0.01)
        var p=prepared.project
        DesignLayoutEngine.resolve(&p,renderer:renderer)
        XCTAssertEqual(p.nodes,prepared.project.nodes)
        _ = store
    }
    @MainActor func testPickerCanAnimateToLastItemWithoutChangingTextY() throws {
        for id in ["ios-segmented","ios-tab-bar"] {
            var base=AppleCatalog.variant(try XCTUnwrap(Catalog.shared.components.first{$0.id==id}),dark:false).project
            let indicator=try XCTUnwrap(base.nodes.first{$0.widget=="pick:ind"})
            let group=indicator.group
            let count=Set(base.nodes.filter{$0.widget.hasPrefix("pick:i") && !$0.widget.hasPrefix("pick:ind")}.map{$0.widget.split(separator:"/").first!}).count
            let target=Double(count-1)
            let original=Dictionary(uniqueKeysWithValues:base.nodes.filter{$0.kind=="TEXT"}.map{($0.id,$0.y)})
            _ = try OriginalCore.shared.request(["op":"set"],project:base)
            let final=try OriginalCore.shared.project("stop",values:["shown":[group:target]])
            let moved=try XCTUnwrap(final.nodes.first{$0.id==indicator.id})
            XCTAssertGreaterThan(moved.x,indicator.x)
            XCTAssertEqual(moved.y,indicator.y,accuracy:0.001)
            for node in final.nodes where node.kind=="TEXT"{XCTAssertEqual(node.y,try XCTUnwrap(original[node.id]),accuracy:0.001)}
            base.nodes=final.nodes
        }
    }
    @MainActor func testPreviouslyMaterializedAppleSwitchIsRepairedWhenOpened() throws {
        var p=try XCTUnwrap(AppleCatalog.bundle.light.first{$0.id=="ios-switch-on"}).project
        let rail=try XCTUnwrap(p.nodes.firstIndex(where:AppleControls.isTrack))
        let knob=try XCTUnwrap(p.nodes.firstIndex(where:AppleControls.isThumb))
        let original=p.nodes
        for i in p.nodes.indices{p.nodes[i].group="fixture~ios-switch-on"}
        p.nodes[rail].widget=p.nodes[rail].widget.replacingOccurrences(of:"switch:itrack",with:"switch:track")
        p.nodes[rail].fillToken=0;p.nodes[rail].x-=1;p.nodes[rail].y-=1;p.nodes[rail].w+=2;p.nodes[rail].h+=2
        p.nodes[knob].widget="switch:thumb";p.nodes[knob].w=24;p.nodes[knob].h=24;p.nodes[knob].fillToken=1
        AppleCatalog.prepare(&p,id:"ios")
        XCTAssertEqual(p.nodes[rail].rect,original[rail].rect)
        XCTAssertEqual(p.nodes[knob].rect,original[knob].rect)
        XCTAssertEqual(p.nodes[knob].fill,original[knob].fill)
        XCTAssertTrue(p.nodes[rail].widget.hasPrefix("switch:itrack"))
        let once=p
        AppleCatalog.prepare(&p,id:"ios")
        XCTAssertEqual(p,once)
    }
    @MainActor func testAlertOnBlankPageDoesNotNeedBackdropPipeline() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:root)}
        let store=ProjectStore(root:root),renderer=DocumentRenderer(root:root)
        let alert=try XCTUnwrap(Catalog.shared.components.first{$0.id=="ios-alert"})
        let project=AppleCatalog.variant(alert,dark:false).project
        XCTAssertFalse(DocumentRenderer.needsBackdrop(project))
        XCTAssertNotNil(renderer.png(project,scale:1))
        XCTAssertEqual(renderer.backdropRenderCount,0)
        _ = store
    }
    @MainActor func testBackdropCacheInvalidatesOnlyWhenItsInputChanges() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:root)}
        let store=ProjectStore(root:root),renderer=DocumentRenderer(root:root)
        var project=AppleCatalog.variant(try XCTUnwrap(Catalog.shared.components.first{$0.id=="ios-alert"}),dark:false).project
        var lower=Node();lower.x=15;lower.y=15;lower.w=200;lower.h=100;lower.fill = -65536
        project.nodes.insert(lower,at:0)
        XCTAssertTrue(DocumentRenderer.needsBackdrop(project))
        XCTAssertNotNil(renderer.png(project,scale:1))
        let renders=renderer.backdropRenderCount
        XCTAssertGreaterThan(renders,0)
        XCTAssertNotNil(renderer.png(project,scale:1))
        XCTAssertEqual(renderer.backdropRenderCount,renders)
        let title=try XCTUnwrap(project.nodes.firstIndex{$0.kind=="TEXT"})
        project.nodes[title].text="Другой заголовок"
        XCTAssertNotNil(renderer.png(project,scale:1))
        XCTAssertEqual(renderer.backdropRenderCount,renders)
        XCTAssertGreaterThan(renderer.backdropCacheHits,0)
        project.nodes[0].fill = -16711936
        XCTAssertNotNil(renderer.png(project,scale:1))
        XCTAssertGreaterThan(renderer.backdropRenderCount,renders)
        _ = store
    }
    @MainActor func testDialogButtonsRespondIndependently() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:root)}
        let store=ProjectStore(root:root)
        let p=AppleCatalog.variant(try XCTUnwrap(Catalog.shared.components.first{$0.id=="ios-alert"}),dark:false).project
        let ok=try XCTUnwrap(p.nodes.first{$0.kind=="RECT" && $0.name=="ОК"})
        let cancel=try XCTUnwrap(p.nodes.first{$0.kind=="RECT" && $0.name=="Отмена"})
        let runtime=InteractionRuntime();runtime.start(p)
        runtime.fire("press",sourceID:ok.id);runtime.tick(at:CACurrentMediaTime()+1)
        let shown=runtime.displayed(p)
        XCTAssertLessThan(try XCTUnwrap(shown.nodes.first{$0.id==ok.id}).w,ok.w)
        XCTAssertEqual(try XCTUnwrap(shown.nodes.first{$0.id==cancel.id}),cancel)
        let restored=try JSONDecoder().decode(Project.self,from:JSONEncoder().encode(p))
        XCTAssertTrue(restored.links.filter{$0.sourceID==ok.id}.allSatisfy{$0.exactSource==true})
        _ = store
    }
    @MainActor func testSystemSymbolsSurviveProjectAndSourceExports() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:root)}
        let store=ProjectStore(root:root)
        let project=AppleCatalog.variant(try XCTUnwrap(Catalog.shared.components.first{$0.id=="ios-tab-bar"}),dark:false).project
        let symbols=project.nodes.filter{$0.asset.hasPrefix("sf:")}
        XCTAssertEqual(symbols.count,4)
        for node in symbols{XCTAssertNotNil(DocumentRenderer.symbolImage(node),node.asset)}
        let imported=try JSONDecoder().decode(Project.self,from:JSONEncoder().encode(project))
        XCTAssertEqual(imported.nodes.map(\.asset),project.nodes.map(\.asset))
        let code=SwiftExport.make(project,root:root)
        XCTAssertTrue(code.contains("Image(systemName: \"house.fill\")"))
        XCTAssertTrue(code.contains("Image(systemName: \"magnifyingglass\")"))
        let archive=try OriginalCore.shared.sourceArchive(project,root:root,kind:"codeassist")
        XCTAssertTrue(FileManager.default.fileExists(atPath:archive.path))
        _ = store
    }
    @MainActor func testGlassOpticsKernelCompilesAndRenders() throws {
        XCTAssertNotNil(LiquidGlassRenderer.kernel)
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:root)}
        let store=ProjectStore(root:root),renderer=DocumentRenderer(root:root)
        var p=AppleCatalog.variant(try XCTUnwrap(Catalog.shared.components.first{$0.id=="ios-btn-glass"}),dark:false).project
        var background=Node();background.w=p.w;background.h=p.h;background.fill = 0xffee77aa;background.fill2 = 0xff4499ee;background.gradKind=1
        p.nodes.insert(background,at:0);p.glassMode=1
        XCTAssertNotNil(renderer.png(p,scale:2))
        XCTAssertGreaterThan(renderer.backdropRenderCount,0)
        _ = store
    }
    @MainActor func testNativeShowcaseFixtures() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:root)}
        let store=ProjectStore(root:root),renderer=DocumentRenderer(root:root)
        for dark in [false,true]{
            var p=Project();p.w=430;p.h=910;p.bg=dark ? 0xff11131a:0xffedf1f7
            var title=Node();title.kind="TEXT";title.text="iOS · Liquid Glass";title.x=24;title.y=28;title.w=382;title.h=36;title.fontSize=26;title.weight=700;title.fill=dark ? 0xffffffff:0xff13141a;p.nodes.append(title)
            var backdrop=Node();backdrop.x=20;backdrop.y=95;backdrop.w=390;backdrop.h=174;backdrop.corner=30;backdrop.gradKind=1;backdrop.gradAngle=25;backdrop.fill=dark ? 0xff653b9c:0xffb6a0ef;backdrop.fill2=dark ? 0xff184673:0xff83c2ec;p.nodes.append(backdrop)
            let samples:[(String,CGFloat,CGFloat)]=[("ios-btn-glass",36,124),("ios-switch-on",300,136),("ios-slider",49,204),("ios-alert",65,295),("ios-segmented",75,533),("ios-search",43.5,602),("ios-list-switch",43.5,678),("ios-tab-bar",36,798)]
            for (id,x,y) in samples{
                let item=AppleCatalog.variant(try XCTUnwrap(Catalog.shared.components.first{$0.id==id}),dark:dark)
                p.nodes += item.project.nodes.map{node in var n=node;n.id="fixture-"+id+"-"+node.id;n.x+=x;n.y+=y;n.group="fixture~"+id;return n}
            }
            let data=try XCTUnwrap(renderer.png(p,scale:2))
            let documents=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0]
            try data.write(to:documents.appendingPathComponent(dark ? "QwelNativeDark.png":"QwelNativeLight.png"))
        }
        _ = store
    }
    func testThumbnailBackdropUsesThumbnailResolution() {
        var project=Project();project.w=390;project.h=844
        XCTAssertEqual(DocumentRenderer.backdropScale(project,transform:CGAffineTransform(scaleX:0.25,y:0.25)),0.25)
        XCTAssertEqual(DocumentRenderer.backdropScale(project,transform:CGAffineTransform(scaleX:3,y:3)),2)
    }
}
