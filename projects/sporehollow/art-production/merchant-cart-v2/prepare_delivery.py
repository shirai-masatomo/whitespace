from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import numpy as np,json,hashlib,shutil
R=Path(__file__).resolve().parents[2]
P=R/"art-production/merchant-cart-v2";D=R/"art_delivery/merchant_cart_v2"
for sub in ["merchant","cart","review"]:(D/sub).mkdir(parents=True,exist_ok=True)
hexes=["382519","5e351e","99653f","171d19","784321","ae622b","d88332","eda146","f7bc65","fff0ce","e5c89c","bc9569","c45d4d","f1aba0","8f969d","b4bbc0","666d73","d2d5d3","dadf81","536e52","7d8b62","edb476","b1b28c","e7d9b5","355e60","4e898a","8abcaa","aadeb2","665082","9465a6","c299c6","ae8c44"]
palette=Image.new("P",(1,1));rgb=[tuple(bytes.fromhex(h)) for h in hexes];palette.putpalette(sum([list(c) for c in rgb],[])+list(rgb[0])*(256-len(rgb)))
def native(name,bound):
 im=Image.open(P/"originals"/name).convert("RGBA")
 a=im.getchannel("A").point(lambda x:255 if x>=128 else 0);box=a.getbbox()
 im=im.crop(box);im.putalpha(a.crop(box))
 scale=min(bound[0]/im.width,bound[1]/im.height)
 size=(round(im.width*scale),round(im.height*scale))
 im=im.resize(size,Image.Resampling.BOX)
 alpha=im.getchannel("A").point(lambda x:255 if x>=128 else 0)
 f=im.convert("RGB").quantize(palette=palette,dither=Image.Dither.NONE).convert("RGBA");f.putalpha(alpha)
 return f
