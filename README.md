# WhiteSpace

人物・環境・主人公・関係によって、同じ言葉の受け取られ方が変わることを試すプロジェクトです。現在の形に固定せず、小さな試作と検証を重ねます。

## 読む入口

- [設計思想](docs/DESIGN_PHILOSOPHY.md)：何を目指し、どう考えてきたか。
- [現在地と次の作業](docs/STATUS.md)：できること、確認済みの範囲、残る課題。
- [コーヒー場面の分岐図](docs/COFFEE_FLOW.md)：選択→反応→次の分岐を見比べて議論する。

## 起動する

このリポジトリのルートから実行します。Node.js 24.16.0 / npm 11.13.0で確認済みです。

```powershell
cd prototypes/001-nadameyo
npm.cmd ci
npm.cmd run dev -- --host 127.0.0.1 --port 5174 --strictPort
```

[アプリを開く](http://127.0.0.1:5174/#coffee)。停止はCtrl+C。ポートが使用中なら、別ポートを明示してください。PowerShellの実行制限がある環境ではnpm.cmdを使います。同じフォルダの `./start-dev.ps1 -Port 5174` でも起動できます。

- **場面実験**：立場を選び、コーヒーをこぼした相手へ関わる。モデルなしでも選択肢で遊べます。
- **宥めよ**：5回の言葉で相手の信頼を得る、辞書方式の会話ゲーム。
- **言語比較ラボ**：同じ入力を辞書とローカルモデルで比較。モデル停止時も辞書は使えます。

## 必要なときだけ

[将来のアイディア](docs/FUTURE_IDEAS.md)：言語ジェンガ、悩みから場面を作る案。次の方向を考えるときに。

[開発・検証の手順](docs/DEVELOPMENT.md) ／ [ローカルモデルの起動・実測](docs/LOCAL_MODEL.md) ／ [辞書の採否・出典・利用条件](docs/INTENT_DICTIONARY_REVIEW.md)。エージェント向けの作業規約は [AGENTS.md](AGENTS.md)です。
