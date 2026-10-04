# 商人・荷車 v2 の出典

- 編集対象：art_delivery/ranch_assets_v1/merchant/idle_right_00.png、stall/idle_front_00.png（前納品 57aab97c3efc495d7553ee412c68696945d8e846）。
- 共通絵柄参照：同納品 review/overview.png。主人公・柴犬・鶏・猫・本・巻物は変更対象外。
- 商人の体格・顔の参考：ユーザー添付 codex-clipboard-7daabaa3-ec48-451d-803a-c9da50d3cd69.png。スポポビッチの雰囲気を少し足すというユーザーの指定。額の文字・戦闘ポーズは採用していない。
- 荷車の商人参照：今回生成した originals/merchant.png。
- 比較背景：art-production/ranch-assets-v1/references/implementation-native-scale.png。実装担当の保存済み画像（実装 d9f4edf8c898f2a5d8f6ea908831e7f34261fdf6）。

内蔵 image_gen.imagegen による編集。merchant.png は exec-bbc14716-1f15-421d-94ea-135bb8085b49.png、cart.png は exec-9330793a-4887-4382-9624-3eea2f1ae70a.png からそのままコピー。

透過alphaを保って等比で論理解像度へ配置し、共通パレットに整理。商人の1px輪郭・眉・口を最終32×48で修正。原画は不変。色キーで白い布や歯を抜く処理はしていない。native-grid-before-cleanup.png は最終調整前の検査資料であり納品PNGではない。

最終生成プロンプト2本は prompts.json に全文保存。prepare_delivery.py で納品PNG・manifest・比較画像を再出力可能。

