> 0.4.5の履歴。現在のルール・検証結果はREADME.mdを参照。

# Dive In Under — 広い戦闘場の確認

**0.4.5 / 896×504の広い戦闘場＋採用済み通常洞窟v2。工程1全体は未完了。**

PCの確認入口は「01 ゲームを起動」「02 画像・画面を確認」「03 変更点」の3項目を維持。[Windows ZIP](../../build/releases/718e07564f73286c5482a999ea7423df773c32f3-b76c011f/DiveInUnder-0.4.5-windows-x64.zip) / [起動・保存手順](../../tools/PLAY.txt) / [参考と実EXEの横並び比較](index.html)。旧EXE/PCK・ユーザーセーブ・使用中プロセスを保持し、Play.cmdの参照だけ安全切替した。

## 画面全体の変更

常設左パネルを廃して、戦闘場を612×270から**896×504**へ拡大。画面原点(16,16)、右336×688にHP/SP・ステータス・潜行/帰還・停止/速度、下896×172にログを配置。独立したControl/Button/Label等で動作し、主人公1人・完全自動戦闘を維持。

通常洞窟v2はユーザーの「納品されたものを採用で構いません。」で採用。1672×941 RGB、2,998,881bytes、SHA `b251f52cde26bf44481a83de844a6879e5ec6d4d18aa91d7dfd32b25dfab3f6b` 一致。16:9を維持しズーム1.0、回転/剪断/横潰しなし。画像内足元は敵(269,312)、主人公(609,433)、足元下約71px。通常6敵の全身・尾・翼、近景床、ボス頭上、右操作とログを実画像で確認。

[変更前0.4.4](62-current-normal-battle.png) / [通常戦闘](66-wide-normal-battle.png) / [ボス](67-wide-boss.png) / [探索](68-wide-exploration.png) / [イベント](69-wide-event.png) / [町](75-wide-town.png) / [タイトル](76-wide-title.png) / [死亡結果](74-wide-death.png)。[画像担当への寸法・床面仕様](../../docs/IMAGE_PRODUCTION_HANDOFF.md)。

## 検証と版

実行ソース `718e07564f73286c5482a999ea7423df773c32f3`、Godot4.7.2。自己レビューでスクロール時に消えるログ見出しを固定し、背景上で読める不透明な帯へ修正。再テスト・再ビルド・隔離撮影を実施。

- [戦闘142](wide-tests.log)＋[探索/保存180](wide-loop-tests.log)＋[通常探索44](wide-campaign-tests.log)、ヘッドレスUI成功。最終差分は採用メタデータのみでゲーム/UIコードはこのテスト対象と同じ。
- 最終EXE/PCKで[隔離290操作](wide-campaign-isolated-campaign-complete.json)と[ヘッドレス290操作](wide-campaign-headless-campaign-complete.json)、途中/突破後の別EXE再開成功。[非対話Station/Desktop監査](wide-campaign-isolated-isolation-complete.json)。通常デスクトップ操作なし。
- コア・データ・探索方針6ファイルのSHAが[直近1000seed](camera-campaign-summary.json)と一致。今回の画面変更で1000seedのローカル再計算は繰り返さず、成功済み0.4.4 CIの3×1000件と同じロジックを使用。290操作の全状態SHAも従来一致。
- 指定された[CI39038821159](https://github.com/shirai-masatomo/whitespace/actions/runs/39038821159)は**全工程成功**。checkout/head c84d01f、366チェック、1000seed単発再比較、通常探索3×1000、EXE290操作、故障注入10件。[CI ZIP](https://github.com/shirai-masatomo/whitespace/actions/runs/39038821159/artifacts/12103492471) / [ログ](https://github.com/shirai-masatomo/whitespace/actions/runs/39038821159/artifacts/12103447600) / [記録](ci-camera.json)。これは広い戦闘場追加前の0.4.4 CIであり、今回0.4.5のCI成功とは言わない。
- [配布SHA](build-manifest.json) / [安全切替記録](local-release.json) / [画面SHA・表示領域監査](wide-evidence.json) / [Draft PR5と最新Checks](https://github.com/shirai-masatomo/whitespace/pull/5)。

## 後続と履歴

状態4効果は仕様抽出のみで未実装。[正本パスと決定範囲](../../docs/PHASE_01_ACCEPTANCE.md)。キャラモーションは追加しない。

**新たに依頼された初回強制死亡・帰還禁止の廃止は、この0.4.5の画面変更とは別単位で反映する。** このZIPには従来の初回導入が残る。最新mainの変更指示を取り込み、初回帰還・通常死亡・旧セーブ互換を後続検証する。旧統計を新仕様へ無理に一致させない。

OS物理入力・他解像度・長時間試遊は未検証。開発用の単発戦闘確認ツールは従来レイアウトを保持、本編の探索/戦闘を今回拡大した。[前版記録](README-0.4.4.md)。
