# Dive In Under — 確認入口

**0.4.2 UI refinement / 通常ソロ10Fを維持した静止画像候補版。5点を現基準として採用済み、工程1全体は未完了。**

PCの入口を本作品のフォルダへ集約しました。

`C:\Users\masat\Documents\codex_test\projects\Dive In Under\確認入口.lnk`

ここから **[Play.cmd](Play.cmd)** または **[画像付き比較ページ](index.html)** を開きます。元の牧場フォルダから移したのは以前作成したDive専用ショートカット1個のみ。他の入口・ファイルは変更していません。

[Windows ZIP](../../build/releases/7bc5f347d2c94019ff20acb9bc4ba83ab6c06fa7-14bc7557/DiveInUnder-0.4.2-windows-x64.zip) / [現在のEXE](../../build/releases/7bc5f347d2c94019ff20acb9bc4ba83ab6c06fa7-14bc7557/DiveInUnder.exe) / [操作・保存手順](../../tools/PLAY.txt) / [環境](../../docs/DEVELOPMENT.md) / [配布SHA](ui-refinement-build-manifest.json) / [安全切替記録](ui-refinement-local-release.json)。ZIPはEXEとPCKを同じ場所へ展開します。

実行ソース `7bc5f347d2c94019ff20acb9bc4ba83ab6c06fa7`、Godot `4.7.2.stable.official.ed1daf0bf`。既存セーブ／戦闘／数値／探索方針は変更なし。旧実行ファイルは停止・上書きせず、検証済みreleaseへの参照だけ切り替えました。

## 素材の採否と画像制作

