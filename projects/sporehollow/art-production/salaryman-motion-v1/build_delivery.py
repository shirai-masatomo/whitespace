from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import numpy as np,json,hashlib,shutil
SRC=Path(__file__).resolve().parent;ROOT=SRC.parents[1];OUT=ROOT/'art_delivery/salaryman_motion_v1';BASE=ROOT/'art_delivery/enemy_animal_direction_v3/pose_drafts/salaryman';OUT.mkdir(exist_ok=True);(OUT/'preview').mkdir(exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
keys=[Image.open(BASE/f'key_{i:02}.png').convert('RGBA') for i in range(7)]
motion=[Image.open(SRC/'native'/f'motion_{i:02}.png').convert('RGBA') for i in range(8)]
call=keys[4].copy();d=ImageDraw.Draw(call);d.line((27,24,28,24),fill=(90,59,54,255))
# Separate upper-body recoil/escape posture from the alternating walking legs.
retreat=[]
for leg in motion[:4]:
 im=motion[6].copy();a=np.array(im);a[39:,:,:]=0;im=Image.fromarray(a);im.alpha_composite(leg.crop((0,39,48,56)),(0,39));retreat.append(im)
clips={
'idle':([keys[0]],[None],False),
'walk':(motion[:4],[120]*4,True),
'hurt':([motion[4],motion[5],keys[0]],[80,120,120],False),
'phone_take':([keys[1],keys[2],keys[3]],[140,120,170],False),
'phone_call':([keys[4],call,keys[4]],[220,120,180],True),
'phone_put':([keys[5],keys[6],keys[0]],[120,140,100],False),
'retreat':(retreat,[100]*4,True)}
assets=[];actions={};images={}
for action,(frames,times,loop) in clips.items():
 (OUT/action).mkdir(exist_ok=True)
 for direction in ['right','left']:
  seq=[]
  for i,(im,ms) in enumerate(zip(frames,times)):
   im=im.copy() if direction=='right' else ImageOps.mirror(im);rel=f'{action}/{direction}_{i:02}.png';p=OUT/rel;im.save(p);images[rel]=im
   rec={'file':rel,'canvas_size_px':[48,56],'foot_anchor_px':[24,50],'visible_bbox_exclusive_px':list(im.getbbox()),'action':action,'direction':direction,'frame_index':i,'frame_duration_ms':ms,'loop':loop,'layer':'body','sha256':sha(p),'runtime_ready':True,'contains_cast_shadow':False,'use':'サラリーマンLv1の盤面動作。32x48へ縮めず48x56の足元を合わせる。'}
   if action.startswith('phone'):rec['phone_baked_in_body']=True
   if action=='hurt':rec['death_pose']=False
   assets.append(rec);seq.append(rel)
  actions[action+'_'+direction]={'action_id':action,'direction':direction,'frames':seq,'frame_duration_ms':times,'loop':loop,'end_behavior':'hold until state changes' if action=='idle' else ('repeat until state changes' if loop else 'return to state-selected pose')}
# Validate meaningful motion, consistent anchors, exact adopted idle and mirrors.
assert sha(OUT/'idle/right_00.png')==sha(BASE/'key_00.png')
face=keys[0].crop((0,0,48,27))
for i in range(4):assert np.array_equal(np.array(motion[i].crop((0,0,48,27))),np.array(face))
for a in assets:
 im=images[a['file']];assert im.mode=='RGBA' and im.size==(48,56)
 assert set(im.getchannel('A').getdata())<={0,255};bb=im.getbbox();assert bb[3]==50 and bb[0]>0 and bb[2]<48 and bb[1]>0
 if a['direction']=='left':assert np.array_equal(np.array(im),np.array(ImageOps.mirror(images[a['file'].replace('left','right')])))
assert len({images[f'walk/right_{i:02}.png'].crop((0,37,48,56)).tobytes() for i in range(4)})==4
refs=[]
for n in ['ART_SPEC.md','ENEMIES.md','ANIMALS.md','ITEMS.md']:refs.append({'file':'../../art-production/salaryman-motion-v1/references/'+n,'sha256':sha(SRC/'references'/n)})
manifest={'schema_version':1,'delivery':'salaryman_motion_v1','date':'2026-10-06','branch':'codex/sporehollow-art-assets','status':'ready_for_implementation','character_id':'salaryman','adopted_design':'../enemy_animal_direction_v3/','adoption_commit':'f26498d2bafe6e274a197aef0a025d5016c8691e','canvas_size_px':[48,56],'foot_anchor_px':[24,50],'standing_body_height_px':40,'rendering':{'format':'RGBA','filter':'nearest','alpha_values':[0,255],'color_key':False,'trim_transparent_margin':False,'baked_ground_shadow':False,'mirror_axis_x':24},'assets':assets,'actions':actions,'timing_policy':'Presentation cadence only. Use existing world visual clock and freeze on pause. Do not derive movement, hit tests, HP, reinforcements or probabilities from frames. phone_call loops only while existing state is calling.','event_notes':{'phone_take_right':{'phone_visible_frame':1},'phone_take_left':{'phone_visible_frame':1},'phone_call':'Phone at ear; no reinforcement spawn event baked into animation','hurt':'Alive flinch; interruption allowed; no flash/death'},'sources':{'original':'../../art-production/salaryman-motion-v1/originals/motion-sheet.png','prompt':'../../art-production/salaryman-motion-v1/generation-record.json','processing':'../../art-production/salaryman-motion-v1/prepare_native.py','assembly':'../../art-production/salaryman-motion-v1/build_delivery.py','existing_phone_keys':'../enemy_animal_direction_v3/pose_drafts/salaryman/','approved_head_reused_pixel_exact':True},'spec_snapshots':refs,'unfinished':['正面・背面の専用動作は未制作（今回の既存横向き契約外）','独立した通常近接攻撃は未制作（現行ART_SPECのサラリーマン必要ActionIDにはない）','ゲームへの取り込み・隔離描画検証は実装担当'],'game_launched':False,'in_game_verified':False}
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
font=lambda sz:ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',sz)
farm=Image.open(ROOT/'art-production/enemy-animal-direction-v3/references/farm-day.png').convert('RGB')
background=farm.crop((270,224,526,312))
def panel(rel):
 b=background.crop((0,0,96,72)).convert('RGBA');b.alpha_composite(images[rel],(24,12));return b.convert('RGB')
review=Image.new('RGB',(1580,7*420+70),'#eee5ca');draw=ImageDraw.Draw(review);draw.text((20,15),'サラリーマン / 正式動作v1 / 1x と nearest 4x / ゲーム内検証ではありません',font=font(20),fill='#39251a')
for row,(action,(frames,times,loop)) in enumerate(clips.items()):
 y=65+row*420;draw.text((20,y),action+' / '+('loop' if loop else 'one-shot / hold')+' / '+str(times),font=font(16),fill='#39251a')
 for i in range(len(frames)):
  rel=f'{action}/right_{i:02}.png';b=panel(rel);review.paste(b,(20+i*390,y+32));big=b.resize((384,288),Image.Resampling.NEAREST);review.paste(big,(20+i*390,y+112))
review.save(OUT/'preview/all_actions.png')
# QA light/dark backgrounds, no color-key; full native frames kept.
alpha=Image.new('RGB',(780,340),'#eee5ca');ad=ImageDraw.Draw(alpha);ad.text((16,8),'透過・左右の足元 / 4x / 基準y50',font=font(18),fill='#39251a')
for j,(rel,bg) in enumerate([('idle/right_00.png','#24353c'),('idle/left_00.png','#eae3c8'),('phone_call/right_01.png','#24353c')]):
 x=12+j*256;ad.rectangle((x,42,x+244,326),fill=bg);im=images[rel].resize((192,224),Image.Resampling.NEAREST);alpha.paste(im,(x+24,74),im);ad.line((x+12,274,x+236,274),fill='#b18449')
alpha.save(OUT/'preview/alpha_and_feet.png')
# Shared palette GIF; colors are stable, no per-frame adaptive flicker.
def render(rel,x=128):
 b=background.copy().convert('RGBA');b.alpha_composite(images[rel],(round(x)-24,72-50));return b.convert('RGB')
timeline=[];x=68
for _ in range(3):
 for i in range(4):x+=3;timeline.append((f'walk/right_{i:02}.png',120,x))
timeline.append(('idle/right_00.png',550,x))
for action in ['hurt','phone_take','phone_call','phone_call','phone_put']:
 for i,ms in enumerate(clips[action][1]):timeline.append((f'{action}/right_{i:02}.png',ms,x))
for _ in range(2):
 for i in range(4):x-=3;timeline.append((f'retreat/left_{i:02}.png',100,x))
timeline.append(('idle/left_00.png',650,x))
gif_frames=[]
for rel,ms,x in timeline:
 b=render(rel,x);frame=Image.new('RGB',(1024,480),'#eee5ca');dd=ImageDraw.Draw(frame);dd.text((16,8),rel.split('/')[0]+' / 1x + nearest 4x / offline preview',font=font(16),fill='#39251a');frame.paste(b,(16,32));frame.paste(b.resize((1024,352),Image.Resampling.NEAREST),(0,128));gif_frames.append(frame)
palette_img=Image.new('RGB',(1024,480*len(gif_frames)))
for i,fr in enumerate(gif_frames):palette_img.paste(fr,(0,i*480))
pal=palette_img.quantize(colors=256,dither=Image.Dither.NONE)
gifs=[fr.quantize(palette=pal,dither=Image.Dither.NONE) for fr in gif_frames]
gifs[0].save(OUT/'preview/motion.gif',save_all=True,append_images=gifs[1:],duration=[ms for _,ms,_ in timeline],loop=0,disposal=2,optimize=False)
qa={'status':'pass','native_png_count':len(assets),'action_count':len(clips),'directions':['right','left'],'all_frames_size':[48,56],'all_foot_anchors':[24,50],'all_ground_contact_y_exclusive':50,'binary_alpha':True,'exact_adopted_idle_sha256':sha(OUT/'idle/right_00.png'),'walk_head_pixel_exact_frame_count':4,'walk_distinct_lower_body_frames':4,'mirror_match_count':len(assets)//2,'no_edge_clipping':True,'preview_timeline_frames':len(gif_frames),'encoded_gif_frames':Image.open(OUT/'preview/motion.gif').n_frames,'preview_duration_ms':sum(ms for _,ms,_ in timeline),'game_launched':False,'in_game_verified':False}
(OUT/'QA.json').write_text(json.dumps(qa,ensure_ascii=False,indent=2),encoding='utf-8')
(OUT/'HANDOFF.md').write_text('''# サラリーマン 正式動作 v1

採用v3の顔・体格を維持した先行納品。左右の静止、歩行、被弾、電話取り出し／通話／収納、生きたまま退散の計7動作・42PNGを用意しました。

## 取り込み契約

- 全コマ48×56、足元(24,50)、通常身体高40px。既存主人公32×48へ合わせて縮小しない。セル足元へアンカーを合わせ、透明余白を保持する。
- 通常RGBA・nearest・alpha 0/255。白い眼鏡やシャツを色キー透過しない。地面影は含まない。
- 右を基準に左右反転した左向きPNGも納品済み。追加で反転しない。足裏はy49の画素、接地基準はy50。
- manifest.assetsが本番PNG一覧。actionsのフレーム順・ms・loopを参照。previewは確認専用。
- 世界のvisual_timeと停止に同期。フレーム時間は表示の初期値であり、既存の移動速度・攻撃間隔・増援確率を変更しない。
- phone_take（430ms）→phone_call（520msでループ）→phone_put（360ms）。通話のループ終了は既存の状態遷移で決定する。増援生成をコマに結び付けない。
- 端末は保持ポーズへ描画済み。既存phone部品を二重に重ねない。通話口元の2pxだけを動かし、採用した曇り眼鏡と顔形状を保持。
- hurtは320ms・非ループ、retreatは400ms周期・ループ。死亡・死体ではなく、生きて出口へ退散する。

## 制作・検査

静止の右PNGは採用元とSHA256が同一。電話キーは採用済み透過PNGを使用。歩行・被弾・退散の追加原画だけ内蔵画像生成で制作し、共有パレット・1px輪郭・二値透過・接地を整形。歩行の頭部は採用画素を完全に維持。退散は専用上半身と交互の脚で4コマ化しています。
原画、正確な生成プロンプト、加工スクリプト、最新仕様のスナップショットは `../../art-production/salaryman-motion-v1/`。顔を別案へ生成し直していません。

QA.jsonに寸法・透過・基準点・左右反転・歩行の異なる脚4コマ・採用頭部の一致を記録。PNG一覧とGIFを実表示1倍・nearest拡大で確認。保存済み牧場背景との合成であり、ゲーム内で動作確認した証拠ではありません。GIF内の移動量は比較用です。

## 未完成／対象外

正面・背面は未制作。独立した通常近接攻撃は未制作（最新ART_SPECのサラリーマン必要ActionIDには含まれていない）。別敵・動物の正式動作はこの納品に含みません。
ゲーム取り込み・隔離描画検証は実装担当。ゲームコード・シーン・UID・能力値は未編集。ユーザーのゲームは起動していません。
''',encoding='utf-8')
(SRC/'README.md').write_text('# サラリーマン動作 制作記録\n\n採用v3を保持。prepare_native.py → build_delivery.pyで納品を再現。内蔵画像生成の原画はoriginals、プロンプトはgeneration-record.json。referencesには採用元PNGと最新の実装仕様。nativeは加工中間素材、納品本体は../../art_delivery/salaryman_motion_v1。\n',encoding='utf-8')
print(json.dumps(qa,ensure_ascii=False))

lineup=Image.new('RGB',(1024,485),'#eee5ca');ld=ImageDraw.Draw(lineup);ld.text((16,8),'採用基準との比較 / 1x + 4x / 実ゲーム確認ではありません',font=font(17),fill='#39251a')
b=farm.crop((270,224,526,312)).convert('RGBA')
for rel,foot,point in [('characters_v1/keeper_idle_right_00.png',(16,44),(42,74)),('characters_v1/shiba_idle_right_00.png',(24,44),(102,74)),('salaryman_motion_v1/idle/right_00.png',(24,50),(158,74)),('salaryman_motion_v1/walk/right_00.png',(24,50),(218,74))]:
 im=Image.open(ROOT/'art_delivery'/rel).convert('RGBA');b.alpha_composite(im,(point[0]-foot[0],point[1]-foot[1]))
lineup.paste(b.convert('RGB'),(16,35));lineup.paste(b.convert('RGB').resize((1024,352),Image.Resampling.NEAREST),(0,133));lineup.save(OUT/'preview/size_comparison.png')
