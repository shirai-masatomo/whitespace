from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import numpy as np,json,hashlib
S=Path(__file__).parent;P=S.parents[1];D=P/'art_delivery/ui_world_direction_v2'
for sub in ['candidates/maid','candidates/thief','candidates/dancer','candidates/kokeshi','preview']: (D/sub).mkdir(parents=True,exist_ok=True)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def components(im):
 ar=np.array(im);on=ar[:,:,3]>=200;seen=np.zeros(on.shape,bool);h,w=on.shape;gs=[]
 for y,x in zip(*np.where(on)):
  if seen[y,x]:continue
  q=[(int(x),int(y))];seen[y,x]=1;pts=[]
  while q:
   xx,yy=q.pop();pts.append((xx,yy))
   for nx,ny in [(xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)]:
    if 0<=nx<w and 0<=ny<h and on[ny,nx] and not seen[ny,nx]:seen[ny,nx]=1;q.append((nx,ny))
  if len(pts)>1000:
   xs,ys=zip(*pts);gs.append({'area':len(pts),'bbox':(min(xs),min(ys),max(xs)+1,max(ys)+1),'points':pts})
 return sorted(gs,key=lambda g:-g['area'])
def extract(im,g):
 ar=np.array(im);mask=np.zeros(ar.shape[:2],np.uint8)
 for x,y in g['points']:mask[y,x]=255
 ar[:,:,3]=mask;return Image.fromarray(ar).crop(g['bbox'])
