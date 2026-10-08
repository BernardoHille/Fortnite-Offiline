[CmdletBinding()]
param([switch]$OfflinePackages, [switch]$SkipBundleCopy)
. (Join-Path $PSScriptRoot 'reboot-common.ps1')
$lock = Get-RebootLock
$source = Join-Path $rebootProjectRoot $lock.launcher.directory
$sdk = Join-Path $rebootProjectRoot $lock.flutter.directory
Assert-RebootCheckout $source $lock.launcher.commit $lock.launcher.url
Assert-RebootPatch $source (Join-Path $rebootProjectRoot $lock.launcher.patch)
Assert-RebootCheckout $sdk $lock.flutter.commit $lock.flutter.url
Get-RebootNativeTools | Out-Null
$flutter = Join-Path $sdk 'bin/flutter.bat'
$gui = Join-Path $source 'gui'
$pubLock = Join-Path $gui 'pubspec.lock'
if ((Get-FileHash -LiteralPath $pubLock).Hash.ToLowerInvariant() -ne $lock.launcher.pubspecLockSha256) { throw 'Dependency lock mismatch. Run restore-reboot-stack.ps1.' }
$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:DART_SUPPRESS_ANALYTICS = 'true'
$env:PUB_CACHE = Join-Path $rebootProjectRoot 'reboot/tools/pub-cache'
$logDirectory = Join-Path $rebootProjectRoot 'reboot/logs'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
if (-not $OfflinePackages) {
    Invoke-RebootTool $flutter @('--no-version-check','precache','--windows','--no-android','--no-ios','--no-web','--no-linux','--no-macos','--no-fuchsia') (Join-Path $logDirectory 'flutter-precache-reproduction.log')
}
$pubLog = Join-Path $logDirectory 'launcher-pub-get-reproduction.log'
Push-Location -LiteralPath $gui
try {
    $pubArguments = @('--no-version-check', 'pub', 'get', '--enforce-lockfile')
    if ($OfflinePackages) { $pubArguments += '--offline' }
    & $flutter @pubArguments *> $pubLog
    $pubExit = $LASTEXITCODE
    if ((Get-FileHash -LiteralPath $pubLock).Hash.ToLowerInvariant() -ne $lock.launcher.pubspecLockSha256) { throw 'pub get changed the lock; build stopped.' }
    if ($pubExit -ne 0 -and -not (Select-String -LiteralPath $pubLog -Pattern 'Building with plugins requires symlink support' -Quiet)) { throw "pub get failed. Inspect $pubLog" }
    # Flutter accepts local NTFS junctions when symlink privilege is unavailable.
    # Each target must be a package inside this project's dedicated cache.
    $plugins = Get-Content -LiteralPath (Join-Path $gui '.flutter-plugins-dependencies') -Raw | ConvertFrom-Json
    $linkRoot = Join-Path $gui 'windows/flutter/ephemeral/.plugin_symlinks'
    New-Item -ItemType Directory -Path $linkRoot -Force | Out-Null
    $cacheRoot = [IO.Path]::GetFullPath($env:PUB_CACHE).TrimEnd('\','/') + '\'
    foreach ($plugin in $plugins.plugins.windows) {
        if ($plugin.name -notmatch '^[A-Za-z0-9_]+$') { throw 'Unexpected plugin name.' }
        $target = [IO.Path]::GetFullPath($plugin.path).TrimEnd('\','/')
        if (-not ($target + '\').StartsWith($cacheRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Plugin target outside local cache.' }
        if (-not (Test-Path -LiteralPath $target -PathType Container)) { throw 'Missing plugin target.' }
        $link = Join-Path $linkRoot $plugin.name
        if (-not (Test-Path -LiteralPath $link)) { New-Item -ItemType Junction -Path $link -Target $target | Out-Null }
        $linkItem = Get-Item -LiteralPath $link -Force
        if (-not $linkItem.LinkType) { throw 'Existing plugin path is not a link; preserved.' }
    }
    Invoke-RebootTool $flutter @('--no-version-check','gen-l10n') (Join-Path $logDirectory 'launcher-gen-l10n-reproduction.log')
    Invoke-RebootTool $flutter @('--no-version-check','build','windows','--release','--no-pub') (Join-Path $logDirectory 'launcher-build-reproduction.log')
} finally { Pop-Location }
$builtBundle = Join-Path $gui 'build/windows/x64/runner/Release'
$bundle = Join-Path $rebootProjectRoot 'reboot/artifacts/launcher/Release'
if ($SkipBundleCopy) {
    Get-FileHash -LiteralPath (Join-Path $builtBundle 'reboot_launcher.exe') -Algorithm SHA256
    Write-Output "[OK] GUI Release compiled: $builtBundle. Bundle copy skipped; no running process stopped."
    return
}
# Check every existing destination before replacing any bundle file. In
# particular, embedded Lawin can stay alive after the GUI is closed.
foreach ($sourceFile in Get-ChildItem -LiteralPath $builtBundle -Recurse -File) {
    $relative = $sourceFile.FullName.Substring($builtBundle.Length).TrimStart('\','/')
    if ($relative -like 'settings\*' -or $relative -eq 'launcher.log') { continue }
    $destinationFile = Join-Path $bundle $relative
    if (-not (Test-Path -LiteralPath $destinationFile -PathType Leaf)) { continue }
    try {
        $stream = [IO.File]::Open($destinationFile, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        $stream.Dispose()
    } catch {
        throw "Bundle file is in use or inaccessible: $destinationFile. Build succeeded, copy stopped. Close your launcher/backend through its controls or use -SkipBundleCopy; no process was stopped automatically."
    }
}
New-Item -ItemType Directory -Path $bundle -Force | Out-Null
foreach ($item in Get-ChildItem -LiteralPath $builtBundle -Force) {
    if ($item.Name -eq 'settings' -or $item.Name -eq 'launcher.log') { continue }
    Copy-Item -LiteralPath $item.FullName -Destination $bundle -Recurse -Force
}
Get-FileHash -LiteralPath (Join-Path $bundle 'reboot_launcher.exe') -Algorithm SHA256
Write-Output "[OK] GUI Release bundle compiled: $bundle. Existing settings preserved; GUI not opened."
