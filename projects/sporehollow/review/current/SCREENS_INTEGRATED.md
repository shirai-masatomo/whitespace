# 統合修正：更新後の画面8枚

撮影ソース `008c67c9c045d76a4084100dfd6236a405d87711`。通常EXE `bf6eeea`、素材 `b0e917a11f205190dde0136165a72c189f39e275`。ゲーム本体のgd/tscn/tresは配布版から差分なし。Godot開発版による実GPU描画、非対話画面、Dummy音声、30fps。

元のrelease EXEへの --script は無視されていた。[原因と修正](RENDER_DIAGNOSIS.md)。修正した正式ランナーで8枚を再取得した。これは同条件before/after比較のafter側。before側は未取得、素材見本/古い画面を代用しない。

| 画面 | PNG | 寸法 |
|---|---|---|
| 初期物資/中央の牧場主・柴犬・像 | [after_01_initial_stock.png](verification/visual/after_01_initial_stock.png) | 1280×800 |
| 役割表（追加作業者は検証fixture） | [after_02_roles.png](verification/visual/after_02_roles.png) | 1280×800 |
| 左下アーキテクト | [after_03_architect.png](verification/visual/after_03_architect.png) | 1280×800 |
| 命令4種 | [after_04_commands.png](verification/visual/after_04_commands.png) | 1280×800 |
| 動物表（鶏・猫は検証fixture） | [after_05_animals.png](verification/visual/after_05_animals.png) | 1280×800 |
| seed31の既存自然岩場 | [after_06_natural_rocks.png](verification/visual/after_06_natural_rocks.png) | 1280×800 |
| 連結岩/採掘跡（制御した配置fixture） | [after_07_connected_rock_fixture.png](verification/visual/after_07_connected_rock_fixture.png) | 1280×800 |
| 1920×1080のアーキテクト | [after_08_architect_1080.png](verification/visual/after_08_architect_1080.png) | 1728×1080 |

画素確認：初期物資は別セルで数量を表示、中央の個体/像を覆わず、役割/命令/アーキテクトは左下。岩の4方向連結と採掘跡は見える。画像欠落/全面空白なし。

別の残課題：動物表の3行目が一部隠れる/見出しと列位置がずれる。連結岩の自然な輪郭・描込みは採用参考との差が残る。技術的な撮影成功をUI全体の合格や人間の快適さと混同しない。
