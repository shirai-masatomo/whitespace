# Codexへの連携文 — 2Dドット調UIへの参考差し替え（2026-10-17）

## そのままCodexへ共有する文面

Dive In Underの**GitHub上のUI参考を更新しました**。以前の絵画・3D調の4枚ではなく、mainの次の3枚を**現行優先UI参照**として読み直してください。

- 探索・全体UI：https://github.com/shirai-masatomo/whitespace/blob/main/projects/dive-in-under/assets/ui-mocks/01_exploration_pixel.webp
- 戦闘UI：https://github.com/shirai-masatomo/whitespace/blob/main/projects/dive-in-under/assets/ui-mocks/02_battle_pixel.webp
- ステータス／装備UI：https://github.com/shirai-masatomo/whitespace/blob/main/projects/dive-in-under/assets/ui-mocks/03_status_pixel.webp
- 必ず確認する詳細説明：https://github.com/shirai-masatomo/whitespace/blob/main/projects/dive-in-under/docs/UI_MOCKS.md

**方針：2Dドット絵の洞窟背景、青緑とランタンの暖色、羊皮紙／真鍮のメニューとステータス表示をデザイン基盤にする。** 進行中の工程1のコード・戦闘コア・セーブ・ビルド構成は維持し、UIを段階的に改善してください。以前の4枚は履歴用アーカイブへ移動済みです。

**モックに描かれた追加機能は実装しないでください**。戦闘は完全自動・素早さ順なので、戦闘画像の「たたかう／スキル／にげる」を手動ターンコマンドとして追加しないこと。初回は主人公1人。3人の味方表示は工程5以降の参考です。探索画面のミニマップ・横スクロール移動・32階は本作の機能要件ではなく、工程1の「潜る／帰還」と地下1〜10Fを維持してください。**追記：器用さ・魔法攻撃／防御・運・精神力・魅力・信仰心と8属性は、2026-10-17に導入予定として設計採用されました。ただし画像中の能力値・耐性倍率はサンプルで、工程1への実装指示ではありません。**

ステータスは正式なHP、ATK、DEF、SPD、SPを基本に、人間の装備スロットは左右手＋防具4＋装飾品5＝11枠を尊重してください。画像内のLv・アイテム名・数値は仮の例です。

**作業について**：現在の作業ブランチへmainの最新参考UIと資料を取り込んでください。既に作成済みのゲーム処理を一から作り直す必要はありません。実画面と新モックを比較するスクリーンショットを残し、UIで採用した要素と意図的に採用していない要素を記録してください。

共有いただいた開発方針の**Godot 4系、GDScript、Windows EXE＋ZIP、ゲーム本体と同じ共通戦闘コアのヘッドレス検証、固定乱数シードの1,000回以上の試験**はそのまま継続してください。Godot実バージョンとPC導入済み環境、実際に成功したWindowsビルド／テストは、確認した結果と計画とを区別してGitHubへ記録してください。必要な共有事項や判断待ちはGitHubとこのチャットへ要点を出してください。

## この連携の性質

- **今回のGitHub変更は参考画像・Markdownのみ**。Windows EXEや開発中コードへの適用はCodex側で実施する。
- Windows PCのCodex工程1について、[作業ブランチのレビュー入口](https://github.com/shirai-masatomo/whitespace/blob/dot/dive-in-under/phase-01/projects/dive-in-under/review/current/README.md)に検証ログがあり、Windows CIが成功したことを確認済み。ただし**工程1の反復探索・倉庫・保存・10F攻略は未完成**。
- 主工程や機能追加の指示ではなく**画風とUI構成の更新**。既存の工程1完了条件（主人公1人で反復探索して10F攻略可能）は変わらない。
