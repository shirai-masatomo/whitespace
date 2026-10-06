from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,math,sys
ROOT=Path(__file__).resolve().parents[2];font=lambda sz:ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',sz)
def demo(cid):
 out=ROOT/'art_delivery'/f'{cid}_motion_v1';m=json.loads((out/'manifest.json').read_text(encoding='utf-8'));farm=Image.open(ROOT/'art-production/enemy-animal-direction-v3/references/farm-day.png').convert('RGB');bg=farm.crop((270,224,590,324));frames=[];records=[]
 def body(b,action,i=0,pt=(88,84),direction='right'):
  a=m['actions'][action+'_'+direction];rel=a['frames'][i%len(a['frames'])];im=Image.open(out/rel).convert('RGBA');an=m['foot_anchor_px'][direction];b.alpha_composite(im,(pt[0]-an[0],pt[1]-an[1]))
  if a.get('weapon_frames'):
   r=a['weapon_frames'][i%len(a['weapon_frames'])];rec=next(x for x in m['assets'] if x['file']==r);an=rec['foot_anchor_px'];b.alpha_composite(Image.open(out/r).convert('RGBA'),(pt[0]-an[0],pt[1]-an[1]))
 def other(b,rel,anchor,pt):
  im=Image.open(ROOT/'art_delivery'/rel).convert('RGBA');b.alpha_composite(im,(pt[0]-anchor[0],pt[1]-anchor[1]))
 if cid=='destroyer':seq=[('idle',0)]+[('iron_ball_windup',i) for i in range(3)]+[('iron_ball_hit',i) for i in range(4)]+[('idle',0)]*2
 elif cid=='ninja':seq=[('shuriken',i) for i in range(5)]+[('dagger',i) for i in range(4)]+[('hurt',i) for i in range(3)]+[('retreat',i) for i in range(4)]
 elif cid=='animal_tamer':seq=[('tame',i) for i in range(4)]+[('tame',3)]*3+[('tame_end',i) for i in range(4)]+[('lead',i%4) for i in range(8)]
 elif cid=='runner':seq=[('run',i%4) for i in range(8)]+[('tired_enter',i) for i in range(2)]+[('tired',i%3) for i in range(6)]+[('tired_exit',i) for i in range(3)]+[('run',i) for i in range(4)]
 elif cid=='bullfrog':seq=[('tongue_extend',i) for i in range(3)]+[('tongue',0)]*5+[('tongue_retract',i) for i in range(3)]+[('croak',i) for i in range(5)]
 else:return
 for t,(action,i) in enumerate(seq):
  b=bg.copy().convert('RGBA');note={};pt=(88,84)
  if cid=='destroyer':
   state='damaged' if t>=4 else 'normal';other(b,f'earth_stone_buildings_v1/soil/wall/{state}/mask_10.png',[24,34],(148,84));body(b,action,i)
  elif cid=='ninja':
   x=100+(max(0,t-12)*6);body(b,action,i,(x,84))
   if 2<=t<=4:
    im=Image.open(out/f'projectile/shuriken_{(t-2)%4:02}.png').convert('RGBA');b.alpha_composite(im,(128+(t-2)*20,60))
   if t>=12:
    other(b,'ranch_assets_v1/scroll/idle_none_00.png',[12,22],(98,84));note['scroll_spawn']='one separate drop, held while ninja leaves'
  elif cid=='animal_tamer':
   x=125+max(0,t-11)*3;body(b,action,i,(x,84))
   catdir='left' if t<11 else 'right';catx=202-min(t,10)*4 if t<11 else x-55;other(b,f'ranch_assets_v1/cat/walk_{catdir}_0{t%4}.png' if False else f'ranch_assets_v1/cat/idle_{catdir}_00.png',[24,36],(catx,84));note['animal_success']='illustrative only, loyalty result not implied';note['animal_anchor']=[catx,84]
  elif cid=='runner':
   x=128;body(b,action,i,(x,84));dm=json.loads((ROOT/'art_delivery/doberman_motion_v1/manifest.json').read_text(encoding='utf-8'));act='run' if action=='run' else 'idle';files=dm['actions'][act+'_right']['frames'];p=files[i%len(files)];other(b,'doberman_motion_v1/'+p,[32,44],(x-62,84));note['separate_ground_anchors']=[[x,84],[x-62,84]]
  elif cid=='bullfrog':
   pt=(42,84);target=(186,84);wrapped=3<=t<=7
   mouth=(pt[0]+(25 if action=='tongue' or (action=='tongue_extend' and i==2) else 21),pt[1]+(-11 if action=='tongue' else -13));hold=(186,68)
   if wrapped:
    im=Image.open(out/'parts/tongue_wrap_back.png').convert('RGBA');b.alpha_composite(im,(hold[0]-9,hold[1]-5))
   other(b,'kidnapper_basic_v1/idle/left_00.png',[16,44],target);body(b,action,i,pt)
   progress={0:0,1:.28,2:.72,3:1,4:1,5:1,6:1,7:1,8:.65,9:.25,10:0}.get(t,0)
   if progress:
    end=(round(mouth[0]+(hold[0]-mouth[0])*progress),round(mouth[1]+(hold[1]-mouth[1])*progress));length=round(math.dist(mouth,end));strip=Image.open(out/'parts/tongue_body.png').convert('RGBA').resize((max(1,length),3),Image.Resampling.NEAREST)
    # Horizontal example, clipped/stepped by per-column center to keep 3px thickness.
    for xx in range(length):
     yy=round(mouth[1]+(end[1]-mouth[1])*xx/max(1,length-1));b.alpha_composite(strip.crop((xx,0,xx+1,3)),(mouth[0]+xx,yy-1))
    tip=Image.open(out/'parts/tongue_tip.png').convert('RGBA');b.alpha_composite(tip,(end[0]-2,end[1]-2))
   if wrapped:
    im=Image.open(out/'parts/tongue_wrap_front.png').convert('RGBA');b.alpha_composite(im,(hold[0]-9,hold[1]-5))
   if action=='croak' and i in [1,2,3]:other(b,'effects_v1/sound_wave/02.png',[4,16],(pt[0]+30,pt[1]-12))
   note={'frog_anchor':list(pt),'target_anchor':list(target),'anchor_distance_px':144,'tongue_progress':progress,'wrapping_layers':['back','target','front']}
  ms=140 if action not in ['tame','tired','tongue'] else 220;fr=Image.new('RGB',(1280,535),'#eee5ca');d=ImageDraw.Draw(fr);d.text((15,8),m['name_ja']+' / '+action+' / 1x + 4x / オフライン部品合成',font=font(18),fill='#39251a');fr.paste(b.convert('RGB'),(15,32));fr.paste(b.convert('RGB').resize((1280,400),Image.Resampling.NEAREST),(0,135));frames.append(fr);records.append({'action':action,'frame_index':i,'preview_duration_ms':ms,**note})
 strip=Image.new('RGB',(1280,535*len(frames)))
 for i,fr in enumerate(frames):strip.paste(fr,(0,i*535))
 pal=strip.quantize(colors=256,dither=Image.Dither.NONE);pg=[fr.quantize(palette=pal,dither=Image.Dither.NONE) for fr in frames];pg[0].save(out/'preview/special_motion.gif',save_all=True,append_images=pg[1:],duration=[r['preview_duration_ms'] for r in records],loop=0,disposal=2,optimize=False)
 selected={'destroyer':[0,2,3,4,5],'ninja':[2,6,12,15],'animal_tamer':[2,5,11,16],'runner':[1,8,12,20],'bullfrog':[1,3,7,9,13]}[cid];contact=Image.new('RGB',(1280,535*len(selected)))
 for j,k in enumerate(selected):contact.paste(frames[k],(0,j*535))
 contact.save(out/'preview/special_contact.png');(out/'preview/sequence.json').write_text(json.dumps({'review_only':True,'in_game_verified':False,'frames':records},ensure_ascii=False,indent=2),encoding='utf-8');print(cid,'special review',len(frames),'frames')
if __name__=='__main__':
 for cid in sys.argv[1:]:demo(cid)
