param([string[]]$Tests=@('test_interaction_revision'))
$ErrorActionPreference='Stop'
$project=Split-Path -Parent $PSScriptRoot
. (Join-Path $project 'tools/workspace_lifecycle.ps1')
$scratch=Start-FarmScratch $project (Join-Path $project 'artifacts/validation/current')
$evidence=Join-Path $project 'review/current/interaction-revision'
New-Item -ItemType Directory -Force -Path $evidence | Out-Null
Set-Content -LiteralPath (Join-Path $evidence '.gdignore') -Value ''
try {
 foreach($test in $Tests){
  $info=[Diagnostics.ProcessStartInfo]::new()
  $info.FileName=Join-Path $project '.tools/Godot_v4.7.2-stable_win64_console.exe'
  foreach($arg in @('--headless','--audio-driver','Dummy','--max-fps','30','--path',$project,'--log-file',(Join-Path $scratch ($test+'.log')),'--script',('res://tests/'+$test+'.gd'),'--','--isolated-review')){$info.ArgumentList.Add($arg)}
  $info.CreateNoWindow=$true;$info.UseShellExecute=$false;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
  $info.Environment['APPDATA']=Join-Path $scratch 'user-data';$info.Environment['LOCALAPPDATA']=Join-Path $scratch 'user-data';$info.Environment['FARM_REVIEW_OUTPUT']=$scratch
  $process=[Diagnostics.Process]::Start($info);$process.PriorityClass='BelowNormal'
  $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
  if(-not $process.WaitForExit(120000)){$process.Kill();throw "$test timeout (120 seconds)"}
  $output=$stdout.Result+$stderr.Result
  Write-Output ($test+': exit '+$process.ExitCode)
  Write-Output $output
  Set-Content -LiteralPath (Join-Path $evidence ($test+".txt")) -Value $output -Encoding utf8
  foreach($file in Get-ChildItem -LiteralPath $scratch -File | Where-Object {$_.Extension -in @('.json','.log') -and $_.Name -ne '.generated-work.json'}){Copy-Item -LiteralPath $file.FullName -Destination $evidence -Force}
  if($process.ExitCode -ne 0 -or $output -match 'SCRIPT ERROR:|Parse Error:'){throw "$test failed"}
 }
}finally{Remove-FarmScratch $project $scratch;$farmLease.Dispose()}
