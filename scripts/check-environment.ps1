[CmdletBinding()]
param([switch]$Json)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$rows = @()
foreach ($name in @('git','node','npm','dotnet','cmake','python')) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    $rows += [pscustomobject]@{dependency=$name; found=[bool]$command; path=if($command){$command.Source}else{''}}
}
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$vs = if(Test-Path -LiteralPath $vswhere){ & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath }else{''}
foreach ($pair in @(@('MSBuild','MSBuild/Current/Bin/MSBuild.exe'),@('MSVC 14.44.35207','VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64/cl.exe'),@('CMake bundled','Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe'))) {
    $toolPath = if($vs){Join-Path $vs $pair[1]}else{''}
    $rows += [pscustomobject]@{dependency=$pair[0]; found=[bool]($toolPath -and (Test-Path -LiteralPath $toolPath)); path=$toolPath}
}
$sdk = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits/10/Include/10.0.26100.0/um/Windows.h'
$rows += [pscustomobject]@{dependency='Windows SDK 10.0.26100.0';found=Test-Path -LiteralPath $sdk;path=$sdk}
if($Json){$rows | ConvertTo-Json}else{$rows | Format-Table -AutoSize; if(Get-Command node -ErrorAction SilentlyContinue){node --version}; if(Get-Command npm -ErrorAction SilentlyContinue){npm --version}}
$missing = @($rows | Where-Object { $_.dependency -in @('git','node','npm','MSBuild','MSVC 14.44.35207','Windows SDK 10.0.26100.0') -and -not $_.found })
if($missing.Count){throw ('Required dependencies missing: ' + ($missing.dependency -join ', '))}
