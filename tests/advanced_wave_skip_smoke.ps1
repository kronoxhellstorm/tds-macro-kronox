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
    'IniWrite(data.advancedAutoSkip, path, "Settings", "advancedAutoSkip")',
    'IniWrite(data.advancedSkipWaves, path, "Settings", "advancedSkipWaves")',
    'AdvancedSkipWaveSet := parsedAdvancedWaves.waves',
    'ConfirmAutoSkipWave()',
    'AdvancedPendingSkipWave := detectedWave',
    'ExtractWaveNumberFromHudText(waveText)',
    '{x: 0.00, y: 0.00, w: 0.74, h: 0.27}'
)) {
    if ($source.IndexOf($marker, [System.StringComparison]::Ordinal) -lt 0) {
        throw "Missing advanced wave-skip marker: $marker"
    }
}

$clickAt = $source.IndexOf('Click(res.x, res.y)', [System.StringComparison]::Ordinal)
$confirmAt = $source.IndexOf('ConfirmAutoSkipWave()', $clickAt, [System.StringComparison]::Ordinal)
if ($clickAt -lt 0 -or $confirmAt -lt $clickAt) {
    throw 'Advanced wave skip is marked complete before its click is sent.'
}

$wavePattern = '(?i)\bW[A4][VY][E3]?\s*[:\-]?\s*(\d{1,3})(?:\s*/\s*\d{1,3})?\b'
foreach ($sample in @('Wave: 5 / 40', 'W4V3 35/40', "Base Health 300/300`nWAVE 12")) {
    if ($sample -notmatch $wavePattern) { throw "HUD wave sample was not recognized: $sample" }
}
foreach ($sample in @('Time Left 00:42', 'Base Health 300/300', 'Wave Rewards $357')) {
    if ($sample -match $wavePattern) { throw "Non-wave HUD sample was incorrectly recognized: $sample" }
}

Write-Output 'PASS: editor keys, runtime selected-wave set, wide HUD OCR fallback, and post-click retry semantics are present.'
