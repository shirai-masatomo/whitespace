# WhiteSpace — PROJECT STATE

更新: 2026-09-18

## 全体

- 基盤方針: [docs/FOUNDATION.md](docs/FOUNDATION.md)
- 先の見通し: [先の心配ごとマップ](docs/roadmap/release-roadmap.md)
- 現在はゲーム制作に集中し、広告・集客は公開準備で検討する。

## 現在のプロジェクト

### 001 First Release

- 状態: **Phase 0 / 企画準備**
- 目的: WhiteSpace名義で最初の正式リリース作品を完成させる。
- 開発モデル: [Codex自律駆動](projects/001-first-release/AUTONOMY.md)。
- ゲーム案: 未決定。
- 候補: わらしべ長者 / 水中高難易度アクション / 今後追加する案。
- 詳細: `projects/001-first-release/`

### 言語ジェンガ（仮）

- これまでのWhiteSpace本体、宥めよ、会話/intent辞書、言語ゲーム構想を引き継ぐ。
- 固有文書は `projects/language-jenga/docs/`、既存Vite + React実装は `projects/language-jenga/app/nadameyo/` に集約済み。
- mainの実装はルールベースの会話ゲーム。別ブランチのコーヒー会話実験は未統合。
- 詳細: [現在地](projects/language-jenga/PROJECT_STATE.md) / [起動と構成](projects/language-jenga/README.md)

## 次

1. `projects/001-first-release/IDEAS.md` の候補を増やす。
2. 候補を比較し、最初に本制作するゲームを人間が決める。
3. 決定後、Codexが最小プロトタイプから自律的に進行する。
4. 言語ジェンガ側は既存資産を保持し、必要になった時だけ再開する。
