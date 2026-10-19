param([switch]$Rendered, [string]$Replay = '')
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'build_path.ps1')
. (Join-Path $PSScriptRoot 'campaign_result.ps1')
if (!$Replay) { $Replay = Join-Path $project 'artifacts/campaign-replay.json' }
$Replay = [IO.Path]::GetFullPath($Replay)
$expected = Get-Content $Replay -Raw -Encoding utf8 | ConvertFrom-Json
$build = Resolve-DiveBuild -Project $project
$exe = Join-Path $build 'DiveInUnder.exe'
$runDir = Join-Path $project $(if ($Rendered) {'artifacts/campaign-isolated'} else {'artifacts/campaign-headless'})
New-Item -ItemType Directory -Force $runDir | Out-Null
$originalAppData = $env:APPDATA
$env:APPDATA = Join-Path $runDir 'user-data'
try {
    if ($Rendered) { & (Join-Path $PSScriptRoot 'isolated_visual.ps1') -ProbeOnly -CampaignReplay $Replay }
    foreach ($stage in @('checkpoint','complete','final')) {
        if ($Rendered) {
            & (Join-Path $PSScriptRoot 'isolated_visual.ps1') -CampaignReplay $Replay -Stage $stage
            Copy-Item (Join-Path $runDir 'isolation.json') (Join-Path $runDir "isolation-$stage.json")
            Copy-Item (Join-Path $runDir 'render.log') (Join-Path $runDir "$stage.log")
        } else {
            $runId = [guid]::NewGuid().ToString('N')
            $log = Join-Path $runDir "$stage.log"
            $arguments = ' --headless --max-fps 120 --audio-driver Dummy --log-file "' + $log + '" -- --legacy-persistence-check --smoke-dir="' + $runDir + '" --smoke-run-id=' + $runId + ' --campaign-replay="' + $Replay + '" --campaign-seed=' + $expected.replay.seed
            if ($stage -eq 'complete') { $arguments += ' --campaign-resume' }
            if ($stage -eq 'final') { $arguments += ' --campaign-final-probe' }
            $process = Start-Process -FilePath $exe -ArgumentList $arguments -WindowStyle Hidden -PassThru
            if (!$process.WaitForExit(120000)) {
                if (!$process.HasExited -and $process.Path -eq $exe) { $process.Kill() }
                throw 'Own campaign test process timed out'
            }
            if ($process.ExitCode -ne 0) { throw "Campaign EXE exit $($process.ExitCode)" }
            if (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet) { throw 'Campaign EXE logged errors' }
            Assert-CampaignResult -RunDir $runDir -RunId $runId -Stage $stage -Rendered $false -Replay $Replay | Out-Null
        }
        if ($stage -ne 'final') { Copy-Item (Join-Path $runDir 'campaign-ui.json') (Join-Path $runDir "campaign-$stage.json") }
    }
    $result = Get-Content (Join-Path $runDir 'campaign-complete.json') -Raw -Encoding utf8 | ConvertFrom-Json
    $result | ConvertTo-Json -Depth 5
} finally { $env:APPDATA = $originalAppData }
