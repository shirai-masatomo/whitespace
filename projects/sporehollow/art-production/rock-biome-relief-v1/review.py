from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageChops
import json,math
S=Path(__file__).resolve().parent;P=S.parents[1];A=P/'art_delivery';D=A/'rock_biome_relief_v1';R=D/'review';R.mkdir(exist_ok=True)
M=json.loads((D/'manifest.json').read_text());font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',13);small=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',11)
def im(f):return Image.open(f).convert('RGBA')
def put(out,o,x,y):out.alpha_composite(o,(int(x),int(y)))
base={(x,y) for x in range(1,4) for y in range(1,4)}
def scene(cells,removed=set(),old=False,damage=0,runtime_scale=False):
 out=Image.new('RGBA',(288,252),'#788950')
 for y in range(5):
  for x in range(5):
   if 1<=x<=3 and 1<=y<=3:key='interior'
   elif x in (0,4) and y in (0,4):key='outer_'+('n' if y==0 else 's')+('w' if x==0 else 'e')
   elif x==0:key='edge_e'
   elif x==4:key='edge_w'
   elif y==0:key='edge_s'
   else:key='edge_n'
   put(out,im(D/f'rock_biome/border/{key}.png'),24+x*48,21+y*42)
 for x,y in removed:put(out,im(D/'rock_biome/mined_states/excavated.png'),24+x*48,21+y*42)
 for x,y in sorted(cells,key=lambda p:(p[1],p[0])):
  m=sum(b for b,dx,dy in [(1,0,-1),(2,1,0),(4,0,1),(8,-1,0)] if (x+dx,y+dy) in cells);v=(((x*374761393+y*668265263+61)*1274126177)>>16)%4
  o=im(A/f'biome_connections_v1/normal/mask_{m:02}.png') if old else im(D/f'rock_biome/mineable/v{v}/mask_{m:02}.png')
  if damage and (x,y)==(2,3):
   over=im(D/f'rock_biome/mined_states/damage_{damage}.png');over.putalpha(ImageChops.multiply(over.getchannel('A'),o.getchannel('A')));o.alpha_composite(over)
  cy=9 if old else -3;put(out,o,24+x*48,cy+y*42)
  if not old:
   for co,dx,dy,b1,b2 in [('nw',-1,-1,1,8),('ne',1,-1,1,2),('sw',-1,1,4,8),('se',1,1,4,2)]:
    if m&b1 and m&b2 and (x+dx,y+dy) not in cells:put(out,im(D/f'rock_biome/cliff/inner_{co}.png'),24+x*48,cy+y*42)
 # Original character PNG, exact source scale; no face edits.
 keeper=im(A/'characters_v1/keeper_idle_right_00.png');dog=im(A/'characters_v1/shiba_idle_right_00.png')
 if runtime_scale:
  keeper=keeper.resize((46,69),Image.Resampling.NEAREST);dog=dog.resize((60,60),Image.Resampling.NEAREST);put(out,keeper,92-23,240-63);put(out,dog,150-30,240-55)
 else:put(out,keeper,76,196)
 if not runtime_scale:put(out,dog,126,196)
 return out
runtime=scene(base,runtime_scale=True);runtime=runtime.resize((432,378),Image.Resampling.NEAREST);runtime.save(R/'runtime_scale_reference.png')
cases=[('従来：12pxの正面',scene(base,old=True)),('追加：24pxの崖面',scene(base)),('中央1マス採掘',scene(base-{(2,2)},{(2,2)})),('端1マス採掘',scene(base-{(2,3)},{(2,3)})),('角1マス採掘',scene(base-{(1,3)},{(1,3)})),('3×3を全て採掘',scene(set(),base))]
canvas=Image.new('RGBA',(904,586),'#293a2f');dd=ImageDraw.Draw(canvas);dd.text((10,4),'オフライン構成比較｜各場面は原寸。実ゲーム画面ではありません。',font=font,fill='white')
for i,(label,o) in enumerate(cases):
 x=8+i%3*300;y=52+i//3*282;put(canvas,o,x,y);dd.text((x,y-22),label,font=font,fill='white')
