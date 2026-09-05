# 宥めよ

「宥めよ」は、限られた発言回数の中で相手に一文ずつ言葉を送り、信頼を得ることを目指すテキスト会話ゲームです。言葉を選び間違えると緊張度が上がるため、「話さなければ進まないが、発言にはリスクがある」という体験を小さく試作しています。

WhiteSpaceプロジェクトの現在のアクティブなプロトタイプです。

## 起動方法

事前にNode.jsをインストールしておきます。初回だけ依存パッケージをインストールしてください。

```powershell
cd C:\Users\masat\Documents\codex_test\prototypes\001-nadameyo
npm.cmd install
```

開発サーバーを起動します。

```powershell
npm.cmd run dev -- --host 127.0.0.1
```

起動後、ブラウザで `http://127.0.0.1:5173/` を開きます。

Codex内でPATHが不安定な場合は、npmをフルパスで指定できます。

```powershell
& 'C:\Program Files\nodejs\npm.cmd' run dev -- --host 127.0.0.1
```

## 確認用コマンド

```powershell
npm.cmd run test
npm.cmd run lint
npm.cmd run build
```

- `test`: intent辞書と入力判定の自動テスト
- `lint`: JavaScriptとJSXの書き方を検査
- `build`: 配布可能なproduction buildを作成できるか検査

## 現在のゲーム仕様

- 初期状態は緊張度 `2 / 5`、信頼度 `0 / 4`、残り発言数 `5`。
- プレイヤーは一度に一文を入力する。
- 入力は `normalizeInput` で全角・半角、空白、句読点の一部を正規化する。
- `apology`、`listening`、`reassurance` は信頼度を上げる。
- `command`、`rejection`、`hostile` は緊張度を上げる。
- `unknown` は緊張度を少し上げる。
- 緊張度が `5` になると失敗、信頼度が `4` になると成功する。
- 発言数を使い切っても成功条件に達しなければ失敗する。
- 終了後は `もう一度` で再挑戦できる。

## intent辞書の状態

intent辞書には144件の候補があります。ユーザーの委任に基づくレビューで68件を追加採用し、有効88件、確認済み保留43件、除外13件、未レビュー0件になりました。`adopted` だけがルールに追加されます。

保留・除外は入力のブロックではなく、別の採用語を含めば引き続き一致します。採否理由と現在の判定は生成された一覧、検証状況と次タスクは [レビュー結果](../../docs/INTENT_REVIEW_OUTCOME.md) にあります。ブラウザの受け入れ確認はまだ完了していません。

候補一覧は [`../../docs/INTENT_DICTIONARY_REVIEW.md`](../../docs/INTENT_DICTIONARY_REVIEW.md) で確認できます。

## 主なファイル

| ファイル | 役割 |
| --- | --- |
| `src/App.jsx` | React画面とゲーム進行を管理する |
| `src/App.css` | 「宥めよ」画面の見た目を定義する |
| `src/lib/intentMatcher.js` | 入力の正規化とintent判定を行う |
| `src/data/intent-dictionary.json` | intent、状態変化、入力候補を保持する |
| `test/intentMatcher.test.js` | 辞書と判定処理を自動テストする |
| `scripts/generate-intent-review.mjs` | 辞書からレビュー用Markdownを生成する |
| `start-dev.ps1` | Codex環境から開発サーバーを起動しやすくする |

## 詳細な状態と変更履歴

ゲーム固有の仕様、管理している状態、状態遷移、intentの効果、変更履歴は [`APP_STATE.md`](APP_STATE.md) に記録しています。

プロジェクト全体の現在地は [`../../PROJECT_STATE.md`](../../PROJECT_STATE.md)、次の作業は [`../../TODO.md`](../../TODO.md) を参照してください。
