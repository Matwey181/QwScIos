import SwiftUI

struct PlaybackLinkControls:View {
    @Binding var link:InteractionLink
    let layers:[Node]
    @Environment(\.q) private var q
    private var texts:[(String,String)] {[("","Выбрать текст")]+layers.filter{$0.kind=="TEXT"}.map{($0.id,$0.name)}}
    var body:some View {
        VStack(alignment:.leading,spacing:14){
            Text("Ползунок как таймер").font(qfont(18,.semibold)).foregroundStyle(q.color("primary"))
            Text("Идёт от текущего положения до конца. Нажатие источника — пауза или продолжение; перемотка меняет время.").font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"))
            QNumber(title:"Полная длительность · секунды",value:Binding(get:{CGFloat(link.duration)},set:{link.duration=max(1,Double($0))}))
            QToggle("Запускать сразу в режиме игры",isOn:flag(\.autoplay))
            QToggle("Продолжать после перемотки",isOn:Binding(get:{link.resumeAfterSeek ?? true},set:{link.resumeAfterSeek=$0}))
            QToggle("Повторять с начала",isOn:$link.repeats)
            QToggle("Текст: прошло",isOn:flag(\.elapsedEnabled))
            if link.elapsedEnabled==true{LinkChoiceField(title:"Прошедшее время",selection:identifier(\.elapsedID),items:texts)}
            QToggle("Текст: осталось",isOn:flag(\.remainingEnabled))
            if link.remainingEnabled==true{LinkChoiceField(title:"Оставшееся время",selection:identifier(\.remainingID),items:texts)}
            if link.elapsedEnabled==true || link.remainingEnabled==true {
                LinkChoiceField(title:"Формат времени",selection:Binding(get:{link.clockFormat ?? "clock"},set:{link.clockFormat=$0}),items:[("clock","0:40"),("seconds","40 с"),("precise","0:40.0")])
            }
        }.padding(16).qSurface(24,"surfaceContainerHighest")
    }
    private func flag(_ key:WritableKeyPath<InteractionLink,Bool?>)->Binding<Bool>{Binding(get:{link[keyPath:key] ?? false},set:{link[keyPath:key]=$0})}
    private func identifier(_ key:WritableKeyPath<InteractionLink,String?>)->Binding<String>{Binding(get:{link[keyPath:key] ?? ""},set:{link[keyPath:key]=$0})}
}
