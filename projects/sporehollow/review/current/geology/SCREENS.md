# 大規模岩盤の画像確認

**すべてCPU合成画像。実ゲームのGPUスクリーンショットではない。**
`tests/review_geology_cpu.gd` が実際の生成Worldのセル・RockView/GeologyArtを使用して描く。下地はセルの地形色の簡易表示。通常の地面シェーダー、樹木、独立岩山、人物、HUDは描いていないため、それらの画面品質を合格とする証拠ではない。

- [seed31全景](cpu-overview-31.png)
- [seed97全景](cpu-overview-97.png)
- [seed2026全景](cpu-overview-2026.png)
- [鉄鉱脈付近・採掘前](cpu-detail-before.png)
- [同じ位置・1セル除去後](cpu-detail-after.png)

前後画像は同一seed・同一切り出し。除去後画像は表示用fixture。実際のWorld.stepによる採掘・通行・資源生成は rock-connections.json と geology-art.json で別に検証する。画像担当の合成見本は完成ゲームの証拠として流用していない。
