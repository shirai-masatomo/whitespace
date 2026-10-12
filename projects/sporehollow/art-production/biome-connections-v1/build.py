from pathlib import Path
from PIL import Image, ImageDraw, ImageChops, ImageFont
import numpy as np, hashlib, json
S=Path(__file__).resolve().parent; P=S.parents[1]; A=P/'art_delivery'; D=A/'biome_connections_v1'; V=A/'biome_environment_v1'; V2=A/'biome_environment_v2'
D.mkdir(exist_ok=True); (D/'review').mkdir(exist_ok=True)
def im(p): return Image.open(p).convert('RGBA')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
prior={str(p.relative_to(A)).replace('\\','/'):sha(p) for p in A.rglob('*.png') if D not in p.parents}
assets=[]; roofs=[]; normals=[]; parts={}; palette=['#55564b','#68695a','#777461','#898571','#9c9680','#aaa48c','#bcb59c','#ccc3a7','#d4ccb2','#7c8949']
def save(a,f,usage,anchor=(24,33),layer='rock',occ=(1,1),**kw):
 ar=np.array(a); ar[ar[:,:,3]==0]=0; a=Image.fromarray(ar); p=D/f;p.parent.mkdir(parents=True,exist_ok=True);a.save(p)
 assets.append(dict(file=f,size_px=list(a.size),anchor_px=list(anchor),occupied_cells=list(occ),layer=layer,usage=usage,frame_index=0,duration_ms=None,loop=False,shadow_baked=False,sha256=sha(p),**kw));return a
# Adopted native swatches, re-clustered at final pixel resolution. No node regeneration.
t=im(P/'art-production/biome-environment-v1/native/top_texture.png')
ar=np.array(t)
for y in range(0,42,3):
 for x in range(0,48,4):
  block=ar[y:y+3,x:x+4];block[:,:,:3]=np.median(block[:,:,:3],axis=(0,1)).astype('uint8')
t=Image.fromarray(ar); dr=ImageDraw.Draw(t)
# Subtle broad fracture facets: not repeated tiny noisy surface veins.
dr.polygon([(8,10),(22,7),(28,10),(24,12),(12,13)],fill='#c0b99f')
dr.line([(30,27),(35,24),(40,25)],fill='#aaa48c')
dr.line([(12,31),(18,32),(21,29)],fill='#aaa48c')
front=im(P/'art-production/biome-environment-v1/native/front_texture.png')
f=np.array(front)
for y in range(0,24,3):
 for x in range(0,48,4):f[y:y+3,x:x+4,:3]=np.median(f[y:y+3,x:x+4,:3],axis=(0,1)).astype('uint8')