def placed(im,size,point):
 out=Image.new("RGBA",size);out.alpha_composite(im,(point[0]-im.width//2,point[1]-im.height));return out
merchant=placed(native("merchant.png",(30,42)),(32,48),(16,44))
# Native-size cleanup: a true1px brown silhouette plus readable brow/eye/smile.
ma=np.asarray(merchant).copy();solid=ma[:,:,3]>0
border=np.zeros_like(solid)
for yy,xx in zip(*np.where(solid)):
    border[yy,xx]=any(nx<0 or ny<0 or nx>=32 or ny>=48 or not solid[ny,nx] for nx,ny in [(xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)])
ma[border,:3]=(56,37,25)
merchant=Image.fromarray(ma)
for xy,col in {
 (18,5):(56,37,25,255),(19,5):(56,37,25,255),(19,6):(56,37,25,255),
 (18,8):(94,53,30,255),(19,8):(255,240,206,255),(20,8):(255,240,206,255),
 (21,8):(94,53,30,255),(19,9):(94,53,30,255),(20,9):(94,53,30,255)
}.items():merchant.putpixel(xy,col)
# Keep connected native pixels and transparent padding. No white-key removal.
cartlogical=placed(native("cart.png",(180,116)),(192,128),(96,124))
cart=cartlogical.resize((768,512),Image.Resampling.NEAREST)
merchant.save(D/"merchant/idle_right_00.png");cart.save(D/"cart/idle_front_00.png")
records=[]
for name,im,point,path,old,unit in [
 ("merchant",merchant,(16,44),"merchant/idle_right_00.png","../ranch_assets_v1/merchant/idle_right_00.png",1),
 ("cart",cart,(384,496),"cart/idle_front_00.png","../ranch_assets_v1/stall/idle_front_00.png",4)]:
 assert im.mode=="RGBA" and im.getbbox()[3]==point[1]
 assert set(im.getchannel("A").getdata())=={0,255}
 assert im.getbbox()[0]>0 and im.getbbox()[2]<im.width
 b=im.getbbox()
 records.append({"asset":name,"file":path,"replaces":old,"canvas_size_px":list(im.size),"foot_anchor_px":list(point),"visible_bbox_exclusive_px":list(b),"visible_body_size_px":[b[2]-b[0],b[3]-b[1]],"logical_pixel_size":unit,"action":"idle","direction":"right_three_quarter" if name=="merchant" else "front_three_quarter","frame_order":[0],"frame_duration_ms":[None],"duration_mode":"hold_until_state_change","loop":False,"sha256":hashlib.sha256((D/path).read_bytes()).hexdigest(),"status":"art_ready_runtime_unverified"})
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",16)
proof=Image.new("RGB",(1000,800),"#e7d9b5");dr=ImageDraw.Draw(proof)
dr.text((18,12),"商人・荷車 v2：実寸比較と予定枠での表示",font=font,fill="#382519")
keeper=Image.open(R/"art_delivery/characters_v1/keeper_idle_right_00.png").convert("RGBA")
dog=Image.open(R/"art_delivery/characters_v1/shiba_idle_right_00.png").convert("RGBA")
oldmerchant=Image.open(R/"art_delivery/ranch_assets_v1/merchant/idle_right_00.png").convert("RGBA")
bg=Image.open(R/"art-production/ranch-assets-v1/references/implementation-native-scale.png").convert("RGB")
proof.paste(bg.crop((200,100,1160,200)),(20,45))
chars=[("主人公（基準）",keeper,(16,44)),("商人 v1",oldmerchant,(16,44)),("商人 v2",merchant,(16,44)),("柴犬C（基準）",dog,(24,44))]
for i,(label,im,anchor) in enumerate(chars):
 x=90+i*230
 proof.paste(im,(x,120-anchor[1]),im);dr.text((x-20,148),label+" 1×",font=font,fill="#382519")
 z=im.resize((im.width*4,im.height*4),Image.Resampling.NEAREST)
 proof.paste(z,(x-24,345-anchor[1]*4),z);dr.text((x-20,365),"4×・足元を固定",font=font,fill="#382519")
oldcart=Image.open(R/"art_delivery/ranch_assets_v1/stall/idle_front_00.png").convert("RGBA")
for i,(label,im) in enumerate([("v1 固定露店",oldcart),("v2 不思議な品を扱う行商の荷車",cart)]):
 x=30+i*500;y=442
 dr.text((x,410),label,font=font,fill="#382519")
 dr.rectangle((x,y,x+400,y+270),fill="#8b956e",outline="#382519",width=2)
 z=im.resize((384,256),Image.Resampling.NEAREST);proof.paste(z,(x+8,y+7),z)
dr.text((30,737),"枠400×270内へ等比配置。画像に商品名・価格は含めない。",font=font,fill="#382519")
dr.text((30,763),"上段は保存済み実画面への合成見本。追加素材のゲーム内動作は未検証。",font=font,fill="#382519")
proof.save(D/"review/comparison.png")
alpha=Image.new("RGB",(900,600));ad=ImageDraw.Draw(alpha)
for i,color in enumerate(["#1a2525","#fff4da"]):
 ad.rectangle((450*i,0,450*(i+1),600),fill=color)
 z=merchant.resize((128,192),Image.Resampling.NEAREST);alpha.paste(z,(i*450+160,30),z)
 z=cart.resize((384,256),Image.Resampling.NEAREST);alpha.paste(z,(i*450+33,295),z)
alpha.save(D/"review/alpha-check.png")
# Validate all existing accepted characters and unrelated ranch PNGs remain untouched.
preserved=[]
sm=json.loads((R/"art_delivery/characters_v1/manifest.json").read_text(encoding="utf8"))
for r in sm["assets"]:
 assert hashlib.sha256((R/"art_delivery/characters_v1"/r["file"]).read_bytes()).hexdigest()==r["delivery_sha256"]
 preserved.append(r["file"])
previous=json.loads((R/"art_delivery/ranch_assets_v1/manifest.json").read_text(encoding="utf8"))
for r in previous["files"]:
 assert hashlib.sha256((R/"art_delivery/ranch_assets_v1"/r["file"]).read_bytes()).hexdigest()==r["sha256"]
manifest={"schema_version":1,"delivery":"merchant_cart_v2","scope":["merchant","stall replacement by travelling cart"],"assets":records,"generator":"image_gen.imagegen","source_directory":"../../art-production/merchant-cart-v2","prompt_file":"../../art-production/merchant-cart-v2/prompts.json","import_rules":{"filter":"nearest","alpha":"normal RGBA; no white-key shader","preserve_transparent_margins":True,"equal_scale":True,"cart_includes_merchant":True,"position_formula":"top_left = target_foot - foot_anchor"},"review_only":["review/comparison.png","review/alpha-check.png"],"quality":{"binary_alpha":True,"native_size_checked":True,"cart_logical_grid":[192,128],"adopted_character_pngs_unchanged":preserved,"previous_ranch_pngs_unchanged":len(previous["files"]),"runtime_verified":False},"unfinished":["merchant walk/rest","cart moving/opening states"]}
(D/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding="utf8")
print(json.dumps(records,ensure_ascii=False))

