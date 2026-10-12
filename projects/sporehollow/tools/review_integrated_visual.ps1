param()
$ErrorActionPreference='Stop'
$farmRoot=Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'workspace_lifecycle.ps1')
$runRoot=Start-FarmScratch $farmRoot (Join-Path $farmRoot 'artifacts/isolated/current')
New-Item -ItemType Directory -Force $runRoot,(Join-Path $runRoot 'user-data')|Out-Null
$succeeded=$false
try {
    Initialize-FarmImports $farmRoot $runRoot
    Add-Type -Path (Join-Path $PSScriptRoot 'isolated_desktop.cs')
    $envBlock=[Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
    [Environment]::GetEnvironmentVariables().GetEnumerator()|ForEach-Object {$envBlock[$_.Key]=[string]$_.Value}
    $envBlock['FARM_REVIEW_OUTPUT']=$runRoot
    $fixture=Join-Path $farmRoot 'tests/review_integrated_visual.gd'
    $cases=@(
        @{side='before';exe=(Join-Path $farmRoot 'artifacts/autonomy-entry-01/bundle/WhistleRanch-Autonomy-Partial.exe');revision='a16def5';suffix=' --baseline';path=''},
        @{side='after';exe=(Join-Path $farmRoot '.tools/Godot_v4.7.2-stable_win64.exe');revision=(git -C $farmRoot rev-parse HEAD).Trim();suffix='';path=' --path "'+$farmRoot+'"'}
    )
    foreach($case in $cases){
        $privateData=Join-Path $runRoot ('user-data/'+$case.side)
        New-Item -ItemType Directory -Force $privateData|Out-Null
        $envBlock['APPDATA']=$privateData;$envBlock['LOCALAPPDATA']=$privateData;$envBlock['FARM_REVIEW_COMMIT']=$case.revision
        $cmd='"'+$case.exe+'"'+$case.path+' --audio-driver Dummy --rendering-method gl_compatibility --max-fps 30 --resolution 1280x800 --log-file "'+$runRoot+'/'+$case.side+'.log" --script "'+$fixture+'" -- --isolated-review'+$case.suffix
        $audit=@{side=$case.side;implementation_commit=$case.revision;asset_delivery_commit=(Get-Content -LiteralPath (Join-Path $farmRoot 'game/art_provenance.json') -Raw|ConvertFrom-Json).latest_delivery_commit;executable=$case.exe;executable_sha256=(Get-FileHash -LiteralPath $case.exe).Hash;command=$cmd;data_root=$privateData;start_utc=[DateTime]::UtcNow.ToString('o')}
        try {$result=[FarmIsolatedDesktop]::Run($case.exe,$cmd,(Split-Path $case.exe),$envBlock,120);$audit.result=$result}
        catch {$audit.error=$_.Exception.Message;throw}
        finally {$audit.end_utc=[DateTime]::UtcNow.ToString('o');$audit|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $runRoot ($case.side+'-isolation.json')) -Encoding utf8}
        if($result.ExitCode -ne 0 -or -not $result.NonInteractive -or -not $result.DesktopMatched){throw 'GPU isolation did not pass. No ordinary-desktop fallback.'}
        if(Select-String -LiteralPath (Join-Path $runRoot ($case.side+'.log')) -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet){throw 'Game render/input error; inspect the saved log.'}
    }
    $succeeded=$true
} finally {Complete-FarmScratch $farmRoot $runRoot 'integrated_ui' $succeeded -Visual}
