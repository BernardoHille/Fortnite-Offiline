[CmdletBinding()]
param([string]$Toolset='v143',[string]$WindowsSdk='10.0.26100.0',[string]$CompilerVersion='14.44.35207')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
if (-not (Test-Path -LiteralPath $vswhere)) { throw 'Visual Studio Installer/vswhere not found.' }
$vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vs) { throw 'Install Desktop development with C++ in Visual Studio.' }
$msbuild = Join-Path $vs 'MSBuild/Current/Bin/MSBuild.exe'
$solution = Join-Path $root 'gameserver/vendor/FortExternalServer/FortExternalServer.sln'
if (-not (Test-Path -LiteralPath $solution)) { throw 'Gameserver source missing. Run scripts/restore-stack.ps1.' }
$log = Join-Path $root 'logs/gameserver-build.log'
& $msbuild $solution /m:2 /t:Build /p:Configuration=Release /p:Platform=x64 "/p:FortExternalServerToolset=$Toolset" "/p:WindowsTargetPlatformVersion=$WindowsSdk" "/p:VCToolsVersion=$CompilerVersion" /nologo /verbosity:minimal *> $log
$code = $LASTEXITCODE
Get-Content -LiteralPath $log -Tail 45
if ($code -ne 0) { throw "Gameserver compilation failed (exit $code). See logs/gameserver-build.log." }
Write-Output '[OK] Gameserver compiled. Binary was not executed or copied to the Fortnite build.'
