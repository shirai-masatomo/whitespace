# 関連検証

実装 `260923924abe952f4ff2befe61831c80f8ab6e77`。ゲーム素材 `3229d2655e35e82d178577cdd8acbbe66e9be4f8`。通常のユーザーデータは読み書きせず専用APPDATAで検証。

| 記録 | 合格/確認数 |
|---|---:|
| [biome-compat.json](biome-compat.json) | 21/21 |
| [integrated-input.json](integrated-input.json) | 29/29 |
| [integrated-work.json](integrated-work.json) | 30/30 |
| [lifecycle-close-entry.json](lifecycle-close-entry.json) | 2/2 |
| [lifecycle-large-close-entry.json](lifecycle-large-close-entry.json) | 2/2 |
| [lifecycle-large-resume-entry.json](lifecycle-large-resume-entry.json) | 3/3 |
| [lifecycle-resume-entry.json](lifecycle-resume-entry.json) | 3/3 |
| [map-actions.json](map-actions.json) | 7/7 |
| [map-expansion.json](map-expansion.json) | 18/18 |
| [map-storage.json](map-storage.json) | 15/15 |
| [mountains.json](mountains.json) | 58/58 |
| [quality-ledger.json](quality-ledger.json) | 15/15 |
| [GPU入力・描画](ui-survey.json) | 87/87 |

計290項目。JSONのチェック単位であり、全ゲーム機能の網羅率ではありません。[各記録の実装版](test-provenance.json)を併記。物流・採掘の関連回帰はa1dffa9で通過し、その後の差分は物資選択情報の表示と再開検証fixtureの初期条件整理。最終版では関係する入力・GPU・新規保存・EXEの新旧保存復帰を再検証し、無関係な大量反復はしていません。

- map-expansion：3seedの6800セル、中央配置、8方向の端、侵入・退却経路、新規保存と実在する旧50×34保存の互換。
- map-actions：旧範囲外の現地運搬→壁・ドア完成、実際の敵対物攻撃による壁破壊、経路・ゾーン更新。
- map-storage：39個使用済みのセルへ1個だけ搬入、空き39なら8個、満杯待機、拡張／消費／受入許可で再評価、複数備蓄、同種優先、2人の容量予約、携行中保存と再開、数量保存。
- integrated-input／GPU：GodotのInputEventを入力経路へ送信。命令ホイール、Ctrlズーム、ボタン上右クリック、対象動物、共通指示、一覧スクロール、非表示キューを確認。
- integrated-work／quality-ledger：既存の配送・施工・役割・禁止・資材台帳の関連回帰。
- lifecycleとlifecycle-large：配布EXEの通常終了ハンドラ→別プロセスで自動保存復帰→世界tick再開。旧50×34、新100×68それぞれ5項目。地形・山・壁・床・物資・仕事を含めて比較。
- export-smoke：Windows exportの起動・正常終了。EXEはDELIVERY.jsonのSHA256と一致。

再開試験の初回は新規fixtureだけ比較不一致。未読の導入説明を再開側の検証操作が閉じ、既存のStoryView.closeが既読・朝記録を更新したことによる初期条件差。fixtureを既読状態にしてから保存し、同条件の再開を検証し直しました。表示・保存の不一致を隠すため比較対象を削る処理はしていません。

関連一式の再現：`./dev.ps1 -Task build -Suites map_expansion,biome_compat,map_actions,map_storage,integrated_input,quality_ledger,integrated_work,mountains`。最後の表示差分は `-Suites map_expansion,integrated_input`。画像は別工程で `./tools/review_ui_survey.ps1 -MapExpansion`。

限界：OSの物理マウス／キーボード、人間の長時間の快適さ、実音、多数住人・多数敵での性能は未判定。固定条件の自動入力・技術試験と区別します。
