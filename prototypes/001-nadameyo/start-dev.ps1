param([int]$Port = 5174)
$ErrorActionPreference = 'Stop'
# Resolve the actual worktree rather than a saved path to another checkout.
Set-Location $PSScriptRoot
$installedNode = 'C:\Program Files\nodejs\node.exe'
$nodePath = if (Test-Path -LiteralPath $installedNode) { $installedNode } else { (Get-Command node -ErrorAction Stop).Source }
$vitePath = Join-Path $PSScriptRoot 'node_modules\vite\bin\vite.js'
if (-not (Test-Path -LiteralPath $vitePath)) {
  throw 'このアプリのフォルダで npm.cmd ci を実行してください。'
}
Write-Host "WhiteSpace: $PSScriptRoot / http://127.0.0.1:$Port/ (Ctrl+Cで停止)"
& $nodePath $vitePath --host 127.0.0.1 --port $Port --strictPort
exit $LASTEXITCODE
