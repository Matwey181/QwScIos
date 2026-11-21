@file:OptIn(ExperimentalJsExport::class)
import kotlin.js.*
import com.qwenz.qwel.data.*
import org.json.*
private var cached:Project?=null
@JsExport
fun qwelCore(input:String):String {
 val request=JSONObject(input)
 if(request.optString("op")=="language") { com.qwenz.qwel.i18n.words=JSON.parse<dynamic>(request.getString("strings"));return "{}" }
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
  "compose"->JSONObject().put("code",ComposeCode.generate(p)).toString()
  "tone"->output(p.nodes.withTone(Tone.fromSeed(request.optInt("seed"),request.optBoolean("dark"))))
  else->throw IllegalArgumentException("Unknown operation")
 }
}
