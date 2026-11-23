import Foundation
import CoreGraphics

struct SliderCheckpoint:Codable,Equatable,Identifiable {
    var id=UUID().uuidString
    var percent:Double=25
    var shapeID="star-8"
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
