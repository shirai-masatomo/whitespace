from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import numpy as np,json,hashlib,math,sys,shutil
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'art_delivery/enemy_animal_direction_v3'
META=json.loads((BASE/'manifest.json').read_text(encoding='utf-8'))['characters']
HUMANS={'destroyer':35,'martial_artist':25,'ninja':32,'tamer':28,'runner':23}
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
font=lambda sz:ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',sz)
def write_json(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2),encoding='utf-8')
def clean_cut(im):
 a=np.array(im.convert('RGBA'));m=a[:,:,3]>200;h,w=m.shape
 seen=np.zeros_like(m);groups=[]
 for sy,sx in zip(*np.where(m)):
  if seen[sy,sx]:continue
  todo=[(int(sx),int(sy))];seen[sy,sx]=True;pts=[]
  while todo:
   x,y=todo.pop();pts.append((x,y))
   for dx,dy in [(1,0),(-1,0),(0,1),(0,-1),(1,1),(-1,-1),(1,-1),(-1,1)]:
    xx,yy=x+dx,y+dy
    if 0<=xx<w and 0<=yy<h and m[yy,xx] and not seen[yy,xx]:seen[yy,xx]=True;todo.append((xx,yy))
  groups.append(pts)
 groups.sort(key=len,reverse=True);keep=np.zeros_like(m)
 for pts in groups:
  if len(pts)<max(10,len(groups[0])*.005):continue
  xs,ys=zip(*pts);keep[ys,xs]=True
 a[:,:,3]=keep*255;a[~keep,:3]=0;out=Image.fromarray(a);return out.crop(out.getbbox())
