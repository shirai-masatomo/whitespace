$ErrorActionPreference='Stop'
$project=Split-Path -Parent $PSScriptRoot
$bundle=Join-Path $project 'artifacts/autonomy-entry-01/bundle'
$exe=Join-Path $bundle 'WhistleRanch-Autonomy-Partial.exe'
if(-not(Test-Path -LiteralPath $exe)){throw 'Latest game is missing. Build the current project; do not launch a legacy build.'}
$stamp=Get-Content -LiteralPath (Join-Path $bundle 'BUILD.json') -Raw | ConvertFrom-Json
if((Get-FileHash -LiteralPath $exe).Hash -ne $stamp.sha256){throw 'Build hash mismatch; current game was not launched'}
$env:APPDATA=Join-Path $bundle 'user-data';$env:LOCALAPPDATA=$env:APPDATA
Start-Process -FilePath $exe -WorkingDirectory $bundle -WindowStyle Normal
