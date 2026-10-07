from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import numpy as np,json,hashlib,math
S=Path(__file__).parent;P=S.parents[1];D=P/'art_delivery/two_direction_review_v1'
for sub in ['sheets','poses','native','layers']:(D/sub).mkdir(parents=True,exist_ok=True)
V1=P/'art-production/ui-world-direction-v1/originals';V2=P/'art-production/ui-world-direction-v2/originals'
meta=[];extracts=[]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):return Image.open(p).convert('RGBA')
def clean(im):
 im=im.copy();im.putalpha(im.getchannel('A').point(lambda a:255 if a>=200 else 0));return im

def components(path,count):
 im=load(path);ar=np.array(im);on=ar[:,:,3]>=200;seen=np.zeros(on.shape,bool);h,w=on.shape;parts=[]
 for y,x in zip(*np.where(on)):
  if seen[y,x]:continue
  q=[(int(x),int(y))];seen[y,x]=True;pts=[]
  while q:
   xx,yy=q.pop();pts.append((xx,yy))
   for nx,ny in [(xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)]:
    if 0<=nx<w and 0<=ny<h and on[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;q.append((nx,ny))
  if len(pts)>1500:parts.append(pts)
 parts=sorted(parts,key=len,reverse=True)[:count];out=[]
 for pts in parts:
  xs,ys=zip(*pts);box=(min(xs),min(ys),max(xs)+1,max(ys)+1);mask=np.zeros(on.shape,np.uint8)
  mask[np.array(ys),np.array(xs)]=255
  cp=im.copy();cp.putalpha(Image.fromarray(mask));cp=cp.crop(box)
  out.append((box,cp));extracts.append({'source':path.relative_to(P).as_posix(),'bbox':box,'opaque_pixels':len(pts)})
 print(path.name,[(b,o.size) for b,o in out],flush=True)
 return out

def gridcell(path,index,cols,rows):
 im=load(path);x=index%cols;y=index//cols
 cp=clean(im.crop((round(x*im.width/cols),round(y*im.height/rows),round((x+1)*im.width/cols),round((y+1)*im.height/rows))))
 return cp.crop(cp.getbbox())

def native(ob,canvas,anchor,scale):
 w,h=max(1,round(ob.width*scale)),max(1,round(ob.height*scale));assert w<=canvas[0] and h<=anchor[1],(w,h,canvas)
 im=ob.resize((w,h),Image.Resampling.NEAREST);a=im.getchannel('A')
 im=im.convert('RGB').quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGBA');im.putalpha(a)
 out=Image.new('RGBA',canvas);out.alpha_composite(im,(anchor[0]-w//2,anchor[1]-h));return out

def add(target,action,label,ob,cs=(64,64),an=(32,58),scale=None,exact=None,direction='right',source='',method='alpha_component_and_proportional_nearest'):
 for folder in ['poses','native']:(D/folder/target).mkdir(exist_ok=True)
 ob.save(D/f'poses/{target}/{action}.png')
 ni=load(P/exact) if exact else native(ob,cs,an,scale if scale is not None else min((cs[0]-4)/ob.width,42/ob.height))
 assert ni.size==cs
 ni.save(D/f'native/{target}/{action}.png')
 a={'asset_id':f'{target}.{action}','target':target,'action':action,'label':label,'direction':direction,'pose_file':f'poses/{target}/{action}.png','file':f'native/{target}/{action}.png','canvas':list(cs),'anchor':list(an),'world_or_ui':'world_preview','frame_order':[0],'frame_duration_ms':None,'loop':False,'runtime_ready':False,'status':'direction_review_only','method':'exact_existing_png' if exact else method,'source':exact or source,'layers':['body_with_props'],'shadow':'no added ground shadow','visible_bbox_exclusive':ni.getbbox(),'sha256':sha(D/f'native/{target}/{action}.png'),'pose_sha256':sha(D/f'poses/{target}/{action}.png')}
 meta.append(a);return a

def left_of(a,label):
 ob=ImageOps.mirror(load(D/a['pose_file']));ni=ImageOps.mirror(load(D/a['file']));act=a['action'].replace('right','left')
 b=add(a['target'],act,label,ob,tuple(a['canvas']),(a['canvas'][0]-a['anchor'][0],a['anchor'][1]),direction='left',scale=min((a['canvas'][0]-4)/ob.width,42/ob.height),source=a['file'],method='horizontal_mirror_of_right')
 ni.save(D/b['file']);b['visible_bbox_exclusive']=ni.getbbox();b['sha256']=sha(D/b['file']);return b

# Preserve exact adopted right-facing basic poses; derive only matching left-facing review pose.
old={}
for who in ['maid','dancer','thief']:
 path=V2/(who+'_revision.png');parts=components(path,4 if who=='maid' else 5 if who=='dancer' else 3)
 if who=='maid':parts=sorted(parts,key=lambda z:(z[0][1]//650,z[0][0]))
 else:parts=sorted(parts,key=lambda z:z[0][0])
 old[who]=parts
 a=add(who,'idle_right','右向き 基本姿',parts[0][1],exact=f'art_delivery/ui_world_direction_v2/candidates/{who}/idle.png',source=str(path))
 left_of(a,'左向き 基本姿')
# Merchant sprite is the already delivered native art. Large view uses same pixels, never a new face.
mer=load(P/'art_delivery/merchant_cart_v2/merchant/idle_right_00.png')
a=add('merchant','idle_right','商人 右向き',mer.crop(mer.getbbox()),(32,48),(16,44),exact='art_delivery/merchant_cart_v2/merchant/idle_right_00.png')
left_of(a,'商人 左向き')
cart=load(P/'art_delivery/cart_ui_detail_v1/cart.png')
a=add('merchant','cart_move_right','荷車 右へ進む姿',cart.crop(cart.getbbox()),(128,96),(64,88),exact='art_delivery/merchant_board_v1/cart_idle_00.png')
a['pose_source']='art_delivery/cart_ui_detail_v1/cart.png';a['contains_merchant']=True;a['note']='Orientation only; translation and wheel animation not made.'
b=left_of(a,'荷車 左へ進む姿');b['contains_merchant']=True;b['note']=a['note']
# Supplement poses. Common scale per sheet retains posture-height differences.
mp=components(S/'originals/maid_supplement.png',4)
mp=sorted(mp,key=lambda z:(0 if z[0][1]<600 else 1,z[0][0]));ms=42/mp[0][1].height
for (act,label),(_,ob) in zip([('coffee_serve_right','Skill：コーヒー配布'),('twirl_right','回転：横向きの代表姿勢'),('drink_right','自分で飲む'),('cleaver_attack_right','包丁攻撃')],mp):
 add('maid',act,label,ob,scale=ms,source='art-production/two-direction-review-v1/originals/maid_supplement.png')
add('maid','rage_right','Ultimate：激ギレ',old['maid'][1][1],exact='art_delivery/ui_world_direction_v2/candidates/maid/rage.png')
aura=load(P/'art_delivery/ui_world_direction_v2/candidates/maid/rage_aura.png');aura.save(D/'layers/maid_rage_aura.png')
# New dance and melee are supplementary; resurrection reuses approved raised-fan pose.
dp=sorted(components(S/'originals/dancer_supplement.png',2),key=lambda z:z[0][0]);ds=42/(dp[0][0][3]-150)
for (act,label),(_,ob) in zip([('dance_right','Skill：舞'),('fan_attack_right','通常攻撃：扇近接')],dp):add('dancer',act,label,ob,scale=ds,source='art-production/two-direction-review-v1/originals/dancer_supplement.png')
add('dancer','resurrection_right','Ultimate：復活の舞',old['dancer'][2][1],exact='art_delivery/ui_world_direction_v2/candidates/dancer/fan_spread.png')
# Steal pose reuses adoption, no new fossil or target is baked into new attacks.
tp=sorted(components(S/'originals/thief_supplement.png',2),key=lambda z:z[0][0]);ts=42/max(ob.height for _,ob in tp)
add('thief','dagger_attack_right','通常攻撃：ダガー',tp[0][1],scale=ts,source='art-production/two-direction-review-v1/originals/thief_supplement.png')
add('thief','steal_right','特殊：盗み',old['thief'][1][1],exact='art_delivery/ui_world_direction_v2/candidates/thief/steal.png')
add('thief','poison_throw_right','Skill：毒瓶投擲',tp[1][1],scale=ts,source='art-production/two-direction-review-v1/originals/thief_supplement.png')
proj=load(P/'art_delivery/ui_world_direction_v1/candidates/new/poison_projectile.png');proj.save(D/'layers/poison_projectile.png')
# Cows keep the already accepted relative scale (48px visible cow /40px bull).
co=clean(load(V1/'cow.png'));co=co.crop(co.getbbox())
a=add('cow','idle_right','右向き 基本姿',co,(80,64),(40,58),exact='art_delivery/ui_world_direction_v1/candidates/new/cow.png');left_of(a,'左向き 基本姿')
cm=components(S/'originals/cow_supplement.png',1)[0][1]
add('cow','milking_right','搾乳時：後脚を引き静止',cm,(80,64),(40,58),scale=48/cm.height,source='art-production/two-direction-review-v1/originals/cow_supplement.png')
bo=gridcell(V1/'bull_sheet.png',0,4,2);bs=40/bo.height
a=add('bull','idle_right','右向き 基本姿',bo,(80,64),(40,58),exact='art_delivery/ui_world_direction_v1/candidates/new/bull.png');left_of(a,'左向き 基本姿')
for i,act,label in [(2,'charge_ready_right','突撃構え'),(4,'charge_right','Skill：突撃'),(7,'guts_right','根性：前傾・荒い呼吸')]:
 add('bull',act,label,gridcell(V1/'bull_sheet.png',i,4,2),(80,64),(40,58),scale=bs,source=f'art-production/ui-world-direction-v1/originals/bull_sheet.png#cell={i}')

# One sheet per requested subject; merchant sheet includes the cart's two directions.
def font(n):return ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',n)
def txt(im,xy,t,n=19,color='#e9deca'):ImageDraw.Draw(im).text(xy,t,font=font(n),fill=color)
def composite(im,ob,x,y):im.alpha_composite(ob,(int(x),int(y)))
order=['merchant','maid','dancer','thief','cow','bull']
names={'merchant':'商人・荷車','maid':'メイド','dancer':'舞姫','thief':'盗賊','cow':'乳牛','bull':'闘牛'}
sheetmeta=[]
for who in order:
 aa=[a for a in meta if a['target']==who]
 if who=='maid':aa=sorted(aa,key=lambda a:['idle_right','idle_left','coffee_serve_right','twirl_right','drink_right','rage_right','cleaver_attack_right'].index(a['action']))
 cols=4 if who=='maid' else 2 if who=='merchant' else 3
 rows=math.ceil(len(aa)/cols);cw=400 if who=='maid' else 500;ch=490
 out=Image.new('RGBA',(cols*cw,110+rows*ch+115),'#252d29')
 txt(out,(22,14),f'{names[who]} — 左右2方向・代表姿勢確認',28)
 txt(out,(22,60),'採用済みデザイン維持 / 正面・背面なし / 正式連番の制作前',18)
 for j,a in enumerate(aa):
  x=j%cols*cw;y=110+j//cols*ch
  ImageDraw.Draw(out).rounded_rectangle((x+9,y+2,x+cw-9,y+ch-8),radius=12,fill='#313a32')
  txt(out,(x+22,y+12),a['label'],19)
  ob=load(D/a['pose_file']);sc=min((cw-52)/ob.width,290/ob.height)
  pic=ob.resize((round(ob.width*sc),round(ob.height*sc)),Image.Resampling.NEAREST)
  if who=='maid' and a['action'] in ['rage_right','cleaver_attack_right']:
   au=aura.resize((310,310),Image.Resampling.NEAREST);composite(out,au,x+(cw-310)//2,y+46)
  composite(out,pic,x+(cw-pic.width)//2,y+345-pic.height)
  ni=load(D/a['file']);mini=ni.copy()
  if who=='maid' and a['action'] in ['rage_right','cleaver_attack_right']:
   mini=Image.new('RGBA',ni.size);mini.alpha_composite(aura);mini.alpha_composite(ni)
  if who=='thief' and a['action']=='poison_throw_right':
   # Independent projectile shown beside hand only on review, not baked into body.
   pp=proj.resize((64,48),Image.Resampling.NEAREST);composite(out,pp,x+cw-75,y+90)
  baseline=y+449
  composite(out,mini,x+27,baseline-a['anchor'][1]);mult=1 if who=='merchant' and 'cart' in a['action'] else 2
  nn=mini.resize((mini.width*mult,mini.height*mult),Image.Resampling.NEAREST)
  composite(out,nn,x+cw-nn.width-24,baseline-a['anchor'][1]*mult)
  ImageDraw.Draw(out).line((x+18,baseline,x+cw-18,baseline),fill='#7a9475')
  txt(out,(x+20,y+464),f"原寸 / {mult}倍   {a['canvas'][0]}×{a['canvas'][1]}  足元{tuple(a['anchor'])}",12)
 notes={'merchant':['右／左は牽引棒の向き。車輪回転・歩行フレームではなく、進行方向の確認。','荷車には商人が含まれる。別の商人を重ねて二人表示にしない。'],
 'maid':['激ギレの赤オーラは独立レイヤー。コーヒー支援中はオーラ・包丁を表示しない。','回転は側面キーポーズで確認。正面／背面の方向枠は作らない。'],
 'dancer':['復活対象・生命光は別レイヤー。扇近接と支援の舞を区別。','今回のポーズは代表姿勢。左右それぞれの連続動作は採用後。'],
 'thief':['毒瓶の飛翔は別PNG。投擲後の手は空にする。','盗みの灰色物体は既存原画の仮表現。正式化時は実際の品を別レイヤーで保持。'],
 'cow':['搾乳姿勢は乳牛本体のみ。乳房側の空間へ作業者・容器を別に配置する。','非戦闘の乳牛へ通常攻撃・Skill・Ultimateの姿勢を追加しない。'],
 'bull':['根性は姿勢と荒い呼吸で区別。全身の赤発光にしない。','突撃構え・全速の代表姿勢を再利用。正式な走行周期や命中判定とは区別。']}[who]
 for k,n in enumerate(notes):txt(out,(22,110+rows*ch+8+k*29),n,16)
 f=f'sheets/{order.index(who)+1:02d}_{who}.png';out.save(D/f)
 sheetmeta.append({'target':who,'file':f,'canvas':list(out.size),'poses':[a['asset_id'] for a in aa],'sha256':sha(D/f),'runtime_ready':False})
# Metadata and review index.
layers=[]
for n,an in [('maid_rage_aura',[32,58]),('poison_projectile',[16,12])]:
 im=load(D/f'layers/{n}.png');layers.append({'asset_id':n,'file':f'layers/{n}.png','canvas':list(im.size),'anchor':an,'frame_order':[0],'frame_duration_ms':None,'loop':False,'runtime_ready':False,'sha256':sha(D/f'layers/{n}.png')})
manifest={'schema_version':1,'delivery':'two_direction_review_v1','date':'2026-10-08','branch':'codex/sporehollow-art-assets','status':'awaiting_two_direction_review','assets':[],'review_assets':meta,'sheets':sheetmeta,'separate_layers':layers,'allowed_directions':['right','left'],'excluded_directions':['front','back'],'rendering':{'filter':'nearest','alpha':'ordinary RGBA','white_key':False,'preserve_padding':True},'formal_motion_gate':'Only after adoption of these direction sheets. Do not interpret representative poses as finished cycles.','implementation_reference':'f6a60ee525cbe63d962a06280a7d7a9533d69d66','remaining':['Direction-sheet adoption.','Per-action left/right formal animation frames, consistent pixel finish, sockets, FX separation and timings.','Runtime integration and isolated-render validation.'],'sources':'../../art-production/two-direction-review-v1/generation-records.json'}
(D/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(S/'extraction.json').write_text(json.dumps(extracts,indent=2)+'\n',encoding='utf-8')
html='<!doctype html><meta charset="utf-8"><title>左右方向確認 v1</title><style>body{background:#252d29;color:#eee4ce;font:18px sans-serif;margin:24px}img{max-width:100%;height:auto}a{color:#e7c579}section{margin:40px 0}</style><h1>左右方向確認 v1</h1><p>6対象・各1枚。方向確認用、正式モーション未制作。</p>'
html+='<nav>'+' / '.join(f'<a href="#{w}">{names[w]}</a>' for w in order)+'</nav>'
for a in sheetmeta:html+=f'<section id="{a["target"]}"><h2>{names[a["target"]]}</h2><img src="{a["file"]}"></section>'
(D/'index.html').write_text(html,encoding='utf-8')
print('saved',len(meta),'keyposes;',len(sheetmeta),'sheets',flush=True)
