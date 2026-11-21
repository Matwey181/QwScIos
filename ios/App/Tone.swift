import Foundation

enum ToneGenerator {
    static func scheme(seed:Int64,dark:Bool)->Tone {
        let v=UInt32(truncatingIfNeeded:seed)
        func linear(_ x:Double)->Double { x<=0.04045 ? x/12.92:pow((x+0.055)/1.055,2.4) }
        let r=linear(Double((v>>16)&255)/255),g=linear(Double((v>>8)&255)/255),b=linear(Double(v&255)/255)
        let l=cbrt(0.4122214708*r+0.5363325363*g+0.0514459929*b)
        let m=cbrt(0.2119034982*r+0.6806995451*g+0.1073969566*b)
        let s=cbrt(0.0883024619*r+0.2817188376*g+0.6299787005*b)
        let a=1.9779984951*l-2.4285922050*m+0.4505937099*s
        let bb=0.0259040371*l+0.7827717662*m-0.8086757660*s
        let chroma=sqrt(a*a+bb*bb),h=atan2(bb,a)*180 / .pi
        let gray=chroma<0.02,cp=gray ? chroma:min(0.2,max(0.11,chroma))
        func tone(_ hue:Double,_ c:Double,_ t:Double)->Int64 {
            let y=t>8 ? pow((t+16)/116,3):t/903.3,L=cbrt(y),hr=hue * .pi/180
            var ch=c,rgb=[Double]()
            for _ in 0..<41 {
                let aa=ch*cos(hr),bb=ch*sin(hr)
                let ll=pow(L+0.3963377774*aa+0.2158037573*bb,3)
                let mm=pow(L-0.1055613458*aa-0.0638541728*bb,3)
                let ss=pow(L-0.0894841775*aa-1.2914855480*bb,3)
                rgb=[4.0767416621*ll-3.3077115913*mm+0.2309699292*ss,-1.2684380046*ll+2.6097574011*mm-0.3413193965*ss,-0.0041960863*ll-0.7034186147*mm+1.7076147010*ss]
                if rgb.allSatisfy({$0 >= -0.0005 && $0 <= 1.0005}) { break };ch *= 0.92
            }
            func byte(_ x:Double)->UInt32 { let x=min(1,max(0,x));return UInt32(min(255,max(0,((x<=0.0031308 ? 12.92*x:1.055*pow(x,1/2.4)-0.055)*255).rounded()))) }
            return Int64(Int32(bitPattern:0xff000000 | byte(rgb[0])<<16 | byte(rgb[1])<<8 | byte(rgb[2])))
        }
        func p(_ t:Double)->Int64 { tone(h,cp,t) };func secondary(_ t:Double)->Int64 { tone(h,cp/3,t) }
        func tertiary(_ t:Double)->Int64 { tone(h+60,cp*0.55,t) };func error(_ t:Double)->Int64 { tone(29,0.19,t) }
        func n(_ t:Double)->Int64 { tone(h,gray ? 0:0.012,t) };func nv(_ t:Double)->Int64 { tone(h,gray ? 0:0.022,t) }
        var out=Tone();out.seed=seed;out.dark=dark;out.mode=1
        out.colors=dark ? [p(80),p(20),p(30),p(90),secondary(80),secondary(30),secondary(90),tertiary(80),tertiary(30),tertiary(90),error(80),error(30),n(6),n(10),n(12),n(17),n(22),n(90),nv(80),nv(60),nv(30),n(90)] : [p(40),p(100),p(90),p(10),secondary(40),secondary(90),secondary(10),tertiary(40),tertiary(90),tertiary(10),error(40),error(90),n(98),n(96),n(94),n(92),n(90),n(10),nv(30),nv(50),nv(80),n(20)]
        return out
    }
}
