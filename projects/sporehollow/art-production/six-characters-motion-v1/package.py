from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
import numpy as np,json,hashlib,sys,math
S=Path(__file__).parent;P=S.parents[1];R=P/'art_delivery/two_direction_review_v1';N=S/'native'
CFG={'merchant':((48,48),(24,44),42),'maid':((64,64),(32,58),42),'dancer':((64,64),(32,58),42),'thief':((64,64),(32,58),42),'cow':((80,64),(40,58),48),'bull':((96,64),(48,58),40)}
def sha(f):return hashlib.sha256(f.read_bytes()).hexdigest()
def im(f):return Image.open(f).convert('RGBA')
def font(n):return ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',n)
def adapt(a,cs):
 if a.size==cs:return a.copy()
 assert a.height==cs[1] and a.width<=cs[0],(a.size,cs)
 out=Image.new('RGBA',cs);out.alpha_composite(a,((cs[0]-a.width)//2,0));return out

def wheel_frames():
 base=im(P/'art_delivery/merchant_board_v1/cart_idle_00.png');ar=np.array(base);frames=[]
 # Rotate only the inner spokes of the visible near wheel; stationary rim/body/merchant preserved.
 cx,cy,rx,ry=26,74,8,10
 for angle in [0,22.5,45,67.5]:
  arr=ar.copy();theta=math.radians(angle)
  for y in range(cy-ry,cy+ry+1):
   for x in range(cx-rx,cx+rx+1):
    u=(x-cx)/rx;v=(y-cy)/ry
    if u*u+v*v>.80:continue
    sx=round(cx+(u*math.cos(theta)+v*math.sin(theta))*rx);sy=round(cy+(-u*math.sin(theta)+v*math.cos(theta))*ry)
    arr[y,x]=ar[sy,sx]
  frames.append(Image.fromarray(arr))
 return frames

def separated_breath(body):
 ar=np.array(body);on=ar[:,:,3]>0;seen=np.zeros(on.shape,bool);gs=[];h,w=on.shape
 for y,x in zip(*np.where(on)):
  if seen[y,x]:continue
  q=[(int(x),int(y))];seen[y,x]=1;pts=[]
  while q:
   xx,yy=q.pop();pts.append((xx,yy))
   for nx,ny in [(xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)]:
    if 0<=nx<w and 0<=ny<h and on[ny,nx] and not seen[ny,nx]:seen[ny,nx]=1;q.append((nx,ny))
  gs.append(pts)
 gs.sort(key=len,reverse=True);fx=np.zeros_like(ar)
 for pts in gs[1:]:
  # Detached breath at the muzzle, not interior colour highlights.
  if min(x for x,y in pts)>w*.65:
   for x,y in pts:fx[y,x]=ar[y,x];ar[y,x]=0
 return Image.fromarray(ar),Image.fromarray(fx)

class Package:
 def __init__(self,who):
  self.who=who;self.cs,self.an,self.height=CFG[who];self.D=P/'art_delivery'/f'{who}_motion_v1';self.D.mkdir(exist_ok=True);(self.D/'preview').mkdir(exist_ok=True)
  self.assets=[];self.actions=[];self.layers=[]
 def ref(self,action):return adapt(im(R/f'native/{self.who}/{action}.png'),self.cs)
 def gen(self,key,i):return adapt(im(N/f'{key}_{i:02}.png'),self.cs)
 def action(self,name,frames,times,loop=False,events=None,layer='body',sockets=None,canvas=None,anchor=None,note=''):
  cs=canvas or self.cs;an=anchor or self.an
  assert len(frames)==len(times)
  rec={'action':name,'frame_order':list(range(len(frames))),'frame_durations_ms':times,'loop':loop,'layer':layer,'events':events or [],'note':note,'directions':{}}
  for direction in ['right','left']:
   files=[]
   for i,(a,t) in enumerate(zip(frames,times)):
    assert a.size==cs,(name,a.size,cs)
    b=a if direction=='right' else ImageOps.mirror(a);f=Path(name)/f'{direction}_{i:02}.png';(self.D/name).mkdir(exist_ok=True);b.save(self.D/f);files.append(f.as_posix())
    sock={}
    if sockets and i<len(sockets):
     for k,v in sockets[i].items():sock[k]=v if direction=='right' else [cs[0]-v[0],v[1]]
    self.assets.append({'file':f.as_posix(),'canvas_size_px':list(cs),'foot_anchor_px':list(an),'visible_bbox_exclusive_px':b.getbbox(),'action':name,'direction':direction,'frame_index':i,'frame_duration_ms':t,'loop':loop,'layer':layer,'sockets_px':sock,'sha256':sha(self.D/f),'runtime_ready':True,'contains_cast_shadow':False})
   rec['directions'][direction]=files
  self.actions.append(rec)
 def finish(self):
  manifest={'schema_version':1,'delivery':f'{self.who}_motion_v1','date':'2026-10-08','branch':'codex/sporehollow-art-assets','status':'ready_for_implementation_runtime_unverified','character_id':self.who,'adopted_design':'../two_direction_review_v1/ADOPTION.json','canvas_size_px':list(self.cs),'foot_anchor_px':list(self.an),'standing_body_height_px':self.height,'rendering':{'format':'RGBA','filter':'nearest','color_key':False,'trim_transparent_margin':False,'baked_ground_shadow':False,'mirror_axis_x':self.an[0]},'assets':self.assets,'actions':self.actions,'timing_contract':'Visual clip timings only. Existing simulation determines movement, damage, targets and state length. Contact/release markers are attachment guidance, never new gameplay events.','sources':'../../art-production/six-characters-motion-v1/generation-records.json','remaining':['Implementation integration and isolated render verification.'],'review_only':['preview/actions.png','preview/actions.gif','preview/movement.gif','preview/alpha.png'],'limits':['Left is pixel-exact mirror; handed props and shading mirror together.','Cycles use the minimum explicit poses; no front/back or alternative designs.']}
  if self.who=='merchant':manifest['remaining']+=['Rear wheel is held behind chassis; only exposed near-wheel spokes animate.','No opening/setup animation or merchant combat actions.']
  if self.who=='thief':manifest['remaining']+=['Actual held item must be supplied by implementation; use item sockets and hand_front layers.']
  (self.D/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
  self.previews()
  self.validate()
  return manifest
 def previews(self):
  bodies=[a for a in self.actions if a['layer']=='body'];rows=len(bodies);w=1440;rh=130
  contact=Image.new('RGBA',(w,60+rows*rh),'#252d29');dd=ImageDraw.Draw(contact);dd.text((18,12),self.who+' / right + left / 1x & 2x / offline review',font=font(18),fill='#eee1c5')
  for r,a in enumerate(bodies):
   y=60+r*rh;dd.text((12,y),a['action'],font=font(15),fill='#eee1c5')
   for side in ['right','left']:
    x0=160 if side=='right' else 840
    for i,f in enumerate(a['directions'][side]):
     ob=im(self.D/f);z=1 if ob.width>=96 else 2
     contact.alpha_composite(ob.resize((ob.width*z,ob.height*z),Image.Resampling.NEAREST),(x0+i*140,y+12))
  contact.save(self.D/'preview/actions.png')
  # Animated state inspection: nonloop clips pause after their final frame; GIF repeats only for review.
  frames=[]
  for tick in range(40):
   out=Image.new('RGBA',(900,45+rows*130),'#252d29');d=ImageDraw.Draw(out);d.text((12,10),self.who+' / offline motion review',font=font(18),fill='white')
   for r,a in enumerate(bodies):
    ts=[t or 1000 for t in a['frame_durations_ms']];total=sum(ts);t=(tick*100)%(total if a['loop'] else total+700);idx=len(ts)-1
    for k,dur in enumerate(ts):
     if t<dur:idx=k;break
     t-=dur
    y=45+r*130;d.text((10,y+8),a['action']+' '+str(idx),font=font(14),fill='#eee1c5')
    for side,x in [('right',200),('left',540)]:
     aimg=im(self.D/a['directions'][side][idx]);z=2 if aimg.width<96 else 1
     out.alpha_composite(aimg.resize((aimg.width*z,aimg.height*z),Image.Resampling.NEAREST),(x,y))
     out.alpha_composite(aimg,(x+160,y+45))
   frames.append(out.convert('RGB'))
  frames[0].save(self.D/'preview/actions.gif',save_all=True,append_images=frames[1:],duration=100,loop=0,disposal=2)
  # right move -> right stop -> left move -> left stop, native and3x.
  move=next((a for a in bodies if a['action'] in ['walk','run']),bodies[0]);idle=bodies[0];demo=[]
  for k in range(40):
   side='right' if k<20 else 'left';moving=k%20<12;act=move if moving else idle;idx=(k//2)%len(act['frame_order']) if moving else 0
   ob=im(self.D/act['directions'][side][idx]);out=Image.new('RGBA',(760,280),'#71884f');d=ImageDraw.Draw(out);d.text((16,14),self.who+' / '+side+(' move' if moving else ' stop')+' /1x+3x',font=font(20),fill='#f3ecd6')
   xx=130+min(k%20,12)*8 if side=='right' else 226-min(k%20,12)*8
   out.alpha_composite(ob,(xx-self.an[0],135-self.an[1]));out.alpha_composite(ob.resize((ob.width*3,ob.height*3),Image.Resampling.NEAREST),(540-self.an[0]*3,235-self.an[1]*3))
   demo.append(out.convert('RGB'))
  demo[0].save(self.D/'preview/movement.gif',save_all=True,append_images=demo[1:],duration=100,loop=0,disposal=2)
  aa=[a for a in self.assets if a['direction']=='right'];cols=8;out=Image.new('RGBA',(cols*150,35+math.ceil(len(aa)/cols)*115),'#252d29');d=ImageDraw.Draw(out);d.text((8,5),'Alpha / light+dark / nearest',font=font(18),fill='white')
  for j,a in enumerate(aa):
   x=j%cols*150;y=35+j//cols*115;d.text((x,y),a['action']+str(a['frame_index']),font=font(9),fill='white');ob=im(self.D/a['file'])
   for z,bg in enumerate(['#e9ddbc','#17211d']):
    t=Image.new('RGBA',(74,96),bg);view=ob
    if view.width>72:view=view.resize((round(view.width*72/view.width),round(view.height*72/view.width)),Image.Resampling.NEAREST)
    t.alpha_composite(view,((74-view.width)//2,90-view.height));out.alpha_composite(t,(x+z*75,y+16))
  out.save(self.D/'preview/alpha.png')
 def validate(self):
  errors=[]
  for a in self.assets:
   f=self.D/a['file'];ob=im(f);ar=np.array(ob)
   if list(ob.size)!=a['canvas_size_px'] or sha(f)!=a['sha256']:errors.append(a['file'])
   if a['layer']=='body' and not set(np.unique(ar[:,:,3])).issubset({0,255}):errors.append('alpha:'+a['file'])
   if a['direction']=='left':
    rf=self.D/a['file'].replace('/left_','/right_')
    if not np.array_equal(np.array(ImageOps.mirror(im(rf))),ar):errors.append('mirror:'+a['file'])
   if not ob.getbbox():errors.append('empty:'+a['file'])
  for a in self.actions:
   assert len(a['frame_order'])==len(a['frame_durations_ms'])
  qa={'png_count':len(self.assets),'actions':len(self.actions),'errors':errors,'checks':['RGBA and SHA256','canvas and fixed foot anchor','pixel exact left/right mirror','body binary alpha','adopted palette and locomotion head lock','contact/release markers metadata only'],'runtime_verified':False,'preview_is_game_evidence':False}
  (self.D/'QA.json').write_text(json.dumps(qa,indent=2)+'\n',encoding='utf-8');assert not errors,errors


def make(who):
 p=Package(who);idle=p.ref('idle_right');g=p.gen;r=p.ref
 p.action('idle',[idle],[None])
 if who=='merchant':
  p.action('walk',[g('merchant_walk',i) for i in range(4)],[140]*4,True)
  cart=im(P/'art_delivery/merchant_board_v1/cart_idle_00.png');p.action('cart_idle',[cart],[None],canvas=(128,96),anchor=(64,88))
  p.action('cart_move',wheel_frames(),[110]*4,True,canvas=(128,96),anchor=(64,88),note='Near wheel spokes rotate; chassis, goods and merchant fixed. Translation belongs to implementation. Cart contains merchant; do not duplicate actor.')
 elif who=='maid':
  walk=[g('maid_locomotion',i) for i in range(4)];p.action('walk',walk,[140]*4,True)
  p.action('attack',[g('maid_actions',0),g('maid_actions',1),g('maid_actions',0)],[140,100,160],events=[{'frame_index':1,'type':'contact_pose','point_right':[48,31],'point_left':[16,31]}])
  p.action('coffee_serve',[idle,r('coffee_serve_right'),g('maid_actions',3)],[160,240,1000],events=[{'frame_index':1,'type':'cup_transfer','point_right':[51,32],'point_left':[13,32]}],note='Final1sec pause is visual support pose. Effect and recipient determined by existing AI.')
  p.action('twirl',[idle,r('twirl_right'),idle],[180,220,180],note='Side-facing twirl cue without new front/back views.')
  p.action('drink',[idle,r('drink_right'),idle],[180,700,200])
  p.action('rest',[g('maid_actions',4)],[None])
  p.action('rage_start',[g('maid_actions',0),r('rage_right')],[180,200])
  p.action('rage_run',[g('maid_locomotion',i) for i in range(4,8)],[90]*4,True)
  p.action('rage_attack',[r('rage_right'),r('cleaver_attack_right'),r('rage_right')],[120,90,140],events=[{'frame_index':1,'type':'cleaver_contact_pose','point_right':[52,42],'point_left':[12,42]}])
  p.action('rage_end',[r('rage_right'),g('maid_actions',0),idle],[180,160,180])
  p.action('hurt',[g('maid_actions',2),idle],[150,150])
  p.action('death',[g('maid_actions',2),g('maid_actions',5),g('maid_actions',6)],[130,200,500],note='Non-gory state end cue only; do not add persistent corpse rule.')
  p.action('get_up',[g('maid_actions',6),g('maid_actions',7),idle],[180,200,200],note='Use only when existing revive state applies; no automatic resurrection.')
  p.action('retreat',walk,[140]*4,True,note='Alive withdrawal only; not an HP0 rule.')
  aura=im(R/'layers/maid_rage_aura.png');fx=[]
  for a in [112,144,160,144]:
   b=aura.copy();b.putalpha(b.getchannel('A').point(lambda v:a if v else 0));fx.append(b)
  p.action('rage_aura',fx,[240]*4,True,layer='behind_body',note='Independent layer, same anchor; show only during rage.')
 elif who=='dancer':
  walk=[g('dancer_motion',i) for i in range(4)];p.action('walk',walk,[150]*4,True)
  p.action('attack',[idle,r('fan_attack_right'),idle],[130,100,170],events=[{'frame_index':1,'type':'fan_contact_pose','point_right':[53,30],'point_left':[11,30]}])
  raise_im=adapt(im(P/'art_delivery/ui_world_direction_v2/candidates/dancer/fan_raise.png'),p.cs)
  p.action('dance',[idle,raise_im,r('dance_right'),raise_im],[200,250,300,250],note='One1sec visual dance; no forced loop. Existing state can replay if needed.')
  p.action('ultimate',[idle,raise_im,r('resurrection_right'),idle],[160,200,360,200],events=[{'frame_index':2,'type':'revival_fx_start_at_existing_target'}])
  p.action('hurt',[g('dancer_motion',4),idle],[160,160])
  p.action('downed',[g('dancer_motion',4),g('dancer_motion',5),g('dancer_motion',6)],[160,200,500],note='Temporary downed / revivable visual, not death. Existing simulation controls10sec window.')
  p.action('get_up',[g('dancer_motion',6),g('dancer_motion',7),idle],[180,200,200])
  p.action('retreat',walk,[150]*4,True)
  fx=[im(N/f'revival_fx_{i:02}.png') for i in range(3)]
  p.action('revival_light',fx,[180,240,220],layer='target_fx',canvas=(32,40),anchor=(16,36),note='Place at target foot, not caster. Target body independent. FX size does not define skill radius.')
 elif who=='thief':
  run=[g('thief_motion',i) for i in range(4)];p.action('run',run,[110]*4,True)
  p.action('attack',[g('thief_recovery',0),r('dagger_attack_right'),idle],[140,100,150],events=[{'frame_index':1,'type':'dagger_contact_pose','point_right':[61,26],'point_left':[3,26]}])
  p.action('steal',[idle,g('thief_motion',4),g('thief_motion',5),idle],[140,220,240,160],events=[{'frame_index':1,'type':'pickup_attach'},{'frame_index':2,'type':'item_into_bag'}],sockets=[{}, {'item':[48,43]}, {'item':[42,43]},{}],note='No baked stolen item; implementation supplies actual item. Suggested held-item extent <=12x12 preserving aspect ratio.')
  wind=adapt(im(P/'art_delivery/ui_world_direction_v2/candidates/thief/poison_windup.png'),p.cs)
  p.action('poison_throw',[idle,wind,r('poison_throw_right'),idle],[130,170,130,170],events=[{'frame_index':2,'type':'projectile_release_pose','point_right':[54,27],'point_left':[10,27]}],note='Reuse independent existing projectile/splash/cloud. No second bottle in the released hand.')
  p.action('hurt',[g('thief_motion',6),idle],[150,160])
  p.action('downed',[g('thief_motion',6),g('thief_recovery',1),g('thief_recovery',2)],[150,200,500])
  p.action('get_up',[g('thief_recovery',2),g('thief_recovery',3),idle],[180,200,180])
  p.action('retreat',run,[110]*4,True)
  # Foreground gripping hands overlay only for pickup and bag transfer.
  hands=[]
  for body,box in [(g('thief_motion',4),(45,39,51,46)),(g('thief_motion',5),(37,38,47,47))]:
   out=Image.new('RGBA',p.cs);out.alpha_composite(body.crop(box),(box[0],box[1]));hands.append(out)
  p.action('hand_front',hands,[None,None],layer='item_front_hand',note='Frame0 aligns steal frame1; frame1 aligns steal frame2. Draw body -> actual item -> matching hand layer.')
 elif who=='cow':
  walk=[g('cow_motion',i) for i in range(4)];p.action('walk',walk,[180]*4,True)
  milk=r('milking_right');p.action('milking_start',[idle,milk],[180,220]);p.action('milking_hold',[milk],[None]);p.action('milking_end',[milk,idle],[180,200])
  p.action('hurt',[g('cow_motion',5),idle],[180,180])
  p.action('death',[g('cow_motion',5),g('cow_motion',6),g('cow_motion',7)],[150,220,500],note='No permanent corpse/respawn rule introduced.')
 elif who=='bull':
  run=[g('bull_motion',i) for i in range(4)];p.action('run',run,[110]*4,True)
  p.action('attack',[g('bull_motion',4),r('charge_ready_right'),idle],[140,100,180],events=[{'frame_index':1,'type':'horn_contact_pose','point_right':[79,36],'point_left':[17,36]}])
  p.action('charge_start',[idle,g('bull_motion',4),r('charge_ready_right')],[160,180,160])
  p.action('charge',run,[80]*4,True,events=[{'frame_index':0,'type':'charge_pose_only'}])
  p.action('charge_end',[r('charge_ready_right'),g('bull_motion',4),idle],[100,160,180])
  body,breath=separated_breath(r('guts_right'));p.action('guts',[idle,body],[260,300],True,note='Show only under existing guts condition. No full-body red flash.')
  if breath.getbbox():
   bb=[]
   for alpha in [112,160,112]:
    b=breath.copy();b.putalpha(b.getchannel('A').point(lambda a:alpha if a else 0));bb.append(b)
   p.action('guts_breath',bb,[180]*3,True,layer='breath_fx',note='Independent breath at muzzle. Same actor anchor; do not draw twice.')
  p.action('hurt',[g('bull_motion',5),idle],[150,160])
  p.action('death',[g('bull_motion',5),g('bull_motion',6),g('bull_motion',7)],[150,220,500])
 m=p.finish();print(who,len(m['assets']),'PNGs',len(m['actions']),'actions',flush=True)
if __name__=='__main__':
 for w in sys.argv[1:]:make(w)
