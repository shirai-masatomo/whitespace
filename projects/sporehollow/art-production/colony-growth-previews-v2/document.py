from pathlib import Path
import json,hashlib,html
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parent; P=R.parents[1];D=P/'art_delivery';O=D/'colony_growth_previews_v2';W=R/'working'
I=Path(r'C:/Users/masat/Documents/Codex/2026-10-10/task/colony-structure-01-work/projects/sporehollow')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
rows=[
('A1','古いラジオ','radio','木箱型／緑の金属ケース型','Aを推奨。既存の木・生成りと馴染む。Bは丸いスピーカーが読みやすい。','放送中の音波は控えめで静止画だけだと差が小さい。採用後は緩い2コマか明るさ変化を比較。','40×36／(20,32)。盤面は仮1マス以内、UIは24pxアイコン・48px枠。','設置・携行・入手表示のどれに使うか。ニュース本文と入手日は既存データを使う。','本体1、音波2、24px専用アイコン1、48px資料版1＝最大5点。','音波 effects_v1、UI枠の色。ラジオ本体は今回の候補。'),
('A2','黄金像の状態','idol_states','元静止／夜に祈れる／祈り中／軽い損傷：各1案','元のgoldA＋独立オーバーレイを推奨。顔・形・模様は再生成していない。','軽い損傷は装飾に埋もれやすい。台座に絞り、影からはみ出ないよう補正した。夜の視認性は実装後に確認が必要。','144×160／(72,152)、既存2×2。表示倍率1。','既存の祈り可否と損傷表示条件へ従う。軽傷専用の新閾値は決定しない。','通常0（再利用）、弱光1、祈り粒子1～2、損傷1＝追加3～4点。','goldA、build_complete/01、rock/damage/lightを合成見本に再利用。'),
('A3','採掘・伐採姿勢','work_pose','採掘と伐採の命中姿勢・左右各1例','腕と道具を同じ姿勢として接続する方向を推奨。顔・帽子は主人公v1の画素を復元。','振りかぶり試作は腕が不明瞭なので未採用。今回は命中のみ。現在コード工具の再現との比較であり、実際のジョブを動かした証拠ではない。','比較キャンバス80×64／右(28,56)、左(52,56)。元の32×48人物は右(12,12)に相当。倍率1.4375。','接触フック・道具の前後・岩山の接触セル。ダメージ、作業速度、占有は変更しない。','採用後、各動作3～4姿勢×左右＝6～8、2動作合計12～16フレーム案。現時点は本制作0。','既存顔・帽子、正式4×4岩山、小岩、tree_a。既存コード工具を図示して比較。'),
('A4','父の日誌・手紙','father_notes','手帳1案＋短い手紙1案','素朴な布表紙の手帳と折り目の手紙を用途別に推奨。緑＋金の図鑑と区別。','小物単体に新しい本文、記号、文明や結末を固定しない。読書用紙面の寸法は未決。','手帳40×40／(20,36)、手紙40×36／(20,32)。UI用途、盤面1マス内は縮尺比較のみ。','発見演出、本文の置場、所持品として扱うかは未確定。','手帳表紙1、短文の紙面1、必要なら開いた手帳1＝2～3点。','採用済み journal_cover_green は比較参照だけ。図鑑本文・ページはそのまま使う。'),
('B1','2人目の住人','resident','A 藍の上着＋額布／B 生成り＋前掛け','Aを推奨。主人公の帽子と柴犬の暖色に対して、小さくても識別しやすい。','A/Bとも成人の作業者候補。髪型・顔は新人物案であり加入人物の採用を意味しない。Bは草色に馴染みすぎる。','40×48／(20,44)、身体高42px。仮1セル、倍率1.4375。','具体人物、名前、能力、加入条件。既存の人間動作設計を流用するか。','採用後の最小左右idle/walkは2＋8＝10コマ案。作業はA3方式の流用可否を別確認。','既存主人公の足元・身体高・歩行フレーム設計を参照。メイド衣装の単純流用は一般住人との混同が大きい。'),
('B2','畑と作物','farm','A 不規則な土の連なり／B 整然とした列','B配置を推奨し、境界の不規則さはA程度に留める。作物は淡色根菜の候補1種。','Aは隣の状態が重なって読みにくい。初稿の2px差が弱かったため不規則な土の連なりを追加し比較。5見本は5論理状態の要求ではない。','1セル48×42／(24,40)。4×4区画192×168、見た目の草・葉はセル内。','作物名、種アイテム、収量、日数、土壌ルールは未確定。ロードマップの4論理状態へ対応させる。','土1、播種表現1、植物3、外縁最大4＝5～9点案。種の現物PNGは要求しない。','既存草地は無改変。地面・UIを再生成せず、1種の土と植物候補だけを合成。'),
('B3','簡易寝床','bed','A 敷き寝具／B 低い木枠','最初はAを推奨。Bは家具として分かりやすく屋内向き。','休息ゾーンは既存の範囲表示であり寝具ではない。既存休息・睡眠コマを寝床へ直接重ねると向きが合わない可能性。','48×84／(24,78)、仮1×2セル。人物と同時に通常倍率で比較。','占有、出入り位置、睡眠中の方向、休息ゾーンとの関係、効果。','寝具後層1＋掛布前層1＋必要なら使用中差分1＝2～3点。人物睡眠は流用可否を確認。','既存木床、08_zonesの休息範囲、人物の身体高を再利用。寝具PNGは監査範囲で未発見。'),
('B4','見張り地点','watch','A 鐘の標識／B 低い木札、16px警戒アイコン2案','A標識＋三角アイコンを推奨。鐘形は施設との対応、三角は警戒状態の識別に強い。','後段P10向けのスケッチ。見張り塔・自動レーダー・敵位置マーカーではない。正式な造形仕上げは保留。','48×56／(24,50)、仮1セル。警戒アイコン16×16、UI層で分離。','予兆の根拠、警戒の解除、設備効果、占有が未確定。','採用後、本体1＋必要なら状態1＋アイコン2＝3～4点案。今はスケッチのみ。','既存木壁・扉・ロックを再利用した配置比較。UIアイコンは現行の小型描画に合わせた図形ラフ。'),
('B5','非戦闘イベント','event','物資箱1案＋現地カードA／通知カードB','Aカードを推奨。どの箱に対する選択か分かる。Bは見落としを減らす用途向き。','木箱は小さいと木材現物に近づくため無地札を太く補正。数量・中身の表示を加える場合は動的UIにする。','48×42／(24,38)、仮1セル。カードA355×175、B375×202。','事件期限、所有者、中身、選択結果、回収の仕事登録条件。','箱1、必要なら開封差分1、16/24px通知1＝2～3点。新NPC0。','既存 wood/stone の24pxアイコンと比較、現行クリーム色カード配色を再利用。')]
# Full source evidence ledger, including supplied screenshots read during audit.
refs=[]
for rel in ['review/current/ui_survey/'+n+'.png' for n in ['01_field','02_map','03_keeper','05_roles','06_architect_0','08_zones','10_animals','19_idol','20_prayer']]+['review/current/story/20_morning_with_radio.png','review/current/story/21_radio_history.png','ART_SPEC.md','assets/ui/SOURCES.md','game/story_view.gd','game/harvest_view.gd']:
 f=I/rel;refs.append({'branch':'codex/sporehollow-biome01','commit':'cf004ab82f5e09e4141507bcd791aba76735d998','path':'projects/sporehollow/'+rel,'sha256':sha(f)})
