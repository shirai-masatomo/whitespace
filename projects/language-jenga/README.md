# 言語ジェンガ（仮）

WhiteSpaceで進めてきた「宥めよ」、会話ゲーム、intent辞書、言語・関係性の実験を扱うプロジェクト。
「正しい言葉を選ぶ」だけでなく、相手・状況・関係・履歴で同じ言葉の意味が変わるゲームを目指す。現在のmain実装は、ローカルのルールベースで動く小さな会話ゲーム「宥めよ」。

## 読む順番

1. [PROJECT_STATE.md](PROJECT_STATE.md): 現在地と未解決問題。
2. [TODO](docs/TODO.md): 次に行う小さな作業。
3. [SPEC](docs/SPEC.md) / [ACCEPTANCE](docs/ACCEPTANCE.md): 仕様と完了条件。
4. [APP_STATE](app/nadameyo/APP_STATE.md): 宥めよの状態遷移と実装履歴。

## 構成と起動

- [app/nadameyo](app/nadameyo/README.md): Vite + Reactアプリ。起動・install・test・lint・buildの手順もここに置く。
- [辞書レビュー](docs/INTENT_DICTIONARY_REVIEW.md): 候補の採用・保留・除外を確認する一覧。
- [COMMAND_LOG](docs/COMMAND_LOG.md): 重要なコマンドと既知の環境問題。

入力 → `app/nadameyo/src/App.jsx` → アプリ内の `src/lib/intentMatcher.js` で正規化・判定 → `src/data/intent-dictionary.json` の採用済み表現に応じて緊張度・信頼度・返答を更新する。辞書と判定は `test/intentMatcher.test.js` で検証する。

依存関係とnpmスクリプトはアプリ内で完結する。WhiteSpace全体の方針は [親README](../../README.md) を参照し、このプロジェクト固有の資料は本ディレクトリ内に置く。
