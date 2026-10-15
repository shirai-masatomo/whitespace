# 製作設備・製作品 正式素材 v1

納品: `projects/sporehollow/art_delivery/crafting_assets_v1/`。ワールド11点＋UI11点、すべて透過RGBA PNG。静止1フレーム、nearest。既存の製作システムの見た目置換用。

| ファイル | 実装ID | キャンバス | 接地点 | 実体サイズ |
|---|---|---|---|---|
| [benches/cooking_bench.png](benches/cooking_bench.png) | `cooking_bench` | [48, 48] | [24, 44] | [44, 23] |
| [benches/carpentry_bench.png](benches/carpentry_bench.png) | `carpentry_bench` | [48, 48] | [24, 44] | [44, 23] |
| [benches/sewing_bench.png](benches/sewing_bench.png) | `sewing_bench` | [48, 48] | [24, 44] | [44, 27] |
| [placeables/wood_crate.png](placeables/wood_crate.png) | `wood_crate` | [48, 48] | [24, 44] | [28, 27] |
| [placeables/wood_shelf.png](placeables/wood_shelf.png) | `wood_shelf` | [48, 48] | [24, 44] | [31, 41] |
| [items/fiber_bundle.png](items/fiber_bundle.png) | `fiber` | [32, 32] | [16, 28] | [24, 20] |
| [items/fiber_clothes.png](items/fiber_clothes.png) | `fiber_clothes` | [32, 32] | [16, 28] | [26, 21] |
| [food/roast_mushroom.png](food/roast_mushroom.png) | `roast_mushroom` | [32, 32] | [16, 28] | [24, 14] |
| [food/egg_meal.png](food/egg_meal.png) | `egg_meal` | [32, 32] | [16, 28] | [24, 12] |
| [food/roast_meat.png](food/roast_meat.png) | `roast_meat` | [32, 32] | [16, 28] | [24, 15] |
| [food/stew.png](food/stew.png) | `stew` | [32, 32] | [16, 28] | [24, 22] |

## ワールド配置

設備・家具は48×48、足元(24,44)。セル中心pに対して接地点をp+(0,21)、画像左上をp+(-24,-23)へ置く。これは現行設備の脚の下端p.y+21と一致する。棚の上部はセルを越えるが占有は既存1マスのまま。透明な余白は切り詰めない。

資材・服・料理は32×32、足元(16,28)。地面の配置点qから(16,28)を引いて置く。画像アンカーは接地線の直下を示し、最下段の可視ピクセルはanchor.y-1。画像寸法を48×42に引き伸ばさない。木箱/棚の現物ドロップにも同じworld画像を使えるが、実体サイズはmanifestのbody_pxに従う。

調理台44×23、木工台44×23、裁縫台44×27の実体。既存仮表示の幅40pxに近い44pxで、通常倍率1×を基本とする。棚31×41は箱28×27より高い。既存主人公v1・柴犬Cは変更していない。比較では既存の現行描画倍率（主人公1.4375、柴犬1.25）も併記した構成とした。

## 識別の基準

- 調理台: 暗い鍋・石の火床・まな板。木工台: 明るいのこぎり・板・万力。裁縫台: 前へ垂れた緑の布・糸巻き。
- 木箱: 閉じた低い箱。棚: 空いた2段の棚板。商品の中身は描かない。
- 繊維: 束ねた黄緑/枯草の穂。服: 首穴・袖・裾のある生成りチュニック。服はアイテム絵であり、人間の着用モーション差分ではない。
- 焼きキノコ: 傘と軸・焦げ目。卵料理: 不透明な白身と黄色い黄身。焼き肉: 赤褐色の厚切り肉と焼き目。煮込み: 深い器・液面・具。

## UI

各worldファイルと同じbasenameの `ui_icons/*.png` を同梱。全32×32、中心アンカー(16,16)、実体は最大28×28。world PNGをUIへ縮小して二重に潰すのではなく、このファイルを使用する。原画から別サイズへ再整形し同じ共通パレットで整理した。UI内の1×、2×表示をcatalogで比較。既存資源UIに大きい枠がある場合もnearest整数倍率を基本とする。

## 取り込み時の注意

- `fiber_bundle.png`の実装IDは`fiber`。他はbasenameと実装IDが一致。設置操作ID `place_wood_crate` / `place_wood_shelf` は既存のまま。
- item_catalogの旧アイコン別名（wood/mushroom/egg/meat/collar等）へ置換する前に、製作品の正確なIDでこの素材を選択する。生キノコや生卵の既存アイコンを全体で上書きしない。
- 設備の仮矩形と上の仮アイコンは、本PNGへの置換時に重ねて描かない。建築途中・破壊後・HP表示は既存処理を維持。今回それらの新しい状態PNGやアニメは追加していない。
- 各画像に落ち影なし。接地陰影は材質の陰影にとどめ、既存のゲーム側の影を必要に応じて1回だけ描く。nearest、straight RGBA、白抜きshaderは使わない。卵白・皿・布の明色は不透明。
- 木箱/棚の収納容量、服の防御や耐久、料理の回復量、設備の性能、材料数・レシピ・UIDは素材側では変更していない。
- フレーム順[0]、時間null（状態維持）、loop=false。アンカー・寸法・SHA256・用途はmanifest.json。

## 検査と未完了範囲

機械検査146項目を通過。RGBA・寸法・ハッシュ・透明余白・二値alpha・32色以内・接地線・卵白保持を検査。草地背景/木床/明暗背景と通常倍率で目視した。のこぎりの刃と包丁、黄身は最終サイズでピクセルを整えた。

`preview/` はすべて比較用。world_nativeは既存実ゲーム画面への**合成プレビュー／未実装**であり、実ゲームへの統合成功を示す画面ではない。ゲームソース・EXE・セーブは変更していない。ゲームへの取り込み、並び順・影・UI倍率の隔離描画確認は実装担当へ引き継ぐ。

## 出典

原画11枚と全プロンプトは `../../art-production/crafting-assets-v1/`。Codex内蔵画像生成を利用し、新規の有料APIなし。共有32色パレット、アルファ整形、等比サイズ、最終ピクセル修正、別UI整形、比較・検査を実施。参考にした採用アートは別デザインへ再生成・上書きしていない。