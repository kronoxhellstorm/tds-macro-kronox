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
    'EnsureKronoxDiscordBotRunning',
    'StopOrphanedKronoxDiscordGateways',
    'ProcessKronoxDiscordCommands',
    'KronoxBotSendScreenshot',
    'KronoxQueueRemoteStrategySwitch',
    'KronoxQueueRemoteSafeStop',
    'KronoxQueueRemoteTimeScale',
    'KronoxQueueRemoteModifiers',
    'KronoxBotBestMessage',
    'KronoxBotSendChannel(text, title := "Kronox Remote Control")',
    '"embeds"',
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
if ($gatewaySource.IndexOf("Invoke-DiscordBotApi -Method 'PUT'", [System.StringComparison]::Ordinal) -lt 0) {
    throw 'Discord gateway does not bulk-register slash commands.'
}
if ($gatewaySource.IndexOf('Discord rate limit on', [System.StringComparison]::Ordinal) -lt 0) {
    throw 'Discord gateway does not back off after HTTP 429 responses.'
}
foreach ($marker in @("title = 'Kronox Command Queue'", "name = 'Watching over Kronox Edition macro'", 'type = 3')) {
    if ($gatewaySource.IndexOf($marker, [System.StringComparison]::Ordinal) -lt 0) {
        throw "Discord gateway is missing presentation marker: $marker"
    }
}

Write-Output 'PASS: Discord remote bot parses, uses branded embeds and Watching presence, bulk-registers commands, backs off on rate limits, and is lifecycle-monitored by Main.ahk.'
