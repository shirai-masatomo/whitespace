# 再開記録

## 再接続後の引き継ぎ完了（2026-10-09 UTC）

最新試遊版：[Play-Isolated.cmd](artifacts/playtest/20261009-020437-216/Play-Isolated.cmd)。ゲーム本体 **002f3cb6ca788ee9c85539570c929b56fc84adc8**、出力時dirty=false。EXE SHA256 **FBB8A7AAD1D04700586B8A525E388EF3ADFE6D508B26B3120F4900D366698B4B**。識別情報は同梱 [BUILD.json](artifacts/playtest/20261009-020437-216/BUILD.json)。この後の引き継ぎコミットは文書とテストUIDだけで、EXEを再出力していない。

出力・smokeと専用保存先での実EXE起動は前回成功済み。[保存検証記録](artifacts/export-verification/20261009-020601-469/verification.json) はWRM1朝保存作成、検証済み5日目朝の再読込・保持、旧3版の12＋14＋14＝40ファイル一致を記録している。起動はheadless/Dummy・独立user-dataで、通常セーブや対話画面は使っていない。試遊用user-dataへ5日目fixtureを移していない。

今回の再接続では、残差分が `test_crowd_budget.gd.uid` / `test_morning_layout_ui.gd.uid` / `test_shop_readability_ui.gd.uid` / `test_wounded_idle.gd.uid` の4件だけであることを確認。全て追跡済みスクリプトのGodot生成識別子で、既存のUID追跡方針に合わせて保存した。コード変更、801検査の再実行、GPU描画、再出力はしていない。Uncommonなど英語表記を維持。接続切断で残っていた資料更新を完了した。

次はROADMAPのF：この版の朝→店→図鑑、負傷復帰後の8秒、入口と代表1夜を人間が試遊し、読みやすさ・敗因の理解・次の行動を確認する。一つの問題へ絞って修正し、必要な固定条件だけ比較する。実聴感、物理IME、実時間長期、クリーンWindowsは未完。以下のF2以前の版と記録は履歴であり、最新起動先は上記。

## 最新：朝画面・読みやすさ・負傷休息（2026-10-08 UTC）

[LAYOUT_REVIEW](review/quality-roadmap/LAYOUT_REVIEW.md) に画像照合・修正範囲・証拠を記録。朝の紙面と下段ボタンを共通配置へ、ショップの吹き出しを統一、英語レア度を実測幅で表示。名称の翻訳はしていない。負傷した主人公は、仕事0件の復帰保留でも安全な8秒の無操作後に休む。予約仕事と明示停止は保持。通常の休息は5秒でHP+1。

関連8スイート801検査・失敗0、UIは3解像度で隔離描画確認。敵の確率・条件・時間は [ENEMIES](ENEMIES.md) 冒頭へ整理し、従来の設計メモは末尾に分けた。敵の能力値や抽選確率は変更していない。通常ゲーム・保存・デスクトップ入力は未使用、push/merge/公開なし。

次は新しい分離試遊版で朝→店→図鑑と負傷復帰の待ち方を確認し、一つの報告に絞って改善する。面白さ・実聴感・IME・実時間長期・クリーンWindowsは未評価。以下のF2以前の記述は履歴。

## 最新の引き継ぎ：F2

人数内AI性能も完了：`artifacts/balance-audit/20261009-003056-834`、[CROWD_PERFORMANCE](review/quality-roadmap/CROWD_PERFORMANCE.md)。通常上限11体/デバッグ22体を各一回、31検査・失敗0、全員入場。AI最大49.098/73.829ms、固定tick250ms超過0。22体で入場前静止17秒があるため、滑らかさや待ち方の体験合格は未宣言。ゲーム変更/再出力なし、配布14ファイル一致、セッション48346回収済み。今回の自動確認はここで区切り、同じ試験や巨大負荷を繰り返さない。新報告がなければ人間試遊・実聴感・実画面の引っ掛かり確認へ進む。以下の「大群未完」はこの限定測定以前の履歴であり、22体を超える一般性能を保証するものでもない。

