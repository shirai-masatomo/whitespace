from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps
import json, math, hashlib
import build_direction as b
SRC=b.SRC; OUT=b.OUT; ROOT=b.ROOT; poses=b.poses; parts=b.parts; SPECS=b.SPECS; names=b.NAMES
FONT='C:/Windows/Fonts/meiryo.ttc'
def ft(s):return ImageFont.truetype(FONT,s)
def txt(im,xy,s,size=16,color='#3f392b'): ImageDraw.Draw(im).text(xy,s,font=ft(size),fill=color)
PAPER=(239,231,207); INK='#343d30'; GOLD='#aa8650'
grass=Image.open(SRC/'references/farm-day.png').convert('RGBA')
def ground(w,h,seed=0):
 return grass.crop((270+(seed*43)%500,224,270+(seed*43)%500+w,224+h))
def stamp(scene,im,foot,anchor):
 scene.alpha_composite(im,(round(foot[0]-anchor[0]),round(foot[1]-anchor[1])))
def body(scene,name,i,foot):
 stamp(scene,poses[name][i],foot,SPECS[name][4])
def baseline(scene,foot):
 d=ImageDraw.Draw(scene);x,y=foot
 d.line((x-8,y,x+8,y),fill=(186,161,98,255));d.line((x,y-1,x,y+2),fill=(186,161,98,255))
def load_ref(rel,anchor):
 return Image.open(ROOT/'art_delivery'/rel).convert('RGBA'),anchor
