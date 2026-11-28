"""Recover declarative animation presets from JADX 1.5.7 output, without APK execution.

Only AnimTemplates/CurvePresets factory methods run on a desktop JVM with inert
model stubs. No Android framework, application classes or APK entry points load.
Usage: python tools/recover_motion_presets.py JADX_SOURCES KOTLIN_STDLIB
"""
from pathlib import Path
import json, re, subprocess, sys, tempfile, shutil

src=Path(sys.argv[1])/'com/qwenz/qwel'
stdlib=Path(sys.argv[2]).resolve()
with tempfile.TemporaryDirectory() as temp:
    root=Path(temp)
    def write(name, text):
        p=root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
    # Keep the recovered preset bodies intact; remove only erased Kotlin generic
    # casts that javac cannot infer from JADX's synthetic Object[] arrays.
    for name in ['AnimTemplates','CurvePresets']:
        s=(src/f'anim/{name}.java').read_text().replace('(Object[]) ', '').replace('Iterator<T>', 'Iterator')
        write(f'com/qwenz/qwel/anim/{name}.java',s)
    write('androidx/window/core/layout/WindowSizeClass.java','package androidx.window.core.layout; public class WindowSizeClass {public static final int WIDTH_DP_EXTRA_LARGE_LOWER_BOUND=1200, WIDTH_DP_LARGE_LOWER_BOUND=840;}')
    write('com/qwenz/qwel/data/ModelKt.java','package com.qwenz.qwel.data; public class ModelKt {public static String newId(){return "track";}}')
    write('com/qwenz/qwel/data/NodeKind.java','package com.qwenz.qwel.data; public enum NodeKind {RECT,SHAPE}')
    write('com/qwenz/qwel/data/Node.java','package com.qwenz.qwel.data; public class Node {public NodeKind getKind(){return NodeKind.RECT;} public float getCorner(){return 16;} public String getShapeId(){return "circle";}}')
    write('com/qwenz/qwel/anim/Target.java','package com.qwenz.qwel.anim; public class Target {}')
    props=re.findall(r'^    ([A-Z_]+)\("([^"]+)"', (src/'anim/Prop.java').read_text(), re.M)
    write('com/qwenz/qwel/anim/Prop.java','package com.qwenz.qwel.anim; public enum Prop {'+','.join(f'{a}("{b}")' for a,b in props)+'; public String id;Prop(String id){this.id=id;}}')
    write('com/qwenz/qwel/anim/Curve.java','''package com.qwenz.qwel.anim;
import java.util.*;
public class Curve {
 public String code;
 Curve(String code){this.code=code;}
 static String nums(float... a){StringJoiner j=new StringJoiner(",");for(float v:a)j.add(Float.toString(v));return j.toString();}
 public String encode(){return code;}
 public static class Linear extends Curve{public static Linear INSTANCE=new Linear();Linear(){super("lin");}}
 public static class Bezier extends Curve{public Bezier(float a,float b,float c,float d){super("bz:"+nums(a,b,c,d));}}
 public static class Spring extends Curve{public Spring(float a,float b){super("sp:"+nums(a,b));}}
 public static class Bounce extends Curve{public Bounce(int a,float b){super("bn:"+nums(a,b));}}
 public static class Elastic extends Curve{public Elastic(float a,float b){super("el:"+nums(a,b));}}
 public static class Steps extends Curve{public Steps(int a,boolean b){super("st:"+a+","+(b?1:0));}}
 public static class Chain extends Curve{public Chain(List<Float>a){super("ch:"+a.toString().replace("[", "").replace("]", "").replace(" ", ""));}}
}''')
    write('com/qwenz/qwel/anim/Key.java','''package com.qwenz.qwel.anim;
public class Key {public int t,c;public float v;public String s;public Curve e;
 public Key(int t,float v,int c,String s,Curve e,int mask,Object marker){this.t=t;this.v=v;this.c=c;this.s=s==null?"":s;this.e=e;}}
''')
    write('com/qwenz/qwel/anim/Track.java','package com.qwenz.qwel.anim;import java.util.*;public class Track{public Prop p;public List<Key> keys;public Track(String id,Target g,Prop p,List<Key> keys){this.p=p;this.keys=keys;}}')
    write('com/qwenz/qwel/anim/AnimTemplate.java','''package com.qwenz.qwel.anim;import kotlin.jvm.functions.*;import com.qwenz.qwel.data.*;
public class AnimTemplate{public String id,name;public int duration;public Function4 build;
 public Function1<Node,Boolean> getApplies(){return (node)->true;}
 public AnimTemplate(String id,String name,int d,Function1 a,Function4 b){this.id=id;this.name=name;duration=d;build=b;}
 public AnimTemplate(String id,String name,int d,Function1 a,Function4 b,int mask,Object marker){this(id,name,d,a,b);}}
''')
    write('com/qwenz/qwel/anim/CurvePreset.java','package com.qwenz.qwel.anim;public class CurvePreset{public String id,name;public Curve c;public CurvePreset(String id,String name,Curve c){this.id=id;this.name=name;this.c=c;}public Curve getCurve(){return c;}}')
    write('com/qwenz/qwel/anim/CurveGroup.java','package com.qwenz.qwel.anim;import java.util.*;public class CurveGroup{public String id,name;public List<CurvePreset> presets;public CurveGroup(String id,String name,List<CurvePreset>p){this.id=id;this.name=name;presets=p;}public List<CurvePreset> getPresets(){return presets;}}')
    write('Main.java','''import com.qwenz.qwel.anim.*;import com.qwenz.qwel.data.*;import java.util.*;
public class Main{
 static String q(String s){return "\\\""+s.replace("\\\\","\\\\\\\\").replace("\\\"","\\\\\\\"")+"\\\"";}
 public static void main(String[]args){
 StringJoiner items=new StringJoiner(",");
 for(AnimTemplate a:AnimTemplates.INSTANCE.getList()){
  StringJoiner tracks=new StringJoiner(",");
  for(Object obj:(List)a.build.invoke(new Target(),new Node(),0,a.duration)){
   Track t=(Track)obj;StringJoiner keys=new StringJoiner(",");
   for(Key k:t.keys)keys.add("{\\\"t\\\":"+k.t+",\\\"v\\\":"+k.v+",\\\"c\\\":"+k.c+",\\\"s\\\":"+q(k.s)+",\\\"e\\\":"+q(k.e.encode())+"}");
   tracks.add("{\\\"id\\\":\\\"preset\\\",\\\"ref\\\":\\\"\\\",\\\"group\\\":false,\\\"prop\\\":"+q(t.p.id)+",\\\"keys\\\":["+keys+"]}");
  }
  items.add("{\\\"id\\\":"+q(a.id)+",\\\"name\\\":"+q(a.name)+",\\\"category\\\":"+q(AnimTemplates.INSTANCE.categoryOf(a.id))+",\\\"duration\\\":"+a.duration+",\\\"tracks\\\":["+tracks+"]}");
 }
 StringJoiner curves=new StringJoiner(",");
 for(CurveGroup g:CurvePresets.INSTANCE.getGroups())for(CurvePreset c:g.presets)curves.add("{\\\"id\\\":"+q(c.id)+",\\\"name\\\":"+q(c.name)+",\\\"group\\\":"+q(g.name)+",\\\"curve\\\":"+q(c.c.encode())+"}");
 System.out.print("{\\\"templates\\\":["+items+"],\\\"curves\\\":["+curves+"]}");
 }}''')
    compiler=['javac'] if shutil.which('javac') else ['java','-jar',sys.argv[3],'-21','-nowarn']
    subprocess.run(compiler+['-cp',str(stdlib),'-d',str(root/'out')]+[str(p)for p in root.rglob('*.java')],check=True)
    result=subprocess.check_output(['java','-cp',f'{root}/out:{stdlib}','Main'],text=True)
    data=json.loads(result)
    destination=Path(__file__).resolve().parents[1]/'ios/Resources/motion-presets.json'
    destination.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':')))
    print(len(data['templates']),'templates;',len(data['curves']),'curves')
