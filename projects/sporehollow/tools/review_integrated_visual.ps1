param()
$ErrorActionPreference='Stop'
$farmRoot=Split-Path -Parent $PSScriptRoot
# A standard release EXE silently ignores --script. Use the editor-capable Godot.
$exe=Join-Path $farmRoot '.tools/Godot_v4.7.2-stable_win64.exe'
$console=Join-Path $farmRoot '.tools/Godot_v4.7.2-stable_win64_console.exe'
$capabilities=((& $console --headless --help) -join "`n") -replace '\x1B\[[0-9;]*m',''
if($LASTEXITCODE -ne 0 -or -not($capabilities -match '--script\s+<script>')){throw 'Capture requires a Godot executable supporting --script; do not launch a release EXE.'}
. (Join-Path $PSScriptRoot 'workspace_lifecycle.ps1')
$runRoot=Start-FarmScratch $farmRoot (Join-Path $farmRoot 'artifacts/isolated/current')
New-Item -ItemType Directory -Force (Join-Path $runRoot 'user-data')|Out-Null
$succeeded=$false
try{
    Initialize-FarmImports $farmRoot $runRoot
    Add-Type -Path (Join-Path $PSScriptRoot 'isolated_desktop.cs')
    $environment=[Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
    [Environment]::GetEnvironmentVariables().GetEnumerator()|ForEach-Object {$environment[$_.Key]=[string]$_.Value}
    $environment['APPDATA']=Join-Path $runRoot 'user-data';$environment['LOCALAPPDATA']=$environment['APPDATA']
    $environment['FARM_REVIEW_OUTPUT']=$runRoot;$environment['FARM_REVIEW_CASE']='source_game'
    $environment['FARM_REVIEW_COMMIT']=(git -C $farmRoot rev-parse HEAD).Trim()
    $build=Get-Content -LiteralPath (Join-Path $farmRoot 'artifacts/autonomy-entry-01/bundle/BUILD.json') -Raw|ConvertFrom-Json
    $changed=@(git -C $farmRoot diff --name-only $build.implementation_commit -- game | Where-Object {$_ -match '\.(gd|tscn|tres)$'})
    $cmd='"'+$exe+'" --path "'+$farmRoot+'" --audio-driver Dummy --rendering-method gl_compatibility --max-fps 30 --resolution 1280x800 --log-file "'+$runRoot+'/capture.log" --script "'+(Join-Path $farmRoot 'tests/review_integrated_visual.gd')+'" -- --isolated-review'
    $record=@{implementation_commit=$environment['FARM_REVIEW_COMMIT'];published_exe_commit=$build.implementation_commit;published_exe_sha256=$build.sha256;game_code_matches_published_exe=($changed.Count -eq 0);game_code_changes=$changed;asset_delivery_commit=$build.asset_delivery_commit;command=$cmd;start_utc=[DateTime]::UtcNow.ToString('o');executable=$exe;executable_sha256=(Get-FileHash -LiteralPath $exe).Hash}
    try{$record.result=[FarmIsolatedDesktop]::Run($exe,$cmd,$farmRoot,$environment,30)}
    finally{$record.end_utc=[DateTime]::UtcNow.ToString('o');$record|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $runRoot 'capture-isolation.json') -Encoding utf8}
    if($record.result.ExitCode -ne 0 -or -not $record.result.NonInteractive -or -not $record.result.DesktopMatched){throw 'Capture failed; inspect checkpoints. No normal desktop fallback.'}
    if(Select-String -LiteralPath (Join-Path $runRoot 'capture.log') -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet){throw 'Game reported a capture error.'}
    $images=@(Get-ChildItem -LiteralPath $runRoot -File -Filter 'after_*.png')
    if($images.Count -ne 8){throw 'Capture ended without all eight expected PNGs.'}
    $succeeded=$true
}finally{Complete-FarmScratch $farmRoot $runRoot 'integrated_ui' $succeeded -Visual}

