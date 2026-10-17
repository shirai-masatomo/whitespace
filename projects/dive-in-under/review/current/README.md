# Dive In Under — 確認入口

**0.4.1 visual candidate A / 通常ソロ10Fを維持した静止画像候補版。5点を現基準として採用済み、工程1全体は未完了。**

PCの入口を本作品のフォルダへ集約しました。

`C:\Users\masat\Documents\codex_test\projects\Dive In Under\確認入口.lnk`

ここから **[Play.cmd](Play.cmd)** または **[画像付き比較ページ](index.html)** を開きます。元の牧場フォルダから移したのは以前作成したDive専用ショートカット1個のみ。他の入口・ファイルは変更していません。

[Windows ZIP](../../build/DiveInUnder-foundation-windows-x64.zip) / [現在のEXE](../../build/releases/187e7f7b2f97ccfda10539340907fe766bebba42-c1bc31aa/DiveInUnder.exe) / [操作・保存手順](../../tools/PLAY.txt) / [環境](../../docs/DEVELOPMENT.md) / [配布SHA](build-manifest.json) / [安全切替記録](local-release.json)。ZIPはEXEとPCKを同じ場所へ展開します。

実行ソース `187e7f7b2f97ccfda10539340907fe766bebba42`、Godot `4.7.2.stable.official.ed1daf0bf`。既存セーブ／戦闘／数値／探索方針は変更なし。旧実行ファイルは停止・上書きせず、検証済みreleaseへの参照だけ切り替えました。

## 素材の採否と画像制作

**[候補5点・来歴・原稿・SHA・採否項目](visual-candidates.md)** / **[画像制作チャット向け引継ぎ](../../docs/IMAGE_PRODUCTION_HANDOFF.md)** / [PX参考との比較](index.html#comparison)。

背景2点、主人公/E04/B10の透過静止画を独立素材として配置。通常背景を浅・中・深層の静的色調と深度名で再利用し、10Fは門背景。UIは実データとつながるControl・Button・Label・ProgressBarです。E01〜E03/E05は仮コード表示、5点は現基準として採用済み。モーションなし。残り敵は親の画像制作チャットへ制作仕様を引き継ぎます。

## 最新の実EXE画面

| 内容 | 画面 |
| --- | --- |
| タイトル／初回 | [タイトル](42-readability-title.png) / [帰還不可の初回](31-visual-first.png) |
| 通常洞窟／深度 | [浅層](39-visual-shallow.png) / [中層](38-visual-middle.png) / [深層](33-visual-deep.png) |
| 候補キャラ | [主人公＋E04](32-visual-goblin.png) / [主人公＋B10](34-visual-boss.png) |
| 町・装備・倉庫 | [ステータス／11部位／倉庫](41-town-status-readable.png) |
| 死亡／突破 | [初回死亡](36-visual-first-death.png) / [通常死亡](40-visual-normal-death.png) / [10F突破](37-visual-clear.png) |

## 0.4.1 — 町の能力値の読みやすさだけを修正

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

2026-10-17、ユーザーの「とりあえず採用でいいよ」により、背景2点・主人公・E04坑道ゴブリン・B10門番の石像の5点を現時点の基準素材として採用。永久固定ではなく、必要な見直しは可能。静止画のみを維持。 [採用記録](visual-adoption.json) / [残る4敵の制作仕様](../../docs/IMAGE_PRODUCTION_HANDOFF.md)。0.4.1 EXEと画像は採用通知前の収録のため、候補/採否未定の表示を含みます。今回の資料更新で実行ファイルは作り直さず、可読性修正のCIと後続UI調整の結果を混同しません。


町の可読性修正0.4.1のCIはhead `cf7cfac259d0f39934fafefbe7f4d8082e38804e` で [PR run39031447916](https://github.com/shirai-masatomo/whitespace/actions/runs/39031447916) と [push run39031444026](https://github.com/shirai-masatomo/whitespace/actions/runs/39031444026) が成功。PR実checkoutは `9390b89d0b1587f20fc86d4e1736b0f372c66aa7`。366チェック・1000seed厳密再比較・EXE290操作/別プロセス再開・故障注入10件を確認。[CI Windows ZIP](https://github.com/shirai-masatomo/whitespace/actions/runs/39031447916/artifacts/12100702226) / [JSON・ログ](https://github.com/shirai-masatomo/whitespace/actions/runs/39031447916/artifacts/12101150514)、期限2027-01-15。後続の採用通知/引継ぎ/CI記録は資料のみで、ローカル配布ソース187e7f7と区別する。
