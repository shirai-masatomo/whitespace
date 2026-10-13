param([string[]]$Cases=@('baseline','simple_ground','grain','noise','gravel','no_decor','all_chunks','no_occupancy'),[int]$Repeats=2,[int]$Seconds=85)
$ErrorActionPreference='Stop'
$farmRoot=Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'workspace_lifecycle.ps1')
$runRoot=Start-FarmScratch $farmRoot (Join-Path $farmRoot 'artifacts/isolated/current')
$evidence=Join-Path $farmRoot 'review/current/performance-diagnosis'
New-Item -ItemType Directory -Force $evidence | Out-Null
$success=$false
try {
 Initialize-FarmImports $farmRoot $runRoot
 Add-Type -Path (Join-Path $PSScriptRoot 'isolated_desktop.cs')
 $exe=Join-Path $farmRoot '.tools/Godot_v4.7.2-stable_win64.exe'
 $all=@()
 foreach($case in $Cases){foreach($repeat in 1..$Repeats){
  $name="$case-$repeat"
  $data=Join-Path (Join-Path $runRoot 'user-data') $name
  New-Item -ItemType Directory -Force $data | Out-Null
  $envs=[Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
  [Environment]::GetEnvironmentVariables().GetEnumerator()|ForEach-Object {$envs[$_.Key]=[string]$_.Value}
  $envs['APPDATA']=$data;$envs['LOCALAPPDATA']=$data;$envs['FARM_DIAG_OUTPUT']=$data
  $cmd='"'+$exe+'" --path "'+$farmRoot+'" --audio-driver Dummy --rendering-method gl_compatibility --disable-vsync --max-fps 240 --resolution 1280x800 --log-file "'+$data+'/render.log" -- --diagnostics --diag-route --diag-case='+$case+' --diag-seconds='+$Seconds
  $result=[FarmIsolatedDesktop]::Run($exe,$cmd,$farmRoot,$envs,($Seconds+90))
  if($result.ExitCode -ne 0 -or -not $result.NonInteractive -or -not $result.DesktopMatched){throw "Failed $name"}
  if(Select-String -LiteralPath (Join-Path $data 'render.log') -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet){throw "Script error $name"}
  $capture=Get-ChildItem -LiteralPath $data -Filter 'play-*.json' | Select-Object -Last 1
  if(-not $capture){throw "Missing diagnostic $name"}
  $json=Get-Content -LiteralPath $capture.FullName -Raw | ConvertFrom-Json
  $record=@{name=$name;summary=$json.summary;startup=$json.startup;gpu=$json.gpu;renderer=$json.renderer;vsync=$json.vsync;fps_cap=$json.fps_cap;audio_driver=$json.audio_driver;source_commit=(git -C $farmRoot rev-parse HEAD).Trim();source_dirty=$true;non_interactive=$true}
  $scopes=@{}
  foreach($frame in $json.frames | Where-Object {$_.ready_ms -ge 0}){foreach($prop in $frame.cpu.PSObject.Properties){if($prop.Name -notlike '*_count'){
   if(-not $scopes.ContainsKey($prop.Name)){$scopes[$prop.Name]=@{total=0.0;max=0.0;frames=0}}
   $s=$scopes[$prop.Name];$s.total+=[double]$prop.Value;$s.max=[Math]::Max($s.max,[double]$prop.Value);$s.frames++
  }}}
  $record.cpu_scopes=$scopes
  $record.source_sha256=@{};foreach($file in @('main.gd','loading.gd','play_diagnostics.gd','soil_surface.gdshader','board_art.gd','retained_ground.gd')){$record.source_sha256[$file]=(Get-FileHash -LiteralPath (Join-Path $farmRoot ('game/'+$file))).Hash}
  $record.segments=$json.summary
  $record.slowest=@($json.frames | Where-Object {$_.ready_ms -ge 0} | Sort-Object frame_ms -Descending | Select-Object -First 12)
  $all+=$record
  $record | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath (Join-Path $evidence "$name.json") -Encoding utf8
  Write-Output "$name first30 p99=$($json.summary.first_30.p99_ms) max=$($json.summary.first_30.max_ms); moving p99=$($json.summary.moving.p99_ms) max=$($json.summary.moving.max_ms)"
 }}
 $all | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath (Join-Path $evidence 'comparison.json') -Encoding utf8
 $success=$true
} finally {Complete-FarmScratch $farmRoot $runRoot 'ground_diagnostics' $success}
