# 開発環境・戦闘基盤・基幹ループ（2026-10-17）

今回の範囲は工程1の保存付き基幹ループまで。**工程1全体は未完了**。進捗・証拠・次の依頼は [PROGRESS.md](dot/PROGRESS.md)、機能別状態は [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) を参照。

## 環境一覧

| 項目 | 採用・確認内容 |
| --- | --- |
| OS | Windows、実測バージョン `10.0.26200.0`、x64 |
| エンジン | **Godot 4.7.2-stable Standard**、実行結果 `4.7.2.stable.official.ed1daf0bf` |
| 言語 | GDScript（UI・戦闘・ランナー）、PowerShell（ビルド・検証） |
| テンプレート | 同じ **4.7.2.stable** の Windows x64 release/debug |
| 描画 | Compatibility / OpenGL 3.3。実機 RTX 4070 SUPER、NVIDIA 610.88 |
| Git | 2.52.0.windows.1。既存認証による push dry-run 成功。新規の永続認証設定なし |
| その他 | Python 3.10.6、Node.js 24.16.0 を確認。ゲームのビルドには不要。`gh`・`rg` は PATH に見つからず |
| 配布 | Windows EXE＋PCK＋説明書＋Godotライセンス＋BUILD.jsonをZIP化。未署名 |
| CI | `.github/workflows/dive-in-under-windows.yml`。本作品の変更のみをトリガーに Windows runner でテスト・エクスポート |

