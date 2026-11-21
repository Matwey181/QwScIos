import SwiftUI

struct LinkRulesEditor:View {
    @ObservedObject var editor:Editor
    let source:Node
    @Environment(\.q) private var q
    @State private var expandedID:String?
    var body:some View {
        VStack(alignment:.leading,spacing:18){
            intro
            presets
            ForEach(editor.project.links){link in ruleCard(link)}
            LinkPill(title:"Новая связка",icon:"plus",prominent:true){preset("custom")}
        }
    }
    private var intro:some View {
        HStack(alignment:.top,spacing:14){
            Image(systemName:"point.3.connected.trianglepath.dotted").font(.system(size:28,weight:.medium)).foregroundStyle(q.color("onPrimaryContainer")).frame(width:56,height:56).qSurface(22,"primaryContainer")
            VStack(alignment:.leading,spacing:6){Text("Один жест. Любая реакция.").font(qfont(19,.semibold));Text("Соедините кнопку, ползунок или слой с нужным свойством. Несколько реакций могут работать одновременно.").font(qfont(13)).foregroundStyle(q.color("onSurfaceVariant"))}
        }.padding(20).qSurface(28,"surfaceContainerHigh")
    }
    private var presets:some View {
        VStack(alignment:.leading,spacing:10){
            Text("Быстрый старт").font(qfont(14,.semibold)).foregroundStyle(q.color("primary"))
            ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){
                LinkPill(title:"Форма 5 ↔ 8",icon:"sparkle"){preset("morph")}
                LinkPill(title:"Ползунок → эхо",icon:"slider.horizontal.3"){preset("echo")}
                LinkPill(title:"Пульсация",icon:"wave.3.right"){preset("pulse")}
                LinkPill(title:"Таймер-плеер",icon:"play.fill"){preset("playback")}
                LinkPill(title:"Прогресс 15 с",icon:"play.fill"){preset("progress")}
                LinkPill(title:"Смена текста",icon:"textformat"){preset("text")}
                LinkPill(title:"Ползунок → размер",icon:"arrow.up.left.and.arrow.down.right"){preset("scale")}
            }}
        }
    }
    private func ruleCard(_ link:InteractionLink)->some View {
        VStack(alignment:.leading,spacing:16){
            Button{withAnimation(.spring(response:0.35,dampingFraction:0.85)){expandedID=expandedID==link.id ? nil:link.id}}label:{
                HStack(spacing:12){
                    Image(systemName:link.mode=="echo" ? "wave.3.right":"point.3.connected.trianglepath.dotted").font(.system(size:22)).foregroundStyle(q.color("primary")).frame(width:44,height:44).qSurface(18,"surfaceContainerHighest")
                    VStack(alignment:.leading,spacing:5){Text(InteractionLink.events.first{$0.0==link.event}?.1 ?? link.event).font(qfont(16,.semibold));Text(summary(link)).font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant")).lineLimit(2)}
                    Spacer(minLength:0)
                    Image(systemName:expandedID==link.id ? "chevron.up":"chevron.down").font(.system(size:12,weight:.semibold)).foregroundStyle(q.color("primary"))
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
            HStack(spacing:12){
                QSwitch(on:Binding(get:{editor.project.links.first{$0.id==link.id}?.enabled ?? false},set:{v in update(link.id){$0.enabled=v}}))
                Text(link.enabled ? "Активна":"Выключена").font(qfont(13)).foregroundStyle(q.color("onSurfaceVariant"))
                Spacer()
                mini("doc.on.doc","Дублировать"){var copy=link;copy.id=UUID().uuidString;editor.edit{$0.links.append(copy)};expandedID=copy.id}
                mini("trash","Удалить"){editor.edit{$0.links.removeAll{$0.id==link.id}}}
            }
            if expandedID==link.id {LinkRuleForm(link:binding(link.id),layers:editor.project.nodes)}
        }.padding(18).qSurface(28,"surfaceContainerHigh")
    }
    private func mini(_ icon:String,_ label:String,action:@escaping()->Void)->some View {
        Button(action:action){Image(systemName:icon).font(.system(size:16,weight:.medium)).foregroundStyle(q.color("primary")).frame(width:44,height:44).qSurface(18,"surfaceContainerHighest")}.buttonStyle(.plain).accessibilityLabel(label)
    }
    private func summary(_ rule:InteractionLink)->String {
        let from=editor.project.nodes.first{$0.id==rule.sourceID}?.name ?? "Источник"
        let to=editor.project.nodes.first{$0.id==rule.targetID}?.name ?? "Цель"
        return "\(from) → \(to)"
    }
    private func binding(_ id:String)->Binding<InteractionLink>{Binding(get:{editor.project.links.first{$0.id==id} ?? InteractionLink()},set:{next in update(id){$0=next}})}
    private func update(_ id:String,_ change:(inout InteractionLink)->Void){editor.edit{p in if let i=p.links.firstIndex(where:{$0.id==id}){change(&p.links[i])}}}
    private func preset(_ kind:String){
        var rule=InteractionLink();rule.sourceID=source.id;rule.targetID=source.id
        switch kind {
        case "morph":rule.property="morph";rule.shapeID="star-8";rule.alternate=true;rule.duration=0.5
        case "playback":rule.mode="playback";rule.duration=80;rule.easing="linear";rule.autoplay=true;rule.elapsedEnabled=false;rule.remainingEnabled=false
        case "progress":rule.property="progress";rule.duration=15;rule.easing="linear"
        case "text":rule.mode="text";rule.alternate=true
        case "scale":rule.event="valueChanged";rule.mode="bind";rule.property="scale";rule.from=0.7;rule.to=1.5
        case "echo":rule.event="valueChanged";rule.mode="bind";rule.property="echo";rule.from=0;rule.to=1
        case "pulse":rule.mode="echo";rule.value=1;rule.duration=1
        default:break
        }
        if kind=="playback",let slider=editor.project.nodes.first(where:{$0.widget.hasPrefix("slider:") || $0.widget.hasPrefix("progress:")}){rule.targetID=slider.id}
        if ["echo","scale"].contains(kind),let slider=editor.project.nodes.first(where:{$0.widget.hasPrefix("slider:")}){rule.sourceID=slider.id}
        editor.edit{$0.links.append(rule)};expandedID=rule.id
    }
}

struct LinkPill:View {
    let title:String
    let icon:String
    var prominent=false
    var action:()->Void
    @Environment(\.q) private var q
    var body:some View{Button(action:action){HStack(spacing:9){Image(systemName:icon).font(.system(size:15,weight:.semibold));Text(title).font(qfont(14,.semibold))}.padding(.horizontal,18).padding(.vertical,15).foregroundStyle(q.color(prominent ? "onPrimaryContainer":"primary")).qSurface(28,prominent ? "primaryContainer":"surfaceContainerHighest")}.buttonStyle(.plain)}
}

private struct LinkRuleForm:View {
    @Binding var link:InteractionLink
    let layers:[Node]
    @Environment(\.q) private var q
    private var colorProperty:Bool{["fill","stroke","fill2","shadowColor"].contains(link.property)}
    private var nodeChoices:[(String,String)]{
        layers.map{node in
            let kind=node.widget.components(separatedBy:":").first ?? ""
            let type=["slider":"Ползунок","progress":"Прогресс","switch":"Переключатель","press":"Кнопка","pick":"Выбор"][kind] ?? ["TEXT":"Текст","SHAPE":"Фигура","IMAGE":"Картинка","RECT":"Прямоугольник","ELLIPSE":"Эллипс"][node.kind] ?? "Слой"
            return (node.id,"\(type) · \(node.name)")
        }
    }
    var body:some View {
        VStack(alignment:.leading,spacing:18){
            section("01",title:"Источник"){
                LinkChoiceField(title:"Откуда приходит действие",selection:$link.sourceID,items:nodeChoices)
                LinkChoiceField(title:"Когда",selection:$link.event,items:InteractionLink.events)
            }
            section("02",title:"Реакция"){
                LinkChoiceField(title:"Что сделать",selection:$link.mode,items:InteractionLink.effects)
                LinkChoiceField(title:"Какой слой изменить",selection:$link.targetID,items:nodeChoices)
                propertyControls
                textControls
                if link.mode=="playback"{PlaybackLinkControls(link:$link,layers:layers)}
            }
            timingControls
        }.onChange(of:link.property){_,property in if property=="morph" && link.shapeID==nil{link.shapeID="star-8";link.from=0;link.to=1}}
        .onChange(of:link.targetID){_,id in
            if let node=layers.first(where:{$0.id==id}),["slider","progress","switch"].contains(node.widget.components(separatedBy:":").first ?? ""),link.property=="opacity" {link.property="progress"}
        }
    }
    @ViewBuilder private var propertyControls:some View {
        if ["animate","set","bind"].contains(link.mode){
            LinkChoiceField(title:"Свойство",selection:$link.property,items:InteractionLink.properties)
            if link.property=="morph"{shapeControls}
            else if colorProperty{QColorRow(title:"Конечный цвет",color:$link.color,colors:[])}
            else if link.mode=="bind"{boundsControls}
            else if link.property != "progress" {number("Значение",value:$link.value)}
            if link.mode=="bind" && link.property=="morph"{boundsControls}
        }
        if ["animate","set","text"].contains(link.mode){QToggle("При повторном нажатии — обратно",isOn:Binding(get:{link.alternate ?? false},set:{link.alternate=$0}))}
        if link.mode=="echo"{number("Сила пульсации",value:$link.value)}
    }
    private var boundsControls:some View {HStack(spacing:10){number("От",value:$link.from);number("До",value:$link.to)}}
    @ViewBuilder private var textControls:some View {
        if link.mode=="text"{
            textInput("Текст после действия",text:$link.text)
            if link.alternate==true{textInput("Обратный текст · пусто = исходный",text:Binding(get:{link.reverseText ?? ""},set:{link.reverseText=$0.isEmpty ? nil:$0}))}
        }
    }
    @ViewBuilder private var timingControls:some View {
        if ["animate","echo","bind"].contains(link.mode){
            section("03",title:link.mode=="bind" ? "Отклик":"Анимация"){
                if link.mode != "bind"{
                    number("Длительность · секунды",value:$link.duration)
                    QSlider(value:$link.duration,range:0.05...20)
                    QToggle("Повторять",isOn:$link.repeats)
                }
                LinkCurveEditor(easing:curve,onPreset:{preset in if preset=="addButton"{link.duration=0.8}})
            }
        }
        if link.mode != "bind"{number("Задержка · секунды",value:$link.delay)}
        if link.mode=="bind" && !["drag","valueChanged"].contains(link.event){Text("Выберите изменение значения ползунка или движение пальца для непрерывной связи.").font(qfont(12)).foregroundStyle(q.color("primary"))}
    }
    private var curve:Binding<String>{Binding(get:{link.mode=="bind" ? (link.easing.hasPrefix("mapped:") ? String(link.easing.dropFirst(7)):"linear"):link.easing},set:{link.easing=link.mode=="bind" ? "mapped:"+$0:$0})}
    private var shapeControls:some View {
        VStack(alignment:.leading,spacing:12){
            LinkChoiceField(title:"Конечная форма",selection:Binding(get:{link.shapeID ?? "star-8"},set:{link.shapeID=$0}),items:Catalog.shared.shapes.map{($0.id,$0.name)})
            if let shape=Catalog.shared.shapes.first(where:{$0.id==(link.shapeID ?? "star-8")}){ShapePreview(shape:shape).fill(q.color("primary")).frame(width:72,height:72).frame(maxWidth:.infinity).padding(16).qSurface(22,"surfaceContainerHighest")}
            if layers.first(where:{$0.id==link.targetID})?.kind != "SHAPE"{Text("В качестве цели выберите фигуру MD3, например «Звезда 5».").font(qfont(12)).foregroundStyle(q.color("primary"))}
        }
    }
    private func section<Content:View>(_ step:String,title:String,@ViewBuilder content:()->Content)->some View {
        VStack(alignment:.leading,spacing:12){HStack(spacing:10){Text(step).font(qfont(12,.semibold)).foregroundStyle(q.color("primary")).padding(8).qSurface(12,"primaryContainer");Text(title).font(qfont(17,.semibold))};content()}
    }
    private func number(_ title:String,value:Binding<Double>)->some View {QNumber(title:title,value:Binding(get:{CGFloat(value.wrappedValue)},set:{if $0.isFinite{value.wrappedValue=Double($0)}}))}
    private func textInput(_ title:String,text:Binding<String>)->some View {VStack(alignment:.leading,spacing:7){Text(title).font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"));TextField("Текст",text:text,axis:.vertical).lineLimit(2...6).font(qfont(16))}.padding(16).qSurface(22,"surfaceContainerHighest")}
}
