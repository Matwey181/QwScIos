import SwiftUI

struct NewProjectView:View {
    @EnvironmentObject var store:ProjectStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.q) var q
    var created:(Project)->Void
    @State private var name="Новый проект"
    @State private var width="360"
    @State private var height="800"
    @State private var template=""
    @State private var seed:Int64 = -16749974
    @State private var dark=false
    private var tone:Tone { ToneGenerator.scheme(seed:seed,dark:dark) }
    var body:some View {
        VStack(spacing:0) {
            QSubHeader(title:"Новый проект"){dismiss()}
            ScrollView {
                VStack(alignment:.leading,spacing:14) {
                    QTextField(title:"Название",text:$name).accessibilityIdentifier("projectName")
                    Text("Шаблон - берите готовое и меняйте под себя").font(qfont(14,.semibold)).foregroundStyle(q.color("primary"))
                    ScrollView(.horizontal,showsIndicators:false) { HStack(spacing:10){templateTile(nil);ForEach(Catalog.shared.templates){templateTile($0)}} }
                    if template.isEmpty {
                        Text("Размер холста (dp)").font(qfont(14,.semibold)).foregroundStyle(q.color("primary"))
                        ScrollView(.horizontal,showsIndicators:false) { HStack(spacing:8) { ForEach(["Телефон 360x800","Компактный 360x640","Планшет 834x1194","Квадрат 512x512","Компьютер 1280x800"],id:\.self) { preset in
                            QChip(title:preset,selected:preset.hasSuffix(width+"x"+height)){let parts=preset.split(separator:" ").last!.split(separator:"x");width=String(parts[0]);height=String(parts[1])}.fixedSize()
                        } } }
                        HStack(spacing:12) { QTextField(title:"Ширина",text:$width).keyboardType(.decimalPad);QTextField(title:"Высота",text:$height).keyboardType(.decimalPad) }
                    } else if let item=Catalog.shared.templates.first(where:{$0.id==template}) { Text(item.category).font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant")) }
                    Text("Тон проекта").font(qfont(14,.semibold)).foregroundStyle(q.color("primary"))
                    ScrollView(.horizontal,showsIndicators:false) { HStack(spacing:8) { QChip(title:"Базовая",selected:seed == -16749974){seed = -16749974}.fixedSize();ForEach(seedColors,id:\.self){color in Circle().fill(Color(argb:color)).frame(width:36,height:36).overlay(Circle().stroke(seed==color ? q.color("onSurface"):q.color("outlineVariant"),lineWidth:seed==color ? 3:1)).onTapGesture{seed=color}} } }
                    HStack{Text("Тёмная схема").font(qfont(16));Spacer();QSwitch(on:$dark)}.padding(.top,8)
                    HStack(spacing:6){ForEach([0,2,5,7,12,16,17],id:\.self){i in Circle().fill(Color(argb:tone.colors[i])).frame(width:26,height:26).overlay(Circle().stroke(q.color("outlineVariant"),lineWidth:1))}}.padding(.top,8)
                    Button(action:create) { Text("Создать").font(qfont(14,.semibold)).foregroundStyle(q.color("onPrimary")).frame(maxWidth:.infinity).frame(height:56).background(q.color("primary"),in:Capsule()) }.buttonStyle(QPressStyle()).accessibilityIdentifier("createProject")
                }.padding(.horizontal,24).padding(.bottom,24)
            }
        }.background(q.color("surface").ignoresSafeArea())
    }
    private func templateTile(_ item:CatalogItem?)->some View {
        let id=item?.id ?? ""
        return Button {
            template=id
            name=item?.name ?? "Новый проект"
        } label: {
            VStack(spacing:8) {
                Group {
                    if let item {
                        // Keep the Android source template aspect ratio; do not
                        // squeeze a portrait 360x800 design into a square tile.
                        ProjectThumbnail(project:AppleCatalog.variant(item,dark:dark).project,root:store.root,inset:3)
                    } else {
                        Rectangle().fill(Color.white).padding(3)
                    }
                }
                .frame(width:98,height:150)
                .qSurface(12,"surfaceContainerHighest")
                .clipped()
                Text(item?.name ?? "Пустой")
                    .font(qfont(12,.medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width:110,height:32)
            }
            .padding(8)
            .frame(width:122)
            .qSurface(20)
            .overlay {
                RoundedRectangle(cornerRadius:20)
                    .stroke(template==id ? q.color("primary"):q.color("outlineVariant"),
                            lineWidth:template==id ? 3:1)
            }
        }
        .buttonStyle(QPressStyle())
    }
    private func create() {
        do {
            var source=Catalog.shared.templates.first{$0.id==template}.map{AppleCatalog.variant($0,dark:dark).project}
            if source != nil { source!.tone=tone;source!.bg=tone.colors[12];source!.nodes=source!.nodes.map { n in var n=n;if tone.colors.indices.contains(Int(n.fillToken)){n.fill=tone.colors[Int(n.fillToken)]};if tone.colors.indices.contains(Int(n.strokeToken)){n.stroke=tone.colors[Int(n.strokeToken)]};return n } }
            var p=try store.create(name:name,width:CGFloat(min(4096,max(16,Double(width) ?? 360))),height:CGFloat(min(4096,max(16,Double(height) ?? 800))),template:source)
            p.tone=tone;p.bgToken=template=="ios" ? -1:12;p.bg=template=="ios" ? (dark ? -16777216:-855305):tone.colors[12];try store.save(p);created(p)
        } catch { store.error=error.localizedDescription }
    }
}
let seedColors:[Int64]=[0xff006a6a,0xff6750a4,0xff386a20,0xff0061a4,0xff984061,0xff855318,0xffc04b00,0xff4c6267].map{Int64(Int32(bitPattern:UInt32($0)))}
