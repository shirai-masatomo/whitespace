param([string]$GodotBinary='')
$ErrorActionPreference='Stop'
$project=Split-Path -Parent $PSScriptRoot
$exe=if($GodotBinary){(Resolve-Path -LiteralPath $GodotBinary).Path}else{Join-Path $project '.tools/Godot_v4.7.2-stable_win64_console.exe'}
if(-not(Test-Path -LiteralPath $exe)){throw 'Run ./tools/setup.ps1 first (PowerShell 7).'}
$out=Join-Path $project ('artifacts/verification/'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Force -Path $out,"$out/user-data" | Out-Null
foreach($suite in @('import','visible_boundary','explicit_storage','negotiation')){
 $info=[Diagnostics.ProcessStartInfo]::new();$info.FileName=$exe;$info.WorkingDirectory=$project
 $info.UseShellExecute=$false;$info.CreateNoWindow=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
 $info.Environment['APPDATA']="$out/user-data";$info.Environment['LOCALAPPDATA']="$out/user-data";$info.Environment['FARM_REVIEW_OUTPUT']=$out
 $arguments=@('--headless','--audio-driver','Dummy','--path',$project,'--log-file',"$out/$suite.log")
 if($suite -eq 'import'){$arguments+=@('--editor','--import','--quit')}else{$arguments+=@('--script',"tests/test_$suite.gd",'--','--isolated-review')}
 foreach($argument in $arguments){$info.ArgumentList.Add($argument)}
 $owned=[Diagnostics.Process]::new();$owned.StartInfo=$info
 if(-not $owned.Start()){throw "Unable to start $suite"}
 $stdout=$owned.StandardOutput.ReadToEndAsync();$stderr=$owned.StandardError.ReadToEndAsync()
 if(-not $owned.WaitForExit(180000)){$owned.Kill();throw "Timed out: $suite"}
 $text=$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult()
 if($owned.ExitCode -ne 0 -or $text -match 'SCRIPT ERROR:|ERROR:'){throw "$suite failed: $text"}
 Write-Output "$suite passed"
}
Write-Output "Verification data: $out"
