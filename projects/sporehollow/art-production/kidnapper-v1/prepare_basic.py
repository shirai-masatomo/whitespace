from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
import numpy as np,json,hashlib,shutil
R=Path(__file__).resolve().parents[2];P=R/"art-production/kidnapper-v1";D=R/"art_delivery/kidnapper_basic_v1"
D.mkdir(exist_ok=True);(D/"review").mkdir(exist_ok=True)
raw=Image.open(P/"originals/motions.png").convert("RGBA")
idle=Image.open(R/"art_delivery/kidnapper_preview_v2/idle_right_00.png").convert("RGBA")
colors=["382519","292729","454453","646170","87768e","72566c","503d50","9b849a","d2b396","edb476","fff0ce","784321","99653f"]
rgb=[tuple(bytes.fromhex(c)) for c in colors];pal=Image.new("P",(1,1));pal.putpalette(sum([list(c) for c in rgb],[])+list(rgb[0])*(256-len(rgb)))
head=idle.copy();a=np.array(head);a[19:]=0;a[15:19,:13]=0;head=Image.fromarray(a)
assets=[];clips={};images={}
def reflect(im):
 out=Image.new("RGBA",(32,48));out.alpha_composite(ImageOps.mirror(im),(1,0));return out
def outline(im):
 a=np.array(im);m=a[:,:,3]>0
 for y,x in zip(*np.where(m)):
  if any(nx<0 or ny<0 or nx>=32 or ny>=48 or not m[ny,nx] for nx,ny in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]):a[y,x,:3]=(56,37,25)
 return Image.fromarray(a)
def extract(box,attack=False):
 f=raw.crop(box);alpha=f.getchannel("A").point(lambda z:255 if z>=128 else 0);mask=np.array(alpha)>0;visited=np.zeros(mask.shape,bool);components=[]
 for yy,xx in zip(*np.where(mask)):
  if visited[yy,xx]:continue
  stack=[(yy,xx)];visited[yy,xx]=True;points=[]
  while stack:
   y,x=stack.pop();points.append((y,x))
   for dy,dx in [(0,1),(0,-1),(1,0),(-1,0)]:
    ny,nx=y+dy,x+dx
    if 0<=ny<mask.shape[0] and 0<=nx<mask.shape[1] and mask[ny,nx] and not visited[ny,nx]:visited[ny,nx]=True;stack.append((ny,nx))
  components.append(points)
 best=max(components,key=len);clean=np.zeros(mask.shape,np.uint8)
 for y,x in best:clean[y,x]=255
 alpha=Image.fromarray(clean);box=alpha.getbbox();f=f.crop(box);f.putalpha(alpha.crop(box))
 h=42;w=round(f.width*h/f.height);f=f.resize((w,h),Image.Resampling.BOX)
 a=f.getchannel("A").point(lambda z:255 if z>=128 else 0);q=f.convert("RGB").quantize(palette=pal,dither=Image.Dither.NONE).convert("RGBA");q.putalpha(a)
 # Fit by height; attach foot center, rather than centering on the extended fist.
 foot=a.crop((0,35,w,42)).getbbox();cx=round((foot[0]+foot[2])/2)
 stage=Image.new("RGBA",(48,48));stage.alpha_composite(q,(16-cx,2))
 if attack:
  # Shorten only outstretched forearm to the 32px cell; keep head, torso and legs at adopted scale.
  f=stage.crop((0,0,24,48));out=Image.new("RGBA",(32,48));out.alpha_composite(f)
  b=stage.crop((24,0,48,48));bb=b.getbbox()
  if bb:out.alpha_composite(b.crop((0,0,bb[2],48)).resize((7,48),Image.Resampling.NEAREST),(24,0))
 else:out=stage.crop((0,0,32,48))
 return outline(out)
def fixed_head(im,action,index):
 a=np.array(im);old=a.copy();a[:19]=0
 a[17:19,:10]=old[17:19,:10]
 if action=="attack" and index==0:a[14:19,:12]=old[14:19,:12]
 if action=="attack" and index==1:a[14:19,27:]=old[14:19,27:]
 im=Image.fromarray(a);im.alpha_composite(head);return im
