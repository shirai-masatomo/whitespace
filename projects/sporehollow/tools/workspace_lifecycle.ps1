$ErrorActionPreference='Stop'
function Assert-FarmGeneratedPath([string]$Project,[string]$Path) {
    $root=[IO.Path]::GetFullPath($Project).TrimEnd('\','/')
    if(-not(Test-Path -LiteralPath (Join-Path $root 'project.godot')) -or -not(Test-Path -LiteralPath (Join-Path $root 'game/world.gd'))){throw 'Not a Whistle Ranch project'}
    $target=[IO.Path]::GetFullPath($Path).TrimEnd('\','/')
    $allowed=@('artifacts/validation/current','artifacts/isolated/current','artifacts/launcher-test/current') | ForEach-Object {[IO.Path]::GetFullPath((Join-Path $root $_)).TrimEnd('\','/')}
    if($target -notin $allowed){throw "Not an owned scratch directory: $target"}
    if(-not $target.StartsWith($root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Path escapes project'}
    $cursor=$target
    while($cursor.Length -ge $root.Length){
        if(Test-Path -LiteralPath $cursor){if((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Reparse path refused'}}
        if($cursor -eq $root){break};$cursor=Split-Path -Parent $cursor
    }
    if(Test-Path -LiteralPath $target){
        if(Get-ChildItem -LiteralPath $target -Recurse -Force | Where-Object {$_.Attributes -band [IO.FileAttributes]::ReparsePoint}){throw 'Reparse content refused'}
    }
    return $target
}
function Remove-FarmScratch([string]$Project,[string]$Path) {
    $target=Assert-FarmGeneratedPath $Project $Path
    if(-not(Test-Path -LiteralPath $target)){return}
    $marker=Join-Path $target '.generated-work.json'
    if(-not(Test-Path -LiteralPath $marker)){throw "Unknown scratch contents retained: $target"}
    $owner=Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
    if([IO.Path]::GetFullPath($owner.project) -ne [IO.Path]::GetFullPath($Project)){throw 'Scratch owner mismatch'}
    if($owner.pid -ne $PID -and (Get-Process -Id $owner.pid -ErrorAction SilentlyContinue)){throw 'Scratch process still running'}
    Remove-Item -LiteralPath $target -Recurse -Force
}
function Start-FarmScratch([string]$Project,[string]$Path) {
    $target=Assert-FarmGeneratedPath $Project $Path
    New-Item -ItemType Directory -Force -Path (Join-Path $Project 'artifacts') | Out-Null
    $lease=[IO.File]::Open((Join-Path $Project 'artifacts/.workflow.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    try {
        Remove-FarmScratch $Project $target
        New-Item -ItemType Directory -Force -Path $target | Out-Null
        @{project=[IO.Path]::GetFullPath($Project);pid=$PID;created_utc=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $target '.generated-work.json') -Encoding utf8
        $script:farmLease=$lease
    } catch {$lease.Dispose();throw}
    return $target
}
function Save-FarmVerification([string]$Project,[string]$Path,[string]$Purpose,[bool]$Succeeded,[switch]$Visual) {
    $target=Assert-FarmGeneratedPath $Project $Path
    if(-not(Test-Path -LiteralPath $target)){return}
    $evidence=Join-Path $Project 'review/current/verification'
    New-Item -ItemType Directory -Force -Path $evidence | Out-Null
    Set-Content -LiteralPath (Join-Path $evidence '.gdignore') -Value ''
    $records=@()
    foreach($file in Get-ChildItem -LiteralPath $target -Recurse -File){
        $relative=[IO.Path]::GetRelativePath($target,$file.FullName)
        if($relative -match '(^|[\\/])user-data([\\/]|$)' -or $file.Name -eq '.generated-work.json'){continue}
        if($file.Extension -in @('.log','.json','.jsonl','.txt')){
            $content=[IO.File]::ReadAllText($file.FullName)
            if($file.Name -eq 'import.log' -and $Succeeded){$content=($content -split '\r?\n' | Where-Object {$_ -match '^Godot Engine|^WARNING:|^ERROR:|^SCRIPT ERROR:|^\[ DONE \]'} | Select-Object -Last 12) -join "`n"}
            $records+=@{path=$relative;text=$content}
        }
    }
    $record=@{format='farm-generated-verification-v1';purpose=$Purpose;succeeded=$Succeeded;utc=[DateTime]::UtcNow.ToString('o');records=$records}
    $name=if($Visual -and -not $Succeeded){'last-visual-error.json'}elseif($Visual){'last-visual.json'}else{'last-run.json'}
    $record | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $evidence $name) -Encoding utf8
    if($Visual -and $Succeeded){
        $images=Join-Path $evidence 'visual'
        if(Test-Path -LiteralPath $images){
            if(Get-ChildItem -LiteralPath $images -Force | Where-Object {$_.PSIsContainer -or $_.Extension -ne '.png'}){throw 'Unexpected review image files; retained'}
            foreach($old in Get-ChildItem -LiteralPath $images -File){Remove-Item -LiteralPath $old.FullName}
        }else{New-Item -ItemType Directory -Path $images | Out-Null}
        foreach($image in Get-ChildItem -LiteralPath $target -File -Filter '*.png'){Copy-Item -LiteralPath $image.FullName -Destination $images}
    }
}
function Get-FarmBytes([string]$Project) {
    return [long]((Get-ChildItem -LiteralPath $Project -Recurse -File -Force | Measure-Object -Property Length -Sum).Sum)
}
function Clear-FarmCaches([string]$Project) {
    # Godot import data is disposable; .import/.uid files and source/assets stay untouched.
    if(-not(Get-Process -Name '*Godot*','*Whistle*' -ErrorAction SilentlyContinue)){
        $cache=[IO.Path]::GetFullPath((Join-Path $Project '.godot'))
        if(Test-Path -LiteralPath $cache){
            if((Get-Item -LiteralPath $cache -Force).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Cache reparse path refused'}
            if(Get-ChildItem -LiteralPath $cache -Recurse -Force | Where-Object {$_.Attributes -band [IO.FileAttributes]::ReparsePoint}){throw 'Cache reparse contents refused'}
            Remove-Item -LiteralPath $cache -Recurse -Force
        }
    }
    foreach($name in @('Godot_v4.7.2-stable_win64.exe.zip','Godot_v4.7.2-stable_export_templates.tpz')){
        $archive=Join-Path $Project ('.tools/'+$name)
        if((Test-Path -LiteralPath $archive) -and (Test-Path -LiteralPath (Join-Path $Project '.tools/Godot_v4.7.2-stable_win64.exe')) -and (Test-Path -LiteralPath (Join-Path $Project '.tools/templates/windows_release_x86_64.exe'))){Remove-Item -LiteralPath $archive}
    }
}
function Complete-FarmScratch([string]$Project,[string]$Path,[string]$Purpose,[bool]$Succeeded,[switch]$Visual) {
    try {
        Save-FarmVerification $Project $Path $Purpose $Succeeded -Visual:$Visual
        Remove-FarmScratch $Project $Path
        Clear-FarmCaches $Project
        $bytes=Get-FarmBytes $Project
        Write-Output ("Cleanup complete; project {0:N1} MiB. Evidence: review/current/verification" -f ($bytes/1MB))
    } finally {if($script:farmLease){$script:farmLease.Dispose();$script:farmLease=$null}}
}


function Initialize-FarmImports([string]$Project,[string]$RunRoot) {
    $exe=Join-Path $Project '.tools/Godot_v4.7.2-stable_win64_console.exe'
    $info=[Diagnostics.ProcessStartInfo]::new();$info.FileName=$exe;$info.WorkingDirectory=$Project
    $info.UseShellExecute=$false;$info.CreateNoWindow=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
    foreach($arg in @('--headless','--path',$Project,'--audio-driver','Dummy','--editor','--import','--quit','--log-file',(Join-Path $RunRoot 'import.log'))){$info.ArgumentList.Add($arg)}
    $info.Environment['APPDATA']=Join-Path $RunRoot 'user-data';$info.Environment['LOCALAPPDATA']=$info.Environment['APPDATA']
    $owned=[Diagnostics.Process]::new();$owned.StartInfo=$info
    try {
        if(-not $owned.Start()){throw 'Import startup failed'}
        $owned.PriorityClass='BelowNormal'
        $stdout=$owned.StandardOutput.ReadToEndAsync();$stderr=$owned.StandardError.ReadToEndAsync()
        if(-not $owned.WaitForExit(60000)){$owned.Kill();$owned.WaitForExit();throw 'Import timed out'}
        $result=$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult()
        if($owned.ExitCode -ne 0 -or $result -match 'SCRIPT ERROR:|ERROR:'){throw 'Import failed; see import.log'}
        Write-Output 'Headless import ready'
    } finally {$owned.Dispose()}
}
