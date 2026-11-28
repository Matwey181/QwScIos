package org.json
import kotlin.js.*
class JSONObject(val obj:dynamic=js("({})"), private val marker:Boolean=true) {
 constructor(s:String):this(JSON.parse<dynamic>(s),true)
 fun put(k:String,v:Any?):JSONObject { obj[k]=when(v){is JSONObject->v.obj;is JSONArray->v.obj;is Long->v.toDouble();else->v};return this }
 fun getString(k:String):String { require(obj[k]!=null);return obj[k].toString() }
 fun optString(k:String,fallback:String=""):String = if(obj[k]==null) fallback else obj[k].toString()
 fun getDouble(k:String):Double { require(obj[k]!=null);return (obj[k] as Number).toDouble() }
 fun optDouble(k:String,fallback:Double=0.0):Double=if(obj[k]==null)fallback else (obj[k] as Number).toDouble()
 fun getInt(k:String):Int=getDouble(k).toInt()
 fun optInt(k:String,fallback:Int=0):Int=optDouble(k,fallback.toDouble()).toInt()
 fun optLong(k:String,fallback:Long=0):Long=optDouble(k,fallback.toDouble()).toLong()
 fun optBoolean(k:String,fallback:Boolean=false):Boolean=if(obj[k]==null)fallback else obj[k] as Boolean
 fun getJSONArray(k:String):JSONArray { require(obj[k]!=null);return JSONArray(obj[k]) }
 fun optJSONArray(k:String):JSONArray?=if(obj[k]==null)null else JSONArray(obj[k])
 fun optJSONObject(k:String):JSONObject?=if(obj[k]==null)null else JSONObject(obj[k],true)
 fun keys():List<String> = (js("Object.keys")(obj) as Array<String>).toList()
 override fun toString():String=JSON.stringify(obj)
}
class JSONArray(val obj:dynamic=js("[]")) {
 fun put(v:Any?):JSONArray { obj.push(when(v){is JSONObject->v.obj;is JSONArray->v.obj;is Long->v.toDouble();else->v});return this }
 fun length():Int=obj.length as Int
 fun getJSONObject(i:Int)=JSONObject(obj[i],true)
 fun getDouble(i:Int)=(obj[i] as Number).toDouble()
 fun getInt(i:Int)=(obj[i] as Number).toInt()
 override fun toString():String=JSON.stringify(obj)
}
