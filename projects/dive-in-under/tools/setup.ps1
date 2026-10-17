param([string]$ArchiveDirectory = '')
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$toolDir = Join-Path $project '.tools'
New-Item -ItemType Directory -Force $toolDir | Out-Null
$lock = Get-Content (Join-Path $PSScriptRoot 'godot-version.json') -Raw | ConvertFrom-Json
Add-Type -AssemblyName System.IO.Compression.FileSystem
foreach ($kind in @('editor','templates')) {
    $filename = if ($kind -eq 'editor') { "Godot_v$($lock.version)_win64.exe.zip" } else { "Godot_v$($lock.version)_export_templates.tpz" }
    $archive = if ($ArchiveDirectory) { Join-Path $ArchiveDirectory $filename } else { Join-Path $toolDir $filename }
    if (!(Test-Path -LiteralPath $archive)) {
        if ($ArchiveDirectory) { throw "Missing archive: $archive" }
        Invoke-WebRequest "$($lock.release_url)/$filename" -OutFile $archive
    }
    $expected = if ($kind -eq 'editor') { $lock.editor_sha256 } else { $lock.templates_sha256 }
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) { throw "SHA256 mismatch: $filename" }
    $zip = [IO.Compression.ZipFile]::OpenRead($archive)
    try {
        $wanted = if ($kind -eq 'editor') {
            @("Godot_v$($lock.version)_win64.exe", "Godot_v$($lock.version)_win64_console.exe")
        } else { @('templates/windows_debug_x86_64.exe','templates/windows_release_x86_64.exe','templates/version.txt') }
        foreach ($entryName in $wanted) {
            $entry = $zip.GetEntry($entryName)
            if (!$entry) { throw "Missing archive member: $entryName" }
            $destination = Join-Path $toolDir $entryName
            New-Item -ItemType Directory -Force (Split-Path $destination -Parent) | Out-Null
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination, $true)
        }
    } finally { $zip.Dispose() }
}
$version = & (Join-Path $toolDir "Godot_v$($lock.version)_win64_console.exe") --version
if ($version.Trim() -ne $lock.runtime_version) { throw "Unexpected engine version: $version" }
if ((Get-Content (Join-Path $toolDir 'templates/version.txt') -Raw).Trim() -ne '4.7.2.stable') { throw 'Unexpected template version' }
Write-Output "Verified Godot $version and matching Windows x64 templates."
