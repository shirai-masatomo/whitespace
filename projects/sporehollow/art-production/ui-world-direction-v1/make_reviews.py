from build import *
import numpy as np
from PIL import ImageFilter
records=json.loads((S/'generation-records.json').read_text(encoding='utf-8-sig'))
extra=S/'records-extra.json'
if extra.exists():
 records+=json.loads(extra.read_text(encoding='utf-8-sig'));extra.unlink()
 unique={r['id']:r for r in records}
 (S/'generation-records.json').write_text(json.dumps(list(unique.values()),ensure_ascii=False,indent=2),encoding='utf-8')
def src(id):return Image.open(S/'originals'/f'{id}.png').convert('RGBA')
def clean(im,t=200):
 im=im.copy(); a=im.getchannel('A').point(lambda v:255 if v>=t else 0);im.putalpha(a);return im
def cell(im,i,cols,rows):
 x=i%cols;y=i//cols
 return im.crop((round(x*im.width/cols),round(y*im.height/rows),round((x+1)*im.width/cols),round((y+1)*im.height/rows)))
def put(id,im,canvas,anchor,extent,folder):
 im=native(clean(im),canvas,anchor,extent);im.save(D/f'candidates/{folder}/{id}.png');return im
for id in ['shiba','hen','cat','salaryman','destroyer','doberman']:
 im=src('portrait_'+id)
 put(id,im,(192,192),(96,184),(176,176),'portraits')
for i,id in enumerate(['common','uncommon','rare','epic','legendary']):
 put('rarity_'+id,cell(src('rarity_atlas'),i,5,1),(64,64),(32,60),(56,56),'ui')
# Exact frame edge crop excludes outer glow. Masks only cut outside corners; cream paper stays opaque.
for i,id in enumerate(['skill_bark','skill_destruction','skill_reinforcement','ultimate_rage','ultimate_resurrection','ultimate_frame']):
 im=cell(src('skills_atlas_fixed'),i,3,2)
 box=(60,64,488,446) if i<3 else (58,4,486,418)
 im=im.crop(box);im=clean(im,170)
 mask=Image.new('L',im.size); md=ImageDraw.Draw(mask);md.rounded_rectangle((0,0,im.width-1,im.height-1),radius=25,fill=255)
 if i==5:md.rectangle((50,50,im.width-52,im.height-50),fill=0)
 im.putalpha(Image.fromarray(np.minimum(np.array(im.getchannel('A')),np.array(mask))))
 put(id,im,(64,64),(32,60),(56,56),'ui')
for i,(id,cs,an,ex) in enumerate([('ready_aura',(48,24),(24,22),(44,18)),('ready_stars',(24,24),(12,22),(20,20)),('ready_corners',(192,192),(96,190),(188,188)),('stamina_lightning',(24,24),(12,22),(20,20)),('stamina_shoe',(24,24),(12,22),(20,20))]):
 im=cell(src('readiness_atlas'),i,3,2);put(id,clean(im,225),cs,an,ex,'ui')
for id,cs,an,ex in [('cow',(80,64),(40,58),(72,48)),('kokeshi',(32,40),(16,36),(24,32)),('fossil',(48,40),(24,36),(40,30))]:put(id,src(id),cs,an,ex,'new')
# Concept cells only: first pose of each requested storyboard source.
sheets={'maid':('maid_sheet',4,4),'dancer':('dancer_sheet',6,2),'thief':('thief_sheet',4,3),'bull':('bull_sheet',4,2)}
for id,(sheet,cols,rows) in sheets.items():
 cs,an,ex=((80,64),(40,58),(72,40)) if id=='bull' else ((64,64),(32,58),(50,42))
 put(id,cell(src(sheet),0,cols,rows),cs,an,ex,'new')
build_world()
# Native readability touchups of small faces / anchors, only new review candidates.
for id in ['maid','dancer','thief']:
 p=D/f'candidates/new/{id}.png';im=Image.open(p);a=np.array(im.getchannel('A'));bbox=im.getbbox()
 # Keep the darkest connected silhouette opaque: never white-key. Record actual bbox later.
 im.save(p)
# Complete but provisional layer split at a horizontal cut; recomposes byte-exactly.
for id in ['tree_a','tree_b','tree_c']:
 im=Image.open(D/f'candidates/world/{id}.png').convert('RGBA')
 ycut={'tree_a':51,'tree_b':52,'tree_c':50}[id]
 canopy=im.copy();canopy.paste((0,0,0,0),(0,ycut,64,80))
 trunk=im.copy();trunk.paste((0,0,0,0),(0,0,64,ycut))
 canopy.save(D/f'candidates/world/{id}_canopy.png');trunk.save(D/f'candidates/world/{id}_trunk.png')
