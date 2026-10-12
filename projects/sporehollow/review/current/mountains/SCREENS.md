# 実ゲーム画像・採掘の動き

実装 `9624a291a35fd73046c1df51dd6e5fb11f73cd45` / 素材 `3229d2655e35e82d178577cdd8acbbe66e9be4f8`。1280×800、隔離GPU。素材担当の見本ではなくゲーム描画です。

[採掘開始→全段階→採掘完了の連続画像](mining.webp)（65フレーム、1フレーム=0.5ゲーム秒、音声なし）。

| 原本 | 条件 |
| --- | --- |
| [01_large_stage1.png](01_large_stage1.png) | 4x4 and 1x1 with keeper and shiba; paused real selection |
| [02_mining_hit.png](02_mining_hit.png) | Normal strike event, actual worker/contact, shared sound cue |
| [large_stage2.png](large_stage2.png) | Ordinary mining transition; updated physical drops and collision |
| [large_stage3.png](large_stage3.png) | Ordinary mining transition; updated physical drops and collision |
| [large_stage4.png](large_stage4.png) | Ordinary mining transition; updated physical drops and collision |
| [06_large_depleted.png](06_large_depleted.png) | Ordinary mining transition; updated physical drops and collision |
| [07_small_before.png](07_small_before.png) | 小岩山の通常採掘 |
| [08_small_after.png](08_small_after.png) | 小岩山の通常採掘 |
| [09_generated_map.png](09_generated_map.png) | Seed31 actual new map, overview scale, HUD hidden |
| [10_generated_rocky.png](10_generated_rocky.png) | Naturally generated large mountain and connected walls |

[画面ごとのtick・資源・占有・検証](mountains-observations.json) / [隔離とソースハッシュ](mountains-isolation.json) / [報告](REPORT.md)
