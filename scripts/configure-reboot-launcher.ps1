[CmdletBinding()]
param([Parameter(Mandatory)][string]$BuildPath, [string]$SettingsDirectory = '')
. (Join-Path $PSScriptRoot 'reboot-common.ps1')
$lock = Get-RebootLock
$profile = Get-Content -LiteralPath (Join-Path $rebootProjectRoot 'reboot/config/launcher-profile.example.json') -Raw | ConvertFrom-Json
$gameRoot = (Resolve-Path -LiteralPath $BuildPath).Path.TrimEnd('\','/')
$projectPrefix = [IO.Path]::GetFullPath($rebootProjectRoot).TrimEnd('\','/') + '\'
if (($gameRoot + '\').StartsWith($projectPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Keep the proprietary build outside this repository.' }
$shipping = Join-Path $gameRoot 'FortniteGame/Binaries/Win64/FortniteClient-Win64-Shipping.exe'
if (-not (Test-Path -LiteralPath $shipping -PathType Leaf)) { throw 'BuildPath must contain FortniteGame and Engine; Shipping not found.' }
if ((Get-FileHash -LiteralPath $shipping).Hash.ToLowerInvariant() -ne $lock.target.shippingSha256) { throw 'Shipping does not match the audited original 13.40 CL 14113327. No files modified.' }
$gameServerDll = Join-Path $rebootProjectRoot 'reboot/artifacts/reboot3/Release/Project Reboot 3.0.dll'
if (-not (Test-Path -LiteralPath $gameServerDll)) { throw 'Compile Project Reboot Release first.' }
if (-not $SettingsDirectory) { $SettingsDirectory = Join-Path $rebootProjectRoot 'reboot/artifacts/launcher/Release/settings' }
$settingsRoot = [IO.Path]::GetFullPath($SettingsDirectory)
$artifactPrefix = [IO.Path]::GetFullPath((Join-Path $rebootProjectRoot 'reboot/artifacts')).TrimEnd('\','/') + '\'
if (-not ($settingsRoot + '\').StartsWith($artifactPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Settings output must stay under reboot/artifacts, outside Fortnite.' }
$containers = @('v3_game_storage','v3_dll_storage','v3_backend_storage','v3_hosting_storage')
foreach ($name in $containers) {
    foreach ($extension in @('.gs','.bak')) {
        if (Test-Path -LiteralPath (Join-Path $settingsRoot ($name + $extension))) { throw 'Settings already exist; preserved without overwrite. Use the GUI for later edits or choose a new SettingsDirectory.' }
    }
}
$version = [ordered]@{name=$profile.profileName; gameVersion=$profile.gameVersion; location=$gameRoot}
$versionsJson = ConvertTo-Json -InputObject @($version) -Compress
$storage = [ordered]@{
    v3_game_storage = [ordered]@{versions=$versionsJson; version=$profile.profileName; username=''; password=''; custom_launch_args=''}
    v3_dll_storage = [ordered]@{custom_game_server=$true; game_server=$gameServerDll; game_server_port=$profile.gameServerPort}
    v3_backend_storage = [ordered]@{type=$profile.backendType; game_server_address=$profile.gameServerAddress; detached=$profile.backendDetached}
    v3_hosting_storage = [ordered]@{headless=$profile.headless; auto_restart=$profile.autoRestart; account_username=''; account_password=''; custom_launch_args=''; name=$profile.serverName; description=$profile.serverDescription; password=''}
}
New-Item -ItemType Directory -Path $settingsRoot -Force | Out-Null
$utf8 = [Text.UTF8Encoding]::new($false)
foreach ($name in $containers) {
    $json = $storage[$name] | ConvertTo-Json -Compress -Depth 8
    foreach ($extension in @('.gs','.bak')) { [IO.File]::WriteAllText((Join-Path $settingsRoot ($name + $extension)), $json, $utf8) }
}
Write-Output "[OK] Local settings prepared: $settingsRoot. Accounts/passwords blank; no import patch, game copy or launch."
