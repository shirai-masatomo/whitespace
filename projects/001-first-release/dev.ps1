param([ValidateSet('check', 'test', 'lint', 'format', 'build', 'visual', 'play', 'editor')][string]$Task = 'check')
$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$godot = Join-Path $projectRoot '.tools/Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $godot)) { throw 'Run ./tools/setup.ps1 first.' }
New-Item -ItemType Directory -Force "$projectRoot/artifacts", "$projectRoot/build/windows" | Out-Null
Set-Content -LiteralPath "$projectRoot/artifacts/.gdignore" -Value ''
Set-Content -LiteralPath "$projectRoot/build/.gdignore" -Value ''

function Invoke-Godot([string]$Name, [string[]]$Arguments) {
    $log = Join-Path $projectRoot "artifacts/$Name.log"
    & $godot --path $projectRoot --log-file $log @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Name failed: exit $LASTEXITCODE" }
    if (Test-Path $log) {
        if (Select-String -Path $log -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw "$Name logged errors: $log" }
    }
}

Push-Location $projectRoot
try {
    if ($Task -eq 'play') {
        & $godot --path $projectRoot
        exit $LASTEXITCODE
    }
    if ($Task -eq 'editor') {
        & $godot --path $projectRoot --editor
        exit $LASTEXITCODE
    }
    if ($Task -eq 'format') {
        & './.tools/venv/Scripts/gdformat.exe' game tests
        if ($LASTEXITCODE -ne 0) { throw 'Formatter failed' }
    }
    if ($Task -eq 'visual') {
        Invoke-Godot 'visual' @('--script', 'tests/test_visual.gd')
    }
    if ($Task -in @('lint', 'check')) {
        & './.tools/venv/Scripts/gdformat.exe' --check game tests
        if ($LASTEXITCODE -ne 0) { throw 'Format check failed: run ./dev.ps1 format' }
        & './.tools/venv/Scripts/gdlint.exe' game tests
        if ($LASTEXITCODE -ne 0) { throw 'Lint failed' }
        & './.tools/venv/Scripts/python.exe' -m pip check
        if ($LASTEXITCODE -ne 0) { throw 'Development dependency check failed' }
    }
    if ($Task -in @('test', 'build', 'check')) {
        Invoke-Godot 'import' @('--headless', '--editor', '--import')
    }
    if ($Task -in @('test', 'check')) {
        Invoke-Godot 'rules' @('--headless', '--script', 'tests/test_rules.gd')
        Invoke-Godot 'scene' @('--headless', '--script', 'tests/test_scene.gd')
    }
    if ($Task -in @('build', 'check')) {
        Invoke-Godot 'build' @('--headless', '--export-release', 'Windows Desktop')
        Copy-Item assets/fonts/OFL.txt build/windows/FONT_LICENSE.txt -Force
        Copy-Item assets/GODOT_COPYRIGHT.txt build/windows/GODOT_COPYRIGHT.txt -Force
        Copy-Item tools/PLAY.txt build/windows/PLAY.txt -Force
        $smokeLog = Join-Path $projectRoot 'artifacts/export-smoke.log'
        $exe = Join-Path $projectRoot 'build/windows/DIVE DIVE.exe'
        $process = Start-Process -FilePath $exe -ArgumentList @('--headless', '--quit-after', '10', '--log-file', ('"' + $smokeLog + '"')) -WindowStyle Hidden -PassThru
        if (-not $process.WaitForExit(30000)) { $process.Kill(); throw 'Export smoke test timed out' }
        if ($process.ExitCode -ne 0) { throw "Export failed to start: $($process.ExitCode)" }
        if (-not (Test-Path $smokeLog)) { throw 'Export did not produce a smoke log' }
        if (Select-String -Path $smokeLog -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw 'Export smoke test logged errors' }
        Compress-Archive -Path build/windows/* -DestinationPath build/DIVE-DIVE-windows.zip -Force
        Write-Output "Windows build: $exe"
    }
} finally { Pop-Location }
