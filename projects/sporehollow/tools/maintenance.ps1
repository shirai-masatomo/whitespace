param([switch]$Clean)
$ErrorActionPreference='Stop'
$project=Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'workspace_lifecycle.ps1')
$before=Get-FarmBytes $project
if($Clean){
    foreach($relative in @('artifacts/validation/current','artifacts/isolated/current','artifacts/launcher-test/current')){Remove-FarmScratch $project (Join-Path $project $relative)}
    Clear-FarmCaches $project
}
$exes=@(Get-ChildItem -LiteralPath $project -Recurse -File -Filter '*.exe' | Where-Object {$_.FullName -notlike "$project\.tools\*"})
$after=Get-FarmBytes $project
@{before_bytes=$before;after_bytes=$after;removed_bytes=$before-$after;game_executables=@($exes.FullName);utc=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $project 'artifacts/maintenance-last.json') -Encoding utf8
Write-Output ("Project {0:N1} -> {1:N1} MiB; game EXEs {2}" -f ($before/1MB),($after/1MB),$exes.Count)
if($exes.Count -gt 1){Write-Warning 'Extra game EXEs require validation/reference audit; not deleted automatically.'}
