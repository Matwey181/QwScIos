import SwiftUI

struct SliderPointEditor:View {
    @Binding var point:SliderCheckpoint
    let parent:InteractionLink
    let layers:[Node]
    let states:[VisualState]
    let pages:[Page]
    let root:URL
    let stopChoices:[(String,String)]
    let showMarkerShape:Bool
    let onDelete:()->Void
    @State private var expanded:String?
    private var actions:[InteractionLink]{parent.actions(at:point)}
    private var effects:[(String,String)]{
        InteractionLink.effects.filter{!["thresholds","bind","moveObject","pinchObject","rotateObject"].contains($0.0)}
    }
    var body:some View{
        InlineSection(title:"Точка · \(Int(point.percent))%"){
            HStack{
                QNumber(title:"Порог %",value:Binding(get:{CGFloat(point.percent)},set:{point.percent=min(100,max(0,Double($0)))}))
                Button(role:.destructive,action:onDelete){Image(systemName:"trash")}
            }
            ForEach(actions){action in actionRow(action)}
            LinkPill(title:"Ещё действие на этой точке",icon:"plus"){
                var action=InteractionLink();action.sourceID=parent.sourceID;action.targetID=parent.targetID
                action.duration=parent.duration;action.easing=parent.easing
                point.actions=actions+[action];expanded=action.id
            }
            QToggle("Возвращать свойства при перемотке назад",isOn:Binding(get:{point.revertOnRewind ?? true},set:{point.revertOnRewind=$0}))
            if showMarkerShape{
                LinkChoiceField(title:"Форма отметки на полоске",selection:$point.shapeID,items:Catalog.shared.shapes.map{($0.id,$0.name)})
            }
        }
    }
    private func actionRow(_ action:InteractionLink)->some View{
        VStack(alignment:.leading,spacing:12){
            Button{expanded=expanded==action.id ? nil:action.id}label:{
                HStack{Text(label(action)).font(qfont(15,.semibold));Spacer();Image(systemName:expanded==action.id ? "chevron.up":"chevron.down")}
            }.buttonStyle(.plain)
            if expanded==action.id || actions.count==1{
                AnyView(LinkRuleForm(isStep:true,link:binding(action.id),layers:layers,states:states,pages:pages,root:root,stopChoices:stopChoices,availableEffects:effects))
            }
            Button("Удалить действие",role:.destructive){point.actions=actions.filter{$0.id != action.id}}
        }.padding(12).qSurface(18,"surfaceContainer")
    }
    private func label(_ action:InteractionLink)->String{
        let effect=InteractionLink.effects.first{$0.0==action.mode}?.1 ?? action.mode
        let target=layers.first{$0.id==action.targetID}?.name ?? "Слой"
        return effect+" · "+target
    }
    private func binding(_ id:String)->Binding<InteractionLink>{
        Binding(get:{actions.first{$0.id==id} ?? InteractionLink()},set:{value in
            var list=actions;if let i=list.firstIndex(where:{$0.id==id}){list[i]=value};point.actions=list
        })
    }
}
