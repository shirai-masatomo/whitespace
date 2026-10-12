from pathlib import Path
from PIL import Image,ImageDraw,ImageChops,ImageFont
import numpy as np,json,hashlib,subprocess
S=Path(__file__).resolve().parent;P=S.parents[1];D=P/'art_delivery/biome_environment_v1';BASE=P/'art_delivery/ui_world_direction_v1/candidates/world';src=Image.open(S/'originals/ground_stumps.png').convert('RGBA');W,H=src.size
colors=['#3d3023','#53412c','#6a5035','#805f3b','#96754b','#af8f5e','#c6a576','#d8bd90','#e5cda3','#53633d','#6b7c44','#87905a']
pal=np.array([tuple(bytes.fromhex(c[1:])) for c in colors],dtype=np.int32)
def im(p):return Image.open(p).convert('RGBA')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def quant(a):
 ar=np.array(a);v=ar[:,:,:3].astype(np.int32);ix=((v[:,:,None,:]-pal)**2).sum(3).argmin(2);ar[:,:,:3]=pal[ix];ar[:,:,3]=np.where(ar[:,:,3]>=160,255,0);ar[ar[:,:,3]==0]=0;return Image.fromarray(ar)
records=[];reuse=[];proof={}
def save(a,path,usage,anchor=[32,72],layer='tree_difference',occupied=[0,0],**kw):
 f=D/path;f.parent.mkdir(parents=True,exist_ok=True);a.save(f);records.append({'file':path,'size_px':list(a.size),'anchor_px':anchor,'occupied_cells':occupied,'usage':usage,'layer':layer,'frame_index':0,'duration_ms':None,'loop':False,'ground_shadow':False,'sha256':sha(f),**kw});return a
review=Image.new('RGBA',(1050,820),'#71884f');dr=ImageDraw.Draw(review);font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',16)
for i,t in enumerate('abc'):
 orig=im(BASE/f'tree_{t}.png');trunk=im(BASE/f'tree_{t}_trunk.png');canopy=im(BASE/f'tree_{t}_canopy.png');joined=trunk.copy();joined.alpha_composite(canopy);assert np.array_equal(np.array(orig),np.array(joined)),t
 proof[t]={'split_matches_original':True,'foot_anchor_px':[32,72],'suggested_cut_pivot_px':[32,65]}
 for suffix in ['', '_trunk','_canopy']:
  f=BASE/f'tree_{t}{suffix}.png';rp=str(f.relative_to(P)).replace('\\','/');remote=subprocess.check_output(['git','show','origin/codex/sporehollow-biome01:projects/sporehollow/'+rp]);assert hashlib.sha256(remote).hexdigest()==sha(f)
  reuse.append({'role':f'tree_{t}{suffix}','file':'../'+str(f.relative_to(P/'art_delivery')).replace('\\','/'),'size_px':[64,80],'anchor_px':[32,72],'occupied_cells':[1,1],'sha256':sha(f),'frame_index':0,'duration_ms':None,'loop':False,'usage':'Reuse unchanged adopted tree; shared foot for trunk/canopy. Runtime TREE_SCALE=1.35 in reference branch.'})
 a=src.crop([(70,845,455,1135),(555,870,840,1130),(995,890,1195,1130)][i]);a.putalpha(a.getchannel('A').point(lambda v:255 if v>=180 else 0));a=a.crop(a.getbbox());a.thumbnail([(24,18),(18,15),(11,12)][i],Image.Resampling.LANCZOS);a=quant(a);stump=Image.new('RGBA',(64,80));stump.alpha_composite(a,(32-a.width//2,72-a.height));save(stump,f'forest/stump_{t}.png','Cut stump aligned to existing tree foot. No new permanent obstacle or resource.',visual_state='after_felling')
 notches=[]
 for j,level in enumerate(['light','deep']):
  cut=Image.new('RGBA',(64,80));d=ImageDraw.Draw(cut);x=[29,30,31][i];width=[5,4,2][i];y=65
  d.polygon([(x,y-1),(x+width+j,y+1),(x,y+2+j)],fill='#3d3023');d.line([(x,y),(x+width-1+j,y+1)],fill='#d8bd90')
  cut.putalpha(ImageChops.multiply(cut.getchannel('A'),trunk.getchannel('A')));ar=np.array(cut);ar[ar[:,:,3]==0]=0;cut=Image.fromarray(ar);save(cut,f'forest/notch_{t}_{level}.png','Alpha clipped to adopted trunk; state choice comes from existing chop progress. Composite over trunk.',layer='trunk_overlay');notches.append(cut)
 x0=24;y0=40+i*255;dr.text((x0,y0-24),f'Tree {t}: adopted / cut overlay / stump / runtime scale 1.35',font=font,fill='white')
 for k,ob in enumerate([orig,orig.copy(),stump]):
  if k==1:ob.alpha_composite(notches[1])
  review.alpha_composite(ob.resize((192,240),Image.Resampling.NEAREST),(x0+k*230,y0))
 runtime=orig.resize((86,108),Image.Resampling.NEAREST);review.alpha_composite(runtime,(800,y0+100));review.alpha_composite(stump.resize((86,108),Image.Resampling.NEAREST),(906,y0+100))
# Small scattered leaf fragments, no full canopy redraw.
for frame in range(3):
 a=Image.new('RGBA',(32,32));dd=ImageDraw.Draw(a)
 for i,(x,y) in enumerate([(7,8),(18,4),(23,11),(12,17)]):
  x+=(-1 if i%2 else 1)*frame;y+=frame*3;col=[(129,143,79),(155,155,86),(98,119,65)][i%3];alpha=255-frame*65;dd.line([(x,y),(x+2,y+1)],fill=(*col,alpha),width=1);dd.point((x+1,y+1),fill=(*col,alpha))
 save(a,f'forest/leaves_{frame:02}.png','Small leaf fragments driven by felling event; not a new resource.',anchor=[16,26],layer='fx',frame_index=frame,duration_ms=[100,120,160][frame],animation='falling_leaves')
for role,path,an in [('wood_drop','resource_icons_v1/hud24/wood.png',[12,12]),('wood_chips','effects_v1/wood_chips',[16,26])]:
 f=P/'art_delivery'/path;fs=sorted(f.glob('*.png')) if f.is_dir() else [f]
 for j,ff in enumerate(fs):reuse.append({'role':role,'file':'../'+str(ff.relative_to(P/'art_delivery')).replace('\\','/'),'size_px':list(im(ff).size),'anchor_px':an,'sha256':sha(ff),'frame_index':j,'loop':False,'timing_source':'../effects_v1/manifest.json' if f.is_dir() else None,'usage':'Reuse original wood bundle or wood chips unchanged.'})
review.save(D/'review/forest_differences.png');(D/'forest_manifest.json').write_text(json.dumps({'stage':'forest','assets':records,'reuse':reuse,'trees':proof,'runtime_verified':False},ensure_ascii=False,indent=2)+'\n',encoding='utf-8');print('Forest:',len(records),'new PNGs;',len(reuse),'reused refs; exact tree split confirmed.')
