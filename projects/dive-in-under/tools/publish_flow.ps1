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
if ($ci.conclusion -ne 'success' -or $ci.head_sha -ne $meta.game_commit -or $ci.verification_scope -ne 'exploration-flow-0.8.0' -or !$ci.run_id -or !$ci.build_artifact_id -or !$ci.evidence_artifact_id -or $meta.version -ne '0.8.0') {throw 'Exact successful journey CI/build provenance required'}
& (Join-Path $PSScriptRoot 'journey_scope.ps1')
$runtimeDiff=@(git -C $project diff --name-only $meta.game_commit HEAD -- ui core data assets project.godot export_presets.cfg | Where-Object { $_ -notmatch '\.md$' })
if ($runtimeDiff.Count -ne 0) {throw 'Runtime source changed since validated build'}
$exeHash=(Get-FileHash (Join-Path $build 'DiveInUnder.exe')).Hash
$pckHash=(Get-FileHash (Join-Path $build 'DiveInUnder.pck')).Hash
$iso=Get-Content (Join-Path $review 'after/isolation.json') -Raw | ConvertFrom-Json
if (!$iso.result.NonInteractive -or !$iso.result.DesktopMatched -or $iso.result.TimedOut -or $iso.result.ExitCode -ne 0 -or $iso.normal_desktop_fallback -or $iso.normal_user_data_accessed -or $iso.exe_sha256 -ne $exeHash -or $iso.pck_sha256 -ne $pckHash -or $iso.save_before_sha256 -ne $iso.save_after_sha256) {throw 'Exact isolated EXE/PCK and unchanged save sentinel required'}
$proof=Get-Content (Join-Path $review 'after/flow-review.json') -Raw | ConvertFrom-Json
if (!$proof.complete -or !$proof.rendered -or !$proof.no_save_store -or $proof.run_id -ne $iso.run_id -or !$proof.exit_button_pressed -or !$proof.normal.received_all_one_input -or !$proof.normal.event_result_one_input -or !$proof.normal.field_double_click -or !$proof.normal.new_battle_stats -or !$proof.normal.direct_return_redepart) {throw 'Focused normal route through real input required'}
foreach ($key in @('full_one_for_one','invalid_drop','outside_drop','full_unequip','unequip_with_space','pending_direct_equip','held_E','mouse_repeat','map_preserves_pending','deep_map','dead_target_cleared','stable_shell','status_follows_sprite','status_cleanup')) {if (!$proof.fixtures.$key) {throw "Missing safety fixture $key"}}
foreach ($name in @('00-title','01-preparation','02-battle','03-enemy-detail','04-field-status','05-chest','06-rewards','07-map-pending','08-event-choice','09-event-result','10-equipment','11-full-reward','12-valid-gear-drop','13-direct-reward-equip','14-status-around-actors','15-status-follow-motion','16-status-cleared','17-after-battle','18-boss-and-deep-map','19-normal-redeparture')) {if (!(Test-Path (Join-Path $review "after/$name.png"))) {throw "Missing real screenshot $name"}}
$baseline=Get-Content (Join-Path $project 'review/ui-feedback/journey-0.7.0/after/journey-review.json') -Raw | ConvertFrom-Json
if (!$baseline.complete -or $baseline.normal_route.highest_floor -ne 11) {throw 'Preserved 0.7.0 full-loop baseline required'}
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
if ($VerifyOnly) { Write-Output 'Exact cloud CI, focused input proof, unchanged full-loop baseline and ZIP checks passed'; return }
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
@{version=$meta.version;game_commit=$meta.game_commit;relative_directory=$relative;previous_directory=$previous;exe_sha256=$exeHash;pck_sha256=$pckHash;zip_sha256=(Get-FileHash $normalZip).Hash;previous_zip_archive=$previousZip;verification='exploration-flow-0.8.0';ci_run_id=$ci.run_id;build_artifact_id=$ci.build_artifact_id;evidence_artifact_id=$ci.evidence_artifact_id;published_utc=[DateTime]::UtcNow.ToString('o');existing_processes_untouched=$true;user_save_edited_by_publish=$false} | ConvertTo-Json | Set-Content (Join-Path $buildRoot 'current.json') -Encoding utf8
Copy-Item (Join-Path $buildRoot 'current.json') (Join-Path $review 'local-release.json')
Write-Output "Normal entry and distribution ZIP now select $($meta.version)."

