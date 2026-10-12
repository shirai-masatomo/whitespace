from pathlib import Path
from PIL import Image,ImageDraw,ImageChops,ImageOps,ImageFilter,ImageFont
import numpy as np,json,hashlib,math
S=Path(__file__).resolve().parent;P=S.parents[1];D=P/'art_delivery/biome_environment_v2';V=P/'art_delivery/biome_environment_v1';D.mkdir(exist_ok=True);(D/'review').mkdir(exist_ok=True)
def im(f):return Image.open(f).convert('RGBA')
def sha(f):return hashlib.sha256(f.read_bytes()).hexdigest()
STONE=['#55564b','#68695a','#777461','#898571','#9c9680','#aaa48c','#bcb59c','#ccc3a7','#d4ccb2']
WOOD=['#3d3023','#53412c','#6a5035','#805f3b','#96754b','#af8f5e','#c6a576','#d8bd90','#e5cda3','#53633d','#6b7c44','#87905a']
def quant(a,palette=STONE):
 ar=np.array(a);cols=np.array([tuple(bytes.fromhex(c[1:])) for c in palette],dtype=np.int32);idx=((ar[:,:,:3].astype(np.int32)[:,:,None,:]-cols)**2).sum(3).argmin(2);ar[:,:,:3]=cols[idx];ar[:,:,3]=np.where(ar[:,:,3]>=160,255,0);ar[ar[:,:,3]==0]=0;return Image.fromarray(ar)
def trim(a):
 a=a.copy();a.putalpha(a.getchannel('A').point(lambda v:255 if v>=180 else 0));return a.crop(a.getbbox())
def fit(a,size,palette=STONE):
 a=trim(a);a.thumbnail(size,Image.Resampling.LANCZOS);return quant(a,palette)
records=[];reuse=[];states={};extraction=[]
def save(a,path,usage,anchor=(24,21),layer='ground',occupied=(0,0),**kw):
 ar=np.array(a);ar[ar[:,:,3]==0]=0;a=Image.fromarray(ar);f=D/path;f.parent.mkdir(parents=True,exist_ok=True);a.save(f);records.append({'file':path,'size_px':list(a.size),'anchor_px':list(anchor),'occupied_cells':list(occupied),'layer':layer,'usage':usage,'frame_index':0,'duration_ms':None,'loop':False,'sha256':sha(f),'shadow_baked':False,**kw});return a
def reference(f,role,anchor,**kw):
 reuse.append({'file':'../'+str(f.relative_to(P/'art_delivery')).replace('\\','/'),'role':role,'size_px':list(im(f).size),'anchor_px':anchor,'sha256':sha(f),'duration_ms':None,'loop':False,**kw})
