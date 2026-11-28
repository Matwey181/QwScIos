package com.qwenz.qwel.i18n
var words:dynamic=null
fun tr(key:String,vararg args:Any):String { var value=if(words!=null && words[key]!=null)words[key].toString() else key;args.forEachIndexed{i,a->value=value.replace("{$i}",a.toString())};return value }
fun trOr(key:String,fallback:String):String=if(words!=null && words[key]!=null)words[key].toString() else fallback
