[CmdletBinding()]
param(
    [string]$ProjectRoot = ''
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}
$main = Join-Path $ProjectRoot 'Main.ahk'
$sidecar = Join-Path $ProjectRoot 'submacros\kronox_discord_gateway.ps1'

if (-not (Test-Path -LiteralPath $main)) { throw "Missing Main.ahk at $main" }
if (-not (Test-Path -LiteralPath $sidecar)) { throw "Missing Discord gateway sidecar at $sidecar" }

[void][scriptblock]::Create((Get-Content -LiteralPath $sidecar -Raw))
$source = Get-Content -LiteralPath $main -Raw
foreach ($marker in @(
    'StartKronoxDiscordBot',
    'ProcessKronoxDiscordCommands',
    'KronoxBotSendScreenshot',
    'KronoxQueueRemoteStrategySwitch',
    'KronoxQueueRemoteSafeStop',
    'KronoxQueueRemoteTimeScale',
    'KronoxQueueRemoteModifiers',
    'KronoxBotBestMessage',
    'Kronox-Discord-Bot.ini'
)) {
    if ($source.IndexOf($marker, [System.StringComparison]::Ordinal) -lt 0) {
        throw "Missing Discord remote bot marker: $marker"
    }
}
$gatewaySource = Get-Content -LiteralPath $sidecar -Raw
foreach ($command in @('switch', 'safe-stop', 'timescale', 'modifiers', 'loadout', 'best')) {
    if ($gatewaySource.IndexOf("name = '$command'", [System.StringComparison]::Ordinal) -lt 0) {
        throw "Discord gateway does not register the /$command command."
    }
}

Write-Output 'PASS: Discord remote bot sidecar parses and its Main.ahk integration markers are present.'
