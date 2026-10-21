from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
fontpath=next(str(p) for p in [Path('C:/Windows/Fonts/YuGothM.ttc'),Path('C:/Windows/Fonts/meiryo.ttc')] if p.exists())
fonts={n:ImageFont.truetype(fontpath,n) for n in [13,15,16,18,20,24,30]}
hero=Image.open(ROOT/'assets/visual-candidates/v1/dive-hero-static-candidate-v1.png').convert('RGBA');hero=hero.crop(hero.getbbox())
foe=Image.open(ROOT/'assets/visual-candidates/v1/dive-e01-underground-rat-static-candidate-v2.png').convert('RGBA');foe=foe.crop(foe.getbbox())
G='#bd9654';INK='#eee4c9';MUT='#a8bbb9';DARK='#17262d';PAPER='#d9c595'
def txt(x,y,s,n=18,c=INK):d.text((x,y),s,font=fonts[n],fill=c)
def box(x,y,w,h,label='',selected=False,paper=False):
 d.rounded_rectangle((x,y,x+w,y+h),7,fill=PAPER if paper else '#102129',outline='#f1c96a' if selected else G,width=3 if selected else 1)
 if label:txt(x+14,y+8,label,18,'#30291e' if paper else INK)
def btn(x,y,w,s,main=False):
 box(x,y,w,42,selected=main);txt(x+14,y+8,s,18,'#f5d996' if main else INK)
def portrait(x,y,w=58,h=78,enemy=False):
 a=(foe if enemy else hero).copy();a.thumbnail((w,h));im.alpha_composite(a,(int(x+(w-a.width)/2),int(y+h-a.height)))
def party(selected=0):
 for i,(name,role) in enumerate([('主人公','攻撃寄り・前衛'),('検証B','防御役・前衛'),('検証C','支援役・後衛')]):
  y=117+i*133;box(24,y,204,121,selected=i==selected);portrait(35,y+29,55,78);txt(101,y+14,name,20);txt(101,y+48,role,13,MUT);txt(101,y+78,'行動設定を編集 →',13,'#d4b77f')
def rule(x,y,num,skill,condition,target,selected=False):
 box(x,y,668,68,selected=selected);box(x+10,y+13,39,39,selected=selected);txt(x+23,y+17,str(num),20,'#f6d57d');
 if '防御' in skill:
  d.polygon([(x+69,y+14),(x+90,y+14),(x+89,y+29),(x+80,y+36),(x+70,y+29)],fill='#7595a2',outline='#e3bf6b',width=2)
 else:
  d.line((x+70,y+33,x+89,y+13),fill='#dfdfcf',width=4);d.line((x+66,y+26,x+78,y+37),fill='#c49c50',width=3)
 txt(x+107,y+10,skill.split('  [')[0],20);txt(x+67,y+39,condition,15,MUT);txt(x+407,y+21,'→ '+target,16);txt(x+604,y+20,'↑ ↓',16,G)
