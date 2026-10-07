# 非干渉の描画検証（Windows）

`./dev.ps1 visual` は `isolated_visual.ps1 -Scenario characters` を実行する。市場・本・サブタスク・壁は `./tools/isolated_visual.ps1 -Scenario controls`。同時に実行せず直列で確認する。初回の環境確認だけなら `-Scenario probe`。通常の `play` / `editor` は呼ばない。

## 隔離境界

- Windowsの非対話Window Stationを作成する。権限上名前付き作成ができない場合は、Windowsが用意するログオン単位の非対話stationを使う。
- **WinSta0ではないこと・WSF_VISIBLEがfalseであることをプロセス作成前に検査**し、その中にUUIDの専用desktopを作る。`STARTUPINFO.lpDesktop`でGodotの最初のウィンドウから隔離する。
- 専用desktopだけを列挙し、起動したPIDの描画ウィンドウが所属することを記録する。ユーザー側のウィンドウ列挙、SwitchDesktop、SendInput、フォーカス変更は使用しない。
- GPUはOpenGL互換描画、音はDummy。入力は対象Godot内のInputEvent。画像はViewportから保存する。OSの画面キャプチャやマウス操作ではない。
- APPDATA/LOCALAPPDATA、画像、ログは `artifacts/isolated/<時刻>` に分離。作成したプロセスのハンドルだけを管理し、120秒でそのプロセスだけ停止する。通常のEXE/セーブは上書きしない。
- 失敗したら終了し、対話デスクトップへフォールバックしない。監査JSONに実装SHA、dirty、素材SHA、起動引数、PID、station/desktop、所属確認、終了結果を残す。

## 必要条件・限界

Windows、同梱Godot 4.7.2 GUIバイナリ、非対話station/desktopの作成権限、そのstationで初期化できるOpenGLドライバが必要。本環境のNVIDIA GPUで確認。他PCで初期化不能なら、同方式に対応するドライバまたは隔離VM/別テストマシンを用意する。ユーザーのデスクトップで試す代替は行わない。

実GPUの画面とゲーム内入力経路を確認できるが、人間の物理マウス操作・実スピーカー聴感・長時間試遊とは区別する。素材の納品・ゲーム取り込み・実画面検証も別の段階として記録する。

根拠：Microsoftの[Window Stations](https://learn.microsoft.com/en-us/windows/win32/winstation/window-stations)、[Desktops](https://learn.microsoft.com/en-us/windows/win32/winstation/desktops)、[STARTUPINFOW.lpDesktop](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/ns-processthreadsapi-startupinfow)。表示とユーザー入力を扱えるstationはWinSta0。headlessは[Godot DisplayServer](https://docs.godotengine.org/en/4.6/classes/class_displayserver.html)のdummy描画であり、PNG検証の代用にはしない。

木建材16接続/損傷/床境界/ドア通行は `-Scenario buildings`。通常デスクトップを使わず同じ隔離ヘルパーで検証する。

ショップの購入/売却全カテゴリと初日の商品詳細の撮影は `-Scenario shop`。通常の新規開始状態からゲーム内入力で画面を巡回し、PNGとobservations.jsonを保存する。所持金や在庫をデバッグで増やさず、購入/売却も専用APPDATA内だけで行う。

追加納品の左右動作/運搬/小演出は `-Scenario delivered`。全コマは描画フィクスチャ、被弾→気絶→運搬→救出と建築/回収は制御した初期位置から通常シミュレーションで確認する。

図鑑の入口・開閉・各個体・育成・命名は `-Scenario book`。前半は初期状態、後半は150G/100EXPを明示した検証状態で通常購入・育成を操作する。世界時間が朝の0tickのままであることも確認する。

世界観統合は `-Scenario story`。導入/開拓は通常新規開始のゲーム内入力、四方向侵入/祈り/搬出/救出は明示した日・初期位置の制御フィクスチャから通常シミュレーションを使用する。各PNGの状態と入力をstory-observation.jsonへ記録。制御例と人間の通し試遊を混同しない。

低カルマ/敵図鑑/装備の現在実装は `-Scenario progression`。day3/180Gの明示した検証条件と敵の描画フィクスチャを使用し、通常8日プレイのheadless記録とは分ける。旧storyシナリオの固定60G祈りは旧仕様の証拠で、現行の新規祈り受付として扱わない。

A〜F定点は `-Scenario ui_revision`（代表10枚）。中間の3画面だけなら `-Preview`。朝/商人/図鑑、予定取消、森外進入、READYは同じ入力シナリオで検査する。READY画面はゲージ・HP・初期位置を明示したフィクスチャで、通常プレイの到達記録と混同しない。

AIの変更確認は `./dev.ps1 evaluate -AISeeds 2` で既存6戦略×2seedへ限定できる。完走/明示休息の抑制を確認し、勝率閾値の統計判定は既定32seedの場合のみ行う。
