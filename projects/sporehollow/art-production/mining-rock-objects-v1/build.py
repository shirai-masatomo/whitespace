from pathlib import Path
from PIL import Image,ImageDraw,ImageChops,ImageFont
import numpy as np,json,hashlib,collections
S=Path(__file__).resolve().parent;P=S.parents[1];A=P/'art_delivery';D=A/'mining_rock_objects_v1';D.mkdir(exist_ok=True);R=D/'review';R.mkdir(exist_ok=True)
PAL=['#505247','#626252','#74705c','#85806b','#95907b','#a8a18a','#b9b198','#c9bfa5','#d8ceb4','#e1d6bc','#9c875f','#b6a17b']
def im(p):return Image.open(p).convert('RGBA')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
prior_file=S/'prior-hashes.json'
if not prior_file.exists():prior_file.write_text(json.dumps({p.relative_to(A).as_posix():sha(p) for p in A.rglob('*.png') if D not in p.parents},indent=2)+'\n')
prior=json.loads(prior_file.read_text());checks=[];records=[];normalization=[];bodies={}
def check(n,v):checks.append({'check':n,'passed':bool(v)});assert v,n
def binary(a):
 a=a.copy();a.putalpha(a.getchannel('A').point(lambda x:255 if x>=180 else 0));return a
def quant(a):
 ar=np.array(a);cols=np.array([tuple(bytes.fromhex(c[1:])) for c in PAL],dtype=np.int32);ids=((ar[:,:,:3].astype(np.int32)[:,:,None,:]-cols)**2).sum(3).argmin(2);ar[:,:,:3]=cols[ids];ar[:,:,3]=np.where(ar[:,:,3]>=145,255,0);ar[ar[:,:,3]==0]=0;return Image.fromarray(ar)
def connected(a):
 ar=np.array(a);mask=ar[:,:,3]>0;seen=set();components=[]
 for y,x in zip(*np.nonzero(mask)):
  if (int(x),int(y)) in seen:continue
  queue=[(int(x),int(y))];seen.add(queue[0]);component=[]
  while queue:
   x,y=queue.pop();component.append((x,y))
   for dx,dy in [(1,0),(-1,0),(0,1),(0,-1)]:
    xx,yy=x+dx,y+dy
    if 0<=xx<a.width and 0<=yy<a.height and mask[yy,xx] and (xx,yy) not in seen:seen.add((xx,yy));queue.append((xx,yy))
  components.append(component)
 main=max(components,key=len)
 for c in components:
  if c is not main:
   for x,y in c:ar[y,x]=0
 return Image.fromarray(ar)
def save(a,name,group,stage,anchor,footprint,**kw):
 ar=np.array(a);ar[ar[:,:,3]==0]=0;a=Image.fromarray(ar);f=D/name;a.save(f);bb=a.getbbox();count=int(np.count_nonzero(ar[:,:,3]));records.append(dict(file=name,group=group,stage=stage,size_px=list(a.size),anchor_px=list(anchor),footprint_cells=list(footprint),frame_order=[stage-1] if isinstance(stage,int) else [0],duration_ms=None,loop=False,rgba='straight alpha',sampling='nearest',ground_shadow_baked=False,visible_bbox_exclusive_px=list(bb),visible_size_px=[bb[2]-bb[0],bb[3]-bb[1]],opaque_pixel_count=count,sha256=sha(f),**kw));return a
