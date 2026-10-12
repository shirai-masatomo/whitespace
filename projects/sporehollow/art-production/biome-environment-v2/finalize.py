from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,re,hashlib
S=Path(__file__).resolve().parent;P=S.parents[1];D=P/'art_delivery/biome_environment_v2';V=P/'art_delivery/biome_environment_v1';m=json.loads((D/'manifest.json').read_text(encoding='utf-8'))
def im(f):return Image.open(f).convert('RGBA')
font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',13)
# Tree difference comparison keeps original body pixels. No new full trees.
o=Image.new('RGBA',(1060,640),'#73874f');dr=ImageDraw.Draw(o)
for row,(t,name) in enumerate([('c','small'),('b','medium'),('a','large')]):
 tree=im(P/f'art_delivery/ui_world_direction_v1/candidates/world/tree_{t}.png');poses=[tree]
 for f in [V/f'forest/notch_{t}_light.png',V/f'forest/notch_{t}_deep.png',D/f'tree_cut/{name}_near_fall.png']:
  a=tree.copy();a.alpha_composite(im(f));poses.append(a)
 poses.append(im(V/f'forest/stump_{t}.png'))
 poses[3]=im(D/f'tree_cut/{name}_near_fall_body.png')
 for col,a in enumerate(poses):
  x=20+col*205;y=35+row*200;pos=(x-48,y-32) if col==3 else (x,y);o.alpha_composite(a.resize((a.width*2,a.height*2),Image.Resampling.NEAREST),pos);dr.text((x,y+164),name+' / '+['standing','chop1','chop2','near fall','stump'][col],font=font,fill='white')
dr.text((10,10),'OFFLINE / existing trees kept pixel-exact / 2x view',font=font,fill='white');o.save(D/'review/tree_states.png')
lines=['# ファイル一覧','', '| ファイル | 寸法 | アンカー | レイヤー | 用途 |','|---|---|---|---|---|']
for a in m['assets']:lines.append('| '+a['file']+' | '+str(a['size_px'])+' | '+str(a['anchor_px'])+' | '+a['layer']+' | '+a['usage']+' |')
lines+=['','## 再利用対応（コピー不要）','', '| ロール | 既存PNG | 寸法 | アンカー | 時間ms |','|---|---|---|---|---|']
for a in m['reuse']:lines.append('| '+a['role']+' | '+a['file']+' | '+str(a['size_px'])+' | '+str(a['anchor_px'])+' | '+str(a['duration_ms'])+' |')
(D/'FILES.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
for folder,roles in [('tree',['tree.']),('fx_mining',['fx_mining.','fx_mining_chips']),('fx_logging',['fx_logging.','fx_falling_leaves'])]:
 d=D/folder;d.mkdir(exist_ok=True);refs=[a for a in m['reuse'] if any(a['role'].startswith(r) for r in roles)]
 (d/'references.json').write_text(json.dumps({'path_base':'../manifest.json directory','assets':refs},ensure_ascii=False,indent=2)+'\n',encoding='utf-8');(d/'README.md').write_text('既存正式PNGを再利用します。references.jsonのfileはこのフォルダではなくbiome_environment_v2/起点です。PNGの重複コピーはありません。\n',encoding='utf-8')
html='''<!doctype html><html lang="ja"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>草原と岩場・採掘伐採追加 v2</title><style>body{max-width:1100px;margin:28px auto;padding:0 20px;background:#293d30;color:#eee4cd;font:17px/1.6 sans-serif}a{color:#ead39d}img{max-width:100%;height:auto;image-rendering:pixelated}section{margin:36px 0}summary{cursor:pointer}</style><h1>草原↔岩場・採掘伐採 追加 v2</h1><p>小・中・大の岩塊4段階、自然な地表境界、採掘跡、伐採後の丸太・枝葉。58枚の追加透過PNG。既存の16接続岩壁・樹木・切株・短い演出は再利用しています。</p><p><strong>以下は構成確認用のオフライン合成です。ゲーム内での動作確認済み画像ではありません。</strong></p><p><a href="HANDOFF.md">納品書</a> / <a href="FILES.md">ファイル用途一覧</a> / <a href="manifest.json">manifest</a> / <a href="IMPLEMENTATION_NOTES.md">実装担当への接続メモ</a> / <a href="../biome_environment_v1/index.html">既存v1</a></p>'''
for title,f in [('草原から岩場への原寸構成例','transition_scene.png'),('採掘岩の削れ方（原寸＋2倍）','node_states.png'),('採掘段階の連続表示','mining_states.gif'),('既存の木と伐採段階','tree_states.png')]:html+=f'<section><h2>{title}</h2><img src="review/{f}" alt="{title}"></section>'
html+='<details><summary>境界・角・帯の全種類</summary><img src="review/transitions.png" alt="境界素材"></details><details><summary>全追加素材の明暗透過確認</summary><img src="review/inventory_alpha.png" alt="明暗確認"></details></html>';(D/'index.html').write_text(html,encoding='utf-8')
for link in re.findall(r'(?:href|src)="([^"]+)"',html):assert (D/link).exists(),link
print('Finalized documentation, tree comparison, reuse catalogs and HTML links.')
