param([ValidateSet('check', 'test', 'evaluate', 'build', 'visual', 'play', 'editor')][string]$Task = 'check', [string[]]$Suites = @('revisions','residents','world','jobs','keeper','planning','rest_until','input'))
$ErrorActionPreference = 'Stop'
$farmRoot = $PSScriptRoot
$godot = Join-Path $farmRoot '.tools/Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $godot)) { throw 'Run ./tools/setup.ps1 first.' }
if ($Task -eq 'visual') { throw 'GUI verification deferred: focus safety at window creation is not verified. Use headless tests.' }
# Only explicit user launch paths may create windows. Verification never calls these.
if ($Task -in @('play', 'editor')) {
    $launchArgs = @('--path', $farmRoot)
    if ($Task -eq 'editor') { $launchArgs += '--editor' }
    & $godot @launchArgs
    exit $LASTEXITCODE
}
$runRoot = Join-Path $farmRoot ('artifacts/validation/' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Force $runRoot, "$runRoot/user-data" | Out-Null
Set-Content -LiteralPath "$farmRoot/artifacts/.gdignore" -Value ''
$revision = (git -C $farmRoot rev-parse --short HEAD).Trim()
$dirty = [bool](git -C $farmRoot status --porcelain)
@{commit=$revision; dirty=$dirty} | ConvertTo-Json | Set-Content -LiteralPath "$farmRoot/game/build_stamp.json"
function Run-Headless([string]$Name, [string[]]$Arguments, [string]$Executable=$godot) {
    $log = Join-Path $runRoot "$Name.log"
    $info = [System.Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $Executable
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.Environment['APPDATA'] = "$runRoot/user-data"
    $info.Environment['LOCALAPPDATA'] = "$runRoot/user-data"
    $baseArgs = @('--headless','--log-file',$log)
    if ($Executable -eq $godot) { $baseArgs += @('--path',$farmRoot) }
    $info.WorkingDirectory = Split-Path -Parent $Executable
    foreach ($arg in ($baseArgs + $Arguments)) { $info.ArgumentList.Add($arg) }
    $record = @{purpose=$Name; parent_pid=$PID; executable=$Executable; arguments=@($info.ArgumentList); start_utc=[DateTime]::UtcNow.ToString('o'); data_root="$runRoot/user-data"}
    $owned = [System.Diagnostics.Process]::new()
    $owned.StartInfo = $info
    if (-not $owned.Start()) { throw "Cannot start $Name" }
    $record.pid=$owned.Id
    $record | ConvertTo-Json -Compress | Add-Content -LiteralPath "$runRoot/launches.jsonl"
    $stdout=$owned.StandardOutput.ReadToEndAsync()
    $stderr=$owned.StandardError.ReadToEndAsync()
    if (-not $owned.WaitForExit(180000)) { $owned.Kill(); $owned.WaitForExit(); $record.result='owned process timed out' }
    else { $record.result=$owned.ExitCode }
    $record.end_utc=[DateTime]::UtcNow.ToString('o')
    $record | ConvertTo-Json -Compress | Add-Content -LiteralPath "$runRoot/launches.jsonl"
    $out=$stdout.GetAwaiter().GetResult(); $err=$stderr.GetAwaiter().GetResult()
    Write-Output $out
    if ($owned.ExitCode -ne 0 -or $record.result -is [string] -or "$out $err" -match 'SCRIPT ERROR:|ERROR:' -or ((Test-Path $log) -and (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet))) { throw "$Name failed: $err" }
}
if ($Task -in @('check','test','build')) {
    Run-Headless 'import' @('--editor','--import','--quit')
    foreach ($suite in $Suites) { Run-Headless $suite @('--script',"tests/test_$suite.gd") }
}
if ($Task -in @('check','evaluate')) { Run-Headless 'evaluate' @('--script','tests/evaluate.gd') }
if ($Task -in @('check','build')) {
    $testExe=Join-Path $runRoot 'WhistleRanch-test.exe'
    Run-Headless 'export' @('--export-release','Windows Desktop',$testExe)
    Run-Headless 'export-smoke' @('--','--smoke') $testExe
}
Write-Output "Verification artifacts: $runRoot"
