from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import numpy as np,json,hashlib
R=Path(__file__).resolve().parents[2];P=R/"art-production/buildings-v1";D=R/"art_delivery/wood_room_preview_v1"
for s in ["wall","floor","door","review"]:(D/s).mkdir(parents=True,exist_ok=True)
raw=Image.open(P/"originals/wood-kit.png").convert("RGBA")
def texture(box,size,colors):
 im=raw.crop(box).convert("RGB");ratio=size[0]/size[1]
 w,h=im.size
 if w/h>ratio: nw=round(h*ratio);im=im.crop(((w-nw)//2,0,(w+nw)//2,h))
 else: nh=round(w/ratio);im=im.crop((0,(h-nh)//2,w,(h+nh)//2))
 im=im.resize(size,Image.Resampling.BOX)
 cs=[tuple(bytes.fromhex(c)) for c in colors];pa=Image.new("P",(1,1));pa.putpalette(sum([list(c) for c in cs],[])+list(cs[0])*(256-len(cs)))
 return im.quantize(palette=pa,dither=Image.Dither.NONE).convert("RGBA")
front=texture((100,180,737,425),(48,24),["784321","99653f","ae7947","bc9569"])
cap=texture((829,742,1437,824),(48,12),["99653f","bc9569","d1ae78"])
floor=texture((828,75,1444,563),(48,42),["ad8b62","b8976c","bea079","c8ad86"])
# Floor is full opaque to all four edges. Equal-colour outer pairs avoid high-contrast grid seams.
a=np.asarray(floor).copy()
a[0,:,:]=a[-1,:,:]=(190,160,121,255);a[:,0,:]=a[:,-1,:]=(190,160,121,255)
floor=Image.fromarray(a);floor.save(D/"floor/wood_00.png")
leaf=texture((270,623,576,942),(36,32),["382519","5e351e","784321","99653f","bc9569","e5c89c","ad9557"])
records=[]
def save(im,path,anchor,use,extra=None):
 im.save(D/path)
 row={"file":path,"canvas_size_px":list(im.size),"anchor_px":anchor,"action":"static","frame_order":[0],"frame_duration_ms":[None],"loop":False,"use":use,"sha256":hashlib.sha256((D/path).read_bytes()).hexdigest()}
 if extra:row.update(extra)
 records.append(row)
def mask(bits):
 m=np.zeros((42,48),bool)
 m[15:27,18:30]=True
 if bits==0:m[15:27,6:42]=True
 if bits&1:m[:21,18:30]=True
 if bits&2:m[15:27,24:]=True
 if bits&4:m[21:,18:30]=True
 if bits&8:m[15:27,:24]=True
 return m
def wall(bits):
 m=mask(bits);im=Image.new("RGBA",(48,68));px=im.load()
 def connected(x,y):
  if 0<=x<48 and 0<=y<42:return m[y,x]
  if y<0:return bool(bits&1 and 18<=x<30)
  if y>=42:return bool(bits&4 and 18<=x<30)
  if x<0:return bool(bits&8 and 15<=y<27)
  return bool(bits&2 and 15<=y<27)
 # Extrude only south-facing external boundaries; connected ends have no face/cap.
 for y,x in zip(*np.where(m)):
  if not connected(x,y+1):
   for z in range(1,25):px[x,y+1+z]=front.getpixel((x,z-1))
   px[x,y+25]=(56,37,25,255)
 for y,x in zip(*np.where(m)):
  c=cap.getpixel((x,y%12))
  if any(not connected(nx,ny) for nx,ny in [(x-1,y),(x+1,y),(x,y-1)]):c=(94,53,30,255)
  px[x,y+1]=c
 return im
walls={}
for bits in [0,3,5,6,9,10,12]:
 im=wall(bits);walls[bits]=im;save(im,f"wall/wood_mask_{bits:02}.png",[24,34],"wood wall preview",{"connection_mask":bits})
save(floor,"floor/wood_00.png",[0,0],"opaque floor tile")
frame=Image.new("RGBA",(48,68));fd=ImageDraw.Draw(frame)
for x in [0,42]:
 fd.rectangle((x,16,x+5,51),fill="#784321")
 fd.rectangle((x,16,x+5,22),fill="#bc9569",outline="#5e351e")
 fd.line((x,23,x,51),fill="#382519");fd.line((x,51,x+5,51),fill="#382519")
save(frame,"door/frame_horizontal.png",[24,34],"door posts; clear aperture")
doors={}
for state in ["closed","open"]:
 l=Image.new("RGBA",(48,68))
 if state=="closed":l.alpha_composite(leaf,(6,20))
 else:l.alpha_composite(leaf.resize((7,32),Image.Resampling.NEAREST),(6,17))
 save(l,f"door/leaf_horizontal_{state}.png",[24,34],"door leaf; composite with frame",{"door_state":state})
 composed=frame.copy();composed.alpha_composite(l);doors[state]=composed
# Rendering is offline proof only; depth is sorted by cell row, never a claim of game logic validation.
background=Image.open(R/"art-production/ranch-assets-v1/references/implementation-native-scale.png").convert("RGB")
keeper=Image.open(R/"art_delivery/characters_v1/keeper_idle_right_00.png").convert("RGBA")
dog=Image.open(R/"art_delivery/characters_v1/shiba_idle_right_00.png").convert("RGBA")
def room(state):
 im=background.crop((860,100,1160,400)).convert("RGBA");origin=(30,50)
 for y in range(5):
  for x in range(5):im.alpha_composite(floor,(origin[0]+x*48,origin[1]+y*42))
 cells={(x,y) for y in range(5) for x in range(5) if x in [0,4] or y in [0,4]}
 drawables=[]
 for x,y in cells:
  p=(origin[0]+x*48+24,origin[1]+y*42+21)
  bits=sum(b for dx,dy,b in [(0,-1,1),(1,0,2),(0,1,4),(-1,0,8)] if (x+dx,y+dy) in cells)
  f=doors[state] if (x,y)==(2,4) else walls[bits]
  drawables.append((p[1],f,(p[0]-24,p[1]-34)))
 for x,y,f,anchor in [(1.5,2,keeper,(16,44)),(2.6,2.5,dog,(24,44))]:
  p=(round(origin[0]+x*48+24),round(origin[1]+y*42+21))
  drawables.append((p[1],f,(p[0]-anchor[0],p[1]+14-anchor[1])))
 for _,f,pos in sorted(drawables,key=lambda t:t[0]):im.alpha_composite(f,pos)
 return im.convert("RGB")
closed=room("closed");opened=room("open")
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",16)
proof=Image.new("RGB",(990,730),"#e7d9b5");dr=ImageDraw.Draw(proof)
dr.text((18,12),"木壁・木床・通常ドア：初回の部屋見本（合成確認）",font=font,fill="#382519")
proof.paste(closed,(18,56));dr.text((18,366),"1×：主人公42px／柴犬28pxを維持",font=font,fill="#382519")
proof.paste(opened.resize((600,600),Image.Resampling.NEAREST),(370,56));dr.text((370,670),"2×：開いたドア。縦横・角のつながりを確認",font=font,fill="#382519")
for i,state in enumerate(["closed","open"]):
 z=doors[state].resize((96,136),Image.Resampling.NEAREST);proof.paste(z,(30+i*152,445),z);dr.text((30+i*152,598),state,font=font,fill="#382519")
dr.text((18,641),"接続契約・初回方向性は確認待ち。",font=font,fill="#382519")
dr.text((18,672),"ゲーム内描画の検証画像ではありません。",font=font,fill="#382519")
proof.save(D/"review/room-size.png")
gif=[]
for r in [closed,opened]:
 z=r.resize((600,600),Image.Resampling.NEAREST);gif.append(z)
gif[0].save(D/"review/door-open-close.gif",save_all=True,append_images=gif[1:],duration=[1000,1000],loop=0)
manifest={"delivery":"wood_room_preview_v1","status":"direction_review_not_full_set","spec_source":"latest implementation ART_SPEC/BUILDINGS read2026-10-04","cell_px":[48,42],"wall":{"canvas":[48,68],"anchor":[24,34],"top_center_local":[24,22],"projected_ground_center_local":[24,46],"extrusion_height_px":24,"connection_bits":{"N":1,"E":2,"S":4,"W":8},"included_masks":[0,3,5,6,9,10,12],"shadow":"No external ground shadow baked. Frontface shading is material, do not remove."},"assets":records,"review_only":["review/room-size.png","review/door-open-close.gif"],"unfinished":["remaining connection masks","soil/stone materials","damage states","floor perimeter/boundary parts","vertical doors","lock components","implementation contract confirmation","user direction confirmation","runtime integration validation"],"unchanged_characters":{"keeper":"../characters_v1/keeper_idle_right_00.png","shiba":"../characters_v1/shiba_idle_right_00.png"}}
(D/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding="utf8")
print("preview assets",len(records))

