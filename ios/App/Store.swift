import SwiftUI
import ZIPFoundation
import CoreText

@MainActor final class ProjectStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var components:[ReusableComponent]=[]
    @Published var error: String?
    @Published var working = false
    let root: URL
    var assets: URL { root.appendingPathComponent("assets") }
    var fonts: URL { root.appendingPathComponent("fonts") }
    init(root:URL?=nil) {
        self.root = root ?? FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0]
        for folder in [self.root,self.root.appendingPathComponent("projects"),assets,fonts] { try? FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true) }
        registerFonts()
        reload();reloadComponents()
    }
    func registerFonts() {
        let custom=(try? FileManager.default.contentsOfDirectory(at:fonts,includingPropertiesForKeys:nil)) ?? []
        let bundled=(Bundle.main.urls(forResourcesWithExtension:"ttf",subdirectory:nil) ?? [])+(Bundle.main.urls(forResourcesWithExtension:"otf",subdirectory:nil) ?? [])
        for u in bundled {let copy=fonts.appendingPathComponent(u.lastPathComponent);if !FileManager.default.fileExists(atPath:copy.path){try? FileManager.default.copyItem(at:u,to:copy)}}
        for u in custom+bundled { CTFontManagerRegisterFontsForURL(u as CFURL,.process,nil) }
    }
    func reload() {
        let folder=root.appendingPathComponent("projects")
        projects=((try? FileManager.default.contentsOfDirectory(at:folder,includingPropertiesForKeys:nil)) ?? []).filter { $0.pathExtension=="json" }.compactMap { u in
            if let d=try? Data(contentsOf:u),var project=try? JSONDecoder().decode(Project.self,from:d){DefaultLinks.allPages(&project);return project}
            for revision in self.revisions(u.deletingPathExtension().lastPathComponent){if let project=try? self.readRevision(revision,projectID:u.deletingPathExtension().lastPathComponent){return project}}
            return nil
        }.sorted { $0.updated > $1.updated }
    }
    func save(_ value:Project) throws {
        var p=value; p.syncPage(); p.updated=Int64(Date().timeIntervalSince1970*1000)
        let d=try JSONEncoder().encode(p)
        let destination=root.appendingPathComponent("projects/\(p.id).json")
        if let old=try? Data(contentsOf:destination),old != d {
            let latest=revisions(p.id).first?.date ?? .distantPast
            if Date().timeIntervalSince(latest)>60,let previous=try? JSONDecoder().decode(Project.self,from:old){try checkpoint(previous,label:"Автосохранение")}
        }
        try d.write(to:destination,options:.atomic)
        if let i=projects.firstIndex(where:{$0.id==p.id}) { projects[i]=p } else { projects.insert(p,at:0) }
    }
    func delete(_ p:Project) {
        do { try FileManager.default.removeItem(at:root.appendingPathComponent("projects/\(p.id).json")); projects.removeAll { $0.id==p.id } }
        catch { self.error=error.localizedDescription }
    }
    func duplicate(_ value:Project) {
        var p=value; p.id=UUID().uuidString;p.name += " — копия"
        do { try save(p) } catch { self.error=error.localizedDescription }
    }
    func create(name:String,width:CGFloat,height:CGFloat,template:Project?=nil) throws -> Project {
        var p=template ?? Project();p.id=UUID().uuidString;p.name=name.isEmpty ? "Новый проект" : name
        if template==nil { p.w=width;p.h=height }
        try save(p);return p
    }
    func importFile(_ url:URL) async {
        guard !working else { return };working=true
        defer { working=false }
        do {
            let root=self.root
            let p=try await Task.detached(priority:.userInitiated) { () throws -> Project in
                let access=url.startAccessingSecurityScopedResource();defer { if access { url.stopAccessingSecurityScopedResource() } }
                let temp=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                try FileManager.default.createDirectory(at:temp,withIntermediateDirectories:true)
                defer { try? FileManager.default.removeItem(at:temp) }
                // Coordinate File Provider/iCloud reads and keep a local copy while parsing.
                let local=temp.appendingPathComponent("input-project")
                var coordinationError:NSError?,copyError:Error?
                NSFileCoordinator().coordinate(readingItemAt:url,options:[],error:&coordinationError){readable in
                    do{try FileManager.default.copyItem(at:readable,to:local)}catch{copyError=error}
                }
                if let error=coordinationError{throw error};if let error=copyError{throw error}
                let data=try Data(contentsOf:local,options:.mappedIfSafe)
                if let project=try? JSONDecoder().decode(Project.self,from:data){return project}
                let archive=try Archive(url:local,accessMode:.read)
                let candidates=archive.filter{entry in entry.type == .file && URL(fileURLWithPath:entry.path).lastPathComponent.lowercased()=="project.json"}
                guard let manifest=candidates.min(by:{$0.path.count<$1.path.count}) else{throw CocoaError(.fileReadCorruptFile)}
                let prefix=String(manifest.path.dropLast("project.json".count))
                var total:UInt64=0
                for entry in archive where entry.type == .file && entry.path.hasPrefix(prefix){
                    total += UInt64(entry.uncompressedSize)
                    guard total <= 150*1024*1024 else{throw CocoaError(.fileReadTooLarge)}
                    let relative=entry.path==manifest.path ? "project.json":String(entry.path.dropFirst(prefix.count))
                    let bits=relative.split(separator:"/",omittingEmptySubsequences:false)
                    guard relative=="project.json" || (bits.count==2 && ["assets","fonts"].contains(String(bits[0])) && !["",".",".."].contains(String(bits[1])) && !relative.contains("\\")) else{continue}
                    let target=temp.appendingPathComponent(relative)
                    try FileManager.default.createDirectory(at:target.deletingLastPathComponent(),withIntermediateDirectories:true)
                    if FileManager.default.fileExists(atPath:target.path){try FileManager.default.removeItem(at:target)}
                    _ = try archive.extract(entry,to:target)
                }
                var p=try JSONDecoder().decode(Project.self,from:Data(contentsOf:temp.appendingPathComponent("project.json")))
                // Namespace each imported asset so another project cannot replace it.
                let namespace=UUID().uuidString+"-"
                var assets:[String:String]=[:],fonts:[String:String]=[:]
                for (folder,kind) in [("assets",0),("fonts",1)] {
                    for file in (try? FileManager.default.contentsOfDirectory(at:temp.appendingPathComponent(folder),includingPropertiesForKeys:[.isRegularFileKey])) ?? [] {
                        guard (try file.resourceValues(forKeys:[.isRegularFileKey])).isRegularFile==true else { continue }
                        let name=namespace+file.lastPathComponent
                        try FileManager.default.copyItem(at:file,to:root.appendingPathComponent(folder).appendingPathComponent(name))
                        if kind==0 { assets[file.lastPathComponent]=name } else { fonts[file.lastPathComponent]=name }
                    }
                }
                func map(_ list:[Node])->[Node] { list.map { n in var n=n;n.asset=assets[n.asset] ?? n.asset;n.font=fonts[n.font] ?? n.font;return n } }
                func mapLink(_ input:InteractionLink)->InteractionLink{var link=input;if var x=link.advanced{x.asset=assets[x.asset] ?? x.asset;for i in x.checkpoints.indices{x.checkpoints[i].actions=x.checkpoints[i].actions?.map(mapLink)};link.advanced=x};link.steps=link.steps?.map(mapLink);return link}
                p.links=p.links.map(mapLink)
                p.nodes=map(p.nodes);p.pages=p.pages.map { pg in var pg=pg;pg.nodes=map(pg.nodes);return pg }
                if var studio=p.studio{studio.states=studio.states.map{state in var state=state;state.nodes=map(state.nodes);return state};studio.textStyles=studio.textStyles?.map{style in var style=style;style.font=fonts[style.font] ?? style.font;return style};p.studio=studio}
                return p
            }.value
            var imported=p;imported.id=UUID().uuidString;DefaultLinks.allPages(&imported)
            try save(imported);registerFonts()
        } catch { self.error="Не удалось открыть проект: "+error.localizedDescription }
    }
    func archive(_ value:Project) throws -> URL {
        var p=value;p.syncPage()
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        let out=folder.appendingPathComponent(safeName(p.name)+".qwel")
        let zip=try Archive(url:out,accessMode:.create)
        let data=try JSONEncoder().encode(p)
        try zip.addEntry(with:"project.json",type:.file,uncompressedSize:Int64(data.count),compressionMethod:.deflate) { position,size in data.subdata(in:Int(position)..<min(data.count,Int(position)+size)) }
        let all=p.nodes+p.pages.flatMap(\.nodes)+(p.studio?.states.flatMap(\.nodes) ?? [])
        var assetNames=Set(all.map(\.asset).filter{!$0.isEmpty})
        func addLinkAssets(_ rules:[InteractionLink]){for rule in rules{
            if let asset=rule.advanced?.asset,!asset.isEmpty{assetNames.insert(asset)}
            addLinkAssets(rule.steps ?? [])
            for point in rule.advanced?.checkpoints ?? []{addLinkAssets(point.actions ?? [])}
        }}
        addLinkAssets(p.links)
        let fontNames=Set(all.map(\.font).filter{!$0.isEmpty})
        let folders:[(String,Set<String>)]=[("assets",assetNames),("fonts",fontNames)]
        for (folder,names) in folders {
            for name in names {
                let file=root.appendingPathComponent(folder).appendingPathComponent(name)
                if FileManager.default.fileExists(atPath:file.path) { try zip.addEntry(with:folder+"/"+name,fileURL:file,compressionMethod:.deflate) }
            }
        }
        return out
    }
}
func safeName(_ s:String)->String { let name=s.components(separatedBy:CharacterSet(charactersIn:"/\\:\n\r")).joined(separator:"_");return name.isEmpty ? "Qwel" : String(name.prefix(100)) }
