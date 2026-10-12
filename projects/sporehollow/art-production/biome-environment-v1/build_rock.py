from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageChops
import json,hashlib,math,numpy as np
S=Path(__file__).resolve().parent;P=S.parents[1];D=P/'art_delivery/biome_environment_v1';D.mkdir(exist_ok=True);(D/'review').mkdir(exist_ok=True)
FONT='C:/Windows/Fonts/meiryo.ttc'
PAL=['#55564b','#68695a','#777461','#898571','#9c9680','#aaa48c','#bcb59c','#ccc3a7','#d4ccb2','#7c8949','#89984c','#a2a76a']
def img(p):return Image.open(p).convert('RGBA')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def palette(a,colors=PAL):
 ar=np.array(a);c=np.array([tuple(bytes.fromhex(s.strip('#'))) for s in colors],dtype=np.int32);rgb=ar[:,:,:3].astype(np.int32);ix=((rgb[:,:,None,:]-c)**2).sum(axis=3).argmin(axis=2);ar[:,:,:3]=c[ix];ar[:,:,3]=np.where(ar[:,:,3]>=180,255,0);ar[ar[:,:,3]==0]=0;return Image.fromarray(ar)
def fit(a,wh):
 a=a.copy();a.putalpha(a.getchannel('A').point(lambda v:255 if v>=180 else 0));a=a.crop(a.getbbox());a.thumbnail(wh,Image.Resampling.LANCZOS);return palette(a)
records=[]
def save(a,path,anchor,usage,layer='object',occ=[1,1],**extra):
 ar=np.array(a);ar[ar[:,:,3]==0]=0;a.paste(Image.fromarray(ar))
 f=D/path;f.parent.mkdir(parents=True,exist_ok=True);a.save(f);rec={'file':path,'size_px':list(a.size),'anchor_px':anchor,'occupied_cells':occ,'usage':usage,'layer':layer,'frame_index':0,'duration_ms':None,'loop':False,'sha256':sha(f),'ground_shadow':False,**extra};records.append(rec);return a
