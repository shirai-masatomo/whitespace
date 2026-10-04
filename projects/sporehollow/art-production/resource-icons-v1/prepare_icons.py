from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageFilter
import numpy as np,json,hashlib
R=Path(__file__).resolve().parents[2];P=R/"art-production/resource-icons-v1";D=R/"art_delivery/resource_icons_v1"
(D/"review").mkdir(parents=True,exist_ok=True)
assets=[];images={}
palettes={
"wood":["382519","674027","865335","a67343","c4945a","deb078","f4d79f","8e8250"],
"soil":["382519","624027","7d4e2a","986135","b17a43","c79759","dfb575"],
"stone":["382519","626657","7e8371","9b9e8b","b5b4a0","d0cbb4","ede2c8"],
"gold":["65451d","98702b","bb8630","d8a343","edbe59","f5d880","fff0bd"]}
for name,colors in palettes.items():
 raw=Image.open(P/f"originals/{name}.png").convert("RGBA");a=raw.getchannel("A").point(lambda z:255 if z>=128 else 0);b=a.getbbox();raw=raw.crop(b);raw.putalpha(a.crop(b))
 for n,folder in [(24,"hud24"),(48,"ui48"),(96,"ui96")]:
  (D/folder).mkdir(exist_ok=True);margin={24:2,48:4,96:8}[n];bound=n-margin*2;s=min(bound/raw.width,bound/raw.height)
  f=raw.resize((round(raw.width*s),round(raw.height*s)),Image.Resampling.BOX);a=f.getchannel("A").point(lambda z:255 if z>=128 else 0)
  cs=[tuple(bytes.fromhex(c)) for c in colors];p=Image.new("P",(1,1));p.putpalette(sum([list(c) for c in cs],[])+list(cs[0])*(256-len(cs)))
  f=f.convert("RGB").quantize(palette=p,dither=Image.Dither.NONE).convert("RGBA");f.putalpha(a)
  # One final-resolution outer contour. Separate pieces remain separate (earth clods etc.).
  ar=np.array(f);m=ar[:,:,3]>0
  for y,x in zip(*np.where(m)):
   if any(nx<0 or ny<0 or nx>=f.width or ny>=f.height or not m[ny,nx] for nx,ny in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]):ar[y,x,:3]=cs[0]
  f=Image.fromarray(ar)
  # Small-size material accents: preserve readable bright endgrain/coin edge, not dither noise.
  if n==24:
   ar=np.array(f)
   for y in range(1,f.height-1):
    for x in range(1,f.width-1):
     if ar[y,x,3] and all(ar[ny,nx,3]>0 for ny,nx in [(y-1,x),(y+1,x),(y,x-1),(y,x+1)]):
      neighbors=[tuple(ar[ny,nx,:3]) for ny,nx in [(y-1,x),(y+1,x),(y,x-1),(y,x+1)]]
      if neighbors.count(neighbors[0])==4:ar[y,x,:3]=neighbors[0]
   f=Image.fromarray(ar)
  im=Image.new("RGBA",(n,n));im.alpha_composite(f,((n-f.width)//2,(n-f.height)//2));fn=f"{folder}/{name}.png";im.save(D/fn);images[name,n]=im
  assert set(np.array(im)[:,:,3].flat)=={0,255}
  assets.append(dict(file=fn,canvas_size_px=[n,n],anchor_px=[n//2,n//2],anchor_use="visual center",resource_id=name,action="static",frame_order=[0],frame_duration_ms=[None],loop=False,use="HUD/small button" if n==24 else "market card and resource UI",visible_bbox_exclusive_px=list(im.getbbox()),sha256=hashlib.sha256((D/fn).read_bytes()).hexdigest(),source=f"../../art-production/resource-icons-v1/originals/{name}.png"))
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",17)
proof=Image.new("RGB",(960,700),"#e7d9b5");dr=ImageDraw.Draw(proof)
dr.text((20,12),"資源アイコン：24／48／96pxを各サイズで整形（原寸表示）",font=font,fill="#382519")
labels={"wood":"木材","soil":"土","stone":"石","gold":"ゴールド"}
for j,name in enumerate(palettes):
 y=60+j*155;dr.text((20,y+36),labels[name],font=font,fill="#382519")
 for x,n in [(160,24),(270,48),(420,96)]:
  im=images[name,n];proof.paste(im,(x+(96-n)//2,y+(96-n)//2),im);dr.text((x+25,y+104),str(n)+"px",font=font,fill="#382519")
 for i,c in enumerate(["#203329","#fff4dd"]):
  x=600+i*165;dr.rectangle((x,y,x+120,y+120),fill=c);im=images[name,96];proof.paste(im,(x+12,y+12),im)
proof.save(D/"review/sizes-and-alpha.png")
m=dict(delivery="resource_icons_v1",assets=assets,resource_ids=list(palettes),generator="image_gen.imagegen",prompt_file="../../art-production/resource-icons-v1/prompts.json",filter="nearest",alpha="normal RGBA binary; pale endgrain and highlights preserved",shadow="no ground shadow",selection="24px HUD;48px standard card;96px close-up card. Pick nearest adequate source size and fit isotropically to existing UI bounds.",integration="These are resource icons, not new resource types or world facilities. Do not apply old primitive-drawing scale2.3 directly to a96px texture.",review_only=["review/sizes-and-alpha.png"],unfinished=["runtime integration and isolated render verification"])
(D/"manifest.json").write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding="utf8")
print("12 resource icons validated")

