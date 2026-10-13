from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps
import numpy as np, json, hashlib, shutil
P=Path(__file__).resolve().parents[2]
ROOT=Path(__file__).resolve().parent
OUT=P/'art_delivery/colony_growth_previews_v2'
C=ROOT/'working';C.mkdir(exist_ok=True)
N=Image.Resampling.NEAREST
meta={}
def load(n):return Image.open(ROOT/'originals'/f'{n}.png').convert('RGBA')
def clean(im,colors=20):
 a=im.getchannel('A').point(lambda v:255 if v>=128 else 0)
 rgb=im.convert('RGB').quantize(colors=colors,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGBA');rgb.putalpha(a)
 arr=np.array(rgb);arr[arr[:,:,3]==0]=0;return Image.fromarray(arr)
def bbox(im):return im.getchannel('A').point(lambda v:255 if v>=128 else 0).getbbox()
def save(n,im,anchor,desc):
 im.save(C/f'{n}.png');meta[n]={'canvas':im.size,'anchor':anchor,'description':desc,'preview_only':True,'runtime_ready':False,'sha256':hashlib.sha256((C/f'{n}.png').read_bytes()).hexdigest()}
def fit(n,wh,canvas,anchor):
 im=load(n);im=im.crop(bbox(im));s=min(wh[0]/im.width,wh[1]/im.height);im=clean(im.resize((round(im.width*s),round(im.height*s)),N))
 out=Image.new('RGBA',canvas);out.alpha_composite(im,(anchor[0]-im.width//2,anchor[1]-im.height));save(n,out,anchor,'generated concept normalized for comparison; not adopted')
for n,wh,cv,an in [('radio_a',(32,28),(40,36),(20,32)),('radio_b',(32,28),(40,36),(20,32)),('father_journal',(27,32),(40,40),(20,36)),('father_letter',(30,28),(40,36),(20,32)),('bed_a',(38,66),(48,84),(24,78)),('bed_b',(42,70),(48,84),(24,78)),('event_crate',(32,30),(48,42),(24,38)),('watch_a',(32,42),(48,56),(24,50)),('watch_b',(42,38),(48,56),(24,50))]:
 if (ROOT/'originals'/f'{n}.png').exists():fit(n,wh,cv,an)
# Restore characteristic large knobs / speaker blocks at native size, no cream color-key.
for n in ['radio_a','radio_b']:
 if not (C/f'{n}.png').exists():continue
 im=Image.open(C/f'{n}.png').convert('RGBA');d=ImageDraw.Draw(im)
 # simplify the highly detailed source grille to horizontal bands at game resolution
 if n=='radio_a':
  for y in [16,19,22,25]:d.line((8,y,17,y+1),fill='#b49d73',width=1)
  d.rectangle((23,23,25,25),fill='#b49556');d.rectangle((28,25,30,27),fill='#b49556')
 save(n,im,(20,32),'preview native retouch: speaker and knobs simplified')
# Make the found-crate tag readable at 1x, retaining cream paper.
if (C/'event_crate.png').exists():
 im=Image.open(C/'event_crate.png').convert('RGBA');d=ImageDraw.Draw(im);d.polygon([(34,25),(38,26),(37,33),(33,32)],fill='#ddcda5',outline='#725338');save('event_crate',im,(24,38),'preview retouch: blank tag made readable at 1x')
# Two standing views of each proposed resident, fit body height exactly 42px.
for n in ['resident_a','resident_b']:
 if not (ROOT/'originals'/f'{n}.png').exists():continue
 src=load(n)
 for i,direction in enumerate(['front','right']):
  im=src.crop((i*src.width//2,0,(i+1)*src.width//2,src.height));im=im.crop(bbox(im));im=clean(im.resize((round(im.width*42/im.height),42),N),18)
  out=Image.new('RGBA',(40,48));out.alpha_composite(im,(20-im.width//2,2));save(n+'_'+direction,out,(20,44),'proposed adult; standing review only')
# Crop five equal source cells. Same earth width and baseline through growth stages.
if (ROOT/'originals/crop.png').exists():
 src=load('crop')
 for i in range(5):
  im=src.crop((i*src.width//5,0,(i+1)*src.width//5,src.height));im=im.crop(bbox(im));s=40/im.width;im=clean(im.resize((40,round(im.height*s)),N),14)
  out=Image.new('RGBA',(48,42));out.alpha_composite(im,(4,40-im.height));save(f'crop_{i}',out,(24,40),'one tentative root crop; visual step, not new logical state')
# Work poses: preserve original face/hat pixels and registered ground contact.
keeper=Image.open(P/'art_delivery/characters_v1/keeper_idle_right_00.png').convert('RGBA')
for n in ['keeper_mining','keeper_logging']:
 if not (ROOT/'originals'/f'{n}.png').exists():continue
 src=load(n)
 for i in [1]:
  half=src.crop((i*src.width//2,0,(i+1)*src.width//2,src.height));bb=bbox(half)
  hat_y=(118 if n=='keeper_mining' else 102) if i==0 else (132 if n=='keeper_mining' else 122)
  # Source is 1760x880; body height measured from hat crest, tool excluded.
  factor=42/(bb[3]-hat_y)
  im=clean(half.resize((round(half.width*factor),round(half.height*factor)),N),20)
  arr=np.array(im);ys,xs=np.where(arr[:,:,3]>128);base=int(ys.max())+1
  feet=np.where((arr[:,:,3]>128)&(np.indices(arr.shape[:2])[0]>=base-5))[1]
  bodyx=int(round((feet.min()+feet.max())/2))
  out=Image.new('RGBA',(80,64));out.alpha_composite(im,(28-bodyx,56-base))
  draw=ImageDraw.Draw(out);draw.rectangle((8,11,48,33),fill=(0,0,0,0))
  out.alpha_composite(keeper.crop((0,0,32,22)),(12,12))
  save(f'{n}_{i}_right',out,(28,56),'42px body; adopted keeper head preserved; two key poses only')
  save(f'{n}_{i}_left',ImageOps.mirror(out),(52,56),'mirrored preview; asymmetry and contact require formal integration review')
(ROOT/'working_manifest.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
# Enlarged internal review for all normalized candidates.
keys=list(meta);sheet=Image.new('RGBA',(800,((len(keys)+5)//6)*220),(49,65,54,255));d=ImageDraw.Draw(sheet);f=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',11)
for i,n in enumerate(keys):
 im=Image.open(C/f'{n}.png');im=im.resize((im.width*2,im.height*2),N);x=(i%6)*133;y=(i//6)*220;sheet.alpha_composite(im,(x,y+24));d.text((x,y),n,font=f,fill='white')
sheet.convert('RGB').save(ROOT/'working_contact_sheet.png')
print('preview candidates',len(meta))
