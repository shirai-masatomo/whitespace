# 再開記録

## 現在の正本（2026-10-10）

開発正本は `whitespace-balance-audit/projects/sporehollow`、作業ブランチは `codex/sporehollow-balance-audit`。確認済み実装はc5c2833。最新のローカル試遊は `artifacts/playtest/20261010-034957-716/Play-Isolated.cmd`、通常プロジェクトの確認入口01が参照する。独立朝フェーズはなく昼開始。現在仕様は [TODAY_SPEC](review/quality-roadmap/TODAY_SPEC.md)、実装済み／未反映は [PROJECT_STATE](PROJECT_STATE.md)、次に扱う候補は [TASKS](TASKS.md)。

今回ユーザーが作業ブランチへの通常pushを承認。元のoriginはローカルコピーを向くため、GitHub `shirai-masatomo/whitespace` の同名作業ブランチへ明示的にpushする。mainへのマージは含めない。以下は当時の状態を残す過去記録で、古い「最新」・朝フェーズ・push禁止などを現在の指示として使用しない。

今回の配布：図鑑の名前あり／なしで画像枠・倍率・位置を統一。`確認入口/01_今回_図鑑画像枠統一_c5c2833.lnk` を追加し、01最新版も同じ版を指す。74項目の描画確認、固定ソースの正式出力、隔離GPU通常起動が成功。旧92d1048は `artifacts/playtest/20261010-034237-963` に保持。ユーザーの通常ゲームを停止せず、旧セーブも移動していない。

## 過去の引継ぎ記録

最新試遊：[20261010-000204-106](artifacts/playtest/20261010-000204-106/Play-Isolated.cmd)、実装 `912b987`。画像は[TODAY_GALLERY](review/quality-roadmap/TODAY_GALLERY.html)。

## 現在（2026-10-09引継ぎ）

今日の指摘分は[TODAY_REVIEW](review/quality-roadmap/TODAY_REVIEW.md)、確定/仮案は[TODAY_SPEC](review/quality-roadmap/TODAY_SPEC.md)。最新パッケージは確認入口01から。04c99ceと559a7fcを基準に保存済みの差分を統合し、巻き戻し・push・mergeなし。配布後は停止し、新しい作業はユーザーの指示を待つ。以下は過去の配布履歴。

## 過去の記録：連行入力の修正を完了（2026-10-09）

[Play-Isolated.cmd](artifacts/playtest/20261009-202008-469/Play-Isolated.cmd)。本体 **04c99ce642e4c49099c5c206e5580e346d42db55**、dirty=false。EXE SHA256 **A37D3C6A11423FF6402CBEF3AAE69EB0B4AE2D0A80F0D61BD501E64160EF2C88**。[BUILD.json](artifacts/playtest/20261009-202008-469/BUILD.json) / [専用保存での起動・再読込検証](artifacts/export-verification/20261009-202158-409/verification.json)。

[GUIDE_TARGET_REVIEW](review/quality-roadmap/GUIDE_TARGET_REVIEW.md) / [比較画像](review/quality-roadmap/GUIDE_TARGET_GALLERY.html)。連れてくの後に壁・鶏・黄金像を押すと予約前に別対象へ切り替わる不具合を修正。物の近くへ向かう既存の移動仕様を使い、指示対象の個体を保持。地面→壁→鶏→像→解除後に別対象を選択する一続きの場面で、全5予約が同じ犬で完了し、おまかせへ復帰した。通常選択も復帰可能。到着後の継続追跡や新機能は追加していない。

関連121検査・失敗0。最終隔離描画20261009-201524-261は終了0、ログエラーなし。途中のレビュー送信形式の誤りは記録に残し、同じ操作列を正常再実行した。新EXEをheadless/Dummyで通常起動しWRM1朝保存を作成、検証済み5日目朝保存の再読込・保持も成功。検証保存と試遊保存は別。旧試遊版の既知87ファイルと元repoの既存4ファイルはSHA256一致。確認入口01・02を更新。

**今回の範囲は完了。ここで停止し、新しい検証や機能を自動追加しない。** 次の未確認事項は **P1：人間試遊で連行モード・解除・救護優先と狙えの距離が理解できるか**。合格条件は対象変更の誤指示・取消の誤解がなく、救助場面で動物の行動理由を説明できること。P2は増援の接近待ちと夜明け境界の正式設計。面白さ・実音・物理IME・長時間・クリーンWindowsは未評価。通常ゲーム・保存・画面・音声は未使用。push／merge／公開なし。以下は過去時点の履歴。

最終保護確認：別途20:00に起動された旧試遊版20261009-194756-179（PID45912）が稼働中だったため、停止・入力・保存変更はしていない。今回の隔離描画・検証プロセスは終了済み。元repoのtemp/に追加された画像2件も未変更で保持した。最新ショートカットへの更新は起動中EXEを差し替えない。

