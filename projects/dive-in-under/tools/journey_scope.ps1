param([switch]$Adventure,[string]$VerifiedSource='')
# The original journey guard below is retained for its original UI-only release.
# User A-H explicitly authorizes new combat/loot/currency rules in adventure.json.
# This additional mode keeps legacy/save/music/logo protection and pins new rules
# to the exact successful CI source; it never accepts an arbitrary dirty checkout.
if ($Adventure) {
 $ErrorActionPreference='Stop'
 $project=Split-Path $PSScriptRoot -Parent
 if ($VerifiedSource -notmatch '^[0-9a-f]{40}$') {throw 'An exact verified source is required'}
 git -C $project cat-file -e "$VerifiedSource^{commit}"
 if ($LASTEXITCODE -ne 0) {throw 'Unknown verified source'}
 git -C $project diff --exit-code $VerifiedSource HEAD -- ui core data assets project.godot export_presets.cfg | Out-Null
 if ($LASTEXITCODE -ne 0) {throw 'Runtime differs from successful CI source'}
 git -C $project diff --exit-code 194d5c9 HEAD -- core/save_store.gd core/catalog.gd data/v1/balance.json data/v1/area1-enemies.json data/v1/expedition.json data/v1/expedition-legacy.json data/v1/expedition-legacy-2.json data/v1/expedition-legacy-3.json data/v1/expedition-legacy-4.json assets | Out-Null
 if ($LASTEXITCODE -ne 0) {throw 'Protected old saves, legacy definitions, original art/music/logo changed'}
 $allowed='^(core/(adventure|currency|item_instances|expedition|equipment_condition|storage|combat|journey)\.gd|data/v1/(adventure|expedition-legacy-5)\.json)$'
 $changes=@(git -C $project diff --relative --name-only 194d5c9 HEAD -- core data assets)
 if (@($changes | Where-Object {$_ -notmatch $allowed}).Count -ne 0) {throw 'Changes exceed user-authorized adventure rule files'}
 $oldText=(git -C $project show 194d5c9:projects/dive-in-under/core/combat.gd) -join "`n"
 $newText=Get-Content (Join-Path $project 'core/combat.gd') -Raw
 $pattern='(?ms)^static func damage\(.*?(?=^static func normalized)'
 if ([regex]::Match($oldText,$pattern).Value.Trim() -ne [regex]::Match($newText.Replace("`r",''),$pattern).Value.Trim()) {throw 'Shared damage formula changed'}
 Write-Output 'Adventure scope: exact verified runtime; old save, legacy data, art/music/logo and damage formula protected.'
 return
}
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
# New loop/storage/UI are tested, but existing combat formula, old configs and save code remain untouched.
git -C $project diff --exit-code 7913054 HEAD -- core/combat.gd core/save_store.gd data/v1/balance.json data/v1/area1-enemies.json data/v1/expedition.json data/v1/expedition-legacy.json data/v1/expedition-legacy-2.json data/v1/expedition-legacy-3.json data/v1/expedition-legacy-4.json assets/bgm assets/title | Out-Null
if ($LASTEXITCODE -ne 0) {throw 'Journey scope changed protected balance/save/BGM/logo inputs'}
