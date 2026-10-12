param()
$ErrorActionPreference='Stop'
$farmRoot=Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'workspace_lifecycle.ps1')
$runRoot=Start-FarmScratch $farmRoot (Join-Path $farmRoot 'artifacts/isolated/current')
New-Item -ItemType Directory -Force (Join-Path $runRoot 'user-data')|Out-Null
$succeeded=$false
try{
    Initialize-FarmImports $farmRoot $runRoot
    Add-Type -Path (Join-Path $PSScriptRoot 'isolated_desktop.cs')
    $environment=[Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
    [Environment]::GetEnvironmentVariables().GetEnumerator()|ForEach-Object {$environment[$_.Key]=[string]$_.Value}
    $environment['APPDATA']=Join-Path $runRoot 'user-data';$environment['LOCALAPPDATA']=$environment['APPDATA'];$environment['FARM_REVIEW_OUTPUT']=$runRoot;$environment['FARM_REVIEW_COMMIT']=(git -C $farmRoot rev-parse HEAD).Trim()
    $exe=Join-Path $farmRoot '.tools/Godot_v4.7.2-stable_win64.exe'
    $cmd='"'+$exe+'" --path "'+$farmRoot+'" --audio-driver Dummy --rendering-method gl_compatibility --max-fps 30 --resolution 1280x800 --log-file "'+$runRoot+'/harvest-render.log" --script tests/review_harvest_visual.gd -- --isolated-review'
    $audit=@{source_commit=$environment['FARM_REVIEW_COMMIT'];command=$cmd;start_utc=[DateTime]::UtcNow.ToString('o');asset_delivery_commit=(Get-Content -LiteralPath (Join-Path $farmRoot 'game/art_provenance.json') -Raw|ConvertFrom-Json).latest_delivery_commit}
    try{$audit.result=[FarmIsolatedDesktop]::Run($exe,$cmd,$farmRoot,$environment,60)}
    finally{$audit.end_utc=[DateTime]::UtcNow.ToString('o');$audit|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $runRoot 'harvest-isolation.json') -Encoding utf8}
    if($audit.result.ExitCode -ne 0 -or -not $audit.result.NonInteractive -or -not $audit.result.DesktopMatched){throw 'Harvest GPU verification failed; no desktop fallback.'}
    if(Select-String -LiteralPath (Join-Path $runRoot 'harvest-render.log') -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet){throw 'Harvest script/render error'}
    $evidence=Join-Path $farmRoot 'review/current/harvest';New-Item -ItemType Directory -Force $evidence|Out-Null
    & 'C:/Users/masat/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' (Join-Path $PSScriptRoot 'encode_harvest.py') $runRoot $evidence
    if($LASTEXITCODE -ne 0){throw 'Sequence encoding failed'}
    foreach($name in @('mine_start.png','mine_strike.png','mine_near_complete.png','mine_after.png','clear_tree_start.png','clear_tree_strike.png','clear_tree_near_complete.png','clear_tree_after.png','mine_hit.wav','chop_hit.wav','rock_crumble.wav','tree_fall.wav','harvest-visual.json','harvest-isolation.json','harvest-stages.json')){Copy-Item -LiteralPath (Join-Path $runRoot $name) -Destination (Join-Path $evidence $name)}
    $succeeded=$true
}finally{Complete-FarmScratch $farmRoot $runRoot 'harvest_visual' $succeeded}
