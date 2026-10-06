# ホイッスル牧場 — 最新レビュー

## 最新：低カルマ基準ルート K0〜K5（2026-10-06）

**試遊版 c443e5b / 素材5848c4f8**。[実装・仮決定・未確認](progression/REVIEW.md) / [13代表画面](progression/SCREENS.md) / [ギャラリー](progression/index.html) / [8日運用](progression/progression-flow.json) / [ビルド](progression/build.json)。起動は [Play.cmd](../../Play.cmd)、ESCの版表示はc443e5b。レビュー保存コミットはゲームを変更しない。

共通データ、低カルマ遭遇、敵6種Lv1、動物3種、柴犬以外の死亡、迎撃型、現地装備、既存本への敵図鑑を統合。既存770＋新規117検査、AI192試行、最終clean版の関連242検査、Windows出力と配布EXEの非対話GPUを確認。新敵/動物の正式素材は不足し仮表示。カテゴリ祈りは抽選サービスまでで、旧固定60Gの新規受付は停止。人間の難度評価・本番カルマ接続は残る。

以下は**過去の対応版の証拠**で、現在の仕様・ビルドを示さない。

## 前回：父の黄金像・森・祈り（2026-10-06）

**試遊版 afb8e1b / 素材5848c4f8**。[実装・仮決定・検証・未確認](story/REVIEW.md) / [29画面](story/SCREENS.md) / [実画面ギャラリー](story/index.html) / [観察](story/story-observation.json) / [ビルド](story/build.json)。

現地開拓、四辺の森からの侵入、中央像、現地の富の祈り→翌朝60G→遅れた事件/ニュース/実襲撃、像破壊・牽引・中断・3種類の敗北、朝の一括復元を統合。765回帰＋AI192、描画修正後の関連50項目、Windows出力/専用データ起動、非対話GPU29画面と出力EXEを確認。通常起動は [Play.cmd](../../Play.cmd)、ESCはafb8e1b。

新規の像・森・祈り・搬出などは正式素材不足による仮描画。人間の数日試遊・難度/予兆調整は残る。永続セーブや他の願いを実装済みとしない。以下は過去の対応する版の証拠。

## 前回：朝・市場UIレビュー対応（2026-10-06）

**この節の検証版 7c5766e / 素材5848c4f8**。[変更・検証・残る差](shop-ui/REVIEW.md) / [before・after一覧](shop-ui/SCREENS.md) / [比較ギャラリー](shop-ui/index.html) / [ビルド](shop-ui/build.json)。商品可視領域の等比拡大、固定左揃え、数量/所持/価格、不能理由、購入売却別の空状態、具体的な結果表示、朝ヘッダーを共通部品へ整理。29画面比較＋補足6画面、698回帰、AI192、Windows出力・隔離GPU成功。取引ロジック・価格・朝→昼は変更なし。


## 前回の試遊版：追加素材取り込み

**この節の検証版は e65f7d1 / 素材5848c4f8**。UI荷車、資源12PNG、誘拐者50PNG、小演出40PNGを実描画へ接続。[取り込み結果と残る差](materials/REVIEW.md)、[取り込み後ショップ29画面](materials/shop/index.html)、[敵・運搬・演出](materials/enemies-effects/index.html)、[ビルド情報](materials/build.json)。回帰668項目・AI192試行・隔離GPU・Windows export/出力EXE起動を確認。以下のe13e16e記録とshop/の29枚は取り込み前の比較証拠。

## 図鑑UI改善に向けた現状撮影（2026-10-04）

実装内容e65f7d1／素材5848c4f8の図鑑を追加撮影。[レビュー観点](book/HANDOFF.md) / [代表画像](book/SCREENS.md) / [ギャラリー](book/index.html)。朝の閉表紙、柴犬・鶏・猫、育成前後、命名、開閉・ページ送りの59PNGと確認用連番GIF6本。通常初期状態と、資源を用意したレビュー状態を区別。ゲーム/UIコード・通常EXEは変更していない。

## ショップUI改善に向けた現状撮影（2026-10-04）

