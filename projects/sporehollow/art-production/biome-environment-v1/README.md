# Biome environment v1 制作原本

2026-10-12。内蔵image_genを使用。新しい有料API・外部サービスなし。生成プロンプト全文はrock-generation.jsonとground-generation.json。既存正式素材は上書きせず、参照のみ。ユーザー添付画像は景観と自然物の参考で、その画素は抽出・転載していない。

- originals/rock_materials.png：岩上面・側面・岩・瓦礫・砂利・露出面の素材原画。
- originals/ground_stumps.png：乾燥地・草地・切株の素材原画。
- references/：指定GitHubブランチのコード・仕様・保存済みレビュー画像。reference-commit.jsonにSHA。保存済み画像は最新コードの描画結果を保証しない。
- native/：加工済み岩テクスチャ。ゲーム用の最終画像はart_delivery/biome_environment_v1/。
- build_rock.py：岩場16接続、独立面、損傷、瓦礫、石片、確認画像。通常素材は現行12pxの正面高さに合わせる。
- build_ground.py：生成原画の実際の物体範囲を明示して抽出し、等比・限定色・alpha整形。地面色を保持する薄い土模様と不規則な小草株。
- build_forest.py：3種の切株と幹内の切り込み、落ち葉。元の木を再生成せず、幹/樹冠の合成一致を検査。
- validate.py：各段階manifestを集約。RGBA/寸法/非空/ハッシュ、既存1501PNGの保全、東西64組・南北64組の接続端の不透明性、中央面充填、シート一致を確認。
- review.py：オフライン構成確認用PNG/GIFと一覧・HTML。ゲームを起動しない。

再現順：build_rock.py → build_ground.py → build_forest.py → validate.py → review.py。Python/Pillow/numpy。画像の輪郭・接続端・アンカー・切断面は原寸で整形し、単に縮小した原画を納品しない。原画alphaに微小な残留があるため閾値を先に適用し、明示範囲で隣接物を排除。白い石面や木口は不透明のまま保持。

各セットの先行納品後も、このフォルダは制作履歴と再現用に保全する。最終納品はHANDOFF/manifestが正本。参考画像・GIFを本番アセットとして読み込まない。