追加確認：新経路50f66c9で13〜30夜を一回だけ通し、228検査・失敗0、18夜成功。`artifacts/balance-audit/20261009-001139-298/summary.json`。55体が新経路を使用して到着処理完了、夜終了時と翌朝の有効な入口割当残留0、朝保存/再起動一致。81ゲーム内分を41.907秒で実行した加速試験であり実時間放置ではない。配布14ファイルはハッシュ一致。セッション30428回収済み。検査の読み取り観測と文書だけを追加し、ゲーム変更/再出力なし。後続コミットにはこの追加検査記録も含む。繰り返さず、次は下記の人間評価項目へ進む。

2026-10-08。入口分散/メイド初回入場/像接触先、自動休息8秒、BGMフェードを実装・関連検証済み。[CONTINUITY_REVIEW](review/quality-roadmap/CONTINUITY_REVIEW.md)、[ENEMY_AI_REVIEW](review/quality-roadmap/ENEMY_AI_REVIEW.md)、CHECK末尾を読む。以下のF1記録は履歴として保持する。

作業場所とbranchは下記と同じ。現在のHEADは `git log -1` で取得。新たな素材を作成・移動していない。確認済みユーザー画像1枚だけは明示指示に従いWindowsごみ箱へ移動済み。Library403の再試行/迂回は禁止されたため行っていない。

最終待機セッション29956は回収済み。入口22検査とstory52検査に失敗・SCRIPT ERRORなし。二重実行しない。今回採用した関連499検査、旧f96467a本体の18夜連続191検査は区別する。通常版の保存・画面・プロセスを検査対象にしない。

最新試遊版：`artifacts/playtest/20261008-234821-898/Play-Isolated.cmd`。本体コミット **50f66c967a91fdfd26b1d0269c316ac452972841**、dirty=false。EXE SHA256 **058E1959B1FBDDFB4B84A94A3AD1885B6EC0F25A7B6361C5BC9C66A622BD09C7**。その後のコミットは出力記録・Godot生成UIDだけで本体の変更はない。

出力/--smoke成功後、`artifacts/export-verification/20261008-235034-897` の専用保存先で実EXEを通常起動。WRM1朝保存作成→検証済み5日目朝を置く→二度目の通常起動で保存保持を確認。試遊版のuser-dataへテスト用セーブを入れていない。固定f96467a14ファイルと3bc0644の12ファイルのハッシュ一致。起動検証セッション90617も回収済み。

次は同じ停止配置と代表1夜の人間試遊で、入口1つの場合の探索の遠回り、敵到達時刻、8秒休息、BGMの聴感を確認する。9条件の全再実行や難度緩和を先にしない。新しい報告が入口以外の停止なら、状態名/役割/周囲の占有/秒数を小さな固定fixtureにする。長時間の実時間試験、大群CPU、IME、クリーンWindowsは別の未完項目。

更新：2026-10-08。旧3bc0644は固定し、修正版f96467aを別出力済み。F1の評価を一区切りにした。[BALANCE_AUDIT](review/quality-roadmap/BALANCE_AUDIT.md)、[DAY5_REVIEW](review/quality-roadmap/DAY5_REVIEW.md)、[CHECK](review/quality-roadmap/CHECK.md)を読む。

## 保護境界

- 作業clone：`C:/Users/masat/Documents/Codex/2026-10-08/task/whitespace-balance-audit`
- branch：`codex/sporehollow-balance-audit`。開始点3bc0644、その後は `git log -1` で取得する。
- 固定配布元：`task/whitespace-quality` / 3bc0644。`projects/sporehollow/artifacts/playtest/20261008-192531-672` を上書きしない。EXE SHA256 `E8BE70D259AF7A0DAE2D6372EF8B29BF6AFCD11CF59E3C0039865F4628D52E75`。
- 新しい修正版：このcloneの `projects/sporehollow/artifacts/playtest/20261008-200838-402/Play-Isolated.cmd`。ゲームcommit f96467a、SHA256 `52A973082FFBCE174EA682059178226E8F49D903CF65E29C50369F3BFB4BE160`。新旧のuser-dataは別。勝手にセーブを移行しない。評価用の追加コミットはテスト/ツール/文書だけで、EXEの本体はf96467a。
- originは **固定配布元のローカルrepo**。push禁止。ゲーム変更のリモートpush/merge/公開は許可されていない。
- 元repo：`C:/Users/masat/Documents/codex_test`。通常EXE8b06e28、review/current0d47970。使用中のゲーム、未コミット変更、セーブ、デスクトップ、音声を妨げない。
- 元repoの新しい `projects/sporehollow/bgm/Porch_Swing_Serenade.mp3` はユーザー提供。読み取りコピーだけ行い、SHA256一致。通常保存へは接続していない。
- 別許可の掃除clone `task/whitespace-review-cleanup` はコミット28a8220、Draft PR https://github.com/shirai-masatomo/whitespace/pull/4。重複画像50件と参照文書だけ。マージなし。ゲームbranchと無関係。

