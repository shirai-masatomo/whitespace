# 原画と制作手順

生成方式：内蔵 image_gen。新規の有料API、CLI/API経由の画像生成、外部素材購入なし。

## 原画

- large_stage1.png：新規の大岩山。大きな峰、左肩の白い筋、前方の基部。
- large_stage2.png：stage1の編集。峰の上部・右肩を欠き取る。
- large_stage3.png：stage2の編集。中央の高い柱・右側を削り低い塊へ。
- large_stage4.png：stage3の編集。基部だけを残す。
- small_stage1.png：1セル用として別途新規制作。大岩山の単純縮小ではない。
- small_stage2.png：small stage1の編集。尖った上部を削る。
- small_stage3.png：small stage2の編集。低い基部だけを残す。
- large_remains.png：large stage1を参照編集し、立体をなくして砕石の散布へ。
- small_remains.png：small stage1を参照編集し、少量の破片へ。

原画9枚はoriginals/に保管。画像ツールの出力を無改変で保存。PROMPTS.mdに実際に使用した全文を記録しています。

## ゲーム用整形

build.pyで、stage1の共通縮尺を維持した原寸化、12色パレット、輪郭内のRGBA整形、接地調整、PNG個別出力を行います。段階ごとに岩の外接矩形を同寸法に合わせ直す処理はありません。normalization.jsonに縮尺と輪郭補正の結果を記録。

既存の自作素材は配色・ドット密度・寸法の参照だけに使用。新しい岩PNGへ既存ゲームや他作品の画素をコピーしていません。比較画像の主人公・柴犬は採用済みPNGをそのまま使用。

納品：../../art_delivery/mining_rock_objects_v1/
基準：48×42セル、nearest、通常RGBA、左上光源。元ブランチの着手前HEAD f541d1ac72549398221e7b458443f6b4d0b9d10e。ゲームコードの編集なし。
