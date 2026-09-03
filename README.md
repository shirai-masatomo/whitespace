# WhiteSpace

WhiteSpaceは、小さなプロトタイプを作りながら、将来的にPC向けゲーム、ARG、その他の実験的・革新的なサービスへ発展させるための基盤プロジェクトです。

完成を急ぐだけでなく、アイデアを小さく試し、仕組みと制作過程を記録しながら育てることを重視しています。

## 現在の状態

現在のアクティブなプロトタイプは、会話ゲーム「宥めよ」です。

- 場所: [`prototypes/001-nadameyo`](prototypes/001-nadameyo/README.md)
- 技術: Vite + React
- 内容: プレイヤーが一文ずつ入力し、相手の信頼度と緊張度を変化させるテキスト会話ゲーム
- 入力判定: ローカルのルールベースintent辞書
- 辞書候補: 144件のうち既存20件が有効、124件が人によるレビュー待ち
- テスト: Node.js標準テスト、ESLint、Vite production build

## 最初に読むもの

1. [`docs/PROJECT_MAP.md`](docs/PROJECT_MAP.md): プロジェクト全体の案内図
2. [`PROJECT_STATE.md`](PROJECT_STATE.md): 現在どこまで進んでいるか
3. [`TODO.md`](TODO.md): 次に何をするか
4. [`SPEC.md`](SPEC.md): 何を作るか、現在の仕様
5. [`ACCEPTANCE.md`](ACCEPTANCE.md): 何を満たせば完了か

## プロジェクト構成

```text
WhiteSpace/
├── prototypes/
│   └── 001-nadameyo/        # 現在のアクティブなReactプロトタイプ
├── docs/
│   ├── PROJECT_MAP.md        # 全体の案内図
│   ├── COMMAND_LOG.md        # 重要コマンドの実行履歴
│   └── INTENT_DICTIONARY_REVIEW.md
├── PROJECT_STATE.md          # リポジトリ全体の現在地
├── SPEC.md                   # 仕様
├── ACCEPTANCE.md             # 完了条件
└── TODO.md                   # 次の作業
```

詳しい構造は [`docs/PROJECT_MAP.md`](docs/PROJECT_MAP.md) を参照してください。

## 「宥めよ」の起動

```powershell
cd C:\Users\masat\Documents\codex_test\prototypes\001-nadameyo
npm.cmd install
npm.cmd run dev -- --host 127.0.0.1
```

起動後、表示されたURLをブラウザで開きます。現在の標準URLは `http://127.0.0.1:5173/` です。

このPCのPowerShellでは `npm` がExecution Policyで止まる場合があるため、`npm.cmd` を使用します。Codex内でPATHが不安定な場合は `C:\Program Files\nodejs\npm.cmd` を直接指定します。

## ルート直下の旧ファイルについて

ルートの `index.html`、`app.js`、`style.css` は、Vite導入前に作った初期のブラウザ版です。現在のアクティブなアプリではありません。残すか整理するかは `TODO.md` の判断待ち項目です。

## GitHub

- Repository: https://github.com/shirai-masatomo/whitespace
- Main branch: `main`
