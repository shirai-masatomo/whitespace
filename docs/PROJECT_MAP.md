# WhiteSpace プロジェクトマップ

このファイルは、WhiteSpaceを初めて開いたときに「どこに何があるか」を理解するための案内図です。

## 全体像

```text
WhiteSpace
├── 開発基盤
│   ├── Git / GitHub          変更履歴と共有
│   ├── Node.js / npm         開発ツールの実行
│   └── Vite + React          ブラウザで動く画面の開発
│
├── prototypes               小さな実験アプリを置く場所
│   └── 001-nadameyo         現在のアクティブなプロトタイプ「宥めよ」
│       ├── React画面         src/App.jsx
│       ├── intent判定       src/lib/intentMatcher.js
│       ├── intent辞書       src/data/intent-dictionary.json
│       ├── テスト           test/intentMatcher.test.js
│       └── アプリ管理       APP_STATE.md / README.md
│
└── 管理ドキュメント
    ├── PROJECT_STATE.md
    ├── SPEC.md
    ├── ACCEPTANCE.md
    ├── TODO.md
    └── docs/
        ├── PROJECT_MAP.md
        ├── COMMAND_LOG.md
        └── INTENT_DICTIONARY_REVIEW.md
```

## 「宥めよ」の処理の流れ

```text
プレイヤーが一文を入力
        ↓
React画面（src/App.jsx）
        ↓
入力を正規化・intent判定（src/lib/intentMatcher.js）
        ↓
採用済み表現を参照（src/data/intent-dictionary.json）
        ↓
緊張度・信頼度・残り発言数・相手の返答を更新
        ↓
自動テスト（test/intentMatcher.test.js）で既存挙動を確認
```

## 各管理ドキュメントの役割

| ドキュメント | 役割 |
| --- | --- |
| [`PROJECT_STATE.md`](../PROJECT_STATE.md) | リポジトリ全体の現在地、成功したこと、問題、次の作業を記録する。 |
| [`SPEC.md`](../SPEC.md) | WhiteSpaceと現在のプロトタイプで「何を作るか」を定義する。 |
| [`ACCEPTANCE.md`](../ACCEPTANCE.md) | 各作業を「完了」と判断するための条件を定義する。 |
| [`TODO.md`](../TODO.md) | 次に実行する作業、判断待ち、完了済み作業を管理する。 |
| [`APP_STATE.md`](../prototypes/001-nadameyo/APP_STATE.md) | 「宥めよ」固有の状態、状態遷移、仕様、変更履歴を記録する。 |
| [`COMMAND_LOG.md`](COMMAND_LOG.md) | 重要なコマンドを、日時・目的・結果と一緒に記録する。 |
| [`INTENT_DICTIONARY_REVIEW.md`](INTENT_DICTIONARY_REVIEW.md) | 収集したintent表現候補を、人が採用・保留・除外するために確認する。 |

## 迷ったときに読む順番

1. この `PROJECT_MAP.md` で全体構成を確認する。
2. `PROJECT_STATE.md` で現在地を確認する。
3. `TODO.md` で次の小さな作業を確認する。
4. 実装前に `SPEC.md` と `ACCEPTANCE.md` を確認する。
5. 「宥めよ」を変更するときは `APP_STATE.md` も確認する。
