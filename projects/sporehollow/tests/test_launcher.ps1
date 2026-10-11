param([string]$WorkRoot='')
$ErrorActionPreference='Stop'
$project=Split-Path -Parent $PSScriptRoot
. (Join-Path $project 'tools/workspace_lifecycle.ps1')
$owns=$WorkRoot -eq ''
if($owns){$WorkRoot=Start-FarmScratch $project (Join-Path $project 'artifacts/launcher-test/current')}
else{Assert-FarmGeneratedPath $project $WorkRoot | Out-Null}
$success=$false
try {
    $text=[Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes((Join-Path $project 'Play.cmd')))
    if($text -match '(?<!\r)\n'){throw 'Play.cmd needs CRLF'}
    $launch='powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\launch_current.ps1"'
    if(-not $text.Contains($launch)){throw 'Unexpected launcher; parser test must be updated'}
    $case=Join-Path $WorkRoot 'launcher/空白 folder'
    $target=Join-Path $case 'artifacts/autonomy-entry-01/bundle/WhistleRanch-Autonomy-Partial.exe'
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    [IO.File]::WriteAllText((Join-Path $case 'Play.cmd'),$text.Replace($launch,'echo LAUNCH_OK').Replace('  pause','  echo PAUSE_EXPECTED'),[Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($target,'not executable')
    $present=(& $env:ComSpec /d /c (Join-Path $case 'Play.cmd') 2>&1 | Out-String).Trim()
    if($LASTEXITCODE -ne 0 -or $present -ne 'LAUNCH_OK'){throw "Launcher existing target failed: $present"}
    Remove-Item -LiteralPath $target
    $missing=(& $env:ComSpec /d /c (Join-Path $case 'Play.cmd') 2>&1 | Out-String).Trim()
    if($LASTEXITCODE -ne 1 -or $missing -notmatch 'PAUSE_EXPECTED' -or $missing -match 'LAUNCH_OK|not recognized'){throw "Launcher missing target failed: $missing"}
    @{passed=$true;checks=3;method='CRLF and cmd.exe present/missing mock files; no game launch'} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $WorkRoot 'launcher.json')
    $success=$true;Write-Output 'PASS: CRLF, present/missing target, spaces/Japanese path; no game launched'
}finally{if($owns){Complete-FarmScratch $project $WorkRoot 'launcher' $success}}
