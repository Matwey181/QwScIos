import SwiftUI

struct SavedLinkSet:Codable,Identifiable {var id=UUID().uuidString;var name:String;var sourceIDs:[String];var links:[InteractionLink];var names:[String:String]}
@MainActor final class MyLinkSets:ObservableObject {
    static let shared=MyLinkSets()
    @Published var sets:[SavedLinkSet]=(UserDefaults.standard.data(forKey:"myLinkSets").flatMap{try? JSONDecoder().decode([SavedLinkSet].self,from:$0)}) ?? []
    func save(){UserDefaults.standard.set(try? JSONEncoder().encode(sets),forKey:"myLinkSets")}
}
struct MyLinkSetsPanel:View {
    @ObservedObject var editor:Editor
    let source:Node
    @ObservedObject private var library=MyLinkSets.shared
    @State private var selected=Set<String>()
    @State private var title="Моя связка"
    @State private var applying:SavedLinkSet?
    @State private var roles:[String:String]=[:]
    private var rules:[InteractionLink]{editor.links(for:source)}
    var body:some View{VStack(alignment:.leading,spacing:12){
        Text("Выберите реакции, объедините их и сохраните для другого объекта.").font(qfont(13))
        ForEach(rules){rule in Button{if !selected.insert(rule.id).inserted{selected.remove(rule.id)}}label:{HStack{Image(systemName:selected.contains(rule.id) ? "checkmark.circle.fill":"circle");Text((InteractionLink.effects.first{$0.0==rule.mode}?.1 ?? rule.mode)+" · "+(editor.project.nodes.first{$0.id==rule.targetID}?.name ?? "Слой")).font(qfont(13));Spacer()}}.buttonStyle(.plain)}
        QTextField(title:"Название набора",text:$title)
        LinkPill(title:"Объединить и сохранить",icon:"square.stack.3d.up"){save()}.disabled(selected.isEmpty)
        ForEach(library.sets){set in HStack{VStack(alignment:.leading){Text(set.name).font(qfont(16,.semibold));Text("Реакций: \(set.links.count)").font(qfont(12))};Spacer();Button("Применить"){applying=set;roles=[:]} ;Button(role:.destructive){library.sets.removeAll{$0.id==set.id};library.save()}label:{Image(systemName:"trash")}}}
    }.sheet(item:$applying){set in ScrollView{VStack(spacing:16){Text(set.name).font(qfont(24,.semibold));Text("Источник — выбранный объект. Выберите, какие слои должны изменяться.").font(qfont(13));ForEach(Array(Set(set.links.flatMap{[$0.targetID,$0.elapsedID ?? "",$0.remainingID ?? "",$0.advanced?.areaID ?? "",$0.advanced?.otherID ?? ""].filter{!$0.isEmpty}+($0.advanced?.sourceIDs ?? [])+($0.advanced?.targetIDs ?? [])})).sorted(),id:\.self){id in
        LinkChoiceField(title:set.names[id] ?? "Цель",selection:Binding(get:{roles[id] ?? source.id},set:{roles[id]=$0}),items:editor.project.nodes.map{($0.id,$0.name)})
    };LinkPill(title:"Добавить набор",icon:"plus",prominent:true){apply(set);applying=nil}}.padding(20)}.modifier(OriginalTheme())}}
    private func save(){let rules=rules.filter{selected.contains($0.id)};let sources=Set(rules.map(\.sourceID));let names=Dictionary(editor.project.nodes.map{($0.id,$0.name)},uniquingKeysWith:{_,b in b});let set=SavedLinkSet(name:title.isEmpty ? "Моя связка":title,sourceIDs:Array(sources),links:rules,names:names);library.sets.append(set);library.save();let ids=selected;editor.edit{p in for i in p.links.indices where ids.contains(p.links[i].id){p.links[i].bundleID=set.id;p.links[i].bundleName=set.name}};selected=[]}
    private func apply(_ set:SavedLinkSet){let id=UUID().uuidString;func map(_ old:String)->String{roles[old] ?? (set.sourceIDs.contains(old) ? source.id:source.id)};func remap(_ input:InteractionLink)->InteractionLink{var r=input;r.id=UUID().uuidString;r.sourceID=source.id;r.targetID=map(r.targetID);r.bundleID=id;r.bundleName=set.name;r.elapsedID=r.elapsedID.map(map);r.remainingID=r.remainingID.map(map);r.steps=r.steps?.map{remap($0)};if var x=r.advanced{x.sourceIDs=x.sourceIDs.map(map);x.targetIDs=x.targetIDs.map(map);if !x.areaID.isEmpty{x.areaID=map(x.areaID)};if !x.otherID.isEmpty{x.otherID=map(x.otherID)};r.advanced=x};return r};let links=set.links.map(remap);editor.edit{$0.links+=links}}
}
