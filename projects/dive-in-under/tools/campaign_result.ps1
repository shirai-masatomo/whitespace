function Assert-CampaignResult([string]$RunDir,[string]$RunId,[string]$Stage,[bool]$Rendered,[string]$Replay) {
    $path = Join-Path $RunDir $(if ($Stage -eq 'final') {'campaign-final.json'} else {'campaign-ui.json'})
    $r = Get-Content -LiteralPath $path -Raw -Encoding utf8 | ConvertFrom-Json
    if ($r.run_id -ne $RunId) { throw 'Campaign run ID mismatch; stale result rejected' }
    if ($r.rendered -ne $Rendered) { throw 'Campaign rendering mode mismatch' }
    if ($Stage -eq 'checkpoint' -and (!$r.checkpoint -or $r.complete -or $r.next_index -le 0)) { throw 'Missing campaign checkpoint' }
    if ($Stage -eq 'complete') {
        $expected = Get-Content -LiteralPath $Replay -Raw -Encoding utf8 | ConvertFrom-Json
        if (!$r.complete -or !$r.restarted -or !$r.warehouse_roundtrip -or !$r.post_clear_replay -or $r.highest_floor -ne 11 -or $r.story_deaths -ne 1) { throw 'Incomplete campaign UI proof' }
        if ($r.clear_state_sha256 -ne $expected.replay.state_sha256 -or $r.verified_actions -ne $expected.replay.actions.Count -or $r.normal_trips -ne $expected.replay.normal_trips -or $r.normal_deaths -ne $expected.replay.normal_deaths) { throw 'Campaign UI differs from shared-core replay' }
    }
    if ($Stage -eq 'final' -and (!$r.final_restart -or $r.highest_floor -ne 11 -or $r.story_deaths -ne 1)) { throw 'Final EXE restart failed' }
    $saveHash = (Get-FileHash (Join-Path $RunDir 'campaign-smoke.json') -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($r.save_sha256 -ne $saveHash) { throw 'Campaign save digest mismatch' }
    return $r
}