# Fonts are review-only. No letters in any candidate.
fontpath='C:/Windows/Fonts/meiryo.ttc'
def font(n):return ImageFont.truetype(fontpath,n)
def label(im,xy,s,n=18,col='#e7dcc0'):ImageDraw.Draw(im).text(xy,s,font=font(n),fill=col)
def panel(w,h):return Image.new('RGBA',(w,h),'#242c29')
def paste(im,obj,x,y,scale=1):
 if scale!=1:obj=obj.resize((obj.width*scale,obj.height*scale),Image.Resampling.NEAREST)
 im.alpha_composite(obj,(x,y))
def cand(folder,id):return Image.open(D/f'candidates/{folder}/{id}.png').convert('RGBA')
keeper=Image.open(P/'art_delivery/characters_v1/keeper_idle_right_00.png').convert('RGBA')
shiba=Image.open(P/'art_delivery/characters_v1/shiba_idle_right_00.png').convert('RGBA')
farm=Image.open(S/'references/farm-day.png').convert('RGBA')
# A idols at1x and3x, literal cell footprintguide is preview-only.
im=panel(1200,690);label(im,(24,16),'A  黄金像 2案 — 原寸 / 2倍 nearest・方向確認',24)
for j,id in enumerate(['goldA','goldB']):
 x=30+j*590;label(im,(x,58),'A：裂けた口・枝角' if j==0 else 'B：甲殻・鉤脚',20)
 bg=farm.crop((240,260,520,470));ob=cand('world',id);bg.alpha_composite(ob,(85,20));paste(bg,keeper,25,128);paste(bg,shiba,200,128);paste(im,bg,x,95)
 paste(im,ob,x+88,310,2)
label(im,(24,652),'全案 144×160 / 接地(72,152) / 論理2×2。採用前・ゲーム未統合。',17)
im.save(D/'preview/A_idols.png')
# B trees native and4x, composition built from repeatable pieces, not a fixed production map.
im=panel(1100,440);label(im,(20,15),'B  木3種 — 原寸と4倍 / 共通足元(32,72)',24)
for j,id in enumerate(['tree_a','tree_b','tree_c']):
 x=30+j*360;label(im,(x,58),['古木','成木','若木'][j]);paste(im,cand('world',id),x,100);paste(im,cand('world',id),x+82,95,4)
im.save(D/'preview/B_trees.png')
tile=farm.crop((280,250,328,292))
forest=Image.new('RGBA',(1280,800))
for y in range(0,800,42):
 for x in range(0,1280,48):paste(forest,tile,x,y)
# dark outer ground and canopy repeated in rows. All composition coordinates recorded through source.
ar=np.array(forest);yy,xx=np.indices((800,1280));dist=np.maximum(abs(xx-640)/640,abs(yy-400)/400);factor=1.0-.45*np.clip((dist-.50)/.36,0,1);ar[:,:,:3]=(ar[:,:,:3]*factor[:,:,None]).astype('uint8');forest=Image.fromarray(ar)
rng=random.Random(174)
placements=[]
for y in range(45,865,38):
 for x in range(-20,1320,42):
  d=max(abs(x-640)/640,abs(y-400)/400)
  if d>.78:placements.append((x+rng.randrange(-10,11),y,rng.choice(['tree_a','tree_b'])))
for x,y,id in sorted(placements,key=lambda a:a[1]):
 ob=cand('world',id); ar=np.array(ob);ar[:,:,:3]=(ar[:,:,:3]*.65).astype('uint8');paste(forest,Image.fromarray(ar),x-32,y-72)
for x,y,id in [(220,190,'tree_a'),(340,135,'tree_c'),(500,145,'tree_b'),(750,150,'tree_a'),(1010,205,'tree_b'),(1090,370,'tree_a'),(980,580,'tree_c'),(800,660,'tree_a'),(430,640,'tree_b'),(265,575,'tree_a'),(180,375,'tree_c')]:
 paste(forest,cand('world',id),x-32,y-72)
