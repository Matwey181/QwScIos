import Foundation
import CoreGraphics

struct TextRun:Codable,Equatable,Identifiable {
    var id=UUID().uuidString
    var start:Int
    var length:Int
    var weight:Int=400
    var italic=false
    var color:Int64?=nil
}
struct LayerExtras:Codable,Equatable {
    var appleTextPrepared:Bool?
    var templatePlayerVersion:Int?
    var linkDefaultsVersion:Int?
    var fillOpacity:CGFloat?
    var disabled:Bool?
    var hugWidth:Bool?=nil
    var hugHeight:Bool?=nil
    var anchorX:String?=nil
    var anchorY:String?=nil
    var reference:Bool?=nil
    var colorStyleID:String?=nil
    var textStyleID:String?=nil
    var tracking:CGFloat=0
    var lineSpacing:CGFloat=0
    var autoFit=false
    var runs:[TextRun]=[]
    var imageMode="stretch"
    var cropX:CGFloat=0.5
    var cropY:CGFloat=0.5
    var imageZoom:CGFloat=1
    var definitionID:String?=nil
    var instanceID:String?=nil
    var sourceLayerID:String?=nil
}
struct VisualState:Codable,Equatable,Identifiable {
    var id=UUID().uuidString
    var name:String
    var nodes:[Node]
    var pageID:String=""
}
struct StudioDocument:Codable,Equatable {
    var layouts:[AutoLayoutFrame]?=nil
    var colorStyles:[ProjectColorStyle]?=nil
    var textStyles:[ProjectTextStyle]?=nil
    var states:[VisualState]=[]
    var guidesX:[CGFloat]=[]
    var guidesY:[CGFloat]=[]
    var gridSnap=false
    var gridSize:CGFloat=8
    var spacingSnap=true
    var showSafeArea:Bool?
    var safeTop:CGFloat?
    var safeBottom:CGFloat?
    var smartPlacement:Bool?
    var smartGap:CGFloat?
}
struct ReusableComponent:Codable,Identifiable,Equatable {
    var id=UUID().uuidString
    var name:String
    var project:Project
}
struct ProjectRevision:Identifiable {
    var id:String
    var date:Date
    var label:String
}
