#!/usr/bin/env python3
"""Extract the original QIcon drawing instructions and logo without redrawing."""
import pathlib,re,json,shutil
root=pathlib.Path(__file__).resolve().parents[1]
s=(root/'app/src/main/kotlin/com/qwenz/qwel/ui/common/QIcon.kt').read_text()
s=s[s.index('    when (ico) {')+len('    when (ico) {'):]
starts=list(re.finditer(r'^        (Ico\.[^\n]+?) ->',s,re.M));out={}
for j,m in enumerate(starts):
 names=re.findall(r'Ico\.(\w+)',m.group(1));body=s[m.end():starts[j+1].start() if j+1<len(starts) else s.rfind('    }')]
 if any(n.startswith('Bool') and n in ['BoolUnion','BoolDiff','BoolIntersect','BoolExclude','BoolDivide'] for n in names):
  for name in names:out[name]=[{'op':'boolean','mode':name}]
  continue
 commands=[]
 pat=re.compile(r'(ln|rc|cr)\(([^)]*)\)|pth(?:\((true|false)\))?\s*\{\s*u\s*->([^}]+)\}',re.S)
 for a in pat.finditer(body):
  if a.group(1):
   values=[]
   for p in a.group(2).split(','):
    p=p.strip().removesuffix('f');values.append(1 if p=='true' else 0 if p=='false' else float(p))
   commands.append({'op':a.group(1),'args':values})
  else:
   path=[]
   for b in re.finditer(r'([mlc])\(u,([^)]*)\)|(close)\(\)',a.group(4)):
    if b.group(3):path.append('Z')
    else:path.append(b.group(1).upper()+' '+' '.join(p.strip().removesuffix('f') for p in b.group(2).split(',')))
   commands.append({'op':'path','path':' '.join(path),'fill':a.group(3)=='true'})
 if names==['Stroke']:commands=[{'op':'cr','args':[12,12,8],'dash':[3,3.4]}]
 for name in names:out[name]=commands
(root/'ios/Resources/ui-icons.json').write_text(json.dumps(out))
s=(root/'app/src/main/kotlin/com/qwenz/qwel/ui/common/Logo.kt').read_text()
logo=[{'path':p,'color':int(c,16)} for p,c in re.findall(r'"([MCZ][^"]+)" to Color\(0x([A-F0-9]+)\)',s)]
(root/'ios/Resources/ui-logo.json').write_text(json.dumps(logo))
for suffix in ['Regular','Medium','SemiBold','Bold','Light']:
 shutil.copy(root/f'app/src/main/assets/fonts/InterSA-{suffix}.otf',root/f'ios/Resources/InterSA-{suffix}.otf')
shutil.copy(root/'app/src/main/assets/lang/ru.json',root/'ios/Resources/ru.json')
shutil.copy(root/'app/src/main/assets/lang/en.json',root/'ios/Resources/en.json')
print(len(out),'original icons;',len(logo),'logo paths')
