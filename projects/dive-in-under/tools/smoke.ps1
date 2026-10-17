param([switch]$Rendered)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$mode = if ($Rendered) { 'rendered' } else { 'headless' }
$runDir = Join-Path $project "artifacts/exe-$mode"
New-Item -ItemType Directory -Force $runDir | Out-Null
Copy-Item (Join-Path $project 'build/windows/DiveInUnder.exe') $runDir -Force
Copy-Item (Join-Path $project 'build/windows/DiveInUnder.pck') $runDir -Force
# Overrides live only beside this private copy, never in the distributed ZIP.
if ($Rendered) {
    @'
[display]
window/size/no_focus=true
window/size/initial_position_type=0
window/size/initial_position=Vector2i(-20000, -20000)
window/size/borderless=true
window/energy_saving/keep_screen_on=false
'@ | Set-Content (Join-Path $runDir 'override.cfg') -Encoding utf8
}
$envBefore = $env:APPDATA
$env:APPDATA = Join-Path $runDir 'user-data'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
$exe = Join-Path $runDir 'DiveInUnder.exe'
$log = Join-Path $runDir 'run.log'
$arguments = @('--log-file', $log, '--audio-driver','Dummy','--quit-after','600')
if ($Rendered) { $arguments += @('--position','-20000,-20000','--resolution','1280x720','--rendering-method','gl_compatibility') }
else { $arguments += '--headless' }
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
    if ($Rendered) {
        foreach ($name in @('01-title.png','02-battle.png','03-battle-result.png')) {
            if (!(Test-Path (Join-Path $runDir $name))) { throw "Missing screenshot: $name" }
        }
    }
    $result | ConvertTo-Json
} finally { $env:APPDATA = $envBefore }
