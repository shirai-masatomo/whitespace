$ErrorActionPreference='Stop'
$engine="$PWD/.tools/Godot_v4.7.2-stable_win64_console.exe"
$env:APPDATA="$PWD/artifacts/adventure-core-user"
New-Item -ItemType Directory -Force artifacts | Out-Null
$test=if(Test-Path tools/party-ui-stage.txt){'tests/test_party_ui.gd'}elseif(Test-Path tools/tactics-stage.txt){'tests/test_tactics.gd'}else{'tests/test_adventure.gd'}
foreach ($entry in @(@('--editor','--import','--quit'),@('--script',$test))) {
 $label=if($entry[0] -eq '--editor'){'import'}else{'core'}
 $log="$PWD/artifacts/adventure-$label.log"
 $arguments=@('--headless','--path',"$PWD",'--log-file',$log)+$entry
 $process=Start-Process -FilePath $engine -ArgumentList (($arguments | ForEach-Object {'"'+$_+'"'}) -join ' ') -WindowStyle Hidden -PassThru
 if (!$process.WaitForExit(45000)) {$process.Kill();throw 'Adventure core/import timeout'}
 $process.Refresh()
 if ($process.ExitCode -ne 0 -or (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet)) {Get-Content $log;throw 'Adventure checkpoint failed'}
 Get-Content $log | Select-Object -Last 5
}
