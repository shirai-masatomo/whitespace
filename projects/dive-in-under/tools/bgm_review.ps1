param([string]$BuildDirectory="",[string]$RunDirectory="")
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
if (!$RunDirectory) {$RunDirectory=Join-Path $project 'artifacts/bgm'}
if (!$BuildDirectory) {. (Join-Path $PSScriptRoot 'build_path.ps1'); $BuildDirectory=Resolve-DiveBuild -Project $project}
New-Item -ItemType Directory -Force $RunDirectory | Out-Null
Add-Type -Path (Join-Path $PSScriptRoot 'isolated_desktop.cs')
$environment=[Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
[Environment]::GetEnvironmentVariables().GetEnumerator() | ForEach-Object {$environment[$_.Key]=[string]$_.Value}
$environment['APPDATA']=Join-Path $RunDirectory 'user-data'
$environment['LOCALAPPDATA']=Join-Path $RunDirectory 'local-data'
$saveFolder=Join-Path $environment['APPDATA'] 'Godot/app_userdata/Dive In Under — 戦闘基盤'
New-Item -ItemType Directory -Force $saveFolder | Out-Null
$sentinel=Join-Path $saveFolder 'campaign-v1.json'
[IO.File]::WriteAllText($sentinel,'{"sentinel":"old save must be ignored and preserved"}')
$oldHash=(Get-FileHash -LiteralPath $sentinel).Hash
$probe=[DiveIsolatedDesktop]::Run('','','',$environment,5)
if (!$probe.NonInteractive) {throw 'Isolated station required; no normal desktop fallback'}
$exe=Join-Path $BuildDirectory 'DiveInUnder.exe'
foreach ($restart in @($false)) {
    $suffix=if($restart){'-restart'}else{''}
    $runId=[guid]::NewGuid().ToString('N')
    $log=Join-Path $RunDirectory ("render$suffix.log")
    $arguments=@('--audio-driver','Dummy','--rendering-method','gl_compatibility','--max-fps','30','--resolution','1280x720','--log-file',$log,'--',"--smoke-dir=$RunDirectory","--smoke-run-id=$runId",'--bgm-review',"--reference-root=$project")
    if($restart) {$arguments+='--ui-integration-restart'}
    $command='"'+$exe+'" '+(($arguments|ForEach-Object {'"'+$_+'"'}) -join ' ')
    $watch=[Diagnostics.Stopwatch]::StartNew()
    $result=[DiveIsolatedDesktop]::Run($exe,$command,$project,$environment,60)
    $watch.Stop()
    $afterHash=(Get-FileHash -LiteralPath $sentinel).Hash
    @{elapsed_ms=$watch.ElapsedMilliseconds;run_id=$runId;result=$result;exe_sha256=(Get-FileHash $exe).Hash;pck_sha256=(Get-FileHash (Join-Path $BuildDirectory 'DiveInUnder.pck')).Hash;normal_desktop_fallback=$false;save_before_sha256=$oldHash;save_after_sha256=$afterHash;normal_user_data_accessed=$false} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $RunDirectory "isolation$suffix.json") -Encoding utf8
    if (!$result.NonInteractive -or !$result.DesktopMatched -or $result.TimedOut -or $result.ExitCode -ne 0 -or $afterHash -ne $oldHash) {throw 'Isolated session check failed'}
    if (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet) {throw 'Engine errors in session check'}
    $name=if($restart){'integration-restart.json'}else{'bgm-review.json'}
    $report=Get-Content -LiteralPath (Join-Path $RunDirectory $name) -Raw | ConvertFrom-Json
    if(!$report.complete -or !$report.rendered -or !$report.no_save_store -or $report.run_id -ne $runId) {throw 'Missing fresh session report'}
}
if (!$report.continuity -or !$report.fade_out -or !$report.native_loop -or !$report.loop_wrap -or !$report.pcm_audible -or !$report.rapid_return -or !$report.quiet_bus -or !$report.title_silent) {throw 'BGM focused checks required'}
Write-Output 'Isolated native OGG BGM, persistent screens, fade, loop wrap and PCM output passed; one process.'
