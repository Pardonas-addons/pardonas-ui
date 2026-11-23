# Fetches LibPardona-1.0 into Libs\lib-pardona for local testing.
# The packager does the same via the externals in .pkgmeta.
#
# Source, in this order:
#   1. sibling repository ..\lib-pardona (local development)
#   2. git clone --depth 1 https://github.com/Pardonas-addons/lib-pardona
#
# Repository-only files (.git, .github, media, lint/packager configs and all *.md files
# in the library root) are skipped.
# Safe to run repeatedly: Libs\lib-pardona is replaced completely on every run.

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$libsDir  = Join-Path $repoRoot 'Libs'
$target   = Join-Path $libsDir 'lib-pardona'
$sibling  = Join-Path (Split-Path -Parent $repoRoot) 'lib-pardona'
$url      = 'https://github.com/Pardonas-addons/lib-pardona'
$skip     = @('.git', '.github', '.gitignore', '.luacheckrc', '.pkgmeta', '.release', 'media')

function Test-Skipped($item) {
    if ($skip -contains $item.Name) { return $true }
    return (-not $item.PSIsContainer) -and ($item.Extension -eq '.md')
}

Write-Host "LibPardona-1.0 -> $target"

if (-not (Test-Path $libsDir)) {
    New-Item -ItemType Directory -Path $libsDir | Out-Null
}
if (Test-Path $target) {
    Write-Host '  Removing previous copy'
    Remove-Item -Recurse -Force $target
}

if (Test-Path (Join-Path $sibling 'lib-pardona.xml')) {
    Write-Host "  Copying from sibling repository $sibling"
    New-Item -ItemType Directory -Path $target | Out-Null
    Get-ChildItem -Path $sibling -Force |
        Where-Object { -not (Test-Skipped $_) } |
        ForEach-Object { Copy-Item -Path $_.FullName -Destination $target -Recurse -Force }
} else {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Sibling repository not found and git is not available.'
    }
    Write-Host "  Sibling repository not found, cloning $url"
    & git clone --quiet --depth 1 $url $target
    if ($LASTEXITCODE -ne 0) { throw "git clone failed (exit code $LASTEXITCODE)." }
    Get-ChildItem -Path $target -Force |
        Where-Object { Test-Skipped $_ } |
        ForEach-Object { Remove-Item -Recurse -Force $_.FullName }
}

if (-not (Test-Path (Join-Path $target 'lib-pardona.xml'))) {
    throw "lib-pardona.xml missing in $target."
}

$files = @(Get-ChildItem -Path $target -Recurse -File)
Write-Host ("  Done: {0} files" -f $files.Count)
foreach ($file in $files) {
    Write-Host ('    ' + $file.FullName.Substring($target.Length + 1))
}
