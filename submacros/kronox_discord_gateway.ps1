<###
Kronox Edition local Discord slash-command gateway.

This sidecar deliberately keeps Discord networking outside of Main.ahk. It has
no macro input code: it acknowledges an owner-approved slash command and
writes it to a local queue for Main.ahk to handle safely.
###>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SettingsPath,
    [Parameter(Mandatory = $true)][string]$CommandQueuePath,
    [Parameter(Mandatory = $true)][string]$LogPath
)

$ErrorActionPreference = 'Stop'
$ApiBase = 'https://discord.com/api/v10'
$CommandSchema = 'kronox-slash-v3'
$Cancellation = [System.Threading.CancellationToken]::None

function Write-Log([string]$Message, [string]$Level = 'INFO') {
    try {
        $dir = Split-Path -Parent $LogPath
        if ($dir -and -not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $safe = $Message.Replace("`r", '').Replace("`n", ' | ')
        Add-Content -LiteralPath $LogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] [DISCORD] $safe" -Encoding utf8
    } catch {
        # The bot must never fail solely because diagnostic logging is unavailable.
    }
}

function Read-IniValue([string]$Section, [string]$Key, [string]$Default = '') {
    if (-not (Test-Path -LiteralPath $SettingsPath)) { return $Default }
    $inSection = $false
    foreach ($line in Get-Content -LiteralPath $SettingsPath -ErrorAction Stop) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^\[(.+)\]$') {
            $inSection = ($Matches[1] -eq $Section)
            continue
        }
        if (-not $inSection -or $trimmed.StartsWith(';') -or $trimmed.StartsWith('#')) { continue }
        if ($trimmed -match ('^' + [regex]::Escape($Key) + '\s*=(.*)$')) {
            return $Matches[1].Trim()
        }
    }
    return $Default
}

$Enabled = (Read-IniValue 'Settings' 'Enabled' '0') -eq '1'
$Token = Read-IniValue 'Token' 'BotToken'
$ApplicationId = Read-IniValue 'Settings' 'ApplicationID'
$ChannelId = Read-IniValue 'Settings' 'ChannelID'
$GuildId = Read-IniValue 'Settings' 'GuildID'
$OwnerId = Read-IniValue 'Settings' 'OwnerUserID'

if (-not $Enabled) { exit 0 }
if ([string]::IsNullOrWhiteSpace($Token) -or [string]::IsNullOrWhiteSpace($ApplicationId) -or [string]::IsNullOrWhiteSpace($ChannelId) -or [string]::IsNullOrWhiteSpace($OwnerId)) {
    Write-Log 'Disabled because the slash-command configuration is incomplete.' 'WARN'
    exit 1
}
if (-not (Test-Path -LiteralPath $CommandQueuePath)) {
    New-Item -ItemType Directory -Path $CommandQueuePath -Force | Out-Null
}

function Invoke-DiscordBotApi([string]$Method, [string]$Path, $Body = $null) {
    $maxAttempts = 6
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $parameters = @{
            Uri = "$ApiBase/$Path"
            Method = $Method
            Headers = @{ Authorization = "Bot $Token"; 'User-Agent' = 'KronoxUltimateMacro/1.3.3' }
            UseBasicParsing = $true
        }
        if ($null -ne $Body) {
            $parameters['ContentType'] = 'application/json'
            $parameters['Body'] = $Body
        }

        try {
            return Invoke-RestMethod @parameters
        } catch {
            $statusCode = 0
            try { $statusCode = [int]$_.Exception.Response.StatusCode } catch {}
            if ($statusCode -ne 429 -or $attempt -ge $maxAttempts) { throw }

            $retryAfter = 5.0
            try {
                $errorPayload = $_.ErrorDetails.Message | ConvertFrom-Json
                if ($null -ne $errorPayload.retry_after) { $retryAfter = [double]$errorPayload.retry_after }
            } catch {}
            $retryAfter = [Math]::Max(1.0, [Math]::Min(60.0, $retryAfter))
            Write-Log "Discord rate limit on $Method $Path; retrying in $retryAfter seconds (attempt $attempt/$maxAttempts)." 'WARN'
            Start-Sleep -Milliseconds ([int][Math]::Ceiling($retryAfter * 1000) + 250)
        }
    }
    throw "Discord API request exhausted its retry budget: $Method $Path"
}

