param()
$ErrorActionPreference = 'Stop'
# Manual preview bundle; never publishes over build/ or opens an interactive game.
$farmRoot = Split-Path -Parent $PSScriptRoot
$godot = Join-Path $farmRoot '.tools/Godot_v4.7.2-stable_win64_console.exe'
$runRoot = Join-Path $farmRoot ('artifacts/playtest/' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
$dataRoot = Join-Path $runRoot 'user-data'
$preview = Join-Path $runRoot 'WhistleRanch-preview.exe'
if (-not (Test-Path -LiteralPath $godot)) { throw 'Godot runtime is missing; run tools/setup.ps1.' }
if (-not (Test-Path -LiteralPath "$farmRoot/.tools/templates/windows_release_x86_64.exe")) { throw 'Windows export template is missing.' }
New-Item -ItemType Directory -Force $runRoot, $dataRoot | Out-Null
Set-Content -LiteralPath "$farmRoot/artifacts/.gdignore" -Value ''
$revision = (git -C $farmRoot rev-parse HEAD).Trim()
$dirty = [bool](git -C $farmRoot status --porcelain)
$art = Get-Content -LiteralPath "$farmRoot/game/art_provenance.json" -Raw | ConvertFrom-Json
@{commit=$revision.Substring(0,7); dirty=$dirty; asset_delivery_commit=$art.latest_delivery_commit} | ConvertTo-Json | Set-Content -LiteralPath "$farmRoot/game/build_stamp.json"
function Run-Owned([string]$Name, [string]$Executable, [string[]]$Arguments) {
    $log = Join-Path $runRoot "$Name.log"
    $info = [System.Diagnostics.ProcessStartInfo]::new()
    $info.FileName=$Executable; $info.WorkingDirectory=$farmRoot
    $info.UseShellExecute=$false; $info.CreateNoWindow=$true
    $info.RedirectStandardOutput=$true; $info.RedirectStandardError=$true
    $info.Environment['APPDATA']=$dataRoot; $info.Environment['LOCALAPPDATA']=$dataRoot
    foreach ($arg in @('--headless','--log-file',$log)+$Arguments) { $info.ArgumentList.Add($arg) }
    $owned=[System.Diagnostics.Process]::new(); $owned.StartInfo=$info
    if (-not $owned.Start()) { throw "Cannot start $Name" }
    $record=@{purpose=$Name; pid=$owned.Id; executable=$Executable; arguments=@($info.ArgumentList); data_root=$dataRoot; start_utc=[DateTime]::UtcNow.ToString('o')}
    $record | ConvertTo-Json -Compress | Add-Content -LiteralPath "$runRoot/launches.jsonl"
    $stdout=$owned.StandardOutput.ReadToEndAsync(); $stderr=$owned.StandardError.ReadToEndAsync()
    if (-not $owned.WaitForExit(180000)) { $owned.Kill(); $owned.WaitForExit(); throw "$Name owned process timed out" }
    $out=$stdout.GetAwaiter().GetResult(); $err=$stderr.GetAwaiter().GetResult()
    $record.exit_code=$owned.ExitCode; $record.end_utc=[DateTime]::UtcNow.ToString('o')
    $record | ConvertTo-Json -Compress | Add-Content -LiteralPath "$runRoot/launches.jsonl"
    if ($owned.ExitCode -ne 0 -or "$out $err" -match 'SCRIPT ERROR:|ERROR:' -or ((Test-Path -LiteralPath $log) -and (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet))) { throw "$Name failed: $err" }
}
Run-Owned 'import' $godot @('--path',$farmRoot,'--editor','--import','--quit')
Run-Owned 'export' $godot @('--path',$farmRoot,'--export-release','Windows Desktop',$preview)
Run-Owned 'export-smoke' $preview @('--','--smoke')
Copy-Item -LiteralPath "$farmRoot/assets/GODOT_COPYRIGHT.txt" -Destination "$runRoot/GODOT_COPYRIGHT.txt"
Copy-Item -LiteralPath "$farmRoot/assets/fonts/OFL.txt" -Destination "$runRoot/FONT_LICENSE.txt"
Copy-Item -LiteralPath "$farmRoot/assets/ui/SOURCES.md" -Destination "$runRoot/UI_SOURCES.txt"
$launcher=@'
@echo off
setlocal
set "APPDATA=%~dp0user-data"
set "LOCALAPPDATA=%~dp0user-data"
if not exist "%~dp0WhistleRanch-preview.exe" (
  echo Preview executable is missing.
  pause
  exit /b 1
)
if not exist "%APPDATA%" mkdir "%APPDATA%"
start "" /D "%~dp0" "%~dp0WhistleRanch-preview.exe"
exit /b 0
'@
[IO.File]::WriteAllText("$runRoot/Play-Isolated.cmd",(($launcher -replace "`r?`n","`r`n")+"`r`n"),[Text.Encoding]::ASCII)
$note=@'
# 分離試遊版

Play-Isolated.cmd を手動でダブルクリックしてください。データ先はこのフォルダの user-data に固定されます。通常版の Play.cmd やセーブへ影響しません。EXE直接起動ではこの分離が適用されないため、必ず専用CMDを使用してください。

最新の死亡/単回蘇生/メイド支援、カテゴリ祈り、ダウン中の役割別標的切替を含む中間版です。全体仮完成版ではありません。Day2に像を調査すると、動物/お金/アイテムを選んで祈り、翌朝受け取れます。未発見の像の位置は敵に知らせません。

終了後のキャンペーン続行保存、後半の成長曲線、明示した到達点はまだ未実装です。難度・面白さは未評価。headlessのWindows出力起動を確認していますが、このCMDでの対話的起動や人間の通し試遊は自動実行していません。ロードマップとTASKSに次の接続を記録しています。

検証情報は BUILD.json と export-smoke.log。古い review/current（0d47970）、通常試遊EXE（8b06e28）とは別物です。
'@
[IO.File]::WriteAllText("$runRoot/README.md",$note,[Text.UTF8Encoding]::new($false))
@{commit=$revision; dirty=$dirty; asset_delivery_commit=$art.latest_delivery_commit; executable='WhistleRanch-preview.exe'; sha256=(Get-FileHash -LiteralPath $preview -Algorithm SHA256).Hash; launcher='Play-Isolated.cmd'; data_root=$dataRoot; headless_export_smoke='passed'; interactive_launch='not run'; scope='intermediate integration preview, not full game completion'} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$runRoot/BUILD.json"
Write-Output "Isolated preview: $runRoot"
