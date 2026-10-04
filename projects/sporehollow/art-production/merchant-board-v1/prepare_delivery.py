from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,hashlib,ast,numpy as np
R=Path(__file__).resolve().parents[2];P=R/"art-production/merchant-board-v1";D=R/"art_delivery/merchant_board_v1"
(D/"review").mkdir(parents=True,exist_ok=True)
src=Image.open(P/"originals/cart-board.png").convert("RGBA")
alpha=src.getchannel("A").point(lambda v:255 if v>=128 else 0);b=alpha.getbbox()
crop=src.crop(b);crop.putalpha(alpha.crop(b))
s=min(120/crop.width,82/crop.height);size=(round(crop.width*s),round(crop.height*s))
small=crop.resize(size,Image.Resampling.BOX)
# Reuse the established merchant/cart palette without executing or modifying its producer.
tree=ast.parse((R/"art-production/merchant-cart-v2/prepare_delivery.py").read_text(encoding="utf-8-sig"))
hexes=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=="hexes" for t in n.targets))
rgb=[tuple(bytes.fromhex(c)) for c in hexes];pal=Image.new("P",(1,1));pal.putpalette(sum([list(c) for c in rgb],[])+list(rgb[0])*(256-len(rgb)))
a=small.getchannel("A").point(lambda v:255 if v>=128 else 0)
small=small.convert("RGB").quantize(palette=pal,dither=Image.Dither.NONE).convert("RGBA");small.putalpha(a)
out=Image.new("RGBA",(128,96));out.alpha_composite(small,(64-small.width//2,88-small.height))
# Final-grid repair: establish crisp continuous1px contour including wheel openings.
v=np.asarray(out).copy();solid=v[:,:,3]>0;edge=np.zeros_like(solid)
for y,x in zip(*np.where(solid)):
 edge[y,x]=any(nx<0 or ny<0 or nx>=128 or ny>=96 or not solid[ny,nx] for nx,ny in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)])
v[edge,:3]=(56,37,25)
out=Image.fromarray(v);out.save(D/"cart_idle_00.png")
assert out.size==(128,96) and out.getbbox()[3]==88
assert set(out.getchannel("A").getdata())=={0,255}
# Preserve accepted designs and unrelated production files.
m=json.loads((R/"art_delivery/merchant_cart_v2/manifest.json").read_text(encoding="utf8"))
for z in m["assets"]:assert hashlib.sha256((R/"art_delivery/merchant_cart_v2"/z["file"]).read_bytes()).hexdigest()==z["sha256"]
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",16)
proof=Image.new("RGB",(950,660),"#e7d9b5");d=ImageDraw.Draw(proof)
d.text((18,12),"入口の仮表示 → 盤面専用の荷車素材",font=font,fill="#382519")
old=Image.open(P/"references/user-current-crop.png").convert("RGB")
proof.paste(old,(25,57));d.text((25,255),"現在の仮表示（ユーザー画像）",font=font,fill="#382519")
bg=Image.open(R/"art-production/ranch-assets-v1/references/implementation-native-scale.png").convert("RGB")
patch=bg.crop((350,135,850,335));proof.paste(patch,(405,57))
#1x assets; align foot baseline170 within the patch.
proof.paste(out,(455,227-88),out)
keeper=Image.open(R/"art_delivery/characters_v1/keeper_idle_right_00.png").convert("RGBA")
dog=Image.open(R/"art_delivery/characters_v1/shiba_idle_right_00.png").convert("RGBA")
proof.paste(keeper,(644,227-44),keeper);proof.paste(dog,(739,227-44),dog)
d.text((405,268),"実寸1×：荷車128×96・主人公32×48・柴犬48×48",font=font,fill="#382519")
z=out.resize((384,288),Image.Resampling.NEAREST);proof.paste(z,(25,351),z)
d.text((25,321),"荷車3×（確認用）",font=font,fill="#382519")
for i,color in enumerate(["#182724","#fff3dc"]):
 x=475+i*220;d.rectangle((x,353,x+205,555),fill=color)
 z=out;proof.paste(z,(x+38,405),z)
d.text((475,573),"暗色／明色で透過を確認",font=font,fill="#382519")
d.text((475,604),"右上は保存背景への合成。ゲーム内確認は別。",font=font,fill="#382519")
proof.save(D/"review/board-comparison.png")
manifest={"schema_version":1,"delivery":"merchant_board_v1","asset":{"file":"cart_idle_00.png","canvas_size_px":[128,96],"foot_anchor_px":[64,88],"visible_bbox_exclusive_px":list(out.getbbox()),"logical_pixel_size":1,"action":"idle","direction":"front_right_three_quarter","frame_order":[0],"frame_duration_ms":[None],"duration_mode":"hold_until_state_change","loop":False,"includes_merchant":True,"sha256":hashlib.sha256((D/"cart_idle_00.png").read_bytes()).hexdigest()},"relationship":{"board_replaces":"game/main.gd draw_market_world primitive cart/merchant/crates/hen","ui_cart_unchanged":"../merchant_cart_v2/cart/idle_front_00.png"},"integration":{"native_scale":1,"filter":"nearest","preserve_transparent_margins":True,"white_key":False,"suggested_current_q_foot_offset_px":[20,30],"position_formula":"top_left = q + Vector2(20,30) - Vector2(64,88)","q_logic":"Preserve current arrival/departure q motion and timing; offset is visual only, proposed to retain the old left boundary","remove_old_primitive_decor":True,"do_not_draw_second_merchant":True,"motion":"translation only; no wheel rotation frames delivered"},"quality":{"alpha_values":[0,255],"same_merchant_cart_v2_palette":True,"existing_v2_png_hashes_unchanged":True,"board_capture_verified":False},"sources":"../../art-production/merchant-board-v1/SOURCES.md","prompts":"../../art-production/merchant-board-v1/prompts.json","review_only":["review/board-comparison.png"],"unfinished":["rolling wheel animation","opening/setup animation","runtime integration validation"]}
(D/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding="utf8")
print(json.dumps(manifest["asset"]))

