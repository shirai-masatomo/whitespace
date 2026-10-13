param([switch]$Baseline)
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
    $environment['FARM_STARTUP_BASELINE']=if($Baseline){'1'}else{'0'}
    $environment['APPDATA']=Join-Path $runRoot 'user-data';$environment['LOCALAPPDATA']=$environment['APPDATA'];$environment['FARM_REVIEW_OUTPUT']=$runRoot;$environment['FARM_REVIEW_COMMIT']=(git -C $farmRoot rev-parse HEAD).Trim()
    $exe=Join-Path $farmRoot '.tools/Godot_v4.7.2-stable_win64.exe'
    $cmd='"'+$exe+'" --path "'+$farmRoot+'" --audio-driver Dummy --rendering-method gl_compatibility --max-fps 60 --resolution 1280x800 --log-file "'+$runRoot+'/startup-render.log" --script tests/review_startup.gd -- --isolated-review'
    $audit=@{source_commit=$environment['FARM_REVIEW_COMMIT'];command=$cmd;start_utc=[DateTime]::UtcNow.ToString('o')}
    $audit.working_tree_changes=[bool](git -C $farmRoot status --porcelain);$audit.source_sha256=@{};foreach($source in Get-ChildItem -LiteralPath (Join-Path $farmRoot 'game') -File -Filter '*.gd'){$audit.source_sha256[$source.Name]=(Get-FileHash -LiteralPath $source.FullName -Algorithm SHA256).Hash}
    try {$audit.result=[FarmIsolatedDesktop]::Run($exe,$cmd,$farmRoot,$environment,240)}
    finally {$audit.end_utc=[DateTime]::UtcNow.ToString('o');$audit|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $runRoot 'startup-isolation.json') -Encoding utf8}
    if($audit.result.ExitCode -ne 0 -or -not $audit.result.NonInteractive -or -not $audit.result.DesktopMatched){throw 'Startup GPU verification failed; no desktop fallback.'}
    if(Select-String -LiteralPath (Join-Path $runRoot 'startup-render.log') -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet){throw 'Startup script/render error'}
    $evidence=Join-Path $farmRoot 'review/current/startup';New-Item -ItemType Directory -Force $evidence|Out-Null
    $prefix=if($Baseline){'before'}else{'after'}
    Copy-Item -LiteralPath (Join-Path $runRoot 'startup.json') -Destination (Join-Path $evidence ($prefix+'.json'))
    Copy-Item -LiteralPath (Join-Path $runRoot 'startup-isolation.json') -Destination (Join-Path $evidence ($prefix+'-isolation.json'))
    foreach($file in Get-ChildItem -LiteralPath $runRoot -File -Filter '*.png'){Copy-Item -LiteralPath $file.FullName -Destination $evidence}
    $succeeded=$true
} finally {Complete-FarmScratch $farmRoot $runRoot 'startup_visual' $succeeded}
