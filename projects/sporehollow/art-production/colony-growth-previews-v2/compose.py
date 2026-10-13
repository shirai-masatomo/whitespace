from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps,ImageFilter,ImageChops
import numpy as np,json,hashlib
R=Path(__file__).resolve().parent; P=R.parents[1];D=P/'art_delivery'; O=D/'colony_growth_previews_v2'; W=R/'working'
I=Path(r'C:/Users/masat/Documents/Codex/2026-10-10/task/colony-structure-01-work/projects/sporehollow')
N=Image.Resampling.NEAREST
F=lambda n:ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',n)
INK='#e6dcc1'; BG='#253b32'; CREAM='#e3d3a6'; DARK='#36483a'
meta=json.loads((R/'working_manifest.json').read_text(encoding='utf-8'))
def asset(rel):return Image.open(D/rel).convert('RGBA')
def work(n):return Image.open(W/(n+'.png')).convert('RGBA')
def tint(im):
 a=np.array(im);a[:,:,:3]=np.rint(a[:,:,:3]*.78+np.array([7.65,15.3,51])*.22).astype('uint8');return Image.fromarray(a)
def put(s,im,xy,anchor=None,scale=1,day=True):
 anchor=anchor or (0,0);im=im.resize((round(im.width*scale),round(im.height*scale)),N)
 if day:im=tint(im)
 s.alpha_composite(im,(round(xy[0]-anchor[0]*scale),round(xy[1]-anchor[1]*scale)))
def wput(s,n,xy,scale=1):put(s,work(n),xy,meta[n]['anchor'],scale)
def person(s,xy,left=False):
 im=asset('characters_v1/keeper_idle_right_00.png');im=ImageOps.mirror(im) if left else im;put(s,im,xy,(16,44),1.4375)
def dog(s,xy):put(s,asset('characters_v1/shiba_idle_right_00.png'),xy,(24,44),1.25)
def tag(s,xy,text,size=16):
 d=ImageDraw.Draw(s);b=d.textbbox(xy,text,font=F(size));d.rectangle((b[0]-6,b[1]-4,b[2]+6,b[3]+4),fill=(39,56,42,230));d.text(xy,text,font=F(size),fill=INK)
def base():return Image.open(R/'references/01_field.png').convert('RGBA')
def card(s,box,title,lines):
 d=ImageDraw.Draw(s);d.rectangle(box,fill=CREAM,outline='#805e3b',width=2);x,y=box[:2];d.text((x+14,y+12),title,font=F(18),fill=DARK)
 for i,t in enumerate(lines):d.text((x+14,y+46+i*24),t,font=F(14),fill=DARK)
