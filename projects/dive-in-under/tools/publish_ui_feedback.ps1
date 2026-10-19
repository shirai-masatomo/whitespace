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
if ($ci.conclusion -ne 'success' -or $ci.head_sha -ne $meta.game_commit -or $ci.verification_scope -ne 'ui-feedback-01-07-unchanged-core' -or !$ci.run_id -or !$ci.build_artifact_id -or !$ci.evidence_artifact_id -or $meta.version -ne '0.6.1') {throw 'Exact successful session UI CI/build provenance required'}
# This UI release reuses baseline core/data verification, rather than pretending to rerun it.
git -C $project diff --exit-code a5c3c6925fbc501d24ce84ccfa1f2fbbeed74456 $meta.game_commit -- core data | Out-Null
if ($LASTEXITCODE -ne 0) {throw 'UI-only publisher rejects changed core/data'}
git -C $project diff --exit-code $meta.game_commit HEAD -- ui core data assets/interface assets/equipment assets/visual-candidates project.godot export_presets.cfg | Out-Null
if ($LASTEXITCODE -ne 0) {throw 'Runtime source changed since validated build'}
$exeHash=(Get-FileHash (Join-Path $build 'DiveInUnder.exe')).Hash
$pckHash=(Get-FileHash (Join-Path $build 'DiveInUnder.pck')).Hash

$iso=Get-Content (Join-Path $review 'evidence/isolation.json') -Raw | ConvertFrom-Json
if (!$iso.result.NonInteractive -or !$iso.result.DesktopMatched -or $iso.result.TimedOut -or $iso.result.ExitCode -ne 0 -or $iso.normal_desktop_fallback -or $iso.normal_user_data_accessed -or $iso.exe_sha256 -ne $exeHash -or $iso.pck_sha256 -ne $pckHash -or $iso.save_before_sha256 -ne $iso.save_after_sha256) {throw 'Exact isolated EXE/PCK and unchanged save sentinel required'}
$proof=Get-Content (Join-Path $review 'evidence/feedback-review.json') -Raw | ConvertFrom-Json
if (!$proof.complete -or !$proof.rendered -or !$proof.no_save_store -or $proof.run_id -ne $iso.run_id -or @($proof.checks.PSObject.Properties).Count -ne 7 -or !$proof.checks.'02'.punctuation_ok -or !$proof.checks.'01'.detail_full_name -or !$proof.checks.'03'.transfer -or !$proof.checks.'04'.aligned -or !$proof.checks.'05'.start_button_tested -or !$proof.checks.'07'.fixture_aligned -or !$proof.checks.'07'.normal_case.consistent) {throw 'All seven focused feedback checks required'}
foreach($name in @('01-status-equipment','02-equipment','03-warehouse','04-status-abilities','05-title','06-preparation','07-battle','07-normal-encounter')) {
    if(!(Test-Path (Join-Path $review "after/$name.png"))) {throw "Missing actual screenshot: $name"}
}
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
if ($VerifyOnly) { Write-Output 'Exact cloud CI, session UI, restart, unchanged core/data and ZIP checks passed'; return }
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
@{version=$meta.version;game_commit=$meta.game_commit;relative_directory=$relative;previous_directory=$previous;exe_sha256=$exeHash;pck_sha256=$pckHash;zip_sha256=(Get-FileHash $normalZip).Hash;previous_zip_archive=$previousZip;verification='cloud-ui-feedback-01-07-unchanged-core';ci_run_id=$ci.run_id;build_artifact_id=$ci.build_artifact_id;evidence_artifact_id=$ci.evidence_artifact_id;published_utc=[DateTime]::UtcNow.ToString('o');existing_processes_untouched=$true;user_save_edited_by_publish=$false} | ConvertTo-Json | Set-Content (Join-Path $buildRoot 'current.json') -Encoding utf8
Copy-Item (Join-Path $buildRoot 'current.json') (Join-Path $review 'local-release.json')
Write-Output "Normal entry and distribution ZIP now select $($meta.version)."

