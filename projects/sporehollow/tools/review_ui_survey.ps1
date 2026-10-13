param([switch]$Quality,[switch]$MapExpansion,[switch]$SelectionControls,[switch]$TerrainQuality,[switch]$Before)
$ErrorActionPreference='Stop'
$farmRoot=Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'workspace_lifecycle.ps1')
$runRoot=Start-FarmScratch $farmRoot (Join-Path $farmRoot 'artifacts/isolated/current')
New-Item -ItemType Directory -Force (Join-Path $runRoot 'user-data')|Out-Null
$succeeded=$false
try {
    Initialize-FarmImports $farmRoot $runRoot
    Add-Type -Path (Join-Path $PSScriptRoot 'isolated_desktop.cs')
    $environment=[Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
    [Environment]::GetEnvironmentVariables().GetEnumerator()|ForEach-Object {$environment[$_.Key]=[string]$_.Value}
    $environment['APPDATA']=Join-Path $runRoot 'user-data';$environment['LOCALAPPDATA']=$environment['APPDATA'];$environment['FARM_REVIEW_OUTPUT']=$runRoot;$environment['FARM_REVIEW_COMMIT']=(git -C $farmRoot rev-parse HEAD).Trim()
    $exe=Join-Path $farmRoot '.tools/Godot_v4.7.2-stable_win64.exe'
    $environment['FARM_TERRAIN_BEFORE']=if($Before){'1'}else{'0'}
    $scenario=if($TerrainQuality){'tests/review_terrain_quality.gd'}elseif($SelectionControls){'tests/test_selection_controls.gd'}elseif($MapExpansion){'tests/review_map_expansion.gd'}elseif($Quality){'tests/review_quality.gd'}else{'tests/review_ui_survey.gd'}
    $cmd='"'+$exe+'" --path "'+$farmRoot+'" --audio-driver Dummy --rendering-method gl_compatibility --max-fps 30 --resolution 1280x800 --log-file "'+$runRoot+'/ui-survey-render.log" --script '+$scenario+' -- --isolated-review'
    $audit=@{source_commit=$environment['FARM_REVIEW_COMMIT'];command=$cmd;start_utc=[DateTime]::UtcNow.ToString('o')}
    $audit.working_tree_changes=[bool](git -C $farmRoot status --porcelain);$audit.source_sha256=@{};foreach($source in Get-ChildItem -LiteralPath (Join-Path $farmRoot 'game') -File -Filter '*.gd'){$audit.source_sha256[$source.Name]=(Get-FileHash -LiteralPath $source.FullName -Algorithm SHA256).Hash}
    try {$audit.result=[FarmIsolatedDesktop]::Run($exe,$cmd,$farmRoot,$environment,420)}
    finally {$audit.end_utc=[DateTime]::UtcNow.ToString('o');$audit|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $runRoot 'ui-survey-isolation.json') -Encoding utf8}
    if(-not $audit.result.NonInteractive -or -not $audit.result.DesktopMatched){throw 'GPU isolation mismatch; no desktop fallback.'}
    $errors=@(Get-Content -LiteralPath (Join-Path $runRoot 'ui-survey-render.log') | Where-Object {$_ -match 'SCRIPT ERROR:|ERROR:|at: draw|res://game/colony_task_controls.gd'} | Select-Object -Unique)
    @{game_errors=$errors;visual_test_passed=($errors.Count -eq 0);note='Survey captures current defects; errors are findings, not a passing runtime test.'}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $runRoot 'ui-errors.json') -Encoding utf8
    $evidence=Join-Path $farmRoot $(if($TerrainQuality){if($Before){'review/current/terrain_quality/before'}else{'review/current/terrain_quality'}}elseif($SelectionControls){'review/current/selection_controls'}elseif($MapExpansion){'review/current/map_expansion'}elseif($Quality){'review/current/quality'}else{'review/current/ui_survey'});New-Item -ItemType Directory -Force $evidence|Out-Null
    foreach($file in Get-ChildItem -LiteralPath $runRoot -File | Where-Object {$_.Extension -eq '.png' -or $_.Name -in @('terrain-performance.json','camera-performance.json','ui-survey.json','ui-survey-isolation.json','ui-errors.json')}){Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $evidence $file.Name)}
    if(($Quality -or $MapExpansion -or $SelectionControls -or $TerrainQuality) -and $errors.Count -gt 0){throw "Quality capture has game errors; evidence preserved"}
    if($audit.result.ExitCode -ne 0){throw 'GPU test assertion failed; captured evidence retained.'}
    $succeeded=$true
} finally {Complete-FarmScratch $farmRoot $runRoot 'ui_survey_visual' $succeeded}