def save(im,action,direction,index,ms,loop,layer=None,**extra):
 fn=f"{action}/{direction}_{index:02}"+(f"_{layer}" if layer else "")+".png";path=D/fn;path.parent.mkdir(exist_ok=True);im.save(path)
 assert im.size==(32,48) and set(np.array(im)[:,:,3].flat)<={0,255}
 row=dict(file=fn,canvas_size_px=[32,48],foot_anchor_px=[16,44],visible_bbox_exclusive_px=list(im.getbbox()) if im.getbbox() else None,action=action,direction=direction,frame_index=index,frame_duration_ms=ms,loop=loop,layer=layer or "body",sha256=hashlib.sha256(path.read_bytes()).hexdigest(),**extra)
 assets.append(row);images[fn]=im;return fn
for direction in ["right","left"]:
 im=idle if direction=="right" else reflect(idle)
 fn=save(im,"idle",direction,0,None,False)
 clips[f"idle_{direction}"]=dict(frames=[fn],duration_mode="hold_until_state_change",frame_duration_ms=[None],loop=False)
rows=[(0,110,1024,565),(0,570,1024,1020),(0,1030,1024,1480)]
bounds=[[0,281,523,792,1024],[0,265,566,800],[0,281,542,798]]
prepared={}
for action,row,count,timing in [("walk",0,4,[120]*4),("attack",1,3,[130,80,140]),("carry",2,3,[None,150,150])]:
 for i in range(count):
  im=extract((bounds[row][i],rows[row][1],bounds[row][i+1],rows[row][3]),attack=action=="attack" and i==1)
  prepared[action,i]=im
  if action!="carry":im=fixed_head(im,action,i)
  for direction in ["right","left"]:
   f=im if direction=="right" else reflect(im)
   if action=="carry":
    # Separate original raised arm + adopted head from body before compositing a keeper.
    arr=np.array(im);mask=np.zeros((48,32),bool);mask[12:29,2:13]=True
    front=Image.fromarray(np.where(mask[:,:,None],arr,0).astype("uint8"))
    # Purge generated head from rear, restore ONLY adopted face/cap in front.
    rear=np.array(im);rear[mask]=0;rear[:19]=0
    fronta=np.array(front);fronta[:12]=0;fronta[:19,13:]=0;front=Image.fromarray(fronta);front.alpha_composite(head)
    rear=Image.fromarray(rear)
    if direction=="left":rear=reflect(rear);front=reflect(front)
    for layer,img in [("rear",rear),("front",front)]:
     save(img,action,direction,i,timing[i],i>0,layer=layer,shoulder_px=[12 if direction=="right" else 20,16],keeper_source_pivot_px=[6,26],keeper_rotation_screen_degrees=-90 if direction=="right" else 90)
   else:save(f,action,direction,i,timing[i],action=="walk",contact=(action=="attack" and i==1))
 for direction in ["right","left"]:
  if action!="carry":
   clips[f"{action}_{direction}"]=dict(frames=[f"{action}/{direction}_{i:02}.png" for i in range(count)],frame_order=list(range(count)),frame_duration_ms=timing,loop=action=="walk",contact_frame_index=1 if action=="attack" else None)
  else:
   for state,indices,durations,loop in [("idle",[0],[None],False),("walk",[1,2],[150,150],True)]:
    clips[f"carry_{state}_{direction}"]=dict(frame_order=indices,frame_duration_ms=durations,loop=loop,frames=[dict(rear=f"carry/{direction}_{i:02}_rear.png",front=f"carry/{direction}_{i:02}_front.png",shoulder_px=[12 if direction=="right" else 20,16],keeper_source_pivot_px=[6,26],keeper_rotation_screen_degrees=-90 if direction=="right" else 90) for i in indices])