購入/売却の各階層・全カテゴリ・初日の商品詳細・取引後を新規撮影した29枚は [ショップレビュー依頼](shop/HANDOFF.md) / [ギャラリー](shop/index.html) / [原寸一覧](shop/SCREENS.md)。abebfd3時点のゲーム内容を通常初期在庫で実操作。新納品のUI荷車・資源アイコンは未取り込みのため、差し替え前の現状として扱う。

## Play.cmd起動修正（2026-10-04）

LF改行の旧Play.cmdをcmd.exeで解析すると、存在するEXEの起動行へ到達せず、`'ev.ps1' is not recognized`となることを再現。CRLFへ修正し、`.gitattributes`で再発を防止。実cmdを使う`tests/test_launcher.ps1`で、空白/日本語を含むパス・EXE存在/欠落の分岐を検査（起動命令のみ検査用echoへ置換、通常画面へは起動しない）。check/test/buildにも組み込んだ。

公開済みEXE e13e16e（素材ebe446e5、上記と同一SHA256）そのものを、分離APPDATAと非対話desktopで150フレーム描画し、エラーなし/終了0/desktop所属一致を確認。[監査](audit/launcher/isolation.json) / [描画ログ](audit/launcher/render.log)。ゲームコード・EXE・通常セーブは変更なし。人間のダブルクリックは未実施。

## 前回のUI・建材検証（e13e16e）

起動先は引き続き **[Play.cmd](../../Play.cmd)**。以下は前回ビルドe13e16e / 素材ebe446e5の検証記録。現在の通常版は上記e65f7d1へ更新済み。

検証実装：`e13e16ed9477c92e4057d10b70d7025b2288908b`（clean）。機能変更ecd1488、整理24ddf18。後続レビュー記録コミットはゲームコードを変更しない。最新素材：`ebe446e5329aa7780b6ef5f13268ceb9433c9796`。納品内訳・実参照・SHA256は [使用一覧](asset-usage.json) と [ART_SPEC](../../ART_SPEC.md)。285 runtime PNGが納品manifestと一致。

[ビルド記録](build.json)：通常EXEと検証EXEのSHA256一致 `b44a2fb8c7b526fe9e457824ce7662d5c25ab718d653de5e3f5916a17e31c7d0`。起動中チェック後に更新。ユーザーのゲーム終了・再起動・通常セーブ変更なし。

## 変更と操作

- Tab / Shift+Tab：現在モードの選択可能な操作だけ巡回。指示モードの最初のTabは牧場主に近い対応動物の選択だけ。Tab単独で仕事・休息・飲料を実行しない。ニュートラルは何もしない。
- 建設・指示の操作ボタンをドラッグして表示順を変更。固定操作IDとUI設定ファイルで保持し、Tabも同順。仕事キューとは別。範囲外・Esc・右クリックはドラッグだけ取消。
- ホイール下：建設→指示→牧場主。上は逆順。ニュートラルから下は建設、上は牧場主。Ctrlはズーム。固定矩形による入力遮断を除き、実際のスクロールUIを優先。
- 市場の買う/売るは入口だけ。右上「戻る」と右クリックは一階層、「メニューへ」は朝入口。昼へ進むのは「支度を終える」。図鑑の右クリックは閉じる。
- 正式閉表紙→開閉連番→見開き。送り中は動的本文を紙のquadに写し、次個体IDは完了時に確定。本文・動物を固定画像へ焼き込まない。
- 主人公v1/柴犬Cの正式左右歩行・寝入り・休息・睡眠・起床、鶏猫の歩行/ついばみ/伸び、巻物を接続。正式RGBAへ白抜きshaderを適用しない。能力・衝突寸法は不変。
- UI荷車v2と盤面専用128×96荷車を分けて等比表示。到着/待機/退出、朝入口、市場を更新。旧商人や箱を重ねない。
- 48×42に合わせた縦横壁、L/T全方向・十字・異素材・ドア接続と接地順を修正。木e648cf75・土石ebe446e5の正式PNGへ置換。48種の接続/損傷、床外周/境界、縦横扉と独立ロックを接続。

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

