from pathlib import Path
import json,hashlib
from PIL import Image,ImageDraw
import numpy as np
p=Path('projects/sporehollow');o=p/'art_delivery/crafting_assets_v1';s=p/'art-production/crafting-assets-v1'
m=json.loads((o/'manifest.json').read_text(encoding='utf8'));checks=[]
def ck(n,v):
 checks.append({'check':n,'pass':bool(v)})
 assert v,n
for a in m['assets']:
 f=o/a['file'];im=Image.open(f);z=np.array(im);alpha=z[:,:,3];box=im.getbbox()
 ck(a['file']+' RGBA/dimensions',im.mode=='RGBA' and list(im.size)==a['size_px'])
 ck(a['file']+' hash',hashlib.sha256(f.read_bytes()).hexdigest()==a['sha256'])
 ck(a['file']+' transparent margin',box[0]>0 and box[1]>0 and box[2]<im.width and box[3]<im.height)
 ck(a['file']+' hard alpha',set(np.unique(alpha))=={0,255})
 ck(a['file']+' clean invisible RGB',np.all(z[alpha==0]==0))
 ck(a['file']+' palette <=32',len(np.unique(z[alpha>0,:3],axis=0))<=32)
 if a['usage']=='world':ck(a['file']+' fixed ground baseline',box[3]==a['anchor_px'][1])
 if a['id']=='egg_meal':ck(a['file']+' opaque white retained',int(((z[:,:,0]>220)&(z[:,:,1]>205)&(z[:,:,2]>160)&(alpha==255)).sum())>20)
