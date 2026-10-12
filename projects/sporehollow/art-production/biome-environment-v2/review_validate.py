from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageChops
import json,numpy as np,hashlib,math
S=Path(__file__).resolve().parent;P=S.parents[1];D=P/'art_delivery/biome_environment_v2';V=P/'art_delivery/biome_environment_v1';m=json.loads((D/'manifest.json').read_text(encoding='utf-8'))
def im(f):return Image.open(f).convert('RGBA')
def font(n=14):return ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',n)
# Full stages at native and3x on same foot line.
o=Image.new('RGBA',(1000,490),'#73874f');d=ImageDraw.Draw(o)
for r,name in enumerate(['small','medium','large']):
 y=25+r*150;d.text((8,y),name,font=font(),fill='white')
 for k,f in enumerate(m['node_states'][name]+['../biome_environment_v1/rock/ground/rubble.png']):
  a=im(D/f);x=100+k*175;an=[24,46] if k<4 else [24,32];o.alpha_composite(a,(x, y+80-an[1]));o.alpha_composite(a.resize((a.width*2,a.height*2),Image.Resampling.NEAREST),(x+45,y+115-an[1]*2));d.text((x,y+118),['intact','chipped','heavy','near depleted','rubble'][k],font=font(12),fill='white')
d.text((8,467),'OFFLINE / equal scale within each row / progress timings are NOT gameplay rules',font=font(13),fill='white');o.save(D/'review/node_states.png')
# 48x42 grid demo of grass to rock ground with isolated nodes and traces.
scene=Image.new('RGBA',(576,378),'#839955')
# Rounded, irregularly dressed rock patch, using actual edge and corner parts.
for y in range(8):
 for x in range(12):
  if x>=4 and not (6<=x<=10 and 2<=y<=5):
   a=im(D/'rock_transition/gravel/edge_e.png') if x==4 else im(D/'rock_ground/gravel.png');scene.alpha_composite(a,(x*48,y*42))
  key=None
  if 6<=x<=10 and 2<=y<=5:key='full'
  elif x==5 and 2<=y<=5:key='edge_e'
  elif x==11 and 2<=y<=5:key='edge_w'
  elif y==1 and 6<=x<=10:key='edge_s'
  elif y==6 and 6<=x<=10:key='edge_n'
  elif (x,y)==(5,1):key='outer_nw'
  elif (x,y)==(11,1):key='outer_ne'
  elif (x,y)==(5,6):key='outer_sw'
  elif (x,y)==(11,6):key='outer_se'
  if key:scene.alpha_composite(im(D/('rock_ground/bedrock.png' if key=='full' else 'rock_transition/bedrock/'+key+'.png')),(x*48,y*42))
for name,xy in [('small',(285,100)),('medium',(410,145)),('large',(490,240))]:
 a=im(D/f'rock_node/{name}/intact.png');scene.alpha_composite(im(D/f'rock_node/shadow_{name}.png'),(xy[0]-24,xy[1]-46));scene.alpha_composite(a,(xy[0]-24,xy[1]-46))
scene.alpha_composite(im(D/'rock_mined/shallow_scoop.png'),(315,250));scene.alpha_composite(im(V/'rock/ground/rubble.png'),(310,210));scene.alpha_composite(im(D/'rock_ground/grass_stone.png'),(228,270));scene.alpha_composite(im(V/'ground/lush/flowers.png'),(145,115));scene.alpha_composite(im(P/'art_delivery/characters_v1/keeper_idle_right_00.png'),(238,145));scene.alpha_composite(im(P/'art_delivery/characters_v1/shiba_idle_right_00.png'),(250,208))
o=Image.new('RGBA',(600,440),'#293d30');o.alpha_composite(scene,(12,40));ImageDraw.Draw(o).text((12,10),'OFFLINE COMPOSITION / native48x42 / no new map generation',font=font(),fill='white');o.save(D/'review/transition_scene.png')
# Connection/corner catalog, all named to avoid cardinal ambiguity.
rows=[a for a in m['assets'] if a['file'].startswith('rock_transition/')];o=Image.new('RGBA',(960,math.ceil(len(rows)/8)*138+30),'#839955');d=ImageDraw.Draw(o)
for i,a in enumerate(rows):
 x=i%8*120;y=30+i//8*138;ob=im(D/a['file']);o.alpha_composite(ob.resize((96,84),Image.Resampling.NEAREST),(x+10,y+30));d.text((x+2,y),a['file'].split('/')[-2],font=font(10),fill='white');d.text((x+2,y+14),Path(a['file']).stem,font=font(11),fill='white')
o.save(D/'review/transitions.png')
# All new assets on light/dark backgrounds. No color-key transparency.
assets=m['assets'];o=Image.new('RGBA',(960,math.ceil(len(assets)/6)*145+30),'#293d30');d=ImageDraw.Draw(o)
for i,a in enumerate(assets):
 x=i%6*160;y=30+i//6*145;ob=im(D/a['file']);d.text((x+2,y),Path(a['file']).stem,font=font(10),fill='white')
 for j,bg in enumerate(['#e6daba','#25392b']):
  panel=Image.new('RGBA',(78,112),bg);panel.alpha_composite(ob,((78-ob.width)//2,100-ob.height));o.alpha_composite(panel,(x+j*80,y+20))
o.save(D/'review/inventory_alpha.png')
# Progress GIF: static poses are selected for demonstration only.
frames=[]
for k in range(5):
 o=Image.new('RGBA',(640,250),'#839955');d=ImageDraw.Draw(o);d.text((12,10),'OFFLINE: visual states, no timing contract',font=font(16),fill='white')
 for j,name in enumerate(['small','medium','large']):
  a=im(D/(m['node_states'][name][k] if k<4 else '../biome_environment_v1/rock/ground/rubble.png'));o.alpha_composite(a.resize((a.width*3,a.height*3),Image.Resampling.NEAREST),(30+j*205,60 if k<4 else 93));d.text((30+j*205,225),name,font=font(),fill='white')
 frames.append(o.convert('RGB'))
frames[0].save(D/'review/mining_states.gif',save_all=True,append_images=frames[1:],duration=[650,450,450,450,900],loop=0,disposal=2)
# Verify body sizes, all hashes, monotonic visible volume and complete source preservation.
errors=[]
for a in m['assets']:
 f=D/a['file'];ob=Image.open(f)
 if ob.mode!='RGBA' or list(ob.size)!=a['size_px'] or not ob.getbbox() or hashlib.sha256(f.read_bytes()).hexdigest()!=a['sha256']:errors.append(a['file'])
for a in m['reuse']:
 if hashlib.sha256((D/a['file']).read_bytes()).hexdigest()!=a['sha256']:errors.append(a['file'])
areas={}
for name,fs in m['node_states'].items():
 areas[name]=[int(np.count_nonzero(np.array(im(D/f))[:,:,3])) for f in fs]
 if not all(a>b for a,b in zip(areas[name],areas[name][1:])):errors.append('volume:'+name)
 if not all(im(D/f).getbbox()[3]==46 for f in fs):errors.append('foot:'+name)
prior=json.loads((S/'prior-hashes.json').read_text());changed=[f for f,h in prior.items() if hashlib.sha256((P/f).read_bytes()).hexdigest()!=h];errors+=changed
qa={'new_png_count':len(m['assets']),'reuse_entries':len(m['reuse']),'prior_png_unchanged':len(prior),'node_visible_areas':areas,'fixed_node_foot_y':46,'errors':errors,'runtime_verified':False};(D/'QA.json').write_text(json.dumps(qa,indent=2)+'\n');print(json.dumps(qa));assert not errors
