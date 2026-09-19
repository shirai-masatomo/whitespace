# WhiteSpace — PROJECT STATE

更新: 2026-09-19

## 全体

- 基盤方針: [docs/FOUNDATION.md](docs/FOUNDATION.md)
- 先の見通し: [先の心配ごとマップ](docs/roadmap/release-roadmap.md)
- 現在はゲーム制作に集中し、広告・集客は公開準備で検討する。

## 現在のプロジェクト

### DIVE DIVE

- 状態: **Phase 1 / 中核プロトタイプ**
- 目的: WhiteSpace名義で最初の正式リリース作品を完成させる。
- 開発モデル: [Codex自律駆動](projects/001-first-release/AUTONOMY.md)。
- ゲーム案: ユーザーがDIVE DIVEを選定。深度/圧力/シームレスな強制浮上を核にする。
- Windows向け300m試作を実装。ゲームの核を人間が触って評価する段階へ進める。
- 詳細: [起動方法](projects/001-first-release/README.md) / [現在地](projects/001-first-release/PROJECT_STATE.md)

### 言語ジェンガ（仮）

- これまでのWhiteSpace本体、宥めよ、会話/intent辞書、言語ゲーム構想を引き継ぐ。
- 固有文書は `projects/language-jenga/docs/`、既存Vite + React実装は `projects/language-jenga/app/nadameyo/` に集約済み。
- mainの実装はルールベースの会話ゲーム。別ブランチのコーヒー会話実験は未統合。
- 詳細: [現在地](projects/language-jenga/PROJECT_STATE.md) / [起動と構成](projects/language-jenga/README.md)

## 次

1. DIVE DIVEのWindows試作を人間がプレイし、圧力・待ち時間・深度損失を評価する。
2. レビュー後、Codexが数値調整・地形試作・配布品質を順に改善する。
3. 言語ジェンガ側は既存資産を保持し、必要になった時だけ再開する。
