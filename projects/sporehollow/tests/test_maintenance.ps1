$ErrorActionPreference='Stop'
$project=Split-Path -Parent $PSScriptRoot
. (Join-Path $project 'tools/workspace_lifecycle.ps1')
$fake=[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'whistle-maintenance-tests'))
if(Test-Path -LiteralPath $fake){throw 'Test root already exists; inspect before reuse'}
New-Item -ItemType Directory -Path "$fake/game","$fake/assets","$fake/artifacts/autonomy-entry-01/bundle/user-data" -Force | Out-Null
Set-Content -LiteralPath "$fake/project.godot" -Value 'fixture'
Set-Content -LiteralPath "$fake/game/world.gd" -Value 'source'
Set-Content -LiteralPath "$fake/assets/original.png" -Value 'formal asset'
Set-Content -LiteralPath "$fake/artifacts/autonomy-entry-01/bundle/user-data/player.sav" -Value 'player save'
$checks=0
function Check($ok,[string]$note){if(-not $ok){throw $note};$script:checks++}
try {
    foreach($path in @($fake,(Join-Path $fake 'game'),(Join-Path $fake 'assets'),(Join-Path $fake 'artifacts/autonomy-entry-01/bundle'),(Join-Path $fake '../escape'))){
        $refused=$false;try{Assert-FarmGeneratedPath $fake $path | Out-Null}catch{$refused=$true};Check $refused "Rejected protected/outside path: $path"
    }
    $scratch=Join-Path $fake 'artifacts/validation/current'
    New-Item -ItemType Directory -Path $scratch -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch 'unknown.txt') -Value 'unowned'
    $refused=$false;try{Remove-FarmScratch $fake $scratch}catch{$refused=$true};Check $refused 'Unknown files must stay'
    Remove-Item -LiteralPath $scratch -Recurse -Force
    Start-FarmScratch $fake $scratch | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch 'candidate.exe') -Value 'test-only output'
    Set-Content -LiteralPath (Join-Path $scratch 'run.log') -Value 'necessary result'
    New-Item -ItemType Directory -Path (Join-Path $scratch 'user-data') | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch 'user-data/private.sav') -Value 'synthetic'
    $refused=$false;try{Start-FarmScratch $fake (Join-Path $fake 'artifacts/isolated/current') | Out-Null}catch{$refused=$true};Check $refused 'Concurrent pipeline refused'
    Complete-FarmScratch $fake $scratch 'fixture' $true
    Check (-not(Test-Path -LiteralPath $scratch)) 'Candidate/synthetic data removed after evidence retained'
    $proof=Get-Content -LiteralPath "$fake/review/current/verification/last-run.json" -Raw | ConvertFrom-Json
    Check ($proof.records.Count -eq 1 -and $proof.records[0].text -match 'necessary result') 'Logs retained; save contents excluded from review'
    Check ((Get-Content -LiteralPath "$fake/artifacts/autonomy-entry-01/bundle/user-data/player.sav" -Raw).Trim() -eq 'player save') 'Player data untouched'
    Check ((Get-Content -LiteralPath "$fake/assets/original.png" -Raw).Trim() -eq 'formal asset') 'Formal asset untouched'
    Start-FarmScratch $fake $scratch | Out-Null;Complete-FarmScratch $fake $scratch 'repeat' $false
    Check (-not(Test-Path -LiteralPath $scratch)) 'Fixed directory reused; failure also cleans generated output'
    Write-Output "Maintenance: $checks checks passed"
}finally{
    if($script:farmLease){$script:farmLease.Dispose();$script:farmLease=$null}
    if($fake -ne [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'whistle-maintenance-tests'))){throw 'Unexpected cleanup path'}
    Remove-Item -LiteralPath $fake -Recurse -Force
}
