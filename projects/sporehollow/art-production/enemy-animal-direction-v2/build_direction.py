from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps, ImageFilter
import numpy as np, json, hashlib, math
ROOT=Path(__file__).resolve().parents[2]
SRC=Path(__file__).resolve().parent
OUT=ROOT/'art_delivery/enemy_animal_direction_v2'
for folder in ['preview','motion_storyboards','equipment','pose_drafts','concept_parts']: (OUT/folder).mkdir(parents=True,exist_ok=True)
FONT=Path('C:/Windows/Fonts/meiryo.ttc')
def font(sz): return ImageFont.truetype(str(FONT),sz)
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
SPECS={
'salaryman':([4,2],7,40,[48,56],[24,50]),
'destroyer':([4,2],6,46,[80,72],[32,64]),
'martial_artist':([4,2],7,42,[64,56],[24,50]),
'ninja':([4,2],6,34,[64,56],[32,50]),
'tamer':([4,2],6,41,[64,56],[24,50]),
'runner':([4,2],6,42,[64,56],[32,50]),
'doberman':([2,2],4,33,[64,48],[32,44]),
'bullfrog':([4,2],6,26,[64,48],[32,44]),
'hedgehog':([3,2],6,18,[32,32],[16,28])}
NAMES={'salaryman':'サラリーマン','destroyer':'デストロイヤー','martial_artist':'武闘家','ninja':'忍者','tamer':'ムッツゴロウ（仮）','runner':'ランナー','doberman':'ドーベルマン','bullfrog':'ウシガエル','hedgehog':'ハリネズミ'}
def component_cut(im, main_only=False):
 a=np.array(im); mask=a[:,:,3]>200
 h,w=mask.shape; seen=np.zeros((h,w),bool); comps=[]
 for sy,sx in zip(*np.where(mask)):
  if seen[sy,sx]: continue
  stack=[(int(sx),int(sy))]; seen[sy,sx]=True; pts=[]
  while stack:
   x,y=stack.pop(); pts.append((x,y))
   for dx,dy in [(-1,0),(1,0),(0,-1),(0,1),(-1,-1),(1,-1),(-1,1),(1,1)]:
    xx,yy=x+dx,y+dy
    if 0<=xx<w and 0<=yy<h and mask[yy,xx] and not seen[yy,xx]:
     seen[yy,xx]=True; stack.append((xx,yy))
  if len(pts)>6: comps.append(pts)
 if not comps: raise ValueError('empty cell')
 comps.sort(key=len,reverse=True); main=comps[0]; xs,ys=zip(*main); bb=[min(xs),min(ys),max(xs)+1,max(ys)+1]
 keep=np.zeros_like(mask)
 for pts in (comps[:1] if main_only else comps):
  xx,yy=zip(*pts); cx=sum(xx)/len(xx); cy=sum(yy)/len(yy)
  if len(pts)>=len(main)*.004 and bb[0]-24<=cx<=bb[2]+24 and bb[1]-24<=cy<=bb[3]+24:
   keep[yy,xx]=True
 a[:,:,3]=np.where(keep,255,0)
 a[~keep,:3]=0
 im=Image.fromarray(a)
 return im.crop(im.getbbox())
def extract(name,index):
 im=Image.open(SRC/'originals'/f'{name}.png').convert('RGBA')
 cols,rows=SPECS[name][0]
 cw,ch=im.width/cols,im.height/rows
 col,row=index%cols,index//cols
 box=[round(col*cw),round(row*ch),round((col+1)*cw),round((row+1)*ch)]
 if name=='destroyer' and index in [1,4]: box[2]+=100
 return component_cut(im.crop(box), main_only=(name in ['bullfrog','hedgehog']))
