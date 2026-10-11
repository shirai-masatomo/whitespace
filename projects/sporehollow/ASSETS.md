# 採用素材の場所

| 対象 | このプロジェクトからの相対パス |
|---|---|
| 主人公・柴犬の静止画 | `art_delivery/characters_v1/` |
| 主人公・柴犬の動作 | `art_delivery/characters_motion_v1/` |
| 猫・鶏・図鑑 | `art_delivery/ranch_assets_v1/` |
| その他の人物・動物の動作 | `art_delivery/*_motion_v1/` |
| 黄金像 | `art_delivery/ui_world_direction_v1/candidates/world/goldA.png` |
| UI | `assets/ui/`、`assets/adopted_ui/` |
| 木造・石造建築 | `art_delivery/wood_buildings_v1/`、`earth_stone_buildings_v1/` |
| フォント | `assets/fonts/` |

画像は本プロジェクトで生成・制作し、採用された透過PNGとSVGを使用しています。ユーザー提供の採用済みUI画像も含みます。旧UIの比較ギャラリー、参考ゲームの解析資料、未採用原画像は含めません。

Noto Sans JPのライセンスは `assets/fonts/OFL.txt`、Godotのライセンスは `assets/GODOT_COPYRIGHT.txt` を参照してください。

効果音と夜の環境音は `game/farm_audio.gd`、握った手カーソルは `game/ui_style.gd` で生成します。昼BGMは任意の外部ファイルで、この公開ソースには収録していません。

## 使用素材の閲覧

`素材/index.html` は実使用画像の分類一覧です。動作名でも検索できます。各画像は元ファイルへリンクし、種別・動作・方向のフレーム構造を維持しています。未使用の旧プレビュー、制作レイヤーは一覧に含めません。
