# 操作・正式素材・図鑑・壁の統合レビュー

## 試遊する版

**[Play.cmd](../../../Play.cmd)をダブルクリック。** 通常版は `build/WhistleRanch.exe`。ESCで **ビルド24ddf18 / 素材7e408375** を確認する。検証フォルダのEXEを探す必要はない。自動起動はしていない。

検証実装：`24ddf180c908d1b5035fc882fc0e3d197513918d`（clean）。機能変更ecd1488、整理24ddf18。後続レビュー記録コミットはゲームコードを変更しない。最新素材：`7e408375f19b86759fc614508fc3e5f413f67ff9`。納品内訳・実参照・SHA256は [使用一覧](asset-usage.json) と [ART_SPEC](../../../ART_SPEC.md)。106 runtime PNGが納品manifestと一致。

[ビルド記録](build.json)：通常EXEと検証EXEのSHA256一致 `3bf6deb9bdfa50d6ab7853d2fc64e4683f1f80fd30798d6e40390ba773ba8fc2`。起動中チェック後に更新。ユーザーのゲーム終了・再起動・通常セーブ変更なし。

## 変更と操作

- Tab / Shift+Tab：現在モードの選択可能な操作だけ巡回。指示モードの最初のTabは牧場主に近い対応動物の選択だけ。Tab単独で仕事・休息・飲料を実行しない。ニュートラルは何もしない。
- 建設・指示の操作ボタンをドラッグして表示順を変更。固定操作IDとUI設定ファイルで保持し、Tabも同順。仕事キューとは別。範囲外・Esc・右クリックはドラッグだけ取消。
- ホイール下：建設→指示→牧場主。上は逆順。ニュートラルから下は建設、上は牧場主。Ctrlはズーム。固定矩形による入力遮断を除き、実際のスクロールUIを優先。
- 市場の買う/売るは入口だけ。右上「戻る」と右クリックは一階層、「メニューへ」は朝入口。昼へ進むのは「支度を終える」。図鑑の右クリックは閉じる。
- 正式閉表紙→開閉連番→見開き。送り中は動的本文を紙のquadに写し、次個体IDは完了時に確定。本文・動物を固定画像へ焼き込まない。
- 主人公v1/柴犬Cの正式左右歩行・寝入り・休息・睡眠・起床、鶏猫の歩行/ついばみ/伸び、巻物を接続。正式RGBAへ白抜きshaderを適用しない。能力・衝突寸法は不変。
- UI荷車v2と盤面専用128×96荷車を分けて等比表示。到着/待機/退出、朝入口、市場を更新。旧商人や箱を重ねない。
- 48×42に合わせた縦横壁、L/T全方向・十字・異素材・ドア接続と接地順を修正。壁/床の最終絵素材は未納品で、現在は接続形状の描画。

## 実画像・動作記録

すべて上記実装のGodot Viewport出力。素材比較GIFや旧版画像ではない。GIFは取得フレームを見やすい間隔で連結した**確認用連番**で、リアルタイム画面録画ではない。[媒体と出典ハッシュ](media-index.json)。

| 対象 | PNG | 動作記録 |
|---|---|---|
| 朝・正式閉表紙・荷車 | [朝](ui/morning.png) / [市場](ui/market_detail.png) | [到着・待機・退出](ui/merchant.gif) |
| 本・本文同期 | [見開き](ui/book_opened.png) | [開く](ui/book-opening.gif) / [次・前・閉じる](ui/book-pages.gif) |
| 操作ボタン | [浮いた操作](ui/operation_drag_06.png) | [操作順変更](ui/operation-drag.gif) |
| 仕事札・番号・経路 | [変更前](ui/queue_before.png) / [変更後](ui/queue_after.png) | [札を掴んで並べ替え](ui/queue-drag.gif) |
| 壁接続 | [縦横・十字](ui/wall_connections.png) / [L/T全方向](ui/wall_corners_and_tees.png) / [縦ドア・異素材](ui/wall_vertical_door_depth.png) / [開放](ui/wall_vertical_door_open.png) | 状態別PNGと回帰で確認 |
| 正式キャラクター | [原寸](characters/native_scale.png) / [全動物](characters/all_animals.png) / [左停止](characters/left_stop.png) | [0.5/1/2倍・左右](characters/walking.gif) / [動物・休息](characters/animal-motion.gif) |
| 睡眠から起床 | [睡眠](characters/sleeping.png) / [起床後](characters/awake_idle.png) | [起床](characters/wake.gif) |
| 床の入力 | [移動](characters/floor_move.png) / [誘導](characters/floor_guide.png) / [通常選択](characters/floor_selected.png) | character入力検査に記録 |

## 検証結果

[観察概要](stage1-observation.json)。整理後のimport、headless **534項目**（既存460＋controls74）、AI **192試行**、Windows exportと出力EXEのheadless smoke成功。[回帰ログ](audit/regression/)。隔離GPUはcontrols **74項目**、characters **31項目**、失敗0。

Tab未選択/逆順/連打/猫/鶏/療養/複数/空、D&D取消/範囲外/設定保存、画面6地点のホイール/Ctrl、市場階層/売買/戻り、本0/1匹/個体ID/命名中入力/Esc、左右停止/床移動/床誘導/睡眠解除を検査。

未反映点検では、建設中の誤回収防止、床層の修理/解体、8仕事と8選択、近傍UI、保留/自動休息、常駐/誘導/屋内制限/囲い込み/救出出口、ドアとロック、巻物、小屋停止を既存回帰で再確認。既に直っていた世界ロジックは作り直していない。受入れ小屋・犬/鶏小屋を通常の表示/建設/AI設備へ復活させず、入口受入・通常休息・産卵を維持。

非対話Window Station・専用desktop・分離APPDATAを使用。[UI監査](audit/ui/isolation.json)、[動物監査](audit/characters/isolation.json)、[補足監査](audit/supplement/isolation.json)。GPUは直列。通常デスクトップ/OS入力/通常セーブに触れていない。補足は同じruntimeを照合し、[保存シナリオ](audit/supplement.gd)で荷車とドラッグを記録。

## 仮決定・不足・要レビュー

- 動物未選択Tabはマス距離、同距離は固定ID。ドラッグ閾値7px。UI順序だけ保存し、キャンペーン永続セーブとは別。
- 本の開閉0.54秒/送り0.42秒。縦ドアは南北隣接が東西より多い場合、それ以外は横。見た目のみの規則。
- **素材不足**：土木石の壁/床/縦横ドアの正式PNG、商人歩行/車輪/開店コマ、鶏猫の正背面、気絶/運搬専用姿勢。静止荷車の位置移動を専用アニメ完成とは扱わない。
- **未確認**：物理的な日本語キーボード/IME操作、実スピーカー聴感、長時間の人間試遊。通常キー/テンキーはエンジン内InputEventで検査。
- **実プレイで見てほしい点**：短い本送りの読みやすさ、操作札のドラッグ感、縦壁/ドアの仮形状、盤面荷車と人物の大きさ。文字は送り中の遠近変形で細くなるが、終了後は通常描画へ戻る。
- 素材担当への追加仕様送信は、自動承認レビューが「送信先への明示許可なし」として拒否したため未送信。壁/ドアの不足パターンはART_SPECへ記録済み。

## 整理

[分類と理由](CLEANUP.md) / [パス一覧](cleanup.json)。旧証拠は [archive](../pre-input-art-b09a420/PACKET.md)。原画・HANDOFF・manifest・ライセンスは保全。不要shader/旧描画/非隔離検証経路を機能変更とは別コミットで削除。中間ビルド・試行画像も最終証拠保存後に限定整理。
