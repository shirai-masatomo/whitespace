# 再開記録

更新：2026-10-08。全体の仮完成版を接続し、隔離出力の節目へ。最新結果と出力場所は [CHECK](review/quality-roadmap/CHECK.md) と `artifacts/quality-roadmap/verification.json`。

## 保護境界

- 作業clone：`C:/Users/masat/Documents/Codex/2026-10-08/task/whitespace-quality`
- branch：`codex/sporehollow-quality-roadmap`。監査元6017608、祈り76d189c、経路ba7c86b、到達点d897d57、保存75bbaa0、成長/保存改善98df31e。その後の操作/回復/BGMは最新の `git log -1` で取得する。
- originは **元作業者のローカルrepo**。push禁止。ゲーム変更のリモートpush/merge/公開は許可されていない。
- 元repo：`C:/Users/masat/Documents/codex_test`。通常EXE8b06e28、review/current0d47970。使用中のゲーム、未コミット変更、セーブ、デスクトップ、音声を妨げない。
- 元repoの新しい `projects/sporehollow/bgm/Porch_Swing_Serenade.mp3` はユーザー提供。読み取りコピーだけ行い、SHA256一致。通常保存へは接続していない。
- 別許可の掃除clone `task/whitespace-review-cleanup` はコミット28a8220、Draft PR https://github.com/shirai-masatomo/whitespace/pull/4。重複画像50件と参照文書だけ。マージなし。ゲームbranchと無関係。

## 次の作業

`git status --short` と `git log -4`、[TASKS](TASKS.md)を読む。未コミット変更を消さず引き継ぐ。再clone/元repoへのコピー/古い仕様の重複実装はしない。

A/B/C/Dの基礎接続は完了。壁ドラッグ、図鑑、動物指示、回復、昼BGMを含む全体版をEとして出力する。既に新しい出力がCHECKにあれば再出力せず、それをF1の固定比較へ使う。未完ならコード・検証結果を確認して出力を終える。最初の中間版76d189cは最新ではない。

F1は像防衛/祈り反作用の代表1ケース比較。自然通しの勝敗、操作シナリオの技術合格、人間の面白さを別記録にする。最大限の機能追加や全数値の一括調整をしない。詳細の順序と合格条件はTASKS/ROADMAP。

## 実行・証拠

通常headlessは `./dev.ps1 -Task test -Suites @('対象名')`。節目の全回帰は `./dev.ps1 -Task test`、自然通しは `-Suites @('campaign_play')`。各runは専用APPDATA/LOCALAPPDATAとBelowNormal優先度。Godotは1プロセスずつ。

描画は `./tools/isolated_visual.ps1 -Scenario ...` のprivate非対話デスクトップだけ。wall_drag/journal_layout_ui/playthrough_ui/morning_saveが新UIの対象。Dummy audio、ユーザーのカーソル/ウィンドウ/入力は触らない。

全出力は `./tools/export_isolated.ps1`、日時別 `artifacts/playtest/`。正常時BUILD.json/README.md/Play-Isolated.cmdとSHA256が出る。自動headless smokeだけで実人間試遊の合格とはしない。通常Play.cmd、EXE直接起動、`dev -Task build` は使わない。

Windows sandbox通常実行はhelper_unknown_errorのためrequire_escalatedを自動承認レビューに通した。拒否なし。PowerShellはUTF-8出力、rgなしのためgit grep/Select-Stringを利用。dev.ps1の例外とログfailures=0を正本にし、残存LASTEXITCODEだけで判定しない。

Godot importの追跡.import差分は大量の改行変換だけが発生する。`git -c core.safecrlf=false diff --numstat -- ':(glob)projects/sporehollow/**/*.import'` が空と確認した追跡分だけ、コミット直前にrestoreする。新規MP3.importは必要な新規assetで保持。原本や他作業者の.importへ触れない。

artifactsはGit管理外のローカル検証証拠。削除しない。参照画像の403に対して署名URLを再利用/手書きしない。新規ゲームbranchの公開、購入、破壊的変更、重大な方向変更だけ親へ相談する。
