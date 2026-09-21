param([ValidateSet('check', 'evaluate', 'test', 'lint', 'format', 'build', 'visual', 'visual-reef', 'visual-discovery', 'visual-playground', 'visual-entry', 'visual-canyon', 'visual-cove', 'visual-massif', 'visual-headland', 'visual-seabed', 'visual-biology', 'benchmark', 'gpu-smoke', 'play', 'editor')][string]$Task = 'check', [ValidateSet('windows','windows-preview','windows-real','windows-agent')][string]$BuildFolder = 'windows-agent', [ValidateSet('forward_plus','gl_compatibility')][string]$Renderer = 'forward_plus')
$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$buildRoot = Join-Path $projectRoot ('build/' + $BuildFolder)
$godot = Join-Path $projectRoot '.tools/Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $godot)) { throw 'Run ./tools/setup.ps1 first.' }
New-Item -ItemType Directory -Force "$projectRoot/artifacts", $buildRoot | Out-Null
Set-Content -LiteralPath "$projectRoot/artifacts/.gdignore" -Value ''
Set-Content -LiteralPath "$projectRoot/build/.gdignore" -Value ''

function Invoke-Godot([string]$Name, [string[]]$Arguments) {
    $log = Join-Path $projectRoot "artifacts/$Name.log"
    if ($Name.StartsWith('visual') -or $Name.StartsWith('benchmark-')) {
        # Keep a real GPU viewport, but never capture the mouse or cover the desktop.
        $gpuArgs = @('--path', ('"' + $projectRoot + '"'), '--log-file', ('"' + $log + '"'), '--rendering-method', $Renderer, '--position', '-20000,-20000', '--audio-driver', 'Dummy') + $Arguments
        $gpu = Start-Process -FilePath $godot -ArgumentList $gpuArgs -WindowStyle Hidden -PassThru
        if (-not $gpu.WaitForExit(300000)) { $gpu.Kill(); throw "$Name exceeded five minutes" }
        if ($gpu.ExitCode -ne 0) { throw "$Name failed: exit $($gpu.ExitCode)" }
    } else {
        & $godot --path $projectRoot --log-file $log --rendering-method $Renderer @Arguments
        if ($LASTEXITCODE -ne 0) { throw "$Name failed: exit $LASTEXITCODE" }
    }
    if (-not (Test-Path -LiteralPath $log)) { throw "$Name did not produce a log" }
    if (Test-Path $log) {
        if (Select-String -Path $log -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw "$Name logged errors: $log" }
    }
}

