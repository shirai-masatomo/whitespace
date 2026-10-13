from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps,ImageChops,ImageFilter
import numpy as np,json,hashlib,shutil
P=Path(__file__).resolve().parents[2];S=Path(__file__).resolve().parent;D=P/'art_delivery';O=D/'colony_growth_assets_v1'
W=P/'art-production/colony-growth-previews-v2/working'
M=json.loads((W.parent/'working_manifest.json').read_text(encoding='utf8'))
N=Image.Resampling.NEAREST;F=lambda n:ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',n)
assets=[];checks=[];reuses=[]
def load(p):return Image.open(p).convert('RGBA')
def work(n):return load(W/(n+'.png'))
def save(im,name,anchor,use,occupancy=None,layer='world_object',action='static',source=None,**extra):
 p=O/name;p.parent.mkdir(parents=True,exist_ok=True)
 arr=np.array(im);arr[arr[:,:,3]==0]=0;im=Image.fromarray(arr)
 im.save(p)
 assert im.mode=='RGBA' and set(np.unique(arr[:,:,3]))<={0,255}
 assert 0<=anchor[0]<=im.width and 0<=anchor[1]<=im.height
 assets.append(dict(file=name,size_px=list(im.size),anchor_px=list(anchor),occupancy_cells=occupancy,layer=layer,action=action,frame_order=[0],frame_duration_ms=[None],loop=False,duration_mode='hold_until_state_change',sha256=hashlib.sha256(p.read_bytes()).hexdigest(),source=source,use=use,**extra))
 checks.extend([name+':RGBA',name+':binary_alpha',name+':anchor'])
 return im
def promote(n,dest,use,occupancy=None,**extra):
 return save(work(n),dest,M[n]['anchor'],use,occupancy,source=str((W/(n+'.png')).relative_to(P)),**extra)
