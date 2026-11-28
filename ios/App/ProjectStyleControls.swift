import SwiftUI

struct ProjectStyleControls:View {
    @ObservedObject var editor:Editor
    @State private var colorName="Основной цвет"
    @State private var textName="Заголовок"
    private var colors:[ProjectColorStyle]{editor.project.studio?.colorStyles ?? []}
    private var texts:[ProjectTextStyle]{editor.project.studio?.textStyles ?? []}
    var body:some View {VStack(alignment:.leading,spacing:14){
        InlineSection(title:"Общие цвета проекта"){
            QTextField(title:"Название цвета",text:$colorName)
            LinkPill(title:"Сохранить цвет выделения",icon:"plus"){let color=editor.selected.first?.fill ?? editor.project.tone.colors.first ?? -16749974;let style=ProjectColorStyle(name:colorName,light:color,dark:color);editor.studio{$0.colorStyles=($0.colorStyles ?? [])+[style]}}.disabled(editor.selected.isEmpty)
            ForEach(colors){style in colorControls(style)}
            if editor.selected.first?.extras?.colorStyleID != nil{Button("Отвязать цвет слоя"){editor.extras{$0.colorStyleID=nil}}}
        }
        InlineSection(title:"Стили текста"){
            QTextField(title:"Название стиля",text:$textName)
            LinkPill(title:"Сохранить стиль текста",icon:"textformat"){saveText()}.disabled(!editor.selected.contains{$0.kind=="TEXT"})
            ForEach(texts){style in textControls(style)}
            if editor.selected.first?.extras?.textStyleID != nil{Button("Отвязать стиль текста"){editor.extras{$0.textStyleID=nil}}}
        }
    }}
    private func colorControls(_ style:ProjectColorStyle)->some View {VStack(alignment:.leading,spacing:10){
        Text(style.name).font(qfont(16,.semibold))
        QColorRow(title:"Светлая тема",color:Binding(get:{colors.first{$0.id==style.id}?.light ?? style.light},set:{v in editColor(style.id){$0.light=v}}),colors:[])
        QColorRow(title:"Тёмная тема",color:Binding(get:{colors.first{$0.id==style.id}?.dark ?? style.dark},set:{v in editColor(style.id){$0.dark=v}}),colors:[])
        QChip(title:"Привязать выделение"){editor.extras{$0.colorStyleID=style.id}}.disabled(editor.selection.isEmpty)
        Button("Удалить стиль",role:.destructive){editor.studio{$0.colorStyles?.removeAll{$0.id==style.id}}}
    }.padding(14).qSurface(22,"surfaceContainerHigh")}
    private func textControls(_ style:ProjectTextStyle)->some View {VStack(alignment:.leading,spacing:10){
        Text(style.name).font(qfont(16,.semibold))
        HStack{QNumber(title:"Размер",value:Binding(get:{texts.first{$0.id==style.id}?.size ?? style.size},set:{v in editText(style.id){$0.size=max(4,v)}}));QNumber(title:"Интервал букв",value:Binding(get:{texts.first{$0.id==style.id}?.tracking ?? style.tracking},set:{v in editText(style.id){$0.tracking=v}}))}
        QChip(title:"Привязать выделенные тексты"){editor.extras{$0.textStyleID=style.id}}.disabled(!editor.selected.contains{$0.kind=="TEXT"})
        Button("Обновить из выделения"){if let node=editor.selected.first(where:{$0.kind=="TEXT"}){editText(style.id){$0.font=node.font;$0.size=node.fontSize;$0.weight=node.weight;$0.alignment=node.textAlign;$0.tracking=node.extras?.tracking ?? 0;$0.lineSpacing=node.extras?.lineSpacing ?? 0}}}
        Button("Удалить стиль",role:.destructive){editor.studio{$0.textStyles?.removeAll{$0.id==style.id}}}
    }.padding(14).qSurface(22,"surfaceContainerHigh")}
    private func saveText(){guard let n=editor.selected.first(where:{$0.kind=="TEXT"}) else{return};let style=ProjectTextStyle(name:textName,font:n.font,size:n.fontSize,weight:n.weight,alignment:n.textAlign,tracking:n.extras?.tracking ?? 0,lineSpacing:n.extras?.lineSpacing ?? 0);editor.studio{$0.textStyles=($0.textStyles ?? [])+[style]}}
    private func editColor(_ id:String,_ block:(inout ProjectColorStyle)->Void){editor.studio{s in if let i=s.colorStyles?.firstIndex(where:{$0.id==id}){block(&s.colorStyles![i])}}}
    private func editText(_ id:String,_ block:(inout ProjectTextStyle)->Void){editor.studio{s in if let i=s.textStyles?.firstIndex(where:{$0.id==id}){block(&s.textStyles![i])}}}
}
