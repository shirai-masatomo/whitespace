param(
    [ValidateSet('campaign','status-ui')][string]$Verification = 'campaign',
    [string]$ReviewDirectory = '',
    [string]$ZipPath = '',
    [switch]$VerifyOnly
)
$ErrorActionPreference = 'Stop'
if ($VerifyOnly -and $Verification -ne 'status-ui') { throw 'VerifyOnly is supported for status-ui verification' }
$project = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'build_path.ps1')
$build = Resolve-DiveBuild -Project $project
$meta = Get-Content (Join-Path $build 'BUILD.json') -Raw -Encoding utf8 | ConvertFrom-Json
$exeHash = (Get-FileHash (Join-Path $build 'DiveInUnder.exe')).Hash
$pckHash = (Get-FileHash (Join-Path $build 'DiveInUnder.pck')).Hash
if ($Verification -eq 'status-ui') {
    if (!$ReviewDirectory -or !$ZipPath) { throw 'UI release requires exact review and ZIP paths' }
    $review = [IO.Path]::GetFullPath($ReviewDirectory)
    $zip = [IO.Path]::GetFullPath($ZipPath)
    $buildRoot = [IO.Path]::GetFullPath((Join-Path $project 'build'))
    if (!$zip.StartsWith($buildRoot + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath $zip)) { throw 'Release ZIP must exist inside project build' }
    $proof = Get-Content (Join-Path $review 'status-review.json') -Raw | ConvertFrom-Json
    $restart = Get-Content (Join-Path $review 'status-review-resume.json') -Raw | ConvertFrom-Json
    foreach ($suffix in @('','-resume')) {
        $iso = Get-Content (Join-Path $review ("isolation"+$suffix+".json")) -Raw | ConvertFrom-Json
        if (!$iso.result.NonInteractive -or !$iso.result.DesktopMatched -or $iso.result.TimedOut -or $iso.result.ExitCode -ne 0 -or $iso.exe_sha256 -ne $exeHash -or $iso.pck_sha256 -ne $pckHash) { throw 'UI proof does not match this isolated EXE/PCK' }
    }
    if (!$proof.complete -or !$proof.rendered -or !$proof.read_only -or !$proof.no_mutation -or !$proof.keyboard -or !$proof.wheel_scroll -or !$proof.origin_return -or !$restart.complete -or !$restart.rendered -or !$restart.separate_restart -or $proof.save_sha256 -ne $proof.save_after_sha256 -or $proof.save_sha256 -ne $restart.save_sha256) { throw 'Incomplete UI or save-invariance evidence' }
    $ci = Get-Content (Join-Path $review 'ci.json') -Raw | ConvertFrom-Json
    if ($ci.conclusion -ne 'success' -or $ci.head_sha -ne $meta.game_commit) { throw 'Exact source CI must succeed before publishing' }
    # UI-only promotion reuses successful core/migration evidence; reject any core/data drift.
    $baseline = '355ded7c0a2af3e97718033d647e979758b5f8bc'
    foreach ($part in @('core','data')) {
        $beforeTree = git -C $project rev-parse ($baseline+':projects/dive-in-under/'+$part)
        if ($LASTEXITCODE -ne 0) { throw 'Cannot resolve verified baseline' }
        $afterTree = git -C $project rev-parse ($meta.game_commit+':projects/dive-in-under/'+$part)
        if ($LASTEXITCODE -ne 0 -or $beforeTree -ne $afterTree) { throw 'Core/data changed; full verification required' }
    }
    $migration = Get-Content (Join-Path $review 'migration-summary.json') -Raw | ConvertFrom-Json
    if (!$migration.complete -or $migration.cases.Count -lt 1 -or $migration.build.game_commit -ne $meta.game_commit) { throw 'Legacy EXE migration and restart proof required' }
    if ($VerifyOnly) { Write-Output 'Exact UI, CI, core/data and migration release checks passed'; return }
    $relative = (Get-Content (Join-Path $buildRoot 'candidate.txt') -Raw).Trim()
    $pointer = Join-Path $buildRoot 'current.txt'
    $previous = (Get-Content $pointer -Raw).Trim()
    $normalZip = Join-Path $buildRoot 'DiveInUnder-foundation-windows-x64.zip'
    $oldZipHash = (Get-FileHash -LiteralPath $normalZip).Hash
    $archiveRoot = Join-Path $buildRoot 'archive'
    New-Item -ItemType Directory -Force -Path $archiveRoot | Out-Null
    $archive = Join-Path $archiveRoot ("DiveInUnder-previous-"+$oldZipHash.Substring(0,12)+".zip")
    if (!(Test-Path -LiteralPath $archive)) { Copy-Item -LiteralPath $normalZip -Destination $archive }
    if ((Get-FileHash -LiteralPath $archive).Hash -ne $oldZipHash) { throw 'Previous distribution archive mismatch' }
    $temporaryZip = Join-Path $buildRoot ('distribution-'+[guid]::NewGuid().ToString('N')+'.tmp')
    Copy-Item -LiteralPath $zip -Destination $temporaryZip
    [IO.File]::Move($temporaryZip,$normalZip,$true)
    $temporaryPointer = Join-Path $buildRoot ('current-'+[guid]::NewGuid().ToString('N')+'.tmp')
    [IO.File]::WriteAllText($temporaryPointer,$relative,[Text.Encoding]::ASCII)
    [IO.File]::Move($temporaryPointer,$pointer,$true)
    $published = @{game_commit=$meta.game_commit;version=$meta.version;relative_directory=$relative;previous_directory=$previous;exe_sha256=$exeHash;pck_sha256=$pckHash;zip_sha256=(Get-FileHash -LiteralPath $normalZip).Hash;previous_zip_archive=$archive;verification='status-ui';ci_run_id=$ci.run_id;reused_core_baseline=$baseline;published_utc=[DateTime]::UtcNow.ToString('o');existing_processes_untouched=$true;user_save_edited_by_publish=$false}
    $published | ConvertTo-Json | Set-Content (Join-Path $buildRoot 'current.json') -Encoding utf8
    $published | ConvertTo-Json | Set-Content (Join-Path $review 'local-release.json') -Encoding utf8
    Write-Output "Normal Play.cmd and distribution ZIP now select $($meta.version); previous release retained."
    return
}
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
