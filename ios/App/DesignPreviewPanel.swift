import SwiftUI

struct DesignPreviewPanel:View {
    @ObservedObject var editor:Editor
    @Environment(\.dismiss) private var dismiss
    @Environment(\.q) private var q
    @State private var device="canvas"
    @State private var theme="original"
    @State private var compare=false
    @State private var controls=true
    private let devices=[("canvas","Холст"),("320x568","Узкий телефон"),("390x844","iPhone 16e"),("430x932","Большой телефон"),("834x1194","iPad")]
    private var resized:Project {
        if device=="canvas"{return editor.project}
        let values=device.split(separator:"x").compactMap{Double($0)}
        guard values.count==2 else{return editor.project}
        return DesignLayoutEngine.resized(editor.project,width:CGFloat(values[0]),height:CGFloat(values[1]),renderer:editor.renderer)
    }
    var body:some View {
        VStack(spacing:12){
            if controls{HStack{QIconButton(icon:"Back",label:"Назад"){dismiss()};Text("Предпросмотр").font(qfont(23,.semibold));Spacer();Button("Скрыть панели"){controls=false}.font(qfont(13))}.padding(.horizontal,12)}
            GeometryReader{geometry in
                if compare{HStack(spacing:12){preview(dark:false);preview(dark:true)}.frame(width:geometry.size.width,height:geometry.size.height)}
                else{DesignPreviewImage(project:themed,root:editor.store.root).id(device+"-"+theme).frame(width:geometry.size.width,height:geometry.size.height)}
            }.contentShape(Rectangle()).onTapGesture{if !controls{controls=true}}
            if controls{VStack(spacing:12){
                LinkChoiceField(title:"Экран",selection:$device,items:devices)
                QToggle("Светлая и тёмная рядом",isOn:$compare)
                if !compare{LinkChoiceField(title:"Тема",selection:$theme,items:[("original","Как в проекте"),("light","Светлая"),("dark","Тёмная")])}
                Text("Проверка не меняет проект. Коснитесь макета, чтобы вернуть панели.").font(qfont(12)).foregroundStyle(q.color("onSurfaceVariant"))
            }.padding(.horizontal,16)}
        }.padding(.vertical,12).background(q.color("surfaceContainer").ignoresSafeArea())
    }
    private var themed:Project{theme=="original" ? resized:DesignLayoutEngine.themed(resized,dark:theme=="dark",renderer:editor.renderer)}
    private func preview(dark:Bool)->some View {VStack(spacing:6){Text(dark ? "Тёмная":"Светлая").font(qfont(12));DesignPreviewImage(project:DesignLayoutEngine.themed(resized,dark:dark,renderer:editor.renderer),root:editor.store.root).id(device+(dark ? "dark":"light"))}}
}

private struct DesignPreviewImage:View {
    let project:Project
    let root:URL
    @State private var image:UIImage?
    var body:some View {
        Group{if let image{Image(uiImage:image).resizable().scaledToFit()}else{ProgressView()}}
            .task{let scale=min(2,1600/max(project.w,project.h));if let data=DocumentRenderer(root:root).png(project,scale:scale){image=UIImage(data:data)}}
    }
}
