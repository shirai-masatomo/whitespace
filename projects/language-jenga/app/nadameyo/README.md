# 宥めよ

「宥めよ」は、限られた発言回数の中で相手に一文ずつ言葉を送り、信頼を得ることを目指すテキスト会話ゲームです。言葉を選び間違えると緊張度が上がるため、「話さなければ進まないが、発言にはリスクがある」という体験を小さく試作しています。

言語ジェンガ（仮）内の既存プロトタイプです。

## 起動方法

事前にNode.jsをインストールしておきます。初回だけ依存パッケージをインストールしてください。

```powershell
cd C:\Users\masat\Documents\codex_test\projects\language-jenga\app\nadameyo
npm.cmd install
```

開発サーバーを起動します。

```powershell
npm.cmd run dev -- --host 127.0.0.1 --port 5181 --strictPort
```

起動後、ブラウザで `http://127.0.0.1:5181/` を開きます。

別セッションと重ならないよう専用ポートを指定しています。使用中なら別の空きポートを指定し、他セッションのプロセスを停止しないでください。

Codex内でPATHが不安定な場合は、Node.jsの場所をこのシェルのPATHへ追加します。

```powershell
$env:Path = 'C:\Program Files\nodejs;' + $env:Path
npm.cmd run dev -- --host 127.0.0.1 --port 5181 --strictPort
```

## 確認用コマンド

```powershell
npm.cmd run review:intents
npm.cmd run test
npm.cmd run lint
npm.cmd run build
```

- `review:intents`: 辞書から本プロジェクトの `docs/INTENT_DICTIONARY_REVIEW.md` を再生成
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

intent辞書には144件の候補があります。既存20件だけが `status: adopted` として有効で、新規124件は `status: review` のままです。レビュー待ち候補は自動的にゲームへ採用されません。

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

プロジェクト全体の現在地は [`../../PROJECT_STATE.md`](../../PROJECT_STATE.md)、次の作業は [`../../docs/TODO.md`](../../docs/TODO.md) を参照してください。
