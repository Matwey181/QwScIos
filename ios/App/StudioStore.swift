import Foundation

@MainActor extension ProjectStore {
    func reloadComponents(){components=(try? JSONDecoder().decode([ReusableComponent].self,from:Data(contentsOf:root.appendingPathComponent("components.json")))) ?? []}
    func saveComponent(_ component:ReusableComponent) throws {
        if let i=components.firstIndex(where:{$0.id==component.id}){components[i]=component}else{components.append(component)}
        try JSONEncoder().encode(components).write(to:root.appendingPathComponent("components.json"),options:.atomic)
    }
    func deleteComponent(_ id:String) throws {components.removeAll{$0.id==id};try JSONEncoder().encode(components).write(to:root.appendingPathComponent("components.json"),options:.atomic)}
    func revisions(_ id:String)->[ProjectRevision] {
        let folder=root.appendingPathComponent("revisions").appendingPathComponent(id)
        return ((try? FileManager.default.contentsOfDirectory(at:folder,includingPropertiesForKeys:[.creationDateKey])) ?? []).filter{$0.pathExtension=="json"}.map{url in
            let name=url.deletingPathExtension().lastPathComponent
            let bits=name.split(separator:"-",maxSplits:1)
            let date=Date(timeIntervalSince1970:(Double(bits.first ?? "0") ?? 0)/1000)
            return ProjectRevision(id:url.lastPathComponent,date:date,label:bits.count>1 ? String(bits[1]):"Версия")
        }.sorted{$0.date>$1.date}
    }
    func checkpoint(_ project:Project,label:String) throws {
        let folder=root.appendingPathComponent("revisions").appendingPathComponent(project.id)
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        let stamp=String(Int64(Date().timeIntervalSince1970*1000))
        var value=project;value.syncPage()
        try JSONEncoder().encode(value).write(to:folder.appendingPathComponent(stamp+"-"+safeName(label)+".json"),options:.atomic)
        for old in revisions(project.id).dropFirst(50){try? FileManager.default.removeItem(at:folder.appendingPathComponent(old.id))}
    }
    func readRevision(_ revision:ProjectRevision,projectID:String) throws ->Project {
        try JSONDecoder().decode(Project.self,from:Data(contentsOf:root.appendingPathComponent("revisions").appendingPathComponent(projectID).appendingPathComponent(revision.id)))
    }
}
