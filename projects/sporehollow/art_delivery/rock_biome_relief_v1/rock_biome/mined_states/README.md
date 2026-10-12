# rock_biome/mined_states

[一覧画像](INDEX.png) / [全体の取り込み仕様](../../HANDOFF.md)

追加PNGと既存参照を区別。INDEX.pngは確認用で本番素材ではありません。

新規6枚／既存参照0枚。PNGの枠と占有は別です。

| ファイル / 参照 | 用途 | 寸法 | 基準点 | 占有 |
|---|---|---|---|---|
| [damage_1.png](damage_1.png) | Clip by selected combined rock alpha. Overlay scars/chips; retain connection until depleted. | [48, 66] | [24, 45] | [1, 1] |
| [damage_2.png](damage_2.png) | Clip by selected combined rock alpha. Overlay scars/chips; retain connection until depleted. | [48, 66] | [24, 45] | [1, 1] |
| [damage_3.png](damage_3.png) | Clip by selected combined rock alpha. Overlay scars/chips; retain connection until depleted. | [48, 66] | [24, 45] | [1, 1] |
| [excavated.png](excavated.png) | Mining aftermath on intact underlying ground; no void, no item counts. | [48, 42] | [24, 21] | [0, 0] |
| [rubble.png](rubble.png) | Mining aftermath on intact underlying ground; no void, no item counts. | [48, 42] | [24, 21] | [0, 0] |
| [rock_dust.png](rock_dust.png) | Mining aftermath on intact underlying ground; no void, no item counts. | [48, 42] | [24, 21] | [0, 0] |

静止状態保持：frame_order=[0]、duration_ms=null、loop=false。採掘時間や資源量は画像で決めません。
接続岩はN1/E2/S4/W8。地表境界は別判定。マスク・内角・重ね順は全体HANDOFFを参照。
