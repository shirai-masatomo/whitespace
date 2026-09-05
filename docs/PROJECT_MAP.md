# WhiteSpace プロジェクトマップ

## 最初に読む順番

[PROJECT_STATE](../PROJECT_STATE.md) → [SPEC](../SPEC.md) → [ACCEPTANCE](../ACCEPTANCE.md) → [TODO](../TODO.md)。制作方針と自律的な進め方は [AGENTS](../AGENTS.md)。対象アプリの [APP_STATE](../prototypes/001-nadameyo/APP_STATE.md) と [README](../prototypes/001-nadameyo/README.md) も確認します。

## 現行アプリの流れ

```text
prototypes/001-nadameyo/
  src/App.jsx                 入力と表示
      ↓ 送信
  src/lib/gameEngine.js       入力・直近履歴・状態を評価器へ渡す
      ↓                      ↑ intent / 判断状態 / 一致語 / 理由
  src/lib/intentMatcher.js    ローカル辞書による言語評価
      ↓ 読み取り
  src/data/intent-dictionary.json

  gameEngine.js              数値・反復・回復・終了を更新
      ↓ 発言後の状態と履歴
  src/lib/responses.js        返答・変化説明・振り返り
      ↓
  App.jsx                    画面へ表示

  test/intentMatcher.test.js  言語評価の独立テスト
  test/gameEngine.test.js     ゲーム進行・返答の独立テスト
```

テストは別途コマンドで実行し、ゲーム中には実行しません。モデル導入はまだなく、必要になったら言語評価の境界を拡張します。

## 記録の役割

- [COMMAND_LOG](COMMAND_LOG.md): 日時・コマンド・結果・学びの累積。
- [INTENT_DICTIONARY_REVIEW](INTENT_DICTIONARY_REVIEW.md): 辞書から生成する採否理由・出典・現在の単独判定。
- [INTENT_REVIEW_OUTCOME](INTENT_REVIEW_OUTCOME.md): 別環境で行ったレビューの歴史的記録。
- [PLAYTEST_2026-09-05](PLAYTEST_2026-09-05.md): 今回の実操作・改善理由・確認結果。

ルートの旧index.html/app.js/style.cssは現行アプリから独立しており、今回編集しません。
