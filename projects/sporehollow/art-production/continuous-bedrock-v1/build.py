from pathlib import Path
from PIL import Image,ImageDraw,ImageChops,ImageFont,ImageFilter
import numpy as np,json,hashlib,math
S=Path(__file__).resolve().parent;P=S.parents[1];A=P/'art_delivery';O=A/'continuous_bedrock_v1'
O.mkdir(exist_ok=True);(O/'review').mkdir(exist_ok=True)
N=Image.Resampling.NEAREST;F=lambda n:ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',n)
assets=[];checks=[];old=A/'biome_connections_v1'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def load(p):return Image.open(p).convert('RGBA')
prior={p.relative_to(A).as_posix():sha(p) for p in A.rglob('*.png') if O not in p.parents}
def check(n,v):
 checks.append({'check':n,'pass':bool(v)})
 assert v,n
def save(im,fn,anchor,role,occ=(0,0),**extra):
 p=O/fn;p.parent.mkdir(parents=True,exist_ok=True)
 a=np.array(im.convert('RGBA'));a[a[:,:,3]==0]=0;im=Image.fromarray(a);im.save(p)
 assets.append(dict(file=fn,size_px=list(im.size),anchor_px=list(anchor),occupied_cells=list(occ),role=role,frame_order=[0],frame_duration_ms=[None],loop=False,shadow_baked=False,sha256=sha(p),**extra))
 return im
def quant(im,pal):
 p=Image.new('P',(1,1));rgb=[tuple(bytes.fromhex(c)) for c in pal];p.putpalette(sum([list(c) for c in rgb],[])+list(rgb[0])*(256-len(rgb)))
 out=im.convert('RGB').quantize(palette=p,dither=Image.Dither.NONE).convert('RGBA');out.putalpha(im.getchannel('A'));return out
rockpal=['515349','626357','737366','817f70','8a8777','918d7d','989383','9e9989','a49f8f','aaa595']
claypal=['33434d','40525c','50616a','64717a','788185','8b8d86','9b9581']
sandpal=['796248','8c7050','9e805b','b09269','c1a477','ceba8c','8b8871']
def periodic(im,band=12):
 # Blend only opposite texture outer borders, never every 48x42 cell.
 a=np.array(im).astype(float);h,w=a.shape[:2]
 for k in range(band):
  t=(1-k/band)**2*.5
  l=a[:,k].copy();r=a[:,w-1-k].copy()
  a[:,k]=l*(1-t)+r*t;a[:,w-1-k]=r*(1-t)+l*t
 for k in range(band):
  t=(1-k/band)**2*.5;u=a[k].copy();v=a[h-1-k].copy()
  a[k]=u*(1-t)+v*t;a[h-1-k]=v*(1-t)+u*t
 return Image.fromarray(np.rint(a).astype('uint8'))
raw=load(S/'originals/bedrock.png')
rock=raw.resize((384,336),Image.Resampling.BOX).filter(ImageFilter.MedianFilter(5)).filter(ImageFilter.GaussianBlur(.75))
# Preserve broad facets and long fissures; suppress high-frequency source dithering.
rock=quant(periodic(rock),rockpal);rock.putalpha(255)
rock=save(rock,'top/atlas.png',(0,0),'opaque seamless 8x8-cell roof surface; sample by WORLD cell position',period_cells=[8,8],sample_origin='world cell left/top; crop48x42 then paste at(0,12) in rock canvas')
fallback=rock.resize((48,42),Image.Resampling.BOX)
ar=np.array(fallback);ar[:,:,:3]=np.rint(ar[:,:,:3]*.5+np.array([145,140,121])*.5).astype('uint8')
fallback=quant(periodic(Image.fromarray(ar),5),rockpal)
roofmask={};bodies={};inner={}
def recolor_faces(im):
 a=np.array(im);lum=a[:,:,:3].mean(2);g=np.clip((lum-65)/125,0,1)
 base=np.array([62,64,55]);end=np.array([143,137,114])
 a[:,:,:3]=(base+(end-base)*g[:,:,None]).astype('uint8');return quant(Image.fromarray(a),rockpal)
