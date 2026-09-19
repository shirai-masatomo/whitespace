# WhiteSpace — PROJECT STATE

更新: 2026-09-19

## 全体

- 基盤方針: [docs/FOUNDATION.md](docs/FOUNDATION.md)
- 先の見通し: [先の心配ごとマップ](docs/roadmap/release-roadmap.md)
- 現在はゲーム制作に集中し、広告・集客は公開準備で検討する。

## 現在のプロジェクト

### DIVE DIVE

- 状態: **リアル層450mの改善版 / HUMAN_REVIEW**
- 目的: WhiteSpace名義で最初の正式リリース作品を完成させる。
- 開発モデル: [Codex自律駆動](projects/001-first-release/AUTONOMY.md)。
- ゲーム案: ユーザーがDIVE DIVEを選定。自然沈降・足場・酸素補給・泡での再挑戦を核にする。
- 人間レビューを受領し4サイクル改善。実プレイヤーの全方向衝突、岸壁歩行/沖側の選択、酸素藻と魚群/エイ、450mの裂け目を追加。Forward+/GLの実GPU試走成功。次は探索・酸素・再挑戦欲の感覚を確認する。
- 詳細: [起動方法](projects/001-first-release/README.md) / [現在地](projects/001-first-release/PROJECT_STATE.md)

### 言語ジェンガ（仮）

- これまでのWhiteSpace本体、宥めよ、会話/intent辞書、言語ゲーム構想を引き継ぐ。
- 固有文書は `projects/language-jenga/docs/`、既存Vite + React実装は `projects/language-jenga/app/nadameyo/` に集約済み。
- mainの実装はルールベースの会話ゲーム。別ブランチのコーヒー会話実験は未統合。
- 詳細: [現在地](projects/language-jenga/PROJECT_STATE.md) / [起動と構成](projects/language-jenga/README.md)

## 次

1. DIVE DIVE改善版はCI成功。探索・酸素・再挑戦欲を次の人間試遊で確認。
2. 試遊指摘を自律修正し、保存/設定を含むオフラインRelease Buildへ進める。
3. 言語ジェンガ側は既存資産を保持し、必要になった時だけ再開する。
