from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import numpy as np,json
SRC=Path(__file__).resolve().parent; ROOT=SRC.parents[1]; BASE=ROOT/'art_delivery/enemy_animal_direction_v3/pose_drafts/salaryman'
keys=[Image.open(BASE/f'key_{i:02}.png').convert('RGBA') for i in range(7)]
raw=Image.open(SRC/'originals/motion-sheet.png').convert('RGBA'); cols,rows=4,2
palette=np.unique(np.concatenate([np.array(im).reshape(-1,4) for im in keys]),axis=0);palette=palette[palette[:,3]==255,:3]
raws=[]
for i in range(8):
 c=raw.crop((round(i%4*raw.width/4),round(i//4*raw.height/2),round((i%4+1)*raw.width/4),round((i//4+1)*raw.height/2)))
 ar=np.array(c);ar[:,:,3]=np.where(ar[:,:,3]>200,255,0); ar[ar[:,:,3]==0,:3]=0;c=Image.fromarray(ar);raws.append(c.crop(c.getbbox()))
scale=40/raws[0].height
frames=[]
for i,c in enumerate(raws):
 wh=(round(c.width*scale),round(c.height*scale));small=c.resize(wh,Image.Resampling.BOX);ar=np.array(small);mask=ar[:,:,3]>=128
 diff=ar[:,:,:3].astype(np.int32)[:,:,None,:]-palette.astype(np.int32)[None,None,:,:]
 ar[:,:,:3]=palette[np.argmin(np.sum(diff**2,axis=3),axis=2)];ar[:,:,3]=mask*255;ar[~mask,:3]=0
 # Use approved palette and one-pixel silhouette; preserve white opaque glasses.
 pad=np.pad(mask,1);inside=pad[1:-1,:-2]&pad[1:-1,2:]&pad[:-2,1:-1]&pad[2:,1:-1]
 ar[mask&~inside,:3]=[57,37,26]
 small=Image.fromarray(ar)
 # Head x determines body alignment, independent of swinging hands/feet.
 a=np.array(small)[:,:,3]; yy,xx=np.where(a>0);sel=yy<4;center=(xx[sel].min()+xx[sel].max()+1)/2
 idlearr=np.array(keys[0])[:,:,3];yi,xi=np.where(idlearr>0);si=yi<14;refcenter=(xi[si].min()+xi[si].max()+1)/2
 x=round(refcenter-center);y=50-small.height
 frame=Image.new('RGBA',(48,56));frame.alpha_composite(small,(x,y))
 # Reuse the adopted head, not the generated reinterpretation.
 dx,dy=([(0,0)]*4+[(-2,1),(-1,0),(1,1),(1,1)])[i]
 fa=np.array(frame);fa[:27+dy,:,:]=0;frame=Image.fromarray(fa)
 frame.alpha_composite(keys[0].crop((0,0,48,27)),(dx,dy))
 frames.append(frame)
(SRC/'native').mkdir(exist_ok=True)
for i,im in enumerate(frames):im.save(SRC/'native'/f'motion_{i:02}.png')
board=Image.new('RGB',(1200,650),'#e9dfc0');d=ImageDraw.Draw(board);f=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',18)
for i,im in enumerate([keys[0]]+frames):
 x=(i%5)*240;y=(i//5)*300;d.text((x+8,y+8),'adopted idle' if i==0 else str(i-1),font=f,fill='#30251d');board.paste(im.resize((192,224),Image.Resampling.NEAREST),(x+16,y+36),im.resize((192,224),Image.Resampling.NEAREST));d.line((x+8,y+236,x+232,y+236),fill='#bd8b45')
board.save(SRC/'native-review.png')
print('Raw dims',raw.size,'scale',scale,'native bboxes',[im.getbbox() for im in frames])