## 過去の記録：混成戦の検証済み試遊版（2026-10-09）

[Play-Isolated.cmd](artifacts/playtest/20261009-194756-179/Play-Isolated.cmd)。本体 **b266a7ad4c4650fdfadb9a9360ab047e95661620**、dirty=false。前回cb84b75の連れ去り表示修正と、今回の電話・増援・夜明け待ち表示を収録。EXE SHA256 **64AC8303AA3FC499294A51135182BD2666A39E29343BDC72768B50B01B8088BF**。[BUILD.json](artifacts/playtest/20261009-194756-179/BUILD.json) / [専用保存での起動・再読込検証](artifacts/export-verification/20261009-194926-513/verification.json)。

[REINFORCEMENT_REVIEW](review/quality-roadmap/REINFORCEMENT_REVIEW.md) / [比較画像](review/quality-roadmap/REINFORCEMENT_GALLERY.html)。電話中の撃破・蘇生、成立済みの予約、外周からの実際の到着、夜明けまでを固定条件で確認。関連138検査・失敗0。画面は区切った1倍速、通常の画面・音声・保存は未使用。電話前の死亡は中断、蘇生しても途中再開せず、成功済み個体は再要請しない。制限時間後は外周出現で生存勝利へ進む現行仕様を維持した。遅い増援を必ず戦わせるかは未確定で、ルール変更はしていない。

新EXEのheadless/Dummy起動でWRM1朝保存を作成し、別の検証済み5日目朝保存を再読込・保持した。検証専用user-dataと試遊用user-dataは分離し、試遊用へfixture保存は移していない。旧試遊版の既知ファイル75件と元プロジェクトの既存4件はSHA256一致。確認入口の01_最新試遊と02_比較画像を更新。ソース確定後は出力記録と索引だけをコミットし、再出力しない。

次は **連行先に動物・黄金像などの対象物を押すと指示モードが切り替わる場面** を一つ確認する。意図しない切替と説明不足を実入力で分け、発見した一点だけ補正する。増援の約18秒の接近待ち、夜明け境界の正式な扱い、面白さ・実聴感・物理IME・長時間・クリーンWindowsは人間試遊に残す。専用cloneを継続し、通常作業と旧版を保護。push／merge／公開なし。以下は各時点の履歴。

## 過去の記録：動物使い＋舞姫の混成確認（2026-10-09）

[MIXED_REVIEW](review/quality-roadmap/MIXED_REVIEW.md) / [比較画像](review/quality-roadmap/MIXED_GALLERY.html)。9日目の固定条件で救助→一度の敵蘇生→再撃破→翌朝と、救助失敗→鶏損失→翌朝を実画面・入力で確認。戦闘は区切った1倍速観察、朝への休息は通常24倍。新たな進行不能は見つからず、健康な連れ去り中の鶏を「療養：1日目の朝に復帰」と誤表示する問題だけ修正した。敵AI・数値・素材は変更していない。

限定回帰11検査・失敗0（artifacts/balance-audit/20261009-190527-779）。強制ダメージの内部試験と、自然ダメージ・通常入力による描画観察を区別。4回の隔離実行は全て終了0、接続復帰後もGodot残留なし。最終図鑑クリックはボタン準備前に拒否され、図鑑は未確認。翌朝の鶏在籍は状態JSON、隔離保存はWRM1ヘッダを確認した。

**試遊EXEは6746c76のまま。今回の表示修正はソースのみで未収録。** 旧版を上書きせず、次のまとまった試遊節目で出力する。確認入口と比較画像へ今回のリンクを追加。通常ゲーム・保存・画面・音声は未使用、push／merge／公開なし。

次はサラリーマン＋舞姫を一組だけ選び、電話中の撃破／蘇生、予約済み増援と夜明けの関係、到着待ちの理解を確認する。先に実装条件を読み、必要な相互作用だけ固定再現する。追跡範囲4と救出本能の優先は説明改善候補。以下は過去の節目の記録。

## 過去の試遊版と確認入口（2026-10-09）

[Play-Isolated.cmd](artifacts/playtest/20261009-184446-538/Play-Isolated.cmd)。ゲーム本体 **6746c76379cc0a842cefc3f8fbc660ac5b59da1a**、dirty=false。EXE SHA256 **92098006EE5AE24D7886C2941C561FC9D942B5A267CDD6AD717EFE3DCD489C4A**。[BUILD.json](artifacts/playtest/20261009-184446-538/BUILD.json) と [通常起動・保存検証](artifacts/export-verification/20261009-184611-785/verification.json) を正本とする。

今回の3点修正を1回だけ新規出力。headless/Dummyの専用保存先で通常起動→WRM1朝保存作成→検証済み5日目朝の再読込・保持に成功。試遊用user-dataへfixtureは入れていない。旧試遊版63ファイル、元プロジェクトのBGMと既存import計4ファイルはSHA256一致。最後のコミットは資料と新テストの生成UID2件だけで、ゲームを再出力しない。

