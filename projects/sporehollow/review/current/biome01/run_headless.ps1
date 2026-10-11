param([string]$Godot='', [ValidateSet('biome','regression','known-baseline-failures')][string]$Suite='biome')
$ErrorActionPreference='Stop'
$gameRoot=(Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
if($Godot -eq ''){$Godot=Join-Path $gameRoot '.tools/Godot_v4.7.2-stable_win64.exe'}
if(-not (Test-Path -LiteralPath $Godot)){throw 'Provide the installed Godot 4.7.2 executable with -Godot.'}
$tests=switch($Suite){
    'biome' {@('test_biome01.gd','test_biome_distribution.gd','test_biome_compat.gd','prepare_biome_views.gd')}
    'regression' {@('test_review02.gd','test_colony_tasks09.gd','test_work_food_chain.gd','test_explicit_storage.gd','test_livestock09.gd','test_nutrition09.gd','test_zones09.gd','test_visible_boundary.gd','test_navigation.gd','test_negotiation.gd','test_animal_commands.gd','test_cycle09.gd')}
    'known-baseline-failures' {@('test_morning_save.gd','test_arrival_routes.gd')}
}
$runRoot=Join-Path $PSScriptRoot ('local-runs/'+[DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss'))
$previous=@{};foreach($name in @('APPDATA','LOCALAPPDATA','FARM_REVIEW_OUTPUT','FARM_LEGACY_FIXTURE')){$previous[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
$results=@()
try{
    foreach($test in $tests){
        $out=Join-Path $runRoot $test.Replace('.gd','')
        New-Item -ItemType Directory -Force -Path $out,(Join-Path $out 'user-data') | Out-Null
        $env:APPDATA=Join-Path $out 'user-data';$env:LOCALAPPDATA=$env:APPDATA;$env:FARM_REVIEW_OUTPUT=$out
        $env:FARM_LEGACY_FIXTURE=Join-Path $PSScriptRoot 'tests/legacy-fixture'
        $arguments='--headless --path "'+$gameRoot+'" --audio-driver Dummy --log-file "'+$out+'/run.log" --script "res://tests/'+$test+'" -- --isolated-review'
        $process=Start-Process -FilePath $Godot -ArgumentList $arguments -WorkingDirectory $gameRoot -WindowStyle Hidden -PassThru
        $timedOut=-not $process.WaitForExit(55000)
        if($timedOut){$process.Kill();$process.WaitForExit(5000) | Out-Null}
        $errors=Select-String -LiteralPath (Join-Path $out 'run.log') -Pattern '^SCRIPT ERROR:|^ERROR:'
        $passed=-not $timedOut -and $process.ExitCode -eq 0 -and -not $errors
        $results+=@{test=$test;passed=$passed;exit_code=$process.ExitCode;timed_out=$timedOut;log=$out+'/run.log'}
        Write-Output "$test passed=$passed"
    }
}finally{foreach($name in $previous.Keys){[Environment]::SetEnvironmentVariable($name,$previous[$name],'Process')}}
$results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $runRoot 'summary.json') -Encoding utf8
if($results.Where({-not $_.passed}).Count -gt 0){throw "Some tests failed. See $runRoot"}
