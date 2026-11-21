@file:OptIn(ExperimentalJsExport::class)
import kotlin.js.*
import com.qwenz.qwel.data.*
import org.json.*
private var cached:Project?=null
@JsExport
fun qwelCore(input:String):String {
 val request=JSONObject(input)
 if(request.optString("op")=="language") { com.qwenz.qwel.i18n.words=JSON.parse<dynamic>(request.getString("strings"));return "{}" }
 if(request.optString("op")=="morph") {
  val m=com.qwenz.qwel.shapes.ShapeLibrary.morph(request.getString("from"),request.getString("to"))
  val result=JSONObject()
  if(m!=null)for((key,t)in listOf("start" to 0f,"end" to 1f))result.put(key,JSONArray().also{a->m.asCubics(t).forEach{c->listOf(c.anchor0X,c.anchor0Y,c.control0X,c.control0Y,c.control1X,c.control1Y,c.anchor1X,c.anchor1Y).forEach{a.put(it)}}})
  return result.toString()
 }
 val supplied=request.optJSONObject("project")
 val p=if(supplied!=null)ProjectStore.decode(supplied).also{cached=it} else cached?:throw IllegalStateException("No project")
 val op=request.getString("op")
 val pm=PlayMode
 val shown=request.optJSONObject("shown")?:JSONObject()
 val values=shown.keys().associateWith { shown.optDouble(it).toFloat() }.toMutableMap()
 fun output(nodes:List<Node>):String=ProjectStore.encode(p.copy(nodes=nodes)).toString()
 fun widgetObject(w:PlayMode.Widget)=JSONObject().put("group",w.group).put("kind",w.kind).put("value",pm.initial(w)).put("persistent",pm.persistent(w)).also { o -> w.bounds?.let { o.put("x",it.l).put("y",it.t).put("w",it.w).put("h",it.h) } }
 return when(op) {
  "set","init"->JSONObject().put("widgets",JSONArray().also { a -> pm.widgets(p.nodes).forEach{a.put(widgetObject(it))} }).toString()
  "hit"->{ val x=request.optDouble("x").toFloat();val y=request.optDouble("y").toFloat();val w=pm.widgetAt(p.nodes,x,y,request.optDouble("pad",8.0).toFloat())
    if(w==null) "{}" else widgetObject(w).put("value",if(w.kind=="slider")pm.sliderValue(w,x) else if(w.kind=="progress")pm.scrubValue(w,x,y) else pm.initial(w)).toString() }
  "tap","swipe"->{val w=pm.widgets(p.nodes).firstOrNull{it.group==request.getString("group")};if(w!=null) {
      if(op=="swipe" && w.kind=="pick")values[w.group]=((values[w.group]?:0f).toInt()+request.optInt("direction")).coerceIn(0,(pm.pickCount(w)-1).coerceAtLeast(0)).toFloat()
      else TapState(p.nodes,values).playTap(w,request.optDouble("x").toFloat(),request.optDouble("y").toFloat())
    };JSONObject().also { o->values.forEach{(k,v)->o.put(k,v)} }.toString() }
  "apply"->output(pm.apply(p.nodes,values,p.tone,request.optDouble("time").toFloat()))
  "stop"->{val ws=pm.widgets(p.nodes).associateBy{it.group};val touched=values.filter{(g,v)->ws[g]?.let{pm.persistent(it)&&kotlin.math.abs(pm.initial(it)-v)>0.001f}==true};output(pm.apply(p.nodes,touched,p.tone))}
  "echo"->{val source=p.nodes.first{it.id==request.getString("id")};val params=EchoParams(request.optInt("count",4),request.optDouble("scale",5.0).toFloat(),request.optDouble("rotation",3.0).toFloat(),request.optDouble("fade",0.85).toFloat(),request.optBoolean("contour",true),request.optDouble("spread").toFloat(),request.optDouble("jitter",0.2).toFloat(),request.optInt("seed",7));output(Echo.copies(source,params))}
  "projectExport"->{val kind=request.optString("kind");val pkg=request.optString("package",ProjectExport.DEFAULT_PACKAGE);val faces=request.optJSONObject("faces")?:JSONObject();val provider:FontFaces={font->val a=faces.optJSONArray(font);if(a==null)emptyList() else (0 until a.length()).map{i->val o=a.getJSONObject(i);o.optInt("weight",400) to o.optString("ext","ttf")}};val result=if(kind=="codeassist")ProjectExport.buildCodeAssist(p,pkg,provider) else ProjectExport.build(p,pkg,pkg,provider);JSONObject().put("files",JSONObject().also{o->result.files.forEach{(k,v)->o.put(k,v)}}).put("images",JSONObject().also{o->result.images.forEach{(k,v)->o.put(k,v)}}).put("fonts",JSONObject().also{o->result.fonts.forEach{(k,v)->o.put(k,JSONObject().put("name",v.first).put("weight",v.second))}}).toString()}
  "blend"->{val samples=request.optJSONObject("samples")?:JSONObject();com.qwenz.qwel.render.blendSamples=samples.keys().associateWith { key->val a=samples.getJSONArray(key);FloatArray(a.length()){i->a.getDouble(i).toFloat()} };output(com.qwenz.qwel.render.blendNodes(p.nodes.first{it.id==request.getString("a")},p.nodes.first{it.id==request.getString("b")},request.optInt("steps",5))?:emptyList())}
  "compose"->JSONObject().put("code",ComposeCode.generate(p)).toString()
  "tone"->output(p.nodes.withTone(Tone.fromSeed(request.optInt("seed"),request.optBoolean("dark"))))
  else->throw IllegalArgumentException("Unknown operation")
 }
}
