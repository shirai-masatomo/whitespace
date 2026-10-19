$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
# New loop/storage/UI are tested, but existing combat formula, old configs and save code remain untouched.
git -C $project diff --exit-code 7913054 HEAD -- core/combat.gd core/save_store.gd data/v1/balance.json data/v1/area1-enemies.json data/v1/expedition.json data/v1/expedition-legacy.json data/v1/expedition-legacy-2.json data/v1/expedition-legacy-3.json data/v1/expedition-legacy-4.json assets/bgm assets/title | Out-Null
if ($LASTEXITCODE -ne 0) {throw 'Journey scope changed protected balance/save/BGM/logo inputs'}