for mode in range(1,5):
 im=Image.new('RGBA',(1280,720),'#071319');d=ImageDraw.Draw(im)
 for y in range(720):d.line((0,y,1280,y),fill=(8+int(y/45),23+int(y/40),30+int(y/50)))
 box(14,14,1252,62);txt(32,26,'作戦  /  '+['部隊の全体像','一人の行動設定','部隊セットの保存・選択','戦闘中の切り替え'][mode-1],24)
 txt(914,33,'モック M0'+str(mode)+' ・ 未承認',18,'#f2c874')
 party(1 if mode==2 else 0)
 box(245,91,1009,541)
 if mode==1:
  txt(265,107,'部隊の配置と、全員の行動設定を見比べる',24);txt(280,151,'前衛',18,G);txt(669,151,'後衛',18,G)
  for x,y,i,name in [(294,191,0,'主人公'),(488,191,1,'検証B'),(718,191,2,'検証C')]:
   box(x,y,163,166,selected=i==0);portrait(x+41,y+37,80,93);txt(x+24,y+8,name,20);txt(x+23,y+136,['強打 → 通常攻撃','予告時：防御','条件付き行動'][i],13,MUT)
  txt(935,151,'個人の行動設定',18,G)
  for j,(name,a,b) in enumerate([('主人公','① 強打','② 通常攻撃'),('検証B','① 防御','② 通常攻撃'),('検証C','① 条件を確認','② 通常攻撃')]):
   txt(935,196+j*62,name,18);txt(1030,196+j*62,a,15);txt(1030,221+j*62,b,13,MUT)
  box(273,397,946,80);txt(290,412,'指定行動順',18,G)
  for j,name in enumerate(['検証B','主人公','検証C']):btn(466+j*231,416,202,f'{j+1}  {name}')
  txt(289,499,'個人の設定 ＋ 隊列 ＋ 指定順 ＝ 名前付きの「作戦」',20)
  btn(285,553,316,'選択キャラの設定へ');btn(623,553,286,'作戦を保存…',True);btn(931,553,280,'作戦を選ぶ…')
 elif mode==2:
  portrait(271,111,61,78);txt(345,112,'検証B の行動設定',24);txt(345,151,'防御役 / 前衛  ・  例示用の所持スキル',16,MUT)
  rule(272,221,1,'防御  [盾のアイコン]','敵が強打を予告 / SP・CDを満たす','自分',True)
  rule(272,306,2,'通常攻撃  [剣のアイコン]','いつでも','敵の前衛')
  btn(272,397,308,'＋ 優先行を追加');box(968,212,257,253,'選択行の詳細',paper=True);txt(986,256,'技能 / 条件 / 対象',18,'#30291e');txt(986,303,'同じ作戦の他キャラは',15,'#30291e');txt(986,331,'左の顔から切り替え',15,'#30291e');txt(986,380,'成立しなければ次の行',15,'#30291e')
  txt(276,492,'この画面では「個人の設定」を編集。全員分の保存は部隊の作戦から。',16,MUT)
  btn(275,553,273,'戻る');btn(574,553,320,'個人の編集を反映',True)
 elif mode==3:
  txt(272,108,'全員分を作戦として保存・選択',24)
  box(276,173,413,331,'作戦一覧');
  for j,(name,extra) in enumerate([('★ 門番に備える','適用中'),('★ 素早く進む','お気に入り'),('☆ 慎重に進む','未適用')]):
   box(293,222+j*82,378,67,selected=j==0);txt(309,232+j*82,name,20);txt(310,263+j*82,extra,13,MUT)
  box(717,173,499,331,'保存する内容',paper=True);txt(739,220,'名前： 門番に備える',24,'#30291e');txt(739,268,'★ お気に入りに登録',18,'#30291e')
  for j,name in enumerate(['主人公：攻撃設定','検証B：予告時の防御','検証C：支援設定']):portrait(742+j*143,317,48,65);txt(735+j*143,387,name,13,'#30291e')
  txt(739,439,'行動順：検証B → 主人公 → 検証C',16,'#30291e');btn(285,548,285,'複製して保存');btn(594,548,286,'選んだ作戦を適用',True);btn(904,548,300,'戻る')
 elif mode==4:
  txt(273,108,'戦闘中  /  現在の作戦：素早く進む',24);box(273,158,549,300,'現在の部隊');portrait(347,238,97,144);portrait(484,253,75,130);portrait(661,251,103,115,True)
  txt(292,407,'Space：停止・再開 / 行動済みの回数は戻さない',15,MUT)
  box(847,158,370,300,'切り替える作戦');btn(865,219,332,'★ 門番に備える',True);btn(865,276,332,'★ 素早く進む');txt(869,348,'次の未実行行動から反映',18,G);txt(869,383,'消費なし / 現行ルールを維持',15,MUT)
  box(277,486,937,80);txt(294,499,'行動済み：主人公    次の候補：検証B',18);txt(294,532,'個人の設定を選び直す操作ではなく、部隊の保存セットを切り替える。',15,MUT)
  btn(279,580,321,'作戦の詳細を見る');btn(626,580,288,'この作戦へ切り替え',True);btn(941,580,273,'戻る')
 box(16,650,1248,54);txt(34,664,'検証専用のダミー編成 / 役割は説明用。加入・成長・技能付与の確定仕様ではありません。',16,MUT)
 im.convert('RGB').save(OUT/f'M0{mode}.png')
print('4 layout mock images written; no game started')