# Structure attacks reuse the same empty-handed clip; no new gameplay event timing.
for direction in ["right","left"]:
 clips[f"structure_attack_{direction}"]=dict(clips[f"attack_{direction}"],use="wall and door attack visual; damage timing remains existing logic")
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",15)
proof=Image.new("RGB",(1060,680),"#e7d9b5");d=ImageDraw.Draw(proof)
d.text((18,10),"採用v2の誘拐者：静止・歩行・攻撃・別レイヤー運搬（合成確認）",font=font,fill="#382519")
for row,action,count in [(0,"walk",4),(1,"attack",3)]:
 d.text((18,55+row*210),action,font=font,fill="#382519")
 for i in range(count):
  im=images[f"{action}/right_{i:02}.png"];z=im.resize((128,192),Image.Resampling.NEAREST);proof.paste(z,(140+i*175,40+row*210),z)
keeper=Image.open(R/"art_delivery/characters_v1/keeper_idle_right_00.png").convert("RGBA")
rot=keeper.transpose(Image.Transpose.ROTATE_90)
def carry_preview(index,withkeeper=True):
 im=Image.new("RGBA",(96,80));pos=(38,26);im.alpha_composite(images[f"carry/right_{index:02}_rear.png"],pos)
 # Exact transform of source pivot(6,26) under 90deg CCW: (26,25).
 if withkeeper:im.alpha_composite(rot,(pos[0]+12-26,pos[1]+16-25))
 im.alpha_composite(images[f"carry/right_{index:02}_front.png"],pos);return im
for i in range(3):
 im=carry_preview(i).resize((192,160),Image.Resampling.NEAREST);proof.paste(im,(80+i*255,488),im)
d.text((18,454),"carry：主人公PNGを別描画。前層は保持腕＋採用した帽子／顔。",font=font,fill="#382519")
proof.save(D/"review/basic-poses.png")
# Native-size movement right -> stop -> left -> stop, and separate carrying preview.
bg=Image.open(R/"art-production/ranch-assets-v1/references/implementation-native-scale.png").convert("RGB").crop((350,70,850,250))
frames=[]
for tick in range(56):
 im=bg.copy();dr=ImageDraw.Draw(im)
 if tick<20:x=70+tick*4;direction="right";fn=f"walk/{direction}_{tick%4:02}.png"
 elif tick<28:x=146;direction="right";fn="idle/right_00.png"
 elif tick<48:x=146-(tick-28)*4;direction="left";fn=f"walk/{direction}_{tick%4:02}.png"
 else:x=70;direction="left";fn="idle/left_00.png"
 f=images[fn];im.paste(f,(x-16,120-44),f);dr.text((12,12),"素材の動き比較／移動量はゲーム速度ではありません",font=font,fill="#fff0ce")
 frames.append(im.resize((1000,360),Image.Resampling.NEAREST))
frames[0].save(D/"review/walk-stop.gif",save_all=True,append_images=frames[1:],duration=120,loop=0)
frames=[]
for i in [0,1,2,1,2,0]:
 f=carry_preview(i);im=Image.new("RGB",(192,160),"#83905e");im.paste(f.resize((192,160),Image.Resampling.NEAREST),(0,0),f.resize((192,160),Image.Resampling.NEAREST));frames.append(im)
frames[0].save(D/"review/carry.gif",save_all=True,append_images=frames[1:],duration=[500,150,150,150,150,500],loop=0)
m=dict(delivery="kidnapper_basic_v1",status="adopted_v2_basic_actions_ready",role="existing kidnapper Lv1",assets=assets,animations=clips,foot_anchor_px=[16,44],canvas_size_px=[32,48],shadow="no external ground shadow",face="adopted v2 head pixels reused, mirrored on left, no regenerated face in delivered frames",carry=dict(order=["enemy rear","unchanged keeper source as separate transformed layer","enemy front holding arm and head"],keeper_source="../characters_v1/keeper_idle_right_00.png",keeper_source_pivot_px=[6,26],extra_extent="carried keeper may extend beyond enemy32x48; do not clip composite to enemy canvas",collision="visual support pivot does not set hitbox or movement"),review_only=["review/basic-poses.png","review/walk-stop.gif","review/carry.gif"],unfinished=["search","discovery reaction","hit reaction","retreat","runtime integration and isolated rendering"],rules="HP0 means retreat, no death. Contact frame1 is a visual reference, not a new damage rule or move speed.")
(D/"manifest.json").write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding="utf8")
print("basic frames",len(assets))