for mask in range(16):
 roofmask[mask]=load(old/f'roof/mask_{mask:02}.png').getchannel('A')
 a=Image.new('RGBA',(48,54))
 for face in ['n','w','e','s']:
  p=old/f'exposed/{face}_mask_{mask:02}.png'
  if p.exists():a.alpha_composite(recolor_faces(load(p)))
 roof=Image.new('RGBA',(48,54));roof.alpha_composite(fallback,(0,12));roof.putalpha(roofmask[mask]);a.alpha_composite(roof)
 bodies[mask]=save(a,f'normal/mask_{mask:02}.png',(24,33),'base body with quiet fallback roof; atlas overlay recommended',(1,1),connection_mask=mask)
 white=Image.new('RGBA',(48,54),(255,255,255,0));white.putalpha(roofmask[mask])
 save(white,f'top/mask_{mask:02}.png',(24,33),'data mask: use ALPHA only; never draw white RGB',(0,0),connection_mask=mask)
for co in ['nw','ne','sw','se']:
 inner[co]=save(recolor_faces(load(old/f'inner/concave_{co}.png')),f'inner/concave_{co}.png',(24,33),'concave seam: both cardinals present and diagonal absent',corner=co)
# Iron contains true transparency; transparent pixels are never keyed from colour.
ir=load(S/'originals/iron.png').resize((384,336),Image.Resampling.BOX)
a=np.array(ir);a[:,:,3]=np.where(a[:,:,3]>=128,255,0)
ir=quant(Image.fromarray(a),['353934','464940','58594d','6c6b5b','827d66','66452c','815331','976a3d'])
a=np.array(ir);yy,xx=np.indices(a.shape[:2])
# Bring any ore that crosses an atlas outer boundary to an irregular endpoint; no wrap seam.
margin=np.minimum.reduce([xx,383-xx,yy,335-yy]);threshold=((xx*13+yy*7)%19)
a[margin<np.maximum(2,threshold//3),3]=0
ir=save(Image.fromarray(a),'iron/atlas.png',(0,0),'transparent oxidized ore veins; same global phase as rock roof',period_cells=[8,8],clip_to='top/mask_XX alpha; not a separate rock collision')
# Small optional patches for implementations without the wide vein atlas.
slots=[]
for y in range(8):
 for x in range(8):
  patch=ir.crop((x*48,y*42,(x+1)*48,(y+1)*42));cover=np.count_nonzero(np.array(patch)[:,:,3])
  if 200<cover<850:slots.append((abs(cover-500),x,y,patch))
patches=[]
for i,(_,x,y,patch) in enumerate(sorted(slots,key=lambda v:v[:3])[:3]):
 a=Image.new('RGBA',(48,54));a.alpha_composite(patch,(0,12));arr=np.array(a)
 # Optional cell patches have transparent edge margin, unlike globally connected atlas.
 yy,xx=np.indices(arr.shape[:2]);arr[(xx<3)|(xx>44)|(yy<15)|(yy>50),3]=0
 patches.append(save(Image.fromarray(arr),f'iron/patch_{i:02}.png',(24,33),'optional local ore cluster; use patch OR atlas, clip to roof',source_cell=[x,y]))
# Distinct surface grains, transparent full layer so existing mesh remains visible.
ground={}
for mat,pal in [('clay',claypal),('sand',sandpal)]:
 im=load(S/f'originals/{mat}.png').resize((192,168),Image.Resampling.BOX)
 im=quant(periodic(im.filter(ImageFilter.MedianFilter(3)) if mat=='clay' else im),pal)
 arr=np.array(im);lum=arr[:,:,:3].mean(2)
 # Keep substrate visible while making fissures/grains solid enough to read.
 alpha=np.where(lum<np.percentile(lum,20),170,np.where(lum>np.percentile(lum,85),105,65))
 arr[:,:,3]=alpha
 # Matching alpha along the atlas outer edges is part of seamlessness too.
 arr[:,0]=arr[:,-1]=(arr[:,0].astype(int)+arr[:,-1].astype(int))//2
 arr[0]=arr[-1]=(arr[0].astype(int)+arr[-1].astype(int))//2
 ground[mat]=save(Image.fromarray(arr),f'ground/{mat}/atlas.png',(0,0),'transparent 4x4-cell ground texture; keep existing mesh underneath',period_cells=[4,4])
# Shared inside-cell transition masks. edge_N means N is material side (legacy convention).
yy,xx=np.indices((42,48));fx=np.clip((xx-3)/41,0,1);fy=np.clip((yy-3)/35,0,1)
fields={'full':np.ones((42,48)),'edge_n':1-fy,'edge_e':fx,'edge_s':fy,'edge_w':1-fx,'outer_nw':fx*fy,'outer_ne':(1-fx)*fy,'outer_sw':fx*(1-fy),'outer_se':(1-fx)*(1-fy),'inner_nw':1-(1-fx)*(1-fy),'inner_ne':1-fx*(1-fy),'inner_sw':1-(1-fx)*fy,'inner_se':1-fx*fy}
boundary={}
for key,f in fields.items():
 # Pixel-cluster erosion keeps no rectangular material stripe at its outside edge.
 h=((xx//2)*374761393+(yy//2)*668265263+73).astype('uint64');h=((h^(h>>13))*1274126177)&0xffffffff;noise=((h^(h>>16))&65535)/65535
 alpha=np.where(f>.93,255,np.where((f>.05)&(noise<f),np.rint(255*f),0)).astype('uint8')
 boundary[key]=Image.fromarray(alpha)
 white=Image.new('RGBA',(48,42),(255,255,255,0));white.putalpha(boundary[key])
 save(white,'boundary/'+key+'.png',(24,21),'shared material mask ALPHA only; one inside-cell transition',boundary_kind=key)
 for mat in ['clay','sand']:
  tile=ground[mat].resize((48,42),Image.Resampling.NEAREST)
  # Compatibility files form a seamless microtexture even without atlas sampling.
  tile=periodic(tile,4);tile.putalpha(ImageChops.multiply(tile.getchannel('A'),boundary[key]))
  save(tile,f'ground/{mat}/{key}.png',(24,21),'ready ground overlay; shared boundary pre-applied',boundary_kind=key)
# Clay/rock crevice grime and subdued rubble are fulfilled by the shared boundary and existing gravel.
reuse=[]
for rel,anchor,role in [
 ('biome_environment_v1/rock/ground/gravel.png',(24,21),'gravel at sand→rock exterior'),
 ('biome_environment_v1/rock/ground/rubble.png',(24,21),'mined rubble'),
 ('biome_environment_v2/rock_mined/exposed_bedrock.png',(24,21),'mined exposed ground'),
 ('biome_environment_v1/rock/damage/light.png',(24,33),'light damage clipped to combined rock alpha'),
 ('biome_environment_v1/rock/damage/heavy.png',(24,33),'heavy damage clipped to combined rock alpha'),
 ('biome_environment_v2/rock_node/wall_near_depleted_overlay.png',(24,33),'near-depleted damage clipped to combined rock alpha')]:
 p=A/rel;reuse.append(dict(file='../'+rel,size_px=list(load(p).size),anchor_px=list(anchor),role=role,sha256=sha(p)))
# Sampling and offline compositor also define a minimal executable CPU reference, not game source.
DIRS=[(0,-1,1),(1,0,2),(0,1,4),(-1,0,8)]
CORNERS=[('nw',-1,-1,1,8),('ne',1,-1,1,2),('sw',-1,1,4,8),('se',1,1,4,2)]
def sample(atlas,x,y):
 tx=(x%(atlas.width//48))*48;ty=(y%(atlas.height//42))*42
 return atlas.crop((tx,ty,tx+48,ty+42))
def rock_cell(mask,x,y,ore=False):
 im=bodies[mask].copy();top=Image.new('RGBA',(48,54));top.alpha_composite(sample(rock,x,y),(0,12));top.putalpha(roofmask[mask]);im.alpha_composite(top)
 if ore:
  vein=Image.new('RGBA',(48,54));vein.alpha_composite(sample(ir,x,y),(0,12));vein.putalpha(ImageChops.multiply(vein.getchannel('A'),roofmask[mask]));im.alpha_composite(vein)
 return im
# Proof surfaces use the actual screenshot's clear grass crop (unmodified reference retained).
base=load(S/'references/01_field.png')
# World compositing examples are deliberately not described as screenshots of a running game.
def terrain_scene(cells,ores=set(),removed=set(),geology=False,size=(1280,800),origin=(20,190)):
 out=base.copy()
 ox,oy=origin
 if geology:
  occ=Image.new('L',size);dd=ImageDraw.Draw(occ)
  for x,y in cells:dd.rectangle((ox+x*48,oy+y*42,ox+(x+1)*48-1,oy+(y+1)*42-1),fill=255)
  near=np.array(occ.filter(ImageFilter.GaussianBlur(38))).astype(float)/255
  outside=np.array(occ)==0
  gy,gx=np.indices((size[1],size[0]))
  # Smooth illustrative substrate tint mimics the implementation's vertex colours,
  # not a replacement terrain-generation algorithm.
  patch=np.clip(.55+.40*np.sin(gx/137+gy/91),0,1)
  clayw=np.clip(near*2.8,0,1)*patch*outside
  sandw=np.clip(near*4,0,1)*(1-clayw)*outside
  # Preserve foreground actors already present in the reference screenshot.
  protect=np.clip((525-gx)/25,0,1);clayw*=protect;sandw*=protect
  for mat,weight,color in [('sand',sandw,(164,133,89)),('clay',clayw,(69,88,101))]:
   tint=Image.new('RGBA',size,(*color,0));tint.putalpha(Image.fromarray(np.rint(weight*165).astype('uint8')));out.alpha_composite(tint)
   surface=Image.new('RGBA',size)
   for y in range(-2,13):
    for x in range(-2,13):surface.alpha_composite(sample(ground[mat],x,y),(ox+x*48,oy+y*42))
   a=np.array(surface);a[:,:,3]=np.rint(a[:,:,3]*weight).astype('uint8');out.alpha_composite(Image.fromarray(a))
  for y in range(-1,12):
   for x in range(-1,12):
    if (x,y) in cells:continue
    nearby=min((abs(x-a)+abs(y-b) for a,b in cells),default=10)
    if nearby==1 and (x+2*y)%5==0:
     out.alpha_composite(load(A/'biome_environment_v1/rock/ground/gravel.png'),(ox+x*48,oy+y*42))
 for x,y in removed:
  for n in ['biome_environment_v2/rock_mined/exposed_bedrock.png','biome_environment_v1/rock/ground/rubble.png']:
   out.alpha_composite(load(A/n),(ox+x*48,oy+y*42))
 for x,y in sorted(cells,key=lambda p:(p[1],p[0])):
  m=sum(b for dx,dy,b in DIRS if (x+dx,y+dy) in cells)
  im=rock_cell(m,x,y,(x,y) in ores)
  out.alpha_composite(im,(ox+x*48,oy+y*42-12))
  for co,dx,dy,b1,b2 in CORNERS:
   if m&b1 and m&b2 and (x+dx,y+dy) not in cells:out.alpha_composite(inner[co],(ox+x*48,oy+y*42-12))
 # Existing reference actors, unchanged body sizes.
 for rel,foot,anchor,scale in [
 ('characters_v1/keeper_idle_right_00.png',(ox+490,oy+451),(16,44),1.4375),
 ('characters_v1/shiba_idle_right_00.png',(ox+550,oy+451),(24,44),1.25)]:
  im=load(A/rel);im=im.resize((round(im.width*scale),round(im.height*scale)),N);out.alpha_composite(im,(round(foot[0]-anchor[0]*scale),round(foot[1]-anchor[1]*scale)))
 return out
def labelled(im,title,path,subtitle='合成プレビュー／未実装。セル48×42、通常倍率1×。'):
 out=Image.new('RGBA',(im.width,im.height+74),'#293e32');out.alpha_composite(im,(0,74))
 d=ImageDraw.Draw(out);d.text((14,8),title,font=F(21),fill='#ecdfbb');d.text((14,42),subtitle,font=F(13),fill='#c5d4b2')
 if not path.startswith('_'):out.convert('RGB').save(O/'review'/path)
 return out
solid={(x,y) for x in range(10) for y in range(10)}
irregular=solid-{(0,0),(1,0),(0,1),(9,0),(9,1),(8,0),(0,8),(0,9),(1,9),(9,9),(8,9),(9,8),(9,4),(8,4),(9,5)}
ores={(x,y) for x,y in irregular if 2<=x<=7 and 2<=y<=7}
labelled(terrain_scene(solid),'01 連続岩盤 10×10マス（100セル）','01_mass_10x10.png')
labelled(terrain_scene(irregular),'02 外縁・突出・切欠き・草地','02_edges_grass.png')
labelled(terrain_scene(irregular,geology=True),'03 岩盤と青灰粘土・茶砂・砕石','03_clay_sand.png')
labelled(terrain_scene(irregular,ores,geology=True),'04 通常岩盤内の鉄鉱脈（崖で分断しない）','04_iron.png')
# Five consecutive bands, same material direction convention, no ore in ground.
bands=Image.new('RGBA',(768,360),'#859257')
for yy in range(8):
 for xx in range(16):
  if xx<3:continue
  mat='sand' if xx<8 else 'clay'
  if xx==8:
   under=Image.new('RGBA',(48,42),(164,133,89,166));bands.alpha_composite(under,(xx*48,yy*42));bands.alpha_composite(sample(ground['sand'],xx,yy),(xx*48,yy*42))
  tile=sample(ground[mat],xx,yy);mask='edge_e' if xx in [3,8] else 'full'
  tint=Image.new('RGBA',(48,42),(164,133,89,0) if mat=='sand' else (69,88,101,0));tint.putalpha(boundary[mask].point(lambda p:int(p*.65)));bands.alpha_composite(tint,(xx*48,yy*42));tile.putalpha(ImageChops.multiply(tile.getchannel('A'),boundary[mask]));bands.alpha_composite(tile,(xx*48,yy*42))
  if xx>=12:bands.alpha_composite(load(A/'biome_environment_v1/rock/ground/gravel.png'),(xx*48,yy*42))
for y in range(1,7):
 for x in range(13,16):
  m=sum(b for dx,dy,b in DIRS if 13<=x+dx<16 and 1<=y+dy<7);bands.alpha_composite(rock_cell(m,x,y),(x*48,y*42-12))
labelled(bands,'05 土/草 → 茶砂 → 粘土 → 砕石・岩盤','05_ground_transition.png')
# Three actual 1-cell removals with cardinal and diagonal redraw.
sheet=Image.new('RGBA',(2560,1748),'#293e32')
for i,(title,removed) in enumerate([('採掘前',set()),('中央1セル採掘',{(5,5)}),('北端1セル採掘',{(4,0)}),('外角1セル採掘',{(0,0)})]):
 sc=terrain_scene(solid-removed,ores,removed,True)
 lab=labelled(sc,title,'_case_'+str(i)+'.png')
 sheet.alpha_composite(lab,(i%2*1280,i//2*874))
sheet.convert('RGB').save(O/'review/mining_cases.png')
# Direct previous/new comparison, same background/positions, normals replayed with old source.
new=terrain_scene(solid)
oldscene=new.copy();background=terrain_scene(set())
oldscene=background
for x,y in sorted(solid,key=lambda p:(p[1],p[0])):
 m=sum(b for dx,dy,b in DIRS if (x+dx,y+dy) in solid)
 oldscene.alpha_composite(load(old/f'normal/mask_{m:02}.png'),(20+x*48,190+y*42-12))
compare=Image.new('RGBA',(2560,874),'#293e32')
compare.alpha_composite(labelled(oldscene,'既存：同じ上面の繰り返し','_old.png'),(0,0));compare.alpha_composite(labelled(new,'今回：広域岩肌＋灰褐色の接続','_new.png'),(1280,0))
compare.convert('RGB').save(O/'review/before_after.png')
# Catalogue is proof only, not a sheet to be cut into game assets.
catalog=Image.new('RGBA',(1120,660),'#6d8453');d=ImageDraw.Draw(catalog)
for m in range(16):
 x=12+(m%8)*138;y=35+(m//8)*154
 z=rock_cell(m,m%8,m//8).resize((96,108),N);catalog.alpha_composite(z,(x,y));d.text((x,y-22),f'mask {m:02}',font=F(14),fill='white')
for i,mat in enumerate(['sand','clay']):
 z=load(O/f'ground/{mat}/full.png').resize((192,168),N);catalog.alpha_composite(z,(20+i*230,390));d.text((20+i*230,365),mat+' / nearest4x',font=F(15),fill='white')
z=ir.resize((384,336),N);catalog.alpha_composite(z,(700,310));d.text((700,286),'iron / native atlas',font=F(15),fill='white')
catalog.convert('RGB').save(O/'review/catalog.png')
# Invariants: no per-cell white borders, complete interior coverage, unchanged prior images.
for r in assets:
 im=load(O/r['file']);check(r['file']+' RGBA-size-hash',im.size==tuple(r['size_px']) and sha(O/r['file'])==r['sha256'])
check('mask15 roof fully opaque42rows',np.all(np.array(roofmask[15])[12:54]==255))
for m in range(16):
 for dx,dy,b,opp in [(1,0,2,8),(0,1,4,1)]:
  for n in range(16):
   if m&b and n&opp:
    aa=np.array(bodies[m])[:,:,3];bb=np.array(bodies[n])[:,:,3]
    ok=np.all(aa[17:38,47]==255) and np.all(bb[17:38,0]==255) if dx else np.all(aa[53,8:40]==255) and np.all(bb[12,8:40]==255)
    check(f'ports {m}/{n}/{b}',ok)
# Global phase continuity: composing 10x10 complete roofs equals exact wrapped atlas, byte-for-byte.
full=Image.new('RGBA',(480,420))
for y in range(10):
 for x in range(10):full.alpha_composite(rock_cell(15,x,y).crop((0,12,48,54)),(x*48,y*42))
ref=Image.new('RGBA',(480,420))
for y in range(0,420,336):
 for x in range(0,480,384):ref.alpha_composite(rock,(x,y))
check('100 interior cells exactly equal global atlas with no cell lines',full.tobytes()==ref.tobytes())
for name,im in [('rock',rock),('clay',ground['clay']),('sand',ground['sand'])]:
 a=np.array(im)
 check(name+' left/right periodic RGBA',np.array_equal(a[:,0],a[:,-1]))
 check(name+' top/bottom periodic RGBA',np.array_equal(a[0],a[-1]))
check('prior adopted PNGs unchanged',all(sha(A/f)==h for f,h in prior.items()))
# Grid-boundary discontinuity against ordinary interior pixel differences.
ar=np.array(full).astype(float)[:,:,:3];dx=np.mean(abs(ar[:,1:]-ar[:,:-1]),axis=2);dy=np.mean(abs(ar[1:]-ar[:-1]),axis=2)
grid_x=float(np.mean(dx[:,47::48]));other_x=float(np.mean(dx));grid_y=float(np.mean(dy[41::42]));other_y=float(np.mean(dy))
check('cell-edge texture contrast not amplified',grid_x<other_x*1.8+0.5 and grid_y<other_y*1.8+0.5)
manifest=dict(schema_version=1,delivery='continuous_bedrock_v1',source_art_commit='fc9e3646afe8708e5bc06756dcaf0448e77a93b6',source_implementation_commit='7708cc34fb5da0adbc0e569fed8fcac2649d8c19',cell_px=[48,42],rock_canvas_px=[48,54],rock_anchor_px=[24,33],ground_anchor_px=[24,21],mask_bits=dict(N=1,E=2,S=4,W=8),assets=assets,reuse=reuse,runtime_verified=False,filter='nearest',alpha='straight RGBA',top_atlas=dict(path='top/atlas.png',size_px=[384,336],period_cells=[8,8],phase='positive_mod(world_cell.x,8),positive_mod(world_cell.y,8)',source_rect='(phase_x*48,phase_y*42,48,42)',paste_px=[0,12],clip='top/mask_XX alpha',draw_order=['normal body','sampled top clipped to roof','iron clipped to roof','concave corner','existing damage clipped to combined alpha']),ground=dict(period_cells=[4,4],paste_px=[0,0],mode='existing vertex color first; alpha texture next; boundary alpha once',boundary_convention='edge_n has material N and outside S; outer_nw outside NW; inner_nw only NW missing',preferred='sample ground/{material}/atlas.png by world phase; multiply ALPHA with boundary/{key}.png ALPHA',fallback='ground/{material}/{key}.png precomposed'),iron=dict(primary='iron/atlas.png',period_cells=[8,8],paste_px=[0,12],clip='roof alpha',alternate_patches=[a['file'] for a in assets if a['file'].startswith('iron/patch')],selection='atlas OR stable one patch, never both. Ore cells share all rock neighbors for geometry. Optional edge-alpha fade into non-ore neighbors; never alter rock silhouette.'),unchanged=['large isolated rock mountain','existing rock collision and resource amounts','all previously adopted images'],unfinished=['runtime integration, EXE build, isolated game rendering are implementation responsibility'])
(O/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
(O/'QA.json').write_text(json.dumps(dict(count=len(checks),passed=all(x['pass'] for x in checks),checks=checks,prior_png_count=len(prior),cell_edge_contrast=dict(grid_x=grid_x,all_x=other_x,grid_y=grid_y,all_y=other_y),actual_game_test=False),ensure_ascii=False,indent=2),encoding='utf8')
(S/'prior_hashes.json').write_text(json.dumps(prior,indent=2),encoding='utf8')
print(json.dumps(dict(assets=len(assets),reuse=len(reuse),checks=len(checks),contrast=[grid_x,other_x,grid_y,other_y])))
