# 画像・音声素材の入れ替え方（今は素材なし）

この試作の背景と人物はすべてRen'Py標準の`Solid()`表示であり、**実際のCGファイルはまだ存在しない**。
採用済みの素材だけをユーザーの同意を得て取り込む。

## 予定名（例）

| 役割 | 将来の格納パス例 | 現在 |
|---|---|---|
| オープニング背景 | `game/images/bg/opening.webp` | 単色 |
| 大学 | `game/images/bg/campus.webp` | 単色 |
| 部室 | `game/images/bg/clubroom.webp` | 単色 |
| 海 | `game/images/bg/beach.webp` | 単色 |
| 葵の立ち絵 | `game/images/characters/aoi/neutral.png` | 単色矩形 |
| BGM | `game/audio/bgm/...` | 未設定 |
| SE | `game/audio/se/...` | 未設定 |

差替え時は、`image bg campus = "images/bg/campus.webp"`のように`image`宣言を書き換える。
人物は透明背景のPNGまたはWEBPを使い、`image aoi neutral = "images/characters/aoi/neutral.png"`等へ差し替える。
画像の解像度を1280×720の画面で確認する。セーブ互換性を意識し、画像タグやラベルは原則維持する。

BGM/SEは素材を実際に配置してから`play music` / `play sound`を導入する。存在しないパスはコードに追加しない。
商用化前に生成モデルと素材の権利・利用規約、登場人物の成人設定を再確認する。