function Register-KronoxSlashCommands {
    # A stamp avoids consuming Discord's command-create quota on every macro
    # reload. Saving the bot configuration removes it and forces a refresh.
    $stampPath = Join-Path $CommandQueuePath '.registration-v1'
    $scope = if ($GuildId) { "guild:$GuildId" } else { 'global' }
    $stamp = "$CommandSchema|$ApplicationId|$scope"
    if ((Test-Path -LiteralPath $stampPath) -and ((Get-Content -LiteralPath $stampPath -Raw).Trim() -eq $stamp)) {
        Write-Log "Slash commands already registered for $scope."
        return
    }

    $endpoint = if ($GuildId) {
        "applications/$ApplicationId/guilds/$GuildId/commands"
    } else {
        "applications/$ApplicationId/commands"
    }
    $commands = @(
        @{ name = 'help';       description = 'Show Kronox macro remote commands'; type = 1 },
        @{ name = 'status';     description = 'Show macro state and run stats'; type = 1 },
        @{ name = 'health';     description = 'Show macro phase and recovery health'; type = 1 },
        @{ name = 'screenshot'; description = 'Capture the current macro desktop view'; type = 1 },
        @{ name = 'start';      description = 'Start the selected strategy'; type = 1 },
        @{ name = 'stop';       description = 'Safely stop the active macro'; type = 1 },
        @{ name = 'safe-stop';  description = 'Finish the current match, then stop'; type = 1 },
        @{ name = 'queue';      description = 'Show pending remote actions'; type = 1 },
        @{ name = 'loadout';    description = 'Show the selected strategy loadout'; type = 1 },
        @{ name = 'best';       description = 'Show best recorded efficiency'; type = 1 },
        @{ name = 'switch'; description = 'Queue a safe swap to a configured strategy'; type = 1; options = @(
            @{ name = 'slot'; description = 'Configured Main-tab strategy slot'; type = 4; required = $true; choices = @(
                @{ name = 'Strategy 1'; value = 1 },
                @{ name = 'Strategy 2'; value = 2 }
            ) }
        ) },
        @{ name = 'timescale'; description = 'Temporarily set next-match timescale'; type = 1; options = @(
            @{ name = 'mode'; description = 'Applies only to this macro session'; type = 3; required = $true; choices = @(
                @{ name = 'Off (1x)'; value = 'off' },
                @{ name = '1.5x'; value = '1.5x' },
                @{ name = '2x'; value = '2x' }
            ) }
        ) },
        @{ name = 'modifiers'; description = 'Temporarily edit next-match modifiers'; type = 1; options = @(
            @{ name = 'action'; description = 'How to change the strategy modifiers'; type = 3; required = $true; choices = @(
                @{ name = 'Set exact list'; value = 'set' },
                @{ name = 'Add to strategy'; value = 'add' },
                @{ name = 'Remove from strategy'; value = 'remove' },
                @{ name = 'Use no modifiers'; value = 'clear' },
                @{ name = 'Restore strategy defaults'; value = 'reset' }
            ) },
            @{ name = 'names'; description = 'Comma-separated, e.g. Exploding, Speedy'; type = 3; required = $false }
        ) }
    )
    # Bulk overwrite is one idempotent request. Registering every command with
    # a separate POST exhausted Discord's application-command rate limit and
    # made the gateway exit before it could ever appear online.
    Invoke-DiscordBotApi -Method 'PUT' -Path $endpoint -Body ($commands | ConvertTo-Json -Depth 6 -Compress) | Out-Null
    [System.IO.File]::WriteAllText($stampPath, $stamp + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
    Write-Log "Registered $($commands.Count) slash commands for $scope."
}

function Send-InteractionReply($Interaction, [string]$Content) {
    $body = @{
        type = 4
        data = @{
            flags = 64
            embeds = @(@{
                title = 'Kronox Command Queue'
                description = $Content
                color = 15674157
                footer = @{ text = "Ultimate Macro Kronox's Edition - owner-only control" }
            })
        }
    } | ConvertTo-Json -Depth 6 -Compress
    # Interaction callbacks authenticate with the one-time interaction token;
    # no bot credential is included in the request.
    Invoke-RestMethod -Method Post -Uri "$ApiBase/interactions/$($Interaction.id)/$($Interaction.token)/callback" -ContentType 'application/json' -Body $body -UseBasicParsing | Out-Null
}

function ConvertTo-QueueField([string]$Value) {
    return ([string]$Value).Replace('|', '').Replace("`r", ' ').Replace("`n", ' ').Trim()
}

function Queue-KronoxCommand($Interaction, [string]$Action, [string]$Argument = '', [string]$Argument2 = '') {
    $id = [string]$Interaction.id
    if ([string]::IsNullOrWhiteSpace($id)) { throw 'Discord interaction had no id.' }
    $temporary = Join-Path $CommandQueuePath (".$id.tmp")
    $target = Join-Path $CommandQueuePath ("$id.cmd")
    if (Test-Path -LiteralPath $target) { return }
    $record = "$id|$(ConvertTo-QueueField $Action)|$(ConvertTo-QueueField $Argument)|$(ConvertTo-QueueField $Argument2)"
    [System.IO.File]::WriteAllText($temporary, $record, [System.Text.UTF8Encoding]::new($false))
    try {
        [System.IO.File]::Move($temporary, $target)
    } catch {
        if (-not (Test-Path -LiteralPath $target)) { throw }
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue }
    }
}

