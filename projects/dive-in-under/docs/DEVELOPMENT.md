# 開発環境と戦闘基盤（2026-10-17）

今回の範囲は工程1の基盤。**工程1全体は未完了**。進捗・証拠・次の依頼は [PROGRESS.md](dot/PROGRESS.md)、機能別状態は [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) を参照。

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
./dev.ps1 -Task simulate -Baseline "$PWD/artifacts/simulation.json" -Output "$PWD/artifacts/comparison.json"
./tools/smoke.ps1
# ゲーム起動なしで非表示ステーション・専用Desktopの権限を検査。
./tools/isolated_visual.ps1 -ProbeOnly
# 成功した場合だけ非対話Window Station内で実EXEを描画。
./tools/isolated_visual.ps1
# ユーザーが通常のウィンドウで操作する場合。
./dev.ps1 -Task play
```

`dev.ps1` は `test / simulate / build / verify / play` を受け付ける。`verify` はテスト→ヘッドレスUI→1,000回の単発戦闘→Windowsビルド。成果物は `build/DiveInUnder-foundation-windows-x64.zip`、ログと統計は `artifacts/`。Godotのユーザーデータはこのプロジェクトの `artifacts/user-data` に隔離する。テンプレートも `.tools/templates` のみ。システムのGodot設定を書き換えない。

Gitコマンドが制限環境で使えない場合は、確認済みのコミットを `-GameCommit` に明示できる。作業中ビルドは `+dirty` などで区別し、正式コミットと偽らない。実機ではsandbox内でGodotのsafe-saveが失敗し、許可済みビルドを権限付きで再実行すると成功した。セキュリティ設定の変更はしていない。

ZIPを展開して `DiveInUnder.exe` を起動し、「戦闘を確認する」→敵/Lv/シード→「この条件で自動戦闘」。停止・1ラウンド進行・同条件再戦・タイトルへの復帰が可能。EXEとPCKを同じフォルダに置く。

## データと共通コア

- `data/v1/balance.json`：COMBATの仮式係数、ENEMIESの6種の基礎値、FLOORSの1〜10Fの遭遇比率・敵候補・Lv範囲。今回の階層テーブルは**参照データのみ**で、探索抽選はまだ呼ばない。宝箱・イベント・ドロップは後続で正本から追加する。
- `core/combat.gd`：ファイル・UI・時計・グローバル乱数に依存しない計算。コピーした状態を返す。`enemy()`が基礎値＋Lvから1度だけ計算し、階層倍率を受け取らない。`start()`→`advance()`をUIと`simulate()`が共用する。
- 同速は戦闘専用 `RandomNumberGenerator`、各ラウンドで確定。命中→会心→振れ幅の順。HP0は即停止、50ラウンドは死亡と別のdraw。スキルは未実装のため通常攻撃倍率1.0。
- `core/catalog.gd`：データ読込と形・値・参照ID検証。ゲームとランナーが共用。
- `tools/runner.gd` / `tools/simulation.gd`：実行・集計・比較のみ。ダメージ式の複製なし。
- `ui/main.gd`：タイトルと単発戦闘の確認画面。モックをクリック画像にせず、GodotのButton/Label等を使用。最新mainのPX-01〜03を実ピクセルで確認し、青緑の洞窟・滝・暖色ランタン・羊皮紙/真鍮パネル・主人公と敵の静止ドット仮表示・HP/SPバーへ段階更新。正式な量産素材の採用は未決定。

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
- 初回死亡、死亡ペナルティ、回復、成長の正式仕様は決めていない。今回の仮値は戦闘試験の主人公HP24/ATK6/DEF1/SPD6/SP0のみ。後続はPHASE_01が許可した可変設定として導入する。
- 1〜10F継戦、反復探索・帰還、初回死亡1回限定と永続化、町/倉庫/装備/保存、通常ルールでのソロ10F突破、4実画面、Windows実操作が残る。仲間・犬・黄金像の仲間排出は工程5まで作らない。
- SPECや設計台帳の古い「未着手／実装開始待ち」は設計時点の記述。現在のユーザー承認と2026-10-17工程順を適用し、確定仕様そのものは書き換えていない。

## 確認入口と素材方針

Windows隔離再起動でGodotの `shader_gles3.cpp:802`（キャッシュのハッシュディレクトリ作成）エラーを検出。既存パスは最大262文字で、長いパスが原因候補。小規模2D基盤では `rendering/shader_compiler/shader_cache/enabled=false` としてディスクキャッシュを無効化した。描画やシェーダーコンパイル自体は有効で、起動ごとのコンパイル費用が残る。既存キャッシュやユーザーデータは削除しない。

ユーザー向け入口は [review/current/README.md](../review/current/README.md) の1か所。最新ZIPは既存buildを参照し、実画面・素材一覧・手順・判断事項へ案内する。別チェックアウトは既存作業保全のための開発場所であり、画面隔離ではない。

最新の明示方針：当面の主人公・敵・味方の素材は**戦闘画面用の静止表示1枚**。画面に置いた見え方で採用/不採用を判断し、採用後もしばらく静止画で使用。待機/攻撃/被弾/歩行モーション、表情差分、カットイン、演出強化は作らない。工程1〜4はゲームループ・UI・戦闘成立を優先し、仲間は工程5まで前倒ししない。今回のコード内ピクセルパターンは未承認の候補で、独立PNG素材はまだない。