公式安定版：[4.7.2 アーカイブ](https://godotengine.org/download/archive/4.7.2-stable/)。版・公式配布SHA256は `tools/godot-version.json` に固定。既存アーカイブが公式GitHubリリースのdigestと一致することを確認して専用 `.tools/` へ展開。他作品のツールは書き換えていない。ツール導入に追加の支払い・契約・管理者インストールは行っていない。

## 再現手順

このプロジェクトのディレクトリで PowerShell を使用する。

```powershell
# 初回だけ。公式エディタZIPと全OSテンプレートTPZ（約1.28GB）を取得・検証。
./tools/setup.ps1
# 既に同じ公式アーカイブがある場合は読取再利用可能。
# ./tools/setup.ps1 -ArchiveDirectory C:\path\to\archives

./dev.ps1 -Task verify
./dev.ps1 -Task simulate -Baseline "$PWD/artifacts/simulation.json" -Output "$PWD/artifacts/comparison.json" -StrictRepeat
./tools/smoke.ps1
./tests/test_harness.ps1
# ゲーム起動なしで非表示ステーション・専用Desktopの権限を検査。
./tools/isolated_visual.ps1 -ProbeOnly
# 成功した場合だけ非対話Window Station内で実EXEを描画。
./tools/isolated_visual.ps1
# ユーザーが通常のウィンドウで操作する場合。
./dev.ps1 -Task play
```

`dev.ps1` は `test / simulate / build / verify / play` を受け付ける。`verify` は戦闘/ループ/保存テスト→ヘッドレスUI→1,000回の単発戦闘→Windowsビルド。成果物は `build/DiveInUnder-foundation-windows-x64.zip`、ログと統計は `artifacts/`。Godotのユーザーデータはこのプロジェクトの `artifacts/user-data` に隔離する。テンプレートも `.tools/templates` のみ。システムのGodot設定を書き換えない。

Gitコマンドが制限環境で使えない場合は、確認済みのコミットを `-GameCommit` に明示できる。作業中ビルドは `+dirty` などで区別し、正式コミットと偽らない。実機ではsandbox内でGodotのsafe-saveが失敗し、許可済みビルドを権限付きで再実行すると成功した。セキュリティ設定の変更はしていない。

ZIPを展開して `DiveInUnder.exe` を起動し、「戦闘を確認する」→敵/Lv/シード→「この条件で自動戦闘」。停止・1ラウンド進行・同条件再戦・タイトルへの復帰が可能。EXEとPCKを同じフォルダに置く。

## データと共通コア

- `data/v1/balance.json`：COMBATの仮式係数、ENEMIESの6種の基礎値、FLOORSの1〜10Fの遭遇比率・敵候補・Lv範囲。本編が階層テーブルを抽選に使用する。宝箱・イベント・ドロップは `expedition.json` に正本から追加。
- `core/combat.gd`：ファイル・UI・時計・グローバル乱数に依存しない計算。コピーした状態を返す。`enemy()`が基礎値＋Lvから1度だけ計算し、階層倍率を受け取らない。`start()`→`advance()`をUIと`simulate()`が共用する。
- 同速は戦闘専用 `RandomNumberGenerator`、各ラウンドで確定。命中→会心→振れ幅の順。HP0は即停止、50ラウンドは死亡と別のdraw。スキルは未実装のため通常攻撃倍率1.0。
- `core/catalog.gd`：データ読込と形・値・参照ID検証。ゲームとランナーが共用。
- `tools/runner.gd` / `tools/simulation.gd`：実行・集計・比較のみ。ダメージ式の複製なし。
- `ui/game.gd`：本編のタイトル・探索/戦闘・結果・町/倉庫/装備。`ui/main.gd`：共通部品と独立単発ツール。モックをクリック画像にせず、GodotのButton/Label等を使用。PX-01〜03を確認し、青緑の洞窟・滝・暖色ランタン・羊皮紙/真鍮パネル・静止ドット候補・HP/SPバーへ反映。正式な量産素材の採用は未決定。

## シミュレーターの条件

```powershell
./dev.ps1 -Task simulate -Trials 1000 -Seed 10000 `
  -Scenario 'res://data/scenarios/baseline.json' `
  -Output "$PWD/artifacts/baseline.json"
```

シナリオには敵ID/Lvと主人公の**実効能力・現在HP/SP**を与える。`hero.level`は記録値で、主人公の成長係数はまだ適用しない。装備・スキル配列は空のみ受理し、未実装機能を黙って無視しない。試行数は1〜100,000、標準1,000。シード集合は開始値からの連番を全件保存する。

JSONは各seedの勝敗・ラウンド・双方残HP・報酬・ログSHA256、勝率・死亡率・打切り率、平均/中央値/p10/p90、勝利時残HP分布、ゲームコミット・エンジン・データ版・設定版・SHA256を含む。人間向けの `.json.txt` も出力。ターン数は**ラウンド数**。仲間死亡率は対象外を示すnull、勝利ゼロ件時の勝利HPもnull。

比較はシナリオとseed集合、エンジン、ランナー契約が一致する場合だけ実施。データ版・ゲームコミットの差は記録して比較できる。同じseedでもルール変更で乱数消費が変わる可能性がある。装備等の入力を変える試験は別シナリオとして別集計し、同条件差分と混ぜない。現在は戦闘だけなのでドロップ・イベント用乱数を消費しない。

## 検証の限界と引き継ぎ

- `tools/smoke.ps1` はヘッドレスのみ。旧 `-Rendered`（画面外/no_focus）は**通常デスクトップから隔離されない**ため禁止し、指定しても起動前にエラー終了する。停止指示前にこの方法で表示された可能性は否定できない。旧画像はローカル `artifacts/exe-rendered` に保持し、現行の隔離証拠と区別。
- `tools/isolated_desktop.cs` は牧場の既存成功手順を読み取り参照し、本作品に限定して整理。OSのログオン単位の非対話ステーションを直接要求し、`WinSta0`でないことと非表示をプロセス作成前に検査。UUIDの専用Desktopを`STARTUPINFO.lpDesktop`へ指定。専用Desktopだけを列挙して起動PIDのウィンドウ所属を記録する。SwitchDesktop、SendInput、通常デスクトップの列挙、拒否後の代替経路、牧場の整理削除処理は持ち込まない。
- 起動監査・ハッシュ・終了結果は `artifacts/isolated/isolation.json`。APPDATA/LOCALAPPDATAも同所に分離。画像はアプリのviewport、操作はアプリ内のMouseButton入力経路。**OS入力や人手による実操作の証拠ではない**。アクセス拒否なら停止し、GUI以外の作業を続ける。
- Computer Useスキルを確認したが、必要なnode_repl APIがこのセッションにない。ユーザー操作中のゲームは終了していない。旧方式の通常画面への表示可能性は上記のとおり残る。
- フォントはWindowsの Yu Gothic UI / Meiryo を参照し同梱していない。他言語OSでの日本語フォント表示は未検証。
- 通常死亡ペナルティ、回復、成長は `expedition.json` の交換可能な仮設定として導入。正式決定ではない。単発ランナーの試験能力値とは用途を区別する。
- 初回から通常探索・帰還／HP0死亡、町／倉庫／装備／保存、旧セーブ移行を実装・隔離確認済み。1000seedの反復ソロ10Fと実EXE再開も確認。状態4効果が未実装。仲間・犬・黄金像の仲間排出は工程5まで作らない。
- SPECや設計台帳の古い「未着手／実装開始待ち」は設計時点の記述。現在のユーザー承認と2026-10-17工程順を適用し、確定仕様そのものは書き換えていない。

## 確認入口と素材方針

Windows隔離再起動でGodotの `shader_gles3.cpp:802`（キャッシュのハッシュディレクトリ作成）エラーを検出。既存パスは最大262文字で、長いパスが原因候補。小規模2D基盤では `rendering/shader_compiler/shader_cache/enabled=false` としてディスクキャッシュを無効化した。描画やシェーダーコンパイル自体は有効で、起動ごとのコンパイル費用が残る。既存キャッシュやユーザーデータは削除しない。

ユーザー向け入口は [review/current/README.md](../review/current/README.md) の1か所。最新ZIPは既存buildを参照し、実画面・素材一覧・手順・判断事項へ案内する。別チェックアウトは既存作業保全のための開発場所であり、画面隔離ではない。

最新の明示方針：当面の主人公・敵・味方の素材は**戦闘画面用の静止表示1枚**。画面に置いた見え方で採用/不採用を判断し、採用後もしばらく静止画で使用。待機/攻撃/被弾/歩行モーション、表情差分、カットイン、演出強化は作らない。工程1〜4はゲームループ・UI・戦闘成立を優先し、仲間は工程5まで前倒ししない。今回のコード内ピクセルパターンは未承認の候補で、独立PNG素材はまだない。

## 基幹ループ 0.2.0 の構成と制約

- `core/expedition.gd`：ファイルに依存しない状態遷移（設定ロード関数は境界）。初回シナリオ/通常探索/戦闘/イベント/結果/町、装備とLv実効値、独立した探索/戦闘/戦利品乱数。戦闘式は既存Combatを呼ぶ。
- 保存は小さいseedとカウンター、戦闘開始時能力・seed・ラウンド数を保持し、再開時は同じCombatで再構成。64bit RNG stateをJSONの浮動小数へ渡さない。入力revisionを持つ古いUI操作は適用しない。
- `core/save_store.gd`：schema/config版と所有個体ID・状態を検査、一時書込み・flush・再検査、前回.bak保全、rename置換。失敗時はUI側の状態変更を取り消す。破損時に黙ってリセットせず、復旧/新規開始の前に元ファイルを同じ保存先へ退避。
- 既定の保存は `user://campaign-v1.json`（Windowsの具体的な場所はPLAY.txt）。旧戦闘基盤には保存データがなかったため移行対象なし。異なるconfig版の自動移行は未実装。同じ保存で同時プレイしない。SHAによる変更検出はあるがCASとrename間の完全な排他は実装していない。
- `ui/game.gd` は本編UI、`ui/main.gd` は共通UI部品と独立単発ツール。本編4画面以上を追加、全キャラクター静止コードパターンのまま。11部位を表示し、アイテム個体は所持品/倉庫/装備のいずれか一か所だけが所有する。
- 基準シミュレーターの主人公は従来の試験専用実効値。本編のLv成長や装備をその入力へ二重適用しない。`-StrictRepeat` / runner `--strict=true` がCI用厳密比較。通常比較は意図したバランス差を報告し成功終了できる。
- `tests/test_harness.ps1` は意図的な不一致/入力断線/古いJSONを拒否することを確認。`tools/smoke_result.ps1` がヘッドレス/隔離描画のrun IDを共通検証。成功JSONは本編とツールの全確認後のみ書く。EXEヘッドレスは終了後に別プロセスで戦闘途中の保存を読み直す。
- ローカル入口は同じ `review/current` のindex.htmlとPlay.cmd。牧場の既存確認フォルダに本作へ向くリンク1個だけを追加し、牧場の起動先・コードは無変更。ゲームやエクスプローラーを勝手に起動しない。
- CIの `github.sha` はpull_requestイベントでmerge commitを指す。PR headと実checkout SHAを分けて報告し、BUILD.jsonの値を実行ソースとして扱う。

## 0.3通常ソロ10F・安全な配布更新

Godot/GDScript/Windows/GPUの固定環境は上記から変更なし。現在の本体と設定はBUILD.jsonを参照。通常1000seed比較と実EXEの再現は以下。

```powershell
./tools/verify_campaign.ps1 -GameCommit (git rev-parse HEAD)
./tools/campaign_smoke.ps1
./tests/test_campaign_harness.ps1
./tools/campaign_smoke.ps1 -Rendered
./tools/publish_local.ps1
```

`verify_campaign` は設定.1/.2の1000seed前後比較、.2の厳密再実行、seed10000全操作列を作る。通常探索の分子・分母は初回を除外。元の単発戦闘ランナーも維持する。GUI再現は同じExpeditionの操作列に従い、実Controlのviewportクリックと本番Timerコールバックを使用。全操作状態を照合し、3つのEXEで途中/突破後保存を検証。OS物理入力は別の未検証範囲。

`dev.ps1 build` は既存EXEを触らず `build/releases/<commit>-<unique>/` を新規作成。検証はcandidate.txtの参照先へ。publish_localは同じEXE/PCKの隔離監査・保存再開・厳密統計が通った後だけcurrent.txtを原子的に置換する。Play.cmdはcurrent.txtを読む。以前のwindows/と配布ディレクトリは削除しない。既存ゲームを終了しない。

設定.1はexpedition-legacy.jsonとして固定し、既存保存はその設定で継続。設定.2は新規保存に適用。未知の設定は拒否。自動書換えによる能力変更や戦闘途中の変化を避ける。保存の同時書込み完全排他は引き続き未実装。

[最新の全受入照合・制約](PHASE_01_ACCEPTANCE.md)が現在の状態。追加の画作り要件は未達で、OS物理入力の未検証と混同しない。

## 静止画像候補A 0.4の確認入口

ユーザー指定の入口は `C:\Users\masat\Documents\codex_test\projects\Dive In Under\確認入口.lnk`。以前のDive専用リンクだけを移動し、元の牧場入口には触れていない。背景と透過原稿は `assets/visual-candidates/v1/` に保存し、SHA・サイズ・来歴をmanifest.jsonへ記録。高解像度原稿を編集せずGodotで比率維持/nearest表示する。ゲームコア・保存形式・数値は0.3と同じ。候補の採否は未確定。

実行版`b358aa1`の独立Windows出力で、通常290操作・途中と突破後の保存再開・非対話描画を検証。通常1000seedの全結果は前版と厳密一致。[最新証拠](../review/current/README.md)、[制作チャット引継ぎ](IMAGE_PRODUCTION_HANDOFF.md)。Library正式ヘルパーはこのWindowsでメタデータAPI非対応だったため、ユーザーが明示保存したローカルファイルを受領。転送手順を改変・迂回していない。

## 0.4.6の保存移行と検証

現在の設定は `2026-10-17.loop-provisional.3`、保存schema2。旧設定.1（HP成長4）と.2（HP成長5）を別ファイルで保持し、旧セーブの設定を引き継ぐ。初回制限フラグは履歴のみ。読み込みは書き換えず、移行後最初の保存で原本の `.preserved-*` を作る。競合書込み・未来版・破損の拒否を維持する。旧バイナリは新schema2を読めないので、移行後に旧EXEと同時進行しない。

追加検証：`./tools/verify_campaign.ps1`、`./tools/campaign_smoke.ps1`、許可確認後の `./tools/campaign_smoke.ps1 -Rendered`、`./tools/migration_smoke.ps1` と `-Rendered`。移行用旧セーブは `tests/test_first_expedition.gd` がartifactsへ生成し、ユーザー実セーブを流用しない。生成されるWindows ZIPは署名なし。EXE/PCKは不変リリースフォルダに置き、検証後 `tools/publish_local.ps1` でcurrent.txtだけ切替する。
