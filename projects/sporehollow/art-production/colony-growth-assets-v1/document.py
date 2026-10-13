from pathlib import Path
from PIL import Image
import json,hashlib
P=Path(__file__).resolve().parents[2];D=P/'art_delivery';O=D/'colony_growth_assets_v1'
m=json.loads((O/'manifest.json').read_text(encoding='utf8'))
m['occupancy_note']='goldA 2x2 existing; others are art footprint proposals, not activated placement/collision rules'
m['adoption_record']='ADOPTION.md'
m['motion_scope']='formal still/keypose delivery, not full motion package'
for r in m['reuse']:
 r.setdefault('anchor_px',[r['size_px'][0]//2,r['size_px'][1]//2])
 r.setdefault('layer','effect_overlay');r.setdefault('frame_order',[0]);r.setdefault('frame_duration_ms',[None]);r.setdefault('loop',False)
for a in m['animations']:
 a['frame_sizes_px']=[];a['frame_anchors_px']=[]
 for f in a['frame_files']:
  assert (O/f).exists(),f
  im=Image.open(O/f);a['frame_sizes_px'].append(list(im.size));a['frame_anchors_px'].append([im.width//2,im.height//2])
(O/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf8')
table='# 完成PNG一覧\n\n静止・接触28点。静止はduration=null（状態保持）、loop=false。SHA256、原画、占有はmanifest。\n\n|ファイル|寸法|アンカー|\n|---|---|---|\n'
for r in m['assets']:
 table+=f"|{r['file']}|{r['size_px'][0]}×{r['size_px'][1]}|{tuple(r['anchor_px'])}|\n"
 assert hashlib.sha256((O/r['file']).read_bytes()).hexdigest()==r['sha256']
(O/'ASSET_LIST.md').write_text(table,encoding='utf8')
names=[('review_idol_ui.png','黄金像：小UI専用'),('preview_idol_4states.png','黄金像：4段階'),('preview_adopted_A.png','ラジオB・記録・作業接触'),('preview_adopted_B.png','住人・畑・寝床・見張り・箱'),('review_alpha.png','明暗背景の透過')]
html='<!doctype html><meta charset="utf-8"><title>拡張採用素材v1</title><style>body{background:#253b32;color:#f0dfbf;font:16px sans-serif;margin:24px}a{color:#c8e2b2}img{display:block;max-width:100%;image-rendering:pixelated}img.native{max-width:none}</style><h1>拡張採用素材v1</h1><p>28点の透過PNG。静止・接触姿勢の先行納品／連続動作は未収録。</p><p>確認画像は合成プレビュー／未実装。画像クリックで100%表示。</p><p><a href="HANDOFF.md">納品書</a> / <a href="ASSET_LIST.md">PNG一覧</a> / <a href="ADOPTION.md">採用記録</a> / <a href="../wall_connection_preview_v1/index.html">壁8形状</a></p>'
for n,l in names:html+=f'<h2>{l}</h2><img src="{n}" onclick="this.classList.toggle(\'native\')">'
(O/'index.html').write_text(html,encoding='utf8')
print('manifest and index validated')

