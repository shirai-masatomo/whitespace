# Dive In Under — 実画面と技術記録

**0.4.4 / 静止素材の採用反映・ボスの前後配置改善・ネズミv2。参考の斜め視点は未達、工程1全体も未完了。**

PCの確認入口は「01 ゲームを起動」「02 画像・画面を確認」「03 変更点」の3項目を維持。ゲーム起動は従来の[Play.cmd](Play.cmd)が検証済み最新版を選ぶ。[画像付き比較](index.html) / [Windows ZIP](../../build/DiveInUnder-foundation-windows-x64.zip) / [操作・保存手順](../../tools/PLAY.txt)。

## 戦闘画面の変更が見えにくかった理由

調査時点の入口→Play.cmd→current.txtは0.4.3、ソース0477842を指しており、EXE/PCKのSHAは配布記録と一致。旧版へのリンクではなかった。読取確認時にDiveInUnderプロセスは見つからず、ユーザーが見たウィンドウの実行版までは断定しない。

0.4.3は中央612×270の画面で敵(171,208)、主人公(416,236)という**28pxの前後差**と1.04倍の背景クロップだけ。レイアウトや原画のカメラは従来どおりで、参考PX-02の斜め視点への一致を「実装済み」とした説明は不十分だった。現在も通常洞窟の細い水平足場は未修正。

今回の0.4.4は既存ボス床の範囲内で、敵(184,190)、主人公(428,246)へ配置し前後差56px、石像175px高。ネズミv2は原画のまま差替え、v1を保持。**この変更だけで戦闘画面全体の視点問題が解消したとはしない。** 通常床面の改善を最優先に、人物は共通カメラを確定してから比較し、全再生成を前提としない。[画像担当への仕様](../../docs/IMAGE_PRODUCTION_HANDOFF.md)。

## 最新の実EXE

[タイトル](59-adopted-title.png) / [通常戦闘](62-current-normal-battle.png) / [ボス修正後](60-boss-depth-placement.png) / [修正前0.4.3](56-oblique-boss.png) / [ネズミv2](61-rat-v2.png) / [町](63-current-town.png) / [探索](64-current-exploration.png) / [初回死亡](65-current-death.png)。

元の9素材の採用通知を[履歴](visual-adoption.json)へ反映。新納品のネズミv2は承認済みの視点修正に基づく差替えとして原稿SHAと表示域を記録し、旧9点の採用通知と区別する。[全原稿記録](../../assets/visual-candidates/v1/manifest.json)。

## 検証と配布

実行ソース `4f6720192732a7f9d8d24f2d6347220ff637654f`、Godot4.7.2。自己レビューでv2測定値の古いメタデータを修正し、再テスト・再ビルド・隔離実EXEを再検証。

- [142](camera-tests.log)＋[180](camera-loop-tests.log)＋[44](camera-campaign-tests.log)項目、ヘッドレスUI、Windowsビルド成功。
- [隔離290操作](camera-campaign-isolated-campaign-complete.json)と[ヘッドレス290操作](camera-campaign-headless-campaign-complete.json)、途中・突破後の別EXE保存再開成功。[非対話Station/Desktop監査](camera-campaign-isolated-isolation-complete.json)。通常デスクトップへの操作なし。
- 固定1000seedを再実行し全記録・SHA・指標が従来と厳密一致。1000/1000突破、通常12,771探索・1,067死亡（8.35%）、突破まで平均12.771/中央値13。初回死亡1000件は別枠。[要約](camera-campaign-repeat.txt) / [比較JSON](camera-campaign-summary.json) / [全件JSON.gz](camera-campaign-repeat.json.gz)。シミュレーター記録は152db91、その後は表示注記・素材メタデータのみ変更。
- クリアSHA `edd3cace3bb8376f1e2d80cb0cc6a44270874df5893a0a91906b036046996d2a`、保存SHA `0dcca1d55581aba169a1ed6ee4251688e37a2d6320da3042789a17c8b33dc6fa` は従来一致。
- [ZIP/EXE/PCK SHA](build-manifest.json) / [安全切替](local-release.json) / [画面SHA](camera-evidence.json)。旧EXE/PCKと使用中プロセスを保持し、Play.cmdの参照のみ切替。
- [Draft PR5](https://github.com/shirai-masatomo/whitespace/pull/5) / [今回CIの状態](https://github.com/shirai-masatomo/whitespace/pull/5/checks)。今回の最終版CIは結果待ちで、旧0.4.3の成功と混同しない。

## 残る工程1条件

最新main8c0711dを取り込み。正本は「毒・暗闇・麻痺＋防御態勢を先行導入し、短い画面エフェクトまで実装する」と追加。実遭遇、途中保存/再開、状態あり/なしの固定シード・10F比較は未実装。まず視点問題を優先。仲間・全状態・高度AI・キャラモーション・工程2は追加しない。

OS物理入力、他解像度、長時間試遊、複数同時セーブ書込の完全排他は未検証/未対応。[工程1照合](../../docs/PHASE_01_ACCEPTANCE.md) / [前版の記録](README-0.4.3.md)。
