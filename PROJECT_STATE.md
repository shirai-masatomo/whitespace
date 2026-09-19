# WhiteSpace — PROJECT STATE

更新: 2026-09-19

## 全体

- 基盤方針: [docs/FOUNDATION.md](docs/FOUNDATION.md)
- 先の見通し: [先の心配ごとマップ](docs/roadmap/release-roadmap.md)
- 現在はゲーム制作に集中し、広告・集客は公開準備で検討する。

## 現在のプロジェクト

### DIVE DIVE

- 状態: **Phase 1 / 中核を自律改善3サイクル・プレイ感レビュー**
- 目的: WhiteSpace名義で最初の正式リリース作品を完成させる。
- 開発モデル: [Codex自律駆動](projects/001-first-release/AUTONOMY.md)。
- ゲーム案: ユーザーがDIVE DIVEを選定。自然沈降・足場・酸素補給・泡での再挑戦を核にする。
- 300m試作に補給分岐・俯瞰・経路測定を追加。ゲームの核の好みだけを人間が評価する段階。可逆な実装ごとの承認は不要。
- 詳細: [起動方法](projects/001-first-release/README.md) / [現在地](projects/001-first-release/PROJECT_STATE.md)

### 言語ジェンガ（仮）

- これまでのWhiteSpace本体、宥めよ、会話/intent辞書、言語ゲーム構想を引き継ぐ。
- 固有文書は `projects/language-jenga/docs/`、既存Vite + React実装は `projects/language-jenga/app/nadameyo/` に集約済み。
- mainの実装はルールベースの会話ゲーム。別ブランチのコーヒー会話実験は未統合。
- 詳細: [現在地](projects/language-jenga/PROJECT_STATE.md) / [起動と構成](projects/language-jenga/README.md)

## 次

1. DIVE DIVEのWindows試作を人間がプレイし、着地・酸素の忙しさ・深度損失を評価する。
2. レビュー後、Codexが着地/カメラ・酸素/損失・経路の選択肢を順に改善する。
3. 言語ジェンガ側は既存資産を保持し、必要になった時だけ再開する。
