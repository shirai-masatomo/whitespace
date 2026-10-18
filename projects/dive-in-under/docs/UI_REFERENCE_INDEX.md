# Dive In Under — UI参考・実画面・不足素材の統合入口（2026-10-19）

> **このページがUIレビューの入口**。ここで「参考（目標）」「現行の実画面（証拠）」「古いアーカイブ」「チャット生成のみ」を明確に区分する。ゲームの起動はせず、GitHubにあるデータのみで目録化。ゲームの採用状態を変更する指示ではない。

## 1. 正式な画風・構図の参考画像

正本：[UI_MOCKS.md](UI_MOCKS.md)、現行3枚は`assets/ui-mocks`（main）。これらは**参考デザイン**であり、完成済みゲーム画面でも画像を貼り付ける実装用素材でもない。

| ID | 画面 | 画像 |
| --- | --- | --- |
| PX-01 | 探索・全体UI | [01_exploration_pixel.webp](../assets/ui-mocks/01_exploration_pixel.webp) |
| PX-02 | 自動戦闘UI | [02_battle_pixel.webp](../assets/ui-mocks/02_battle_pixel.webp) |
| PX-03 | ステータス／装備UI | [03_status_pixel.webp](../assets/ui-mocks/03_status_pixel.webp) |

**古い画風は正式参照ではない**：[2026-10-16旧4枚](../assets/ui-mocks/archive/2026-10-16/) のうち旧倉庫画像は [04_warehouse.webp](../assets/ui-mocks/archive/2026-10-16/04_warehouse.webp) にある。**旧倉庫画像は「参考が存在する場所」の履歴であり、採用対象ではない**。

## 2. 倉庫・起動準備など、画像より後に確定した要件

| 対象 | 新しい決定（画像の有無） | 仕様の置き場所 |
| --- | --- | --- |
| **冒険準備ハブ** | 毎回新規開始、開始後は準備画面からステータス／倉庫／装備へ、出発後に1F。**正式モック画像は未作成** | [STARTUP_PREPARATION_UI.md](STARTUP_PREPARATION_UI.md) |
| **倉庫専用画面** | **左：バックパック15＋風呂敷3、中央：複数列倉庫、右：選択アイテム詳細**。新しい正式な倉庫モック画像はmainには未保存 | [STARTUP_PREPARATION_UI.md](STARTUP_PREPARATION_UI.md)、[UI_ASSET_INVENTORY](UI_ASSET_INVENTORY_2026-10-18.md) |
| **ステータス** | 倉庫から独立、装備・能力・状態・プロフィールの4タブ | [STARTUP_PREPARATION_UI.md](STARTUP_PREPARATION_UI.md)、PX-03 |
| **探索ミニマップ** | 前・現・次階層／分岐。クリックで全景。ノード種別は基本非公開 | [DUNGEON_MAP.md](DUNGEON_MAP.md) |

> チャット中で作った新しい倉庫理想図やUI装飾・装備アイコンを、**GitHubに正式保存済み・採用済みと推定しない**。元画像の保存・透過・使える分離素材・承認状況が確認できるまで「チャット制作候補」。

## 3. 現在の実装画面（参考UIではなくレビュー証拠）

