# 仕様書（SPEC）

このファイルは、WhiteSpaceプロジェクトで「何を作るか」「現在の実装がどのような仕様か」を記録する。

## プロジェクトの目的

WhiteSpaceは、小さな試作を重ねながら、将来的に次のような作品やサービスを制作するための基盤プロジェクトである。

- PC向けゲーム
- ARG（現実世界の情報やWebサイトなども使って進行する体験型ゲーム）
- その他の実験的・革新的なサービス

## 現在のアクティブなプロトタイプ

- 場所: `prototypes/001-nadameyo`
- タイトル: `宥めよ`
- 種類: テキスト会話ゲーム
- 技術構成: Vite、React、ローカルのルールベースintent判定
- 実行環境: ローカルブラウザ

## 体験の狙い

プレイヤーは言葉を発することでしか状況を動かせないが、発言そのものにリスクがある。相手の言葉を読み、一文を選び、信頼度または緊張度の変化を見ながら成功・失敗へ進む小さなゲームループで、この緊張感を表現する。

## 現在のゲーム仕様

- 指令 `宥めよ` を表示する。
- 緊張度、信頼度、残り発言数を表示する。
- プレイヤーは一度に一文を入力して送信できる。
- 入力を正規化してからintent判定を行う。
- 一致したintentに応じて、相手の返答と状態値を変更する。
- 緊張度が最大になると失敗する。
- 信頼度が成功条件に達すると成功する。
- 発言回数を使い切ると失敗する。
- 成功・失敗後は最初から再挑戦できる。

## intent判定

単語ごとの個別処理ではなく、意味カテゴリであるintentを使って入力を判定する。

- `rejection`（拒絶）: 緊張度を大きく上げる。
- `hostile`（敵意）: 緊張度を大きく上げる。
- `command`（命令）: 緊張度を上げる。
- `apology`（謝罪）: 信頼度を上げる。
- `listening`（傾聴）: 信頼度を上げる。
- `reassurance`（安心）: 信頼度を上げる。
- `unknown`（未分類）: 緊張度を少し上げる。

ゲームで使うintent定義と表現データは `prototypes/001-nadameyo/src/data/intent-dictionary.json`、判定処理は `prototypes/001-nadameyo/src/lib/intentMatcher.js` に置く。

## intent辞書の運用

各表現は `text`、`intent`、`subtype`、`confidence`、`sourceType`、`status` を持つ。

- `status: adopted`: ゲームの判定に使用する。
- `status: review`: レビュー候補として保持し、ゲームの判定には自動採用しない。
- `confidence: medium` または `low`: 文脈によって意味が変わる可能性があるため、特に慎重に確認する。

候補一覧は `docs/INTENT_DICTIONARY_REVIEW.md` に生成する。候補収集だけを理由に、緊張度・信頼度・返答・intentの優先順位・成功条件・失敗条件を変更しない。

## 管理ドキュメント

- `PROJECT_STATE.md`: リポジトリ全体の現在地を記録する。
- `SPEC.md`: プロジェクトとアプリの仕様を記録する。
- `ACCEPTANCE.md`: マイルストーンの完了条件を記録する。
- `TODO.md`: 次に実行する小さな作業を管理する。
- `docs/COMMAND_LOG.md`: 重要なコマンドの実行履歴を記録する。
- `docs/INTENT_DICTIONARY_REVIEW.md`: intent候補の採否をレビューする。
- `prototypes/001-nadameyo/APP_STATE.md`: 「宥めよ」固有の状態、仕様、変更履歴を記録する。
- `docs/PROJECT_MAP.md`: プロジェクト構成と各文書の役割を案内する。
