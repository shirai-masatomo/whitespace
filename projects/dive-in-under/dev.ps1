param(
    [ValidateSet('test','simulate','build','verify','play','campaign')][string]$Task = 'verify',
    [int]$Trials = 8,
    [int]$Seed = 10000,
    [string]$Scenario = 'res://data/scenarios/baseline.json',
    [string]$Baseline = '',
    [string]$Output = '',
    [string]$GameCommit = '',
    [switch]$StrictRepeat
)
$ErrorActionPreference = 'Stop'
$project = $PSScriptRoot
$lock = Get-Content (Join-Path $project 'tools/godot-version.json') -Raw | ConvertFrom-Json
$godot = Join-Path $project ".tools/Godot_v$($lock.version)_win64_console.exe"
if (!(Test-Path $godot)) { throw 'Run tools/setup.ps1 first.' }
$version = & $godot --version
if ($version.Trim() -ne $lock.runtime_version) { throw "Wrong Godot version: $version" }
$artifacts = Join-Path $project 'artifacts'
New-Item -ItemType Directory -Force $artifacts | Out-Null
Set-Content (Join-Path $artifacts '.gdignore') ''
$oldAppData = $env:APPDATA
$env:APPDATA = Join-Path $artifacts 'user-data'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
if (!$GameCommit) {
    $GameCommit = git -C $project rev-parse HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Cannot identify source commit; pass -GameCommit explicitly.' }
    $dirty = git -C $project status --porcelain -- .
    if ($dirty) { $GameCommit += '+dirty' }
}
function Run-Godot([string]$Name, [string[]]$Arguments) {
    $logPath = Join-Path $artifacts "$Name.log"
    & $godot --headless --path $project --log-file $logPath @Arguments 2>&1 | Tee-Object (Join-Path $artifacts "$Name.console.log")
    if ($LASTEXITCODE -ne 0) { throw "$Name failed: exit $LASTEXITCODE" }
    if (Select-String -LiteralPath $logPath -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet) { throw "$Name logged an engine error" }
}
try {
    if ($Task -in @('test','verify')) {
        Run-Godot 'storage-tests' @('--script','tests/test_storage.gd')
        Run-Godot 'equipment-condition-tests' @('--script','tests/test_equipment_condition.gd')
        Run-Godot 'tests' @('--script','tests/test_combat.gd')
        Run-Godot 'status-tests' @('--script','tests/test_status.gd')
        Run-Godot 'area1-encounter-tests' @('--script','tests/test_area1_encounters.gd')
        Run-Godot 'enemy-pack-tests' @('--script','tests/test_enemy_pack.gd')
        Run-Godot 'defense-tests' @('--script','tests/test_defense.gd')
        Run-Godot 'loop-tests' @('--script','tests/test_expedition.gd')
        Run-Godot 'campaign-tests' @('--script','tests/test_campaign.gd')
        Run-Godot 'first-expedition-tests' @('--script','tests/test_first_expedition.gd')
        Run-Godot 'ui-headless' @('--',"--smoke-dir=$artifacts","--smoke-run-id=$([guid]::NewGuid().ToString('N'))")
    }
    if ($Task -in @('simulate','verify')) {
        if (!$Output) { $Output = Join-Path $artifacts 'simulation.json' }
        $simArgs = @('--script','tools/runner.gd','--',"--trials=$Trials","--seed=$Seed","--scenario=$Scenario","--out=$Output","--commit=$GameCommit")
        if ($Baseline) { $simArgs += "--baseline=$Baseline" }
        if ($StrictRepeat) { $simArgs += '--strict=true' }
        Run-Godot 'simulation' $simArgs
    }
    if ($Task -eq 'campaign') {
        if (!$Output) { $Output = Join-Path $artifacts 'campaign.json' }
        $args = @('--script','tools/campaign_runner.gd','--',"--trials=$Trials","--seed=$Seed","--out=$Output","--commit=$GameCommit")
        if ($Baseline) { $args += "--baseline=$Baseline" }
        if ($StrictRepeat) { $args += '--strict=true' }
        Run-Godot 'campaign' $args
    }
    if ($Task -in @('build','verify')) {
        # Never overwrite a live user's executable or PCK. Each export is immutable.
        $buildKey = ($GameCommit -replace '[^a-zA-Z0-9-]', '_') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
        $relativeBuild = 'releases/' + $buildKey
        $build = Join-Path $project ('build/' + $relativeBuild)
        if (Test-Path $build) { throw 'Refusing to overwrite an existing release directory' }
        New-Item -ItemType Directory -Force $build | Out-Null
        Set-Content (Join-Path $project 'build/.gdignore') ''
        Run-Godot 'import' @('--editor','--import','--quit')
        Run-Godot 'export' @('--export-release','Windows Desktop',(Join-Path $build 'DiveInUnder.exe'))
        Copy-Item (Join-Path $project 'tools/PLAY.txt') $build
        Copy-Item (Join-Path $project 'assets/licenses/GODOT_LICENSE.txt') $build
        Copy-Item (Join-Path $project 'assets/licenses/GODOT_COPYRIGHT.txt') $build
        @{ game_commit=$GameCommit; engine=$version.Trim(); data_version=(Get-Content (Join-Path $project 'data/v1/balance.json') -Raw | ConvertFrom-Json).data_version; campaign_config_version=(Get-Content (Join-Path $project 'data/v1/expedition.json') -Raw | ConvertFrom-Json).config_version } | ConvertTo-Json | Set-Content (Join-Path $build 'BUILD.json') -Encoding utf8
        Compress-Archive -Path (Join-Path $build '*') -DestinationPath (Join-Path $project 'build/DiveInUnder-foundation-windows-x64.zip') -Force
        Set-Content (Join-Path $project 'build/candidate.txt') $relativeBuild -Encoding ascii
        Get-FileHash (Join-Path $project 'build/DiveInUnder-foundation-windows-x64.zip') -Algorithm SHA256 | Format-List
    }
    if ($Task -eq 'play') {
        & $godot --path $project
    }
} finally { $env:APPDATA = $oldAppData }
