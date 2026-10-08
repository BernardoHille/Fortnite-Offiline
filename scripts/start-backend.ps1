#Requires -Version 7.0
[CmdletBinding()]
param([switch]$SmokeTest)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$configFile = Join-Path $root 'configs/local.json'
if(-not (Test-Path -LiteralPath $configFile)){ $configFile = Join-Path $root 'configs/local.example.json' }
$config = Get-Content -LiteralPath $configFile -Raw | ConvertFrom-Json
if($config.phase -eq 2){
    if($SmokeTest){& (Join-Path $PSScriptRoot 'test-phase2-backend.ps1') -ConfigPath $configFile}else{& (Join-Path $PSScriptRoot 'start-phase2.ps1') -Mode Prepare -ConfigPath $configFile}
    return
}
if($config.environment -ne 'local' -or $config.phase -ne 1 -or $config.backendHost -ne '127.0.0.1' -or $config.gameServerHost -ne '127.0.0.1'){throw 'Only local Phase 1 loopback configuration is supported.'}
$port = [int]$config.backendPort
if($port -lt 1024 -or $port -gt 65535){throw 'Backend port must be between 1024 and 65535.'}
$source = Join-Path $root 'backend/vendor/LawinServer'
if(-not (Test-Path -LiteralPath (Join-Path $source 'node_modules/express'))){throw 'Backend dependencies missing. Run scripts/restore-stack.ps1.'}
$runtime = Join-Path $root 'backend/runtime'
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
$names = @('HOST','PORT','FORTNITE_LOCAL_PHASE','LOCALAPPDATA')
$previous = @{}
foreach($name in $names){$previous[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
$process = $null
$originalLocation = Get-Location
try {
    $env:HOST='127.0.0.1'; $env:PORT=[string]$port; $env:FORTNITE_LOCAL_PHASE='1'; $env:LOCALAPPDATA=$runtime
    Set-Location -LiteralPath $source
    $node = (Get-Command node -ErrorAction Stop).Source
    $guard = Join-Path $root 'backend/offline-guard.cjs'
    if(-not $SmokeTest){ & $node --require $guard index.js; if($LASTEXITCODE -ne 0){throw 'Backend exited with an error.'}; return }
    if(Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue){throw "Port $port is already in use."}
    $argsList = @('--require',('"'+$guard+'"'),'index.js')
    $process = Start-Process -FilePath $node -ArgumentList $argsList -WorkingDirectory $source -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $root 'logs/backend-stdout.log') -RedirectStandardError (Join-Path $root 'logs/backend-stderr.log')
    $health = $null
    for($attempt=0;$attempt -lt 40;$attempt++){
        if($process.HasExited){throw 'Backend exited before health check. See logs/backend-stderr.log.'}
        try{$health=Invoke-RestMethod -Uri "http://127.0.0.1:$port/health" -TimeoutSec 1;break}catch{Start-Sleep -Milliseconds 250}
    }
    if(-not $health -or $health.status -ne 'ok' -or $health.phase -ne 1){throw 'Health check failed.'}
    $listener = Get-NetTCPConnection -State Listen -OwningProcess $process.Id
    if(@($listener).Count -ne 1 -or $listener.LocalAddress -ne '127.0.0.1'){throw 'Backend is not isolated to a single loopback listener.'}
    $locked = Invoke-WebRequest -Uri "http://127.0.0.1:$port/fortnite/api/version" -SkipHttpErrorCheck
    if($locked.StatusCode -ne 503){throw 'Phase 1 routes must remain disabled.'}
    Invoke-RestMethod -Uri "http://127.0.0.1:$port/__phase1/shutdown" -Method Post | Out-Null
    if(-not $process.WaitForExit(10000)){throw 'Graceful shutdown timeout.'}
    if($process.ExitCode -ne 0){throw "Backend exited with code $($process.ExitCode)."}
    [pscustomobject]@{health=$health;loopbackOnly=$true;gameRoutesDisabled=$true;exitCode=$process.ExitCode} | ConvertTo-Json -Depth 5
} finally {
    if($process -and -not $process.HasExited){Stop-Process -Id $process.Id -Force}
    Set-Location -LiteralPath $originalLocation
    foreach($name in $names){[Environment]::SetEnvironmentVariable($name,$previous[$name],'Process')}
}
