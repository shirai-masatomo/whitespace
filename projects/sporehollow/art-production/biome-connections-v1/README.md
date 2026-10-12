# 接続・露出・境界の原寸整形

既存の内蔵image_gen由来v1/nativeの上面・前面テクスチャ、v2の地表を参照。原画重複コピー・単独岩再生成なし。build.pyで接続ポート、露出面、草土砂利岩盤の遷移を原寸で整形する。Pillow/numpy。原画そのものはv1に保存済み。

既存素材の不変ハッシュはprior-hashes.json。ゲーム用PNGとオフライン見本はart_delivery/biome_connections_v1。実ゲーム検証は実装側が別途実施する。build.pyは実行ごとにその時点の既存素材を検査するため、納品時のprior-hashesはコミット保存して基準とする。
