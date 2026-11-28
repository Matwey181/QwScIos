import SwiftUI

struct TabBarControls:View {
    @ObservedObject var editor:Editor
    var groups:[String]{Array(Set(editor.selected.filter{$0.group.contains("~ios-tab-bar")}.map(\.group)))}
    private var count:Int{guard let group=groups.first else{return 4};return Set(editor.project.nodes.filter{$0.group==group && $0.widget.hasPrefix("pick:i") && !$0.widget.hasPrefix("pick:ind")}.compactMap{Int($0.widget.dropFirst(6).split(separator:"/").first ?? "")}).count}
    var body:some View{
        if !groups.isEmpty{VStack(alignment:.leading,spacing:6){Text("Вкладок: \(count)").font(qfont(14,.semibold));QSlider(value:Binding(get:{Double(count)},set:{value in let count=min(8,max(2,Int(value.rounded())));if count != self.count{resize(count)}}),range:2...8)}}
    }
    private func resize(_ count:Int){
        editor.edit{project in
            for group in groups{
                let nodes=project.nodes.filter{$0.group==group}
                guard let rail=nodes.first(where:{$0.kind=="RECT" && $0.widget.isEmpty}),let indicator=nodes.first(where:{$0.widget.hasPrefix("pick:ind")})else{continue}
                let dark=project.tone.dark,ink:Int64=dark ? 0xff98989f:0xff6c6c70,blue:Int64=dark ? 0xff0a84ff:0xff007aff
                let step=(rail.w-8)/CGFloat(count),scale=rail.h/76
                let symbols=["house.fill","magnifyingglass","square.stack.fill","person.crop.circle","star.fill","heart.fill","bell.fill","gearshape.fill"]
                let titles=["Главная","Поиск","Медиатека","Профиль","Избранное","Коллекция","События","Настройки"]
                var replacement=nodes.filter{!$0.widget.hasPrefix("pick:")}
                var lens=indicator;lens.x=rail.x+4;lens.w=step;lens.h=rail.h-8*scale;lens.corner=lens.h/2;replacement.append(lens)
                for index in 0..<count{
                    let role="pick:i\(index)/\(UInt32(truncatingIfNeeded:blue))/\(UInt32(truncatingIfNeeded:ink))"
                    let existing=nodes.filter{$0.widget.hasPrefix("pick:i\(index)/")}
                    var icon=existing.first{$0.kind=="IMAGE"} ?? Node();icon.id=existing.first{$0.kind=="IMAGE"}?.id ?? UUID().uuidString;icon.kind="IMAGE";icon.asset="sf:"+symbols[index];icon.name=titles[index];icon.group=group;icon.widget=role;icon.w=23*scale;icon.h=23*scale;icon.x=rail.x+4+step*(CGFloat(index)+0.5)-icon.w/2;icon.y=rail.y+18*scale;icon.fill=index==0 ? blue:ink;icon.fillToken = -1
                    var text=existing.first{$0.kind=="TEXT"} ?? Node();text.kind="TEXT";text.name=titles[index];text.text=titles[index];text.group=group;text.widget=role;text.x=rail.x+4+step*CGFloat(index);text.y=rail.y+47*scale;text.w=step;text.h=16*scale;text.fontSize=(count>5 ? 9:11)*scale;text.fixW=true;text.textAlign="center";text.fill=index==0 ? blue:ink;text.fillToken = -1
                    var extras=text.extras ?? LayerExtras();extras.appleTextPrepared=true;extras.hugHeight=false;text.extras=extras
                    replacement += [icon,text]
                }
                let index=project.nodes.firstIndex{$0.group==group} ?? project.nodes.count
                project.nodes.removeAll{$0.group==group};project.nodes.insert(contentsOf:replacement,at:min(index,project.nodes.count))
            }
        }
        editor.selection=Set(editor.project.nodes.filter{groups.contains($0.group)}.map(\.id))
    }
}
