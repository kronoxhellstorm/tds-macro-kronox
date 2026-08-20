[CmdletBinding()]
param(
    [string]$ProjectRoot = ''
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}

$main = Join-Path $ProjectRoot 'Main.ahk'
$intro = Join-Path $ProjectRoot 'Resources\intro.gif'
if (-not (Test-Path -LiteralPath $main)) { throw "Missing Main.ahk at $main" }
if (-not (Test-Path -LiteralPath $intro)) { throw "Missing startup GIF at $intro" }

$source = Get-Content -LiteralPath $main -Raw
foreach ($marker in @(
    'ShowStartupSplash()',
    'FinishStartupSplash()',
    'FinishStartupSplash(minimumVisibleMs := 3000)',
    'animation:bootProgress 3s',
    'Shell.Explorer',
    'Kronox Edition is starting'
)) {
    if ($source.IndexOf($marker, [System.StringComparison]::Ordinal) -lt 0) {
        throw "Missing startup splash marker: $marker"
    }
}

Add-Type -AssemblyName System.Drawing
$image = [System.Drawing.Image]::FromFile($intro)
try {
    $frames = $image.GetFrameCount([System.Drawing.Imaging.FrameDimension]::Time)
    if ($image.Width -ne 784 -or $image.Height -ne 442) {
        throw "Unexpected startup GIF dimensions: $($image.Width)x$($image.Height)"
    }
    if ($frames -le 1) { throw 'Startup asset is not an animated GIF.' }
} finally {
    $image.Dispose()
}

Write-Output "PASS: centered startup splash uses a 3-second branded progress sequence and a 784x442 animated GIF ($frames frames)."
