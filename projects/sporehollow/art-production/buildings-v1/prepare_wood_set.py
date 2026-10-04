from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import numpy as np,json,hashlib,runpy
R=Path(__file__).resolve().parents[2];P=R/"art-production/buildings-v1";D=R/"art_delivery/wood_buildings_v1"
# Reuse the approved wood sample's original textures and projection.
v=runpy.run_path(str(P/"prepare_room_preview.py"))
for folder in ["wall/normal","wall/damaged","floor/perimeter","floor/boundary","door","review"]:(D/folder).mkdir(parents=True,exist_ok=True)
assets=[]
def save(im,fn,anchor,use,**extra):
 im.save(D/fn);a=im.getchannel("A")
 assert im.mode=="RGBA" and set(a.getdata())<={0,255}
 assets.append(dict(file=fn,canvas_size_px=list(im.size),anchor_px=list(anchor),action="static",frame_order=[0],frame_duration_ms=[None],duration_mode="hold_until_state_change",loop=False,sha256=hashlib.sha256((D/fn).read_bytes()).hexdigest(),use=use,**extra))
def damage(im):
 a=np.array(im);mark=Image.new("RGBA",im.size);d=ImageDraw.Draw(mark)
 for pts in [[(21,7),(23,11),(21,15)],[(26,18),(23,23),(26,27),(24,31)],[(11,31),(14,35),(12,39)],[(35,33),(32,37),(35,41)],[(23,44),(26,47),(24,52)]]:
  d.line(pts,fill="#5e351e",width=1);d.point((pts[1][0]+1,pts[1][1]),fill="#d1ae78")
 b=np.array(mark);ok=(a[:,:,3]==255)&(b[:,:,3]==255);a[ok]=b[ok]
 return Image.fromarray(a)
walls={}
for bits in range(16):
 im=v["wall"](bits);walls[bits]=im
 for state,f in [("normal",im),("damaged",damage(im))]:
  save(f,f"wall/{state}/wood_mask_{bits:02}.png",(24,34),"connected wood wall",connection_mask=bits,state=state)
floor=v["floor"];save(floor,"floor/wood_00.png",(0,0),"full opaque constructed wood floor")
for bits in range(16):
 im=Image.new("RGBA",(48,42));d=ImageDraw.Draw(im)
 if bits&1:d.line((0,0,47,0),fill="#99764f");d.line((0,1,47,1),fill="#d1ae78")
 if bits&2:d.line((47,0,47,41),fill="#99764f")
 if bits&4:d.line((0,41,47,41),fill="#99764f")
 if bits&8:d.line((0,0,0,41),fill="#99764f");d.line((1,1,1,40),fill="#d1ae78")
 save(im,f"floor/perimeter/mask_{bits:02}.png",(0,0),"optional exposed floor perimeter over full tile",exposed_edges_mask=bits)
for direction,line in [("n",(0,0,47,0)),("e",(47,0,47,41)),("s",(0,41,47,41)),("w",(0,0,0,41))]:
 im=Image.new("RGBA",(48,42));ImageDraw.Draw(im).line(line,fill="#ab8c65")
 save(im,f"floor/boundary/{direction}.png",(0,0),"optional mixed-material seam; apply once per edge",edge=direction)
def post(im,x0,y0,x1,y1):
 d=ImageDraw.Draw(im);d.rectangle((x0,y0+1,x1,y1+25),fill="#784321");d.line((x0,y1+25,x1,y1+25),fill="#382519");d.rectangle((x0,y0+1,x1,y1+1),fill="#bc9569",outline="#5e351e")