front=Image.fromarray(f)
for m in range(16):
 n,e,s,w=[bool(m&b) for b in (1,2,4,8)];x0=0 if w else 5;x1=47 if e else 42;y0=12 if n else 16;y1=53 if s else 38
 tl=0 if n or w else 3;tr=0 if n or e else 3;bl=0 if s or w else 2;br=0 if s or e else 2
 # Irregular exposed contours; connected ports keep exact cell edges.
 north=[(x,y0+(0 if n else [0,1,0,0,-1,0][(x//7)%6])) for x in range(x0+tl,x1-tr+1)]
 east=[(x1+(0 if e else [0,0,-1,0,1,0][(y//6)%6]),y) for y in range(y0+tr,y1-br+1)]
 south=[(x,y1+(0 if s else [0,1,1,0,-1,0][(x//8)%6])) for x in range(x1-br,x0+bl-1,-1)]
 west=[(x0+(0 if w else [0,0,1,0,-1,0][(y//6)%6]),y) for y in range(y1-bl,y0+tl-1,-1)]
 poly=north+east+south+west
 rm=Image.new('L',(48,54));ImageDraw.Draw(rm).polygon(poly,fill=255)
 roof=Image.new('RGBA',(48,54));roof.paste(t,(0,12));roof.putalpha(rm);rd=ImageDraw.Draw(roof)
 if not n:
  for a,b in [(10,17),(28,34)]:rd.line([(a,y0),(b,y0)],fill=palette[7])
 if not w:rd.line([(x0,24),(x0,29)],fill=palette[7])
 if not e:rd.line([(x1,21),(x1,27)],fill=palette[4])
 if not s:
  for a,b in [(9,18),(29,36)]:rd.line([(a,y1),(b,y1)],fill=palette[7])
 normals.append(Image.new('RGBA',(48,54)));parts[m]={}
 # North is a shallow rear shoulder; do not fake a south-facing cliff on the north edge.
 for name,present in [('n',n),('w',w),('e',e),('s',s)]:
  if present:continue
  face=Image.new('RGBA',(48,54));dd=ImageDraw.Draw(face)
  if name=='n':
   dd.polygon([(x0+tl,16)]+[(x,y0+[1,0,0,1,0,0][(x//7)%6]) for x in range(x0+tl,x1-tr+1)]+[(x1-tr,17)],fill=palette[4])
  if name in ('w','e'):
   west=name=='w';lo=3 if west else 43;hi=4 if west else 44;ya=y0+ (tl if west else tr);yb=53 if s else 48
   dd.polygon([(lo+[0,0,1,0,-1,0][(y//6)%6],y) for y in range(ya,yb+1)]+[(hi+1,yb),(hi+1,ya)],fill=palette[3] if west else palette[1])
   for yy in range(ya+4,yb-2,9):dd.line([(lo,yy),(hi,yy+2)],fill=palette[2] if west else palette[0])
   dd.line([(lo,yb),(hi,yb)],fill=palette[0])
  if name=='s':
   xa=0 if w else 5;xb=47 if e else 42;face.paste(front.crop((0,5,48,18)),(0,39));fm=Image.new('L',(48,54));ImageDraw.Draw(fm).polygon([(xa,38),(xb,38),(xb,48)]+[(x,50+[0,1,0,1,1,0][(x//8)%6]) for x in range(xb-2,xa+1,-1)]+[(xa,48)],fill=255);face.putalpha(fm);dd=ImageDraw.Draw(face)
   for xx in [11,25,39]:dd.line([(xx,40),(xx-2,45),(xx-1,49)],fill=palette[1]);dd.line([(xx+1,40),(xx,44)],fill=palette[4])
   dd.line([(xa+5,50),(min(xa+13,xb-2),50)],fill=palette[1])
  parts[m][name]=save(face,f'exposed/{name}_mask_{m:02}.png','Exposed '+name+' face only when neighboring rock absent. Draw before roof.',layer='exposed_face',connection_mask=m,direction=name)
  normals[m].alpha_composite(face)
 normals[m].alpha_composite(roof);roofs.append(save(roof,f'roof/mask_{m:02}.png','Separate roof; use parts OR combined, never both.',layer='roof',connection_mask=m))
 save(normals[m],f'normal/mask_{m:02}.png','Combined connected rock. Select current cardinal occupancy mask every render.',connection_mask=m,visual_front_height_px=12)
# Concave notch at a missing diagonal, only with both adjacent cardinal neighbors present.
for corner in ('nw','ne','sw','se'):
 a=Image.new('RGBA',(48,54));dd=ImageDraw.Draw(a);x=0 if corner[1]=='w' else 47;y=12 if corner[0]=='n' else 53;dx=1 if x==0 else -1;dy=1 if y==12 else -1
 dd.polygon([(x,y),(x+dx*5,y),(x+dx*2,y+dy*2),(x,y+dy*6)],fill=palette[2]);dd.line([(x+dx*5,y),(x+dx*2,y+dy*2),(x,y+dy*6)],fill=palette[7] if dy==1 else palette[4])
 save(a,f'inner/concave_{corner}.png','Small concave exposed seam: BOTH cardinals present and diagonal absent.',layer='roof_overlay',requires_diagonal_query=True,corner=corner)
# Four-stage transition selected once per ground cell. Substrate remains alpha visible.
yy,xx=np.indices((42,48));fx=np.clip((xx-5)/38,0,1);fy=np.clip((yy-4)/33,0,1)
fields={'edge_n':1-fy,'edge_e':fx,'edge_s':fy,'edge_w':1-fx,'outer_nw':fx*fy,'outer_ne':(1-fx)*fy,'outer_sw':fx*(1-fy),'outer_se':(1-fx)*(1-fy),'inner_nw':1-(1-fx)*(1-fy),'inner_ne':1-fx*(1-fy),'inner_sw':1-(1-fx)*fy,'inner_se':1-fx*fy,'full':np.ones((42,48))}
h=((xx//2)*374761393+(yy//2)*668265263+31).astype('uint64');h=((h^(h>>13))*1274126177)&0xffffffff;noise=((h^(h>>16))&65535)/65535
stone=np.array(im(V2/'rock_ground/bedrock.png'));gravel=np.array(im(V2/'rock_ground/gravel.png'))
for name,field in fields.items():
 a=np.zeros((42,48,4),dtype=np.uint8)
 for y in range(42):
  for x in range(48):
   q=field[y,x];v=noise[y,x]
   if q<.13 or v>min(1,q*2.5):continue
   # Patchy soil emerges first, gravel increases, bedrock interior dominates.
   a[y,x]=[160,148,105,110 if q<.42 else 145]
   if q>.32 and gravel[y,x,3]>0 and v<min(1,(q-.24)*2):a[y,x]=gravel[y,x]
   if q>.58 and v<(q-.58)/.42:a[y,x]=stone[y,x];a[y,x,3]=190
 save(Image.fromarray(a),f'transition/{name}.png','Single composite grass→soil→gravel→bedrock ground overlay; biome side named for edges, grass side for corners.',anchor=(24,21),layer='ground',occ=(0,0),boundary_kind=name)
reuse=[]
for root,pattern,role,anchor in [(V/'rock/damage','*.png','damage',(24,33)),(V/'rock/ground','*.png','mined_ground',(24,21)),(V2/'rock_mined','*.png','mined_ground',(24,21)),(V2/'rock_node','wall_near*.png','damage',(24,33)),(V2/'rock_node','*/intact.png','isolated_node',(24,46)),(V2/'rock_node','*/damaged_*.png','isolated_node',(24,46)),(V2/'rock_node','*/near_depleted.png','isolated_node',(24,46))]:
 for f in sorted(root.glob(pattern)):reuse.append(dict(file='../'+f.relative_to(A).as_posix(),role=role,size_px=list(im(f).size),anchor_px=list(anchor),sha256=sha(f),duration_ms=None,loop=False))
manifest=dict(schema_version=1,tile_size_px=[48,42],mask_bits={'N':1,'E':2,'S':4,'W':8},sampling='nearest',format='RGBA',assets=assets,reuse=reuse,placement='cell_center - anchor; same as v1 connected walls',ground_shadow='No cast ground shadow; face shading is intrinsic.',runtime_verified=False,connection_rule='cardinal occupancy; optional concave diagonal overlay; re-evaluate 3x3 around mined cell',boundary_rule='Biome field classification separate from rock occupancy. Select ONE full/edge/inner/outer transition per cell. Keep original ground underneath.')
(D/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',14)
def scene(cells,removed):
 out=Image.new('RGBA',(288,252),'#839955')
 for y in range(5):
  for x in range(5):
   if 1<=x<=3 and 1<=y<=3:key='full'
   elif x in (0,4) and y in (0,4):key='outer_'+('n' if y==0 else 's')+('w' if x==0 else 'e')
   elif x==0:key='edge_e'
   elif x==4:key='edge_w'
   elif y==0:key='edge_s'
   else:key='edge_n'
   out.alpha_composite(im(D/f'transition/{key}.png'),(24+x*48,21+y*42))
 for x,y in removed:out.alpha_composite(im(V2/'rock_mined/exposed_bedrock.png'),(24+x*48,21+y*42));out.alpha_composite(im(V/'rock/ground/rubble.png'),(24+x*48,21+y*42))
 for x,y in sorted(cells,key=lambda c:(c[1],c[0])):
  mask=sum(b for b,dx,dy in [(1,0,-1),(2,1,0),(4,0,1),(8,-1,0)] if (x+dx,y+dy) in cells);out.alpha_composite(normals[mask],(24+x*48,9+y*42))
  for co,dx,dy,b1,b2 in [('nw',-1,-1,1,8),('ne',1,-1,1,2),('sw',-1,1,4,8),('se',1,1,4,2)]:
   if mask&b1 and mask&b2 and (x+dx,y+dy) not in cells:out.alpha_composite(im(D/f'inner/concave_{co}.png'),(24+x*48,9+y*42))
 return out
base={(x,y) for x in range(1,4) for y in range(1,4)};canvas=Image.new('RGBA',(600,578),'#293d30');dd=ImageDraw.Draw(canvas)
for i,(name,removed) in enumerate([('intact 3x3',set()),('center mined',{(2,2)}),('edge mined',{(2,1)}),('corner mined',{(1,1)})]):
 x=8+(i%2)*300;y=27+(i//2)*278;canvas.alpha_composite(scene(base-removed,removed),(x,y));dd.text((x,y-22),name,font=font,fill='white')
dd.text((12,555),'OFFLINE composition / actual game validation is separate',font=font,fill='white');canvas.save(D/'review/connection_cases.png')
cat=Image.new('RGBA',(768,512),'#71884f');dd=ImageDraw.Draw(cat)
for m,a in enumerate(normals):
 x=(m%4)*192;y=(m//4)*128;cat.alpha_composite(a.resize((96,108),Image.Resampling.NEAREST),(x+48,y+18));dd.text((x+8,y+2),f'mask {m:02}',font=font,fill='white')
cat.save(D/'review/masks.png')
# Explicit checks: composition, opacity ports, alpha mode, preserved prior artwork.
checks=[]
def check(name,value):checks.append({'check':name,'pass':bool(value)});assert value,name
check('prior PNG hashes unchanged',all(sha(A/p)==h for p,h in prior.items()))
check('12 standalone rock states retained',sum(r['role']=='isolated_node' for r in reuse)==12)
for a in assets:check(a['file']+' RGBA + hash',Image.open(D/a['file']).mode=='RGBA' and sha(D/a['file'])==a['sha256'])
for m in range(16):
 test=Image.new('RGBA',(48,54))
 for face in parts[m].values():test.alpha_composite(face)
 test.alpha_composite(roofs[m]);check(f'parts equal combined {m}',np.array_equal(np.array(test),np.array(normals[m])))
for a in range(16):
 for b in range(16):
  if a&2 and b&8:check(f'EW interior port {a}-{b}',all(normals[a].getpixel((47,y))[3]==normals[b].getpixel((0,y))[3]==255 for y in range(17,38)))
  if a&4 and b&1:check(f'NS interior port {a}-{b}',all(normals[a].getpixel((x,53))[3]==normals[b].getpixel((x,12))[3]==255 for x in range(8,40)))
(D/'QA.json').write_text(json.dumps({'checks':checks,'count':len(checks),'prior_png_preserved':len(prior),'actual_game_test':False},indent=2)+'\n')
(S/'prior-hashes.json').write_text(json.dumps(prior,indent=2)+'\n')
print(json.dumps({'assets':len(assets),'reuse':len(reuse),'checks':len(checks),'prior':len(prior)}))
