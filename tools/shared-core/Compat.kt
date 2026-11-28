package com.qwenz.qwel.data
object Math { fun toRadians(x:Double)=x*kotlin.math.PI/180;fun toDegrees(x:Double)=x*180/kotlin.math.PI;fun round(x:Float)=kotlin.math.round(x).toInt() }
object System { fun currentTimeMillis():Long=(js("Date.now()") as Double).toLong() }
fun freshId():String=js("'xxxxxxxxxx'.replace(/x/g,function(){return (Math.random()*16|0).toString(16)})") as String
fun formatNumber(pattern:String,vararg values:Any):String { var i=0;return Regex("%([0-9]*)(?:\\.([0-9]+))?([fXd])").replace(pattern) { m ->
 val v=values[i++];when(m.groupValues[3]) { "X"->(v as Number).toInt().toUInt().toString(16).uppercase().padStart(m.groupValues[1].toIntOrNull()?:0,'0');"d"->v.toString();else->{val d=(v as Number).toDouble();d.asDynamic().toFixed(m.groupValues[2].toIntOrNull()?:6) as String} }
} }
class Random(seed:Long) { private var value=(seed xor 0x5DEECE66DL) and ((1L shl 48)-1);fun nextFloat():Float { value=(value*25214903917L+11L) and ((1L shl 48)-1);return (value ushr 24).toInt().toFloat()/16777216f } }
fun <K,V> MutableMap<K,V>.putIfAbsent(k:K,v:V):V? { val old=this[k];if(!containsKey(k))this[k]=v;return old }
fun <K:Comparable<K>,V> Map<K,V>.toSortedMap():Map<K,V> = entries.sortedBy{it.key}.associate{it.key to it.value}
fun <T:Comparable<T>> sortedSetOf():MutableSet<T> = linkedSetOf()
