param([Parameter(Mandatory)][string]$ReviewDirectory,[Parameter(Mandatory)][string]$ZipPath,[switch]$VerifyOnly)
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'build_path.ps1')
$build=Resolve-DiveBuild -Project $project
$buildRoot=[IO.Path]::GetFullPath((Join-Path $project 'build'))
$zip=[IO.Path]::GetFullPath($ZipPath)
$review=[IO.Path]::GetFullPath($ReviewDirectory)
if (!$zip.StartsWith($buildRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath $zip)) { throw 'Expected an existing distribution ZIP inside build' }
$meta=Get-Content (Join-Path $build 'BUILD.json') -Raw | ConvertFrom-Json
$ci=Get-Content (Join-Path $review 'ci.json') -Raw | ConvertFrom-Json
if ($ci.conclusion -ne 'success' -or $ci.head_sha -ne $meta.game_commit -or $ci.verification_scope -ne 'full-structural' -or !$ci.run_id -or !$ci.build_artifact_id -or !$ci.evidence_artifact_id -or !$meta.version) { throw 'Exact successful structural CI/build provenance required' }
$exeHash=(Get-FileHash (Join-Path $build 'DiveInUnder.exe')).Hash
$pckHash=(Get-FileHash (Join-Path $build 'DiveInUnder.pck')).Hash
function Read-Proof([string]$Path) { Get-Content (Join-Path $review $Path) -Raw | ConvertFrom-Json -Depth 80 }
foreach ($kind in @('equipment-assets','status')) {
    foreach ($suffix in @('','-resume')) {
        $iso=Read-Proof "$kind-isolated/isolation$suffix.json"
        if (!$iso.result.NonInteractive -or !$iso.result.DesktopMatched -or $iso.result.TimedOut -or $iso.result.ExitCode -ne 0 -or $iso.exe_sha256 -ne $exeHash -or $iso.pck_sha256 -ne $pckHash) { throw 'Cloud rendered evidence must match exact downloaded EXE/PCK' }
        $proof=Read-Proof "$kind-isolated/$kind-review$suffix.json"
        if (!$proof.complete -or !$proof.rendered -or $proof.run_id -ne $iso.run_id) { throw 'Missing exact rendered run proof' }
    }
}
$art=Read-Proof 'equipment-assets-isolated/equipment-assets-review.json'
$artRestart=Read-Proof 'equipment-assets-isolated/equipment-assets-review-resume.json'
if (!$art.new_game_button -or !$art.starter_worn -or !$art.head_exclusive -or !$art.viewport_transfers -or !$art.legacy_preserved -or $art.mapped_existing -ne 10 -or !$artRestart.separate_restart -or $art.save_sha256 -ne $artRestart.save_sha256) { throw 'Starter, artwork, legacy state and separate restart must pass' }
$status=Read-Proof 'status-isolated/status-review.json'
$statusRestart=Read-Proof 'status-isolated/status-review-resume.json'
if (!$status.read_only -or !$status.no_mutation -or !$status.keyboard -or !$status.wheel_scroll -or !$status.origin_return -or !$statusRestart.separate_restart -or $status.save_sha256 -ne $status.save_after_sha256 -or $status.save_sha256 -ne $statusRestart.save_sha256) { throw 'Status interactions must remain read-only and restartable' }
$migration=Read-Proof 'migration-headless/summary.json'
if (!$migration.complete -or $migration.cases.Count -lt 8 -or $migration.build.game_commit -ne $meta.game_commit) { throw 'All required legacy EXE cases must pass' }
$repeat=Read-Proof 'campaign-repeat.json'
$campaign=Read-Proof 'campaign-headless/campaign-complete.json'
$final=Read-Proof 'campaign-headless/campaign-final.json'
if (!$repeat.comparison.strict_equal -or $repeat.metrics.invalid_results -ne 0 -or !$campaign.complete -or !$campaign.warehouse_roundtrip -or !$campaign.post_clear_replay -or !$final.final_restart -or $campaign.save_sha256 -ne $final.save_sha256) { throw 'Normal campaign replay and separate restart required' }
# Compare the ZIP payload rather than assuming an adjacent archive holds the same build.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive=[IO.Compression.ZipFile]::OpenRead($zip)
try {
    foreach ($name in @('DiveInUnder.exe','DiveInUnder.pck')) {
        $entry=$archive.GetEntry($name)
        if (!$entry) { throw "ZIP missing $name" }
        $stream=$entry.Open()
        try { $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream)) } finally { $stream.Dispose() }
        if ($hash -ne (Get-FileHash (Join-Path $build $name)).Hash) { throw 'ZIP payload mismatch' }
    }
} finally { $archive.Dispose() }
if ($VerifyOnly) { Write-Output 'Exact cloud CI, rendering, migration, restart and ZIP checks passed'; return }
$relative=(Get-Content (Join-Path $buildRoot 'candidate.txt') -Raw).Trim()
$pointer=Join-Path $buildRoot 'current.txt'
$previous=(Get-Content $pointer -Raw).Trim()
$normalZip=Join-Path $buildRoot 'DiveInUnder-foundation-windows-x64.zip'
$previousHash=(Get-FileHash $normalZip).Hash
$archiveRoot=Join-Path $buildRoot 'archive'
New-Item -ItemType Directory -Force -Path $archiveRoot | Out-Null
$previousZip=Join-Path $archiveRoot ("DiveInUnder-previous-"+$previousHash.Substring(0,12)+".zip")
if (!(Test-Path -LiteralPath $previousZip)) { Copy-Item -LiteralPath $normalZip -Destination $previousZip }
if ((Get-FileHash $previousZip).Hash -ne $previousHash) { throw 'Previous distribution archive mismatch' }
$tempZip=Join-Path $buildRoot ('distribution-'+[guid]::NewGuid().ToString('N')+'.tmp')
Copy-Item -LiteralPath $zip -Destination $tempZip
[IO.File]::Move($tempZip,$normalZip,$true)
$tempPointer=Join-Path $buildRoot ('current-'+[guid]::NewGuid().ToString('N')+'.tmp')
[IO.File]::WriteAllText($tempPointer,$relative,[Text.Encoding]::ASCII)
[IO.File]::Move($tempPointer,$pointer,$true)
@{version=$meta.version;game_commit=$meta.game_commit;relative_directory=$relative;previous_directory=$previous;exe_sha256=$exeHash;pck_sha256=$pckHash;zip_sha256=(Get-FileHash $normalZip).Hash;previous_zip_archive=$previousZip;verification='cloud-full-structural';ci_run_id=$ci.run_id;build_artifact_id=$ci.build_artifact_id;evidence_artifact_id=$ci.evidence_artifact_id;published_utc=[DateTime]::UtcNow.ToString('o');existing_processes_untouched=$true;user_save_edited_by_publish=$false} | ConvertTo-Json | Set-Content (Join-Path $buildRoot 'current.json') -Encoding utf8
Copy-Item (Join-Path $buildRoot 'current.json') (Join-Path $review 'local-release.json')
Write-Output "Normal entry and distribution ZIP now select $($meta.version)."

