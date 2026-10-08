#Requires -Version 7.4
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Apply)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'phase2-runtime-observation-common.ps1')
$targets = Get-RuntimeObservationTargets
$sessionId = [Guid]::NewGuid().ToString('N')
$planned = @(Get-RuntimeObservationRulePlan -Targets $targets -SessionId $sessionId)

# Always show exactly which files would be affected before any OS mutation.
$targets.Programs | ForEach-Object { Write-Host "PROPOSED PROGRAM: $_" }
Write-Host '16 exact-path block rules: Inbound + Outbound, Profile/Protocol/Addresses/Ports Any. No launch or capture.'
if (-not $Apply) {
    Write-Host 'PLAN ONLY. No firewall rules or session state created. -Apply is reserved for future explicit authorization.'
    return
}
Assert-RuntimeObservationAdministrator
Assert-RuntimeObservationStopped -Targets $targets
Assert-RuntimeObservationPhysicallyOffline
foreach ($service in @('BFE', 'MpsSvc')) {
    if ((Get-Service -Name $service -ErrorAction Stop).Status -ne 'Running') { throw "$service is not running; no change made." }
}
$profiles = @(Get-NetFirewallProfile -PolicyStore ActiveStore -ErrorAction Stop)
if ($profiles.Count -ne 3 -or @($profiles | Where-Object { $_.Enabled.ToString() -ne 'True' -or $_.AllowLocalFirewallRules.ToString() -eq 'False' }).Count) {
    throw 'Firewall disabled or local rules prohibited; existing policy will not be changed.'
}
$bypass = @(Get-NetFirewallRule -PolicyStore ActiveStore -ErrorAction Stop | Get-NetFirewallSecurityFilter -ErrorAction Stop | Where-Object OverrideBlockRules)
if ($bypass.Count) { throw 'Existing authenticated bypass rules require review. No existing rule will be modified.' }
if (Test-Path -LiteralPath $RuntimeObservationState) { throw 'Existing session state: review/cleanup it first. No overwrite.' }
if (-not $PSCmdlet.ShouldProcess('The eight listed build executables', 'Create the 16 temporary project block rules')) { return }

New-Item -ItemType Directory -Path $RuntimeObservationDirectory -Force | Out-Null
$snapshot = Get-RuntimeObservationFirewallSnapshot
$snapshot.Json | Set-Content -LiteralPath (Join-Path $RuntimeObservationDirectory "firewall-before-$sessionId.local.json") -Encoding utf8
$state = [pscustomobject][ordered]@{
    Schema = 1; SessionId = $sessionId; BuildPath = $targets.BuildPath; Programs = $targets.Programs
    StartedUtc = [DateTime]::UtcNow.ToString('o'); Status = 'Preparing'; LaunchReady = $false
    BeforeFirewallSha256 = $snapshot.Sha256; Rules = $planned; CleanupUtc = $null; CleanupMatchesBaseline = $null
}
# Persist ownership before the first rule so interrupted preparation remains removable.
$handle = [IO.File]::Open($RuntimeObservationState, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
try {
    $bytes = [Text.Encoding]::UTF8.GetBytes(($state | ConvertTo-Json -Depth 15))
    $handle.Write($bytes, 0, $bytes.Length)
} finally { $handle.Dispose() }
try {
    foreach ($item in $planned) {
        New-NetFirewallRule -PolicyStore PersistentStore -Name $item.Name -DisplayName $item.DisplayName -Group $item.Group `
            -Description $item.Description -Program $item.Program -Direction $item.Direction -Action Block -Enabled True `
            -Profile Any -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any -ErrorAction Stop | Out-Null
    }
    foreach ($item in $planned) {
        $rule = Get-NetFirewallRule -PolicyStore ActiveStore -Name $item.Name -ErrorAction Stop
        Assert-RuntimeObservationOwnedRule -Rule $rule -Expected $item -Effective
    }
    Assert-RuntimeObservationPhysicallyOffline
    $state.Status = 'RulesVerifiedCaptureNotReady'
    Save-RuntimeObservationState -State $state
    Write-Host 'Project rules verified in ActiveStore. CLIENT REMAINS CLOSED: filtered capture and independent offline verification still required.'
    Write-Host 'Keep networking disconnected until the client and all build helpers have exited and cleanup has completed.'
} catch {
    $preparationError = $_
    $state.Status = 'PreparationFailedKeepClientClosed'
    try { Save-RuntimeObservationState -State $state } catch { Write-Warning 'State update failed; original ownership record is retained.' }
    # Cleanup validates ownership, refuses running game processes and removes no other rule.
    try { & (Join-Path $PSScriptRoot 'cleanup-phase2-runtime-observation.ps1') -Apply -Confirm:$false }
    catch { Write-Warning "Cleanup incomplete: $($_.Exception.Message). Keep networking disconnected and the client closed." }
    throw $preparationError
}
