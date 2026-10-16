from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageFilter
import numpy as np,json,hashlib,shutil,subprocess
S=Path(__file__).resolve().parent;P=S.parents[1];A=P/'art_delivery';O=A/'bed_assets_v1';N=Image.Resampling.NEAREST
rec=json.loads((S/'generation.json').read_text(encoding='utf-8-sig'));src=S/'originals/bed.png'
if not src.exists():shutil.copy2(rec['path'],src)
raw=Image.open(src).convert('RGBA');box=raw.getchannel('A').point(lambda p:255 if p>=128 else 0).getbbox();raw=raw.crop(box)
colors=['392b24','514033','6c4c34','845c3b','9a7048','ae8354','c19765','d2ac78','e0c494','f1dfb7','faf0d3','544e42','74705f','96917b','b5af96','303b2c','444f38','596748','70805a','88946b','a5b17e','bdc599','d7d1b9','b3b0a0']
pal=Image.new('P',(1,1));cs=[tuple(bytes.fromhex(c)) for c in colors];pal.putpalette(sum([list(c) for c in cs],[])+list(cs[0])*(256-len(cs)))
def fit(h):
 size=(round(raw.width*h/raw.height),h);im=raw.resize(size,Image.Resampling.BOX).filter(ImageFilter.UnsharpMask(.6,100,4));alpha=im.getchannel('A').point(lambda p:255 if p>=128 else 0);im=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');im.putalpha(alpha);return im
world=Image.new('RGBA',(48,56));body=fit(52);world.alpha_composite(body,((48-body.width)//2,56-body.height))
ui=Image.new('RGBA',(64,64));bodyui=fit(56);ui.alpha_composite(bodyui,((64-bodyui.width)//2,4))
assets=[]
for name,im,anchor,usage in [('bed.png',world,[24,56],'world'),('bed_ui.png',ui,[32,32],'ui')]:
 ar=np.array(im);ar[ar[:,:,3]==0]=0;im=Image.fromarray(ar);im.save(O/name)
 assets.append(dict(file=name,usage=usage,size_px=list(im.size),anchor_px=anchor,visible_bbox=list(im.getbbox()),occupied_cells=[1,1] if usage=='world' else [0,0],orientation='head_north_feet_south',frame_order=[0],frame_duration_ms=[None],loop=False,shadow_baked=False,sha256=hashlib.sha256((O/name).read_bytes()).hexdigest()))
F=lambda z:ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',z)
preview=Image.new('RGBA',(720,340),'#e3d5af');d=ImageDraw.Draw(preview);d.text((16,12),'ベッド正式素材：通常倍率とnearest 3倍',font=F(21),fill='#3e382c')
d.text((16,48),'南が足側／人物なし／合成確認・未実装',font=F(14),fill='#4f5540')
for im,x,label in [(world,24,'world 48×56'),(ui,375,'UI 64×64')]:
 d.text((x,83),label,font=F(15),fill='#3e382c');preview.alpha_composite(im,(x,115));preview.alpha_composite(im.resize((im.width*3,im.height*3),N),(x+92,115))
preview.convert('RGB').save(O/'preview/catalog.png')
base=Image.open(P/'art-production/crafting-assets-v1/references/01_field.png').convert('RGBA');field=base.copy()
floor=Image.open(A/'wood_buildings_v1/floor/wood_00.png').convert('RGBA')
for y in range(4):
 for x in range(4):field.alpha_composite(floor,(130+x*48,200+y*42))
# cell top-left (178,242); image top-left (178,228).
field.alpha_composite(world,(178,228));field.alpha_composite(world,(370,228))
ghost=world.copy();ghost.putalpha(ghost.getchannel('A').point(lambda v:v//2));field.alpha_composite(ghost,(466,228))
for file,foot,anchor,scale in [('characters_v1/keeper_idle_right_00.png',(334,284),(16,44),1.4375),('characters_v1/shiba_idle_right_00.png',(437,284),(24,44),1.25)]:
 im=Image.open(A/file).convert('RGBA');im=im.resize((round(im.width*scale),round(im.height*scale)),N);field.alpha_composite(im,(round(foot[0]-anchor[0]*scale),round(foot[1]-anchor[1]*scale)))
out=Image.new('RGBA',(1280,864),'#293e32');out.alpha_composite(field,(0,64));ImageDraw.Draw(out).text((16,15),'合成プレビュー／未実装：木床・草地・半透明ゴースト、通常倍率',font=F(20),fill='#e9dfbe');out.convert('RGB').save(O/'preview/world_native.png')
# Alpha and anchor display only; crosses are not baked into the delivered image.
proof=Image.new('RGBA',(360,140),'#26303a');pd=ImageDraw.Draw(proof);pd.rectangle((180,0,359,139),fill='#f3e6c8')
for x in [38,218]:proof.alpha_composite(world,(x,30));pd.line((x+21,86,x+27,86),fill='#d78842');pd.line((x+24,83,x+24,89),fill='#d78842')
proof.convert('RGB').save(O/'preview/alpha_anchor.png')
checks=[]
def check(name,val):
 checks.append(dict(check=name,passed=bool(val)));assert val,name
for a in assets:
 im=Image.open(O/a['file']);ar=np.array(im);alpha=ar[:,:,3];check(a['file']+' RGBA dimensions',im.mode=='RGBA' and list(im.size)==a['size_px']);check(a['file']+' binary alpha',set(np.unique(alpha))=={0,255});check(a['file']+' invisible rgb clean',np.all(ar[alpha==0]==0));check(a['file']+' palette <=24',len(np.unique(ar[alpha>0,:3],axis=0))<=24);check(a['file']+' pillow opaque',int(((ar[:,:,0]>220)&(ar[:,:,1]>205)&(ar[:,:,2]>160)&(alpha==255)).sum())>20)
check('world south contact reaches anchor',world.getbbox()[3]==56);check('UI centered 4px vertical margin',ui.getbbox()[1]==4 and ui.getbbox()[3]==60);check('UI horizontal center',abs((ui.getbbox()[0]+ui.getbbox()[2])/2-32)<=.5)
manifest=dict(delivery='bed_assets_v1',implementation_ref='e8dac810726d4def56fb6154db5607d0a94caf89',spec='projects/sporehollow/docs/internal/ART_SPEC.md : 家屋・睡眠：ベッド正式素材の依頼',cell_px=[48,42],format='straight RGBA',filter='nearest',assets=assets,world_placement={'target':'cell_top_left+(24,42)','image_top_left':'cell_top_left+(0,-14)'},runtime_verified=False)
(O/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8');(O/'QA.json').write_text(json.dumps({'passed':True,'count':len(checks),'checks':checks,'runtime_verified':False},ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(assets))
