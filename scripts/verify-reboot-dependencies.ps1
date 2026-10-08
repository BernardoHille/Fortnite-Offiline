[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'reboot-common.ps1')
$lock = Get-RebootLock
$dllRoot = Join-Path $rebootProjectRoot 'reboot/artifacts/launcher/Release/dlls'
foreach ($entry in $lock.downloadedDependencies) {
    $path = Join-Path $dllRoot $entry.name
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing dependency: $($entry.name). This script never downloads or injects it." }
    $hash = (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()
    if ($hash -ne $entry.sha256) { throw "Dependency differs from the manually tested version: $($entry.name). Do not silently replace the pinned state." }
    Write-Output "[OK] $($entry.name) SHA-256 matches the tested state."
}
Write-Output '[OK] Read-only file verification. This does not audit DLL internals or prove completely offline operation.'
