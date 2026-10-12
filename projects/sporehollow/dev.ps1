param([ValidateSet('check', 'test', 'evaluate', 'build', 'visual', 'play', 'editor', 'clean')][string]$Task = 'check', [string[]]$Suites = @('wall_drag','day_music','animal_commands','animal_corpse','journal_layout_ui','playthrough_ui','debug_lifecycle','revisions','residents','world','jobs','keeper','planning','rest_until','input','controls','building_art','delivered_art','progression_art','idol_debug','ranch_content','ranch_content_ui','quality','quality_ui','corpses','target_policy','navigation','forest','forest_ui','market_ui','story','story_ui','prayer','prayer_ui','progression','progression_flow','campaign_route','campaign_tiers','campaign_route_ui','morning_save','morning_save_ui','progression_ui','combat_revision','ui_revision'), [ValidateRange(1,32)][int]$AISeeds=32)
$ErrorActionPreference = 'Stop'
$farmRoot = $PSScriptRoot
. (Join-Path $farmRoot 'tools/workspace_lifecycle.ps1')
if($Task -eq 'clean'){& (Join-Path $farmRoot 'tools/maintenance.ps1') -Clean;exit 0}
$godot = Join-Path $farmRoot '.tools/Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $godot)) { throw 'Run ./tools/setup.ps1 first.' }
if ($Task -eq 'visual') { & "$farmRoot/tools/isolated_visual.ps1" -Scenario characters; exit $LASTEXITCODE }
# Only explicit user launch paths may create windows. Verification never calls these.
if($Task -eq 'play'){& (Join-Path $farmRoot 'tools/launch_current.ps1');exit 0}
if ($Task -eq 'editor') {
    $launchArgs = @('--path', $farmRoot)
    if ($Task -eq 'editor') { $launchArgs += '--editor' }
    & $godot @launchArgs
    exit $LASTEXITCODE
}
$runRoot = Start-FarmScratch $farmRoot (Join-Path $farmRoot 'artifacts/validation/current')
New-Item -ItemType Directory -Force $runRoot, "$runRoot/user-data" | Out-Null
Set-Content -LiteralPath "$farmRoot/artifacts/.gdignore" -Value ''
$succeeded=$false
try {
$revision = (git -C $farmRoot rev-parse --short HEAD).Trim()
$dirty = [bool](git -C $farmRoot status --porcelain)
$artProvenance=Get-Content -LiteralPath "$farmRoot/game/art_provenance.json" -Raw | ConvertFrom-Json
@{commit=$revision; dirty=$dirty; asset_delivery_commit=$artProvenance.latest_delivery_commit} | ConvertTo-Json | Set-Content -LiteralPath "$farmRoot/game/build_stamp.json"
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
    $info.Environment['FARM_REVIEW_OUTPUT']=$runRoot
    $info.Environment['FARM_LEGACY_FIXTURE']=Join-Path $farmRoot 'review/current/biome01/tests/legacy-fixture'
    if ($Name -eq 'evaluate') { $info.Environment['FARM_AI_SEEDS'] = [string]$AISeeds }
    if($Name -eq 'animal_size') {
        git -C $farmRoot show eba972e:projects/sporehollow/game/main.gd | Set-Content -LiteralPath (Join-Path $runRoot 'baseline_main.gd') -Encoding utf8
        $info.Environment['ANIMAL_SIZE_PROBE_ROOT']=$runRoot
    }
    $baseArgs = @('--headless','--audio-driver','Dummy','--max-fps','30','--log-file',$log)
    if ($Executable -eq $godot) { $baseArgs += @('--path',$farmRoot) }
    $info.WorkingDirectory = Split-Path -Parent $Executable
    foreach ($arg in ($baseArgs + $Arguments)) { $info.ArgumentList.Add($arg) }
    $record = @{purpose=$Name; parent_pid=$PID; executable=$Executable; arguments=@($info.ArgumentList); start_utc=[DateTime]::UtcNow.ToString('o'); data_root="$runRoot/user-data"}
    $owned = [System.Diagnostics.Process]::new()
    $owned.StartInfo = $info
    if (-not $owned.Start()) { throw "Cannot start $Name" }
    $owned.PriorityClass='BelowNormal' # Verification yields CPU priority to the user's active game.
    $record.pid=$owned.Id
    $record | ConvertTo-Json -Compress | Add-Content -LiteralPath "$runRoot/launches.jsonl"
    $stdout=$owned.StandardOutput.ReadToEndAsync()
    $stderr=$owned.StandardError.ReadToEndAsync()
    if (-not $owned.WaitForExit(180000)) { $owned.Kill(); $owned.WaitForExit(); $record.result='owned process timed out' }
    else { $record.result=$owned.ExitCode }
    $record.end_utc=[DateTime]::UtcNow.ToString('o')
    $record | ConvertTo-Json -Compress | Add-Content -LiteralPath "$runRoot/launches.jsonl"
    $out=$stdout.GetAwaiter().GetResult(); $err=$stderr.GetAwaiter().GetResult()
    Write-Output "$Name completed (full log retained until review capture)"
    if ($owned.ExitCode -ne 0 -or $record.result -is [string] -or "$out $err" -match 'SCRIPT ERROR:|ERROR:' -or ((Test-Path $log) -and (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet))) { throw "$Name failed: $err" }
}
if ($Task -in @('check','test','build')) {
    & "$farmRoot/tests/test_launcher.ps1" -WorkRoot $runRoot
    Run-Headless 'import' @('--editor','--import','--quit')
    foreach ($suite in $Suites) { Run-Headless $suite @('--script',"tests/test_$suite.gd",'--','--isolated-review') }
}
if ($Task -in @('check','evaluate')) { Run-Headless 'evaluate' @('--script','tests/evaluate.gd') }
if ($Task -in @('check','build')) {
    $testExe=Join-Path $runRoot 'WhistleRanch-test.exe'
    Run-Headless 'export' @('--export-release','Windows Desktop',$testExe)
    Run-Headless 'export-smoke' @('--','--smoke') $testExe
    if ($Task -eq 'build') { & "$farmRoot/tools/publish_build.ps1" -Executable $testExe -Revision $revision -Dirty $dirty }
}
$succeeded=$true
} finally {Complete-FarmScratch $farmRoot $runRoot $Task $succeeded}
