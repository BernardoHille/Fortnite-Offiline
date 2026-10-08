#Requires -Version 7.4
[CmdletBinding()]
param([string]$ConfigPath)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'phase2-common.ps1')
$settings=if($ConfigPath){Get-Phase2Config -ConfigPath $ConfigPath}else{Get-Phase2Config}
$session=$null
$results=[ordered]@{timestamp=[DateTime]::UtcNow.ToString('o');health=$false;localProfile=$false;timelineConfig=$false;lobbyBootstrapSimulation=$false;noExternalBackendConnections=$false;negativeCases=$false;gracefulStop=$false;clientExecuted=$false}
function Assert-Phase2 {param([bool]$Condition,[string]$Message);if(-not $Condition){throw $Message}}
try{
    $session=Start-Phase2Backend -Settings $settings
    $base=$session.BaseUrl
    $health=Invoke-RestMethod -Uri ($base+'/health')
    Assert-Phase2 ($health.phase -eq 2 -and -not $health.clientStarted -and -not $health.realCredentialsUsed) 'Health state mismatch'
    $results.health=$true;Write-Output '[OK] health'
    # Synthetic pair only: not an Epic credential. Never printed or stored in logs.
    $token=Invoke-RestMethod -Uri ($base+'/account/api/oauth/token') -Method Post -ContentType 'application/x-www-form-urlencoded' -Body 'grant_type=password&username=local-player&password=local-only-not-epic'
    Assert-Phase2 ($token.account_id -eq 'local-player' -and $token.access_token -match '^local-[a-f0-9]{64}$') 'Invalid local session'
    $headers=@{Authorization=('Bearer '+$token.access_token);'User-Agent'='Fortnite/++Fortnite+Release-13.40-CL-14113327 Windows/10'}
    $verify=Invoke-RestMethod -Uri ($base+'/account/api/oauth/verify') -Headers $headers
    $account=Invoke-RestMethod -Uri ($base+'/account/api/public/account/local-player') -Headers $headers
    Assert-Phase2 ($verify.account_id -eq 'local-player' -and $account.displayName -eq $settings.Config.displayName) 'Local identity mismatch'
    foreach($id in @('athena','common_core','common_public')){
        $profile=Invoke-RestMethod -Uri ($base+"/fortnite/api/game/v2/profile/local-player/client/QueryProfile?profileId=$id&rvn=-1") -Method Post -Headers $headers -ContentType 'application/json' -Body '{}'
        Assert-Phase2 ($profile.profileId -eq $id -and $profile.profileChanges[0].profile.accountId -eq 'local-player') 'Profile envelope mismatch'
        if($id -eq 'athena'){
            Assert-Phase2 ($profile.profileChanges[0].profile.stats.attributes.season_num -eq 13 -and -not $profile.profileChanges[0].profile.stats.attributes.book_purchased) 'Season/local profile mismatch'
        }
        $sameRevision=Invoke-RestMethod -Uri ($base+"/fortnite/api/game/v2/profile/local-player/client/QueryProfile?profileId=$id&rvn=1") -Method Post -Headers $headers -ContentType 'application/json' -Body '{}'
        Assert-Phase2 (@($sameRevision.profileChanges).Count -eq 0) 'Stable profile revision mismatch'
    }
    $results.localProfile=$true;Write-Output '[OK] local profile'
    $timeline=Invoke-RestMethod -Uri ($base+'/fortnite/api/calendar/v1/timeline') -Headers $headers
    $localConfig=Invoke-RestMethod -Uri ($base+'/local/phase2/config') -Headers $headers
    $cloud=Invoke-RestMethod -Uri ($base+'/fortnite/api/cloudstorage/system') -Headers $headers
    $version=Invoke-RestMethod -Uri ($base+'/fortnite/api/version')
    $update=Invoke-RestMethod -Uri ($base+'/fortnite/api/v2/versioncheck')
    $status=Invoke-RestMethod -Uri ($base+'/lightswitch/api/service/bulk/status')
    Assert-Phase2 ($timeline.channels.'client-events'.states[0].state.seasonNumber -eq 13 -and $localConfig.changelist -eq 14113327 -and -not $localConfig.externalServices -and @($cloud).Count -eq 0 -and $version.version -eq '13.40' -and $update.type -eq 'NO_UPDATE' -and $status[0].status -eq 'UP') 'Timeline/config mismatch'
    $results.timelineConfig=$true;Write-Output '[OK] timeline/config'
    $bootstrap=Invoke-RestMethod -Uri ($base+'/local/phase2/lobby-bootstrap') -Headers $headers
    $presence=Invoke-RestMethod -Uri ($base+'/local/phase2/presence') -Headers $headers
    Assert-Phase2 ($bootstrap.account.displayName -eq $settings.Config.displayName -and $bootstrap.localSimulationReady -and -not $bootstrap.realClientLobbyVerified -and -not $bootstrap.playButtonVerified -and -not $bootstrap.matchmakingEnabled -and $presence.status -eq 'local-only') 'Simulation bootstrap mismatch'
    Assert-Phase2 (($bootstrap | ConvertTo-Json -Depth 30) -notmatch 'https?://[^"\s]+') 'Bootstrap contains an external URL'
    $results.lobbyBootstrapSimulation=$true;Write-Output '[OK] lobby bootstrap (simulation only; real client unverified)'
    $cases=@(
        @{Method='GET';Route='/account/api/public/account/local-player';Headers=@{};Expected=401},
        @{Method='GET';Route='/account/api/public/account/other-player';Headers=$headers;Expected=404},
        @{Method='GET';Route='/account/api/oauth/verify';Headers=@{Authorization='Bearer invalid-local-test'};Expected=401},
        @{Method='POST';Route='/__local/shutdown';Headers=@{};Expected=403},
        @{Method='GET';Route='/fortnite/api/game/v2/matchmakingservice/ticket/player/local-player';Headers=$headers;Expected=503},
        @{Method='GET';Route='/unimplemented';Headers=$headers;Expected=503},
        @{Method='POST';Route='/fortnite/api/game/v2/profile/local-player/client/SetCosmeticLockerSlot';Headers=$headers;Expected=503}
    )
    foreach($case in $cases){$response=Invoke-WebRequest -Uri ($base+$case.Route) -Method $case.Method -Headers $case.Headers -SkipHttpErrorCheck;Assert-Phase2 ($response.StatusCode -eq $case.Expected) ('Unexpected negative status: '+$case.Route)}
    $badGrant=Invoke-WebRequest -Uri ($base+'/account/api/oauth/token') -Method Post -ContentType 'application/x-www-form-urlencoded' -Body 'grant_type=exchange_code&exchange_code=synthetic-test-only' -SkipHttpErrorCheck
    Assert-Phase2 ($badGrant.StatusCode -eq 400) 'Nonlocal credential flow must fail'
    $invalidProfile=Invoke-WebRequest -Uri ($base+'/fortnite/api/game/v2/profile/local-player/client/QueryProfile?profileId=campaign&rvn=-1') -Method Post -Headers $headers -ContentType 'application/json' -Body '{}' -SkipHttpErrorCheck
    Assert-Phase2 ($invalidProfile.StatusCode -eq 404) 'Unsupported profile must fail'
    $malformed=Invoke-WebRequest -Uri ($base+'/fortnite/api/game/v2/profile/local-player/client/QueryProfile?profileId=athena') -Method Post -Headers $headers -ContentType 'application/json' -Body '{' -SkipHttpErrorCheck
    Assert-Phase2 ($malformed.StatusCode -eq 400) 'Malformed JSON must fail in a controlled way'
    $probe=Invoke-WebRequest -Uri ($base+'/synthetic-redaction-probe?password=synthetic-redaction-probe') -Headers @{Authorization='Bearer synthetic-redaction-probe';'Content-Type'='synthetic-redaction-probe'} -SkipHttpErrorCheck
    Assert-Phase2 ($probe.StatusCode -eq 503) 'Unknown route must fail'
    $logText=Get-Content -LiteralPath (Join-Path $Phase2Root 'logs/phase2-backend.log') -Raw
    Assert-Phase2 ($logText -notmatch 'synthetic-redaction-probe|Bearer |local-[a-f0-9]{64}|local-only-not-epic') 'Sensitive values leaked into backend log'
    $results.negativeCases=$true
    $network=Invoke-RestMethod -Uri ($base+'/local/phase2/network-report') -Headers $headers
    Assert-Phase2 ($network.guard.attempted -eq 0 -and $network.guard.externalAllowed -eq 0 -and -not $network.clientCoverage) 'Backend attempted network access or overstated guard scope'
    $results.noExternalBackendConnections=$true;Write-Output '[OK] no external connections (audited backend process only)'
}finally{
    try{if($session){Stop-Phase2Backend -Session $session;$results.gracefulStop=$true}}
    finally{
        $token=$null;$headers=$null
        $results | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Phase2Root 'logs/phase2-smoke.json') -Encoding utf8
    }
}
