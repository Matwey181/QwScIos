import SwiftUI

func tr(_ key:String)->String { let language=UserDefaults.standard.string(forKey:"language") ?? "ru";return QwelStrings.maps[language=="en" ? "en":"ru"]?[key] ?? key }
private enum QwelStrings{static let maps:[String:[String:String]]=["ru":load("ru"),"en":load("en")]}
struct SettingsView:View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.q) var q
    @State private var page=""
    @AppStorage("uiStyle") private var uiStyle=0
    @AppStorage("liquidMode") private var liquidMode=0
    @AppStorage("componentScale") private var componentScale=0.0
    @AppStorage("appearance") private var appearance=2
    @AppStorage("glass") private var glass=true
    @AppStorage("accent") private var accent=0
    @AppStorage("accentSeed") private var seed:Int = 0xff006a6a
    @AppStorage("uiFont") private var font="InterSA"
    @AppStorage("language") private var language="ru"
    @AppStorage("hints") private var hints=true
    @AppStorage("pngScale") private var scale=2.0
    @AppStorage("pets") private var pets=0
    @AppStorage("recordEdge") private var recordEdge=1080
    var title:String { ["":"Настройки","look":"Внешний вид и стиль","lang":"Язык","gest":"Жесты и обучение","export":"Экспорт","fun":"Смешнявки","news":"Что нового"][page] ?? "Настройки" }
    var body:some View {
        VStack(spacing:0) {
            QSubHeader(title:title){if page.isEmpty{dismiss()}else{page=""}}
            ScrollView {
                VStack(spacing:12) {
                    switch page {
                    case "look":look
                    case "lang":QSettingsGroup {QSetting("Авто",selected:language=="auto"){language="auto"};QSetting("Русский",selected:language=="ru"){language="ru"};QSetting("English",selected:language=="en"){language="en"}}
                    case "gest":gestures
                    case "export":
                        QSettingsGroup("Масштаб PNG по умолчанию"){ForEach([1.0,2,3,4],id:\.self){n in QSetting("\(Int(n))x",selected:scale==n){scale=n}}}
                        QSettingsGroup("Размер записи режима игры"){ForEach([720,1080,1440,2160],id:\.self){n in QSetting("\(n) px",selected:recordEdge==n){recordEdge=n}}}
                    case "fun":funny
                    case "news":QSettingsGroup("Vexel 2.9.2 · iOS"){Text("Ключевые анимации: 63 шаблона, 45 кривых, пружины и морфинг. Экспорт MP4 и кадров PNG, запись режима игры. Перо с кривыми, отдельные углы, настройки линзы и бликов. iOS 26 Alert и Context Menu, пять новых шаблонов iOS. Независимые привязки и анимации появления слоёв.").font(qfont(16)).padding(20)}
                    default:root
                    }
                }.padding(.horizontal,16).padding(.bottom,24)
            }
        }.background(q.color("surface").ignoresSafeArea())
    }
    private var root:some View {
        Group {
            VStack(spacing:0){QLogo().frame(width:88,height:88);Text("Vexel").font(qfont(28,.semibold)).padding(.top,12);Text("2.9.2 · iOS 0.13").font(qfont(14,.semibold)).foregroundStyle(q.color("onSurfaceVariant"))}.frame(maxWidth:.infinity).padding(.top,8).padding(.bottom,12)
            QSettingsGroup {
                QSetting("Внешний вид и стиль",subtitle:"Тема, акцент, шрифт, стекло",icon:"Style",chevron:true){page="look"}
                QSetting("Язык",icon:"Text",value:language=="en" ? "English":"Русский"){page="lang"}
            }
            QSettingsGroup("Редактор") {
                QSetting("Жесты и обучение",subtitle:"Настройка жестов редактора",icon:"Select",chevron:true){page="gest"}
                QSettingsToggle(title:"Подсказки",subtitle:"Объяснять инструменты по ходу работы",on:$hints)
                QSetting("Масштаб PNG по умолчанию",icon:"Export",value:"\(Int(scale))x"){page="export"}
            }
            QSettingsGroup("Другое") {
                QSetting("Смешнявки",subtitle:"Линус, Столлман, Тукс и манулы",icon:"Shapes",chevron:true){page="fun"}
                QSetting("Что нового",subtitle:"Список изменений последнего обновления",icon:"Shapes",chevron:true){page="news"}
            }
        }
    }
    private var look:some View {
        Group {
            QSettingsGroup("Интерфейс Vexel") {QSetting("Классика",selected:uiStyle==0){uiStyle=0};QSetting("iOS",subtitle:"Синие акценты, сгруппированный фон и системные переключатели",selected:uiStyle==1){uiStyle=1}}
            QSettingsGroup("Жидкое стекло в слоях") {QSetting("Авто",selected:liquidMode==0){liquidMode=0};QSetting("Преломление · Core Image",subtitle:"Искажает фон у края слоя",selected:liquidMode==1){liquidMode=1};QSetting("Упрощённое",subtitle:"Размытие, светлая кромка и блик",selected:liquidMode==2){liquidMode=2}}
            QSettingsGroup("Размер компонентов") {ForEach([0.0,0.75,1,1.25,1.5],id:\.self){value in QSetting(value==0 ? "Авто":"\(Int(value*100))%",selected:componentScale==value){componentScale=value}}}
            QSettingsGroup("Тема приложения") {ForEach(Array(["Как в системе","Светлая","Тёмная","AMOLED","AMOLED светлая"].enumerated()),id:\.offset){i,title in QSetting(title,selected:appearance==i){appearance=i}}}
            QSettingsGroup("Акцент") {
                QSetting("Vexel",selected:accent==0){accent=0}
                QSetting("Свой цвет",selected:accent==2){accent=2}
                if accent==2 {HStack(spacing:10){ForEach(seedColors,id:\.self){c in Circle().fill(Color(argb:c)).frame(width:40,height:40).overlay(Circle().stroke(seed==Int(c) ? q.color("onSurface"):q.color("outline"),lineWidth:seed==Int(c) ? 3:1)).onTapGesture{seed=Int(c)}}}.padding(.horizontal,20).padding(.vertical,14)}
            }
            QSettingsGroup("Шрифт интерфейса") {QSetting("InterSA",selected:font=="InterSA"){font="InterSA"};QSetting("Figtree",selected:font=="Figtree"){font="Figtree"};QSetting("Системный",selected:font.isEmpty){font=""}}
            QSettingsGroup("Интерфейс") {QSettingsToggle(title:"Стеклянные панели",subtitle:"Размывать холст под панелями редактора",on:$glass)}
        }
    }
    private var gestures:some View {
        QSettingsGroup {
            ForEach(["UNDO_TAP","REDO_TAP","DOUBLE_FIT","DOUBLE_LAYER","LONG_EMPTY","LONG_LAYER","PANEL_SWIPE"],id:\.self){id in GestureSetting(id:id)}
        }
    }
    private var funny:some View {
        Group {
            QSettingsGroup("Персонажи") {LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:10){ForEach(["linus","stallman","tux","manul"],id:\.self){id in VStack{if let image=UIImage(named:id){Image(uiImage:image).resizable().scaledToFit().frame(height:120)}else{Text("?").font(qfont(28,.semibold)).frame(height:120)};Text(["linus":"Линус","stallman":"Столлман","tux":"Тукс","manul":"Манул"][id] ?? id).font(qfont(14,.semibold))}.padding(12)}}.padding(12)}
            QSettingsGroup("Манулы на экране") {HStack(spacing:8){ForEach(0...5,id:\.self){n in QChip(title:n==0 ? "Выкл.":"\(n)",selected:pets==n){pets=n}}}.padding(.horizontal,16).padding(.vertical,10)}
        }
    }
}
struct GestureSetting:View {
    var id:String
    @State private var enabled=true
    private var text:(String,String){switch id{case "UNDO_TAP":return("Тап двумя пальцами","Отменить действие");case "REDO_TAP":return("Тап тремя пальцами","Повторить действие");case "DOUBLE_FIT":return("Двойной тап по листу","Вписать лист в экран");case "DOUBLE_LAYER":return("Двойной тап по слою","Открыть текст или стиль");case "LONG_EMPTY":return("Долгое нажатие на листе","Открыть панель добавления");case "LONG_LAYER":return("Долгое нажатие на слое","Открыть стиль");default:return("Свайп по шапке панели","Закрыть панель свайпом вниз")}}
    var body:some View {QSettingsToggle(title:text.0,subtitle:text.1,on:Binding(get:{enabled},set:{enabled=$0;UserDefaults.standard.set($0,forKey:"gesture_"+id)})).onAppear{enabled=(UserDefaults.standard.object(forKey:"gesture_"+id) as? Bool) ?? true}}
}
struct QSettingsGroup<Content:View>:View {
    var title:String?
    var content:Content
    @Environment(\.q) var q
    init(_ title:String?=nil,@ViewBuilder content:()->Content){self.title=title;self.content=content()}
    var body:some View {VStack(alignment:.leading,spacing:0){if let title{Text(title).font(qfont(14,.semibold)).foregroundStyle(q.color("primary")).padding(.leading,20).padding(.top,12).padding(.bottom,8)};VStack(spacing:2){content}.background(q.color("surface")).clipShape(RoundedRectangle(cornerRadius:28))}}
}
struct QSetting:View {
    var title:String
    var subtitle:String?
    var icon:String?
    var value:String?
    var selected:Bool?
    var chevron=false
    var run:()->Void
    @Environment(\.q) var q
    init(_ title:String,subtitle:String?=nil,icon:String?=nil,value:String?=nil,selected:Bool?=nil,chevron:Bool=false,run:@escaping()->Void){self.title=title;self.subtitle=subtitle;self.icon=icon;self.value=value;self.selected=selected;self.chevron=chevron;self.run=run}
    var body:some View {Button(action:run){HStack(spacing:16){if let icon{QIcon(id:icon,tint:q.color("onSurfaceVariant"))};VStack(alignment:.leading,spacing:0){Text(title).font(qfont(16));if let subtitle{Text(subtitle).font(qfont(14)).foregroundStyle(q.color("onSurfaceVariant"))}}.frame(maxWidth:.infinity,alignment:.leading);if let value{Text(value).font(qfont(16)).foregroundStyle(q.color("primary"))};if let selected{Circle().stroke(q.color(selected ? "primary":"onSurfaceVariant"),lineWidth:2).frame(width:20,height:20).overlay{if selected{Circle().fill(q.color("primary")).padding(5)}}};if chevron{QIcon(id:"Back",size:16,tint:q.color("onSurfaceVariant")).rotationEffect(.degrees(180))}}.padding(.horizontal,20).padding(.vertical,12).frame(minHeight:56).frame(maxWidth:.infinity).qSurface(6,"surfaceContainerHigh")}.buttonStyle(.plain)}
}
struct QSettingsToggle:View {
    var title:String
    var subtitle:String?
    @Binding var on:Bool
    @Environment(\.q) var q
    var body:some View {HStack{VStack(alignment:.leading,spacing:0){Text(title).font(qfont(16));if let subtitle{Text(subtitle).font(qfont(14)).foregroundStyle(q.color("onSurfaceVariant"))}}.frame(maxWidth:.infinity,alignment:.leading);QSwitch(on:$on)}.padding(.horizontal,20).padding(.vertical,12).frame(minHeight:56).qSurface(6,"surfaceContainerHigh")}
}
