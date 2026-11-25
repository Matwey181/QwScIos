import SwiftUI

struct TextEditPanel:View {
    @ObservedObject var editor:Editor
    let nodeID:String
    var formattingOnly=false
    var close:()->Void
    @Environment(\.q) private var q
    @State private var draft=""
    @State private var runs:[TextRun]=[]
    @State private var selection=NSRange(location:0,length:0)
    @State private var color=false
    private var node:Node{editor.project.nodes.first{$0.id==nodeID} ?? Node()}
    var body:some View {
        VStack(alignment:.leading,spacing:12){
            Text(formattingOnly ? "Стиль текста":"Редактировать текст").font(qfont(22,.semibold))
            RichTextInput(text:$draft,runs:$runs,selection:$selection,node:node,font:editor.renderer.font(node))
                .frame(height:145).overlay(RoundedRectangle(cornerRadius:16).stroke(q.color("outline")))
            if !formattingOnly{HStack{Button("Цвет выделенного"){color=true};Button("Сбросить цвета"){runs=runs.map{var r=$0;r.color=nil;return r}}}.font(qfont(13));Text("Выдели слово и выбери цвет.").font(qfont(11))}
            if formattingOnly {
            VStack(spacing:8){HStack(spacing:8){QChip(title:"Жирный"){style(weight:700)};QChip(title:"Курсив"){style(italic:true)}};HStack(spacing:8){QChip(title:"Цвет"){color=true};QChip(title:"Обычный"){style(weight:400,italic:false,reset:true)}}}
            Text(selection.length>0 ? "Выделено: \(selection.length)":"Без выделения стиль применяется ко всему тексту.").font(qfont(11)).foregroundStyle(q.color("onSurfaceVariant"))
            }
            HStack{Button("Отмена",action:close);Spacer();Button("Готово"){commit();close()}.accessibilityIdentifier("textEditorDone")}.font(qfont(16,.semibold)).foregroundStyle(q.color("primary")).frame(minHeight:44)
        }.padding(24).qSurface(28,"surfaceContainerHigh")
        .onAppear{draft=node.text;runs=node.extras?.runs ?? []}
        .sheet(isPresented:$color){QColorDialog(initial:node.fill,cancel:{color=false},confirm:{style(color:$0);color=false}).padding(24).modifier(OriginalTheme())}
    }
    private func style(weight:Int?=nil,italic:Bool?=nil,color:Int64?=nil,reset:Bool=false){
        let range=selection.length>0 ? selection:NSRange(location:0,length:(draft as NSString).length)
        let existing=runs.last{$0.start<=range.location && $0.start+$0.length>range.location}
        runs.append(TextRun(start:range.location,length:range.length,weight:weight ?? existing?.weight ?? Int(node.weight),italic:italic ?? existing?.italic ?? false,color:reset ? nil:color ?? existing?.color))
    }
    private func commit(){
        guard let i=editor.project.nodes.firstIndex(where:{$0.id==nodeID}) else{return}
        editor.edit{p in p.nodes[i].text=draft;p.nodes[i].spans=AndroidTextSpans.format(runs);var extras=p.nodes[i].extras ?? LayerExtras();extras.runs=runs;p.nodes[i].extras=extras;editor.reflowText(&p.nodes[i])}
    }
}
