# ホイッスル牧場 — 採用画像/G〜M 定点（2026-10-08）

実装 **f6a60ee525cbe63d962a06280a7d7a9533d69d66**、ゲーム変更 **377090cd89971f2147ee224fb964afe2f3884303**、素材 **a34390e584037cef78c9f49dcec4b18bd44f6f3d**。f6a60eeは撮影フィクスチャの位置調整のみ。後続のレビュー保存コミットはゲーム内容を変えない。

起動は **[Play.cmd](../../Play.cmd)**。ESCの版表示 `f6a60ee`。[EXE・SHA対応](revision-f6a60ee/build.json)。検証済みWindows版へ更新済み、自動起動はしていない。

- [代表3画面](revision-f6a60ee/SCREENS.md)
- [変更・仮決定・未完了](revision-f6a60ee/REVIEW.md)
- [実入力/画面観察](revision-f6a60ee/observations.json) / [非対話GPU監査](revision-f6a60ee/isolation.json)
- [検証範囲](revision-f6a60ee/verification.json) / [ログ](revision-f6a60ee/logs)
- [採用素材・SHA256](../../game/direction_receipt.json) / [正式モーション](../../game/motion_receipt.json)

鉄球/構え/蹴り/飛翔部品、森、6種Portrait、レアリティ/スキル画像を接続。メイド・舞姫・盗賊・乳牛・闘牛、こけし・化石を実装。新規5キャラクターは納品済み静止画/キーポーズを使用し、未納品の連続動作を完成扱いにしない。恐竜復活は保留。

23スイート、限定AI12試行、関連113検査、隔離GPU20検査/3PNG、Windows出力/headless起動を確認。AIは統計的バランス評価ではない。画像は制御フィクスチャで、人間の通しプレイ記録ではない。

過去の通常操作/UI証拠は[前定点](HISTORY-before-f6a60ee.md)に保持。現在のTab/Shift/Wheel・朝昼夜・既存ゲーム操作は維持。以前の画像を今回の証拠には流用していない。
