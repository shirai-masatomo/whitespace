# UI参考と実画面の統合索引

管理入口は `assets/ui-reference/`。全画像の元ファイル・用途・採用状態・版・SHA-256は [manifest.json](../assets/ui-reference/manifest.json) に記録する。原本は削除・上書きしない。

| 画面 | 採用する参考 | 区分 |
| --- | --- | --- |
| 探索 | [PX-01](../assets/ui-mocks/01_exploration_pixel.webp) | 正式画風・構図 |
| 戦闘 | [PX-02](../assets/ui-mocks/02_battle_pixel.webp) | 正式画風・構図。手動コマンド・複数人は不採用 |
| ステータス | [PX-03](../assets/ui-mocks/03_status_pixel.webp) | 正式画風・構図。4タブ・11枠の操作仕様を優先 |
| タイトル | [最新ユーザー参考](../assets/ui-reference/supplemental/title-latest.png) | 今回の添付参考。PX番号は新設しない |
| 冒険準備 | [最新ユーザー参考](../assets/ui-reference/supplemental/preparation-latest.png) | 今回保存。従来の「未制作」を解消 |
| 倉庫 | [最新ユーザー参考](../assets/ui-reference/supplemental/warehouse-latest.png) | 今回保存。左15＋3／中央グリッド／右詳細の仕様を優先 |

ユーザーの旧倉庫・ステータス・4タブ仕様シートは [supplemental](../assets/ui-reference/supplemental/) に保存。新しい構図と両立する範囲で参照する。旧4枚は [archive/2026-10-16](../assets/ui-mocks/archive/2026-10-16/) に保持し、現行画風として採用しない。

## 実装用の独立素材

[interface/v1](../assets/interface/v1/) の羊皮紙・石・真鍮フレーム・ボタンを領域参照／9-sliceで再利用。
[interface/v2](../assets/interface/v2/) の `surface-title.png`／`surface-preparation.png`／`surface-warehouse.png` は、ユーザーが別添した **文字・ボタンのない独立背景**。完成UI参考の切り抜きではない。
同フォルダの `symbols.png` のHP/SP/EXP・攻撃／防御／速度・4状態アイコン、`containers.png` 上段の収納3種をAtlasTextureとして利用する。
旧地下倉庫・地下町の背景と重複ファイルは元画像を保持するが、最新の地上町構図には適用しない。下段の収納発光は隣と重なるため不採用、選択は実UI枠で表す。
既存主人公・敵・洞窟、青マントと装備アイコンは継続利用する。

## 実ゲームの証拠

[0.6.0 比較・確認資料](../review/ui-integration-0.6.0/README.md) に参考対実画面、改善前後、4タブ、遷移と不足素材を集約する。**参考原画と実ゲームの画面は別物**。固定検証状態の倉庫内容・ボス・結果は通常の攻略実績と区別する。
変更前は保存済み実画面を使い、元ファイル名・版が確認できる0.5.4と、それ以前の履歴を区別してマニフェストに登録する。

## 関連する仕様

[起動・準備](STARTUP_PREPARATION_UI.md)／[ミニマップ](DUNGEON_MAP.md)／[元素材監査](UI_ASSET_INVENTORY_2026-10-18.md)／[今回の不足素材](UI_INTEGRATION_ASSETS.md)。
数値・経歴・属性耐性・仲間などは参考画像から仕様化しない。
