# バイオーム追加 v2 制作原本

内蔵image_genを用い、不足する岩塊の進行原画と伐採後の丸太/枝葉だけを新規生成。generation.jsonに完全なプロンプトを保存。既存採用素材は参照利用し、v1も上書きしない。

実行順：build.py → review_validate.py → finalize.py。Python/Pillow/numpy。ゲームの起動・本番コード変更なし。

build.pyは固定倍率で岩を原寸化し、無傷の顔/岩肌を保持したまま初期欠けを加工。後段は実際に体積を減らし、共通接地y46へ配置。原画を単に同じ外接サイズへ縮小した4枚ではない。地表・境界は既存原画と正式PNGから作り、2px単位の不規則な透明密度で移行する。木の割れは既存幹alphaにクリップ。白い石面・木口を残し、透明RGBは0に正規化。

prior-hashes.jsonは開始時の既存PNG保全記録。extraction.jsonに倍率と各段階の可視面積を記録。レビューGIFの時間は確認用で、ゲームの作業時間や閾値ではない。最終素材・manifest・HANDOFFは../../art_delivery/biome_environment_v2/。
