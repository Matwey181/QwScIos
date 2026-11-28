import Foundation
import CoreGraphics

enum AppleUpdateCatalog {
    // Component positions and template sizes recovered from Templates.kt in 2.9.2.
    static func extend(_ original:AppleCatalogBundle)->AppleCatalogBundle{
        var bundle=original
        for dark in [false,true]{
            for (id,name,w,h) in [("ios26-alert","iOS 26 · Alert",300,306),("ios26-menu","iOS 26 · Context Menu",250,612)]{
                var p=Project();p.w=CGFloat(w);p.h=CGFloat(h);p.tone.dark=dark
                let item=AppleNativeStyle.make(CatalogItem(id:id,name:name,category:"apple",project:p))
                if dark{bundle.dark.insert(item,at:0)}else{bundle.light.insert(item,at:0)}
            }
        }
        let layouts:[(String,[(String,CGFloat,CGFloat)])]=[
            ("ios-settings",[("ios-search",16,170),("ios-section-header",23.5,224),("ios-list-group",23.5,252),("ios-list-switch",23.5,430),("ios-list-switch",23.5,490),("ios-section-footer",23.5,552),("ios-tab-bar",15,748),("ios-nav-large",7.5,0)]),
            ("ios-controls",[("ios-segmented",55,180),("ios-slider",45,240),("ios-btn-filled",95,300),("ios-btn-tinted",95,370),("ios-btn-glass",95,440),("ios-btn-plain",135,510),("ios-switch-on",163,580),("ios-switch-off",163,630),("ios-tab-bar",15,748),("ios-nav-large",7.5,0)]),
            ("ios-dialog",[("ios-card-stat",23.5,130),("ios-list-group",23.5,270),("ios-list-switch",23.5,450),("ios-tab-bar",15,748),("ios-nav-large",7.5,0),("ios26-alert",45,270)]),
            ("ios-home",[("ios-widget",24,90),("ios-widget",208,90),("ios-card-stat",23.5,270),("ios-app-icon",30,420),("ios-app-icon",120,420),("ios-app-icon",210,420),("ios-app-icon",300,420),("ios-app-icon",30,520),("ios-app-icon",120,520),("ios-app-icon",210,520),("ios-app-icon",300,520),("ios-tab-bar",15,748)]),
            ("ios-sheet",[("ios-list-group",23.5,170),("ios-card-stat",23.5,350),("ios-nav-large",7.5,0),("ios-sheet",0,544),("ios-btn-glass-icon",322,560)])]
        for dark in [false,true]{
            let source=dark ? bundle.dark:bundle.light
            for (id,positions) in layouts{
                var p=Project();p.w=390;p.h=844;p.tone.dark=dark;p.bg=dark ? 0xff000000:0xfff2f2f7
                for (index,position) in positions.enumerated(){
                    guard let raw=source.first(where:{$0.id==position.0})else{continue}
                    let item=AppleNativeStyle.make(raw),group="\(id)-\(index)~\(position.0)"
                    let ids=Dictionary(item.project.nodes.map{($0.id,"\(group)-\($0.id)")},uniquingKeysWith:{_,b in b})
                    p.nodes+=item.project.nodes.map{node in var n=node;n.id=ids[n.id] ?? n.id;n.x+=position.1;n.y+=position.2;n.group=group;return n}
                    p.links+=item.project.links.map{link in var r=link;r.id=group+"-"+r.id;r.sourceID=ids[r.sourceID] ?? r.sourceID;r.targetID=ids[r.targetID] ?? r.targetID;return r}
                }
                let key="tpl_"+id.replacingOccurrences(of:"-",with:"_")
                p.name=tr(key);bundle.templates.append(CatalogItem(id:id,name:p.name,category:"iOS",project:p))
            }
        }
        return bundle
    }
}
