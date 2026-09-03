# プロジェクト状態（PROJECT STATE）

最終更新: 2026-09-03

このファイルは、WhiteSpaceリポジトリ全体の「現在どこまで進んでいるか」を短時間で確認するための記録である。詳しい構成は [`docs/PROJECT_MAP.md`](docs/PROJECT_MAP.md) を参照する。

## 1. 現在地

- WhiteSpaceは、将来のPC向けゲーム、ARG、実験的・革新的サービスを小さな試作から育てる基盤プロジェクトである。
- 現在のアクティブなプロトタイプは `prototypes/001-nadameyo` の会話ゲーム「宥めよ」。
- 「宥めよ」はVite + Reactで動作し、ローカルのルールベースintent判定を使う。
- intent辞書には144件の候補があり、既存20件が `adopted`、新規124件が `review`。
- 現在のマイルストーンは、レビュー待ち124件を人が確認し、採用・保留・除外を判断すること。
- リポジトリはGitHubの `https://github.com/shirai-masatomo/whitespace` と同期している。

## 2. 完了していること

- Node.js LTSとnpmを導入し、Vite + Reactプロジェクトを作成した。
- 緊張度、信頼度、残り発言数、会話履歴、成功・失敗、再挑戦を実装した。
- 入力の正規化と、`apology`、`listening`、`reassurance`、`command`、`rejection`、`hostile`、`unknown` の判定を実装した。
- intent辞書を `App.jsx` から外部JSONへ切り出した。
- 辞書候補を自動採用せず、人がレビューできる仕組みにした。
- Node.js標準テスト、ESLint、Vite production buildを実行できるようにした。
- ブラウザで成功、緊張度による失敗、発言数による失敗、再挑戦を確認した。
- プロジェクト管理文書とREADMEを日本語で整理し、`docs/PROJECT_MAP.md` を追加した。

## 3. 現在の技術構成

| 項目 | 現在の状態 |
| --- | --- |
| Node.js | `v24.16.0` |
| npm | `11.13.0`。PowerShellでは `npm.cmd` を使用する |
| フロントエンド | React `19.2.6` |
| 開発・build | Vite `8.0.14` |
| 状態管理 | React `useState` |
| 入力判定 | `normalizeInput` とローカルintent辞書 |
| 自動テスト | Node.js標準テストランナー |
| バージョン管理 | Git / GitHub、`main` ブランチ |

## 4. 直近の確認結果

- `npm.cmd run test`: 自動テスト6件成功。
- `npm.cmd run lint`: 成功。
- `npm.cmd run build`: 成功。
- `http://127.0.0.1:5173/`: ブラウザ上で主要なゲーム遷移を確認済み。
- Markdownのローカルリンク: リンク切れなし。
- 今回の文書整理: Markdownのみ変更し、ゲームコードと挙動は未変更。

## 5. 既知の問題と注意点

- Windows PowerShellでは `npm` がExecution Policyで止まる場合があるため、`npm.cmd` を使う。
- Codex内ではNode.js/npmのPATHが通常のPowerShellと異なる場合があり、必要に応じて `C:\Program Files\nodejs\npm.cmd` を直接指定する。
- CodexからGitを更新するときは、`.git` の所有権とACLの影響で権限付き実行が必要になる場合がある。
- 現在のintent判定は部分一致のため、「大丈夫じゃない」が `大丈夫` に一致するなど、否定文を誤判定する可能性がある。
- 一文に複数intentがある場合は、辞書で先に定義されたintentを採用する。
- ルートの `index.html`、`app.js`、`style.css` はVite導入前の旧ブラウザ版で、現在は使用していない。削除するかは未決定。

## 6. 次にやること

1. `docs/INTENT_DICTIONARY_REVIEW.md` の `confidence: medium` / `low` 候補を確認する。
2. 複数intentにまたがる候補を、採用・保留・除外に分類する。
3. 採用する候補を少数ずつ `status: adopted` に変更する。
4. 各変更後に自動テスト、lint、build、ブラウザ確認を行う。
5. 辞書レビュー後に、ゲームバランス調整を別タスクとして検討する。

## 7. 今回整理したファイル

- `README.md`
- `SPEC.md`
- `ACCEPTANCE.md`
- `TODO.md`
- `PROJECT_STATE.md`
- `docs/PROJECT_MAP.md`
- `docs/COMMAND_LOG.md`
- `prototypes/001-nadameyo/README.md`

`prototypes/001-nadameyo/APP_STATE.md` と `docs/INTENT_DICTIONARY_REVIEW.md` は内容を確認したが、今回はアプリ仕様と辞書候補を変更していないため編集していない。

## 8. GPTに相談したいこと

- `empathy`、`accountability`、`offering_space` を独立intentにするか。
- 「大丈夫じゃない」のような否定文をどの段階で解析するか。
- 124件のレビュー候補を、どの順番と単位でゲームへ採用するか。
- ルート直下の旧ブラウザ版ファイルを残すか削除するか。
