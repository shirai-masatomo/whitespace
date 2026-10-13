# 現在：診断撤去・保存機能なし

ユーザーのPC全体の停止報告と撤去指示を受け、診断前 a519450 の描画・音声・ローディングに戻した。保存／読込／自動保存も撤去し、起動は毎回新規。

- headless検査・ビルド結果：[verification/last-run.json](verification/last-run.json)
- EXE対応：[verification/session-only-delivery.json](verification/session-only-delivery.json)
- 過去の診断結果：[performance-diagnosis/REPORT.md](performance-diagnosis/REPORT.md)（撤去済み。現在の起動手順には使わない）

通常画面・GPUを使った検査は実施しない。フリーズの原因と解消は未確認。以前のセーブファイルは残すが、ゲームから読み書きしない。ゲーム内進行とUI設定は維持。
