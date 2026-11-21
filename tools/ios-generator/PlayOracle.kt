import com.qwenz.qwel.data.*
import org.json.*
import java.io.File
fun main() {
 val cases=JSONArray()
 for(c in Components.all) {
  val p=Project("test",c.name,c.w,c.h,0,c.build(0f,0f,"component"),0,0)
  for(v in listOf(0f,0.25f,1f)) {
   val shown=PlayMode.widgets(p.nodes).associate{it.group to v}
   cases.put(JSONObject().put("id",c.id).put("project",ProjectStore.encode(p)).put("shown",JSONObject().also{o->shown.forEach{(k,v)->o.put(k,v)}}).put("expected",ProjectStore.encode(p.copy(nodes=PlayMode.apply(p.nodes,shown,p.tone,1f)))))
  }
 }
 File("/workspace/scratch/qwel-play-oracle.json").writeText(cases.toString())
 println("Original JVM oracle: ${cases.length()} cases")
}
