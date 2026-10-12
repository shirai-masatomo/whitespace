# rock_biome/drops

[一覧画像](INDEX.png) / [全体の取り込み仕様](../../HANDOFF.md)

追加PNGと既存参照を区別。INDEX.pngは確認用で本番素材ではありません。

新規2枚／既存参照1枚。PNGの枠と占有は別です。

| ファイル / 参照 | 用途 | 寸法 | 基準点 | 占有 |
|---|---|---|---|---|
| [crushed_stone.png](crushed_stone.png) | Optional appearance of existing stone item; NOT a new resource type or quantity. | [24, 24] | [12, 18] | [0, 0] |
| [rock_scraps.png](rock_scraps.png) | Optional appearance of existing stone item; NOT a new resource type or quantity. | [24, 24] | [12, 18] | [0, 0] |
| [REF drops.stone](../../../resource_icons_v1/hud24/stone.png) | drops.stone | [24, 24] | [12, 12] | [0, 0] |

静止状態保持：frame_order=[0]、duration_ms=null、loop=false。採掘時間や資源量は画像で決めません。
接続岩はN1/E2/S4/W8。地表境界は別判定。マスク・内角・重ね順は全体HANDOFFを参照。
