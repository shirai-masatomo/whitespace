# 採掘・伐採：画面と動き

撮影ソースca21a14、正式素材b0e917a11f205190dde0136165a72c189f39e275。seed31の検証配置、1280×800の実GPU OpenGL、Dummy音声、30fps上限。

- [採掘の8秒連続画像](mine.webp)
- [伐採の8秒連続画像](clear_tree.webp)

各64サンプルを8fpsで取得。無劣化WebPは同じ待機画面をまとめ、51フレーム/8秒として保存。実際のWorld.stepとゲーム描画で、素材比較GIFではない。

| 作業 | 開始 | 打撃 | 完了直前 | 崩壊/倒木後 |
|---|---|---|---|---|
| 採掘 | [PNG](mine_start.png) | [PNG](mine_strike.png) | [PNG](mine_near_complete.png) | [PNG](mine_after.png) |
| 伐採 | [PNG](clear_tree_start.png) | [PNG](clear_tree_strike.png) | [PNG](clear_tree_near_complete.png) | [PNG](clear_tree_after.png) |

採掘後も隣接4セルは残り、石8個は現地・利用可0。伐採後も別の木は残り、木材8個は現地・利用可0。4秒の作業で打撃5回/完了1回。回収の実動作はheadlessで別検証。

[石への打撃](mine_hit.wav) / [斧の打撃](chop_hit.wav) / [崩壊](rock_crumble.wav) / [倒木](tree_fall.wav)

音は実際のGame Audioが使うPCMを出力。Dummy検証で通知/cueを確認し、実スピーカーの聴感評価とは区別。元BGMは維持。
SHA256・寸法・時間は[IMAGES.json](IMAGES.json)。
