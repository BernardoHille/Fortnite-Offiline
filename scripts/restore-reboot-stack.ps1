[CmdletBinding()]
param([switch]$IncludeFlutterSdk)
. (Join-Path $PSScriptRoot 'reboot-common.ps1')
$lock = Get-RebootLock
$entries = @($lock.reboot3, $lock.launcher)
if ($IncludeFlutterSdk) { $entries += $lock.flutter }
foreach ($entry in $entries) {
    $destination = Join-Path $rebootProjectRoot $entry.directory
    if (-not (Test-Path -LiteralPath (Join-Path $destination '.git'))) {
        if (Test-Path -LiteralPath $destination) { throw "Destination already exists without Git: $destination" }
        New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
        Invoke-RebootTool git @('clone', '--filter=blob:none', '--no-checkout', '--', $entry.url, $destination)
        Invoke-RebootTool git @('-C', $destination, 'checkout', '--detach', $entry.commit)
    }
    Assert-RebootCheckout $destination $entry.commit $entry.url
}
foreach ($entry in @($lock.reboot3, $lock.launcher)) {
    $destination = Join-Path $rebootProjectRoot $entry.directory
    $patch = Join-Path $rebootProjectRoot $entry.patch
    & git -C $destination apply --reverse --check $patch 2>$null
    if ($LASTEXITCODE -eq 0) { continue }
    Invoke-RebootTool git @('-C', $destination, 'apply', '--check', $patch)
    Invoke-RebootTool git @('-C', $destination, 'apply', $patch)
}
$savedLock = Join-Path $rebootProjectRoot $lock.launcher.pubspecLock
if ((Get-FileHash -LiteralPath $savedLock).Hash.ToLowerInvariant() -ne $lock.launcher.pubspecLockSha256) { throw 'Saved pubspec.lock hash mismatch.' }
$destinationLock = Join-Path $rebootProjectRoot 'reboot/launcher/gui/pubspec.lock'
if (Test-Path -LiteralPath $destinationLock) {
    if ((Get-FileHash -LiteralPath $destinationLock).Hash.ToLowerInvariant() -ne $lock.launcher.pubspecLockSha256) { throw 'Existing pubspec.lock differs; preserved without overwrite.' }
} else {
    Copy-Item -LiteralPath $savedLock -Destination $destinationLock
}
Write-Output '[OK] Pinned sources, build patches and dependency lock prepared. No Fortnite download or launch.'
