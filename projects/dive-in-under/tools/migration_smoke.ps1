param([switch]$Rendered)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'build_path.ps1')
$build = Resolve-DiveBuild -Project $project
$exe = Join-Path $build 'DiveInUnder.exe'
$root = Join-Path $project $(if($Rendered){'artifacts/migration-isolated'}else{'artifacts/migration-headless'})
New-Item -ItemType Directory -Force $root | Out-Null
$environment = [Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
[Environment]::GetEnvironmentVariables().GetEnumerator() | ForEach-Object { $environment[$_.Key] = [string]$_.Value }
if ($Rendered) {
    Add-Type -Path (Join-Path $PSScriptRoot 'isolated_desktop.cs')
    $probe = [DiveIsolatedDesktop]::Run('','','',$environment,5)
    $probe | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $root 'permission-probe.json') -Encoding utf8
    if (!$probe.NonInteractive) { throw 'Noninteractive probe failed; no desktop fallback' }
}
$originalAppData = $env:APPDATA
$records = @()
try {
    foreach ($case in @('1-before','2-inside','2-story','1-town','2-battle','2-death','3-battle')) {
        $dir = Join-Path $root ($case+'-'+[guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory $dir | Out-Null
        $fixture = Join-Path $project "artifacts/migration-fixtures/$case.json"
        $originalHash = (Get-FileHash $fixture).Hash.ToLowerInvariant()
        Copy-Item -LiteralPath $fixture -Destination (Join-Path $dir 'campaign-smoke.json')
        foreach ($stage in @('migrate','restart')) {
            $runId = [guid]::NewGuid().ToString('N')
            $log = Join-Path $dir "$stage.log"
            $argsText = '--audio-driver Dummy --max-fps 120 --log-file "'+$log+'"'
            if ($Rendered) { $argsText += ' --rendering-method gl_compatibility --resolution 1280x720' }
            else { $argsText += ' --headless' }
            $argsText += ' -- --smoke-dir="'+$dir+'" --smoke-run-id='+$runId+' --migration-probe'
            if ($stage -eq 'restart') { $argsText += ' --migration-resume' }
            $environment['APPDATA'] = Join-Path $dir 'user-data'
            $environment['LOCALAPPDATA'] = Join-Path $dir 'local-data'
            if ($Rendered) {
                $result = [DiveIsolatedDesktop]::Run($exe,('"'+$exe+'" '+$argsText),$project,$environment,45)
                @{run_id=$runId;result=$result;exe_sha256=(Get-FileHash $exe).Hash;pck_sha256=(Get-FileHash (Join-Path $build 'DiveInUnder.pck')).Hash;build=(Get-Content (Join-Path $build 'BUILD.json') -Raw | ConvertFrom-Json)} | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $dir "isolation-$stage.json") -Encoding utf8
                if (!$result.NonInteractive -or !$result.DesktopMatched -or $result.TimedOut -or $result.ExitCode -ne 0) { throw "Isolated migration failed: $case $stage" }
            } else {
                $env:APPDATA = $environment['APPDATA']
                $proc = Start-Process -FilePath $exe -ArgumentList $argsText -WindowStyle Hidden -PassThru
                if (!$proc.WaitForExit(45000)) {
                    if (!$proc.HasExited -and $proc.Path -eq $exe) { $proc.Kill() }
                    throw 'Own migration test process timed out'
                }
                if ($proc.ExitCode -ne 0) { throw 'Migration EXE failed' }
            }
            if (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet) { throw 'Migration EXE logged an error' }
            $report = Get-Content (Join-Path $dir $(if($stage -eq 'restart'){'migration-restart.json'}else{'migration-ui.json'})) -Raw -Encoding utf8 | ConvertFrom-Json
            if ($report.run_id -ne $runId -or !$report.complete -or $report.rendered -ne [bool]$Rendered) { throw 'Missing or stale migration result' }
            if ($report.save_sha256 -ne (Get-FileHash (Join-Path $dir 'campaign-smoke.json')).Hash.ToLowerInvariant()) { throw 'Migrated save hash mismatch' }
            if ($stage -eq 'migrate' -and ($report.old_sha256 -ne $originalHash -or $report.archive_sha256 -ne $originalHash)) { throw 'Legacy bytes were not preserved' }
        }
        $records += @{case=$case;directory=$dir;complete=$true;original_sha256=$originalHash;save_sha256=$report.save_sha256}
    }
    @{complete=$true;rendered=[bool]$Rendered;cases=$records;build=(Get-Content (Join-Path $build 'BUILD.json') -Raw | ConvertFrom-Json)} | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $root 'summary.json') -Encoding utf8
    Write-Output "Migration EXE: $($records.Count) legacy fixtures and separate restarts passed; rendered=$Rendered"
} finally { $env:APPDATA = $originalAppData }
