import SwiftUI

struct UpdateLayerControls:View {
    @ObservedObject var editor:Editor
    let node:Node
    var body:some View {
        VStack(alignment:.leading,spacing:12){
            if node.kind=="RECT" {
                QToggle("Каждый угол отдельно",isOn:Binding(get:{node.cornerRadii != nil},set:{on in editor.change{$0.cornerRadii=on ? Array(repeating:$0.corner,count:4):nil}}))
                if let corners=node.cornerRadii,corners.count==4{
                    HStack{corner(0,"Слева сверху");corner(1,"Справа сверху")}
                    HStack{corner(3,"Слева снизу");corner(2,"Справа снизу")}
                }
            }
            LinkChoiceField(title:"Появление при смене видимости",selection:Binding(get:{String(node.appear)},set:{v in editor.change{$0.appear=Int(v) ?? 0}}),items:[("0","Без анимации"),("1","Плавное появление"),("2","Масштаб"),("3","Снизу"),("4","Сверху"),("5","Справа"),("6","Слева"),("7","Pop")])
            if node.appear != 0 {
                LinkChoiceField(title:"Движение",selection:Binding(get:{String(node.appearSpring)},set:{v in editor.change{$0.appearSpring=Int(v) ?? 2}}),items:[("0","Плавное"),("1","Expressive Fast"),("2","Expressive Default"),("3","Expressive Slow")])
            }
        }
    }
    private func corner(_ index:Int,_ title:String)->some View{
        QNumber(title:title,value:Binding(get:{max(0,node.cornerRadii?[index] ?? node.corner)},set:{v in editor.change{n in var c=n.cornerRadii ?? Array(repeating:n.corner,count:4);c[index]=max(0,v);n.cornerRadii=c}}))
    }
}
