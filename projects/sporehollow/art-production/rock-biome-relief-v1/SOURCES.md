# 制作記録

内蔵 image_gen を使用。新規の有料API・CLI画像API・外部ゲーム素材は使用していません。

- originals/rock_material_atlas.png：2026-10-12 内蔵生成。四つの岩材スウォッチ。上面と崖面を抽出し、ゲーム原寸で再整形。
- originals/fallen_trunk.png：同日 内蔵生成。倒れた幹の独立素材。
- PROMPTS.md：実際に送信した完全な生成条件。
- build.py：縦横比を維持した材料範囲の抽出、パレット整理、接続・輪郭・損傷・RGBA整形、manifestと検査。既存の採用済み素材は参照のみ。
- review.py：原寸・2倍・透過・採掘の構成見本。ゲーム実行ではありません。
- native/：生成原画から整えた原寸の中間材料。ゲーム側はart_deliveryの完成PNGを使用。
- prior-hashes.json：今回着手前の既存1,736PNGの保全比較。

参照：実装ブランチcodex/sporehollow-biome01、235230dfa0ac823e7a1c02789b17f84f355295bc。ART_SPEC、biome_connections_v1、biome_environment_v1/v2のHANDOFFとmanifest、seed_31_connected_before実画面を確認。最新ART_SPECは実装作業領域を参照（素材作業領域の古い仮仕様より実値を優先）。

添付された他作品の参考画像は生成入力にも画素の抽出元にも使用していません。ホイッスル牧場内の自作正式素材は、再生成しない継続ルールに従って無改変参照しています。