function Send-GatewayPayload($Socket, $Payload) {
    $json = $Payload | ConvertTo-Json -Depth 8 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $segment = [System.ArraySegment[byte]]::new($bytes)
    $Socket.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $Cancellation).GetAwaiter().GetResult()
}

function Receive-CompleteGatewayMessage($Socket, $InitialTask) {
    $buffer = [byte[]]::new(65536)
    $segment = [System.ArraySegment[byte]]::new($buffer)
    $result = $InitialTask.GetAwaiter().GetResult()
    if ($result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) { throw 'Discord Gateway closed the socket.' }
    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.Append([System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count))
    while (-not $result.EndOfMessage) {
        $result = $Socket.ReceiveAsync($segment, $Cancellation).GetAwaiter().GetResult()
        if ($result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) { throw 'Discord Gateway closed the socket.' }
        [void]$builder.Append([System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count))
    }
    return $builder.ToString()
}

function Handle-GatewayPayload($Payload, [ref]$LastSequence) {
    if ($null -ne $Payload.s) { $LastSequence.Value = $Payload.s }
    if ($Payload.op -ne 0 -or $Payload.t -ne 'INTERACTION_CREATE') { return }
    $interaction = $Payload.d
    if ($interaction.type -ne 2) { return }

    $callerId = ''
    if ($interaction.member -and $interaction.member.user) { $callerId = [string]$interaction.member.user.id }
    elseif ($interaction.user) { $callerId = [string]$interaction.user.id }

    if ($callerId -ne $OwnerId) {
        Send-InteractionReply $interaction 'This Kronox remote bot only accepts commands from its configured owner.'
        Write-Log "Denied a slash command from Discord user $callerId." 'WARN'
        return
    }

    $action = [string]$interaction.data.name
    if ($action -notin @('help', 'status', 'health', 'screenshot', 'start', 'stop', 'safe-stop', 'queue', 'switch', 'timescale', 'modifiers', 'loadout', 'best')) {
        Send-InteractionReply $interaction 'This command is not available in Kronox Edition.'
        return
    }

    $argument = ''
    $argument2 = ''
    $options = @{}
    if ($interaction.data.options) {
        foreach ($option in $interaction.data.options) {
            $options[[string]$option.name] = [string]$option.value
        }
    }
    if ($action -eq 'switch') {
        if (-not $options.ContainsKey('slot')) {
            Send-InteractionReply $interaction 'Choose Strategy 1 or Strategy 2 for /switch.'
            return
        }
        $argument = $options['slot']
        if ($argument -notin @('1', '2')) {
            Send-InteractionReply $interaction 'Choose Strategy 1 or Strategy 2 for /switch.'
            return
        }
    }
    if ($action -eq 'timescale') {
        if (-not $options.ContainsKey('mode') -or $options['mode'] -notin @('off', '1.5x', '2x')) {
            Send-InteractionReply $interaction 'Choose Off, 1.5x, or 2x for /timescale.'
            return
        }
        $argument = $options['mode']
    }
    if ($action -eq 'modifiers') {
        if (-not $options.ContainsKey('action') -or $options['action'] -notin @('set', 'add', 'remove', 'clear', 'reset')) {
            Send-InteractionReply $interaction 'Choose set, add, remove, clear, or reset for /modifiers.'
            return
        }
        $argument = $options['action']
        if ($options.ContainsKey('names')) { $argument2 = $options['names'] }
        if ($argument -in @('set', 'add', 'remove') -and [string]::IsNullOrWhiteSpace($argument2)) {
            Send-InteractionReply $interaction 'Provide comma-separated modifier names for this /modifiers action.'
            return
        }
    }

    Queue-KronoxCommand $interaction $action $argument $argument2
    $acknowledgement = if ($action -eq 'switch') {
        "Queued /switch to Strategy $argument for the local Kronox macro."
    } elseif ($action -eq 'safe-stop') {
        'Queued /safe-stop. The local macro will stop at its next run boundary.'
    } elseif ($action -eq 'timescale') {
        "Queued /timescale $argument for the next local match."
    } elseif ($action -eq 'modifiers') {
        "Queued /modifiers $argument for the next local match."
    } else {
        "Queued /$action for the local Kronox macro."
    }
    Send-InteractionReply $interaction $acknowledgement
    Write-Log "Queued /$action from the configured owner."
}

