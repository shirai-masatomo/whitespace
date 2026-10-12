# rock_biome/decor

[一覧画像](INDEX.png) / [全体の取り込み仕様](../../HANDOFF.md)

追加PNGと既存参照を区別。INDEX.pngは確認用で本番素材ではありません。

新規5枚／既存参照2枚。PNGの枠と占有は別です。

| ファイル / 参照 | 用途 | 寸法 | 基準点 | 占有 |
|---|---|---|---|---|
| [pebbles.png](pebbles.png) | Sparse non-resource ground scatter; does not represent collectible quantity. | [48, 42] | [24, 21] | [0, 0] |
| [crushed_stone.png](crushed_stone.png) | Sparse non-resource ground scatter; does not represent collectible quantity. | [48, 42] | [24, 21] | [0, 0] |
| [rock_shards.png](rock_shards.png) | Sparse non-resource ground scatter; does not represent collectible quantity. | [48, 42] | [24, 21] | [0, 0] |
| [gravel.png](gravel.png) | Sparse non-resource ground scatter; does not represent collectible quantity. | [48, 42] | [24, 21] | [0, 0] |
| [fissure_dirt.png](fissure_dirt.png) | Optional mineral/dirt fissure, sparse overlay. | [48, 42] | [24, 21] | [0, 0] |
| [REF decor.low_sparse](../../../biome_environment_v1/ground/lush/low_sparse.png) | decor.low_sparse | [48, 42] | [24, 21] | [0, 0] |
| [REF decor.flowers](../../../biome_environment_v1/ground/lush/flowers.png) | decor.flowers | [48, 42] | [24, 21] | [0, 0] |

静止状態保持：frame_order=[0]、duration_ms=null、loop=false。採掘時間や資源量は画像で決めません。
接続岩はN1/E2/S4/W8。地表境界は別判定。マスク・内角・重ね順は全体HANDOFFを参照。
