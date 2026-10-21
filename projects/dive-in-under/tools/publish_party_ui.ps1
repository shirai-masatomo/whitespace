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
if ($ci.conclusion -ne 'success' -or $ci.head_sha -ne $meta.game_commit -or $ci.verification_scope -ne 'party-ui-0.11.0' -or !$ci.run_id -or !$ci.build_artifact_id -or !$ci.evidence_artifact_id -or $meta.version -ne '0.11.0') {throw 'Exact successful journey CI/build provenance required'}
& (Join-Path $PSScriptRoot 'journey_scope.ps1') -Adventure -VerifiedSource $meta.game_commit
$runtimeDiff=@(git -C $project diff --name-only $meta.game_commit HEAD -- ui core data assets project.godot export_presets.cfg | Where-Object { $_ -notmatch '\.md$' })
if ($runtimeDiff.Count -ne 0) {throw 'Runtime source changed since validated build'}
$exeHash=(Get-FileHash (Join-Path $build 'DiveInUnder.exe')).Hash
$pckHash=(Get-FileHash (Join-Path $build 'DiveInUnder.pck')).Hash
$iso=Get-Content (Join-Path $review 'after/isolation.json') -Raw | ConvertFrom-Json
if (!$iso.result.NonInteractive -or !$iso.result.DesktopMatched -or $iso.result.TimedOut -or $iso.result.ExitCode -ne 0 -or $iso.normal_desktop_fallback -or $iso.normal_user_data_accessed -or $iso.exe_sha256 -ne $exeHash -or $iso.pck_sha256 -ne $pckHash -or $iso.save_before_sha256 -ne $iso.save_after_sha256) {throw 'Exact isolated EXE/PCK and unchanged save sentinel required'}
$core=Get-Content (Join-Path $review 'core.json') -Raw | ConvertFrom-Json
if (!$core.complete -or $core.checks.Count -lt 15 -or 'full bag one-to-one companion exchange keeps both individuals' -notin $core.checks -or 'single coin half moves one' -notin $core.checks) {throw 'Targeted core confirmation missing'}
$proof=Get-Content (Join-Path $review 'after/party-ui-review.json') -Raw | ConvertFrom-Json
if (!$proof.complete -or !$proof.rendered -or !$proof.no_save_store -or $proof.run_id -ne $iso.run_id -or !$proof.exit_button_pressed -or !$proof.fixtures_labelled -or $proof.version -ne '0.11.0' -or $proof.checks.Count -lt 15) {throw 'Actual party UI input and completion required'}
foreach ($name in @('Shift left equips selected companion only','drag full frame unequips to exact warehouse cell','warehouse drag equips companion','right click returns one screen with selected actor','Shift drag floors odd stack and preserves total','Shift right moves once and does not go back','only full acquisition opens replacement UI','cancel preserves unreceived reward and bag','portal right click chooses neither return nor stay','new strategy UI preserves battle action ledger')) {if ($name -notin $proof.checks) {throw "Missing focused operation $name"}}
foreach ($name in @('01-normal-preparation','02-equipment-companion','03-equipment-warehouse','04-equipment-filter','05-equipment-hero','06-status-hero','07-status-companion-abilities','08-tactics-overview','09-tactics-individual','10-tactics-save-select','11-items','12-items-half-stack','13-items-manual-cells','14-chest-before','15-chest-acquired','16-descent','16-exploration','17-loot-full-before','18-loot-replace','19-loot-cancelled','20-portal-five','21-tactics-battle-switch')) {if (!(Test-Path (Join-Path $review "after/$name.png"))) {throw "Missing actual screenshot $name"}}
if (!(Test-Path (Join-Path $build 'Debug.cmd'))) {throw 'Missing distinct debug entry'}
$play=Get-Content (Join-Path $build 'PLAY.txt') -Raw
if ($play -notmatch '0\.11\.0' -or $play -match '自動保存されます|続きから再開' -or $play -notmatch 'リセット') {throw 'Stale distribution instructions'}
# This publisher verifies the user-requested party UI differences.
# It does not reinterpret the preserved 0.9.0 whole-journey evidence as a new full playthrough.
# Compare the ZIP payload rather than assuming an adjacent archive holds the same build.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive=[IO.Compression.ZipFile]::OpenRead($zip)
try {
    foreach ($name in @('DiveInUnder.exe','DiveInUnder.pck','Debug.cmd','PLAY.txt','BUILD.json')) {
        $entry=$archive.GetEntry($name)
        if (!$entry) { throw "ZIP missing $name" }
        $stream=$entry.Open()
        try { $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream)) } finally { $stream.Dispose() }
        if ($hash -ne (Get-FileHash (Join-Path $build $name)).Hash) { throw 'ZIP payload mismatch' }
    }
} finally { $archive.Dispose() }
if ($VerifyOnly) { Write-Output 'Exact cloud CI, grouped rule and UI proof, protected save and ZIP checks passed'; return }
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
@{version=$meta.version;game_commit=$meta.game_commit;relative_directory=$relative;previous_directory=$previous;exe_sha256=$exeHash;pck_sha256=$pckHash;zip_sha256=(Get-FileHash $normalZip).Hash;previous_zip_archive=$previousZip;verification='party-ui-0.11.0';ci_run_id=$ci.run_id;build_artifact_id=$ci.build_artifact_id;evidence_artifact_id=$ci.evidence_artifact_id;published_utc=[DateTime]::UtcNow.ToString('o');existing_processes_untouched=$true;user_save_edited_by_publish=$false} | ConvertTo-Json | Set-Content (Join-Path $buildRoot 'current.json') -Encoding utf8
Copy-Item (Join-Path $buildRoot 'current.json') (Join-Path $review 'local-release.json')
Write-Output "Normal entry and distribution ZIP now select $($meta.version)."

