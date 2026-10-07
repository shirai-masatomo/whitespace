from make_reviews import *
from collections import deque
def components(im,threshold=190):
 ar=np.array(im);on=ar[:,:,3]>=threshold;seen=np.zeros(on.shape,bool);h,w=on.shape;groups=[]
 for y,x in zip(*np.where(on)):
  if seen[y,x]:continue
  q=[(int(x),int(y))];seen[y,x]=1;pts=[]
  while q:
   xx,yy=q.pop();pts.append((xx,yy))
   for nx,ny in ((xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)):
    if 0<=nx<w and 0<=ny<h and on[ny,nx] and not seen[ny,nx]:seen[ny,nx]=1;q.append((nx,ny))
  if len(pts)>30:
   xs,ys=zip(*pts);groups.append((len(pts),(min(xs),min(ys),max(xs)+1,max(ys)+1),pts))
 return sorted(groups,reverse=True,key=lambda a:a[0])
def component_image(im,g):
 mask=Image.new('L',im.size);a=np.array(mask)
 for x,y in g[2]:a[y,x]=255
 out=im.copy();out.putalpha(Image.fromarray(a));return out.crop(g[1])
# Extract whole separated dancer silhouettes by connected alpha, never arbitrary equal-width cuts.
dancer_parts={}
for action in ['dance','resurrection']:
 raw=src('dancer_'+action+'_clean')
 gs=sorted(components(raw)[:5],key=lambda g:g[1][0])
 assert len(gs)==5
 dancer_parts[action]=[component_image(raw,g) for g in gs]
 (S/f'dancer_{action}_extraction.json').write_text(json.dumps([{'bbox':g[1],'pixels':g[0]} for g in gs],indent=2),encoding='utf-8')
# Native small stars need readable ivory centers, no soft halo.
stars=cand('ui','ready_stars');d=ImageDraw.Draw(stars)
for x,y in [(8,6),(16,13),(6,18)]:
 d.line((x-2,y,x+2,y),fill='#c29746',width=1);d.line((x,y-2,x,y+2),fill='#c29746',width=1);d.point((x,y),fill='#fff2c5')
stars.save(D/'candidates/ui/ready_stars.png')
# Separate translucent poison demonstration and projectile are direction parts, not runtime animation.
for i,id,cs,an,ex in [(9,'poison_projectile',(32,24),(16,12),(28,18)),(10,'poison_splash',(48,32),(24,28),(44,26)),(11,'poison_cloud',(64,40),(32,36),(58,32))]:
 ob=clean(cell(src('thief_sheet'),i,4,3),190)
 gs=components(ob)
 # Remove small prior-row outlines near top, preserve isolated fragments in effect.
 a=np.array(ob);a[:40,:,:]=0;ob=Image.fromarray(a)
 ob=native(ob,cs,an if id!='poison_projectile' else (16,22),ex)
 if id=='poison_cloud':ob.putalpha(ob.getchannel('A').point(lambda v:96 if v else 0))
 ob.save(D/f'candidates/new/{id}.png')
