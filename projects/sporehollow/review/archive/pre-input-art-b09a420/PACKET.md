# 床操作・採用静止素材・隔離描画レビュー

- 対象：`codex/sporehollow-prototype`
- 画面検証：`d9f4edf8c898f2a5d8f6ea908831e7f34261fdf6`、dirty=false。
- ゲーム実装 / Windows出力：`62514753bce2e67bdc2ae7c9a11eb799a94d16d4`、dirty=false。d9f4edfの差分は検証fixtureのみで、ゲーム本体は同じ。
- 採用静止素材：`codex/sporehollow-art-assets` / `f3e4ae82b68c342b928dfb5dfcebb451353f9b8d` / `art_delivery/characters_v1/`。先行受領は28f0e3f。素材側のゲームコードは取り込んでいない。

## 今回変えたこと

- 物のない床へのクリックは、牧場主選択中なら移動、「連れていく」中なら誘導先指定。通常選択では床の修理/現地解体を維持。UIと建設ツールの優先順位も維持。
- 主人公v1右静止・柴犬C左右正面を盤面/プレビュー/個体情報へ導入。顔とPNGは無改変。主人公32×48・足元(16,44)、柴犬48×48・足元(24,44)。共通足元はセル中心+(0,14)。身体高42:28、native1.0、追加64%縮小なし、nearest・通常alpha。
- 旧主人公の図形描画と白抜きshaderを置換。クリック範囲と選択枠を新しい姿に合わせた。到着個体にカーソルの誘導プレビューを重ねない。
- `dev.ps1 visual` を非対話Windows Stationの専用desktop内のGPU描画へ置換。通常デスクトップにウィンドウを作らず、音/ユーザー入力/通常セーブも分離。失敗時に通常GUIへ戻さない。

## 納品・取込・検証の区別

| 素材 | 納品 | ゲーム取込 | 今回の画面確認 |
| --- | --- | --- | --- |
| 主人公v1・柴犬C静止4点 | f3e4ae82、SHA/寸法/alpha確認済み | 6251475で完了 | 隔離GPUで等倍/1.5倍表示、左右移動/停止、静止から仮休息/起床を確認 |
| 追加歩行/休息44コマ | 作業中にa5b6f55の追加納品連絡。Git上の全PNGをmanifestと照合 | **未取込** | **未確認**。納品側のGIFはゲーム確認の証拠にしない |

[静止受領検査](asset-receipt.json) / [追加動作納品の読み取り検査](motion-delivery-receipt.json)。今回は静止先行版。主人公の左静止は左右反転、歩行は既存の補間と小動作、睡眠は静止画像の仮回転。正式な動作コマの統合は次の動作単位の作業で行う。

## 今回撮影した画面・短い記録

すべて上記d9f4edfの実GPU描画。ゲーム内InputEventを使う検証fixtureであり、人間のOSマウス操作ではない。

- [等倍の相対サイズ・足元](characters/native_scale.png) / [選択枠](characters/keeper_selected.png)
- [停止中の床への移動予定](characters/floor_move.png) / [通常選択時の床解体](characters/floor_selected.png)
- [停止中の床への誘導予約](characters/floor_guide.png)
- [0.5 / 1 / 2倍：右移動→停止→左移動→停止](characters/movement-speeds.gif)（13.2秒、各倍率4.4秒）
- [床への誘導・左右の停止姿](characters/floor-guidance.gif)（8秒）
- [仮睡眠](characters/sleeping.png) / [起床後](characters/awake.png)

各画像・GIFの実装/素材コミット、フレーム列、SHA256は [index.json](characters/index.json)。GIFはViewportの連続フレームを10fpsへ符号化したもの。色の細部はPNGで判断する。

このフォルダ直下に残る旧PNG/GIFは過去の比較資料で、今回の検証証拠ではない。今回の証拠は `characters/` に限定する。

## 確認結果

- headless 8スイート **460項目成功**（入力40）。通常/PAUSEの床移動・誘導、屋内禁止、床解体、建設優先、落とし物優先、UI遮断、8件/8対象、既存防衛/生存/救出を確認。
- 既存AI評価192試行完走。評価式・衝突・マス座標・速度・戦闘能力は変更なし。
- Windows exportと専用EXEのheadless smoke成功。`artifacts/validation/20261004-200716-423/WhistleRanch-test.exe`。通常の実行中ゲームや `build/WhistleRanch.exe` は終了/再起動/上書きしていない。
- 隔離GPU **27項目成功**。NVIDIA GeForce RTX 4070 SUPER / OpenGL互換描画。等倍と拡大画面を目視し、サイズ比、接地、左右向き、選択範囲、白縁/ぼけ/旧描画重複なしを確認。睡眠から起床でZzzも消える。
- 描画ウィンドウ2つが、起動したPIDの専用desktopに所属することを確認。非対話station、終了0、タイムアウトなし。ユーザーのウィンドウやOS入力を調べたり操作したりしていない。

根拠：[観察要約](stage1-observation.json)、[フレーム/入力観察](character-observation.json)、[GPU隔離監査](isolated-render.json)、[描画ログ](isolated-render.log)、[headless/出力起動監査](validation-launches.jsonl)、[再実行方法と必要条件](../../../tools/SAFE_RENDER.md)。

## 未確認・残る点

- 正式な歩行/寝入り/休息/起床44コマの速度・状態同期は未取込。現在の仮睡眠の横倒し表現を完成アニメと扱わない。
- 本・露店・壁接続の新素材、実スピーカー聴感、人間の長時間試遊は今回の確認対象外。
- 隔離描画はこのWindows/GPU環境で確認。他環境で非対話stationの権限やOpenGL初期化が不足する場合は停止し、対応ドライバまたは隔離テストマシンが必要。
- 調査中に名前付きstationの権限不足、ウィンドウ所属監査の検出方法、終了時の空desktop列挙を修正した。最終実行は非対話確認を通過。安全でない通常GUIへのフォールバックはしていない。

## 起動先の整理（追加）

通常起動はプロジェクト直下の **Play.cmd** → `build/WhistleRanch.exe` に統一。現行配布EXEのビルドは **41e6e8f**（dirty=false）。上記の描画検証後に変えたのは起動/ビルド手順と文書のみで、ゲーム本体の仕様は同じ。

`dev.ps1 build` はWindows export / headless smoke成功後に通常版を更新する。起動中の通常ゲームがあれば更新を拒否し、終了や再起動を行わない。`check` / `visual` は通常版を更新しない。旧エンジン直接起動への暗黙フォールバックは廃止。

[配布EXEのSHA256と元コミット](launch-build.json) / [今回の出力・起動検査](launch-validation.jsonl)。検証EXEとのバイト一致を確認済み。Play.cmd自体を実行してゲーム画面を開く確認は行っていない。

ユーザーの依頼で古い `artifacts/` 出力約712MBと空フォルダ4つを整理。最新検証1回分、通常版、素材、ソース、通常セーブ、保存済みレビューは維持。[削除記録](cleanup.json)。本書の以前の `artifacts/...` 参照は検証当時の場所であり、古い生データは削除済み。`characters/` の証拠と監査記録はそのまま残す。
