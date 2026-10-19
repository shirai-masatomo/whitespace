param([string]$Base='1a8da5b')
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$changed=@(git -C $project diff --name-only --relative $Base HEAD -- core data)
if ($LASTEXITCODE -ne 0 -or $changed.Count -ne 1 -or $changed[0] -ne 'core/expedition.gd') {throw 'Only reviewed initial-trip validation may change in core/data'}
$old=(git -C $project show "${Base}:projects/dive-in-under/core/expedition.gd") -join "`n"
$expected=$old.Replace('or s.trips<1: return "Invalid progression"','or (s.trips==0 and (s.phase!="town" or s.schema_version<5 or s.highest_floor!=0)): return "Invalid progression"')
$actual=(Get-Content (Join-Path $project 'core/expedition.gd') -Raw).Replace("`r",'').TrimEnd()
if($expected -eq $old -or $actual -ne $expected.TrimEnd()) {throw 'Unexpected core edit; focused scope rejected'}
git -C $project diff --exit-code $Base HEAD -- ui/preparation_music.gd assets/bgm core/combat.gd core/save_store.gd data | Out-Null
if ($LASTEXITCODE -ne 0) {throw 'BGM, saves, balance and data must remain unchanged'}
Write-Output 'Only the initial unstarted-town trip validation changed; battle/save/data/BGM unchanged.'
