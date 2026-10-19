param([string]$GameCommit = '', [int]$Trials = 3)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
if (!$GameCommit) { $GameCommit = git -C $project rev-parse HEAD }
$godot = Join-Path $project '.tools/Godot_v4.7.2-stable_win64_console.exe'
$artifacts = Join-Path $project 'artifacts'
$oldAppData = $env:APPDATA
$env:APPDATA = Join-Path $artifacts 'campaign-runner-user'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
function Invoke-Campaign([string]$Name,[string[]]$Extra) {
    $log = Join-Path $artifacts "$Name.log"
    & $godot --headless --path $project --log-file $log --script tools/campaign_runner.gd -- "--trials=$Trials" --seed=10000 "--out=$artifacts/$Name.json" "--commit=$GameCommit" @Extra
    if ($LASTEXITCODE -ne 0) { throw "$Name failed: $LASTEXITCODE" }
    if (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet) { throw "$Name logged errors" }
}
try {
    Invoke-Campaign 'campaign-before' @('--config=res://data/v1/expedition-no-defense.json')
    Invoke-Campaign 'campaign-after' @("--baseline=$artifacts/campaign-before.json")
    Invoke-Campaign 'campaign-repeat' @("--baseline=$artifacts/campaign-after.json",'--strict=true')
    $Trials = 1
    Invoke-Campaign 'campaign-replay' @('--trace=true')
} finally { $env:APPDATA = $oldAppData }
