param([string]$Python = 'python')
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$projectRoot = Split-Path $PSScriptRoot -Parent
$toolRoot = Join-Path $projectRoot '.tools'
New-Item -ItemType Directory -Force $toolRoot, "$toolRoot/templates" | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
$release = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable'

function Get-VerifiedArchive([string]$Name, [string]$Hash) {
    $target = Join-Path $toolRoot $Name
    if (-not (Test-Path -LiteralPath $target)) {
        Invoke-WebRequest "$release/$Name" -OutFile $target
    }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA512).Hash -ne $Hash) {
        throw "Checksum mismatch: $target. Remove this incomplete download and rerun setup."
    }
    return $target
}

if (-not (Test-Path "$toolRoot/Godot_v4.7.2-stable_win64.exe")) {
    $archive = Get-VerifiedArchive 'Godot_v4.7.2-stable_win64.exe.zip' '83decd58fdf67b9d657958a1ae6bf1929c20785315a81effe245874cdc57acb709bf868e00778a96984338c1b29dafdb453c6847747694621c6ecf5da2259993'
    Expand-Archive -LiteralPath $archive -DestinationPath $toolRoot -Force
}
if (-not (Test-Path "$toolRoot/templates/windows_release_x86_64.exe") -or -not (Test-Path "$toolRoot/templates/windows_debug_x86_64.exe")) {
    $archive = Get-VerifiedArchive 'Godot_v4.7.2-stable_export_templates.tpz' 'ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079'
    $zip = [IO.Compression.ZipFile]::OpenRead($archive)
    try {
        foreach ($name in @('windows_release_x86_64.exe', 'windows_debug_x86_64.exe')) {
            $entry = $zip.GetEntry("templates/$name")
            if ($null -eq $entry) { throw "Missing template: $name" }
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, "$toolRoot/templates/$name", $true)
        }
    } finally { $zip.Dispose() }
}
$version = & "$toolRoot/Godot_v4.7.2-stable_win64_console.exe" --version
if ($LASTEXITCODE -ne 0 -or $version -notmatch '^4\.7\.2\.stable') { throw 'Godot version mismatch' }
if (-not (Test-Path "$toolRoot/venv/Scripts/python.exe")) {
    & $Python -m venv "$toolRoot/venv"
    if ($LASTEXITCODE -ne 0) { throw 'Python 3.12+ is required for setup' }
}
& "$toolRoot/venv/Scripts/python.exe" -m pip install -r "$projectRoot/requirements-dev.txt"
if ($LASTEXITCODE -ne 0) { throw 'Development tools installation failed' }
Write-Output 'DIVE DIVE tools ready. Run ./dev.ps1 check, then ./dev.ps1 play.'
