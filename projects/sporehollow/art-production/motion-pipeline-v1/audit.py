from pathlib import Path
from PIL import Image,ImageOps
import json,hashlib,numpy as np
ROOT=Path(__file__).resolve().parents[2]
required={'destroyer':['idle','walk','iron_ball_windup','iron_ball_hit','hurt','retreat'],'martial_artist':['idle','walk','bow','stance','attack','hurt','retreat'],'ninja':['idle','walk','shuriken','dagger','hurt','retreat'],'animal_tamer':['idle','walk','tame','lead','hurt','retreat'],'runner':['idle','run','tired','attack','hurt','retreat'],'doberman':['idle','walk','run','attack','hurt','death'],'bullfrog':['idle','move','tongue','croak','hurt'],'hedgehog':['idle','move','defense_enter','defense','hurt']}
results=[];sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for cid,need in required.items():
 o=ROOT/'art_delivery'/f'{cid}_motion_v1';m=json.loads((o/'manifest.json').read_text(encoding='utf-8'));paths=set()
 for a in m['assets']:
  p=o/a['file'];paths.add(a['file']);im=Image.open(p);assert sha(p)==a['sha256'];assert list(im.size)==a['canvas_size_px'];assert im.mode=='RGBA';assert set(im.getchannel('A').getdata())<={0,255}
  if a['direction']=='left':assert np.array_equal(np.array(im),np.array(ImageOps.mirror(Image.open(o/a['file'].replace('left','right')))))
 for act in need:
  for direction in ['right','left']:assert act+'_'+direction in m['actions']
 for key,a in m['actions'].items():
  assert len(a['frames'])==len(a['frame_duration_ms'])
  assert all(r in paths for r in a['frames'])
  assert not a['loop'] or all(t is not None and t>0 for t in a['frame_duration_ms'])
  for w in a.get('weapon_frames',[]):assert w in paths
 if cid in ['destroyer','ninja']:
  for action,socks in m['sockets'].items():
   if not isinstance(socks,list):continue
   for i,socket in enumerate(socks):
    im=Image.open(o/action/f'right_{i:02}.png');assert im.getpixel(tuple(socket['grip_body_px']))[3]>0,(cid,action,i)
 original='tamer' if cid=='animal_tamer' else cid;assert sha(o/'idle/right_00.png')==sha(ROOT/'art_delivery/enemy_animal_direction_v3/pose_drafts'/original/'key_00.png')
 gifs=[]
 for p in (o/'preview').glob('*.gif'):
  im=Image.open(p);duration=0
  for i in range(im.n_frames):im.seek(i);duration+=im.info['duration'];im.load()
  gifs.append({'file':p.name,'decoded_frames':im.n_frames,'duration_ms':duration})
 results.append({'id':cid,'runtime_png_count':len(paths),'action_count':len(m['actions'])//2,'required_action_ids':need,'hashes_alpha_dimensions_mirrors_actions':'pass','adopted_idle_unchanged':True,'weapon_grips_on_opaque_body':'pass' if cid in ['destroyer','ninja'] else 'not applicable','preview_gifs':gifs,'in_game_verified':False})
report={'status':'pass','sets':8,'runtime_png_count':sum(r['runtime_png_count'] for r in results),'action_count':sum(r['action_count'] for r in results),'results':results,'game_launched':False,'game_code_modified':False}
(Path(__file__).resolve().parent/'audit-results.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps({k:v for k,v in report.items() if k!='results'},ensure_ascii=False))
