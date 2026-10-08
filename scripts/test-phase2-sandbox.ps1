#Requires -Version 7.4
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'phase2-common.ps1')
$feature=Get-CimInstance Win32_OptionalFeature -Filter "Name='Containers-DisposableClientVM'"
if($feature.InstallState -ne 1){throw 'Windows Sandbox is not enabled; nothing was installed or changed.'}
$sandbox=(Get-Command WindowsSandbox.exe -ErrorAction Stop).Source
if(Get-Process -Name WindowsSandbox -ErrorAction SilentlyContinue){throw 'An existing Sandbox is running; it was not reused or stopped.'}
$export=Join-Path $Phase2Root ('runtime/phase2/sandbox-tests/'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $export -Force | Out-Null
$nodeDirectory=Split-Path (Get-Command node).Source -Parent
@{hostComputerName=$env:COMPUTERNAME} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Phase2Root 'runtime/phase2/sandbox-test.settings.json') -Encoding utf8
$escape={param($value);[Security.SecurityElement]::Escape($value)}
$project=& $escape $Phase2Root;$node=& $escape $nodeDirectory;$output=& $escape $export
$config=@"
<Configuration>
  <Networking>Disable</Networking><vGPU>Enable</vGPU><ProtectedClient>Enable</ProtectedClient>
  <AudioInput>Disable</AudioInput><VideoInput>Disable</VideoInput><ClipboardRedirection>Disable</ClipboardRedirection><PrinterRedirection>Disable</PrinterRedirection>
  <MemoryInMB>4096</MemoryInMB>
  <MappedFolders>
    <MappedFolder><HostFolder>$project</HostFolder><SandboxFolder>C:\LocalProject</SandboxFolder><ReadOnly>true</ReadOnly></MappedFolder>
    <MappedFolder><HostFolder>$node</HostFolder><SandboxFolder>C:\LocalNode</SandboxFolder><ReadOnly>true</ReadOnly></MappedFolder>
    <MappedFolder><HostFolder>$output</HostFolder><SandboxFolder>C:\LocalExport</SandboxFolder><ReadOnly>false</ReadOnly></MappedFolder>
  </MappedFolders>
  <LogonCommand><Command>powershell.exe -NoProfile -File C:\LocalProject\scripts\phase2-sandbox-backend-test.ps1</Command></LogonCommand>
</Configuration>
"@
$file=Join-Path $Phase2Root 'launcher/phase2-backend-test.local.wsb'
$config | Set-Content -LiteralPath $file -Encoding utf8
$xml=[xml](Get-Content -LiteralPath $file -Raw)
if($xml.Configuration.Networking -ne 'Disable' -or $config -match 'FortniteClient|FortniteLauncher|FortExternalServer'){throw 'Unsafe guest test definition'}
Write-Phase2LauncherLog -Result 'isolated-backend-only-test-requested'
$instance=Start-Process -FilePath $sandbox -ArgumentList ('"'+$file+'"') -WindowStyle Hidden -PassThru
$null=$instance.Handle
$deadline=[DateTime]::UtcNow.AddSeconds(100)
$resultPath=Join-Path $export 'backend-test-result.json'
try{while([DateTime]::UtcNow -lt $deadline){
    if(Test-Path -LiteralPath $resultPath){
        $result=Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
        $result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Phase2Root 'logs/phase2-sandbox-test.json') -Encoding utf8
        if(-not $result.success){throw 'Isolated backend-only test failed; see exported sandbox logs.'}
        Write-Output '[OK] Backend-only guest test passed. Fortnite was not mapped or executed.'
        return
    }
    Start-Sleep -Milliseconds 500
}
Write-Phase2LauncherLog -Result 'isolated-backend-only-test-timeout'
[ordered]@{timestamp=[DateTime]::UtcNow.ToString('o');component='phase2-sandbox-backend-test';success=$false;result='timeout-no-guest-proof';clientExecuted=$false;fortniteMapped=$false;guestNetworkVerified=$false} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Phase2Root 'logs/phase2-sandbox-test.json') -Encoding utf8
throw 'Sandbox test produced no result within 100 seconds. No game was launched. Do not retry blindly; inspect the Sandbox state.'
}finally{
    if(-not $instance.HasExited){
        $null=$instance.CloseMainWindow()
        if(-not $instance.WaitForExit(5000)){Stop-Process -Id $instance.Id -Force}
    }
}
