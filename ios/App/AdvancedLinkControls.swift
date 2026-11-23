import SwiftUI
import UniformTypeIdentifiers

struct AdvancedLinkControls:View {
    @Binding var link:InteractionLink
    let layers:[Node]
    var root:URL
    @State private var importing=false
    @State private var importError=""
    @State private var selectedPoint:String?
    @State private var percent:CGFloat=25
    @Environment(\.q) private var q
    private var options:AdvancedLinkOptions{link.advanced ?? AdvancedLinkOptions()}
    private func flag(_ key:WritableKeyPath<AdvancedLinkOptions,Bool>)->Binding<Bool>{Binding(get:{options[keyPath:key]},set:{v in change{$0[keyPath:key]=v}})}
    private func text(_ key:WritableKeyPath<AdvancedLinkOptions,String>)->Binding<String>{Binding(get:{options[keyPath:key]},set:{v in change{$0[keyPath:key]=v}})}
    private func number(_ key:WritableKeyPath<AdvancedLinkOptions,Double>)->Binding<CGFloat>{Binding(get:{CGFloat(options[keyPath:key])},set:{v in change{$0[keyPath:key]=Double(v)}})}
    private func integer(_ key:WritableKeyPath<AdvancedLinkOptions,Int>)->Binding<CGFloat>{Binding(get:{CGFloat(options[keyPath:key])},set:{v in change{$0[keyPath:key]=max(0,Int(v))}})}
    private var choices:[(String,String)]{[("","Не выбран")]+layers.map{($0.id,$0.name)}}
    var body:some View{VStack(alignment:.leading,spacing:14){
        if ["multiMorph","typewriter"].contains(link.mode){QNumber(title:"Длительность · с",value:Binding(get:{CGFloat(link.duration)},set:{link.duration=max(0.01,Double($0))}))}
        QToggle("Один раз за просмотр",isOn:flag(\.once))
        if link.repeats{QNumber(title:"Пауза между повторами · с",value:number(\.repeatGap))}
        if link.event=="holdRepeat"{QNumber(title:"Интервал удержания · с",value:number(\.holdInterval))}
        if link.event=="nthTap"{QNumber(title:"Количество нажатий",value:integer(\.tapCount))}
        if link.event=="stepTap"{QNumber(title:"Номер нажатия",value:integer(\.tapStep));QNumber(title:"Длина цикла",value:integer(\.tapCount))}
        if ["enterArea","exitArea","collision"].contains(link.event){LinkChoiceField(title:"Область / второй объект",selection:text(\.areaID),items:choices)}
        if link.mode=="thresholds"{checkpointControls}
        if link.mode=="multiMorph"{selection("Исходные объекты",key:\.sourceIDs);selection("Конечные объекты",key:\.targetIDs);Text("Выберите конечные объекты на холсте заранее. Их расположение задаёт результат превращения.").font(qfont(12))}
        if link.mode=="moveObject"{LinkChoiceField(title:"Разрешённое направление",selection:text(\.axis),items:[("both","Свободно"),("x","Горизонтально"),("y","Вертикально")]);LinkChoiceField(title:"Границы движения",selection:text(\.areaID),items:choices)}
        if link.mode=="imageSwap" || link.mode=="sound"{QTextField(title:"Файл ресурса",text:text(\.asset));LinkPill(title:link.mode=="sound" ? "Выбрать звук":"Выбрать картинку",icon:"folder"){importing=true}}
        if link.mode=="iconSwap"{LinkChoiceField(title:"Новый значок",selection:text(\.icon),items:QIcon.icons.keys.sorted().map{($0,$0)})}
        if ["numberAdd","numberSubtract"].contains(link.mode){QNumber(title:"Шаг",value:Binding(get:{CGFloat(link.value)},set:{link.value=Double($0)}))}
        if ["textLimit","keyboard","validate"].contains(link.mode){QNumber(title:"Максимум символов",value:integer(\.maxLength));LinkChoiceField(title:"Формат ввода",selection:text(\.validation),items:[("any","Любой текст"),("email","Электронная почта"),("number","Число"),("phone","Телефон")])}
        if ["formatNumber","sum","numberAdd","numberSubtract"].contains(link.mode){LinkChoiceField(title:"Формат результата",selection:text(\.format),items:[("number","Число"),("currency","Валюта"),("percent","Проценты")]);QNumber(title:"Знаков после запятой",value:integer(\.decimals));QTextField(title:"Перед числом",text:text(\.prefix));QTextField(title:"После числа / единицы",text:text(\.suffix))}
        if link.mode=="sum"{selection("Слои со значениями",key:\.sourceIDs)}
        if link.mode=="stateText"{QTextField(title:"Когда выбран",text:$link.text);QTextField(title:"Когда выключен",text:Binding(get:{link.reverseText ?? ""},set:{link.reverseText=$0}))}
        if link.mode=="typewriter"{QTextField(title:"Полный текст",text:$link.text)}
        if link.mode=="stopLink"{LinkChoiceField(title:"Остановить реакцию",selection:text(\.stopID),items:stopChoices)}
        if link.mode=="followSize"{LinkChoiceField(title:"Следовать за слоем",selection:text(\.otherID),items:choices);QNumber(title:"Отступ вокруг",value:number(\.padding))}
    }.fileImporter(isPresented:$importing,allowedContentTypes:link.mode=="sound" ? [.audio]:[.image]){result in do{let url=try result.get();let access=url.startAccessingSecurityScopedResource();defer{if access{url.stopAccessingSecurityScopedResource()}};let name=UUID().uuidString+"."+url.pathExtension;try FileManager.default.createDirectory(at:root.appendingPathComponent("assets"),withIntermediateDirectories:true);try FileManager.default.copyItem(at:url,to:root.appendingPathComponent("assets").appendingPathComponent(name));change{$0.asset=name}}catch{importError=error.localizedDescription}}.alert("Не удалось добавить файл",isPresented:Binding(get:{!importError.isEmpty},set:{if !$0{importError=""}})){Button("Понятно"){importError=""}}message:{Text(importError)}}
    var stopChoices:[(String,String)]=[]
    private func change(_ block:(inout AdvancedLinkOptions)->Void){var x=options;block(&x);link.advanced=x}
    private func selection(_ title:String,key:WritableKeyPath<AdvancedLinkOptions,[String]>)->some View{InlineSection(title:title){ForEach(layers){node in Button{change{x in if x[keyPath:key].contains(node.id){x[keyPath:key].removeAll{$0==node.id}}else{x[keyPath:key].append(node.id)}}}label:{HStack{Image(systemName:options[keyPath:key].contains(node.id) ? "checkmark.circle.fill":"circle");Text(node.name).font(qfont(14));Spacer()}}.buttonStyle(.plain)}}}
    private var checkpointControls:some View{VStack(spacing:12){
        Text("Нажмите на полоску, чтобы поставить порог. Состояние включается, когда ползунок проходит эту отметку.").font(qfont(12))
        GeometryReader{g in ZStack(alignment:.leading){Capsule().fill(q.color("primaryContainer")).frame(height:12);ForEach(options.checkpoints){point in Circle().fill(q.color(point.id==selectedPoint ? "primary":"outline")).frame(width:18,height:18).position(x:g.size.width*point.percent/100,y:24)}}.contentShape(Rectangle()).gesture(DragGesture(minimumDistance:0).onEnded{v in add(min(100,max(0,Double(v.location.x/g.size.width)*100)))})}.frame(height:48)
        HStack{QNumber(title:"Процент",value:$percent);Button("Добавить"){add(Double(percent))}}
        ForEach(options.checkpoints.sorted{$0.percent<$1.percent}){point in VStack(spacing:8){HStack{QNumber(title:"Порог %",value:Binding(get:{CGFloat(point.percent)},set:{v in update(point.id){$0.percent=min(100,max(0,Double(v)))}}));Button(role:.destructive){change{$0.checkpoints.removeAll{$0.id==point.id}}}label:{Image(systemName:"trash")}};LinkChoiceField(title:"Форма после порога",selection:Binding(get:{point.shapeID},set:{shape in update(point.id){$0.shapeID=shape}}),items:Catalog.shared.shapes.map{($0.id,$0.name)})}}
        QToggle("Показывать отметки на холсте",isOn:flag(\.showMarkers))
        if options.showMarkers{QToggle("Вертикальная полоска",isOn:flag(\.showMarkerBar));QToggle("Форма над полоской",isOn:flag(\.showMarkerShape));QColorRow(title:"Цвет отметок",color:Binding(get:{options.markerColor},set:{v in change{$0.markerColor=v}}),colors:[]);QNumber(title:"Масштаб",value:number(\.markerScale));HStack{QNumber(title:"Ширина полоски",value:number(\.markerWidth));QNumber(title:"Высота полоски",value:number(\.markerHeight))};QNumber(title:"Размер формы",value:number(\.markerShapeSize))}
    }}
    private func add(_ percent:Double){var point=SliderCheckpoint();point.percent=percent;selectedPoint=point.id;change{$0.checkpoints.append(point)}}
    private func update(_ id:String,_ block:(inout SliderCheckpoint)->Void){change{x in if let i=x.checkpoints.firstIndex(where:{$0.id==id}){block(&x.checkpoints[i])}}}
}
