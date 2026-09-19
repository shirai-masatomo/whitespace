# 言語ジェンガ（仮）

言葉や前提を抜く・変えると、場面の意味はどこまで残るか。現在は「雨の駅前」の六層を直接操作する小さなパズルです。自由入力の日本語全般を解釈するものではありません。

- [現在地・次の仮説](PROJECT_STATE.md)
- [起動方法](app/nadameyo/README.md)
- [遊び方と規則](docs/SPEC.md)
- [次の候補](docs/TODO.md)

旧試作「宥めよ」は画面上部から開けます。[辞書の採否・出典・利用条件](docs/INTENT_DICTIONARY_REVIEW.md)は保持しています。別ブランチのコーヒー実験は未統合です。

アプリは app/nadameyo にあります。Jenga.jsx が画面、lib/layers.js が層の定義・解釈・操作の境界です。旧App.jsxとintentMatcherは比較用に維持。現行の規則をこのプロジェクト内で育て、他作品には依存しません。

[WhiteSpace全体](../../README.md) / [環境メモ](docs/COMMAND_LOG.md)
