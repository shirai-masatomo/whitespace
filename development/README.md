# develop：素材の確認と採否

[資料の入口](../README.md) ／ [採用・格納のルール](../reports/SCENE_MANAGEMENT.md)

PC側の現行入口は画像ラボの `develop/index.html`。各素材の横で **OK／保留／不採用／修正待ち／旧版へ** を記録し、メモを書けます。シーン・人物・背景・文字／エフェクトを同じ入口で管理します。

- [共通の操作用HTML](index.html)
- [シーンだけの操作用HTML](scenes/index.html)
- [文字・エフェクトだけの操作用HTML](text-effects/index.html)

GitHub上ではHTMLは動作しません。Code → Download ZIPで取得・展開して開いてください。採否はブラウザー保存＋JSONの書き出し／読み込みです。**「採否を保存」でJSONをCodexへ渡して「正式反映して」と伝えるか、画像ID等で対象を明示して採用を指示してください。** ブラウザーのOKだけでは製品フォルダーに書き込みません。

正式採用済みは「正式採用済み」、旧版・不採用は「旧版・不採用」へ分け、通常の確認中に古い版がたまらないようにします。画像が変わった際は旧版のOKを引き継ぎません。同一用途の改訂は旧ファイルと後継を記録します。原本・履歴は削除しません。

今後のシーン制作は、ユーザーが見直しているassetsの現行素材・個別採否を参照します。assets内の文字も掲載だけで採用とはみなしません。製品用は背景＋人物＋表情＋効果のレイヤー構成を基本とします。

## 今回の範囲

PC側は288項目（文字・エフェクト66、シーン53、人物92、場所51、部品26）。形式違いをまとめた採否単位です。明確な旧版等50項目は履歴へ分けています。今回新たに正式採用した素材は0、製品CGへの画像追加も0です。

共有版は既にGitHubに保存済みの画像だけを参照します。最新のローカル限定素材や、全形式を共有できていない項目は除外。PC側が現在の素材確認の正本です。製品CG・最新寝室・ローカルの自宅archive整理を新規送信していません。Pagesは有効化しません。

## 参考シーンを場所ごとに読む（GitHub上の静的な一覧）

| 場所 | 参考画像数 |
| --- | --- |
| [海水浴場](beach/README.md) | 1 |
| [カフェ](cafe/README.md) | 1 |
| [自宅・浴室](heroine-home/bathroom/README.md) | 4 |
| [自宅・寝室](heroine-home/bedroom/README.md) | 5 |
| [自宅・キッチン](heroine-home/kitchen/README.md) | 1 |
| [自宅・リビング](heroine-home/living/README.md) | 30 |
| [自宅・トイレ](heroine-home/toilet/README.md) | 1 |
| [ホテル](hotel/README.md) | 1 |
| [個室居酒屋](izakaya-private-room/README.md) | 1 |
| [図書館](library/README.md) | 1 |
| [屋外](outdoors/README.md) | 2 |
| [その他・場所確認待ち](unclassified/README.md) | 5 |
