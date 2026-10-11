$ErrorActionPreference='Stop'
$project=Split-Path -Parent $PSScriptRoot
$entry='C:\Users\masat\Documents\codex_test\projects\sporehollow\確認入口'
$bundle=Join-Path $project 'artifacts/autonomy-entry-01/bundle'
$launcher=Join-Path $bundle 'Launch-Autonomy.ps1'
$exe=Join-Path $bundle 'WhistleRanch-Autonomy-Partial.exe'
if(-not(Test-Path -LiteralPath $launcher) -or -not(Test-Path -LiteralPath $exe)){throw 'Verified current bundle is missing'}
$manifestPath=Join-Path $project 'review/quality-roadmap/directive-09/cleanup-manifest.json'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $manifestPath) | Out-Null
$shell=New-Object -ComObject WScript.Shell
$fixed=Join-Path $entry '最新開発版.lnk'
$manifest=@{fixed_entry=$fixed;launcher=$launcher;exe=$exe;retained=@('All repositories and Git histories','All user-data folders and normal build files','Current verified development bundle','Reference documents and image evidence');actions=@()}
$candidates=[System.Collections.Generic.List[string]]::new()
foreach($file in Get-ChildItem -LiteralPath $entry -Filter '*.lnk' -File){
 if($file.FullName -eq $fixed){continue}
 $link=$shell.CreateShortcut($file.FullName)
 if($file.Name -eq '研究_自律作業と食事_部分試作_2366024.lnk'){$candidates.Add($file.FullName);continue}
 if($file.Name -notlike '01_*'){continue}
 $target=$link.TargetPath
 if($target -notmatch '\\artifacts\\(research|playtest|onsite-clarity)\\[^\\]+\\Play-[^\\]+\.cmd$'){throw "Unexpected old entry target; review manually: $target"}
 $folder=Split-Path -Parent $target
 $sourceRoot=$target.Substring(0,$target.IndexOf('\artifacts\',[StringComparison]::OrdinalIgnoreCase))
 git -C $sourceRoot rev-parse --git-dir *> $null
 if($LASTEXITCODE -ne 0){throw "Source Git history is not retained: $sourceRoot"}
 $candidates.Add($file.FullName)
 if(Test-Path -LiteralPath $folder){
  foreach($artifact in Get-ChildItem -LiteralPath $folder -File){
   if($artifact.Extension -eq '.exe' -or $artifact.Name -like 'Play-*.cmd'){
    $resolved=(Resolve-Path -LiteralPath $artifact.FullName).Path
    if(-not $resolved.StartsWith($folder+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Out-of-scope artifact'}
    $candidates.Add($resolved)
   }
  }
 }
}
$localShortcut=Join-Path $bundle '自律作業と食事_部分試作.lnk'
if(Test-Path -LiteralPath $localShortcut){$candidates.Add($localShortcut)}
foreach($path in $candidates | Select-Object -Unique){
 $resolved=(Resolve-Path -LiteralPath $path).Path
 $manifest.actions+=@(@{path=$resolved;sha256=(Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash;action='recycle_file';status='planned'})
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
$link=$shell.CreateShortcut($fixed)
$link.TargetPath=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
$link.Arguments='-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+$launcher+'"'
$link.WorkingDirectory=$bundle;$link.IconLocation=$exe+',0';$link.Description='ホイッスル牧場 最新開発版（部分実装）。現在は自律作業・運搬・食事まで確認済み。';$link.Save()
Add-Type -AssemblyName Microsoft.VisualBasic
foreach($item in $manifest.actions){
 try{
  [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($item.path,[Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,[Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin,[Microsoft.VisualBasic.FileIO.UICancelOption]::ThrowException)
  if(Test-Path -LiteralPath $item.path){throw 'File still present'}
  $item.status='recycled'
 }catch{$item.status='failed';$item.error=$_.Exception.Message;throw}
 finally{$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8}
}
Write-Output "Fixed entry: $fixed"
Write-Output "Recycled files: $($manifest.actions.Count); code, saves and history retained."
