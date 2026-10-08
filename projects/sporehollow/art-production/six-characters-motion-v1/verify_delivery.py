from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont,ImageSequence
import json,hashlib,numpy as np
S=Path(__file__).parent;P=S.parents[1];D=P/'art_delivery'
fnt=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',14)
def im(f):return Image.open(f).convert('RGBA')
errs=[];counts={}
old=json.loads((S/'prior-hashes.json').read_text())
for f,h in old.items():
 if hashlib.sha256((P/f).read_bytes()).hexdigest()!=h:errs.append('prior_changed:'+f)
for who in ['merchant','maid','dancer','thief','cow','bull']:
 d=D/f'{who}_motion_v1';m=json.loads((d/'manifest.json').read_text());counts[who]=len(m['assets'])
 for a in m['assets']:
  f=d/a['file'];o=Image.open(f)
  assert o.mode=='RGBA' and list(o.size)==a['canvas_size_px'] and hashlib.sha256(f.read_bytes()).hexdigest()==a['sha256'],f
  assert o.getbbox() and a['direction'] in ['left','right']
 src=im(D/f'two_direction_review_v1/native/{who}/idle_right.png');out=Image.new('RGBA',tuple(m['canvas_size_px']));out.alpha_composite(src,((out.width-src.width)//2,0))
 assert np.array_equal(np.array(out),np.array(im(d/'idle/right_00.png'))),who
 o=Image.new('RGBA',(1000,220),'#27332a');dd=ImageDraw.Draw(o)
 with Image.open(d/'preview/movement.gif') as gif:
  timed=[];clock=0
  for gf in ImageSequence.Iterator(gif):
   timed.append((clock,gf.convert('RGBA').copy()));clock+=gf.info.get('duration',100)
  for i,k in enumerate([0,8,16,24,36]):
   ob=next(frame for tm,frame in reversed(timed) if tm<=k*100);ob=ob.crop((370,45,710,260)).resize((200,126),Image.Resampling.NEAREST);o.alpha_composite(ob,(i*200,40));dd.text((i*200+6,10),str(k*100)+'ms',font=fnt,fill='white')
 o.save(d/'preview/movement_samples.png')
# Layer composition inspection: body-only, FX-only, composite, both directions.
rows=[]
for who,act,idx,fx,fi,behind in [('maid','rage_start',1,'rage_aura',1,True),('dancer','ultimate',2,'revival_light',1,False),('bull','guts',1,'guts_breath',1,False)]:
 for side in ['right','left']:
  d=D/f'{who}_motion_v1';body=im(d/f'{act}/{side}_{idx:02}.png');layer=im(d/f'{fx}/{side}_{fi:02}.png');full=Image.new('RGBA',body.size)
  if who=='dancer':
   body=Image.new('RGBA',(64,64));body.alpha_composite(im(D/'characters_v1/keeper_idle_right_00.png'),(16,14));full.alpha_composite(layer,(16,22))
  else:full.alpha_composite(layer)
  comp=full.copy() if behind else body.copy();comp.alpha_composite(body if behind else full)
  rows.append((who+' '+side,[body,full,comp]))
# Reuse a real delivered item only for QA. Runtime steal images have empty hands.
fossils=sorted(D.glob('**/*fossil*.png'));fossil=next((f for f in fossils if 'preview' not in f.as_posix() and 'review' not in f.as_posix()),None)
if fossil:
 item=im(fossil);item=item.crop(item.getbbox());item.thumbnail((12,12),Image.Resampling.NEAREST)
 for i in [1,2]:
  for side in ['right','left']:
   d=D/'thief_motion_v1';m=json.loads((d/'manifest.json').read_text());a=next(a for a in m['assets'] if a['action']=='steal' and a['direction']==side and a['frame_index']==i);x,y=a['sockets_px']['item'];body=im(d/a['file']);held=body.copy();held.alpha_composite(item,(x-item.width//2,y-item.height//2));comp=held.copy();comp.alpha_composite(im(d/f'hand_front/{side}_{i-1:02}.png'));rows.append((f'thief {side} steal{i}',[body,held,comp]))
canvas=Image.new('RGBA',(1140,30+len(rows)*220),'#6f8155');draw=ImageDraw.Draw(canvas)
for r,(label,imgs) in enumerate(rows):
 y=30+r*220;draw.text((5,y),label,font=fnt,fill='white')
 for i,o in enumerate(imgs):canvas.alpha_composite(o.resize((o.width*3,o.height*3),Image.Resampling.NEAREST),(180+i*320,y))
canvas.save(S/'layer-inspection.png')
result={'prior_png_verified':len(old),'png_counts':counts,'total_png':sum(counts.values()),'errors':errs,'runtime_verified':False,'adopted_idle_pixel_exact':True,'item_qa_reference':str(fossil.relative_to(P)) if fossil else None}
(S/'final-QA.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');assert not errs,errs
print(json.dumps(result,ensure_ascii=False))
