# 採用6対象の左右モーション制作原本

2026-10-08の方向確認6枚へのユーザー「OK」に基づく。右/左のみ。独立納品はmerchant_motion_v1、maid_motion_v1、dancer_motion_v1、thief_motion_v1、cow_motion_v1、bull_motion_v1。

- originals: 内蔵image_genの生成原画。generation-records.jsonに完全なプロンプトと採用参照を記録。
- references: 最新ART_SPEC/ENEMIES/ANIMALS/WORLD_SYSTEMSの読み取りコピー。バイト保持のためGitのtext/diff変換を抑制。
- prepare.py: 原画の連結alpha抽出、共通倍率・採用パレットの原寸整形。原画は変更しない。
- polish.py: 採用頭部の保持、商人/闘牛の必要な透明余白。先にprepareを実行する。
- native/: 原寸加工済みの個別姿勢。native-processing.json、native-corrections.jsonが加工記録。
- package.py: 対象名を引数に、左右・時間・イベント目安・レイヤー・比較PNG/GIF・manifestを作る。ゲームコードとは独立。
- write_handoffs.py: 各セットのHANDOFFを作成。
- prior-hashes.json: 開始時の既存1163PNGの保全記録。

荷車は採用盤面PNGの手前車輪のスポーク領域のみ画素回転。車体・商人を再生成しない。奥車輪は固定。舞姫の復活光は独立原画から32×40へ加工し、アルファ144で対象を隠しにくくする。

左向きは水平反転。固定アンカーで配置し、攻撃/復活等の実際の判定は既存実装が担当。素材作業でゲームを起動しない。新しい有料APIは使用しない。

## 最終検査

`verify_delivery.py`で既存1163PNGの保全、320PNGのRGBA・ハッシュ・寸法、採用静止の画素一致を再検査し、GIFの時刻別比較と独立レイヤー比較を作成。`final-QA.json`が結果。

`native/revival_fx_*.png`は生成原画から手作業で確定した32×40の加工マスターで、prepare.pyによる再抽出の対象外。再納品はこの原寸マスターを使用する。初期inspection画像は頭部固定・余白補正前の作業記録。最終状態は各納品フォルダのpreviewとlayer-inspection.pngを参照。過去の方向確認build.pyは採用前の生成用で、採用状態の正本はADOPTION.json。
