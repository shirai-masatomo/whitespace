# Dive In Under — ローカル確認入口

**0.3.0 solo10 / 通常ソロ10Fの実装側検証済み。工程1全体は画作り要件が未達です。**

このPCでは、いつもの牧場の確認フォルダにある **Dive In Under 確認.lnk** → **[Play.cmd](Play.cmd)** で起動します。[画像付きページ](index.html)。

`C:\Users\masat\Documents\codex_test\projects\sporehollow\確認入口\Dive In Under 確認.lnk`

入口は同じです。Play.cmdは検証済み配布ディレクトリへの参照だけを切り替え、使用中の旧EXE/PCKは停止・上書きしません。旧保存は元の成長設定で継続、新規開始だけHP成長+5を使います。異なる版で同じ保存を同時に遊ばないでください。

[Windows ZIP](../../build/DiveInUnder-foundation-windows-x64.zip) / [現在のEXE](../../build/releases/24314385e5ed6c4f6d4fffefc5be87108d073d11-851ac5dd/DiveInUnder.exe) / [操作・保存手順](../../tools/PLAY.txt) / [開発環境](../../docs/DEVELOPMENT.md) / [SHA256](build-manifest.json) / [切替記録](local-release.json)。ZIPのEXEとPCKは同じ場所に展開してください。配布ファイル名は既存リンク維持のため継続しています。

実行ソースは `24314385e5ed6c4f6d4fffefc5be87108d073d11`、固定Godot `4.7.2.stable.official.ed1daf0bf`。通常探索シミュレーターの記録は `d146437`（ゲームコア同一）、後続の資料コミット、PR head、CIの実checkoutは区別します。[Draft PR #5](https://github.com/shirai-masatomo/whitespace/pull/5) / [最新Checks](https://github.com/shirai-masatomo/whitespace/pull/5/checks)。

## 今回の結果

- 新規セーブseed10000から通常13探索、通常死亡1回・帰還11回を経て10F突破。初回死亡は別に1回のみ。Lv編集・階層スキップ・無敵・強制勝利なし。
- 290操作すべてを実UIのクリック/通常Timer経路で実行し、ヘッドレスの全状態SHAと一致。途中終了→別EXE再開→突破→倉庫出入れ→再出発→3つ目のEXE再開を確認。
- 1000固定seedの設定前後比較：突破率100%→100%、探索数中央値14→13、p90は17→15、通常探索死亡率10.12%→8.35%。異常/未突破seedなし。初回探索/死亡は分子・分母から除外。
- 敵・遭遇・報酬の正本を保持し、仮の主人公HP成長のみ+4→+5。正式な難易度決定ではありません。[全受入項目・方針・分位・限界](../../docs/PHASE_01_ACCEPTANCE.md)。
- [戦闘142](tests.log)＋[探索/保存180](loop-tests.log)＋[通常10F 44](campaign-tests.log)成功。[既存故障6件](harness-faults.json)＋[継続探索故障4件](campaign-harness-faults.json)を拒否。攻撃ログ重複・導入死亡混入を修正し再検証。

## 最新の実EXE画面

| 画面 | 証拠 |
| --- | --- |
| タイトル / 初回探索 | [タイトル](11-campaign-title.png) / [初回探索](12-campaign-first.png) |
| 初回死亡 / 町 | [初回死亡](13-campaign-first-death.png) / [町](14-campaign-town.png) |
| 通常死亡 / ボス | [通常死亡](15-campaign-normal-death.png) / [10F戦闘](16-campaign-boss.png) |
| 10F突破 / 保存後の町 | [突破](17-campaign-clear.png) / [町・装備・倉庫](18-campaign-clear-town.png) |

**[PX-01〜03との横並び比較](index.html#comparison)**。通常デスクトップへ自動起動していません。隔離アプリ内入力の証拠であり、OS物理入力の検証とは区別します。親の要件上、人間への手動試遊の強制はしません。

## 検証データ

- [before要約JSON](campaign-before-summary.json) / [after要約JSON](campaign-after-summary.json) / [日本語after要約](campaign-after.txt) / [同条件差分](campaign-comparison.json)。階層別到達/死亡/帰還、敵・Lv・戦利品、EXP/Goldと分位を含みます。
- 全seed/全探索記録：[before JSON.gz](campaign-before.json.gz) / [after JSON.gz](campaign-after.json.gz) / [再実行JSON.gz](campaign-repeat.json.gz)。gzip解凍でJSONになります。未圧縮SHAは各要約に記録。[厳密一致](campaign-repeat-summary.json)。CI証拠には生JSONも保存します。
- [seed10000全操作列](campaign-replay.json) / [ヘッドレスEXE一致](campaign-headless-campaign-complete.json) / [隔離GPU一致](campaign-isolated-campaign-complete.json) / [最終再起動](campaign-isolated-campaign-final.json)。
- [隔離監査](campaign-isolated-isolation-complete.json) / [GPUログ](campaign-isolated-complete.log) / [ビルドログ](export.log)。非対話Stationと専用Desktop、所有窓、run ID、EXE/PCK SHAを照合。

## 残る工程1と素材

main e7cc5a2で追加された[画作り受入基準](../../docs/dot/PHASE_01_VISUAL_TARGET.md)は**未達**です。背景はコード矩形、主人公/E01〜E05/B10は静止コード配列の仮素材。独立背景画像、背景透過スプライト、階層帯/ボス背景の差、ユーザーによる素材採否・見た目の節目評価が残ります。モーションは作っていません。

[背景コード](../../ui/cavern.gd) / [静止キャラ候補](../../ui/battle_stage.gd) / [現行参考3枚](../../assets/ui-mocks/README.md)。UIは実データを表示するGodot Controlで、画像全体をクリック画面にしていません。仲間/犬/ガチャ/耐久/全スキル/11F内容は工程外です。

旧0.2画面01〜10とLibrary4画像は保存済み履歴です。[旧Library ID](library-images.json)。旧 `isolation.json` / `ci.json` / `first-start-*` / `solo-E*` も当時の証拠で、今回の0.3描画証拠には流用しません。最新CIはChecksとこの入口の追記で区別します。

## 0.3のCI証拠

[Windows CI 39026936268](https://github.com/shirai-masatomo/whitespace/actions/runs/39026936268) は実checkout/head `2431438` で全工程成功。単発・通常1000seedの前後/厳密比較、3つのEXE、故障注入10件を含む。[CI ZIP](https://github.com/shirai-masatomo/whitespace/actions/runs/39026936268/artifacts/12099420409) / [CI証拠](https://github.com/shirai-masatomo/whitespace/actions/runs/39026936268/artifacts/12099415456)、期限2027-01-15。 [実行記録JSON](ci-solo10.json)。main資料統合・証拠追記後のPR merge CIは最新Checksで区別します。
