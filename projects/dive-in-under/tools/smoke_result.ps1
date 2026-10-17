function Assert-SmokeResult {
    param([string]$Path,[string]$RunId,[bool]$Rendered,[switch]$ResumeProbe)
    if (!(Test-Path -LiteralPath $Path)) { throw 'No smoke result' }
    $result = Get-Content -LiteralPath $Path -Raw -Encoding utf8 | ConvertFrom-Json
    if (!$RunId -or $result.run_id -ne $RunId) { throw 'Smoke run ID mismatch: stale result rejected' }
    if ($ResumeProbe) {
        if (!$result.restart_loaded) { throw 'Restart load failed' }
    } elseif (!$result.ui_core_equal -or !$result.loop_input -or !$result.normal_death_retry -or !$result.tool_start_pause_resume_restart_back -or $result.rendered -ne $Rendered) {
        throw 'Unexpected smoke result'
    }
    return $result
}
