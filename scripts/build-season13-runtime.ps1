[CmdletBinding()]
param([ValidateSet('Debug','RelWithDebInfo','Release')][string]$Configuration='Debug',[switch]$Test)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$vswhere=Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$visualStudio=& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if(-not $visualStudio){throw 'MSVC x64 installation missing.'}
$cmake=Join-Path $visualStudio 'Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe'
$source=Join-Path $projectRoot 'runtime-mod'
$output=Join-Path $source 'out'
& $cmake -S $source -B $output -G 'Visual Studio 17 2022' -A x64
if($LASTEXITCODE -ne 0){throw 'CMake configure failed.'}
& $cmake --build $output --config $Configuration --parallel 2
if($LASTEXITCODE -ne 0){throw 'Runtime build failed.'}
if($Test){
  $ctest=Join-Path (Split-Path $cmake) 'ctest.exe'
  & $ctest --test-dir $output -C $Configuration --output-on-failure
  if($LASTEXITCODE -ne 0){throw 'Offline tests failed.'}
}
Write-Output "[OK] $Configuration compiled outside Fortnite. No game launch/attach/injection performed."
