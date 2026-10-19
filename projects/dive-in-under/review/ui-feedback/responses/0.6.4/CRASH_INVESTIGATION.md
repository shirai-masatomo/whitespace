# CI異常終了の追跡確認 — 2026-10-19

指定の[e4c41cc / CI39244216616](https://github.com/shirai-masatomo/whitespace/actions/runs/39244216616)は失敗のまま扱う。今回の開始時点でmain `476c4e0`には後続修正と成功証拠が既に存在した。origin/mainと一致しており、ゲームコードの再変更・再現起動は行わず、ログ・差分・保存済み画像・配布ファイルを再照合した。[機械可読の照合結果](CRASH_AUDIT.json)。

## 失敗位置と、断定できる範囲

- Windows書き出し（step20）は成功。step25の独立実行で、beforeは終了0／14.205秒、afterは `3221225477 (0xC0000005)`／16.292秒。PowerShellの48行目は異常終了を検出してCIを失敗させた場所であり、ゲームが落ちた命令位置ではない。
- afterは12枚を保存し、[最後の撮影ブロックの実画面](history/after-render-initialization/07-next-departure.png)でも人物・敵・ログが描画されている。その後、通常タイマーとSpace入力、地図・Esc遷移、バッグ満杯確認の順に進むコードだった。完成JSONと13枚目の `08-backpack-full.png` は存在しない。画像番号順で実行されたわけではなく、バッグ処理で落ちたとも断定できない。
- 対象コミットには途中チェックポイントがないため、当該run単独では「撮影後からバッグ確認前」の範囲まで。後続の段階記録と修正差分で、入力処理中の画面ツリー再構築が関係する経路へ絞り込んだ。
- render.logはエンジン起動とANGLE切替警告で終わるが、同様に短いログでも後続の全確認は成功している。**描画初期化が原因という判断は根拠不足**。`history/after-render-initialization/` は当初の仮説による保存名で、確定原因を意味しない。

元の[隔離結果](history/after-render-initialization/isolation.json)・[ログ](history/after-render-initialization/render.log)と[証拠artifact](https://github.com/shirai-masatomo/whitespace/actions/runs/39244216616/artifacts/12183540329)を保持する。今回保存した元画像のSHAと元runの画像一覧はCRASH_AUDIT.jsonに記録した。

## 既存の修正と、その後の結果

|コミット／CI|観測結果と変更|
|---|---|
|[3ae3dec / 39244712751](https://github.com/shirai-masatomo/whitespace/actions/runs/39244712751)|成功済みbeforeを再利用し、afterだけでも同じ異常終了（18.504秒）。beforeとの連続起動を必要条件とはしない。|
|[87dd10b / 39245179773](https://github.com/shirai-masatomo/whitespace/actions/runs/39245179773)|Space処理中の即時 `show_campaign()` を `call_deferred` へ。Space停止・echo無視・2秒間の全状態不変・キー／ボタン再開確認を通り、[07-start](history/esc-input-order/progress.json)まで進んで異常終了（14.046秒）。この時点ではまだ解消扱いにしない。|
|[3aab6f6 / 39245634405](https://github.com/shirai-masatomo/whitespace/actions/runs/39245634405)|Esc入力を先に処理済みにし、地図を閉じる／準備へ戻る／タイトルへ戻る操作を遅延実行。以後は全対象確認・13画像・完成JSON・終了0（19.133秒）。|
|[c8ca625 / 39246303803](https://github.com/shirai-masatomo/whitespace/actions/runs/39246303803)|文字コントラスト等の小調整を含む最終配布EXE/PCKで、同じ対象確認が終了0（18.114秒）。これを配布済み0.6.4の根拠とする。|

修正箇所は通常ゲームの `ui/game.gd`（Space）、`ui/play_view.gd`・`ui/warehouse_view.gd`（Esc）。入力配送中に受信Controlを画面ツリーから外すタイミングを避ける。撮影側は途中の進行記録を追加した。別途あった固定データの未実装ID・描画プロセス追跡の不備は、指定runより前の撮影側問題として分けている。

ネイティブスタック／ダンプは未取得であり、Windows内部の正確な障害命令や単一の根本原因までは確定していない。**通常ゲームの入力処理に対する遅延化の後、同じ限定操作で観測された異常終了が解消した**ことが確認済みの結論。物理キーでも同じクラッシュが起きるかは未確認で、過去のPC全体のフリーズ原因とも同定しない。

## 確認の省略や成功扱いへの変更はしていない

`-AfterOnly` は成功済み旧版beforeの再撮影だけを省く指定。修正版afterのSpace・Esc・バッグ満杯・タイトル終了を含む確認は残っている。ハーネスは非0終了・タイムアウト・隔離不一致・完成JSON欠落を失敗とし、配布処理も実EXE/PCKのSHA、完成JSON、対象10ケース、満杯画像等を要求する。

最終の[完成JSON](after/refinement-review.json)と[外部プロセス終了記録](after/isolation.json)は同じrun_idで、終了ボタン押下、終了0、complete=true。バッグは[満杯画像](after/08-backpack-full.png)、1枠空けた解除、同じ個体ID・耐久37の維持まで記録されている。旧セーブの検証用番兵SHAも前後一致。

## 現在の通常入口と今回の最小確認

11:26 UTC時点で通常版が0.6.3だった記録は正しい。後続成功CIを確認した**11:45:30 UTC（20:45:30 JST）**に0.6.4へ切り替えられており、失敗したe4c41cc版は配布完了にしていない。

- 起動：いつもの「01 ゲームを起動」→ `review/current/Play.cmd` → `build/current.txt`。
- 対応版0.6.4、実装ソース `c8ca625ceae51cc033dc89c95166c94e6c32921e`。今回のmainはその後の資料追加のみで、実行コード・画像・音源に差分なし。
- 現在の通常入口のEXE/PCKのSHAを成功CI証拠と再照合し一致。通常ZIPのSHAも[配布記録](local-release.json)と一致。after全13画像のSHAと1280×720サイズ、JSONの完成・終了・run_idを再照合した。
- 今回のローカルゲーム起動0、クラウド再起動0。既に正常終了が記録された同一配布物への追加再現は不要と判断。UI改善・BGM・バランスを変更せず、旧0.6.3と失敗履歴も保持。

長時間プレイ・物理入力・全PC環境での再発有無は未確認。見た目の採用判断は利用者の評価待ち。[修正前後の比較一覧](index.html)。
