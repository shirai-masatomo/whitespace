from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageFilter
import numpy as np,json,hashlib,ast,shutil
R=Path(__file__).resolve().parents[2];P=R/"art-production/earth-stone-v1";D=R/"art_delivery/earth_stone_buildings_v1"
raw=Image.open(P/"originals/material-kit.png").convert("RGBA")
# Load only pure geometry/texture functions; never rerun or overwrite previous deliveries.
source=ast.parse((R/"art-production/buildings-v1/prepare_room_preview.py").read_text(encoding="utf-8-sig"))
ctx=dict(Image=Image,np=np,raw=raw)
exec(compile(ast.Module(body=[n for n in source.body if isinstance(n,ast.FunctionDef) and n.name in ["texture","mask","wall"]],type_ignores=[]),"<shared geometry>","exec"),ctx)
assets=[];walls={};floors={}
def save(im,fn,anchor,use,**extra):
 path=D/fn;path.parent.mkdir(parents=True,exist_ok=True);im.save(path)
 assert im.mode=="RGBA" and set(np.array(im)[:,:,3].flat)<={0,255}
 assets.append(dict(file=fn,canvas_size_px=list(im.size),anchor_px=list(anchor),action="static",frame_order=[0],frame_duration_ms=[None],duration_mode="hold_until_state_change",loop=False,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),use=use,**extra))
specs={
 "soil":dict(front=(64,213,522,441),floor=(630,161,959,453),cap=(1080,245,1473,285),pal=["805b37","a17a4a","b99059","caa571"],floorpal=["b59768","bea074","c6aa7e"],edge="#977649",light="#d0b58b"),
 "stone":dict(front=(64,584,522,833),floor=(630,565,959,858),cap=(1080,678,1473,704),pal=["595b4b","767968","939482","b2b09a"],floorpal=["919583","a3a591","b3b39e"],edge="#787d6c",light="#c7c5ae")}
for material,s in specs.items():
 ctx["front"]=ctx["texture"](s["front"],(48,24),s["pal"])
 ctx["cap"]=ctx["texture"](s["cap"],(48,12),s["pal"][1:])
 tile=raw.crop(s["floor"]).convert("RGB").resize((48,42),Image.Resampling.BOX).filter(ImageFilter.MedianFilter(3))
 lum=np.array(tile.convert("L"));lo,hi=np.quantile(lum,[0.18,0.9])
 pal=np.array([tuple(bytes.fromhex(c))+(255,) for c in s["floorpal"]],dtype=np.uint8)
 a=pal[np.where(lum<lo,0,np.where(lum>hi,2,1))]
 # Wrap edge pairs with a quiet common material tone; no alpha cuts.
 c=tuple(bytes.fromhex(s["floorpal"][1]))+(255,)
 a[0]=a[-1]=c;a[:,0]=a[:,-1]=c
 f=Image.fromarray(a);floors[material]=f
 save(f,f"{material}/floor/base.png",(0,0),"fully opaque constructed floor",material=material)
 for bits in range(16):
  base=ctx["wall"](bits);a=np.array(base)
  # Shared geometry adds wood-colored outlines: replace only those exact shades.
  for src,dst in [((94,53,30),s["pal"][0]),((56,37,25),"382519")]:
   match=np.all(a[:,:,:3]==src,axis=2)&(a[:,:,3]>0);a[match,:3]=tuple(bytes.fromhex(dst))
  base=Image.fromarray(a);walls[material,bits]=base
  crack=Image.new("RGBA",(48,68));d=ImageDraw.Draw(crack)
  for pts in [[(21,7),(24,12),(21,16)],[(27,20),(24,24),(26,29),(23,34)],[(10,31),(14,35),(11,40)],[(36,31),(32,36),(34,42)],[(24,43),(21,48),(24,53)]]:
   d.line(pts,fill="#5e4933" if material=="soil" else "#484c40")
   d.point((pts[1][0]+1,pts[1][1]),fill=s["light"])
  damage=np.array(base);overlay=np.array(crack);solid=(damage[:,:,3]>0)&(overlay[:,:,3]>0);damage[solid]=overlay[solid]
  for state,im in [("normal",base),("damaged",Image.fromarray(damage))]:
   save(im,f"{material}/wall/{state}/mask_{bits:02}.png",(24,34),"connected wall",material=material,connection_mask=bits,state=state)
  edge=Image.new("RGBA",(48,42));d=ImageDraw.Draw(edge)
  for bit,line in [(1,(0,0,47,0)),(2,(47,0,47,41)),(4,(0,41,47,41)),(8,(0,0,0,41))]:
   if bits&bit:d.line(line,fill=s["edge"])
  save(edge,f"{material}/floor/perimeter/mask_{bits:02}.png",(0,0),"exposed construction edge over opaque floor",exposed_edges_mask=bits)
 for direction,line in [("n",(0,0,47,0)),("e",(47,0,47,41)),("s",(0,41,47,41)),("w",(0,0,0,41))]:
  edge=Image.new("RGBA",(48,42));ImageDraw.Draw(edge).line(line,fill=s["edge"])
  save(edge,f"{material}/floor/boundary/{direction}.png",(0,0),"mixed-material boundary; once per shared edge",edge=direction)
