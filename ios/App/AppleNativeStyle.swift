import UIKit

/// Editable iOS-inspired presets. They use the public system font and SF
/// Symbols on iOS 17/18; liquid surfaces are rendered by the cached canvas.
enum AppleNativeStyle {
    static func make(_ item:CatalogItem)->CatalogItem {
        if item.id=="ios"{return template(item)}
        var result=item
        let dark=item.project.tone.dark
        let ink:Int64=dark ? 0xffffffff:0xff000000
        let secondary:Int64=dark ? 0xff98989f:0xff6c6c70
        let blue:Int64=dark ? 0xff0a84ff:0xff007aff
        let card:Int64=dark ? 0xff1c1c1e:0xffffffff
        let track:Int64=dark ? 0xff39393d:0xffe5e5ea
        let hairline:Int64=dark ? 0x33545458:0x243c3c43
        let milk:Int64=dark ? 0xb82b2b2e:0xb8ffffff
        var nodes:[Node]=[]
        func box(_ name:String,_ x:CGFloat,_ y:CGFloat,_ w:CGFloat,_ h:CGFloat,_ radius:CGFloat,_ fill:Int64,liquid:CGFloat=0,blur:CGFloat=0)->Node {
            var n=Node();n.name=name;n.x=x;n.y=y;n.w=w;n.h=h;n.corner=radius;n.fill=fill;n.liquid=liquid;n.blur=blur;n.group="apple"
            if liquid>0{n.shadowBlur=8;n.shadowDy=3;n.shadowColor=dark ? 0x33000000:0x16000000;n.stroke=dark ? 0x22ffffff:0x30ffffff;n.strokeWidth=0.5}
            return n
        }
        func label(_ text:String,_ x:CGFloat,_ y:CGFloat,_ width:CGFloat,_ size:CGFloat,_ weight:Int64=400,_ color:Int64?=nil,_ align:String="left",height:CGFloat?=nil)->Node {
            var n=Node();n.kind="TEXT";n.name=text;n.text=text;n.x=x;n.y=y;n.w=width;n.h=height ?? ceil(size*1.3);n.font="";n.fontSize=size;n.weight=weight;n.fill=color ?? ink;n.textAlign=align;n.fixW=true;n.group="apple"
            var extras=LayerExtras();extras.appleTextPrepared=true;extras.hugHeight=false;n.extras=extras
            return n
        }
        func symbol(_ name:String,_ x:CGFloat,_ y:CGFloat,_ size:CGFloat,_ color:Int64?=nil,_ weight:Int64=400)->Node {
            var n=Node();n.kind="IMAGE";n.name=name;n.asset="sf:"+name;n.x=x;n.y=y;n.w=size;n.h=size;n.fill=color ?? ink;n.weight=weight;n.group="apple"
            var extras=LayerExtras();extras.imageMode="fit";n.extras=extras;return n
        }
        func toggle(_ x:CGFloat,_ y:CGFloat,_ on:Bool){
            var rail=box("Дорожка",x,y,64,28,14,on ? 0xff34c759:track)
            rail.widget="switch:itrack/\(UInt32(truncatingIfNeeded:track))/4281648985"
            var thumb=box("Бегунок",x+(on ? 22:2),y+2,40,24,12,dark ? 0xb8ffffff:0xd9ffffff,liquid:0.72,blur:1)
            thumb.widget="switch:ithumb/0/0";thumb.shadowBlur=3;thumb.shadowDy=1
            nodes += [rail,thumb]
        }
        func dialog(_ width:CGFloat,_ height:CGFloat,_ radius:CGFloat){
            nodes.append(box("Стеклянная плашка",0,0,width,height,radius,milk,liquid:0.5,blur:12))
        }
        switch item.id {
        case "ios26-alert":
            result.project.w=300;result.project.h=306
            nodes=[box("Окно",0,0,300,306,38,dark ? 0xff2a2a2c:0xfffafafa),label(tr("comp_alert_title"),24,31,252,18,700),label(tr("comp_alert_msg1"),24,72,252,16),label(tr("comp_alert_msg2"),24,94,252,16)]
            for (i,title) in [tr("comp_default"),tr("comp_destructive"),tr("cancel")].enumerated(){
                let y=CGFloat(138+i*56),fill=i==0 ? blue:(dark ? Int64(0xff3a3a3c):Int64(0xffe3e3e3))
                nodes += [box(title,12,y,276,48,24,fill),label(title,24,y+13,252,17,600,i==0 ? 0xffffffff:i==1 ? 0xffff3b30:ink,"center")]
            }
        case "ios26-menu":
            result.project.w=250;result.project.h=612
            nodes=[box("Контекстное меню",0,0,250,612,30,dark ? 0xe62c2c2e:0xe6ebebeb,liquid:0.65,blur:12),box("Быстрое действие",10,11,72,58,16,dark ? 0x26ffffff:0x1a000000)]
            for i in 0..<3{let x=CGFloat(46+i*79);nodes += [symbol("star",x-11,17,22,i==2 ? 0xffff3b30:ink),label(i==2 ? tr("comp_destructive_short"):tr("comp_label"),x-35,48,70,11,500,i==2 ? 0xffff3b30:ink,"center")]}
            for y in [CGFloat(80),251,315,516]{nodes.append(box("Разделитель",17,y,216,0.5,0,hairline))}
            for (y,title,shortcut,disabled,destructive) in [(CGFloat(112),tr("comp_label"),"⌘ A",false,false),(155,tr("comp_disabled"),"⌘ B",true,false),(207,tr("comp_destructive_action"),"⌘ C",false,true),(283,tr("comp_action"),"",false,false),(580,tr("comp_action"),"⌘ Y",false,false)]{
                let color=destructive ? Int64(0xffff3b30):disabled ? secondary:ink
                var text=label(title,23,y-10,160,16,400,color);if disabled{var e=text.extras ?? LayerExtras();e.disabled=true;text.extras=e}
                nodes += [text,label(shortcut,192,y-10,38,14,400,secondary,"right")]
            }
            for y in [CGFloat(338),539]{nodes.append(label(tr("comp_section"),23,y-8,204,12,400,secondary))}
            for (y,title) in [(CGFloat(378),tr("comp_submenu")),(420,tr("comp_submenu")),(473,tr("comp_submenu_long"))]{nodes += [label(title,23,y-10,185,16),symbol("chevron.right",222,y-6,12,secondary)]}
        case "ios-btn-filled","ios-btn-tinted","ios-btn-plain","ios-btn-glass":
            let captionWidth=ceil(("Продолжить" as NSString).size(withAttributes:[.font:UIFont.systemFont(ofSize:17,weight:.semibold)]).width)+32
            let width=max(item.id=="ios-btn-plain" ? CGFloat(120):CGFloat(200),captionWidth)
            result.project.w=width;result.project.h=50
            if item.id != "ios-btn-plain"{
                let fill=item.id=="ios-btn-filled" ? blue:item.id=="ios-btn-tinted" ? (dark ? 0x330a84ff:0x1f007aff):(dark ? 0x242c2c2e:0x26ffffff)
                nodes.append(box("Кнопка",0,0,width,50,25,fill,liquid:item.id=="ios-btn-glass" ? 0.8:0,blur:item.id=="ios-btn-glass" ? 4:0))
            }
            nodes.append(label("Продолжить",12,14,width-24,17,600,item.id=="ios-btn-filled" ? 0xffffffff:blue,"center"))
        case "ios-btn-glass-icon":
            result.project.w=50;result.project.h=50
            nodes=[box("Кнопка",0,0,50,50,25,dark ? 0x332c2c2e:0x33ffffff,liquid:0.8,blur:4),symbol("plus",15,15,20,ink,500)]
        case "ios-switch-on","ios-switch-off":
            result.project.w=64;result.project.h=28;toggle(0,0,item.id=="ios-switch-on")
        case "ios-list-switch":
            result.project.w=343;result.project.h=56
            nodes=[box("Строка",0,0,343,56,18,card),label("Авиарежим",16,17,230,17)]
            toggle(263,14,true)
        case "ios-segmented":
            result.project.w=280;result.project.h=36
            nodes=[box("Сегменты",0,0,280,36,18,dark ? 0x33767680:0x1f767680)]
            var indicator=box("Выбранный сегмент",2,2,89.33,32,16,dark ? 0x555e5e62:0xb8ffffff,liquid:0.4,blur:2);indicator.widget="pick:ind";indicator.shadowBlur=3;indicator.shadowDy=1;nodes.append(indicator)
            for (i,title) in ["День","Неделя","Месяц"].enumerated(){
                var n=label(title,CGFloat(i)*93.333,9,93.333,13,600,ink,"center")
                n.widget="pick:i\(i)/\(UInt32(truncatingIfNeeded:ink))/\(UInt32(truncatingIfNeeded:secondary))";nodes.append(n)
            }
        case "ios-slider":
            result.project.w=332;result.project.h=32
            var rail=box("Дорожка",16,14,300,4,2,track);rail.widget="slider:track"
            var active=box("Заполнение",16,14,150,4,2,blue);active.widget="slider:active"
            var thumb=box("Бегунок",150,4,32,24,12,dark ? 0xcfffffff:0xe6ffffff,liquid:0.7,blur:2);thumb.widget="slider:thumb";thumb.shadowBlur=3;thumb.shadowDy=1
            nodes=[rail,active,thumb]
        case "ios-search":
            result.project.w=343;result.project.h=44
            nodes=[box("Поиск",0,0,343,44,22,dark ? 0x33767680:0x1f767680),symbol("magnifyingglass",14,13,18,secondary),label("Поиск",42,11,254,17,400,secondary),symbol("mic.fill",312,14,16,secondary)]
        case "ios-section-header":
            result.project.w=343;result.project.h=28
            nodes=[label("РАЗДЕЛ",16,6,311,13,400,secondary)]
        case "ios-section-footer":
            result.project.w=343;result.project.h=48
            nodes=[label("Дополнительная информация\nо выбранной настройке.",16,8,311,13,400,secondary,height:36)]
        case "ios-alert":
            result.project.w=300;result.project.h=202;dialog(300,202,30)
            nodes += [label("Заголовок",20,25,260,17,600,ink,"center"),label("Сообщение с пояснением\nвыбранного действия.",20,57,260,13,400,ink,"center",height:40)]
            nodes += [box("Отмена",16,142,128,44,22,dark ? 0x26ffffff:0x10000000),box("ОК",156,142,128,44,22,blue),label("Отмена",24,153,112,17,500,ink,"center"),label("ОК",164,153,112,17,600,0xffffffff,"center")]
        case "ios-action-sheet":
            result.project.w=358;result.project.h=226;dialog(358,164,28)
            nodes += [label("Выберите действие",18,18,322,13,600,secondary,"center"),box("Разделитель",0,50,358,0.5,0,hairline),label("Изменить",16,67,326,20,400,blue,"center"),box("Разделитель",0,106,358,0.5,0,hairline),label("Удалить",16,122,326,20,400,0xffff3b30,"center"),box("Отмена",0,176,358,50,25,milk,liquid:0.5,blur:12),label("Отмена",16,188,326,20,600,blue,"center")]
        case "ios-sheet":
            result.project.w=390;result.project.h=300;dialog(390,300,32)
            nodes += [box("Индикатор",177,8,36,5,2.5,dark ? 0xff636366:0xffc7c7cc),label("Заголовок",24,35,342,20,600),label("Добавьте содержимое вашей плашки.",24,77,342,15,400,secondary),box("Готово",24,226,342,50,25,blue),label("Готово",40,240,310,17,600,0xffffffff,"center")]
        case "ios-nav-bar","ios-nav-large":
            let large=item.id=="ios-nav-large"
            result.project.w=375;result.project.h=large ? 140:64
            nodes=[box("Назад",16,10,44,44,22,dark ? 0x332c2c2e:0x38ffffff,liquid:0.75,blur:4),symbol("chevron.left",29,23,18,blue,500)]
            if large{nodes.append(label("Заголовок",20,85,335,34,700))}
            else{nodes.append(label("Заголовок",72,21,231,17,600,ink,"center"))}
        case "ios-tab-bar":
            result.project.w=358;result.project.h=76
            nodes=[box("Плавающая панель",0,0,358,76,38,dark ? 0x80232326:0x80ffffff,liquid:0.7,blur:8)]
            var indicator=box("Выбранная вкладка",6,8,80.5,60,30,dark ? 0x33ffffff:0x80ffffff,liquid:0.35,blur:2);indicator.widget="pick:ind";indicator.shadowBlur=0;nodes.append(indicator)
            let tabs=[("house.fill","Главная"),("magnifyingglass","Поиск"),("square.stack.fill","Медиатека"),("person.crop.circle","Профиль")]
            for (i,tab) in tabs.enumerated(){
                let x=CGFloat(i)*87+5
                let role="pick:i\(i)/\(UInt32(truncatingIfNeeded:blue))/\(UInt32(truncatingIfNeeded:secondary))"
                var icon=symbol(tab.0,x+32,18,23,i==0 ? blue:secondary,500);icon.widget=role
                var text=label(tab.1,x,47,87,11,500,i==0 ? blue:secondary,"center");text.widget=role
                nodes += [icon,text]
            }
        case "ios-list-group":
            result.project.w=343;result.project.h=156
            nodes=[box("Группа",0,0,343,156,18,card)]
            let rows=[("wifi","Wi-Fi","Дом"),("antenna.radiowaves.left.and.right","Bluetooth","Вкл."),("bell.badge.fill","Уведомления","")]
            for (i,row) in rows.enumerated(){
                let y=CGFloat(i)*52
                nodes += [symbol(row.0,16,y+16,22,blue),label(row.1,52,y+15,195,17),label(row.2,241,y+15,66,17,400,secondary,"right"),symbol("chevron.right",316,y+20,12,secondary)]
                if i<2{nodes.append(box("Разделитель",52,y+51.5,291,0.5,0,hairline))}
            }
        default:
            nodes=item.project.nodes
            for i in nodes.indices{
                if nodes[i].kind=="TEXT"{
                    if ["search","dialog_text","message","cancel","ok"].contains(nodes[i].text){nodes[i].text=tr(nodes[i].text)}
                    let old=nodes[i],center=old.center
                    nodes[i].font="";nodes[i].fixW=true
                    let weight:UIFont.Weight=old.weight>=700 ? .bold:old.weight>=600 ? .semibold:old.weight>=500 ? .medium:old.weight<=300 ? .light:.regular
                    let font=UIFont.systemFont(ofSize:old.fontSize,weight:weight)
                    nodes[i].w=ceil((old.text as NSString).size(withAttributes:[.font:font]).width)+2
                    nodes[i].h=ceil(old.fontSize*1.3)
                    if ["ios-app-icon"].contains(item.id){nodes[i].x=center.x-nodes[i].w/2}
                    var x=nodes[i].extras ?? LayerExtras();x.appleTextPrepared=true;x.hugHeight=false;nodes[i].extras=x
                }
                if ["ios-card-stat","ios-widget"].contains(item.id){nodes[i].liquid=0;nodes[i].blur=0;nodes[i].shadowBlur=0}
            }
        }
        for i in nodes.indices{
            nodes[i].id=item.id+"-native-\(i)";nodes[i].group="apple"
            if nodes[i].kind=="TEXT"{nodes[i].font="";var x=nodes[i].extras ?? LayerExtras();x.appleTextPrepared=true;x.hugHeight=false;nodes[i].extras=x}
            nodes[i].fillToken = -1;nodes[i].strokeToken = -1
        }
        result.project.nodes=nodes;result.project.links=[];result.project.pages=[]
        if ["ios-alert","ios-sheet","ios26-alert","ios26-menu"].contains(item.id){
            for button in nodes where button.kind=="RECT" && (item.id=="ios26-alert" ? button.h==48:["ОК","Отмена","Готово"].contains(button.name)){
                for (event,scale,opacity) in [("press",0.97,0.8),("release",1.0,1.0)]{
                    for (property,value) in [("scale",scale),("opacity",opacity)]{
                        var link=InteractionLink();link.id=button.id+"-"+event+"-"+property
                        link.sourceID=button.id;link.targetID=button.id;link.event=event;link.mode="animate";link.property=property;link.value=value;link.duration=0.16;link.easing="easeOut";link.exactSource=true
                        result.project.links.append(link)
                    }
                }
            }
        }
        result.project.bg=dark ? 0xff000000:0xfff2f2f7
        return result
    }

    private static func template(_ item:CatalogItem)->CatalogItem {
        var result=item,p=item.project
        let dark=p.tone.dark,raw=dark ? AppleCatalog.bundle.dark:AppleCatalog.bundle.light
        p.w=390;p.h=844;p.bg=dark ? 0xff000000:0xfff2f2f7;p.nodes=[];p.pages=[];p.links=[]
        func add(_ id:String,_ x:CGFloat,_ y:CGFloat){
            guard let source=raw.first(where:{$0.id==id}) else{return}
            let component=make(source)
            p.nodes += component.project.nodes.enumerated().map{i,node in var n=node;n.id="native-template-\(id)-\(i)";n.x+=x;n.y+=y;n.group="native-template~"+id;return n}
        }
        add("ios-nav-large",7,0)
        if let i=p.nodes.firstIndex(where:{$0.kind=="TEXT"}){p.nodes[i].text="Настройки"}
        add("ios-search",23.5,150)
        add("ios-section-header",7,214)
        add("ios-list-group",23.5,250)
        add("ios-list-switch",23.5,426)
        add("ios-section-footer",7,492)
        add("ios-btn-filled",95,586)
        add("ios-tab-bar",16,744)
        result.project=p;return result
    }
}