ck('11 world and 11 UI',sum(a['usage']=='world' for a in m['assets'])==11 and sum(a['usage']=='ui' for a in m['assets'])==11)
q=dict(passed=True,count=len(checks),checks=checks,runtime_verified=False,visual_review=['native field composite','native wood floor composite','nearest3x catalogue','dark/light alpha','tool/food pixel inspection'])
(o/'QA.json').write_text(json.dumps(q,ensure_ascii=False,indent=2),encoding='utf8')
# Regenerate inspection from final pixels, not stale interim versions.
canvas=Image.new('RGBA',(1152,768),'#798b57')
for i,f in enumerate(['benches/cooking_bench','benches/carpentry_bench','benches/sewing_bench','food/egg_meal','food/roast_mushroom','items/fiber_clothes']):
 a=Image.open(o/(f+'.png')).convert('RGBA');canvas.alpha_composite(a.resize((a.width*8,a.height*8),Image.Resampling.NEAREST),(i%3*384,i//3*384))
canvas.convert('RGB').save(o/'preview/pixel_inspection.png')
lines=['# 製作設備・製作品 正式素材 v1','', '納品: `projects/sporehollow/art_delivery/crafting_assets_v1/`。ワールド11点＋UI11点、すべて透過RGBA PNG。静止1フレーム、nearest。既存の製作システムの見た目置換用。', '', '| ファイル | 実装ID | キャンバス | 接地点 | 実体サイズ |','|---|---|---|---|---|']
for a in m['assets']:
 if a['usage']=='world':lines.append(f"| [{a['file']}]({a['file']}) | `{a['id']}` | {a['size_px']} | {a['anchor_px']} | {a['body_px']} |")
lines+=['','## ワールド配置','', '設備・家具は48×48、足元(24,44)。セル中心pに対して接地点をp+(0,21)、画像左上をp+(-24,-23)へ置く。これは現行設備の脚の下端p.y+21と一致する。棚の上部はセルを越えるが占有は既存1マスのまま。透明な余白は切り詰めない。', '', '資材・服・料理は32×32、足元(16,28)。地面の配置点qから(16,28)を引いて置く。画像アンカーは接地線の直下を示し、最下段の可視ピクセルはanchor.y-1。画像寸法を48×42に引き伸ばさない。木箱/棚の現物ドロップにも同じworld画像を使えるが、実体サイズはmanifestのbody_pxに従う。', '', '調理台44×23、木工台44×23、裁縫台44×27の実体。既存仮表示の幅40pxに近い44pxで、通常倍率1×を基本とする。棚31×41は箱28×27より高い。既存主人公v1・柴犬Cは変更していない。比較では既存の現行描画倍率（主人公1.4375、柴犬1.25）も併記した構成とした。', '', '## 識別の基準','', '- 調理台: 暗い鍋・石の火床・まな板。木工台: 明るいのこぎり・板・万力。裁縫台: 前へ垂れた緑の布・糸巻き。', '- 木箱: 閉じた低い箱。棚: 空いた2段の棚板。商品の中身は描かない。', '- 繊維: 束ねた黄緑/枯草の穂。服: 首穴・袖・裾のある生成りチュニック。ユーザー指示で繊維模様・緑の斑点・継ぎ当てを除去し、無地の布へ変更。服はアイテム絵であり、人間の着用モーション差分ではない。', '- 焼きキノコ: 傘と軸・焦げ目。卵料理: 不透明な白身と黄色い黄身。焼き肉: 赤褐色の厚切り肉と焼き目。煮込み: 深い器・液面・具。', '', '## UI','', '各worldファイルと同じbasenameの `ui_icons/*.png` を同梱。全32×32、中心アンカー(16,16)、実体は最大28×28。world PNGをUIへ縮小して二重に潰すのではなく、このファイルを使用する。原画から別サイズへ再整形し同じ共通パレットで整理した。UI内の1×、2×表示をcatalogで比較。既存資源UIに大きい枠がある場合もnearest整数倍率を基本とする。', '', '## 取り込み時の注意','', '- `fiber_bundle.png`の実装IDは`fiber`。他はbasenameと実装IDが一致。設置操作ID `place_wood_crate` / `place_wood_shelf` は既存のまま。', '- item_catalogの旧アイコン別名（wood/mushroom/egg/meat/collar等）へ置換する前に、製作品の正確なIDでこの素材を選択する。生キノコや生卵の既存アイコンを全体で上書きしない。', '- 設備の仮矩形と上の仮アイコンは、本PNGへの置換時に重ねて描かない。建築途中・破壊後・HP表示は既存処理を維持。今回それらの新しい状態PNGやアニメは追加していない。', '- 各画像に落ち影なし。接地陰影は材質の陰影にとどめ、既存のゲーム側の影を必要に応じて1回だけ描く。nearest、straight RGBA、白抜きshaderは使わない。卵白・皿・布の明色は不透明。', '- 木箱/棚の収納容量、服の防御や耐久、料理の回復量、設備の性能、材料数・レシピ・UIDは素材側では変更していない。', '- フレーム順[0]、時間null（状態維持）、loop=false。アンカー・寸法・SHA256・用途はmanifest.json。', '', '## 検査と未完了範囲','', f'機械検査{len(checks)}項目を通過。RGBA・寸法・ハッシュ・透明余白・二値alpha・32色以内・接地線・卵白保持を検査。草地背景/木床/明暗背景と通常倍率で目視した。のこぎりの刃と包丁、黄身は最終サイズでピクセルを整えた。', '', '`preview/` はすべて比較用。world_nativeは既存実ゲーム画面への**合成プレビュー／未実装**であり、実ゲームへの統合成功を示す画面ではない。ゲームソース・EXE・セーブは変更していない。ゲームへの取り込み、並び順・影・UI倍率の隔離描画確認は実装担当へ引き継ぐ。', '', '## 出典','', '原画11枚と全プロンプトは `../../art-production/crafting-assets-v1/`。Codex内蔵画像生成を利用し、新規の有料APIなし。共有32色パレット、アルファ整形、等比サイズ、最終ピクセル修正、別UI整形、比較・検査を実施。参考にした採用アートは別デザインへ再生成・上書きしていない。']
(o/'HANDOFF.md').write_text('\n'.join(lines),encoding='utf8')
(o/'EXISTING_ASSET_AUDIT.md').write_text('''# 既存資産照合

実装参照 `codex/sporehollow-biome01` = `aa3eb39a18b250a3a34f987744eb1b6fd7b24cb9`。アート起点 `adb33aa07da2ec57959e0315963f15003ddcd085`。

- main.gdのCraft BENCHES分岐は矩形＋既存資材アイコンの仮表示。幅40px前後、脚下端はセル中心+21。今回ここを置換するPNGを制作。
- crafting_data.gdの設備/料理/家具/服IDを確認。fiberはitem_catalogの既存資材IDで、画像ファイル名のみfiber_bundle。
- resource_icons_v1: 木材/石材/土/金貨。今回の束・家具・料理と用途が異なるため維持。
- colony_growth_assets_v1: 非戦闘イベント用箱、寝床等は既存用途を維持。今回の空の簡素な木箱とは使い分ける。既存イベント箱に収納家具の役割を付けない。
- wood_buildings_v1の木床と壁、characters_v1の主人公/柴犬を縮尺・配色参考に使用。再制作なし。
- 正式な設備3種・今回の料理4種・服/繊維/空木箱/棚に一致する納品は確認範囲で見つからず、新規別フォルダで追加。
- review/current/craftingはテスト報告が中心。構成背景には最新参照ブランチで存在するui_survey/01_field.pngを使用。この画像は過去の画面記録であり製作機能の現行導線の完成証拠ではない。

本番データを変更せず原画・成果物・文書だけを納品する。
''',encoding='utf8')
(o/'FILE_LIST.md').write_text('# PNGファイル一覧\n\n'+'\n'.join(f"- [{a['file']}]({a['file']}) — {a['usage']}, {a['size_px']}, anchor {a['anchor_px']}" for a in m['assets']),encoding='utf8')
body=''.join(f'<section><h2>{title}</h2><a href="preview/{name}">PNG</a><div><img src="preview/{name}" alt="{title}"></div></section>' for name,title in [('world_native.png','ゲーム背景・通常倍率'),('catalog.png','11種とUI一覧'),('wood_floor.png','既存木床・通常倍率'),('wood_floor_2x.png','木床・nearest2倍'),('alpha_dark_light.png','明暗背景と透過')])
(o/'index.html').write_text('''<!doctype html><html lang="ja"><meta charset="utf-8"><title>製作設備・製作品 v1</title><style>body{background:#293f32;color:#eddfbc;font:16px sans-serif;margin:24px}a{color:#edcb7d}section{margin:30px 0}section div{overflow:auto}img{image-rendering:pixelated;max-width:none}</style><h1>製作設備・製作品：正式素材 v1</h1><p>world 11点 + UI 11点。合成プレビュー／未実装。画像は通常倍率（拡大版は明記）。</p><p><a href="HANDOFF.md">HANDOFF</a> / <a href="FILE_LIST.md">全PNG一覧</a> / <a href="manifest.json">manifest</a> / <a href="QA.json">検査記録</a></p>'''+body+'</html>',encoding='utf8')
print('QA passed',len(checks))
