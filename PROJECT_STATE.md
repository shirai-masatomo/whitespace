# WhiteSpace — PROJECT STATE

更新: 2026-09-20

## 全体

- 基盤方針: [docs/FOUNDATION.md](docs/FOUNDATION.md)
- 先の見通し: [先の心配ごとマップ](docs/roadmap/release-roadmap.md)
- 現在はゲーム制作に集中し、広告・集客は公開準備で検討する。

## 現在のプロジェクト

### DIVE DIVE

- 状態: **海をプレイグラウンドにする試作 / CHANGES・SELF_CONTINUE**
- 目的: WhiteSpace名義で最初の正式リリース作品を完成させる。
- 開発モデル: [Codex自律駆動](projects/001-first-release/AUTONOMY.md)。
- ゲーム案: ユーザーがDIVE DIVEを選定。自然沈降・足場・酸素補給・泡での再挑戦を核にする。
- 450m人間試遊「まだ面白くない」を受領。岩への移動反復から、巨大泡・曲がる潮流・岩の穴・未知の生物を比較する試作へ。人間待ちは解除、テスト完走を面白さと同一視しない。
- 最新コメント「まだ人間レビューする段階ではない」を反映。右の浅海に歩ける岩礁/ケルプ林/二口洞窟を試作し、屋根・内部・外側を比較。9/20の方針を取り込み、側面穴→泡上昇流→屋根の藻→上穴→洞内の周回へ。過密海藻と近接カメラ案を棄却し、入水/発見/深部の反復を継続改善中。
- 詳細: [起動方法](projects/001-first-release/README.md) / [現在地](projects/001-first-release/PROJECT_STATE.md)

### 言語ジェンガ（仮）

- これまでのWhiteSpace本体、宥めよ、会話/intent辞書、言語ゲーム構想を引き継ぐ。
- 固有文書は `projects/language-jenga/docs/`、既存Vite + React実装は `projects/language-jenga/app/nadameyo/` に集約済み。
- mainの実装はルールベースの会話ゲーム。別ブランチのコーヒー会話実験は未統合。
- 詳細: [現在地](projects/language-jenga/PROJECT_STATE.md) / [起動と構成](projects/language-jenga/README.md)

## 次

1. DIVE DIVEの探索/リスク/発見仮説を実操作・実画面で比較し、弱い案を捨てる。
2. 最初の数分の変化と自由な出口を改善。その後、保存/設定を含むオフラインRelease Buildへ。
3. 言語ジェンガ側は既存資産を保持し、必要になった時だけ再開する。
