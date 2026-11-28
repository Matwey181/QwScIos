import UIKit

// Visibility changes use the same relative transforms as timeline tracks.
final class LayerAppearanceRuntime {
    struct Transition {var start:Double;var from:Double;var to:Double;var node:Node}
    private var shown:[String:Bool]=[:]
    private var transitions:[String:Transition]=[:]
    var active:Bool{!transitions.isEmpty}
    func reset(){shown=[:];transitions=[:]}
    func frame(_ source:Project,time:Double)->Project{
        var result=source
        result.nodes=source.nodes.map{node in
            defer{shown[node.id]=node.visible}
            if let old=shown[node.id],old != node.visible,node.appear != 0{
                let from=transitions[node.id].map{value($0,time:time,spring:node.appearSpring)} ?? (old ? 1:0)
                transitions[node.id]=Transition(start:time,from:from,to:node.visible ? 1:0,node:node)
            }
            guard let tr=transitions[node.id]else{return node}
            let duration=node.appearSpring==0 ? 0.3:MotionCurve.settle(stiffness(node.appearSpring),damping(node.appearSpring))
            if time-tr.start>=duration{transitions[node.id]=nil;return node}
            let p=value(tr,time:time,spring:node.appearSpring),remaining=CGFloat(1-p)
            var n=node;n.visible=p>0.003;n.opacity*=CGFloat(min(1,max(0,p)))
            if node.kind=="TEXT" && [2,7].contains(node.appear){n.y+=12*remaining;return n}
            switch node.appear {
            case 2,7:
                let s=CGFloat(node.appear==7 ? max(0.01,0.3+0.7*p):max(0,0.5+0.5*p)),cx=n.center.x,cy=n.center.y
                n.w*=s;n.h*=s;n.x=cx-n.w/2;n.y=cy-n.h/2;n.fontSize*=s;n.corner*=s
                if node.appear==7{n.opacity=node.opacity*CGFloat(min(1,max(0,p)*2))}
            case 3:n.y+=48*remaining
            case 4:n.y-=48*remaining
            case 5:n.x+=48*remaining
            case 6:n.x-=48*remaining
            default:break
            }
            return n
        };return result
    }
    private func stiffness(_ spring:Int)->Double{spring==1 ? 800:spring==3 ? 200:380}
    private func damping(_ spring:Int)->Double{spring==1 ? 0.6:0.8}
    private func value(_ tr:Transition,time:Double,spring:Int)->Double{
        let duration=spring==0 ? 0.3:MotionCurve.settle(stiffness(spring),damping(spring))
        let progress=(time-tr.start)/duration
        let p=MotionCurve.at(spring==0 ? MotionCurve.standard:"sp:\(stiffness(spring)),\(damping(spring))",progress)
        return tr.from+(tr.to-tr.from)*p
    }
}
