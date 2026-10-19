param([string]$BuildDirectory='', [string]$BaselineDirectory='', [switch]$AfterOnly)
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
if (!$BuildDirectory) {. (Join-Path $PSScriptRoot 'build_path.ps1'); $BuildDirectory=Resolve-DiveBuild -Project $project}
$runRoot=Join-Path $project 'artifacts/refinement'
New-Item -ItemType Directory -Force $runRoot | Out-Null
if (!$AfterOnly -and !$BaselineDirectory) {
    if (!$env:GITHUB_TOKEN) {throw 'Cloud read token required to obtain exact old distribution'}
    $headers=@{Authorization="Bearer $env:GITHUB_TOKEN";Accept='application/vnd.github+json'}
    $outer=Join-Path $runRoot 'baseline-artifact.zip'
    Invoke-WebRequest -Uri 'https://api.github.com/repos/shirai-masatomo/whitespace/actions/artifacts/12180570239/zip' -Headers $headers -OutFile $outer
    if ((Get-FileHash $outer).Hash -ne 'ABE07E741F5E0162CF93007F740C108196F68FC95A566A20687925B8F5ADB58C') {throw 'Old artifact digest mismatch'}
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($outer,(Join-Path $runRoot 'baseline-download'))
    $BaselineDirectory=Join-Path $runRoot 'baseline-build'
    [IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $runRoot 'baseline-download/DiveInUnder-foundation-windows-x64.zip'),$BaselineDirectory)
}
Add-Type -Path (Join-Path $PSScriptRoot 'isolated_desktop.cs')
$modes=if($AfterOnly){@('after')}else{@('before','after')}
foreach($mode in $modes) {
    $dir=Join-Path $runRoot $mode
    New-Item -ItemType Directory -Force $dir | Out-Null
    $environment=[Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
    [Environment]::GetEnvironmentVariables().GetEnumerator() | ForEach-Object {$environment[$_.Key]=[string]$_.Value}
    $environment['APPDATA']=Join-Path $dir 'user-data'; $environment['LOCALAPPDATA']=Join-Path $dir 'local-data'
    $saveFolder=Join-Path $environment['APPDATA'] 'Godot/app_userdata/Dive In Under — 戦闘基盤'
    New-Item -ItemType Directory -Force $saveFolder | Out-Null
    $sentinel=Join-Path $saveFolder 'campaign-v1.json'; [IO.File]::WriteAllText($sentinel,'{"sentinel":"ignore and preserve old save"}')
    $oldHash=(Get-FileHash $sentinel).Hash
    $probe=[DiveIsolatedDesktop]::Run('','','',$environment,5)
    if (!$probe.NonInteractive) {throw 'No normal desktop fallback'}
    $runId=[guid]::NewGuid().ToString('N'); $log=Join-Path $dir 'render.log'
    $arguments=@('--audio-driver','Dummy','--rendering-method','gl_compatibility','--max-fps','30','--resolution','1280x720','--log-file',$log)
    $payload=$BuildDirectory
    if($mode -eq 'before') {
        $payload=$BaselineDirectory
        $exe=Join-Path $project '.tools/Godot_v4.7.2-stable_win64.exe'
        $arguments+=@('--main-pack',(Join-Path $payload 'DiveInUnder.pck'),'--script',(Join-Path $PSScriptRoot 'refinement_before.gd'),'--',"--review-dir=$dir","--review-run-id=$runId","--review-script=$(Join-Path $project 'ui/refinement_review.gd')")
    } else {
        $exe=Join-Path $payload 'DiveInUnder.exe'
        $arguments+=@('--',"--smoke-dir=$dir","--smoke-run-id=$runId",'--refinement-review')
    }
    $command='"'+$exe+'" '+(($arguments|ForEach-Object {'"'+$_+'"'}) -join ' ')
    $watch=[Diagnostics.Stopwatch]::StartNew()
    $result=[DiveIsolatedDesktop]::Run($exe,$command,$payload,$environment,60)
    $watch.Stop(); $afterHash=(Get-FileHash $sentinel).Hash
    @{mode=$mode;elapsed_ms=$watch.ElapsedMilliseconds;run_id=$runId;result=$result;exe_sha256=(Get-FileHash $exe).Hash;pck_sha256=(Get-FileHash (Join-Path $payload 'DiveInUnder.pck')).Hash;normal_desktop_fallback=$false;normal_user_data_accessed=$false;save_before_sha256=$oldHash;save_after_sha256=$afterHash;renderer=if($mode -eq 'before'){'Pinned Godot engine with exact published 0.6.3 PCK'}else{'Actual distribution EXE/PCK'}} | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $dir 'isolation.json') -Encoding utf8
    if(!$result.NonInteractive -or !$result.DesktopMatched -or $result.TimedOut -or $result.ExitCode -ne 0 -or $oldHash -ne $afterHash) {throw "Isolated $mode failed"}
    if(Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet){throw "Engine error in $mode"}
    $proof=Get-Content (Join-Path $dir 'refinement-review.json') -Raw | ConvertFrom-Json
    if(!$proof.complete -or !$proof.rendered -or !$proof.no_save_store -or !$proof.exit_button_pressed -or $proof.run_id -ne $runId){throw "Missing fresh $mode proof"}
    if($mode -eq 'after' -and @($proof.checks.PSObject.Properties).Count -ne 10){throw 'Nine requested cases plus title required'}
}
Write-Output 'Fixed-state before/after and targeted UI/input checks passed sequentially.'
