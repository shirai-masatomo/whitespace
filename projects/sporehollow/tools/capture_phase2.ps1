$ErrorActionPreference='Stop'
$project=Split-Path -Parent $PSScriptRoot
. (Join-Path $project 'tools/workspace_lifecycle.ps1')
$scratch=Start-FarmScratch $project (Join-Path $project 'artifacts/isolated/current')
$evidence=Join-Path $project 'review/current/integrated-revision/phase2'
$screens=Join-Path $evidence 'screenshots'
New-Item -ItemType Directory -Force -Path $screens | Out-Null
$record=@{source_commit=(git -C $project rev-parse HEAD).Trim();start_utc=[DateTime]::UtcNow.ToString('o');timeout_seconds=60;fps_limit=30;normal_desktop_fallback=$false;success=$false}
try {
 $delivery=Get-Content -LiteralPath (Join-Path $evidence 'DELIVERY.json') -Raw | ConvertFrom-Json
 if($delivery.implementation_commit -ne $record.source_commit){throw 'Delivery/source commit mismatch'}
 Add-Type -Path (Join-Path $project 'tools/isolated_desktop.cs')
 $environment=[System.Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
 [Environment]::GetEnvironmentVariables().GetEnumerator() | ForEach-Object {$environment[$_.Key]=[string]$_.Value}
 $environment['APPDATA']=Join-Path $scratch 'user-data';$environment['LOCALAPPDATA']=Join-Path $scratch 'user-data';$environment['FARM_REVIEW_OUTPUT']=$scratch;$environment['FARM_REVIEW_COMMIT']=$record.source_commit
 $normal=Join-Path $project 'artifacts/autonomy-entry-01/bundle/WhistleRanch-Autonomy-Partial.exe'
 $environment['FARM_REVIEW_EXE_SHA']=(Get-FileHash -LiteralPath $normal -Algorithm SHA256).Hash
 if($environment['FARM_REVIEW_EXE_SHA'] -ne $delivery.sha256){throw 'Published EXE hash mismatch'}
 $exe=Join-Path $project '.tools/Godot_v4.7.2-stable_win64.exe'
 $command='"'+$exe+'" --path "'+$project+'" --audio-driver Dummy --rendering-method gl_compatibility --max-fps 30 --resolution 1280x800 --log-file "'+(Join-Path $scratch 'phase2-capture.log')+'" --script res://tests/capture_phase2.gd -- --isolated-review --automated'
 $record.result=[FarmIsolatedDesktop]::Run($exe,$command,$project,$environment,60)
 if($record.result.ExitCode -ne 0 -or -not $record.result.NonInteractive -or -not $record.result.DesktopMatched -or $record.result.TimedOut){throw 'Isolated capture failed; no normal desktop fallback'}
 $manifest=Join-Path $scratch 'SCREENSHOT_MANIFEST.json'
 if(-not(Test-Path -LiteralPath $manifest)){throw 'Capture manifest missing'}
 $data=Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
 if($data.failed -or $data.screens.Count -ne 14){throw 'Screenshot count/PNG error'}
 $log=Get-Content -LiteralPath (Join-Path $scratch 'phase2-capture.log') -Raw
 if($log -match 'SCRIPT ERROR:|ERROR:'){throw 'Game capture emitted errors'}
 $record.success=$true
}catch{$record.error=$_.Exception.Message;throw}
finally {
 $record.end_utc=[DateTime]::UtcNow.ToString('o')
 $record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $evidence 'CAPTURE_ISOLATION.json') -Encoding utf8
 foreach($file in Get-ChildItem -LiteralPath $scratch -File){if($file.Extension -eq '.png' -and $file.Name -ne 'loading.png'){Copy-Item -LiteralPath $file.FullName -Destination $screens -Force}elseif($file.Name -in @('SCREENSHOT_MANIFEST.json','phase2-capture.log')){Copy-Item -LiteralPath $file.FullName -Destination $evidence -Force}}
 Remove-FarmScratch $project $scratch;$farmLease.Dispose()
}
$record | ConvertTo-Json -Depth 8