# Review storyboard: use entire silhouettes, same physical scale, supplementary target layered from adopted art.
storymeta=json.loads((D/'storyboards/index.json').read_text(encoding='utf-8'))
for entry in storymeta:
 id=entry['action'];names=entry['order'];cw=260
 out=panel(len(names)*cw,430);label(out,(15,10),id+' / 方向確認・正式フレームではありません',20)
 if id.startswith('dancer_'):
  poses=dancer_parts[id.split('_')[1]]
 else:
  sheet=src(entry['source'][:-4]);cols,rows=entry['source_grid'];poses=[]
  for i in entry['source_cells_zero_based']:
   ob=clean(cell(sheet,i,cols,rows),190)
   gs=components(ob)
   if id=='maid_rage':
    ob=component_image(ob,gs[0]) # removes the detached swing arc and neighbouring residue
   else:
    ar=np.array(ob);mask=np.zeros(ar.shape[:2],np.uint8)
    for g in gs:
     if g[0]>=160:
      for x,y in g[2]:mask[y,x]=255
    ob.putalpha(Image.fromarray(mask));ob=ob.crop(ob.getbbox())
   poses.append(ob)
 maxh=max(o.height for o in poses);maxw=max(o.width for o in poses)
 sc=min(220/maxw,255/maxh)
 for j,(ob,name) in enumerate(zip(poses,names)):
  ob=ob.resize((round(ob.width*sc),round(ob.height*sc)),Image.Resampling.NEAREST)
  if id=='thief_poison' and j==5:ob.putalpha(ob.getchannel('A').point(lambda v:100 if v else 0))
  paste(out,ob,j*cw+(cw-ob.width)//2,315-ob.height)
  label(out,(j*cw+8,327),str(j+1)+'. '+name,16)
  if id=='dancer_resurrection':
   target=Image.open(P/'art_delivery/martial_artist_motion_v1/idle/right_00.png').convert('RGBA')
   if j<4:target=target.rotate(90,expand=True)
   paste(out,target,j*cw+164,365-target.height//2)
   if j==3:
    for ox,oy in [(130,347),(150,355),(174,353)]:paste(out,stars,j*cw+ox,oy)
 if id=='dancer_resurrection':label(out,(15,403),'対象＝既存武闘家の別レイヤー。寝た向きは絵コンテ用の回転表示で、蘇生・気絶素材ではありません。',14)
 out.save(D/f'storyboards/{id}.png')
 entry['source']=('dancer_'+id.split('_')[1]+'_clean.png') if id.startswith('dancer_') else entry['source']
 entry['source_extraction']='connected alpha components, see art-production' if id.startswith('dancer_') else 'grid cells with detached residue removed'
 entry['composition_layers']=['body','target_existing_martial_artist','life_light'] if id=='dancer_resurrection' else (['body','projectile','splash','cloud'] if id=='thief_poison' else ['body_concept'])
(D/'storyboards/index.json').write_text(json.dumps(storymeta,ensure_ascii=False,indent=2),encoding='utf-8')
# Larger basic concept art contact sheet, separate from native candidates.
out=panel(1600,920);label(out,(20,14),'F  基本原画7種 — 衣装・形の確認用（盤面へ直接使用しない）',24)
for j,id in enumerate(['maid','dancer','thief','cow','bull','kokeshi','fossil']):
 if id in sheets:
  sheet,cols,rows=sheets[id];ob=clean(cell(src(sheet),0,cols,rows))
  gs=components(ob);ob=component_image(ob,gs[0])
 else:ob=clean(src(id));ob=ob.crop(ob.getbbox())
 x=20+(j%4)*395;y=65+(j//4)*425
 label(out,(x,y),id);scale=min(360/ob.width,345/ob.height);ob=ob.resize((round(ob.width*scale),round(ob.height*scale)),Image.Resampling.NEAREST)
 paste(out,ob,x+(370-ob.width)//2,y+45+345-ob.height)
out.save(D/'preview/F_concept_art.png')
# Native readiness on keeper: exact1x and4x.
out=panel(1000,320);label(out,(20,14),'E  READY：原寸・3倍 / 影や効果範囲とは別の表示',23)
for j,id in enumerate(['ready_aura','ready_stars']):
 sample=Image.new('RGBA',(110,75),'#6b7d49')
 ob=cand('ui',id)
 if j==0:paste(sample,ob,31,45)
 paste(sample,keeper,39,15)
 if j==1:paste(sample,ob,64,12)
 paste(out,sample,20+j*490,60);paste(out,sample,140+j*490,60,3)
label(out,(20,290),'常時ループや点滅は未指定。表示の継続は既存ゲージ状態に従う。',16)
out.save(D/'preview/E_ready_native.png')
# Alpha QA dark/light for representative whites / paper and all candidate groups.
files=sorted((D/'candidates').rglob('*.png'))
out=panel(1200,((len(files)+5)//6)*170+50);label(out,(15,10),'RGBA透過チェック / 明色・暗色 / 全て方向確認候補',20)
for i,f in enumerate(files):
 im=Image.open(f).convert('RGBA');x=(i%6)*200;y=50+(i//6)*170
 label(out,(x+3,y),f.stem[:23],11)
 sc=min(90/im.width,115/im.height);ob=im.resize((round(im.width*sc),round(im.height*sc)),Image.Resampling.NEAREST)
 for k,bg in enumerate(['#e9ddbc','#172122']):
  tile=Image.new('RGBA',(96,132),bg);paste(tile,ob,(96-ob.width)//2,(132-ob.height)//2);paste(out,tile,x+k*100,y+22)
out.save(D/'preview/alpha_all.png')
print('final visual repairs complete')

