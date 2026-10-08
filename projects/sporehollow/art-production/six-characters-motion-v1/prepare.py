from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import numpy as np,json
S=Path(__file__).parent;P=S.parents[1];R=P/'art_delivery/two_direction_review_v1';N=S/'native';N.mkdir(exist_ok=True)
settings={'merchant_walk':('merchant',4,2,42,(48,48),(24,44)),'maid_locomotion':('maid',8,4,42,(64,64),(32,58)),'maid_actions':('maid',8,4,42,(64,64),(32,58)),'dancer_motion':('dancer',8,4,42,(64,64),(32,58)),'thief_motion':('thief',8,4,42,(64,64),(32,58)),'thief_recovery':('thief',4,2,42,(64,64),(32,58)),'cow_motion':('cow',8,4,48,(80,64),(40,58)),'bull_motion':('bull',8,4,40,(80,64),(40,58))}
def parts(im,count,cols):
 ar=np.array(im);on=ar[:,:,3]>=200;seen=np.zeros(on.shape,bool);h,w=on.shape;gs=[]
 for y,x in zip(*np.where(on)):
  if seen[y,x]:continue
  seen[y,x]=True;q=[(int(x),int(y))];pts=[]
  while q:
   xx,yy=q.pop();pts.append((xx,yy))
   for nx,ny in [(xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)]:
    if 0<=nx<w and 0<=ny<h and on[ny,nx] and not seen[ny,nx]:seen[ny,nx]=1;q.append((nx,ny))
  if len(pts)>1500:gs.append(pts)
 gs=sorted(gs,key=len,reverse=True)[:count];res=[]
 assert len(gs)==count,(len(gs),count)
 for pts in gs:
  xs,ys=zip(*pts);b=(min(xs),min(ys),max(xs)+1,max(ys)+1);mask=np.zeros(on.shape,np.uint8);mask[np.array(ys),np.array(xs)]=255
  a=im.copy();a.putalpha(Image.fromarray(mask));a=a.crop(b);res.append((b,a))
 # Each row shares foot baseline even for fallen/crouched poses.
 res.sort(key=lambda z:z[0][3]);out=[]
 for r in range(count//cols):out+=sorted(res[r*cols:(r+1)*cols],key=lambda z:z[0][0])
 return out

def palette(who):
 chunks=[]
 for f in (R/'native'/who).glob('*.png'):
  if who=='merchant' and 'cart' in f.name:continue
  a=np.array(Image.open(f).convert('RGBA'));chunks.append(a[a[:,:,3]>0][:,:3])
 ar=np.concatenate(chunks,axis=0);im=Image.fromarray(ar.reshape((1,-1,3)));return im.quantize(colors=48,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)

def quant(im,pal):
 alpha=im.getchannel('A');rgb=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');rgb.putalpha(alpha)
 a=np.array(rgb);on=a[:,:,3]>0;nei=np.zeros(on.shape,np.uint8)
 nei[1:]+=on[:-1];nei[:-1]+=on[1:];nei[:,1:]+=on[:,:-1];nei[:,:-1]+=on[:,1:]
 a[(nei==0)&on,3]=0;a[a[:,:,3]==0,:3]=0
 return Image.fromarray(a)
meta={}
for key,(who,count,cols,height,cs,an) in settings.items():
 path=S/'originals'/f'{key}.png';im=Image.open(path).convert('RGBA');pp=parts(im,count,cols);pal=palette(who)
 # One source scale from standing/walking references, never force bent/fallen frames to standing height.
 base=np.median([ob.height for _,ob in pp[:4 if count==8 and key!='maid_actions' else 1]])
 scale=height/base
 frames=[]
 for i,(box,ob) in enumerate(pp):
  size=(round(ob.width*scale),round(ob.height*scale))
  assert size[0]<=cs[0] and size[1]<=an[1],(key,i,size,cs)
  ni=quant(ob.resize(size,Image.Resampling.NEAREST),pal);out=Image.new('RGBA',cs)
  x=an[0]-ni.width//2;y=an[1]-ni.height
  out.alpha_composite(ni,(x,y));out.save(N/f'{key}_{i:02}.png')
  frames.append({'index':i,'source_bbox':box,'scale':scale,'placed_xy':[x,y],'visible_bbox':out.getbbox(),'canvas':list(cs),'anchor':list(an)})
 meta[key]=frames;print(key,[f['visible_bbox'] for f in frames],flush=True)
(S/'native-processing.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')
# Expanded native inspection with coordinate grid at 1px = 6px.
rows=len(settings);out=Image.new('RGB',(1360,rows*430),'#252d29');d=ImageDraw.Draw(out);font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',16)
for r,(key,(_,count,_,_,cs,an)) in enumerate(settings.items()):
 d.text((5,r*430),key,font=font,fill='#ffffff')
 for i in range(count):
  im=Image.open(N/f'{key}_{i:02}.png').convert('RGBA');z=3;x=10+i*168;y=r*430+30
  out.paste(im.resize((cs[0]*z,cs[1]*z),Image.Resampling.NEAREST),(x,y),im.resize((cs[0]*z,cs[1]*z),Image.Resampling.NEAREST))
  d.text((x,y+cs[1]*z+3),str(i),font=font,fill='white')
out.save(S/'native-inspection.png')
