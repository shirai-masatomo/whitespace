# 撮影失敗の原因と修正（2026-10-12）

**原因は撮影ランナーの誤り。配布用release EXEへ非対応の `--script` を渡していた。** GPU隔離の失敗や、ゲーム自体のフリーズではなかった。

同じ非対話station/専用desktop、OpenGL・Dummy音声・30fpsで実測：

| 起動経路 | 結果 |
|---|---|
| 配布EXE＋最小外部スクリプト | 初期化のファイル記録なし。通常ゲームのウィンドウが起動し続け、20秒でtimeout |
| 開発用Godot＋同じ最小スクリプト | 初期化/描画/PNG保存、exit0 |
| 開発用Godot＋今回のゲーム撮影スクリプト | 初期化から8画面のPNG保存/正常終了まで約7秒、exit0 |

ローカルGodot4.7.2の `--help` を両方確認。開発版では `--script` がX分類、配布release版には存在しない。Xはeditor buildまたは `disable_path_overrides=false` で構築したexport templateのみ。[Godot公式CLI仕様](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)でも、未対応引数は警告なしに無視すると明記。標準release版で撮影/終了スクリプトが始まらず、外側の待機上限まで通常ゲームが続いたことがtimeoutの原因。

最初はbeforeとして旧EXEへこれを指定して失敗し、after撮影へ到達しなかった。さらにこれを隔離環境全体の問題と扱い、EXE反映まで止めた判断が不適切だった。通常EXEは別の組込み起動/終了/再開検証を通し、既にbf6eeeaへ更新済み。

修正：`tools/review_integrated_visual.ps1`を開発用Godotと明示project pathへ限定。CLI対応を起動前確認。途中段階をファイルへ即時保存し、PNG保存失敗/枚数不足も検出。beforeとして現行EXEを古いa16def5と偽って撮るhardcodeも除去。古いEXEでの同条件beforeは未取得のまま。

診断は[監査原本](verification/render-diagnosis.json)。画面は[今回の8枚](SCREENS_INTEGRATED.md)。実ゲームcodeは配布版と同じで、変更は撮影/診断用だけ。人物/鶏/猫/岩連結は明記したfixture。初期物資とUIの画素は確認したが、人間の快適さ/長時間試遊の合格とは分ける。

撮影で見つかった別課題：動物表は3行目が部分的に隠れ、見出しと列位置にもずれがある。連結岩は採用参考の自然さ/描込みにまだ差がある。今回は原因究明の範囲で記録し、完了扱いにしない。