**[候補5点・来歴・原稿・SHA・採否項目](visual-candidates.md)** / **[画像制作チャット向け引継ぎ](../../docs/IMAGE_PRODUCTION_HANDOFF.md)** / [PX参考との比較](index.html#comparison)。

背景2点、主人公/E04/B10の透過静止画を独立素材として配置。通常背景を浅・中・深層の静的色調と深度名で再利用し、10Fは門背景。UIは実データとつながるControl・Button・Label・ProgressBarです。E01〜E03/E05は仮コード表示、5点は現基準として採用済み。モーションなし。残り敵は親の画像制作チャットへ制作仕様を引き継ぎます。

## 最新の実EXE画面

| 内容 | 画面 |
| --- | --- |
| タイトル／初回 | [タイトル](46-ui-title.png) / [帰還不可の初回](31-visual-first.png) |
| 通常洞窟／深度 | [浅層](39-visual-shallow.png) / [中層](38-visual-middle.png) / [深層](33-visual-deep.png) |
| 候補キャラ | [主人公＋E04](45-ui-battle.png) / [主人公＋B10](47-ui-boss.png) |
| 町・装備・倉庫 | [ステータス／11部位／倉庫](44-ui-town.png) |
| 死亡／突破 | [初回死亡](36-visual-first-death.png) / [通常死亡](40-visual-normal-death.png) / [10F突破](37-visual-clear.png) |

## 0.4.2 — 既存Godot UIの質感と情報整理

実行ソース `7bc5f347d2c94019ff20acb9bc4ba83ab6c06fa7`。羊皮紙の控えめな繊維模様、パネル余白内の真鍮枠、見出し帯、11部位の交互行と「部位／装備名／既存の能力効果／外す」の整列を追加。既存ボタン・操作・データを維持し、アニメーションや新しい画像は追加していません。5点の現基準採用をEXE内注記とmanifestへ反映。未納品E01〜E03/E05は仮表示のままです。

[町：変更前0.4.1](41-town-status-readable.png) / [変更後0.4.2](44-ui-town.png) / [通常戦闘](45-ui-battle.png) / [タイトル](46-ui-title.png) / [10F](47-ui-boss.png) / [初回帰還](48-ui-first-town.png) / [結果](49-ui-result.png) / [探索](50-ui-exploration.png)。[PX並列比較](index.html#comparison)。

- [戦闘142](ui-refinement-tests.log)＋[探索/保存180](ui-refinement-loop-tests.log)＋[10F44](ui-refinement-campaign-tests.log)成功、ヘッドレスUI/Windowsビルド成功。実画面の自己レビューで無効ボタンの幅と装飾線の余白を修正し、再テスト・再ビルド・再撮影。
- [隔離EXE290操作](ui-refinement-campaign-isolated-campaign-complete.json)と[ヘッドレスEXE](ui-refinement-campaign-headless-campaign-complete.json)、[別EXE再開](ui-refinement-campaign-isolated-campaign-final.json)成功。クリア・保存SHAは従来と同一。
- [非対話Station/Desktop監査](ui-refinement-campaign-isolated-isolation-complete.json) / [GPUログ](ui-refinement-campaign-isolated-complete.log) / [画面SHA](ui-refinement-evidence.json)。全3プロセス終了0、タイムアウトなし。通常デスクトップ操作・旧EXE停止なし。
- コア・保存・データ・PNG・探索方針の差分なし。ローカル1000seed再計算は省略し、今回CIの厳密比較を別に記録します。旧版の成功CIは今回の結果と混同しません。

**残り**：残敵4種の納品・別単位での組込、PXとの節目レビュー。参考の細かな装飾や装備アイコン配置との一致は未達で、今回の控えめなコード描画改善だけで工程1完了とはしません。追加UI画像は現時点で不要。主人公単独・11部位・HP/SP・ログを維持。OS物理入力・別解像度・長時間試遊の制約は継続。

## 前回0.4.1 — 町の能力値の読みやすさだけを修正

HP/SP/Lv/ATK/DEF/SPD/Goldを不透明な濃色パネルへ配置。文字21px、左右12px・上下4pxの余白。1280×720の実EXEで一覧、装備11部位、再出発ボタンが収まることを確認しました。[修正後](41-town-status-readable.png) / [修正前0.4](35-visual-town.png) / [初回帰還後](43-town-status-first-return.png)。他の旧画像30〜40はb358aa1時点の履歴です。

- [戦闘142](readability-tests.log)＋[探索/保存180](readability-loop-tests.log)＋[10F44](readability-campaign-tests.log)成功。Windows再ビルド後に実画面を自己レビュー。
- [隔離EXE290操作](readability-campaign-isolated-campaign-complete.json)、[ヘッドレスEXE](readability-campaign-headless-campaign-complete.json)、[別EXE保存再開](readability-campaign-isolated-campaign-final.json)成功。0.4とクリア・保存SHAが一致。
- [隔離監査](readability-campaign-isolated-isolation-complete.json) / [GPUログ](readability-campaign-isolated-complete.log) / [画像SHA](readability-evidence.json)。3プロセスとも非対話Station＋専用Desktop、終了0、タイムアウトなし。
- コア・データ・既存PNG・シミュレーション方針はb358aa1から差分なし。1000seedのローカル全件再計算は今回省略し、下記0.4の厳密比較を継承。今回のCI結果はPR Checksで別管理します。

羊皮紙・真鍮の素材感と装備UIはPX参考より簡素で、画作りの残課題です。5素材はこの検証後に現基準として採用されました。実装側で追加画像を重複生成しません。

## 回帰証拠

- [戦闘142](visual-tests.log)＋[探索/保存180](visual-loop-tests.log)＋[10F44](visual-campaign-tests.log)成功。素材組込後にテスト・ビルド・実画面レビュー。フォーカス枠の影による暗転を修正し、再ビルド・実EXE再検証済み。
- [1000seed厳密比較](visual-campaign-repeat-summary.json)／[全文JSON.gz](visual-campaign-repeat.json.gz)／[日本語要約](visual-campaign-repeat.txt)：12,771探索・1,067通常死亡・全1000件10F突破、全記録/状態SHA/指標が従来と一致。測定時のcommit表記は`158fb06+dirty`で、現在の実EXEとのコア・データ・方針SHA一致を確認しています。
- [隔離EXEの290操作](visual-campaign-isolated-campaign-complete.json)／[ヘッドレスEXE](visual-campaign-headless-campaign-complete.json)／[第3プロセス再開](visual-campaign-isolated-campaign-final.json)。クリア・保存SHAは0.3と同一。通常13探索、死亡1・帰還11、初回死亡は別に1回。
- [隔離監査](visual-campaign-isolated-isolation-complete.json)／[GPUログ](visual-campaign-isolated-complete.log)／[画像配置監査](34-visual-boss-audit.json)／[画面SHAと元の撮影名](visual-evidence.json)。非対話Station＋専用Desktop、終了0、タイムアウトなし。通常デスクトップへの自動起動なし。
- [既存故障6件](visual-harness-faults.json)＋[比較故障4件](visual-campaign-harness-faults.json)を拒否。UI入力はviewportクリックと通常Timerで、OS物理入力の試験ではありません。

[Draft PR #5](https://github.com/shirai-masatomo/whitespace/pull/5) / [最新CI Checks](https://github.com/shirai-masatomo/whitespace/pull/5/checks)。今回の画像候補版と以前の成功CIを混同しません。0.3 CIは[記録](ci-solo10.json)、旧画面01〜18／旧Library画像／従来campaign証拠は履歴として保存。

## 残り

残るE01〜E03/E05の静止画、参考への近さの節目レビュー。OS物理入力、別解像度、長時間試遊は未検証。完全な同時セーブ書込排他は未対応。仲間・犬・耐久・全スキル・11F内容は工程外。**5点の採用は記録済み。工程1全体は未完了です。** [全受入照合](../../docs/PHASE_01_ACCEPTANCE.md)。

## 採用通知後の資料更新

2026-10-17、ユーザーの「とりあえず採用でいいよ」により、背景2点・主人公・E04坑道ゴブリン・B10門番の石像の5点を現時点の基準素材として採用。永久固定ではなく、必要な見直しは可能。静止画のみを維持。 [採用記録](visual-adoption.json) / [残る4敵の制作仕様](../../docs/IMAGE_PRODUCTION_HANDOFF.md)。0.4.1 EXEと画像は採用通知前の履歴です。現0.4.2では採用済み表示へ更新。前回と今回の検証は別記録です。


町の可読性修正0.4.1のCIはhead `cf7cfac259d0f39934fafefbe7f4d8082e38804e` で [PR run39031447916](https://github.com/shirai-masatomo/whitespace/actions/runs/39031447916) と [push run39031444026](https://github.com/shirai-masatomo/whitespace/actions/runs/39031444026) が成功。PR実checkoutは `9390b89d0b1587f20fc86d4e1736b0f372c66aa7`。366チェック・1000seed厳密再比較・EXE290操作/別プロセス再開・故障注入10件を確認。[CI Windows ZIP](https://github.com/shirai-masatomo/whitespace/actions/runs/39031447916/artifacts/12100702226) / [JSON・ログ](https://github.com/shirai-masatomo/whitespace/actions/runs/39031447916/artifacts/12101150514)、期限2027-01-15。後続の採用通知/引継ぎ/CI記録は資料のみで、ローカル配布ソース187e7f7と区別する。
