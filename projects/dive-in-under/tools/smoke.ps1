param([switch]$Rendered)
$ErrorActionPreference = 'Stop'
if ($Rendered) { throw 'Normal-desktop rendering is prohibited. Use tools/isolated_visual.ps1 after a successful permission probe.' }
$project = Split-Path $PSScriptRoot -Parent
$runDir = Join-Path $project 'artifacts/exe-headless'
New-Item -ItemType Directory -Force $runDir | Out-Null
$envBefore = $env:APPDATA
$env:APPDATA = Join-Path $runDir 'user-data'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
$exe = Join-Path $project 'build/windows/DiveInUnder.exe'
$log = Join-Path $runDir 'run.log'
$arguments = @('--headless','--log-file', $log, '--audio-driver','Dummy','--quit-after','600')
$arguments += @('--',"--smoke-dir=$runDir")
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
    $resultPath = Join-Path $runDir 'ui-smoke.json'
    if (!(Test-Path $resultPath)) { throw 'No smoke result' }
    $result = Get-Content $resultPath -Raw | ConvertFrom-Json
    if (!$result.ui_core_equal -or $result.rendered -ne [bool]$Rendered) { throw 'Unexpected smoke result' }
    $result | ConvertTo-Json
} finally { $env:APPDATA = $envBefore }