# Node sizes are graphical variants of the existing one-cell resource, not new amounts/classes.
a=im(S/'originals/rock_nodes.png');W,H=a.size
for row,name in enumerate(['small','medium','large']):
 raw=[]
 for col in range(4):
  box=(col*W//4,row*H//3,(col+1)*W//4,(row+1)*H//3);raw.append(trim(a.crop(box)))
 factor=min([22,34,44][row]/raw[0].width,[18,27,36][row]/raw[0].height);native=[]
 for k,obj in enumerate(raw):
  obj=quant(obj.resize((max(1,round(obj.width*factor)),max(1,round(obj.height*factor))),Image.Resampling.LANCZOS));out=Image.new('RGBA',(48,54));out.alpha_composite(obj,(24-obj.width//2,46-obj.height));native.append(out)
 # Preserve the exact intact identity at the first chipping step. Remove material, expose a fresh edge.
 native[1]=native[0].copy();b=native[0].getbbox();x=b[2]-1;y=b[3]-max(4,round((b[3]-b[1])*.42));dd=ImageDraw.Draw(native[1]);cut=[(x,y-3),(x-5-row*2,y+1),(x-4-row*2,y+5+row),(x-1,y+7+row),(x+2,y+7+row),(x+2,y-3)];dd.polygon(cut,fill=(0,0,0,0));dd.line([(x-6-row*2,y),(x-5-row*2,y+2),(x-4-row*2,y+4)],fill=STONE[7],width=1)
 # Monotonic silhouette loss is mandatory; source frames are not stretched to a fixed bbox.
 for k in [2,3]:
  prev=np.count_nonzero(np.array(native[k-1])[:,:,3]);ar=np.array(native[k]);limit=int(prev*([.84,.62][k-2]));coords=np.argwhere(ar[:,:,3]>0)
  if len(coords)>limit:
   ranked=sorted(coords.tolist(),key=lambda p:(p[0]+abs(p[1]-22)*.25))
   for yy,xx in ranked[:len(coords)-limit]:ar[yy,xx]=0
   native[k]=Image.fromarray(ar)
 stages=['intact','damaged_1','damaged_2','near_depleted'];states[name]=[]
 for k,ob in enumerate(native):
  f=f'rock_node/{name}/{stages[k]}.png';save(ob,f,'Mineable one-cell stone deposit. Visual state only; existing resource data determines availability.',anchor=(24,46),layer='resource_node',occupied=(1,1),visual_state=stages[k],size_variant=name,placement='cell_center + (0,14) - anchor');states[name].append(f)
 extraction.append({'row':row,'scale_fixed_for_all_stages':factor,'native_alpha_area':[int(np.count_nonzero(np.array(o)[:,:,3])) for o in native]})
 # Separable contact shadow: optional and deliberately weak.
 shadow=Image.new('RGBA',(48,54));dd=ImageDraw.Draw(shadow);rx=[10,15,20][row];dd.ellipse((24-rx,43,24+rx,48),fill=(45,55,38,42));save(shadow,f'rock_node/shadow_{name}.png','Optional ground contact shadow; suppress if renderer already draws one.',anchor=(24,46),layer='shadow')
# Ground materials retain continuous base color. Periodic bedrock sample from adopted master.
tex=im(P/'art-production/biome-environment-v1/native/top_texture.png');tex.putalpha(Image.new('L',tex.size,160));save(tex,'rock_ground/bedrock.png','Low-contrast continuous bedrock overlay; existing base remains visible')
pebble=im(V/'rock/ground/gravel.png');gravel=Image.new('RGBA',(48,42))
# Wrap offsets creates scatter density without opaque patches or rectangular ground backgrounds.
for x,y in [(0,0),(19,13),(-17,-11)]:
 for dx in [-48,0,48]:
  for dy in [-42,0,42]:gravel.alpha_composite(pebble,(x+dx,y+dy))
gravel.putalpha(gravel.getchannel('A').point(lambda v:180 if v else 0));save(gravel,'rock_ground/gravel.png','Scattered fine gravel overlay; zero collision')
soil=im(V/'ground/dry/soil_spot.png');mixed=soil.copy();mixed.alpha_composite(pebble);save(mixed,'rock_ground/pebbly_soil.png','Small stones with some worn soil, not a harvestable deposit')
mixedgrass=pebble.copy();mixedgrass.alpha_composite(im(V/'ground/lush/cover_sparse.png'));save(mixedgrass,'rock_ground/grass_stone.png','Sparse surviving meadow grass among small stones')
# One family per boundary. The names describe which side contains the rock biome.
yy,xx=np.indices((42,48));fx=np.clip((xx-12)/24,0,1);fy=np.clip((yy-10)/22,0,1)
hashgrid=((xx//2).astype('uint64')*374761393+(yy//2).astype('uint64')*668265263+19)&0xffffffff
hashgrid=((hashgrid^(hashgrid>>13))*1274126177)&0xffffffff
noise=((hashgrid^(hashgrid>>16))&0xffff)/65536.0
fields={'edge_n':1-fy,'edge_s':fy,'edge_w':1-fx,'edge_e':fx,
'outer_nw':fx*fy,'outer_ne':(1-fx)*fy,'outer_sw':fx*(1-fy),'outer_se':(1-fx)*(1-fy),
'inner_nw':1-(1-fx)*(1-fy),'inner_ne':1-fx*(1-fy),'inner_sw':1-(1-fx)*fy,'inner_se':1-fx*fy}
for family,base in [('bedrock',tex),('gravel',gravel)]:
 for key,field in fields.items():
  arr=np.array(base);coverage=np.where(noise<field,1,0);arr[:,:,3]=(arr[:,:,3]*coverage).astype('uint8');save(Image.fromarray(arr),f'rock_transition/{family}/{key}.png','Pixel-dithered biome boundary; select one transition per cell, do not stack edge and corner.',boundary_family=family,boundary_kind=key)
# Thin strips and irregular patches can be sparsely overlaid; no framed tile border.
for name,field in [('thin_horizontal',np.clip(1-abs(yy-21)/6,0,1)),('thin_vertical',np.clip(1-abs(xx-24)/6,0,1)),('patch_round',np.clip(1-((xx-25)/19)**2-((yy-20)/14)**2,0,1)),('patch_worn',np.clip(1-abs(xx-24)/24-abs(yy-21)/8,0,1))]:
 arr=np.array(mixed);arr[:,:,3]=(arr[:,:,3]*(noise<field)).astype('uint8');save(Image.fromarray(arr),f'rock_transition/{name}.png','Optional sparse boundary/wear patch, no passability effect')
# Mined results remain ground overlays, deliberately shallow.
rubble=im(V/'rock/ground/rubble.png');reference(V/'rock/ground/rubble.png','rock_mined.rubble',[24,21]);reference(V/'rock/ground/gravel.png','rock_mined.scattered_chips',[24,21])
scuff=Image.new('RGBA',(48,42));d=ImageDraw.Draw(scuff);d.polygon([(8,14),(15,9),(33,11),(41,20),(35,31),(16,33),(6,24)],fill=(154,145,111,120));d.line([(10,14),(18,11),(32,12)],fill=(110,105,83,140));d.line([(15,30),(29,30),(35,27)],fill=(199,186,142,140));save(scuff,'rock_mined/shallow_scoop.png','Shallow mined ground, not a void or new pit collision')
skin=scuff.copy();small=tex.copy();mask=Image.new('L',(48,42));ImageDraw.Draw(mask).polygon([(12,14),(30,12),(36,20),(28,27),(13,26)],fill=150);small.putalpha(mask);skin.alpha_composite(small);save(skin,'rock_mined/exposed_bedrock.png','Fresh exposed rock surface after node depletion')
# Scatter aliases avoid generating known flowers, grass and fine fragments again.
for role,f in [('scatter.pebbles',V/'rock/ground/gravel.png'),('scatter.rock_grass',V/'ground/lush/low_sparse.png'),('scatter.small_flowers',V/'ground/lush/flowers.png'),('scatter.soil_scuff',V/'ground/dry/soil_spot.png')]:reference(f,role,[24,21])
# Existing connected walls remain unchanged; optional pre-completion crack overlay is new.
for f in sorted((V/'rock/normal').glob('*.png')):reference(f,'connected_wall.'+f.stem,[24,33])
for f in sorted((V/'rock/parts').glob('inner_*.png')):reference(f,'connected_inner.'+f.stem,[24,33])
for f in sorted((V/'rock/parts').glob('tall_*.png')):reference(f,'ledge.'+f.stem,[24,24])
crack=im(V/'rock/damage/heavy.png');d=ImageDraw.Draw(crack);d.line([(9,22),(13,25),(11,34),(15,41),(13,48)],fill=STONE[0],width=2);d.line([(31,27),(37,29),(34,38),(38,45)],fill=STONE[0],width=2);save(crack,'rock_node/wall_near_depleted_overlay.png','Clip by selected wall alpha. Maintains connection ports until mining completes.',anchor=(24,33),layer='damage_overlay')
for f in (V/'rock/damage').glob('*.png'):reference(f,'wall_damage.'+f.stem,[24,33])
# Logging supplement: no new full standing trees.
woodsrc=im(S/'originals/log_branch.png');W,H=woodsrc.size
for i,name in enumerate(['log','branch_debris']):
 ob=fit(woodsrc.crop((i*W//2,0,(i+1)*W//2,H)),(32,20),WOOD);o=Image.new('RGBA',(48,42));o.alpha_composite(ob,((48-ob.width)//2,29-ob.height));save(o,f'tree_cut/{name}.png','Felling aftermath prop; drops/counts/removal are controlled by existing implementation')
for letter,label in [('c','small'),('b','medium'),('a','large')]:
 base=P/f'art_delivery/ui_world_direction_v1/candidates/world/tree_{letter}.png';reference(base,'tree.'+label,[32,72],occupied_cells=[1,1]);reference(V/f'forest/stump_{letter}.png','tree_cut.stump_'+label,[32,72])
 for level in ['light','deep']:reference(V/f'forest/notch_{letter}_{level}.png','tree_cut.'+label+'_'+level,[32,72])
 overlay=im(V/f'forest/notch_{letter}_deep.png');d=ImageDraw.Draw(overlay);d.line([(31,61),(33,64),(31,68)],fill=WOOD[0],width=1);d.line([(32,62),(34,65)],fill=WOOD[7],width=1);trunk=im(base.with_name('tree_'+letter+'_trunk.png'));overlay.putalpha(ImageChops.multiply(overlay.getchannel('A'),trunk.getchannel('A')));save(overlay,f'tree_cut/{label}_near_fall.png','Final split overlay on adopted tree; renderer may tilt around cut point (32,65). No new progress threshold.',anchor=(32,72),layer='trunk_overlay')
# Three optional pre-fall body poses derived solely from adopted tree pixels.
for letter,name in [('c','small'),('b','medium'),('a','large')]:
 tree=im(P/f'art_delivery/ui_world_direction_v1/candidates/world/tree_{letter}.png');tree.alpha_composite(im(D/f'tree_cut/{name}_near_fall.png'))
 upper=tree.copy();ImageDraw.Draw(upper).rectangle((0,65,63,79),fill=(0,0,0,0));lower=tree.copy();ImageDraw.Draw(lower).rectangle((0,0,63,64),fill=(0,0,0,0))
 body=Image.new('RGBA',(112,96));body.alpha_composite(lower,(24,16));tilt=Image.new('RGBA',(112,96));tilt.alpha_composite(upper,(24,16));tilt=tilt.rotate(-14,Image.Resampling.NEAREST,center=(56,81));body.alpha_composite(tilt)
 save(body,f'tree_cut/{name}_near_fall_body.png','Optional full-body pre-fall pose derived from adopted pixels. REPLACES standing tree; do not overlay both. Root stays fixed.',anchor=(56,88),layer='resource_node',occupied=(1,1),visual_state='near_fall',cut_pivot_px=[56,81],rotation_degrees=-14)

# Existing minimal FX, with exact times copied from source contracts.
fxmeta=json.loads((P/'art_delivery/effects_v1/manifest.json').read_text(encoding='utf-8'))
for action,role in [('stone_powder','fx_mining.powder'),('soil_dust','fx_mining.dust'),('wood_chips','fx_logging.chips'),('attack_hit','fx_mining.small_hit')]:
 for a in fxmeta['assets']:
  if a['action']!=action:continue
  reference(P/'art_delivery/effects_v1'/a['file'],role,a['anchor_px'],frame_index=a['frame_index'],duration_ms=a['frame_duration_ms'],animation=role)
for a in json.loads((V/'manifest.json').read_text(encoding='utf-8'))['assets']:
 if a.get('animation') in ['mining_chips','falling_leaves']:reference(V/a['file'],'fx_'+a['animation'],a['anchor_px'],frame_index=a['frame_index'],duration_ms=a['duration_ms'],animation=a['animation'])
for name in ['stone','wood']:reference(P/f'art_delivery/resource_icons_v1/hud24/{name}.png','resource_drop.'+name,[12,12])
meta={'schema_version':1,'date':'2026-10-12','branch':'codex/sporehollow-art-assets','tile_size_px':[48,42],'assets':records,'reuse':reuse,'node_states':states,'state_order':['intact','damaged_1','damaged_2','near_depleted','rubble'],'runtime_verified':False,'rendering':{'format':'RGBA','filter':'nearest','color_key':False},'state_contract':'Visual names only, never new progress/HP/damage/yield/respawn/movement rules.'}
(D/'manifest.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');(S/'extraction.json').write_text(json.dumps(extraction,indent=2)+'\n');print(len(records),'new PNGs;',len(reuse),'reuse references')
