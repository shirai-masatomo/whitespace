# WhiteSpace

WhiteSpaceは、**複数のゲームや実験作品を継続的に制作・公開するための制作母体**として扱う。

将来的にはWhiteSpace名義から複数タイトルを出すことを想定する。成人向け等でブランド分離が必要になった場合は、BlackSpace（仮）など別ブランドを検討する。

## プロジェクト

- [001 First Release](projects/001-first-release/README.md)  
  WhiteSpace名義で最初の正式リリースを目指す新規プロジェクト。Codex自律駆動モデルを採用。現在はゲーム案選定前。

- [言語ジェンガ（仮）](projects/language-jenga/README.md)  
  これまでWhiteSpaceで進めてきた「宥めよ」、会話ゲーム、intent辞書、言語/関係性の実験を引き継ぐ既存プロジェクト。

全体一覧: [projects/README.md](projects/README.md)

## 現在の構造

```text
WhiteSpace/
├── projects/
│   ├── 001-first-release/   # 最初の正式リリース候補
│   └── language-jenga/      # 既存WhiteSpace/宥めよ系
├── prototypes/
│   └── 001-nadameyo/        # 言語ジェンガ側の既存実装
├── docs/                    # 既存履歴・辞書資料（言語ジェンガ側）
└── PROJECT_STATE.md         # WhiteSpace全体の現在地
```

## リポジトリ方針

当面は1つの `whitespace` repo内で複数作品を管理する。

ただし、各ゲームが本制作・公開・保守フェーズへ進み、依存関係やCI、権限、ブランドを独立させた方がよくなった場合は、そのゲームだけ別repoへ切り出す。

## 既存ドキュメントについて

ルートの `SPEC.md`、`ACCEPTANCE.md`、`TODO.md`、`docs/INTENT_DICTIONARY_REVIEW.md`、既存の `docs/COMMAND_LOG.md`、`prototypes/001-nadameyo/` は、**言語ジェンガ（仮）プロジェクトの既存資産**として扱う。

現時点ではリンクや起動環境を壊さないため物理移動は行っていない。

## GitHub

- Repository: https://github.com/shirai-masatomo/whitespace
- Main branch: `main`
