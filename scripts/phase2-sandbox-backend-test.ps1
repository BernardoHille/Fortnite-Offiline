# Guest-only, Windows PowerShell 5 compatible. Does not start any game binary.
$ErrorActionPreference='Stop'
$guestSettings=Get-Content -LiteralPath 'C:\LocalProject\runtime\phase2\sandbox-test.settings.json' -Raw | ConvertFrom-Json
if($env:COMPUTERNAME -eq $guestSettings.hostComputerName -or -not (Test-Path -LiteralPath 'C:\LocalExport')){throw 'This test must only run in its isolated guest.'}
$result=[ordered]@{timestamp=[DateTime]::UtcNow.ToString('o');component='phase2-sandbox-backend-test';success=$false;clientExecuted=$false;nonLoopbackAdapters=$null;health=$false;profile=$false;bootstrap=$false;errorType=$null}
$process=$null
try{
    $active=@(Get-CimInstance Win32_NetworkAdapter | Where-Object {$_.NetEnabled -eq $true -and $_.PhysicalAdapter -eq $true})
    $result.nonLoopbackAdapters=$active.Count
    if($active.Count -ne 0){throw 'Network interface isolation is not confirmed.'}
    $guestRoot='C:\LocalBackend'
    New-Item -ItemType Directory -Path "$guestRoot\backend\phase2","$guestRoot\backend\vendor\LawinServer","$guestRoot\configs","$guestRoot\logs" -Force | Out-Null
    Copy-Item -LiteralPath 'C:\LocalProject\backend\phase2\server.cjs','C:\LocalProject\backend\phase2\profiles.cjs' -Destination "$guestRoot\backend\phase2"
    Copy-Item -LiteralPath 'C:\LocalProject\backend\offline-guard.cjs' -Destination "$guestRoot\backend"
    Copy-Item -LiteralPath 'C:\LocalProject\backend\vendor\LawinServer\node_modules' -Destination "$guestRoot\backend\vendor\LawinServer" -Recurse
    $cfg=@{environment='local';phase=2;backendHost='127.0.0.1';backendPort=3551;gameServerHost='127.0.0.1';accountId='local-player';displayName='Bernardo'}
    $cfg | ConvertTo-Json | Set-Content -LiteralPath "$guestRoot\configs\local.json" -Encoding utf8
    $env:FORTNITE_LOCAL_CONFIG="$guestRoot\configs\local.json"
    $env:FORTNITE_LOCAL_CONTROL_KEY=[guid]::NewGuid().ToString('N')
    $arguments=@('--require',"$guestRoot\backend\offline-guard.cjs","$guestRoot\backend\phase2\server.cjs")
    $process=Start-Process -FilePath 'C:\LocalNode\node.exe' -ArgumentList $arguments -WorkingDirectory $guestRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput "$guestRoot\logs\stdout.log" -RedirectStandardError "$guestRoot\logs\stderr.log"
    $null=$process.Handle
    $base='http://127.0.0.1:3551'
    for($i=0;$i -lt 80;$i++){
        if($process.HasExited){throw 'Guest backend exited before health.'}
        try{$health=Invoke-RestMethod -Uri ($base+'/health') -TimeoutSec 1;if($health.phase -eq 2){break}}catch{}
        Start-Sleep -Milliseconds 250
    }
    if($health.phase -ne 2){throw 'Guest health failed'}
    $result.health=$true
    $session=Invoke-RestMethod -Uri ($base+'/account/api/oauth/token') -Method Post -ContentType 'application/x-www-form-urlencoded' -Body 'grant_type=password&username=local-player&password=local-only-not-epic'
    $headers=@{Authorization=('Bearer '+$session.access_token)}
    $profile=Invoke-RestMethod -Uri ($base+'/fortnite/api/game/v2/profile/local-player/client/QueryProfile?profileId=athena&rvn=-1') -Method Post -Headers $headers -ContentType 'application/json' -Body '{}'
    if($profile.profileChanges[0].profile.accountId -ne 'local-player'){throw 'Guest local profile failed'}
    $result.profile=$true
    $bootstrap=Invoke-RestMethod -Uri ($base+'/local/phase2/lobby-bootstrap') -Headers $headers
    if(-not $bootstrap.localSimulationReady -or $bootstrap.realClientLobbyVerified){throw 'Guest bootstrap failed'}
    $result.bootstrap=$true
    Invoke-RestMethod -Uri ($base+'/__local/shutdown') -Method Post -Headers @{'X-Local-Control'=$env:FORTNITE_LOCAL_CONTROL_KEY} | Out-Null
    if(-not $process.WaitForExit(10000) -or $process.ExitCode -ne 0){throw 'Guest shutdown failed'}
    $result.success=$true
}catch{
    $result.errorType=$_.Exception.GetType().Name
}finally{
    if($process -and -not $process.HasExited){Stop-Process -Id $process.Id -Force}
    if(Test-Path -LiteralPath 'C:\LocalBackend\logs'){Copy-Item -Path 'C:\LocalBackend\logs\*' -Destination 'C:\LocalExport' -Force}
    $result | ConvertTo-Json | Set-Content -LiteralPath 'C:\LocalExport\backend-test-result.json' -Encoding utf8
    if($env:COMPUTERNAME -ne $guestSettings.hostComputerName){& "$env:SystemRoot\System32\shutdown.exe" /s /t 0}
}
