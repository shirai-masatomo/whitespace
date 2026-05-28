# Codex Test React App

`C:\Users\masat\Documents\codex_test` に作った、最小構成の React テストアプリです。

## 今の構成

- `index.html`: エントリーポイント
- `app.js`: React コンポーネント本体
- `style.css`: 画面の見た目

## 動かし方

1. `index.html` をブラウザで開く
2. 画面が表示されたら、入力欄にタスクを入れて `追加` を押す
3. チェックボックスで完了状態を切り替える

## 補足

このPCでは `Node.js` と `npm` が未導入だったため、まずは依存インストールなしで動く React 構成にしています。

将来的に `Vite` ベースへ移行するときは、次の流れが自然です。

1. `Node.js` をインストールする
2. `npm create vite@latest`
3. 今の `app.js` のロジックを `src/App.jsx` へ移す
4. CSS を `src/index.css` などへ移す
