#Requires -Version 7.4
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Apply)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'phase2-runtime-observation-common.ps1')
if (-not (Test-Path -LiteralPath $RuntimeObservationState -PathType Leaf)) {
    Write-Host 'No project session state exists. No firewall rule removed.'
    return
}
$state = Get-Content -LiteralPath $RuntimeObservationState -Raw | ConvertFrom-Json
$targets = Get-RuntimeObservationTargets
if ($state.Schema -ne 1 -or $state.SessionId -notmatch '^[a-f0-9]{32}$' -or $state.BuildPath -ne $targets.BuildPath -or
    @(Compare-Object ($state.Programs | Sort-Object) ($targets.Programs | Sort-Object)).Count) {
    throw 'Invalid session ownership/inventory. No firewall rule removed.'
}
$expected = @(Get-RuntimeObservationRulePlan -Targets $targets -SessionId $state.SessionId)
# Use the hard-coded allowlist and session identity, never arbitrary rule names from JSON.
Write-Host "Cleanup proposes only the 16 exact rule identities in session $($state.SessionId)."
if (-not $Apply) { Write-Host 'PLAN ONLY. No system mutation.'; return }
Assert-RuntimeObservationAdministrator
Assert-RuntimeObservationStopped -Targets $targets
$found = @()
foreach ($item in $expected) {
    $rule = Get-NetFirewallRule -PolicyStore PersistentStore -Name $item.Name -ErrorAction SilentlyContinue
    if ($rule) {
        Assert-RuntimeObservationOwnedRule -Rule $rule -Expected $item
        $found += [pscustomobject]@{ Rule = $rule; Expected = $item }
    }
}
if (-not $PSCmdlet.ShouldProcess("Owned project session $($state.SessionId)", "Remove $($found.Count) rules after confirming the client is stopped")) { return }
foreach ($item in $found) {
    # Re-read immediately before removal to avoid deleting a replaced rule.
    $current = Get-NetFirewallRule -PolicyStore PersistentStore -Name $item.Expected.Name -ErrorAction Stop
    Assert-RuntimeObservationOwnedRule -Rule $current -Expected $item.Expected
    $current | Remove-NetFirewallRule -ErrorAction Stop
}
foreach ($item in $expected) {
    if (Get-NetFirewallRule -PolicyStore PersistentStore -Name $item.Name -ErrorAction SilentlyContinue) { throw 'Project rule remains; cleanup is incomplete.' }
    if (Get-NetFirewallRule -PolicyStore ActiveStore -Name $item.Name -ErrorAction SilentlyContinue) { throw 'Project rule remains active; cleanup is incomplete.' }
}
$after = Get-RuntimeObservationFirewallSnapshot
$after.Json | Set-Content -LiteralPath (Join-Path $RuntimeObservationDirectory "firewall-after-$($state.SessionId).local.json") -Encoding utf8
$state.CleanupUtc = [DateTime]::UtcNow.ToString('o')
$state.CleanupMatchesBaseline = $after.Sha256 -eq $state.BeforeFirewallSha256
$state.Status = if ($state.CleanupMatchesBaseline) { 'CleanedBaselineMatched' } else { 'ProjectRulesRemovedPolicyDrift' }
$state.LaunchReady = $false
Save-RuntimeObservationState -State $state
if (-not $state.CleanupMatchesBaseline) {
    throw 'Project rules removed, but policy metadata differs from the baseline. Report concurrent changes; never reset or overwrite other rules.'
}
Write-Host 'All session rules absent from PersistentStore/ActiveStore; observed firewall policy fields match the baseline. Evidence retained privately.'
