param(
    [Parameter(Mandatory)][string]$Executable,
    [Parameter(Mandatory)][string]$Revision,
    [bool]$Dirty=$false
)
$ErrorActionPreference='Stop'
$farmRoot=Split-Path -Parent $PSScriptRoot
$buildRoot=Join-Path $farmRoot 'build'
$source=(Resolve-Path -LiteralPath $Executable).Path
$validationRoot=[IO.Path]::GetFullPath((Join-Path $farmRoot 'artifacts/validation'))+[IO.Path]::DirectorySeparatorChar
if(-not $source.StartsWith($validationRoot,[StringComparison]::OrdinalIgnoreCase)) { throw 'Only a validated output from artifacts/validation can be published.' }
# Do not close or replace a player's running game. The validated output remains available.
if(Get-Process -Name WhistleRanch -ErrorAction SilentlyContinue) {
    throw "Game is running. Close it yourself, then publish $source. The current game was not changed."
}
New-Item -ItemType Directory -Force $buildRoot | Out-Null
$target=Join-Path $buildRoot 'WhistleRanch.exe'
$staging=Join-Path $buildRoot ('WhistleRanch-'+[Guid]::NewGuid().ToString('N')+'.tmp')
try {
    Copy-Item -LiteralPath $source -Destination $staging
    # Atomic replacement also fails safely if the game opens after the process check.
    if(Test-Path -LiteralPath $target) { [IO.File]::Replace($staging,$target,[NullString]::Value) }
    else { [IO.File]::Move($staging,$target) }
} finally {
    if(Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging }
}
Copy-Item -LiteralPath "$farmRoot/assets/fonts/OFL.txt" -Destination "$buildRoot/FONT_LICENSE.txt"
Copy-Item -LiteralPath "$farmRoot/assets/GODOT_COPYRIGHT.txt" -Destination "$buildRoot/GODOT_COPYRIGHT.txt"
Copy-Item -LiteralPath "$farmRoot/assets/ui/SOURCES.md" -Destination "$buildRoot/UI_SOURCES.txt"
$artProvenance=Get-Content -LiteralPath "$farmRoot/game/art_provenance.json" -Raw | ConvertFrom-Json
@{commit=$Revision;dirty=$Dirty;asset_delivery_commit=$artProvenance.latest_delivery_commit;sha256=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash;source=$source;published_utc=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath "$buildRoot/BUILD.json"
Write-Output "Ready: $farmRoot/Play.cmd (build $Revision)"
