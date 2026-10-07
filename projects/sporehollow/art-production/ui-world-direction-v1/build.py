from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
import json,hashlib,shutil,random
P=Path(__file__).resolve().parents[2]; S=Path(__file__).parent; D=P/'art_delivery/ui_world_direction_v1'
for sub in ['candidates/world','candidates/portraits','candidates/ui','candidates/new','storyboards','preview']: (D/sub).mkdir(parents=True,exist_ok=True)
def save_ref(id,path):
 im=Image.open(P/path).convert('RGBA'); im.resize((im.width*8,im.height*8),Image.Resampling.NEAREST).save(S/'references'/f'{id}.png')
for id,path in {'shiba':'art_delivery/characters_v1/shiba_idle_front_00.png','hen':'art_delivery/ranch_assets_v1/hen/idle_right_00.png','cat':'art_delivery/ranch_assets_v1/cat/idle_right_00.png','salaryman':'art_delivery/salaryman_motion_v1/idle/right_00.png','destroyer':'art_delivery/destroyer_motion_v1/idle/right_00.png','doberman':'art_delivery/doberman_motion_v1/idle/right_00.png'}.items():
 if (P/path).exists(): save_ref(id,path)
def native(im,canvas,anchor,extent):
 im=im.convert('RGBA'); a=im.getchannel('A').point(lambda v:255 if v>=160 else 0); im.putalpha(a); im=im.crop(a.getbbox())
 sc=min(extent[0]/im.width,extent[1]/im.height)
 im=im.resize((max(1,round(im.width*sc)),max(1,round(im.height*sc))),Image.Resampling.NEAREST)
 a=im.getchannel('A'); rgb=im.convert('RGB').quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGB'); im=rgb.convert('RGBA'); im.putalpha(a)
 # Remove isolated native pixels, preserve all white opaque parts; no color key.
 pix=im.load()
 for y in range(im.height):
  for x in range(im.width):
   if pix[x,y][3] and not any(0<=x+dx<im.width and 0<=y+dy<im.height and pix[x+dx,y+dy][3] for dx,dy in [(-1,0),(1,0),(0,-1),(0,1)]): pix[x,y]=(0,0,0,0)
 out=Image.new('RGBA',canvas);out.alpha_composite(im,(anchor[0]-im.width//2,anchor[1]-im.height));return out
def build_world():
 for id,canvas,anchor,ext in [('goldA',(144,160),(72,152),(132,144)),('goldB',(144,160),(72,152),(132,144)),('tree_a',(64,80),(32,72),(60,68)),('tree_b',(64,80),(32,72),(54,66)),('tree_c',(64,80),(32,72),(40,53))]:
  if (S/'originals'/f'{id}.png').exists(): native(Image.open(S/'originals'/f'{id}.png'),canvas,anchor,ext).save(D/'candidates/world'/f'{id}.png')
if __name__=='__main__':build_world()

