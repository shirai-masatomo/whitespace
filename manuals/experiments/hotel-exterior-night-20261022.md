# ホテルの夜外観と場所の導線

制作・記録日：2026-10-22。

## 目的・合格条件

ユーザーの依頼は、添付写真をモデルとしてホテルの外装を場所として実装すること。夜の暖色照明、石壁、緑の庇と屋上装飾、角の建物と入口を引き継ぎ、既存背景に合う横長の人物なし背景を制作する。手前の道路に人物配置用の余白を設けることは制作側で補った構図条件。

場所の正本と台帳を登録し、既存university-circle-renpyのマップから外観を表示してマップへ戻れるソースを追加する。ゲーム表示・操作の成功は、静的確認と区別する。

## 入力と環境

- 建築参照：ユーザー添付codex-clipboard-89c85a50-cbba-4ac0-b5a8-f111665f2f62.png。画風参照：assets/locations/heroine-home/exterior/exterior-night.png。画風参照の集合住宅の建築・構図は引き継がない指定。
- 原画像2点は読み取りのみ。作業用複製・事前SHA256はoutput/hotel-exterior-night-20261022/referencesとbefore.json。作業後も参照SHA一致。
- 内蔵image_genを使用、transparent_background=false。モデル内部版、seed、CFG、steps等は非公開。所要時間とGPU/VRAM/RAMは未測定。
- 作業用プロンプト全文と生成元はoutput/hotel-exterior-night-20261022/request.json。完成側にもlocation.jsonへ生成指示を記録。
- ホストで行ったのは、ファイル編集、画像の復号・コピー・ハッシュ照合と、ゲームを読み込まない静的検査。Sandbox/VMは確認しておらず、隔離内テストなし。ゲーム・SDK・Launcher・Ren'Py Lint・GUI自動操作・ビルドは未実施。

## 試行ごとの記録

| ID | 条件 | 出力 | 採否 |
| --- | --- | --- | --- |
| H1 | 添付の夜景ホテルを建築参照、既存の夜外観を画風参照とした横長背景 | 1枚、1672×941 | 完成候補として場所登録・ソース実装に使用。明示採用は未確認 |

AI新規生成1、建築参照1、画風参照1、完成背景1、ゲーム用の無加工複製1。ゲーム複製を新規生成には数えない。クロップ・リサイズ・元絵の合成・マスク加工なし。

## 観察と実装

- 暖色の縦長ライト、石張り外壁、緑の庇と屋上装飾、左側の入口、椰子の植栽、横長の空いた道路を目視確認。人物・車両なし。添付の正確な実寸・所在地・細部を復元したものではない。
- 看板は添付のHOTEL / CHAPEL / COCONUTS表記を残す指示。表記を目視確認。ゲーム上の正式ホテル名は未決定。
- 正本：[ホテル背景](../../media/d26f040ed0924e4274a9.png)。[場所設定](../../reports/COVERAGE.md#同梱しないもの)とassets/catalog.jsonに候補登録。
- ゲームへgame/images/bg/hotel-exterior-night.pngを原寸コピーし、生成元・正本・ゲーム用のSHA256一致を確認。
- game/assets.rpyで`bg hotel exterior night`を1280×720、fit=coverとして登録。原画像1672×941は変更せず、表示時に画面へ合わせる指定。
- game/circle_map.rpyへ4番目の「ホテル（外観）」と`hotel_exterior_event`を追加。既存の大学・部室・海の項目は維持。
- game/story/hotel.rpyは背景を表示し、マップへ戻るボタンのReturn()を待ってreturnする。人物の追加・室内イベント・好感度変更はなし。マップ呼出し元のループへ復帰する構造。
- game/asset-register.jsonへ出所・ハッシュ・実機未検証・採用未確定を記録。ゲームのREADMEとPROJECT_STATEに追加分を記録。
- 変更前のゲーム既存ソース・台帳・README計4ファイルはoutputのbeforeへ保存。Git操作・既存作業プロセスへの停止はしていない。

## 静的確認

- 既存scripts/verify_static.pyを、SDKとは別の既存バンドルPythonで`-B`を付けて実行。内容を読み、Ren'PyやゲームPythonをimport/実行しないことを確認してから使用した。
- output/hotel-exterior-night-20261022/static-review.jsonのissuesは0。画像参照の実在、マップ先labelの実在、ラベル重複、埋込みPython式の構文、既存表示確認導線等のファイル検査。これはRen'Pyの構文解析・Lint・実機操作ではない。
- `git diff --check`は終了コード0。新規ファイルを含む全ソースのエンジン構文保証ではない。
- 完成画像の寸法、場所台帳・ゲーム台帳のハッシュ、入口・復帰ソースのつながり、添付参照の不変を追加のファイル検査で確認。検査記録はoutput/hotel-exterior-night-20261022/verification.json。

## 片付けと未実施

- ホスト変更：画像labの完成背景・場所台帳・文書、university-circle-renpyのホテル用画像とソース・台帳・文書、outputの作業記録。sample/ヒロイン/まとまりに中間物なし。
- OS設定・レジストリ・共通ランタイム・ドライバー・サービス・既存アプリは変更していない。新規取得や導入はなし。
- 自分が起動した短いNode処理と非SDK Python静的検査は終了コード0。常駐ヘルパーは作成せず、既存のユーザー作業プロセスを停止していない。PC全体の残存プロセス監査は未実施。
- 隔離環境の導入・有効化、SDK・ゲーム実行、ボタン操作、1280×720での実際のマップレイアウトと描画、ロード互換性、製品ビルド、販売要件・参照素材の利用条件の独立再調査は未実施。

[ホテルの素材一覧](../../notes/a47d20b48e928e5ee7cd.md) ／ [実験一覧](../README.md)
