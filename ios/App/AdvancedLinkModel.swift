import Foundation
import CoreGraphics

struct SliderCheckpoint:Codable,Equatable,Identifiable {
    var id=UUID().uuidString
    var percent:Double=25
    var shapeID="star-8"
    var actions:[InteractionLink]?
    var revertOnRewind:Bool?
}
struct AdvancedLinkOptions:Codable,Equatable {
    var once=false
    var repeatGap:Double=0
    var holdInterval:Double=0.15
    var tapCount:Int=2
    var tapStep:Int=1
    var axis="both"
    var areaID=""
    var otherID=""
    var sourceIDs:[String]=[]
    var targetIDs:[String]=[]
    var asset=""
    var icon="Play"
    var maxLength:Int=100
    var validation="email"
    var format="number"
    var decimals:Int=0
    var prefix=""
    var suffix=""
    var padding:Double=0
    var stopID=""
    var checkpoints:[SliderCheckpoint]=[]
    var showMarkers=false
    var showMarkerBar=true
    var showMarkerShape=true
    var markerColor:Int64 = -16749974
    var markerScale:Double=1
    var markerWidth:Double=3
    var markerHeight:Double=38
    var markerShapeSize:Double=28
}

extension InteractionLink {
    func actions(at point:SliderCheckpoint)->[InteractionLink]{
        if let actions=point.actions{return actions}
        var action=InteractionLink()
        action.id=point.id+"-shape";action.sourceID=sourceID;action.targetID=targetID
        action.mode="animate";action.property="morph";action.shapeID=point.shapeID
        action.duration=duration;action.easing=easing
        return [action]
    }
}