**作業の確認対象**：`codex/dive-in-under/phase-02`。2026-10-19照合時のhead `6896a57b`。現在の起動入口は[0.5.3 README](https://github.com/shirai-masatomo/whitespace/blob/codex/dive-in-under/phase-02/projects/dive-in-under/review/current/README.md)。以後の更新ではheadと起動版を確認し直す。

| 画面 | 実画面リンク | 実装ファイル（作業ブランチ） |
| --- | --- | --- |
| 倉庫・3列＋詳細 | [warehouse-overview.png](https://github.com/shirai-masatomo/whitespace/blob/codex/dive-in-under/phase-02/projects/dive-in-under/review/warehouse-development/warehouse-overview.png)、[詳細例](https://github.com/shirai-masatomo/whitespace/blob/codex/dive-in-under/phase-02/projects/dive-in-under/review/warehouse-development/warehouse-detail.png) | `ui/warehouse_view.gd`, `ui/warehouse_frame.gd`, `ui/warehouse_catalog.gd` |
| ステータス：装備 | [status-equipment.png](https://github.com/shirai-masatomo/whitespace/blob/codex/dive-in-under/phase-02/projects/dive-in-under/review/status-layout-refinement/status-equipment.png) | `ui/status_view.gd` |
| ステータス：能力 | [status-abilities.png](https://github.com/shirai-masatomo/whitespace/blob/codex/dive-in-under/phase-02/projects/dive-in-under/review/status-layout-refinement/status-abilities.png) | 同上 |
| ステータス：状態 | [status-conditions.png](https://github.com/shirai-masatomo/whitespace/blob/codex/dive-in-under/phase-02/projects/dive-in-under/review/status-layout-refinement/status-conditions.png) | 同上 |
| ステータス：プロフィール | [status-profile.png](https://github.com/shirai-masatomo/whitespace/blob/codex/dive-in-under/phase-02/projects/dive-in-under/review/status-layout-refinement/status-profile.png) | 同上 |
| 参考シート（作業成果側） | [reference-ui-sheet.png](https://github.com/shirai-masatomo/whitespace/blob/codex/dive-in-under/phase-02/projects/dive-in-under/review/status-layout-refinement/reference-ui-sheet.png) | 元画像の来歴・ユーザー承認を要確認。mainのPX-03とは区別 |
| 町メニュー／起動 | [status-town-after.png](https://github.com/shirai-masatomo/whitespace/blob/codex/dive-in-under/phase-02/projects/dive-in-under/review/status-layout-refinement/status-town-after.png)、[実装current](https://github.com/shirai-masatomo/whitespace/tree/codex/dive-in-under/phase-02/projects/dive-in-under/review/current) | `ui/game.gd` |
| 探索／戦闘 | [現行レビュー画像フォルダ](https://github.com/shirai-masatomo/whitespace/tree/codex/dive-in-under/phase-02/projects/dive-in-under/review/current) | `ui/game.gd`, `ui/battle_stage.gd` |

**注意**：mainの参考3枚、mainの最新仕様と作業ブランチの実装はまだ完全に同期していない。作業ブランチでは町帰還後のハブ・倉庫・ステータス画面は存在するが、**起動後すぐ準備ハブへ進む・セーブなし**の新指示はまだ反映されていない。自動保存・続きからもコードに残る。

## 4. 違いと優先改修

| 優先 | 対象 | 何がまだ足りないか |
| --- | --- | --- |
| P0 | 起動→準備ハブ | 今は起動直後に準備画面へ行かず、旧セーブ／続きからUIがある |
| P0 | UI参照の一元化 | 3枚の現行モックと旧倉庫画像、開発ブランチの実画面が離れている。リンク・版・採用状況を1か所に |
| P1 | ステータス画面 | 4タブ・11枠は存在。ただしPX-03に対する密度／余白／絵と装飾の一体感／アイコンの正式感を比較し直す |
| P1 | 倉庫 | 3列の構造と動作は存在。UI全体の石・羊皮紙・真鍮・スクロール／装備アイコンの見た目を現行基準にそろえる |
| P1 | 探索・自動戦闘 | PX-01／02と同じ画面密度・見やすさ・斜め視点・ステータスの優先順を、現在の実画面で評価 |
| P2 | 資産化 | シートを貼るだけではなく、透過・余白検査した独立PNG／9-sliceを正式採用してから組込む |

参考UIの画風は**暗い石、青緑の洞窟、使い込んだ羊皮紙、真鍮の縁、統一した2Dドット**。スクリーンショット丸貼り、画像への文字／数値焼込み、手動戦闘コマンド、仲間の先行追加、未決定数値の固定をしない。

## 5. 物理的な集約と次の制作

- 今回はこの**一枚の索引**が統合入口。既存PNG/WebPは壊さず・削除せず・旧URLを無効にしない。
- 製造側は必要に応じ `assets/ui-reference/README.md` を作成し、正式参照画像の原稿・採用済み・アーカイブの区分を**一つの参照フォルダから辿れるように**する。コピーによる二重管理は避け、原稿の場所とSHA／採用状況をマニフェスト化。倉庫・準備画面の新参考画像が採用されたら追加する。
- 実際のゲームスクリーンショットは`review/`に保存し、**参考画像とは絶対に混同しない**。
- 画像素材制作の不足品台帳は[UI_ASSET_INVENTORY_2026-10-18.md](UI_ASSET_INVENTORY_2026-10-18.md)。優先は9-slice石・羊皮紙パネル、角飾り、ボタン／タブ状態、選択枠、HP/SP/EXPゲージ枠、装備アイコン・収納アイコン。既存の洞窟と主人公・敵は再生成しない。
- 製造担当用の具体的な指示は[UI_VISUAL_ALIGNMENT_HANDOFF.md](dot/UI_VISUAL_ALIGNMENT_HANDOFF.md)。

今回の目録化は**仕様・参照の整理のみ**。PC・EXE起動、ゲーム実装、負荷テストは実施していない。


## 6. 画面別UI検討のカバレッジ（2026-10-19照合）

> **判定の意味**：「正式参考あり」は現行参考画風のモックがあること、「実画面あり」はゲーム実装の表示証拠があること、「未設計」は**専用の最終レイアウトが未確定**なこと。画像未制作＝機能仕様未決定ではない。参照ブランチ `codex/dive-in-under/phase-02` head `a5c3c692` 時点。

| 画面／機能 | 正式な理想UI | 現行実画面／仕様 | レビュー優先 |
| --- | --- | --- | --- |
| 探索 | **PX-01あり**（ただし分岐ミニマップ追加後の最新版はなし） | 本編の実画面あり | 高：参考との差分とミニマップ |
| 自動戦闘／10Fボス | **PX-02あり**（専用ボスレイアウトの参考なし） | 実画面あり | 高：遠近、人物／敵サイズ、情報密度 |
| ステータス4タブ | **PX-03あり**（全タブ個別の正式モックはなし） | `status-layout-refinement/` の4タブ実画面あり | 中：装飾・見た目の統一 |
| 冒険準備ハブ | **専用の正式参考なし** | 画面遷移仕様あり。旧町ハブは別物 | **最優先：今の起動導線** |
| 倉庫・所持品（左携行／中央倉庫／右詳細） | **新画風の正式参考なし**。旧倉庫モックはarchive | 実装済み3列画面あり、基本配置は確定 | **高：デザインの正式化** |
| 階層のミニマップ・クリック全景／分岐選択 | **専用の正式参考なし** | 手描き構想・接続／隠しノード種別の仕様あり | **高：実装前にレイアウト検討** |
| タイトル | 専用の現行正式モックなし（PX-01の画風を流用） | 実画面あり。セーブ／続きからの旧導線を要変更 | 中 |
| 帰還／死亡／10Fクリア結果 | 専用の現行正式モックなし。旧死亡画像はarchive | 実画面・スクリーンショットあり | 中：報酬・損失／次の行動を整理 |
| 装備・修理 | PX-03が関連参考だが、修理専用の最終配置は未確定 | 工程2で装備・修理の実画面あり | 中 |
| イベント選択／宝箱・戦利品 | **専用の正式参考なし** | イベント条件・報酬台帳と簡易の実画面例 | 中：探索画面の情報パネル |
| 黄金像の祈り／抽選結果 | **専用の正式参考なし** | [SHRINE](SHRINE.md)に仕様。工程3以降 | 後工程 |
| 支給所 | **専用の正式参考なし** | [ITEMS](ITEMS.md)に支給品の保存禁止など。未完成 | 後工程 |
| チェックポイントからの開始階層選択 | **専用の正式参考なし** | 1F・11F等の解放仕様あり | 後工程 |
| スキル構成・自動AI優先度 | **専用の正式参考なし** | [工程4](dot/PHASE_04.md)に機能要件 | 後工程 |
| 仲間・配下・控えの編成 | **専用の正式参考なし** | [工程5](dot/PHASE_05.md)に最大6体仕様。現状はステータスの仮枠 | 後工程 |
| 友好度／忠実度・連携情報 | **専用の正式参考なし** | [工程6](dot/PHASE_06.md)に要件 | 後工程 |

**デザイン制作の推薦順**：冒険準備ハブ → 新倉庫の正式参考 → 階層ミニマップ／全景 → 探索・戦闘の現行差分解消 → 帰還／死亡／ボス結果 → イベント・宝箱。**黄金像／支給所／仲間・スキル・関係性はゲーム工程に合わせて順次設計**。

現在は画像制作の要否が画面によって異なる。まずレイアウトとクリック遷移を確定し、ゲーム側の部品として不足する装飾を画像制作担当へ渡す。コードで動く画面と、ユーザー承認された画像参考を区別する。