def native(raw,scale,pal=None):
 wh=(max(1,round(raw.width*scale)),max(1,round(raw.height*scale)))
 # Coverage resampling followed by a limited shared palette, binary alpha,
 # a single native-pixel contour and explicit feature repairs below.
 small=raw.resize(wh,Image.Resampling.BOX)
 ar=np.array(small); mask=ar[:,:,3]>=125
 rgb=Image.fromarray(ar[:,:,:3])
 if pal is None: rgb=rgb.quantize(colors=24,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGB')
 else: rgb=rgb.quantize(palette=pal,dither=Image.Dither.NONE).convert('RGB')
 ar[:,:,:3]=np.array(rgb); ar[:,:,3]=mask*255
 padded=np.pad(mask,1)
 inner=padded[1:-1,:-2]&padded[1:-1,2:]&padded[:-2,1:-1]&padded[2:,1:-1]
 edge=mask&~inner
 ar[edge,:3]=[57,37,26]
 ar[~mask,:3]=0
 return Image.fromarray(ar)
poses={}; records=[]; char_meta={}
for name,(grid,count,height,canvas,anchor) in SPECS.items():
 raws=[extract(name,i) for i in range(count)]
 scale=height/raws[0].height
 # One palette and scale for all poses of the same character.
 palstrip=Image.new('RGB',(sum(r.width for r in raws),max(r.height for r in raws)),(57,37,26))
 px=0
 for raw in raws:
  palstrip.paste(raw.convert('RGB'),(px,0)); px+=raw.width
 pal=palstrip.quantize(colors=24,dither=Image.Dither.NONE)
 arr=[]
 for i,raw in enumerate(raws):
  p=native(raw,scale,pal)
  a=np.array(p)[:,:,3]; ys,xs=np.where(a>0)
  # Foot/paw support span, excluding arm and head motion from centering.
  low=ys>=p.height-max(2,round(3))
  foot_center=int(round((int(xs[low].min())+int(xs[low].max())+1)/2))
  if name=='doberman': foot_center=round(p.width*.50)
  if name=='bullfrog': foot_center=round(p.width*.48)
  if name=='hedgehog': foot_center=p.width//2
  x=anchor[0]-foot_center; y=anchor[1]-p.height
  if x<0 or x+p.width>canvas[0] or y<0: raise ValueError((name,i,p.size,(x,y),canvas))
  if name=='destroyer' and i==3:
   # Boot soles are 2px above the fist in the source; align feet, not lowest hand.
   x+=6; y+=2
  frame=Image.new('RGBA',canvas); frame.alpha_composite(p,(x,y))
  if name=='salaryman':
   d=ImageDraw.Draw(frame)
   if i in [0,2,3,5]:
    aa=np.array(frame)[:,:,3]; yy,xx=np.where(aa>0); top=int(yy.min())
    sel=yy<top+4; l=int(xx[sel].min())+1; r=int(xx[sel].max())-1
    d.rectangle((l,top,r,top+2),fill=(67,57,52,255))
    d.line((l,top,r,top),fill=(57,37,26,255))
   if i in [2,5]:
    d.rectangle((35,25,40,32),fill=(0,0,0,0))
    d.rectangle((36,26,38,31),fill=(37,46,57,255))
    d.line((37,27,37,29),fill=(164,188,171,255))
    d.point((35,31),fill=(216,156,107,255))
   elif i==3:
    d.rectangle((31,26,33,31),fill=(37,46,57,255))
    d.line((32,27,32,29),fill=(164,188,171,255))
    d.point((31,31),fill=(216,156,107,255))
   elif i==4:
    d.rectangle((18,22,20,27),fill=(37,46,57,255))
    d.line((18,23,18,25),fill=(164,188,171,255))
    d.point((20,27),fill=(216,156,107,255))
  path=OUT/'pose_drafts'/name/f'key_{i:02}.png'; path.parent.mkdir(exist_ok=True)
  frame.save(path); arr.append(frame)
  records.append({'file':path.relative_to(OUT).as_posix(),'character':name,'key_pose':i,'canvas':canvas,'anchor':anchor,'body_bbox':list(frame.getbbox()),'body_height_px':frame.getbbox()[3]-frame.getbbox()[1],'source_cell':i,'frame_duration_ms':None,'loop':False,'status':'direction_review_only','sha256':sha(path)})
 poses[name]=arr
 char_meta[name]={'name_ja':NAMES[name],'canvas':canvas,'anchor':anchor,'standing_body_height_px':arr[0].getbbox()[3]-arr[0].getbbox()[1],'standing_body_width_px':arr[0].getbbox()[2]-arr[0].getbbox()[0],'shared_source_scale':scale,'key_pose_count':count}
 print(name, [(r.width,r.height) for r in raws], [a.getbbox() for a in arr],flush=True)
# Left-facing standing Doberman, same canvas and foot anchor.
left=ImageOps.mirror(poses['doberman'][0]); left.save(OUT/'pose_drafts/doberman/stand_left.png')
# Source-derived independent weapon pieces.
parts={}
for name,idx,key,size in [('destroyer',6,'iron_ball',(12,14)),('destroyer',7,'chain_source',(14,14)),('ninja',6,'shuriken',(7,7)),('ninja',7,'dagger',(14,5)),('bullfrog',6,'tongue_body',(8,3)),('bullfrog',7,'tongue_tip',(5,5))]:
 raw=extract(name,idx); factor=min(size[0]/raw.width,size[1]/raw.height); p=native(raw,factor)
 if key=='tongue_body':
  # Tileable square-cut 8x3 strip, no end caps inside a stretched tongue.
  p=Image.new('RGBA',(8,3)); d=ImageDraw.Draw(p)
  d.rectangle((0,0,7,2),fill=(113,54,48,255));d.line((0,1,7,1),fill=(215,126,116,255))
 p.save(OUT/'concept_parts'/f'{key}.png'); parts[key]=p
(OUT/'pose-data.json').write_text(json.dumps({'characters':char_meta,'poses':records},ensure_ascii=False,indent=2),encoding='utf-8')
# Contact sheet used for checking before review layouts.
debug=Image.new('RGB',(1200,9*250),(224,211,171)); d=ImageDraw.Draw(debug)
for row,(name,arr) in enumerate(poses.items()):
 d.text((10,row*250+5),name,font=font(16),fill='#39291e')
 for i,im in enumerate(arr):
  im=im.resize((im.width*3,im.height*3),Image.Resampling.NEAREST)
  debug.paste(im,(10+i*165,row*250+28),im)
debug.save(SRC/'native-contact.png')


