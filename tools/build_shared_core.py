#!/usr/bin/env python3
import pathlib,re,subprocess,shutil,os
ROOT=pathlib.Path(__file__).resolve().parents[1]
CACHE=pathlib.Path(os.environ.get('QWEL_KOTLIN_CACHE','/workspace/scratch/qwel-tools'))
OUT=ROOT/'.core-build';OUT.mkdir(exist_ok=True)
SRC=ROOT/'app/src/main/kotlin/com/qwenz/qwel/data'
files=[]
for name in ['Model','Tone','Palette','PlayMode','Components','ExpressiveComponents','Templates','IconNodes','ComposeCode','Echo','Align','Geometry','Snap']:
 s=(SRC/(name+'.kt')).read_text().replace('import java.util.Locale','').replace('import java.util.Random','')
 s=s.replace('java.util.UUID.randomUUID().toString().replace("-", "").take(10)','freshId()')
 s=s.replace('String.format(Locale.US,','formatNumber(')
 s=s.replace('"%.4f %.4f ".format(java.util.Locale.US,','formatNumber("%.4f %.4f ",')
 p=OUT/(name+'.kt');p.write_text(s);files.append(p)
s=(SRC/'ProjectStore.kt').read_text();s=s[s.index('        fun encode(p:'):];s=s.rsplit('\n    }',1)[0]
p=OUT/'ProjectStore.kt';p.write_text('package com.qwenz.qwel.data\nimport org.json.*\nobject ProjectStore {\n'+s+'\n}');files.append(p)
files+=list((ROOT/'tools/shared-core').glob('*.kt'))
files.append(ROOT/'tools/ios-generator/Icons.kt')
cp=str(CACHE/'*')
base=['java','-cp',cp,'org.jetbrains.kotlin.cli.js.K2JSCompiler','-libraries',str(CACHE/'stdlib-js.klib')]
subprocess.run(base+['-Xir-produce-klib-file','-ir-output-dir',str(OUT),'-ir-output-name','qwelcore',*map(str,files)],check=True,cwd=ROOT)
subprocess.run(base+['-Xir-produce-js','-Xinclude='+str(OUT/'qwelcore.klib'),'-ir-output-dir',str(OUT/'js'),'-ir-output-name','qwelcore','-module-kind','plain','-main','noCall','-Xir-dce'],check=True,cwd=ROOT)
shutil.copy(OUT/'js/qwelcore.js',ROOT/'ios/Resources/qwelcore.js')
