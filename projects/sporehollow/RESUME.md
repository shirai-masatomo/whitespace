# 再開記録

更新：2026-10-08。配布済み3bc0644は固定し、F1を別領域で継続。今回の評価は [BALANCE_AUDIT](review/quality-roadmap/BALANCE_AUDIT.md)、限定検証は [CHECK](review/quality-roadmap/CHECK.md)。このcloneには未配布の修正がある。

## 保護境界

- 作業clone：`C:/Users/masat/Documents/Codex/2026-10-08/task/whitespace-balance-audit`
- branch：`codex/sporehollow-balance-audit`。開始点3bc0644、その後は `git log -1` で取得する。
- 固定配布元：`task/whitespace-quality` / 3bc0644。`projects/sporehollow/artifacts/playtest/20261008-192531-672` を上書きしない。EXE SHA256 `E8BE70D259AF7A0DAE2D6372EF8B29BF6AFCD11CF59E3C0039865F4628D52E75`。
- originは **固定配布元のローカルrepo**。push禁止。ゲーム変更のリモートpush/merge/公開は許可されていない。
- 元repo：`C:/Users/masat/Documents/codex_test`。通常EXE8b06e28、review/current0d47970。使用中のゲーム、未コミット変更、セーブ、デスクトップ、音声を妨げない。
- 元repoの新しい `projects/sporehollow/bgm/Porch_Swing_Serenade.mp3` はユーザー提供。読み取りコピーだけ行い、SHA256一致。通常保存へは接続していない。
- 別許可の掃除clone `task/whitespace-review-cleanup` はコミット28a8220、Draft PR https://github.com/shirai-masatomo/whitespace/pull/4。重複画像50件と参照文書だけ。マージなし。ゲームbranchと無関係。

## 次の作業

`git status --short` と `git log -4`、[TASKS](TASKS.md)を読む。未コミット変更を消さず引き継ぐ。再clone/元repoへのコピー/古い仕様の重複実装はしない。

A〜Eの全体試遊版3bc0644を配布済み。F1は既存9条件の4敗北をすべて再現し、同じ敗北朝からの誘導＋修理で4件とも当夜成功。像被弾通知と全周壁の進行停止だけを限定修正した。新EXEは出力していない。

次は `artifacts/balance-fixtures/failure-31-gold_once.sav` の朝から、誘導到着・20秒中断・修理再予約の短い隔離UI確認。4条件の前日までや9全条件を再実行しない。自然な勝敗・操作の技術合格・人間の面白さを別記録にする。数値や機能を一括変更しない。

## 実行・証拠

今回の軽量runnerは `task/run_balance_audit.ps1 -Script tests/test_idol_response.gd`。Godot実行ファイルだけ固定cloneから借り、--pathと保存先はこのclone専用。スクリプト省略は4敗北の前日までを再計算するため避ける。最終6スイート196検査は `artifacts/balance-audit/20261008-195938-413` から `20261008-195947-707`。修正前の朝保存4件とJSON一次証拠はBALANCE_AUDIT参照。

通常headlessは `./dev.ps1 -Task test -Suites @('対象名')`。節目の全回帰は `./dev.ps1 -Task test`、自然通しは `-Suites @('campaign_play')`。各runは専用APPDATA/LOCALAPPDATAとBelowNormal優先度。Godotは1プロセスずつ。

描画は `./tools/isolated_visual.ps1 -Scenario ...` のprivate非対話デスクトップだけ。wall_drag/journal_layout_ui/playthrough_ui/morning_saveが新UIの対象。Dummy audio、ユーザーのカーソル/ウィンドウ/入力は触らない。

全出力は `./tools/export_isolated.ps1`、日時別 `artifacts/playtest/`。正常時BUILD.json/README.md/Play-Isolated.cmdとSHA256が出る。自動headless smokeだけで実人間試遊の合格とはしない。通常Play.cmd、EXE直接起動、`dev -Task build` は使わない。

Windows sandbox通常実行はhelper_unknown_errorのためrequire_escalatedを自動承認レビューに通した。拒否なし。PowerShellはUTF-8出力、rgなしのためgit grep/Select-Stringを利用。dev.ps1の例外とログfailures=0を正本にし、残存LASTEXITCODEだけで判定しない。

Godot importの追跡.import差分は大量の改行変換だけが発生する。`git -c core.safecrlf=false diff --numstat -- ':(glob)projects/sporehollow/**/*.import'` が空と確認した追跡分だけ、コミット直前にrestoreする。新規MP3.importは必要な新規assetで保持。原本や他作業者の.importへ触れない。

artifactsはGit管理外のローカル検証証拠。削除しない。参照画像の403に対して署名URLを再利用/手書きしない。新規ゲームbranchの公開、購入、破壊的変更、重大な方向変更だけ親へ相談する。
