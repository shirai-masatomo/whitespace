param([string]$BuildDirectory='')
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
if (!$BuildDirectory) { . (Join-Path $PSScriptRoot 'build_path.ps1'); $BuildDirectory=Resolve-DiveBuild -Project $project }
$dir=Join-Path $project 'artifacts/party-ui/after'
New-Item -ItemType Directory -Force $dir | Out-Null
Add-Type -Path (Join-Path $PSScriptRoot 'isolated_desktop.cs')
$environment=[Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
[Environment]::GetEnvironmentVariables().GetEnumerator() | ForEach-Object {$environment[$_.Key]=[string]$_.Value}
$environment['APPDATA']=Join-Path $dir 'user-data'; $environment['LOCALAPPDATA']=Join-Path $dir 'local-data'
$saveFolder=Join-Path $environment['APPDATA'] 'Godot/app_userdata/Dive In Under — 戦闘基盤'
New-Item -ItemType Directory -Force $saveFolder | Out-Null
$sentinel=Join-Path $saveFolder 'campaign-v1.json'; [IO.File]::WriteAllText($sentinel,'{"sentinel":"ignore and preserve old save"}')
$oldHash=(Get-FileHash $sentinel).Hash
$probe=[DiveIsolatedDesktop]::Run('','','',$environment,5)
if (!$probe.NonInteractive) {throw 'No normal desktop fallback'}
$runId=[guid]::NewGuid().ToString('N'); $log=Join-Path $dir 'render.log'; $exe=Join-Path $BuildDirectory 'DiveInUnder.exe'
$arguments=@('--audio-driver','Dummy','--rendering-method','gl_compatibility','--max-fps','30','--resolution','1280x720','--log-file',$log,'--',"--smoke-dir=$dir","--smoke-run-id=$runId",'--party-ui-review','--campaign-seed=10000')
$command='"'+$exe+'" '+(($arguments | ForEach-Object {'"'+$_+'"'}) -join ' ')
$watch=[Diagnostics.Stopwatch]::StartNew()
$result=[DiveIsolatedDesktop]::Run($exe,$command,$BuildDirectory,$environment,150)
$watch.Stop(); $afterHash=(Get-FileHash $sentinel).Hash
@{elapsed_ms=$watch.ElapsedMilliseconds;run_id=$runId;result=$result;exe_sha256=(Get-FileHash $exe).Hash;pck_sha256=(Get-FileHash (Join-Path $BuildDirectory 'DiveInUnder.pck')).Hash;normal_desktop_fallback=$false;normal_user_data_accessed=$false;save_before_sha256=$oldHash;save_after_sha256=$afterHash;renderer='Actual distribution EXE/PCK'} | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $dir 'isolation.json') -Encoding utf8
if (!$result.NonInteractive -or !$result.DesktopMatched -or $result.TimedOut -or $result.ExitCode -ne 0 -or $oldHash -ne $afterHash) { if(Test-Path $log){Get-Content $log | Select-Object -Last 30}; throw 'Isolated journey failed' }
if (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet) { Get-Content $log; throw 'Engine logged error' }
$proof=Get-Content (Join-Path $dir 'party-ui-review.json') -Raw | ConvertFrom-Json
if (!$proof.complete -or !$proof.rendered -or !$proof.no_save_store -or !$proof.exit_button_pressed -or !$proof.fixtures_labelled -or $proof.run_id -ne $runId -or $proof.version -ne '0.11.0' -or $proof.checks.Count -lt 15) {throw 'Missing actual party UI input and completion proof'}
$play=Get-Content (Join-Path $BuildDirectory 'PLAY.txt') -Raw
if ($play -notmatch '0\.11\.0' -or $play -notmatch '999' -or $play -notmatch 'リセット') {throw 'Distribution instructions mismatch'}
Write-Output "PARTY_UI_EXE_OK: actual EXE/PCK, exit 0, complete proof, $($watch.ElapsedMilliseconds) ms."
