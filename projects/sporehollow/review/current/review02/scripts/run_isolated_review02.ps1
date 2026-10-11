param([ValidateSet('after','ui')][string]$Phase='ui')
$ErrorActionPreference='Stop'
$game='C:\Users\masat\Documents\Codex\2026-10-10\task\colony-structure-01-work\projects\sporehollow'
$base=$PSScriptRoot
$candidate=Join-Path $base 'candidate/WhistleRanch-Autonomy-Partial.exe'
$exe=Join-Path $game '.tools/Godot_v4.7.2-stable_win64.exe'
$out=if($Phase -eq 'after'){Join-Path $base 'after'}else{Join-Path $base 'tests/isolated-ui'}
$script=if($Phase -eq 'after'){Join-Path $base 'capture_frames.gd'}else{Join-Path $base 'test_review02_ui.gd'}
New-Item -ItemType Directory -Force -Path $out,"$out/isolated-user-data" | Out-Null
Add-Type -Path (Join-Path $game 'tools/isolated_desktop.cs')
$environment=[System.Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
[Environment]::GetEnvironmentVariables().GetEnumerator() | ForEach-Object {$environment[$_.Key]=[string]$_.Value}
$environment['APPDATA']="$out/isolated-user-data"
$environment['LOCALAPPDATA']="$out/isolated-user-data"
$environment['FARM_REVIEW_OUTPUT']=$out
$cmd='"'+$exe+'" --main-pack "'+$candidate+'" --audio-driver Dummy --rendering-method gl_compatibility --max-fps 30 --resolution 1280x800 --log-file "'+$out+'/isolated.log" --script "'+$script+'" -- --isolated-review'
$stamp=Get-Content -LiteralPath (Join-Path $game 'game/build_stamp.json') -Raw | ConvertFrom-Json
$record=@{implementation_commit=$stamp.commit;asset_delivery_commit=$stamp.asset_delivery_commit;sha256=(Get-FileHash -LiteralPath $candidate).Hash;phase=$Phase;command=$cmd;user_data="$out/isolated-user-data";start_utc=[DateTime]::UtcNow.ToString('o')}
try {$record.result=[FarmIsolatedDesktop]::Run($exe,$cmd,$game,$environment,30)}
catch {$record.error=$_.Exception.Message;throw}
finally {$record.end_utc=[DateTime]::UtcNow.ToString('o');$record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath "$out/isolation.json" -Encoding UTF8}
if($record.result.ExitCode -ne 0 -or -not $record.result.NonInteractive -or -not $record.result.DesktopMatched -or $record.result.TimedOut){throw 'Isolated review failed. No desktop fallback.'}
if(Select-String -LiteralPath "$out/isolated.log" -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet){throw 'Game reported an error.'}
Write-Output "Verified isolated $Phase : $out"
