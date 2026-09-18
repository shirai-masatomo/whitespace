# WhiteSpace — PROJECT STATE

更新: 2026-09-18

## WhiteSpaceの位置づけ

WhiteSpaceは単一ゲームではなく、複数のゲーム・実験作品を生み出す制作母体として扱う。

将来的にWhiteSpace名義で複数ゲームを公開する。成人向け等で区分が必要になればBlackSpace（仮）など別ブランドを検討する。

## 現在のプロジェクト

### 001 First Release

- 状態: **Phase 0 / 企画準備**
- 目的: WhiteSpace名義で最初の正式リリース作品を完成させる。
- 開発モデル: `other task` で試したCodex自律駆動モデル。
- ゲーム案: 未決定。
- 候補: わらしべ長者 / 水中高難易度アクション / 今後追加する案。
- 詳細: `projects/001-first-release/`

### 言語ジェンガ（仮）

- これまでのWhiteSpace本体、宥めよ、会話/intent辞書、言語ゲーム構想を引き継ぐ。
- 既存のルート文書・`docs/`・`prototypes/001-nadameyo/` はこのプロジェクト所属として扱う。
- 現時点では大量移動をせず、リンクと実行環境を維持する。
- 詳細: `projects/language-jenga/`

## リポジトリ方針

当面はモノレポ。

```text
WhiteSpace
├─ 001 First Release
├─ 言語ジェンガ（仮）
└─ 将来のゲーム...
```

ゲームが大きくなり、独自CI/依存/公開保守/権限分離が必要になった時点で別repoへの切り出しを検討する。

## 次

1. `projects/001-first-release/IDEAS.md` の候補を増やす。
2. 候補を比較し、最初に本制作するゲームを人間が決める。
3. 決定後、Codexが最小プロトタイプから自律的に進行する。
4. 言語ジェンガ側は既存資産を保持し、必要になった時だけ再開する。
