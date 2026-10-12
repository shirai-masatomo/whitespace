from pathlib import Path
from PIL import Image,ImageOps
import json,hashlib,numpy as np
S=Path(__file__).resolve().parent;P=S.parents[1];D=P/'art_delivery/biome_environment_v1'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
allassets=[];reuse=[]
for f in sorted(D.glob('*_manifest.json')):
 m=json.loads(f.read_text(encoding='utf-8-sig'));allassets+=m['assets'];reuse+=m.get('reuse',[])
errors=[]
for a in allassets:
 f=D/a['file'];im=Image.open(f)
 if im.mode!='RGBA' or list(im.size)!=a['size_px'] or sha(f)!=a['sha256'] or not im.getbbox():errors.append(a['file'])
for a in reuse:
 if sha(D/a['file'])!=a['sha256']:errors.append(a['file'])
prior=json.loads((S/'prior-hashes.json').read_text());changed=[f for f,h in prior.items() if sha(P/f)!=h];errors+=changed
# Main interior is solid. Connected ports remain open across their common roof interval.
rocks=[Image.open(D/f'rock/normal/mask_{i:02}.png').getchannel('A') for i in range(16)]
assert np.all(np.array(rocks[15])[12:54,:]==255)
checks=0
for l in range(16):
 for r in range(16):
  if not l&2 or not r&8:continue
  lo=max(12 if l&1 else 16,12 if r&1 else 16);hi=min(54 if l&4 else 39,54 if r&4 else 39)
  assert np.all(np.array(rocks[l])[lo:hi,47]==255) and np.all(np.array(rocks[r])[lo:hi,0]==255);checks+=1
ns_checks=0
for n in range(16):
 for south in range(16):
  if not n&4 or not south&1:continue
  lo=max(0 if n&8 else 3,0 if south&8 else 3);hi=min(48 if n&2 else 45,48 if south&2 else 45)
  assert np.all(np.array(rocks[n])[53,lo:hi]==255) and np.all(np.array(rocks[south])[12,lo:hi]==255);ns_checks+=1
sheet=Image.open(D/'rock/normal_sheet.png')
for i in range(16):assert np.array_equal(np.array(sheet.crop(((i%4)*48,(i//4)*54,(i%4+1)*48,(i//4+1)*54))),np.array(Image.open(D/f'rock/normal/mask_{i:02}.png')))
effects=json.loads((P/'art_delivery/effects_v1/manifest.json').read_text(encoding='utf-8'))
for r in reuse:
 r.setdefault('duration_ms',None);r.setdefault('occupied_cells',[0,0])
 if r.get('timing_source'):
  match=next(a for a in effects['assets'] if r['file']=='../effects_v1/'+a['file']);r['duration_ms']=match['frame_duration_ms'];r['animation']=match['action']
animations={}
for a in allassets+reuse:
 if a.get('animation'):animations.setdefault(a['animation'],[]).append({'file':a['file'],'frame_index':a['frame_index'],'duration_ms':a['duration_ms']})
for frames in animations.values():frames.sort(key=lambda a:a['frame_index'])
m={'animations':animations,'schema_version':1,'date':'2026-10-12','branch':'codex/sporehollow-art-assets','assets':allassets,'reuse':reuse,'sheets':[{'file':'rock/normal_sheet.png','size_px':[192,216],'frame_size_px':[48,54],'order':list(range(16)),'anchor_px':[24,33],'duration_ms':None,'loop':False,'sha256':sha(D/'rock/normal_sheet.png')}],'runtime_verified':False,'review_is_game_evidence':False}
(D/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
qa={'png_assets':len(allassets),'sheet_count':1,'external_references':len(reuse),'prior_png_unchanged':len(prior),'connected_EW_port_cases':checks,'connected_NS_port_cases':ns_checks,'interior_solid':True,'sheet_matches_frames':True,'errors':errors,'runtime_verified':False}
(D/'QA.json').write_text(json.dumps(qa,indent=2)+'\n');print(json.dumps(qa));assert not errors
