#Requires -Version 7.4
$Phase2Root = Split-Path $PSScriptRoot -Parent
function Get-Phase2Config {
    param([string]$ConfigPath=(Join-Path $Phase2Root 'configs/local.json'))
    $absoluteConfig=(Resolve-Path -LiteralPath $ConfigPath).Path
    $config=Get-Content -LiteralPath $absoluteConfig -Raw | ConvertFrom-Json
    if($config.environment -ne 'local' -or $config.phase -ne 2 -or $config.backendHost -ne '127.0.0.1' -or $config.gameServerHost -ne '127.0.0.1' -or $config.accountId -ne 'local-player'){throw 'Phase 2 requires local environment, local-player and loopback hosts.'}
    if($config.backendPort -isnot [long] -and $config.backendPort -isnot [int]){throw 'Backend port must be an integer.'}
    if($config.backendPort -lt 1024 -or $config.backendPort -gt 65535 -or $config.displayName -notmatch '^[\p{L}\p{N} _-]{1,24}$'){throw 'Invalid port or local displayName.'}
    if(-not $config.buildPath -or -not [IO.Path]::IsPathFullyQualified($config.buildPath)){throw 'An absolute local build path is required.'}
    $binary=Join-Path $config.buildPath 'FortniteGame/Binaries/Win64/FortniteClient-Win64-Shipping.exe'
    if(-not (Test-Path -LiteralPath $binary -PathType Leaf) -or -not (Test-Path -LiteralPath (Join-Path $config.buildPath 'Engine') -PathType Container)){throw 'Expected existing external build not found.'}
    $repoPrefix=[IO.Path]::GetFullPath($Phase2Root).TrimEnd('\')+'\'
    $buildPrefix=[IO.Path]::GetFullPath($config.buildPath).TrimEnd('\')+'\'
    if($buildPrefix.StartsWith($repoPrefix,[StringComparison]::OrdinalIgnoreCase)){throw 'The Fortnite build must remain outside Git.'}
    [pscustomobject]@{Config=$config;Path=$absoluteConfig;BaseUrl="http://127.0.0.1:$($config.backendPort)";Binary=$binary}
}
function Write-Phase2LauncherLog {
    param([string]$Result,[string]$Route='(coordinator)',[int]$ComponentPid=0)
    [ordered]@{timestamp=[DateTime]::UtcNow.ToString('o');component='phase2-launcher';pid=$PID;componentPid=$ComponentPid;host='127.0.0.1';route=$Route;result=$Result} | ConvertTo-Json -Compress | Add-Content -LiteralPath (Join-Path $Phase2Root 'logs/phase2-launcher.log') -Encoding utf8
}
function Start-Phase2Backend {
    param($Settings)
    if(Get-NetTCPConnection -State Listen -LocalPort $Settings.Config.backendPort -ErrorAction SilentlyContinue){throw 'Backend port already in use; no existing process was stopped.'}
    $node=(Get-Command node -ErrorAction Stop).Source
    $entry=Join-Path $Phase2Root 'backend/phase2/server.cjs'
    $guard=Join-Path $Phase2Root 'backend/offline-guard.cjs'
    $nonce=[Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
    $process=$null
    try {
        $process=Start-Process -FilePath $node -ArgumentList @('--require',('"'+$guard+'"'),('"'+$entry+'"')) -WorkingDirectory $Phase2Root -WindowStyle Hidden -PassThru `
            -Environment @{FORTNITE_LOCAL_CONFIG=$Settings.Path;FORTNITE_LOCAL_CONTROL_KEY=$nonce} `
            -RedirectStandardOutput (Join-Path $Phase2Root 'logs/phase2-backend.stdout.log') -RedirectStandardError (Join-Path $Phase2Root 'logs/phase2-backend.stderr.log')
        for($attempt=0;$attempt -lt 60;$attempt++){
            if($process.HasExited){throw 'Phase 2 backend exited before readiness. See phase2-backend.stderr.log.'}
            try{$health=Invoke-RestMethod -Uri ($Settings.BaseUrl+'/health') -TimeoutSec 1;if($health.status -eq 'ok' -and $health.phase -eq 2){break}}catch{}
            Start-Sleep -Milliseconds 200
        }
        if(-not $health -or $health.phase -ne 2){throw 'Phase 2 health check timed out.'}
        $listeners=@(Get-NetTCPConnection -State Listen -OwningProcess $process.Id)
        if($listeners.Count -ne 1 -or $listeners[0].LocalAddress -ne '127.0.0.1' -or $listeners[0].LocalPort -ne $Settings.Config.backendPort){throw 'Unexpected backend listener.'}
        Write-Phase2LauncherLog -Result 'backend-ready' -Route '/health' -ComponentPid $process.Id
        [pscustomobject]@{Process=$process;Pid=$process.Id;StartTimeUtc=$process.StartTime.ToUniversalTime().ToString('o');ControlKey=$nonce;BaseUrl=$Settings.BaseUrl}
    }catch{
        if($process -and -not $process.HasExited){Stop-Process -Id $process.Id -Force}
        Write-Phase2LauncherLog -Result 'backend-start-failed'
        throw
    }
}
function Stop-Phase2Backend {
    param($Session)
    $owned=Get-Process -Id $Session.Pid -ErrorAction SilentlyContinue
    if(-not $owned){Write-Phase2LauncherLog -Result 'backend-already-stopped';return}
    $recordedStart=([DateTime]$Session.StartTimeUtc).ToUniversalTime().Ticks
    if($owned.StartTime.ToUniversalTime().Ticks -ne $recordedStart -or $owned.ProcessName -ne 'node'){throw 'PID ownership mismatch; no process stopped.'}
    $waitProcess=if($Session.Process -is [Diagnostics.Process]){$Session.Process}else{$owned}
    $null=$waitProcess.Handle
    try{
        Invoke-RestMethod -Uri ($Session.BaseUrl+'/__local/shutdown') -Method Post -Headers @{'X-Local-Control'=$Session.ControlKey} -TimeoutSec 2 | Out-Null
        if(-not $waitProcess.WaitForExit(10000)){throw 'Graceful shutdown timeout.'}
        if($waitProcess.ExitCode -ne 0){throw 'Backend exit code is not zero.'}
        Write-Phase2LauncherLog -Result 'backend-stopped-normally' -ComponentPid $Session.Pid
    }catch{
        Write-Phase2LauncherLog -Result 'backend-stop-error' -ComponentPid $Session.Pid
        throw
    }
}
