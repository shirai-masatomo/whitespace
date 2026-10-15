from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageFilter
import numpy as np,json,hashlib,collections
S=Path(__file__).resolve().parent;P=S.parents[1];A=P/'art_delivery';O=A/'crafting_assets_v1';N=Image.Resampling.NEAREST
F=lambda n:ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',n)
rows=[('cooking_bench','調理台','benches',(44,36)),('carpentry_bench','木工作業台','benches',(44,36)),('sewing_bench','裁縫台','benches',(44,36)),('wood_crate','木箱','placeables',(28,28)),('wood_shelf','木製棚','placeables',(32,41)),('fiber_bundle','植物繊維','items',(24,24)),('fiber_clothes','草繊維の服','items',(26,26)),('roast_mushroom','焼きキノコ','food',(24,21)),('egg_meal','卵料理','food',(24,21)),('roast_meat','焼き肉','food',(24,21)),('stew','肉とキノコの煮込み','food',(24,24))]
palette=['392b24','514033','6c4c34','845c3b','9a7048','ae8354','c19765','d2ac78','e0c494','f1dfb7','faf0d3','544e42','74705f','96917b','b5af96','444940','64705a','889171','a7af88','77503c','9b5c43','ba7854','ce966c','885e35','bb8534','d5a647','edc664','464344','64605b','858179','b3b0a0','d7d1b9']
pal=Image.new('P',(1,1));cs=[tuple(bytes.fromhex(c)) for c in palette];pal.putpalette(sum([list(c) for c in cs],[])+list(cs[0])*(256-len(cs)))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):return Image.open(p).convert('RGBA')
def clean(im):
 a=np.array(im);a[:,:,3]=np.where(a[:,:,3]>=128,255,0);a[a[:,:,3]==0]=0
 return Image.fromarray(a)
def fit(raw,limit):
 # Alpha defines object bounds; opaque cream/white pixels are never chroma-keyed.
 box=raw.getchannel('A').point(lambda p:255 if p>=128 else 0).getbbox();crop=raw.crop(box)
 ratio=min(limit[0]/crop.width,limit[1]/crop.height);size=(max(1,round(crop.width*ratio)),max(1,round(crop.height*ratio)))
 im=clean(crop.resize(size,Image.Resampling.BOX))
 im=im.filter(ImageFilter.UnsharpMask(radius=.6,percent=100,threshold=4))
 # Shared palette removes tiny generated texture variations. No dithering.
 alpha=im.getchannel('A');im=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');im.putalpha(alpha)
 return clean(im),box
assets=[];worlds={};uis={};info=[]
def save(im,rel,anchor,id,kind,extra):
 p=O/rel;p.parent.mkdir(parents=True,exist_ok=True);im=clean(im);im.save(p)
 assets.append(dict(file=rel,id=id,usage=kind,size_px=list(im.size),anchor_px=list(anchor),alpha_bbox=list(im.getbbox()),sha256=sha(p),frame_order=[0],frame_duration_ms=[None],loop=False,shadow_baked=False,**extra))
 return im
