# 実行環境の監査 — 2026-10-20

## 今回の隔離方式と制限

**使用できる隔離環境を確認できていません。今回、ゲーム・SDK・Launcher・Ren'Py Lint・ビルドは実行していません。**

読み取りで確認した範囲:

- Windowsのエディション情報は `Core`（Home）、build 26200 / 25H2。レジストリのProductNameは旧表記のWindows 10 Homeを返すため、これだけでOSの表示名は断定しない。
- `WindowsSandbox.exe`、Hyper-V PowerShellモジュール、VirtualBox、VMware Workstationの標準配置とコマンドは見つからなかった。
- `wsl.exe`は存在するが、稼働可能なWindows用隔離GUI環境として確認していない。
- カスタム配置のVMや別PCを網羅的に調査した結果ではない。「VMが絶対に存在しない」とは断定しない。
- OS機能の有効化、仮想化ソフト導入、ネットワーク有効化、ドライバー・ランタイム変更は行っていない。

隔離内の実機テストはゼロ。通常デスクトップでの代替実行は行わない。

### 他タスクの独自撮影方式を追加確認

ユーザーの指摘を受け、Codexタスク「ホイッスル牧場 製造」と実装側のファイルを読み取りで調査した。
標準配置のVMツールだけを調べた当初の調査では、この方式を見落としていた。
独自方式と実画面撮影の成功記録は存在する。「独自方式もない」「スクリーンショットの自動取得自体が不可能」という意味ではない。

- `projects/sporehollow/tools/isolated_desktop.cs`: 非対話Window Stationと専用Desktopを作成し、そこへゲームを起動。通常の入力デスクトップへ切り替えず、所属ウィンドウ・正常終了・タイムアウトを確認する。
- `tools/isolated_visual.ps1`: `APPDATA`と`LOCALAPPDATA`を専用保存先へ変更し、Dummy音声・FPS制限・直列実行・通常画面へのfallback禁止を適用する。
- `tests/review_integrated_visual.gd`、`tests/capture_phase2.gd`: Godotの実際のviewportを`get_texture().get_image().save_png()`で保存。ホスト全画面のキャプチャや合成した理想画像ではない。
- 過去の`review/current/review02/tests/isolated-ui/isolation.json`には`ExitCode=0`、`NonInteractive=true`、`DesktopMatched=true`、`TimedOut=false`が記録されている。現在進行中の工程2の撮影完了を示す記録として流用しない。

確認したランナーは通常の`CreateProcess`を使用し、独立したゲストOS、ファイルアクセス制限、レジストリ分離、ネットワーク遮断を確立する処理は見つからなかった。
環境変数で保存先を変える処理は、ホストの他のフォルダへのアクセス禁止を実証するものではない。GPUもホスト側を共有する。
したがってこの実装だけでは、最新規約の「ファイルシステム・設定・プロセス隔離」を満たすと確認できない。
画面への干渉を避ける設計と内部フレーム保存は再利用候補だが、そのままRen'Pyを起動する根拠にはしない。
今回の調査では他作品のコードを変更せず、撮影スクリプトも実行していない。

## 前回のホスト実行で確認された変更

隔離規約が提示される前の作業で、ホストのWindows上でSDKのテンプレート生成、Lint、GUI画像生成、ゲーム／Launcherの起動を試行した。
これは現在の規約を満たさない。過去のホストでのLint成功を、隔離内での検証成功として扱わない。

確認できた書き込み:

| 保存先 | 内容 | 今回の扱い |
| --- | --- | --- |
| 作業領域 `tools/renpy-sdk/` | SDK ZIP・展開先・生成元・準備スクリプト | ゲストへ渡す取得済み入力として保全。ホスト実行禁止 |
| 独立作業ツリーの本プロジェクト | `.rpyc`、キャッシュ、ログ、エラー記録、公式GUI画像 | ソース以外はGit除外。診断用に保全、再実行しない |
| `%APPDATA%\RenPy\WhiteSpace-UniversityCircle-Foundation-1` | persistent、例外時のトレースセーブ、syncコピー | 今回作成した専用ディレクトリと確認し、丸ごと退避 |
| `%APPDATA%\RenPy\backups\university-circle-renpy` | 今回のスクリプトバックアップ | ハッシュ付きで丸ごと退避 |
| `%APPDATA%\RenPy\launcher-4` | Launcher persistentとsyncコピー、当日の更新日時 | 以前の状態が不明な共有データのため変更・削除しない |
| `%APPDATA%\RenPy\persistent` | 当日の更新日時のディレクトリ | 既存状態を確定できないため変更しない |

他の既存ゲームのセーブは対象にしていない。以前のユーザープロファイル全体のスナップショットはなく、ホストへの全影響を否定できない。

### NVIDIA設定APIの記録

前回のSDKログには `nvdrs: Disabled thread optimizations.` がある。
同梱の `renpy/display/core.py` はNVIDIAの設定APIを呼び、終了時の復元関数を`atexit`へ登録している。
**API呼び出しは記録されているが、終了後に設定が復元されたかは確認できていない。**
ドライバーのインストール・更新は行っていない。推測による設定変更や「復元のため」のホスト再起動・SDK再実行・GPU設定変更もしない。

## 整理と残存物

2026-10-20 21:03 JSTの監査時点で、コマンドラインがRen'Py／UniversityCircleに一致する `python.exe` / `pythonw.exe` / `renpy.exe` は検出されなかった。
ユーザーの既存作業プロセスを停止していない。

専用保存データと専用スクリプトバックアップは、原本の絶対パスと退避先を照合し、ファイルごとのSHA256を記録して、次へ移動した:

`C:\Users\masat\Documents\codex_test\tools\renpy-sdk\host-audit-20261020\`

- `game-profile/`: 試作専用の保存データ
- `project-script-backups/`: 今回のスクリプトバックアップ
- `audit.json`: 元パス、退避先、サイズ、SHA256、プロセス確認結果

移動後、上記2つのAppData内の専用ディレクトリが存在しないことを確認した。
調査証拠を失わないよう破棄ではなく退避とし、この保管物・共有プロファイル・SDK展開先は残存している。
個人プロファイルのバイナリはGitHubへアップロードしない。

## 今回行った静的作業

規約・手順書の更新、ソースレビュー、UTF-8・label・素材参照・SVG XML・WAVヘッダ・フォント内ライセンス表記の確認のみ。
静的チェック用の標準ライブラリPythonは既存の非SDK Pythonを使用し、Ren'Pyをimportせず、ゲームスクリプトのPythonも実行しない。
SDKの起動処理を呼ぶLintとは区別する。

## 未検証

隔離方式の実効性、タイトル・導入・マップの実画面、セーブ／ロードの状態復元、スキップ・オート・ロールバック、聴感、日本語の描画、Windows配布ビルド、配布物の起動は未検証。
前回の起動試行を、GUI受入テストの成功・スクリーンショット取得の成功として扱わない。
