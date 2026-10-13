# 修正前後の実ゲーム画面

同じseed31/73/109、1280×800、05:00、停止、同じカメラ条件。素材比較見本ではなくGodotのviewport PNG。before/afterで地形生成規則が変わるため粘土の最大点は移動する。全景・中央・岩場の構図は同じ。素材の最終納品3229d265（個別由来はgame/art_provenance.json）。実装・EXEとの照合はDELIVERY.json。

|確認|前|後|
|---|---|---|
|seed_31_overview|[PNG](before/seed_31_overview.png)|[PNG](seed_31_overview.png)|
|seed_73_overview|[PNG](before/seed_73_overview.png)|[PNG](seed_73_overview.png)|
|seed_109_overview|[PNG](before/seed_109_overview.png)|[PNG](seed_109_overview.png)|
|center_soil_grass|[PNG](before/center_soil_grass.png)|[PNG](center_soil_grass.png)|
|seed_31_rock_edge|[PNG](before/seed_31_rock_edge.png)|[PNG](seed_31_rock_edge.png)|
|seed_73_rock_edge|[PNG](before/seed_73_rock_edge.png)|[PNG](seed_73_rock_edge.png)|
|seed_109_rock_edge|[PNG](before/seed_109_rock_edge.png)|[PNG](seed_109_rock_edge.png)|
|sand_transition|[PNG](before/sand_transition.png)|[PNG](sand_transition.png)|
|clay_transition|[PNG](before/clay_transition.png)|[PNG](clay_transition.png)|

[連続0](scroll_00.png) → [1](scroll_01.png) → [2](scroll_02.png) → [3](scroll_03.png)。同じ地表のままカメラが移動。PNG読込時間を含むため速度評価には使わず、[フレーム計測](PERFORMANCE.md)を参照。

観察：地表に土粒・草の短い茎・砕石を追加。旧版の独立した広い青地は岩場寄りの灰青の斑点へ。岩盤は地面として連続し、採掘対象の低い岩壁と大岩山は別に存在。低い岩壁のセル状外形と大岩山の描き込み差は残る。
