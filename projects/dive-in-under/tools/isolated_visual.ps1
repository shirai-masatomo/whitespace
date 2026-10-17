param([switch]$ProbeOnly)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$runDir = Join-Path $project 'artifacts/isolated'
New-Item -ItemType Directory -Force $runDir | Out-Null
Add-Type -Path (Join-Path $PSScriptRoot 'isolated_desktop.cs')
$environment = [Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
[Environment]::GetEnvironmentVariables().GetEnumerator() | ForEach-Object { $environment[$_.Key] = [string]$_.Value }
$environment['APPDATA'] = Join-Path $runDir 'user-data'
$environment['LOCALAPPDATA'] = Join-Path $runDir 'local-data'
# Keep this renderer's user/cache data separate from the default desktop runs.
$exe = Join-Path $project 'build/windows/DiveInUnder.exe'
$log = Join-Path $runDir 'render.log'
$cmd = '"' + $exe + '" --audio-driver Dummy --rendering-method gl_compatibility --max-fps 30 --resolution 1280x720 --log-file "' + $log + '" -- --smoke-dir="' + $runDir + '"'
$record = @{ mode= $(if($ProbeOnly){'permission_probe'}else{'isolated_exe'}); start_utc=[DateTime]::UtcNow.ToString('o'); normal_desktop_fallback=$false; data_root=$runDir }
$audit = Join-Path $runDir $(if($ProbeOnly){'permission-probe.json'}else{'isolation.json'})
try {
    if ($ProbeOnly) { $result = [DiveIsolatedDesktop]::Run('','','',$environment,5) }
    else {
        $probe = Get-Content (Join-Path $runDir 'permission-probe.json') -Raw | ConvertFrom-Json
        if (!$probe.result.NonInteractive) { throw 'Successful noninteractive permission probe required' }
        $record.executable = $exe
        $record.exe_sha256 = (Get-FileHash $exe -Algorithm SHA256).Hash
        $record.pck_sha256 = (Get-FileHash (Join-Path $project 'build/windows/DiveInUnder.pck') -Algorithm SHA256).Hash
        $record.build = Get-Content (Join-Path $project 'build/windows/BUILD.json') -Raw | ConvertFrom-Json
        $record.command = $cmd
        $result = [DiveIsolatedDesktop]::Run($exe,$cmd,$project,$environment,45)
    }
    $record.result = $result
} catch { $record.error=$_.Exception.Message; throw }
finally {
    $record.end_utc=[DateTime]::UtcNow.ToString('o')
    $record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $audit -Encoding utf8
    Write-Output "Isolation audit: $audit"
}
if (!$result.NonInteractive) { throw 'Interactive station rejected; no fallback' }
if (!$ProbeOnly) {
    if ($result.ExitCode -ne 0 -or !$result.DesktopMatched -or $result.TimedOut) { throw 'Isolated renderer failed' }
    if (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet) { throw 'Renderer logged errors' }
    $smoke = Get-Content (Join-Path $runDir 'ui-smoke.json') -Raw | ConvertFrom-Json
    if (!$smoke.rendered -or !$smoke.ui_core_equal) { throw 'Invalid rendered smoke result' }
}
$result | ConvertTo-Json
