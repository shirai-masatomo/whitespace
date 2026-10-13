from pathlib import Path
from PIL import Image,ImageDraw,ImageChops,ImageFont
import numpy as np,json,hashlib
P=Path(__file__).resolve().parents[2];O=P/'art_delivery/colony_growth_assets_v1'
m=json.loads((O/'manifest.json').read_text(encoding='utf8'))
states=['healthy','light','medium','heavy'];icons=[]
for i,state in enumerate(states):
 p=P/'art_delivery/ui_world_direction_v1/candidates/world/goldA.png' if i==0 else O/f'idol/goldA_damage_{state}.png'
 body=Image.open(p).convert('RGBA').resize((58,64),Image.Resampling.NEAREST)
 im=Image.new('RGBA',(64,72));im.alpha_composite(body,(3,4))
 if i:
  layer=Image.new('RGBA',im.size);d=ImageDraw.Draw(layer)
  # Explicit UI-only pixel cleanup keeps short cracks readable, without magnifying the world body's damage.
  paths=[[(24,31),(27,34),(25,37)],[(42,54),(40,57),(43,60)]]
  if i>=2:paths += [[(39,30),(42,35),(40,39),(43,42)]]
  if i==3:paths += [[(22,42),(27,46),(24,51)]]
  for pts in paths:d.line(pts,fill='#422b19',width=2)
  layer.putalpha(ImageChops.multiply(layer.getchannel('A'),im.getchannel('A')));im.alpha_composite(layer)
 out=O/f'idol/ui_64x72_{state}.png';im.save(out);icons.append(im)
 row=dict(file=out.relative_to(O).as_posix(),size_px=[64,72],anchor_px=[32,65],occupancy_cells=None,layer='ui',action=state,frame_order=[0],frame_duration_ms=[None],loop=False,duration_mode='hold_until_state_change',sha256=hashlib.sha256(out.read_bytes()).hexdigest(),source=str(p.relative_to(P)),use='small UI only: retouched cracks at target resolution; do not use as world sprite')
 m['assets']=[a for a in m['assets'] if a['file']!=row['file']]+[row]
 assert set(np.unique(np.array(im)[:,:,3]))<={0,255}
(O/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf8')
# Replace only the small UI area of the approved-world comparison; exact saved screen remains underneath.
path=O/'preview_idol_4states.png';sheet=Image.open(path).convert('RGBA')
base=Image.open(P/'art-production/colony-growth-previews-v2/references/01_field.png').convert('RGBA')
for x,im in zip([190,490,790,1090],icons):
 # Previous row was local y618..682, main image offset 80.
 sheet.paste(base.crop((x-40,610,x+40,691)),(x-40,690))
 sheet.alpha_composite(im,(x-32,690))
 d=ImageDraw.Draw(sheet);d.rectangle((x-65,774,x+73,799),fill='#243b31')
 d.text((x-61,777),'UI専用：64×72',font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',13),fill='#eee0bd')
sheet.convert('RGB').save(path)
# Supplemental native UI comparison with one-click expandable 3x view.
proof=Image.new('RGB',(900,490),'#e5d8b5');d=ImageDraw.Draw(proof);font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',17)
d.text((16,8),'黄金像 UI専用64×72：亀裂を小表示で再調整（未実装）',font=font,fill='#3f4733')
for i,(state,im) in enumerate(zip(['健常','軽損傷','中損傷','重損傷'],icons)):
 x=20+i*220
 proof.paste(im,(x+60,58),im);z=im.resize((192,216),Image.Resampling.NEAREST);proof.paste(z,(x,190),z)
 d.text((x+45,140),state,font=font,fill='#3f4733')
proof.save(O/'review_idol_ui.png')
q=json.loads((O/'QUALITY_REVIEW.json').read_text(encoding='utf8'))
q['checks']=[c for c in q['checks'] if not c.startswith('idol/ui_')]
for state in states:q['checks'] += [f'idol/ui_{state}:binary_RGBA',f'idol/ui_{state}:registered64x72']
q['passed']=len(q['checks'])
(O/'QUALITY_REVIEW.json').write_text(json.dumps(q,ensure_ascii=False,indent=2),encoding='utf8')
for n in ['ASSET_LIST.md','HANDOFF.md','index.html']:
 t=(O/n).read_text(encoding='utf-8-sig').replace('24点','28点').replace('静止・接触24','静止・接触28')
 (O/n).write_text(t,encoding='utf8')
with (O/'HANDOFF.md').open('a',encoding='utf8') as f:f.write('\n## 黄金像の小UI専用4枚\n64×72/(32,65)。盤面144×160版の単純縮小では亀裂が薄れるため、小UIだけ2pxの亀裂へ整理。健常・軽・中・重を同じ枠に収め、個別bboxで拡大しない。小UI専用版は盤面へ使わない。[専用比較](review_idol_ui.png)。\n')
with (O/'PREVIEW_INDEX.md').open('a',encoding='utf8') as f:f.write('\n[黄金像UI専用64×72の1倍・3倍](review_idol_ui.png)。軽い亀裂は小表示だけ再調整しました。\n')
print('4 UI icons finalized')
