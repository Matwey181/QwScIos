import Foundation

// Isolated classic build. Keep saved links for returning to the main build.
enum DefaultLinks {
    static func install(_ project:inout Project,componentID:String?=nil){
        let savedLinks=project.links
        func restore(_ nodes:inout [Node]){
            for i in nodes.indices{
                let id=nodes[i].id
                if nodes[i].pressCorner<0,let press=savedLinks.first(where:{$0.targetID==id && $0.event=="press" && $0.property=="corner"}){nodes[i].pressCorner=CGFloat(press.value)}
                if nodes[i].action.isEmpty,let action=savedLinks.first(where:{$0.sourceID==id && $0.id.hasPrefix("default-") && $0.property=="action"}){
                    if action.mode=="navigate"{nodes[i].action=action.destination=="back" ? "back":"goto:"+(action.destination ?? "")}
                    if action.mode=="visibility"{nodes[i].action="toggle:"+action.targetID}
                    if action.mode=="url"{nodes[i].action="url:"+(action.destination ?? "")}
                }
            }
        }
        var nodes=project.nodes;restore(&nodes);project.nodes=nodes
        for i in project.pages.indices{var page=project.pages[i].nodes;restore(&page);project.pages[i].nodes=page}
    }
    static func allPages(_ project:inout Project){install(&project);project.syncPage()}
}
@MainActor extension Editor {
    func links(for source:Node)->[InteractionLink]{[]}
}
