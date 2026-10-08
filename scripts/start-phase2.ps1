#Requires -Version 7.4
[CmdletBinding()]
param([ValidateSet('Prepare','Stop','Launch')][string]$Mode='Prepare',[switch]$Approved,[string]$ConfigPath)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'phase2-common.ps1')
$statePath=Join-Path $Phase2Root 'runtime/phase2/coordinator.private.json'
if($Mode -eq 'Stop'){
    if(-not (Test-Path -LiteralPath $statePath)){throw 'No saved coordinator session exists.'}
    $state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    Stop-Phase2Backend -Session $state
    Write-Output '[OK] Components stopped; Fortnite was never started.'
    return
}
$settings=if($ConfigPath){Get-Phase2Config -ConfigPath $ConfigPath}else{Get-Phase2Config}
if($Mode -eq 'Launch'){
    if(-not $Approved){Write-Phase2LauncherLog -Result 'client-launch-denied-no-approval';throw 'Explicit user approval is required before the first client execution.'}
    Write-Phase2LauncherLog -Result 'client-launch-blocked-technical-readiness'
    throw 'No validated client routing/isolation architecture exists yet. Approval does not remove this technical block; see docs/PHASE2_PRELAUNCH.md.'
}
New-Item -ItemType Directory -Path (Split-Path $statePath -Parent) -Force | Out-Null
$session=Start-Phase2Backend -Settings $settings
$state=[ordered]@{Pid=$session.Pid;StartTimeUtc=$session.StartTimeUtc;ControlKey=$session.ControlKey;BaseUrl=$session.BaseUrl;ClientPid=$null;ClientStarted=$false}
$state | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8
[ordered]@{timestamp=[DateTime]::UtcNow.ToString('o');component='phase2-client';pid=$null;host=$null;route=$null;result='not-started-awaiting-approval-and-technical-readiness'} | ConvertTo-Json -Compress | Add-Content -LiteralPath (Join-Path $Phase2Root 'logs/phase2-client.log') -Encoding utf8
Write-Output ('[OK] Local backend prepared; PID '+$session.Pid+'. Client launch remains blocked. Stop with scripts/start-phase2.ps1 -Mode Stop.')
