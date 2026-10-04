# Parse the real launcher with cmd.exe without ever starting the game.
$ErrorActionPreference='Stop'
$farmRoot=Split-Path -Parent $PSScriptRoot
$source=Join-Path $farmRoot 'Play.cmd'
$bytes=[IO.File]::ReadAllBytes($source)
$text=[Text.Encoding]::UTF8.GetString($bytes)
if($text -match '(?<!\r)\n') { throw 'Play.cmd must use CRLF, not LF.' }
$runRoot=Join-Path $farmRoot ('artifacts/launcher-test/'+[Guid]::NewGuid().ToString('N')+'/空白 folder')
New-Item -ItemType Directory -Force "$runRoot/build" | Out-Null
$launch='start "" /D "%~dp0build" "%~dp0build\WhistleRanch.exe"'
if(-not $text.Contains($launch)) { throw 'Launcher changed: update the non-launching parser test.' }
# Intercept only process creation and the interactive pause. Keep encoding,
# conditionals, %~dp0 expansion and messages identical to the real launcher.
$probe=$text.Replace($launch,'echo LAUNCH_OK').Replace('  pause','  echo PAUSE_EXPECTED')
[IO.File]::WriteAllText("$runRoot/Play.cmd",$probe,[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText("$runRoot/build/WhistleRanch.exe",'not executable')
$present=(& $env:ComSpec /d /c "$runRoot/Play.cmd" 2>&1 | Out-String).Trim()
if($LASTEXITCODE -ne 0 -or $present -ne 'LAUNCH_OK') { throw "Existing build branch failed: $present" }
# This is the dummy file created above, never the published game.
Remove-Item -LiteralPath "$runRoot/build/WhistleRanch.exe"
$missing=(& $env:ComSpec /d /c "$runRoot/Play.cmd" 2>&1 | Out-String).Trim()
if($LASTEXITCODE -ne 1 -or $missing -notmatch 'PAUSE_EXPECTED' -or $missing -match 'LAUNCH_OK|not recognized') { throw "Missing build branch failed: $missing" }
Write-Output 'PASS: CRLF; cmd.exe existing/missing build branches; spaces and Japanese path; no game launched.'
