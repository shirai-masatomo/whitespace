# WhiteSpace

WhiteSpaceは、**ゲーム・小説・映像・ARG・仮想現実・Webなど、媒体を限定せず作品や実験を継続的に制作・公開するための制作母体**。

全体の目的、プロジェクトの分け方、AI/Codexの自律度、文書方針は [WhiteSpace 基盤方針](docs/FOUNDATION.md) を正本とする。

## プロジェクト

- [DIVE DIVE](projects/001-first-release/README.md)
  深い海底へ潜る3D高難易度アクション。Codex自律駆動でWindows向け300m試作を開発中。

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
├── docs/FOUNDATION.md       # WhiteSpace全体の基盤方針
├── docs/creative/           # 媒体横断の創作ノウハウ
├── docs/roadmap/            # 全作品共通のリリース見通し（画像・元テキスト）
└── projects/
    ├── README.md           # 作品一覧
    ├── 001-first-release/  # DIVE DIVE
    └── language-jenga/
        ├── README.md
        ├── PROJECT_STATE.md
        ├── docs/           # 仕様・TODO・辞書レビュー・コマンド履歴
        └── app/nadameyo/   # 既存Vite + Reactアプリ
```

## 文書とコードの置き場所

ルートには全体の入口と現在地だけを置く。共通方針は基盤文書、各作品の仕様・タスク・実装は対応するプロジェクト内で管理する。

宥めよ・会話ゲーム・intent辞書の既存資産は [言語ジェンガ](projects/language-jenga/README.md) に集約済み。起動・検証コマンドは [宥めよのREADME](projects/language-jenga/app/nadameyo/README.md) を参照する。

## GitHub

- Repository: https://github.com/shirai-masatomo/whitespace
- Main branch: `main`