ユーザー向け入口は C:/Users/masat/Documents/codex_test/projects/sporehollow/確認入口/00_確認ガイド.html。隣の01_最新試遊.lnkから起動でき、比較画像・採用素材索引・納品と候補・試遊履歴・ロードマップへ6リンクを置いた。リンク先の存在と保存先の分離を検証。元repoの既存変更を保持し、新規の確認入口だけ追加。素材実体の移動／削除なし。

Godotが書き換えた1251件のimportはGit上の内容差分ゼロを確認して改行差だけ戻した。このcloneの生成レビューimport3件は task/generated-imports-20261009-184446 に復元用manifestと共に保管。元repoの同名3件は保持。新UIDは既存と重複なし。通常デスクトップでのEXE起動・音・IME・人間試遊は未実施。

## 実画面・入力レビューと3点の補正（2026-10-09）

[WALKTHROUGH_REVIEW](review/quality-roadmap/WALKTHROUGH_REVIEW.md) と [比較画像](review/quality-roadmap/WALKTHROUGH_GALLERY.html) を追加。seed31の同じ新規牧場で導入→購入→壁→連行→初夜→2日目の朝・図鑑まで確認。別fixtureで療養からの操作復帰、誘拐・像破壊・像搬出の敗北と再挑戦、鶏損失後の翌朝と継続を実画面・入力で確認した。レビュー時計は停止・加速付きで、人間の1倍速試遊・聴感とは別。

朝用の文字サイズが昼へ残って休息ボタンが4px欠ける問題を修正。「狙え」の範囲外メッセージへ仲間名と対処を追加。像の固定解除・搬出中はHUDに危険と対処を継続表示する。関連48検査・失敗0、修正後の隔離画像3枚を確認。今回の代表条件で新しい進行不能は再現せず、能力値・確率・素材・英語レア度は変更していない。既存801検査を繰り返していない。

次は動物使いの連れ去り／舞姫の蘇生／サラリーマン増援から一組の混成だけを選び、対象喪失・救助・夜明けを短い実画面シナリオで確認する。朝の損失理解、連行先での選択切替、1倍速の待ち時間は未評価。通常ゲーム・セーブ・デスクトップに干渉せず、push/merge/公開なし。

指定元プロジェクトの 確認入口/00_確認ガイド.html に試遊版・比較画像・採用記録・候補・履歴の入口を追加した。素材実体は移動しない。[素材と整理規則](review/quality-roadmap/ASSET_INDEX.md) に現在の分類と今後の置き方を記録。以下の最新表記は各時点の履歴として読む。

## 再接続後の引き継ぎ完了（2026-10-09 UTC）

最新試遊版：[Play-Isolated.cmd](artifacts/playtest/20261009-020437-216/Play-Isolated.cmd)。ゲーム本体 **002f3cb6ca788ee9c85539570c929b56fc84adc8**、出力時dirty=false。EXE SHA256 **FBB8A7AAD1D04700586B8A525E388EF3ADFE6D508B26B3120F4900D366698B4B**。識別情報は同梱 [BUILD.json](artifacts/playtest/20261009-020437-216/BUILD.json)。この後の引き継ぎコミットは文書とテストUIDだけで、EXEを再出力していない。

出力・smokeと専用保存先での実EXE起動は前回成功済み。[保存検証記録](artifacts/export-verification/20261009-020601-469/verification.json) はWRM1朝保存作成、検証済み5日目朝の再読込・保持、旧3版の12＋14＋14＝40ファイル一致を記録している。起動はheadless/Dummy・独立user-dataで、通常セーブや対話画面は使っていない。試遊用user-dataへ5日目fixtureを移していない。

今回の再接続では、残差分が `test_crowd_budget.gd.uid` / `test_morning_layout_ui.gd.uid` / `test_shop_readability_ui.gd.uid` / `test_wounded_idle.gd.uid` の4件だけであることを確認。全て追跡済みスクリプトのGodot生成識別子で、既存のUID追跡方針に合わせて保存した。コード変更、801検査の再実行、GPU描画、再出力はしていない。Uncommonなど英語表記を維持。接続切断で残っていた資料更新を完了した。

次はROADMAPのF：この版の朝→店→図鑑、負傷復帰後の8秒、入口と代表1夜を人間が試遊し、読みやすさ・敗因の理解・次の行動を確認する。一つの問題へ絞って修正し、必要な固定条件だけ比較する。実聴感、物理IME、実時間長期、クリーンWindowsは未完。以下のF2以前の版と記録は履歴であり、最新起動先は上記。

## 過去の記録：朝画面・読みやすさ・負傷休息（2026-10-08 UTC）

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
