# Project State

## 1. 今回やったこと

- `codex_test` に Vite + React プロジェクト `prototypes/001-nadameyo` を作成した。
- Node.js LTS を `winget` でインストールした。
- PowerShell では `npm` ではなく `npm.cmd` を使う必要があることを確認した。
- Codex 内では PATH が通常の Windows PowerShell と異なるため、Node.js/npm はフルパス指定で実行している。
- `prototypes/001-nadameyo` で依存パッケージをインストールした。
- GitHub push 前の安全確認を行い、`.npm-cache/` を `.gitignore` に追加した。

## 2. 成功したこと

- Windows PowerShell では `node -v` が `v24.16.0` で動作する。
- Windows PowerShell では `npm.cmd -v` が `11.13.0` で動作する。
- `create-vite` 本体を直接 `node` で起動して、Vite + React の雛形作成に成功した。
- `npm.cmd install` により `node_modules` と `package-lock.json` が作成された。
- npm audit 結果は `found 0 vulnerabilities`。
- `node_modules/` と `.npm-cache/` は Git 管理対象外にできた。

## 3. 失敗・エラー

- Codex 内で通常の `node` を実行すると、Codex アプリ内部の `node.exe` に当たり `Access is denied` になる。
- Codex 内で通常の `npm` は見つからない。
- `npm create vite@latest ...` は `cmd.exe /c create-vite ...` の段階で `Access is denied` になった。
- Windows PowerShell で `npm -v` を実行すると、`npm.ps1` が Execution Policy により拒否される。`npm.cmd -v` は成功する。
- push 前確認で `.npm-cache/` が未追跡として見えたため、`.gitignore` に追加して除外した。

## 4. 変更したファイル

- `PROJECT_STATE.md`
- `.gitignore`
- `README.md`
- `app.js`
- `index.html`
- `style.css`
- `.gitignore`
- `prototypes/001-nadameyo/package.json`
- `prototypes/001-nadameyo/package-lock.json`
- `prototypes/001-nadameyo/index.html`
- `prototypes/001-nadameyo/vite.config.js`
- `prototypes/001-nadameyo/eslint.config.js`
- `prototypes/001-nadameyo/README.md`
- `prototypes/001-nadameyo/src/main.jsx`
- `prototypes/001-nadameyo/src/App.jsx`
- `prototypes/001-nadameyo/src/App.css`
- `prototypes/001-nadameyo/src/index.css`
- `prototypes/001-nadameyo/public/vite.svg`
- `prototypes/001-nadameyo/src/assets/react.svg`

## 5. 次にやるべきこと

- `prototypes/001-nadameyo` で開発サーバーを起動し、初期 React 画面を確認する。
- `App.jsx` を少しずつ変更して、会話ゲーム「宥めよ」の最小プロトタイプにする。
- 既存ルート直下の手作り React ファイルを残すか整理するか決める。
- Git のユーザー名とメールアドレスを確認し、初回コミットする。
- GitHub に push する前に、ステージ対象の最終確認をする。

## 6. GPTに相談したいこと

- 「宥めよ」の最小プロトタイプで、最初に実装すべき状態とルールの設計。
- `緊張度`、`信頼度`、`残り発言数` のバランス調整。
- 固定テキスト判定から、将来的に LLM 連携へ拡張する設計。
- Codex 内 PATH が Windows PowerShell と違う問題の扱い方。
