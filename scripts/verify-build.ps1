[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Path, [switch]$Json, [switch]$MetadataOnly)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$item = Get-Item -LiteralPath $Path
$archive = $null
$binary = $null
$result = [ordered]@{ path=$item.FullName; kind=''; bytes=$null; sha256=$null; entries=0; uncompressedBytes=$null; root=''; structure=[ordered]@{}; versionEvidence=@(); identityConfirmed=$false; limitations=@() }
try {
    if ($item.PSIsContainer) {
        $result.kind = 'directory'
        $root = $item.FullName
        if (-not (Test-Path -LiteralPath (Join-Path $root 'FortniteGame'))) {
            $children = @(Get-ChildItem -LiteralPath $root -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'FortniteGame') })
            if ($children.Count -eq 1) { $root = $children[0].FullName }
        }
        $result.root = $root
        $result.structure.Engine = Test-Path -LiteralPath (Join-Path $root 'Engine') -PathType Container
        $result.structure.FortniteGame = Test-Path -LiteralPath (Join-Path $root 'FortniteGame') -PathType Container
        $result.structure.Win64 = Test-Path -LiteralPath (Join-Path $root 'FortniteGame/Binaries/Win64') -PathType Container
        $exePath = Join-Path $root 'FortniteGame/Binaries/Win64/FortniteClient-Win64-Shipping.exe'
        $result.structure.Shipping = Test-Path -LiteralPath $exePath -PathType Leaf
        if ($result.structure.Shipping) {
            if ((Get-Item -LiteralPath $exePath).Length -gt 512MB) { throw 'Shipping executable exceeds the 512 MiB read limit.' }
            $binary = [IO.File]::ReadAllBytes($exePath)
        }
        $result.limitations += 'Directory validation checks structure and Shipping strings; no archive SHA-256 is calculated for a directory.'
    } else {
        if ($item.Extension -ne '.zip') { throw 'Expected a ZIP archive or an extracted build directory.' }
        $result.kind = 'zip'
        $result.bytes = $item.Length
        $archive = [IO.Compression.ZipFile]::OpenRead($item.FullName)
        $result.entries = $archive.Entries.Count
        $result.uncompressedBytes = [long]($archive.Entries | Measure-Object Length -Sum).Sum
        $names = @($archive.Entries | ForEach-Object { $_.FullName.Replace('\','/') })
        $shipping = @($archive.Entries | Where-Object { $_.FullName.Replace('\','/') -match '(^|/)FortniteGame/Binaries/Win64/FortniteClient-Win64-Shipping\.exe$' })
        if ($shipping.Count -ne 1) { throw 'Expected exactly one Shipping executable in the archive.' }
        $root = $shipping[0].FullName.Replace('\','/') -replace 'FortniteGame/Binaries/Win64/FortniteClient-Win64-Shipping\.exe$', ''
        $result.root = $root
        $result.structure.Engine = @($names | Where-Object { $_.StartsWith($root + 'Engine/') }).Count -gt 0
        $result.structure.FortniteGame = @($names | Where-Object { $_.StartsWith($root + 'FortniteGame/') }).Count -gt 0
        $result.structure.Win64 = @($names | Where-Object { $_.StartsWith($root + 'FortniteGame/Binaries/Win64/') }).Count -gt 0
        $result.structure.Shipping = $shipping[0].Length -gt 0
        if ($shipping[0].Length -gt 512MB) { throw 'Shipping executable exceeds the 512 MiB read limit.' }
        $stream = $shipping[0].Open()
        $memory = New-Object IO.MemoryStream
        try { $stream.CopyTo($memory); $binary = $memory.ToArray() } finally { $stream.Dispose(); $memory.Dispose() }
        if (-not $MetadataOnly) {
            $result.sha256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        } else {
            $result.limitations += 'MetadataOnly was requested; SHA-256 was not recalculated in this run.'
        }
        $result.topLevel = @($names | ForEach-Object { $_.Split('/')[0] } | Sort-Object -Unique)
        $result.limitations += 'ZIP directory and Shipping payload are readable. This is not a full CRC test of every archive member.'
    }
    if ($binary) {
        foreach ($encoding in @([Text.Encoding]::ASCII, [Text.Encoding]::Unicode)) {
            $strings = $encoding.GetString($binary)
            $matchesFound = [regex]::Matches($strings, '\+\+Fortnite\+Release-13\.40(?:[^\x00\r\n]{0,100})|13\.40-CL-14113327')
            foreach ($match in $matchesFound) { $result.versionEvidence += $match.Value }
            $strings = $null
        }
        $result.versionEvidence = @($result.versionEvidence | Sort-Object -Unique)
        $result.identityConfirmed = @($result.versionEvidence | Where-Object { $_ -match '13\.40' -and $_ -match '14113327' }).Count -gt 0
    }
    $result.limitations += 'Embedded strings and structural checks do not prove authenticity or provenance; no trusted official reference hash is available.'
    $ok = $result.structure.Engine -and $result.structure.FortniteGame -and $result.structure.Win64 -and $result.structure.Shipping
    $result.structure.ExpectedBuildStructure = [bool]$ok
    if ($Json) { $result | ConvertTo-Json -Depth 6 } else {
        foreach ($pair in @(@('Engine','Engine'),@('FortniteGame','FortniteGame'),@('Win64','Win64 binaries'),@('Shipping','Shipping executable'),@('ExpectedBuildStructure','Expected build structure'))) {
            $label = if ($result.structure[$pair[0]]) { 'OK' } else { 'FAIL' }
            Write-Output ('[{0}] {1}' -f $label,$pair[1])
        }
        if ($result.sha256) { Write-Output ('SHA-256: ' + $result.sha256); Write-Output ('Bytes: ' + $result.bytes) }
        if ($result.identityConfirmed) { Write-Output ('[OK] Embedded identity: ' + ($result.versionEvidence -join '; ')) } else { Write-Output '[UNCONFIRMED] 13.40 / CL 14113327 could not be confirmed from embedded strings.' }
        $result.limitations | ForEach-Object { Write-Output ('[NOTE] ' + $_) }
    }
    if (-not $ok) { throw 'Build structure validation failed.' }
} finally { if ($archive) { $archive.Dispose() } }