canvas.save(R/'connection_cases.png')
hero=Image.new('RGBA',(1184,592),'#293a2f');d=ImageDraw.Draw(hero)
for i,(label,o) in enumerate(cases[:2]):put(hero,o.resize((576,504),Image.Resampling.NEAREST),8+i*592,44);d.text((8+i*592,17),label+' / nearest 2倍',font=font,fill='white')
d.text((12,563),'構成見本・未実装｜主人公v1／柴犬Cは原画を維持。占有48×42・崖面24px・接地位置を維持。',font=font,fill='white');hero.save(R/'before_after_2x.png')
frames=[scene(base,damage=s) for s in range(4)]+[scene(base-{(2,3)},{(2,3)})]
strip=Image.new('RGBA',(5*288,282),'#293a2f');d=ImageDraw.Draw(strip)
for i,(label,o) in enumerate(zip(['完全','軽い欠け','大きな欠け','完了直前','採掘後'],frames)):put(strip,o,i*288,28);d.text((i*288+8,6),label,font=font,fill='white')
strip.save(R/'mining_states.png');frames[0].save(R/'mining_comparison.gif',save_all=True,append_images=frames[1:],duration=[800]*5,loop=0,disposal=2)
# Per requested group: inventory and per-file table, including exact existing references.
groups=['rock_biome/top','rock_biome/cliff','rock_biome/border','rock_biome/decor','rock_biome/mineable','rock_biome/mined_states','rock_biome/drops','woodcut']
for group in groups:
 folder=D/group;folder.mkdir(parents=True,exist_ok=True)
 rows=[dict(a,path=D/a['file'],label=a['file'][len(group)+1:]) for a in M['assets'] if a['file'].startswith(group+'/')]
 roles={'rock_biome/mineable':'mineable.','rock_biome/drops':'drops.','woodcut':'woodcut.','rock_biome/decor':'decor.'}
 for a in M['reuse']:
  if group in roles and a['role'].startswith(roles[group]):rows.append(dict(a,path=D/a['file'],label='REF '+a['role']))
 cols=5;cw=190;ch=165;out=Image.new('RGBA',(cols*cw,38+math.ceil(len(rows)/cols)*ch),'#6c7c50');d=ImageDraw.Draw(out);d.text((8,7),group+' / nearest 2x / REF = existing PNG',font=font,fill='white')
 for k,a in enumerate(rows):
  o=im(a['path']);o=o.resize((o.width*2,o.height*2),Image.Resampling.NEAREST);x=k%cols*cw;y=38+k//cols*ch;put(out,o,x+(cw-o.width)//2,y+2);label=a['label'];d.text((x+4,y+135),label[:29],font=small,fill='white')
 out.save(folder/'INDEX.png')
 lines=['# '+group,'','[一覧画像](INDEX.png) / [全体の取り込み仕様](%sHANDOFF.md)' % ('../'*len(group.split('/'))),'','追加PNGと既存参照を区別。INDEX.pngは確認用で本番素材ではありません。','',f'新規{sum(not a["label"].startswith("REF") for a in rows)}枚／既存参照{sum(a["label"].startswith("REF") for a in rows)}枚。PNGの枠と占有は別です。','', '| ファイル / 参照 | 用途 | 寸法 | 基準点 | 占有 |','|---|---|---|---|---|']
 import os
 for a in rows:
  rel=Path(os.path.relpath(a['path'],folder)).as_posix();lines.append(f'| [{a["label"]}]({rel}) | {a.get("usage",a.get("role"))} | {a["size_px"]} | {a["anchor_px"]} | {a["occupied_cells"]} |')
 lines+=['','静止状態保持：frame_order=[0]、duration_ms=null、loop=false。採掘時間や資源量は画像で決めません。','接続岩はN1/E2/S4/W8。地表境界は別判定。マスク・内角・重ね順は全体HANDOFFを参照。']
 (folder/'README.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
# Light/dark alpha audit visual.
show=[im(D/'rock_biome/mineable/v0/mask_00.png'),im(D/'rock_biome/mineable/v1/mask_03.png'),im(D/'rock_biome/drops/crushed_stone.png'),im(D/'woodcut/fallen_trunk.png')]
out=Image.new('RGBA',(760,330));d=ImageDraw.Draw(out)
for row,col in enumerate(['#24382e','#eee3c7']):
 d.rectangle((0,row*165,759,row*165+164),fill=col)
 for i,o in enumerate(show):put(out,o.resize((o.width*2,o.height*2),Image.Resampling.NEAREST),i*190+15,row*165+18)
out.save(R/'alpha_light_dark.png')
html='''<!doctype html><meta charset="utf-8"><title>岩場の立体素材 v1</title><style>body{background:#25372d;color:#f6efd9;font:16px sans-serif;max-width:1200px;margin:24px auto}img{max-width:100%;image-rendering:pixelated}a{color:#e0c890}section{margin:24px 0}h1{font-size:26px}</style><h1>岩場の立体素材 v1</h1><p>オフライン構成比較です。実ゲームでの描画確認ではありません。</p><p><a href="HANDOFF.md">取り込み仕様</a> · <a href="manifest.json">manifest</a></p>'''
for name,title in [('before_after_2x.png','従来と追加：上面と崖面'),('connection_cases.png','部分採掘・接続確認（原寸）'),('mining_states.png','採掘進行'),('mining_comparison.gif','状態比較：800ms/段階、ゲーム時間とは無関係'),('alpha_light_dark.png','明暗背景の透過'),('runtime_scale_reference.png','現行描画倍率の近似比較：カメラ1.5倍、主人公1.4375倍・柴犬静止1.25倍。実ゲーム撮影ではありません。')]:html+=f'<section><h2>{title}</h2><img src="review/{name}"></section>'
for group in groups:html+=f'<section><h2>{group}</h2><a href="{group}/README.md">対応表</a><img src="{group}/INDEX.png"></section>'
(D/'index.html').write_text(html,encoding='utf8')
print('Review sheets and folder indexes saved.')


