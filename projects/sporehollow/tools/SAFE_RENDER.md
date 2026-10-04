# 非干渉の描画検証（Windows）

`./dev.ps1 visual` は `isolated_visual.ps1 -Scenario characters` を実行する。初回の環境確認だけなら `-Scenario probe`。通常の `play` / `editor` は呼ばない。

## 隔離境界

- Windowsの非対話Window Stationを作成する。権限上名前付き作成ができない場合は、Windowsが用意するログオン単位の非対話stationを使う。
- **WinSta0ではないこと・WSF_VISIBLEがfalseであることをプロセス作成前に検査**し、その中にUUIDの専用desktopを作る。`STARTUPINFO.lpDesktop`でGodotの最初のウィンドウから隔離する。
- 専用desktopだけを列挙し、起動したPIDの描画ウィンドウが所属することを記録する。ユーザー側のウィンドウ列挙、SwitchDesktop、SendInput、フォーカス変更は使用しない。
- GPUはOpenGL互換描画、音はDummy。入力は対象Godot内のInputEvent。画像はViewportから保存する。OSの画面キャプチャやマウス操作ではない。
- APPDATA/LOCALAPPDATA、画像、ログは `artifacts/isolated/<時刻>` に分離。作成したプロセスのハンドルだけを管理し、120秒でそのプロセスだけ停止する。通常のEXE/セーブは上書きしない。
- 失敗したら終了し、対話デスクトップへフォールバックしない。監査JSONに実装SHA、dirty、素材SHA、起動引数、PID、station/desktop、所属確認、終了結果を残す。

## 必要条件・限界

Windows、同梱Godot 4.7.2 GUIバイナリ、非対話station/desktopの作成権限、そのstationで初期化できるOpenGLドライバが必要。本環境のNVIDIA GPUで確認。他PCで初期化不能なら、同方式に対応するドライバまたは隔離VM/別テストマシンを用意する。ユーザーのデスクトップで試す代替は行わない。

実GPUの画面とゲーム内入力経路を確認できるが、人間の物理マウス操作・実スピーカー聴感・長時間試遊とは区別する。静止素材からの仮歩行/仮睡眠と、正式動作素材の完成も別。

根拠：Microsoftの[Window Stations](https://learn.microsoft.com/en-us/windows/win32/winstation/window-stations)、[Desktops](https://learn.microsoft.com/en-us/windows/win32/winstation/desktops)、[STARTUPINFOW.lpDesktop](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/ns-processthreadsapi-startupinfow)。表示とユーザー入力を扱えるstationはWinSta0。headlessは[Godot DisplayServer](https://docs.godotengine.org/en/4.6/classes/class_displayserver.html)のdummy描画であり、PNG検証の代用にはしない。
