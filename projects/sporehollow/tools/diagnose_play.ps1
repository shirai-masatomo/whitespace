param(
 [ValidateSet('baseline','simple_ground','grain','noise','gravel','no_decor','all_chunks','no_occupancy','legacy_color','manual_chunks','no_scene','no_world','no_hud','no_audio')][string]$Case='baseline',
 [switch]$Route,[switch]$Source,[switch]$NoVSync,[switch]$Fullscreen,[switch]$GpuTiming,
 [ValidateRange(0,240)][int]$MaxFps=0,[ValidateRange(30,120)][int]$Seconds=120,
 [ValidateSet('current','on','off')][string]$ShaderCache='current',
 [string]$Tag='desktop'
)
$ErrorActionPreference='Stop'
$farmRoot=Split-Path -Parent $PSScriptRoot
$bundle=Join-Path $farmRoot 'artifacts/autonomy-entry-01/bundle'
$exe=Join-Path $bundle 'WhistleRanch-Autonomy-Partial.exe'
if($Source){$exe=Join-Path $farmRoot '.tools/Godot_v4.7.2-stable_win64.exe'}
if(-not(Test-Path -LiteralPath $exe)){throw 'Game executable missing'}
if(Get-Process | Where-Object {try{$_.Path -eq $exe}catch{$false}}){throw 'The selected game executable is already running; leave it intact and exit first.'}
$root=Join-Path $farmRoot 'artifacts/diagnostics'
New-Item -ItemType Directory -Force $root | Out-Null
$lease=[IO.File]::Open((Join-Path $root '.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
$override=Join-Path $(if($Source){$farmRoot}else{$bundle}) 'override.cfg'
$createdOverride=$false;$owned=$null
try {
 if($ShaderCache -ne 'current'){
  if(Test-Path -LiteralPath $override){throw 'Existing override.cfg retained; cannot change cache experiment'}
  $value=if($ShaderCache -eq 'on'){'true'}else{'false'}
  $overrideText="[rendering]`nshader_compiler/shader_cache/enabled=$value`n"
  [IO.File]::WriteAllText($override,$overrideText,[Text.UTF8Encoding]::new($false));$createdOverride=$true
 }
 $data=Join-Path $root 'user-data';$saveDir=Join-Path $data 'WhistleResearchAutonomy'
 New-Item -ItemType Directory -Force $saveDir | Out-Null
 # Only the fixed, generated diagnostic save is reset. Normal data is read-only.
 foreach($name in @('colony.snapshot','campaign/morning.sav','campaign/morning.sav.bak','campaign/morning.sav.tmp')){
  $target=[IO.Path]::GetFullPath((Join-Path $saveDir $name))
  if(-not $target.StartsWith([IO.Path]::GetFullPath($root)+[IO.Path]::DirectorySeparatorChar)){throw 'Unsafe diagnostic path'}
  if(Test-Path -LiteralPath $target){Remove-Item -LiteralPath $target -Force}
 }
 $original=Join-Path $bundle 'user-data/WhistleResearchAutonomy/colony.snapshot'
 $saveHash=if(Test-Path -LiteralPath $original){(Get-FileHash -LiteralPath $original).Hash}else{''}
 if($Source){. (Join-Path $PSScriptRoot 'workspace_lifecycle.ps1');Initialize-FarmImports $farmRoot $root}
 $info=[Diagnostics.ProcessStartInfo]::new();$info.FileName=$exe;$info.WorkingDirectory=Split-Path -Parent $exe;$info.UseShellExecute=$false;$info.WindowStyle='Normal'
 $info.Environment['APPDATA']=$data;$info.Environment['LOCALAPPDATA']=$data;$info.Environment['FARM_DIAG_OUTPUT']=$root
 $argsList=@('--resolution','1280x800','--max-fps',"$MaxFps",'--log-file',(Join-Path $root 'desktop.log'))
 if($Source){$argsList+=@('--path',$farmRoot)}
 if($NoVSync){$argsList+='--disable-vsync'}
 if($Fullscreen){$argsList+='--fullscreen'}else{$argsList+='--windowed'}
 $argsList+=@('--','--diagnostics','--diag-shot',"--diag-case=$Case","--diag-seconds=$Seconds")
 if($Route){$argsList+='--diag-route'}
 if($GpuTiming){$argsList+='--diag-gpu'}
 foreach($arg in $argsList){$info.ArgumentList.Add($arg)}
 $owned=[Diagnostics.Process]::new();$owned.StartInfo=$info
 $start=[DateTime]::UtcNow
 if(-not $owned.Start()){throw 'Cannot start diagnostic game'}
 Write-Output "Diagnostic PID $($owned.Id); F9 stops/saves. Output: $root"
 $processSamples=@();$lastCpu=0.0;$lastAt=0.0
 while(-not $owned.WaitForExit(1000)){
  $owned.Refresh();$elapsed=([DateTime]::UtcNow-$start).TotalSeconds;$cpu=$owned.TotalProcessorTime.TotalMilliseconds
  $processSamples+=@{seconds=$elapsed;working_set_bytes=$owned.WorkingSet64;cpu_ms=$cpu;cpu_one_core_percent=($cpu-$lastCpu)/[Math]::Max(1,($elapsed-$lastAt)*10)}
  $lastCpu=$cpu;$lastAt=$elapsed
 }
 $finalHash=if(Test-Path -LiteralPath $original){(Get-FileHash -LiteralPath $original).Hash}else{''}
 @{tag=$Tag;case=$Case;exe_sha256=(Get-FileHash -LiteralPath $exe).Hash;source=$Source.IsPresent;args=$argsList;pid=$owned.Id;exit_code=$owned.ExitCode;normal_save_unchanged=($saveHash -eq $finalHash);start_utc=$start.ToString('o');end_utc=[DateTime]::UtcNow.ToString('o');process_samples=$processSamples} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $root 'launch.json') -Encoding utf8
 if($saveHash -ne $finalHash){throw 'Normal save changed during test; investigate concurrent external change'}
 if($owned.ExitCode -ne 0){throw 'Diagnostic game did not exit cleanly'}
} finally {
 if($createdOverride -and (Test-Path -LiteralPath $override) -and [IO.File]::ReadAllText($override) -eq $overrideText){Remove-Item -LiteralPath $override -Force}
 if($owned){$owned.Dispose()};$lease.Dispose()
}
