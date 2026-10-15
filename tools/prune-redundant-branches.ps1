# Requires GitHub CLI authenticated to shirai-masatomo/whitespace. Read-only preview by default.
# Run: pwsh ./tools/prune-redundant-branches.ps1
# Execute: pwsh ./tools/prune-redundant-branches.ps1 -Apply
param([switch]$Apply)
$ErrorActionPreference = 'Stop'
$repo = 'shirai-masatomo/whitespace'
$candidates = @(
    @{ Branch = 'codex/coffee-blind-play'; Keep = 'codex/coffee-conversation-boundaries'; Expected = 'aaff8cea1cc' }
    @{ Branch = 'codex/coffee-circumstances'; Keep = 'codex/coffee-conversation-boundaries'; Expected = '11d175eecc1' }
    @{ Branch = 'codex/coffee-clear-presentation'; Keep = 'codex/coffee-conversation-boundaries'; Expected = 'fa5bf551c31' }
    @{ Branch = 'codex/coffee-context-experiment'; Keep = 'codex/coffee-conversation-boundaries'; Expected = '890cb86b168' }
    @{ Branch = 'codex/coffee-natural-dialogue'; Keep = 'codex/coffee-conversation-boundaries'; Expected = 'fc2ebf38ae1' }
    @{ Branch = 'codex/coffee-player-flow'; Keep = 'codex/coffee-conversation-boundaries'; Expected = '92b18bb1abd' }
    @{ Branch = 'codex/coffee-scene-flow'; Keep = 'codex/coffee-conversation-boundaries'; Expected = 'eb4ed166e0e' }
    @{ Branch = 'codex/coffee-scene-presence'; Keep = 'codex/coffee-conversation-boundaries'; Expected = 'ccb005d88d0' }
    @{ Branch = 'codex/dive-dive-autonomous-evaluation'; Keep = 'codex/dive-dive-playground'; Expected = 'eae03be7574' }
    @{ Branch = 'codex/dive-dive-oxygen-platforms'; Keep = 'codex/dive-dive-playground'; Expected = '40f22066909' }
    @{ Branch = 'codex/dive-dive-oxygen-routes'; Keep = 'codex/dive-dive-playground'; Expected = '231d6c16eac' }
    @{ Branch = 'codex/dive-dive-prototype'; Keep = 'codex/dive-dive-playground'; Expected = '4a092cde822' }
    @{ Branch = 'codex/dive-dive-real-layer'; Keep = 'codex/dive-dive-playground'; Expected = '7d7ac19225f' }
    @{ Branch = 'codex/dive-dive-rescue-visibility'; Keep = 'codex/dive-dive-playground'; Expected = '67c4362c7a8' }
    @{ Branch = 'codex/dive-dive-surface-descent'; Keep = 'codex/dive-dive-playground'; Expected = 'ea6706d22c3' }
    @{ Branch = 'codex/sporehollow-balance-audit'; Keep = 'codex/sporehollow-biome01'; Expected = '13c113fa542' }
    @{ Branch = 'codex/sporehollow-prototype'; Keep = 'codex/sporehollow-biome01'; Expected = '6017608fc23' }
    @{ Branch = 'codex/sporehollow-review02'; Keep = 'codex/sporehollow-biome01'; Expected = 'b5e9fe5a6b2' }
)
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI (gh) is not installed.' }
gh auth status 1>$null
if ($LASTEXITCODE -ne 0) { throw 'Please authenticate GitHub CLI with gh auth login.' }

$prs = @(gh api "repos/$repo/pulls?state=open&per_page=100" | ConvertFrom-Json)
$blocked = 0
$deleted = 0
foreach ($c in $candidates) {
    if ($c.Branch -eq 'main' -or $c.Branch -eq $c.Keep) { throw "Invalid candidate $($c.Branch)" }
    $branchRef = "repos/$repo/branches/$($c.Branch)"
    $current = gh api $branchRef 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or -not $current) { Write-Host "SKIP absent: $($c.Branch)"; continue }
    if ($current.protected -or -not $current.commit.sha.StartsWith($c.Expected)) {
        Write-Host "KEEP protected/changed: $($c.Branch)"
        $blocked++; continue
    }
    if (@($prs | Where-Object { $_.head.ref -eq $c.Branch }).Count -gt 0) {
        Write-Host "KEEP open pull request: $($c.Branch)"
        $blocked++; continue
    }
    $comparePath = "repos/$repo/compare/$($c.Branch)...$($c.Keep)"
    $cmp = gh api $comparePath | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or $cmp.behind_by -ne 0 -or @('ahead','identical') -notcontains $cmp.status) {
        Write-Host "KEEP unmerged divergence: $($c.Branch)"
        $blocked++; continue
    }
    if (-not $Apply) {
        Write-Host "READY to delete: $($c.Branch)  -> $($c.Keep)"
        continue
    }
    # Revalidate the ref immediately before deletion; no force branch move.
    $latest = gh api $branchRef | ConvertFrom-Json
    if ($latest.commit.sha -ne $current.commit.sha) {
        Write-Host "KEEP updated during audit: $($c.Branch)"
        $blocked++; continue
    }
    gh api -X DELETE "repos/$repo/git/refs/heads/$($c.Branch)" 1>$null
    if ($LASTEXITCODE -ne 0) { throw "Deletion failed at $($c.Branch)" }
    Write-Host "DELETED: $($c.Branch)"
    $deleted++
}
Write-Host "Finished. Deleted: $deleted; skipped: $blocked."
if (-not $Apply) { Write-Host "DRY RUN only. Run with -Apply to delete verified branches." }
