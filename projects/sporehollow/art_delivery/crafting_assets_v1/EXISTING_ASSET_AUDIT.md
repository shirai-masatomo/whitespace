# 既存資産照合

実装参照 `codex/sporehollow-biome01` = `aa3eb39a18b250a3a34f987744eb1b6fd7b24cb9`。アート起点 `adb33aa07da2ec57959e0315963f15003ddcd085`。

- main.gdのCraft BENCHES分岐は矩形＋既存資材アイコンの仮表示。幅40px前後、脚下端はセル中心+21。今回ここを置換するPNGを制作。
- crafting_data.gdの設備/料理/家具/服IDを確認。fiberはitem_catalogの既存資材IDで、画像ファイル名のみfiber_bundle。
- resource_icons_v1: 木材/石材/土/金貨。今回の束・家具・料理と用途が異なるため維持。
- colony_growth_assets_v1: 非戦闘イベント用箱、寝床等は既存用途を維持。今回の空の簡素な木箱とは使い分ける。既存イベント箱に収納家具の役割を付けない。
- wood_buildings_v1の木床と壁、characters_v1の主人公/柴犬を縮尺・配色参考に使用。再制作なし。
- 正式な設備3種・今回の料理4種・服/繊維/空木箱/棚に一致する納品は確認範囲で見つからず、新規別フォルダで追加。
- review/current/craftingはテスト報告が中心。構成背景には最新参照ブランチで存在するui_survey/01_field.pngを使用。この画像は過去の画面記録であり製作機能の現行導線の完成証拠ではない。

本番データを変更せず原画・成果物・文書だけを納品する。
