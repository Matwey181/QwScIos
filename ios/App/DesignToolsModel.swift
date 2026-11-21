import Foundation
import CoreGraphics

struct AutoLayoutFrame:Codable,Equatable,Identifiable {
    var id=UUID().uuidString
    var name="Раскладка"
    var children:[String]
    var backgroundID:String?=nil
    var groupItems:Bool?=nil
    var axis="horizontal"
    var alignment="center"
    var gap:CGFloat=12
    var padding:CGFloat=16
    var x:CGFloat
    var y:CGFloat
    var width:CGFloat
    var height:CGFloat
    var widthMode="hug"
    var heightMode="hug"
    var rightInset:CGFloat=0
    var enabled=true
}
struct ProjectColorStyle:Codable,Equatable,Identifiable {
    var id=UUID().uuidString
    var name:String
    var light:Int64
    var dark:Int64
}
struct ProjectTextStyle:Codable,Equatable,Identifiable {
    var id=UUID().uuidString
    var name:String
    var font:String
    var size:CGFloat
    var weight:Int64
    var alignment:String
    var tracking:CGFloat
    var lineSpacing:CGFloat
}
