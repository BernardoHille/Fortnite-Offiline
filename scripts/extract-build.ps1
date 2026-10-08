[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Path, [Parameter(Mandatory=$true)][string]$Destination, [switch]$Approved)
$ErrorActionPreference = 'Stop'
if (-not $Approved) { throw 'Extraction consumes tens of GB. Obtain user authorization, then pass -Approved.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\') + '\'
$target = [IO.Path]::GetFullPath($Destination).TrimEnd('\') + '\'
if ($target.StartsWith($repo,[StringComparison]::OrdinalIgnoreCase) -or $target.TrimEnd('\') -eq $repo.TrimEnd('\')) { throw 'Build destination must be outside the Git repository.' }
if (Test-Path -LiteralPath $target) { throw 'Use a new destination directory to avoid overwriting any existing files.' }
$ancestor = [IO.Path]::GetDirectoryName($target.TrimEnd('\'))
while ($ancestor) {
    if (Test-Path -LiteralPath $ancestor) {
        $ancestorItem = Get-Item -LiteralPath $ancestor -Force
        if ($ancestorItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Destination ancestors must not contain junctions or symbolic links.' }
    }
    $nextAncestor = [IO.Path]::GetDirectoryName($ancestor)
    if ($nextAncestor -eq $ancestor) { break }
    $ancestor = $nextAncestor
}
$archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $Path).Path)
try {
    $total = [long]($archive.Entries | Measure-Object Length -Sum).Sum
    $drive = New-Object IO.DriveInfo ([IO.Path]::GetPathRoot($target))
    if ($drive.AvailableFreeSpace -lt ($total + 10GB)) { throw 'Insufficient free space (10 GiB margin required).' }
    foreach ($entry in $archive.Entries) {
        $name = $entry.FullName.Replace('/','\')
        $resolved = [IO.Path]::GetFullPath((Join-Path $target $name))
        if (-not $resolved.StartsWith($target,[StringComparison]::OrdinalIgnoreCase) -or $name.Contains(':')) { throw ('Unsafe ZIP path: ' + $entry.FullName) }
        $unixType = ($entry.ExternalAttributes -shr 16) -band 0xF000
        if ($unixType -eq 0xA000) { throw 'ZIP symbolic links are not accepted.' }
    }
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    [long]$done = 0
    foreach ($entry in $archive.Entries) {
        $resolved = [IO.Path]::GetFullPath((Join-Path $target $entry.FullName.Replace('/','\')))
        if ($entry.FullName.EndsWith('/')) { New-Item -ItemType Directory -Path $resolved -Force | Out-Null; continue }
        New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($resolved)) -Force | Out-Null
        $inputStream = $entry.Open()
        $outputStream = [IO.File]::Open($resolved,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write)
        try { $inputStream.CopyTo($outputStream) } finally { $outputStream.Dispose(); $inputStream.Dispose() }
        if ((Get-Item -LiteralPath $resolved).Length -ne $entry.Length) { throw ('Extracted length mismatch: ' + $entry.FullName) }
        $done += $entry.Length
        Write-Progress -Activity 'Extracting owned build outside Git' -Status $entry.FullName -PercentComplete ([int](100.0*$done/[Math]::Max([long]1,$total)))
    }
    Write-Progress -Activity 'Extracting owned build outside Git' -Completed
    Write-Output ('Extracted bytes: ' + $done)
} finally { $archive.Dispose() }
& (Join-Path $PSScriptRoot 'verify-build.ps1') -Path $target