for name,jp,folder,limit in rows:
 source_name='fiber_clothes_clean' if name=='fiber_clothes' else name
 raw=load(S/'originals'/f'{source_name}.png');small,box=fit(raw,limit);big=folder in ['benches','placeables'];canvas=(48,48) if big else (32,32);anchor=(24,44) if big else (16,28)
 world=Image.new('RGBA',canvas);xy=(anchor[0]-small.width//2,anchor[1]-small.height);world.alpha_composite(small,xy)
 # Final-size pixel edits: preserve the saw's teeth and opaque yolk/white separation.
 d=ImageDraw.Draw(world)
 if name=='carpentry_bench':
  d.line([(19,29),(26,27),(27,29),(19,29)],fill='#d7d1b9');d.point([(20,30),(22,30),(24,30)],fill='#514033')
 if name=='cooking_bench':
  d.line([(30,28),(34,29)],fill='#d7d1b9');d.point((35,29),fill='#514033')
 if name=='egg_meal':
  d.ellipse((10,20,15,24),fill='#d5a647');d.point([(11,20),(12,20),(11,21)],fill='#edc664')
 id='fiber' if name=='fiber_bundle' else name
 worlds[name]=save(world,f'{folder}/{name}.png',anchor,id,'world',dict(occupied_cells=[1,1] if big else [0,0],placement='cell center + (0,21)' if big else 'item ground foot',body_px=list(small.size),source='../../art-production/crafting-assets-v1/originals/'+source_name+'.png'))
 # UI is re-rasterized from original at a separate size. Keep one recognizable object.
 icon,_=fit(raw,(28,28));ui=Image.new('RGBA',(32,32));ui.alpha_composite(icon,((32-icon.width)//2,(32-icon.height)//2))
 uis[name]=save(ui,f'ui_icons/{name}.png',(16,16),id,'ui',dict(occupied_cells=[0,0],placement='UI rectangle center',body_px=list(icon.size)))
 info.append(dict(name=name,label=jp,source_bbox=box,world_body=small.size))
(O/'preview').mkdir(exist_ok=True)
# Native-size, nearest4x and palette checks on both light and dark backgrounds.
sheet=Image.new('RGBA',(1120,780),'#e3d5af');d=ImageDraw.Draw(sheet)
d.text((18,10),'製作設備・製作品：正式PNG / 11種',font=F(22),fill='#3b352b');d.text((18,43),'左：world 1× / 中：nearest 3× / 右：UI 1×と2×。表示サイズの確認用。',font=F(14),fill='#4e503c')
for i,(name,jp,folder,limit) in enumerate(rows):
 x=16+(i%4)*278;y=82+(i//4)*226
 d.text((x,y),jp,font=F(16),fill='#3b352b');d.text((x,y+23),name,font=F(11),fill='#66614a')
 im=worlds[name];sheet.alpha_composite(im,(x+2,y+71));sheet.alpha_composite(im.resize((im.width*3,im.height*3),N),(x+56,y+50))
 sheet.alpha_composite(uis[name],(x+214,y+58));sheet.alpha_composite(uis[name].resize((64,64),N),(x+200,y+110))
sheet.convert('RGB').save(O/'preview/catalog.png')
alpha=Image.new('RGBA',(792,240),'#252d36');dd=ImageDraw.Draw(alpha);dd.rectangle((0,120,792,239),fill='#f4ead1')
for i,(name,*_) in enumerate(rows):
 for y in [8,128]:
  im=worlds[name];alpha.alpha_composite(im,(i*72+(72-im.width)//2,y+30));dd.text((i*72+5,y),str(i+1),font=F(12),fill='#a78960')
alpha.convert('RGB').save(O/'preview/alpha_dark_light.png')
# Actual existing screenshot as immutable backdrop; these are offline compositing proofs.
base=load(S/'references/01_field.png');out=base.copy();dd=ImageDraw.Draw(out)
positions=[(140,280),(270,280),(400,280),(140,410),(250,410),(360,410),(460,410),(140,580),(240,580),(340,580),(440,580)]
for (name,jp,folder,limit),(x,y) in zip(rows,positions):
 im=worlds[name];anchor=(24,44) if folder in ['benches','placeables'] else (16,28)
 out.alpha_composite(im,(x-anchor[0],y-anchor[1]));dd.text((x-35,y+8),jp,font=F(11),fill='#f6e7bd',stroke_width=1,stroke_fill='#455335')
# Adopted figures at current field draw scale, without redesign.
for rel,foot,anchor,scale in [('characters_v1/keeper_idle_right_00.png',(580,280),(16,44),1.4375),('characters_v1/shiba_idle_right_00.png',(650,280),(24,44),1.25)]:
 im=load(A/rel);im=im.resize((round(im.width*scale),round(im.height*scale)),N);out.alpha_composite(im,(round(foot[0]-anchor[0]*scale),round(foot[1]-anchor[1]*scale)))
label=Image.new('RGBA',(out.width,out.height+64),'#293f32');label.alpha_composite(out,(0,64));ImageDraw.Draw(label).text((16,13),'合成プレビュー／未実装：実ゲーム背景へ正式素材を通常倍率で仮配置',font=F(20),fill='#e9dfbe');label.convert('RGB').save(O/'preview/world_native.png')
# Wood floor staging with identical anchors; screenshot case above provides world context.
floor=load(A/'wood_buildings_v1/floor/wood_00.png');room=Image.new('RGBA',(576,252),'#84945b')
for y in range(6):
 for x in range(12):room.alpha_composite(floor,(x*48,y*42))
for i,(name,*_) in enumerate(rows[:5]):room.alpha_composite(worlds[name],(24+i*106,72))
roomlabel=Image.new('RGBA',(576,302),'#293f32');roomlabel.alpha_composite(room,(0,50));ImageDraw.Draw(roomlabel).text((12,12),'合成プレビュー／未実装：既存の木床、world 1×',font=F(17),fill='#e9dfbe');roomlabel.convert('RGB').save(O/'preview/wood_floor.png');large=roomlabel.resize((1152,604),N);ld=ImageDraw.Draw(large);ld.rectangle((0,0,1151,99),fill='#293f32');ld.text((24,24),'合成プレビュー／未実装：既存木床、nearest 2×',font=F(32),fill='#e9dfbe');large.convert('RGB').save(O/'preview/wood_floor_2x.png')
manifest=dict(schema_version=1,delivery='crafting_assets_v1',implementation_ref='aa3eb39a18b250a3a34f987744eb1b6fd7b24cb9',art_base='adb33aa07da2ec57959e0315963f15003ddcd085',cell_px=[48,42],filter='nearest',format='straight RGBA',assets=assets,details=info,runtime_verified=False)
(O/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(info,ensure_ascii=False))
