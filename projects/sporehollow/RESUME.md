# 電源断・会話再開時の記録

更新：2026-10-08、描画/探索修正の検証完了時点。作業停止の指示ではない。OS自動起動や設定は変更していない。

## 再開場所

- 専用clone：`C:/Users/masat/Documents/Codex/2026-10-08/task/whitespace-quality`
- ブランチ：`codex/sporehollow-quality-roadmap`
- 元実装：6017608。祈り/役割変更：76d189c。最新チェックポイントはこの記録を含むローカルコミット（`git log -1`で取得）。
- `origin`はGitHubではなく **元作業者のローカルrepo**。`git push origin`を実行しない。
- 元作業者：`C:/Users/masat/Documents/codex_test`。通常EXE8b06e28、既存review/current0d47970。ファイル、ゲーム、通常セーブを変更・終了しない。

## 保存済み・検証済み

ロードマップ、カテゴリ祈り、主人公ダウン中の役割別ターゲットを実装。人間型敵を絶対1.3倍、森の地面による切断/前後関係を修正、外周を群れとして増密。猫の袋小路/敵の局所回避/探索目標の毎tick破棄/像接近不能を再現して根本修正。

祈り関連482検査。描画/経路の関連13スイート1038検査、最後の限定39検査（navigation23/forest9/UI7）、隔離描画7検査/3画面は失敗0。詳しくは [CHECK](review/quality-roadmap/CHECK.md) と `artifacts/quality-roadmap/verification.json`。最終描画は `artifacts/isolated/20261008-170516-916/`、比較元は `20261008-163142-550/`。

既知の難度観察：固定seed31・同じ自動操作の8日生存目標は未達（修正後4日目敗北）。技術的進行停止とは分けて記録。未検証は人間試遊/物理キーボード/音声/長時間。初期完成や全体仮完成とは呼ばない。

既存の分離試遊版は **76d189c時点**の `artifacts/playtest/20261008-162638-452/Play-Isolated.cmd`。最新の描画/探索修正はこのEXEへ未出力。通常のPlay.cmdやEXE直接起動を使わず、専用CMDでデータを分離する。

## 次に行うこと

1. 再起動後は`git status --short`と`git log -3`を読む。未コミット変更があれば続きとして保護し、勝手にリセットしない。最初からcloneを作り直さない。
2. B1日数進行/仮到達点へ続ける。`encounters.gd`の最後の導入11日→次の既存節目15日を導出し、勝利後16日朝に区切りと続行/新規開始を表示。新たな金銭ボーナスや物語の結末は追加しない。
3. campaignへ一回性の達成記録。14日成功/15日敗北/15日成功/二重finish/再挑戦/朝再構成を比較。seed17/31/73と実UIの翌朝seed+1を検証。単なる固定seed通しを実UI同等と扱わない。
4. 次はB2の粗い成長・Cのカルマ・Dの朝保存。保存境界はdayを増やしnight_ready=falseとなるnext_campaignから作った朝。決済済みdawnの生campaignを再開保存しない。
5. 全体接続の節目で専用EXEを出力し、検証範囲と未完を明記する。通常は関連検証だけ。

## 再実行・操作しないもの

祈り/素材取り込み/死亡処理を重複実装しない。旧QA.jsonのruntime_verified=falseだけで素材を未統合扱いしない。既にある320PNGと搾乳動作は統合済み。

push、共有ブランチmerge、force push、履歴書換え、元repoのファイル削除、ユーザープロセス停止、通常user-dataでの試験、対話デスクトップ描画を行わない。GitHub掃除は50画像の重複監査だけで、反映は親の指示待ち。監査はタスク直下 `cleanup-audit/AUDIT.txt` と `candidates.json`。

PowerShellの通常sandbox実行はhelper_unknown_errorだったため、require_escalatedを自動承認レビューに通して実行した。拒否は受けていない。UTF-8出力を設定。`rg`は無く`git grep`を使う。検証はdev.ps1（専用APPDATA）、描画はtools/isolated_visual.ps1。dev.ps1の成功後もLASTEXITCODEに古い1が残る場合があるため、PowerShellの例外と各ログのfailures=0を確認する。

`artifacts/`はローカル証拠でGit管理外。電源断で消えないが、repo削除/再cloneだけでは引き継がれない。不要として削除しない。