for rel in ['characters_v1/keeper_idle_right_00.png','characters_v1/shiba_idle_right_00.png','ui_world_direction_v1/candidates/world/goldA.png','ui_world_direction_v1/candidates/world/tree_a.png','mining_rock_objects_v1/rock_large_4x4_stage1.png','mining_rock_objects_v1/rock_small_1x1_stage1.png','wood_buildings_v1/floor/wood_00.png','cart_ui_detail_v1/cart.png','equipment_icons_v1/collar.png']:
 f=D/rel;refs.append({'branch':'codex/sporehollow-art-assets','commit':'3229d2655e35e82d178577cdd8acbbe66e9be4f8','path':'projects/sporehollow/art_delivery/'+rel,'sha256':sha(f),'reused_without_overwrite':True})
refs.append({'source':'user supplied roadmap v1.1','path':'references/roadmap_v1.1_2026-10-13.md','sha256':sha(R/'references/roadmap_v1.1_2026-10-13.md'),'priority_sections':[14,17]})
(O/'source_receipt.json').write_text(json.dumps(refs,ensure_ascii=False,indent=2),encoding='utf-8')
wm=json.loads((R/'working_manifest.json').read_text(encoding='utf-8'));manifest={'status':'direction_review_only','runtime_ready':False,'formal_assets_delivered':0,'screen_evidence':False,'cell_px':[48,42],'base_screenshot_px':[1280,800],'world_camera_zoom':1,'screen_y_offset_on_sheet':80,'keeper_scale':1.4375,'shiba_idle_scale':1.25,'tree_scale':1.35,'day_tint':{'source':'main.gd morning05:00','overlay_rgb':[0.03,0.06,0.20],'alpha':0.22},'candidate_geometry':wm,'previews':[]}
for f in sorted(O.glob('preview_*.png')):manifest['previews'].append({'file':f.name,'dimensions':Image.open(f).size,'sha256':sha(f),'label':'合成プレビュー／未実装','contains_native_game_composite':True,'zoom_detail':'nearest2x'})
(O/'preview_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
intro='''# 拡張プレビュー v2 — 初回比較

**合成プレビュー／未実装。全候補は採用待ちです。** 正式PNG・全動作・新規データは今回納品していません。ゲーム内で動作確認した証拠ではありません。

2026-10-13受領のロードマップv1.1の14章・17章と、画像担当指示v2に基づきます。A群を先頭に、B群は比較ラフ、C群は未着手、D群は対象外です。

[画像で見る入口](index.html) ／ [縮尺一覧](preview_scale_sheet.png) ／ [既存素材監査](EXISTING_ASSET_AUDIT.md) ／ [出典・ハッシュ](source_receipt.json) ／ [比較用寸法記録](preview_manifest.json)

通常倍率の元画面1280×800を各シートの上から80pxの位置に配置し、その中へ候補だけを合成。下段は同じ合成結果のnearest2倍です。Webの縮小表示では細部判断せず、画像を100%表示してください。朝05:00の画面に合わせ、追加した盤面画像にも既存と同じ朝色の被せ方を再現しました。UI見本には朝色を掛けていません。

## 候補別の評価

|テーマ|比較画像|推奨|現在の扱い|
|---|---|---|---|
'''
text= intro+'\n'.join(f'|{r[0]} {r[1]}|[{r[3]}](preview_{r[0]}_{r[2]}.png)|{r[4]}|'+('A先行比較' if r[0].startswith('A') else 'Bラフ')+'|' for r in rows)
for r in rows:
 text+=f'\n\n## {r[0]} {r[1]}\n\n- 候補差：{r[3]}\n- 推奨：{r[4]}\n- 自己批評・修正：{r[5]}\n- 寸法・基準点：{r[6]}\n- 未確定ルール：{r[7]}\n- 正式制作の差分見積もり：{r[8]}\n- 既存素材との重複・再利用：{r[9]}\n'
text+='''

## 引き渡し条件

基準点は画像左上原点、x右/y下。上記の新規候補の占有と寸法は提案で、ゲームの当たり判定・建築費・所持品定義を確定しません。A3の接触座標は [work_contact_proposal.json](work_contact_proposal.json) に記録。キーポーズの接触時刻は既存harvestのstrikeフックへ結び付ける想定ですが、フレーム時間・判定は実装側の仕様に従います。

表示層案：草地→耕土/床/寝具後層→人物・像・小物（接地y順）→寝具前掛布/接触工具前層→小さな光/音波→UI。新しい落ち影PNGは作っていません。元の像・樹木・岩の陰影は保持し、実装時に接地影を追加する場合は二重影を点検してください。

採用後に限り、必要な候補をピクセル単位で仕上げ、分離RGBA・アンカー・状態・時間・manifest・HANDOFF・再利用表を正式納品します。作業姿勢の振りかぶりと戻り、寝床使用時の人体、作物境界の全接続などは未完成です。未採用候補のモーションは制作しません。

## 制作記録

組込みのimagegenを原案に使用。外部有料APIなし。原画・生成指示・比較用加工は `../../art-production/colony-growth-previews-v2/`。生成画像を縮小するだけで終えず、ラジオのスピーカー/つまみ、物資箱の無地札、人物の採用済み顔の復元、接触点、像の損傷マスク、畑の境界を実寸で補正しました。正式素材の品質認定を意味しません。

ゲーム・セーブ・UID・本番シーン・規則は変更なし。ゲームEXEの起動・再生成なし。通常ゲームの入口・既存の未保存作業に触れていません。
'''
(O/'PREVIEW_INDEX.md').write_text(text,encoding='utf-8')
audit='''# 既存資産監査 — 2026-10-13

調査時のGitHubブランチ先端を照合：

- `codex/sporehollow-art-assets`：`3229d2655e35e82d178577cdd8acbbe66e9be4f8`
- `codex/sporehollow-biome01`：`cf004ab82f5e09e4141507bcd791aba76735d998`

素材専用の既存worktreeを継続利用。実装ブランチは読み取りのみ。後から進んだ実装をこのスナップショットの実証と混ぜない。

## 現行画面・資料

指定の01_field、02_map、03_keeper、05_roles、06_architect_0、10_animals、19_idol、20_prayerに加えて08_zonesを目視。01_fieldはカメラ1倍、02_mapは0.48倍なので縮尺比較には01を使う。19/20は像の選択/夜の祈りの現行表示を確認する資料。goldAの実寸・アンカーはstory_view.gdを優先する。

過去のstory/20_morning_with_radioと21_radio_historyも目視。ラジオ入手・ニュース記録・再読UIが存在する。これらは旧画面であり、最新連続時計UIからの導線完成を証明しない。A1内には旧履歴見出しの切り抜きへ小アイコンを置き、過去画面への仮合成と表示。

現行ART_SPECとassets/ui/SOURCES、既存manifest/HANDOFFを照合。古いART_SPECの「黄金像未納品」は後段のgoldA採用記録により更新済み。旧茶色表紙ではなく、現在の緑＋金のjournal_cover_greenを図鑑の採用参照にする。

受領した `WhistleRanch_拡充設計ロードマップ_v1.1_簡単順_2026-10-13.md` は14章/17章を優先。本文中の実装担当向け指示を、この画像作業からゲームを変更する権限とは扱わない。

## 使える既存素材と不足範囲

|対象|既存の実体|今回の判断|
|---|---|---|
|主人公・柴犬|characters_v1、characters_motion_v1。32×48/(16,44)、48×48/(24,44)|既存PNG再利用。頭部の顔・帽子を作業姿勢へ復元。柴犬Cを再縮小しない|
|一般人物の動作設計|主人公、商人、メイドなどの左右正式動作|足元/時間設計を参照。特徴的な衣装をそのまま一般住人として転用する案は見分けにくい|
|黄金像|ui_world_direction_v1/candidates/world/goldA.png、144×160/(72,152)|採用元を保持。既存コード効果があり、独立した正式状態PNGとは区別|
|岩山/小岩| mining_rock_objects_v1 の正式PNG |4×4と1×1の採掘姿勢の背景にそのまま使用|
|樹木|tree_a/b/c、64×80/(32,72)、実描画1.35倍|伐採比較はtree_a使用、全体再生成なし|
|建材|wood_buildings_v1、earth_stone_buildings_v1|木床・木壁・扉/柱/ロックを再利用。建築仕様は変更なし|
|図鑑・荷車|現行assets/ui/journal_cover_green.png、ranch_assets_v1の紙面、cart_ui_detail_v1/cart.png、merchant_board_v1|採用素材を維持。手帳を装飾の少ない茶系にして図鑑と区別|
|資源・装備・UI|resource_icons_v1、equipment_icons_v1/collar、ui_styleの小アイコン、paper-frame.svg|物資現物・配色・UI寸法を参照。既存首輪を重複生成しない|
|作業エフェクト|effects_v1 の音波/完成粒子/木くず/石粉|音波と小粒子を合成見本で再利用。新エフェクト大量制作なし|
|ラジオ本体|radio取得/ニュース/旧履歴UIは存在。両ブランチのart_delivery/assets/uiに本体PNGは未発見|本体2候補のみ制作。外部の未確認納品先まで不存在とは断言しない|
|父の日誌・手紙|記録画面/文章と図鑑用紙面は存在。専用小物PNGは監査範囲で未発見|手帳・短い手紙を各1案、内容は凍結|
|採掘/伐採人体|harvest_view.gdの工具仮描画、既存主人公|人体作業コマ不足。命中キーだけ比較。正式全動作は未完成|
|畑・寝具・見張り・事件箱|休息範囲/木床/物資現物はあるが、該当する正式専用PNGは監査範囲で未発見|B群の比較ラフだけ。設備・住人・商品データなし|

## 保全・出典

[source_receipt.json](source_receipt.json)に読んだ画面・主要素材のSHA256を保存。原画は組込みimagegen。参考ゲームの素材をコピー/トレースしていない。既存の正式PNGは上書きしていない。合成用の01/08/旧21と現行図鑑表紙のみ制作記録へスナップショット保存（参照元は実装ブランチ、再納品ではない）。

今回の比較PNGは実ゲームの検証資料フォルダへ置かない。ソース・セーブ・ゲームルール変更、本番起動、動作確認済みの宣言はしていない。C群の種・装備・世界変化とD群は禁止/保留のまま。
'''
(O/'EXISTING_ASSET_AUDIT.md').write_text(audit,encoding='utf-8')
(R/'README.md').write_text('''# Preview production only

14 built-in imagegen concept calls (not final asset delivery). `originals/` preserves originals; `generation.json` records prompts and tool output paths. `working/` contains disposable normalized composition ingredients, not runtime sprites. `prepare.py` and `compose.py` create review-only outputs. Rejected windups are preserved only in original sheets and are not completed animations.

Reference screenshots/cover are unmodified snapshots from biome01 cf004ab; exact provenance is in delivery/source_receipt.json. Native goldA and other existing sprites are read directly from art_delivery and not duplicated as new assets. No API key or external paid service used.
''',encoding='utf-8')
# Lightweight local gallery: preview labels stay visible, 1x option is explicit.
parts=['<!doctype html><html lang="ja"><meta charset="utf-8"><title>拡張プレビュー v2</title><style>body{background:#253b32;color:#ecdfbc;font:16px Meiryo,sans-serif;margin:28px}a{color:#e6c777}h1{font-size:28px}article{margin:32px 0;padding:18px;background:#30493c;border:1px solid #637253}img{display:block;width:100%;max-width:1280px;image-rendering:pixelated}button{padding:10px;background:#e2d1a5;color:#304638;border:0;cursor:pointer}.frame{overflow:auto}.native img{width:1280px;max-width:none}.note{color:#b9c9ac}nav a{margin-right:20px}</style><h1>拡張プレビュー v2</h1><p>合成プレビュー／未実装。正式採用・ゲーム動作確認の資料ではありません。</p><nav><a href="PREVIEW_INDEX.md">評価・未確定事項</a><a href="EXISTING_ASSET_AUDIT.md">既存素材監査</a><a href="#A1">A群</a><a href="#B1">B群</a><a href="#scale">縮尺</a></nav>']
for r in rows:
 parts.append(f'<article id="{r[0]}"><h2>{r[0]} {r[1]}</h2><p>{r[4]}</p><p class="note">{r[5]}</p><button onclick="this.nextElementSibling.classList.toggle(\'native\')">画面に収める／画像100%に切替</button><div class="frame"><a href="preview_{r[0]}_{r[2]}.png"><img loading="lazy" src="preview_{r[0]}_{r[2]}.png" alt="合成プレビュー／未実装 {r[1]}"></a></div></article>')
parts.append('<article id="scale"><h2>縮尺一覧</h2><a href="preview_scale_sheet.png"><img src="preview_scale_sheet.png" alt="合成プレビュー／未実装 縮尺"></a></article></html>');(O/'index.html').write_text(''.join(parts),encoding='utf-8')
print('audit/index/gallery/preview metadata saved')
