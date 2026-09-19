# WhiteSpace — PROJECT STATE

更新: 2026-09-19

## 全体

- 基盤方針: [docs/FOUNDATION.md](docs/FOUNDATION.md)
- 先の見通し: [先の心配ごとマップ](docs/roadmap/release-roadmap.md)
- 現在はゲーム制作に集中し、広告・集客は公開準備で検討する。

## 現在のプロジェクト

### DIVE DIVE

- 状態: **リアル層Vertical Slice制作中 / SELF_CONTINUE**
- 目的: WhiteSpace名義で最初の正式リリース作品を完成させる。
- 開発モデル: [Codex自律駆動](projects/001-first-release/AUTONOMY.md)。
- ゲーム案: ユーザーがDIVE DIVEを選定。自然沈降・足場・酸素補給・泡での再挑戦を核にする。
- 300m試作に海上からの入水、Space浮上、E急降下の酸素コスト、瞬時補給、動く足場と深度別景観を追加。中核レビュー待ちは解除。Forward+、自然足場、関節付き主人公、潮流/泡を自律改善中。可逆な実装ごとの承認は不要。
- 詳細: [起動方法](projects/001-first-release/README.md) / [現在地](projects/001-first-release/PROJECT_STATE.md)

### 言語ジェンガ（仮）

- これまでのWhiteSpace本体、宥めよ、会話/intent辞書、言語ゲーム構想を引き継ぐ。
- 固有文書は `projects/language-jenga/docs/`、既存Vite + React実装は `projects/language-jenga/app/nadameyo/` に集約済み。
- mainの実装はルールベースの会話ゲーム。別ブランチのコーヒー会話実験は未統合。
- 詳細: [現在地](projects/language-jenga/PROJECT_STATE.md) / [起動と構成](projects/language-jenga/README.md)

## 次

1. DIVE DIVEの通常視点の目標認識をAI側で改善する。
2. 浅海の素材/水面/主人公を磨き、リアル層の製品品質ゲートに達した時だけ人間レビューへ進む。
3. 言語ジェンガ側は既存資産を保持し、必要になった時だけ再開する。
