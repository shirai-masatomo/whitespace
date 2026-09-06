# WhiteSpace

自由な試作を重ね、PCゲーム、ARG、実験的サービスへ発展させるプロジェクト。スピード・柔軟性・拡張性を重視し、現在の形にも固定しません。

現在のアプリは会話ゲーム **宥めよ**。5回の言葉で相手の信頼を得ます。理解できない入力は数値を変えず聞き返し、言葉の反復や歩み寄りに応じて反応します。

同じアプリの **言語比較ラボ** で、辞書とローカルQwen3.5のカテゴリ・理由・時間を比較できます。モデル停止中も辞書は利用可能。[モデルの起動と実測](docs/LOCAL_MODEL.md) / [今回の確認結果](docs/PLAYTEST_2026-09-06.md)。

## はじめに

- [現在地](PROJECT_STATE.md) / [構成案内](docs/PROJECT_MAP.md)
- [制作方針](AGENTS.md) / [仕様](SPEC.md) / [完了条件](ACCEPTANCE.md) / [次の作業](TODO.md)
- [アプリの起動・構成](prototypes/001-nadameyo/README.md)
- [改善版の確認結果](docs/PLAYTEST_2026-09-05.md)

## ローカル起動

実際に開いているリポジトリのルートから実行します。元checkoutの絶対パスをコピーせず、このworktreeを使用してください。

```powershell
cd prototypes/001-nadameyo
npm.cmd ci
npm.cmd run dev -- --host 127.0.0.1 --port 5174 --strictPort
```

[ローカルの試作を開く](http://127.0.0.1:5174/)。Ctrl+Cでサーバーを停止します。Node.js 24環境で確認済み。PowerShellでnpm.ps1が制限される場合はnpm.cmdを使います。

## 辞書と旧版

144候補のうち88採用・43保留・13除外。全件の判断理由と出典は [辞書レビュー](docs/INTENT_DICTIONARY_REVIEW.md) に保持しています。ルートのindex.html/app.js/style.cssはVite導入前の旧版で、現行アプリでは使いません。

[GitHubリポジトリ](https://github.com/shirai-masatomo/whitespace)
