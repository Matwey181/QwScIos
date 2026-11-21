import com.qwenz.qwel.data.*
import com.qwenz.qwel.shapes.ShapeLibrary
import org.json.*
import java.io.File
fun main() {
 val out=JSONObject()
 out.put("components",JSONArray().also { arr -> Components.groups.forEach { (category,defs) -> defs.forEach { c ->
  val p=Project("component",c.name,c.w,c.h,0,c.build(0f,0f,"component"),0,0)
  arr.put(JSONObject().put("id",c.id).put("name",c.name).put("category",category).put("project",ProjectStore.encode(p)))
 } } })
 out.put("templates",JSONArray().also { a -> Templates.all.forEach { t -> a.put(JSONObject().put("id",t.id).put("name",t.name).put("category",t.description).put("project",ProjectStore.encode(t.toProject(t.name,Tone.Baseline)))) } })
 out.put("shapes",JSONArray().also { a -> ShapeLibrary.all.forEach { s ->
  val cs=s.cubics
  val path=buildString { append("M ${cs.first().anchor0X} ${cs.first().anchor0Y} ");cs.forEach { append("C ${it.control0X} ${it.control0Y} ${it.control1X} ${it.control1Y} ${it.anchor1X} ${it.anchor1Y} ") };append("Z") }
  a.put(JSONObject().put("id",s.id).put("name",s.name).put("category",s.categories.first()).put("path",path))
 } })
 File("ios/Resources/catalog.json").writeText(out.toString())
 println("Generated: ${Components.all.size} components, ${Templates.all.size} templates, ${ShapeLibrary.all.size} shapes")
}