settings={'large':dict(count=4,canvas=(224,240),anchor=(112,224),max_body=(188,192),footprint=(4,4),ground_rect=(16,64,192,168)), 'small':dict(count=3,canvas=(48,54),anchor=(24,46),max_body=(42,44),footprint=(1,1),ground_rect=(0,11,48,42))}
for group,cfg in settings.items():
 first=binary(im(S/f'originals/{group}_stage1.png'));bb=first.getbbox();factor=min(cfg['max_body'][0]/(bb[2]-bb[0]),cfg['max_body'][1]/(bb[3]-bb[1]));raw_center=(bb[0]+bb[2])/2;previous=None;bodies[group]=[]
 for stage in range(1,cfg['count']+1):
  src=S/f'originals/{group}_stage{stage}.png';a=binary(im(src));check(f'{group}{stage} source aspect preserved',abs(a.width/a.height-first.width/first.height)<.015)
  # Full-canvas normalization. No per-stage fitting or stretching of the remaining body.
  relative=first.width/a.width;scale=factor*relative;box=a.getbbox();out=Image.new('RGBA',cfg['canvas']);native=quant(a.resize((round(a.width*scale),round(a.height*scale)),Image.Resampling.BOX));dx=round(cfg['anchor'][0]-raw_center*factor);dy=cfg['anchor'][1]-round(box[3]*scale)
  out.alpha_composite(native,(dx,dy));out=connected(out)
  # Pixel registration: the same bottom ground-contact row in every frame.
  delta=cfg['anchor'][1]-out.getbbox()[3]
  if delta:reg=Image.new('RGBA',out.size);reg.alpha_composite(out,(0,delta));out=reg
  before=int(np.count_nonzero(np.array(out)[:,:,3]))
  if previous is not None:
   out.putalpha(ImageChops.multiply(out.getchannel('A'),previous.getchannel('A')));out=connected(out)
   contact_fix=cfg['anchor'][1]-out.getbbox()[3]
   check(f'{group}{stage} native contact correction <=3px',abs(contact_fix)<=3)
   if contact_fix:reg=Image.new('RGBA',out.size);reg.alpha_composite(out,(0,contact_fix));out=reg;delta+=contact_fix
  check(f'{group}{stage} same contact line',out.getbbox()[3]==cfg['anchor'][1])
  out=save(out,f'rock_{group}_{cfg["footprint"][0]}x{cfg["footprint"][1]}_stage{stage}.png',group,stage,cfg['anchor'],cfg['footprint'],ground_footprint_rect_px=list(cfg['ground_rect']),usage='Mining resource object; replace whole image at progress state, not a ground tile.',stage_progress='Existing implementation chooses transition thresholds; no HP or timing inferred.')
  if previous is not None:
   prev=np.array(previous)[:,:,3]>0;now=np.array(out)[:,:,3]>0
   check(f'{group}{stage} material area decreases',now.sum()<prev.sum()*.95)
   b=out.getbbox();pb=previous.getbbox();check(f'{group}{stage} shrinking silhouette bounds',b[0]>=pb[0] and b[1]>pb[1] and b[2]<=pb[2] and b[3]==pb[3])
   check(f'{group}{stage} height decreases',out.getbbox()[3]-out.getbbox()[1]<previous.getbbox()[3]-previous.getbbox()[1])
  normalization.append(dict(source=src.name,source_size=list(a.size),native_scale=scale,common_stage1_factor=factor,source_width_normalization=relative,offset_px=[dx,dy+delta],alpha_area_before_registration_clip=before,alpha_area_after=int(np.count_nonzero(np.array(out)[:,:,3])),final_bbox=list(out.getbbox())))
  bodies[group].append(out);previous=out
 # Required significant silhouette difference, not just HP cracks.
 check(group+' final area below 25% of intact',np.count_nonzero(np.array(bodies[group][-1])[:,:,3])<np.count_nonzero(np.array(bodies[group][0])[:,:,3])*.25)
