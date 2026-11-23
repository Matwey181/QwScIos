import Foundation
import QuartzCore

@MainActor final class PlaybackRuntime {
    struct Track {
        var rule:InteractionLink
        var group:String
        var position:Double
        var last:Double
        var running:Bool
        var scrubbing=false
    }
    private var tracks:[String:Track]=[:]
    var onProgress:((String,Double)->Void)?
    var onText:((String,String)->Void)?
    var active:Bool {tracks.values.contains{$0.running && !$0.scrubbing}}
    func start(_ project:Project,values:[String:Double]) {
        tracks=[:]
        let now=CACurrentMediaTime()
        for rule in project.links where rule.enabled && rule.mode=="playback" {
            guard let node=project.nodes.first(where:{$0.id==rule.targetID}) else{continue}
            let position=min(1,max(0,values[node.group] ?? 0))
            let track=Track(rule:rule,group:node.group,position:position,last:now,running:rule.autoplay ?? false)
            tracks[rule.id]=track;publish(track)
        }
    }
    func stop(){tracks=[:]}
    func toggle(_ id:String,forcePlay:Bool=false) {
        guard var track=tracks[id] else{return}
        if track.position>=1{track.position=0}
        track.running=forcePlay ? true:!track.running;track.last=CACurrentMediaTime();tracks[id]=track;publish(track)
    }
    func control(target:String,group:String,action:String){
        for id in Array(tracks.keys){
            guard var track=tracks[id],track.rule.targetID==target || (!group.isEmpty && track.group==group) else{continue}
            switch action{case "pause":track.running=false;case "stop":track.running=false;track.position=0;case "restart":track.position=0;track.running=true;case "play":if track.position>=1{track.position=0};track.running=true;default:track.running.toggle()}
            track.last=CACurrentMediaTime();tracks[id]=track;publish(track)
        }
    }
    func seek(group:String,value:Double) {
        for id in Array(tracks.keys) {
            guard var track=tracks[id],track.group==group else{continue}
            track.position=min(1,max(0,value));track.last=CACurrentMediaTime();tracks[id]=track;publish(track)
        }
    }
    func scrub(group:String,_ enabled:Bool) {
        for id in Array(tracks.keys) where tracks[id]?.group==group {
            tracks[id]?.scrubbing=enabled;tracks[id]?.last=CACurrentMediaTime()
            if !enabled,tracks[id]?.rule.resumeAfterSeek != false{tracks[id]?.running=true}
        }
    }
    @discardableResult func tick(_ now:Double)->Bool {
        var changed=false
        for id in Array(tracks.keys) {
            guard var track=tracks[id],track.running && !track.scrubbing else{continue}
            let duration=max(1,track.rule.duration)
            track.position+=max(0,now-track.last)/duration;track.last=now
            if track.position>=1 {
                if track.rule.repeats{track.position.formTruncatingRemainder(dividingBy:1)}
                else{track.position=1;track.running=false}
            }
            tracks[id]=track;publish(track);changed=true
        }
        return changed
    }
    private func publish(_ track:Track) {
        onProgress?(track.rule.targetID,track.position)
        let total=max(1,track.rule.duration),elapsed=track.position*total
        if track.rule.elapsedEnabled==true,let id=track.rule.elapsedID,!id.isEmpty{onText?(id,format(elapsed,track.rule.clockFormat ?? "clock"))}
        if track.rule.remainingEnabled==true,let id=track.rule.remainingID,!id.isEmpty{onText?(id,format(track.rule.clockFormat=="precise" ? max(0,total-elapsed):ceil(max(0,total-elapsed)),track.rule.clockFormat ?? "clock"))}
    }
    private func format(_ seconds:Double,_ style:String)->String {
        let value=max(0,seconds),whole=Int(value.rounded(.down))
        if style=="seconds"{return "\(whole) с"}
        let result=String(format:"%d:%02d",whole/60,whole%60)
        return style=="precise" ? result+String(format:".%d",Int(value*10)%10):result
    }
}
