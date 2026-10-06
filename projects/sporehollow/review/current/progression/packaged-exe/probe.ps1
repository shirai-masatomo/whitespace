$ErrorActionPreference='Stop'
$farmRoot=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$runRoot=Join-Path $PSScriptRoot 'progression-export-probe'
New-Item -ItemType Directory -Force "$runRoot/user-data" | Out-Null
$exe=Join-Path $farmRoot 'build/WhistleRanch.exe'
$build=Get-Content "$farmRoot/build/BUILD.json" -Raw | ConvertFrom-Json
Add-Type -Path "$farmRoot/tools/isolated_desktop.cs"
$envBlock=[System.Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
[Environment]::GetEnvironmentVariables().GetEnumerator() | ForEach-Object {$envBlock[$_.Key]=[string]$_.Value}
$envBlock['APPDATA']="$runRoot/user-data"
$envBlock['LOCALAPPDATA']="$runRoot/user-data"
$cmd='"'+$exe+'" --audio-driver Dummy --rendering-method gl_compatibility --max-fps 30 --resolution 1280x800 --quit-after 150 --log-file "'+$runRoot+'/render.log"'
$record=@{build=$build;sha256=(Get-FileHash $exe -Algorithm SHA256).Hash;command=$cmd;result=[FarmIsolatedDesktop]::Run($exe,$cmd,$farmRoot,$envBlock,60)}
$record | ConvertTo-Json -Depth 8 | Set-Content "$runRoot/isolation.json"
if($record.result.ExitCode -ne 0 -or -not $record.result.NonInteractive -or -not $record.result.DesktopMatched){throw 'Isolated EXE probe failed'}
if(Select-String "$runRoot/render.log" -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet){throw 'EXE render error'}
Write-Output "Isolated packaged EXE passed: $runRoot"
