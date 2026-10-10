param([string]$Executable='')
$ErrorActionPreference='Stop'
$project=Split-Path -Parent $PSScriptRoot
$runRoot=Join-Path $project ('artifacts/onsite-screen/'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $runRoot,(Join-Path $runRoot 'user-data') | Out-Null
$exe=if($Executable){(Resolve-Path -LiteralPath $Executable).Path}else{Join-Path $project '.tools/Godot_v4.7.2-stable_win64.exe'}
$cmd='"'+$exe+'"'
if(-not $Executable){$cmd+=' --path "'+$project+'"'}
$cmd+=' --audio-driver Dummy --rendering-method gl_compatibility --max-fps 30 --resolution 1280x800 --log-file "'+$runRoot+'/render.log" -- --isolated-review --review-onsite'
Add-Type -Path (Join-Path $project 'tools/isolated_desktop.cs')
$environment=[System.Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
[Environment]::GetEnvironmentVariables().GetEnumerator() | ForEach-Object {$environment[$_.Key]=[string]$_.Value}
$environment['APPDATA']=Join-Path $runRoot 'user-data';$environment['LOCALAPPDATA']=$environment['APPDATA'];$environment['FARM_REVIEW_OUTPUT']=$runRoot
$audit=@{purpose='Controlled UI, lifecycle and state fixtures; no strategic simulation';exe=$exe;sha256=(Get-FileHash -LiteralPath $exe).Hash;command=$cmd;start_utc=[DateTime]::UtcNow.ToString('o')}
try{$result=[FarmIsolatedDesktop]::Run($exe,$cmd,$project,$environment,60);$audit.result=$result}catch{$audit.error=$_.Exception.Message;throw}finally{$audit|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $runRoot 'isolation.json') -Encoding UTF8}
if($result.ExitCode -ne 0 -or -not $result.NonInteractive -or -not $result.DesktopMatched){throw "UI review stopped: $runRoot"}
if(Select-String -LiteralPath (Join-Path $runRoot 'render.log') -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet){throw "UI review reported error: $runRoot"}
if(-not(Test-Path -LiteralPath (Join-Path $runRoot 'verification.json'))){throw 'Review JSON missing'}
Write-Output "UI evidence: $runRoot"