for bits in range(16):
 w=Image.open(R/f"art_delivery/wood_buildings_v1/wall/normal/wood_mask_{bits:02}.png").convert("RGBA");walls["wood",bits]=w
 assert all(np.array(w.getchannel("A")).tobytes()==np.array(walls[m,bits].getchannel("A")).tobytes() for m in specs)
 for m in ["wood","soil","stone"]:
  a=walls[m,bits].getchannel("A")
  for bit,points in [(1,[(x,1) for x in range(18,30)]),(2,[(47,y) for y in range(16,28)]),(4,[(x,42) for x in range(18,30)]),(8,[(0,y) for y in range(16,28)])]:
   if bits&bit:assert all(a.getpixel(xy)==255 for xy in points)
floors["wood"]=Image.open(R/"art_delivery/wood_buildings_v1/floor/wood_00.png").convert("RGBA")
assert all(f.getchannel("A").getextrema()==(255,255) for f in floors.values())
background=Image.open(R/"art-production/ranch-assets-v1/references/implementation-native-scale.png").convert("RGBA")
room=background.crop((760,90,1110,390));origin=(28,43);cells={(x,y) for y in range(5) for x in range(6) if x in [0,5] or y in [0,4]}
for y in range(5):
 for x in range(6):room.alpha_composite(floors[["soil","wood","stone"][x//2]],(origin[0]+x*48,origin[1]+y*42))
drawables=[]
for x,y in cells:
 bits=sum(b for dx,dy,b in [(0,-1,1),(1,0,2),(0,1,4),(-1,0,8)] if (x+dx,y+dy) in cells)
 p=(origin[0]+x*48+24,origin[1]+y*42+21)
 im=walls[["soil","wood","stone"][x//2],bits]
 if (x,y)==(3,4):
  im=Image.new("RGBA",(48,68))
  for layer in ["frame_rear","leaf_open_normal","frame_front"]:im.alpha_composite(Image.open(R/f"art_delivery/wood_buildings_v1/door/horizontal_{layer}.png"))
 drawables.append((p[1],im,(p[0]-24,p[1]-34)))
for name,pos,anchor in [("keeper_idle_right_00.png",(125,169),(16,44)),("shiba_idle_right_00.png",(193,181),(24,44))]:
 im=Image.open(R/"art_delivery/characters_v1"/name);drawables.append((pos[1]-14,im,(pos[0]-anchor[0],pos[1]-anchor[1])))
for _,im,pos in sorted(drawables,key=lambda t:t[0]):room.alpha_composite(im,pos)
(D/"review").mkdir(exist_ok=True)
room.save(D/"review/mixed-room-native.png")
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",16);proof=Image.new("RGB",(1120,920),"#e7d9b5");d=ImageDraw.Draw(proof)
d.text((18,10),"土・木・石の接続／施工床：保存済み背景への合成比較",font=font,fill="#382519")
proof.paste(room,(16,54));proof.paste(room.resize((700,600),Image.Resampling.NEAREST),(400,54))
d.text((18,365),"1×：主人公v1・柴犬Cを維持",font=font,fill="#382519");d.text((400,670),"2×：混在する角・端・木ドア。実ゲーム検証ではありません。",font=font,fill="#382519")
for i,m in enumerate(["soil","wood","stone"]):
 d.text((25+i*365,722),m+"：通常／損傷／床の連続",font=font,fill="#382519")
 normal=walls[m,10];path=(D/f"{m}/wall/damaged/mask_10.png") if m!="wood" else R/"art_delivery/wood_buildings_v1/wall/damaged/wood_mask_10.png"
 for j,im in enumerate([normal,Image.open(path)]):
  z=im.resize((96,136),Image.Resampling.NEAREST);proof.paste(z,(25+i*365+j*110,753),z)
 for yy in range(3):
  for xx in range(2):proof.paste(floors[m],(255+i*365+xx*48,756+yy*42))
proof.save(D/"review/materials-and-seams.png")
m=dict(delivery="earth_stone_buildings_v1",status="ready_for_implementation_integration",assets=assets,cell_px=[48,42],wall=dict(canvas_px=[48,68],anchor_px=[24,34],top_center_px=[24,22],ground_center_px=[24,46],extrusion_px=24,connection_bits=dict(N=1,E=2,S=4,W=8),damage="existing HP<=50%"),floor=dict(canvas_px=[48,42],anchor_px=[0,0],coverage="all alpha255",soil_identity="even compacted pale clay, deliberately different from natural grassy ground",boundary_owner="north/west cell renders E/S once"),compatible_doors="../wood_buildings_v1/door/",shadow="no external ground shadows",review_only=["review/materials-and-seams.png","review/mixed-room-native.png"],unfinished=["runtime integration and isolated render validation"])
(D/"manifest.json").write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding="utf8")
(D/"HANDOFF.md").write_text("""# 土・石の壁と床
完成：土／石それぞれ16接続×通常／損傷、全面床、外周16マスク、異素材境界4辺。計106PNG。木と共通の接続形状・アンカー、通常木ドアはwood_buildings_v1/doorを流用。

壁48×68、アンカー(24,34)をセル中心pへ。上面中心(24,22)、投影地面中心(24,46)、高さ24。接続N1/E2/S4/W8。土・木・石のalpha形状が全16パターンで一致し、全接続口が不透明であることを検査。異素材でも接続ありと判定し、内部へ端面を挿入しない。
床48×42、セル左上、全面alpha255。土は草や小石の無い、押し固めた明るい粘土の施工面。未舗装の自然地面とは異なる。外周は露出辺のみ、異素材境界は北／西側のセルがE／Sを一度だけ描く。境界部品は全面床へ重ね、床を切り抜かない。

損傷は既存ART_SPECのHP50%以下用。耐久値・新しいルールを決めていない。ドアの開口へ通常壁を置かない。縦壁座標・接続判定・奥行き順・通行は実装担当の検証範囲。
RGBA・nearest、静止状態保持、loop=false、duration=null。影の焼き込みなし、面の陰影は素材。顔・相対サイズ・既存キャラクターの画像は変更なし。

原画・プロンプト・加工は../../art-production/earth-stone-v1/。全ファイルの寸法・基準・SHA256はmanifest.json。
reviewは保存済み実背景への素材合成で、ゲーム内確認済みの証拠ではない。未完成はゲームへの取り込みと隔離描画検証。
""",encoding="utf8")
print("validated",len(assets),"PNGs and all16 mixed-material alpha joins")

