import SwiftUI

struct LinkMorph {
    let start:[Double]
    let end:[Double]
    @MainActor init?(from:String,to:String) {
        guard let result=try? OriginalCore.shared.request(["op":"morph","from":from,"to":to]),
              let a=result["start"] as? [NSNumber],let b=result["end"] as? [NSNumber],a.count==b.count,a.count>=8 else{return nil}
        start=a.map(\.doubleValue);end=b.map(\.doubleValue)
    }
    func svg(_ progress:Double)->String {
        func pair(_ i:Int)->String {"\(start[i]+(end[i]-start[i])*progress) \(start[i+1]+(end[i+1]-start[i+1])*progress)"}
        return "M \(pair(0)) "+stride(from:0,to:start.count-7,by:8).map{"C \(pair($0+2)) \(pair($0+4)) \(pair($0+6))"}.joined(separator:" ")+" Z"
    }
}
