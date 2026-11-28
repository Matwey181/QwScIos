import XCTest
import UIKit
import AVFoundation
@testable import QwelIos

final class MotionUpdateTests:XCTestCase {
    func testRecoveredCatalogAndCurveEndpoints()throws{
        let catalog=MotionPresetCatalog.shared
        XCTAssertEqual(catalog.templates.count,63);XCTAssertEqual(catalog.curves.count,45)
        for curve in catalog.curves{
            XCTAssertEqual(MotionCurve.at(curve.curve,0),0);XCTAssertEqual(MotionCurve.at(curve.curve,1),1)
            for i in 0...100{XCTAssertTrue(MotionCurve.at(curve.curve,Double(i)/100).isFinite)}
        }
        XCTAssertGreaterThan(MotionCurve.at("sp:300,0.35",0.2),1)
        XCTAssertEqual(MotionCurve.at("st:4,1",0.49),0.25)
    }
    @MainActor func testAndroidMotionFormatAndRelativeTransforms()throws{
        let json=Data(#"{"tracks":[{"id":"t","group":false,"ref":"n","prop":"x","keys":[{"t":0,"v":0,"e":"lin"},{"t":1000,"v":100,"e":"lin"}]}],"dur":1000,"loop":false}"#.utf8)
        let motion=try JSONDecoder().decode(MotionData.self,from:json)
        var p=Project(),n=Node();n.id="n";n.x=10;n.y=20;n.w=80;n.h=40;p.nodes=[n];p.motion=motion
        let at500=MotionEvaluator.frame(p,time:500)
        XCTAssertEqual(at500.nodes[0].x,60,accuracy:0.001);XCTAssertEqual(p.nodes[0].x,10)
        XCTAssertEqual(try JSONDecoder().decode(MotionData.self,from:JSONEncoder().encode(motion)),motion)
        var group=MotionTrack(group:true,ref:"g",prop:"sc");group.keys=[MotionKey(t:0,v:2)]
        p.nodes[0].group="g";p.motion?.tracks.append(group)
        XCTAssertEqual(MotionEvaluator.frame(p,time:0).nodes[0].w,160,accuracy:0.001)
    }
    @MainActor func testNewFieldsSurviveSharedEngineAndProjectArchive()throws{
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:root)}
        let store=ProjectStore(root:root)
        var p=Project(),n=Node();n.cornerRadii=[0,8,16,24];n.liquidDepth=1.7;n.liquidPower=2.3;n.liquidHighlight=0.2;n.liquidHighlightWidth=2;n.appear=7;n.outer="parent";p.nodes=[n];p.motion=MotionData()
        _=try OriginalCore.shared.request(["op":"set"],project:p)
        let output=try OriginalCore.shared.project("apply",values:["shown":[:]])
        XCTAssertEqual(output.nodes[0].cornerRadii,n.cornerRadii);XCTAssertEqual(output.nodes[0].liquidPower,n.liquidPower);XCTAssertEqual(output.nodes[0].appear,7);XCTAssertEqual(output.motion,p.motion)
        try store.save(output);store.reload();XCTAssertEqual(store.projects.first?.nodes.first?.outer,"parent")
        XCTAssertEqual(Set(AppleCatalog.bundle.templates.map(\.id)).intersection(["ios-settings","ios-controls","ios-dialog","ios-home","ios-sheet"]).count,5)
        for id in ["ios26-alert","ios26-menu"]{let item=try XCTUnwrap(Catalog.shared.components.first{$0.id==id});XCTAssertFalse(AppleCatalog.variant(item,dark:false).project.nodes.isEmpty)}
    }
    @MainActor func testVideoProducesDecodableMP4()async throws{
        var p=Project();p.w=64;p.h=64;var n=Node();n.w=32;n.h=32;n.fill=0xffff0000;p.nodes=[n]
        let writer=try CanvasVideoWriter(project:p,longEdge:64,fps:30),renderer=DocumentRenderer(root:FileManager.default.temporaryDirectory)
        for i in 0..<6{try await writer.waitUntilReady();try writer.append(p,renderer:renderer,time:CMTime(value:Int64(i),timescale:30))}
        let url=try await writer.finish();defer{try? FileManager.default.removeItem(at:url)}
        let asset=AVURLAsset(url:url);let tracks=try await asset.loadTracks(withMediaType:.video)
        let duration=try await asset.load(.duration)
        XCTAssertEqual(tracks.count,1);XCTAssertGreaterThan(duration.seconds,0)
    }
}
