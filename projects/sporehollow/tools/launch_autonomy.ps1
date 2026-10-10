param([switch]$Verify)
$ErrorActionPreference='Stop'
$bundle=$PSScriptRoot
$exe=Join-Path $bundle 'WhistleRanch-Autonomy-Partial.exe'
$data=Join-Path $bundle 'user-data'
if(-not(Test-Path -LiteralPath $exe)){throw 'Research executable missing.'}
New-Item -ItemType Directory -Force -Path $data | Out-Null
$env:APPDATA=$data
$env:LOCALAPPDATA=$data
if(-not $Verify){
    Start-Process -FilePath $exe -WorkingDirectory $bundle -WindowStyle Normal
    exit 0
}
# Same entry point, executable and data folder; the verification branch places its window on a private desktop.
$output=Join-Path $bundle 'verification'
New-Item -ItemType Directory -Force -Path $output | Out-Null
Add-Type -Path (Join-Path $bundle 'isolated_desktop.cs')
$environment=[System.Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
[Environment]::GetEnvironmentVariables().GetEnumerator() | ForEach-Object {$environment[$_.Key]=[string]$_.Value}
$environment['FARM_REVIEW_OUTPUT']=$output
$records=@()
foreach($phase in @('save','resume')){
    $cmd='"'+$exe+'" --audio-driver Dummy --rendering-method gl_compatibility --max-fps 30 --resolution 1280x800 --log-file "'+$output+'/'+$phase+'.log" -- --isolated-review --review-autonomy'
    if($phase -eq 'resume'){$cmd+=' --resume-entry'}
    $record=@{phase=$phase;executable=$exe;sha256=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash;command=$cmd;data_root=$data;start_utc=[DateTime]::UtcNow.ToString('o')}
    try{$result=[FarmIsolatedDesktop]::Run($exe,$cmd,$bundle,$environment,60);$record.result=$result}
    catch{$record.error=$_.Exception.Message;throw}
    finally{$record.end_utc=[DateTime]::UtcNow.ToString('o');$records+=@($record);$records | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'isolation.json') -Encoding UTF8}
    if($result.ExitCode -ne 0 -or -not $result.NonInteractive -or -not $result.DesktopMatched){throw "Entry verification failed: $phase"}
    if(Select-String -LiteralPath (Join-Path $output ($phase+'.log')) -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet){throw "Engine error: $phase"}
    $proof=Get-Content -LiteralPath (Join-Path $output ($phase+'.json')) -Raw -Encoding UTF8 | ConvertFrom-Json
    if(-not $proof.passed){throw "Evidence failed: $phase"}
}
Write-Output "Entry, process restart and UI load verified: $output"
