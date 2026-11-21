package com.qwenz.qwel.render
import com.qwenz.qwel.data.Node
object IconLibrary { val styles = emptyList<String>(); fun bytes(style:String,name:String,fill:Boolean):ByteArray?=null; fun label(name:String)=name }
data class Imported(val nodes:List<Node>,val width:Float,val height:Float)
object SvgImport { fun parseOwnSize(b:ByteArray,s:Double):Imported?=null }
