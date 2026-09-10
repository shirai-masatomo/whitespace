# WhiteSpace プロジェクトマップ

## 最初に読む順番

新しい試作・仕様変更・タスク立案時は [設計思想書](DESIGN_PHILOSOPHY.md) を参照します。将来構想と今回の実装範囲は区別します。

[PROJECT_STATE](../PROJECT_STATE.md) → [SPEC](../SPEC.md) → [ACCEPTANCE](../ACCEPTANCE.md) → [TODO](../TODO.md)。制作方針と自律的な進め方は [AGENTS](../AGENTS.md)。対象アプリの [APP_STATE](../prototypes/001-nadameyo/APP_STATE.md) と [README](../prototypes/001-nadameyo/README.md) も確認します。

## コーヒー場面実験

[最初に開く：プレイヤー視点の分岐図](COFFEE_PLAYER_FLOW.md)。A/B/Cの初期状況→初手→相手の反応→2手目の全候補と結果を、実際の文言で追う入口。操作を省く・自動化する議論はここから。[今回のUI・図の確認](COFFEE_PLAYER_FLOW_REVIEW.md)。

[COFFEE_PRESENCE_REVIEW](COFFEE_PRESENCE_REVIEW.md): 現在の場面UI・台詞/実動作・既知情報の仕様と検証。

[COFFEE_TRANSITIONS](COFFEE_TRANSITIONS.md): A/B/Cの全体遷移図・規則表・数え方。完全な行き先は [A](COFFEE_STATES_A.md) / [B](COFFEE_STATES_B.md) / [C](COFFEE_STATES_C.md) の全状態表。

[COFFEE_CONTEXT](COFFEE_CONTEXT.md): 初版の判断・実モデル測定・ブラウザ検証（歴史的記録）。

coffeeRules（条件/発話/効果）→ coffeeScene（更新/根拠/履歴）→ CoffeeScene + CoffeeTable（発話/動作/机上表示）。scripts/coffeeGraph.mjsが全到達状態を探索し、generate-coffee-map.mjsが図と表を生成。test/coffeeGraph.test.jsが全遷移の不変条件を検証。

Workspace → CoffeeScene (#coffee) → coffeeScene（事実/知識/同意/更新） → coffeeCharacter → Character。自由入力は coffeeLanguage → /api/coffee/evaluate → server/coffeeModel → 既存Ollama。解釈をプレイヤーが確認してから同じ状態更新へ渡します。

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

テストは別途コマンドで実行し、ゲーム中には実行しません。ゲームは辞書のまま、次の独立比較経路を追加しています。

```text
src/Workspace.jsx → App.jsx (#game) / Comparison.jsx (#compare)
Comparison.jsx → lib/comparison.js → 同じ辞書評価器
                                  → /api/language/evaluate
server/localModel.js → lib/modelContract.js（固定プロンプト・形式検証）
                     → このPCのOllama :11435
src/data/comparisonCases.js        レビュー3例・生成25例
scripts/compare-language.mjs       同じ実装で初回/ウォーム測定
test/localModel.test.js            契約・エラー・APIの検証
```

[LOCAL_MODEL](LOCAL_MODEL.md) は環境・起動・測定条件、[PLAYTEST_2026-09-06](PLAYTEST_2026-09-06.md) は今回の実操作、`experiments/` は実測JSONです。モデルとランタイムはルート `.local-llm/` にあり、Gitには含めません。

## 記録の役割

人物表示の経路:

```text
App.jsx（実ゲーム・round・手動動き軽減）
  → Character.jsx（独立プレビュー・代替SVG・開発パネル）
  → lib/characterState.js（状態→姿勢、発言イベント、補間）
  → character/createCharacterRenderer.js（Three.js・ループ・解放）
      → createBust.js（コード生成の形状・光）
      → disposeScene.js（共有する資源の解放）
```

今回の確認・判断・未確認事項は [PLAYTEST_2026-09-08](PLAYTEST_2026-09-08.md)。人物表示はゲームを読み取るだけで、LLMや比較ラボへ依存しません。

- [COMMAND_LOG](COMMAND_LOG.md): 日時・コマンド・結果・学びの累積。
- [INTENT_DICTIONARY_REVIEW](INTENT_DICTIONARY_REVIEW.md): 辞書から生成する採否理由・出典・現在の単独判定。
- [INTENT_REVIEW_OUTCOME](INTENT_REVIEW_OUTCOME.md): 別環境で行ったレビューの歴史的記録。
- [PLAYTEST_2026-09-05](PLAYTEST_2026-09-05.md): 今回の実操作・改善理由・確認結果。

ルートの旧index.html/app.js/style.cssは現行アプリから独立しており、今回編集しません。
