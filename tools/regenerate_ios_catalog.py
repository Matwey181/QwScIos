#!/usr/bin/env python3
"""Evaluate the original Android model/catalog on the JVM; writes iOS JSON assets."""
import concurrent.futures,pathlib,subprocess,urllib.request,zipfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
CACHE=ROOT/'.catalog-cache'
CACHE.mkdir(exist_ok=True)
MAVEN='https://repo.maven.apache.org/maven2/'
GOOGLE='https://dl.google.com/dl/android/maven2/'
items=[('kotlin-compiler-embeddable','org/jetbrains/kotlin','2.1.20'),('kotlin-stdlib','org/jetbrains/kotlin','2.1.20'),('kotlin-script-runtime','org/jetbrains/kotlin','2.1.20'),('kotlin-reflect','org/jetbrains/kotlin','1.6.10'),('kotlin-daemon-embeddable','org/jetbrains/kotlin','2.1.20'),('trove4j','org/jetbrains/intellij/deps','1.0.20200330'),('kotlinx-coroutines-core-jvm','org/jetbrains/kotlinx','1.8.0'),('annotations','org/jetbrains','13.0'),('json','org/json','20240303')]
def download(item):
 name,group,version=item
 path=CACHE/(name+'.jar')
 if not path.exists():urllib.request.urlretrieve(f'{MAVEN}{group}/{name}/{version}/{name}-{version}.jar',path)
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:list(pool.map(download,items))
for name,url in [('collection.jar',GOOGLE+'androidx/collection/collection-jvm/1.4.0/collection-jvm-1.4.0.jar'),('shapes.aar',GOOGLE+'androidx/graphics/graphics-shapes-android/1.0.1/graphics-shapes-android-1.0.1.aar')]:
 path=CACHE/name
 if not path.exists():urllib.request.urlretrieve(url,path)
with zipfile.ZipFile(CACHE/'shapes.aar') as z:(CACHE/'graphics-shapes.jar').write_bytes(z.read('classes.jar'))
source=ROOT/'app/src/main/kotlin/com/qwenz/qwel'
files=list((ROOT/'tools/ios-generator').glob('*.kt'))
files += [source/'data'/f'{name}.kt' for name in ['Model','Palette','Tone','Components','ExpressiveComponents','Templates','PlayMode','IconNodes','ProjectStore']]
files += [source/'shapes/ShapeLibrary.kt']
subprocess.run(['java','-cp',str(CACHE/'*'),'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler','-no-stdlib','-no-reflect','-classpath',':'.join(str(CACHE/(n+'.jar')) for n in ['kotlin-stdlib','json','graphics-shapes']),'-d',str(CACHE/'generator.jar'),*map(str,files)],check=True,cwd=ROOT)
subprocess.run(['java','-cp',str(CACHE/'*'),'GenerateKt'],check=True,cwd=ROOT)
