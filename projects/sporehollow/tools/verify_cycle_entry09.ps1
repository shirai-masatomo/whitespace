param([Parameter(Mandatory=$true)][string]$Executable,[Parameter(Mandatory=$true)][string]$Fixture,[Parameter(Mandatory=$true)][string]$OutputDirectory)
$ErrorActionPreference='Stop'
$exe=(Resolve-Path -LiteralPath $Executable).Path
$fixturePath=(Resolve-Path -LiteralPath $Fixture).Path
$out=[IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $out,"$out/user-data" | Out-Null
if($fixturePath -ne (Join-Path $out 'fixture.snapshot')){Copy-Item -LiteralPath $fixturePath -Destination (Join-Path $out 'fixture.snapshot')}
Add-Type -Path (Join-Path $PSScriptRoot 'isolated_desktop.cs')
$environment=[System.Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
[Environment]::GetEnvironmentVariables().GetEnumerator() | ForEach-Object {$environment[$_.Key]=[string]$_.Value}
$environment['APPDATA']="$out/user-data"
$environment['LOCALAPPDATA']="$out/user-data"
$environment['FARM_REVIEW_OUTPUT']=$out
$records=@()
foreach($phase in @('close','resume')){
    $cmd='"'+$exe+'" --audio-driver Dummy --rendering-method gl_compatibility --max-fps 30 --resolution 1280x800 --log-file "'+$out+'/'+$phase+'.log" -- --isolated-review --review-cycle-entry'
    if($phase -eq 'resume'){$cmd+=' --resume-cycle-entry'}
    $record=@{phase=$phase;executable=$exe;sha256=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash;command=$cmd;data_root="$out/user-data";start_utc=[DateTime]::UtcNow.ToString('o')}
    try{$result=[FarmIsolatedDesktop]::Run($exe,$cmd,(Split-Path -Parent $exe),$environment,30);$record.result=$result}
    catch{$record.error=$_.Exception.Message;throw}
    finally{$record.end_utc=[DateTime]::UtcNow.ToString('o');$records+=@($record);$records | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $out 'isolation.json') -Encoding UTF8}
    if($result.ExitCode -ne 0 -or -not $result.NonInteractive -or -not $result.DesktopMatched){throw "Entry verification failed: $phase"}
    if(Select-String -LiteralPath (Join-Path $out ($phase+'.log')) -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet){throw "Engine error: $phase"}
    $proof=Get-Content -LiteralPath (Join-Path $out ($phase+'-entry.json')) -Raw -Encoding UTF8 | ConvertFrom-Json
    if(-not $proof.passed){throw "Evidence failed: $phase"}
}
Write-Output "Exported close/startup persistence verified with separate data: $out"
