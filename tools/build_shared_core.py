#!/usr/bin/env python3
import pathlib,re,subprocess,shutil,os
ROOT=pathlib.Path(__file__).resolve().parents[1]
CACHE=pathlib.Path(os.environ.get('QWEL_KOTLIN_CACHE','/workspace/scratch/qwel-tools'))
OUT=ROOT/'.core-build';OUT.mkdir(exist_ok=True)
SRC=ROOT/'app/src/main/kotlin/com/qwenz/qwel/data'
files=[]
for name in ['Model','Tone','Palette','PlayMode','Components','ExpressiveComponents','Templates','IconNodes','ComposeCode','Echo','Align','Geometry','Snap','ProjectExport']:
 s=(SRC/(name+'.kt')).read_text().replace('import java.util.Locale','').replace('import java.util.Random','')
 s=s.replace('java.util.UUID.randomUUID().toString().replace("-", "").take(10)','freshId()')
 s=s.replace('String.format(Locale.US,','formatNumber(').replace('String.format(java.util.Locale.US,','formatNumber(').replace('"%.1f".format(java.util.Locale.US,','formatNumber("%.1f",')
 s=s.replace('"%.4f %.4f ".format(java.util.Locale.US,','formatNumber("%.4f %.4f ",')
 p=OUT/(name+'.kt');p.write_text(s);files.append(p)
s=(SRC/'ProjectStore.kt').read_text();s=s[s.index('        fun encode(p:'):];s=s.rsplit('\n    }',1)[0]
p=OUT/'ProjectStore.kt';p.write_text('package com.qwenz.qwel.data\nimport org.json.*\nobject ProjectStore {\n'+s+'\n}');files.append(p)
blend=(ROOT/'app/src/main/kotlin/com/qwenz/qwel/render/Blend.kt').read_text()
blend=blend.replace('import android.graphics.PathMeasure','').replace('import androidx.compose.ui.graphics.asAndroidPath','').replace('import java.util.Locale','import com.qwenz.qwel.data.formatNumber')
a=blend.index('private fun samplePoly(');b=blend.index('\nprivate fun area(',a)
blend=blend[:a]+'var blendSamples:Map<String,FloatArray> = emptyMap()\nprivate fun samplePoly(n:Node):FloatArray? = blendSamples[n.id]\n'+blend[b:]
blend=blend.replace('String.format(Locale.US,','formatNumber(')
p=OUT/'Blend.kt';p.write_text(blend);files.append(p)
for source in (ROOT/'tools/shared-core/graphics').glob('*.kt'):
 s=source.read_text()
 if source.name=='Format.kt':s=s.replace('internal expect fun Float.toStringWithLessPrecision(): String','internal fun Float.toStringWithLessPrecision(): String = toString()')
 s=re.sub(r'^import (?:kotlin.jvm|androidx.annotation)\.[^\n]+\n','',s,flags=re.M)
 s=re.sub(r'@(?:file:)?Jvm\w+(?:\([^)]*\))?','',s)
 s=re.sub(r'@(?:FloatRange|IntRange)\([^)]*\)','',s)
 target=OUT/('Graphics'+source.name);target.write_text(s);files.append(target)
shape=ROOT/'app/src/main/kotlin/com/qwenz/qwel/shapes/ShapeLibrary.kt'
files.append(shape)
files+=list((ROOT/'tools/shared-core').glob('*.kt'))
files.append(ROOT/'tools/ios-generator/Icons.kt')
cp=str(CACHE/'*')
base=['java','-cp',cp,'org.jetbrains.kotlin.cli.js.K2JSCompiler','-libraries',str(CACHE/'stdlib-js.klib')]
subprocess.run(base+['-Xir-produce-klib-file','-ir-output-dir',str(OUT),'-ir-output-name','qwelcore',*map(str,files)],check=True,cwd=ROOT)
subprocess.run(base+['-Xir-produce-js','-Xinclude='+str(OUT/'qwelcore.klib'),'-ir-output-dir',str(OUT/'js'),'-ir-output-name','qwelcore','-module-kind','plain','-main','noCall','-Xir-dce'],check=True,cwd=ROOT)
shutil.copy(OUT/'js/qwelcore.js',ROOT/'ios/Resources/qwelcore.js')
