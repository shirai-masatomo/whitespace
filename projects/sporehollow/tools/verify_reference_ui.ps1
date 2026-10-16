param([switch]$Publish,[switch]$DeliveryOnly,[string[]]$Suites=@("ambient-harvest","ambient-work","reference-ui","reserved-preview","life-ui"))
$ErrorActionPreference='Stop'
$project=Split-Path -Parent $PSScriptRoot
. (Join-Path $project 'tools/workspace_lifecycle.ps1')
$scratch=Start-FarmScratch $project (Join-Path $project 'artifacts/validation/current')
$evidence=Join-Path $project 'review/current/interaction-revision'
function Run([string]$name,[string[]]$extra){
 $info=[Diagnostics.ProcessStartInfo]::new();$info.FileName=Join-Path $project '.tools/Godot_v4.7.2-stable_win64_console.exe';$info.WorkingDirectory=$project;$info.UseShellExecute=$false;$info.CreateNoWindow=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
 foreach($arg in (@('--headless','--path',$project,'--audio-driver','Dummy','--max-fps','30','--log-file',(Join-Path $scratch ($name+'.log')))+$extra)){$info.ArgumentList.Add($arg)}
 $info.Environment['APPDATA']=Join-Path $scratch 'user-data';$info.Environment['LOCALAPPDATA']=$info.Environment['APPDATA'];$info.Environment['FARM_REVIEW_OUTPUT']=$scratch
 $proc=[Diagnostics.Process]::new();$proc.StartInfo=$info
 try{$null=$proc.Start();$proc.PriorityClass='BelowNormal';$out=$proc.StandardOutput.ReadToEndAsync();$err=$proc.StandardError.ReadToEndAsync();if(-not $proc.WaitForExit(120000)){$proc.Kill();$proc.WaitForExit();throw "$name timeout"};$result=$out.GetAwaiter().GetResult()+$err.GetAwaiter().GetResult();if($proc.ExitCode-ne 0 -or $result-match 'SCRIPT ERROR:|ERROR:'){Write-Output $result;throw "$name failed"};Write-Output "$name passed"}finally{$proc.Dispose()}
}
try{
 if(-not $DeliveryOnly){
 Run 'import' @('--editor','--import')
 foreach($suite in $Suites){if($suite -notin @('ambient-harvest','ambient-work','reference-ui','reserved-preview','life-ui','construction-visual','button-hit')){throw 'Unknown focused suite'};Run $suite @('--script',('res://tests/test_'+$suite.Replace('-','_')+'.gd'),'--','--isolated-review')}
 }
 Run 'loading' @('--script','res://tests/test_loading.gd','--','--isolated-review')
 if($Publish){$revision=(git -C $project rev-parse HEAD).Trim();$stamp=Get-Content -LiteralPath (Join-Path $project 'game/build_stamp.json') -Raw | ConvertFrom-Json;$stamp.commit=$revision;$stamp.dirty=$true;$stamp.asset_delivery_commit=(Get-Content -LiteralPath (Join-Path $project 'game/art_provenance.json') -Raw | ConvertFrom-Json).latest_delivery_commit;$stamp | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $project 'game/build_stamp.json') -Encoding utf8;Run 'export' @('--export-release','Windows Desktop',(Join-Path $scratch 'WhistleRanch-test.exe')); & (Join-Path $project 'tools/publish_build.ps1') -Executable (Join-Path $scratch 'WhistleRanch-test.exe') -Revision $revision -Dirty $true;Copy-Item -LiteralPath (Join-Path $project 'artifacts/autonomy-entry-01/bundle/BUILD.json') -Destination (Join-Path $evidence 'DELIVERY.json') -Force}
}finally{
 foreach($file in Get-ChildItem -LiteralPath $scratch -File){if($file.Extension-in @('.json','.log') -and $file.Name-ne '.generated-work.json'){Copy-Item -LiteralPath $file.FullName -Destination $evidence -Force}}
 Remove-FarmScratch $project $scratch;$farmLease.Dispose()
}
