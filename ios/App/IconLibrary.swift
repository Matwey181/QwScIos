import SwiftUI
import UniformTypeIdentifiers
import ZIPFoundation

struct ImportedIconPanel:View {
    @ObservedObject var editor:Editor
    var choose:()->Void
    @Environment(\.q) var q
    @State private var selecting=false
    @State private var query=""
    @State private var revision=0
    @State private var style="outlined"
    @State private var fill=false
    private var folder:URL{editor.store.root.appendingPathComponent("icons")}
    private var all:[URL]{((try? FileManager.default.contentsOfDirectory(at:folder,includingPropertiesForKeys:nil)) ?? []).filter{$0.pathExtension=="svg"}}
    private var shown:[URL]{let _=revision;return all.filter{(query.isEmpty || $0.lastPathComponent.localizedCaseInsensitiveContains(query)) && $0.lastPathComponent.hasPrefix(style+"--") && ($0.deletingPathExtension().lastPathComponent.hasSuffix("-fill")==fill)}.sorted{$0.lastPathComponent<$1.lastPathComponent}}
    var body:some View {
        VStack(alignment:.leading,spacing:10) {
            if all.isEmpty {Text("Иконки Material Symbols").font(qfont(16,.semibold));Text("Импортируйте набор SVG-иконок из ZIP-архива. Можно использовать Outlined, Rounded и Sharp.").font(qfont(14)).foregroundStyle(q.color("onSurfaceVariant"))}
            else {QTextField(title:"Поиск иконок",text:$query);HStack(spacing:8){ForEach(["outlined","rounded","sharp"],id:\.self){s in QChip(title:s.capitalized,selected:style==s){style=s}};QChip(title:"Заливка",selected:fill){fill.toggle()}};Text("Иконок: \(shown.count)").font(qfont(12));LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:8),count:4),spacing:8){ForEach(shown,id:\.path){url in IconTile(url:url,editor:editor)}}}
            Button{selecting=true}label:{Text(all.isEmpty ? "Импортировать набор":"Добавить ещё").font(qfont(14,.semibold)).frame(maxWidth:.infinity).frame(height:40).background(q.color("primary"),in:Capsule()).foregroundStyle(q.color("onPrimary"))}.buttonStyle(.plain)
        }.fileImporter(isPresented:$selecting,allowedContentTypes:[.data],allowsMultipleSelection:false){result in if case .success(let urls)=result,let url=urls.first{importIcons(url)}}
    }
    private func importIcons(_ url:URL){Task{@MainActor in do{let access=url.startAccessingSecurityScopedResource();defer{if access{url.stopAccessingSecurityScopedResource()}};let root=folder
        let count=try await Task.detached{()->Int in try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);let archive=try Archive(url:url,accessMode:.read);var count=0,total:UInt64=0
            for entry in archive where entry.path.lowercased().hasSuffix(".svg") {guard entry.type == .file,entry.uncompressedSize<2_000_000 else{continue};total+=UInt64(entry.uncompressedSize);guard total<200_000_000,count<50000 else{throw CocoaError(.fileReadTooLarge)};let parts=entry.path.split(separator:"/").map(String.init);let style=parts.first(where:{["outlined","rounded","sharp"].contains($0)}) ?? "outlined";guard let basename=parts.last,!basename.contains("\\") else{continue};let destination=root.appendingPathComponent(style+"--"+basename);if FileManager.default.fileExists(atPath:destination.path){continue};_=try archive.extract(entry,to:destination);count+=1};return count
        }.value;revision+=1;if count==0{editor.error="В архиве не найдены SVG-иконки."}
    }catch{editor.error=error.localizedDescription}}}
}
private struct IconTile:View {
    var url:URL
    @ObservedObject var editor:Editor
    @Environment(\.q) var q
    @State private var nodes:[Node]=[]
    var body:some View {Button{var copies=nodes;let box=copies.reduce(CGRect.null){$0.union($1.rect)},k=48/max(box.width,box.height);copies=copies.map{n in var n=n;n.id=UUID().uuidString;n.x=(n.x-box.midX)*k+editor.project.w/2;n.y=(n.y-box.midY)*k+editor.project.h/2;n.w*=k;n.h*=k;n.fill=editor.project.tone.colors.first ?? -16749974;return n};editor.edit{$0.nodes+=copies};editor.selection=Set(copies.map(\.id))}label:{VStack(spacing:6){EffectPreview(nodes:nodes,renderer:editor.renderer).frame(height:46);Text(url.deletingPathExtension().lastPathComponent.components(separatedBy:"--").last ?? "").font(qfont(10,.medium)).lineLimit(1)}.padding(6).qSurface(20,"surfaceContainerHighest")}.buttonStyle(.plain).task{nodes=(try? SVGImport.parse(Data(contentsOf:url))) ?? []}}
}