def sheet(name,title,s,zooms,notes):
 out=Image.new('RGBA',(1280,1440),BG);d=ImageDraw.Draw(out)
 d.text((24,12),title,font=F(25),fill=INK);d.text((24,46),'合成プレビュー／未実装　｜　上：実ゲーム画像へ通常倍率で仮配置　下：nearest 2倍',font=F(14),fill='#bcd0b3')
 out.alpha_composite(s,(0,80));d.text((24,894),notes,font=F(16),fill=INK)
 for j,(label,rect) in enumerate(zooms):
  crop=s.crop(rect);crop=crop.resize((crop.width*2,crop.height*2),N);x=24+j*(1232//len(zooms));out.alpha_composite(crop,(x,958));d.text((x,932),label,font=F(14),fill='#bcd0b3')
 out.convert('RGB').save(O/(name+'.png'))
# A1 radio: normal objects, broadcast signal reuse, inventory and historic header proof.
s=base();wave=asset('effects_v1/sound_wave/01.png')
for x,n,label in [(220,'radio_a','A 木箱型'),(860,'radio_b','B 緑の金属ケース型')]:
 person(s,(x-65,396));wput(s,n,(x+8,396));wput(s,n,(x+106,396));put(s,wave,(x+118,369),scale=.5)
 tag(s,(x-58,294),label);tag(s,(x-5,415),'静止',13);tag(s,(x+79,415),'放送中',13)
 card(s,(x-65,493,x+300,620),'見出し・所持品の縮尺候補',['古いラジオ　／　履歴','24px小アイコン・48px資料表示','設置・運搬の可否は未確定'])
 im=work(n);bb=im.getbbox();im=im.crop(bb);im.thumbnail((24,24),N);put(s,im,(x+230,537),day=False)
 im48=work(n);im48.thumbnail((48,48),N);put(s,im48,(x+245,579),scale=1.2,day=False)
 # historical UI remains untouched, tiny icon placed beside existing header on a crop
 hist=Image.open(R/'references/21_radio_history.png').convert('RGBA').crop((190,145,500,215));im=work(n);im.thumbnail((28,28),N);hist.alpha_composite(im,(5,17));s.alpha_composite(hist,(x-65,650));tag(s,(x-65,628),'過去画面の見出しへ仮合成',12)
sheet('preview_A1_radio','A1 古いラジオ｜本体2案と放送中の見分け',s,[('A 木箱型',(130,321,420,447)),('B 金属ケース型',(770,321,1060,447))],'推奨 A：木・生成りの既存UIと調和。B：丸いスピーカーが小さくても判別しやすい。')
# A2: exact goldA body with reusable isolated overlay, no semantic redraw.
gold=asset('ui_world_direction_v1/candidates/world/goldA.png');variants={}
for kind in ['normal','ready','praying','damage']:
 im=Image.new('RGBA',gold.size)
 if kind in ['ready','praying']:
  a=gold.getchannel('A');rim=ImageChops.subtract(a.filter(ImageFilter.MaxFilter(5)),a);glow=Image.new('RGBA',gold.size,(236,189,78,0));glow.putalpha(rim.point(lambda p:int(p*(.3 if kind=='ready' else .45))));im.alpha_composite(glow)
 im.alpha_composite(gold)
 if kind=='praying':
  sp=asset('effects_v1/build_complete/01.png');im.alpha_composite(sp,(31,93));im.alpha_composite(sp,(92,107))
 if kind=='damage':
  crack=asset('biome_environment_v1/rock/damage/light.png');c=np.array(crack);c[:,:,:3]=[84,59,30];crack=Image.fromarray(c);crack=crack.crop(crack.getbbox()).resize((12,18),N);layer=Image.new('RGBA',gold.size);hi=crack.copy();a=hi.getchannel('A');hi.paste((220,177,78),(0,0,hi.width,hi.height));hi.putalpha(a);layer.alpha_composite(hi,(77,130));layer.alpha_composite(crack,(76,131));layer.putalpha(ImageChops.multiply(layer.getchannel('A'),gold.getchannel('A')));im.alpha_composite(layer)
 variants[kind]=im
s=base()
for x,kind,label in [(200,'normal','通常（元PNG）'),(455,'ready','夜：祈れる表示'),(830,'praying','祈り実行中'),(1090,'damage','軽い損傷')]:
 put(s,variants[kind],(x,289),(72,152));tag(s,(x-75,100),label,14)
tag(s,(780,590),'全て goldA を原寸で再利用／光・小粒子・亀裂のみ重ねる',14)
tag(s,(780,624),'発光速度・損傷条件・能力・2×2占有は既存仕様に従う',13)
sheet('preview_A2_idol_states','A2 黄金像｜形を変えない状態差分・1方向',s,[(label,(x-72,133,x+72,303)) for x,label in [(200,'通常'),(455,'祈れる'),(830,'祈り中'),(1090,'軽い損傷')]],'推奨：細い金色の縁＋少量の既存粒子。顔と模様は維持し、点滅や大きな光柱を避ける。')
# A3: contact poses, anchors and points are explicit; native face retained.
s=base();large=asset('mining_rock_objects_v1/rock_large_4x4_stage1.png');small=asset('mining_rock_objects_v1/rock_small_1x1_stage1.png');tree=asset('ui_world_direction_v1/candidates/world/tree_a.png')
put(s,large,(275,475),(112,224));put(s,small,(408,624),(24,46));put(s,tree,(1000,456),(32,72),1.35)
# Tool contact coordinates within working canvases measured at native: mine(62,48), axe(64,39).
contacts=[]
def contact_pose(kind,tip,left=False):
 n='keeper_'+kind+'_1_'+('left' if left else 'right');a=meta[n]['anchor'];tc=(28,46) if left and kind=='mining' else ((51,46) if kind=='mining' else ((20,42) if left else (59,42)))
 foot=(tip[0]-(tc[0]-a[0])*1.4375,tip[1]-(tc[1]-a[1])*1.4375);wput(s,n,foot,1.4375);contacts.append({'pose':n,'tool_point_local':tc,'foot_screen':foot,'contact_screen':tip})
 d=ImageDraw.Draw(s);x,y=map(round,tip);d.line((x-4,y,x+4,y),fill='#f9e5ad');d.line((x,y-4,x,y+4),fill='#f9e5ad')
contact_pose('mining',(185,429));contact_pose('mining',(425,613),True);contact_pose('logging',(990,437));put(s,tree,(1000,585),(32,72),1.35);contact_pose('logging',(1011,566),True)
tag(s,(100,225),'採掘：既存4×4岩山／右向き命中',15);tag(s,(265,657),'小岩1×1／左向き命中',14);tag(s,(830,315),'伐採：右・左の接触姿勢',15)
# Equivalent existing tool-drawing construction at strike phase 0 (visual comparison only)
person(s,(170,610));dd=ImageDraw.Draw(s);dd.line((170,586,178,589),fill='#d3ad82',width=4);dd.line((172,589,218,596),fill='#8c6444',width=3);dd.line([(210,600),(215,592),(225,593),(229,599)],fill='#bbbfb4',width=3);tag(s,(80,650),'現行コード工具の再現',13)
tag(s,(789,661),'十字＝道具先端の接触候補（ゲーム判定ではない）',12)
sheet('preview_A3_work_pose','A3 採掘・伐採｜命中キーポーズ・左右の配置比較',s,[('採掘：腕と接触点',(105,349,345,489)),('伐採：幹との接触',(850,351,1110,491))],'提案：人体の腕＋道具先端を合わせる。振りかぶり・戻り・遮蔽は正式制作時の未完成項目。')
(O/'work_contact_proposal.json').write_text(json.dumps({'preview_only':True,'damage_timing_changed':False,'contacts':contacts},ensure_ascii=False,indent=2),encoding='utf-8')
# A4 record objects and cards, no new story content.
s=base()
for x,n,title in [(230,'father_journal','古い手帳／1案'),(900,'father_letter','短い手紙／1案')]:
 person(s,(x-70,392));wput(s,n,(x+5,392));tag(s,(x-70,285),title)
 card(s,(x-95,478,x+240,654),'父の記録（資料見本）',['本文は既存データを表示する領域','発見場所・内容・結末は未確定','販売物としての追加は行わない'])
 im=work(n);put(s,im,(x+178,542),scale=1.5,day=False)
book=Image.open(R/'references/journal_cover_green.png').convert('RGBA');book.thumbnail((85,85),N);put(s,book,(678,606),day=False);tag(s,(580,698),'採用済み図鑑：緑＋金（再制作しない）',12)
sheet('preview_A4_father_notes','A4 父の記録｜手帳と手紙・内容を固定しない外観',s,[('手帳：素朴な布表紙',(139,321,399,447)),('手紙：折り目と紙色',(799,321,1059,447))],'推奨：手帳は継続記録、手紙は短文カード。表紙・小物に物語の答えや新しい本文を描かない。')
# B1 two proposed adults, matching source body height and render scale.
s=base()
for x,code,title in [(225,'a','A 藍の作業上着'),(890,'b','B 生成りシャツ＋前掛け')]:
 for dx,di in [(0,'front'),(74,'right')]:wput(s,'resident_'+code+'_'+di,(x+dx,398),1.4375)
 person(s,(x-78,398));dog(s,(x+159,398));tag(s,(x-78,285),title)
 tag(s,(x-86,430),'主人公　　正面　　側面　　柴犬',13)
 card(s,(x-100,526,x+250,644),'立ち姿だけの比較ラフ',['同じ身体高42px／現在の人物倍率','加入人物・能力・名前は未確定','主人公の歩行設計は後で流用検討'])
sheet('preview_B1_resident','B1 2人目の住人｜服・髪・輪郭の2案',s,[('A 藍色で主人公と区別',(119,322,419,420)),('B 世界観への馴染みを優先',(784,322,1084,420))],'推奨 A：遠目でも帽子の主人公と区別しやすい。Bは自然だが草地との明度差が小さい。')
# B2 same growth sprites, two arrangements, no seed item or new state logic.
s=base()
for x,natural,title in [(180,True,'A 自然型'),(880,False,'B 整然型')]:
 tag(s,(x-30,258),title+'｜4×4マス',16)
 if natural:
  # Reuse the same tilled-earth candidate to join a few mounds into irregular patches.
  for rr,cc in [(0,0),(1,1),(2,0),(2,2)]:wput(s,'crop_0',(x+cc*48+22,340+rr*42+13))
 for r in range(4):
  for c in range(4):
   stage=[1,2,3,4][r];ox=([0,6,-6,4][(r+c)%4] if natural else 0);oy=([0,-5,4,0][(c*2+r)%4] if natural else 0)
   wput(s,f'crop_{stage}',(x+c*48+ox,340+r*42+oy))
 person(s,(x-60,447));dog(s,(x+205,448))
 tag(s,(x-40,498),'種まき→若芽→成長→収穫（比較用混在）',12)
# Five exemplar visual steps along lower-middle area, not game UI.
for i,t in enumerate(['耕土','播種','若芽','成長','収穫']):wput(s,f'crop_{i}',(460+i*75,666));tag(s,(443+i*75,683),t,12)
sheet('preview_B2_farm','B2 畑・作物｜根菜候補1種・配置2案',s,[('A 小さく不規則な土の端',(136,288,396,492)),('B セルの状態を追いやすい列',(836,288,1096,492))],'推奨 Bの配置＋Aの外縁。丸い淡色根菜は仮候補。種アイテムや5論理状態を追加する意味ではない。')
# B3 grass and indoor material, with existing rest-zone reference.
s=base();floor=asset('wood_buildings_v1/floor/wood_00.png')
for x,n,title in [(240,'bed_a','A 敷き寝具'),(920,'bed_b','B 低い木枠')]:
 tag(s,(x-90,252),title+'｜仮1×2マス')
 wput(s,n,(x,418));person(s,(x-54,418));tag(s,(x-18,436),'草地',13)
 for r in range(3):
  for c in range(3):put(s,floor,(x-70+c*48,499+r*42))
 wput(s,n,(x,601));person(s,(x+47,601));tag(s,(x-65,642),'既存木床上／屋内を想定',12)
# Existing zone is a region, not an existing bed.
z=Image.open(R/'references/08_zones.png').convert('RGBA').crop((426,589,638,693));s.alpha_composite(z,(500,595));tag(s,(497,701),'既存「休息」は範囲表示',12)
sheet('preview_B3_bed','B3 簡易寝床｜草地・屋内床・人物との縮尺',s,[('A 地面に馴染む敷き寝具',(156,301,426,441)),('B 家具として判別しやすい木枠',(836,301,1106,441))],'推奨 Aを最初の候補に。Bは施設感が明確。睡眠時の身体・掛布の前後分離は採用後に必要。')
# B4 sketch only; code-native alert glyphs, equal16px, no direction information.
def alert(kind):
 im=Image.new('RGBA',(16,16));d=ImageDraw.Draw(im)
 if kind=='bell':d.polygon([(7,2),(10,3),(12,6),(12,10),(14,12),(2,12),(4,10),(4,6)],fill='#dbb45a',outline='#513c29');d.rectangle((7,13,9,14),fill='#f7dda1');d.rectangle((7,0,9,1),fill='#d3b777')
 else:d.polygon([(8,1),(15,14),(1,14)],fill='#dbb45a',outline='#513c29');d.rectangle((7,5,8,9),fill='#513c29');d.rectangle((7,11,8,12),fill='#513c29')
 return im
s=base()
for x,n,kind,title in [(235,'watch_a','bell','A 鐘の標識'),(905,'watch_b','triangle','B 低い木札')]:
 for dx in [0,106]:wput(s,n,(x+dx,405))
 put(s,alert(kind),(x+99,341));person(s,(x-60,405));tag(s,(x-70,270),title+'（スケッチ）');tag(s,(x-15,430),'平時　　　警戒時',13)
 # Existing wall and full door parts surrounding the tiny post.
 for dx in [-48,48]:put(s,asset('wood_buildings_v1/wall/normal/wood_mask_10.png'),(x+dx,565),(24,34))
 for part in ['horizontal_frame_rear','horizontal_leaf_closed_normal','horizontal_lock_closed_normal','horizontal_frame_front']:put(s,asset('wood_buildings_v1/door/'+part+'.png'),(x,565),(24,34))
 wput(s,n,(x+110,600));tag(s,(x-65,640),'既存の木壁・扉との比較',12)
 tag(s,(x-65,674),'16px警戒アイコン：位置・範囲は示さない',12)
sheet('preview_B4_watch','B4 見張り地点・警戒｜小型標識2案・設計ラフ',s,[('A 鐘と同形の警戒アイコン',(151,299,421,439)),('B 汎用の警戒三角',(821,299,1091,439))],'推奨 Aの標識＋Bの三角アイコン。視覚案のみ。探知範囲・予告精度・設備効果は未確定。')
# B5 one crate, two small selection card layouts, dynamic action captions only.
s=base();wput(s,'event_crate',(250,396));person(s,(195,396));tag(s,(164,281),'物資箱：1案／縄と無地の札')
put(s,asset('resource_icons_v1/hud24/wood.png'),(349,373));put(s,asset('resource_icons_v1/hud24/stone.png'),(395,373));tag(s,(318,415),'既存の資源現物と比較',12)
for box,title,lines in [((100,483,455,658),'A 地点の小カード',['道端の物資箱（構成ラフ）','中身・期限・所有者は未確定']),((820,300,1195,502),'B 通知から開くカード',['物資箱を見つけた（仮文）','事件の結果や数量は未設定'])]:
 card(s,box,title,lines);d=ImageDraw.Draw(s);x,y,xx,yy=box
 for dx,t in [(14,'回収する'),(183,'見送る')]:d.rectangle((x+dx,yy-49,x+dx+147,yy-13),fill='#eee1b9',outline='#876d42',width=2);d.text((x+dx+27,yy-43),t,font=F(17),fill=DARK)
wput(s,'event_crate',(1000,591));tag(s,(854,654),'操作カードは見本／報酬・NPC・商品は追加しない',12)
sheet('preview_B5_event','B5 非戦闘イベント｜物資箱1案＋選択UI2案',s,[('箱の縄・無地札を確認',(157,322,427,412)),('カードAの通常倍率は上段参照',(110,602,407,661))],'推奨 A：現地の箱との関係を読み取りやすい。Bは見落とし防止向きだが画面を塞ぎやすい。')
# Cross-theme actual-size lineup. All proposed occupancy values remain provisional.
s=base();xs=[140,235,347,467,558,685,790,890,980,1080];y=624
person(s,(xs[0],y));dog(s,(xs[1],y));put(s,gold,(xs[2],y),(72,152));wput(s,'radio_a',(xs[3],y));wput(s,'resident_a_right',(xs[4],y),1.4375);wput(s,'crop_4',(xs[5],y));wput(s,'bed_a',(xs[6],y));wput(s,'watch_a',(xs[7],y));wput(s,'event_crate',(xs[8],y));wput(s,'father_journal',(xs[9],y))
for x,t in zip(xs,['主人公','柴犬C','goldA','ラジオ','住人A','根菜候補','寝床A','見張りA','物資箱','手帳']):tag(s,(x-27,648),t,12)
tag(s,(135,215),'同じゲーム背景・カメラ通常倍率で比較／既存人物と動物の倍率を保持',19)
tag(s,(135,257),'マス48×42px｜黄金像144×160px原寸｜人物32×48px×1.4375｜柴犬48×48px×1.25',14)
sheet('preview_scale_sheet','縮尺一覧｜採用済み素材＋今回の候補',s,[('主人公・柴犬・像',(104,468,404,630)),('生活・作業小物',(660,490,960,630))],'候補は全て未採用。接地点の十字やラベルはレビュー用で、素材に焼き込むものではありません。')
print('10 preview sheets composed')
