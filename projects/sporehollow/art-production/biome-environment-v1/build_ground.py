from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import numpy as np,json,hashlib
S=Path(__file__).resolve().parent;P=S.parents[1];D=P/'art_delivery/biome_environment_v1';src=Image.open(S/'originals/ground_stumps.png').convert('RGBA');W,H=src.size
COLORS=['#4d653d','#607844','#71864d','#829654','#98a565','#b1b77a','#837651','#968760','#a7996f','#b7aa7e','#cec29c','#6c6c59','#92917a','#b4af95','#e4dcc0','#f2e5c5']
pal=np.array([tuple(bytes.fromhex(c[1:])) for c in COLORS],dtype=np.int32)
def master(i,wh):
 boxes=[(95,110,470,360),(550,165,770,350),(930,170,1210,350),(110,565,405,765),(520,510,810,760),(920,550,1230,760)]
 a=src.crop(boxes[i]);a.putalpha(a.getchannel('A').point(lambda v:255 if v>=180 else 0));a=a.crop(a.getbbox());a.thumbnail(wh,Image.Resampling.LANCZOS);ar=np.array(a);v=ar[:,:,:3].astype(np.int32);ix=((v[:,:,None,:]-pal)**2).sum(3).argmin(2);ar[:,:,:3]=pal[ix];ar[:,:,3]=np.where(ar[:,:,3]>=150,255,0);ar[ar[:,:,3]==0]=0;return Image.fromarray(ar)
rec=[]
def save(a,path,anchor,usage,layer='ground',**kw):
 f=D/path;f.parent.mkdir(parents=True,exist_ok=True);a.save(f);rec.append({'file':path,'size_px':list(a.size),'anchor_px':anchor,'occupied_cells':[0,0],'usage':usage,'layer':layer,'frame_index':0,'duration_ms':None,'loop':False,'ground_shadow':False,'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),**kw});return a
def patch(a):
 o=Image.new('RGBA',(48,42));o.alpha_composite(a,((48-a.width)//2,(42-a.height)//2));return o
soil=master(0,(30,20));soil.putalpha(soil.getchannel('A').point(lambda v:144 if v else 0));save(patch(soil),'ground/dry/soil_spot.png',[24,21],'Subtle144alpha dry soil spot over unchanged biome vertex color')
for v in range(2):
 a=Image.new('RGBA',(48,42));d=ImageDraw.Draw(a);pts=[(17,15),(20,18),(19,21),(23,23),(24,27)] if v==0 else [(16,23),(20,20),(24,21),(28,17)]
 d.line(pts,fill=(113,103,77,144));d.line([(pts[2][0],pts[2][1]),(26,24),(30,23)],fill=(113,103,77,144));save(a,f'ground/dry/cracks_{v:02}.png',[24,21],'Sparse fine dry cracks; no terrain type change')
for name,i,wh in [('short_grass',1,(12,9)),('grass_tuft',1,(16,13)),('gravel',2,(17,10))]:save(patch(master(i,wh)),f'ground/dry/{name}.png',[24,21],'Small dry grassland decoration, optional and nonblocking')
for name,i,wh in [('low_sparse',3,(12,9)),('low_dense',3,(19,12)),('tall_tuft',4,(17,18)),('flowers',5,(18,12))]:save(patch(master(i,wh)),f'ground/lush/{name}.png',[24,21],'Low irregular meadow plant; omit beneath jobs, drops or occupied cells')
# Ground cover is a few separated tufts, not a solid square of grass.
a=Image.new('RGBA',(48,42));tuft=master(3,(10,7))
for xy in [(5,7),(28,12),(17,28)]:a.alpha_composite(tuft,xy)
save(a,'ground/lush/cover_sparse.png',[24,21],'Three separated grass clumps with readable empty ground between')
# Boundary strips use a deterministic irregular distribution, no frame around cells.
for edge in ['n','e','s','w']:
 a=Image.new('RGBA',(48,42));soilsmall=master(0,(12,8));soilsmall.putalpha(soilsmall.getchannel('A').point(lambda v:112 if v else 0));g=master(3,(8,6))
 for i in range(4):
  if edge in ['n','s']:x=2+i*11;y=(1+i%3) if edge=='n' else (32+i%3)
  else:x=(1+i%2) if edge=='w' else (34+i%2);y=1+i*10
  a.alpha_composite(soilsmall,(x,y))
  if i%2==0:a.alpha_composite(g,(x+2,y+1))
 save(a,f'ground/boundary/{edge}.png',[24,21],'Optional grass/soil transition strip; assign to one side only; no perimeter outline')
(D/'ground_manifest.json').write_text(json.dumps({'stage':'ground','assets':rec,'reuse':[],'runtime_verified':False},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',14);review=Image.new('RGBA',(900,530),'#293d30');dr=ImageDraw.Draw(review)
for j,(title,bg,prefix) in enumerate([('Open: existing ground retained','#839955',None),('Dry: mild grassland','#9a9564','ground/dry'),('Lush: scattered, not carpet','#738b4e','ground/lush')]):
 x=j*300;dr.text((x+12,12),title,font=font,fill='white');pan=Image.new('RGBA',(288,420),bg)
 fs=[a['file'] for a in rec if prefix and a['file'].startswith(prefix)]
 if fs:
  for k in range(16):
   a=Image.open(D/fs[k%len(fs)]).convert('RGBA');px=8+(k*73)%232;py=12+(k*89)%354;pan.alpha_composite(a,(px,py))
 keeper=Image.open(P/'art_delivery/characters_v1/keeper_idle_right_00.png').convert('RGBA');pan.alpha_composite(keeper,(128,186));review.alpha_composite(pan,(x+6,40))
dr.text((12,488),'OFFLINE COMPOSITION / 1x / base colors retained / no runtime verification',font=font,fill='white');review.save(D/'review/ground_comparison.png')
print('Ground:',len(rec),'PNGs')