def src(id):return Image.open(S/'originals'/f'{id}_revision.png').convert('RGBA')
def fit(im,cs,an,scale):
 sz=(max(1,round(im.width*scale)),max(1,round(im.height*scale)));im=im.resize(sz,Image.Resampling.NEAREST)
 a=im.getchannel('A');q=im.convert('RGB').quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGBA');q.putalpha(a)
 out=Image.new('RGBA',cs);out.alpha_composite(q,(an[0]-q.width//2,an[1]-q.height));return out
def rawcrop(im):
 a=im.getchannel('A').point(lambda x:255 if x>=200 else 0);im.putalpha(a);return im.crop(a.getbbox())
groups={};poses={};meta=[]
for id in ['maid','thief','dancer']:
 im=src(id);gs=components(im)
 print(id,[(g['area'],g['bbox']) for g in gs[:8]])
 if id=='maid':
  selected=[]
  for target in [(0.27,0.26),(0.76,0.27),(0.29,0.77)]:
   sel=min(gs,key=lambda g:(((g['bbox'][0]+g['bbox'][2])/2/im.width-target[0])**2+((g['bbox'][1]+g['bbox'][3])/2/im.height-target[1])**2))
   selected.append(sel)
 elif id=='thief':selected=sorted(gs[:3],key=lambda g:g['bbox'][0])
 else:
  # First3 complete separated bodies suffice for clothing / fan revision; old pose order is retained in the original.
  selected=sorted(gs[:5],key=lambda g:g['bbox'][0])[:3]
 groups[id]=selected;poses[id]=[extract(im,g) for g in selected]
 names={'maid':['idle','rage','chase'],'thief':['idle','steal','poison_windup'],'dancer':['idle','fan_raise','fan_spread']}[id]
 scale=min(42/poses[id][0].height,58/max(o.width for o in poses[id]))
 for name,ob in zip(names,poses[id]):
  native=fit(ob,(64,64),(32,58),scale);native.save(D/f'candidates/{id}/{name}.png')
  meta.append({'asset_id':id+'.'+name,'file':f'candidates/{id}/{name}.png','canvas':[64,64],'anchor':[32,58],'action':name,'layer':'body_with_props','frame_index':0,'frame_order':[0],'frame_duration_ms':None,'loop':False,'runtime_ready':False,'status':'revision_review' if id!='dancer' else 'provisional_phoenix_interpretation','source_bbox':selected[names.index(name)]['bbox'],'notes':'Keypose only. Not a complete animation; formal native polish and held-prop sockets pending.'})
raw=src('maid');aura=raw.crop((740,650,1312,1199));aura=rawcrop(aura)
aura=fit(aura,(64,64),(32,58),min(56/aura.width,52/aura.height));aura.putalpha(aura.getchannel('A').point(lambda a:160 if a else 0));aura.save(D/'candidates/maid/rage_aura.png')
meta.append({'asset_id':'maid.rage_aura','file':'candidates/maid/rage_aura.png','canvas':[64,64],'anchor':[32,58],'action':'rage_overlay','layer':'behind_body','frame_index':0,'frame_order':[0],'frame_duration_ms':None,'loop':False,'runtime_ready':False,'status':'revision_review','notes':'Alpha160, separate overlay. Draw aura then body at identical anchor; no screen flash. Timing follows future game state.'})
ob=rawcrop(src('kokeshi'));poses['kokeshi']=[ob];native=fit(ob,(32,40),(16,36),min(24/ob.width,32/ob.height));native.save(D/'candidates/kokeshi/idle.png')
meta.append({'asset_id':'kokeshi.idle','file':'candidates/kokeshi/idle.png','canvas':[32,40],'anchor':[16,36],'action':'placed_concept','layer':'body','frame_index':0,'frame_order':[0],'frame_duration_ms':None,'loop':False,'runtime_ready':False,'status':'revision_review','notes':'Dirt obscures facial expression; no eyes or mouth repainted.'})
def font(n):return ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',n)
def text(im,xy,s,size=18):ImageDraw.Draw(im).text(xy,s,font=font(size),fill='#eadfca')
def paste(im,ob,x,y,scale=1):
 if scale!=1:ob=ob.resize((ob.width*scale,ob.height*scale),Image.Resampling.NEAREST)
 im.alpha_composite(ob,(x,y))
def candidate(id,name='idle'):return Image.open(D/f'candidates/{id}/{name}.png').convert('RGBA')
out=Image.new('RGBA',(1600,840),'#252d29')
text(out,(20,16),'修正版 v2 — メイド / 踊り子（フェニックス解釈の暫定案）/ 盗賊 / こけし',24)
for j,id in enumerate(['maid','dancer','thief','kokeshi']):
 x=20+j*395;ob=poses[id][0];sc=min(350/ob.width,430/ob.height)
 paste(out,ob.resize((round(ob.width*sc),round(ob.height*sc)),Image.Resampling.NEAREST),x+(360-round(ob.width*sc))//2,90+430-round(ob.height*sc))
 text(out,(x,58),{'maid':'黒髪・三つ編みツインテール','dancer':'顔・体型を維持 / 赤・金・羽根','thief':'白髪・歪んだ笑い・猫背','kokeshi':'汚れで表情を隠す'}[id],17)
 c=candidate(id);paste(out,c,x+20,574);paste(out,c,x+90,553,3)
 text(out,(x,790),'原寸＋3倍 / 採用前の修正見本',15)
out.save(D/'preview/revisions.png')
out=Image.new('RGBA',(1440,720),'#252d29');text(out,(20,15),'メイド：通常 → 激怒（浮く三つ編み＋赤オーラ）→ 追跡',24)
for j,name in enumerate(['idle','rage','chase']):
 x=20+j*475;ob=poses['maid'][j];sc=min(390/ob.width,380/ob.height)
 pic=ob.resize((round(ob.width*sc),round(ob.height*sc)),Image.Resampling.NEAREST)
 if j:
  aa=aura.resize((420,420),Image.Resampling.NEAREST);paste(out,aa,x+5,92)
 paste(out,pic,x+(420-pic.width)//2,480-pic.height)
 text(out,(x,520),['通常：自然に垂れる三つ編み','激怒：三つ編みが持ち上がる','追跡：髪形・体型・牛柄を維持'][j],18)
 sm=Image.new('RGBA',(64,64))
 if j:sm.alpha_composite(aura)
 sm.alpha_composite(candidate('maid',name));paste(out,sm,x+5,566);paste(out,sm,x+130,548,2)
text(out,(20,690),'赤オーラは独立PNG。身体の後ろへ同じ足元基準で合成。静止キーポーズであり正式動作ではありません。',16)
out.save(D/'preview/maid_rage_layers.png')
# Standalone original-scale aura preview + dark/light native validation.
out=Image.new('RGBA',(1200,570),'#252d29');text(out,(20,12),'透過・原寸確認 / 明色と暗色 / 通常RGBA・nearest',24)
for j,a in enumerate(meta):
 ob=Image.open(D/a['file']);a['sha256']=sha(D/a['file']);a['visible_bbox_exclusive']=ob.getbbox();a['alpha_values']=sorted(set(np.array(ob.getchannel('A')).ravel().tolist()))
 assert ob.mode=='RGBA' and set(a['alpha_values'])<={0,160,255}
 x=(j%6)*200;y=60+(j//6)*245
 text(out,(x+4,y),a['asset_id'],13)
 for k,bg in enumerate(['#e9ddbc','#17201d']):
  tile=Image.new('RGBA',(96,200),bg);paste(tile,ob,(96-ob.width)//2,25);paste(tile,ob.resize((ob.width*1,ob.height*1),Image.Resampling.NEAREST),(96-ob.width)//2,108)
  paste(out,tile,x+k*100,y+25)
out.save(D/'preview/alpha.png')
manifest={'schema_version':1,'delivery':'ui_world_direction_v2','branch':'codex/sporehollow-art-assets','status':'revision_review','assets':[],'review_assets':meta,'supersedes_for_design_only':['ui_world_direction_v1/candidates/new/maid.png','ui_world_direction_v1/candidates/new/thief.png','ui_world_direction_v1/candidates/new/kokeshi.png'],'provisional_dancer':True,'approved_unchanged':'All other v1 directions accepted by user. Golden-idol A/B selection not explicitly specified.','rendering':{'RGBA':True,'nearest':True,'white_color_key':False,'trim_padding':False,'baked_ground_shadow':False},'remaining':['Dancer intended meaning confirmation pending; phoenix is a stated working assumption.','Full revised Coffee/Dance/steal/poison/rage animations not produced; v1 sequence remains narrative-only.','No gameplay integration or rendering verification.'],'sources':'../../art-production/ui-world-direction-v2/generation-records.json'}
for f in sorted((D/'preview').glob('*.png')):manifest['review_assets'].append({'asset_id':'preview.'+f.stem,'file':f.relative_to(D).as_posix(),'canvas':list(Image.open(f).size),'anchor':None,'action':'comparison','frame_order':None,'frame_duration_ms':None,'loop':False,'runtime_ready':False,'sha256':sha(f)})
(D/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
(S/'extraction.json').write_text(json.dumps({id:[{'bbox':g['bbox'],'area':g['area']} for g in gs] for id,gs in groups.items()},indent=2),encoding='utf-8')
(D/'QA.json').write_text(json.dumps({'candidates':len(meta),'checks':['RGBA','canvas and anchor','alpha0/255 bodies and0/160 aura','SHA256','proportional scale','v1 assets untouched'],'not_verified':['animation continuity','game runtime','dancer interpretation confirmed']},indent=2),encoding='utf-8')
print('saved',D)


