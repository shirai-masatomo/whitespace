from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import numpy as np,json,hashlib
R=Path(__file__).resolve().parents[2];P=R/"art-production/cart-ui-detail-v1";D=R/"art_delivery/cart_ui_detail_v1"
(D/"review").mkdir(parents=True,exist_ok=True)
raw=Image.open(R/"art-production/merchant-cart-v2/originals/cart.png").convert("RGBA")
a=raw.getchannel("A").point(lambda z:255 if z>=128 else 0);b=a.getbbox();raw=raw.crop(b);raw.putalpha(a.crop(b))
scale=min(716/raw.width,464/raw.height);f=raw.resize((round(raw.width*scale),round(raw.height*scale)),Image.Resampling.BOX)
alpha=f.getchannel("A").point(lambda z:255 if z>=128 else 0);f=f.convert("RGB").quantize(colors=64,dither=Image.Dither.NONE).convert("RGBA");f.putalpha(alpha)
ar=np.array(f);solid=ar[:,:,3]>0
for y,x in zip(*np.where(solid)):
 if any(nx<0 or ny<0 or nx>=f.width or ny>=f.height or not solid[ny,nx] for nx,ny in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]):ar[y,x,:3]=(56,37,25)
f=Image.fromarray(ar);cart=Image.new("RGBA",(768,512));cart.alpha_composite(f,(384-f.width//2,496-f.height));cart.save(D/"cart.png")
old=Image.open(R/"art_delivery/merchant_cart_v2/cart/idle_front_00.png").convert("RGBA")
book=Image.open(R/"art_delivery/ranch_assets_v1/book/closed_00.png").convert("RGBA")
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",18);small=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",15)
def fit(im,rect):
 x,y,w,h=rect;s=min(w/im.width,h/im.height);z=im.resize((round(im.width*s),round(im.height*s)),Image.Resampling.NEAREST)
 return z,(round(x+(w-z.width)/2),round(y+(h-z.height)/2))
def panel(new):
 im=Image.new("RGB",(656,437),"#d6c18d");d=ImageDraw.Draw(im);d.rectangle((1,1,654,435),outline="#624721",width=2)
 d.text((39,10),"1日目の朝",font=font,fill="#3c4b36");d.text((386,57),"牧場の仲間",font=font,fill="#3c4b36")
 for f,rect in [(cart if new else old,(12,92,318,246)),(book,(418,107,176,220))]:
  z,xy=fit(f,rect);im.paste(z,xy,z)
 for x,label in [(42,"朝の市"),(394,"図鑑を開く")]:
  d.rectangle((x,370,x+220,411),fill="#e0cd98",outline="#80653c",width=2);d.text((x+74,380),label,font=small,fill="#3c4b36")
 return im
proof=Image.new("RGB",(1348,523),"#ede1c5");d=ImageDraw.Draw(proof)
d.text((15,10),"旧：実質192×128の荷車",font=font,fill="#382519");d.text((689,10),"新：採用原画の細部を残したUI専用版／本は同一",font=font,fill="#382519")
proof.paste(panel(False),(10,48));proof.paste(panel(True),(682,48))
d.text((14,495),"実装の表示枠を再現した合成比較。ゲーム内検証ではありません。文字は比較用のみ。",font=small,fill="#382519")
proof.save(D/"review/before-after.png");panel(True).save(D/"review/morning-size.png")
proof=Image.new("RGB",(1040,710));d=ImageDraw.Draw(proof)
for i,col in enumerate(["#1e302a","#fff4dc"]):
 d.rectangle((i*520,0,i*520+519,710),fill=col)
 for j,im in enumerate([old,cart]):
  z,xy=fit(im,(i*520+20,20+j*350,480,320));proof.paste(z,xy,z)
proof.save(D/"review/alpha-and-zoom.png")
m=dict(delivery="cart_ui_detail_v1",assets=[dict(file="cart.png",canvas_size_px=[768,512],anchor_px=[384,496],visible_bbox_exclusive_px=list(cart.getbbox()),logical_pixel_size=1,action="static_ui",frame_order=[0],frame_duration_ms=[None],loop=False,sha256=hashlib.sha256((D/"cart.png").read_bytes()).hexdigest(),use="morning and market UI only",source="../../art-production/merchant-cart-v2/originals/cart.png")],filter="nearest",alpha="normal RGBA binary; no white-key shader",contains_merchant=True,source_method="existing adopted raw art processed at finer resolution; no AI regeneration or face redesign",replaces_for_ui="../merchant_cart_v2/cart/idle_front_00.png",keep_unchanged=["board cart128x96","book all assets","keeper/Shiba/merchant actor sprites"],shadow="no external ground shadow",review_only=["review/before-after.png","review/morning-size.png","review/alpha-and-zoom.png"],unfinished=["runtime integration and isolated render verification"])
assert cart.getbbox()[3]==496 and set(np.array(cart)[:,:,3].flat)=={0,255}
(D/"manifest.json").write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding="utf8")
print(m["assets"])