## 次の作業

`git status --short` と `git log -4`、[TASKS](TASKS.md)を読む。未コミット変更を消さず引き継ぐ。再clone/元repoへのコピー/古い仕様の重複実装はしない。

A〜Eの全体試遊版3bc0644を配布済み。F1は既存9条件の4敗北をすべて再現し、同じ敗北朝からの誘導＋修理で4件とも当夜成功。像被弾通知と全周壁の進行停止だけを限定修正し、f96467aの新EXEを別フォルダへ提供した。

`artifacts/balance-fixtures/failure-31-gold_once.sav` の朝からの誘導到着・20秒中断・修理再予約のUI確認は26検査/隔離5画面で完了。重大な追加問題なし。ここでF1を区切る。次はユーザーの試遊で困った日・祈り・配置・対処の余地を照合し、必要な1項目だけ改善する。フィードバックなしの細かい数値調整や全9条件の再実行はしない。長時間/IME/聴感/クリーンWindows/面白さなど完成条件は引き続き未完。

## 実行・証拠

新出力スモーク：`artifacts/export-verification/20261008-201313-186`。5日目UI：headless `artifacts/balance-audit/20261008-202014-228`、GPU `artifacts/isolated/20261008-202156-040`。同じ26検査を二方式で確認し、52種類とは数えない。再現は `./tools/isolated_visual.ps1 -Scenario day5_defense_ui`、既に合格済みなので必要な変更時だけ使う。

今回の軽量runnerは `task/run_balance_audit.ps1 -Script tests/test_idol_response.gd`。Godot実行ファイルだけ固定cloneから借り、--pathと保存先はこのclone専用。スクリプト省略は4敗北の前日までを再計算するため避ける。最終6スイート196検査は `artifacts/balance-audit/20261008-195938-413` から `20261008-195947-707`。修正前の朝保存4件とJSON一次証拠はBALANCE_AUDIT参照。

通常headlessは `./dev.ps1 -Task test -Suites @('対象名')`。節目の全回帰は `./dev.ps1 -Task test`、自然通しは `-Suites @('campaign_play')`。各runは専用APPDATA/LOCALAPPDATAとBelowNormal優先度。Godotは1プロセスずつ。

描画は `./tools/isolated_visual.ps1 -Scenario ...` のprivate非対話デスクトップだけ。wall_drag/journal_layout_ui/playthrough_ui/morning_saveが新UIの対象。Dummy audio、ユーザーのカーソル/ウィンドウ/入力は触らない。

全出力は `./tools/export_isolated.ps1`、日時別 `artifacts/playtest/`。正常時BUILD.json/README.md/Play-Isolated.cmdとSHA256が出る。自動headless smokeだけで実人間試遊の合格とはしない。通常Play.cmd、EXE直接起動、`dev -Task build` は使わない。

Windows sandbox通常実行はhelper_unknown_errorのためrequire_escalatedを自動承認レビューに通した。拒否なし。PowerShellはUTF-8出力、rgなしのためgit grep/Select-Stringを利用。dev.ps1の例外とログfailures=0を正本にし、残存LASTEXITCODEだけで判定しない。

Godot importの追跡.import差分は大量の改行変換だけが発生する。`git -c core.safecrlf=false diff --numstat -- ':(glob)projects/sporehollow/**/*.import'` が空と確認した追跡分だけ、コミット直前にrestoreする。新規MP3.importは必要な新規assetで保持。原本や他作業者の.importへ触れない。

artifactsはGit管理外のローカル検証証拠。削除しない。参照画像の403に対して署名URLを再利用/手書きしない。新規ゲームbranchの公開、購入、破壊的変更、重大な方向変更だけ親へ相談する。
