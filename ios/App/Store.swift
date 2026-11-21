import SwiftUI
import ZIPFoundation
import CoreText

@MainActor final class ProjectStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var error: String?
    @Published var working = false
    let root: URL
    var assets: URL { root.appendingPathComponent("assets") }
    var fonts: URL { root.appendingPathComponent("fonts") }
    init(root:URL?=nil) {
        self.root = root ?? FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0]
        for folder in [self.root,self.root.appendingPathComponent("projects"),assets,fonts] { try? FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true) }
        registerFonts()
        reload()
    }
    func registerFonts() {
        let custom=(try? FileManager.default.contentsOfDirectory(at:fonts,includingPropertiesForKeys:nil)) ?? []
        let bundled=(Bundle.main.urls(forResourcesWithExtension:"ttf",subdirectory:nil) ?? [])+(Bundle.main.urls(forResourcesWithExtension:"otf",subdirectory:nil) ?? [])
        for u in custom+bundled { CTFontManagerRegisterFontsForURL(u as CFURL,.process,nil) }
    }
    func reload() {
        let folder=root.appendingPathComponent("projects")
        projects=((try? FileManager.default.contentsOfDirectory(at:folder,includingPropertiesForKeys:nil)) ?? []).filter { $0.pathExtension=="json" }.compactMap { u in
            guard let d=try? Data(contentsOf:u) else { return nil }; return try? JSONDecoder().decode(Project.self,from:d)
        }.sorted { $0.updated > $1.updated }
    }
    func save(_ value:Project) throws {
        var p=value; p.syncPage(); p.updated=Int64(Date().timeIntervalSince1970*1000)
        let d=try JSONEncoder().encode(p)
        try d.write(to:root.appendingPathComponent("projects/\(p.id).json"),options:.atomic)
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
                if url.pathExtension.lowercased()=="json" { return try JSONDecoder().decode(Project.self,from:Data(contentsOf:url)) }
                let archive=try Archive(url:url,accessMode:.read)
                var total:UInt64=0
                for entry in archive {
                    total += UInt64(entry.uncompressedSize)
                    guard total <= 150*1024*1024 else { throw CocoaError(.fileReadTooLarge) }
                    let bits=entry.path.split(separator:"/",omittingEmptySubsequences:false)
                    guard entry.path=="project.json" || (bits.count==2 && ["assets","fonts"].contains(String(bits[0])) && !["",".",".."].contains(String(bits[1])) && !entry.path.contains("\\")) else { continue }
                    let target=temp.appendingPathComponent(entry.path)
                    try FileManager.default.createDirectory(at:target.deletingLastPathComponent(),withIntermediateDirectories:true)
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
                p.nodes=map(p.nodes);p.pages=p.pages.map { pg in var pg=pg;pg.nodes=map(pg.nodes);return pg }
                return p
            }.value
            var imported=p;imported.id=UUID().uuidString
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
        let all=p.nodes+p.pages.flatMap(\.nodes)
        for (folder,names) in [("assets",Set(all.map(\.asset).filter{!$0.isEmpty})),("fonts",Set(all.map(\.font).filter{!$0.isEmpty}))] {
            for name in names {
                let file=root.appendingPathComponent(folder).appendingPathComponent(name)
                if FileManager.default.fileExists(atPath:file.path) { try zip.addEntry(with:folder+"/"+name,fileURL:file,compressionMethod:.deflate) }
            }
        }
        return out
    }
}
func safeName(_ s:String)->String { let name=s.components(separatedBy:CharacterSet(charactersIn:"/\\:\n\r")).joined(separator:"_");return name.isEmpty ? "Qwel" : String(name.prefix(100)) }
