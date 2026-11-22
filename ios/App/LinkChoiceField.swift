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
        if title=="Что сделать"{return ["state":"Состояния","playback":"Плеер","text":"Текст","echo":"Эффекты","toggle":"Внешний вид"][key] ?? "Свойства и движение"}
        if title=="Свойство"{
            if ["x","y","scale","rotation","width","height"].contains(key){return "Положение и размер"}
            if ["fontSize","weight"].contains(key){return "Текст"}
            if key=="progress"{return "Компоненты"}
            if ["fill","fill2","stroke","gradAngle"].contains(key){return "Цвет"}
            return "Форма и эффекты"
        }
        return ""
    }
    private var sections:[String]{Array(Set(filtered.map{group($0.0)})).sorted()}
    var body:some View {
        VStack(spacing:16){
            HStack{QIconButton(icon:"Back",label:"Назад",action:close);Text(title).font(qfont(22,.semibold));Spacer()}.padding(.top,12)
            QTextField(title:"Поиск",text:$search).padding(.horizontal,6)
            ScrollView {
                LazyVStack(alignment:.leading,spacing:8){ForEach(sections,id:\.self){section in
                    if !section.isEmpty{Text(section).font(qfont(13,.semibold)).foregroundStyle(q.color("primary")).padding(.top,12)}
                    ForEach(filtered.filter{group($0.0)==section},id:\.0){item in
                    Button{selection=item.0;close()}label:{
                        HStack(spacing:12){Text(item.1).font(qfont(16,.medium)).multilineTextAlignment(.leading);Spacer();if item.0==selection{Image(systemName:"checkmark.circle.fill").foregroundStyle(q.color("primary"))}}
                            .padding(18).frame(maxWidth:.infinity,alignment:.leading).qSurface(22,item.0==selection ? "primaryContainer":"surfaceContainerHigh")
                    }.buttonStyle(.plain)
                }}}.padding(.bottom,20)
            }.scrollDismissesKeyboard(.interactively)
        }.padding(.horizontal,16).background(q.color("surfaceContainer").ignoresSafeArea())
    }
}
