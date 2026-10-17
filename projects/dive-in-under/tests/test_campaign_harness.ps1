$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$artifacts = Join-Path $project 'artifacts'
. (Join-Path $project 'tools/campaign_result.ps1')
$evidence = @()
$dir = Join-Path $artifacts 'campaign-headless'
$replay = Join-Path $artifacts 'campaign-replay.json'
$rejected = $false
try { Assert-CampaignResult -RunDir $dir -RunId 'stale-nonce-test' -Stage complete -Rendered $false -Replay $replay | Out-Null }
catch { $rejected = $_.Exception.Message -like '*run ID mismatch*' }
if (!$rejected) { throw 'Stale campaign success was accepted' }
$evidence += @{case='campaign-stale-nonce'; rejected=$true}
$godot = Join-Path $project '.tools/Godot_v4.7.2-stable_win64_console.exe'
$original = Get-Content $replay -Raw -Encoding utf8 | ConvertFrom-Json
foreach ($kind in @('trace','metrics','floor')) {
    $changed = $original | ConvertTo-Json -Depth 80 | ConvertFrom-Json
    if ($kind -eq 'trace') { $changed.records[0].trace_sha256='bad' }
    elseif ($kind -eq 'metrics') { $changed.metrics.clear_rate=0.5 }
    else { $changed.floors.'10'.deaths+=1 }
    $path = Join-Path $artifacts "campaign-fault-$kind.json"
    [IO.File]::WriteAllText($path,($changed | ConvertTo-Json -Depth 80),[Text.UTF8Encoding]::new($false))
    & $godot --headless --path $project --script tools/campaign_compare.gd -- "--before=$replay" "--after=$path" "--out=$artifacts/campaign-fault-$kind-result.json" --strict=true 2>&1 | Out-File (Join-Path $artifacts "campaign-fault-$kind.log") -Encoding utf8
    if ($LASTEXITCODE -ne 1) { throw "Campaign strict comparison failed to reject $kind" }
    $evidence += @{case="campaign-strict-$kind";rejected=$true;exit_code=1}
}
$evidence | ConvertTo-Json | Set-Content (Join-Path $artifacts 'campaign-harness-faults.json') -Encoding utf8
Write-Output 'CAMPAIGN_HARNESS_FAULTS: 4 cases rejected'
$global:LASTEXITCODE=0
