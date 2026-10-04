$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$farmRoot = Split-Path $PSScriptRoot -Parent
$toolRoot = Join-Path $farmRoot '.tools'
$release = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable'
New-Item -ItemType Directory -Force "$toolRoot/templates" | Out-Null
Set-Content -LiteralPath "$toolRoot/.gdignore" -Value ''
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-VerifiedArchive([string]$Name, [string]$Hash) {
    $file = Join-Path $toolRoot $Name
    if (-not (Test-Path -LiteralPath $file)) { Invoke-WebRequest "$release/$Name" -OutFile $file }
    if ((Get-FileHash -LiteralPath $file -Algorithm SHA512).Hash -ne $Hash) { throw "Checksum mismatch: $Name" }
    return $file
}

if (-not (Test-Path "$toolRoot/Godot_v4.7.2-stable_win64_console.exe")) {
    $zip = Get-VerifiedArchive 'Godot_v4.7.2-stable_win64.exe.zip' '83decd58fdf67b9d657958a1ae6bf1929c20785315a81effe245874cdc57acb709bf868e00778a96984338c1b29dafdb453c6847747694621c6ecf5da2259993'
    Expand-Archive -LiteralPath $zip -DestinationPath $toolRoot -Force
}
if (-not (Test-Path "$toolRoot/templates/windows_release_x86_64.exe") -or -not (Test-Path "$toolRoot/templates/windows_debug_x86_64.exe")) {
    $zipFile = Get-VerifiedArchive 'Godot_v4.7.2-stable_export_templates.tpz' 'ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079'
    $archive = [IO.Compression.ZipFile]::OpenRead($zipFile)
    try {
        foreach ($name in @('windows_release_x86_64.exe', 'windows_debug_x86_64.exe')) {
            $entry = $archive.GetEntry("templates/$name")
            if ($null -eq $entry) { throw "Missing template $name" }
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, "$toolRoot/templates/$name", $true)
        }
    } finally { $archive.Dispose() }
}
$version = & "$toolRoot/Godot_v4.7.2-stable_win64_console.exe" --headless --version
if ($LASTEXITCODE -ne 0 -or $version -notmatch '^4\.7\.2\.stable') { throw 'Godot version mismatch' }
Write-Output 'Whistle Ranch tools ready. Run ./dev.ps1 check.'
