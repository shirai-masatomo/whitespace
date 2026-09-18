# WhiteSpace

WhiteSpaceは、**ゲーム・小説・映像・ARG・仮想現実・Webなど、媒体を限定せず作品や実験を継続的に制作・公開するための制作母体**として扱う。

先に媒体を決めず、観念・感情・体験の核に合う形式を選ぶ。制作途中で媒体が変容したり、複数の形式が混ざることも許容する。将来的にはWhiteSpace名義から複数作品を出すことを想定する。成人向け等でブランド分離が必要になった場合は、BlackSpace（仮）など別ブランドを検討する。

## プロジェクト

- [001 First Release](projects/001-first-release/README.md)  
  WhiteSpace名義で最初の正式リリースを目指す新規プロジェクト。Codex自律駆動モデルを採用。現在はゲーム案選定前。

- [言語ジェンガ（仮）](projects/language-jenga/README.md)  
  これまでWhiteSpaceで進めてきた「宥めよ」、会話ゲーム、intent辞書、言語/関係性の実験を引き継ぐ既存プロジェクト。

全体一覧: [projects/README.md](projects/README.md)

## クリエイティブ・ノウハウ

[Creative Methods](docs/creative/CREATIVE_METHODS.md)  
制作時に立ち返るための、媒体横断の短いノウハウ集。AI活用、発想、試作、批評など再利用できる方法をここへ蓄積する。

## リリースまでの見通し

[先の心配ごとマップ（画像・元テキスト）](docs/roadmap/release-roadmap.md)

今は「ゲーム制作」に集中。広告・集客は「公開準備」で考え始めればOK。将来の心配事や追加工程は、この短いマップへ整理する。

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
