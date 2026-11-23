import SwiftUI

struct LinkChoiceField:View {
    let title:String
    @Binding var selection:String
    let items:[(String,String)]
    @Environment(\.q) private var q
    @State private var choosing=false
    var body:some View {
        Button{choosing=true}label:{
            HStack(spacing:12){
                VStack(alignment:.leading,spacing:5){
                    Text(title).font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"))
                    Text(items.first{$0.0==selection}?.1 ?? "Выбрать").font(qfont(16,.medium)).foregroundStyle(q.color("onSurface")).multilineTextAlignment(.leading)
                }
                Spacer(minLength:8)
                Image(systemName:"chevron.down").font(.system(size:13,weight:.semibold)).foregroundStyle(q.color("primary"))
            }.padding(16).frame(maxWidth:.infinity,alignment:.leading).qSurface(22,"surfaceContainerHighest")
        }.buttonStyle(.plain).sheet(isPresented:$choosing){
            LinkChoiceSheet(title:title,selection:$selection,items:items){choosing=false}.modifier(OriginalTheme())
        }
    }
}
private struct LinkChoiceSheet:View {
    let title:String
    @Binding var selection:String
    let items:[(String,String)]
    var close:()->Void
    @Environment(\.q) private var q
    @State private var search=""
    private var filtered:[(String,String)] {search.isEmpty ? items:items.filter{$0.1.localizedCaseInsensitiveContains(search)}}
    private func group(_ key:String)->String {
        if title=="Что сделать"{return ["state":"Состояния","playback":"Плеер","text":"Текст","echo":"Эффекты","toggle":"Внешний вид","visibility":"Внешний вид","navigate":"Навигация","url":"Навигация","component":"Компоненты","playerControl":"Плеер"][key] ?? "Свойства и движение"}
        if title=="Свойство"{
            if ["x","y","scale","rotation","width","height"].contains(key){return "Положение и размер"}
            if ["fontSize","weight"].contains(key){return "Текст"}
            if key=="progress"{return "Компоненты"}
            if ["fill","fill2","stroke","gradAngle","fillOpacity"].contains(key){return "Цвет"}
            return "Форма и эффекты"
        }
        return ""
    }
    private var sections:[String]{Array(Set(filtered.map{group($0.0)})).sorted()}
    var body:some View {
        VStack(spacing:16){
            HStack{QIconButton(icon:"Back",label:"Назад",action:close);Text(title).font(qfont(22,.semibold));Spacer()}.padding(.top,12)
            QTextField(title:"Поиск",text:$search).padding(.horizontal,6)
            LinkChoiceList(items:filtered,selection:selection,palette:q,group:group){key in selection=key;close()}
        }.padding(.horizontal,16).background(q.color("surfaceContainer").ignoresSafeArea())
    }
}

private struct LinkChoiceList:UIViewRepresentable {
    var items:[(String,String)]
    var selection:String
    var palette:QPalette
    var group:(String)->String
    var choose:(String)->Void
    func makeCoordinator()->Coordinator{Coordinator(self)}
    func makeUIView(context:Context)->UITableView {
        let table=UITableView(frame:.zero,style:.plain)
        table.backgroundColor = .clear;table.separatorStyle = .none
        table.delaysContentTouches=true;table.canCancelContentTouches=true
        table.keyboardDismissMode = .interactive;table.rowHeight=UITableView.automaticDimension;table.estimatedRowHeight=74
        table.delegate=context.coordinator;table.dataSource=context.coordinator
        return table
    }
    func updateUIView(_ table:UITableView,context:Context){context.coordinator.parent=self;table.reloadData()}
    final class Coordinator:NSObject,UITableViewDelegate,UITableViewDataSource {
        var parent:LinkChoiceList
        init(_ parent:LinkChoiceList){self.parent=parent}
        var sections:[String]{Array(Set(parent.items.map{parent.group($0.0)})).sorted()}
        func rows(_ section:Int)->[(String,String)]{parent.items.filter{parent.group($0.0)==sections[section]}}
        func numberOfSections(in tableView:UITableView)->Int{sections.count}
        func tableView(_ tableView:UITableView,numberOfRowsInSection section:Int)->Int{rows(section).count}
        func tableView(_ tableView:UITableView,titleForHeaderInSection section:Int)->String?{sections[section].isEmpty ? nil:sections[section]}
        func tableView(_ tableView:UITableView,cellForRowAt indexPath:IndexPath)->UITableViewCell {
            let cell=tableView.dequeueReusableCell(withIdentifier:"choice") ?? UITableViewCell(style:.default,reuseIdentifier:"choice")
            let item=rows(indexPath.section)[indexPath.row],selected=item.0==parent.selection,q=parent.palette
            cell.backgroundColor = .clear;cell.selectionStyle = .none
            cell.contentConfiguration=UIHostingConfiguration{
                HStack(spacing:12){Text(item.1).font(qfont(16,.medium)).foregroundStyle(q.color("onSurface")).multilineTextAlignment(.leading);Spacer();if selected{Image(systemName:"checkmark.circle.fill").foregroundStyle(q.color("primary"))}}
                    .padding(18).frame(maxWidth:.infinity,alignment:.leading).qSurface(22,selected ? "primaryContainer":"surfaceContainerHigh").environment(\.q,q)
            }.margins(.vertical,4).margins(.horizontal,0)
            return cell
        }
        func tableView(_ tableView:UITableView,didSelectRowAt indexPath:IndexPath){tableView.deselectRow(at:indexPath,animated:false);parent.choose(rows(indexPath.section)[indexPath.row].0)}
    }
}
