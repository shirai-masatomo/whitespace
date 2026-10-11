$ErrorActionPreference='Stop'
$project=Split-Path -Parent $PSScriptRoot
$manifestPath=Join-Path $project 'review/quality-roadmap/directive-09/cleanup-manifest.json'
$manifest=Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
Add-Type -AssemblyName Microsoft.VisualBasic
foreach($item in $manifest.actions | Where-Object status -ne 'recycled'){
 $resolved=(Resolve-Path -LiteralPath $item.path).Path
 $entry='C:\Users\masat\Documents\codex_test\projects\sporehollow\確認入口\'
 $allowedEntry=$resolved.StartsWith($entry,[StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetExtension($resolved) -eq '.lnk' -and [IO.Path]::GetFileName($resolved) -ne '最新開発版.lnk'
 $allowedArtifact=$resolved -match '^C:\\Users\\masat\\Documents\\Codex\\2026-10-(08|09|10)\\task\\[^\\]+\\projects\\sporehollow\\artifacts\\(research|playtest|onsite-clarity)\\[^\\]+\\(Play-[^\\]+\.cmd|[^\\]+\.exe)$'
 $allowedLocal=$resolved -eq (Join-Path $project 'artifacts/autonomy-entry-01/bundle/自律作業と食事_部分試作.lnk')
 if(-not($allowedEntry -or $allowedArtifact -or $allowedLocal)){throw "Out of scope: $resolved"}
 if((Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash -ne $item.sha256){throw "Changed file: $resolved"}
 try{
  [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($resolved,[Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,[Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin,[Microsoft.VisualBasic.FileIO.UICancelOption]::ThrowException)
  if(Test-Path -LiteralPath $resolved){throw 'File still present'}
  $item.status='recycled'
 }catch{
  $item.status='failed'
  $item | Add-Member -NotePropertyName error -NotePropertyValue $_.Exception.Message -Force
  Write-Warning "Recycle failed: $resolved"
 }finally{$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8}
}
$manifest.actions | Group-Object status | Select-Object Name,Count
