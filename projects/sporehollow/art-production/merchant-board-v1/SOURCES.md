# 出典

- デザイン参照：art_delivery/merchant_cart_v2/cart/idle_front_00.png。坊主で筋肉質の商人、緑前掛け、生成り／緑の屋根、不思議な品と木製荷車を継承。
- 問題箇所：ユーザー添付 codex-clipboard-58d91fa6-b75d-4608-a37f-16a6c9336997.png。references/user-current-crop.pngにそのまま保存。旧仮描画を新デザインとして採用したものではない。
- 比較背景：art-production/ranch-assets-v1/references/implementation-native-scale.png（実装担当保存済み画面）。主人公・柴犬はcharacters_v1の採用済み透過PNGを使用。
- 生成：内蔵image_gen.imagegen。生成画像 exec-0966ebdb-26fa-4b65-b5cf-8960ba35d15a.png をoriginals/cart-board.pngへコピー。外部有料API不使用。
- 最終生成プロンプト：prompts.jsonに全文保存。
- 加工：128×96の盤面用グリッドへ等比配置し、前納品の共通パレットを使用。最終1px輪郭と車輪の抜けを整理。透明背景をalphaで保持し、白い布を色キーで抜かない。
- prepare_delivery.pyで透過PNG・manifest・比較画像を再出力可能。出力以外の既存画像やコードは変更しない。

