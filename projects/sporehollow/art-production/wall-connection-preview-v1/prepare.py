from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageChops
import numpy as np,json,hashlib,shutil
P=Path(__file__).resolve().parents[2];D=P/'art_delivery';O=D/'wall_connection_preview_v1'
O.mkdir(exist_ok=True);R=Path(__file__).resolve().parent
I=Path('C:/Users/masat/Documents/Codex/2026-10-10/task/colony-structure-01-work/projects/sporehollow')
F=lambda n:ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',n)
N=Image.Resampling.NEAREST
files={};checks=[]
def read(p):
 p=Path(p);files[str(p.relative_to(P)) if p.is_relative_to(P) else str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
 return Image.open(p).convert('RGBA')
# The morning game screenshot is reused unchanged as the backing crop.
bg=read(P/'art-production/colony-growth-previews-v2/references/01_field.png').crop((740,390,1220,710))
keeper=read(D/'characters_v1/keeper_idle_right_00.png')
dog=read(D/'characters_v1/shiba_idle_right_00.png')
gold=read(D/'ui_world_direction_v1/candidates/world/goldA.png')
walls={}
for mat in ['soil','wood','stone']:
 for st in ['normal','damaged']:
  for m in range(16):
   p=D/(f'wood_buildings_v1/wall/{st}/wood_mask_{m:02}.png' if mat=='wood' else f'earth_stone_buildings_v1/{mat}/wall/{st}/mask_{m:02}.png')
   walls[mat,st,m]=read(p)
   assert walls[mat,st,m].size==(48,68)
   assert set(walls[mat,st,m].getchannel('A').getdata())<={0,255}
for m in range(16):
 for mat in ['soil','stone']:
  assert walls[mat,'normal',m].getchannel('A').tobytes()==walls['wood','normal',m].getchannel('A').tobytes()
  checks.append(f'{mat} mask{m:02} geometry = wood')
 for mat in ['soil','wood','stone']:
  a=walls[mat,'normal',m].getchannel('A')
  for bit,xy in [(1,[(x,1) for x in range(18,30)]),(2,[(47,y) for y in range(16,28)]),(4,[(x,42) for x in range(18,30)]),(8,[(0,y) for y in range(16,28)])]:
   if m&bit:
    assert all(a.getpixel(p)==255 for p in xy)
    checks.append(f'{mat} mask{m:02} port{bit} opaque')
doors={}
for axis in ['horizontal','vertical']:
 for state in ['open','closed']:
  im=Image.new('RGBA',(48,68))
  for layer in ['frame_rear','leaf_'+state+'_normal','frame_front']:
   im.alpha_composite(read(D/f'wood_buildings_v1/door/{axis}_{layer}.png'))
  doors[axis,state]=im
dirs=[(0,-1,1),(1,0,2),(0,1,4),(-1,0,8)]
forms=[
 ('single','単独1マス',{(0,0)},{}),
 ('horizontal','横5マス',{(x,0) for x in range(5)},{}),
 ('vertical','縦5マス',{(0,y) for y in range(5)},{}),
 ('elbow','L字',{(0,y) for y in range(4)}|{(x,3) for x in range(4)},{}),
 ('tee','T字',{(x,0) for x in range(5)}|{(2,y) for y in range(4)},{}),
 ('cross','十字',{(x,2) for x in range(5)}|{(2,y) for y in range(5)},{}),
 ('door','壁とドア・開口',{(x,0) for x in range(5)}|{(0,y) for y in range(5)},{(2,0):('horizontal','open'),(0,2):('vertical','open')}),
 ('mixed','土→木→石・混在',{(x,0) for x in range(5)}|{(2,y) for y in range(4)},{}),
]
def tint(im):
 a=np.array(im);a[:,:,:3]=np.rint(a[:,:,:3]*.78+np.array([7.65,15.3,51])*.22).astype('uint8')
 return Image.fromarray(a)
def sprite(im,s,xy,an,scale=1):
 s=s.resize((round(s.width*scale),round(s.height*scale)),N)
 im.alpha_composite(tint(s),(round(xy[0]-an[0]*scale),round(xy[1]-an[1]*scale)))
def render(cells,doorcells,mat,improved=False,mixed=False):
 scene=bg.copy();layer=Image.new('RGBA',scene.size)
 # Keep characters outside the wall footprint so this proof does not imply depth correctness.
 cx=(min(x for x,y in cells)+max(x for x,y in cells))/2
 cy=(min(y for x,y in cells)+max(y for x,y in cells))/2
 ox,oy=round(142-cx*48),round(145-cy*42)
 for x,y in sorted(cells,key=lambda p:(p[1],p[0])):
  mask=sum(bit for dx,dy,bit in dirs if (x+dx,y+dy) in cells)
  material=['soil','wood','stone'][min(2,x*3//5)] if mixed else mat
  im=doors[doorcells[x,y]] if (x,y) in doorcells else walls[material,'normal',mask]
  layer.alpha_composite(im,(ox+x*48-24,oy+y*42-34))
 if improved:
  # A composite-only proposal: a one-pixel cool-brown right silhouette,
  # not a regenerated wall, not a baked ground shadow, not a collision expansion.
  a=layer.getchannel('A')
  shifted=Image.new('L',a.size);shifted.paste(a,(1,0))
  rim=ImageChops.subtract(shifted,a)
  # Preserve every pixel of the door cells, including the open aperture.
  for x,y in doorcells:ImageDraw.Draw(rim).rectangle((ox+x*48-25,oy+y*42-34,ox+x*48+25,oy+y*42+34),fill=0)
  edge=Image.new('RGBA',a.size,(62,53,35,0));edge.putalpha(rim.point(lambda p:160 if p else 0));layer=Image.alpha_composite(edge,layer)
 scene.alpha_composite(tint(layer))
 sprite(scene,keeper,(342,285),(16,44),1.4375)
 sprite(scene,dog,(402,285),(24,44),1.25)
 sprite(scene,gold,(388,181),(72,152))
 return scene
pages=[]
for key,title,cells,dc in forms:
 mats=['mixed'] if key=='mixed' else ['soil','wood','stone']
 out=Image.new('RGB',(1000,100+len(mats)*355),'#243b31');d=ImageDraw.Draw(out)
 d.text((18,10),title+' ｜既存素材 / 外側1px補助案',font=F(23),fill='#f0e4c5')
 d.text((18,48),'合成プレビュー／未実装。通常倍率1×、セル48×42。全て同じ地面・人物倍率。',font=F(14),fill='#c9d3b8')
 for i,mat in enumerate(mats):
  y=90+i*355
  a=render(cells,dc,mat,False,key=='mixed');b=render(cells,dc,mat,True,key=='mixed')
  d.text((12,y),mat+' 既存PNG・現行アンカー',font=F(14),fill='#e8d9b0')
  d.text((510,y),'改善候補：外側右辺のみ1px補助（PNG再制作なし）',font=F(13),fill='#e8d9b0')
  out.paste(a,(10,y+26));out.paste(b,(510,y+26))
 out.save(O/f'{key}_1x.png');pages.append((key,title))
 # Exact nearest 2x copy. Never call a downscaled browser thumbnail "normal size".
 out.resize((out.width*2,out.height*2),N).save(O/f'{key}_2x.png')
# Open / closed doors independently check aperture plus connections, both axes.
out=Image.new('RGB',(1000,790),'#243b31');d=ImageDraw.Draw(out)
d.text((16,8),'木ドア：開 / 閉、縦 / 横 ｜合成プレビュー／未実装',font=F(22),fill='#e8d9b0')
for i,axis in enumerate(['horizontal','vertical']):
 for j,st in enumerate(['closed','open']):
  cells={(x,0) for x in range(5)} if axis=='horizontal' else {(0,y) for y in range(5)}
  dc={(2,0) if axis=='horizontal' else (0,2):(axis,st)}
  im=render(cells,dc,'wood',True)
  out.paste(im,(10+j*500,58+i*360));d.text((12+j*500,34+i*360),axis+' / '+st,font=F(14),fill='#e8d9b0')
out.save(O/'door_states_1x.png')
# Touching ports are inclusive 0..41 tile coordinates shifted +1. Every cardinal edge remains covered.
(O/'QUALITY_REVIEW.json').write_text(json.dumps({'checks_passed':len(checks),'checks':checks,'new_runtime_png_count':0,'runtime_tested':False,'wall_size':[48,68],'cell':[48,42],'anchor':[24,34],'improvement':'one-pixel exposed right silhouette only; zero within door cell'},ensure_ascii=False,indent=2),encoding='utf8')
sources={'art_branch':'codex/sporehollow-art-assets','art_source_commit':'a0fec22ab0fac417c07609ae209b0a1c78f5b825','implementation_branch':'codex/sporehollow-biome01','implementation_source_commit':'ef67bc4dfccf468a99939f803d2cf13e1ae4c995','images':files,'code':{}}
for n in ['building_art.gd','wall_stroke.gd','main.gd','buildings.gd']:
 p=I/'game'/n;sources['code'][n]=hashlib.sha256(p.read_bytes()).hexdigest()
(O/'source_receipt.json').write_text(json.dumps(sources,ensure_ascii=False,indent=2),encoding='utf8')
(O/'PREVIEW_INDEX.md').write_text('''# 壁1マス接続の監査・比較

**全て合成プレビュー／未実装。実ゲーム動作確認の証拠ではありません。** 1×リンクは画像を100%で表示。2×は同じ画素のnearest拡大です。

|形状|通常倍率|2倍|
|---|---|---|
'''+''.join(f'|{title}|[{key} 1×]({key}_1x.png)|[nearest 2×]({key}_2x.png)|\n' for key,title in pages)+'''
[ドア縦横・開閉](door_states_1x.png) / [不足一覧・判断](HANDOFF.md) / [検査](QUALITY_REVIEW.json)

## 推奨と自己評価
既存16接続を継続使用。必須の新規PNGは0枚です。改善欄は右外縁へ1pxの輪郭補助を追加した表示案で、壁の厚み・アンカー・占有は変えていません。縦壁が草地から識別しやすくなりますが、小さな差です。横壁は元々前面24pxで十分読めるため、元のままでよいです。採用するなら縦の外縁だけへ限定することを推奨します。

この案は「壁を太くする」案ではありません。縦横を同じ見かけの太さにしたい場合は投影断面の再設計となり、局所パッチで済むと誤認しないでください。今回は全16接続を再制作していません。
''',encoding='utf8')
(O/'HANDOFF.md').write_text('''# 壁接続・不足素材の調査結果

## 結論
土・木・石の通常16×3、損傷16×3が実在。通常96枚ではなく、通常48枚＋損傷48枚です。48×68、基準(24,34)、セル48×42、N1/E2/S4/W8。異素材でも接続口のalpha形状は同一です。木ドア縦横の前後柱・開閉扉板・施錠部品も既存。必須の不足PNGは見つかりませんでした。

## 指定8形状
単独、横5、縦5、L、T、十字、ドア接続は3素材ずつ比較。混在は土→木→石の連続とT字。ドアは追加画像で縦横・開閉を比較。元画像を1×で使い、主人公1.4375、柴犬1.25、黄金像1.0の同じ基準を両欄へ配置。画面は保存済み実ゲーム画像の草地を同じ位置で切り出した比較用構成です。

## 現行コードとの照合
- building_art.gdは完成壁とドアを隣接として16マスク選択。壁はp-(24,34)に整数配置。
- main.gd wall_links→Buildings.enclosureはreadyの壁・ドアを接続対象にする。予約は対象外。素材を問わない。
- ドア方向はN/S数がE/W数より多い時のみ縦。ドアセルに壁本体を重ねない。
- wall_stroke.gdは入力の4近傍連続セル列を扱う。画像や描画順を修正するファイルではない。
- 元PNGの外部接地影は無し。前面陰影は材質の陰影。比較案も地面の影を追加していない。

## 不足・任意補助の一覧
|項目|既存で可能か|追加PNG|残る判断|
|---|---|---|---|
|単独・端・直線|可能|不要|単独は36px横幅、縦芯は12px。現在投影を維持|
|内角・外角・T・十字|16マスクで可能|不要|重複端面を別途重ねない|
|異素材境界|口形状共通で可能|不要|材質色の切替は意図した境目。二重外枠禁止|
|壁・ドア接続|既存部品で可能|不要|人物と柱・扉の前後関係は実装側で確認|
|縦壁の視認性補助|本プレビュー右欄|現時点不要|画像の合成alphaの外縁1pxで試作。採用後に表示処理か少数部品か決める|
|損傷|既存各16|不要|HP閾値は既存仕様。今回変更しない|
|接地影|ゲーム側との重複を要確認|保留|今回追加しない|

外縁補助は連結結果のalphaから作り、接続内部には描かない。ドアセル全域には加えず、開口を1pxも狭めない。今回の候補はプレビューPNG内だけに保存し、正式素材やゲームコードは無変更。

## 未検証
PNGの接続口と共通形状は検査済み。実ゲームの設置/削除更新、縦壁の遮蔽、ドア通過、非整数カメラ倍率の継ぎ目は未検証。保存済みwall_connections等も参照したが、今回の改善案を実ゲームで動かした証拠には使っていない。ゲームは起動していない。
''',encoding='utf8')
html='<!doctype html><meta charset="utf-8"><title>壁1マス接続比較</title><style>body{background:#253b32;color:#eeddbb;font:16px sans-serif;margin:24px}a{color:#bedbb6}img{display:block;max-width:100%;image-rendering:pixelated;margin:16px 0}img.native{max-width:none}button{padding:8px}</style><h1>壁1マス接続比較</h1><p>合成プレビュー／未実装。クリックで画像を100%表示・解除。</p><p><a href="HANDOFF.md">不足一覧</a> / <a href="PREVIEW_INDEX.md">評価</a></p>'
for key,title in pages:html+=f'<h2>{title}</h2><img src="{key}_1x.png" onclick="this.classList.toggle(\'native\')">'
html+='<h2>ドア開閉</h2><img src="door_states_1x.png">'
(O/'index.html').write_text(html,encoding='utf8')
print('wall preview',len(pages),'shapes',len(checks),'checks passed')

