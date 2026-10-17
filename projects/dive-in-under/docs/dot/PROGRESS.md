# Dive In Under — Dot自律開発 工程進捗

> **実測更新（2026-10-17）**：通常ソロ10FのWindows EXE 0.3.0を検証。**工程1全体は画作り要件が未達で進行中**。[全受入照合](../PHASE_01_ACCEPTANCE.md)、[同じローカル確認入口](../../review/current/README.md)。工程2へ進まず親の受入評価へ戻す。
>
> 工程単位の状態を本資料、機能単位の状態を[IMPLEMENTATION_STATUS.md](../IMPLEMENTATION_STATUS.md)で管理する。進捗状況は実際のテスト・成果物がなければ「完了」にしない。

| 工程 | 到達点 | 状態 | 検証証拠（PR／CI／Windows ZIP／実画面／シミュレーション） |
| --- | --- | --- | --- |
| **01** | **主人公単独・反復探索から10F突破＋PX画作り** | **通常進行検証済み／画作り未達** | [PR #5](https://github.com/shirai-masatomo/whitespace/pull/5)、[0.3 ZIP・実画面・全指標](../../review/current/README.md)、[受入照合](../PHASE_01_ACCEPTANCE.md) |
| **02** | ソロ用装備11枠・耐久・育成・経済・支給所 | **未着手** | なし |
| **03** | 階層・宝箱・ドロップ・イベント、黄金像のアイテム／装備 | **未着手** | なし |
| **04** | 主人公／敵の自動スキル・SP・状態異常・戦闘AI | **未着手** | なし |
| **05** | **ここで仲間導入**：人間3＋配下3・犬イベント・死亡 | **未着手** | なし |
| **06** | 友好度・忠実度・連携／隊列の評価 | **未着手** | なし |
| **07** | UI・難易度・アート・Windows試遊版の総合調整 | **未着手** | なし |

### 状態と更新方法

未着手 → 進行中 → 検証中 → 完了。またはブロック。DotはPR・CI・ビルドの証拠を記載し、完成していない作業を完了扱いしない。特に工程1は**初回強制死亡だけで終わらず、2回目以降の単独探索で10Fまで攻略・帰還できること**を確認する。

## 追加された画作り要件

main e7cc5a2 の [画作り受入基準](PHASE_01_VISUAL_TARGET.md) を保持する。通常10F進行の検証と、背景画像・独立透過静止スプライト・採否レビューは別の受入項目。現行はコード仮描画であり美術要件は未達、工程1全体を完了とはしない。

## 次のタスク

親の受入評価へ戻す。通常10F進行・保存・隔離実操作は検証済み。新たな画作り要件の独立背景画像・透過静止スプライト・採否比較が残る。工程2以降へ進まない。ゲームの数値や素材の正式決定を勝手に行わない。

main be0e601 の追加設計（COMBAT v0.2の8属性・状態異常・追加能力、ITEMSの個体差・印）を統合した。物理通常攻撃式は同じであり、追加機能は将来設計として保持し、今回の実装範囲を拡張しない。

## 今回の通常ソロ10F（0.3.0 / 2431438）

- コア/シミュレーター実装d146437、配布・故障検査2431438。main e7cc5a2を資料統合。実行ソースと後続資料head、CIのmerge checkoutは別記録。
- 新規seed10000、通常13探索（9回目に10F通常死亡、13回目に勝利）、Lv1→10、EXP585、Gold447、残HP25。11F到達のみ記録し内容は入場不可。無敵・編集Lv・階層スキップ・強制勝利なし。
- 実EXEの290操作が共通Expedition/Combatから生成した状態SHAとすべて一致。途中終了→2つ目のEXEで再開→突破→倉庫相互移動→再出発→3つ目のEXEで全保存SHA一致。非WinSta0/非表示Stationだけで実行し、3回とも所属Desktop一致・終了0・ログエラーなし。
- 通常1000seed（10000〜10999、最大30探索）で全件突破。HP成長だけ仮+4→+5にすると通常死亡率10.12%→8.35%、突破探索中央値14→13/p90 17→15。異常seed・未突破seed・進行停止0。初回1000探索/死亡は分母分子から除外。全記録・操作ハッシュ・全指標・階層集計の厳密再実行一致。
- 戦闘142＋探索/保存180＋10F44項目、旧故障6＋新故障4件。親レビューの累計死亡混入と前ラウンド攻撃重複を修正し、先手勝利/敗北を固定4.7.2で検証。自己レビューでLv上昇時のHP損失集計を修正し、故障注入が元値と同じになるケースも直して再検証。
- 旧セーブの設定.1/成長+4は変更せず、ロード時にその版を使用。新規だけ設定.2/+5。旧EXE/PCKのSHA不変。新規のbuild/releases配下へ出力し、Play.cmdが読む小さい参照ファイルだけを原子的に切替。使用中ゲームを停止・上書きしない。
- [検証表と全受入判定](../PHASE_01_ACCEPTANCE.md)、[before/after](../../review/current/campaign-comparison.json)、[厳密再現](../../review/current/campaign-repeat-summary.json)、[実画面比較](../../review/current/index.html#comparison)。追加の美術要件が未達なので工程1完了ではない。

- [Windows CI 39026936268](https://github.com/shirai-masatomo/whitespace/actions/runs/39026936268) は実checkout/head `2431438` で全工程成功。単発・通常1000seedの前後/厳密比較、3つのEXE、故障注入10件を含む。[CI ZIP](https://github.com/shirai-masatomo/whitespace/actions/runs/39026936268/artifacts/12099420409) / [CI証拠](https://github.com/shirai-masatomo/whitespace/actions/runs/39026936268/artifacts/12099415456)、期限2027-01-15。 [CI記録](../../review/current/ci-solo10.json)。

## 以前の記録

以下は0.2以前の時点の記録。10F未検証・人手未検証の記述は当時のもので、現在の機能受入は上の照合表を参照する。

## 基幹ループ履歴（214a1a9）

- 新規→初回探索→仮2Fシナリオ死亡（死亡時点で済フラグ保存）→結果→町→倉庫/11枠→通常探索/帰還/死亡/再挑戦を実装。すべて主人公単独、仲間・犬・ガチャ・耐久・全スキルなし。
- `expedition.json` に初期値・Lv成長・イベント・死亡ペナルティを分離。既定の町無料全回復、EXP/装備保持で再出発可能。FLOORS/ENEMIES/ITEMS/EVENTSの1〜10Fデータを使用。EV03除外、適格イベント個別重みは未定のため等確率。
- [戦闘142](../../review/current/tests.log)＋[ループ/保存177](../../review/current/loop-tests.log)成功。[100seed×12回の3F帰還反復](../../review/current/loop-summary.json)を検証。高Lv入力で10Fボス→11F記録→再挑戦の分岐を検査したが、通常成長による10F攻略バランス証明は未実施。
- 一時保存→検証→前回.bak→置換、外部更新検出、破損/未来版拒否、明示的なバックアップ復旧。初回途中/死亡結果/町/戦闘途中の再開、連打、装備入替、所有重複/消失、保存失敗をテスト。
- [別EXE再起動](../../review/current/resume-smoke.json)で戦闘途中のrevision33・保存SHA一致。[実画面10枚と入口](../../review/current/README.md)、[隔離監査](../../review/current/isolation.json)で非WinSta0/非表示・専用Desktop・起動PID所属・終了0を確認。人間のOS入力は未検証。
- 独立レビューの検証偽陽性3件を修正：[故障注入6件](../../review/current/harness-faults.json)を拒否。CIの厳密再現はrecords/log SHA/全metricsを正規化比較し、不一致でexit1。Start/停止/再開/再戦/Backを確認後だけ成功出力。両EXEハーネスは共通nonce照合で古い成功JSONを拒否。
- 自己レビュー後、町の出発ボタンを画面内へ修正、装備効果を表示、保存の戦闘能力整合と未来版の巻戻し防止を追加し、再テスト・再ビルド・隔離EXE確認を実施。
- ユーザーの追加指示で、牧場の既存ローカル `確認入口` に `Dive In Under 確認.lnk` を1個だけ追加。本作の `review/current/` を参照する。既存リンク・牧場コードは無変更、新しい確認フォルダは作成せず。Play.cmd/EXE/PCK/版/リンクを検査し、自動起動は行っていない。
- 同じ保存への同時書込みの完全排他、保存設定版の自動移行、長時間プレイは未対応/未検証。書込み失敗時は状態変更を取り消す。
- CIのheadと実checkoutを区別する。前回PR head243d6adはmerge commit7ca6c12を実行した。2026-10-17のhead `32b87a1` で [push CI](https://github.com/shirai-masatomo/whitespace/actions/runs/39025558947) と [PR CI](https://github.com/shirai-masatomo/whitespace/actions/runs/39025562061) が成功。PRの実checkoutは `d5348538a2052105dacc707b3eea3bd58689893d`。戦闘142＋ループ177・厳密1000seed比較・EXE再開・故障注入6件が成功し、[CI ZIP](https://github.com/shirai-masatomo/whitespace/actions/runs/39025562061/artifacts/12098357692) と [CIログ](https://github.com/shirai-masatomo/whitespace/actions/runs/39025562061/artifacts/12098372666) を保存。期限2027-01-15。ローカルGPU検証版214a1a9とは区別する。 [CI記録](../../review/current/ci.json)。

- 通常勝利バナーを追加し177項目で再検証。CI39025060294は故障注入の期待exit1がPowerShell親へ残るため失敗した。全検査後に終了コードを0へ戻し、GitHubと同じラッパーで再実行してexit0を確認した（80c5054）。

## 前回の戦闘基盤（472bc01）の記録

- ソース: `472bc01a9a816530fcb462e4ff90883e354b94cc`。この後の資料・証拠追記コミットとは区別。ブランチ `dot/dive-in-under/phase-01`、main `5b016439da69730a601dd80cc1c24a4a722b8857` をマージ済み。旧prototypeと他作品の既存未コミット変更は変更していない。
- Godot `4.7.2.stable.official.ed1daf0bf` + 同版テンプレート + GDScript。配布ZIPはEXE/PCK/手順/ライセンス/BUILD.json、未署名。正確な環境・再現方法は [DEVELOPMENT.md](../DEVELOPMENT.md)。
- [142項目・失敗0](../../review/current/tests.log)。速度順、同速の再現性、死者行動停止、50ラウンド打切り、敵Lv補正1回、入力不変、UI逐次進行と一括コアの一致、JSON比較、異常入力を検証。
- [1,000固定seed](../../review/current/simulation.json) は10000〜10999、主人公HP24/ATK6/DEF1/SPD6/SP0の試験専用実効値、E04 Lv4。勝率21.6%、死亡率78.4%、打切り0%、平均4.152/中央値4ラウンド、全戦闘残HP平均1.331/中央値0、勝利時残HP平均6.162/中央値6。再実行の [同条件比較](../../review/current/comparison.json) は全指標差0。難易度の妥当性や連続10F攻略の証明ではない。
- 追加の4条件も各1,000seed、異常結果0。E01 Lv1: 勝率100%/平均2.043ラウンド/残HP平均20.957、E02 Lv1: 100%/3.061/19.905、E04 Lv2: 97.7%/4.175/8.382、E04 Lv3: 26.6%/4.140/1.676。[条件別集計](../../review/current/scenario-summary.json)。敵Lv以外同一でもLv2→3で急変するため、後続の成長・装備・回復を含む調整が必要。
- Windows EXEのヘッドレス入力経路と、非対話Window Station内の隔離GPU描画を実測。キャッシュ修正後2回連続正常終了、GPUログのERRORなし。最終PID16780、非WinSta0/非表示、専用Desktop一致、所有窓2、終了0。[隔離監査](../../review/current/isolation.json)、[GPUログ](../../review/current/render.log)、[初回監査](../../review/current/first-start-isolation.json)。
- 実画面3枚はタイトルと戦闘確認の2画面/3状態。現行PX-01〜03を実際に確認し、青緑の洞窟、水、橙色ランタン、真鍮/羊皮紙パネル、主人公1人と敵の静止ドットに反映。画像をクリック画面にはしていない。素材は候補・未承認、キャラクターは静止画1枚方針。装備11枠の画面は未実装。
- CI `ae0f8a287cda5fb79791b68eec8ac7be411d479b` の [Windows PR実行](https://github.com/shirai-masatomo/whitespace/actions/runs/39022931253) は成功（2026-10-17）。テスト/エクスポート/同seed比較/実EXEヘッドレス/ZIPと証拠アップロードを完了。[CI配布ZIP](https://github.com/shirai-masatomo/whitespace/actions/runs/39022931253/artifacts/12096484715) / [CIログ一式](https://github.com/shirai-masatomo/whitespace/actions/runs/39022931253/artifacts/12097054030)、保存期限2027-01-15。この記録の追記後のhead結果は [PR Checks](https://github.com/shirai-masatomo/whitespace/pull/5/checks) で区別する。CI版はBUILD.jsonにソースコミットを記録し、ローカルGPU確認版472bc01と区別。課金・支払い・Steam公開は行っていない。

## 自己レビューで修正し再検証した点

1. JSON読込前後の整数/浮動小数表現で同条件比較が不一致になる問題を正規化で修正し、往復テストを追加。
2. エクスポートに共通コア/描画スクリプトが不足する問題を実EXEで検出。明示的な対象リストに修正し、再ビルドとEXE起動で確認。
3. UI上端のボタン余白、フォーカス時の文字色を画面確認後に修正。入力確認はGodot viewportのマウスイベント経路を通し、直接signal呼出しだけに依存しない。
4. 当初の画面外/no_focus起動は隔離ではなく、通常デスクトップへ表示された可能性がある。停止指示後、この経路を禁止。牧場の成功手順を読み取り参照し、非表示Station・専用Desktopを作成前検査する専用ツールへ置換。アクセス拒否後の代替起動は設けていない。ユーザー操作中のアプリは終了していない。
5. 隔離再起動でシェーダーキャッシュの長いパスに関連するエラーを検出。ディスクキャッシュを無効にし、142項目・ビルド・比較・実EXE・2回の隔離描画を再確認。既存データは削除していない。

**検証制約**：隔離画面の入力はアプリ内マウスイベントであり、OSの物理入力や人間のWindows試遊ではない。通常デスクトップへの自動GUI起動は禁止のまま。日本語フォントはWindowsの既存フォントを参照し、別OS環境は未検証。
