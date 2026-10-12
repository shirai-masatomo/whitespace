param([switch]$ReproduceUnsupportedExport)
$ErrorActionPreference='Stop'
$farmRoot=Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'workspace_lifecycle.ps1')
$runRoot=Start-FarmScratch $farmRoot (Join-Path $farmRoot 'artifacts/isolated/current')
New-Item -ItemType Directory -Force (Join-Path $runRoot 'user-data')|Out-Null
$succeeded=$false
try{
    Initialize-FarmImports $farmRoot $runRoot
    Add-Type -Path (Join-Path $PSScriptRoot 'isolated_desktop.cs')
    $envBlock=[Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
    [Environment]::GetEnvironmentVariables().GetEnumerator()|ForEach-Object {$envBlock[$_.Key]=[string]$_.Value}
    $envBlock['FARM_REVIEW_OUTPUT']=$runRoot
    $envBlock['FARM_REVIEW_COMMIT']=(git -C $farmRoot rev-parse HEAD).Trim()
    $cases=@(
        @{name='export_probe';exe=(Join-Path $farmRoot 'artifacts/autonomy-entry-01/bundle/WhistleRanch-Autonomy-Partial.exe');script='tests/render_diagnosis.gd';path=''},
        @{name='source_probe';exe=(Join-Path $farmRoot '.tools/Godot_v4.7.2-stable_win64.exe');script='tests/render_diagnosis.gd';path=' --path "'+$farmRoot+'"'},
        @{name='source_game';exe=(Join-Path $farmRoot '.tools/Godot_v4.7.2-stable_win64.exe');script='tests/review_integrated_visual.gd';path=' --path "'+$farmRoot+'"'}
    )
    $records=@()
    foreach($case in $cases){
        if($case.name -eq 'export_probe' -and -not $ReproduceUnsupportedExport){
            $records+=@(@{case='export_probe';skipped=$true;reason='Release template has no --script; use explicit -ReproduceUnsupportedExport only to reproduce the proven failure.'});continue
        }
        $privateData=Join-Path $runRoot ('user-data/'+$case.name);New-Item -ItemType Directory -Force $privateData|Out-Null
        $envBlock['APPDATA']=$privateData;$envBlock['LOCALAPPDATA']=$privateData;$envBlock['FARM_REVIEW_CASE']=$case.name
        $cmd='"'+$case.exe+'"'+$case.path+' --audio-driver Dummy --rendering-method gl_compatibility --max-fps 30 --resolution 1280x800 --log-file "'+$runRoot+'/'+$case.name+'.log" --script "'+(Join-Path $farmRoot $case.script)+'" -- --isolated-review'
        $record=@{case=$case.name;command=$cmd;executable_sha256=(Get-FileHash -LiteralPath $case.exe).Hash;start_utc=[DateTime]::UtcNow.ToString('o')}
        try{$record.result=[FarmIsolatedDesktop]::Run($case.exe,$cmd,(Split-Path $case.exe),$envBlock,20)}
        catch{$record.error=$_.Exception.Message;throw}
        finally{$record.end_utc=[DateTime]::UtcNow.ToString('o');$records+=@($record);$records|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $runRoot 'diagnosis.json') -Encoding utf8}
        Write-Output ($case.name+': '+($record.result|ConvertTo-Json -Compress -Depth 4))
    }
    $succeeded=$records[-1].result.ExitCode -eq 0 -and (Test-Path -LiteralPath (Join-Path $runRoot 'after_01_initial_stock.png'))
}finally{Complete-FarmScratch $farmRoot $runRoot 'render_diagnosis' $succeeded -Visual}
