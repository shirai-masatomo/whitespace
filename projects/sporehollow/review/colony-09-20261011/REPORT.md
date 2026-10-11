# 最新版の作業場所と検証結果

確認日：2026-10-11。旧標準版13c113fの検証結果は今回の最新版の合格根拠に含めません。

## 作業場所

- 開発元：C:/Users/masat/Documents/Codex/2026-10-10/task/colony-structure-01-work
- 開発元ブランチ：research/colony-structure-01
- 確認時HEAD：48685b697c80fd2b79f128b8fe64aa3ca9f9087c
- 公開用コピー：C:/Users/masat/Documents/Codex/2026-10-10/task/whitespace-public-release
- 公開用ローカルブランチ：feature/whistle-ranch-colony-20261011
- 公開用HEAD：1eab797b65ef44198fc317fb7a132b4438475200
- dotが報告したGitHubブランチ：codex/sporehollow-colony-09

各リポジトリ内の projects/sporehollow がゲームです。公開用HEADはdotの提示SHAと完全一致します。ローカルと公開先ではブランチ名・履歴が異なります。

公開用のgame内75ファイルを開発元と比較した結果、差はbuilding_art.gd末尾の空行だけでした。source-comparison.jsonに記録しています。開発元の未コミット.import/.uidを破棄していません。

## 普段の起動先

C:/Users/masat/Documents/codex_test/projects/sporehollow/確認入口/最新開発版.lnk

このショートカットは開発元の projects/sporehollow/artifacts/autonomy-entry-01/bundle/Launch-Autonomy.ps1 を指します。

- EXE：同bundle内 WhistleRanch-Autonomy-Partial.exe
- BUILD.jsonの実装コミット：8deea2f
- EXE SHA256：EE5ED75ABD1AF47AE528461CE8F7ACF6FCA7C6F499C9A56FD1FEFE0257A9A2D7

開発元の8deea2fから確認時HEADまでgameとproject.godotに差はありません。公開コミット番号とEXEの実装番号が違うことだけでは旧版とは判定できません。旧標準フォルダや古いPROJECT_STATEだけを基準にした前回の検証対象選定は誤りでした。

## 今回の検証

公開用1eab797で既存verify.ps1を実行：インポート成功、関連77項目成功。

| 分類 | 成功 |
|---|---:|
| 50×34境界・移行・カメラ | 51 |
| 明示回収・物理搬送・建設用資材 | 11 |
| 選択人物の交渉・時間停止・中断 | 15 |

ログと詳細はheadless/。検証後の公開用Git追跡ファイルに差分なし。これは決定的なテスト用状態での検証で、人間の通し試遊ではありません。

## 通常デスクトップでの実画面確認

ユーザーの追加許可を受け、2026-10-11に最新版EXEを通常画面で起動しました。人物選択・時間停止ボタン・役割画面・動物図鑑一覧／詳細・敵図鑑一覧を実際に操作し、6枚を保存しました。PNGにはタイトルバーが含まれます。導入はスキップした確認用の新規プレイです。

さらに公開用1eab797の既存交渉UIテストを、同じGodot 4.7.2の通常GPUウィンドウで実行しました。17項目成功、交渉ボタンとショップ入口の2枚を保存・目視確認しました。こちらは初期位置と時間を固定したテスト用状態です。商人へ接近してから開くこと、ショップ中の時間停止、右クリック終了、建設／命令／ゾーンの入力優先を確認しています。

計8枚。代表5画面と補助画像のリンクはSCREENS.mdにまとめています。EXE起動による画像とソース実行による画像を区別しました。EXEの実装コミットは8deea2f、公開用の検証コードは1eab797です。今回参照している素材はそれぞれの既存同梱素材で、素材担当ブランチの最新HEADを別途採用した作業ではありません。

先行した隔離起動は60秒でタイムアウトしました。原因は未特定ですが、通常起動と通常GPUソース実行では描画できています。隔離失敗をゲーム本体の起動不能とは扱いません。

## レビューで確認してほしい点・未確認範囲

- 人物選択時、装備・休息・図鑑・持ち物が並ぶため、下部情報量と主操作の分かりやすさ。
- 柴犬一覧のRarityエンブレムは小さいため、縮小時の識別性。
- 役割画面の優先度1〜4と未設定の説明、人物行の読みやすさ。
- 行商人入口の荷車・閉じた本・二つの選択ボタンの重心と余白。
- 図鑑の未発見枠8枠・一覧／詳細の構成は今回画像で確認済み。

今回、敵戦闘の通し試遊、死体／蘇生、各敵AIの行動循環、ショップ全カテゴリ・全取引、ページめくりの動画、音声・BGM、キーボード全操作は確認していません。静止画だけでこれらを合格扱いにしていません。キー送信によるSpace／EscはこのWindows操作経路で期待した変化を確認できず、停止と終了はボタンを使いました。原因はゲームと入力ツールのどちらか未特定です。

## データ保護

起動前に既存ゲームウィンドウがないことを確認。通常EXEのAPPDATA／LOCALAPPDATAはdirect/user-dataへ、ソース実行はdirect/source-user-dataへ分離しました。確認用EXEのウィンドウだけを閉じ、確認用colony.snapshotはdirect/user-dataに保存されました。普段のbundle/user-data内ファイルの更新時刻は今回起動前のままです。

今回、ゲームコード・通常の起動先・EXEは変更していません。撮影後も公開用HEADは1eab797、追跡ファイル差分なし。GitHubへのpush/mergeなし。

## 保存資料

- headless/：公開版の77項目・インポートログ
- direct/screenshots/：通常EXEから6枚
- direct/source-capture/：最新版ソースから2枚・17項目の結果・GPUログ
- direct/launch.json：EXEのPID・ハッシュ・専用ユーザーデータ
- direct/image-hashes.json：今回8枚のSHA256
- gpu-isolation.json：先行した隔離起動失敗の記録

交渉キャプチャ用スクリプトは、既存テストにショップ入口の撮影を追加したものです。通常GPU実行であることはdirect/source-capture/capture-manifest.jsonに記録します（既存テスト由来のmethod文面にはPrivate GPUが残っています）。