src=img(S/'originals/rock_materials.png');W,H=src.size
# Source grid regions are recorded, never taken from user reference illustrations.
regions=[(0,0,W//3,H//2),(W//3,0,W*2//3,H//2),(W*2//3,0,W,H//2),(0,H//2,W//3,H),(W//3,H//2,W*2//3,H),(W*2//3,H//2,W,H)]
parts=[src.crop(b) for b in regions]
# The two flat texture swatches are sampled from their interiors; object aspect ratios are preserved separately.
t=palette(src.crop((95,175,310,360)).resize((48,42),Image.Resampling.LANCZOS))
f=palette(src.crop((560,155,940,475)).resize((48,24),Image.Resampling.LANCZOS))
# Match terminal samples for seamless lattice repeat, then restrict to palette again.
def periodic(a,vertical):
 ar=np.array(a)
 for k in range(3):
  c=((ar[:,k,:3].astype(int)+ar[:,-1-k,:3].astype(int))//2).astype('uint8');ar[:,k,:3]=c;ar[:,-1-k,:3]=c
 if vertical:
  for k in range(3):
   c=((ar[k,:,:3].astype(int)+ar[-1-k,:,:3].astype(int))//2).astype('uint8');ar[k,:,:3]=c;ar[-1-k,:,:3]=c
 ar[:,:,3]=255;return palette(Image.fromarray(ar))
t=periodic(t,True);t=palette(t,['#b2ac95','#bcb59c','#c7bfa5']);f=periodic(f,False)
(S/'native').mkdir(exist_ok=True);t.save(S/'native/top_texture.png');f.save(S/'native/front_texture.png')
rock=[];roofs=[]
for mask in range(16):
 n,e,s,w=[bool(mask&b) for b in [1,2,4,8]];x0=0 if w else 3;x1=47 if e else 44;y0=12 if n else 16;y1=53 if s else 38
 tl=0 if n or w else 4;tr=0 if n or e else 4;bl=0 if s or w else 3;br=0 if s or e else 3
 poly=[(x0+tl,y0),(x1-tr,y0),(x1,y0+tr),(x1,y1-br),(x1-br,y1),(x0+bl,y1),(x0,y1-bl),(x0,y0+tl)]
 roofmask=Image.new('L',(48,54));ImageDraw.Draw(roofmask).polygon(poly,fill=255)
 roof=Image.new('RGBA',(48,54));roof.paste(t,(0,12));roof.putalpha(roofmask);dr=ImageDraw.Draw(roof)
 if not n:dr.line([(x0+tl,y0),(x1-tr,y0)],fill=PAL[8],width=1)
 if not w:dr.line([(x0,y0+tl),(x0,y1-bl)],fill=PAL[7],width=1)
 if not e:dr.line([(x1,y0+tr),(x1,y1-br)],fill=PAL[1],width=1)
 if not s:dr.line([(x0+bl,y1),(x1-br,y1)],fill=PAL[7],width=1)
 face=Image.new('RGBA',(48,54))
 if not s:
  face.paste(f.crop((0,6,48,18)),(0,39));fm=Image.new('L',(48,54));fd=ImageDraw.Draw(fm);fd.polygon([(x0+bl,39),(x1-br,39),(x1-br,49),(x1-br-2,51),(x0+bl+2,51),(x0+bl,49)],fill=255);face.putalpha(fm)
  df=ImageDraw.Draw(face);df.line([(x0+bl+2,51),(x1-br-2,51)],fill=PAL[0])
 out=face.copy();out.alpha_composite(roof)
 # Sparse moss kept away from ports; no opaque outline on connected interiors.
 if not s:
  dd=ImageDraw.Draw(out);dd.line([(12,37),(15,37),(15,39)],fill=PAL[9]);dd.point((32,39),fill=PAL[10])
 rock.append(out);roofs.append(roof)
 save(out,f'rock/normal/mask_{mask:02}.png',[24,33],'48x42 cell rock; N1 E2 S4 W8',connection_mask=mask,placement='cell_center - anchor',visual_front_height_px=12)
 save(roof,f'rock/parts/top_{mask:02}.png',[24,33],'Optional independent roof; do not overlay onto combined normal',connection_mask=mask,layer='roof')
 if not s and not n:
  save(face,f'rock/parts/front_edges_{int(w)*2+int(e):02}.png',[24,33],'Optional normal12px front; select W/E bits; use instead of combined',layer='front')
# Taller face is optional separate part, not a new height rule or default replacement.
for edges in range(4):
 a=f.copy();m=Image.new('L',(48,24));ImageDraw.Draw(m).rectangle((0 if edges&2 else 6,0,47 if edges&1 else 41,23),fill=255);a.putalpha(m)
 save(a,f'rock/parts/tall_front_edges_{edges:02}.png',[24,24],'Optional24px cliff front. Renderer must provide its top and depth; not used by current rock_view.',layer='optional_front',runtime_connection='unconnected_optional')
for corner in ['nw','ne','sw','se']:
 a=Image.new('RGBA',(48,54));dr=ImageDraw.Draw(a);x=0 if corner.endswith('w') else 47;y=12 if corner.startswith('n') else 53;dx=1 if x==0 else -1;dy=1 if y==12 else -1
 dr.line([(x,y+dy*5),(x+dx*2,y+dy*2),(x+dx*5,y)],fill=PAL[1],width=1)
 save(a,f'rock/parts/inner_{corner}.png',[24,33],'Optional concave notch: BOTH adjacent cardinal rocks present AND diagonal absent; one per eligible corner.',layer='roof_overlay',requires_diagonal_query=True)
# Master cracks are independent. Clip by selected rock alpha before compositing.
for level in ['light','heavy']:
 a=Image.new('RGBA',(48,54));dr=ImageDraw.Draw(a)
 paths=[[(18,20),(21,23),(20,28),(25,32),(24,37)],[(20,28),(15,30),(12,29)]]
 if level=='heavy':paths += [[(33,19),(29,23),(30,28),(25,32),(27,40),(26,47)],[(25,32),(34,34),(38,31)],[(21,23),(17,18)]]
 for pts in paths:
  dr.line([(x+1,y) for x,y in pts],fill=PAL[7],width=1);dr.line(pts,fill=PAL[0],width=1)
 save(a,f'rock/damage/{level}.png',[24,33],'Clip alpha by current rock; state threshold comes from existing implementation',layer='damage_overlay')
for i,(name,wh) in enumerate([('rubble',(36,22)),('gravel',(34,21)),('exposed',(44,30))]):
 a=fit(parts[i+3],wh);o=Image.new('RGBA',(48,42));o.alpha_composite(a,((48-a.width)//2,(42-a.height)//2));save(o,f'rock/ground/{name}.png',[24,21],name+' on existing continuous biome base',layer='ground',occ=[0,0])
# Small native chips from generated gravel, placed with integer displacements. No scene-wide flash.
chip=fit(parts[4],(10,7));chip=chip.crop((0,0,5,5));chip=chip.crop(chip.getbbox())
for frame in range(4):
 a=Image.new('RGBA',(32,32))
 for i,(dx,dy) in enumerate([(-1,-1),(1,-1),(-1,0),(1,0)]):
  ob=chip.copy();ob.putalpha(ob.getchannel('A').point(lambda z: max(0,255-frame*52) if z else 0));a.alpha_composite(ob,(14+dx*(frame*3+i),18+dy*(frame*3+2)-frame))
 save(a,f'rock/fx/chips_{frame:02}.png',[16,26],'Local mining impact fragments; visual only',layer='fx',occ=[0,0],frame_index=frame,duration_ms=[65,75,85,100][frame],animation='mining_chips')
# External references remain in their existing folders, avoiding duplicate PNGs.
reuse=[]
for role,path,anchor in [('stone_drop','resource_icons_v1/hud24/stone.png',[12,12]),('mining_dust','effects_v1/soil_dust',[16,26]),('collapse_powder','effects_v1/stone_powder',[16,26])]:
 source=P/'art_delivery'/path;files=sorted(source.glob('*.png')) if source.is_dir() else [source]
 for i,ff in enumerate(files):reuse.append({'role':role,'file':'../'+str(ff.relative_to(P/'art_delivery')).replace('\\','/'),'size_px':list(img(ff).size),'anchor_px':anchor,'sha256':sha(ff),'frame_index':i,'timing_source':'../effects_v1/manifest.json' if source.is_dir() else None,'loop':False,'usage':'Reuse unchanged; item center for stone, local ground contact for dust.'})
meta={'schema_version':1,'stage':'rock','branch':'codex/sporehollow-art-assets','reference_commit':json.loads((S/'reference-commit.json').read_text())['commit'],'tile_size_px':[48,42],'mask_bits':{'N':1,'E':2,'S':4,'W':8},'assets':records,'reuse':reuse,'runtime_verified':False,'sampling':'nearest','format':'RGBA'}
(D/'rock_manifest.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
# Review proof: isolated, connected, mined hole and cleared footprint at exact lattice pitch.
font=ImageFont.truetype(FONT,16)
def scene(cells,removed):
 out=Image.new('RGBA',(336,252),'#839955')
 for y in range(5):
  for x in range(6):
   if (x,y) in cells or (x,y) in removed:out.alpha_composite(img(D/'rock/ground/gravel.png'),(24+x*48,24+y*42))
 for x,y in removed:
  out.alpha_composite(img(D/'rock/ground/exposed.png'),(24+x*48,24+y*42))
  if cells:out.alpha_composite(img(D/'rock/ground/rubble.png'),(24+x*48,24+y*42))
 for x,y in sorted(cells,key=lambda p:(p[1],p[0])):
  m=sum(b for b,dx,dy in [(1,0,-1),(2,1,0),(4,0,1),(8,-1,0)] if (x+dx,y+dy) in cells);out.alpha_composite(rock[m],(24+x*48,12+y*42))
 return out
base={(x,y) for y in range(1,4) for x in range(1,5)};hole={(2,2),(3,3)}
panels=[scene({(2,2)},set()),scene(base,set()),scene(base-hole,hole),scene(set(),base)]
review=Image.new('RGBA',(720,620),'#293d30');dr=ImageDraw.Draw(review)
for i,pan in enumerate(panels):
 x=12+(i%2)*354;y=40+(i//2)*292;review.alpha_composite(pan,(x,y));dr.text((x,y-24),['1 isolated / native','2 connected / native','3 mined two cells','4 all mined / ground remains'][i],font=font,fill='white')
dr.text((14,595),'OFFLINE COMPOSITION / not an in-game screenshot',font=font,fill='white');review.save(D/'review/rock_mining.png')
scale=scene(base-hole,hole);keeper=img(P/'art_delivery/characters_v1/keeper_idle_right_00.png');dog=img(P/'art_delivery/characters_v1/shiba_idle_right_00.png');scale.alpha_composite(keeper,(145,170));scale.alpha_composite(dog,(200,174));scale.save(D/'review/rock_scale_native.png')
grid=Image.new('RGBA',(800,620),'#71884f');dr=ImageDraw.Draw(grid)
for i,a in enumerate(rock):
 x=(i%4)*200;y=(i//4)*150;dr.text((x+8,y+8),f'mask {i:02}',font=font,fill='white');grid.alpha_composite(a.resize((96,108),Image.Resampling.NEAREST),(x+20,y+32))
grid.save(D/'review/rock_masks_2x.png')
sheet=Image.new('RGBA',(192,216))
for i,a in enumerate(rock):sheet.alpha_composite(a,((i%4)*48,(i//4)*54))
sheet.save(D/'rock/normal_sheet.png')
(S/'rock-extraction.json').write_text(json.dumps({'texture_crops':[[95,175,310,360],[560,155,940,475]],'source_size':list(src.size),'source_regions':regions,'palette':PAL,'texture_periodic_edge_width':3,'alpha_threshold':180,'damage_clip_required':True},indent=2))
print('Rock assets:',len(records),'external reuse:',len(reuse))
