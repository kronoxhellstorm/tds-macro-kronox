[CmdletBinding()]
param(
    [string]$ProjectRoot = ''
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}

$main = Join-Path $ProjectRoot 'Main.ahk'
if (-not (Test-Path -LiteralPath $main)) { throw "Missing Main.ahk at $main" }
$source = Get-Content -LiteralPath $main -Raw

foreach ($marker in @(
    'OffsetSettingsContentAfter(Tab5_Section3, 56)',
    'Set any limit to 0 for unlimited',
    'x520 y210 w150 Hidden", "Legacy image mode"',
    'x520 y238 w65 h20 Hidden BackgroundTrans", "Timescale:"',
    'x310 y264 w94 h20 Hidden BackgroundTrans", "Upgrade delay:"',
    'x310 y292 w82 h20 Hidden BackgroundTrans", "Mouse Speed:"'
)) {
    if ($source.IndexOf($marker, [System.StringComparison]::Ordinal) -lt 0) {
        throw "Missing settings-layout marker: $marker"
    }
}

Write-Output 'PASS: macro settings rows are separated and later scroll content is offset below the tuning controls.'