paste(forest,cand('world','goldA'),568,278);paste(forest,keeper,465,424);paste(forest,shiba,510,424)
label(forest,(26,16),'B  森の構成案：中央の牧場 → 点在する木 → 濃い森の奥',22)
label(forest,(26,758),'部品のオフライン合成。地形・侵入口・衝突は未検証。固定背景として取り込まない。',17)
forest.save(D/'preview/B_forest_composition.png')
forest.resize((640,400),Image.Resampling.NEAREST).save(D/'preview/B_forest_zoomout_50pct.png')
# Portraits native192 and96/48 comparison.
im=panel(1240,700);label(im,(20,16),'C  Portrait — 192px原寸 / 96px / 48px nearest',24)
for j,id in enumerate(['shiba','hen','cat','salaryman','destroyer','doberman']):
 x=20+(j%3)*410;y=65+(j//3)*315;label(im,(x,y),id,18);ob=cand('portraits',id)
 paste(im,ob,x,y+30);paste(im,ob.resize((96,96),Image.Resampling.NEAREST),x+210,y+35);paste(im,ob.resize((48,48),Image.Resampling.NEAREST),x+315,y+35)
im.save(D/'preview/C_portraits.png')
im=panel(1160,630);label(im,(20,16),'D/E  Rarity・Skill・Ultimate・Stamina の方向確認',24)
for j,id in enumerate(['common','uncommon','rare','epic','legendary']):
 x=25+j*220;label(im,(x,56),id);paste(im,cand('ui','rarity_'+id),x,90,2);paste(im,cand('ui','rarity_'+id),x+140,100)
for j,id in enumerate(['skill_bark','skill_destruction','skill_reinforcement','ultimate_rage','ultimate_resurrection','ultimate_frame']):
 x=25+j*185;label(im,(x,250),['吠える','破壊','応援要請','激ギレ（案）','蘇生（案）','共通枠'][j],16);paste(im,cand('ui',id),x,280,2)
for j,id in enumerate(['ready_aura','ready_stars','ready_corners','stamina_lightning','stamina_shoe']):
 x=25+j*220;label(im,(x,440),id,15);ob=cand('ui',id)
 if id=='ready_corners':ob=ob.resize((96,96),Image.Resampling.NEAREST);paste(im,ob,x,477)
 else:paste(im,ob,x,485,3)
im.save(D/'preview/DE_ui.png')
# New concepts: true native1x plus4x. Current keeper and Shiba are unchanged reference files.
im=panel(1700,740);label(im,(20,16),'F  新規7種 — 基本姿の方向確認 / 原寸＋4倍',24)
for j,id in enumerate(['maid','dancer','thief','cow','bull','kokeshi','fossil']):
 x=25+(j%4)*420;y=65+(j//4)*315;label(im,(x,y),id);ob=cand('new',id);paste(im,ob,x,y+35);paste(im,ob,x+80,y+28,4)
paste(im,keeper,1350,440);paste(im,shiba,1400,440);label(im,(1320,520),'既存主人公v1・柴犬C',16)
im.save(D/'preview/F_concepts.png')
# Storyboards preserve source artwork and narrative ordering, explicitly NOT runtime frames.
stories=[
 ('maid_coffee','maid_sheet',4,4,list(range(1,8)),['持つ','回る','配る','1秒停止の姿','次へ向く','自分で飲む','休憩']),
 ('maid_rage','maid_sheet',4,4,list(range(8,15)),['通常','怒り','包丁を出す','前傾','高速追跡','攻撃','落ち着く']),
 ('dancer_dance','dancer_sheet',6,2,list(range(1,6)),['構える','扇を開く','旋回','舞う','風・支援']),
 ('dancer_resurrection','dancer_sheet',6,2,list(range(6,11)),['対象へ向く','舞を開始','扇を広げる','対象へ光','対象が起きる']),
 ('thief_steal','thief_sheet',4,3,list(range(1,6)),['発見','しゃがむ','拾う','袋へ入れる','逃走']),
 ('thief_poison','thief_sheet',4,3,list(range(6,12)),['取り出す','振りかぶる','投げる','瓶飛翔','破裂','薄い毒雲']),
 ('bull_charge','bull_sheet',4,2,list(range(1,7)),['地面を蹴る','頭を下げる','開始','全速直進','接触','減速'])]
storymeta=[]
for id,sheet,cols,rows,indices,names in stories:
 out=panel(len(indices)*220,345);label(out,(15,10),id+' / 絵コンテ・非本番',20)
 for j,(i,name) in enumerate(zip(indices,names)):
  ob=clean(cell(src(sheet),i,cols,rows),190);bb=ob.getbbox()
  if bb:ob=ob.crop(bb)
  sc=min(196/ob.width,232/ob.height);ob=ob.resize((round(ob.width*sc),round(ob.height*sc)),Image.Resampling.NEAREST)
  paste(out,ob,j*220+(220-ob.width)//2,285-ob.height)
  label(out,(j*220+8,302),str(j+1)+'. '+name,16)
 out.save(D/f'storyboards/{id}.png')
 storymeta.append({'action':id,'file':f'storyboards/{id}.png','source':sheet+'.png','source_grid':[cols,rows],'source_cells_zero_based':indices,'order':names,'frame_duration_ms':None,'loop':False,'runtime_ready':False,'note':'Narrative keyposes only; not animation frames. Timing and layers must be finalized after adoption.'})
(D/'storyboards/index.json').write_text(json.dumps(storymeta,ensure_ascii=False,indent=2),encoding='utf-8')
print('built',D)

