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
    $cmd='"'+$exe+'" --path "'+$farmRoot+'" --audio-driver Dummy --rendering-method gl_compatibility --max-fps 30 --resolution 1280x800 --log-file "'+$runRoot+'/rock-render.log" --script tests/review_rock_connections.gd -- --isolated-review'
    $audit=@{source_commit=$environment['FARM_REVIEW_COMMIT'];command=$cmd;start_utc=[DateTime]::UtcNow.ToString('o');asset_delivery_commit=(Get-Content -LiteralPath (Join-Path $farmRoot 'game/art_provenance.json') -Raw|ConvertFrom-Json).latest_delivery_commit}
    try{$audit.result=[FarmIsolatedDesktop]::Run($exe,$cmd,$farmRoot,$environment,90)}
    finally{$audit.end_utc=[DateTime]::UtcNow.ToString('o');$audit|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $runRoot 'rock-isolation.json') -Encoding utf8}
    if($audit.result.ExitCode -ne 0 -or -not $audit.result.NonInteractive -or -not $audit.result.DesktopMatched){throw 'Harvest GPU verification failed; no desktop fallback.'}
    if(Select-String -LiteralPath (Join-Path $runRoot 'rock-render.log') -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet){throw 'Harvest script/render error'}
    $evidence=Join-Path $farmRoot 'review/current/rock_connections';New-Item -ItemType Directory -Force $evidence|Out-Null
    & 'C:/Users/masat/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' (Join-Path $PSScriptRoot 'encode_rock_connections.py') $runRoot $evidence
    if($LASTEXITCODE -ne 0){throw 'Sequence encoding failed'}
    foreach($file in Get-ChildItem -LiteralPath $runRoot -File | Where-Object {($_.Extension -eq '.png' -and $_.Name -notlike 'frame_*') -or $_.Name -in @('rock-observations.json','rock-isolation.json','rock-stages.json')}){Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $evidence $file.Name)}
    $succeeded=$true
}finally{Complete-FarmScratch $farmRoot $runRoot 'rock_connections_visual' $succeeded}
