[CmdletBinding()]
param([ValidateSet('Debug','Release','Both')][string]$Configuration = 'Both')
. (Join-Path $PSScriptRoot 'reboot-common.ps1')
$lock = Get-RebootLock
$source = Join-Path $rebootProjectRoot $lock.reboot3.directory
Assert-RebootCheckout $source $lock.reboot3.commit $lock.reboot3.url
Assert-RebootPatch $source (Join-Path $rebootProjectRoot $lock.reboot3.patch)
$tools = Get-RebootNativeTools
$configurations = if ($Configuration -eq 'Both') { @('Debug','Release') } else { @($Configuration) }
foreach ($mode in $configurations) {
    $output = Join-Path $rebootProjectRoot "reboot/artifacts/reboot3/$mode"
    $intermediate = Join-Path $rebootProjectRoot "reboot/artifacts/intermediate/reboot3/$mode"
    $log = Join-Path $rebootProjectRoot "reboot/logs/reboot3-$mode-reproduction.log"
    $arguments = @(
        (Join-Path $source 'Project Reboot 3.0.sln'), '/t:Build', '/m:2', '/nologo', '/v:minimal',
        "/p:Configuration=$mode", '/p:Platform=x64', '/p:CL_MPCount=2',
        "/p:PlatformToolset=$($lock.nativeTools.platformToolset)",
        "/p:VCToolsVersion=$($lock.nativeTools.vcToolsVersion)",
        "/p:WindowsTargetPlatformVersion=$($lock.nativeTools.windowsSdkVersion)",
        ('/p:OutDir=' + $output + '\'), ('/p:IntDir=' + $intermediate + '\')
    )
    Invoke-RebootTool $tools.msbuild $arguments $log
    $dll = Join-Path $output 'Project Reboot 3.0.dll'
    if (-not (Test-Path -LiteralPath $dll)) { throw "Missing output: $dll" }
    Get-FileHash -LiteralPath $dll -Algorithm SHA256
    Write-Output "[OK] $mode x64 compiled. Log: $log"
}
Write-Output '[OK] Build only; no DLL loaded and no game started.'
