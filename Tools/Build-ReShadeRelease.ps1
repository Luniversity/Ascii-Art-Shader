[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$')]
    [string] $Version
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..')
)
$distributionRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $repositoryRoot 'Dist')
)
$packageName = "JackYe-ASCII-Shader-v$Version"
$packageRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $distributionRoot $packageName)
)
$archivePath = [System.IO.Path]::GetFullPath(
    (Join-Path $distributionRoot "$packageName.zip")
)

if (
    [System.IO.Path]::GetDirectoryName($packageRoot) -ne
    $distributionRoot
) {
    throw "Package path escaped the distribution folder: $packageRoot"
}

$sourceFiles = @(
    @{
        Source = 'ReShade/README.md'
        Destination = 'README.md'
    },
    @{
        Source = 'LICENSE'
        Destination = 'LICENSE.txt'
    },
    @{
        Source = 'ThirdParty/AcerolaFX/LICENSE.md'
        Destination = 'AcerolaFX-LICENSE.md'
    },
    @{
        Source = 'ReShade/Shaders/JackYeAscii.fx'
        Destination = 'reshade-shaders/Shaders/JackYeAscii.fx'
    },
    @{
        Source = 'ReShade/Textures/JackYeAscii_GlyphAtlasStandard.png'
        Destination =
            'reshade-shaders/Textures/JackYeAscii_GlyphAtlasStandard.png'
    },
    @{
        Source = 'ReShade/Textures/JackYeAscii_GlyphAtlasExtended.png'
        Destination =
            'reshade-shaders/Textures/JackYeAscii_GlyphAtlasExtended.png'
    },
    @{
        Source = 'ReShade/Textures/JackYeAscii_EdgeAtlas.png'
        Destination = 'reshade-shaders/Textures/JackYeAscii_EdgeAtlas.png'
    }
)

foreach ($file in $sourceFiles) {
    $sourcePath = Join-Path $repositoryRoot $file.Source
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Required release file is missing: $sourcePath"
    }
}

New-Item -ItemType Directory -Path $distributionRoot -Force | Out-Null

if (Test-Path -LiteralPath $packageRoot) {
    Remove-Item -LiteralPath $packageRoot -Recurse -Force
}

if (Test-Path -LiteralPath $archivePath) {
    Remove-Item -LiteralPath $archivePath -Force
}

New-Item -ItemType Directory -Path $packageRoot | Out-Null

foreach ($file in $sourceFiles) {
    $sourcePath = Join-Path $repositoryRoot $file.Source
    $destinationPath = Join-Path $packageRoot $file.Destination
    $destinationDirectory = Split-Path -Parent $destinationPath

    New-Item -ItemType Directory -Path $destinationDirectory -Force |
        Out-Null

    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory(
    $packageRoot,
    $archivePath,
    [System.IO.Compression.CompressionLevel]::Optimal,
    $false
)

$archiveHash = Get-FileHash -LiteralPath $archivePath -Algorithm SHA256

Write-Output "Release directory: $packageRoot"
Write-Output "Release archive:   $archivePath"
Write-Output "SHA-256:           $($archiveHash.Hash)"
