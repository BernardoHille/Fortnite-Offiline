#Requires -Version 7.4
# Helpers only: no launch, capture, firewall change or network request on import.
Set-StrictMode -Version Latest
$RuntimeObservationRoot = Split-Path $PSScriptRoot -Parent
$RuntimeObservationDirectory = Join-Path $RuntimeObservationRoot 'runtime/phase2/runtime-observation'
$RuntimeObservationState = Join-Path $RuntimeObservationDirectory 'session.local.json'
$RuntimeObservationGroup = 'Fortnite-Local-C2S3 Phase2 Runtime Observation'

function Assert-RuntimeObservationNoReparsePath {
    param([Parameter(Mandatory)][string]$LiteralPath)
    # FileInfo.Directory/DirectoryInfo.Parent return plain .NET objects, without
    # the PowerShell provider's synthetic PSIsContainer property.
    $part = Get-Item -LiteralPath $LiteralPath -ErrorAction Stop
    while ($null -ne $part) {
        if ($part.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Reparse point rejected: $($part.FullName)" }
        if ($part -is [IO.DirectoryInfo]) { $part = $part.Parent }
        elseif ($part -is [IO.FileInfo]) { $part = $part.Directory }
        else { throw 'Expected a filesystem file or directory.' }
    }
}

function Get-RuntimeObservationTargets {
    $settings = Get-Content -LiteralPath (Join-Path $RuntimeObservationRoot 'configs/local.json') -Raw | ConvertFrom-Json
    $build = [IO.Path]::GetFullPath($settings.buildPath).TrimEnd('\')
    if ((Split-Path $build -Leaf) -ne '13.40' -or (Split-Path (Split-Path $build -Parent) -Leaf) -ne '13.40-CL-14113327') {
        throw 'Unexpected build. Only the existing 13.40 / CL 14113327 build is supported.'
    }
    if ($build.StartsWith([IO.Path]::GetFullPath($RuntimeObservationRoot).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The build must remain outside the repository.'
    }
    $relative = @(
        'Engine/Binaries/Win64/CrashReportClient.exe'
        'Engine/Binaries/Win64/UnrealCEFSubProcess.exe'
        'FortniteGame/Binaries/Win64/FortniteClient-Win64-Shipping_BE.exe'
        'FortniteGame/Binaries/Win64/FortniteClient-Win64-Shipping_EAC.exe'
        'FortniteGame/Binaries/Win64/FortniteClient-Win64-Shipping.exe'
        'FortniteGame/Binaries/Win64/FortniteLauncher.exe'
        'FortniteGame/Binaries/Win64/BattlEye/BEService_x64.exe'
        'FortniteGame/Binaries/Win64/EasyAntiCheat/EasyAntiCheat_Setup.exe'
    )
    $targets = @($relative | ForEach-Object { [IO.Path]::GetFullPath((Join-Path $build $_)) })
    foreach ($target in $targets) {
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Missing executable: $target" }
        # Reparse points would defeat path-specific ownership/isolation checks.
        Assert-RuntimeObservationNoReparsePath -LiteralPath $target
    }
    $actual = @(Get-ChildItem -LiteralPath $build -Filter '*.exe' -Recurse -File | ForEach-Object FullName)
    if (@(Compare-Object ($targets | Sort-Object) ($actual | Sort-Object)).Count) {
        throw 'Executable inventory changed. Review the exact list before creating any rule.'
    }
    [pscustomobject]@{ BuildPath = $build; Programs = $targets }
}

function Assert-RuntimeObservationAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Future application/cleanup requires an elevated PowerShell 7. No automatic elevation is attempted.'
    }
}

function Assert-RuntimeObservationStopped {
    param($Targets)
    $processes = @(Get-CimInstance Win32_Process -ErrorAction Stop)
    foreach ($process in $processes) {
        if (($process.ExecutablePath -and $process.ExecutablePath.StartsWith($Targets.BuildPath + '\', [StringComparison]::OrdinalIgnoreCase)) -or
            $process.Name -eq 'FortExternalServer.exe') {
            throw "Game/helper still running (PID $($process.ProcessId)); keep isolation and close it normally first."
        }
    }
}

function Assert-RuntimeObservationPhysicallyOffline {
    # Per-program rules do not establish isolation for shared DNS/services.
    # Conservatively require all adapters/interfaces except software loopback offline.
    $up = @(Get-NetAdapter -IncludeHidden -ErrorAction Stop | Where-Object Status -eq 'Up')
    $connected = @(Get-NetIPInterface -ErrorAction Stop | Where-Object {
        $_.ConnectionState -eq 'Connected' -and $_.InterfaceAlias -notlike '*Loopback*'
    })
    if ($up.Count -or $connected.Count) {
        $names = @(@($up | ForEach-Object Name) + @($connected | ForEach-Object InterfaceAlias) | Sort-Object -Unique)
        throw ('Offline gate failed: connected adapters/interfaces: ' + ($names -join ', ') + '. Disconnect external networking manually before the authorized run; this script never changes adapters, DNS or shared services.')
    }
}

function Get-RuntimeObservationRulePlan {
    param($Targets, [string]$SessionId)
    if ($SessionId -notmatch '^[a-f0-9]{32}$') { throw 'Invalid session identity.' }
    for ($i = 0; $i -lt $Targets.Programs.Count; $i++) {
        foreach ($direction in @('Inbound', 'Outbound')) {
            [pscustomobject][ordered]@{
                Name = "FNLC2S3-P2Runtime-$SessionId-$i-$direction"
                DisplayName = "Fortnite-Local-C2S3 P2 Runtime $SessionId $i $direction"
                Group = $RuntimeObservationGroup
                Description = "Owned by Fortnite-Local-C2S3 runtime observation session $SessionId."
                Program = $Targets.Programs[$i]
                Direction = $direction
            }
        }
    }
}

function Assert-RuntimeObservationOwnedRule {
    param($Rule, $Expected, [switch]$Effective)
    if ($Rule.Name -ne $Expected.Name -or $Rule.Group -ne $Expected.Group -or $Rule.Description -ne $Expected.Description -or
        $Rule.DisplayName -ne $Expected.DisplayName -or $Rule.Direction.ToString() -ne $Expected.Direction -or
        $Rule.Action.ToString() -ne 'Block' -or $Rule.Enabled.ToString() -ne 'True' -or $Rule.Profile.ToString() -ne 'Any') {
        throw "Rule ownership/settings mismatch; no removal authorized: $($Expected.Name)"
    }
    $application = $Rule | Get-NetFirewallApplicationFilter -ErrorAction Stop
    $address = $Rule | Get-NetFirewallAddressFilter -ErrorAction Stop
    $port = $Rule | Get-NetFirewallPortFilter -ErrorAction Stop
    if ($application.Program -ne $Expected.Program -or $address.LocalAddress -ne 'Any' -or $address.RemoteAddress -ne 'Any' -or
        $port.Protocol -ne 'Any' -or $port.LocalPort -ne 'Any' -or $port.RemotePort -ne 'Any') {
        throw "Rule scope mismatch: $($Expected.Name)"
    }
    if ($Effective -and $Rule.PrimaryStatus.ToString() -ne 'OK') { throw "Rule not effective: $($Expected.Name)" }
}

function Get-RuntimeObservationFirewallSnapshot {
    # Only policy metadata, never packet contents or process activity.
    $records = @(Get-NetFirewallRule -PolicyStore PersistentStore -ErrorAction Stop | Sort-Object Name | ForEach-Object {
        $rule = $_
        $application = $rule | Get-NetFirewallApplicationFilter -ErrorAction Stop
        $address = $rule | Get-NetFirewallAddressFilter -ErrorAction Stop
        $port = $rule | Get-NetFirewallPortFilter -ErrorAction Stop
        $service = $rule | Get-NetFirewallServiceFilter -ErrorAction Stop
        $interface = $rule | Get-NetFirewallInterfaceFilter -ErrorAction Stop
        $interfaceType = $rule | Get-NetFirewallInterfaceTypeFilter -ErrorAction Stop
        $security = $rule | Get-NetFirewallSecurityFilter -ErrorAction Stop
        [ordered]@{
            Name = $rule.Name; DisplayName = $rule.DisplayName; Group = $rule.Group; Description = $rule.Description
            Enabled = "$($rule.Enabled)"; Profile = "$($rule.Profile)"; Direction = "$($rule.Direction)"; Action = "$($rule.Action)"
            EdgeTraversalPolicy = "$($rule.EdgeTraversalPolicy)"; LooseSourceMapping = "$($rule.LooseSourceMapping)"; LocalOnlyMapping = "$($rule.LocalOnlyMapping)"
            Program = $application.Program; Package = $application.Package; Service = $service.Service
            LocalAddress = @($address.LocalAddress); RemoteAddress = @($address.RemoteAddress)
            Protocol = "$($port.Protocol)"; LocalPort = @($port.LocalPort); RemotePort = @($port.RemotePort); IcmpType = @($port.IcmpType)
            InterfaceAlias = @($interface.InterfaceAlias); InterfaceType = "$($interfaceType.InterfaceType)"
            Authentication = "$($security.Authentication)"; Encryption = "$($security.Encryption)"; OverrideBlockRules = "$($security.OverrideBlockRules)"
            LocalUser = $security.LocalUser; RemoteUser = $security.RemoteUser; RemoteMachine = $security.RemoteMachine
        }
    })
    $profileProperties = @('Name', 'Enabled', 'DefaultInboundAction', 'DefaultOutboundAction', 'AllowInboundRules',
        'AllowLocalFirewallRules', 'AllowLocalIPsecRules', 'NotifyOnListen', 'LogFileName', 'LogMaxSizeKilobytes',
        'LogAllowed', 'LogBlocked', 'DisabledInterfaceAliases')
    $profiles = @(Get-NetFirewallProfile -PolicyStore PersistentStore -ErrorAction Stop | Sort-Object Name | Select-Object -Property $profileProperties)
    $json = [ordered]@{ Rules = $records; Profiles = $profiles } | ConvertTo-Json -Depth 12 -Compress
    [pscustomobject]@{ Sha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($json))); Json = $json; RuleCount = $records.Count }
}

function Save-RuntimeObservationState {
    param($State)
    $temp = Join-Path $RuntimeObservationDirectory 'session.local.json.tmp'
    $State | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath $temp -Encoding utf8
    Move-Item -LiteralPath $temp -Destination $RuntimeObservationState -Force
}