radio=promote('radio_b','radio/radio_b_body.png','adopted B green metal radio; no placement rule implied',[1,1])
# UI icon is a separate retouched native target, not a scaling instruction for the world body.
im=radio.crop(radio.getbbox());im.thumbnail((22,20),N);icon=Image.new('RGBA',(24,24));icon.alpha_composite(im,((24-im.width)//2,22-im.height))
dr=ImageDraw.Draw(icon);dr.rectangle((16,15,17,16),fill='#b9aa76');dr.rectangle((18,16,19,17),fill='#4a4b38')
save(icon,'radio/radio_b_icon_24.png',(12,22),'inventory/header radio icon; no baked text',None,'ui',source='radio/radio_b_body.png; native knob cleanup')
for n,name in [('father_journal','father_journal_closed'),('father_letter','father_letter_folded')]:
 promote(n,'records/'+name+'.png','father record exterior; content and discovery remain data',None,layer='ui_or_world')
for action in ['mining','logging']:
 for di in ['right','left']:
  point=([51,46] if di=='right' else [28,46]) if action=='mining' else ([59,42] if di=='right' else [20,42])
  promote(f'keeper_{action}_1_{di}',f'work_pose/{action}_contact_{di}.png','approved contact key pose; not a complete animation',[1,1],action=action+'_contact',direction=di,contact_px=point,display_scale=1.4375,animation_complete=False)
res=promote('resident_a_right','resident/idle_right_00.png','adopted resident A; headband and short hair',[1,1],direction='right',display_scale=1.4375)
save(ImageOps.mirror(res),'resident/idle_left_00.png',(20,44),'left idle, mirrored same clothes; no asymmetric insignia',[1,1],direction='left',display_scale=1.4375,source='resident/idle_right_00.png')
for i,label in enumerate(['tilled','sown','sprout','growing','harvestable']):
 promote('crop_'+str(i),'crop/'+f'{i:02}_{label}.png','single pale root-crop appearance; name/yield/growth rules unspecified',[1,1],layer='ground_then_crop',visual_stage=i,logical_state_mapping='implementation-defined; 5 images do not require 5 game states')
bed=work('bed_a');rear=bed.copy();front=Image.new('RGBA',bed.size)
# Separate the blanket at its upper seam. Preserve every original pixel exactly between the two layers.
a=np.array(bed);yy,xx=np.indices(a.shape[:2]);sel=(yy>=31)&(yy<73)&(xx>=7)&(xx<39)&(a[:,:,3]>0)
af=np.zeros_like(a);af[sel]=a[sel];ar=a.copy();ar[sel]=0
rear=Image.fromarray(ar);front=Image.fromarray(af)
save(rear,'bed/bed_a_rear.png',(24,78),'straw mat + pillow + uncovered frame; before sleeper',[1,2],'object_rear',source='approved bed_a pixel partition')
save(front,'bed/bed_a_blanket_front.png',(24,78),'blanket foreground; after compatible sleeper',[1,2],'object_front',source='approved bed_a pixel partition')
assert Image.alpha_composite(rear,front).tobytes()==bed.tobytes();checks.append('bed:lossless layer reconstruction')
promote('watch_a','watch/bell_post.png','small adopted bell post; no watch radius or enemy location',[1,1])
alert=Image.new('RGBA',(16,16));dr=ImageDraw.Draw(alert);dr.polygon([(8,1),(15,14),(1,14)],fill='#dbb45a',outline='#513c29');dr.rectangle((7,5,8,9),fill='#513c29');dr.rectangle((7,11,8,12),fill='#513c29')
save(alert,'watch/alert_16.png',(8,15),'adopted triangle alert; hide in normal state; above post or UI',None,'status_overlay',source='approved B4 triangle icon from preview compose.py')
promote('event_crate','event/found_crate.png','roadside event prop; tagged closed crate, not ordinary resource stack',[1,1])
# Adopted goldA remains the sole healthy body. Generated damaged studies inform native silhouette cuts:
# retain original pixels and identity rather than resampling differently-sized AI bodies.
goldpath=D/'ui_world_direction_v1/candidates/world/goldA.png';gold=load(goldpath)
reuses.append(dict(file='../ui_world_direction_v1/candidates/world/goldA.png',size_px=[144,160],anchor_px=[72,152],occupancy_cells=[2,2],layer='world_object',action='healthy',frame_order=[0],frame_duration_ms=[None],loop=False,sha256=hashlib.sha256(goldpath.read_bytes()).hexdigest(),use='healthy goldA unchanged; do not duplicate'))
original=np.array(gold)
def damaged(level):
 im=gold.copy();a=np.array(im)
 factor=[1,.88,.80,.67][level]
 # Reduce metallic highlight range while retaining the warm hue, not a grey or horror recolor.
 a[:,:,:3]=np.clip(a[:,:,:3]*factor+np.array([7,5,2])*(1-factor),0,255).astype('uint8')
 im=Image.fromarray(a);cut=Image.new('L',im.size);d=ImageDraw.Draw(cut)
 if level==1:
  d.polygon([(35,6),(46,6),(47,17),(43,16),(40,18),(37,15)],fill=255)
  d.polygon([(119,120),(128,122),(127,128),(123,126)],fill=255)
 if level>=2:
  d.polygon([(20,0),(77,0),(77,25),(63,25),(59,31),(53,27),(46,30),(30,28)],fill=255)
  d.polygon([(103,91),(118,94),(119,102),(111,108),(105,105)],fill=255)
  d.polygon([(115,123),(130,123),(129,134),(119,130)],fill=255)
 if level==3:
  d.polygon([(20,0),(114,0),(114,49),(101,49),(97,44),(89,47),(80,44),(62,47),(53,43),(40,48),(20,43)],fill=255)
  d.polygon([(17,83),(34,85),(43,91),(40,97),(44,105),(34,109),(23,105)],fill=255)
  d.polygon([(100,88),(123,90),(122,113),(110,119),(105,113),(99,110)],fill=255)
 im.putalpha(ImageChops.subtract(im.getchannel('A'),cut))
 # Give freshly broken silhouette edges a solid dark bronze cross-section,
 # rather than leaving a flat paper-cut outline at the removed chunks.
 edge=ImageChops.multiply(cut.filter(ImageFilter.MaxFilter(5)),im.getchannel('A'))
 bevel=Image.new('RGBA',im.size,(103,70,34,0));bevel.putalpha(edge);im.alpha_composite(bevel)
 layer=Image.new('RGBA',im.size);d=ImageDraw.Draw(layer)
 paths=[
 [(47,61),(52,64),(49,70),(54,75)],
 [(93,120),(89,125),(94,130),(91,137)]
 ]
 if level>=2:paths += [[(86,62),(92,69),(88,77),(94,85),(89,92)],[(40,82),(45,88),(42,96),(47,101)],[(66,127),(72,132),(68,138),(74,146)]]
 if level==3:paths += [[(42,60),(48,67),(45,78),(49,86)],[(78,112),(84,119),(80,126),(85,130)],[(29,119),(39,123),(46,121),(56,126)]]
 for j,pts in enumerate(paths):
  width=2 if level<3 else 3
  d.point((pts[-1][0]+2,pts[-1][1]),fill=(162,115,49,255))
  d.line(pts,fill=(60,40,24,255),width=width)
 layer.putalpha(ImageChops.multiply(layer.getchannel('A'),im.getchannel('A')));im.alpha_composite(layer)
 if level==3:
  # Shift upper broken body two native pixels; pedestal and foot anchor stay fixed.
  upper=im.crop((0,0,144,112));bottom=im.copy();ImageDraw.Draw(bottom).rectangle((0,0,143,111),fill=(0,0,0,0));bottom.alpha_composite(upper,(-2,0));im=bottom
 return im
for level,state in enumerate(['light','medium','heavy'],1):
 im=damaged(level)
 save(im,f'idol/goldA_damage_{state}.png',(72,152),f'{state} damage body replacement; NOT overlay; preserve identity and pedestal anchor',[2,2],source='adopted goldA pixels + native silhouette/crack finishing guided by imagegen '+state+' study',health_threshold=None,damage_stage=level,display_scale=1.0)
# Standalone prayer rim: actual RGBA pixels remain binary; fade brightness in renderer if desired.
a=gold.getchannel('A').point(lambda p:255 if p>=128 else 0)
rim=ImageChops.subtract(a.filter(ImageFilter.MaxFilter(3)),a)
glow=Image.new('RGBA',gold.size,(232,190,84,0));glow.putalpha(rim)
save(glow,'idol/prayer_available_rim.png',(72,152),'optional restrained night prayer availability outline; separate body layer',[2,2],'status_overlay',source='goldA alpha outer rim',suggested_opacity=.38,damage_compatibility='healthy only; do not overlay healthy silhouette on damaged body')
for fn in ['effects_v1/sound_wave/00.png','effects_v1/sound_wave/01.png','effects_v1/build_complete/00.png','effects_v1/build_complete/01.png','effects_v1/build_complete/02.png']:
 p=D/fn
 if p.exists():
  src=load(p);reuses.append(dict(file='../'+fn,size_px=list(src.size),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),use='optional existing sound wave for radio or small prayer sparkle; no duplicate PNG'))
manifest=dict(delivery='colony_growth_assets_v1',status='adopted_minimum_assets_ready_for_integration',cell_px=[48,42],filter='nearest',alpha='straight RGBA, no color-key',assets=assets,reuse=reuses,raw_sources='../../art-production/colony-growth-assets-v1/originals/',prior_sources='../../art-production/colony-growth-previews-v2/',shadow='No added drop shadows. Existing object self-shading preserved.',animations=[
 dict(name='radio_broadcast',frame_files=['../effects_v1/sound_wave/00.png','../effects_v1/sound_wave/01.png'],frame_order=[0,1],frame_duration_ms=[700,700],loop=True,position='radio anchor + (17,-29); center wave on that point; 0.5x example',optional=True),
 dict(name='prayer_sparkle',frame_files=['../effects_v1/build_complete/00.png','../effects_v1/build_complete/01.png','../effects_v1/build_complete/02.png'],frame_order=[0,1,2],frame_duration_ms=[180,180,240],loop=False,position='small particle at pedestal corner; existing event controls timing',optional=True)
 ],unfinished=['mining/logging windup and recovery motion; only approved contact keyposes included','resident walk and work motion; idle left/right included','occupied bed pose and runtime actor blanket depth matching','runtime integration and damage-state thresholds','UI reading page size, new names, recipes, prices, NPC/item data: not defined by art'])
(O/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
# Native review on exact morning screenshot. No game is started.
ref=P/'art-production/colony-growth-previews-v2/references/01_field.png'
base=load(ref);BG='#243b31'
def tint(im):
 a=np.array(im);a[:,:,:3]=np.rint(a[:,:,:3]*.78+np.array([7.65,15.3,51])*.22).astype('uint8');return Image.fromarray(a)
def put(scene,im,pos,anchor,scale=1,day=True):
 im=im.resize((round(im.width*scale),round(im.height*scale)),N)
 scene.alpha_composite(tint(im) if day else im,(round(pos[0]-anchor[0]*scale),round(pos[1]-anchor[1]*scale)))
def text(scene,xy,t,size=15):
 d=ImageDraw.Draw(scene);b=d.textbbox(xy,t,font=F(size));d.rectangle((b[0]-4,b[1]-3,b[2]+4,b[3]+3),fill='#243b31');d.text(xy,t,font=F(size),fill='#eee0bd')
def sheet(name,title,scene,details,notes):
 out=Image.new('RGBA',(1280,1320),BG);d=ImageDraw.Draw(out)
 d.text((22,10),title,font=F(24),fill='#eee0bd');d.text((22,48),'合成プレビュー／未実装。上段：保存済み実ゲーム画面へ通常倍率で配置。',font=F(14),fill='#c6d8b5')
 out.alpha_composite(scene,(0,80));d.text((22,902),notes,font=F(15),fill='#eee0bd')
 for i,(label,box) in enumerate(details):
  z=scene.crop(box);z=z.resize((z.width*2,z.height*2),N);x=18+i*310
  out.alpha_composite(z,(x,965));d.text((x,938),label+' nearest2×',font=F(13),fill='#c6d8b5')
 out.convert('RGB').save(O/name)
scene=base.copy();states=[gold]+[load(O/f'idol/goldA_damage_{s}.png') for s in ['light','medium','heavy']]
labels=['健常：goldA原本','軽損傷：小欠け','中損傷：角・腕の欠損','重損傷：大欠損・傾き']
for x,im,label in zip([190,490,790,1090],states,labels):
 put(scene,im,(x,278),(72,152));text(scene,(x-83,94),label,14)
 # Same full-canvas scale in small UI, never individually trim to bbox.
 put(scene,im,(x-35,618),(0,0),.4,False);text(scene,(x-65,700),'UI：58×64枠',13)
text(scene,(80,572),'小表示：輪郭・欠け・亀裂・輝きの減少を比較（同じ64px高）',15)
sheet('preview_idol_4states.png','黄金像｜健常・軽損傷・中損傷・重損傷',scene,[(l,(x-72,120,x+72,290)) for x,l in zip([190,490,790,1090],['健常','軽','中','重'])],'台座の足元(72,152)と2×2占有は維持。損傷閾値は実装側。上段の中央に元画面の既存像も残す。')
scene=base.copy()
for x,n,label in [(170,'radio/radio_b_body.png','ラジオB'),(345,'records/father_journal_closed.png','父の手帳'),(850,'records/father_letter_folded.png','父の手紙'),(1060,'event/found_crate.png','事件用の箱')]:
 r=next(a for a in assets if a['file']==n);put(scene,load(O/n),(x,276),r['anchor_px']);text(scene,(x-54,305),label)
for i,(ac,di) in enumerate([('mining','right'),('mining','left'),('logging','right'),('logging','left')]):
 n=f'work_pose/{ac}_contact_{di}.png';r=next(a for a in assets if a['file']==n);x=190+i*280
 put(scene,load(O/n),(x,620),r['anchor_px'],1.4375);text(scene,(x-60,650),('採掘' if ac=='mining' else '伐採')+' 接触 '+di,13)
sheet('preview_adopted_A.png','採用A群｜ラジオB・記録・作業接触姿勢',scene,[('ラジオB',(110,230,255,300)),('記録',(295,230,440,300)),('採掘',(132,539,277,630)),('伐採',(690,539,835,630))],'連続作業モーションとは区別。顔・帽子は主人公v1の採用画素。資料本文・ニュースは画像に焼き込まない。')
scene=base.copy()
for x,di in [(160,'right'),(220,'left')]:put(scene,load(O/f'resident/idle_{di}_00.png'),(x,300),(20,44),1.4375)
text(scene,(100,322),'住人A：左右静止',14)
for rr in range(4):
 for cc in range(4):put(scene,load(O/('crop/'+f'{rr+1:02}_'+['sown','sprout','growing','harvestable'][rr]+'.png')),(930+cc*48,210+rr*42),(24,40))
text(scene,(875,382),'整然型4×4・土外縁は柔らかく',13)
put(scene,bed,(188,638),(24,78));text(scene,(130,655),'寝床A：前後分離',14)
for x in [820,940]:
 put(scene,load(O/'watch/bell_post.png'),(x,615),(24,50))
 if x==940:put(scene,alert,(x,557),(8,15),1,False)
text(scene,(780,644),'鐘の見張り地点：平時／警戒',14)
put(scene,load(O/'event/found_crate.png'),(1100,620),(24,38));text(scene,(1050,652),'物資箱',13)
sheet('preview_adopted_B.png','採用B群｜住人・栽培・寝床・見張り・物資箱',scene,[('住人',(105,225,250,310)),('作物',(890,280,1035,375)),('寝床',(115,545,260,640)),('見張り',(875,532,1020,630))],'占有案：住人/作物/見張り/箱1×1、寝床1×2。加入・栽培名・効果・建築条件は未確定。')
# True RGBA on bright/dark review, pixel doubled, native drawing controls preserved.
tiles=[('radio',radio),('bed',bed),('resident',res),('gold light',states[1]),('gold medium',states[2]),('gold heavy',states[3])]
proof=Image.new('RGB',(1200,800),BG);d=ImageDraw.Draw(proof)
for i,(label,im) in enumerate(tiles):
 x=(i%3)*400;y=(i//3)*400
 for j,color in enumerate(['#e5dbbd','#25352c']):
  panel=Image.new('RGBA',(190,345),color);scale=2 if im.height<90 else 1
  z=im.resize((im.width*scale,im.height*scale),N);panel.alpha_composite(z,((190-z.width)//2,20))
  proof.paste(panel.convert('RGB'),(x+j*195,y+30))
 d.text((x+6,y+6),label,font=F(15),fill='#eee0bd')
proof.save(O/'review_alpha.png')
# Every delivered file is ordinary RGBA, nonempty, well inside stable canvas.
for r in assets:
 im=load(O/r['file']);assert im.getbbox() is not None
 assert hashlib.sha256((O/r['file']).read_bytes()).hexdigest()==r['sha256']
 checks.append(r['file']+':hash')
assert hashlib.sha256(goldpath.read_bytes()).hexdigest()==reuses[0]['sha256'];checks.append('healthy goldA source untouched')
(O/'QUALITY_REVIEW.json').write_text(json.dumps({'passed':len(checks),'checks':checks,'runtime_tested':False,'visual_checks':['native-size eyes/tools','gold silhouettes at144x160 and58x64','light and dark transparency','lossless bed layer composition','no baked text or HP','no directions other than left/right for new resident']},ensure_ascii=False,indent=2),encoding='utf8')
print('formal minimum',len(assets),'RGBA assets;',len(checks),'checks')

