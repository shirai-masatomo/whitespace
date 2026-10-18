param([switch]$Isolated, [string]$RunDirectory = "", [string]$BuildDirectory = "")
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
if (!$RunDirectory) { $RunDirectory = Join-Path $project $(if ($Isolated) {'artifacts/enemy-art-isolated'} else {'artifacts/enemy-art-headless'}) }
New-Item -ItemType Directory -Force -Path $RunDirectory | Out-Null
if (!$BuildDirectory) {
    . (Join-Path $PSScriptRoot 'build_path.ps1')
    $BuildDirectory = Resolve-DiveBuild -Project $project
}
$exe = Join-Path $BuildDirectory 'DiveInUnder.exe'
$runId = [guid]::NewGuid().ToString('N')
$log = Join-Path $RunDirectory 'render.log'
$environment = [Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
[Environment]::GetEnvironmentVariables().GetEnumerator() | ForEach-Object { $environment[$_.Key] = [string]$_.Value }
$environment['APPDATA'] = Join-Path $RunDirectory 'user-data'
$environment['LOCALAPPDATA'] = Join-Path $RunDirectory 'local-data'
$arguments = @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--max-fps','30','--resolution','1280x720','--log-file',$log,'--',"--smoke-dir=$RunDirectory","--smoke-run-id=$runId",'--enemy-art-review')
if ($Isolated) {
    Add-Type -Path (Join-Path $PSScriptRoot 'isolated_desktop.cs')
    $probe = [DiveIsolatedDesktop]::Run('','','',$environment,5)
    if (!$probe.NonInteractive) { throw 'Noninteractive station required; no fallback' }
    $command = '"' + $exe + '" ' + (($arguments | ForEach-Object { '"' + $_ + '"' }) -join ' ')
    $result = [DiveIsolatedDesktop]::Run($exe,$command,$project,$environment,45)
    @{run_id=$runId;result=$result;exe_sha256=(Get-FileHash $exe).Hash;pck_sha256=(Get-FileHash (Join-Path $BuildDirectory 'DiveInUnder.pck')).Hash;normal_desktop_fallback=$false} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $RunDirectory 'isolation.json') -Encoding utf8
    if (!$result.NonInteractive -or !$result.DesktopMatched -or $result.TimedOut -or $result.ExitCode -ne 0) { throw 'Isolated image review failed' }
} else {
    $oldAppData=$env:APPDATA; $oldLocalData=$env:LOCALAPPDATA
    try {
        $env:APPDATA=$environment['APPDATA']; $env:LOCALAPPDATA=$environment['LOCALAPPDATA']
        & $exe --headless @arguments
        if ($LASTEXITCODE -ne 0) { throw 'Headless image review failed' }
    } finally { $env:APPDATA=$oldAppData; $env:LOCALAPPDATA=$oldLocalData }
}
if (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet) { throw 'Engine errors in image review' }
$report=Get-Content -LiteralPath (Join-Path $RunDirectory 'enemy-art-review.json') -Raw | ConvertFrom-Json
if ($report.run_id -ne $runId -or !$report.complete -or !$report.first_return_town -or $report.rendered -ne [bool]$Isolated -or $report.cases.Count -ne 5) { throw 'Missing/current image review result' }
Write-Output "Enemy art review passed: 5 fixed display cases + first return/town; rendered=$Isolated; run_id=$runId"
