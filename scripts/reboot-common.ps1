$ErrorActionPreference = 'Stop'
$rebootProjectRoot = Split-Path $PSScriptRoot -Parent
function Get-RebootLock {
    Get-Content -LiteralPath (Join-Path $rebootProjectRoot 'reboot/stack.lock.json') -Raw | ConvertFrom-Json
}
function Invoke-RebootTool {
    param([string]$Executable, [string[]]$ToolArguments, [string]$LogPath = '')
    if ($LogPath) {
        New-Item -ItemType Directory -Path (Split-Path $LogPath -Parent) -Force | Out-Null
        & $Executable @ToolArguments *> $LogPath
    } else {
        & $Executable @ToolArguments
    }
    if ($LASTEXITCODE -ne 0) { throw "Tool failed (exit $LASTEXITCODE): $Executable. Log: $LogPath" }
}
function Assert-RebootCheckout {
    param([string]$Directory, [string]$Commit, [string]$Remote)
    $actualCommit = & git -C $Directory rev-parse HEAD
    if ($LASTEXITCODE -ne 0 -or $actualCommit -ne $Commit) { throw "Unexpected commit: $Directory. Existing files preserved." }
    $actualRemote = & git -C $Directory remote get-url origin
    if ($LASTEXITCODE -ne 0 -or $actualRemote.TrimEnd('/') -ne $Remote.TrimEnd('/')) { throw "Unexpected remote: $Directory" }
}
function Assert-RebootPatch {
    param([string]$Directory, [string]$PatchPath)
    & git -C $Directory apply --reverse --check $PatchPath 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Required build patch is not applied: $PatchPath. Run restore-reboot-stack.ps1." }
}
function Get-RebootNativeTools {
    $lock = Get-RebootLock
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere)) { throw 'VS 2022 with Desktop C++ is required.' }
    $vs = & $vswhere -latest -version '[17.0,18.0)' -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $vs) { throw 'VS 2022 Desktop C++ installation not found.' }
    if (-not (Test-Path -LiteralPath (Join-Path $vs ('VC/Tools/MSVC/' + $lock.nativeTools.vcToolsVersion)))) {
        throw "Install the pinned MSVC $($lock.nativeTools.vcToolsVersion) through Visual Studio Installer. No automatic toolchain update."
    }
    $sdkInclude = Join-Path ${env:ProgramFiles(x86)} ('Windows Kits/10/Include/' + $lock.nativeTools.windowsSdkVersion)
    if (-not (Test-Path -LiteralPath $sdkInclude)) { throw "Windows SDK $($lock.nativeTools.windowsSdkVersion) is required." }
    [pscustomobject]@{
        msbuild = Join-Path $vs 'MSBuild/Current/Bin/MSBuild.exe'
        cmake = Join-Path $vs 'Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe'
    }
}