# Aftermath uses a separate source on the large object's same original canvas/scale.
cfg=settings['large'];src=im(S/'originals/large_remains.png');first=im(S/'originals/large_stage1.png');bb=binary(first).getbbox();factor=min(188/(bb[2]-bb[0]),192/(bb[3]-bb[1]));scale=factor*first.width/src.width;native=quant(src.resize((round(src.width*scale),round(src.height*scale)),Image.Resampling.BOX));out=Image.new('RGBA',cfg['canvas']);box=binary(src).getbbox();out.alpha_composite(native,(round(112-(bb[0]+bb[2])/2*factor),224-round(box[3]*scale)))
remains=save(out,'rock_mined_remains.png','large_remains','depleted',cfg['anchor'],(4,4),ground_footprint_rect_px=list(cfg['ground_rect']),usage='Temporary visual aftermath; no resource/collision/quantity encoded.',occupancy_policy='0 occupied cells after depletion; 4x4 is art alignment only.')
# Small aftermath has its own original, not a squeezed 4x4 field.
src=im(S/'originals/small_remains.png');box=binary(src).getbbox();crop=src.crop(box);crop.thumbnail((36,17),Image.Resampling.BOX);out=Image.new('RGBA',(48,54));out.alpha_composite(quant(crop),(24-crop.width//2,46-crop.height));small_remains=save(out,'rock_small_1x1_mined_remains.png','small_remains','depleted',(24,46),(1,1),usage='Small deposit aftermath, separate ground visual.',occupancy_policy='0 occupied cells after depletion; 1x1 is art alignment only.')
for a in records:
 f=D/a['file'];o=im(f);ar=np.array(o);check(a['file']+' RGBA/size/hash',Image.open(f).mode=='RGBA' and list(o.size)==a['size_px'] and sha(f)==a['sha256']);check(a['file']+' alpha clean',set(np.unique(ar[:,:,3])).issubset({0,255}) and np.all(ar[ar[:,:,3]==0]==0));check(a['file']+' transparent frame margin',not np.any(ar[0,:,3]) and not np.any(ar[-1,:,3]) and not np.any(ar[:,0,3]) and not np.any(ar[:,-1,3]))
check('old artwork preserved',all(sha(A/p)==h for p,h in prior.items()))
manifest=dict(schema_version=1,delivery='mining_rock_objects_v1',branch='codex/sporehollow-art-assets',tile_size_px=[48,42],assets=records,animations={},runtime_verified=False,source='../../art-production/mining-rock-objects-v1/originals',pixel_palette=PAL,shadow='No ground cast shadow baked. Rock-face shading remains.',large_placement='Region top-left in world pixels + (96,160) - anchor(112,224). Art footprint = 4x4 cells. Do not infer blocker layout from alpha.',small_placement='Cell center + (0,14) - anchor(24,46).',state_order={'large':[1,2,3,4,'depleted'],'small':[1,2,3,'depleted']},splitting='These are whole-object progress sprites, NOT 16 auto-connect tiles. Spatial partial mining needs implementation masks/ownership; blind rectangular slicing is unsupported.',rules='No resource quantities, progress thresholds, removal delay, collision, save format or game rules are changed.')
(D/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf8');(D/'QA.json').write_text(json.dumps(dict(checks=checks,count=len(checks),prior_png_preserved=len(prior),normalization=normalization,actual_game_verified=False),indent=2)+'\n');(S/'normalization.json').write_text(json.dumps(normalization,indent=2)+'\n')
font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',13);title=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',18)
def background(size):
 o=Image.new('RGBA',size,'#798b51');return o
keeper=im(A/'characters_v1/keeper_idle_right_00.png');dog=im(A/'characters_v1/shiba_idle_right_00.png')
# Production native-size sequence. The transparent canvas stays identical.
large=bodies['large']+[remains];labels=['stage1：掘る前','stage2：少し削る','stage3：大幅に削る','stage4：完了直前','採掘後の残骸']
out=Image.new('RGBA',(1200,354),'#26382e');dr=ImageDraw.Draw(out);dr.text((12,7),'大岩山4×4｜原寸比較・同じ倍率と接地点｜素材合成であり実ゲーム画面ではありません',font=title,fill='#f0e6c8')
for i,o in enumerate(large):
 x=8+i*240;dr.text((x,40),labels[i],font=font,fill='white');tile=background((224,284));tile.alpha_composite(o,(0,0));tile.alpha_composite(keeper,(28,235));tile.alpha_composite(dog,(77,235));out.alpha_composite(tile,(x,63))
out.save(R/'large_stages_native.png')
# Shared-canvas alpha check, no grid burned into game PNGs.
alpha=Image.new('RGBA',(1120,510));dr=ImageDraw.Draw(alpha)
for row,bg in enumerate(['#26382e','#eee4cb']):
 dr.rectangle((0,row*255,1119,row*255+254),fill=bg)
 for i,o in enumerate(large):alpha.alpha_composite(o,(i*224,row*255+7))
alpha.save(R/'large_alpha_light_dark.png')
small=bodies['small']+[small_remains];out=Image.new('RGBA',(720,220),'#26382e');dr=ImageDraw.Draw(out);dr.text((12,7),'小岩山1×1｜左は原寸、右はnearest 2倍',font=title,fill='white')
for i,o in enumerate(small):
 x=12+i*178;tile=background((164,148));tile.alpha_composite(o,(6,55));tile.alpha_composite(o.resize((96,108),Image.Resampling.NEAREST),(63,1));out.alpha_composite(tile,(x,54));dr.text((x,33),'stage'+str(i+1) if i<3 else '採掘後',font=font,fill='white')
out.save(R/'small_stages.png')
# Footprint figure is explicitly comparison only, not an occupancy algorithm.
out=background((640,390));dr=ImageDraw.Draw(out);dr.text((12,8),'配置範囲の確認（枠は確認用／PNGには焼き込まない）',font=title,fill='white')
for y in range(5):dr.line((24,100+y*42,216,100+y*42),fill='#a7b97c')
for x in range(5):dr.line((24+x*48,100,24+x*48,268),fill='#a7b97c')
out.alpha_composite(bodies['large'][0],(8,36));out.alpha_composite(keeper,(249,220));out.alpha_composite(dog,(290,220));out.alpha_composite(bodies['small'][0],(391,220));dr.rectangle((391,231,438,272),outline='#a7b97c');dr.text((24,290),'4×4＝192×168 / 画像224×240',font=font,fill='white');dr.text((363,290),'1×1 / 画像48×54',font=font,fill='white');dr.text((12,342),'接地点固定。HP・資源量・採掘時間・判定は既存実装側で管理。',font=font,fill='white');out.save(R/'footprint_scale.png')
frames=[]
for o in large:
 f=background((320,300));f.alpha_composite(o,(48,12));f.alpha_composite(keeper,(19,239));f.alpha_composite(dog,(67,239));frames.append(f)
frames[0].save(R/'mining_progress.gif',save_all=True,append_images=frames[1:],duration=[900]*5,loop=0,disposal=2)
html='<!doctype html><meta charset="utf-8"><title>採掘対象の岩山</title><style>body{max-width:1240px;margin:24px auto;background:#26382e;color:#f4ead0;font:16px sans-serif}img{max-width:100%;image-rendering:pixelated}a{color:#e2c787}section{margin:28px 0}</style><h1>採掘対象の岩山：4×4 / 1×1</h1><p>オフライン素材比較。ゲーム実装・実ゲーム撮影ではありません。</p><p><a href="HANDOFF.md">納品書</a> · <a href="manifest.json">寸法・基準点・ファイル一覧</a></p>'
for f,t in [('large_stages_native.png','大岩山：同一キャンバス・原寸'),('mining_progress.gif','採掘段階：900msは比較用'),('small_stages.png','小岩山'),('footprint_scale.png','人物・柴犬との大きさと配置範囲'),('large_alpha_light_dark.png','暗色／明色での透過')]:html+=f'<section><h2>{t}</h2><img src="review/{f}"></section>'
html+='<h2>PNG個別ファイル</h2><ul>'+''.join(f'<li><a href="{a["file"]}">{a["file"]}</a></li>' for a in records)+'</ul>'
(D/'index.html').write_text(html,encoding='utf8')
print(json.dumps({'assets':len(records),'checks':len(checks),'prior':len(prior),'stages':[dict(file=a['file'],size=a['visible_size_px'],area=a['opaque_pixel_count']) for a in records]}))

