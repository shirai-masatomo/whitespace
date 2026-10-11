# ホイッスル牧場 — AI・戦闘・情報表示の品質定点（2026-10-08）

実装 **0d47970eb10c707d51c60ea9b961e4781f21f215**、素材 **a34390e584037cef78c9f49dcec4b18bd44f6f3d**。開始HEAD209d370から更新。後続レビュー保存コミットはゲーム内容を変えない。

起動は **[Play.cmd](../../Play.cmd)**。ESCの版表示 `0d47970`。[EXE・SHA対応](revision-0d47970/build.json)。検証済みWindows版へ更新済み、自動起動なし。

- [代表5画面と見る点](revision-0d47970/SCREENS.md)
- [変更・仮決定・未確認事項](revision-0d47970/REVIEW.md)
- [実入力/画面観察](revision-0d47970/observations.json) / [非対話GPU監査](revision-0d47970/isolation.json)
- [戦闘・増援・療養80検査](revision-0d47970/quality-tests.json)
- [検証範囲](revision-0d47970/verification.json) / [関連ログ](revision-0d47970/logs) / [限定AI12](revision-0d47970/evaluation.json)

敵Skillを共通データ化し、図鑑8枠/Rarity/Hoverを整理。舞姫の有限支援、敵メイド/陣営対応/特殊仲間化、被弾救出、誘拐猶予後の緩やかな療養、戦闘不能時の標的切替を統合。群生森、Human描画1.15、数字速度、牧場主の図鑑/持ち物、最新6件イベントも反映。

関連25スイートを段階確認、最終SHAで影響する7スイート435検査、限定AI12試行、隔離GPU19検査/5PNG、Windows出力/headless起動を確認。静止画は制御fixtureで、戦闘の時間経過は決定的シミュレーションと区別。大量撮影/AI192は行っていない。

人間レビュー：森の群れ方、Humanサイズ、舞と近接の循環、増援の到着、敵メイド、Down後の標的、療養の安全性、図鑑とログの読みやすさ。数日試遊/物理配列/IMEは未確認。不足する正式Skill Icon/気絶SpriteはART_SPECへ記録。

過去証拠は[前定点](HISTORY-before-0d47970.md)に保持し、今回の証拠へ流用しない。
