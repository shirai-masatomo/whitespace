# Dive In Under — 初回通常化とボス床面修正

**0.4.6 / 初回から通常探索・帰還。工程1全体は未完了。** [Windows ZIP](../../build/DiveInUnder-foundation-windows-x64.zip) / [操作手順](../../tools/PLAY.txt) / [実画面比較](index.html) / [Draft PR #5](https://github.com/shirai-masatomo/whitespace/pull/5)。PCの入口は「01 ゲームを起動」「02 画像・画面を確認」「03 変更点」の3項目。

## 初回通常化・旧セーブ

新規開始は1Fの通常抽選へ。遭遇解決後は初回から帰還でき、固定階の強制死亡はない。HP0なら通常死亡と同じ報酬・ペナルティ処理。帰還／死亡から町・倉庫・装備・再出発が可能。

保存schema2へ移行。旧schema1の初回前／途中、旧死亡結果、町、探索、戦闘途中、通常死亡を旧設定.1/.2で検証。所持品・装備・EXP・Gold・旧成長設定・総回数を保持し、旧story_deathsは通常死亡から除外。読み込みだけで元ファイルを変更せず、移行後最初の保存前に原本を退避する。検証にユーザー実セーブは使っていない。

[初回1F](78-normal-first-1f.png) / [初回帰還](79-first-return.png) / [町](80-first-town.png) / [初回HP0死亡](81-first-natural-death.png) / [旧履歴](86-legacy-history.png) / [旧セーブ帰還](87-legacy-return.png)。

## ボス・ボタンの自己レビュー

旧67は主人公が崖際に立ち、床が浅い帯に見えた。背景v2の連続石床へ交換し、原画v1を保全。キャラの非等方拡縮や位置ずらしで代用していない。両者の足元と手前に床が続き、門は奥へ離れた。[欠点と修正根拠](../../docs/BOSS_VISUAL_REVIEW_2026-10-17.md)。

[旧ボス](67-wide-boss.png) / [修正ボス](83-boss-floor-v2.png) / [同じEXEの通常戦闘](82-normal-battle.png) / [有効・無効・フォーカス](84-button-states.png)。有効は明るい背景＋濃い文字、無効は灰色、フォーカスは青緑枠。描画順とコントロール位置も監査。床の反射・目地は強めに残るが、足元周囲に穴や崖の立面はなく、旧版の接地問題を解消した。

## 実測

実行ソース `e7c63c65a47712f39702531009a8b2d3d5e7a93a`、Godot **4.7.2.stable.official.ed1daf0bf**、設定 `.3`。戦闘142＋探索保存180＋反復探索44＋初回/移行461＝**827項目成功**。後続変更は表示・検証ドライバーのみ。最終EXEで全フローを再検証。

- 隔離描画・ヘッドレス双方で新規seed10000の**286操作**が共通コアと全状態一致。途中／突破後の3プロセス再開、11F記録、町倉庫、10F再挑戦を確認。
- 初回帰還→町→倉庫往復→装備、初回通常死亡→町→再挑戦、保存再開を実EXEで確認。旧セーブ6種は隔離描画とヘッドレス双方で、移行と別EXE再開を確認。[移行監査](normal-migration-isolated.json)。
- seeds10000〜10999、同じ探索方針、最大30探索。**1000/1000突破、12779探索、通常死亡1080（8.4514%）、帰還10699、打切り0、異常0**。突破まで平均12.779・中央値13・最大19。全指標／各seed／階層記録の厳密再実行一致。
- 旧導入版は12771探索・死亡1067（8.3549%）。新規初回を通常探索に含め、最初から未装備で戦うため差が出る。旧結果への一致は要求しない。[仕様変更比較](normal-first-rule-comparison.json)。成長HP+4対+5の別比較と混同しない。
- [要約](normal-campaign-summary.json) / [全1000記録gzip](normal-campaign-after.json.gz) / [厳密再実行gzip](normal-campaign-repeat.json.gz) / [テスト](normal-first-expedition-tests.log) / [画面SHA](normal-evidence.json) / [配布SHA](build-manifest.json)。

## 残項目と制約

**毒・暗闇・麻痺・防御態勢と短いエフェクトは未実装。** [工程1正本](../../docs/dot/PHASE_01.md)・[受入照合](../../docs/PHASE_01_ACCEPTANCE.md)に従って次に扱う。仲間・犬・黄金像の仲間排出は工程5。工程2へ進まない。

実画面は非対話Window Station/Desktopでアプリ内入力したもの。通常デスクトップへの自動起動・OS物理入力・長時間試遊・他解像度は行っていない。既存EXE/PCK、ユーザー保存、実行中の旧版を保持する。[前版0.4.5の履歴](README-0.4.5.md)。GitHubの最終CI結果はPR Checksと `ci-normal.json`（記録後）を参照。
