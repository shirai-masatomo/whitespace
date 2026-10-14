<!-- 2026-10-14に旧review/currentから移動。現行仕様は ../../../GAME_SPEC.md / ../../current/PACKET.md -->

# マップ動物の表示サイズ +25%（2026-10-12）

正式ソース `colony-structure-01-work/projects/sporehollow`、ブランチ `codex/sporehollow-biome01`、作業開始HEAD `eba972e01b995df85fd65e5a71e7c4e934b46094`。既存の最新開発版ショートカットの参照先とREADME/DEVELOPMENT/AGENTSを照合して継続利用。新しいソースコピー・EXE・ショートカットは作成していません。

## 変更

- `game/main.gd`：動物のマップ描画専用倍率1.25を追加。柴犬・猫・鶏は既存レンダラー全体へ追加倍率を掛け、柴犬の静止fallbackも現在比1.25に統一。牛・闘牛・ドーベルマン・ウシガエル・ハリネズミは従来1.25×追加1.25＝1.5625。左右・全アニメーション・敵側動物・死体・死亡演出・マップ上の誘導予告へ適用。
- `game/progression_art.gd`：ウシガエルの舌の口元ソケットを拡大後の身体へ合わせる。標的座標・射程・効果は維持。
- 足元を中心とする描画変換のみ。クリック判定、物理占有、移動、AI、人物、図鑑肖像、UI、影・ラベルは変更なし。mainの変更関数は `_draw`、`draw_pointer_preview`、`draw_enemy_actor`、`draw_animal_corpse`、`draw_animal_actor` の5つ。他の既存関数はHEADと一致。

## 検証

headless / Dummy音声 / 最大30fps / 直列 / 専用APPDATAで実施。通常デスクトップ・入力・保存は使っていません。

| 検証 | 結果 |
|---|---|
| 追加検証：倍率・足元座標計算、変更前mainを読み込んだ当たり判定比較 | 303項目成功、失敗0。左右の動物素材242フレームを含む |
| animal_commands | 39項目成功、失敗0 |
| six_motion | 422項目成功、失敗0 |
| progression_art | 549項目成功、失敗0 |
| animal_corpse | 24項目中22成功、2失敗 |
| headless import、git diff --check | 成功 |

死亡回復テストの失敗は「既存回復日の翌日に柴犬が活動可能」「回復後に通常ターゲット対象へ戻る」の2点。このテストから参照される46のGDScriptはHEADと同一で、今回変更した描画2ファイルを読み込まないことを確認しました。シミュレーション側の既存テスト課題として残しています。変更前EXEでの再試験や、この無関係な挙動の修正は実施していません。

[ログ・スコープ・保持確認](../../current/verification/last-run.json) / [死亡回復テスト依存比較](../../current/verification/animal-size-corpse-dependencies.json)

## 配布・残件

**ソース修正まで完了。通常EXEへ未反映、視覚確認は未実施。** 正式配布手順 `tools/publish_build.ps1` は `verify_cycle_entry09.ps1` による隔離GPU終了・再開検証が必須です。既に拒否されたWindow Station作成は再試行せず、通常GUIへの代替も行っていません。検証中に通常ゲームの起動も確認したため、停止・再起動・上書きしていません。

現行通常EXEは1本を維持。SHA256 `25141146DED2A167AE07652113342FFFAF7318A08BCC30814130C29FDDA75F6C` は前後一致。既存ショートカットはこのEXEを参照したまま。ビルド記録上の実装commitは `a16def5` / dirty=true。Gitコミット・push・main統合なし。

自分の固定検証領域 `artifacts/validation/current` は結果保存後に削除済み。通常ゲーム起動中のため標準安全ルールに従い新規import cache `.godot` 約15.71MiBは保持。既存素材メタデータ1491件は最後の検証前後でハッシュ一致。無関係なフォルダ削除なし。全体の容量増分は約15.4MiB（主にこのキャッシュ、レビュー記録の置換差を含む）。

次の安全な配布工程は、通常ゲーム終了後、隔離GPU検証を実行できる担当が既存 `dev.ps1 build` で候補ビルド→終了再開検証→同じEXEへ反映することです。今回の2失敗を合格扱いしないでください。

追記：候補EXEの正式エクスポートとheadless smokeは成功しました。通常EXEへは未反映。画像転送とGPU検証の阻害・再開手順は [HANDOFF](HANDOFF.md) を参照。
