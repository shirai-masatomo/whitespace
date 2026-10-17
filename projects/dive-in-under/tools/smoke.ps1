param([switch]$Rendered, [ValidateSet('','start','back','omit-result')][string]$Fault = '', [switch]$ResumeProbe)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'smoke_result.ps1')
if ($Rendered) { throw 'Normal-desktop rendering is prohibited. Use tools/isolated_visual.ps1 after a successful permission probe.' }
$project = Split-Path $PSScriptRoot -Parent
$runDir = Join-Path $project 'artifacts/exe-headless'
New-Item -ItemType Directory -Force $runDir | Out-Null
$envBefore = $env:APPDATA
$env:APPDATA = Join-Path $runDir 'user-data'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
$exe = Join-Path $project 'build/windows/DiveInUnder.exe'
$log = Join-Path $runDir 'run.log'
$runId = [guid]::NewGuid().ToString('N')
$arguments = @('--headless','--log-file', $log, '--audio-driver','Dummy','--quit-after','2000')
$arguments += @('--',"--smoke-dir=$runDir","--smoke-run-id=$runId")
if ($Fault) { $arguments += "--smoke-fault=$Fault" }
if ($ResumeProbe) { $arguments += '--resume-probe' }
$quoted = ($arguments | ForEach-Object { '"' + $_.Replace('"','\"') + '"' }) -join ' '
try {
    $process = Start-Process -FilePath $exe -ArgumentList $quoted -WindowStyle Hidden -PassThru
    if (!$process.WaitForExit(30000)) {
        # Only the process object created by this invocation is eligible for cleanup.
        if (!$process.HasExited -and $process.Path -eq $exe) { $process.Kill() }
        throw 'Own smoke EXE timed out; inspect run.log'
    }
    if ($process.ExitCode -ne 0) { throw "EXE exit $($process.ExitCode)" }
    if (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet) { throw 'Exported EXE logged errors' }
    $resultPath = Join-Path $runDir $(if ($ResumeProbe) {'resume-smoke.json'} else {'ui-smoke.json'})
    $result = Assert-SmokeResult -Path $resultPath -RunId $runId -Rendered ([bool]$Rendered) -ResumeProbe:$ResumeProbe
    $result | ConvertTo-Json
} finally { $env:APPDATA = $envBefore }
if (!$Fault -and !$ResumeProbe) { & $PSCommandPath -ResumeProbe }