Push-Location $projectRoot
try {
    if ($Task -eq 'gpu-smoke') {
        $exe = Join-Path $buildRoot 'DIVE DIVE.exe'
        if (-not (Test-Path -LiteralPath $exe)) { throw 'Build this folder before gpu-smoke.' }
        $log = Join-Path $projectRoot "artifacts/native-gpu-$Renderer.log"
        $gpuArgs = @('--rendering-method', $Renderer, '--position', '-20000,-20000', '--audio-driver', 'Dummy', '--quit-after', '120', '--log-file', ('"' + $log + '"'), '--', '--smoke-test')
        $gpu = Start-Process -FilePath $exe -ArgumentList $gpuArgs -WindowStyle Hidden -PassThru
        if (-not $gpu.WaitForExit(60000)) { $gpu.Kill(); throw 'Packaged GPU smoke timed out' }
        if ($gpu.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $log)) { throw 'Packaged GPU smoke failed' }
        if (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw 'Packaged GPU smoke logged errors' }
        Write-Output "Packaged GPU startup and 120 frames succeeded: $Renderer"
    }
    if ($Task -eq 'play') {
        & $godot --path $projectRoot --rendering-method $Renderer
        exit $LASTEXITCODE
    }
    if ($Task -eq 'editor') {
        & $godot --path $projectRoot --rendering-method $Renderer --editor
        exit $LASTEXITCODE
    }
    if ($Task -eq 'format') {
        & './.tools/venv/Scripts/gdformat.exe' game tests
        if ($LASTEXITCODE -ne 0) { throw 'Formatter failed' }
    }
    if ($Task -eq 'benchmark') {
        Invoke-Godot ('benchmark-' + $Renderer) @('--script', 'tests/test_rendering.gd')
    }
    if ($Task -eq 'visual-entry') {
        Invoke-Godot 'visual-entry' @('--script', 'tests/test_entry.gd')
    }
    if ($Task -eq 'visual-biology') {
        Invoke-Godot 'visual-biology' @('--script', 'tests/test_biology.gd')
    }
    if ($Task -eq 'visual-seabed') {
        Invoke-Godot 'visual-seabed' @('--script', 'tests/test_seabed.gd')
    }
    if ($Task -eq 'visual-headland') {
        Invoke-Godot 'visual-headland' @('--script', 'tests/test_headland.gd')
    }
    if ($Task -eq 'visual-cove') {
        Invoke-Godot 'visual-cove' @('--script', 'tests/test_canyon.gd', '--', '--cove-only')
    }
    if ($Task -eq 'visual-canyon') {
        Invoke-Godot 'visual-canyon' @('--script', 'tests/test_canyon.gd')
    }
    if ($Task -eq 'visual-massif') {
        Invoke-Godot 'visual-massif' @('--script', 'tests/test_canyon.gd', '--', '--massif-only')
    }
    if ($Task -eq 'visual-playground') {
        Invoke-Godot 'visual-playground' @('--script', 'tests/test_playground.gd')
    }
    if ($Task -eq 'visual-discovery') {
        Invoke-Godot 'visual-discovery' @('--script', 'tests/test_discovery.gd')
    }
    if ($Task -eq 'visual-reef') {
        Invoke-Godot 'visual-reef' @('--script', 'tests/test_reef_visual.gd')
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
    if ($Task -in @('evaluate', 'test', 'build', 'check')) {
        Invoke-Godot 'import' @('--headless', '--editor', '--import')
    }
    if ($Task -in @('test', 'check')) {
        Invoke-Godot 'rules' @('--headless', '--script', 'tests/test_rules.gd')
        Invoke-Godot 'scene' @('--headless', '--script', 'tests/test_scene.gd')
        Invoke-Godot 'audio' @('--headless', '--script', 'tests/test_audio.gd')
        Invoke-Godot 'rock-surface' @('--headless', '--script', 'tests/test_rock_surface.gd')
        Invoke-Godot 'player-collision' @('--headless', '--script', 'tests/test_player_collision.gd')
        Invoke-Godot 'discovery' @('--headless', '--script', 'tests/test_discovery.gd')
        Invoke-Godot 'playground' @('--headless', '--script', 'tests/test_playground.gd')
        Invoke-Godot 'entry' @('--headless', '--script', 'tests/test_entry.gd')
        Invoke-Godot 'seabed' @('--headless', '--script', 'tests/test_seabed.gd')
        Invoke-Godot 'headland' @('--headless', '--script', 'tests/test_headland.gd')
        Invoke-Godot 'canyon' @('--headless', '--script', 'tests/test_canyon.gd')
        Invoke-Godot 'biology' @('--headless', '--script', 'tests/test_biology.gd', '--', '--full')
    }
    if ($Task -in @('evaluate', 'check')) {
        Invoke-Godot 'evaluation' @('--headless', '--script', 'tests/test_evaluation.gd')
        Invoke-Godot 'route-resilience' @('--headless', '--script', 'tests/test_route_resilience.gd')
    }
    if ($Task -in @('build', 'check')) {
        Invoke-Godot 'build' @('--headless', '--export-release', 'Windows Desktop', (Join-Path $buildRoot 'DIVE DIVE.exe'))
        Copy-Item assets/fonts/OFL.txt (Join-Path $buildRoot FONT_LICENSE.txt) -Force
        Copy-Item assets/GODOT_COPYRIGHT.txt (Join-Path $buildRoot GODOT_COPYRIGHT.txt) -Force
        Copy-Item tools/PLAY.txt (Join-Path $buildRoot PLAY.txt) -Force
        Copy-Item tools/Play-Compatibility.ps1 (Join-Path $buildRoot Play-Compatibility.ps1) -Force
        $smokeLog = Join-Path $projectRoot 'artifacts/export-smoke.log'
        $exe = Join-Path $buildRoot 'DIVE DIVE.exe'
        $process = Start-Process -FilePath $exe -ArgumentList @('--headless', '--rendering-method', $Renderer, '--quit-after', '10', '--log-file', ('"' + $smokeLog + '"')) -WindowStyle Hidden -PassThru
        if (-not $process.WaitForExit(30000)) { $process.Kill(); throw 'Export smoke test timed out' }
        if ($process.ExitCode -ne 0) { throw "Export failed to start: $($process.ExitCode)" }
        if (-not (Test-Path $smokeLog)) { throw 'Export did not produce a smoke log' }
        if (Select-String -Path $smokeLog -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw 'Export smoke test logged errors' }
        Compress-Archive -Path (Join-Path $buildRoot '*') -DestinationPath build/DIVE-DIVE-windows.zip -Force
        Write-Output "Windows build: $exe"
    }
} finally { Pop-Location }
