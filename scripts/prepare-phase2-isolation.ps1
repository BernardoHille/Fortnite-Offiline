#Requires -Version 7.4
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'phase2-common.ps1')
$settings=Get-Phase2Config
$sandbox=Get-Command WindowsSandbox.exe -ErrorAction SilentlyContinue
$feature=Get-CimInstance Win32_OptionalFeature -Filter "Name='Containers-DisposableClientVM'" -ErrorAction SilentlyContinue
$export=Join-Path $Phase2Root 'runtime/phase2/sandbox-export'
New-Item -ItemType Directory -Path $export -Force | Out-Null
$escape={param($value);[Security.SecurityElement]::Escape($value)}
$build=& $escape $settings.Config.buildPath
$project=& $escape $Phase2Root
$output=& $escape $export
$template=@"
<Configuration>
  <Networking>Disable</Networking>
  <vGPU>Enable</vGPU>
  <ProtectedClient>Enable</ProtectedClient>
  <AudioInput>Disable</AudioInput>
  <VideoInput>Disable</VideoInput>
  <PrinterRedirection>Disable</PrinterRedirection>
  <ClipboardRedirection>Disable</ClipboardRedirection>
  <MemoryInMB>8192</MemoryInMB>
  <MappedFolders>
    <MappedFolder><HostFolder>$build</HostFolder><SandboxFolder>C:\LocalBuild</SandboxFolder><ReadOnly>true</ReadOnly></MappedFolder>
    <MappedFolder><HostFolder>$project</HostFolder><SandboxFolder>C:\LocalProject</SandboxFolder><ReadOnly>true</ReadOnly></MappedFolder>
    <MappedFolder><HostFolder>$output</HostFolder><SandboxFolder>C:\LocalExport</SandboxFolder><ReadOnly>false</ReadOnly></MappedFolder>
  </MappedFolders>
</Configuration>
"@
$file=Join-Path $Phase2Root 'launcher/phase2-isolation.local.wsb'
$template | Set-Content -LiteralPath $file -Encoding utf8
$parsed=[xml](Get-Content -LiteralPath $file -Raw)
if($parsed.Configuration.Networking -ne 'Disable' -or $parsed.Configuration.LogonCommand -or $parsed.Configuration.MappedFolders.MappedFolder[0].ReadOnly -ne 'true'){throw 'Isolation template validation failed'}
$readiness=[ordered]@{timestamp=[DateTime]::UtcNow.ToString('o');phase=2;sandboxExecutableFound=[bool]$sandbox;sandboxFeatureInstallState=$feature.InstallState;
    sandboxStarted=$false;sandboxNetworking='Disabled-in-template';clientRoutingVerified=$false;clientIsolationVerified=$false;
    realClientReady=$false;clientExecuted=$false;automaticLogonCommand=$false;blockers=@('No verified native local service URL override in Fortnite 13.40','Client isolation/runtime and loopback inside guest have not been verified','Anti-cheat and signed authentication prerequisites remain unknown; no bypass permitted')}
$readiness | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Phase2Root 'configs/phase2-readiness.local.json') -Encoding utf8
Write-Phase2LauncherLog -Result 'offline-sandbox-template-prepared-not-started'
Write-Output '[OK] Offline Sandbox XML prepared with read-only build mapping and no automatic command. This is an untested alternative, not client launch readiness.'
