# WhiteSpace — PROJECT STATE

更新: 2026-10-02

## 全体

- 基盤方針: [docs/FOUNDATION.md](docs/FOUNDATION.md)
- 先の見通し: [先の心配ごとマップ](docs/roadmap/release-roadmap.md)
- 現在はゲーム制作に集中し、広告・集客は公開準備で検討する。

## 現在のプロジェクト

### ホイッスル牧場（仮）

- 旧「胞庭」を人間の新方針で更新。柴犬を育て、笛・餌・門で防衛するGodot製Windows試作。DIVE DIVEのコード・タスクとは分離。
- Stage 1→EXP・Gold・購入→Stage 2へ引継ぎ。鶏の産卵・盗難・卵の売却/餌交換まで動作。現在は侵入中の間接操作を試す段階。定期再開は設定しない。
- 詳細: [起動方法](projects/sporehollow/README.md) / [現在地](projects/sporehollow/PROJECT_STATE.md) / [次の仮説](projects/sporehollow/TASKS.md)

### DIVE DIVE

- 管理: L=層 / P=層内フェーズ / G=層間ゲート。[構成の正本](projects/001-first-release/HUMAN_DIRECTION.md)。
- 状態: **2D主開発・3D開発STOPPED**。L1〜L6とエンディングまで約1,960mの圧縮試作 / 品質CHANGES / 定期自律開発PAUSED。
- 現在はL1の完成度とL2の導入が対象。L2-G/L3以降は構想のみ。目安深度を固定仕様にしない。
- 対象フェーズへ集中し、通常は軽量検証。画像は確認依頼時のみ2〜4枚、旧画像はGit履歴。
- 詳細: [起動方法](projects/001-first-release/README.md) / [現在地](projects/001-first-release/PROJECT_STATE.md) / [次の作業](projects/001-first-release/TASKS.md)

### 言語ジェンガ（仮）

- これまでのWhiteSpace本体、宥めよ、会話/intent辞書、言語ゲーム構想を引き継ぐ。
- 固有文書は `projects/language-jenga/docs/`、既存Vite + React実装は `projects/language-jenga/app/nadameyo/` に集約済み。
- mainの実装はルールベースの会話ゲーム。別ブランチのコーヒー会話実験は未統合。
- 詳細: [現在地](projects/language-jenga/PROJECT_STATE.md) / [起動と構成](projects/language-jenga/README.md)

## 次

1. DIVE DIVEはユーザー指定のL/P/Gへ集中。3Dは再開せず、2Dの探索・採掘する動機と区間の印象を磨く。
2. 保存/設定とSteamは場所の試作後。定期自律再開は保留。
3. 言語ジェンガ側は既存資産を保持し、必要になった時だけ再開する。
