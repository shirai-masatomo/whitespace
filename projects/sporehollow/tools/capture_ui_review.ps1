$ErrorActionPreference='Stop'
$project=Split-Path -Parent $PSScriptRoot
. (Join-Path $project 'tools/workspace_lifecycle.ps1')
$scratch=Start-FarmScratch $project (Join-Path $project 'artifacts/isolated/current')
$evidence=Join-Path $project 'review/current/interaction-revision'
$record=@{source_commit=(git -C $project rev-parse HEAD).Trim();start_utc=[DateTime]::UtcNow.ToString('o');timeout_seconds=60;fps_limit=30;scenario='architect, stockpile filters/access, staged house';normal_desktop_fallback=$false}
try {
 Add-Type -Path (Join-Path $project 'tools/isolated_desktop.cs')
 $environment=[System.Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
 [Environment]::GetEnvironmentVariables().GetEnumerator() | ForEach-Object {$environment[$_.Key]=[string]$_.Value}
 $environment['APPDATA']=Join-Path $scratch 'user-data';$environment['LOCALAPPDATA']=Join-Path $scratch 'user-data';$environment['FARM_REVIEW_OUTPUT']=$scratch;$environment['FARM_REVIEW_COMMIT']=$record.source_commit
 $exe=Join-Path $project '.tools/Godot_v4.7.2-stable_win64.exe'
 $command='"'+$exe+'" --path "'+$project+'" --audio-driver Dummy --rendering-method gl_compatibility --max-fps 30 --resolution 1280x800 --log-file "'+(Join-Path $scratch 'ui-capture.log')+'" --script res://tests/capture_ui_review.gd -- --isolated-review --automated'
 $record.result=[FarmIsolatedDesktop]::Run($exe,$command,$project,$environment,60)
 if($record.result.ExitCode -ne 0 -or -not $record.result.NonInteractive -or -not $record.result.DesktopMatched -or $record.result.TimedOut){throw 'Isolated capture failed; no normal-desktop fallback'}
 if(-not(Test-Path -LiteralPath (Join-Path $scratch '05-current-house.png'))){throw 'No screenshot was produced'}
 $record.success=$true
}catch{$record.success=$false;$record.error=$_.Exception.Message;throw}
finally{
 $record.end_utc=[DateTime]::UtcNow.ToString('o')
 $record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $evidence 'ui-capture-isolation.json') -Encoding utf8
 foreach($name in @('02-current-architect.png','03-current-stockpile-filters.png','04-current-stockpile-access.png','05-current-house.png','ui-capture.json','ui-capture.log')){$path=Join-Path $scratch $name;if(Test-Path -LiteralPath $path){Copy-Item -LiteralPath $path -Destination $evidence -Force}}
 Remove-FarmScratch $project $scratch;$farmLease.Dispose()
}
$record | ConvertTo-Json -Depth 8