doors={}
for axis in ["horizontal","vertical"]:
 rear=Image.new("RGBA",(48,68));front=rear.copy()
 if axis=="horizontal":
  # Each post is a separate depth layer; no lintel covers the aperture.
  post(rear,0,15,5,26);post(front,42,15,47,26)
 else:
  post(rear,18,0,29,5);post(front,18,36,29,41)
 for layer,f in [("frame_rear",rear),("frame_front",front)]:
  save(f,f"door/{axis}_{layer}.png",(24,34),"normal wood door frame depth layer",orientation=axis,layer=layer)
 for state in ["closed","open"]:
  leaf=Image.new("RGBA",(48,68))
  if axis=="horizontal":
   base=v["leaf"]
   leaf.alpha_composite(base if state=="closed" else base.resize((7,32),Image.Resampling.NEAREST),(6,20) if state=="closed" else (6,17))
  else:
   d=ImageDraw.Draw(leaf)
   if state=="closed":
    # Vertical leaf is viewed edge-on, not a rotated horizontal sprite.
    tex=v["leaf"].resize((6,54),Image.Resampling.NEAREST);leaf.alpha_composite(tex,(21,7))
    d.line((21,7,21,59),fill="#bc9569");d.line((26,7,26,60),fill="#382519")
   else:
    tex=v["leaf"].crop((0,0,24,28));leaf.alpha_composite(tex,(24,6))
    d.line((24,6,47,6),fill="#bc9569");d.line((24,33,47,33),fill="#382519")
  for health,f in [("normal",leaf),("damaged",damage(leaf))]:
   save(f,f"door/{axis}_leaf_{state}_{health}.png",(24,34),"door leaf; never stack wall in aperture",orientation=axis,door_state=state,state=health)
  result=rear.copy();result.alpha_composite(leaf);result.alpha_composite(front);doors[(axis,state)]=result
  for lockstate in ["normal","broken"]:
   lock=Image.new("RGBA",(48,68));d=ImageDraw.Draw(lock)
   cx,cy=({"horizontal":{"closed":(36,34),"open":(10,31)},"vertical":{"closed":(23,43),"open":(43,21)}}[axis][state])
   if lockstate=="normal":
    d.line((cx-1,cy,cx-1,cy-2,cx+1,cy-2,cx+1,cy),fill="#ad9557",width=1);d.rectangle((cx-2,cy,cx+2,cy+3),fill="#ad9557",outline="#382519");d.point((cx,cy+1),fill="#382519")
   else:
    d.line((cx-2,cy-2,cx-2,cy-3,cx,cy-3),fill="#c6b98f");d.rectangle((cx-2,cy+1,cx,cy+3),fill="#786a56");d.point((cx+2,cy+2),fill="#c6b98f")
   save(lock,f"door/{axis}_lock_{state}_{lockstate}.png",(24,34),"locked-door only hardware; independent lock HP state",orientation=axis,door_state=state,lock_state=lockstate)
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",15)
proof=Image.new("RGB",(1120,850),"#e7d9b5");d=ImageDraw.Draw(proof)
d.text((16,10),"木壁16接続・損傷・縦横ドア（素材合成／ゲーム内検証ではありません）",font=font,fill="#382519")
for bits in range(16):
 x=22+(bits%8)*136;y=52+(bits//8)*165
 im=walls[bits].resize((96,136),Image.Resampling.NEAREST);proof.paste(im,(x,y),im);d.text((x,y+137),f"mask {bits:02}",font=font,fill="#382519")
for j,(axis,state) in enumerate(doors):
 x=25+j*145;y=420;im=doors[(axis,state)].resize((96,136),Image.Resampling.NEAREST);proof.paste(im,(x,y),im);d.text((x,y+140),axis[:1]+" "+state,font=font,fill="#382519")
for j,bits in enumerate([5,10,15]):
 x=660+j*145;y=420;im=damage(walls[bits]).resize((96,136),Image.Resampling.NEAREST);proof.paste(im,(x,y),im);d.text((x,y+140),"damaged "+str(bits),font=font,fill="#382519")
d.text((18,610),"床は全面不透明。外周・異素材境界は上から必要な辺だけ重ねます。",font=font,fill="#382519")
for j in range(6):
 for k in range(4):proof.paste(floor,(22+j*48,650+k*42))
keeper=v["keeper"];dog=v["dog"]
proof.paste(keeper,(370,740-44),keeper);proof.paste(dog,(440,740-44),dog);d.text((345,765),"1× 主人公・柴犬（既存PNG）",font=font,fill="#382519")
proof.save(D/"review/connections.png")
# Reuse the original approved room proof byte-for-byte as review, keeping historical status separate.
import shutil
shutil.copy2(R/"art_delivery/wood_room_preview_v1/review/room-size.png",D/"review/approved-room-preview.png")
# Exact seam and full-alpha checks.
for bits,im in walls.items():
 for bit,coords in [(1,[(x,1) for x in range(18,30)]),(2,[(47,y) for y in range(16,28)]),(4,[(x,42) for x in range(18,30)]),(8,[(0,y) for y in range(16,28)])]:
  if bits&bit: assert all(im.getpixel(p)[3]==255 for p in coords),(bits,bit)
assert floor.getchannel("A").getextrema()==(255,255)
assert doors["horizontal","open"].crop((13,23,42,50)).getchannel("A").getbbox() is None
# Vertical doorway center strip clear in its lower aperture in the open state.
assert doors["vertical","open"].crop((18,34,30,37)).getchannel("A").getbbox() is None
m=dict(delivery="wood_buildings_v1",status="ready_for_implementation_integration",cell_px=[48,42],wall=dict(canvas_px=[48,68],anchor_px=[24,34],top_center_px=[24,22],ground_center_px=[24,46],extrusion_px=24,connection_bits=dict(N=1,E=2,S=4,W=8),connection_masks=list(range(16)),damage="existing HP <= 50% contract; no gameplay change",neighbor_rule="completed walls of ANY material and completed door bodies connect; construction reservations do not"),floor=dict(canvas_px=[48,42],anchor_px=[0,0],perimeter_bits=dict(N=1,E=2,S=4,W=8),boundary_ownership="apply shared boundary on north/west tile's E/S edge once, not on both cells"),door=dict(anchor_px=[24,34],orientation_rule="existing implementation compares N+S completed neighbors vs E+W; vertical only if greater",layer_order=["frame_rear","leaf","lock if locked door","frame_front"],collision="image state does not define passability or enclosure",lock_damage="existing lock HP <= 0; closing does not repair it",depth_note="frame halves are separate; actors must be depth sorted with leaf/posts by projected ground; final renderer responsibility"),assets=assets,shadow="No external ground shadow. Material face shading only.",review_only=["review/connections.png","review/approved-room-preview.png"],unfinished=["soil/stone compatible set follows separately","runtime integration and isolated rendering checks are implementation responsibility"])
(D/"manifest.json").write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding="utf8")
(D/"HANDOFF.md").write_text("""# 木壁・木床・通常ドアの先行納品

木の部屋見本の方向で全接続へ展開。誘拐者の見た目修正とは独立した素材セットです。

## 完成範囲
- 木壁：N1/E2/S4/W8の全16接続×通常／損傷。単独、4端、縦横直線、L、T、十字。
- 木床：48×42の全面施工面、外周16マスク、異素材境界4辺。
- 通常ドア：縦／横、前後に分離した柱、開／閉×通常／損傷の扉板。
- 施錠ドア用の正常／破損ロック：縦横・開閉に対応。通常ドアには重ねない。
- 全PNGはRGBA・nearest・二値alpha。固定余白を切り詰めない。

## 取り込み
壁・ドアは48×68、アンカー(24,34)をセル中心pへ。上面中心(24,22)、投影した地面中心(24,46)、高さ24px。床は48×42でセル左上に配置。主人公32×48／(16,44)、柴犬48×48／(24,44)の既存素材を変更しない。

接続は素材の種類を問わず完成済み壁・完成済みドア本体に対して算出。接続口に端面を置かない。土・石の後続セットも同じ口形状とアンカーで納品する。ドアセルへ通常壁を描かず、柱後層→扉板→施錠部品→柱前層を使う。縦の扉は横の画像を回転したものではなく、立ち上がりを保って側面視へ整形した。

床の外周マスクは外へ露出する辺だけ。異素材境界は共有辺の北／西側セルがE／Sを1回だけ描く。全面床の上へ部品を重ねるため地面が透けない。外周と境界を同じ辺に二重描画しない。

損傷はART_SPECの既存HP50%以下用。ロック破損は独立した既存lock HP0の状態。画像側でHP、速度、通行、ダメージ、ドア向き判定を変更しない。

ドア開状態の通路、縦壁の座標、接続判定、人物が柱・扉の手前／奥を通る描画順は実装担当が確認する。部品の前後層は利用可能だが、全層を単に同じ順へ固定すれば人物の遮蔽も解決するという意味ではない。

地面影は焼き込んでいない。木の側面陰影とゲーム側の接地影を区別する。動作フレームはなく全PNGが静止・状態切替、durationはnull（状態が変わるまで保持）、loop=false。

## 検査と未完成
寸法、RGBA、alpha、接続口の連続、全床opaque、縦横開口の透明、SHA256を検査。reviewは保存済み実背景への合成／拡大比較でありゲーム内動作検証ではない。初回部屋画像は履歴としてそのまま保存しているため画像内の確認待ち表示は当時のもの。

土・石は次の独立セット。ゲーム取り込みと隔離描画検証は未実施。原画・プロンプト・加工手順は../../art-production/buildings-v1/。
""",encoding="utf8")
print("validated",len(assets),"wood PNGs")

