# 出典と加工記録

- 基準：ART_SPEC.md、assets/ui/SOURCES.md、採用済み主人公v1・柴犬比較v2 C。人物・柴犬の採用静止PNGは再描画していない。
- 鶏・猫：art-production/stage-1-v2/review/existing-hen-crop.png と existing-cat-crop.png の既存個体を参照。鶏は生成りの羽・赤い冠・短い黄土色の嘴、猫は灰色・黄緑の目・立った尾を維持。
- 商人・露店：実在する assets/ui/market-stall.png を参照。麦わら帽子・髭・生成りシャツ・緑の前掛けの人間。merchant.png は頭身の不採用原画、merchant-v2.png が納品用。
- 図鑑：実在する assets/ui/book-open.png の茶革・生成り紙・緑の栞を参照。文字や未指定の動物は追加していない。
- 巻物：採用色・ドット密度に合わせた新規原画。
- 背景：実装担当保存の review/current/characters/native_scale.png。原画側 references/ に画像・SHA256・実装コミットを保存。素材担当がゲームを起動したものではない。
- ユーザー添付のUI提案は案段階のレイアウト参考として扱い、掲載の牛・羊・馬・小屋などは制作対象へ追加していない。

内蔵 image_gen.imagegen で生成した原画を originals/ に保存。プロンプト全文は原画側 prompts.json。白背景原画の再加工や比較画像からの切り抜きで、採用済み主人公・柴犬を作り直すことはしていない。

追加原画は最終ドット寸法へ等比で整え、パレット・alpha・目や輪郭・足元を整理。図鑑は白紙の中間領域を延長してページ比率を整え、同じ綴じ目を支点に素材を合成。表紙の押し印と枠を最終論理解像度で補正。商人は主人公に近い頭身を再生成し、採用キャラクターの顔を変更していない。

原画側 prepare_assets.py → finish_assets.py で出力し、validate_delivery.py で寸法・alpha・足元・ハッシュと既存採用画像の一致を検査する。