refs={
'keeper':load_ref('characters_v1/keeper_idle_right_00.png',(16,44)),
'shiba':load_ref('characters_v1/shiba_idle_right_00.png',(24,44)),
'hen':load_ref('ranch_assets_v1/hen/idle_right_00.png',(16,29)),
'cat':load_ref('ranch_assets_v1/cat/idle_right_00.png',(24,36)),
'cat_left':load_ref('ranch_assets_v1/cat/idle_left_00.png',(24,36)),
'kidnapper':load_ref('kidnapper_basic_v1/idle/right_00.png',(16,44)),
'merchant':load_ref('merchant_cart_v2/merchant/idle_right_00.png',(16,44))}
def ref(scene,key,foot): stamp(scene,*[refs[key][0],foot,refs[key][1]])
def scene_for(name,i=0,w=80,h=76,x=None,y=None,seed=0):
 sc=ground(w,h,seed); foot=(x or w//2,y or h-10);baseline(sc,foot)
 if name in refs:ref(sc,name,foot)
 else:body(sc,name,i,foot)
 if name=='destroyer':
  grip=(foot[0]+16,foot[1]-15);ring=(foot[0]+28,foot[1]-14)
  ImageDraw.Draw(sc).line((*grip,*ring),fill=(151,150,129),width=2)
  sc.alpha_composite(parts['iron_ball'],(ring[0]-parts['iron_ball'].width//2,ring[1]))
 return sc
def page(title,sub,w,h):
 im=Image.new('RGB',(w,h),PAPER)
 d=ImageDraw.Draw(im); d.rectangle((0,0,w,8),fill='#4c6249')
 txt(im,(28,23),title,26,INK);txt(im,(30,67),sub,15)
 d.line((28,96,w-28,96),fill='#c2ae83',width=1)
 return im
def footer(im):
 txt(im,(28,im.height-34),'方向確認用・未採用｜4×は同一画像のnearest拡大。ゲーム内動作検証ではありません。',14,'#6c6554')
def paste_rgb(dst,im,xy):dst.paste(im.convert('RGB'),xy)
def lineup(filename,title,entries):
 w=1400;im=page(title+' / 修正版v2','1×実表示 と 同一スプライトの4× nearest拡大。原案の方向・身体高・足元を確認。',w,1120)
 txt(im,(30,110),'1× / 画像内の1 px = 素材の1 px',17)
 for i,(key,label) in enumerate(entries):
  x=38+i*165; sc=scene_for(key,seed=i)
  paste_rgb(im,sc,(x,142));txt(im,(x,222),label,13)
  ht=(refs[key][0].getbbox()[3]-refs[key][0].getbbox()[1]) if key in refs else b.char_meta[key]['standing_body_height_px']
  txt(im,(x,243),f'身体 {ht}px',12)
 txt(im,(30,281),'4× / 図鑑拡大も同一画像',18)
 for i,(key,label) in enumerate(entries):
  x=30+(i%4)*344;y=316+(i//4)*366
  sc=scene_for(key,seed=i).resize((320,304),Image.Resampling.NEAREST)
  paste_rgb(im,sc,(x,y));txt(im,(x,y+310),label,17)
  if key in refs:sz=refs[key][0].size;an=refs[key][1]
  else:sz=SPECS[key][3];an=SPECS[key][4]
  txt(im,(x,y+339),f'{sz[0]}×{sz[1]}  足元 {tuple(an)}',13)
 footer(im);im.save(OUT/'preview'/filename)
lineup('01_enemy_lineup.png','01  敵の基本デザイン比較',[
 ('keeper','主人公v1・既存'),('kidnapper','誘拐者・既存'),('destroyer','デストロイヤー'),('martial_artist','武闘家'),
 ('salaryman','サラリーマン'),('ninja','忍者'),('tamer','ムッツゴロウ'),('runner','ランナー')])
lineup('02_animal_lineup.png','02  動物のサイズ・輪郭比較',[
 ('shiba','柴犬C・既存'),('doberman','ドーベルマン'),('bullfrog','ウシガエル'),('hedgehog','ハリネズミ'),('hen','鶏・既存'),('cat','猫・既存')])
# Every scene is already at native scale. Only its exact pixel replication is shown enlarged.
board_records=[]
def board(filename,title,sections,note,w=1440,folder='motion_storyboards'):
 layouts=[];height=120
 for heading,scenes,labels in sections:
  sw,sh=scenes[0].size; cols=max(1,min(len(scenes),(w-56)//(sw*4+20)))
  native_step=max(sw+22,128)
  if len(scenes)==6 and cols>=3: cols=3
  native_rows=math.ceil(len(scenes)/max(1,(w-56)//native_step))
  sec_h=45+native_rows*(sh+40)+36+math.ceil(len(scenes)/cols)*(sh*4+36)+25
  layouts.append((height,cols,sec_h));height+=sec_h
 height+=66
 im=page(title+' / 修正版v2',note,w,height)
 for (heading,scenes,labels),(y,cols,_) in zip(sections,layouts):
  sw,sh=scenes[0].size
  txt(im,(28,y),heading+'  /  1×',18)
  native_step=max(sw+22,128);native_cols=max(1,(w-56)//native_step);yy=y+34
  for i,(sc,label) in enumerate(zip(scenes,labels)):
   x=28+(i%native_cols)*native_step;cy=yy+(i//native_cols)*(sh+40)
   paste_rgb(im,sc,(x,cy));txt(im,(x,cy+sh+4),f'{i+1}. {label}',12)
  big_y=yy+math.ceil(len(scenes)/native_cols)*(sh+40)+25
  txt(im,(28,big_y-26),'4× / 同一ピクセル',15)
  for i,(sc,label) in enumerate(zip(scenes,labels)):
   x=28+(i%cols)*(sw*4+20);cy=big_y+(i//cols)*(sh*4+36)
   paste_rgb(im,sc.resize((sw*4,sh*4),Image.Resampling.NEAREST),(x,cy))
   txt(im,(x,cy+sh*4+5),f'{i+1}. {label}',14)
 footer(im);im.save(OUT/folder/filename)
 board_records.append({'file':f'{folder}/{filename}','sections':[{'name':s[0],'key_pose_order':s[2],'frame_duration_ms':None,'loop':False} for s in sections]})
def plain_series(name,indices,w=80,h=68):
 return [scene_for(name,i,w,h,seed=j) for j,i in enumerate(indices)]
# Source-derived ball + light native chain link segments. The chain is NOT baked in the body.
chain=Image.new('RGBA',(7,3));d=ImageDraw.Draw(chain)
d.line((1,0,4,0),fill='#443d32');d.line((1,2,4,2),fill='#443d32')
d.point((0,1),fill='#443d32');d.point((5,1),fill='#443d32')
d.line((1,1,4,1),fill='#9a9a81');d.point((6,1),fill='#b9b9a0')
chain.save(OUT/'concept_parts/chain_link.png')
phone=Image.new('RGBA',(3,6),(37,46,57,255));ImageDraw.Draw(phone).line((1,1,1,3),fill=(164,188,171,255))
phone.save(OUT/'concept_parts/phone.png')
def draw_chain(sc,p,q):
 dx=q[0]-p[0];dy=q[1]-p[1];dist=math.hypot(dx,dy)
 d=ImageDraw.Draw(sc);d.line((*p,*q),fill=(66,60,49),width=2)
 steps=max(1,int(dist/5))
 for j in range(steps+1):
  x=round(p[0]+dx*j/steps);y=round(p[1]+dy*j/steps)
  d.point((x,y),fill='#bbb69b')
wall=Image.open(ROOT/'art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_10.png').convert('RGBA')
wall_bad=Image.open(ROOT/'art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_10.png').convert('RGBA')
ds=[]
# Scene-space hand points sampled after native processing; separate ball ring attaches to chain end.
hand=[(60,67),(26,56),(37,29),(69,82),(82,61),(58,69)]
ring=[(72,68),(7,41),(64,8),(108,56),(119,59),(77,63)]
for i in range(6):
 sc=ground(144,96,i);foot=(44,82);baseline(sc,foot)
 stamp(sc,wall if i<4 else wall_bad,(120,81),(24,34))
 draw_chain(sc,hand[i],ring[i])
 body(sc,'destroyer',i,foot)
 sc.alpha_composite(parts['iron_ball'],(ring[i][0]-parts['iron_ball'].width//2,ring[i][1]))
 ds.append(sc)
board('03_destroyer_motion.png','03  デストロイヤー / 鉄球の重量感',
 [('鉄球：6キー案',ds,['下げる','後ろへ引く','振りかぶる','叩きつける','鎖が伸びる','戻す'])],
 '身体高46px。胴巻きの鎖は常時着用、動く鉄球・鎖は別部品。壁の損傷は演出意図の例で、判定・耐久値は変更しません。')
board('04_martial_artist_motion.png','04  武闘家 / 礼と構え',
 [('戦闘開始',plain_series('martial_artist',[0,1,2,3]),['向く','姿勢を正す','短く礼','構える']),
  ('戦闘終了',plain_series('martial_artist',[3,0,2,6]),['構え解除へ','対象を見る','礼','離れる']),
  ('攻撃の意味',plain_series('martial_artist',[3,4,5,3]),['構え','突き','蹴り','戻る'])],
 '身体高42px。礼は腰から曲げ、足元を維持。正確な時間と補間は未確定。')
board('05_salaryman_phone_motion.png','05  サラリーマン / 電話で仲間を呼ぶ',
 [('電話：7キー案（通話と会話を1キーに統合）',plain_series('salaryman',list(range(7))),['通常','ポケットへ','取り出す','画面を見る','耳へ・話す','通話を切る','しまう'])],
 '身体高40px。端末は3×6pxを基準に手元補正。phone_take / phone_call / phone_put に分割可能。')
# Throw and retreat/drop: old scroll reference stays independent.
ns=[]
for i in range(4):
 sc=scene_for('ninja',i,112,72,x=35,y=62,seed=i)
 if i>=2:sc.alpha_composite(parts['shuriken'],(76+(i-2)*22,29))
 ns.append(sc)
scroll=Image.open(ROOT/'art_delivery/ranch_assets_v1/scroll/idle_none_00.png').convert('RGBA')
# The existing UI scroll is shown at its existing size; it is not supplied as a new world-scale item.
drop=[]
for i in [4,5,5]:
 sc=ground(112,72,i);body(sc,'ninja',i,(35 if not drop else 75,62))
 if drop: sc.alpha_composite(scroll,(22,72-scroll.height-5))
 drop.append(sc)
board('06_ninja_motion.png','06  忍者 / 投擲と巻物ドロップ',
 [('手裏剣（本体と分離）',ns,['構え','腕を引く','投げる','振り抜く']),
  ('撃退後（生存して退散）',drop,['よろめく','巻物を落とす','退散'])],
 '身体高34px。手裏剣と短剣は別素材。巻物は既存品の合成例。Lv1に煙玉は追加しません。')
ts=[]
for j,i in enumerate([1,2,3,4,4,5]):
 sc=ground(112,72,j);baseline(sc,(34,62));body(sc,'tamer',i,(34 if j<5 else 69,62))
 ref(sc,'cat_left' if j<5 else 'cat',((88 if j<4 else 72) if j<5 else 24,62));ts.append(sc)
board('07_tamer_motion.png','07  ムッツゴロウ（仮）/ おやつで誘う',
 [('手懐け：6キー案',ts,['見つける','しゃがむ','手を出す','おやつ・声','近づく','連れて歩く'])],
 '完全オリジナルの人物。猫は既存素材を別レイヤーで配置。懐柔判定や柴犬の抵抗仕様は変更しません。')
rs=plain_series('runner',[1,2,3,4,5,1])
pair=[]
for i in [0,1,2]:
 sc=ground(128,72,i);baseline(sc,(30,62));baseline(sc,(91,62));body(sc,'runner',i,(30,62));body(sc,'doberman',i,(91,62));pair.append(sc)
board('08_runner_motion.png','08  ランナー / 走行・疲労・同行',
 [('走行から疲労、回復',rs,['大きな歩幅','脚を集める','フォーム崩れ','膝に手・息切れ','回復','再走']),
  ('ドーベルマン同行 / 足元は61px離す',pair,['待機','伸びる走り','脚を集める'])],
 '身体高42px、犬33px。速度・疲労時間はアート側で確定しません。同じマスに重ねません。')
# Frog: three horizontal cells between actor ground anchors, with front/back wraps.
for part,start,end in [('tongue_wrap_back',180,360),('tongue_wrap_front',0,180)]:
 im=Image.new('RGBA',(18,10));d=ImageDraw.Draw(im)
 d.arc((0,0,17,9),start,end,fill=(112,71,62,255),width=3)
 d.arc((1,1,16,8),start,end,fill=(197,143,132,255),width=2)
 im.save(OUT/'concept_parts'/f'{part}.png');parts[part]=im
fs=[];mouth_offsets={1:(21,-13),2:(25,-11)}
for j,i in enumerate([0,1,1,2,2,0]):
 sc=ground(232,76,j);frogfoot=(38,64);enemyfoot=(182,64)
 baseline(sc,frogfoot);baseline(sc,enemyfoot)
 # Cell boundaries exist ONLY in the review composite.
 d=ImageDraw.Draw(sc)
 for x in [14,62,110,158,206]:d.line((x,66,x,71),fill=(188,166,104,255))
 wrap_xy=(173,47)
 if j in [3,4]:sc.alpha_composite(parts['tongue_wrap_back'],wrap_xy)
 body(sc,'bullfrog',i,frogfoot);ref(sc,'kidnapper',enemyfoot)
 if j in [2,3,4]:
  mouth=(frogfoot[0]+mouth_offsets[i][0],frogfoot[1]+mouth_offsets[i][1])
  end=(117 if j==2 else 176,mouth[1])
  strip=parts['tongue_body'].resize((end[0]-mouth[0],3),Image.Resampling.NEAREST)
  sc.alpha_composite(strip,(mouth[0],mouth[1]-1))
  if j==2:sc.alpha_composite(parts['tongue_tip'],(end[0]-2,end[1]-2))
  else:
   sc.alpha_composite(parts['tongue_wrap_front'],wrap_xy)
   sc.alpha_composite(parts['tongue_tip'],(186,53))
 fs.append(sc)
alarm=[]
wave=Image.open(ROOT/'art_delivery/effects_v1/sound_wave/02.png').convert('RGBA')
for j,i in enumerate([3,4,5,0]):
 sc=scene_for('bullfrog',i,96,64,x=34,y=54,seed=j)
 if j==2:stamp(sc,wave,(65,37),(4,16))
 alarm.append(sc)
board('09_bullfrog_motion.png','09  ウシガエル / 3マスの舌・巻き付き・鳴き',
 [('舌の伸縮 / 足元基準点間 3×48 = 144px',fs,['敵を見る','口を開く','伸ばす','巻き付く','引く・固定','戻す']),
  ('襲撃を知らせる鳴き声',alarm,['襲われる','喉を膨らます','鳴く・小音波','落ち着く'])],
 '通常26px。灰白色のたるんだ体。舌は伸縮部・先端・巻き付き前後に分離。射程ロジックは未編集。')
board('10_hedgehog_motion.png','10  ハリネズミ / 防御モード',
 [('通常から防御、解除',plain_series('hedgehog',list(range(6)),64,52),['通常','被弾','縮める','棘が立つ','丸く防御','戻る'])],
 '通常18px、棘を立てたキー20px。身体を巨大化せず、輪郭と顔の隠れ方で防御を示します。')
# Doberman exact left/right and two run poses, separate from the runner storyboard.
dogsc=[]
for j in range(5):
 sc=ground(88,64,j);foot=(44,54);baseline(sc,foot)
 if j==1:stamp(sc,ImageOps.mirror(poses['doberman'][0]),foot,SPECS['doberman'][4])
 else:body(sc,'doberman',[0,0,1,2,3][j],foot)
 dogsc.append(sc)
board('12_doberman_motion.png','12  ドーベルマン / 姿勢の方向確認',
 [('立ち・走り・攻撃構え',dogsc,['右立ち','左立ち','走り・伸びる','走り・集める','攻撃構え'])],
 '通常身体高33px（柴犬Cは28px）。左右は同じキャンバスと足元。全方向の正式歩行は未制作。')
# Equipment icons: body24-28px within32px UI frames, palette and contour same native treatment.
eqs=[]
for name in ['collar','healing_berry']:
 if name=='collar':
  icon=Image.open(SRC/'references/collar-v1-unchanged.png').convert('RGBA')
 else:
  raw=b.component_cut(Image.open(SRC/'originals/berry.png').convert('RGBA'))
  pic=b.native(raw,min(28/raw.width,28/raw.height))
  icon=Image.new('RGBA',(32,32));icon.alpha_composite(pic,((32-pic.width)//2,(32-pic.height)//2))
 icon.save(OUT/'equipment'/f'{name}.png')
 sc=Image.new('RGBA',(56,48),(219,204,159,255));sc.alpha_composite(icon,(12,8));eqs.append(sc)
board('11_equipment_icons.png','11  装備UI / 首輪・きのみ',
 [('UIアイコン案 32×32 / きのみは薄黄色・一粒・ごつごつ',eqs,['犬用の首輪','回復のきのみ'])],
 'キャラクターへの装着表示は制作対象外。レアリティ枠・数字・文字はアイコンへ焼き込みません。',folder='preview')
(OUT/'storyboard-data.json').write_text(json.dumps(board_records,ensure_ascii=False,indent=2),encoding='utf-8')
print('review sheets ready',flush=True)

