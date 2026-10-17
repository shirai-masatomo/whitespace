$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'build_path.ps1')
$build = Resolve-DiveBuild -Project $project
$meta = Get-Content (Join-Path $build 'BUILD.json') -Raw -Encoding utf8 | ConvertFrom-Json
$exeHash = (Get-FileHash (Join-Path $build 'DiveInUnder.exe')).Hash
$pckHash = (Get-FileHash (Join-Path $build 'DiveInUnder.pck')).Hash
$audit = Get-Content (Join-Path $project 'artifacts/campaign-isolated/isolation-complete.json') -Raw -Encoding utf8 | ConvertFrom-Json
if (!$audit.result.NonInteractive -or !$audit.result.DesktopMatched -or $audit.result.ExitCode -ne 0 -or $audit.build.game_commit -ne $meta.game_commit -or $audit.exe_sha256 -ne $exeHash -or $audit.pck_sha256 -ne $pckHash) { throw 'Candidate differs from verified isolated EXE' }
foreach ($mode in @('campaign-isolated','campaign-headless')) {
    $complete = Get-Content (Join-Path $project "artifacts/$mode/campaign-complete.json") -Raw -Encoding utf8 | ConvertFrom-Json
    $final = Get-Content (Join-Path $project "artifacts/$mode/campaign-final.json") -Raw -Encoding utf8 | ConvertFrom-Json
    if (!$complete.complete -or !$complete.warehouse_roundtrip -or !$complete.post_clear_replay -or !$final.final_restart -or $complete.clear_state_sha256 -ne $complete.expected_clear_sha256 -or $complete.save_sha256 -ne $final.save_sha256) { throw "Incomplete $mode proof" }
}
$repeat = Get-Content (Join-Path $project 'artifacts/campaign-repeat.json') -Raw -Encoding utf8 | ConvertFrom-Json -Depth 80
if (!$repeat.comparison.strict_equal -or $repeat.metrics.invalid_results -ne 0) { throw 'Campaign replay is not verified' }
$root = Join-Path $project 'build'
$relative = (Get-Content (Join-Path $root 'candidate.txt') -Raw).Trim()
$pointer = Join-Path $root 'current.txt'
$previous = if (Test-Path $pointer) { (Get-Content $pointer -Raw).Trim() } else { 'windows' }
$temporary = Join-Path $root ('current-' + [guid]::NewGuid().ToString('N') + '.tmp')
[IO.File]::WriteAllText($temporary,$relative,[Text.Encoding]::ASCII)
# Only the small pointer changes. Existing EXE/PCK directories are never edited/deleted.
[IO.File]::Move($temporary,$pointer,$true)
@{game_commit=$meta.game_commit;relative_directory=$relative;previous_directory=$previous;exe_sha256=$exeHash;pck_sha256=$pckHash;published_utc=[DateTime]::UtcNow.ToString('o');existing_processes_untouched=$true} | ConvertTo-Json | Set-Content (Join-Path $root 'current.json') -Encoding utf8
Write-Output "Local Play.cmd now selects $relative; previous release retained."
