import Foundation

// Only repair known placeholders from older bundled templates. Genuine circles stay circles.
enum IconRepair {
    struct Glyph:Decodable {var path:String;var name:String}
    private static let glyphs:[String:Glyph] = {
        guard let url=Bundle.main.url(forResource:"icon-repairs",withExtension:"json"),let data=try? Data(contentsOf:url) else{return [:]}
        return (try? JSONDecoder().decode([String:Glyph].self,from:data)) ?? [:]
    }()
    static func apply(_ node:inout Node){
        guard node.kind=="ELLIPSE",node.name=="icon",let glyph=glyphs[node.id] else{return}
        let center=node.center
        node.kind="PATH";node.name=glyph.name;node.path=glyph.path
        node.w/=0.75;node.h/=0.75;node.x=center.x-node.w/2;node.y=center.y-node.h/2
        node.ratioLock=true
    }
}
