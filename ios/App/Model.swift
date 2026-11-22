import SwiftUI
import UIKit

struct Node: Codable, Identifiable, Equatable {
    var extras:LayerExtras?
    var id: String = UUID().uuidString
    var kind: String = "RECT"
    var name: String = "Слой"
    var x: CGFloat = 0
    var y: CGFloat = 0
    var w: CGFloat = 100
    var h: CGFloat = 100
    var rotation: CGFloat = 0
    var strokeWidth: CGFloat = 0
    var opacity: CGFloat = 1
    var corner: CGFloat = 0
    var fontSize: CGFloat = 16
    var blur: CGFloat = 0
    var softBlur: CGFloat = 0
    var pressCorner: CGFloat = -1
    var gradAngle: CGFloat = 90
    var shadowBlur: CGFloat = 0
    var shadowDx: CGFloat = 0
    var shadowDy: CGFloat = 4
    var fill: Int64 = -16749974
    var stroke: Int64 = 0
    var weight: Int64 = 400
    var fillToken: Int64 = -1
    var strokeToken: Int64 = -1
    var gradKind: Int64 = 0
    var fill2: Int64 = -16777216
    var shadowColor: Int64 = 1493172224
    var visible: Bool = true
    var locked: Bool = false
    var ratioLock: Bool = false
    var evenOdd: Bool = false
    var mask: Bool = false
    var shapeId: String = ""
    var text: String = ""
    var textAlign: String = "left"
    var group: String = ""
    var path: String = ""
    var asset: String = ""
    var font: String = ""
    var widget: String = ""
    var action: String = ""
    var fillOpacity:CGFloat {get{min(1,max(0,extras?.fillOpacity ?? 1))}set{var x=extras ?? LayerExtras();x.fillOpacity=min(1,max(0,newValue));extras=x}}
    init() {}
    enum CodingKeys: String, CodingKey {
        case extras = "ux"
        case id = "id"
        case kind = "kind"
        case name = "name"
        case x = "x"
        case y = "y"
        case w = "w"
        case h = "h"
        case rotation = "rot"
        case strokeWidth = "sw"
        case opacity = "op"
        case corner = "corner"
        case fontSize = "fs"
        case blur = "blur"
        case softBlur = "sb"
        case pressCorner = "pc"
        case gradAngle = "ga"
        case shadowBlur = "shb"
        case shadowDx = "shx"
        case shadowDy = "shy"
        case fill = "fill"
        case stroke = "stroke"
        case weight = "fw"
        case fillToken = "ft"
        case strokeToken = "st"
        case gradKind = "gk"
        case fill2 = "f2"
        case shadowColor = "shc"
        case visible = "vis"
        case locked = "lock"
        case ratioLock = "ratio"
        case evenOdd = "eo"
        case mask = "mask"
        case shapeId = "shape"
        case text = "text"
        case textAlign = "ta"
        case group = "group"
        case path = "path"
        case asset = "asset"
        case font = "font"
        case widget = "wd"
        case action = "ac"
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        extras = try c.decodeIfPresent(LayerExtras.self,forKey:.extras)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        kind = try c.decodeIfPresent(String.self, forKey: .kind) ?? "RECT"
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Слой"
        x = try c.decodeIfPresent(CGFloat.self, forKey: .x) ?? 0
        y = try c.decodeIfPresent(CGFloat.self, forKey: .y) ?? 0
        w = try c.decodeIfPresent(CGFloat.self, forKey: .w) ?? 100
        h = try c.decodeIfPresent(CGFloat.self, forKey: .h) ?? 100
        rotation = try c.decodeIfPresent(CGFloat.self, forKey: .rotation) ?? 0
        strokeWidth = try c.decodeIfPresent(CGFloat.self, forKey: .strokeWidth) ?? 0
        opacity = try c.decodeIfPresent(CGFloat.self, forKey: .opacity) ?? 1
        corner = try c.decodeIfPresent(CGFloat.self, forKey: .corner) ?? 0
        fontSize = try c.decodeIfPresent(CGFloat.self, forKey: .fontSize) ?? 16
        blur = try c.decodeIfPresent(CGFloat.self, forKey: .blur) ?? 0
        softBlur = try c.decodeIfPresent(CGFloat.self, forKey: .softBlur) ?? 0
        pressCorner = try c.decodeIfPresent(CGFloat.self, forKey: .pressCorner) ?? -1
        gradAngle = try c.decodeIfPresent(CGFloat.self, forKey: .gradAngle) ?? 90
        shadowBlur = try c.decodeIfPresent(CGFloat.self, forKey: .shadowBlur) ?? 0
        shadowDx = try c.decodeIfPresent(CGFloat.self, forKey: .shadowDx) ?? 0
        shadowDy = try c.decodeIfPresent(CGFloat.self, forKey: .shadowDy) ?? 4
        fill = try c.decodeIfPresent(Int64.self, forKey: .fill) ?? -16749974
        stroke = try c.decodeIfPresent(Int64.self, forKey: .stroke) ?? 0
        weight = try c.decodeIfPresent(Int64.self, forKey: .weight) ?? 400
        fillToken = try c.decodeIfPresent(Int64.self, forKey: .fillToken) ?? -1
        strokeToken = try c.decodeIfPresent(Int64.self, forKey: .strokeToken) ?? -1
        gradKind = try c.decodeIfPresent(Int64.self, forKey: .gradKind) ?? 0
        fill2 = try c.decodeIfPresent(Int64.self, forKey: .fill2) ?? -16777216
        shadowColor = try c.decodeIfPresent(Int64.self, forKey: .shadowColor) ?? 1493172224
        visible = try c.decodeIfPresent(Bool.self, forKey: .visible) ?? true
        locked = try c.decodeIfPresent(Bool.self, forKey: .locked) ?? false
        ratioLock = try c.decodeIfPresent(Bool.self, forKey: .ratioLock) ?? false
        evenOdd = try c.decodeIfPresent(Bool.self, forKey: .evenOdd) ?? false
        mask = try c.decodeIfPresent(Bool.self, forKey: .mask) ?? false
        shapeId = try c.decodeIfPresent(String.self, forKey: .shapeId) ?? ""
        text = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
        textAlign = try c.decodeIfPresent(String.self, forKey: .textAlign) ?? "left"
        group = try c.decodeIfPresent(String.self, forKey: .group) ?? ""
        path = try c.decodeIfPresent(String.self, forKey: .path) ?? ""
        asset = try c.decodeIfPresent(String.self, forKey: .asset) ?? ""
        font = try c.decodeIfPresent(String.self, forKey: .font) ?? ""
        widget = try c.decodeIfPresent(String.self, forKey: .widget) ?? ""
        action = try c.decodeIfPresent(String.self, forKey: .action) ?? ""
    }
    var center: CGPoint { CGPoint(x:x+w/2, y:y+h/2) }
    var rect: CGRect { CGRect(x:x,y:y,width:w,height:h) }
    func contains(_ p: CGPoint) -> Bool {
        let a = -rotation * .pi / 180, dx = p.x-center.x, dy = p.y-center.y
        return abs(dx*cos(a)-dy*sin(a)) <= w/2 && abs(dx*sin(a)+dy*cos(a)) <= h/2
    }
}