def process(n):
 src=ROOT/'art-production'/f'{n.replace("_","-")}-motion-v1';meta=META[n];canvas=tuple(meta['canvas']);anchor=meta['anchor'];height=meta['standing_body_height_px']
 keys=[Image.open(p).convert('RGBA') for p in sorted((BASE/'pose_drafts'/n).glob('key_*.png'))]
 sheet=Image.open(src/'originals/motion-sheet.png').convert('RGBA');cols,rows=(3,2) if n in ['bullfrog','hedgehog'] else ((4,3) if n=='doberman' else (4,2))
 raws=[clean_cut(sheet.crop((round(i%cols*sheet.width/cols),round(i//cols*sheet.height/rows),round((i%cols+1)*sheet.width/cols),round((i//cols+1)*sheet.height/rows)))) for i in range(cols*rows)]
 scale=height/raws[0].height
 pal=np.unique(np.concatenate([np.array(im).reshape(-1,4) for im in keys]),axis=0);pal=pal[pal[:,3]>0,:3]
 motions=[];records=[]
 for i,r in enumerate(raws):
  small=r.resize((max(1,round(r.width*scale)),max(1,round(r.height*scale))),Image.Resampling.BOX);a=np.array(small);mask=a[:,:,3]>=128
  dist=((a[:,:,:3].astype(np.int32)[:,:,None,:]-pal.astype(np.int32)[None,None,:,:])**2).sum(axis=3)
  a[:,:,:3]=pal[dist.argmin(axis=2)];a[:,:,3]=mask*255;a[~mask,:3]=0
  pad=np.pad(mask,1);inside=pad[1:-1,:-2]&pad[1:-1,2:]&pad[:-2,1:-1]&pad[2:,1:-1];a[mask&~inside,:3]=[57,37,26];small=Image.fromarray(a)
  if n in HUMANS:
   yy,xx=np.where(mask);sel=yy<max(4,int(height*.12));headcenter=(int(xx[sel].min())+int(xx[sel].max())+1)/2
   a0=np.array(keys[0])[:,:,3];y0,x0=np.where(a0>0);sel0=y0<y0.min()+max(4,int(height*.12));refcenter=(int(x0[sel0].min())+int(x0[sel0].max())+1)/2;x=round(refcenter-headcenter)
  else:
   # Locomotion uses the same support-center convention as adopted standing art.
   x=anchor[0]-round(small.width*(.48 if n=='bullfrog' else .5))
  y=anchor[1]-small.height
  if x<0 or x+small.width>canvas[0] or y<0:raise ValueError(('clipping',n,i,small.size,(x,y),canvas))
  frame=Image.new('RGBA',canvas);frame.alpha_composite(small,(x,y))
  if n in HUMANS:
   cut=HUMANS[n];dy=1 if i in [4,6,7] else 0;dx=-1 if i==4 else 0
   head=keys[0].crop((0,0,canvas[0],cut)); hb=head.getbbox();ar=np.array(frame);ar[:cut+dy,max(0,hb[0]-2):min(canvas[0],hb[2]+2),:]=0;frame=Image.fromarray(ar);frame.alpha_composite(head,(dx,dy))
  if n=='ninja' and i==7:
   draw=ImageDraw.Draw(frame);draw.line([(37,33),(42,32),(44,31)],fill=(57,37,26,255),width=3);draw.line([(37,33),(42,32),(44,31)],fill=(75,70,88,255),width=1);draw.point((43,31),fill=(161,153,139,255))
  motions.append(frame);records.append({'source_cell':i,'bbox':list(frame.getbbox()),'scale':scale,'head_reused':n in HUMANS})
 (src/'native').mkdir(exist_ok=True)
 for i,im in enumerate(motions):im.save(src/'native'/f'motion_{i:02}.png')
 write_json(src/'native/processing.json',records)
 return src,keys,motions

def build(n):
 src,keys,g=process(n);meta=META[n];cw,ch=meta['canvas'];ax,ay=meta['anchor'];anR=[ax,ay];anL=[cw-ax,ay];cid='animal_tamer' if n=='tamer' else n
 out=ROOT/'art_delivery'/f'{cid}_motion_v1';out.mkdir(exist_ok=True);(out/'preview').mkdir(exist_ok=True)
 clips={};options={};bodykeys={}
 def add(action,frames,times,loop=False,**opts):
  clips[action]=(frames,times,loop);options[action]=opts
 def fromkeys(action,indices,times,loop=False,**opts):
  add(action,[keys[i] for i in indices],times,loop,**opts);bodykeys[action]=indices
 add('idle',[keys[0]],[None],False,end_behavior='hold')
 if n in HUMANS:
  add('run' if n=='runner' else 'walk',g[:4],[90 if n in ['runner','ninja'] else 140]*4,True)
  add('hurt',[g[4],g[5],keys[0]],[80,120,120],False)
  # Retreat is an alive movement cycle; no death pose for Human enemies.
  if n in ['destroyer','martial_artist']:
   split=ay-12;ret=[]
   for leg in g[:4]:
    im=g[6].copy();a=np.array(im);a[split:,:,:]=0;im=Image.fromarray(a);im.alpha_composite(leg.crop((0,split,cw,ch)),(0,split));ret.append(im)
  else:ret=g[:4]
  add('retreat',ret,[100]*4,True,alive=True)
 if n=='destroyer':
  fromkeys('iron_ball_windup',[0,1,2],[130,180,160],False)
  fromkeys('iron_ball_hit',[3,4,5,0],[80,100,180,100],False,visual_contact_frame=0)
 elif n=='martial_artist':
  fromkeys('bow',[1,2,1,3],[60,150,70,80],False)
  fromkeys('bow_end',[3,1,2,1],[70,60,150,80],False)
  fromkeys('stance',[3],[None],False,end_behavior='hold')
  fromkeys('attack',[3,4,3],[100,80,150],False,visual_contact_frame=1)
  fromkeys('kick',[3,5,3],[130,100,150],False,visual_contact_frame=1)
 elif n=='ninja':
  fromkeys('shuriken',[0,1,2,3,0],[70,100,60,90,100],False,visual_release_frame=2)
  add('dagger',[g[6],g[7],g[6],keys[0]],[100,70,90,120],False,visual_contact_frame=1)
 elif n=='tamer':
  fromkeys('tame',[1,2,3,4],[100,160,180,160],False,end_behavior='hold last while existing tame state remains')
  fromkeys('tame_end',[3,2,1,0],[100,100,100,100],False)
  lead=[];split=ay-13
  for leg in g[:4]:
   im=g[6].copy();a=np.array(im);a[split:,:,:]=0;im=Image.fromarray(a);im.alpha_composite(leg.crop((0,split,cw,ch)),(0,split));lead.append(im)
  add('lead',lead,[140]*4,True,animal_separate_layer=True)
 elif n=='runner':
  fromkeys('tired_enter',[3,4],[160,200],False)
  breath=keys[4].copy();ba=np.array(breath);ba[:ay-14,:,:]=0;breath=Image.fromarray(ba);breath.alpha_composite(keys[4].crop((0,0,cw,ay-14)),(0,-1));add('tired',[keys[4],breath,keys[4]],[320,220,320],True)
  fromkeys('tired_exit',[4,5,0],[140,160,100],False)
  add('attack',[g[6],g[7],g[6],keys[0]],[100,80,120,100],False,visual_contact_frame=1)
 elif n=='doberman':
  add('walk',g[:4],[130]*4,True)
  add('run',[keys[1],g[4],keys[2],g[5]],[80]*4,True)
  add('attack',[keys[3],g[6],g[7],keys[0]],[100,90,120,100],False,visual_contact_frame=1)
  add('hurt',[g[8],g[9],keys[0]],[90,130,120],False)
  add('death',[g[10],g[11]],[140,240],False,end_behavior='hold last until existing lifecycle removes actor',non_graphic=True)
 elif n=='bullfrog':
  add('move',g[:4],[160]*4,True)
  fromkeys('tongue_extend',[0,1,2],[80,120,100],False)
  fromkeys('tongue',[2],[None],False,end_behavior='hold until existing restraint state releases')
  fromkeys('tongue_retract',[2,1,0],[100,90,120],False)
  fromkeys('croak',[3,4,5,4,0],[80,120,160,100,140],False)
  add('hurt',[g[4],g[5],keys[0]],[90,120,120],False)
 elif n=='hedgehog':
  add('move',g[:4],[120]*4,True)
  fromkeys('defense_enter',[1,2,3,4],[60,80,80,100],False)
  fromkeys('defense',[4],[None],False,end_behavior='hold until existing defense state ends')
  fromkeys('defense_exit',[3,5,0],[90,120,100],False)
  fromkeys('hurt',[1,2,0],[80,100,120],False)
 assets=[];actions={};imgs={};weapons={};sockets={}
 def save(im,rel,action,direction,idx,ms,loop,anchor,layer='body',extra=None):
  p=out/rel;p.parent.mkdir(parents=True,exist_ok=True);im.save(p);imgs[rel]=im
  rec={'file':rel,'canvas_size_px':list(im.size),'foot_anchor_px':anchor,'visible_bbox_exclusive_px':list(im.getbbox()) if im.getbbox() else None,'action':action,'direction':direction,'frame_index':idx,'frame_duration_ms':ms,'loop':loop,'layer':layer,'sha256':sha(p),'runtime_ready':True,'contains_cast_shadow':False}
  if extra:rec.update(extra)
  
  if n=='destroyer' and action=='iron_ball_hit' and idx==0 and layer=='body':rec['ground_note']='Boot soles y64; fist reaches y66. Lowest alpha pixel is not ground.'
  assets.append(rec)
 for action,(frames,times,loop) in clips.items():
  for direction in ['right','left']:
   anchor=anR if direction=='right' else anL;files=[]
   for i,(im,ms) in enumerate(zip(frames,times)):
    im=im if direction=='right' else ImageOps.mirror(im);rel=f'{action}/{direction}_{i:02}.png';save(im,rel,action,direction,i,ms,loop,anchor);files.append(rel)
   actions[action+'_'+direction]={'action_id':action,'direction':direction,'frames':files,'frame_duration_ms':times,'loop':loop,'end_behavior':'repeat while state active' if loop else 'return to state-selected pose',**options[action]}
 # Preserve separate weapon/tongue assets. Frames below are visual layers only.
 partmeta={}
 def part(key,anchor,meaning):
  im=Image.open(BASE/'concept_parts'/f'{key}.png').convert('RGBA');rel='parts/'+key+'.png';save(im,rel,'part','none',0,None,False,None,layer='part',extra={'anchor_px':anchor,'use':meaning});partmeta[key]={'file':rel,'anchor_px':anchor,'use':meaning};return im
 if n=='destroyer':
  ball=part('iron_ball',[5,0],'ring top, independent iron ball');link=part('chain_link',[0,1],'repeatable chain link');grips=[[48,49],[14,38],[25,11],[57,64],[70,43],[46,51]]
  # Weapon canvas extends beyond body without changing actor anchor or collider.
  WA=[56,80];WS=(128,96)
  for action,(frames,times,loop) in clips.items():
   socketframes=[]
   for i,im in enumerate(frames):
    ki=bodykeys.get(action,[0]*len(frames))[i];grip=grips[ki] if action.startswith('iron_ball') or action=='idle' else ([48,42] if action in ['hurt','retreat'] else [49,49])
    balls={0:(58,50),1:(-7,29),2:(11,-5),3:(82,48),4:(89,39),5:(59,50)}
    bp=balls[ki] if action.startswith('iron_ball') else (grip[0]+10,50)
    w=Image.new('RGBA',WS);d=ImageDraw.Draw(w);off=(WA[0]-ax,WA[1]-ay);p0=(grip[0]+off[0],grip[1]+off[1]);p1=(bp[0]+off[0],bp[1]+off[1]);count=max(2,math.ceil(math.dist(p0,p1)/4));pts=[]
    for j in range(count+1):
     t=j/count;sag=(3 if action not in ['iron_ball_hit'] else 0)*math.sin(math.pi*t);pts.append((round(p0[0]+(p1[0]-p0[0])*t),round(p0[1]+(p1[1]-p0[1])*t+sag)))
    d.line(pts,fill=(57,37,26,255),width=3)
    for j,p in enumerate(pts):d.point(p,fill=(165,157,134,255) if j%2==0 else (97,92,80,255))
    w.alpha_composite(ball,(p1[0]-5,p1[1]));socketframes.append({'grip_body_px':grip,'ball_ring_body_px':list(bp)})
    for direction in ['right','left']:
     ww=w if direction=='right' else ImageOps.mirror(w);aa=WA if direction=='right' else [WS[0]-WA[0],WA[1]];rel=f'weapon/{action}/{direction}_{i:02}.png';save(ww,rel,action,direction,i,times[i],loop,aa,'weapon_front');weapons[(action,direction,i)]=(ww,aa)
   sockets[action]=socketframes
 elif n=='ninja':
  star=part('shuriken',[3,3],'independent projectile; no hit logic');dagger=part('dagger',[1,2],'grip pivot')
  for i,angle in enumerate([0,45,90,135]):
   spin=star.rotate(angle,resample=Image.Resampling.NEAREST,expand=True);im=Image.new('RGBA',(11,11));im.alpha_composite(spin,((11-spin.width)//2,(11-spin.height)//2));save(im,f'projectile/shuriken_{i:02}.png','projectile','none',i,80,True,None,'projectile',{'anchor_px':[5,5]})
  hands=[[22,31],[45,31],[22,31],[40,39]]
  for i,(hand,angle) in enumerate(zip(hands,[-90,0,-90,60])):
   # Keep separate held dagger; body pose has an empty grip.
   w=Image.new('RGBA',(cw,ch));theta=math.radians(angle)
   for yy in range(dagger.height):
    for xx in range(dagger.width):
     rgba=dagger.getpixel((xx,yy))
     if rgba[3]:
      px=round(hand[0]+math.cos(theta)*(xx-1)-math.sin(theta)*(yy-2));py=round(hand[1]+math.sin(theta)*(xx-1)+math.cos(theta)*(yy-2))
      if 0<=px<cw and 0<=py<ch:w.putpixel((px,py),rgba)
   for direction in ['right','left']:
    ww=w if direction=='right' else ImageOps.mirror(w);anchor=anR if direction=='right' else anL;rel=f'weapon/dagger/{direction}_{i:02}.png';save(ww,rel,'dagger',direction,i,clips['dagger'][1][i],False,anchor,'weapon_front');weapons[('dagger',direction,i)]=(ww,anchor)
  sockets['dagger']=[{'grip_body_px':h} for h in hands];sockets['shuriken']={'release_frame':2,'right_body_px':[51,32],'left_body_px':[cw-51,32]}
 elif n=='bullfrog':
  for key,a,use in [('tongue_body',[0,1],'tile or extend; no cap on internal joints'),('tongue_tip',[2,2],'attachment tip'),('tongue_wrap_back',[9,5],'behind target'),('tongue_wrap_front',[9,5],'in front of target')]:part(key,a,use)
  sockets['mouth']={'idle':[53,33],'open':[53,31],'hold':[57,33],'left_formula':'canvas_width - x; y unchanged'}
 # Layer references explicit; prevent double-drawing independent layers.
 for key,a in actions.items():
  refs=[f'weapon/{a["action_id"]}/{a["direction"]}_{i:02}.png' for i in range(len(a['frames']))]
  if all((out/r).exists() for r in refs):a['weapon_frames']=refs;a['layer_order']=['body','weapon_front']
 # Runtime validation.
 for a in assets:
  im=imgs[a['file']];assert im.mode=='RGBA' and set(im.getchannel('A').getdata())<={0,255},a['file']
  bb=im.getbbox();assert bb is not None
  if a['layer']=='body':assert im.size==(cw,ch) and bb[0]>=0 and bb[2]<=cw and bb[1]>=0 and bb[3]<=ch
  if a['direction']=='left':assert np.array_equal(np.array(im),np.array(ImageOps.mirror(imgs[a['file'].replace('left','right')]))),a['file']
 assert sha(out/'idle/right_00.png')==sha(BASE/'pose_drafts'/n/'key_00.png')
 moveaction='run' if n=='runner' else ('walk' if n in HUMANS or n=='doberman' else 'move');assert len({im.tobytes() for im in clips[moveaction][0]})==4
 manifest={'schema_version':1,'delivery':out.name,'date':'2026-10-06','branch':'codex/sporehollow-art-assets','status':'ready_for_implementation','character_id':cid,'name_ja':meta['name_ja'],'adopted_design':'../enemy_animal_direction_v3/','adoption_commit':'f26498d2bafe6e274a197aef0a025d5016c8691e','canvas_size_px':[cw,ch],'foot_anchor_px':{'right':anR,'left':anL},'standing_body_height_px':meta['standing_body_height_px'],'rendering':{'format':'RGBA','filter':'nearest','alpha':[0,255],'color_key':False,'trim_transparent_margin':False,'baked_ground_shadow':False},'assets':assets,'actions':actions,'parts':partmeta,'sockets':sockets,'timing_policy':'Presentation cadence only; synchronize existing visual clock and pause. State durations, damage, range, speed, HP and probabilities remain implementation rules. Contact/release indices are visual cues, not gameplay triggers.','sources':{'original':'../../art-production/'+src.name+'/originals/motion-sheet.png','generation_record':'../../art-production/'+src.name+'/generation-record.json','processing':'../../art-production/motion-pipeline-v1/build.py','adopted_keys':'../enemy_animal_direction_v3/pose_drafts/'+n+'/'},'spec_snapshots':[{'file':'../../art-production/'+src.name+'/references/'+s,'sha256':sha(src/'references'/s)} for s in ['ART_SPEC.md','ENEMIES.md','ANIMALS.md']],'unfinished':['正面・背面の専用動作は今回の横向き契約外','ゲーム取り込みと隔離描画検証は実装担当'],'game_launched':False,'in_game_verified':False}
 if n=='bullfrog':manifest['tongue_contract']={'hold_action':'tongue','extend_action':'tongue_extend','retract_action':'tongue_retract','target_layer_order':['tongue_wrap_back','target','tongue_wrap_front'],'distance':'connect current mouth to target hold point; no fixed range baked','preview_anchor_distance_px':144,'latest_ANIMALS_range':'4 cells; not changed; preview 3 cells is a drawing example','rotation':'nearest, no filtering','stretch_body_only':True}
 if n=='ninja':manifest['scroll_drop']={'source':'../ranch_assets_v1/scroll/idle_none_00.png','independent_from_actor':True,'spawn_once_on_existing_retreat_transition':'implementation rule, not a repeated animation event','smoke_included':False,'canvas_size_px':[24,24],'foot_anchor_px':[12,22]}
 if n=='tamer':manifest['taming_contract']={'character_id':'animal_tamer','source_design_id':'tamer','animal_separate_layer':True,'animal_position':'keep separate ground anchor; never baked into body','success':'existing loyalty/resistance rules only; no automatic success in animation'}
 write_json(out/'manifest.json',manifest)
 # Reviews are composites over a saved real farm background, not game verification.
 farm=Image.open(ROOT/'art-production/enemy-animal-direction-v3/references/farm-day.png').convert('RGB');bg=farm.crop((270,224,590,324))
 def render(action,direction,i,x=90):
  b=bg.copy().convert('RGBA');an=anR if direction=='right' else anL;im=imgs[f'{action}/{direction}_{i:02}.png'];b.alpha_composite(im,(x-an[0],84-an[1]))
  if (action,direction,i) in weapons:
   wi,wa=weapons[(action,direction,i)];b.alpha_composite(wi,(x-wa[0],84-wa[1]))
  return b.convert('RGB')
 review=Image.new('RGB',(1320,len(clips)*380+75),'#eee5ca');d=ImageDraw.Draw(review);d.text((15,12),meta['name_ja']+' / 正式動作 / 1x + nearest 4x / オフライン合成',font=font(20),fill='#39251a')
 for row,(action,(frames,times,loop)) in enumerate(clips.items()):
  y=65+row*380;d.text((15,y),action+' '+str(times)+' '+('loop' if loop else 'one shot / hold'),font=font(15),fill='#39251a')
  for i in range(min(5,len(frames))):
   b=render(action,'right',i,x=38).crop((0,20,64,92)) if n=='hedgehog' else render(action,'right',i,x=48).crop((0,8,80,88))
   review.paste(b,(15+i*260,y+28));z=b.resize((b.width*3,b.height*3),Image.Resampling.NEAREST);review.paste(z,(15+i*260,y+110))
 # This compact sheet uses 3x; native 4x is in the GIF/lineup.
 ImageDraw.Draw(review).rectangle((0,0,1320,54),fill='#eee5ca');ImageDraw.Draw(review).text((15,12),meta['name_ja']+' / 全動作 / 1x + nearest 3x / オフライン合成',font=font(20),fill='#39251a');review.save(out/'preview/all_actions.png')
 timeline=[]
 for action,(frames,times,loop) in clips.items():
  for _ in range(2 if loop else 1):
   for i,ms in enumerate(times):timeline.append((action,'right',i,ms or 500))
  timeline.append(('idle','right',0,250))
 for i,ms in enumerate(clips[moveaction][1]):timeline.append((moveaction,'left',i,ms))
 timeline.append(('idle','left',0,500));gifs=[]
 for action,direction,i,ms in timeline:
  b=render(action,direction,i,x=140);fr=Image.new('RGB',(1280,535),'#eee5ca');dd=ImageDraw.Draw(fr);dd.text((15,8),meta['name_ja']+' / '+action+' '+direction+' / 1x + 4x / offline',font=font(17),fill='#39251a');fr.paste(b,(15,32));fr.paste(b.resize((1280,400),Image.Resampling.NEAREST),(0,135));gifs.append(fr)
 palstrip=Image.new('RGB',(1280,535*len(gifs)))
 for i,fr in enumerate(gifs):palstrip.paste(fr,(0,535*i))
 pal=palstrip.quantize(colors=256,dither=Image.Dither.NONE);gifp=[fr.quantize(palette=pal,dither=Image.Dither.NONE) for fr in gifs];gifp[0].save(out/'preview/motion.gif',save_all=True,append_images=gifp[1:],duration=[v[3] for v in timeline],loop=0,disposal=2,optimize=False)
 # Exact-size comparison and alpha background checks.
 b=bg.convert('RGBA')
 for rel,anchor,x in [('characters_v1/keeper_idle_right_00.png',[16,44],35),('characters_v1/shiba_idle_right_00.png',[24,44],90),(out.name+'/idle/right_00.png',anR,160),(out.name+'/idle/left_00.png',anL,245)]:
  im=Image.open(ROOT/'art_delivery'/rel).convert('RGBA');b.alpha_composite(im,(x-anchor[0],84-anchor[1]))
 comp=Image.new('RGB',(1280,535),'#eee5ca');cd=ImageDraw.Draw(comp);cd.text((15,8),meta['name_ja']+' / 主人公・柴犬との実寸比較 / 1x + 4x',font=font(18),fill='#39251a');comp.paste(b,(15,32));comp.paste(b.resize((1280,400),Image.Resampling.NEAREST),(0,135));comp.save(out/'preview/size_comparison.png')
 alpha=Image.new('RGB',(cw*12,ch*4+48),'#eee5ca');ad=ImageDraw.Draw(alpha);ad.text((10,8),'透過・足元 / nearest 4x',font=font(17),fill='#39251a')
 for i,(direction,bgc) in enumerate([('right','#26353d'),('left','#eee5ca'),('right','#767b62')]):
  an=anR if direction=='right' else anL;x=i*cw*4;ad.rectangle((x,42,x+cw*4-1,42+ch*4-1),fill=bgc);im=imgs['idle/'+direction+'_00.png'].resize((cw*4,ch*4),Image.Resampling.NEAREST);alpha.paste(im,(x,42),im);ad.line((x,42+ay*4,x+cw*4-1,42+ay*4),fill='#b08a48')
 alpha.save(out/'preview/alpha_and_feet.png')
 qa={'status':'pass','native_png_count':len(assets),'body_png_count':sum(a['layer']=='body' for a in assets),'action_count':len(clips),'directions':['right','left'],'native_canvas':[cw,ch],'anchors':{'right':anR,'left':anL},'adopted_idle_hash_unchanged':True,'adopted_idle_sha256':sha(out/'idle/right_00.png'),'distinct_locomotion_frames':4,'binary_alpha':True,'exact_mirror_validated':True,'gif_decoded_frames':Image.open(out/'preview/motion.gif').n_frames,'game_launched':False,'in_game_verified':False};write_json(out/'QA.json',qa)
 notes={
 'destroyer':'胴に巻いた鎖は本体。動く鎖と鉄球はweaponの独立レイヤーで、本体→weapon_frontの順。武器128×96のアンカーは右(56,80)／左(72,80)。manifestのgrip/ball_ring座標は右向きの本体座標。左向きはxを80-xへ変換。通常80×72と武器のキャンバスを同じ左上座標で重ねない。接触はiron_ball_hitの0番が視覚上の目印。実際の攻撃距離・土壁2発等のルールは変更しない。',
 'martial_artist':'bowは開始、bow_endは終了の礼。どちらも360ms。礼で無敵化しない。stanceは保持用。attackは突き、kickは蹴りの別クリップ。いずれも接触意図は1番。既存の不殺処理は画像に依存させない。',
 'ninja':'顔は完全に覆い、目は追加していない。手裏剣はparts/projectileで独立、投げる本体へ焼き込まない。shurikenの2番が視覚上のリリース。daggerは本体＋weaponの保持武器を重ねる。巻物は既存ranch_assets_v1を別レイヤーで一度だけ落とす。Lv1の煙玉は追加していない。',
 'tamer':'実装IDはanimal_tamer、採用資料のIDはtamer。UIDやコードは変更していない。tameは最後を状態に応じて保持し、tame_endで戻す。leadは動物を含まない歩行。猫・犬は別の足元座標で追従させる。忠誠低下や柴犬の抵抗、成功判定を演出側で決めない。',
 'runner':'採用済み身体高54px、小さい頭と長い手足を維持。run/retreatは移動用、tired_enter→tired（呼吸ループ）→tired_exitで復帰。疲労の8秒/4秒等の値や移動速度は画像側で変更しない。同行ドーベルマンは別セル・別レイヤー。',
 'doberman':'立ち耳・直立した首と背筋、柴犬Cより大型の33pxを維持。walkとrunを分離。attackの1番が噛み付きの視覚上の接触。deathは既存ANIMALSのHP0死亡に合わせた、流血なしの倒れる→横たわる。最後を保持し、消去は既存処理に従う。人間の敵の退散とは別。',
 'bullfrog':'tongue_extend→tongue（保持）→tongue_retractで分離。舌はpartsの胴だけを伸縮し、先端と巻き付きは等比のまま別描画。巻き付き背面→対象→巻き付き前面。3マス見本は足元144px、現行仕様の4マス射程を変更する指示ではない。保持時間・成功は既存処理に従う。croakの音波は既存effects_v1/sound_waveを任意に別描画。',
 'hedgehog':'defense_enter→defense（保持）→defense_exit。採用された通常18pxと鋭い迎撃21/23pxのキーを維持。防御の保持は既存状態に従い、画像のコマ時間で防御秒数・反射ダメージを変更しない。'
 }[n]
 table='\n'.join('| '+a+' | '+str(len(f))+' | '+('/'.join('hold' if t is None else str(t) for t in ts))+' | '+str(loop)+' |' for a,(f,ts,loop) in clips.items())
 doc=f'''# {meta['name_ja']} 正式動作 v1

採用済みv3を基準にした横向き正式動作。{len(clips)}動作、左右の本体{qa['body_png_count']}PNG、独立部品を含む本番PNG計{len(assets)}点。manifest.assetsが本番一覧です。

## 規格

本体{cw}×{ch}、足元は右({ax},{ay})／左({cw-ax},{ay})。通常身体高{meta['standing_body_height_px']}px。左は反転した全キャンバスなので、非対称アンカーも反転済み。共通ワールド足元へ各方向のアンカーを合わせます。余白を切り詰めず、nearest・通常RGBA・二値透過・等比表示。白い部分を色キー透過しない。地面への影は含みません。

| 動作 | 片方向コマ数 | ms | loop |
|---|---:|---|---|
{table}

## 固有の取り込み注意

{notes}

すべて表示用の時間です。既存visual_timeと一時停止へ同期。速度、射程、ダメージ、能力の継続時間、確率は変更しません。接触/リリース番号は視覚上の目印で、ゲーム判定の発生を画像から決定する指示ではありません。静止や保持のnull時間は状態が終了するまで保持する意味です。

## 出典・検査

採用済み静止PNGはSHA256完全一致で維持。採用された特殊キーを再利用し、不足する動作だけ内蔵画像生成で制作。原画・正確なプロンプト・最新仕様の写しは `../../art-production/{src.name}/`、加工・連番・GIF生成は `../../art-production/motion-pipeline-v1/build.py`。共有パレット、輪郭、透過、アンカーを整形済み。

QA.jsonとmanifestへ寸法、左右アンカー、フレーム順・ms・loop、SHA256、レイヤー/保持位置を記録。静止比較は1x/4x、全コマ一覧は1x/3x、GIFは1x/4x。保存済み牧場画面へオフライン合成した確認用で、ゲーム内の動作検証ではありません。previewを本番素材にしないこと。

## 未完成・対象外

正面・背面の専用動作、レベル上昇差分は今回の契約外。ゲーム取り込み・隔離描画検証は実装担当。ゲームコード・シーン・UID・ルールは変更していません。ユーザーのゲームは起動していません。
'''
 (out/'HANDOFF.md').write_text(doc,encoding='utf-8');(src/'README.md').write_text('# '+meta['name_ja']+' 動作制作\n\n原画 originals/motion-sheet.png、正確なプロンプト generation-record.json、採用参照 references、加工中間 native。`../motion-pipeline-v1/build.py '+n+'` で納品再現。追加動作以外の採用絵は再生成しない。\n',encoding='utf-8')
 print(json.dumps(qa,ensure_ascii=False),flush=True)
if __name__=='__main__':
 for n in sys.argv[1:]:build(n)
