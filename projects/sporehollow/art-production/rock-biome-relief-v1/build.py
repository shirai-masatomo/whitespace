from pathlib import Path
from PIL import Image,ImageDraw,ImageChops,ImageFont
import numpy as np, hashlib,json,math
S=Path(__file__).resolve().parent; P=S.parents[1]; A=P/'art_delivery'; D=A/'rock_biome_relief_v1'; D.mkdir(exist_ok=True)
V=A/'biome_environment_v1'; V2=A/'biome_environment_v2'; OLD=A/'biome_connections_v1'
def im(p):return Image.open(p).convert('RGBA')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
prior={p.relative_to(A).as_posix():sha(p) for p in A.rglob('*.png') if D not in p.parents}
STONE=['#505247','#626252','#74705c','#85806b','#95907b','#a8a18a','#b9b198','#c9bfa5','#d8ceb4','#e1d6bc','#9c875f']
WOOD=['#3e3024','#53412c','#6a5035','#805f3b','#96754b','#af8f5e','#c6a576','#d8bd90','#e5cda3','#53633d','#6b7c44','#87905a']
def quant(a,pal=STONE):
 ar=np.array(a); cols=np.array([tuple(bytes.fromhex(c[1:])) for c in pal],dtype=np.int32);ix=((ar[:,:,:3].astype(np.int32)[:,:,None,:]-cols)**2).sum(3).argmin(2);ar[:,:,:3]=cols[ix];ar[:,:,3]=np.where(ar[:,:,3]>=180,255,0);ar[ar[:,:,3]==0]=0;return Image.fromarray(ar)
def swatch(src,box,size):
 o=src.crop(box);tw,th=size;r=tw/th
 if o.width/o.height>r:
  w=round(o.height*r);x=(o.width-w)//2;o=o.crop((x,0,x+w,o.height))
 else:
  h=round(o.width/r);y=(o.height-h)//2;o=o.crop((0,y,o.width,y+h))
 return quant(o.resize(size,Image.Resampling.BOX))
master=im(S/'originals/rock_material_atlas.png')
# Interior opaque material only; gutters and generated edge fringe never enter game tiles.
tops=[swatch(master,b,(48,42)) for b in [(86,90,470,426),(240,125,624,461),(718,90,1102,426),(861,160,1245,496)]]
fronts=[swatch(master,b,(48,24)) for b in [(80,610,615,1065),(716,610,1253,1065)]]
for a in tops+fronts:a.putalpha(Image.new('L',a.size,255))
# Match EVERY variant at tile ports, while preserving broad fracture planes within the tile.
canonical=np.array(tops[0]);edge=canonical.copy()
for k in range(1):
 col=((canonical[:,k,:3].astype(int)+canonical[:,-1-k,:3])/2).astype('uint8');edge[:,k,:3]=col;edge[:,-1-k,:3]=col
for k in range(1):
 row=((edge[k,:,:3].astype(int)+edge[-1-k,:,:3])/2).astype('uint8');edge[k,:,:3]=row;edge[-1-k,:,:3]=row
for i,a in enumerate(tops):
 ar=np.array(a)
 for k in range(1):ar[:,k]=edge[:,k];ar[:,-1-k]=edge[:,-1-k];ar[k]=edge[k];ar[-1-k]=edge[-1-k]
 tops[i]=quant(Image.fromarray(ar));tops[i].save(S/f'native/top_{i}.png')
for i,a in enumerate(fronts):
 ar=np.array(a)
 # Shared lateral cliff ports: connected front strips have no border/cap.
 for k in range(2):ar[:,k]=np.array(fronts[0])[:,k];ar[:,-1-k]=ar[:,k]
 fronts[i]=Image.fromarray(ar);fronts[i].save(S/f'native/front_{i}.png')
