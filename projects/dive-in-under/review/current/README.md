# Dive In Under — 通常0.8.0

いつもの「入口 / 01 ゲームを起動」から起動。リンク先の[Play.cmd](Play.cmd)は変更せず、build/current.txtを確認済み0.8.0へ更新した。起動中の旧プロセスは終了・置換していないため、新版を見る場合は一度終了して起動し直す。

- 版：**0.8.0**。実行ソース：`33b33a2cafaf086c497ef53d006baf8957f70dce`。
- [番号別の実画面・前後比較](../ui-feedback/exploration-flow-0.8.0/index.html) / [操作方法・クリック数](../ui-feedback/exploration-flow-0.8.0/OPERATIONS.md) / [確認・未確認](../ui-feedback/exploration-flow-0.8.0/README.md)。
- E＝主な肯定、I＝所持品・装備、C＝ステータス、Space＝自動戦闘停止／再開。右上地図をクリックで詳細地図。
- [CI39275995061](https://github.com/shirai-masatomo/whitespace/actions/runs/39275995061)成功。単一隔離EXE49,158ms・終了0、確認完了JSONあり。新規開始→1〜4F→装備交換→直接帰還→準備→再出発と固定境界を確認。
- [通常リリース記録・ハッシュ](local-release.json)。通常デスクトップのOS入力、他解像度、長時間、新UIでの全10F再走は未確認。既存の10F証拠を再利用。見た目・操作感のユーザー評価は未評価。

旧0.7.0のリリースフォルダ・ZIP・[記録](README-0.7.0.md)を保持。今回の中間候補も不変のフォルダ／アーカイブへ保持。セーブ、BGM、戦闘バランス、初期装備や死亡仕様、モデル設定は変更していない。ローカルPCでゲームを起動・負荷試験していない。
