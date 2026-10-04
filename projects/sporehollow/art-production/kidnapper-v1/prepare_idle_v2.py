from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
import numpy as np,json,hashlib
R=Path(__file__).resolve().parents[2];P=R/"art-production/kidnapper-v1";D=R/"art_delivery/kidnapper_preview_v2";(D/"review").mkdir(parents=True,exist_ok=True)
raw=Image.open(P/"originals/idle-v2.png").convert("RGBA")
a=raw.getchannel("A").point(lambda v:255 if v>=128 else 0);b=a.getbbox();raw=raw.crop(b);raw.putalpha(a.crop(b))
s=min(28/raw.width,42/raw.height);raw=raw.resize((round(raw.width*s),round(raw.height*s)),Image.Resampling.BOX)
colors=["382519","292729","454453","646170","87768e","72566c","503d50","9b849a","d2b396","edb476","fff0ce","784321","99653f"]
rgb=[tuple(bytes.fromhex(c)) for c in colors];p=Image.new("P",(1,1));p.putpalette(sum([list(c) for c in rgb],[])+list(rgb[0])*(256-len(rgb)))
a=raw.getchannel("A").point(lambda v:255 if v>=128 else 0)
f=raw.convert("RGB").quantize(palette=p,dither=Image.Dither.NONE).convert("RGBA");f.putalpha(a)
out=Image.new("RGBA",(32,48));out.alpha_composite(f,(16-f.width//2,44-f.height))
v=np.asarray(out).copy();solid=v[:,:,3]>0
for y,x in zip(*np.where(solid)):
 if any(nx<0 or ny<0 or nx>=32 or ny>=48 or not solid[ny,nx] for nx,ny in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]):v[y,x,:3]=(56,37,25)
out=Image.fromarray(v);out.save(D/"idle_right_00.png")
left=Image.new("RGBA",(32,48));left.alpha_composite(ImageOps.mirror(out),(1,0));left.save(D/"idle_left_00.png")
assets=[]
for name,im in [("right",out),("left",left)]:
 assert im.size==(32,48) and im.getbbox()[3]==44 and set(im.getchannel("A").getdata())=={0,255}
 fn=f"idle_{name}_00.png";assets.append({"file":fn,"canvas_size_px":[32,48],"foot_anchor_px":[16,44],"visible_bbox_exclusive_px":list(im.getbbox()),"action":"idle","direction":name,"frame_order":[0],"frame_duration_ms":[None],"duration_mode":"hold_until_state_change","loop":False,"sha256":hashlib.sha256((D/fn).read_bytes()).hexdigest()})
keeper=Image.open(R/"art_delivery/characters_v1/keeper_idle_right_00.png").convert("RGBA")
dog=Image.open(R/"art_delivery/characters_v1/shiba_idle_right_00.png").convert("RGBA")
merchant=Image.open(R/"art_delivery/merchant_cart_v2/merchant/idle_right_00.png").convert("RGBA")
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",16)
proof=Image.new("RGB",(980,650),"#e7d9b5");dr=ImageDraw.Draw(proof)
dr.text((18,12),"既存の誘拐者Lv1：修正版：コソ泥感・悪者感（新しい敵種ではありません）",font=font,fill="#382519")
bg=Image.open(R/"art-production/ranch-assets-v1/references/implementation-native-scale.png").convert("RGB")
proof.paste(bg.crop((220,90,1160,210)),(20,48))
actors=[("主人公v1",keeper,(16,44)),("柴犬C",dog,(24,44)),("商人v2",merchant,(16,44)),("誘拐者 右",out,(16,44)),("誘拐者 左",left,(16,44))]
for i,(label,im,anchor) in enumerate(actors):
 x=58+i*186
 proof.paste(im,(x,132-anchor[1]),im);dr.text((x-5,177),label+" 1×",font=font,fill="#382519")
 z=im.resize((im.width*4,im.height*4),Image.Resampling.NEAREST);proof.paste(z,(x-12,410-anchor[1]*4),z)
 dr.text((x-5,428),"4×／足元共通",font=font,fill="#382519")
for i,col in enumerate(["#182724","#fff3dc"]):
 x=40+i*170;dr.rectangle((x,494,x+150,619),fill=col);z=out.resize((64,96),Image.Resampling.NEAREST);proof.paste(z,(x+40,510),z)
dr.text((405,502),"目深な帽子・鋭い目・曲げた膝と手で忍び込む姿。",font=font,fill="#382519")
dr.text((405,534),"新しい武器や能力、HP0の死亡・死体は追加しません。",font=font,fill="#382519")
dr.text((405,566),"静止の方向確認用。歩行・攻撃・運搬は未制作です。",font=font,fill="#382519")
proof.save(D/"review/identity-size.png")
m={"schema_version":1,"delivery":"kidnapper_preview_v2","status":"direction_review_pending","role":"existing kidnapper Lv1 in ENEMIES.md","assets":assets,"shadow":"No ground shadow baked; game may draw one external shadow.","carry_plan":"After direction confirmation: enemy rear layer + unchanged keeper sprite layer + enemy holding-arm front layer; per-frame shoulder/pivot coordinates. No keeper burned into enemy.","review_only":["review/identity-size.png"],"unfinished":["walk","search","discovery reaction","attack","wall/door attack","hit reaction","carry","retreat","user direction confirmation","runtime integration"],"rules":"HP0 means retreat; no death frames. No stat, speed or damage timing changes."}
(D/"manifest.json").write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding="utf8")
print(assets)


