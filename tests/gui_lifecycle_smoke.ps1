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

$hoverStart = $source.IndexOf('Hoverwatchdog(*)', [System.StringComparison]::Ordinal)
$hoverEnd = $source.IndexOf('HideAllTabContent()', $hoverStart, [System.StringComparison]::Ordinal)
if ($hoverStart -lt 0 -or $hoverEnd -lt 0) { throw 'Could not isolate Hoverwatchdog.' }
$hoverSource = $source.Substring($hoverStart, $hoverEnd - $hoverStart)
foreach ($marker in @('hChild := 0', 'try hChild := ChildGui.Hwnd', 'catch')) {
    if ($hoverSource.IndexOf($marker, [System.StringComparison]::Ordinal) -lt 0) {
        throw "Hoverwatchdog is missing destroyed-child protection: $marker"
    }
}

Write-Output 'PASS: hover hit-testing tolerates the strategy-library child window being destroyed and rebuilt.'