[観察概要](stage1-observation.json)。整理後のimport、headless **632項目**（既存460＋controls74＋建材98）、AI **192試行**、Windows exportと出力EXEのheadless smoke成功。[回帰ログ](audit/regression/)。隔離GPUはcontrols **74項目**、characters **31項目**、建材 **98項目**、失敗0。

Tab未選択/逆順/連打/猫/鶏/療養/複数/空、D&D取消/範囲外/設定保存、画面6地点のホイール/Ctrl、市場階層/売買/戻り、本0/1匹/個体ID/命名中入力/Esc、左右停止/床移動/床誘導/睡眠解除を検査。

未反映点検では、建設中の誤回収防止、床層の修理/解体、8仕事と8選択、近傍UI、保留/自動休息、常駐/誘導/屋内制限/囲い込み/救出出口、ドアとロック、巻物、小屋停止を既存回帰で再確認。既に直っていた世界ロジックは作り直していない。受入れ小屋・犬/鶏小屋を通常の表示/建設/AI設備へ復活させず、入口受入・通常休息・産卵を維持。

非対話Window Station・専用desktop・分離APPDATAを使用。[UI監査](audit/ui/isolation.json)、[動物監査](audit/characters/isolation.json)、[補足監査](audit/supplement/isolation.json)。GPUは直列。通常デスクトップ/OS入力/通常セーブに触れていない。補足は同じruntimeを照合し、[保存シナリオ](audit/supplement.gd)で荷車とドラッグを記録。

## 仮決定・不足・要レビュー

- 動物未選択Tabはマス距離、同距離は固定ID。ドラッグ閾値7px。UI順序だけ保存し、キャンペーン永続セーブとは別。
- 本の開閉0.54秒/送り0.42秒。縦ドアは南北隣接が東西より多い場合、それ以外は横。見た目のみの規則。
- **素材不足・未接続**：商人歩行/車輪/開店コマ、鶏猫の正背面、気絶/運搬専用姿勢。静止荷車の位置移動を専用アニメ完成とは扱わない。
- **未確認**：物理的な日本語キーボード/IME操作、実スピーカー聴感、長時間の人間試遊。通常キー/テンキーはエンジン内InputEventで検査。
- **実プレイで見てほしい点**：短い本送りの読みやすさ、操作札のドラッグ感、縦壁/ドアの見え方、盤面荷車と人物の大きさ。文字は送り中の遠近変形で細くなるが、終了後は通常描画へ戻る。
- 素材担当への追加仕様送信は、自動承認レビューが「送信先への明示許可なし」として拒否したため未送信。壁/ドアの不足パターンはART_SPECへ記録済み。

## 整理

[分類と理由](CLEANUP.md) / [パス一覧](cleanup.json)。旧証拠は [archive](../archive/pre-input-art-b09a420/PACKET.md)。原画・HANDOFF・manifest・ライセンスは保全。不要shader/旧描画/非隔離検証経路を機能変更とは別コミットで削除。中間ビルド・試行画像も最終証拠保存後に限定整理。

## 追加建材の検証

木は5e5d41c、土石はe13e16eで取り込み。納品PNG179枚は無改変。前回24ddf18の画像は [専用archive](../archive/24ddf18-before-construction-art/PACKET.md) へ分離し、currentの全画像をe13e16eから再取得した。

[石接続](buildings/stone_wall_masks_1_normal.png) / [土の損傷](buildings/wall_masks_0_damaged.png) / [木接続](buildings/wood_wall_masks_1_normal.png) / [異素材床](buildings/wood_floor_boundaries.png) / [開閉](buildings/wood_doors_open.png) / [ロック破損](buildings/wood_doors_broken_lock.png) / [ドア通過](buildings/door-walk.gif)。[隔離監査](audit/buildings/isolation.json)。敵素材はこの建材追加の対象外。

後着の敵素材は納品通知のみ受領。今回の対象には追加せず、ゲーム取り込み・検証済みとは報告しない。

並行設計更新：公開直前にoriginのfb4c9bdまでの8文書コミットを通常マージ。抽選/Rarity/装備/非柴犬死亡などの新設計は保持したが、この依頼の固定60G版と区別しK0〜K8へ未実装として記録。ゲームコード・素材はafb8e1bから変更なし。