struct Tone: Codable, Equatable {
    var mode = 0
    var seed: Int64 = -16749974
    var dark = false
    var colors: [Int64] = []
}
struct Page: Codable, Identifiable, Equatable {
    var id = UUID().uuidString
    var name = "Экран"
    var nodes: [Node] = []
}
struct Project: Codable, Identifiable, Equatable {
    var v = 1
    var id = UUID().uuidString
    var name = "Новый проект"
    var w: CGFloat = 390
    var h: CGFloat = 844
    var bg: Int64 = -1
    var created: Int64 = Int64(Date().timeIntervalSince1970*1000)
    var updated: Int64 = Int64(Date().timeIntervalSince1970*1000)
    var nodes: [Node] = []
    var tone = Tone()
    var bgToken = -1
    var pages: [Page] = []
    var active = 0
    var studio:StudioDocument?
    var links: [InteractionLink] = []
    enum CodingKeys: String, CodingKey { case v,id,name,w,h,bg,created,updated,nodes,tone,bgToken,pages,active,links,studio }
    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy:CodingKeys.self)
        id = try c.decode(String.self,forKey:.id)
        name = try c.decodeIfPresent(String.self,forKey:.name) ?? "Проект"
        w = try c.decode(CGFloat.self,forKey:.w); h = try c.decode(CGFloat.self,forKey:.h)
        guard w.isFinite && h.isFinite && w > 0 && h > 0 && w <= 16384 && h <= 16384 else { throw CocoaError(.fileReadCorruptFile) }
        bg = try c.decodeIfPresent(Int64.self,forKey:.bg) ?? -1
        created = try c.decodeIfPresent(Int64.self,forKey:.created) ?? created
        updated = try c.decodeIfPresent(Int64.self,forKey:.updated) ?? updated
        nodes = try c.decode([Node].self,forKey:.nodes)
        tone = try c.decodeIfPresent(Tone.self,forKey:.tone) ?? Tone()
        bgToken = try c.decodeIfPresent(Int.self,forKey:.bgToken) ?? -1
        pages = try c.decodeIfPresent([Page].self,forKey:.pages) ?? []
        studio = try c.decodeIfPresent(StudioDocument.self,forKey:.studio)
        links = try c.decodeIfPresent([InteractionLink].self,forKey:.links) ?? []
        active = min(max(0,try c.decodeIfPresent(Int.self,forKey:.active) ?? 0),max(0,pages.count-1))
        let all = nodes + pages.flatMap(\.nodes)
        guard links.count <= 2000, all.count <= 10000, all.allSatisfy({ n in [n.x,n.y,n.w,n.h,n.rotation,n.opacity,n.fontSize].allSatisfy(\.isFinite) && n.w >= 0 && n.h >= 0 }) else { throw CocoaError(.fileReadCorruptFile) }
    }
    mutating func syncPage() { if pages.indices.contains(active) { pages[active].nodes = nodes } }
}
struct CatalogItem: Decodable, Identifiable {
    var id: String
    var name: String
    var category: String
    var project: Project
}
struct ShapeItem: Decodable, Identifiable {
    var id: String
    var name: String
    var category: String
    var path: String
}
struct Catalog: Decodable {
    var components: [CatalogItem]
    var templates: [CatalogItem]
    var shapes: [ShapeItem]
    static let shared: Catalog = {
        guard let url = Bundle.main.url(forResource:"catalog",withExtension:"json"),
              let data = try? Data(contentsOf:url), let result = try? JSONDecoder().decode(Catalog.self,from:data) else { fatalError("Missing Qwel catalog") }
        return result
    }()
}
extension UIColor {
    convenience init(argb: Int64) {
        let c = UInt32(truncatingIfNeeded:argb)
        self.init(red:CGFloat((c>>16)&255)/255,green:CGFloat((c>>8)&255)/255,blue:CGFloat(c&255)/255,alpha:CGFloat((c>>24)&255)/255)
    }
    var argb: Int64 {
        var r: CGFloat=0,g: CGFloat=0,b: CGFloat=0,a: CGFloat=0
        getRed(&r,green:&g,blue:&b,alpha:&a)
        return Int64(Int32(bitPattern:UInt32(a*255)<<24 | UInt32(r*255)<<16 | UInt32(g*255)<<8 | UInt32(b*255)))
    }
}
extension Color { init(argb:Int64) { self.init(uiColor:UIColor(argb:argb)) } }
