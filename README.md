# WhiteSpace

WhiteSpaceは、**複数のゲームや実験作品を継続的に制作・公開するための制作母体**として扱う。

将来的にはWhiteSpace名義から複数タイトルを出すことを想定する。成人向け等でブランド分離が必要になった場合は、BlackSpace（仮）など別ブランドを検討する。

## プロジェクト

- [001 First Release](projects/001-first-release/README.md)  
  WhiteSpace名義で最初の正式リリースを目指す新規プロジェクト。Codex自律駆動モデルを採用。現在はゲーム案選定前。

- [言語ジェンガ（仮）](projects/language-jenga/README.md)  
  これまでWhiteSpaceで進めてきた「宥めよ」、会話ゲーム、intent辞書、言語/関係性の実験を引き継ぐ既存プロジェクト。

全体一覧: [projects/README.md](projects/README.md)

## リリースまでの見通し

[リリースロードマップ（画像・元テキスト）](docs/roadmap/release-roadmap.md)

今は「ゲーム制作」に集中。広告・集客は「公開準備」で考え始めればOK。将来の心配事や追加工程は、この短いロードマップへ整理する。

## 現在の構造

```text
WhiteSpace/
├── README.md
├── PROJECT_STATE.md         # WhiteSpace全体の現在地
├── docs/roadmap/            # 全作品共通のリリース見通し（画像・元テキスト）
└── projects/
    ├── README.md           # 作品一覧
    ├── 001-first-release/  # 最初の正式リリース候補
    └── language-jenga/
        ├── README.md
        ├── PROJECT_STATE.md
        ├── docs/           # 仕様・TODO・辞書レビュー・コマンド履歴
        └── app/nadameyo/   # 既存Vite + Reactアプリ
```

## リポジトリ方針

当面は1つの `whitespace` repo内で複数作品を管理する。

ただし、各ゲームが本制作・公開・保守フェーズへ進み、依存関係やCI、権限、ブランドを独立させた方がよくなった場合は、そのゲームだけ別repoへ切り出す。

## 文書とコードの置き場所

ルートには全体の案内・現在地・共通設定だけを置く。各ゲームの仕様、タスク、実装、依存関係は対応するプロジェクト内で管理する。

宥めよ・会話ゲーム・intent辞書の既存資産は [言語ジェンガ](projects/language-jenga/README.md) に集約済み。起動・検証コマンドは [宥めよのREADME](projects/language-jenga/app/nadameyo/README.md) を参照する。

## GitHub

- Repository: https://github.com/shirai-masatomo/whitespace
- Main branch: `main`
