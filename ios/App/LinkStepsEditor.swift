import SwiftUI

struct LinkStepsEditor:View {
    @Binding var link:InteractionLink
    let layers:[Node]
    let states:[VisualState]
    var pages:[Page]=[]
    var root:URL=FileManager.default.temporaryDirectory
    var stopChoices:[(String,String)]=[]
    @State private var expanded:String?
    @Environment(\.q) private var q
    private var enabled:Binding<Bool>{Binding(get:{link.steps != nil},set:{v in link.steps=v ? []:nil})}
    var body:some View {
        VStack(alignment:.leading,spacing:14){
            QToggle("Дополнительные действия",isOn:enabled)
            if link.steps != nil {
                Text("Первое действие настроено выше. Каждый следующий шаг может ждать предыдущий или начаться вместе с ним.").font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"))
                ForEach(link.steps ?? []){step in
                    VStack(alignment:.leading,spacing:12){
                        Button{expanded=expanded==step.id ? nil:step.id}label:{HStack{Text("\((link.steps?.firstIndex{$0.id==step.id} ?? 0)+2). \(InteractionLink.effects.first{$0.0==step.mode}?.1 ?? step.mode)").font(qfont(15,.semibold));Spacer();Image(systemName:expanded==step.id ? "chevron.up":"chevron.down")}}.buttonStyle(.plain)
                        LinkChoiceField(title:"Начало шага",selection:Binding(get:{step.stepTiming ?? "after"},set:{v in update(step.id){$0.stepTiming=v}}),items:[("after","После предыдущего"),("with","Вместе с предыдущим")])
                        if expanded==step.id{LinkRuleForm(isStep:true,link:binding(step.id),layers:layers,states:states,pages:pages,root:root,stopChoices:stopChoices)}
                        HStack{
                            Button("Выше"){move(step.id,-1)}.disabled(link.steps?.first?.id==step.id)
                            Button("Ниже"){move(step.id,1)}.disabled(link.steps?.last?.id==step.id)
                            Spacer();Button("Удалить",role:.destructive){link.steps?.removeAll{$0.id==step.id}}
                        }.font(qfont(13,.medium))
                    }.padding(14).qSurface(22,"surfaceContainer")
                }
                LinkPill(title:"Добавить действие",icon:"plus"){var step=InteractionLink();step.targetID=link.targetID;step.sourceID=link.sourceID;step.stepTiming="after";step.property=link.property;step.value=link.value;step.easing=link.easing;link.steps?.append(step);expanded=step.id}
            }
        }
    }
    private func update(_ id:String,_ block:(inout InteractionLink)->Void){guard let i=link.steps?.firstIndex(where:{$0.id==id}) else{return};block(&link.steps![i])}
    private func binding(_ id:String)->Binding<InteractionLink>{Binding(get:{link.steps?.first{$0.id==id} ?? InteractionLink()},set:{value in update(id){$0=value}})}
    private func move(_ id:String,_ delta:Int){guard let i=link.steps?.firstIndex(where:{$0.id==id}),let count=link.steps?.count,(0..<count).contains(i+delta) else{return};link.steps?.swapAt(i,i+delta)}
}