assets=[];reuse=[];normals={};roofs={};parts={};checks=[]
def check(n,v):checks.append({'check':n,'passed':bool(v)});assert v,n
def save(a,f,usage,anchor=(24,45),layer='rock',occ=(1,1),**kw):
 ar=np.array(a);ar[ar[:,:,3]==0]=0;a=Image.fromarray(ar);p=D/f;p.parent.mkdir(parents=True,exist_ok=True);a.save(p)
 assets.append(dict(file=f,size_px=list(a.size),anchor_px=list(anchor),occupied_cells=list(occ),layer=layer,usage=usage,frame_order=[0],duration_ms=None,loop=False,shadow_baked=False,sha256=sha(p),**kw));return a
def ref(f,role,anchor,occ=(0,0),**kw):
 reuse.append(dict(file='../'+f.relative_to(A).as_posix(),role=role,size_px=list(im(f).size),anchor_px=list(anchor),occupied_cells=list(occ),sha256=sha(f),duration_ms=None,loop=False,**kw))
for v in range(len(tops)):
 save(tops[v],f'rock_biome/top/interior_{v}.png','Raised upper rock material; never a walkable floor by filename alone.',anchor=(24,21),layer='top_material',occ=(0,0))
 if v<2:save(fronts[v%2],f'rock_biome/cliff/front_strip_{v}.png','24px tall cliff texture swatch; use mask parts for actual walls.',anchor=(24,24),layer='cliff_material',occ=(0,0))
 for m in range(16):
  n,e,s,w=[bool(m&b) for b in (1,2,4,8)];x0=0 if w else 5;x1=47 if e else 42;y0=12 if n else 16;y1=53 if s else 38
  tl=0 if n or w else 3;tr=0 if n or e else 3;bl=0 if s or w else 3;br=0 if s or e else 3
  north=[(x,y0+(0 if n else [0,0,1,0,-1,0][x//8%6])) for x in range(x0+tl,x1-tr+1)]
  east=[(x1+(0 if e else [0,-1,0,0,1,0][y//7%6]),y) for y in range(y0+tr,y1-br+1)]
  south=[(x,y1+(0 if s else [0,1,0,-1,0,0][x//8%6])) for x in range(x1-br,x0+bl-1,-1)]
  west=[(x0+(0 if w else [0,1,0,0,-1,0][y//7%6]),y) for y in range(y1-bl,y0+tl-1,-1)]
  rm=Image.new('L',(48,66));ImageDraw.Draw(rm).polygon(north+east+south+west,fill=255)
  roof=Image.new('RGBA',(48,66));roof.paste(tops[v],(0,12));roof.putalpha(rm);dr=ImageDraw.Draw(roof)
  # Broken highlight on EXPOSED edges only; no internal frame.
  if not n:dr.line([(10,16),(18,16),(20,17)],fill=STONE[8]);dr.line([(29,16),(35,16)],fill=STONE[7])
  if not w:dr.line([(5,23),(5,29)],fill=STONE[8])
  if not s:dr.line([(9,38),(17,38),(19,37)],fill=STONE[8]);dr.line([(29,37),(34,38),(39,38)],fill=STONE[7])
  roof.putalpha(rm)
  combined=Image.new('RGBA',(48,66));parts[v,m]={}
  for direction,present in [('n',n),('w',w),('e',e),('s',s)]:
   if present:continue
   face=Image.new('RGBA',(48,66));dd=ImageDraw.Draw(face)
   if direction=='n':dd.polygon([(x0+tl,14),(x1-tr,14),(x1,20),(x0,20)],fill=STONE[4])
   elif direction in ('w','e'):
    left=direction=='w';lo,hi=(2,6) if left else (41,45);ya=y0+(tl if left else tr);yb=65 if s else 62
    dd.polygon([(lo+1,ya),(hi-1,ya),(hi,yb-2),(hi-1,yb),(lo,yb-1),(lo,ya+4)],fill=STONE[3] if left else STONE[1])
    dd.line([(lo+1,ya+3),(lo+1,yb-3)],fill=STONE[5] if left else STONE[2])
    for yy in range(ya+6,yb-3,9):dd.line([(lo,yy),(hi,yy+2)],fill=STONE[2] if left else STONE[0])
   else:
    face=Image.new('RGBA',(48,66),STONE[0]);face.paste(fronts[v%2],(0,39));fm=Image.new('L',(48,66));ImageDraw.Draw(fm).polygon([(x0,38),(x1,38),(x1,60)]+[(x,62+[0,1,0,1,0,0][x//8%6]) for x in range(x1-1,x0,-1)]+[(x0,60)],fill=255);face.putalpha(fm)
    # Ensure fresh vertical fractures span the face at native resolution.
    dd=ImageDraw.Draw(face)
    for xx in ([12,31] if v==0 else [19,38]):
     dd.line([(xx,40),(xx-1,46),(xx+1,53),(xx,60)],fill=STONE[1]);dd.line([(xx+1,41),(xx,46),(xx+2,51)],fill=STONE[5])
    face.putalpha(fm)
   parts[v,m][direction]=save(face,f'rock_biome/cliff/v{v}/{direction}_mask_{m:02}.png','Only exposed face; neighbor absent in named direction. Draw BEFORE roof.',layer='cliff',connection_mask=m,variant=v,direction=direction)
   combined.alpha_composite(face)
  combined.alpha_composite(roof)
  roofs[v,m]=save(roof,f'rock_biome/top/v{v}/mask_{m:02}.png','Upper plane, paired with cliff parts; combined alternative in mineable.',layer='top',connection_mask=m,variant=v)
  normals[v,m]=save(combined,f'rock_biome/mineable/v{v}/mask_{m:02}.png','Combined one-cell connected rock. Use combined OR separate parts.',connection_mask=m,variant=v,front_height_px=24,placement='cell_center - (24,45)')
for co in ['nw','ne','sw','se']:
 o=Image.new('RGBA',(48,66));d=ImageDraw.Draw(o);x=0 if co[1]=='w' else 47;y=12 if co[0]=='n' else 53;dx=1 if x==0 else -1;dy=1 if y==12 else -1
 d.polygon([(x,y),(x+dx*6,y),(x+dx*3,y+dy*3),(x,y+dy*7)],fill=STONE[2]);d.line([(x+dx*6,y),(x+dx*3,y+dy*3),(x,y+dy*7)],fill=STONE[6])
 save(o,f'rock_biome/cliff/inner_{co}.png','Concave cut: both cardinal neighbors exist, diagonal neighbor missing.',layer='inner_overlay',corner=co)
# Damage overlays: internal scars + visibly chipped exposed strata, no collision or threshold policy.
cracks=[[(12,21),(17,25),(15,30),(22,33)],[(32,18),(27,24),(30,30),(25,36)],[(8,43),(14,47),(11,53),(17,59)]]
for stage in range(1,4):
 o=Image.new('RGBA',(48,66));d=ImageDraw.Draw(o)
 for j,path in enumerate(cracks[:stage]):
  d.line(path,fill=STONE[1],width=1 if stage==1 else 2)
  d.line([(x+1,y) for x,y in path],fill=STONE[7],width=1)
  x,y=path[-1];d.polygon([(x-3,y),(x+2,y-2),(x+4,y+2),(x,y+4)],fill=STONE[3]);d.line([(x-2,y),(x+2,y-1),(x+3,y+1)],fill=STONE[8])
 if stage>=2:d.line([(17,25),(24,23),(27,24)],fill=STONE[1])
 if stage==3:
  d.polygon([(28,41),(38,40),(35,47),(29,50),(25,46)],fill=STONE[1]);d.polygon([(28,41),(37,40),(33,43),(27,44)],fill=STONE[8])
 # Fresh chipped facets contrast with the weathered intact surface even at native size.
 d.polygon([(16,27),(22,24),(28,28),(24,33),(18,32)],fill=STONE[8])
 d.line([(16,27),(18,32),(24,33),(28,28)],fill=STONE[1],width=1)
 if stage>=2:
  d.polygon([(18,43),(26,40),(31,44),(28,53),(19,54),(16,49)],fill=STONE[1])
  d.polygon([(18,43),(26,40),(31,44),(24,46),(18,46)],fill=STONE[8])
 if stage==3:
  d.polygon([(11,39),(21,37),(28,41),(32,48),(27,59),(15,58),(10,49)],fill=STONE[1])
  d.polygon([(11,39),(21,37),(28,41),(20,44),(13,43)],fill=STONE[8])
  d.polygon([(15,52),(22,49),(26,54),(24,58),(16,57)],fill=STONE[5])
 save(o,f'rock_biome/mined_states/damage_{stage}.png','Clip by selected combined rock alpha. Overlay scars/chips; retain connection until depleted.',layer='damage',visual_state=['light','heavy','near_depleted'][stage-1])
# Small generated-rock fragments. Drawn from source texture masks, not foreign artwork.
def chip(w,h,variant=0):
 o=fronts[variant].crop((8,4,8+w,4+h));mask=Image.new('L',(w,h));dd=ImageDraw.Draw(mask);dd.polygon([(0,h//2),(w//3,0),(w-2,1),(w-1,h-2),(w//2,h-1),(1,h-2)],fill=255);o.putalpha(mask);ImageDraw.Draw(o).line([(0,h//2),(w//3,0),(w-2,1)],fill=STONE[8]);return o
for name,positions in [('pebbles',[(12,19,3,3),(25,15,4,3),(33,25,3,3)]),('crushed_stone',[(15,19,5,4),(21,22,6,4),(28,17,5,5),(34,24,3,3)]),('rock_shards',[(15,19,8,5),(28,23,6,6)]),('gravel',[(8,14,3,2),(17,24,3,2),(24,14,3,3),(35,19,4,3),(31,28,3,2)])]:
 o=Image.new('RGBA',(48,42))
 for j,(x,y,w,h) in enumerate(positions):o.alpha_composite(chip(w,h,j%2),(x,y))
 save(o,f'rock_biome/decor/{name}.png','Sparse non-resource ground scatter; does not represent collectible quantity.',anchor=(24,21),layer='decor',occ=(0,0))
# Dirt and mineral stains follow fractures with low-alpha warm color; no painted grass carpet.
o=Image.new('RGBA',(48,42));d=ImageDraw.Draw(o);d.line([(8,13),(16,16),(21,14),(27,22),(37,26)],fill=(107,95,62,115),width=2);d.line([(21,14),(25,8)],fill=(127,109,72,100))
save(o,'rock_biome/decor/fissure_dirt.png','Optional mineral/dirt fissure, sparse overlay.',anchor=(24,21),layer='decor',occ=(0,0))
# Boundary field: soil then gravel then rock. True transparency leaves native ground intact.
yy,xx=np.indices((42,48));fx=np.clip((xx-4)/40,0,1);fy=np.clip((yy-3)/35,0,1)
fields={'edge_n':1-fy,'edge_e':fx,'edge_s':fy,'edge_w':1-fx,'outer_nw':fx*fy,'outer_ne':(1-fx)*fy,'outer_sw':fx*(1-fy),'outer_se':(1-fx)*(1-fy),'inner_nw':1-(1-fx)*(1-fy),'inner_ne':1-fx*(1-fy),'inner_sw':1-(1-fx)*fy,'inner_se':1-fx*fy,'interior':np.ones((42,48))}
h=((xx//2)*374761393+(yy//2)*668265263+73).astype('uint64');h=((h^(h>>13))*1274126177)&0xffffffff;noise=((h^(h>>16))&65535)/65535
for name,f in fields.items():
 ar=np.zeros((42,48,4),dtype='uint8');t=np.array(tops[0])
 for y in range(42):
  for x in range(48):
   q=f[y,x];r=noise[y,x]
   if q<.1 or r>q*1.8:continue
   ar[y,x]=[158,142,99,100 if q<.5 else 145]
   if q>.35 and r<(q-.2)*.6:ar[y,x]=[*t[y,x,:3],95]
   if q>.74 and r<(q-.74)/.26:ar[y,x]=[*t[y,x,:3],100]
 save(Image.fromarray(ar),f'rock_biome/border/{name}.png','Single rock-side ground boundary; edge direction is ROCK side, corner name is GRASS side.',anchor=(24,21),layer='ground_boundary',occ=(0,0),boundary_kind=name)
for state in ['excavated','rubble','rock_dust']:
 o=Image.new('RGBA',(48,42));d=ImageDraw.Draw(o)
 if state!='rubble':
  mask=Image.new('L',(48,42));ImageDraw.Draw(mask).polygon([(7,17),(15,10),(34,12),(41,22),(34,31),(14,32),(5,24)],fill=95 if state=='excavated' else 55);o=tops[1].copy();o.putalpha(mask);d=ImageDraw.Draw(o)
  d.line([(10,19),(18,16),(26,18)],fill=(99,94,74,140));d.line([(16,28),(29,28),(36,24)],fill=(212,197,158,150))
 if state!='rock_dust':
  for j,(x,y,w,h) in enumerate([(12,22,5,4),(23,19,6,5),(29,25,5,4),(18,27,4,3)]):o.alpha_composite(chip(w,h,j%2),(x,y))
 save(o,f'rock_biome/mined_states/{state}.png','Mining aftermath on intact underlying ground; no void, no item counts.',anchor=(24,21),layer='mined_ground',occ=(0,0))
# Small/medium/large approved nodes and official stone item stay byte-identical.
for size in ['small','medium','large']:
 for state in ['intact','damaged_1','damaged_2','near_depleted']:ref(V2/f'rock_node/{size}/{state}.png',f'mineable.{size}.{state}',[24,46],(1,1),placement='cell_center + (0,14) - anchor')
ref(A/'resource_icons_v1/hud24/stone.png','drops.stone',[12,12],display='existing item scale')
ref(A/'resource_icons_v1/hud24/wood.png','woodcut.wood_drop',[12,12],display='existing item scale')
for label,file in [('small','c'),('medium','b'),('large','a')]:ref(V/f'forest/stump_{file}.png','woodcut.stump_'+label,[32,72])
for name in ['log','branch_debris']:ref(V2/f'tree_cut/{name}.png','woodcut.'+name,[24,21])
for name in ['low_sparse','flowers']:ref(V/f'ground/lush/{name}.png','decor.'+name,[24,21])
for kind,root in [('mining',V/'rock/fx'),('wood_chips',A/'effects_v1/wood_chips'),('leaves',V/'forest')]:
 for f in sorted(root.glob('*.png')):
  if kind=='leaves' and not f.stem.startswith('leaves'):continue
  origin=V if kind in ('mining','leaves') else A/'effects_v1'
  original=json.loads((origin/'manifest.json').read_text(encoding='utf-8-sig'))
  meta=next(a for a in original['assets'] if a['file']==f.relative_to(origin).as_posix())
  ref(f,'fx.'+kind,meta['anchor_px'],source_manifest='../'+origin.relative_to(A).as_posix()+'/manifest.json',frame_index=meta['frame_index'])
  reuse[-1]['duration_ms']=meta.get('duration_ms',meta.get('frame_duration_ms'));reuse[-1]['loop']=meta['loop']
# New fallen-trunk original (if generated) and compact sawdust aftermath.
wf=S/'originals/fallen_trunk.png'
if wf.exists():
 o=im(wf);o.putalpha(o.getchannel('A').point(lambda a:255 if a>=180 else 0));o=o.crop(o.getbbox());o.thumbnail((72,30),Image.Resampling.LANCZOS);o=quant(o,WOOD);out=Image.new('RGBA',(96,48));out.alpha_composite(o,((96-o.width)//2,35-o.height));save(out,'woodcut/fallen_trunk.png','Optional non-colliding fallen trunk visual; 2-cell-wide drawing, no new resource node.',anchor=(48,35),layer='logging_aftermath',occ=(0,0))
o=Image.new('RGBA',(48,42));d=ImageDraw.Draw(o)
for x,y in [(9,20),(15,17),(20,27),(29,18),(34,25),(24,23)]:d.polygon([(x,y),(x+4,y-1),(x+6,y+1),(x+1,y+2)],fill=(174,143,92,160));d.line([(x,y),(x+3,y)],fill=(217,190,139,180))
save(o,'woodcut/logging_ground.png','Sparse wood dust and splinters after felling; base ground remains.',anchor=(24,21),layer='ground',occ=(0,0))
# Optional visual-only loose stone item alternatives, no new game item IDs.
for name,pts in [('crushed_stone',[(6,11,6,5),(12,13,5,4),(10,8,5,4)]),('rock_scraps',[(5,12,7,5),(13,12,6,5)])]:
 o=Image.new('RGBA',(24,24))
 for j,(x,y,w,h) in enumerate(pts):o.alpha_composite(chip(w,h,j%2),(x,y))
 save(o,f'rock_biome/drops/{name}.png','Optional appearance of existing stone item; NOT a new resource type or quantity.',anchor=(12,18),layer='item',occ=(0,0))
# Validation, including all variant port combinations and split composition.
for (v,m),normal in normals.items():
 out=Image.new('RGBA',(48,66))
 for part in parts[v,m].values():out.alpha_composite(part)
 out.alpha_composite(roofs[v,m]);check(f'parts equal combined {v}/{m}',np.array_equal(np.array(out),np.array(normal)))
 check(f'24px southern face {v}/{m}',bool(m&4) or normal.getpixel((24,60))[3]==255)
for va in range(len(tops)):
 for vb in range(len(tops)):
  for a in range(16):
   for b in range(16):
    if a&2 and b&8:
     check(f'EW port {va}/{a}-{vb}/{b}',all(normals[va,a].getpixel((47,y))[3]==normals[vb,b].getpixel((0,y))[3]==255 for y in range(18,37)))
    if a&4 and b&1:check(f'NS port {va}/{a}-{vb}/{b}',all(normals[va,a].getpixel((x,53))[3]==normals[vb,b].getpixel((x,12))[3]==255 for x in range(8,40)))
for a in assets:
 f=D/a['file'];o=im(f);check(a['file']+' RGBA / size / hash / nonempty',Image.open(f).mode=='RGBA' and list(o.size)==a['size_px'] and sha(f)==a['sha256'] and o.getbbox() is not None)
for va in range(len(tops)):
 for vb in range(len(tops)):
  check(f'top EW color match {va}-{vb}',all(tops[va].getpixel((47,y))==tops[vb].getpixel((0,y)) for y in range(42)))
  check(f'top NS color match {va}-{vb}',all(tops[va].getpixel((x,41))==tops[vb].getpixel((x,0)) for x in range(48)))
for (v,m),o in normals.items():
 check(f'no accidental black fill {v}/{m}',all(px[3]==0 or px[:3]!=(0,0,0) for px in o.getdata()))
check('all earlier PNG unchanged',all(sha(A/p)==h for p,h in prior.items()))
manifest=dict(schema_version=1,tile_size_px=[48,42],mask_bits={'N':1,'E':2,'S':4,'W':8},assets=assets,reuse=reuse,format='RGBA',sampling='nearest',placement='Raised connected rock: cell_center-(24,45), 48x66 canvas. One-cell occupancy unchanged.',runtime_verified=False,originals='../../art-production/rock-biome-relief-v1/originals',height_change='24px front vs prior 12px. Foot unchanged at center+18. Whole elevated top is 12px higher. Do not use former anchor24,33.',shadow='No cast shadow baked. Intrinsic face shade remains.',connection_update='Re-evaluate cardinals and diagonals in 3x3 after each mined cell. Variant fixed by cell seed, not frame or damage.',damage='3 static overlays; clip to normal alpha. State thresholds belong to existing game. duration null = hold.',multi_cell='Cluster of independent one-cell nodes, never a single multi-cell resource.')
(D/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
(D/'QA.json').write_text(json.dumps(dict(checks=checks,count=len(checks),prior_png_preserved=len(prior),runtime_verified=False),indent=2)+'\n')
(S/'prior-hashes.json').write_text(json.dumps(prior,indent=2)+'\n')
print(json.dumps({'assets':len(assets),'reuse':len(reuse),'checks':len(checks),'prior':len(prior)}))




