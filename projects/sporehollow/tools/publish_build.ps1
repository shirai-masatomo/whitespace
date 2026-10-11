param([Parameter(Mandatory)][string]$Executable,[Parameter(Mandatory)][string]$Revision,[bool]$Dirty=$false)
$ErrorActionPreference='Stop'
$project=Split-Path -Parent $PSScriptRoot
$source=(Resolve-Path -LiteralPath $Executable).Path
$work=[IO.Path]::GetFullPath((Join-Path $project 'artifacts/validation/current'))+[IO.Path]::DirectorySeparatorChar
if(-not $source.StartsWith($work,[StringComparison]::OrdinalIgnoreCase)){throw 'Only the current validated scratch build can be published'}
$bundle=Join-Path $project 'artifacts/autonomy-entry-01/bundle'
$target=Join-Path $bundle 'WhistleRanch-Autonomy-Partial.exe'
if(Get-CimInstance Win32_Process | Where-Object {$_.ExecutablePath -eq $target}){throw 'Player game is running; no replacement or restart'}
$fixture=Join-Path $project 'review/current/biome01/tests/legacy-fixture/legacy.snapshot'
& (Join-Path $PSScriptRoot 'verify_cycle_entry09.ps1') -Executable $source -Fixture $fixture -OutputDirectory (Join-Path (Split-Path -Parent $source) 'lifecycle')
if(Get-CimInstance Win32_Process | Where-Object {$_.ExecutablePath -eq $target}){throw 'Player started; replacement stopped'}
New-Item -ItemType Directory -Force -Path $bundle | Out-Null
$staging=Join-Path $bundle 'WhistleRanch.tmp'
try {
    Copy-Item -LiteralPath $source -Destination $staging
    if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $staging).Hash){throw 'Staging hash mismatch'}
    if(Test-Path -LiteralPath $target){[IO.File]::Replace($staging,$target,[NullString]::Value)}else{[IO.File]::Move($staging,$target)}
}finally{if(Test-Path -LiteralPath $staging){Remove-Item -LiteralPath $staging}}
$art=Get-Content -LiteralPath (Join-Path $project 'game/art_provenance.json') -Raw | ConvertFrom-Json
@{implementation_commit=$Revision;commit=$Revision;dirty=$Dirty;asset_delivery_commit=$art.latest_delivery_commit;sha256=(Get-FileHash -LiteralPath $target).Hash;utc=[DateTime]::UtcNow.ToString('o');native_lifecycle_checks=5;automatically_launched=$false;normal_data_unchanged=$true} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $bundle 'BUILD.json') -Encoding utf8
Write-Output "Published $Revision to the existing latest entry. No backup EXE retained; scratch output is cleaned by dev.ps1."
