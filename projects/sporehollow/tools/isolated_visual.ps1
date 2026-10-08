param([ValidateSet('probe','characters','controls','buildings','shop','book','delivered','story','progression','ui_revision','progression_art','idol_debug','ranch_content','quality','six_motion','corpses','prayer','forest')][string]$Scenario='probe',[switch]$Preview)
$ErrorActionPreference='Stop'
$farmRoot=Split-Path -Parent $PSScriptRoot
$runRoot=Join-Path $farmRoot ('artifacts/isolated/'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Force $runRoot,"$runRoot/user-data" | Out-Null
$revision=(git -C $farmRoot rev-parse HEAD).Trim()
$dirty=[bool](git -C $farmRoot status --porcelain)
$exe=Join-Path $farmRoot '.tools/Godot_v4.7.2-stable_win64.exe'
$script=if($Scenario -eq 'probe'){'tests/render_probe.gd'}elseif($Scenario -eq 'corpses'){'tests/test_corpses_ui.gd'}elseif($Scenario -eq 'six_motion'){'tests/test_six_motion.gd'}elseif($Scenario -eq 'quality'){'tests/test_quality_ui.gd'}elseif($Scenario -eq 'ranch_content'){'tests/test_ranch_content_ui.gd'}elseif($Scenario -eq 'idol_debug'){'tests/test_idol_debug.gd'}elseif($Scenario -eq 'progression_art'){'tests/test_progression_art.gd'}elseif($Scenario -eq 'ui_revision'){'tests/test_ui_revision.gd'}elseif($Scenario -eq 'progression'){'tests/test_progression_ui.gd'}elseif($Scenario -eq 'story'){'tests/visual_story.gd'}elseif($Scenario -eq 'delivered'){'tests/test_delivered_art.gd'}elseif($Scenario -eq 'book'){'tests/visual_book.gd'}elseif($Scenario -eq 'shop'){'tests/visual_shop.gd'}elseif($Scenario -eq 'buildings'){'tests/test_building_art.gd'}elseif($Scenario -eq 'controls'){'tests/test_controls.gd'}else{'tests/visual_characters.gd'}
if($Scenario -eq 'forest'){$script='tests/test_forest_ui.gd'}
if($Scenario -eq 'prayer'){$script='tests/test_prayer_ui.gd'}
$cmd='"'+$exe+'" --path "'+$farmRoot+'" --audio-driver Dummy --rendering-method gl_compatibility --max-fps 30 --resolution 1280x800 --log-file "'+$runRoot+'/render.log" --script '+$script+' -- --isolated-review --output="'+$runRoot+'"'
# No interactive desktop fallback. No SwitchDesktop, SendInput, cursor movement, or user-process discovery.
Add-Type -Path (Join-Path $PSScriptRoot 'isolated_desktop.cs')
$environment=[System.Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
[Environment]::GetEnvironmentVariables().GetEnumerator() | ForEach-Object { $environment[$_.Key]=[string]$_.Value }
$environment['APPDATA']="$runRoot/user-data"
$environment['LOCALAPPDATA']="$runRoot/user-data"
$environment['FARM_REVIEW_OUTPUT']=$runRoot
if($Preview){$environment['FARM_REVIEW_PREVIEW']='1'}
$environment['FARM_REVIEW_COMMIT']=$revision
$environment['FARM_REVIEW_DIRTY']=$dirty.ToString()
$record=@{implementation_commit=$revision;dirty=$dirty;asset_delivery_commit=(Get-Content -LiteralPath (Join-Path $farmRoot 'game/art_provenance.json') -Raw | ConvertFrom-Json).latest_delivery_commit;parent_pid=$PID;purpose=$Scenario;executable=$exe;command=$cmd;start_utc=[DateTime]::UtcNow.ToString('o');data_root="$runRoot/user-data"}
$auditPath=Join-Path $runRoot 'isolation.json'
$record | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $auditPath
try {
    $result=[FarmIsolatedDesktop]::Run($exe,$cmd,$farmRoot,$environment,120)
    $record.result=$result
} catch { $record.error=$_.Exception.Message; throw }
finally { $record.end_utc=[DateTime]::UtcNow.ToString('o'); $record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $auditPath; Write-Output "Isolated render audit: $auditPath" }
if($result.ExitCode -ne 0 -or -not $result.NonInteractive -or -not $result.DesktopMatched) { throw 'Isolated rendering failed; no interactive fallback is permitted.' }
if(Select-String -LiteralPath "$runRoot/render.log" -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw 'Renderer reported an error. Inspect the isolated log.' }
Write-Output "Isolated render output: $runRoot"
