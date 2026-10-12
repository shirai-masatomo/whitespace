# woodcut

[一覧画像](INDEX.png) / [全体の取り込み仕様](../HANDOFF.md)

追加PNGと既存参照を区別。INDEX.pngは確認用で本番素材ではありません。

新規2枚／既存参照6枚。PNGの枠と占有は別です。

| ファイル / 参照 | 用途 | 寸法 | 基準点 | 占有 |
|---|---|---|---|---|
| [fallen_trunk.png](fallen_trunk.png) | Optional non-colliding fallen trunk visual; 2-cell-wide drawing, no new resource node. | [96, 48] | [48, 35] | [0, 0] |
| [logging_ground.png](logging_ground.png) | Sparse wood dust and splinters after felling; base ground remains. | [48, 42] | [24, 21] | [0, 0] |
| [REF woodcut.wood_drop](../../resource_icons_v1/hud24/wood.png) | woodcut.wood_drop | [24, 24] | [12, 12] | [0, 0] |
| [REF woodcut.stump_small](../../biome_environment_v1/forest/stump_c.png) | woodcut.stump_small | [64, 80] | [32, 72] | [0, 0] |
| [REF woodcut.stump_medium](../../biome_environment_v1/forest/stump_b.png) | woodcut.stump_medium | [64, 80] | [32, 72] | [0, 0] |
| [REF woodcut.stump_large](../../biome_environment_v1/forest/stump_a.png) | woodcut.stump_large | [64, 80] | [32, 72] | [0, 0] |
| [REF woodcut.log](../../biome_environment_v2/tree_cut/log.png) | woodcut.log | [48, 42] | [24, 21] | [0, 0] |
| [REF woodcut.branch_debris](../../biome_environment_v2/tree_cut/branch_debris.png) | woodcut.branch_debris | [48, 42] | [24, 21] | [0, 0] |

静止状態保持：frame_order=[0]、duration_ms=null、loop=false。採掘時間や資源量は画像で決めません。
接続岩はN1/E2/S4/W8。地表境界は別判定。マスク・内角・重ね順は全体HANDOFFを参照。
