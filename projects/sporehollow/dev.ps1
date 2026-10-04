param([ValidateSet('check', 'test', 'evaluate', 'build', 'visual', 'play', 'editor')][string]$Task = 'check')
$ErrorActionPreference = 'Stop'
$farmRoot = $PSScriptRoot
$godot = Join-Path $farmRoot '.tools/Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $godot)) { throw 'Run ./tools/setup.ps1 first.' }
New-Item -ItemType Directory -Force "$farmRoot/artifacts", "$farmRoot/build" | Out-Null
Set-Content -LiteralPath "$farmRoot/artifacts/.gdignore" -Value ''
Set-Content -LiteralPath "$farmRoot/build/.gdignore" -Value ''

function Run-Headless([string]$Name, [string[]]$Arguments) {
    $log = Join-Path $farmRoot "artifacts/$Name.log"
    & $godot --headless --path $farmRoot --log-file $log @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Name failed" }
    if (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw "$Name logged errors" }
}

if ($Task -in @('play', 'editor')) {
    $argsForEditor = @('--path', $farmRoot)
    if ($Task -eq 'editor') { $argsForEditor += '--editor' }
    & $godot @argsForEditor
    exit $LASTEXITCODE
}
if ($Task -in @('check', 'test', 'build')) {
    Run-Headless 'import' @('--editor', '--import', '--quit')
    Run-Headless 'residents' @('--script', 'tests/test_residents.gd')
    Run-Headless 'tests' @('--script', 'tests/test_world.gd')
    Run-Headless 'jobs' @('--script', 'tests/test_jobs.gd')
    Run-Headless 'keeper' @('--script', 'tests/test_keeper.gd')
    Run-Headless 'planning' @('--script', 'tests/test_planning.gd')
    Run-Headless 'rest-until' @('--script', 'tests/test_rest_until.gd')
}
if ($Task -in @('check', 'evaluate')) { Run-Headless 'evaluate' @('--script', 'tests/evaluate.gd') }
if ($Task -in @('check', 'build')) {
    Run-Headless 'export' @('--export-release', 'Windows Desktop', 'build/WhistleRanch.exe')
    $smokeArgs = @('--headless', '--log-file', ('"' + $farmRoot + '/artifacts/export-smoke.log"'), '--', '--smoke')
    $smoke = Start-Process -FilePath "$farmRoot/build/WhistleRanch.exe" -ArgumentList $smokeArgs -WindowStyle Hidden -PassThru
    if (-not $smoke.WaitForExit(30000)) { $smoke.Kill(); throw 'Owned export smoke timed out' }
    if ($smoke.ExitCode -ne 0) { throw 'Export smoke failed' }
    if (Select-String -LiteralPath "$farmRoot/artifacts/export-smoke.log" -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw 'Export smoke logged errors' }
    Copy-Item -LiteralPath "$farmRoot/assets/ui/SOURCES.md" -Destination "$farmRoot/build/UI_SOURCES.txt"
    Copy-Item -LiteralPath "$farmRoot/assets/fonts/OFL.txt" -Destination "$farmRoot/build/FONT_LICENSE.txt"
    Copy-Item -LiteralPath "$farmRoot/assets/GODOT_COPYRIGHT.txt" -Destination "$farmRoot/build/GODOT_COPYRIGHT.txt"
}
if ($Task -eq 'visual') {
    $log = Join-Path $farmRoot 'artifacts/visual.log'
    $gpuArgs = @('--path', ('"' + $farmRoot + '"'), '--position', '-20000,-20000', '--audio-driver', 'Dummy', '--log-file', ('"' + $log + '"'), '--script', 'tests/visual.gd')
    $owned = Start-Process -FilePath $godot -ArgumentList $gpuArgs -WindowStyle Hidden -PassThru
    if (-not $owned.WaitForExit(60000)) { $owned.Kill(); throw 'Owned visual test timed out' }
    if ($owned.ExitCode -ne 0 -or (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet)) { throw 'Visual test failed' }
    Get-Content -LiteralPath $log
}
