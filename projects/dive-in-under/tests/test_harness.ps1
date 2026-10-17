$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$artifacts = Join-Path $project 'artifacts'
$evidence = [Collections.Generic.List[object]]::new()
. (Join-Path $project 'tools/smoke_result.ps1')
$rejected = $false
try { Assert-SmokeResult -Path (Join-Path $artifacts 'exe-headless/ui-smoke.json') -RunId 'new-isolated-run-with-old-json' -Rendered $true | Out-Null }
catch { $rejected = $_.Exception.Message -like '*run ID mismatch*' }
if (!$rejected) { throw 'Shared isolated/headless verifier accepted stale JSON' }
$evidence.Add(@{case='shared-isolated-headless-stale-nonce';rejected=$true})
foreach ($fault in @('start','back','omit-result')) {
    $old = Get-FileHash (Join-Path $artifacts 'exe-headless/ui-smoke.json') -Algorithm SHA256
    $rejected = $false
    try { & (Join-Path $project 'tools/smoke.ps1') -Fault $fault }
    catch {
        $message = $_.Exception.Message
        $rejected = if ($fault -eq 'omit-result') { $message -like '*run ID mismatch*' } else { $message -like '*EXE exit*' -or $message -like '*logged errors*' }
    }
    if (!$rejected) { throw "Injected fault was not rejected: $fault" }
    $new = Get-FileHash (Join-Path $artifacts 'exe-headless/ui-smoke.json') -Algorithm SHA256
    if ($old.Hash -ne $new.Hash) { throw 'Failed run wrote a success JSON' }
    $evidence.Add(@{case=$fault; rejected=$true; stale_result_unchanged=$true})
}
$baseline = Get-Content (Join-Path $artifacts 'simulation.json') -Raw -Encoding utf8 | ConvertFrom-Json
$godot = Join-Path $project '.tools/Godot_v4.7.2-stable_win64_console.exe'
foreach ($fault in @('trace','metrics')) {
    $changed = $baseline | ConvertTo-Json -Depth 40 | ConvertFrom-Json
    if ($fault -eq 'trace') { $changed.records[0].log_sha256 = 'injected trace corruption' }
    else { $changed.metrics.win_rate += 0.001 }
    $inputFile=Join-Path $artifacts "fault-$fault.json"
    [IO.File]::WriteAllText($inputFile,($changed | ConvertTo-Json -Depth 40),[Text.UTF8Encoding]::new($false))
    $outputFile=Join-Path $artifacts "fault-$fault-result.json"
    & $godot --headless --path $project --script tools/runner.gd -- --trials=1000 --seed=10000 "--out=$outputFile" "--baseline=$inputFile" --strict=true 2>&1 | Out-File (Join-Path $artifacts "fault-$fault.log") -Encoding utf8
    if ($LASTEXITCODE -ne 1) { throw "Strict replay failed to reject $fault with exit 1" }
    $evidence.Add(@{case="strict-$fault";rejected=$true;exit_code=$LASTEXITCODE})
}
$evidence | ConvertTo-Json | Set-Content (Join-Path $artifacts 'harness-faults.json') -Encoding utf8
# Restore a successful current EXE log/result after negative tests.
& (Join-Path $project 'tools/smoke.ps1')
Write-Output 'HARNESS_FAULT_TESTS: 6 cases rejected as expected'
# GitHub's pwsh wrapper exits with LASTEXITCODE. The expected native exit 1
# must not leak after every rejection and the final positive smoke passed.
$global:LASTEXITCODE = 0
