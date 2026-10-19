function Resolve-DiveBuild([string]$Project) {
    $root = [IO.Path]::GetFullPath((Join-Path $Project 'build'))
    $pointer = Join-Path $root 'candidate.txt'
    $relative = if (Test-Path $pointer) { (Get-Content $pointer -Raw).Trim() } else { 'windows' }
    $path = [IO.Path]::GetFullPath((Join-Path $root $relative))
    if (!$path.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Build pointer outside project build directory' }
    foreach ($name in @('DiveInUnder.exe','DiveInUnder.pck','BUILD.json')) {
        if (!(Test-Path -LiteralPath (Join-Path $path $name))) { throw "Incomplete build: $name" }
    }
    return $path
}
