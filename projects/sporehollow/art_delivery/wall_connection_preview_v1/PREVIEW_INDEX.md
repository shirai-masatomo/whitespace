# 壁1マス接続の監査・比較

**全て合成プレビュー／未実装。実ゲーム動作確認の証拠ではありません。** 1×リンクは画像を100%で表示。2×は同じ画素のnearest拡大です。

|形状|通常倍率|2倍|
|---|---|---|
|単独1マス|[single 1×](single_1x.png)|[nearest 2×](single_2x.png)|
|横5マス|[horizontal 1×](horizontal_1x.png)|[nearest 2×](horizontal_2x.png)|
|縦5マス|[vertical 1×](vertical_1x.png)|[nearest 2×](vertical_2x.png)|
|L字|[elbow 1×](elbow_1x.png)|[nearest 2×](elbow_2x.png)|
|T字|[tee 1×](tee_1x.png)|[nearest 2×](tee_2x.png)|
|十字|[cross 1×](cross_1x.png)|[nearest 2×](cross_2x.png)|
|壁とドア・開口|[door 1×](door_1x.png)|[nearest 2×](door_2x.png)|
|土→木→石・混在|[mixed 1×](mixed_1x.png)|[nearest 2×](mixed_2x.png)|

[ドア縦横・開閉](door_states_1x.png) / [不足一覧・判断](HANDOFF.md) / [検査](QUALITY_REVIEW.json)

## 推奨と自己評価
既存16接続を継続使用。必須の新規PNGは0枚です。改善欄は右外縁へ1pxの輪郭補助を追加した表示案で、壁の厚み・アンカー・占有は変えていません。縦壁が草地から識別しやすくなりますが、小さな差です。横壁は元々前面24pxで十分読めるため、元のままでよいです。採用するなら縦の外縁だけへ限定することを推奨します。

この案は「壁を太くする」案ではありません。縦横を同じ見かけの太さにしたい場合は投影断面の再設計となり、局所パッチで済むと誤認しないでください。今回は全16接続を再制作していません。