function Run-DiscordGateway {
    $gateway = Invoke-DiscordBotApi -Method 'GET' -Path 'gateway/bot'
    $socket = [System.Net.WebSockets.ClientWebSocket]::new()
    try {
        $socket.ConnectAsync([Uri]($gateway.url + '/?v=10&encoding=json'), $Cancellation).GetAwaiter().GetResult()
        Write-Log 'Discord Gateway websocket connected; identifying the bot.'
        $firstBuffer = [byte[]]::new(65536)
        $firstSegment = [System.ArraySegment[byte]]::new($firstBuffer)
        $firstTask = $socket.ReceiveAsync($firstSegment, $Cancellation)
        $helloResult = $firstTask.GetAwaiter().GetResult()
        if ($helloResult.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) { throw 'Discord Gateway closed before HELLO.' }
        $helloJson = [System.Text.Encoding]::UTF8.GetString($firstBuffer, 0, $helloResult.Count)
        while (-not $helloResult.EndOfMessage) {
            $helloResult = $socket.ReceiveAsync($firstSegment, $Cancellation).GetAwaiter().GetResult()
            $helloJson += [System.Text.Encoding]::UTF8.GetString($firstBuffer, 0, $helloResult.Count)
        }
        $hello = $helloJson | ConvertFrom-Json
        if ($hello.op -ne 10) { throw 'Discord Gateway did not return HELLO.' }

        Send-GatewayPayload $socket @{
            op = 2
            d = @{
                token = $Token
                intents = 0
                properties = @{ os = 'windows'; browser = 'kronox-ultimate-macro'; device = 'kronox-ultimate-macro' }
                presence = @{
                    since = $null
                    # Some Discord surfaces omit the activity-type prefix and
                    # render only the raw name. Keep the complete phrase here
                    # so the member list never degrades to "over Kronox…".
                    activities = @(@{ name = 'Watching over Kronox Edition macro'; type = 3 })
                    status = 'online'
                    afk = $false
                }
            }
        }
        $heartbeatMs = [int]$hello.d.heartbeat_interval
        $nextHeartbeat = [DateTime]::UtcNow.AddMilliseconds($heartbeatMs)
        $lastSequence = $null
        $buffer = [byte[]]::new(65536)
        $segment = [System.ArraySegment[byte]]::new($buffer)
        $receiveTask = $socket.ReceiveAsync($segment, $Cancellation)

        while ($socket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
            if ($receiveTask.Wait(250)) {
                $result = $receiveTask.GetAwaiter().GetResult()
                if ($result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) { throw 'Discord Gateway closed the socket.' }
                $json = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count)
                while (-not $result.EndOfMessage) {
                    $result = $socket.ReceiveAsync($segment, $Cancellation).GetAwaiter().GetResult()
                    if ($result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) { throw 'Discord Gateway closed the socket.' }
                    $json += [System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count)
                }
                $payload = $json | ConvertFrom-Json
                Handle-GatewayPayload $payload ([ref]$lastSequence)
                if ($payload.op -eq 0 -and $payload.t -eq 'READY') {
                    Write-Log 'Remote bot is online and ready for slash commands.'
                }
                if ($payload.op -eq 1) { Send-GatewayPayload $socket @{ op = 1; d = $lastSequence } }
                if ($payload.op -eq 7 -or $payload.op -eq 9) { throw 'Discord requested a fresh Gateway session.' }
                $receiveTask = $socket.ReceiveAsync($segment, $Cancellation)
            }
            if ([DateTime]::UtcNow -ge $nextHeartbeat) {
                Send-GatewayPayload $socket @{ op = 1; d = $lastSequence }
                $nextHeartbeat = [DateTime]::UtcNow.AddMilliseconds($heartbeatMs)
            }
        }
    } finally {
        $socket.Dispose()
    }
}

try {
    Register-KronoxSlashCommands
    Write-Log 'Local slash-command gateway initialized.'
    while ($true) {
        try {
            Run-DiscordGateway
        } catch {
            Write-Log "Gateway reconnect: $($_.Exception.Message)" 'WARN'
            Start-Sleep -Seconds 5
        }
    }
} catch {
    Write-Log "Gateway stopped: $($_.Exception.Message)" 'ERROR'
    exit 1
}
