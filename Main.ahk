; Ultimate Macro (macro for TDS) by Darksen
;   Free for anyone to use
;   Modifications are welcome, however stealing credit is not.
;   You can add your name, but my original credit must remain.
;
; Thanks to everyone who helped me.
;
; Started on March 30, 2026. My friend bet me that I wouldn't make a macro for TDS, but I did.
;
; Discord Server - https://discord.gg/DQnc2JDJtr

#Requires AutoHotkey v2.0.19+
#SingleInstance Force

SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Client")
CoordMode("Pixel", "Client")

ListLines(False)
KeyHistory(0)
SetTitleMatchMode(1)

if (RegExMatch(A_ScriptDir, "i)\.(zip|rar)")) {
    MsgBox("You are attempting to run the script from a ZIP file.`n`nPlease Extract/Unzip the file first, then run the script in the extracted folder.","Running From ZIP", 0x10)
    ExitApp()
}

if WinExist("Ultimate Macro Kronox's Edition") {
    WinClose("Ultimate Macro Kronox's Edition")
}

if (A_PtrSize == 4) {
    MsgBox("You are running 32-bit AutoHotkey, the macro will not work properly, sadly.")
}

#Include "%A_ScriptDir%\lib\Gdip_All.ahk"
#Include "%A_ScriptDir%\lib\OCR.ahk"
#Include "%A_ScriptDir%\lib\Gdip_ImageSearch.ahk"
#Include "%A_ScriptDir%\lib\Roblox.ahk"
#Include "%A_ScriptDir%\lib\HyperSleep.ahk"
#Include "%A_ScriptDir%\lib\ImageSearch\ImageSearch.ahk"
#Include "%A_ScriptDir%\lib\TowerXP.ahk"
#Include "%A_ScriptDir%\lib\KronoxFeatures.ahk"
#Include "%A_ScriptDir%\submacros\updater.ahk"

ver := "1.3.3-kronox.10"
; Kronox's Edition checks only its own releases and never falls back to upstream builds.
global ForkUpdateRepository := "kronoxhellstorm/tds-macro-kronox"

; Kronox visual system: warm black-red surfaces with a true-crimson signal color.
; Keeping the palette here prevents Windows theming from drifting controls toward blue-gray.
global UITheme := Map(
    "App", "100C0E",
    "Surface", "120B0D",
    "Elevated", "1A1113",
    "Hover", "241317",
    "Selected", "2A171B",
    "Accent", "EF2B2D",
    "AccentHover", "FF4545",
    "AccentPressed", "B91F24",
    "AccentDark", "7A151B",
    "AccentSubtle", "351215",
    "BorderStrong", "43242B",
    "BorderSubtle", "2D171C",
    "TextPrimary", "F5E9EC",
    "TextSecondary", "B79AA0",
    "TextMuted", "987D83",
    "Success", "31B45C",
    "Warning", "E6A23C",
    "Info", "4F8CFF"
)

; Editable ComboBoxes use the current public, exclusive and evolved TDS roster.
; Roster checked against the TDS Wiki on 2026-08-17. Custom typing stays enabled
; so a newly released tower or a macro-specific alias never becomes a blocker.
global SupportedTowerNames := [
    "Abstract", "Accelerator", "Ace Pilot", "Archer", "Assassin", "Biologist", "Boomerang", "Brawler",
    "Commander", "Commando", "Cowboy", "Crook Boss", "Cryomancer", "Demoman", "DJ", "DJ Booth",
    "Electroshocker", "Elementalist", "Elf Camp", "Enforcer", "Engineer", "Executioner", "Farm",
    "Firework Technician", "Freezer", "Frost Blaster", "Gatling Gun", "Gladiator", "Hacker",
    "Hallow Punk", "Harvester", "Hunter", "Jester", "Juggernaut", "Kingpin", "Mecha Base", "Medic",
    "Mercenary Base", "Militant", "Military Base", "Minigunner", "Mortar", "Necromancer", "Operator",
    "Paintballer", "Pulse Trooper", "Pursuit", "Pyromancer", "Ranger", "Rocketeer", "Saboteur", "Scout",
    "Shotgunner", "Slasher", "Sledger", "Slime Trooper", "Sniper", "Snowballer", "Soldier",
    "Spotlight Tech", "Swarmer", "Tesla", "Toxic Gunner", "Trapper", "Turret", "Warden", "Warlock",
    "War Machine", "G Cowboy", "G Crook Boss", "G Minigunner", "G Pyromancer", "G Scout",
    "G Snowballer", "G Soldier"
]

ThemeColor(name) {
    global UITheme
    return UITheme[name]
}

SetButtonRole(ctrl, role := "Secondary") {
    ctrl.ThemeRole := role
    ApplyButtonRestStyle(ctrl)
}

ApplyButtonRestStyle(ctrl) {
    role := HasProp(ctrl, "ThemeRole") ? ctrl.ThemeRole : "Secondary"
    if (role = "Primary") {
        ctrl.Opt("Background" ThemeColor("Accent"))
        ctrl.SetFont("c" ThemeColor("TextPrimary") " Bold")
    } else if (role = "Danger") {
        ctrl.Opt("Background" ThemeColor("Surface"))
        ctrl.SetFont("c" ThemeColor("AccentHover") " Norm")
    } else {
        ctrl.Opt("Background" ThemeColor("Surface"))
        ctrl.SetFont("c" ThemeColor("TextPrimary") " Norm")
    }
}

ApplyButtonHoverStyle(ctrl) {
    role := HasProp(ctrl, "ThemeRole") ? ctrl.ThemeRole : "Secondary"
    if (role = "Primary") {
        ctrl.Opt("Background" ThemeColor("AccentHover"))
        ctrl.SetFont("c" ThemeColor("TextPrimary") " Bold")
    } else if (role = "Danger") {
        ctrl.Opt("Background" ThemeColor("AccentSubtle"))
        ctrl.SetFont("c" ThemeColor("AccentHover") " Bold")
    } else {
        ctrl.Opt("Background" ThemeColor("Hover"))
        ctrl.SetFont("c" ThemeColor("AccentHover") " Bold")
    }
}

ApplyDarkWindowTheme(hwnd) {
    darkMode := Buffer(4, 0)
    NumPut("Int", 1, darkMode)
    result := DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "Int", 20, "Ptr", darkMode, "Int", 4, "Int")
    if (result != 0)
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "Int", 19, "Ptr", darkMode, "Int", 4, "Int")
}

ApplyDarkControlThemes(guiObj) {
    for hwnd, ctrl in guiObj {
        try {
            controlType := ctrl.Type
            if (controlType = "Edit" || controlType = "DropDownList" || controlType = "ComboBox" || controlType = "ListBox") {
                ctrl.Opt("Background" ThemeColor("Elevated") " c" ThemeColor("TextPrimary"))
                DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
            }
        }
    }
}

A_MaxHotkeysPerInterval := 9999

pToken := Gdip_Startup()
OnExit(CleanupGdip)
OnExit(HandleExit)

global AppDataOpt := A_AppData "\Ultimate_Macro\Options"
global SettingsFile := AppDataOpt "\Settings.tds"
global KronoxBotSettingsFile := AppDataOpt "\Kronox-Discord-Bot.ini"
global KronoxBotCommandQueueDir := AppDataOpt "\Kronox-Discord-Commands"
global RecordingsDir := A_AppData "\Ultimate_Macro\Recordings"
global StateFile := A_AppData "\Ultimate_Macro\state.ini"
global OverallStatsFile := A_AppData "\Ultimate_Macro\overall_stats.ini"
global RunLedgerFile := A_AppData "\Ultimate_Macro\run_ledger.csv"
global RunContextFile := A_AppData "\Ultimate_Macro\run_context.csv"
global StrategyProfileFile := A_AppData "\Ultimate_Macro\strategy_profiles.csv"
global RuntimeLogDir := A_AppData "\Ultimate_Macro\Logs"
global KronoxBotRuntimeLogFile := RuntimeLogDir "\discord-bot.log"
global KronoxBotGatewayScript := A_ScriptDir "\submacros\kronox_discord_gateway.ps1"
global KronoxBotGatewayPID := 0
global DiscordRemoteView := "Webhook"

global StratsDir := A_WorkingDir "\Resources\Strats"

global ShowIndicators := true

global WebhookQueue := []
global WebhookTimerActive := false
global WebhookInstantQueue := []
global WebhookInstantTimerActive := false
global WebhookEnabled := false

if !DirExist(AppDataOpt)
    DirCreate(AppDataOpt)
if !DirExist(RecordingsDir)
    DirCreate(RecordingsDir)
if !DirExist(RuntimeLogDir)
    DirCreate(RuntimeLogDir)
if !DirExist(KronoxBotCommandQueueDir)
    DirCreate(KronoxBotCommandQueueDir)

OnError(HandleRuntimeError)
WriteRuntimeLog("MAIN", "Macro process started (PID " DllCall("GetCurrentProcessId") ").")
global CurrentMacroPhase := "idle"
SetMacroPhase("idle", "macro-ui-ready", 0)

;INI READS
global VipLink := IniRead(SettingsFile, "Options", "VipLink", "") 
global UseVipServer := IniRead(SettingsFile, "Options", "UseVipServer", "0")
global AlwaysOnTop := IniRead(SettingsFile, "Options", "AlwaysOnTop", 0)
global WebhookLink := IniRead(SettingsFile, "Webhook", "Link", "")
global WebhookLink2 := IniRead(SettingsFile, "Webhook", "Link2", "")
global WebhookEnabled := IniRead(SettingsFile, "Webhook", "Enabled", "0")
global PotatoMode := IniRead(SettingsFile, "Options", "PotatoMode", 0)
global LegacyMode := IniRead(SettingsFile, "Options", "LegacyMode", 0)
global UpgradeDelay := Max(50, Min(2000, Integer(IniRead(SettingsFile, "Options", "UpgradeDelay", 190))))
global SendCurrenciesEnabled := IniRead(SettingsFile, "Webhook", "SendCurrencies", "1")
global WebhookDebugLogs := IniRead(SettingsFile, "Webhook", "WebhookDebugLogs", "1")
global WebhookScreenshots := IniRead(SettingsFile, "Webhook", "WebhookScreenshots", "1")
global WebhookTriumphScreenshots := IniRead(SettingsFile, "Webhook", "WebhookTriumphScreenshots", 1)
global WebhookSepatateTriumphScreenshots := IniRead(SettingsFile, "Webhook", "WebhookSepatateTriumphScreenshots", 0)
; Remote control is intentionally opt-in. The token stays in a separate local
; settings file so normal webhook settings never enable a bot accidentally.
global KronoxBotEnabled := Integer(IniRead(KronoxBotSettingsFile, "Settings", "Enabled", 0))
global KronoxBotToken := IniRead(KronoxBotSettingsFile, "Token", "BotToken", "")
global KronoxBotApplicationID := IniRead(KronoxBotSettingsFile, "Settings", "ApplicationID", "")
global KronoxBotChannelID := IniRead(KronoxBotSettingsFile, "Settings", "ChannelID", "")
global KronoxBotGuildID := IniRead(KronoxBotSettingsFile, "Settings", "GuildID", "")
global KronoxBotOwnerUserID := IniRead(KronoxBotSettingsFile, "Settings", "OwnerUserID", "")
global UseRestartBtn := IniRead(SettingsFile, "Options", "UseRestartBtn", "1")
global UsePlayAgainBtn := IniRead(SettingsFile, "Options", "UsePlayAgainBtn", "1")
global RotateStrategies := IniRead(SettingsFile, "Options", "RotateStrategies", 0)
global AutoEquip := IniRead(SettingsFile, "Options", "AutoEquip", 0)
global CheckTheMap := IniRead(SettingsFile, "Options", "CheckTheMap", 1)
global UseNumbersForHotbar := IniRead(SettingsFile, "Options", "UseNumbers", 1)
global UseHForUpgrade := IniRead(SettingsFile, "Options", "UseHotkeyForUpgrade", 1)
global CollectPlaytimeRewards:= IniRead(SettingsFile, "Options", "CollectPlaytimeRewards", "1")
global Strategy1Path := IniRead(SettingsFile, "Options", "Strategy1", "")
global Strategy2Path := IniRead(SettingsFile, "Options", "Strategy2", "")
global PartyMembers := IniRead(SettingsFile, "Multiplayer", "PartyMembers", "someone, someone...")
global PlayerRole := IniRead(SettingsFile, "Multiplayer", "PlayerRole", "Host")
global LeaveCondition := IniRead(SettingsFile, "Multiplayer", "LeaveCondition", "Any")
global HostName := IniRead(SettingsFile, "Multiplayer", "HostName", "...")
global MultiplayerEnabled := IniRead(SettingsFile, "Multiplayer", "MultiplayerEnabled", 0)
global TowerXPTrackerEnabled := Integer(IniRead(SettingsFile, "TowerXP", "Enabled", 0))
global TowerXPStopMode := TowerXPStoredStopMode(IniRead(SettingsFile, "TowerXP", "StopMode", "Never"))
global EvolutionQueueEnabled := Integer(IniRead(SettingsFile, "EvolutionQueue", "Enabled", 0))
global EvolutionQueueTowers := IniRead(SettingsFile, "EvolutionQueue", "Towers", "")
global EvolutionQueueAutoEquip := Integer(IniRead(SettingsFile, "EvolutionQueue", "AutoEquip", 1))
global StrategyProfilerEnabled := Integer(IniRead(SettingsFile, "Analytics", "ProfilerEnabled", 1))
global WeekendXPBoostEnabled := Integer(IniRead(SettingsFile, "Analytics", "WeekendXPBoost", 1))
global VIPXPBoostEnabled := Integer(IniRead(SettingsFile, "Analytics", "VIPXPBoost", 0))
global OtherXPBoostMultiplier := IniRead(SettingsFile, "Analytics", "OtherXPBoost", "1.0")
global TimeScaleBudgetEnabled := Integer(IniRead(SettingsFile, "ResourceBudget", "TimeScaleEnabled", 0))
global TimeScaleTicketBalance := Integer(IniRead(SettingsFile, "ResourceBudget", "TicketBalance", 0))
global TimeScaleTicketReserve := Integer(IniRead(SettingsFile, "ResourceBudget", "TicketReserve", 0))
global TimeScaleTicketMaxSession := Integer(IniRead(SettingsFile, "ResourceBudget", "TicketMaxPerSession", 0))
global ConsumableBudgetEnabled := Integer(IniRead(SettingsFile, "ResourceBudget", "ConsumableEnabled", 0))
global ConsumableMaxPerRun := Integer(IniRead(SettingsFile, "ResourceBudget", "ConsumableMaxPerRun", 0))
global ConsumableMaxPerSession := Integer(IniRead(SettingsFile, "ResourceBudget", "ConsumableMaxPerSession", 0))
global UpdateCanaryEnabled := Integer(IniRead(SettingsFile, "UpdateCanary", "Enabled", 1))
global TDSVersionOverride := IniRead(SettingsFile, "UpdateCanary", "VersionOverride", "")
global AbsoluteModeEnabled := Integer(IniRead(SettingsFile, "Reliability", "AbsoluteMode", 0))

global DefaultMouseSpeed := IniRead(SettingsFile, "Options", "DefaultMouseSpeed", "2")
global MouseDelay := IniRead(SettingsFile, "Options", "MouseDelay", "10")
global KeyDelay := IniRead(SettingsFile, "Options", "KeyDelay", "20")

global PlaceTowerKey := IniRead(SettingsFile, "RecordingHotkeys", "PlaceTowerKey", "f")
global UpgradeTowerKey := IniRead(SettingsFile, "RecordingHotkeys", "UpgradeTowerKey", "^u")
global AlignCameraKey := IniRead(SettingsFile, "RecordingHotkeys", "AlignCameraKey", "^g")
global ChangeDJTrackKey := IniRead(SettingsFile, "RecordingHotkeys", "ChangeDJTrackKey", "^d")
global SellTowerKey := IniRead(SettingsFile, "RecordingHotkeys", "SellTowerKey", "^x")
global DeleteTowerRecordingKey := IniRead(SettingsFile, "RecordingHotkeys", "DeleteTowerRecordingKey", "^b")
global RecordInputsKey := IniRead(SettingsFile, "RecordingHotkeys", "RecordInputsKey", "^+e")
global HoloKey := IniRead(SettingsFile, "RecordingHotkeys", "HoloKey", "^!h")
global UseRaiseDeadKey := IniRead(SettingsFile, "RecordingHotkeys", "RaiseDeadKey", "^vkC0")
global ChangeTargetsKey := IniRead(SettingsFile, "RecordingHotkeys", "ChangeTargetsKey", "^!y")

global CurrentStratStartTime := Integer(IniRead(StateFile, "State", "CurrentStratStartTime", "0"))
global CurrentRotationIndex := Integer(IniRead(StateFile, "State", "CurrentRotationIndex", "1"))

global g_IsFirstLaunch := Integer(IniRead(StateFile, "State", "IsFirstLaunch", 1))

global SwapAmount := IniRead(SettingsFile, "Options", "SwapAmount", "4")
global SwapUnit := IniRead(SettingsFile, "Options", "SwapUnit", "Runs")
global CurrentRunCount := Integer(IniRead(StateFile, "State", "CurrentRunCount", "0"))

SendMode("Event")
SetDefaultMouseSpeed(DefaultMouseSpeed)
SetMouseDelay(MouseDelay)
SetKeyDelay(KeyDelay)

global LogLines := []
global OverlayHWND := 0
global OverlayBitmap := 0
global OverlayGraphics := 0
global OverlayPicHWND := 0
global OverlayWidth := 500
global OverlayHeight := 200
global OverlayX := 1400
global OverlayY := 820

global StrategyWidth := 1920
global StrategyHeight := 1090
global CloneFailurePolicy := ""
global EngineerCloneMaxAttempts := 3

global Slots := [
    ScaleX(800) ", " ScaleY(960), 
    ScaleX(880) ", " ScaleY(960), 
    ScaleX(960) ", " ScaleY(960), 
    ScaleX(1040) ", " ScaleY(960), 
    ScaleX(1120) ", " ScaleY(960)
]

global readyX := 0
global readyY := 0

global ChainKey, BeatKey, CaravanKey, SwatVanKey, CancelPlacementKey, TimeScaleMode, UseTimeScale, TimeScaleMultiplier
ChainKey := IniRead(SettingsFile, "Hotkeys", "Chain", "C")
BeatKey := IniRead(SettingsFile, "Hotkeys", "Beat", "B")
CaravanKey := IniRead(SettingsFile, "Hotkeys", "Caravan", "J")
SwatVanKey := IniRead(SettingsFile, "Hotkeys", "SwatVan", "N")
global RaiseDeadKey := IniRead(SettingsFile, "Hotkeys", "RaiseTheDead", "V")
global HologramKey := IniRead(SettingsFile, "Hotkeys", "Hologram", "K")
global RepoKey := IniRead(SettingsFile, "Hotkeys", "Repo", "L")
CancelPlacementKey := IniRead(SettingsFile, "Hotkeys", "CancelPlacement", "Q")
global UpgradeTowerGKey := IniRead(SettingsFile, "Hotkeys", "UpgradeTower", "E")
global UpgradeTowerGBKey := IniRead(SettingsFile, "Hotkeys", "UpgradeBottom", "Z")
ChainKey := SanitizeGameplayKeyBinding(ChainKey, "C", "Chain")
BeatKey := SanitizeGameplayKeyBinding(BeatKey, "B", "Beat")
CaravanKey := SanitizeGameplayKeyBinding(CaravanKey, "J", "Caravan")
SwatVanKey := SanitizeGameplayKeyBinding(SwatVanKey, "N", "SwatVan")
RaiseDeadKey := SanitizeGameplayKeyBinding(RaiseDeadKey, "V", "RaiseTheDead")
HologramKey := SanitizeGameplayKeyBinding(HologramKey, "K", "Hologram")
RepoKey := SanitizeGameplayKeyBinding(RepoKey, "L", "Repo")
CancelPlacementKey := SanitizeGameplayKeyBinding(CancelPlacementKey, "Q", "CancelPlacement")
UpgradeTowerGKey := SanitizeGameplayKeyBinding(UpgradeTowerGKey, "E", "UpgradeTower")
UpgradeTowerGBKey := SanitizeGameplayKeyBinding(UpgradeTowerGBKey, "Z", "UpgradeBottom")
TimeScaleMode := IniRead(SettingsFile, "Options", "TimeScaleMode", "OFF")
global DebugConsole := IniRead(SettingsFile, "Options", "DebugConsole", "1")

global TimescaleActive := false

if (TimeScaleMode = "1.5x") {
    UseTimeScale := true,  TimeScaleMultiplier := 1.5
} else if (TimeScaleMode = "2x") {
    UseTimeScale := true,  TimeScaleMultiplier := 2
} else {
    UseTimeScale := false, TimeScaleMultiplier := 1
}

global gamemap := "", difficulty := "", requiredTowers := ""
global AbstractTowerSlots := [], AbstractTowerSlot := 0
global AbstractPlacementLimit := Max(1, Min(4, Integer(IniRead(SettingsFile, "Options", "AbstractPlacementLimit", 4))))
global AbstractPlacementMax := 0
global StrategyHotbarSlotMap := Map(), StrategyHotbarRemapSummary := ""
global autoChain := "OFF", autoCaravan := "OFF", autoDropTheBeat := "OFF"
global Commander := false, AutoSkip := "ON", AbilitySpam := "ON"
global AdvancedAutoSkip := "OFF", AdvancedSkipWaves := "", AdvancedSkipWaveSet := Map()
global AdvancedLastSkippedWave := 0
global AutoSkipStopWave := 0, AutoSkipSuccessfulCount := 0
global AutoSkipLastDetectedWave := 0, AutoSkipBlockLogged := false

global SpecialMaps := ["Simplicity", "Cataclysm"]

global MoveEnabled := false, MoveDirection := "W", MoveDuration := 750
global unfocusX := 150, unfocusY := 200
global Towers := Map(), RecordedSteps := [], Recording := false, RunningStrategy := false
global modifiers := ""
global LastDisconnectCheck := 0
global LastOpenedTowerID := ""
global IsRestarting := false
global SafeExitFlag := false
global RestartLock := false
global InputAutomationSuspended := false
global LastBlockedHotbarToggleTick := 0
global FatalRecoveryScheduled := false
global TowerHotbarVerifiedOnce := false
global HotbarSafetyMisses := 0
global HotbarSafetyRecoveryActive := false

global isUiPositionSaved := false
global isUpgradeAuthorized := false
global activeUpgradeRegions := [0, 0, 0, 0]
global CachedMenuUI := {x: 0, y: 0}
global ActiveRTowerID := false

global canUseAbility := true, canBeUpgraded := true, needtocheckTowerUI := true

global KeyDownTimes := Map()

global MacroRecording := false
global MacroSteps := []
global MacroStartTime := 0
global InputHookObj := ""

global LastSkipCheck := 0
global SKIP_CHECK_INTERVAL := 1000
global AutorunStartTime := 0
global watchdogPID := ""

global SC_L:="sc026"
global SC_R:="sc013" 
global SC_Esc:="sc001"
global SC_Enter:="sc01c" 
SC_E:="sc012" ; e

if (DebugConsole = "1")
    ShowDebugConsole()

IconPath := A_WorkingDir "\ico.png"
CompiledIconPath := A_WorkingDir "\KronoxEdition.ico"
if !FileExist(IconPath)
    IconPath := CompiledIconPath
if FileExist(CompiledIconPath)
    TraySetIcon(CompiledIconPath)
else if FileExist(IconPath)
    TraySetIcon(IconPath)

WM_LBUTTONDOWN_Drag(wParam, lParam, msg, hwnd) {
    global MainGui
    if EditorHotbarTryBeginDrag(hwnd)
        return 0
    If (MainGui) {
        if (hwnd != MainGui.Hwnd) {
            return
        }
    }
    mouseY := lParam >> 16
    if (mouseY >= 42)
        return

    PostMessage(0xA1, 2, , , "ahk_id " MainGui.Hwnd)
}

IsRecordingActive(*) {
    global Recording
    return (Recording != false)
}

if (PlaceTowerKey = "") {
    IniWrite("f", SettingsFile, "RecordingHotkeys", "PlaceTowerKey")
    global PlaceTowerKey := IniRead(SettingsFile, "RecordingHotkeys", "PlaceTowerKey", "f")
}
if (PlaceTowerKey = "") {
    IniWrite("f", SettingsFile, "RecordingHotkeys", "PlaceTowerKey")
    global PlaceTowerKey := IniRead(SettingsFile, "RecordingHotkeys", "PlaceTowerKey", "f")
}
if (UpgradeTowerKey = "") {
    IniWrite("^u", SettingsFile, "RecordingHotkeys", "UpgradeTowerKey")
    global UpgradeTowerKey := IniRead(SettingsFile, "RecordingHotkeys", "UpgradeTowerKey", "^u")
}
if (AlignCameraKey = "") {
    IniWrite("^g", SettingsFile, "RecordingHotkeys", "AlignCameraKey")
    global AlignCameraKey := IniRead(SettingsFile, "RecordingHotkeys", "AlignCameraKey", "^g")
}
if IsTowerHotbarToggleKeySpec(AlignCameraKey) {
    AlignCameraKey := "^g"
    IniWrite(AlignCameraKey, SettingsFile, "RecordingHotkeys", "AlignCameraKey")
    WriteRuntimeLog("HOTBAR", "Migrated the unsafe Align Camera shortcut away from T to Ctrl+G.", "WARN")
}
if (ChangeDJTrackKey = "") {
    IniWrite("^d", SettingsFile, "RecordingHotkeys", "ChangeDJTrackKey")
    global ChangeDJTrackKey := IniRead(SettingsFile, "RecordingHotkeys", "ChangeDJTrackKey", "^d")
}
if (SellTowerKey = "") {
    IniWrite("^x", SettingsFile, "RecordingHotkeys", "SellTowerKey")
    global SellTowerKey := IniRead(SettingsFile, "RecordingHotkeys", "SellTowerKey", "^x")
}
if (DeleteTowerRecordingKey = "") {
    IniWrite("^b", SettingsFile, "RecordingHotkeys", "DeleteTowerRecordingKey")
    global DeleteTowerRecordingKey := IniRead(SettingsFile, "RecordingHotkeys", "DeleteTowerRecordingKey", "^b")
}
if (RecordInputsKey = "") {
    IniWrite("^+e", SettingsFile, "RecordingHotkeys", "RecordInputsKey")
    global RecordInputsKey := IniRead(SettingsFile, "RecordingHotkeys", "RecordInputsKey", "^+e")
}
if (HoloKey = "") {
    IniWrite("^!h", SettingsFile, "RecordingHotkeys", "HoloKey")
    global HoloKey := IniRead(SettingsFile, "RecordingHotkeys", "HoloKey", "^!h")
}
if (UseRaiseDeadKey = "") {
    IniWrite("^vkC0", SettingsFile, "RecordingHotkeys", "RaiseDeadKey")
    global UseRaiseDeadKey := IniRead(SettingsFile, "RecordingHotkeys", "RaiseDeadKey", "^vkC0")
}
if (ChangeTargetsKey = "") {
    IniWrite("^!y", SettingsFile, "RecordingHotkeys", "ChangeTargetsKey")
    global ChangeTargetsKey := IniRead(SettingsFile, "RecordingHotkeys", "ChangeTargetsKey", "^!y")
}
if IsTowerHotbarToggleKeySpec(ChangeTargetsKey) {
    ChangeTargetsKey := "^!y"
    IniWrite(ChangeTargetsKey, SettingsFile, "RecordingHotkeys", "ChangeTargetsKey")
    WriteRuntimeLog("HOTBAR", "Migrated the unsafe Change Targets shortcut away from T to Ctrl+Alt+Y.", "WARN")
}

RegisterRecordingHotkeys()
RegisterTowerHotbarProtection()

;Got this from someone on a Discord server
RegisterRecordingHotkeys(oldKeys := "") {
    global PlaceTowerKey, UpgradeTowerKey, ChangeDJTrackKey, DeleteTowerRecordingKey, ChangeTargetsKey, IsRecordingActive
    global SellTowerKey, AlignCameraKey, RecordInputsKey, HoloKey, UseRaiseDeadKey, RepoKey, UpgradeTowerGKey

    HotIf(IsRecordingActive)

    if IsObject(oldKeys) {
        for old in oldKeys {
            if (old != "") {
                try Hotkey(old, "Off")
            }
        }
    }

    Hotkey(PlaceTowerKey, PlaceTowerHK, "On")
    Hotkey(UpgradeTowerKey, UpgradeTowerHK, "On")
    Hotkey(ChangeDJTrackKey, ChangeDJTrackHK, "On")
    Hotkey(ChangeTargetsKey, ChangeTargetsHK, "On")
    Hotkey(DeleteTowerRecordingKey, DeleteTowerRecordingHK, "On")
    Hotkey(SellTowerKey, SellTowerHK, "On")
    Hotkey(AlignCameraKey, AlignCameraHK, "On")
    Hotkey(RecordInputsKey, RecordInputsHK, "On")
    Hotkey(HoloKey, CloneTowerHK, "On")
    Hotkey("~^" RepoKey, BrawlerRepositionHK, "On")
    Hotkey(UseRaiseDeadKey, ActivateRaiseTheDeadHK, "On")
    Hotkey("~LButton", DetectTowerForUpgrading, "On")
    Hotkey("~LButton Up", DetectUpgrade, "On")

    HotIf()
}

ShouldProtectTowerHotbarToggle(*) {
    global RunningStrategy, InputAutomationSuspended
    return RunningStrategy && !InputAutomationSuspended
        && WinActive("ahk_exe RobloxPlayerBeta.exe")
}

RegisterTowerHotbarProtection() {
    HotIf(ShouldProtectTowerHotbarToggle)
    Hotkey("$*t", BlockTowerHotbarToggle, "On")
    Hotkey("$*t Up", BlockTowerHotbarToggle, "On")
    HotIf()
}

BlockTowerHotbarToggle(*) {
    global LastBlockedHotbarToggleTick
    if (A_TickCount - LastBlockedHotbarToggleTick >= 2000) {
        LastBlockedHotbarToggleTick := A_TickCount
        WriteRuntimeLog("HOTBAR", "Blocked an accidental consumables hotbar toggle while the strategy was running.", "WARN")
    }
}

IsTowerHotbarToggleKeySpec(keySpec) {
    normalized := StrLower(RegExReplace(String(keySpec), "[\s\^+!#~*$<>]", ""))
    return normalized = "t" || normalized = "sc014" || normalized = "vk54"
}

SanitizeGameplayKeyBinding(keySpec, fallback, iniName) {
    global SettingsFile
    if !IsTowerHotbarToggleKeySpec(keySpec)
        return keySpec

    IniWrite(fallback, SettingsFile, "Hotkeys", iniName)
    WriteRuntimeLog("HOTBAR", "Migrated unsafe TDS keybind '" iniName "' away from T to " fallback ".", "WARN")
    return fallback
}

BlockUnsafeRecordingHotkeyPassthrough(keySpec, actionName := "recording hotkey") {
    global RunningStrategy
    if (!RunningStrategy || !IsTowerHotbarToggleKeySpec(keySpec))
        return false

    WriteRuntimeLog("HOTBAR", "Blocked " actionName " from forwarding T into Roblox during strategy playback.", "ERROR")
    return true
}

SendGameplayKey(keySpec, actionName := "gameplay action") {
    global InputAutomationSuspended, RunningStrategy
    if (InputAutomationSuspended)
        return false

    if IsTowerHotbarToggleKeySpec(keySpec) {
        detail := actionName " attempted to send reserved T hotkey"
        WriteRuntimeLog("HOTBAR", "Blocked " detail ".", "ERROR")
        LogToConsole("HOTBAR SAFETY: " actionName " was blocked because T only opens consumables.", true, false)
        if (RunningStrategy)
            TriggerUnsafeHotbarRecovery(detail)
        return false
    }

    SendEvent("{" keySpec "}")
    return true
}

IsTowerHotbarMonitoringPhase() {
    global CurrentMacroPhase
    return CurrentMacroPhase = "strategy-playback" || CurrentMacroPhase = "strategy-maintenance"
}

TriggerUnsafeHotbarRecovery(detail, inspection := "") {
    global HotbarSafetyRecoveryActive
    if (HotbarSafetyRecoveryActive)
        return

    HotbarSafetyRecoveryActive := true
    inspectionText := ""
    if IsObject(inspection) {
        observed := Trim(RegExReplace(inspection.text, "\s+", " "))
        if (observed = "")
            observed := "<no price text>"
        inspectionText := "; OCR=" observed "; region=" (inspection.HasProp("region") ? inspection.region : "unavailable")
    }

    WriteRuntimeLog("HOTBAR", "UNSAFE HOTBAR: " detail inspectionText
        ". All input was suspended; no slot key, click, or T recovery input was sent.", "ERROR")
    LogToConsole("HOTBAR SAFETY: " detail ". Input is suspended and Roblox will restart without pressing T.", true, false)
    SuspendAutomationInput("unsafe-consumable-hotbar")
    SetMacroPhase("hotbar-safety-recovery", detail, 0)
    KillSubmacros()
    CloseRoblox()
    SafeReload("unsafe-consumable-hotbar")
}

HotbarSafetyWatchdog(*) {
    global RunningStrategy, InputAutomationSuspended, HotbarSafetyMisses
    if (!RunningStrategy || InputAutomationSuspended || !IsTowerHotbarMonitoringPhase()
        || !WinActive("ahk_exe RobloxPlayerBeta.exe"))
        return

    inspection := InspectTowerHotbarBeforeSlotInput()
    if (inspection.safe) {
        HotbarSafetyMisses := 0
        return
    }

    HotbarSafetyMisses += 1
    if (HotbarSafetyMisses < 2) {
        WriteRuntimeLog("HOTBAR", "Watchdog did not see tower prices (probe 1/2); waiting for confirmation before recovery.", "WARN")
        return
    }

    HotbarSafetyMisses := 0
    TriggerUnsafeHotbarRecovery("continuous watchdog found no tower price in slots 1-2", inspection)
}

DetectTowerForUpgrading(*) {
    global MacroRecording, MacroSteps, MacroStartTime, Recording, Towers, RecordedSteps, Commander, ActiveRTowerID, CachedMenuUI, isUiPositionSaved, isUpgradeAuthorized, activeUpgradeRegions, CachedResV2, CachedResV1

    if (IsSet(MacroRecording) && MacroRecording) {
        MouseGetPos(&mx, &my)
        elapsed := A_TickCount - MacroStartTime
        MacroStartTime := A_TickCount
        MacroSteps.Push("Sleep(" elapsed ")")
        MacroSteps.Push("Click(" mx ", " my ")")
        return
    }

    if (!Recording)
        return

    MouseGetPos(&mx, &my, &clickWindow)
    robloxHwnd := GetRobloxHWND()
    
    if (clickWindow != robloxHwnd)
        return

    currentTowerID := ""
    for id, t in Towers {
        ix1 := t.x - 16
        iy1 := t.y - 16
        ix2 := ix1 + 32
        iy2 := iy1 + 32
        
        if (mx >= ix1 && mx <= ix2 && my >= iy1 && my <= iy2) {
            currentTowerID := id
            break
        }
    }

    if (currentTowerID != "") {
        ActiveRTowerID := currentTowerID
        isUpgradeAuthorized := false
        
        openedSuccessfully := waitForTowerUI(&resv2, &resv1)
        
        if (!openedSuccessfully) {
            ActiveRTowerID := ""
        } else {
            CachedResV2 := IsSet(resv2) ? resv2 : ""
            CachedResV1 := IsSet(resv1) ? resv1 : ""
        }
        return
    } else {
        if (ActiveRTowerID != "") {
            openedSuccessfully := waitForTowerUI(&resv2, &resv1, 120)
            
            if (!openedSuccessfully) {
                ActiveRTowerID := ""
            }
        }
    }
}

DetectUpgrade(*) {
    global Recording, ActiveRTowerID, Towers, RecordedSteps, Commander, isUpgradeAuthorized, activeUpgradeRegions, CachedResV2, CachedResV1
    
    if (!Recording || !IsSet(ActiveRTowerID) || ActiveRTowerID == "")
        return

    towerID := ActiveRTowerID
    
    if (!Towers.Has(towerID)) {
        ActiveRTowerID := ""
        return
    }

    MouseGetPos(&mx, &my, &clickWindow)
    robloxHwnd := GetRobloxHWND()
    
    if (clickWindow != robloxHwnd)
        return

    if (!IsSet(CachedResV2) || !IsSet(CachedResV1) || (CachedResV2 == "" && CachedResV1 == "")) {
        resv2 := ""
        resv1 := ""
        openedSuccessfully := waitForTowerUI(&resv2, &resv1)
        if (!openedSuccessfully) {
            ActiveRTowerID := ""
            return
        }
        CachedResV2 := IsSet(resv2) ? resv2 : ""
        CachedResV1 := IsSet(resv1) ? resv1 : ""
    } else {
        resv2 := CachedResV2
        resv1 := CachedResV1
    }

    path := Towers[towerID].path
    pathLevel := Towers[towerID].pathLevel
    nextLevel := Towers[towerID].level + 1

    doResV2 := (IsObject(resv2) && resv2.HasProp("score") && resv2.score > 0.55)

    if (doResV2) {
        upgAX := resv2.x - ScaleX(100)
        upgAY := resv2.y - ScaleY(260)
        upgAW := ScaleX(300)
        upgAH := ScaleY(110)
    } else if (IsObject(resv1)) {
        upgAX := resv1.x - ScaleX(344)
        upgAY := resv1.y + ScaleY(343)
        upgAW := ScaleX(300)
        upgAH := ScaleY(110)
    } else {
        return
    }

    region := [upgAX, upgAY, upgAW, upgAH]

    if (path != 0 && nextLevel > pathLevel && pathLevel != 0) {
        if (path = 2 && IsObject(resv1)) { 
            region := [resv1.x - ScaleX(344), resv1.y + ScaleY(488), ScaleX(300), ScaleY(110)]
        }
    }

    x1 := region[1]
    y1 := region[2]
    x2 := region[1] + region[3]
    y2 := region[2] + region[4]

    if (mx >= x1 && mx <= x2 && my >= y1 && my <= y2) {
        if PixelSearch(&gx, &gy, x1, y1, x2, y2, 0x206435, 7) {
            if (AdvImageSearch("Resources/fully_upgraded.png", x1, y1, region[3], region[4]).score >= 0.69) {
                return
            }

            Towers[towerID].level += 1
            LogToConsole("Upgraded tower " towerID " to level " Towers[towerID].level ".")
            UpdateTowerIndicator(towerID)
            
            if (Towers[towerID].path != 0 && Towers[towerID].path != "") {
                RecordedSteps.Push("UpgradeTower(" towerID ", false, 1, " Towers[towerID].path ", " Towers[towerID].pathLevel ")")
            } else {
                RecordedSteps.Push("UpgradeTower(" towerID ")")
            }
            
            if (Towers[towerID].level >= 2 && RegExMatch(towerID, "i)^Commander\d*$") && !Commander) {
                Commander := true
                if (!HasStep("Commander := true"))
                    RecordedSteps.Push("Commander := true")
            }
        }
    }
}

ScaleX(baseX, Width := 1920) {
    getRobloxPos(&pX, &pY, &currentWidth, &currentHeight)
    return Round(baseX * (currentWidth / Width))
}

ScaleY(baseY, Height := 1009) {
    getRobloxPos(&pX, &pY, &currentWidth, &currentHeight)
    return Round(baseY * (currentHeight / Height))
}

sX(baseX, Width := 1920) {
    global StrategyHeight
    hwnd := GetRobloxHWND()
    if !hwnd
        return

    getRobloxPos(&pX, &pY, &currentWidth, &currentHeight, hwnd)
    if (Width == 0) 
        return baseX

    if (Width == 1920 && StrategyHeight == 1090) {
        WinGetClientPos(&cX, , , , "ahk_id " hwnd)
        WinGetPos(&wX, , , , "ahk_id " hwnd)
        currentBorderX := cX - wX
        baseX := baseX - currentBorderX 
        Width := 1920 
    }
    
    return Round(baseX * (currentWidth / Width))
}

sY(baseY, Height := 1090) {
    hwnd := GetRobloxHWND()
    if !hwnd
        return
    getRobloxPos(&pX, &pY, &currentWidth, &currentHeight, hwnd)
    if (Height == 0) 
        return baseY
    
    if (Height == 1090) {
        WinGetClientPos(, &cY, , , "ahk_id " hwnd)
        WinGetPos(, &wY, , , "ahk_id " hwnd)
        currentBorderY := cY - wY
        baseY := baseY - currentBorderY 
        Height := 1009 
    }
    
    return Round(baseY * (currentHeight / Height))
}

autoRun := IniRead(StateFile, "State", "Running",   0)
autoStrat := IniRead(StateFile, "State", "Strategy",  "")
savedStartTime := IniRead(StateFile, "State", "StartTime", 0)
if (savedStartTime != 0)
    AutorunStartTime := Integer(savedStartTime)

if (autoRun = 1) {
    if KronoxConsumeRemoteSafeStop() {
        autoRun := 0
        IniWrite(0, StateFile, "State", "Running")
        WriteRuntimeLog("DISCORD", "Remote safe stop prevented automatic launch of another match.")
    } else {
        queuedRemoteStrategy := ""
        if ConsumeKronoxRemoteStrategySwitch(&queuedRemoteStrategy)
            autoStrat := queuedRemoteStrategy
    }
}

if (autoRun = 1 && autoStrat != "" && FileExist(autoStrat)) {
    WriteRuntimeLog("MAIN", "Automatic resume is loading strategy: " autoStrat ".")
    LoadStrategyFile(autoStrat)
    WriteRuntimeLog("MAIN", "Automatic resume strategy loaded successfully.")
    RunningStrategy := true
    ResumeAutomationInput("automatic-resume")
    ActivateRoblox()
    RunStrategy()
    RunningStrategy := false
    IniWrite(0, StateFile, "State", "Running")
} else {
    updateResult := CheckForUpdate(ver, ForkUpdateRepository)
    if (updateResult = 2) {
        SafeReload()
    }

    MultiInstanceTools := "RobloxAccountManager.exe,Roblox Account Manager.exe,RAM.exe,RobloxMulti.exe,MultiRoblox.exe,MultipleRoblox.exe,Multiple Roblox.exe"
    Loop Parse, MultiInstanceTools, "," {
        if ProcessExist(A_LoopField) {
            MsgBox("Conflicting program detected:`n" A_LoopField "`n`nFor this script to work properly, please close all Roblox multi-client utilities.`nPlease close them and try again.", "Error", 48)
            ExitApp()
        }
    }
}

global MainGui := Gui("-Caption +Border +LastFound")
MainGui.BackColor := ThemeColor("App")
global MainWindowWidth := 760
global MainWindowHeight := 610

global SystemHwnds := Map()

sysAccent := MainGui.Add("Progress", "x0 y0 w" MainWindowWidth " h3 Disabled Background" ThemeColor("Accent"), 0)
SystemHwnds[sysAccent.Hwnd] := true
sysBar1 := MainGui.Add("Progress", "x0 y3 w" MainWindowWidth " h39 Disabled Background" ThemeColor("Surface"), 0)
SystemHwnds[sysBar1.Hwnd] := true

MainGui.SetFont("s11 w300 c" ThemeColor("TextPrimary"), "Segoe UI")
if FileExist(IconPath) {
    iconOptions := "BackgroundTrans x20 y12 w20 h20"
    if (SubStr(StrLower(IconPath), -3) = "ico")
        iconOptions .= " Icon1"
    sysIcon := MainGui.Add("Picture", iconOptions, IconPath)
    SystemHwnds[sysIcon.Hwnd] := true
}

global GuiTitleCtrl := MainGui.Add("Text", "x50 y12 w360 h25 BackgroundTrans", "Ultimate Macro Kronox's Edition")
GuiTitleCtrl.OnEvent("Click", MoveWindow)
SystemHwnds[GuiTitleCtrl.Hwnd] := true

MainGui.SetFont("s11 w400 c" ThemeColor("TextPrimary"), "Marlett")
global BtnMin   := MainGui.Add("Text", "x660 y12 w30 h25 Center BackgroundTrans", "0")
BtnMin.OnEvent("Click", MinimizeWindow)
SystemHwnds[BtnMin.Hwnd] := true

MainGui.SetFont("s11 w400 c" ThemeColor("TextMuted"), "Marlett")
sysDot := MainGui.Add("Text", "x690 y12 w30 h25 Center BackgroundTrans", "1")
SystemHwnds[sysDot.Hwnd] := true

MainGui.SetFont("s11 w400 c" ThemeColor("TextPrimary"), "Marlett")
global BtnClose := MainGui.Add("Text", "x720 y12 w30 h25 Center BackgroundTrans", "r")
BtnClose.OnEvent("Click", CloseWindow)
SystemHwnds[BtnClose.Hwnd] := true

sysLine1 := MainGui.Add("Progress", "x0 y42 w" MainWindowWidth " h1 Background" ThemeColor("BorderSubtle"), 0)
SystemHwnds[sysLine1.Hwnd] := true


MainGui.SetFont("s10 w400 c" ThemeColor("TextMuted"), "Segoe UI")
global HoverTab := []
global TabCtrl  := []
global HoverEffect_btns := []
global GradientButtons := []

;tabs
global TAB3 := []

;==

tabNames := ["Main", "Record", "Party", "Webhook", "Settings", "Tools", "Analytics", "Editor", "Credits"]
global TabStartX := 15
global TabStep := 81
global TabWidth := 74

Loop tabNames.Length {
    i   := A_Index
    xTab := TabStartX + (i-1) * TabStep
    
    hBg := MainGui.Add("Progress", "x" xTab " y43 w" TabWidth " h34 Hidden Background" ThemeColor("Selected") " Disabled")
    HoverTab.Push(hBg)
    SystemHwnds[hBg.Hwnd] := true 
    
    t := MainGui.Add("Text", "x" xTab " y52 w" TabWidth " h22 Center BackgroundTrans", tabNames[i])
    t.OnEvent("Click", SelectTab)
    TabCtrl.Push(t)
    SystemHwnds[t.Hwnd] := true 
}

global TabLine := MainGui.Add("Progress", "x" TabStartX " y75 w" TabWidth " h2 Background" ThemeColor("Accent"), 0)
SystemHwnds[TabLine.Hwnd] := true 

sysLine2 := MainGui.Add("Progress", "x0 y77 w" MainWindowWidth " h1 Background" ThemeColor("BorderSubtle"), 0)
SystemHwnds[sysLine2.Hwnd] := true

; tab 1 - MAIN ===========================

MainGui.SetFont("s10 w600 c" ThemeColor("Accent"), "Segoe UI")
global Tab1_Section1 := MainGui.Add("Text", "x30 y95  w200 h22",  "Custom Strategies")
global Tab1_Line1 := MainGui.Add("Progress", "x30 y118 w640 h1 Background" ThemeColor("BorderStrong"), 0)

MainGui.SetFont("s9 w400 c" ThemeColor("TextSecondary"), "Segoe UI")
global Tab1_Lbl1 := MainGui.Add("Text", "x30 y130 w100 h20", "Strategy:")
MainGui.SetFont("s9 w400 c000000")
global Strategy1Ctrl := MainGui.Add("Edit", "x110 y127 w400 h22 vStrategy1", Strategy1Path)
Strategy1Ctrl.OnEvent("Change", SaveStrat1)
MainGui.SetFont("s9 w400 c" ThemeColor("TextPrimary"))
global Tab1_Btn1 := MainGui.Add("Text", "x515 y126 w70 h22 +Border 0x200 Center", "Browse")
Tab1_Btn1.OnEvent("Click", SelectStrat1)
global Tab1_Btn2 := MainGui.Add("Text", "x590 y126 w70 h22 +Border 0x200 Center", "Clear")
Tab1_Btn2.OnEvent("Click", ClearStrat1)

HoverEffect_btns.Push(Tab1_Btn1) 
HoverEffect_btns.Push(Tab1_Btn2) 

MainGui.SetFont("s9 w400 c" ThemeColor("TextSecondary"))
global Tab1_Lbl2 := MainGui.Add("Text", "x30 y160 w100 h20", "Strategy 2:")
MainGui.SetFont("s9 w400 c000000")
global Strategy2Ctrl := MainGui.Add("Edit", "x110 y157 w400 h22 vStrategy2", Strategy2Path)
Strategy2Ctrl.OnEvent("Change", SaveStrat2)
MainGui.SetFont("s9 w400 c" ThemeColor("TextPrimary"))
global Tab1_Btn3 := MainGui.Add("Text", "x515 y156 w70 h22 +Border 0x200 Center", "Browse")
Tab1_Btn3.OnEvent("Click", SelectStrat2)
global Tab1_Btn4 := MainGui.Add("Text", "x590 y156 w70 h22 +Border 0x200 Center", "Clear")
Tab1_Btn4.OnEvent("Click", ClearStrat2)

HoverEffect_btns.Push(Tab1_Btn3) 
HoverEffect_btns.Push(Tab1_Btn4) 

MainGui.SetFont("s9 w400 c" ThemeColor("TextPrimary"))
global RotateStrategiesCtrl := MainGui.Add("Checkbox", "x30 y190 w150 h22 vRotateStrategies Checked" RotateStrategies, "Strategy Rotation")
RotateStrategiesCtrl.OnEvent("Click", EnableStratRotation)

MainGui.SetFont("s9 w400 c" ThemeColor("TextSecondary"))
global SwapAfterLbl := MainGui.Add("Text", "x148 y188 w70 h20 0x200 BackgroundTrans", "Swap after:")

MainGui.SetFont("s9 w400 c000000") 
global SwapAmountCtrl := MainGui.Add("Edit", "x217 y186 w40 h22 +Border Number Center vSwapAmount", SwapAmount)

SwapAmountCtrl.OnEvent("Change", (*) => (
    IniWrite(SwapAmountCtrl.Text, SettingsFile, "Options", "SwapAmount"),
    SwapAmount := SwapAmountCtrl.Text
))

MainGui.SetFont("s9 w400 c000000")
global SwapUnitCtrl := MainGui.Add("DropDownList", "x267 y186 w80 Choose" (SwapUnit = "Minutes" ? 2 : 1) " vSwapUnit", ["Runs", "Minutes"])

SwapUnitCtrl.OnEvent("Change", (*) => (
    IniWrite(SwapUnitCtrl.Text, SettingsFile, "Options", "SwapUnit"),
    SwapUnit := SwapUnitCtrl.Text
    IniWrite(SwapAmountCtrl.Text, SettingsFile, "Options", "SwapAmount")
))

MainGui.SetFont("s9 w400 c" ThemeColor("TextPrimary"))
global AutoEquipCtrl := MainGui.Add("Checkbox", "x205 y190 w160 h22 vAutoEquip Checked" AutoEquip, "Auto Equip Towers")
AutoEquipCtrl.OnEvent("Click", EnableAutoEquip)

MainGui.SetFont("s9 w400 c" ThemeColor("TextSecondary"))
global AbstractCountLabel := MainGui.Add("Text", "x492 y188 w110 h22 Hidden 0x200 BackgroundTrans", "Active abstract:")
MainGui.SetFont("s9 w400 c000000")
global AbstractCountCtrl := MainGui.Add("DropDownList", "x605 y186 w55 Hidden", ["1", "2", "3", "4"])
AbstractCountCtrl.Text := String(AbstractPlacementLimit)
AbstractCountCtrl.OnEvent("Change", AbstractPlacementLimitChanged)
if (Strategy1Path != "" && FileExist(Strategy1Path))
    LoadAbstractPlacementProfile(Strategy1Path)

MainGui.SetFont("s10 w600 c" ThemeColor("Accent"), "Segoe UI")
global Tab1_Section2 := MainGui.Add("Text", "x30 y225 h22", "Community Strategies")
global Tab1_Line2 := MainGui.Add("Progress", "x30 y248 w640 h1 Background" ThemeColor("BorderStrong"), 0)


if !DirExist(StratsDir)
    DirCreate(StratsDir)

LoadedStrats := []
needUpdate := true
lastUpdate := IniRead(StateFile, "Cache", "LastUpdateTime", "0")

if (lastUpdate != "0") {
    timeDiff := DateDiff(A_Now, lastUpdate, "Hours")
    if (timeDiff < 6) {
        needUpdate := false 
    }
}

if (needUpdate) {
    try {
        apiURL := "https://api.github.com/repos/DarksenDev/tds-macro/contents/Strategies"
        
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", apiURL, true)
        whr.SetRequestHeader("User-Agent", "Strategy-Updater")
        whr.Send()
        
        while (!whr.WaitForResponse(1)) {
            Sleep(50)
        }
        
        if (whr.Status != 200) {
            throw Error("API request failed with status: " whr.Status)
        }
            
        responseText := whr.ResponseText
        
        tempDir := StratsDir "\.download_temp"
        if DirExist(tempDir)
            DirDelete(tempDir, true)
        DirCreate(tempDir)

        pos := 1
        fileCount := 0
        successCount := 0
        
        while (pos := RegExMatch(responseText, '\{[^}]*"name":"([^"]+\.strat)"[^}]*"download_url":"([^"]+)"[^}]*\}', &match, pos)) {
            fileName := match[1]
            downloadURL := match[2]
            fileCount++
            
            try {
                fileWhr := ComObject("WinHttp.WinHttpRequest.5.1")
                fileWhr.SetTimeouts(3000, 3000, 3000, 5000)
                fileWhr.Open("GET", downloadURL, false)
                fileWhr.SetRequestHeader("User-Agent", "Strategy-Updater")
                fileWhr.Send()
                
                if (fileWhr.Status == 200) {
                    ado := ComObject("ADODB.Stream")
                    ado.Type := 1
                    ado.Open()
                    ado.Write(fileWhr.ResponseBody)
                    ado.SaveToFile(tempDir "\" fileName, 2)
                    ado.Close()
                    successCount++
                } else {
                    LogToConsole("Failed to download file '" fileName "'. Status: " fileWhr.Status, (AlwaysOnTop = 1) ? 0x1000 : 0)
                }
            } catch Error as fileErr {
                LogToConsole("Network error downloading file '" fileName "': " fileErr.Message, (AlwaysOnTop = 1) ? 0x1000 : 0)
            }
            
            pos += match.Len
            Sleep(30)
        }

        if (fileCount > 0 && successCount == 0) {
            DirDelete(tempDir, true)
            throw Error("All strategy downloads failed. Aborting update to protect existing files.")
        }

        if !DirExist(StratsDir)
            DirCreate(StratsDir)

        oldManifestStr := IniRead(StateFile, "Cache", "CommunityStratFiles", "")
        oldManifestFiles := (oldManifestStr = "") ? [] : StrSplit(oldManifestStr, "|")

        for oldFile in oldManifestFiles {
            if (oldFile != "" && FileExist(StratsDir "\" oldFile))
                try FileDelete(StratsDir "\" oldFile)
        }

        newManifestStr := ""
        newFileCount := 0
        Loop Files, tempDir "\*.strat" {
            FileMove(A_LoopFileFullPath, StratsDir "\" A_LoopFileName, 1)
            newManifestStr .= (newManifestStr = "" ? "" : "|") A_LoopFileName
            newFileCount++
        }

        DirDelete(tempDir, true)
        IniWrite(A_Now, StateFile, "Cache", "LastUpdateTime")
        IniWrite(newManifestStr, StateFile, "Cache", "CommunityStratFiles")
        
    } catch Error as err {
        LogToConsole("Error while downloading strats: " err.Message, (AlwaysOnTop = 1) ? 0x1000 : 0)
    }
}

global FrameX := 30
global FrameY := 294
global FrameW := 640
global FrameH := 227
global ContentH := 0
global CurrentScrollPos := 0
global SliderH := 30
global ChildHwnd := 0
global ChildGui := ""
global SliderBG := ""
global CustomSlider := ""
global CommunityFilter := IniRead(SettingsFile, "StrategyLibrary", "Filter", "All")
global CommunityFavoriteFiles := KronoxStrategyFavoritesParse(IniRead(SettingsFile, "StrategyLibrary", "Favorites", ""))
global CommunityFilterButtons := []
global CommunityLibraryCtrls := []

Tab1_Section2.Text := "Strategy Library"
MainGui.SetFont("s8 w600 c" ThemeColor("TextMuted"), "Segoe UI")
global CommunityStrategyCount := MainGui.Add("Text", "x500 y225 w170 h22 Right BackgroundTrans", "0 STRATEGIES")
CommunityLibraryCtrls.Push(CommunityStrategyCount)

Loop Files, StratsDir "\*.strat" {
    localPath := A_LoopFileFullPath
    
    sMap := IniRead(localPath, "Settings", "map", "")
    sDifficulty := IniRead(localPath, "Settings", "difficulty", "")
    sTowers := IniRead(localPath, "Settings", "requiredTowers", "")
    sDesc := IniRead(localPath, "Info", "desc", "")
    sAuthor := IniRead(localPath, "Info", "author", "")
    sTitle := KronoxStrategyDisplayName(IniRead(localPath, "Info", "title", ""), A_LoopFileName)
    sTime := IniRead(localPath, "Info", "time", "")
    sIncome := IniRead(localPath, "Info", "income", "")
    sModifiers := IniRead(localPath, "Settings", "modifiers", "")
    
    LoadedStrats.Push({
        fileName: A_LoopFileName,
        map: sMap,
        difficulty: sDifficulty,
        towers: sTowers,
        desc: sDesc,
        author: sAuthor,
        title: sTitle,
        time: sTime,
        income: sIncome,
        modifiers: sModifiers
    })
}

communityModes := []
communityModeSeen := Map()
for strat in LoadedStrats {
    modeName := Trim(strat.difficulty)
    modeKey := StrLower(modeName)
    if (modeName != "" && !communityModeSeen.Has(modeKey))
        communityModeSeen[modeKey] := modeName
}
for preferredMode in ["Easy", "Intermediate", "Molten", "Fallen", "Frost", "Hardcore", "Voidcore"] {
    preferredKey := StrLower(preferredMode)
    if (communityModeSeen.Has(preferredKey)) {
        communityModes.Push(communityModeSeen[preferredKey])
        communityModeSeen.Delete(preferredKey)
    }
}
for modeKey, modeName in communityModeSeen
    communityModes.Push(modeName)

communityFilters := ["All", "Favorites"]
for modeName in communityModes
    communityFilters.Push(modeName)
if (!KronoxArrayContains(communityFilters, CommunityFilter))
    CommunityFilter := "All"

filterGap := 4
filterWidth := Floor((640 - (communityFilters.Length - 1) * filterGap) / communityFilters.Length)
for index, filterName in communityFilters {
    filterX := 30 + ((index - 1) * (filterWidth + filterGap))
    MainGui.SetFont("s8 w600 c" ThemeColor("TextSecondary"), "Segoe UI")
    filterCtrl := MainGui.Add("Text", "x" filterX " y258 w" filterWidth " h26 Center +0x200 Background" ThemeColor("Surface"), filterName)
    filterCtrl.FilterName := filterName
    filterCtrl.OnEvent("Click", SelectCommunityStrategyFilter)
    CommunityFilterButtons.Push(filterCtrl)
    CommunityLibraryCtrls.Push(filterCtrl)
}

RefreshCommunityFilterStyles()
BuildCommunityStrategyGui()

OnMessage(0x0115, OnScroll)
OnMessage(0x020A, OnMouseWheel)


MainGui.SetFont("s11 w600 c" ThemeColor("TextPrimary"), "Segoe UI")
global Tab1_Start := MainGui.Add("Text", "x30 y545 w300 h40 Center Background" ThemeColor("Accent") " +Border 0x200", "Start (F1)")
Tab1_Start.OnEvent("Click", StartStrategy)
global Tab1_Stop := MainGui.Add("Text",  "x340 y545 w330 h40 Center Background" ThemeColor("Surface") " +Border 0x200", "Stop (F2)")
Tab1_Stop.OnEvent("Click", StopStrategy)
SetButtonRole(Tab1_Start, "Primary")
SetButtonRole(Tab1_Stop, "Danger")

HoverEffect_btns.Push(Tab1_Start) 
HoverEffect_btns.Push(Tab1_Stop) 

; tab 2 - RECORD ===========================

MainGui.SetFont("s10 w600 cEF2B2D", "Segoe UI")
global Tab2_Title := MainGui.Add("Text", "x30 y95  w200 h22 Hidden", "Configuration")
global Tab2_Line1 := MainGui.Add("Progress", "x30 y118 w640 h1  Hidden Background43242B", 0)

MainGui.SetFont("s9 w400 cB79AA0")
global Tab2_Lbl1 := MainGui.Add("Text", "x30 y145 w80 h20 Hidden", "Map:")
MainGui.SetFont("s9 w400 cFFFFFF")
global RecMapsD := MainGui.Add("DropDownList", "x80 y142 w220 Hidden vRecMaps", [ ; WARNING: These are all the supported maps for this macro. If a map is not listed here, it is unsupported
    "Abandoned City", "Area 52", "Autumn Falling", 
    "Badlands II", "Black Spot Exchange", "Candy Valley", "Cataclysm", "Chess Board", 
    "Construction Crazy", "Coral Deep", "Crossroads", "Crystal Cave", 
    "Cyber City", "Dead Ahead", "Derelict Outpost", "Deserted Village", "Dusty Bridges", 
    "Enchanted Forest", "Farm Lands", "Forest Camp", "Forgetten Docks", "Four Seasons", 
    "Fungi Island", "Grass Isle", "Happy Home of Robloxia", "Harbor", "Honey Valley", 
    "Hot Spot", "Iceville", "Infernal Abyss", "Lay By", "Lighthaos", "Marshlands", "Mason Arch", "Medieval Times", "Meltdown", 
    "Midnight Issue", "Moon Base", "Musaceae Kingdom", "Necropolis", "Nether", "Night Station", 
    "Northern Lights", "Outskirts Commune", "Pier Pressure", "Pizza Party", "Polluted Wasteland II", 
    "Portland", "Retro Crossroads", "Retro Lighthouse", "Retro Rocket Arena", "Retro Stained Temple", 
    "Retro The Heights", "Retro Zone", "Rocket Arena", "Ruby Escort", "Sacred Mountains", 
    "Sky Islands", "Simplicity", "Space City", "Spring Fever", "Stained Temple", "Sugar Rush", 
    "The Heavens", "The Heights", "Toyboard", "Tropical Industries", "Tropical Isles", "U-Turn", 
    "Unknown Garden", "Winter Abyss", "Winter Bridges", "Winter Stronghold", "Wrecked Battlefield", 
    "Wrecked Battlefield II", "Wretched Front"
])

MainGui.SetFont("s9 w400 cB79AA0")
global Tab2_Lbl2 := MainGui.Add("Text", "x320 y145 w80 h20 Hidden", "Mode:")
MainGui.SetFont("s9 w400 cFFFFFF")
global RecDiffCtrl := MainGui.Add("DropDownList", "x380 y142 w220 Hidden vRecDifficulty", [
    "Easy", "Casual", "Intermediate", "Molten", "Fallen", "Frost", 
    "Hardcore", "Voidcore", "Pizza Party", "Badlands II", "Polluted Wasteland II"
])

MainGui.SetFont("s9 w400 cB79AA0")
global Tab2_Lbl3 := MainGui.Add("Text", "x30 y260 w80 h20 Hidden", "Modifiers:")
MainGui.SetFont("s9 w400 c000000")

global RecModifiersCtrl := MainGui.Add("ListBox", "x110 y257 w220 h165 Multi Hidden vRecModifiers", [
    "Broke", "Exploding", "Flying", "Fog", "Glass", 
    "Healthy", "Hidden", "Inflation", "Jailed", "Limitation", 
    "Committed", "Quarantine", "Speedy"
])

MainGui.SetFont("s9 w400 cB79AA0", "Segoe UI")
global Tab2_Info2 := MainGui.Add("Text", "x20 w70 y298 BackgroundTrans Hidden", "Hold CTRL to select multiple modifiers.")

MainGui.SetFont("s9 w600 cEF2B2D", "Segoe UI")
global Tab2_Lbl4 := MainGui.Add("Text", "x30 y176 w180 h20 Hidden", "Tower Hotbar")
global RecTowerLabels := []
global RecTowerCtrls := []
initialRecTowers := SplitTowerNames(requiredTowers)
Loop 5 {
    towerX := 30 + ((A_Index - 1) * 128)
    MainGui.SetFont("s8 w600 cB79AA0", "Segoe UI")
    towerLabel := MainGui.Add("Text", "x" towerX " y194 w118 h18 Hidden", "SLOT " A_Index)
    MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
    towerCtrl := MainGui.Add("ComboBox", "x" towerX " y211 w118 Hidden", SupportedTowerNames)
    if (A_Index <= initialRecTowers.Length)
        towerCtrl.Text := initialRecTowers[A_Index]
    RecTowerLabels.Push(towerLabel)
    RecTowerCtrls.Push(towerCtrl)
}

MainGui.SetFont("s8 w400 c987D83", "Segoe UI")
global Tab2_Info1 := MainGui.Add("Text", "x30 y238 w640 h17 BackgroundTrans Hidden", "Type a tower name or choose one. Golden perks use G Tower (for example, G Soldier).")

MainGui.Add("Progress", "x360 y257 w320 h1 Hidden Background43242B vTab2_Line2", 0)
global Tab2_Line2 := MainGui["Tab2_Line2"]

MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global RecAutoChainCtrl := MainGui.Add("Checkbox", "x360 y278 Hidden vRecAutoChain Checked" (autoChain="ON"?1:0), "Use Call of Arms")
global RecAutoCaravanCtrl := MainGui.Add("Checkbox", "x490 y278 Hidden vRecAutoCaravan Checked" (autoCaravan="ON"?1:0), "Use Support Caravan")
global RecAutoDropCtrl := MainGui.Add("Checkbox", "x360 y300 Hidden vRecAutoDropTheBeat Checked" (autoDropTheBeat="ON"?1:0), "Use Drop the Beat")

MainGui.Add("Progress", "x360 y325 w320 h1 Hidden Background43242B vTab2_Line3", 0)
global Tab2_Line3 := MainGui["Tab2_Line3"]
global RecAutoSkipCtrl := MainGui.Add("Checkbox", "x360 y338 h20 Hidden vRecAutoSkip", "Auto Skip Waves")
RecAutoSkipCtrl.OnEvent("Click", RecordToggleAutoskip)
global RecAbilitySpamCtrl := MainGui.Add("Checkbox", "x490 y338 h20 Hidden vRecAbilitySpam", "Abilities Spam")
global RecAbstractSlotEnabledCtrl := MainGui.Add("Checkbox", "x360 y363 h20 Hidden vRecAbstractSlotEnabled", "Abstract XP towers")
RecAbstractSlotEnabledCtrl.OnEvent("Click", UpdateRecAbstractSlotControls)
MainGui.SetFont("s9 w400 cB79AA0")
global RecAbstractSlotLabel := MainGui.Add("Text", "x505 y365 w42 h20 Hidden", "Slots:")
MainGui.SetFont("s9 w400 cFFFFFF")
global RecAbstractSlotCtrls := []
Loop 5 {
    abstractSlotCtrl := MainGui.Add("Checkbox", "x" (545 + ((A_Index - 1) * 27)) " y362 w26 h20 Hidden", String(A_Index))
    abstractSlotCtrl.Enabled := false
    RecAbstractSlotCtrls.Push(abstractSlotCtrl)
}
MainGui.SetFont("s8 w400 cB79AA0")
global RecAbstractSlotInfo := MainGui.Add("Text", "x360 y388 w320 h24 BackgroundTrans Hidden", "Each selected slot accepts any equipped tower and keeps its recorded actions.")
global Tab2_Info := MainGui.Add("Link", "x360 y413 w320 h34 Hidden", "
(
Record a strategy and save it into a file. <a href="https://www.youtube.com/watch?v=j8Y5qHBaYOs&feature=youtu.be">Watch the tutorial</a>. Timescale is recommended for complex strategies.
)")

global RecMoveCtrl := MainGui.Add("Checkbox", "x30 y452 w60 h20 Hidden vRecMoveEnabled Checked" (MoveEnabled?1:0), "Move")
MainGui.SetFont("s9 w400 cB79AA0")
global DIRECTIONTEXTCtrl := MainGui.Add("Text", "x100 y452 w45 Hidden", "Direction")
MainGui.SetFont("s9 w400 cFFFFFF")
global RecMoveDirCtrl := MainGui.Add("DropDownList", "x160 y450 w45 Hidden Choose1 vRecMoveDirection", ["W", "A", "S", "D"])
MainGui.SetFont("s9 w400 cB79AA0")
global Tab2_Txt4 := MainGui.Add("Text", "x220 y452 Hidden", "Duration (ms):")
MainGui.SetFont("s9 w400 c000000")
global RecMoveDurCtrl := MainGui.Add("Edit", "x310 y450 w50 h22 Hidden vRecMoveDuration", 1000)

MainGui.SetFont("s11 w400 cFFFFFF", "Segoe UI")
global Tab2_Btn1 := MainGui.Add("Text", "x30  y545 w300 h40 Center Background120B0D +Border 0x200 Hidden", "Start Recording")
Tab2_Btn1.OnEvent("Click", StartRecording)
MainGui.SetFont("s11 w400 c808080", "Segoe UI")
global Tab2_Btn2 := MainGui.Add("Text", "x340 y545 w330 h40 Center Background120B0D +Border 0x200 Hidden", "Stop")
Tab2_Btn2.OnEvent("Click", StopRecord)
SetButtonRole(Tab2_Btn1, "Primary")
Tab2_Btn2.ThemeRole := "Danger"

HoverEffect_btns.Push(Tab2_Btn1) 

global Tab2Ctrls := [Tab2_Title, Tab2_Line1, Tab2_Lbl1, RecMapsD, Tab2_Lbl2, RecDiffCtrl,
    Tab2_Lbl3, RecModifiersCtrl, Tab2_Info2, Tab2_Lbl4, Tab2_Info1, Tab2_Line2, Tab2_Line3,
    RecAutoChainCtrl, RecAutoCaravanCtrl, RecAutoDropCtrl, RecAutoSkipCtrl, RecAbilitySpamCtrl,
    RecAbstractSlotEnabledCtrl, RecAbstractSlotLabel, RecAbstractSlotInfo,
    Tab2_Info, RecMoveCtrl, DIRECTIONTEXTCtrl, RecMoveDirCtrl, Tab2_Txt4, RecMoveDurCtrl,
    Tab2_Btn1, Tab2_Btn2]
for ctrl in RecTowerLabels
    Tab2Ctrls.Push(ctrl)
for ctrl in RecTowerCtrls
    Tab2Ctrls.Push(ctrl)
for ctrl in RecAbstractSlotCtrls
    Tab2Ctrls.Push(ctrl)

; tab 3 - MULTIPLAYER ===========================

MainGui.SetFont("s10 w600 cEF2B2D", "Segoe UI")
global Tab3_Title := MainGui.Add("Text", "x30 y95  w200 h22 Hidden", "Usernames")
global Tab3_Line1 := MainGui.Add("Progress", "x30 y118 w640 h1 Hidden Background43242B", 0)

MainGui.SetFont("s9 w400 cB79AA0")
global Tab3_HostNm := MainGui.Add("Text", "x30 y140 w170 BackgroundTrans h20 Hidden", "Host Username:")
MainGui.SetFont("s9 w400 c000000")
global Tab3_HostNm_EDIT := MainGui.Add("Edit", "x130 y137 w540 Hidden vHostName", HostName)

MainGui.SetFont("s9 w400 cB79AA0")
global Tab3_PartyMemb := MainGui.Add("Text", "x30 y175 w165 BackgroundTrans h20 Hidden", "Party Members:")
MainGui.SetFont("s9 w400 c000000")
global Tab3_PartyMemb_Edit := MainGui.Add("Edit", "x130 y168 w540 Hidden vPartyMembersStr", PartyMembers)

MainGui.SetFont("s10 w600 cEF2B2D", "Segoe UI")
global Tab3_Title2 := MainGui.Add("Text", "x30 y201  w200 h22 Hidden", "Settings")
global Tab3_Line2 := MainGui.Add("Progress", "x30 y224 w640 h1 Hidden Background43242B", 0)

MainGui.SetFont("s9 w400 cffffff")
global Tab3_RoleTxt := MainGui.Add("Text", "x30 y240 w60 BackgroundTrans h20 Hidden", "You are:")

global Tab3_Role_Host := MainGui.Add("Radio", "x30 y260 w54 Hidden vPlayerRole Group " (PlayerRole != "Member" ? "Checked" : ""), "Host")
global Tab3_Role_Member := MainGui.Add("Radio", "x85 y260 w80 Hidden " (PlayerRole == "Member" ? "Checked" : ""), "Member")

global Tab3_LConditionTxt := MainGui.Add("Text", "x30 y290 w170 BackgroundTrans h20 Hidden", "Go back to lobby if:")

global Tab3_LCondition_All := MainGui.Add("Radio", "x30 y310 w144 Hidden vLeaveCondition Group " (LeaveCondition == "All" ? "Checked" : ""), "All members are gone")
global Tab3_LCondition_Any := MainGui.Add("Radio", "x175 y310 Hidden " (LeaveCondition == "Any" ? "Checked" : ""), "Any member is gone")

MainGui.SetFont("s10 w400 cFFFFFF")
global MultiplayerEnabledTGL := MainGui.Add("Checkbox", "x30 y368 Hidden vMultiplayerEnabled Checked" MultiplayerEnabled, "Enabled")
global Tab3_Line3 := MainGui.Add("Progress", "x30 y360 w640 h1 Hidden Background43242B", 0)

MainGui.SetFont("s11 w400 cFFFFFF")
global Tab3_Btn1 := MainGui.Add("Text", "x30 y545 w645 h40 Center Background120B0D +Border 0x200 Hidden", "Save all settings")
Tab3_Btn1.OnEvent("Click", SaveAllSettingsMULTIPLAYER)
SetButtonRole(Tab3_Btn1, "Primary")

HoverEffect_btns.Push(Tab3_Btn1)

MainGui.SetFont("s9 w400 cFFFFFF")
global Tab3_Info := MainGui.Add("Text", "x30 y400 w640 h100 Hidden", "The macro can now run simultaneously with other users. Just enter the host's username and the party members.`nHow to use:`n1. Enter the party leader's username in 'Host Username'.`n2. Enter other players' usernames in 'Party Members' (separated by commas).`n3. Click 'Save all settings'.")

TAB3.Push(Tab3_Title, Tab3_Line1, Tab3_HostNm, Tab3_HostNm_EDIT, Tab3_PartyMemb, Tab3_PartyMemb_Edit, Tab3_Line2, Tab3_Btn1, Tab3_Info, MultiplayerEnabledTGL, Tab3_RoleTxt, Tab3_Role_Host, Tab3_Role_Member, Tab3_Title2, Tab3_Line3, Tab3_LCondition_All, Tab3_LCondition_Any, Tab3_LConditionTxt)

; tab 4 - WEBHOOK ===========================

MainGui.SetFont("s10 w600 cEF2B2D", "Segoe UI")
global Tab4_Title := MainGui.Add("Text", "x30 y95  w200 h22 Hidden", "Discord Webhook")
global Tab4_Line1 := MainGui.Add("Progress", "x30 y118 w640 h1  Hidden Background43242B", 0)
global Tab4_ModeSwitch := MainGui.Add("Text", "x525 y94 w145 h24 Center Background120B0D +Border 0x200 Hidden", "Remote Bot")
Tab4_ModeSwitch.OnEvent("Click", SwitchDiscordRemoteView)
HoverEffect_btns.Push(Tab4_ModeSwitch)
MainGui.SetFont("s9 w400 cB79AA0")
MainGui.Add("Text", "x30 y135 w200 h20 Hidden vTab4_Lbl1", "Webhook URL:")
global Tab4_Lbl1 := MainGui["Tab4_Lbl1"]
MainGui.SetFont("s9 w400 c000000")
global WebhookLinkCtrl := MainGui.Add("Edit", "x30 y155 w640 h24 Hidden vWebhookLink", WebhookLink)
WebhookLinkCtrl.OnEvent("Change", CheckWebhookLink)
MainGui.SetFont("s9 w400 cFFFFFF")
global WebhookEnabledCtrl := MainGui.Add("Checkbox", "x30 y195 Hidden vWebhookEnabled Checked" WebhookEnabled, "Enable Webhook")
global Tab4_Line2 := MainGui.Add("Progress", "x30 y243 w640 h1 Hidden Background43242B", 0)
global SendCurrCtrl := MainGui.Add("Checkbox", "x30 y253 Hidden vSendCurrenciesEnabled Checked" SendCurrenciesEnabled, "Send Statistics")
SendCurrCtrl.OnEvent("Click", (CtrlObj, *) => CtrlObj.Value ? CheckOcrLanguage() : "")
global DebugLogsCtrl := MainGui.Add("Checkbox", "x140 y253 Hidden vWebhookDebugLogs Checked" WebhookDebugLogs, "Debug Logs")
global WebhookScreenshotsCtrl := MainGui.Add("Checkbox", "x235 y253 Hidden vWebhookScreenshots Checked" WebhookScreenshots, "Automatic screenshots")
global WebhookTriumphScreenshotsCtrl := MainGui.Add("Checkbox", "x385 y253 Hidden vWebhookTriumphScreenshots Checked" WebhookTriumphScreenshots, "Triumph and Loss screenshots")
global WebhookSepatateTriumphScreenshotsCtrl := MainGui.Add("Checkbox", "x30 y283 Hidden vWebhookSepatateTriumphScreenshots Checked" WebhookSepatateTriumphScreenshots, "Send Triumph/Loss to a separate channel")
MainGui.SetFont("s9 w400 c000000")
global WebhookLinkCtrl2 := MainGui.Add("Edit", "x285 y283 w360 h24 Hidden vWebhookLink2", WebhookLink2)
MainGui.SetFont("s9 w400 cFFFFFF")
WebhookLinkCtrl2.OnEvent("Change", CheckWebhookLink2)
EnableWebhookLink2()
WebhookSepatateTriumphScreenshotsCtrl.OnEvent("Click", EnableWebhookLink2)
global Tab4_Info := MainGui.Add("Text", "x30 y400 w640 h100 Hidden", "Webhook sends real-time logs, screenshots, and currency stats to your Discord server.`nUseful to check if your macro is working while being outside.`nHow to get a webhook URL: Create your own Discord Server > Open any channel's settings > Integrations > Create Webhook > Copy Webhook URL.")
MainGui.SetFont("s12 w400 cFFFFFF")
global Tab4_Btn1 := MainGui.Add("Text", "x30  y545 w300 h40 Center Background120B0D +Border 0x200 Hidden", "Test Webhook")
Tab4_Btn1.OnEvent("Click", TestWebhook)
global Tab4_Btn2 := MainGui.Add("Text", "x340 y545 w330 h40 Center Background120B0D +Border 0x200 Hidden", "Save webhook settings")
Tab4_Btn2.OnEvent("Click", SaveWebhookSettings)
SetButtonRole(Tab4_Btn2, "Primary")

HoverEffect_btns.Push(Tab4_Btn1) 
HoverEffect_btns.Push(Tab4_Btn2) 

; Optional Discord remote bot. It is disabled by default and uses Discord slash
; commands via the bundled local gateway sidecar; it does not share webhook state.
MainGui.SetFont("s9 w400 cB79AA0")
global Tab4_BotTokenLabel := MainGui.Add("Text", "x30 y135 w240 h20 Hidden", "Bot token (stored locally):")
MainGui.SetFont("s9 w400 cFFFFFF")
global Tab4_BotTokenCtrl := MainGui.Add("Edit", "x30 y155 w640 h24 Password Hidden vKronoxBotToken", KronoxBotToken)
global Tab4_BotEnabledCtrl := MainGui.Add("Checkbox", "x30 y195 Hidden vKronoxBotEnabled", "Enable slash-command remote bot")
Tab4_BotEnabledCtrl.Value := KronoxBotEnabled

MainGui.SetFont("s9 w400 cB79AA0")
global Tab4_BotApplicationLabel := MainGui.Add("Text", "x30 y225 w250 h20 Hidden", "Application ID:")
global Tab4_BotOwnerLabel := MainGui.Add("Text", "x360 y225 w280 h20 Hidden", "Owner Discord user ID:")
MainGui.SetFont("s9 w400 cFFFFFF")
global Tab4_BotApplicationCtrl := MainGui.Add("Edit", "x30 y245 w300 h24 Hidden vKronoxBotApplicationID", KronoxBotApplicationID)
global Tab4_BotOwnerCtrl := MainGui.Add("Edit", "x360 y245 w310 h24 Hidden vKronoxBotOwnerUserID", KronoxBotOwnerUserID)

MainGui.SetFont("s9 w400 cB79AA0")
global Tab4_BotChannelLabel := MainGui.Add("Text", "x30 y285 w270 h20 Hidden", "Command response channel ID:")
global Tab4_BotGuildLabel := MainGui.Add("Text", "x360 y285 w310 h20 Hidden", "Guild/server ID (recommended):")
MainGui.SetFont("s9 w400 cFFFFFF")
global Tab4_BotChannelCtrl := MainGui.Add("Edit", "x30 y305 w300 h24 Hidden vKronoxBotChannelID", KronoxBotChannelID)
global Tab4_BotGuildCtrl := MainGui.Add("Edit", "x360 y305 w310 h24 Hidden vKronoxBotGuildID", KronoxBotGuildID)
global Tab4_BotInfo := MainGui.Add("Text", "x30 y350 w640 h145 Hidden BackgroundTrans",
    "Status: /status, /health, /screenshot    Control: /start, /stop, /safe-stop, /queue`n"
    . "Strategy: /switch slot:1 or slot:2, /loadout, /best — switches only at a safe run boundary; Abstract slots stay protected.`n"
    . "Next match only: /timescale mode:off|1.5x|2x, /modifiers action:set|add|remove|clear|reset names:Exploding,Speedy`n"
    . "Setup: invite with bot and applications.commands scopes. Enable Discord Developer Mode to copy IDs. Leave Interactions Endpoint URL blank.`n"
    . "Safety: only the configured Owner ID can control the macro. The bot uses this PC's local Gateway sidecar; never share the token.")

MainGui.SetFont("s12 w400 cFFFFFF")
global Tab4_BotTest := MainGui.Add("Text", "x30 y545 w300 h40 Center Background120B0D +Border 0x200 Hidden", "Test remote bot")
Tab4_BotTest.OnEvent("Click", TestKronoxDiscordBot)
global Tab4_BotSave := MainGui.Add("Text", "x340 y545 w330 h40 Center Background120B0D +Border 0x200 Hidden", "Save + start remote bot")
Tab4_BotSave.OnEvent("Click", SaveKronoxDiscordBotSettings)
SetButtonRole(Tab4_BotSave, "Primary")
HoverEffect_btns.Push(Tab4_BotTest)
HoverEffect_btns.Push(Tab4_BotSave)

global DiscordWebhookTabCtrls := [Tab4_Lbl1, WebhookLinkCtrl, WebhookEnabledCtrl, Tab4_Line2,
    SendCurrCtrl, DebugLogsCtrl, WebhookScreenshotsCtrl, WebhookTriumphScreenshotsCtrl,
    WebhookSepatateTriumphScreenshotsCtrl, WebhookLinkCtrl2, Tab4_Info, Tab4_Btn1, Tab4_Btn2]
global DiscordBotTabCtrls := [Tab4_BotTokenLabel, Tab4_BotTokenCtrl, Tab4_BotEnabledCtrl,
    Tab4_BotApplicationLabel, Tab4_BotOwnerLabel, Tab4_BotApplicationCtrl, Tab4_BotOwnerCtrl,
    Tab4_BotChannelLabel, Tab4_BotGuildLabel, Tab4_BotChannelCtrl, Tab4_BotGuildCtrl,
    Tab4_BotInfo, Tab4_BotTest, Tab4_BotSave]

;TAB 5 - SETTINGS ==========================

MainGui.SetFont("s10 w600 cEF2B2D", "Segoe UI")
global Tab5_Section1 := MainGui.Add("Text", "x30 y95  w200 h22 Hidden", "TDS Keybinds")
global Tab5_Line1 := MainGui.Add("Progress", "x30 y118 w250 h1  Hidden Background43242B", 0)

MainGui.SetFont("s8 w400 cB79AA0", "Segoe UI")
global Tab5_Lbl1 := MainGui.Add("Text", "x30 y135 w70 h16 Hidden", "Call of Arms:")
MainGui.SetFont("s8 w400 c000000")
global ChainKeyCtrl := MainGui.Add("Edit", "x105 y132 w40 h18 Center Limit1 Hidden", ChainKey)

MainGui.SetFont("s8 w400 cB79AA0")
global Tab5_Lbl2 := MainGui.Add("Text", "x152 y135 w80 h16 Hidden", "Drop The Beat:")
MainGui.SetFont("s8 w400 c000000")
global BeatKeyCtrl := MainGui.Add("Edit", "x238 y132 w40 h18 Center Limit1 Hidden", BeatKey)

MainGui.SetFont("s8 w400 cB79AA0")
global Tab5_Lbl3 := MainGui.Add("Text", "x30 y160 h16 Hidden", "S. Caravan:")
MainGui.SetFont("s8 w400 c000000")
global CaravanKeyCtrl := MainGui.Add("Edit", "x105 y157 w40 h18 Center Limit1 Hidden", CaravanKey)

MainGui.SetFont("s8 w400 cB79AA0")
global Tab5_Lbl44 := MainGui.Add("Text", "x152 y160 w80 h16 Hidden", "Raise the Dead:")
MainGui.SetFont("s8 w400 c000000")
global RaiseDeadKeyCtrl := MainGui.Add("Edit", "x238 y157 w40 h18 Center Limit1 Hidden", RaiseDeadKey)

MainGui.SetFont("s8 w400 cB79AA0")
global Tab5_Lbl55 := MainGui.Add("Text", "x30 y185 h16 Hidden", "Hologram:")
MainGui.SetFont("s8 w400 c000000")
global HologramKeyCtrl := MainGui.Add("Edit", "x105 y182 w40 h18 Center Limit1 Hidden", HologramKey)

MainGui.SetFont("s8 w400 cB79AA0")
global Tab5_Lbl56 := MainGui.Add("Text", "x152 y185 h16 Hidden", "Reposition:")
MainGui.SetFont("s8 w400 c000000")
global RepoKeyCtrl := MainGui.Add("Edit", "x238 y182 w40 h18 Center Limit1 Hidden", RepoKey)
MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global Tab5_Help11 := MainGui.Add("Text", "x280 y182 w18 h18 0x200 Center Hidden", "?")
Tab5_Help11.OnEvent("Click", HelpBrawler)

MainGui.SetFont("s8 w400 cB79AA0", "Segoe UI")
global Tab5_LblSwatVan := MainGui.Add("Text", "x30 y210 w70 h16 Hidden", "SWAT Van:")
MainGui.SetFont("s8 w400 c000000")
global SwatVanKeyCtrl := MainGui.Add("Edit", "x105 y207 w40 h18 Center Limit1 Hidden", SwatVanKey)

MainGui.SetFont("s9 w400 cB79AA0")
global Tab5_Lbl99 := MainGui.Add("Text", "x183 y248 BackgroundTrans Hidden", "cancel:")
MainGui.SetFont("s8 w400 c000000")
global CancelPlacementKeyCtrl := MainGui.Add("Edit", "x230 y248 w17 h17 Center Limit1 Hidden", CancelPlacementKey)

MainGui.SetFont("s9 w400 cB79AA0")
global Tab5_LblUPG := MainGui.Add("Text", "x30 y248 BackgroundTrans Hidden", "upgrade:")
MainGui.SetFont("s8 w400 c000000")
global UpgradeTowerGCtrl := MainGui.Add("Edit", "x85 y248 w17 h17 Center Limit1 Hidden", UpgradeTowerGKey)

MainGui.SetFont("s9 w400 cB79AA0")
global Tab5_LblUPGBTM := MainGui.Add("Text", "x108 y248 BackgroundTrans Hidden", "bottom:")
MainGui.SetFont("s8 w400 c000000")
global UpgradeTowerGBCtrl := MainGui.Add("Edit", "x158 y248 W17 h17 Center Limit1 Hidden", UpgradeTowerGBKey)

MainGui.SetFont("s9 w400 cFFFFFF")

MainGui.SetFont("s10 w600 cEF2B2D", "Segoe UI")
global Tab5_Section2 := MainGui.Add("Text", "x310 y95  w200 h22 Hidden BackgroundTrans", "Macro Settings")
global Tab5_Line2    := MainGui.Add("Progress", "x310 y118 w360 h1  Hidden Background43242B", 0)

MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global UseUpgradeHCtrl := MainGui.Add("Checkbox", "x310 y135 Hidden", "Use Hotkeys for Upgrading")
UseUpgradeHCtrl.Value := (UseHForUpgrade = 1)
global Tab5_Help6 := MainGui.Add("Text", "x475 y135 w18 h18 0x200 Center Hidden", "?")
Tab5_Help6.OnEvent("Click", HelpAutoCameraCorrection)

global UseRestartBtnCtrl := MainGui.Add("Checkbox", "x310 y160 Hidden", "Click Restart button")
UseRestartBtnCtrl.Value := (UseRestartBtn = "1" || UseRestartBtn = 1)
global Tab5_Help4 := MainGui.Add("Text", "x475 y158 w18 h18 0x200 Center Hidden", "?")
Tab5_Help4.OnEvent("Click", HelpRestartBtn)

global UsePlayAgainBtnCtrl := MainGui.Add("Checkbox", "x310 y185 Hidden", "Click Play Again button")
UsePlayAgainBtnCtrl.Value := (UsePlayAgainBtn = "1" || UsePlayAgainBtn = 1)
global Tab5_Help5 := MainGui.Add("Text", "x475 y183 w18 h18 0x200 Center Hidden", "?")
Tab5_Help5.OnEvent("Click", HelpPlayAgainBtn)

global CheckTheMapCtrl := MainGui.Add("Checkbox", "x310 y210 Hidden", "Check the map")
CheckTheMapCtrl.Value := (CheckTheMap = "1" || CheckTheMap = 1)
global Tab5_Help7 := MainGui.Add("Text", "x475 y207 w18 h18 0x200 Center Hidden", "?")
Tab5_Help7.OnEvent("Click", HelpCheckTheMap)

global UseNumbersForHotbarCtrl := MainGui.Add("Checkbox", "x310 y235 Hidden", "Use Numbers for Hotbar")
UseNumbersForHotbarCtrl.Value := (UseNumbersForHotbar = "1" || UseNumbersForHotbar = 1)

global CollectPlaytimeRewardsCtrl := MainGui.Add("Checkbox", "x510 y185 Hidden", "Collect playtime rewards")
CollectPlaytimeRewardsCtrl.Value := (CollectPlaytimeRewards = "1" || CollectPlaytimeRewards = 1)

global DebugConsoleCtrl := MainGui.Add("Checkbox", "x570 y135 Hidden", "Debug Logs")
DebugConsoleCtrl.Value := (DebugConsole = "1" || DebugConsole = 1)

global PotatoModeCtrl := MainGui.Add("Checkbox", "x570 y160 Hidden", "Potato Mode")
PotatoModeCtrl.Value := (PotatoMode = 1)

global LegacyModeCtrl := MainGui.Add("Checkbox", "x510 y245 Hidden", "Legacy image mode")
LegacyModeCtrl.Value := (LegacyMode = "1" || LegacyMode = 1)
LegacyModeCtrl.OnEvent("Click", LegacyModeInfo)

MainGui.SetFont("s9 w400 cFFFFFF")
global UpgradeDelayLbl := MainGui.Add("Text", "x468 y238 w100 h20 Hidden BackgroundTrans", "Upgrade delay:")
global UpgradeDelayCtrl := MainGui.Add("Edit", "x570 y234 w58 h22 Center Number Limit4 Hidden", UpgradeDelay)
global UpgradeDelayUnitLbl := MainGui.Add("Text", "x632 y238 w40 h20 Hidden BackgroundTrans", "ms")

MainGui.SetFont("s9 w400 cB79AA0")
global Tab1_Lbl3 := MainGui.Add("Text", "x530 y220 w100 h20 Hidden BackgroundTrans", "Timescale:")
MainGui.SetFont("s9 w400 cFFFFFF")
global TimeScaleModeCtrl := MainGui.Add("DropDownList", "x595 y216 w80 Hidden", ["OFF","1.5x","2x"])
TimeScaleModeCtrl.Text := TimeScaleMode

MainGui.SetFont("s9 w400 cFFFFFF")
global MouseSpeedLbl := MainGui.Add("Text", "x310 y270 w110 h20 Hidden BackgroundTrans", "Mouse Speed:")
global MouseSpeedTxt := MainGui.Add("Text", "x389 y270 w26 Hidden", DefaultMouseSpeed)
global MouseSpeedUpDown := MainGui.Add("UpDown", "Range1-3 Hidden", DefaultMouseSpeed)
MouseSpeedUpDown.OnEvent("Change", (ctrl, *) => MouseSpeedTxt.Value := ctrl.Value)

global MouseDelayLbl := MainGui.Add("Text", "x435 y270 w90 h20 Hidden BackgroundTrans", "Mouse Delay:")
global MouseDelayTxt := MainGui.Add("Text", "x509 y270 w32 Hidden", MouseDelay)
global MouseDelayUpDown := MainGui.Add("UpDown", "Range3-75 Hidden", MouseDelay)
MouseDelayUpDown.OnEvent("Change", (ctrl, *) => MouseDelayTxt.Value := ctrl.Value)

global KeyDelayLbl := MainGui.Add("Text", "x565 y270 w90 h20 Hidden BackgroundTrans", "Key Delay:")
global KeyDelayTxt := MainGui.Add("Text", "x625 y270 w32 Hidden", KeyDelay)
global KeyDelayUpDown := MainGui.Add("UpDown", "Range5-100 Hidden", KeyDelay)
KeyDelayUpDown.OnEvent("Change", (ctrl, *) => KeyDelayTxt.Value := ctrl.Value)

MainGui.SetFont("s10 w600 cEF2B2D", "Segoe UI")
global Tab5_Section3 := MainGui.Add("Text", " BackgroundTrans x30 y272 w200 h22 Hidden", "Recording Hotkeys")
global Tab5_Line3    := MainGui.Add("Progress", "x30 y295 w640 h1  Hidden Background43242B", 0)

MainGui.SetFont("s9 w400 cB79AA0")
global PlcTowerTEXT := MainGui.Add("Text", "x30 y304 w95 h20 Hidden", "Place Tower:")
global PlaceTowerKeyCtrl := MainGui.Add("Hotkey", "x130 y304 w110 h20 Center Hidden", PlaceTowerKey)

global UpgTowerTEXT := MainGui.Add("Text", "x30 y334 w95 h20 Hidden", "Upgrade Tower:")
global UpgradeTowerKeyCtrl := MainGui.Add("Hotkey", "x130 y334 w110 h20 Center Hidden", UpgradeTowerKey)

global AlignCamTEXT := MainGui.Add("Text", "x30 y366 w95 h20 Hidden", "Align Camera:")
global AlignCameraKeyCtrl := MainGui.Add("Hotkey", "x130 y366 w110 h20 Center Hidden", AlignCameraKey)

global DjTrackTEXT := MainGui.Add("Text", "x255 y304 w95 h20 Hidden", "Change DJ Track:")
global ChangeDJTrackKeyCtrl := MainGui.Add("Hotkey", "x355 y304 w110 h20 Center Hidden", ChangeDJTrackKey)

global SellTowTEXT := MainGui.Add("Text", "x255 y334 w95 h20 Hidden", "Sell Tower:")
global SellTowerKeyCtrl := MainGui.Add("Hotkey", "x355 y334 w110 h20 Center Hidden", SellTowerKey)

global DelRecTEXT := MainGui.Add("Text", "x255 y366 w95 h20 Hidden", "Delete Record:")
global DeleteTowerRecordingKeyCtrl := MainGui.Add("Hotkey", "x355 y366 w110 h20 Center Hidden", DeleteTowerRecordingKey)

global RecInputsTEXT := MainGui.Add("Text", "x480 y304 w95 h20 Hidden", "Record Inputs:")
global RecordInputsKeyCtrl := MainGui.Add("Hotkey", "x580 y304 w90 h20 Center Hidden", RecordInputsKey)

global HoloTEXT := MainGui.Add("Text", "x480 y334 w95 h20 Hidden", "Hologram Tower:")
global HoloKeyCtrl := MainGui.Add("Hotkey", "x580 y334 w90 h20 Center Hidden", HoloKey)

global ChangeTargetsTEXT := MainGui.Add("Text", "x480 y366 w95 h20 Hidden", "Change Target:")
global ChangeTargetsKeyCtrl := MainGui.Add("Hotkey", "x580 y366 w90 h20 Center Hidden", ChangeTargetsKey)

global RaiseDeadTEXT := MainGui.Add("Text", "x480 y396 w95 h20 Hidden", "Raise the Dead:")
global UseRaiseDeadKeyCtrl := MainGui.Add("Hotkey", "x580 y396 w90 h20 Center Hidden", UseRaiseDeadKey)

global Tab5_Line4 := MainGui.Add("Progress", "x30 y423 w640 h1 Hidden Background43242B", 0)

MainGui.SetFont("s9 w400 cB79AA0")
global Tab5_Lbl4 := MainGui.Add("Text", "x30 y435 w100 h20 Hidden", "VIP Server Link:")
MainGui.SetFont("s9 w400 c000000")
global VipLinkCtrl := MainGui.Add("Edit", "x30 y460 w640 h24 Hidden", VipLink)
MainGui.SetFont("s11 w400 cFFFFFF")
VipLinkCtrl.OnEvent("Change", CheckVipLink)

global UseVipServerCtrl := MainGui.Add("Checkbox", "x30 y495 Hidden", "Use VIP Server")
UseVipServerCtrl.Value := (UseVipServer = "1" || UseVipServer = 1)

global AlwaysOnTopCtrl := MainGui.Add("Checkbox", "x160 y495 Hidden", "Always On Top")
AlwaysOnTopCtrl.Value := (AlwaysOnTop = "1" || AlwaysOnTop = 1)

MainGui.SetFont("s10 w600 cEF2B2D", "Segoe UI")
global TowerXPSection := MainGui.Add("Text", "x30 y523 w200 h22 Hidden BackgroundTrans", "Tower XP Tracker")
global TowerXPLine := MainGui.Add("Progress", "x30 y546 w640 h1 Hidden Background43242B", 0)

MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global TowerXPEnabledCtrl := MainGui.Add("Checkbox", "x30 y562 w150 h22 Hidden", "Enable XP tracking")
TowerXPEnabledCtrl.Value := TowerXPTrackerEnabled
TowerXPEnabledCtrl.OnEvent("Click", UpdateTowerXPControlState)

MainGui.SetFont("s8 w400 cB79AA0", "Segoe UI")
global TowerXPStopModeLabelCtrl := MainGui.Add("Text", "x250 y565 w95 h18 Hidden", "Stop macro when:")
MainGui.SetFont("s8 w400 c000000", "Segoe UI")
global TowerXPStopModeCtrl := MainGui.Add("DropDownList", "x350 y560 w180 Hidden", ["Never", "Any selected tower", "All selected towers"])
TowerXPStopModeCtrl.Text := TowerXPStopModeLabel(TowerXPStopMode)
TowerXPStopModeCtrl.OnEvent("Change", UpdateTowerXPControlState)

MainGui.SetFont("s8 w700 cFF6B6D", "Segoe UI")
global TowerXPSkinWarning := MainGui.Add("Text", "x30 y596 w640 h36 Hidden Background180E11 +Border 0x200", "  DEFAULT SKINS REQUIRED — tracked towers MUST use their default skin. Alternate skins cannot be identified safely and will be ignored.")

MainGui.SetFont("s8 w600 cB79AA0", "Segoe UI")
global TowerXPHeaderTrack := MainGui.Add("Text", "x30 y642 w35 h18 Center Hidden", "USE")
global TowerXPHeaderName := MainGui.Add("Text", "x70 y642 w110 h18 Hidden", "TOWER")
global TowerXPHeaderLevel := MainGui.Add("Text", "x195 y642 w55 h18 Center Hidden", "LEVEL")
global TowerXPHeaderXP := MainGui.Add("Text", "x268 y642 w82 h18 Center Hidden", "XP IN LEVEL")
global TowerXPHeaderNext := MainGui.Add("Text", "x365 y642 w130 h18 Center Hidden", "NEXT LEVEL")
global TowerXPHeaderStop := MainGui.Add("Text", "x525 y642 w135 h18 Center Hidden", "STOP TARGET")

global TowerXPRows := []
global TowerXPTrackCtrls := []
global TowerXPLevelCtrls := []
global TowerXPCurrentXPCtrls := []
global TowerXPRequirementCtrls := []
global TowerXPStopTargetCtrls := []
global TowerXPSettingsCtrls := [TowerXPSection, TowerXPLine, TowerXPEnabledCtrl,
    TowerXPStopModeLabelCtrl, TowerXPStopModeCtrl, TowerXPSkinWarning,
    TowerXPHeaderTrack, TowerXPHeaderName, TowerXPHeaderLevel, TowerXPHeaderXP,
    TowerXPHeaderNext, TowerXPHeaderStop]

for towerIndex, towerDef in TowerXPDefinitions() {
    rowY := 666 + ((towerIndex - 1) * 28)
    section := TowerXPSectionName(towerDef.name)
    tracked := Integer(IniRead(SettingsFile, section, "Tracked", 0))
    level := Integer(IniRead(SettingsFile, section, "Level", 0))
    currentXP := Integer(IniRead(SettingsFile, section, "XP", 0))
    stopTarget := Integer(IniRead(SettingsFile, section, "StopTarget", 0))
    normalized := TowerXPAdvance(towerDef, level, currentXP)

    MainGui.SetFont("s8 w400 cFFFFFF", "Segoe UI")
    trackCtrl := MainGui.Add("Checkbox", "x39 y" rowY " w18 h20 Hidden", "")
    trackCtrl.Value := tracked
    trackCtrl.OnEvent("Click", UpdateTowerXPControlState)
    nameCtrl := MainGui.Add("Text", "x70 y" (rowY + 2) " w112 h18 Hidden", towerDef.name)

    MainGui.SetFont("s8 w400 c000000", "Segoe UI")
    levelCtrl := MainGui.Add("Edit", "x198 y" rowY " w48 h20 Center Number Limit2 Hidden", normalized.level)
    levelCtrl.OnEvent("Change", UpdateTowerXPControlState)
    xpCtrl := MainGui.Add("Edit", "x276 y" rowY " w68 h20 Center Number Limit6 Hidden", normalized.xp)
    xpCtrl.OnEvent("Change", UpdateTowerXPControlState)

    MainGui.SetFont("s8 w400 cB79AA0", "Segoe UI")
    requirementText := normalized.isMax ? "MAX LEVEL" : normalized.xp "/" normalized.nextRequired " XP"
    requirementCtrl := MainGui.Add("Text", "x365 y" (rowY + 2) " w130 h18 Center Hidden", requirementText)
    MainGui.SetFont("s8 w400 cFFFFFF", "Segoe UI")
    targetCtrl := MainGui.Add("Checkbox", "x580 y" rowY " w18 h20 Hidden", "")
    targetCtrl.Value := stopTarget
    targetCtrl.OnEvent("Click", UpdateTowerXPControlState)

    TowerXPTrackCtrls.Push(trackCtrl)
    TowerXPLevelCtrls.Push(levelCtrl)
    TowerXPCurrentXPCtrls.Push(xpCtrl)
    TowerXPRequirementCtrls.Push(requirementCtrl)
    TowerXPStopTargetCtrls.Push(targetCtrl)
    TowerXPRows.Push({definition: towerDef, track: trackCtrl, name: nameCtrl, level: levelCtrl,
        xp: xpCtrl, requirement: requirementCtrl, target: targetCtrl})
    for rowCtrl in [trackCtrl, nameCtrl, levelCtrl, xpCtrl, requirementCtrl, targetCtrl]
        TowerXPSettingsCtrls.Push(rowCtrl)
}

; Kronox automation lab lives inside the existing scrollable Settings page so
; the title bar remains compact and every runtime-affecting option is saved by
; the same explicit Save action.
MainGui.SetFont("s10 w600 cEF2B2D", "Segoe UI")
global EvolutionQueueSection := MainGui.Add("Text", "x30 y890 w260 h22 Hidden BackgroundTrans", "Abstract Evolution Queue")
global EvolutionQueueLine := MainGui.Add("Progress", "x30 y913 w640 h1 Hidden Background43242B", 0)
MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global EvolutionQueueEnabledCtrl := MainGui.Add("Checkbox", "x30 y928 w145 h22 Hidden", "Enable evolution queue")
EvolutionQueueEnabledCtrl.Value := EvolutionQueueEnabled
global EvolutionQueueAutoEquipCtrl := MainGui.Add("Checkbox", "x200 y928 w185 h22 Hidden", "Auto-equip the next batch")
EvolutionQueueAutoEquipCtrl.Value := EvolutionQueueAutoEquip
MainGui.SetFont("s8 w400 cB79AA0", "Segoe UI")
global EvolutionQueueLabelCtrl := MainGui.Add("Text", "x30 y958 w90 h18 Hidden", "QUEUE ORDER")
MainGui.SetFont("s8 w400 c000000", "Segoe UI")
global EvolutionQueueTowersCtrl := MainGui.Add("Edit", "x125 y954 w545 h22 Hidden", EvolutionQueueTowers)
DllCall("SendMessage", "Ptr", EvolutionQueueTowersCtrl.Hwnd, "UInt", 0x1501, "Ptr", 1,
    "Str", "Example: Operator, Juggernaut, Kingpin")
MainGui.SetFont("s8 w400 cB79AA0", "Segoe UI")
global EvolutionQueueHelpCtrl := MainGui.Add("Text", "x30 y982 w640 h32 Hidden BackgroundTrans",
    "Type Tower Evolution names separated by commas, in the order you want them leveled.`nExample: Operator, Juggernaut, Kingpin. One tower is assigned to each active Abstract slot.")
global EvolutionQueueStatusCtrl := MainGui.Add("Text", "x30 y1018 w640 h38 Hidden Background180E11 +Border 0x200",
    "  Current slots: " KronoxEvolutionAssignmentText(SettingsFile) "`n  At level 20, the finished tower leaves the batch and the next name moves in.")

MainGui.SetFont("s10 w600 cEF2B2D", "Segoe UI")
global AnalyticsLabSection := MainGui.Add("Text", "x30 y1068 w260 h22 Hidden BackgroundTrans", "Profiler + Boost Analytics")
global AnalyticsLabLine := MainGui.Add("Progress", "x30 y1091 w640 h1 Hidden Background43242B", 0)
MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global StrategyProfilerEnabledCtrl := MainGui.Add("Checkbox", "x30 y1106 w170 h22 Hidden", "Profile strategy steps")
StrategyProfilerEnabledCtrl.Value := StrategyProfilerEnabled
global WeekendXPBoostCtrl := MainGui.Add("Checkbox", "x220 y1106 w180 h22 Hidden", "Weekend 2x XP context")
WeekendXPBoostCtrl.Value := WeekendXPBoostEnabled
global VIPXPBoostCtrl := MainGui.Add("Checkbox", "x420 y1106 w115 h22 Hidden", "VIP 1.25x XP")
VIPXPBoostCtrl.Value := VIPXPBoostEnabled
MainGui.SetFont("s8 w400 cB79AA0", "Segoe UI")
global OtherXPBoostLabelCtrl := MainGui.Add("Text", "x545 y1109 w75 h18 Hidden", "OTHER XP x")
MainGui.SetFont("s8 w400 c000000", "Segoe UI")
global OtherXPBoostCtrl := MainGui.Add("Edit", "x625 y1105 w45 h22 Center Hidden", OtherXPBoostMultiplier)
MainGui.SetFont("s8 w400 cB79AA0", "Segoe UI")
global ProfilerStatusCtrl := MainGui.Add("Text", "x30 y1136 w640 h22 Hidden BackgroundTrans", "Last profile: " KronoxProfilerSummary(StateFile))

MainGui.SetFont("s10 w600 cEF2B2D", "Segoe UI")
global ResourceBudgetSection := MainGui.Add("Text", "x30 y1170 w260 h22 Hidden BackgroundTrans", "Resource Budget Guard")
global ResourceBudgetLine := MainGui.Add("Progress", "x30 y1193 w640 h1 Hidden Background43242B", 0)
MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global TimeScaleBudgetEnabledCtrl := MainGui.Add("Checkbox", "x30 y1208 w165 h22 Hidden", "Guard timescale tickets")
TimeScaleBudgetEnabledCtrl.Value := TimeScaleBudgetEnabled
MainGui.SetFont("s8 w400 cB79AA0", "Segoe UI")
global TicketBalanceLabelCtrl := MainGui.Add("Text", "x210 y1211 w55 h18 Hidden", "BALANCE")
global TicketReserveLabelCtrl := MainGui.Add("Text", "x330 y1211 w55 h18 Hidden", "RESERVE")
global TicketSessionLabelCtrl := MainGui.Add("Text", "x450 y1211 w90 h18 Hidden", "SESSION CAP (0=∞)")
MainGui.SetFont("s8 w400 c000000", "Segoe UI")
global TicketBalanceCtrl := MainGui.Add("Edit", "x270 y1207 w48 h22 Center Number Limit6 Hidden", TimeScaleTicketBalance)
global TicketReserveCtrl := MainGui.Add("Edit", "x390 y1207 w48 h22 Center Number Limit6 Hidden", TimeScaleTicketReserve)
global TicketSessionCtrl := MainGui.Add("Edit", "x550 y1207 w55 h22 Center Number Limit6 Hidden", TimeScaleTicketMaxSession)
MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global ConsumableBudgetEnabledCtrl := MainGui.Add("Checkbox", "x30 y1238 w165 h22 Hidden", "Guard consumable steps")
ConsumableBudgetEnabledCtrl.Value := ConsumableBudgetEnabled
MainGui.SetFont("s8 w400 cB79AA0", "Segoe UI")
global ConsumableRunLabelCtrl := MainGui.Add("Text", "x210 y1241 w105 h18 Hidden", "MAX / RUN (0=∞)")
global ConsumableSessionLabelCtrl := MainGui.Add("Text", "x390 y1241 w125 h18 Hidden", "MAX / SESSION (0=∞)")
MainGui.SetFont("s8 w400 c000000", "Segoe UI")
global ConsumableRunCtrl := MainGui.Add("Edit", "x320 y1237 w48 h22 Center Number Limit4 Hidden", ConsumableMaxPerRun)
global ConsumableSessionCtrl := MainGui.Add("Edit", "x520 y1237 w55 h22 Center Number Limit5 Hidden", ConsumableMaxPerSession)

MainGui.SetFont("s10 w600 cEF2B2D", "Segoe UI")
global UpdateCanarySection := MainGui.Add("Text", "x30 y1278 w260 h22 Hidden BackgroundTrans", "TDS Update Canary")
global UpdateCanaryLine := MainGui.Add("Progress", "x30 y1301 w640 h1 Hidden Background43242B", 0)
MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global UpdateCanaryEnabledCtrl := MainGui.Add("Checkbox", "x30 y1316 w205 h22 Hidden", "Guard the first run after updates")
UpdateCanaryEnabledCtrl.Value := UpdateCanaryEnabled
MainGui.SetFont("s8 w400 cB79AA0", "Segoe UI")
global TDSVersionOverrideLabelCtrl := MainGui.Add("Text", "x260 y1319 w145 h18 Hidden", "VERSION OVERRIDE (optional)")
MainGui.SetFont("s8 w400 c000000", "Segoe UI")
global TDSVersionOverrideCtrl := MainGui.Add("Edit", "x415 y1315 w110 h22 Hidden", TDSVersionOverride)
MainGui.SetFont("s8 w400 cB79AA0", "Segoe UI")
global UpdateCanaryStatusCtrl := MainGui.Add("Text", "x30 y1346 w640 h36 Hidden Background180E11 +Border 0x200", "  Last observed: " IniRead(SettingsFile, "UpdateCanary", "LastObservedVersion", "Not detected yet") "`n  A failed or stalled canary stops unattended looping instead of repeatedly retrying.")

MainGui.SetFont("s10 w600 cEF2B2D", "Segoe UI")
global AbsoluteModeSection := MainGui.Add("Text", "x30 y1394 w300 h22 Hidden BackgroundTrans", "Absolute Mode / Stall Recovery")
global AbsoluteModeLine := MainGui.Add("Progress", "x30 y1417 w640 h1 Hidden Background43242B", 0)
MainGui.SetFont("s9 w600 cFFFFFF", "Segoe UI")
global AbsoluteModeEnabledCtrl := MainGui.Add("Checkbox", "x30 y1432 w210 h22 Hidden", "Enable Absolute Mode")
AbsoluteModeEnabledCtrl.Value := AbsoluteModeEnabled
MainGui.SetFont("s8 w400 cB79AA0", "Segoe UI")
global AbsoluteModeInfoCtrl := MainGui.Add("Text", "x30 y1460 w640 h48 Hidden Background180E11 +Border 0x200",
    "  Releases all held input, closes Roblox, and restarts after 5 minutes stuck joining or 10 minutes with no confirmed progress.`n  Intended for unattended runs. TDS Update Canary safety stops still take priority.")

global KronoxFeatureSettingsCtrls := [EvolutionQueueSection, EvolutionQueueLine,
    EvolutionQueueEnabledCtrl, EvolutionQueueAutoEquipCtrl, EvolutionQueueLabelCtrl,
    EvolutionQueueTowersCtrl, EvolutionQueueHelpCtrl, EvolutionQueueStatusCtrl, AnalyticsLabSection, AnalyticsLabLine,
    StrategyProfilerEnabledCtrl, WeekendXPBoostCtrl, VIPXPBoostCtrl, OtherXPBoostLabelCtrl,
    OtherXPBoostCtrl, ProfilerStatusCtrl, ResourceBudgetSection, ResourceBudgetLine,
    TimeScaleBudgetEnabledCtrl, TicketBalanceLabelCtrl, TicketReserveLabelCtrl,
    TicketSessionLabelCtrl, TicketBalanceCtrl, TicketReserveCtrl, TicketSessionCtrl,
    ConsumableBudgetEnabledCtrl, ConsumableRunLabelCtrl, ConsumableSessionLabelCtrl,
    ConsumableRunCtrl, ConsumableSessionCtrl, UpdateCanarySection, UpdateCanaryLine,
    UpdateCanaryEnabledCtrl, TDSVersionOverrideLabelCtrl, TDSVersionOverrideCtrl,
    UpdateCanaryStatusCtrl, AbsoluteModeSection, AbsoluteModeLine, AbsoluteModeEnabledCtrl,
    AbsoluteModeInfoCtrl]

MainGui.SetFont("s11 w400 cFFFFFF")
global Tab5_Btn1 := MainGui.Add("Text", "x30 y545 w645 h40 Center Background120B0D +Border 0x200 Hidden", "Save all settings")
Tab5_Btn1.OnEvent("Click", SaveAllSettings)
SetButtonRole(Tab5_Btn1, "Primary")

HoverEffect_btns.Push(Tab5_Btn1)

global SettingsScrollTrack := MainGui.Add("Progress", "x746 y95 w4 h430 Hidden Disabled Background2D171C", 0)
global SettingsScrollThumb := MainGui.Add("Progress", "x746 y95 w4 h90 Hidden Disabled BackgroundEF2B2D", 0)
global SettingsScrollOffset := 0
global SettingsScrollMax := 0
global SettingsBaseY := Map()
global SettingsViewportTop := 92
global SettingsViewportBottom := 532
global SettingsScrollableCtrls := [Tab5_Section1, Tab5_Line1, Tab5_Lbl1, ChainKeyCtrl,
    Tab5_Lbl2, BeatKeyCtrl, Tab5_Lbl3, CaravanKeyCtrl, Tab5_Lbl44, RaiseDeadKeyCtrl,
    Tab5_Lbl55, HologramKeyCtrl, Tab5_Lbl56, RepoKeyCtrl, Tab5_Help11, Tab5_LblSwatVan, SwatVanKeyCtrl,
    Tab5_Lbl99, CancelPlacementKeyCtrl, Tab5_LblUPG, UpgradeTowerGCtrl,
    Tab5_LblUPGBTM, UpgradeTowerGBCtrl, Tab5_Section2, Tab5_Line2, UseUpgradeHCtrl,
    Tab5_Help6, UseRestartBtnCtrl, Tab5_Help4, UsePlayAgainBtnCtrl, Tab5_Help5,
    CheckTheMapCtrl, Tab5_Help7, UseNumbersForHotbarCtrl, CollectPlaytimeRewardsCtrl,
    DebugConsoleCtrl, PotatoModeCtrl, LegacyModeCtrl, UpgradeDelayLbl, UpgradeDelayCtrl, UpgradeDelayUnitLbl, Tab1_Lbl3, TimeScaleModeCtrl, MouseSpeedLbl,
    MouseSpeedTxt, MouseSpeedUpDown, MouseDelayLbl, MouseDelayTxt, MouseDelayUpDown,
    KeyDelayLbl, KeyDelayTxt, KeyDelayUpDown, Tab5_Section3, Tab5_Line3, PlcTowerTEXT,
    PlaceTowerKeyCtrl, UpgTowerTEXT, UpgradeTowerKeyCtrl, AlignCamTEXT, AlignCameraKeyCtrl,
    DjTrackTEXT, ChangeDJTrackKeyCtrl, SellTowTEXT, SellTowerKeyCtrl, DelRecTEXT,
    DeleteTowerRecordingKeyCtrl, RecInputsTEXT, RecordInputsKeyCtrl, HoloTEXT, HoloKeyCtrl,
    ChangeTargetsTEXT, ChangeTargetsKeyCtrl, RaiseDeadTEXT, UseRaiseDeadKeyCtrl, Tab5_Line4, Tab5_Lbl4, VipLinkCtrl,
    UseVipServerCtrl, AlwaysOnTopCtrl]
for towerXPSettingCtrl in TowerXPSettingsCtrls
    SettingsScrollableCtrls.Push(towerXPSettingCtrl)
for featureSettingCtrl in KronoxFeatureSettingsCtrls
    SettingsScrollableCtrls.Push(featureSettingCtrl)

; tab 6 - tools ===========================

MainGui.SetFont("s10 w600 cEF2B2D", "Segoe UI")
global Tools_Section := MainGui.Add("Text", "x30 y95 w200 h22 Hidden", "Tools")
global Tools_Section_Line := MainGui.Add("Progress", "x30 y118 w640 h1 Hidden  Background43242B", 0)

MainGui.SetFont("s9 w400 cffffff")
global Tools_Info:= MainGui.Add("Text", "x30 y490 w640 h100 Hidden", "Additional utilities for optimizing and simplifying the gameplay and automating repetitive actions. It reduces your suffering.")

global Auto_COA := MainGui.Add("Picture", "x30 y125 w197 h176 Hidden", "Resources/Gui/auto_coa_preview.png")

Auto_COA.OnEvent("Click", RunAutoAbTool)

global Auto_Spin := MainGui.Add("Picture", "x240 y125 w197 h139 Hidden", "Resources/Gui/auto_spin_preview.png")

Auto_Spin.OnEvent("Click", RunAutoSpinTool)

global Auto_Consum := MainGui.Add("Picture", "x450 y125 w200 h140 Hidden", "Resources/Gui/auto_open_consumable_preview.png")

Auto_Consum.OnEvent("Click", RunAutoConsumableTool)


; tab 7 - analytics ===========================

MainGui.SetFont("s8 w700 cEF2B2D", "Segoe UI")
global Stats_Kicker := MainGui.Add("Text", "x30 y91 w640 Hidden Center", "KRONOX ANALYTICS  /  LOCAL TELEMETRY")
MainGui.SetFont("s16 w650 cF5E9EC", "Segoe UI Variable")
global Stats_TITLE := MainGui.Add("Text", "x30 y107 w640 Hidden Center", "Overall Statistics")
MainGui.SetFont("s9 w400 c987D83", "Segoe UI")
global Stats_Subtitle := MainGui.Add("Text", "x30 y133 w640 Hidden Center", "Confirmed outcomes, run coverage, and strategy efficiency")

MainGui.SetFont("s8 w650 cB79AA0", "Segoe UI")
global Stats_ScopeLabel := MainGui.Add("Text", "x30 y153 w54 h22 Hidden 0x200", "VIEW")
MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global Stats_ScopeCtrl := MainGui.Add("DropDownList", "x84 y150 w150 Hidden Choose1", ["Overall", "By Map", "By Gamemode", "By Strategy", "By Modifiers", "By XP Boost"])
global Stats_FilterCtrl := MainGui.Add("DropDownList", "x248 y150 w312 Hidden Disabled", ["All tracked runs"])
global StatsFilterSections := []
Stats_ScopeCtrl.OnEvent("Change", StatsScopeChanged)
Stats_FilterCtrl.OnEvent("Change", StatsFilterChanged)

global Stats_MatchesBG := MainGui.Add("Progress", "x30 y181 w116 h58 Hidden Disabled Background1A1113", 0)
global Stats_WinsBG := MainGui.Add("Progress", "x156 y181 w116 h58 Hidden Disabled Background1A1113", 0)
global Stats_LossesBG := MainGui.Add("Progress", "x282 y181 w116 h58 Hidden Disabled Background1A1113", 0)
global Stats_WinRateBG := MainGui.Add("Progress", "x408 y181 w116 h58 Hidden Disabled Background1A1113", 0)
global Stats_CoverageBG := MainGui.Add("Progress", "x534 y181 w116 h58 Hidden Disabled Background2A171B", 0)

MainGui.SetFont("s8 w650 c987D83", "Segoe UI")
global Stats_MatchesLabel := MainGui.Add("Text", "x38 y187 w100 h16 Hidden Center BackgroundTrans", "RUN STARTS")
global Stats_WinsLabel := MainGui.Add("Text", "x164 y187 w100 h16 Hidden Center BackgroundTrans", "WINS")
global Stats_LossesLabel := MainGui.Add("Text", "x290 y187 w100 h16 Hidden Center BackgroundTrans", "LOSSES")
global Stats_WinRateLabel := MainGui.Add("Text", "x416 y187 w100 h16 Hidden Center BackgroundTrans", "WIN RATE")
global Stats_CoverageLabel := MainGui.Add("Text", "x542 y187 w100 h16 Hidden Center BackgroundTrans", "COVERAGE")
MainGui.SetFont("s16 w700 cF5E9EC", "Segoe UI Variable")
global Stats_MatchesValue := MainGui.Add("Text", "x38 y204 w100 h27 Hidden Center BackgroundTrans", "0")
global Stats_WinsValue := MainGui.Add("Text", "x164 y204 w100 h27 Hidden Center BackgroundTrans", "0")
global Stats_LossesValue := MainGui.Add("Text", "x290 y204 w100 h27 Hidden Center BackgroundTrans", "0")
MainGui.SetFont("s16 w700 cEF2B2D", "Segoe UI Variable")
global Stats_WinRateValue := MainGui.Add("Text", "x416 y204 w100 h27 Hidden Center BackgroundTrans", "0%")
global Stats_CoverageValue := MainGui.Add("Text", "x542 y204 w100 h27 Hidden Center BackgroundTrans", "0%")

global Stats_CoinsBG := MainGui.Add("Progress", "x30 y249 w200 h64 Hidden Disabled Background1A1113", 0)
global Stats_GemsBG := MainGui.Add("Progress", "x250 y249 w200 h64 Hidden Disabled Background1A1113", 0)
global Stats_XPBG := MainGui.Add("Progress", "x470 y249 w200 h64 Hidden Disabled Background1A1113", 0)
MainGui.SetFont("s8 w650 c987D83", "Segoe UI")
global Stats_CoinsLabel := MainGui.Add("Text", "x40 y256 w180 h16 Hidden Center BackgroundTrans", "TOTAL COINS")
global Stats_GemsLabel := MainGui.Add("Text", "x260 y256 w180 h16 Hidden Center BackgroundTrans", "TOTAL GEMS")
global Stats_XPLabel := MainGui.Add("Text", "x480 y256 w180 h16 Hidden Center BackgroundTrans", "TOTAL XP")
MainGui.SetFont("s16 w700 cF5E9EC", "Segoe UI Variable")
global Stats_CoinsValue := MainGui.Add("Text", "x40 y275 w180 h27 Hidden Center BackgroundTrans", "0")
global Stats_GemsValue := MainGui.Add("Text", "x260 y275 w180 h27 Hidden Center BackgroundTrans", "0")
global Stats_XPValue := MainGui.Add("Text", "x480 y275 w180 h27 Hidden Center BackgroundTrans", "0")

global Stats_DetailsBG := MainGui.Add("Progress", "x30 y323 w400 h150 Hidden Disabled Background1A1113", 0)
global Stats_RecentBG := MainGui.Add("Progress", "x440 y323 w230 h150 Hidden Disabled Background1A1113", 0)
MainGui.SetFont("s8 w700 cEF2B2D", "Segoe UI")
global Stats_DetailsTitle := MainGui.Add("Text", "x47 y335 w365 h16 Hidden BackgroundTrans", "EFFICIENCY + DATA QUALITY")
global Stats_RecentTitle := MainGui.Add("Text", "x457 y335 w196 h16 Hidden BackgroundTrans", "RECENT CONFIRMED RESULTS")
MainGui.SetFont("s9 w400 cF5E9EC", "Segoe UI")
global Stats_Details := MainGui.Add("Text", "x47 y356 w365 h108 Hidden BackgroundTrans", "No completed matches have been recorded yet.")
MainGui.SetFont("s8 w400 cB79AA0", "Segoe UI")
global Stats_Recent := MainGui.Add("Text", "x457 y356 w196 h108 Hidden BackgroundTrans", "No confirmed results yet.")

global StatsCtrls := [Stats_Kicker, Stats_TITLE, Stats_Subtitle, Stats_ScopeLabel, Stats_ScopeCtrl, Stats_FilterCtrl,
    Stats_MatchesBG, Stats_WinsBG, Stats_LossesBG, Stats_WinRateBG, Stats_CoverageBG,
    Stats_MatchesLabel, Stats_WinsLabel, Stats_LossesLabel, Stats_WinRateLabel, Stats_CoverageLabel,
    Stats_MatchesValue, Stats_WinsValue, Stats_LossesValue, Stats_WinRateValue, Stats_CoverageValue,
    Stats_CoinsBG, Stats_GemsBG, Stats_XPBG,
    Stats_CoinsLabel, Stats_GemsLabel, Stats_XPLabel,
    Stats_CoinsValue, Stats_GemsValue, Stats_XPValue,
    Stats_DetailsBG, Stats_RecentBG, Stats_DetailsTitle, Stats_RecentTitle, Stats_Details, Stats_Recent]

; tab 8 - strategy editor ===========================

global EditorStrategyPath := ""
global EditorRecordedTowerText := ""
global EditorSyncingAbstract := false
global EditorHotbarDragSource := 0, EditorHotbarDragTarget := 0
global EditorHotbarDragStartX := 0, EditorHotbarDragStartY := 0, EditorHotbarDragMoved := false
global EditorSupportedMaps := [
    "Abandoned City", "Area 52", "Autumn Falling", "Badlands II", "Black Spot Exchange",
    "Candy Valley", "Cataclysm", "Chess Board", "Construction Crazy", "Coral Deep", "Crossroads",
    "Crystal Cave", "Cyber City", "Dead Ahead", "Derelict Outpost", "Deserted Village", "Dusty Bridges",
    "Enchanted Forest", "Farm Lands", "Forest Camp", "Forgetten Docks", "Four Seasons", "Fungi Island",
    "Grass Isle", "Happy Home of Robloxia", "Harbor", "Honey Valley", "Hot Spot", "Iceville",
    "Infernal Abyss", "Lay By", "Lighthaos", "Marshlands", "Mason Arch", "Medieval Times", "Meltdown",
    "Midnight Issue", "Moon Base", "Musaceae Kingdom", "Necropolis", "Nether", "Night Station",
    "Northern Lights", "Outskirts Commune", "Pier Pressure", "Pizza Party", "Polluted Wasteland II",
    "Portland", "Retro Crossroads", "Retro Lighthouse", "Retro Rocket Arena", "Retro Stained Temple",
    "Retro The Heights", "Retro Zone", "Rocket Arena", "Ruby Escort", "Sacred Mountains", "Sky Islands",
    "Simplicity", "Space City", "Spring Fever", "Stained Temple", "Sugar Rush", "The Heavens", "The Heights",
    "Toyboard", "Tropical Industries", "Tropical Isles", "U-Turn", "Unknown Garden", "Winter Abyss",
    "Winter Bridges", "Winter Stronghold", "Wrecked Battlefield", "Wrecked Battlefield II", "Wretched Front"
]
global EditorSupportedModes := [
    "Easy", "Casual", "Intermediate", "Molten", "Fallen", "Frost", "Hardcore", "Voidcore",
    "Pizza Party", "Badlands II", "Polluted Wasteland II"
]
global EditorModifierNames := [
    "Broke", "Exploding", "Flying", "Fog", "Glass", "Healthy", "Hidden", "Inflation", "Jailed",
    "Limitation", "Committed", "Quarantine", "Speedy"
]

MainGui.SetFont("s8 w700 cEF2B2D", "Segoe UI")
global Editor_Kicker := MainGui.Add("Text", "x30 y91 w700 Hidden Center", "KRONOX STRATEGY TOOLS  /  SAFE EDITOR")
MainGui.SetFont("s16 w650 cF5E9EC", "Segoe UI Variable")
global Editor_Title := MainGui.Add("Text", "x30 y107 w700 Hidden Center", "Strategy Editor")
MainGui.SetFont("s9 w400 c987D83", "Segoe UI")
global Editor_Subtitle := MainGui.Add("Text", "x30 y133 w700 Hidden Center", "Edit general settings without touching recorded Steps")

MainGui.SetFont("s8 w650 cB79AA0", "Segoe UI")
global Editor_FileLabel := MainGui.Add("Text", "x30 y160 w52 h22 Hidden 0x200", "FILE")
MainGui.SetFont("s9 w400 c000000", "Segoe UI")
global Editor_PathCtrl := MainGui.Add("Edit", "x82 y158 w468 h23 Hidden ReadOnly", "No strategy loaded")
MainGui.SetFont("s9 w400 cF5E9EC", "Segoe UI")
global Editor_BrowseBtn := MainGui.Add("Text", "x560 y158 w80 h23 Hidden Center +Border 0x200 Background120B0D", "Browse")
global Editor_ReloadBtn := MainGui.Add("Text", "x650 y158 w80 h23 Hidden Center +Border 0x200 Background120B0D", "Reload")
Editor_BrowseBtn.OnEvent("Click", EditorBrowseStrategy)
Editor_ReloadBtn.OnEvent("Click", EditorReloadStrategy)
SetButtonRole(Editor_BrowseBtn)
SetButtonRole(Editor_ReloadBtn)
HoverEffect_btns.Push(Editor_BrowseBtn)
HoverEffect_btns.Push(Editor_ReloadBtn)

MainGui.SetFont("s8 w400 c987D83", "Segoe UI")
global Editor_Status := MainGui.Add("Text", "x30 y184 w700 h17 Hidden", "Browse to a .strat file. Save Copy is the safest first edit.")
global Editor_Line1 := MainGui.Add("Progress", "x30 y205 w700 h1 Hidden Disabled Background43242B", 0)

MainGui.SetFont("s9 w650 cEF2B2D", "Segoe UI")
global Editor_GeneralTitle := MainGui.Add("Text", "x30 y215 w180 h20 Hidden", "GENERAL")
MainGui.SetFont("s8 w600 cB79AA0", "Segoe UI")
global Editor_MapLabel := MainGui.Add("Text", "x30 y242 w45 h22 Hidden 0x200", "MAP")
global Editor_ModeLabel := MainGui.Add("Text", "x325 y242 w48 h22 Hidden 0x200", "MODE")
global Editor_AbstractLabel := MainGui.Add("Text", "x565 y242 w70 h22 Hidden 0x200", "ABSTRACT")
MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global Editor_MapCtrl := MainGui.Add("ComboBox", "x75 y240 w235 Hidden", EditorSupportedMaps)
global Editor_ModeCtrl := MainGui.Add("ComboBox", "x375 y240 w175 Hidden", EditorSupportedModes)
global Editor_AbstractCtrls := []
Loop 5 {
    editorAbstractCtrl := MainGui.Add("Checkbox", "x" (635 + ((A_Index - 1) * 20)) " y242 w20 h20 Hidden", String(A_Index))
    Editor_AbstractCtrls.Push(editorAbstractCtrl)
}

MainGui.SetFont("s9 w650 cEF2B2D", "Segoe UI")
global Editor_HotbarTitle := MainGui.Add("Text", "x30 y275 w180 h20 Hidden", "TOWER HOTBAR")
MainGui.SetFont("s8 w600 c987D83", "Segoe UI")
global Editor_HotbarMode := MainGui.Add("Text", "x300 y276 w430 h18 Hidden Right", "RECORDED ORDER  /  NO REMAP")
global Editor_Line2 := MainGui.Add("Progress", "x30 y297 w700 h1 Hidden Disabled Background43242B", 0)
global EditorTowerLabels := []
global EditorOriginalTowerCtrls := []
global EditorTowerCtrls := []
Loop 5 {
    slotX := 105 + ((A_Index - 1) * 125)
    MainGui.SetFont("s8 w600 cB79AA0", "Segoe UI")
    slotLabel := MainGui.Add("Text", "x" slotX " y302 w117 h14 Hidden Center", "SLOT " A_Index)
    MainGui.SetFont("s8 w500 cB79AA0", "Segoe UI")
    originalCtrl := MainGui.Add("Text", "x" slotX " y317 w117 h23 Hidden Center +Border +0x100 0x200 Background170E10", "—")
    MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
    slotCtrl := MainGui.Add("ComboBox", "x" slotX " y346 w117 Hidden", SupportedTowerNames)
    EditorTowerLabels.Push(slotLabel)
    EditorOriginalTowerCtrls.Push(originalCtrl)
    EditorTowerCtrls.Push(slotCtrl)
}
MainGui.SetFont("s8 w650 cB79AA0", "Segoe UI")
global Editor_OriginalLabel := MainGui.Add("Text", "x30 y318 w66 h20 Hidden 0x200", "ORIGINAL")
global Editor_EquippedLabel := MainGui.Add("Text", "x30 y347 w66 h20 Hidden 0x200", "EQUIPPED")
MainGui.SetFont("s8 w400 c987D83", "Segoe UI")
global Editor_HotbarHint := MainGui.Add("Text", "x30 y374 w700 h16 Hidden", "Drag Original cards to rearrange both rows; edit an Equipped dropdown to replace only that tower.")

MainGui.SetFont("s9 w650 cEF2B2D", "Segoe UI")
global Editor_ModifiersTitle := MainGui.Add("Text", "x30 y393 w180 h20 Hidden", "MODIFIERS")
global Editor_Line3 := MainGui.Add("Progress", "x30 y413 w700 h1 Hidden Disabled Background43242B", 0)
global EditorModifierCtrls := Map()
MainGui.SetFont("s8 w400 cF5E9EC", "Segoe UI")
for index, modifierName in EditorModifierNames {
    modifierCol := Mod(index - 1, 5)
    modifierRow := Floor((index - 1) / 5)
    modifierCtrl := MainGui.Add("Checkbox", "x" (30 + modifierCol * 144) " y" (421 + modifierRow * 22) " w132 h19 Hidden", modifierName)
    EditorModifierCtrls[modifierName] := modifierCtrl
}

global Editor_Line4 := MainGui.Add("Progress", "x30 y489 w700 h1 Hidden Disabled Background43242B", 0)
MainGui.SetFont("s8 w400 cF5E9EC", "Segoe UI")
global Editor_AutoSkipCtrl := MainGui.Add("Checkbox", "x30 y495 w115 h20 Hidden", "Auto Skip")
global Editor_AdvancedSkipCtrl := MainGui.Add("Checkbox", "x155 y495 w155 h20 Hidden", "Advanced Wave Skip")
MainGui.SetFont("s8 w600 cB79AA0", "Segoe UI")
global Editor_AdvancedWavesLabel := MainGui.Add("Text", "x330 y495 w48 h20 Hidden 0x200", "WAVES")
MainGui.SetFont("s8 w400 c000000", "Segoe UI")
global Editor_AdvancedWavesCtrl := MainGui.Add("Edit", "x380 y493 w350 h22 Hidden Disabled", "")
Editor_AutoSkipCtrl.OnEvent("Click", EditorAutoSkipModeChanged)
Editor_AdvancedSkipCtrl.OnEvent("Click", EditorAutoSkipModeChanged)

MainGui.SetFont("s8 w400 cF5E9EC", "Segoe UI")
global Editor_AbilitySpamCtrl := MainGui.Add("Checkbox", "x30 y519 w125 h20 Hidden", "Ability Spam")
global Editor_AutoChainCtrl := MainGui.Add("Checkbox", "x165 y519 w125 h20 Hidden", "Call of Arms")
global Editor_AutoCaravanCtrl := MainGui.Add("Checkbox", "x300 y519 w140 h20 Hidden", "Support Caravan")
global Editor_AutoDropCtrl := MainGui.Add("Checkbox", "x450 y519 w145 h20 Hidden", "Drop the Beat")

MainGui.SetFont("s10 w500 cF5E9EC", "Segoe UI")
global Editor_SaveCopyBtn := MainGui.Add("Text", "x30 y553 w225 h32 Hidden Center +Border 0x200 BackgroundEF2B2D", "Save Copy")
global Editor_OverwriteBtn := MainGui.Add("Text", "x265 y553 w225 h32 Hidden Center +Border 0x200 Background120B0D", "Overwrite + Backup")
global Editor_RenameBtn := MainGui.Add("Text", "x500 y553 w230 h32 Hidden Center +Border 0x200 Background120B0D", "Rename File")
Editor_SaveCopyBtn.OnEvent("Click", EditorSaveCopy)
Editor_OverwriteBtn.OnEvent("Click", EditorOverwrite)
Editor_RenameBtn.OnEvent("Click", EditorRename)
SetButtonRole(Editor_SaveCopyBtn, "Primary")
SetButtonRole(Editor_OverwriteBtn)
SetButtonRole(Editor_RenameBtn)
HoverEffect_btns.Push(Editor_SaveCopyBtn)
HoverEffect_btns.Push(Editor_OverwriteBtn)
HoverEffect_btns.Push(Editor_RenameBtn)

global EditorCtrls := [Editor_Kicker, Editor_Title, Editor_Subtitle, Editor_FileLabel, Editor_PathCtrl,
    Editor_BrowseBtn, Editor_ReloadBtn, Editor_Status, Editor_Line1, Editor_GeneralTitle, Editor_MapLabel,
    Editor_ModeLabel, Editor_AbstractLabel, Editor_MapCtrl, Editor_ModeCtrl,
    Editor_HotbarTitle, Editor_HotbarMode, Editor_Line2, Editor_OriginalLabel, Editor_EquippedLabel,
    Editor_HotbarHint, Editor_ModifiersTitle, Editor_Line3, Editor_Line4,
    Editor_AutoSkipCtrl, Editor_AdvancedSkipCtrl, Editor_AdvancedWavesLabel, Editor_AdvancedWavesCtrl,
    Editor_AbilitySpamCtrl, Editor_AutoChainCtrl, Editor_AutoCaravanCtrl, Editor_AutoDropCtrl,
    Editor_SaveCopyBtn, Editor_OverwriteBtn, Editor_RenameBtn]
for ctrl in EditorTowerLabels
    EditorCtrls.Push(ctrl)
for ctrl in EditorOriginalTowerCtrls
    EditorCtrls.Push(ctrl)
for ctrl in EditorTowerCtrls
    EditorCtrls.Push(ctrl), ctrl.OnEvent("Change", EditorHotbarChanged)
for ctrl in Editor_AbstractCtrls
    EditorCtrls.Push(ctrl), ctrl.OnEvent("Click", EditorAbstractSlotChanged)
for modifierName, ctrl in EditorModifierCtrls
    EditorCtrls.Push(ctrl)

; tab 9 - credits ===========================

MainGui.SetFont("s8 w700 cEF2B2D", "Segoe UI")
global Credits_Kicker := MainGui.Add("Text", "x30 y98 w640 Hidden Center", "KRONOX'S EDITION  /  CREDITS")
MainGui.SetFont("s18 w650 cF5E9EC", "Segoe UI Variable")
global Credits_Title := MainGui.Add("Text", "x30 y119 w640 Hidden Center", "Built on Ultimate Macro")
MainGui.SetFont("s9 w400 c987D83", "Segoe UI")
global Credits_Subtitle := MainGui.Add("Text", "x30 y151 w640 Hidden Center", "Original automation by Darksen • analytics and strategy tooling by Kronox")
global Credits_Accent := MainGui.Add("Progress", "x60 y177 w580 h2 Hidden Disabled BackgroundEF2B2D", 0)

global Credits_OriginalBG := MainGui.Add("Progress", "x30 y196 w305 h126 Hidden Disabled Background1A1113", 0)
global Credits_EditionBG := MainGui.Add("Progress", "x350 y196 w320 h126 Hidden Disabled Background1A1113", 0)
MainGui.SetFont("s8 w700 cEF2B2D", "Segoe UI")
global Credits_OriginalLabel := MainGui.Add("Text", "x48 y211 w265 h16 Hidden BackgroundTrans", "ORIGINAL PROJECT")
global Credits_EditionLabel := MainGui.Add("Text", "x368 y211 w282 h16 Hidden BackgroundTrans", "KRONOX'S EDITION")
MainGui.SetFont("s12 w650 cF5E9EC", "Segoe UI Variable")
global Credits_OriginalName := MainGui.Add("Text", "x48 y235 w265 h24 Hidden BackgroundTrans", "Darksen")
global Credits_EditionName := MainGui.Add("Text", "x368 y235 w282 h24 Hidden BackgroundTrans", "Strategy analytics fork")
MainGui.SetFont("s9 w400 cB79AA0", "Segoe UI")
global Credits_OriginalText := MainGui.Add("Text", "x48 y266 w265 h42 Hidden BackgroundTrans", "Creator of Ultimate Macro for TDS.`nOriginal credit retained with gratitude.")
global Credits_EditionText := MainGui.Add("Text", "x368 y266 w282 h42 Hidden BackgroundTrans", "Run ledger, outcome coverage, strategy-version tracking, diagnostics, and visual redesign.")

global Credits_LicenseBG := MainGui.Add("Progress", "x30 y337 w640 h103 Hidden Disabled Background120B0D", 0)
MainGui.SetFont("s8 w700 cEF2B2D", "Segoe UI")
global Credits_LicenseLabel := MainGui.Add("Text", "x48 y352 w604 h16 Hidden BackgroundTrans", "OPEN SOURCE + ATTRIBUTION")
MainGui.SetFont("s9 w400 cB79AA0", "Segoe UI")
global Credits_LicenseText := MainGui.Add("Text", "x48 y376 w604 h48 Hidden BackgroundTrans", "Licensed under GNU GPL v3. Modifications are welcome; Darksen's original credit remains.`nProject links and version information are available below.")
MainGui.SetFont("s8 w400 c987D83", "Segoe UI")
global Credits_Footnote := MainGui.Add("Text", "x30 y463 w640 h20 Hidden Center", "Ultimate Macro Kronox's Edition")

global CreditsCtrls := [Credits_Kicker, Credits_Title, Credits_Subtitle, Credits_Accent,
    Credits_OriginalBG, Credits_EditionBG, Credits_OriginalLabel, Credits_EditionLabel,
    Credits_OriginalName, Credits_EditionName, Credits_OriginalText, Credits_EditionText,
    Credits_LicenseBG, Credits_LicenseLabel, Credits_LicenseText, Credits_Footnote]

global Divider := MainGui.Add("Progress", "x0 y545 w" MainWindowWidth " h1 Hidden Background2D171C", 0)
global FooterBg := MainGui.Add("Progress", "x0 y546 w" MainWindowWidth " h64 Disabled Hidden Background120B0D", 0)

global version_text := MainGui.Add("Text", "x30 y565 BackgroundTrans Hidden", ver)

global githubImg := MainGui.Add("Picture", "x640 y565 w24 h-1 Hidden BackgroundTrans", "Resources\github.png")
githubImg.OnEvent("Click", githubLink)
global DiscordImg := MainGui.Add("Picture", "x671 y565 w24 h-1 Hidden BackgroundTrans", "Resources\discord.png")
DiscordImg.OnEvent("Click", DiscordLink)
global YoutubeImg := MainGui.Add("Picture", "x702 y565 w24 h-1 Hidden BackgroundTrans", "Resources\youtube.png")
YoutubeImg.OnEvent("Click", YouTubeLink)

MainGui.Title := "Ultimate Macro Kronox's Edition"
CenterLegacyTabLayouts()
InitializeSettingsScroll()
ApplyDarkControlThemes(MainGui)
ApplyDarkControlThemes(ChildGui)
ApplyDarkWindowTheme(MainGui.Hwnd)
ApplyDarkWindowTheme(ChildGui.Hwnd)
MainGui.Show("w" MainWindowWidth " h" MainWindowHeight)

if (AlwaysOnTop = 1) {
    MainGui.Opt("+AlwaysOnTop")
} else {
    MainGui.Opt("-AlwaysOnTop")
}

SetTimer(() => RemoveInitialFocus(), -50)

global CurrentTab := "Tab1"
TabCtrl[1].SetFont("c" ThemeColor("TextPrimary") " Bold")
HoverTab[1].Visible := true
ShowTabContent("Tab1")
ShowChildGui()
EnableStratRotation()

SetTimer(Hoverwatchdog, 10)
SetTimer(HotbarSafetyWatchdog, 12000)
if KronoxBotEnabled
    SetTimer(StartKronoxDiscordBot, -1000)

OnMessage(0x0201, WM_LBUTTONDOWN_Drag)
OnMessage(0x0200, EditorHotbarDragMouseMove)
OnMessage(0x0202, EditorHotbarDragMouseUp)

RemoveInitialFocus() {
    if !WinActive("ahk_id " MainGui.Hwnd)
        return
    ControlFocus(GuiTitleCtrl, "ahk_id " MainGui.Hwnd)
}

~F1:: StartStrategy(0, 0)
~F2:: StopStrategy(0, 0)

SelectTab(ctrl, *) {
    global CurrentTab, TabCtrl, TabLine, HoverTab, TabStartX, TabStep, TabWidth
    idx := 0
    Loop HoverTab.Length {
        if (TabCtrl[A_Index] = ctrl) {
            idx := A_Index
            break
        }
    }
    if (!idx)
        return
    newTab := "Tab" idx
    if (newTab = CurrentTab)
        return
    
    oldIdx := Integer(SubStr(CurrentTab, 4))
    HoverTab[oldIdx].Visible := false
    TabCtrl[oldIdx].SetFont("c" ThemeColor("TextMuted") " Norm")
    HideAllTabContent()
    
    CurrentTab := newTab
    HoverTab[idx].Visible := true
    TabCtrl[idx].SetFont("c" ThemeColor("TextPrimary") " Bold")
    
    
    newX := TabStartX + (idx - 1) * TabStep
    TabLine.Move(newX, , TabWidth)
    
    ShowTabContent(newTab)
}

Hoverwatchdog(*) {
    static hClose := 0, hMin := 0, hMain := 0, hChild := 0
    static hoverClose := false, hoverMin := false, hoverTabs := []
    loop HoverTab.Length {
        hoverTabs.Push(false)
    }
    static activeHoverHwnd := 0
    static activeGradHwnd := 0 
    
    if (!hMain)
        hMain := MainGui.Hwnd
        
    ; The strategy library rebuilds its child window when a filter or favorite changes.
    ; Refreshing this handle keeps hover hit-testing attached to the current card list.
    if (IsSet(ChildGui) && IsObject(ChildGui))
        hChild := ChildGui.Hwnd
    
    oldMode := A_CoordModeMouse
    CoordMode("Mouse", "Screen")
    MouseGetPos(&screenX, &screenY, &mouseWin, &mouseCtrl, 2)
    CoordMode("Mouse", oldMode)
    
    try {
        WinGetPos(&mX, &mY,,, "ahk_id " hMain)
        mouseX := screenX - mX
        mouseY := screenY - mY
    } catch {
        mouseX := 0
        mouseY := 0
    }
    
    if (mouseWin != hMain && mouseWin != hChild) {
        Loop HoverTab.Length {
            if (hoverTabs[A_Index]) {
                HoverTab[A_Index].Visible := (CurrentTab = "Tab" A_Index)
                if (CurrentTab != "Tab" A_Index)
                    TabCtrl[A_Index].SetFont("c" ThemeColor("TextMuted") " Norm")
                hoverTabs[A_Index] := false
            }
        }
        if (hoverClose) { 
            BtnClose.SetFont("cFFFFFF")
            hoverClose := false 
        }
        if (hoverMin) { 
            BtnMin.SetFont("cFFFFFF")
            hoverMin := false 
        }
        
        if (activeHoverHwnd != 0 && IsSet(HoverEffect_btns)) {
            for ctrl in HoverEffect_btns {
                if (ctrl.Hwnd = activeHoverHwnd) {
                    ApplyButtonRestStyle(ctrl)
                    ctrl.Redraw()
                    break
                }
            }
            activeHoverHwnd := 0
        }
        
        if (activeGradHwnd != 0 && IsSet(GradientButtons)) {
            for ctrl in GradientButtons {
                if (ctrl.Hwnd = activeGradHwnd) {
                    if (HasProp(ctrl, "PicControl"))
                        ctrl.PicControl.Value := "HBITMAP:*" ctrl.ImgNormal
                    ctrl.Redraw()
                    break
                }
            }
            activeGradHwnd := 0
        }
        return
    }
    
    if (!hClose) {
        hClose := BtnClose.Hwnd
        hMin := BtnMin.Hwnd
    }
    
    if (mouseCtrl = hClose) {
        if (!hoverClose) { 
            BtnClose.SetFont("c" ThemeColor("AccentHover"))
            hoverClose := true 
        }
    } else if (hoverClose) { 
        BtnClose.SetFont("cFFFFFF")
        hoverClose := false 
    }

    if (mouseCtrl = hMin) {
        if (!hoverMin) { 
            BtnMin.SetFont("c" ThemeColor("Accent"))
            hoverMin := true 
        }
    } else if (hoverMin) { 
        BtnMin.SetFont("cFFFFFF")
        hoverMin := false 
    }
    
    Loop HoverTab.Length {
        hTab := TabCtrl[A_Index].Hwnd
        if (mouseCtrl = hTab) {
            if (!hoverTabs[A_Index]) {
                HoverTab[A_Index].Visible := true
                TabCtrl[A_Index].SetFont("c" ThemeColor("TextPrimary"))
                hoverTabs[A_Index] := true
            }
        } else if (hoverTabs[A_Index]) {
            if (CurrentTab != "Tab" A_Index) {
                HoverTab[A_Index].Visible := false
                TabCtrl[A_Index].SetFont("c" ThemeColor("TextMuted"))
            } else {
                HoverTab[A_Index].Visible := true
                TabCtrl[A_Index].SetFont("c" ThemeColor("TextPrimary") " Bold")
            }
            hoverTabs[A_Index] := false
        }
    }

    if (IsSet(HoverEffect_btns)) {
        matchedAny := false
        for ctrl in HoverEffect_btns {
            if (!ctrl.Visible)
                continue
            ctrl.GetPos(&cX, &cY, &cW, &cH)
            if (mouseX >= cX && mouseX <= cX + cW && mouseY >= cY && mouseY <= cY + cH) {
                matchedAny := true
                if (activeHoverHwnd != ctrl.Hwnd) {
                    if (activeHoverHwnd != 0) {
                        for oldCtrl in HoverEffect_btns {
                            if (oldCtrl.Hwnd = activeHoverHwnd) {
                                ApplyButtonRestStyle(oldCtrl)
                                oldCtrl.Redraw()
                                break
                            }
                        }
                    }
                    ApplyButtonHoverStyle(ctrl)
                    ctrl.Redraw()
                    activeHoverHwnd := ctrl.Hwnd
                }
                break
            }
        }
        if (!matchedAny && activeHoverHwnd != 0) {
            for ctrl in HoverEffect_btns {
                if (ctrl.Hwnd = activeHoverHwnd) {
                    ApplyButtonRestStyle(ctrl)
                    ctrl.Redraw()
                    break
                }
            }
            activeHoverHwnd := 0
        }
    }

    
    if (IsSet(GradientButtons) && hChild) {
        matchedGrad := false
        
        try {
            WinGetPos(&chX, &chY,,, "ahk_id " hChild)
            childMouseX := screenX - chX
            childMouseY := screenY - chY
        } catch {
            childMouseX := 0
            childMouseY := 0
        }
        
        for ctrl in GradientButtons {
            if (!ctrl.Visible)
                continue

            ctrl.GetPos(&cX, &cY, &cW, &cH)
            
            if (childMouseX >= cX && childMouseX <= cX + cW && childMouseY >= cY && childMouseY <= cY + cH) {
                matchedGrad := true
                if (activeGradHwnd != ctrl.Hwnd) {
                    
                    if (activeGradHwnd != 0) {
                        for oldCtrl in GradientButtons {
                            if (oldCtrl.Hwnd = activeGradHwnd) {
                                if (HasProp(oldCtrl, "PicControl"))
                                    oldCtrl.PicControl.Value := "HBITMAP:*" oldCtrl.ImgNormal
                                oldCtrl.Redraw()
                                break
                            }
                        }
                    }
                    
                    if (HasProp(ctrl, "PicControl")) {
                        ctrl.PicControl.Value := "HBITMAP:*" ctrl.ImgHover
                    }
                    ctrl.Redraw()
                    activeGradHwnd := ctrl.Hwnd
                }
                break
            }
        }
         
        if (!matchedGrad && activeGradHwnd != 0) {
            for ctrl in GradientButtons {
                if (ctrl.Hwnd = activeGradHwnd) {
                    if (HasProp(ctrl, "PicControl"))
                        ctrl.PicControl.Value := "HBITMAP:*" ctrl.ImgNormal
                    ctrl.Redraw()
                    break
                }
            }
            activeGradHwnd := 0
        }
    }
}

HideAllTabContent() {
    global ChildGui, MainGui, SystemHwnds
    for hwnd, ctrl in MainGui {
        if (SystemHwnds.Has(hwnd))
            continue

        try {
            ctrl.Visible := false
        }
    }
    ChildGui.Hide()
}

CenterLegacyTabLayouts() {
    static centered := false
    global MainWindowWidth, FrameX, Tab2Ctrls, TAB3, StatsCtrls, CreditsCtrls, TowerXPSettingsCtrls, KronoxFeatureSettingsCtrls, CommunityLibraryCtrls
    global DiscordWebhookTabCtrls, DiscordBotTabCtrls
    if (centered)
        return
    centered := true

    offset := Round((MainWindowWidth - 700) / 2)
    if (offset = 0)
        return

    FrameX += offset
    controlGroups := [
        [Tab1_Section1, Tab1_Line1, Tab1_Lbl1, Strategy1Ctrl, Tab1_Btn1, Tab1_Btn2,
         Tab1_Lbl2, Strategy2Ctrl, Tab1_Btn3, Tab1_Btn4, RotateStrategiesCtrl, SwapAfterLbl,
         SwapAmountCtrl, SwapUnitCtrl, AutoEquipCtrl, AbstractCountLabel, AbstractCountCtrl,
         Tab1_Section2, Tab1_Line2, Tab1_Start, Tab1_Stop],
        CommunityLibraryCtrls,
        Tab2Ctrls,
        TAB3,
        [Tab4_Title, Tab4_Line1, Tab4_ModeSwitch],
        DiscordWebhookTabCtrls,
        DiscordBotTabCtrls,
        [Tab5_Section1, Tab5_Line1, Tab5_Lbl1, ChainKeyCtrl, Tab5_Lbl2, BeatKeyCtrl,
         Tab5_Lbl3, CaravanKeyCtrl, Tab5_Lbl44, RaiseDeadKeyCtrl, Tab5_Lbl55, HologramKeyCtrl,
         Tab5_Lbl56, RepoKeyCtrl, Tab5_Help11, Tab5_LblSwatVan, SwatVanKeyCtrl, Tab5_Lbl99, CancelPlacementKeyCtrl,
         Tab5_LblUPG, UpgradeTowerGCtrl, Tab5_LblUPGBTM, UpgradeTowerGBCtrl,
         Tab5_Section2, Tab5_Line2, UseUpgradeHCtrl, Tab5_Help6, UseRestartBtnCtrl, Tab5_Help4,
         UsePlayAgainBtnCtrl, Tab5_Help5, CheckTheMapCtrl, Tab5_Help7, UseNumbersForHotbarCtrl,
         CollectPlaytimeRewardsCtrl, DebugConsoleCtrl, PotatoModeCtrl, LegacyModeCtrl, UpgradeDelayLbl, UpgradeDelayCtrl, UpgradeDelayUnitLbl, Tab1_Lbl3, TimeScaleModeCtrl,
         MouseSpeedLbl, MouseSpeedTxt, MouseSpeedUpDown, MouseDelayLbl, MouseDelayTxt,
         MouseDelayUpDown, KeyDelayLbl, KeyDelayTxt, KeyDelayUpDown, Tab5_Section3, Tab5_Line3,
         PlcTowerTEXT, PlaceTowerKeyCtrl, UpgTowerTEXT, UpgradeTowerKeyCtrl, AlignCamTEXT,
         AlignCameraKeyCtrl, DjTrackTEXT, ChangeDJTrackKeyCtrl, SellTowTEXT, SellTowerKeyCtrl,
         DelRecTEXT, DeleteTowerRecordingKeyCtrl, RecInputsTEXT, RecordInputsKeyCtrl, HoloTEXT,
         HoloKeyCtrl, ChangeTargetsTEXT, ChangeTargetsKeyCtrl, RaiseDeadTEXT, UseRaiseDeadKeyCtrl, Tab5_Line4, Tab5_Lbl4, VipLinkCtrl,
         UseVipServerCtrl, AlwaysOnTopCtrl, Tab5_Btn1],
        TowerXPSettingsCtrls,
        KronoxFeatureSettingsCtrls,
        [Tools_Section, Tools_Section_Line, Tools_Info, Auto_COA, Auto_Spin, Auto_Consum],
        StatsCtrls,
        CreditsCtrls
    ]

    for controls in controlGroups {
        for ctrl in controls {
            try {
                ctrl.GetPos(&ctrlX, &ctrlY, &ctrlW, &ctrlH)
                ctrl.Move(ctrlX + offset, ctrlY, ctrlW, ctrlH)
            } catch Error {
            }
        }
    }
}

ShowTabContent(tab) {
    global ChildGui, CommunityLibraryCtrls
    if (tab = "Tab1") {
        for ctrl in [Tab1_Section1, Tab1_Line1, Tab1_Lbl1, Strategy1Ctrl, Tab1_Btn1, Tab1_Btn2,
                     Tab1_Lbl2, Strategy2Ctrl, Tab1_Btn3, Tab1_Btn4, RotateStrategiesCtrl, AutoEquipCtrl, Tab1_Section2, Tab1_Line2,
                     Tab1_Start, Tab1_Stop]
            ctrl.Visible := true
        for ctrl in CommunityLibraryCtrls
            ctrl.Visible := true
        EnableStratRotation()
        UpdateAbstractPlacementControls()
        ShowChildGui()
    } else if (tab = "Tab2") {
        for ctrl in Tab2Ctrls
            ctrl.Visible := true
    } else if (tab = "Tab3") {
        for ctrl in TAB3
            ctrl.Visible := true
    } else if (tab = "Tab4") {
        ShowDiscordRemoteView()
} else if (tab = "Tab5") {
        for ctrl in [Tab5_Section1, Tab5_Line1, Tab5_Lbl1, ChainKeyCtrl,
                     Tab5_Lbl2, BeatKeyCtrl, Tab5_Lbl3, CaravanKeyCtrl,
                     Tab5_Lbl44, RaiseDeadKeyCtrl, Tab5_Lbl55, Tab5_Lbl56, HologramKeyCtrl, RepoKeyCtrl, Tab5_LblSwatVan, SwatVanKeyCtrl,
                     Tab5_Lbl99, Tab5_LblUPG, Tab5_LblUPGBTM, CancelPlacementKeyCtrl, UpgradeTowerGCtrl, UpgradeTowerGBCtrl, Tab1_Lbl3, TimeScaleModeCtrl,
                     Tab5_Section2, Tab5_Line2, Tab5_Help6,
                     UseRestartBtnCtrl, Tab5_Help4, UsePlayAgainBtnCtrl, Tab5_Help5,
                     CheckTheMapCtrl, UseNumbersForHotbarCtrl, UseUpgradeHCtrl, Tab5_Help7, Tab5_Help11, PotatoModeCtrl, LegacyModeCtrl, DebugConsoleCtrl, UpgradeDelayLbl, UpgradeDelayCtrl, UpgradeDelayUnitLbl,
                     Tab5_Section3, Tab5_Line3, PlcTowerTEXT, UpgTowerTEXT, AlignCamTEXT,
                     DjTrackTEXT, SellTowTEXT, DelRecTEXT, RecInputsTEXT,
                     HoloTEXT, ChangeTargetsTEXT, RaiseDeadTEXT,
                     PlaceTowerKeyCtrl, UpgradeTowerKeyCtrl, AlignCameraKeyCtrl,
                     ChangeDJTrackKeyCtrl, SellTowerKeyCtrl, DeleteTowerRecordingKeyCtrl,
                     RecordInputsKeyCtrl, HoloKeyCtrl, ChangeTargetsKeyCtrl, UseRaiseDeadKeyCtrl,
                     CollectPlaytimeRewardsCtrl,
                     Tab5_Line4, Tab5_Lbl4, VipLinkCtrl, UseVipServerCtrl, AlwaysOnTopCtrl, Tab5_Btn1,
                     MouseSpeedLbl, MouseSpeedTxt, MouseSpeedUpDown,
                     MouseDelayLbl, MouseDelayTxt, MouseDelayUpDown, KeyDelayLbl, KeyDelayTxt, KeyDelayUpDown]
            ctrl.Visible := true

        
        ChainKeyCtrl.Value := ChainKey
        BeatKeyCtrl.Value := BeatKey
        CaravanKeyCtrl.Value := CaravanKey
        SwatVanKeyCtrl.Value := SwatVanKey
        RaiseDeadKeyCtrl.Value := RaiseDeadKey     
        HologramKeyCtrl.Value := HologramKey
        RepoKeyCtrl.Value := RepoKey       
        CancelPlacementKeyCtrl.Value := CancelPlacementKey
        AlignCameraKeyCtrl.Value := AlignCameraKey
        PlaceTowerKeyCtrl.Value := PlaceTowerKey
        UpgradeTowerKeyCtrl.Value := UpgradeTowerKey
        SellTowerKeyCtrl.Value := SellTowerKey
        DeleteTowerRecordingKeyCtrl.Value := DeleteTowerRecordingKey
        ChangeDJTrackKeyCtrl.Value := ChangeDJTrackKey
        RecordInputsKeyCtrl.Value := RecordInputsKey
        HoloKeyCtrl.Value := HoloKey
        ChangeTargetsKeyCtrl.Value := ChangeTargetsKey
        UseRaiseDeadKeyCtrl.Value := UseRaiseDeadKey
        TimeScaleModeCtrl.Text := TimeScaleMode
        LegacyModeCtrl.Value := (LegacyMode = "1" || LegacyMode = 1)
        UpgradeDelayCtrl.Value := UpgradeDelay
        
        MouseSpeedUpDown.Value := DefaultMouseSpeed
        MouseSpeedTxt.Value := DefaultMouseSpeed
        MouseDelayUpDown.Value := MouseDelay
        MouseDelayTxt.Value := MouseDelay
        KeyDelayUpDown.Value := KeyDelay
        KeyDelayTxt.Value := KeyDelay
        UpdateTowerXPControlState()
        EvolutionQueueStatusCtrl.Text := "  Current slots: " KronoxEvolutionAssignmentText(SettingsFile) "`n  At level 20, the finished tower leaves the batch and the next name moves in."
        ProfilerStatusCtrl.Text := "Last profile: " KronoxProfilerSummary(StateFile)
        UpdateCanaryStatusCtrl.Text := "  Last observed: " IniRead(SettingsFile, "UpdateCanary", "LastObservedVersion", "Not detected yet") "`n  A failed or stalled canary stops unattended looping instead of repeatedly retrying."
        SettingsScrollTrack.Visible := true
        SettingsScrollThumb.Visible := true
        ApplySettingsScroll()

    } else if (tab = "Tab6") {
        for ctrl in [Tools_Section, Tools_Section_Line, Tools_Info, Auto_COA, Auto_Spin, Auto_Consum]
            ctrl.Visible := true
    } else if (tab = "Tab7") {
        UpdateOverallStatsUI()
        for ctrl in StatsCtrls
            ctrl.Visible := true
        version_text.Visible := true
        Divider.Visible := true
        FooterBg.Visible := true
        DiscordImg.Visible := true
        YoutubeImg.Visible := true
        githubImg.Visible := true
    } else if (tab = "Tab8") {
        if (EditorStrategyPath = "" && Trim(Strategy1Ctrl.Text) != "" && FileExist(Strategy1Ctrl.Text))
            EditorLoadStrategy(Strategy1Ctrl.Text)
        for ctrl in EditorCtrls
            ctrl.Visible := true
    } else if (tab = "Tab9") {
        for ctrl in CreditsCtrls
            ctrl.Visible := true
        version_text.Visible := true
        Divider.Visible := true
        FooterBg.Visible := true
        DiscordImg.Visible := true
        YoutubeImg.Visible := true
        githubImg.Visible := true
    }
}

StatsScopeChanged(*) {
    global OverallStatsFile, Stats_ScopeCtrl, Stats_FilterCtrl, StatsFilterSections

    scope := Stats_ScopeCtrl.Text
    StatsFilterSections := []
    Stats_FilterCtrl.Delete()

    if (scope = "Overall") {
        Stats_FilterCtrl.Add(["All tracked runs"])
        Stats_FilterCtrl.Choose(1)
        Stats_FilterCtrl.Enabled := false
        UpdateOverallStatsUI()
        return
    }

    prefix := (scope = "By Map") ? "Map_"
        : ((scope = "By Gamemode") ? "Mode_"
        : ((scope = "By Strategy") ? "Strategy_"
        : ((scope = "By Modifiers") ? "Modifier_" : "Boost_")))
    labels := []
    sectionNames := ""
    if FileExist(OverallStatsFile) {
        try sectionNames := IniRead(OverallStatsFile)
    }

    for section in StrSplit(sectionNames, "`n", "`r") {
        if (SubStr(section, 1, StrLen(prefix)) != prefix)
            continue
        label := IniRead(OverallStatsFile, section, "DisplayName", SubStr(section, StrLen(prefix) + 1))
        labels.Push(label)
        StatsFilterSections.Push(section)
    }

    if (labels.Length = 0) {
        emptyLabel := (scope = "By Map") ? "No map data yet"
            : ((scope = "By Gamemode") ? "No gamemode data yet"
            : ((scope = "By Strategy") ? "No strategy-version data yet"
            : ((scope = "By Modifiers") ? "No modifier data yet" : "No boost-context data yet")))
        Stats_FilterCtrl.Add([emptyLabel])
        Stats_FilterCtrl.Choose(1)
        Stats_FilterCtrl.Enabled := false
    } else {
        Stats_FilterCtrl.Add(labels)
        Stats_FilterCtrl.Choose(1)
        Stats_FilterCtrl.Enabled := true
    }

    UpdateOverallStatsUI()
}

StatsFilterChanged(*) {
    UpdateOverallStatsUI()
}

UpdateOverallStatsUI() {
    global OverallStatsFile, StateFile, Stats_ScopeCtrl, Stats_FilterCtrl, StatsFilterSections
    global Stats_TITLE, Stats_Subtitle
    global Stats_MatchesValue, Stats_WinsValue, Stats_LossesValue, Stats_WinRateValue
    global Stats_CoverageValue, Stats_CoinsValue, Stats_GemsValue, Stats_XPValue, Stats_Details, Stats_Recent

    scope := Stats_ScopeCtrl.Text
    section := "Overall"
    displayName := "All maps and gamemodes"

    if (scope != "Overall") {
        selectedIndex := Integer(Stats_FilterCtrl.Value)
        if (selectedIndex > 0 && selectedIndex <= StatsFilterSections.Length) {
            section := StatsFilterSections[selectedIndex]
            displayName := Stats_FilterCtrl.Text
        } else {
            section := "NoData"
            displayName := (scope = "By Map") ? "No map data yet"
                : ((scope = "By Gamemode") ? "No gamemode data yet"
                : ((scope = "By Strategy") ? "No strategy-version data yet"
                : ((scope = "By Modifiers") ? "No modifier data yet" : "No boost-context data yet")))
        }
    }

    Stats_TITLE.Text := (scope = "Overall") ? "Overall Statistics"
        : ((scope = "By Map") ? "Map Statistics"
        : ((scope = "By Gamemode") ? "Gamemode Statistics"
        : ((scope = "By Strategy") ? "Strategy Version Statistics"
        : ((scope = "By Modifiers") ? "Modifier ROI Statistics" : "XP Boost Statistics"))))
    Stats_Subtitle.Text := (scope = "Overall") ? "Confirmed outcomes, run coverage, and strategy efficiency" : "Lifetime view: " displayName

    wins := Integer(IniRead(OverallStatsFile, section, "TotalTriumphs", 0))
    losses := Integer(IniRead(OverallStatsFile, section, "TotalLosses", 0))
    coins := Integer(IniRead(OverallStatsFile, section, "Coins", 0))
    gems := Integer(IniRead(OverallStatsFile, section, "Gems", 0))
    exp := Integer(IniRead(OverallStatsFile, section, "EXP", 0))
    normalizedExp := Integer(IniRead(OverallStatsFile, section, "NormalizedEXP", 0))
    boostTrackedRuns := Integer(IniRead(OverallStatsFile, section, "BoostTrackedRuns", 0))
    boostTrackedSeconds := Integer(IniRead(OverallStatsFile, section, "BoostTrackedSeconds", 0))
    totalSeconds := Integer(IniRead(OverallStatsFile, section, "TotalTimeSeconds", 0))
    lastUpdated := IniRead(OverallStatsFile, section, "LastUpdated", "Never")

    matches := wins + losses
    starts := Integer(IniRead(OverallStatsFile, section, "TotalRunStarts", matches))
    starts := Max(starts, matches)
    unconfirmed := Integer(IniRead(OverallStatsFile, section, "UnconfirmedRuns", 0))
    aborted := Integer(IniRead(OverallStatsFile, section, "AbortedRuns", 0))
    active := StatsViewHasActiveRun(scope, displayName) ? 1 : 0
    resolvedAttempts := Max(matches + unconfirmed + aborted, starts - active)
    coverage := (resolvedAttempts > 0) ? Round((matches / resolvedAttempts) * 100) : 0
    winRate := (matches > 0) ? Round((wins / matches) * 100) : 0
    wlRatio := (losses > 0) ? Round(wins / losses, 2) : wins
    elapsedHours := totalSeconds / 3600
    coinsPerHour := (elapsedHours > 0) ? Round(coins / elapsedHours) : 0
    gemsPerHour := (elapsedHours > 0) ? Round(gems / elapsedHours) : 0
    expPerHour := (elapsedHours > 0) ? Round(exp / elapsedHours) : 0
    normalizedExpPerHour := (boostTrackedSeconds > 0) ? Round(normalizedExp / (boostTrackedSeconds / 3600)) : 0
    averageSeconds := (matches > 0) ? Round(totalSeconds / matches) : 0

    Stats_MatchesValue.Text := FormatStatsNumber(starts)
    Stats_WinsValue.Text := FormatStatsNumber(wins)
    Stats_LossesValue.Text := FormatStatsNumber(losses)
    Stats_WinRateValue.Text := winRate "%"
    Stats_CoverageValue.Text := coverage "%"
    Stats_CoinsValue.Text := FormatStatsNumber(coins)
    Stats_GemsValue.Text := FormatStatsNumber(gems)
    Stats_XPValue.Text := FormatStatsNumber(exp)

    if (matches = 0) {
        Stats_Details.Text := "No confirmed result screens for this view.`nStarted: " starts "  •  Unconfirmed: " unconfirmed "  •  Aborted: " aborted "  •  Active: " active
    } else if (scope = "Overall") {
        Stats_Details.Text := "Coins/h " FormatStatsNumber(coinsPerHour)
            . "  •  Gems/h: " FormatStatsNumber(gemsPerHour)
            . "  •  XP/h: " FormatStatsNumber(expPerHour)
            . "`nAverage " FormatStatsDuration(averageSeconds) "  •  Confirmed W/L " wlRatio
            . "`nCoverage " coverage "%  •  Unconfirmed " unconfirmed "  •  Aborted " aborted "  •  Active " active
            . "`nBest coins: " FindBestStatsBreakdown("Map_", "Coins")
            . "  |  Best XP: " FindBestStatsBreakdown("Map_", "EXP")
            . "`nBase XP/h " FormatStatsNumber(normalizedExpPerHour) " (" boostTrackedRuns " boost-tagged)"
            . "  |  Best modifier: " FindBestModifierROI()
    } else {
        Stats_Details.Text := "Coins/h " FormatStatsNumber(coinsPerHour)
            . "  •  Gems/h " FormatStatsNumber(gemsPerHour)
            . "  •  XP/h " FormatStatsNumber(expPerHour)
            . "`nAverage " FormatStatsDuration(averageSeconds) "  •  Confirmed W/L " wlRatio
            . "`nCoverage " coverage "%  •  Unconfirmed " unconfirmed "  •  Aborted " aborted "  •  Active " active
            . "`nTracked " FormatStatsDuration(totalSeconds) "  •  Updated " lastUpdated
        if (scope = "By Modifiers")
            Stats_Details.Text .= "`nNominal reward x" IniRead(OverallStatsFile, section, "ModifierMultiplier", 1) "  •  observed ROI uses confirmed runtime"
        else if (scope = "By XP Boost")
            Stats_Details.Text .= "`nBoost-normalized XP/h " FormatStatsNumber(normalizedExpPerHour) "  •  " boostTrackedRuns " tagged runs"
        else if (scope = "By Strategy")
            Stats_Details.Text .= "`nProfiler: " KronoxProfilerSummary(StateFile)
    }

    Stats_Recent.Text := BuildRecentRunsText()
}

StatsViewHasActiveRun(scope, displayName) {
    global StateFile

    activeRunId := IniRead(StateFile, "State", "ActiveRunId", "")
    if (activeRunId = "")
        return false
    if (scope = "Overall")
        return true
    if (scope = "By Map")
        return (IniRead(StateFile, "State", "ActiveMap", "") = displayName)
    if (scope = "By Gamemode")
        return (IniRead(StateFile, "State", "ActiveMode", "") = displayName)
    if (scope = "By Strategy")
        return (IniRead(StateFile, "State", "ActiveStrategyDisplay", "") = displayName)
    if (scope = "By Modifiers")
        return (KronoxCanonicalModifierSet(IniRead(StateFile, "State", "ActiveModifiers", "")) = displayName)
    if (scope = "By XP Boost")
        return (IniRead(StateFile, "State", "ActiveXPBoostProfile", "") = displayName)
    return false
}

FindBestModifierROI() {
    global OverallStatsFile
    if !FileExist(OverallStatsFile)
        return "No data"
    sections := ""
    try sections := IniRead(OverallStatsFile)
    bestName := "No proven set"
    bestRate := -1
    for section in StrSplit(sections, "`n", "`r") {
        if (SubStr(section, 1, 9) != "Modifier_")
            continue
        wins := Integer(IniRead(OverallStatsFile, section, "TotalTriumphs", 0))
        losses := Integer(IniRead(OverallStatsFile, section, "TotalLosses", 0))
        matches := wins + losses
        totalSeconds := Integer(IniRead(OverallStatsFile, section, "TotalTimeSeconds", 0))
        if (matches < 3 || totalSeconds <= 0)
            continue
        rate := Round(Integer(IniRead(OverallStatsFile, section, "Coins", 0)) / (totalSeconds / 3600))
        if (rate > bestRate) {
            bestRate := rate
            bestName := IniRead(OverallStatsFile, section, "DisplayName", "Unknown") " (" FormatStatsNumber(rate) "/h, n=" matches ")"
        }
    }
    return bestName
}

BuildRecentRunsText() {
    global OverallStatsFile

    recentText := ""
    Loop 3 {
        summary := IniRead(OverallStatsFile, "Overall", "RecentRun" A_Index, "")
        if (summary != "")
            recentText .= (recentText != "" ? "`n" : "") summary
    }
    return (recentText != "") ? recentText : "No confirmed results yet."
}

FindBestStatsBreakdown(prefix, valueKey) {
    global OverallStatsFile

    if !FileExist(OverallStatsFile)
        return "No data"

    sectionNames := ""
    try sectionNames := IniRead(OverallStatsFile)
    bestName := "No data"
    bestRate := -1

    for section in StrSplit(sectionNames, "`n", "`r") {
        if (SubStr(section, 1, StrLen(prefix)) != prefix)
            continue

        totalSeconds := Integer(IniRead(OverallStatsFile, section, "TotalTimeSeconds", 0))
        if (totalSeconds <= 0)
            continue

        value := Integer(IniRead(OverallStatsFile, section, valueKey, 0))
        rate := Round(value / (totalSeconds / 3600))
        if (rate > bestRate) {
            bestRate := rate
            bestName := IniRead(OverallStatsFile, section, "DisplayName", SubStr(section, StrLen(prefix) + 1))
        }
    }

    return (bestRate >= 0) ? bestName " (" FormatStatsNumber(bestRate) "/h)" : "No data"
}

FormatStatsNumber(value) {
    number := Integer(value)
    sign := (number < 0) ? "-" : ""
    digits := String(Abs(number))
    grouped := ""

    while (StrLen(digits) > 3) {
        groupStart := StrLen(digits) - 2
        grouped := "," SubStr(digits, groupStart, 3) grouped
        digits := SubStr(digits, 1, groupStart - 1)
    }

    return sign digits grouped
}

FormatStatsDuration(totalSeconds) {
    totalSeconds := Max(0, Integer(totalSeconds))
    hours := Floor(totalSeconds / 3600)
    minutes := Floor(Mod(totalSeconds, 3600) / 60)
    seconds := Mod(totalSeconds, 60)

    if (hours > 0)
        return hours "h " minutes "m " seconds "s"
    if (minutes > 0)
        return minutes "m " seconds "s"
    return seconds "s"
}

BeginTrackedRun() {
    global StateFile, OverallStatsFile, RunLedgerFile, RunContextFile, StrategyProfileFile
    global SettingsFile, gamemap, difficulty, modifiers, TimeScaleMode

    ResolveActiveRunWithoutResult("Unconfirmed", "next-run-started")

    strategyPath := IniRead(StateFile, "State", "Strategy", "")
    SplitPath(strategyPath, &strategyFileName, , , &strategyName)
    if (strategyName = "")
        strategyName := (strategyFileName != "") ? strategyFileName : "Unknown strategy"

    fingerprint := GetStrategyFingerprint(strategyPath)
    strategyDisplay := strategyName " [" fingerprint "]"
    modifierDisplay := KronoxCanonicalModifierSet(modifiers)
    boostContext := KronoxXPBoostContext(SettingsFile)
    runId := FormatTime(, "yyyyMMdd-HHmmss") "-" Format("{:03}", A_MSec) "-" DllCall("GetCurrentProcessId")
    startedAt := FormatTime(, "yyyy-MM-dd HH:mm:ss")

    RegisterStatsRunStart(OverallStatsFile, "Overall", "Overall")
    RegisterStatsRunStart(OverallStatsFile, "Map", gamemap)
    RegisterStatsRunStart(OverallStatsFile, "Mode", difficulty)
    RegisterStatsRunStart(OverallStatsFile, "Strategy", strategyDisplay)
    RegisterStatsRunStart(OverallStatsFile, "Modifier", modifierDisplay)
    RegisterStatsRunStart(OverallStatsFile, "Boost", boostContext.profile)
    sessionStarts := Integer(IniRead(StateFile, "State", "RunStarts", 0)) + 1
    IniWrite(sessionStarts, StateFile, "State", "RunStarts")

    IniWrite(runId, StateFile, "State", "ActiveRunId")
    IniWrite(startedAt, StateFile, "State", "ActiveRunStartedAt")
    IniWrite(A_TickCount, StateFile, "State", "ActiveRunStartedTick")
    IniWrite(strategyPath, StateFile, "State", "ActiveStrategyPath")
    IniWrite(strategyName, StateFile, "State", "ActiveStrategyName")
    IniWrite(fingerprint, StateFile, "State", "ActiveStrategyFingerprint")
    IniWrite(strategyDisplay, StateFile, "State", "ActiveStrategyDisplay")
    IniWrite(gamemap, StateFile, "State", "ActiveMap")
    IniWrite(difficulty, StateFile, "State", "ActiveMode")
    IniWrite(String(modifiers), StateFile, "State", "ActiveModifiers")
    IniWrite(modifierDisplay, StateFile, "State", "ActiveModifierDisplay")
    IniWrite(boostContext.profile, StateFile, "State", "ActiveXPBoostProfile")
    IniWrite(boostContext.factor, StateFile, "State", "ActiveXPBoostFactor")
    IniWrite(TimeScaleMode, StateFile, "State", "ActiveTimeScaleMode")

    KronoxBudgetBeginRun(StateFile)
    profilerEnabled := KronoxFeatureBool(IniRead(SettingsFile, "Analytics", "ProfilerEnabled", 1))
    IniWrite(profilerEnabled ? 1 : 0, StateFile, "Profiler", "Enabled")
    KronoxProfilerBegin(profilerEnabled, runId, strategyName, fingerprint, StrategyProfileFile, StateFile)

    AppendRunLedgerEvent(RunLedgerFile, runId, "STARTED", "Active", "strategy-playback-started",
        strategyName, fingerprint, gamemap, difficulty, String(modifiers))
    KronoxAppendRunContextEvent(RunContextFile, runId, "STARTED", boostContext.profile, boostContext.factor,
        modifierDisplay, KronoxModifierMultiplier(modifiers), TimeScaleMode,
        IniRead(StateFile, "State", "ActiveTDSVersion", "Unknown"),
        KronoxFeatureBool(IniRead(StateFile, "State", "CanaryActive", 0)) ? "Canary" : "Normal")
    return runId
}

ResolveActiveRunWithoutResult(status, detection) {
    global StateFile, OverallStatsFile, RunLedgerFile

    runId := IniRead(StateFile, "State", "ActiveRunId", "")
    if (runId = "")
        return false

    strategyName := IniRead(StateFile, "State", "ActiveStrategyName", "Unknown strategy")
    fingerprint := IniRead(StateFile, "State", "ActiveStrategyFingerprint", "legacy")
    strategyDisplay := IniRead(StateFile, "State", "ActiveStrategyDisplay", strategyName " [" fingerprint "]")
    mapName := IniRead(StateFile, "State", "ActiveMap", "Unknown")
    modeName := IniRead(StateFile, "State", "ActiveMode", "Unknown")
    modifiersText := IniRead(StateFile, "State", "ActiveModifiers", "")
    modifierDisplay := IniRead(StateFile, "State", "ActiveModifierDisplay", KronoxCanonicalModifierSet(modifiersText))
    boostProfile := IniRead(StateFile, "State", "ActiveXPBoostProfile", "Base XP")
    startedTick := Integer(IniRead(StateFile, "State", "ActiveRunStartedTick", 0))
    duration := (startedTick > 0 && A_TickCount >= startedTick) ? Round((A_TickCount - startedTick) / 1000) : 0

    RegisterIncompleteRunStats(OverallStatsFile, "Overall", "Overall", status)
    RegisterIncompleteRunStats(OverallStatsFile, "Map", mapName, status)
    RegisterIncompleteRunStats(OverallStatsFile, "Mode", modeName, status)
    RegisterIncompleteRunStats(OverallStatsFile, "Strategy", strategyDisplay, status)
    RegisterIncompleteRunStats(OverallStatsFile, "Modifier", modifierDisplay, status)
    RegisterIncompleteRunStats(OverallStatsFile, "Boost", boostProfile, status)
    sessionKey := (status = "Aborted") ? "RunAborted" : "RunUnconfirmed"
    IniWrite(Integer(IniRead(StateFile, "State", sessionKey, 0)) + 1, StateFile, "State", sessionKey)
    AppendRunLedgerEvent(RunLedgerFile, runId, "RESULT", status, detection,
        strategyName, fingerprint, mapName, modeName, modifiersText, duration)

    IniWrite(status, OverallStatsFile, "Overall", "LastAttemptStatus")
    IniWrite(detection, OverallStatsFile, "Overall", "LastAttemptDetection")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), OverallStatsFile, "Overall", "LastAttemptAt")
    ClearActiveRunState()
    return true
}

RegisterStatsRunStart(file, kind, displayName) {
    if (kind != "Overall" && (displayName = "" || displayName = "Unknown"))
        return

    section := (kind = "Overall") ? "Overall" : kind "_" SanitizeStatsSectionNameMain(displayName)
    confirmed := Integer(IniRead(file, section, "TotalTriumphs", 0)) + Integer(IniRead(file, section, "TotalLosses", 0))
    starts := Max(confirmed, Integer(IniRead(file, section, "TotalRunStarts", confirmed))) + 1
    IniWrite(starts, file, section, "TotalRunStarts")
    if (kind != "Overall") {
        IniWrite(kind, file, section, "Kind")
        IniWrite(displayName, file, section, "DisplayName")
    }
}

RegisterIncompleteRunStats(file, kind, displayName, status) {
    if (kind != "Overall" && (displayName = "" || displayName = "Unknown"))
        return

    section := (kind = "Overall") ? "Overall" : kind "_" SanitizeStatsSectionNameMain(displayName)
    key := (status = "Aborted") ? "AbortedRuns" : "UnconfirmedRuns"
    count := Integer(IniRead(file, section, key, 0)) + 1
    IniWrite(count, file, section, key)
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), file, section, "LastUpdated")
    if (kind != "Overall") {
        IniWrite(kind, file, section, "Kind")
        IniWrite(displayName, file, section, "DisplayName")
    }
}

ClearActiveRunState() {
    global StateFile

    for key in ["ActiveRunId", "ActiveRunStartedAt", "ActiveRunStartedTick", "ActiveStrategyPath",
        "ActiveStrategyName", "ActiveStrategyFingerprint", "ActiveStrategyDisplay", "ActiveMap",
        "ActiveMode", "ActiveModifiers", "ActiveModifierDisplay", "ActiveXPBoostProfile", "ActiveXPBoostFactor", "ActiveTimeScaleMode"]
        try IniDelete(StateFile, "State", key)
}

GetStrategyFingerprint(path) {
    if (path = "" || !FileExist(path))
        return "missing"

    try content := FileRead(path)
    catch
        return "unreadable"

    hash := 2166136261
    Loop Parse, content {
        hash := hash ^ Ord(A_LoopField)
        hash := Mod(hash * 16777619, 4294967296)
    }
    return "v" Format("{:08X}", Integer(hash))
}

SanitizeStatsSectionNameMain(name) {
    cleanName := RegExReplace(Trim(name), "[^A-Za-z0-9 _-]", "_")
    cleanName := RegExReplace(cleanName, "\s+", "_")
    return (cleanName != "") ? cleanName : "Unknown"
}

AppendRunLedgerEvent(file, runId, eventName, status, detection, strategyName, fingerprint,
    mapName, modeName, modifiersText, durationSeconds := 0, coins := 0, gems := 0, exp := 0) {
    if (!FileExist(file))
        FileAppend("Timestamp,RunId,Event,Status,Detection,Strategy,StrategyFingerprint,Map,Mode,Modifiers,DurationSeconds,Coins,Gems,XP`n", file, "UTF-8")

    row := LedgerCsvField(FormatTime(, "yyyy-MM-dd HH:mm:ss")) ","
        . LedgerCsvField(runId) "," . LedgerCsvField(eventName) "," . LedgerCsvField(status) ","
        . LedgerCsvField(detection) "," . LedgerCsvField(strategyName) "," . LedgerCsvField(fingerprint) ","
        . LedgerCsvField(mapName) "," . LedgerCsvField(modeName) "," . LedgerCsvField(modifiersText) ","
        . Integer(durationSeconds) "," . Integer(coins) "," . Integer(gems) "," . Integer(exp) "`n"
    FileAppend(row, file, "UTF-8")
}

LedgerCsvField(value) {
    return '"' StrReplace(String(value), '"', '""') '"'
}

SelectCommunityStrategyFilter(ctrl, *) {
    global CommunityFilter, SettingsFile
    if (CommunityFilter = ctrl.FilterName)
        return
    CommunityFilter := ctrl.FilterName
    IniWrite(CommunityFilter, SettingsFile, "StrategyLibrary", "Filter")
    RefreshCommunityFilterStyles()
    SetTimer(RebuildCommunityStrategyGui, -10)
}

ToggleCommunityStrategyFavorite(ctrl, *) {
    global CommunityFavoriteFiles, SettingsFile
    key := KronoxStrategyFavoriteKey(ctrl.StratFile)
    if (CommunityFavoriteFiles.Has(key))
        CommunityFavoriteFiles.Delete(key)
    else
        CommunityFavoriteFiles[key] := ctrl.StratFile
    IniWrite(KronoxStrategyFavoritesSerialize(CommunityFavoriteFiles), SettingsFile, "StrategyLibrary", "Favorites")
    RefreshCommunityFilterStyles()
    SetTimer(RebuildCommunityStrategyGui, -10)
}

RefreshCommunityFilterStyles() {
    global CommunityFilterButtons, CommunityFilter, CommunityFavoriteFiles, LoadedStrats
    availableFavoriteCount := 0
    for strat in LoadedStrats {
        if (CommunityFavoriteFiles.Has(KronoxStrategyFavoriteKey(strat.fileName)))
            availableFavoriteCount += 1
    }
    for ctrl in CommunityFilterButtons {
        selected := StrLower(ctrl.FilterName) = StrLower(CommunityFilter)
        ctrl.Text := (ctrl.FilterName = "Favorites") ? "Favorites (" availableFavoriteCount ")" : ctrl.FilterName
        ctrl.Opt("Background" ThemeColor(selected ? "AccentSubtle" : "Surface"))
        ctrl.SetFont("s8 w" (selected ? "700" : "600") " c" ThemeColor(selected ? "AccentHover" : "TextSecondary"), "Segoe UI")
        ctrl.Redraw()
    }
}

RebuildCommunityStrategyGui(*) {
    global CurrentTab
    BuildCommunityStrategyGui()
    if (CurrentTab = "Tab1")
        ShowChildGui()
}

BuildCommunityStrategyGui() {
    global MainGui, ChildGui, LoadedStrats, CommunityFilter, CommunityFavoriteFiles, CommunityStrategyCount
    global FrameW, FrameH, ContentH, CurrentScrollPos, SliderH, SliderBG, CustomSlider, GradientButtons

    try ChildGui.Destroy()
    GradientButtons := []
    CurrentScrollPos := 0
    SliderBG := ""
    CustomSlider := ""

    ChildGui := Gui("-Caption +E0x20 +Border +Parent" MainGui.Hwnd)
    ChildGui.BackColor := ThemeColor("App")
    ChildGui.SetFont("s10 c" ThemeColor("TextPrimary"), "Segoe UI")

    visibleStrats := []
    for strat in LoadedStrats {
        if (KronoxStrategyMatchesLibraryFilter(strat.difficulty, strat.fileName, CommunityFilter, CommunityFavoriteFiles))
            visibleStrats.Push(strat)
    }

    CommunityStrategyCount.Text := visibleStrats.Length " OF " LoadedStrats.Length
    StartY := 10
    CardH := 112
    CardW := 610
    Gap := 12
    ContentH := StartY

    for index, strat in visibleStrats {
        CurrentY := StartY + ((index - 1) * (CardH + Gap))
        ContentH := CurrentY + CardH + Gap
        C1X := 8
        C1Y := CurrentY

        hFrameBg := CreateFrame(CardW, CardH, 10, "0xFF120B0D", "0xFF43242B", "0xFF2D171C")
        ChildGui.Add("Picture", "x" C1X " y" C1Y " w" CardW " h" CardH " +BackgroundTrans", "HBITMAP:*" hFrameBg)

        hIconBg := CreateGradientButton(56, 56, 8, "0xFF2A1B1D", "0xFF0E090A", "0xff000000", "0x2343242B", "", "Segoe UI", 10, 1)
        ChildGui.Add("Picture", "x" (C1X + 10) " y" (C1Y + 29) " w76 h76 +BackgroundTrans", "HBITMAP:*" hIconBg)
        diffImg := "Resources/Strats/images/" strat.difficulty ".png"
        if (FileExist(diffImg))
            ChildGui.Add("Picture", "x" (C1X + 20) " y" (C1Y + 39) " h56 w56 +BackgroundTrans", diffImg)

        ChildGui.Add("Picture", "x" (C1X + 75) " y" (C1Y + 29) " w76 h76 +BackgroundTrans", "HBITMAP:*" hIconBg)
        coinsCount := 0
        if RegExMatch(strat.income, "i)([\d,]+)\s*coins", &incomeMatch)
            coinsCount := Number(StrReplace(incomeMatch[1], ","))
        if (strat.difficulty = "Hardcore" || strat.difficulty = "Voidcore")
            rewardIcon := "Resources/Strats/images/GemsMediumPile.png"
        else if (coinsCount >= 8000)
            rewardIcon := "Resources/Strats/images/CoinsSmallChest.png"
        else if (coinsCount >= 6000)
            rewardIcon := "Resources/Strats/images/CoinsMediumPile.png"
        else
            rewardIcon := "Resources/Strats/images/CoinsSmallPile.png"
        if (FileExist(rewardIcon))
            ChildGui.Add("Picture", "x" (C1X + 85) " y" (C1Y + 39) " h56 w56 +BackgroundTrans", rewardIcon)

        ChildGui.SetFont("s11 w700 c" ThemeColor("TextPrimary"), "Segoe UI")
        ChildGui.Add("Text", "x" (C1X + 15) " y" (C1Y + 9) " w430 h22 +BackgroundTrans", strat.title)

        favoriteKey := KronoxStrategyFavoriteKey(strat.fileName)
        favoriteCtrl := ChildGui.Add("Text", "x" (C1X + 545) " y" (C1Y + 7) " w26 h26 Center +0x200 BackgroundTrans", CommunityFavoriteFiles.Has(favoriteKey) ? "★" : "☆")
        favoriteCtrl.SetFont("s15 w400 c" ThemeColor(CommunityFavoriteFiles.Has(favoriteKey) ? "AccentHover" : "TextMuted"), "Segoe UI Symbol")
        favoriteCtrl.StratFile := strat.fileName
        favoriteCtrl.OnEvent("Click", ToggleCommunityStrategyFavorite)

        ChildGui.SetFont("s9 w700 c" ThemeColor("TextMuted"), "Segoe UI")
        helpCtrl := ChildGui.Add("Text", "x" (C1X + 580) " y" (C1Y + 10) " w18 h20 Center +BackgroundTrans", "i")
        helpCtrl.OnEvent("Click", ((t, a, r, m, d) => (*) => StratInfo(t, a, r, m, d))(
            strat.title, strat.author, strat.towers, (strat.modifiers != "" ? strat.modifiers : "none"), strat.desc))

        if (strat.difficulty = "Hardcore")
            badgeColor1 := "0xFFB91F24", badgeColor2 := "0xFF7A151B"
        else if (strat.difficulty = "Molten")
            badgeColor1 := "0xFFE09334", badgeColor2 := "0xFF8F5413"
        else if (strat.difficulty = "Frost")
            badgeColor1 := "0xff34a9e0", badgeColor2 := "0xff17559c"
        else if (strat.difficulty = "Fallen")
            badgeColor1 := "0xFF374151", badgeColor2 := "0xFF1F2937"
        else
            badgeColor1 := "0xb900ff2a", badgeColor2 := "0xff1a5f39"
        hgmMode := CreateGradientButton(102, 28, 3, badgeColor1, badgeColor2, "0x40000000", "0x7effffff", strat.difficulty != "" ? strat.difficulty : "Easy", "Segoe UI", 11, 1)
        ChildGui.Add("Picture", "x" (C1X + 145) " y" (C1Y + 34) " w102 h28 +BackgroundTrans", "HBITMAP:*" hgmMode)

        ChildGui.SetFont("s9 w500 c" ThemeColor("TextSecondary"), "Segoe UI")
        ChildGui.Add("Text", "x" (C1X + 154) " y" (C1Y + 66) " w105 h18 +BackgroundTrans", "◷ " (strat.time != "" ? strat.time : "Not listed"))
        ChildGui.Add("Text", "x" (C1X + 154) " y" (C1Y + 84) " w105 h18 +BackgroundTrans", "◈ " (strat.income != "" ? strat.income : "Not listed"))

        ChildGui.SetFont("s7 w700 c" ThemeColor("Accent"), "Segoe UI")
        ChildGui.Add("Text", "x" (C1X + 270) " y" (C1Y + 31) " w95 h16 +BackgroundTrans", "REQUIRED LOADOUT")
        ChildGui.SetFont("s9 w400 c" ThemeColor("TextPrimary"), "Segoe UI")
        ChildGui.Add("Text", "x" (C1X + 270) " y" (C1Y + 47) " w320 h20 +BackgroundTrans", strat.towers != "" ? strat.towers : "No tower requirement")

        hBtnNormal := CreateGradientButton(220, 34, 8, "0xFFB91F24", "0xFF7A151B", "0x40000000", "0x5dffffff", "Load strategy", "Segoe UI", 12, 1)
        hBtnHover := CreateGradientButton(220, 34, 8, "0xFFFF4545", "0xFFEF2B2D", "0x60000000", "0x5dffffff", "Load strategy", "Segoe UI", 12, 1)
        picLoadBtn := ChildGui.Add("Picture", "x" (C1X + 365) " y" (C1Y + 70) " w220 h34 +BackgroundTrans", "HBITMAP:*" hBtnNormal)
        loadCtrl := ChildGui.Add("Text", "x" (C1X + 365) " y" (C1Y + 70) " w220 h34 +BackgroundTrans +0x200 Center", "")
        loadCtrl.SetFont("cFFFFFF s10 w700", "Segoe UI")
        loadCtrl.StratFile := strat.fileName
        loadCtrl.OnEvent("Click", DownloadStrat)
        loadCtrl.PicControl := picLoadBtn
        loadCtrl.ImgNormal := hBtnNormal
        loadCtrl.ImgHover := hBtnHover
        GradientButtons.Push(loadCtrl)
    }

    if (visibleStrats.Length = 0) {
        ChildGui.SetFont("s15 w700 c" ThemeColor("TextPrimary"), "Segoe UI")
        ChildGui.Add("Text", "x20 y65 w600 h28 +BackgroundTrans Center", CommunityFilter = "Favorites" ? "No favorites yet" : "No strategies in this mode")
        ChildGui.SetFont("s9 w400 c" ThemeColor("TextMuted"), "Segoe UI")
        ChildGui.Add("Text", "x40 y101 w560 h44 +BackgroundTrans Center", CommunityFilter = "Favorites" ? "Select the star on any strategy to keep it one click away here." : "Choose another gamemode filter to continue browsing.")
        ContentH := FrameH
    }

    if (ContentH > FrameH) {
        SliderH := Max(30, Round(FrameH * (FrameH / ContentH)))
        SliderX := FrameW - 9
        SliderW := 5
        hSliderBG := CreateScrollThumb(SliderW, FrameH, 3, "0xFF1A1113", "0xFF1A1113", "0x000000")
        hSlider := CreateScrollThumb(SliderW, SliderH, 3, "0xFFEF2B2D", "0xFFB91F24", "0xFF351215")
        SliderBG := ChildGui.Add("Picture", "x" SliderX " y0 w" SliderW " h" FrameH " +BackgroundTrans", "HBITMAP:*" hSliderBG)
        CustomSlider := ChildGui.Add("Picture", "x" SliderX " y0 w" SliderW " h" SliderH " +BackgroundTrans", "HBITMAP:*" hSlider)
    } else {
        SliderH := FrameH
    }

    ApplyDarkControlThemes(ChildGui)
    ApplyDarkWindowTheme(ChildGui.Hwnd)
}

ShowChildGui() {
    global ChildGui, FrameX, FrameY, FrameW, FrameH, MainGui
    ChildGui.Show("x" FrameX " y" FrameY " w" FrameW " h" FrameH)
}


MoveWindow(ctrl, *) {
    PostMessage(0xA1, 2, , , MainGui)
}
MinimizeWindow(ctrl, *) {
    MainGui.Minimize()
}
CloseWindow(ctrl, *) {
    ExitApp()
}
DiscordLink(ctrl, *) {
    Run("https://discord.gg/DQnc2JDJtr")
}
githubLink(ctrl, *) {
    Run("https://github.com/kronoxhellstorm/tds-macro-kronox")
}
YouTubeLink(ctrl, *) {
    Run("https://www.youtube.com/@darksenn")
}

DownloadStrat(ctrl, *) {
    nm := ctrl.StratFile 
    
    downloadedStrat := A_WorkingDir "\Resources\Strats" (SubStr(nm, 1, 1) = "\" ? nm : "\" nm)

    if (Strategy1Ctrl.Value = "") {
    Strategy1Ctrl.Value := downloadedStrat
    Strategy1Path := downloadedStrat
    IniWrite(downloadedStrat, SettingsFile, "Options", "Strategy1")
    } else if (Strategy2Ctrl.Value = "" && Strategy2Ctrl.Visible) {
        Strategy2Ctrl.Value := downloadedStrat
        Strategy2Path := downloadedStrat
        IniWrite(downloadedStrat, SettingsFile, "Options", "Strategy2")
    } else {
        Strategy1Ctrl.Value := downloadedStrat
        Strategy1Path := downloadedStrat
        IniWrite(downloadedStrat, SettingsFile, "Options", "Strategy1")
    }
    
    LoadStrategyFile(downloadedStrat)
}


InitializeSettingsScroll() {
    global SettingsScrollableCtrls, SettingsBaseY, SettingsScrollMax
    global SettingsViewportBottom

    SettingsBaseY := Map()
    maxBottom := 0
    for ctrl in SettingsScrollableCtrls {
        try {
            ctrl.GetPos(, &ctrlY, , &ctrlH)
            SettingsBaseY[ctrl.Hwnd] := ctrlY
            maxBottom := Max(maxBottom, ctrlY + ctrlH)
        }
    }
    SettingsScrollMax := Max(0, maxBottom - SettingsViewportBottom + 12)
}

ApplySettingsScroll() {
    global CurrentTab, SettingsScrollableCtrls, SettingsBaseY, SettingsScrollOffset
    global SettingsScrollMax, SettingsViewportTop, SettingsViewportBottom
    global SettingsScrollTrack, SettingsScrollThumb, MainGui

    if (!IsSet(CurrentTab) || CurrentTab != "Tab5")
        return

    ; Moving dozens of native controls one at a time leaves stale text/edit
    ; fragments on some Windows renderers. Batch the layout under WM_SETREDRAW,
    ; then invalidate the parent and all children in one paint pass.
    DllCall("SendMessage", "Ptr", MainGui.Hwnd, "UInt", 0x000B, "Ptr", 0, "Ptr", 0)
    try {
        SettingsScrollOffset := Max(0, Min(SettingsScrollOffset, SettingsScrollMax))
        for ctrl in SettingsScrollableCtrls {
            try {
                ctrl.GetPos(, , , &ctrlH)
                newY := SettingsBaseY[ctrl.Hwnd] - SettingsScrollOffset
                ctrl.Move(, newY)
                ctrl.Visible := (newY >= SettingsViewportTop && (newY + ctrlH) <= SettingsViewportBottom)
            }
        }

        viewportHeight := SettingsViewportBottom - SettingsViewportTop
        contentHeight := viewportHeight + SettingsScrollMax
        thumbHeight := (contentHeight > 0) ? Max(55, Round(viewportHeight * viewportHeight / contentHeight)) : viewportHeight
        travel := Max(0, viewportHeight - thumbHeight)
        thumbY := SettingsViewportTop + ((SettingsScrollMax > 0) ? Round((SettingsScrollOffset / SettingsScrollMax) * travel) : 0)
        SettingsScrollTrack.Move(, SettingsViewportTop, , viewportHeight)
        SettingsScrollThumb.Move(, thumbY, , thumbHeight)
        SettingsScrollTrack.Visible := SettingsScrollMax > 0
        SettingsScrollThumb.Visible := SettingsScrollMax > 0
    } finally {
        DllCall("SendMessage", "Ptr", MainGui.Hwnd, "UInt", 0x000B, "Ptr", 1, "Ptr", 0)
        DllCall("RedrawWindow", "Ptr", MainGui.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0185)
    }
}

SettingsScrollBy(amount) {
    global SettingsScrollOffset, SettingsScrollMax
    newOffset := Max(0, Min(SettingsScrollOffset + amount, SettingsScrollMax))
    if (newOffset = SettingsScrollOffset)
        return
    SettingsScrollOffset := newOffset
    ApplySettingsScroll()
}

UpdateTowerXPControlState(*) {
    global TowerXPEnabledCtrl, TowerXPStopModeCtrl, TowerXPRows

    enabled := TowerXPEnabledCtrl.Value = 1
    stopMode := TowerXPStoredStopMode(TowerXPStopModeCtrl.Text)
    TowerXPStopModeCtrl.Enabled := enabled

    for row in TowerXPRows {
        tracked := row.track.Value = 1
        row.track.Enabled := enabled
        row.level.Enabled := enabled && tracked
        row.xp.Enabled := enabled && tracked

        levelText := Trim(row.level.Text)
        xpText := Trim(row.xp.Text)
        if (!RegExMatch(levelText, "^\d+$") || !RegExMatch(xpText, "^\d+$")) {
            row.requirement.Text := "CHECK VALUES"
        } else {
            progress := TowerXPAdvance(row.definition, Integer(levelText), Integer(xpText))
            row.requirement.Text := progress.isMax ? "MAX LEVEL" : progress.xp "/" progress.nextRequired " XP"
            row.xp.Enabled := enabled && tracked && !progress.isMax
        }

        if (!tracked)
            row.target.Value := 0
        row.target.Enabled := enabled && tracked && stopMode != "Never"
    }
}

CollectTowerXPSettings() {
    global TowerXPEnabledCtrl, TowerXPStopModeCtrl, TowerXPRows

    config := {enabled: TowerXPEnabledCtrl.Value = 1,
        stopMode: TowerXPStoredStopMode(TowerXPStopModeCtrl.Text), entries: []}
    targetCount := 0

    for row in TowerXPRows {
        levelText := Trim(row.level.Text)
        xpText := Trim(row.xp.Text)
        if (!RegExMatch(levelText, "^\d+$") || Integer(levelText) > row.definition.maxLevel) {
            MsgBox(row.definition.name " level must be a whole number from 0 to " row.definition.maxLevel ".",
                "Tower XP settings", 0x10)
            return false
        }
        if (!RegExMatch(xpText, "^\d+$")) {
            MsgBox(row.definition.name " XP must be a non-negative whole number.", "Tower XP settings", 0x10)
            return false
        }

        progress := TowerXPAdvance(row.definition, Integer(levelText), Integer(xpText))
        tracked := row.track.Value = 1
        stopTarget := row.target.Value = 1
        if (stopTarget && !tracked) {
            MsgBox(row.definition.name " is a stop target but is not enabled for tracking.", "Tower XP settings", 0x10)
            return false
        }
        if (stopTarget)
            targetCount += 1
        config.entries.Push({definition: row.definition, tracked: tracked, level: progress.level,
            xp: progress.xp, stopTarget: stopTarget})
    }

    if (config.enabled && config.stopMode != "Never" && targetCount = 0) {
        MsgBox("Choose at least one tracked tower as a stop target, or set Stop macro when to Never.",
            "Tower XP settings", 0x10)
        return false
    }
    return config
}

PersistTowerXPSettings(config) {
    global SettingsFile, TowerXPTrackerEnabled, TowerXPStopMode, TowerXPRows

    TowerXPTrackerEnabled := config.enabled ? 1 : 0
    TowerXPStopMode := config.stopMode
    IniWrite(TowerXPTrackerEnabled, SettingsFile, "TowerXP", "Enabled")
    IniWrite(TowerXPStopMode, SettingsFile, "TowerXP", "StopMode")

    for index, entry in config.entries {
        section := TowerXPSectionName(entry.definition.name)
        IniWrite(entry.tracked ? 1 : 0, SettingsFile, section, "Tracked")
        IniWrite(entry.level, SettingsFile, section, "Level")
        IniWrite(entry.xp, SettingsFile, section, "XP")
        IniWrite(entry.stopTarget ? 1 : 0, SettingsFile, section, "StopTarget")
        TowerXPRows[index].level.Text := entry.level
        TowerXPRows[index].xp.Text := entry.xp
    }
    UpdateTowerXPControlState()
}

CollectKronoxFeatureSettings() {
    queueNames := []
    queueSeen := Map()
    for rawName in KronoxEvolutionTokens(EvolutionQueueTowersCtrl.Text) {
        definition := KronoxTowerDefinition(rawName)
        if (!IsObject(definition)) {
            if (Trim(rawName) != "") {
                MsgBox("Unsupported Evolution Queue tower: " Trim(rawName) ".`n`nType Tower Evolution names separated by commas, for example:`nOperator, Juggernaut, Kingpin`n`nUse names listed in the Tower XP tracker.", "Evolution Queue", 0x10)
                return false
            }
            continue
        }
        key := StrLower(definition.name)
        if (!queueSeen.Has(key)) {
            queueSeen[key] := true
            queueNames.Push(definition.name)
        }
    }
    if (EvolutionQueueEnabledCtrl.Value = 1 && queueNames.Length = 0) {
        MsgBox("Evolution Queue is enabled but its queue is empty.", "Evolution Queue", 0x10)
        return false
    }

    otherBoostText := Trim(OtherXPBoostCtrl.Text)
    if (!IsNumber(otherBoostText) || Number(otherBoostText) < 0.1 || Number(otherBoostText) > 10) {
        MsgBox("Other XP boost must be a number from 0.1 to 10.", "Boost analytics", 0x10)
        return false
    }

    numericFields := [
        {ctrl: TicketBalanceCtrl, name: "Ticket balance"},
        {ctrl: TicketReserveCtrl, name: "Ticket reserve"},
        {ctrl: TicketSessionCtrl, name: "Ticket session cap"},
        {ctrl: ConsumableRunCtrl, name: "Consumable per-run cap"},
        {ctrl: ConsumableSessionCtrl, name: "Consumable session cap"}
    ]
    values := []
    for field in numericFields {
        fieldText := Trim(field.ctrl.Text)
        if (!RegExMatch(fieldText, "^\d+$")) {
            MsgBox(field.name " must be a non-negative whole number.", "Resource Budget Guard", 0x10)
            return false
        }
        values.Push(Integer(fieldText))
    }
    if (values[2] > values[1]) {
        MsgBox("Ticket reserve cannot be greater than the current ticket balance.", "Resource Budget Guard", 0x10)
        return false
    }

    versionOverride := Trim(TDSVersionOverrideCtrl.Text)
    if (versionOverride != "" && KronoxExtractTDSVersion(versionOverride ~= "i)^v" ? versionOverride : "v" versionOverride) = "") {
        MsgBox("Version override must look like 2.6.1 or v2.6.1.", "TDS Update Canary", 0x10)
        return false
    }

    return {
        evolutionEnabled: EvolutionQueueEnabledCtrl.Value = 1,
        evolutionAutoEquip: EvolutionQueueAutoEquipCtrl.Value = 1,
        evolutionTowers: KronoxJoin(queueNames),
        profilerEnabled: StrategyProfilerEnabledCtrl.Value = 1,
        weekendBoost: WeekendXPBoostCtrl.Value = 1,
        vipBoost: VIPXPBoostCtrl.Value = 1,
        otherBoost: Round(Number(otherBoostText), 3),
        timeScaleBudget: TimeScaleBudgetEnabledCtrl.Value = 1,
        ticketBalance: values[1], ticketReserve: values[2], ticketSession: values[3],
        consumableBudget: ConsumableBudgetEnabledCtrl.Value = 1,
        consumableRun: values[4], consumableSession: values[5],
        canaryEnabled: UpdateCanaryEnabledCtrl.Value = 1,
        versionOverride: versionOverride,
        absoluteMode: AbsoluteModeEnabledCtrl.Value = 1
    }
}

PersistKronoxFeatureSettings(config, towerXPConfig) {
    global SettingsFile, StateFile
    global EvolutionQueueEnabled, EvolutionQueueTowers, EvolutionQueueAutoEquip
    global StrategyProfilerEnabled, WeekendXPBoostEnabled, VIPXPBoostEnabled, OtherXPBoostMultiplier
    global TimeScaleBudgetEnabled, TimeScaleTicketBalance, TimeScaleTicketReserve, TimeScaleTicketMaxSession
    global ConsumableBudgetEnabled, ConsumableMaxPerRun, ConsumableMaxPerSession
    global UpdateCanaryEnabled, TDSVersionOverride, AbsoluteModeEnabled

    oldQueue := IniRead(SettingsFile, "EvolutionQueue", "Towers", "")
    oldEnabled := Integer(IniRead(SettingsFile, "EvolutionQueue", "Enabled", 0))
    EvolutionQueueEnabled := config.evolutionEnabled ? 1 : 0
    EvolutionQueueTowers := config.evolutionTowers
    EvolutionQueueAutoEquip := config.evolutionAutoEquip ? 1 : 0
    StrategyProfilerEnabled := config.profilerEnabled ? 1 : 0
    WeekendXPBoostEnabled := config.weekendBoost ? 1 : 0
    VIPXPBoostEnabled := config.vipBoost ? 1 : 0
    OtherXPBoostMultiplier := config.otherBoost
    TimeScaleBudgetEnabled := config.timeScaleBudget ? 1 : 0
    TimeScaleTicketBalance := config.ticketBalance
    TimeScaleTicketReserve := config.ticketReserve
    TimeScaleTicketMaxSession := config.ticketSession
    ConsumableBudgetEnabled := config.consumableBudget ? 1 : 0
    ConsumableMaxPerRun := config.consumableRun
    ConsumableMaxPerSession := config.consumableSession
    UpdateCanaryEnabled := config.canaryEnabled ? 1 : 0
    TDSVersionOverride := config.versionOverride
    AbsoluteModeEnabled := config.absoluteMode ? 1 : 0

    IniWrite(EvolutionQueueEnabled, SettingsFile, "EvolutionQueue", "Enabled")
    IniWrite(EvolutionQueueTowers, SettingsFile, "EvolutionQueue", "Towers")
    IniWrite(EvolutionQueueAutoEquip, SettingsFile, "EvolutionQueue", "AutoEquip")
    if (oldQueue != EvolutionQueueTowers || oldEnabled != EvolutionQueueEnabled) {
        IniWrite("", SettingsFile, "EvolutionQueue", "Assignments")
        IniWrite(1, StateFile, "State", "EvolutionQueuePendingEquip")
    }
    IniWrite(StrategyProfilerEnabled, SettingsFile, "Analytics", "ProfilerEnabled")
    IniWrite(WeekendXPBoostEnabled, SettingsFile, "Analytics", "WeekendXPBoost")
    IniWrite(VIPXPBoostEnabled, SettingsFile, "Analytics", "VIPXPBoost")
    IniWrite(OtherXPBoostMultiplier, SettingsFile, "Analytics", "OtherXPBoost")
    IniWrite(TimeScaleBudgetEnabled, SettingsFile, "ResourceBudget", "TimeScaleEnabled")
    IniWrite(TimeScaleTicketBalance, SettingsFile, "ResourceBudget", "TicketBalance")
    IniWrite(TimeScaleTicketReserve, SettingsFile, "ResourceBudget", "TicketReserve")
    IniWrite(1, SettingsFile, "ResourceBudget", "TicketCostPerRun")
    IniWrite(TimeScaleTicketMaxSession, SettingsFile, "ResourceBudget", "TicketMaxPerSession")
    IniWrite(ConsumableBudgetEnabled, SettingsFile, "ResourceBudget", "ConsumableEnabled")
    IniWrite(ConsumableMaxPerRun, SettingsFile, "ResourceBudget", "ConsumableMaxPerRun")
    IniWrite(ConsumableMaxPerSession, SettingsFile, "ResourceBudget", "ConsumableMaxPerSession")
    IniWrite(UpdateCanaryEnabled, SettingsFile, "UpdateCanary", "Enabled")
    IniWrite(TDSVersionOverride, SettingsFile, "UpdateCanary", "VersionOverride")
    IniWrite(AbsoluteModeEnabled, SettingsFile, "Reliability", "AbsoluteMode")
    IniWrite(300000, SettingsFile, "Reliability", "JoinTimeoutMs")
    IniWrite(600000, SettingsFile, "Reliability", "IdleTimeoutMs")

    if (EvolutionQueueEnabled) {
        IniWrite(1, SettingsFile, "TowerXP", "Enabled")
        for towerName in KronoxEvolutionQueue(SettingsFile)
            IniWrite(1, SettingsFile, TowerXPSectionName(towerName), "Tracked")
    }
    EvolutionQueueStatusCtrl.Text := "  Current slots: " KronoxEvolutionAssignmentText(SettingsFile) "`n  Assignments refresh when the strategy starts; completed level-20 towers advance automatically."
}

OnMouseWheel(wp, lp, msg, hwnd) {
    global ChildHwnd, ChildGui, CurrentTab, MainGui
    MouseGetPos(, , &maxH, &ctrlH, 2)

    if (CurrentTab = "Tab5" && maxH = MainGui.Hwnd) {
        wheelDelta := (wp >> 16) & 0xFFFF
        if (wheelDelta > 0x7FFF)
            wheelDelta -= 0x10000
        SettingsScrollBy(wheelDelta > 0 ? -60 : 60)
        return
    }

    parentH := (ctrlH != "") ? DllCall("GetParent", "Ptr", ctrlH, "Ptr") : 0
    ch := ChildGui.Hwnd
    
    if (maxH = ch || ctrlH = ch || parentH = ch) {
        
        dir := ((wp >> 16) & 0xFFFF) > 0x7FFF ? 1 : 0
        Loop 3 {
            
            SendMessage(0x0115, dir, 0, , "ahk_id " ch)
        }
    }
}


OnScroll(wp, lp, msg, hwnd) {
    global ChildGui, CurrentScrollPos, ContentH, FrameH, SliderH, CustomSlider, SliderBG
    ch := ChildGui.Hwnd
    if (hwnd != ch)
        return
    action := wp & 0xFFFF
    if (action = 0) {
        newPos := CurrentScrollPos - 12
    } else if (action = 1) {
        newPos := CurrentScrollPos + 12
    } else {
        return
    }
    maxScroll := ContentH - FrameH
    if (maxScroll <= 0)
        return
    newPos := Max(0, Min(newPos, maxScroll))
    if (newPos != CurrentScrollPos) {
        DllCall("ScrollWindow", "Ptr", hwnd, "Int", 0, "Int", CurrentScrollPos - newPos, "Ptr", 0, "Ptr", 0)
        CurrentScrollPos := newPos
        
        availableTrackSpace := FrameH - SliderH

        sliderVisualY := Round((newPos / maxScroll) * availableTrackSpace)
        
        ; ScrollWindow moves every child, including the decorative scrollbar.
        ; Offset both scrollbar pieces by the content position so they remain fixed in the viewport.
        if (IsObject(SliderBG))
            SliderBG.Move(, newPos)
        if (IsObject(CustomSlider))
            CustomSlider.Move(, newPos + sliderVisualY)
        
        DllCall("UpdateWindow", "Ptr", hwnd)
    }
}

EnableStratRotation(*) {
    global RotateStrategies, SwapAmount, SwapUnit
    
    v := MainGui.Submit(false)
    RotateStrategies := v.RotateStrategies
    IniWrite(RotateStrategies, SettingsFile, "Options", "RotateStrategies")
    
    show := (RotateStrategies = 1)

    Tab1_Lbl2.Visible := show
    Strategy2Ctrl.Visible := show
    Tab1_Btn3.Visible := show
    Tab1_Btn4.Visible := show

    SwapAfterLbl.Visible := show
    SwapAmountCtrl.Visible := show
    SwapUnitCtrl.Visible := show

    AutoEquipCtrl.Enabled := !show

    if (show) {
        AutoEquipCtrl.Value := 1
        v := MainGui.Submit(false)
        AutoEquip := v.AutoEquip
        IniWrite(AutoEquip, SettingsFile, "Options", "AutoEquip")
        SwapAmount := SwapAmountCtrl.Text
        SwapUnit := SwapUnitCtrl.Text
        AutoEquipCtrl.Move(365, 190)
        IniWrite(SwapAmount, SettingsFile, "Options", "SwapAmount")
        IniWrite(SwapUnit, SettingsFile, "Options", "SwapUnit")
    } else {
        AutoEquipCtrl.Move(205, 190)
    }
}

EnableAutoEquip(*) {
    global AutoEquip
    
    v := MainGui.Submit(false)
    AutoEquip := v.AutoEquip
    IniWrite(AutoEquip, SettingsFile, "Options", "AutoEquip")
}

UpdateRecAbstractSlotControls(*) {
    global RecAbstractSlotEnabledCtrl, RecAbstractSlotCtrls
    enabled := RecAbstractSlotEnabledCtrl.Value = 1
    for slotCtrl in RecAbstractSlotCtrls
        slotCtrl.Enabled := enabled
}

CollectRecAbstractSlots() {
    global RecAbstractSlotEnabledCtrl, RecAbstractSlotCtrls
    if (RecAbstractSlotEnabledCtrl.Value != 1)
        return []
    slots := []
    for slot, slotCtrl in RecAbstractSlotCtrls {
        if (slotCtrl.Value = 1)
            slots.Push(slot)
    }
    return slots
}

NormalizeAbstractTowerSlot(value) {
    try {
        slot := Integer(value)
    } catch Error {
        return 0
    }
    return (slot >= 1 && slot <= 5) ? slot : 0
}

NormalizeAbstractTowerSlots(value) {
    selected := Map()
    values := IsObject(value) ? value : StrSplit(String(value), ",")
    for rawValue in values {
        slot := NormalizeAbstractTowerSlot(Trim(String(rawValue)))
        if (slot > 0)
            selected[slot] := true
    }

    slots := []
    Loop 5 {
        if (selected.Has(A_Index))
            slots.Push(A_Index)
    }
    return slots
}

AbstractTowerSlotsToText(slots) {
    normalizedSlots := NormalizeAbstractTowerSlots(slots)
    text := ""
    for index, slot in normalizedSlots
        text .= (index > 1 ? ", " : "") slot
    return text
}

SetAbstractTowerSlots(value) {
    global AbstractTowerSlots, AbstractTowerSlot
    AbstractTowerSlots := NormalizeAbstractTowerSlots(value)
    AbstractTowerSlot := AbstractTowerSlots.Length > 0 ? AbstractTowerSlots[1] : 0
    return AbstractTowerSlots
}

IsAbstractTowerSlot(slot) {
    global AbstractTowerSlots
    normalizedSlot := NormalizeAbstractTowerSlot(slot)
    for abstractSlot in AbstractTowerSlots {
        if (abstractSlot = normalizedSlot)
            return true
    }
    return false
}

ActiveAbstractTowerSlots() {
    global AbstractTowerSlots, AbstractPlacementLimit, AbstractPlacementMax
    activeSlots := []
    availableCount := AbstractTowerSlots.Length
    if (AbstractPlacementMax > 0)
        availableCount := Min(availableCount, AbstractPlacementMax)
    activeCount := Min(availableCount, Max(0, AbstractPlacementLimit))
    Loop activeCount
        activeSlots.Push(AbstractTowerSlots[A_Index])
    return activeSlots
}

IsActiveAbstractTowerSlot(slot) {
    normalizedSlot := NormalizeAbstractTowerSlot(slot)
    for activeSlot in ActiveAbstractTowerSlots() {
        if (activeSlot = normalizedSlot)
            return true
    }
    return false
}

UpdateAbstractPlacementControls() {
    global AbstractTowerSlots, AbstractPlacementLimit, AbstractPlacementMax
    global AbstractCountLabel, AbstractCountCtrl, CurrentTab

    if (!IsSet(AbstractCountLabel) || !IsSet(AbstractCountCtrl))
        return

    availableCount := Min(4, AbstractTowerSlots.Length)
    if (AbstractPlacementMax > 0)
        availableCount := Min(availableCount, AbstractPlacementMax)
    if (availableCount <= 0) {
        AbstractCountLabel.Visible := false
        AbstractCountCtrl.Visible := false
        return
    }

    AbstractPlacementLimit := Max(1, Min(AbstractPlacementLimit, availableCount))
    AbstractCountCtrl.Delete()
    choices := []
    Loop availableCount
        choices.Push(String(A_Index))
    AbstractCountCtrl.Add(choices)
    AbstractCountCtrl.Choose(AbstractPlacementLimit)

    shouldShow := availableCount > 1 && IsSet(CurrentTab) && CurrentTab = "Tab1"
    AbstractCountLabel.Visible := shouldShow
    AbstractCountCtrl.Visible := shouldShow
}

AbstractPlacementLimitChanged(ctrl, *) {
    global AbstractPlacementLimit, SettingsFile
    selectedCount := IsNumber(ctrl.Text) ? Integer(ctrl.Text) : ctrl.Value
    AbstractPlacementLimit := Max(1, Min(4, selectedCount))
    IniWrite(AbstractPlacementLimit, SettingsFile, "Options", "AbstractPlacementLimit")
    UpdateAbstractPlacementControls()
}

ReadStrategyAbstractTowerSlots(path, towerText := "") {
    configuredSlots := IniRead(path, "Settings", "abstractSlots", "")
    if (Trim(configuredSlots) = "")
        configuredSlots := IniRead(path, "Settings", "abstractSlot", "")
    slots := NormalizeAbstractTowerSlots(configuredSlots)
    if (slots.Length > 0)
        return slots

    for index, towerName in SplitTowerNames(towerText) {
        if (index <= 5 && NormalizeTowerIdentity(towerName) = "abstract")
            slots.Push(index)
    }
    return NormalizeAbstractTowerSlots(slots)
}

LoadAbstractPlacementProfile(path) {
    global AbstractTowerSlots, AbstractPlacementMax

    if (path = "" || !FileExist(path)) {
        SetAbstractTowerSlots([])
        AbstractPlacementMax := 0
        UpdateAbstractPlacementControls()
        return
    }

    towerText := IniRead(path, "Settings", "requiredTowers", "")
    SetAbstractTowerSlots(ReadStrategyAbstractTowerSlots(path, towerText))
    placementMaxSetting := IniRead(path, "Settings", "abstractPlacementMax", AbstractTowerSlots.Length)
    AbstractPlacementMax := IsNumber(placementMaxSetting)
        ? Max(0, Min(4, Integer(placementMaxSetting)))
        : Min(4, AbstractTowerSlots.Length)
    UpdateAbstractPlacementControls()
}

SplitTowerNames(towerText) {
    towerList := []
    for rawTower in StrSplit(towerText, ",") {
        towerName := Trim(rawTower)
        if (towerName != "")
            towerList.Push(towerName)
    }
    return towerList
}

TowerListToText(towerList) {
    towerText := ""
    for index, towerName in towerList
        towerText .= (index = 1 ? "" : ", ") Trim(towerName)
    return towerText
}

NormalizeTowerIdentity(towerName) {
    normalized := StrLower(RegExReplace(Trim(towerName), "\s+", " "))
    if RegExMatch(normalized, "^golden\s+(.+)$", &goldenMatch)
        return "g " goldenMatch[1]
    return normalized
}

BuildTowerHotbarRemap(recordedTowerText, equippedTowerText) {
    recordedTowers := SplitTowerNames(recordedTowerText)
    equippedTowers := SplitTowerNames(equippedTowerText)
    emptyMap := Map()

    if (recordedTowers.Length = 0 || equippedTowers.Length = 0)
        return {valid: false, changed: false, moveCount: 0, slots: emptyMap, summary: "", message: "Original and equipped hotbars cannot be empty."}
    if (recordedTowers.Length != equippedTowers.Length)
        return {valid: false, changed: false, moveCount: 0, slots: emptyMap, summary: "", message: "Hotbar swapping requires the exact same number of towers."}

    usedEquippedSlots := Map()
    slotMap := Map()
    changed := false
    summaryParts := []
    for recordedSlot, recordedTower in recordedTowers {
        identity := NormalizeTowerIdentity(recordedTower)
        matchedSlot := 0
        for equippedSlot, equippedTower in equippedTowers {
            if (!usedEquippedSlots.Has(equippedSlot) && NormalizeTowerIdentity(equippedTower) = identity) {
                matchedSlot := equippedSlot
                break
            }
        }
        if (matchedSlot = 0) {
            return {
                valid: false,
                changed: false,
                moveCount: 0,
                slots: emptyMap,
                summary: "",
                message: "Hotbar swapping requires exactly the same towers. '" recordedTower "' is missing from Equipped."
            }
        }

        usedEquippedSlots[matchedSlot] := true
        slotMap[recordedSlot] := matchedSlot
        if (matchedSlot != recordedSlot) {
            changed := true
            summaryParts.Push("S" recordedSlot ">S" matchedSlot " " recordedTower)
        }
    }

    summary := ""
    for index, part in summaryParts
        summary .= (index = 1 ? "" : "  |  ") part
    return {valid: true, changed: changed, moveCount: summaryParts.Length, slots: slotMap, summary: summary, message: ""}
}

ResolveStrategyHotbarSlot(recordedSlot) {
    global StrategyHotbarSlotMap
    slot := NormalizeAbstractTowerSlot(recordedSlot)
    return (slot > 0 && StrategyHotbarSlotMap.Has(slot)) ? StrategyHotbarSlotMap[slot] : slot
}

CollectTowerSlotValues(towerControls) {
    towerList := []
    foundBlank := false
    for index, towerCtrl in towerControls {
        towerName := Trim(towerCtrl.Text)
        if (towerName = "") {
            foundBlank := true
            continue
        }
        if (foundBlank) {
            return {
                ok: false,
                value: "",
                message: "Tower slots must be consecutive. Fill the earlier blank slot or clear the later slot."
            }
        }
        towerList.Push(towerName)
    }

    if (towerList.Length = 0)
        return {ok: false, value: "", message: "Choose or type at least one tower."}

    towerText := ""
    for index, towerName in towerList
        towerText .= (index = 1 ? "" : ", ") towerName
    return {ok: true, value: towerText, message: ""}
}

ParseAdvancedWaveSelection(waveText) {
    waveText := Trim(waveText)
    if (waveText = "")
        return {ok: false, canonical: "", waves: Map(), message: "Enter at least one wave for Advanced Wave Skip."}

    waveSet := Map()
    canonicalParts := []
    for rawPart in StrSplit(waveText, ",") {
        part := Trim(rawPart)
        if RegExMatch(part, "^(\d{1,3})$", &singleMatch) {
            wave := Integer(singleMatch[1])
            if (wave < 1)
                return {ok: false, canonical: "", waves: Map(), message: "Wave numbers must be 1 or higher."}
            waveSet[wave] := true
            canonicalParts.Push(String(wave))
        } else if RegExMatch(part, "^(\d{1,3})\s*-\s*(\d{1,3})$", &rangeMatch) {
            firstWave := Integer(rangeMatch[1])
            lastWave := Integer(rangeMatch[2])
            if (firstWave < 1 || lastWave < firstWave)
                return {ok: false, canonical: "", waves: Map(), message: "Invalid wave range '" part "'. Use a range such as 10-15."}
            if (lastWave - firstWave > 200)
                return {ok: false, canonical: "", waves: Map(), message: "Wave range '" part "' is too large."}
            Loop lastWave - firstWave + 1
                waveSet[firstWave + A_Index - 1] := true
            canonicalParts.Push(firstWave "-" lastWave)
        } else {
            return {ok: false, canonical: "", waves: Map(), message: "Invalid wave entry '" part "'. Use commas and ranges, for example: 1, 3, 10-15."}
        }
    }

    canonical := ""
    for index, part in canonicalParts
        canonical .= (index = 1 ? "" : ", ") part
    return {ok: true, canonical: canonical, waves: waveSet, message: ""}
}

BuildAbstractRequiredTowers(towers, abstractSlots) {
    abstractSlots := NormalizeAbstractTowerSlots(abstractSlots)
    if (abstractSlots.Length = 0)
        return {ok: true, value: Trim(towers, " `t,")}

    towerList := []
    for rawTower in StrSplit(towers, ",") {
        towerName := Trim(rawTower)
        if (towerName != "")
            towerList.Push(towerName)
    }

    highestSlot := abstractSlots[abstractSlots.Length]
    if (highestSlot > towerList.Length) {
        return {
            ok: false,
            value: "",
            message: "Abstract hotbar slot " highestSlot " has no matching entry in the Towers list. Add a placeholder tower name for every slot through slot " highestSlot "."
        }
    }

    for abstractSlot in abstractSlots
        towerList[abstractSlot] := "Abstract"
    result := ""
    for index, towerName in towerList
        result .= (index = 1 ? "" : ", ") towerName

    return {ok: true, value: result}
}

EditorBrowseStrategy(ctrl, *) {
    global EditorStrategyPath, StratsDir, Strategy1Ctrl

    targetDir := StratsDir
    if (EditorStrategyPath != "" && FileExist(EditorStrategyPath)) {
        SplitPath(EditorStrategyPath, , &targetDir)
    } else if (Trim(Strategy1Ctrl.Text) != "" && FileExist(Strategy1Ctrl.Text)) {
        SplitPath(Strategy1Ctrl.Text, , &targetDir)
    }

    selectedFile := FileSelect("3", targetDir, "Open strategy in the safe editor", "Strategy (*.strat)")
    if (selectedFile != "")
        EditorLoadStrategy(selectedFile)
}

EditorReloadStrategy(ctrl := 0, *) {
    global EditorStrategyPath
    if (EditorStrategyPath = "" || !FileExist(EditorStrategyPath)) {
        EditorSetStatus("Nothing to reload. Browse to a strategy first.", true)
        return
    }
    EditorLoadStrategy(EditorStrategyPath)
}

EditorLoadStrategy(path) {
    global EditorStrategyPath, Editor_PathCtrl, Editor_Status, Editor_MapCtrl, Editor_ModeCtrl
    global Editor_AbstractCtrls, EditorTowerCtrls, EditorOriginalTowerCtrls, EditorModifierCtrls, EditorModifierNames
    global EditorRecordedTowerText
    global Editor_AutoSkipCtrl, Editor_AdvancedSkipCtrl, Editor_AdvancedWavesCtrl
    global Editor_AbilitySpamCtrl, Editor_AutoChainCtrl, Editor_AutoCaravanCtrl, Editor_AutoDropCtrl

    if (path = "" || !FileExist(path)) {
        EditorSetStatus("Strategy file not found.", true)
        return false
    }

    try {
        mapName := IniRead(path, "Settings", "map", "")
        modeName := IniRead(path, "Settings", "difficulty", "")
        towerText := IniRead(path, "Settings", "requiredTowers", "")
        recordedTowerText := IniRead(path, "Settings", "recordedTowers", towerText)
        if (Trim(recordedTowerText) = "")
            recordedTowerText := towerText
        hotbarRemapEnabled := EditorSettingIsOn(IniRead(path, "Settings", "hotbarRemap", "OFF"))
        arrangedTowerText := IniRead(path, "Settings", "arrangedTowers", "")
        if (Trim(arrangedTowerText) = "") {
            legacyRemap := BuildTowerHotbarRemap(recordedTowerText, towerText)
            arrangedTowerText := (hotbarRemapEnabled && legacyRemap.valid) ? towerText : recordedTowerText
        }
        arrangedRemap := BuildTowerHotbarRemap(recordedTowerText, arrangedTowerText)
        if (!arrangedRemap.valid)
            arrangedTowerText := recordedTowerText
        modifierText := IniRead(path, "Settings", "modifiers", "")
        abstractSlots := ReadStrategyAbstractTowerSlots(path, towerText)

        towerList := []
        for rawTower in StrSplit(towerText, ",") {
            towerName := Trim(rawTower)
            if (towerName != "")
                towerList.Push(towerName)
        }
        recordedTowerList := SplitTowerNames(recordedTowerText)
        arrangedTowerList := SplitTowerNames(arrangedTowerText)

        Editor_MapCtrl.Text := mapName
        Editor_ModeCtrl.Text := modeName
        EditorRecordedTowerText := TowerListToText(recordedTowerList)
        for index, originalCtrl in EditorOriginalTowerCtrls
            originalCtrl.Value := index <= arrangedTowerList.Length ? arrangedTowerList[index] : "—"
        EditorRefreshOriginalTowerStyles()
        for index, towerCtrl in EditorTowerCtrls
            towerCtrl.Text := index <= towerList.Length ? towerList[index] : ""
        for slot, abstractCtrl in Editor_AbstractCtrls
            abstractCtrl.Value := 0
        for abstractSlot in abstractSlots {
            if (abstractSlot <= EditorTowerCtrls.Length) {
                Editor_AbstractCtrls[abstractSlot].Value := 1
                EditorTowerCtrls[abstractSlot].Text := "Abstract"
            }
        }
        EditorHotbarChanged()

        selectedModifiers := Map()
        for rawModifier in StrSplit(modifierText, ",") {
            modifierName := Trim(rawModifier)
            if (modifierName != "")
                selectedModifiers[StrLower(modifierName)] := true
        }
        for modifierName, modifierCtrl in EditorModifierCtrls
            modifierCtrl.Value := selectedModifiers.Has(StrLower(modifierName)) ? 1 : 0

        advancedSkipOn := EditorSettingIsOn(IniRead(path, "Settings", "advancedAutoSkip", "OFF"))
        Editor_AutoSkipCtrl.Value := advancedSkipOn ? 0 : EditorSettingIsOn(IniRead(path, "Settings", "autoSkip", "OFF"))
        Editor_AdvancedSkipCtrl.Value := advancedSkipOn ? 1 : 0
        Editor_AdvancedWavesCtrl.Value := IniRead(path, "Settings", "advancedSkipWaves", "")
        EditorAutoSkipModeChanged(advancedSkipOn ? Editor_AdvancedSkipCtrl : Editor_AutoSkipCtrl)
        Editor_AbilitySpamCtrl.Value := EditorSettingIsOn(IniRead(path, "Settings", "abilitySpam", "OFF"))
        Editor_AutoChainCtrl.Value := EditorSettingIsOn(IniRead(path, "Settings", "autoChain", "OFF"))
        Editor_AutoCaravanCtrl.Value := EditorSettingIsOn(IniRead(path, "Settings", "autoCaravan", "OFF"))
        Editor_AutoDropCtrl.Value := EditorSettingIsOn(IniRead(path, "Settings", "autoDropTheBeat", "OFF"))

        EditorStrategyPath := path
        Editor_PathCtrl.Value := path
        stepCount := EditorCountSteps(path)
        EditorSetStatus("Loaded " EditorFileName(path) "  |  " stepCount " recorded steps locked and preserved")
        return true
    } catch Error as err {
        EditorSetStatus("Could not load strategy: " err.Message, true)
        return false
    }
}

EditorHotbarTryBeginDrag(hwnd) {
    global EditorOriginalTowerCtrls, EditorHotbarDragSource, EditorHotbarDragTarget
    global EditorHotbarDragStartX, EditorHotbarDragStartY, EditorHotbarDragMoved
    global Editor_HotbarMode, Editor_HotbarHint

    sourceSlot := 0
    for slot, originalCtrl in EditorOriginalTowerCtrls {
        if (originalCtrl.Hwnd = hwnd && originalCtrl.Visible) {
            sourceSlot := slot
            break
        }
    }
    if (sourceSlot = 0)
        return false

    oldMouseMode := A_CoordModeMouse
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    CoordMode("Mouse", oldMouseMode)

    EditorHotbarDragSource := sourceSlot
    EditorHotbarDragTarget := sourceSlot
    EditorHotbarDragStartX := mouseX
    EditorHotbarDragStartY := mouseY
    EditorHotbarDragMoved := false
    DllCall("SetCapture", "Ptr", hwnd)
    EditorRefreshOriginalTowerStyles(sourceSlot, sourceSlot)
    Editor_HotbarMode.Value := "DRAG SLOT " sourceSlot "  /  CHOOSE A DESTINATION"
    Editor_HotbarMode.SetFont("c" ThemeColor("Accent") " w700")
    Editor_HotbarHint.Value := "Hold the mouse button and release over another Original slot to swap the two Equipped positions."
    return true
}

EditorHotbarDragMouseMove(wParam, lParam, msg, hwnd) {
    global EditorHotbarDragSource, EditorHotbarDragTarget, EditorHotbarDragStartX, EditorHotbarDragStartY
    global EditorHotbarDragMoved, Editor_HotbarMode
    if (EditorHotbarDragSource = 0)
        return

    oldMouseMode := A_CoordModeMouse
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    CoordMode("Mouse", oldMouseMode)

    if (Abs(mouseX - EditorHotbarDragStartX) >= 4 || Abs(mouseY - EditorHotbarDragStartY) >= 4)
        EditorHotbarDragMoved := true
    if (!EditorHotbarDragMoved)
        return 0

    targetSlot := EditorHotbarSlotAtScreenPoint(mouseX, mouseY)
    if (targetSlot != EditorHotbarDragTarget) {
        EditorHotbarDragTarget := targetSlot
        EditorRefreshOriginalTowerStyles(EditorHotbarDragSource, targetSlot)
        Editor_HotbarMode.Value := targetSlot > 0
            ? "RELEASE TO SWAP SLOT " EditorHotbarDragSource " WITH SLOT " targetSlot
            : "DRAG BACK OVER AN ORIGINAL SLOT"
    }
    return 0
}

EditorHotbarDragMouseUp(wParam, lParam, msg, hwnd) {
    global EditorHotbarDragSource, EditorHotbarDragTarget, EditorHotbarDragMoved
    global EditorTowerCtrls, EditorOriginalTowerCtrls
    if (EditorHotbarDragSource = 0)
        return

    oldMouseMode := A_CoordModeMouse
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    CoordMode("Mouse", oldMouseMode)
    releaseSlot := EditorHotbarSlotAtScreenPoint(mouseX, mouseY)
    if (releaseSlot > 0)
        EditorHotbarDragTarget := releaseSlot

    DllCall("ReleaseCapture")
    sourceSlot := EditorHotbarDragSource
    targetSlot := EditorHotbarDragTarget
    didSwap := EditorHotbarDragMoved && targetSlot > 0 && targetSlot != sourceSlot

    EditorHotbarDragSource := 0
    EditorHotbarDragTarget := 0
    EditorHotbarDragMoved := false
    EditorRefreshOriginalTowerStyles()

    if (didSwap) {
        sourceOriginal := EditorOriginalTowerCtrls[sourceSlot].Text
        targetOriginal := EditorOriginalTowerCtrls[targetSlot].Text
        sourceTower := EditorTowerCtrls[sourceSlot].Text
        targetTower := EditorTowerCtrls[targetSlot].Text
        EditorOriginalTowerCtrls[sourceSlot].Text := targetOriginal
        EditorOriginalTowerCtrls[targetSlot].Text := sourceOriginal
        EditorTowerCtrls[sourceSlot].Text := targetTower
        EditorTowerCtrls[targetSlot].Text := sourceTower
        EditorHotbarChanged()
        EditorSetStatus("Slot arrangement changed: slot " sourceSlot " and slot " targetSlot ". Original and Equipped moved together; save to keep it.")
    } else {
        EditorHotbarChanged()
    }
    return 0
}

EditorHotbarSlotAtScreenPoint(screenX, screenY) {
    global MainGui, EditorOriginalTowerCtrls
    try WinGetClientPos(&clientX, &clientY,,, "ahk_id " MainGui.Hwnd)
    catch
        return 0

    localX := screenX - clientX
    localY := screenY - clientY
    for slot, originalCtrl in EditorOriginalTowerCtrls {
        originalCtrl.GetPos(&ctrlX, &ctrlY, &ctrlW, &ctrlH)
        if (localX >= ctrlX && localX <= ctrlX + ctrlW && localY >= ctrlY && localY <= ctrlY + ctrlH)
            return slot
    }
    return 0
}

EditorRefreshOriginalTowerStyles(sourceSlot := 0, targetSlot := 0) {
    global EditorOriginalTowerCtrls, EditorTowerCtrls
    for slot, originalCtrl in EditorOriginalTowerCtrls {
        background := "170E10"
        textColor := ThemeColor("TextSecondary")
        if (slot <= EditorTowerCtrls.Length
            && NormalizeTowerIdentity(originalCtrl.Text) != NormalizeTowerIdentity(EditorTowerCtrls[slot].Text)) {
            background := "241217"
            textColor := ThemeColor("AccentHover")
        }
        if (slot = targetSlot && targetSlot != sourceSlot) {
            background := ThemeColor("AccentDark")
            textColor := ThemeColor("TextPrimary")
        } else if (slot = sourceSlot) {
            background := ThemeColor("AccentSubtle")
            textColor := ThemeColor("AccentHover")
        }
        originalCtrl.Opt("Background" background)
        originalCtrl.SetFont("c" textColor " w600")
        originalCtrl.Redraw()
    }
}

EditorOriginalTowerList() {
    global EditorOriginalTowerCtrls
    towers := []
    for originalCtrl in EditorOriginalTowerCtrls {
        towerName := Trim(originalCtrl.Text)
        if (towerName != "" && towerName != "—")
            towers.Push(towerName)
    }
    return towers
}

EditorOriginalTowerForSlot(slot) {
    global EditorOriginalTowerCtrls
    if (slot < 1 || slot > EditorOriginalTowerCtrls.Length)
        return ""
    towerName := Trim(EditorOriginalTowerCtrls[slot].Text)
    return towerName = "—" ? "" : towerName
}

EditorAbstractSlotChanged(ctrl, *) {
    global EditorSyncingAbstract, Editor_AbstractCtrls, EditorTowerCtrls
    if (EditorSyncingAbstract)
        return

    EditorSyncingAbstract := true
    for slot, towerCtrl in EditorTowerCtrls {
        if (Editor_AbstractCtrls[slot].Value = 1)
            towerCtrl.Text := "Abstract"
        else if (NormalizeTowerIdentity(towerCtrl.Text) = "abstract")
            towerCtrl.Text := EditorOriginalTowerForSlot(slot)
    }
    EditorSyncingAbstract := false
    EditorHotbarChanged()
}

EditorSyncAbstractSelection(changedCtrl := 0) {
    global EditorSyncingAbstract, Editor_AbstractCtrls, EditorTowerCtrls
    if (EditorSyncingAbstract)
        return

    EditorSyncingAbstract := true
    changedSlot := 0
    if (changedCtrl) {
        for slot, towerCtrl in EditorTowerCtrls {
            if (towerCtrl.Hwnd = changedCtrl.Hwnd) {
                changedSlot := slot
                break
            }
        }
    }

    if (changedSlot > 0)
        Editor_AbstractCtrls[changedSlot].Value := NormalizeTowerIdentity(EditorTowerCtrls[changedSlot].Text) = "abstract" ? 1 : 0
    else {
        for slot, towerCtrl in EditorTowerCtrls
            Editor_AbstractCtrls[slot].Value := NormalizeTowerIdentity(towerCtrl.Text) = "abstract" ? 1 : 0
    }
    EditorSyncingAbstract := false
}

EditorSelectedAbstractSlots() {
    global Editor_AbstractCtrls
    slots := []
    for slot, abstractCtrl in Editor_AbstractCtrls {
        if (abstractCtrl.Value = 1)
            slots.Push(slot)
    }
    return slots
}

EditorHotbarChanged(changedCtrl := 0, *) {
    global EditorRecordedTowerText, EditorTowerCtrls, Editor_HotbarMode, Editor_HotbarHint

    EditorSyncAbstractSelection(changedCtrl)

    equippedTowers := []
    for towerCtrl in EditorTowerCtrls {
        towerName := Trim(towerCtrl.Text)
        if (towerName != "")
            equippedTowers.Push(towerName)
    }
    arrangedTowers := EditorOriginalTowerList()
    remap := BuildTowerHotbarRemap(EditorRecordedTowerText, TowerListToText(arrangedTowers))

    replacementSlots := []
    Loop Max(arrangedTowers.Length, equippedTowers.Length) {
        arrangedTower := A_Index <= arrangedTowers.Length ? arrangedTowers[A_Index] : ""
        equippedTower := A_Index <= equippedTowers.Length ? equippedTowers[A_Index] : ""
        if (NormalizeTowerIdentity(arrangedTower) != NormalizeTowerIdentity(equippedTower))
            replacementSlots.Push("S" A_Index)
    }
    replacementCount := replacementSlots.Length
    replacementSummary := ""
    for index, slotName in replacementSlots
        replacementSummary .= (index = 1 ? "" : ", ") slotName

    if (!remap.valid) {
        Editor_HotbarMode.Value := "ARRANGEMENT INVALID"
        Editor_HotbarMode.SetFont("c" ThemeColor("Warning") " w700")
        Editor_HotbarHint.Value := remap.message
    } else if (remap.changed && replacementCount > 0) {
        Editor_HotbarMode.Value := "ARRANGED + CUSTOM  /  " remap.moveCount " MOVES + " replacementCount " CHANGES"
        Editor_HotbarMode.SetFont("c" ThemeColor("Accent") " w700")
        Editor_HotbarHint.Value := "Original positions control recorded-step remapping; Equipped-only changes are replacements (" replacementSummary ")."
    } else if (remap.changed) {
        Editor_HotbarMode.Value := "ARRANGEMENT READY  /  " remap.moveCount " SLOT MOVES"
        Editor_HotbarMode.SetFont("c" ThemeColor("Accent") " w700")
        Editor_HotbarHint.Value := "Arrangement only: Original and Equipped moved together; recorded steps will follow the new slots."
    } else if (replacementCount > 0) {
        Editor_HotbarMode.Value := "TOWER CHANGES  /  " replacementCount " REPLACEMENTS"
        Editor_HotbarMode.SetFont("c" ThemeColor("Warning") " w700")
        Editor_HotbarHint.Value := "Equipped differs from Original in " replacementSummary ". Recorded slot positions are unchanged."
    } else {
        Editor_HotbarMode.Value := "RECORDED ORDER  /  NO REMAP"
        Editor_HotbarMode.SetFont("c" ThemeColor("TextMuted") " w600")
        Editor_HotbarHint.Value := "Drag Original cards to rearrange both rows; edit an Equipped dropdown to replace only that tower."
    }
    EditorRefreshOriginalTowerStyles()
}

EditorAutoSkipModeChanged(changedCtrl, *) {
    global Editor_AutoSkipCtrl, Editor_AdvancedSkipCtrl, Editor_AdvancedWavesCtrl

    if (changedCtrl = Editor_AutoSkipCtrl && Editor_AutoSkipCtrl.Value)
        Editor_AdvancedSkipCtrl.Value := 0
    else if (changedCtrl = Editor_AdvancedSkipCtrl && Editor_AdvancedSkipCtrl.Value)
        Editor_AutoSkipCtrl.Value := 0

    Editor_AdvancedWavesCtrl.Enabled := Editor_AdvancedSkipCtrl.Value = 1
}

EditorSettingIsOn(value) {
    normalized := StrLower(Trim(String(value)))
    return normalized = "on" || normalized = "1" || normalized = "true" || normalized = "yes"
}

EditorFileName(path) {
    SplitPath(path, &fileName)
    return fileName
}

EditorReadStepsSection(path) {
    text := FileRead(path)
    markerPos := RegExMatch(text, "im)^\[Steps\]\s*$")
    return markerPos ? SubStr(text, markerPos) : ""
}

EditorCountSteps(path) {
    stepsText := EditorReadStepsSection(path)
    if (stepsText = "")
        return 0

    count := 0
    for line in StrSplit(stepsText, "`n", "`r") {
        line := Trim(line)
        if (line != "" && SubStr(line, 1, 1) != "[" && SubStr(line, 1, 1) != ";")
            count++
    }
    return count
}

EditorSetStatus(message, isError := false) {
    global Editor_Status
    Editor_Status.Value := message
    Editor_Status.SetFont("c" (isError ? ThemeColor("AccentHover") : ThemeColor("TextMuted")))
}

EditorCollectSettings() {
    global EditorStrategyPath, Editor_MapCtrl, Editor_ModeCtrl, Editor_AbstractCtrls
    global EditorTowerCtrls, EditorModifierCtrls, EditorModifierNames
    global EditorRecordedTowerText
    global Editor_AutoSkipCtrl, Editor_AdvancedSkipCtrl, Editor_AdvancedWavesCtrl
    global Editor_AbilitySpamCtrl, Editor_AutoChainCtrl, Editor_AutoCaravanCtrl, Editor_AutoDropCtrl

    if (EditorStrategyPath = "" || !FileExist(EditorStrategyPath))
        return {ok: false, message: "Browse to a valid strategy before saving."}

    mapName := Trim(Editor_MapCtrl.Text)
    modeName := Trim(Editor_ModeCtrl.Text)
    if (mapName = "" || modeName = "")
        return {ok: false, message: "Map and mode cannot be blank."}

    towers := []
    foundBlank := false
    for index, towerCtrl in EditorTowerCtrls {
        towerName := Trim(towerCtrl.Text)
        if (towerName = "") {
            foundBlank := true
            continue
        }
        if (foundBlank)
            return {ok: false, message: "Hotbar slots must be consecutive. Fill the earlier blank slot or clear later slots."}
        towers.Push(towerName)
    }
    if (towers.Length = 0)
        return {ok: false, message: "Add at least one tower to the hotbar."}

    arrangedTowers := EditorOriginalTowerList()
    if (arrangedTowers.Length != towers.Length)
        return {ok: false, message: "Original and Equipped must contain the same number of occupied slots."}

    abstractSlots := EditorSelectedAbstractSlots()
    if (abstractSlots.Length > 4)
        return {ok: false, message: "A strategy can use at most four abstract XP tower slots."}
    abstractSlotMap := Map()
    for abstractSlot in abstractSlots
        abstractSlotMap[abstractSlot] := true
    for index, towerName in towers {
        if (StrLower(towerName) = "abstract" && !abstractSlotMap.Has(index)) {
            return {ok: false, message: "Slot " index " still contains Abstract. Replace it with its real tower or enable slot " index " in the Abstract selector."}
        }
    }
    for abstractSlot in abstractSlots {
        if (abstractSlot > towers.Length)
            return {ok: false, message: "Abstract slot " abstractSlot " is blank. Add a tower entry through that slot."}
        towers[abstractSlot] := "Abstract"
    }

    towerText := TowerListToText(towers)
    arrangedTowerText := TowerListToText(arrangedTowers)
    recordedTowerText := Trim(EditorRecordedTowerText)
    if (recordedTowerText = "")
        recordedTowerText := arrangedTowerText
    hotbarRemap := BuildTowerHotbarRemap(recordedTowerText, arrangedTowerText)
    if (!hotbarRemap.valid)
        return {ok: false, message: "The Original arrangement is invalid: " hotbarRemap.message}
    hotbarRemapEnabled := hotbarRemap.valid && hotbarRemap.changed

    modifierText := ""
    for modifierName in EditorModifierNames {
        if (EditorModifierCtrls[modifierName].Value)
            modifierText .= (modifierText = "" ? "" : ", ") modifierName
    }

    if (Editor_AutoSkipCtrl.Value && Editor_AdvancedSkipCtrl.Value)
        return {ok: false, message: "Auto Skip and Advanced Wave Skip are mutually exclusive. Choose only one."}

    advancedWaveText := ""
    if (Editor_AdvancedSkipCtrl.Value) {
        parsedWaves := ParseAdvancedWaveSelection(Editor_AdvancedWavesCtrl.Text)
        if (!parsedWaves.ok)
            return {ok: false, message: parsedWaves.message}
        advancedWaveText := parsedWaves.canonical
    }

    return {
        ok: true,
        data: {
            mapName: mapName,
            modeName: modeName,
            towers: towerText,
            recordedTowers: recordedTowerText,
            arrangedTowers: arrangedTowerText,
            hotbarRemap: hotbarRemapEnabled ? "ON" : "OFF",
            hotbarRemapSummary: hotbarRemapEnabled ? hotbarRemap.summary : "",
            abstractSlot: abstractSlots.Length > 0 ? abstractSlots[1] : 0,
            abstractSlots: AbstractTowerSlotsToText(abstractSlots),
            modifiers: modifierText,
            autoSkip: Editor_AutoSkipCtrl.Value ? "ON" : "OFF",
            advancedAutoSkip: Editor_AdvancedSkipCtrl.Value ? "ON" : "OFF",
            advancedSkipWaves: advancedWaveText,
            abilitySpam: Editor_AbilitySpamCtrl.Value ? "ON" : "OFF",
            autoChain: Editor_AutoChainCtrl.Value ? "ON" : "OFF",
            autoCaravan: Editor_AutoCaravanCtrl.Value ? "ON" : "OFF",
            autoDropTheBeat: Editor_AutoDropCtrl.Value ? "ON" : "OFF"
        }
    }
}

EditorWriteSettings(path, data) {
    IniWrite(data.mapName, path, "Settings", "map")
    IniWrite(data.modeName, path, "Settings", "difficulty")
    IniWrite(data.towers, path, "Settings", "requiredTowers")
    IniWrite(data.recordedTowers, path, "Settings", "recordedTowers")
    IniWrite(data.arrangedTowers, path, "Settings", "arrangedTowers")
    IniWrite(data.hotbarRemap, path, "Settings", "hotbarRemap")
    IniWrite(data.abstractSlot, path, "Settings", "abstractSlot")
    IniWrite(data.abstractSlots, path, "Settings", "abstractSlots")
    IniWrite(data.modifiers, path, "Settings", "modifiers")
    IniWrite(data.autoChain, path, "Settings", "autoChain")
    IniWrite(data.autoCaravan, path, "Settings", "autoCaravan")
    IniWrite(data.autoDropTheBeat, path, "Settings", "autoDropTheBeat")
    IniWrite(data.autoSkip, path, "Settings", "autoSkip")
    IniWrite(data.advancedAutoSkip, path, "Settings", "advancedAutoSkip")
    IniWrite(data.advancedSkipWaves, path, "Settings", "advancedSkipWaves")
    IniWrite(data.abilitySpam, path, "Settings", "abilitySpam")
}

EditorSaveCopy(ctrl, *) {
    global EditorStrategyPath
    collected := EditorCollectSettings()
    if (!collected.ok) {
        EditorSetStatus(collected.message, true)
        return
    }

    SplitPath(EditorStrategyPath, , &sourceDir, , &sourceName)
    suggestedPath := sourceDir "\" sourceName " - Edited.strat"
    destination := FileSelect("S", suggestedPath, "Save edited strategy as a new file", "Strategy (*.strat)")
    if (destination = "")
        return
    if !RegExMatch(destination, "i)\.strat$")
        destination .= ".strat"
    if FileExist(destination) {
        EditorSetStatus("That file already exists. Choose another name or use Overwrite + Backup.", true)
        return
    }

    stepsBefore := EditorReadStepsSection(EditorStrategyPath)
    created := false
    try {
        FileCopy(EditorStrategyPath, destination, 0)
        created := true
        EditorWriteSettings(destination, collected.data)
        if (EditorReadStepsSection(destination) != stepsBefore)
            throw Error("Recorded Steps changed during save; the copy was rejected.")
        EditorLoadStrategy(destination)
        remapNote := collected.data.hotbarRemap = "ON" ? "  |  hotbar swap active" : ""
        EditorSetStatus("Saved new copy: " EditorFileName(destination) "  |  recorded Steps verified" remapNote)
    } catch Error as err {
        if (created && FileExist(destination))
            try FileDelete(destination)
        EditorSetStatus("Save Copy failed: " err.Message, true)
    }
}

EditorOverwrite(ctrl, *) {
    global EditorStrategyPath, RunningStrategy, Recording
    if (RunningStrategy || Recording) {
        EditorSetStatus("Overwrite is locked while the macro is running or recording. Use Save Copy instead.", true)
        return
    }

    collected := EditorCollectSettings()
    if (!collected.ok) {
        EditorSetStatus(collected.message, true)
        return
    }
    if (ModernMsgBox("Overwrite strategy?", "This will update only [Settings] in:`n" EditorFileName(EditorStrategyPath) "`n`nA timestamped backup will be created first. Recorded Steps remain locked.", "YES|NO", "WARNING") != "YES")
        return

    stepsBefore := EditorReadStepsSection(EditorStrategyPath)
    backupPath := EditorCreateBackupPath(EditorStrategyPath)
    backupCreated := false
    try {
        FileCopy(EditorStrategyPath, backupPath, 0)
        backupCreated := true
        EditorWriteSettings(EditorStrategyPath, collected.data)
        if (EditorReadStepsSection(EditorStrategyPath) != stepsBefore)
            throw Error("Recorded Steps changed during save.")
        EditorLoadStrategy(EditorStrategyPath)
        remapNote := collected.data.hotbarRemap = "ON" ? "  |  hotbar swap active" : ""
        EditorSetStatus("Overwritten safely  |  backup: " EditorFileName(backupPath) "  |  Steps verified" remapNote)
    } catch Error as err {
        if (backupCreated && FileExist(backupPath))
            try FileCopy(backupPath, EditorStrategyPath, 1)
        EditorSetStatus("Overwrite failed; original restored from backup: " err.Message, true)
    }
}

EditorCreateBackupPath(path) {
    SplitPath(path, , &parentDir, , &nameNoExt)
    timestamp := FormatTime(, "yyyyMMdd-HHmmss")
    ; Keep backups out of the community strategy list, which scans only *.strat.
    backupPath := parentDir "\" nameNoExt ".backup-" timestamp ".strat.bak"
    suffix := 2
    while FileExist(backupPath) {
        backupPath := parentDir "\" nameNoExt ".backup-" timestamp "-" suffix ".strat.bak"
        suffix++
    }
    return backupPath
}

EditorRename(ctrl, *) {
    global EditorStrategyPath, RunningStrategy, Recording
    if (EditorStrategyPath = "" || !FileExist(EditorStrategyPath)) {
        EditorSetStatus("Browse to a valid strategy before renaming.", true)
        return
    }
    if (RunningStrategy || Recording) {
        EditorSetStatus("Rename is locked while the macro is running or recording.", true)
        return
    }

    SplitPath(EditorStrategyPath, , &parentDir, , &nameNoExt)
    result := InputBox("New file name (the recorded strategy content will not change):", "Rename strategy", "w420 h140", nameNoExt)
    if (result.Result != "OK")
        return

    newName := Trim(result.Value)
    if (newName = "" || RegExMatch(newName, '[<>:"/\\|?*]')) {
        EditorSetStatus("The file name is empty or contains an invalid Windows character.", true)
        return
    }
    if !RegExMatch(newName, "i)\.strat$")
        newName .= ".strat"

    destination := parentDir "\" newName
    if (StrLower(destination) = StrLower(EditorStrategyPath)) {
        EditorSetStatus("The strategy already has that name.")
        return
    }
    if FileExist(destination) {
        EditorSetStatus("A strategy with that name already exists.", true)
        return
    }

    oldPath := EditorStrategyPath
    try {
        FileMove(oldPath, destination, 0)
        EditorUpdateStrategyReferences(oldPath, destination)
        EditorLoadStrategy(destination)
        EditorSetStatus("Renamed to " EditorFileName(destination) "  |  file content unchanged")
    } catch Error as err {
        EditorSetStatus("Rename failed: " err.Message, true)
    }
}

EditorUpdateStrategyReferences(oldPath, newPath) {
    global Strategy1Ctrl, Strategy2Ctrl, Strategy1Path, Strategy2Path, SettingsFile
    if (StrLower(Trim(Strategy1Ctrl.Text)) = StrLower(oldPath)) {
        Strategy1Ctrl.Value := newPath
        Strategy1Path := newPath
        IniWrite(newPath, SettingsFile, "Options", "Strategy1")
    }
    if (StrLower(Trim(Strategy2Ctrl.Text)) = StrLower(oldPath)) {
        Strategy2Ctrl.Value := newPath
        Strategy2Path := newPath
        IniWrite(newPath, SettingsFile, "Options", "Strategy2")
    }
}

SelectStrat1(ctrl, *) {
    global Strategy1Path
    targDir := RecordingsDir
    if (Strategy1Ctrl.Value) {
        SplitPath(Strategy1Ctrl.Value, , &parentDir) 
        targDir := parentDir
    }
    f := FileSelect("3", targDir, "Select strategy file 1", "Strategy (*.strat)")
    if (f != "") {
        Strategy1Ctrl.Value := f
        Strategy1Path := f
        IniWrite(f, SettingsFile, "Options", "Strategy1")
        LoadAbstractPlacementProfile(f)
    }
}
SelectStrat2(ctrl, *) {
    global Strategy2Path
    targDir := RecordingsDir
    if (Strategy2Ctrl.Value) {
        SplitPath(Strategy2Ctrl.Value, , &parentDir) 
        targDir := parentDir
    }
    f := FileSelect("3", targDir, "Select strategy file 2", "Strategy (*.strat)")
    if (f != "") {
        Strategy2Ctrl.Value := f
        Strategy2Path := f
        IniWrite(f, SettingsFile, "Options", "Strategy2")
    }
}
ClearStrat1(ctrl, *) {
    global Strategy1Path
    Strategy1Ctrl.Value := ""
    Strategy1Path := ""
    IniWrite(" ", SettingsFile, "Options", "Strategy1")
    LoadAbstractPlacementProfile("")
}
ClearStrat2(ctrl, *) {
    global Strategy2Path
    Strategy2Ctrl.Value := ""
    Strategy2Path := ""
    IniWrite(" ", SettingsFile, "Options", "Strategy2")
}
SaveStrat1(ctrl, *) {
    global Strategy1Path, Strategy1Ctrl
    Strategy1Path := Strategy1Ctrl.Text
    IniWrite(Strategy1Ctrl.Text, SettingsFile, "Options", "Strategy1")
    if (FileExist(Strategy1Path))
        LoadAbstractPlacementProfile(Strategy1Path)
}

SaveStrat2(ctrl, *) {
    global Strategy2Path, Strategy2Ctrl
    Strategy2Path := Strategy2Ctrl.Text
    IniWrite(Strategy2Ctrl.Text, SettingsFile, "Options", "Strategy2")
}


StartStrategy(ctrl, *) {
    if (RunningStrategy or Recording) {
        return
    }
    ResumeAutomationInput("strategy-start")
    g_IsFirstLaunch := Integer(IniRead(StateFile, "State", "IsFirstLaunch", 1))

    global RunningStrategy, CurrentRotationIndex, gamemap, difficulty, requiredTowers, modifiers
    global autoChain, autoCaravan, autoDropTheBeat, AutoSkip, AbilitySpam, MoveEnabled, MoveDirection, MoveDuration
    global AutorunStartTime, CurrentStratStartTime, AbstractTowerSlots, AbstractTowerSlot, AbstractPlacementLimit

    v := MainGui.Submit(false)
    IniWrite(v.Strategy1, SettingsFile, "Options", "Strategy1")
    IniWrite(v.Strategy2, SettingsFile, "Options", "Strategy2")

    if (v.RotateStrategies = 1) {
        s1 := Trim(v.Strategy1)
        s2 := Trim(v.Strategy2)

        for num, s in [s1, s2] {
            if (s == "" || !FileExist(s)) {
                ModernMsgBox("Warning", "Rotation mode is enabled but strategy " num " is empty or file doesn't exist!`nPlease select a valid file for Strategy " num "!", "OK", "WARNING")
                return
            }
        }
    }

    stratFile := ""
    s1 := v.Strategy1, s2 := v.Strategy2

    if (v.RotateStrategies = 1 && s2 != "") {
        if (s1 != "" && FileExist(s1)) {
            stratFile := s1
            CurrentRotationIndex := 1
        }
    } else {
        if (s1 != "" && FileExist(s1))
            stratFile := s1
        else if (s2 != "" && FileExist(s2))
            stratFile := s2
    }

    queuedRemoteStrategy := ""
    if ConsumeKronoxRemoteStrategySwitch(&queuedRemoteStrategy)
        stratFile := queuedRemoteStrategy

    if (stratFile = "") {
        ModernMsgBox("Warning", "No valid strategy file selected!", "OK", "WARNING")
        return
    }

    ; A previous active marker means the old process ended without a confirmed
    ; result. Preserve it as unconfirmed before resetting this session.
    ResolveActiveRunWithoutResult("Unconfirmed", "new-session-started")

    if (g_IsFirstLaunch = 1) {
        IniWrite(0, StateFile, "State", "IsFirstLaunch")
        MsgBox("Since you are starting the macro for the first time... Read this so your macro can work properly:`n`n1. Go to the TDS Settings and ENABLE 'Prefer Vertical Upgrades`n2. Go to the TDS Settings and set UI Scale to 'LARGE'`n3. Set your Roblox Camera Mode to Classic`n4. If your Roblox graphics are automatic, set them to manual.`n5. Turn off camera shake in TDS.`n6. Disable Dialog in TDS`n7. Enable UI Navigation toggle in the Roblox settings.`n8. Enable 'Show Tower Options' in TDS.`n9. Make sure you have 60 fps in Roblox settings.`n`nRecommended screen resolution for this macro is 1920x1080 (Resolutions bigger than 1080p may not work. You can use 1366x768 & 1280x720 though, they work pretty well). The scale must be 100%.`nThis macro requires a good CPU. You can use it though if your device is bad, enable potato mode and make the delays bigger.`nPlease, join my Discord server to get help and check the FAQ.","READ THIS!!", 0x1030)
    }

    IniDelete(StateFile, "State", "Coins")
    IniDelete(StateFile, "State", "Gems")
    IniDelete(StateFile, "State", "EXP")
    IniDelete(StateFile, "State", "TotalTriumphs")
    IniDelete(StateFile, "State", "TotalLosses")
    IniDelete(StateFile, "State", "TotalTimeSeconds")
    IniDelete(StateFile, "State", "RunStarts")
    IniDelete(StateFile, "State", "RunUnconfirmed")
    IniDelete(StateFile, "State", "RunAborted")
    IniDelete(StateFile, "State", "Timescale")
    IniDelete(StateFile, "State", "CurrentStratStartTime")
    IniDelete(StateFile, "State", "CurrentRotationIndex")
    IniDelete(StateFile, "State", "CurrentRunCount")
    IniDelete(StateFile, "State", "StartTime")
    IniDelete(StateFile, "State", "TimeWhenStartedPlaying")
    AutorunStartTime := 0

    LoadStrategyFile(stratFile)

    evolutionRun := PrepareEvolutionQueueForRun()
    if (evolutionRun.enabled) {
        if (v.RotateStrategies = 1) {
            ModernMsgBox("Evolution Queue", "Evolution Queue currently requires one fixed Abstract strategy. Turn Strategy Rotation off before starting.", "OK", "WARNING")
            return
        }
        if (!evolutionRun.valid) {
            message := evolutionRun.complete ? "Every tower in the Evolution Queue is already level 20." : evolutionRun.message
            ModernMsgBox("Evolution Queue", message, "OK", evolutionRun.complete ? "INFO" : "WARNING")
            return
        }
        if (KronoxFeatureBool(IniRead(SettingsFile, "EvolutionQueue", "AutoEquip", 1)))
            IniWrite(1, StateFile, "State", "EvolutionQueuePendingEquip")
    }

    if (requiredTowers != "") {
        requiredMessage := requiredTowers
        if (AbstractTowerSlots.Length > 0) {
            abstractSlotText := AbstractTowerSlotsToText(ActiveAbstractTowerSlots())
            requiredMessage .= "`n`nACTIVE ABSTRACT XP SLOTS: " abstractSlotText
            requiredMessage .= "`nEquip the towers you want to level in hotbar slots " abstractSlotText "."
            if (AbstractPlacementLimit < AbstractTowerSlots.Length)
                requiredMessage .= "`nThe remaining configured abstract slots are disabled and may be left empty."
            if (evolutionRun.enabled)
                requiredMessage .= "`n`nEVOLUTION QUEUE: " KronoxEvolutionAssignmentText(SettingsFile) "`nEffective loadout: " evolutionRun.text
            else
                requiredMessage .= "`nAuto Equip is skipped for this strategy so those towers are never removed."
        }
        ModernMsgBox("Required Towers", requiredMessage, "OK")
    }

    IniWrite(1, StateFile, "State", "Running")
    IniWrite(stratFile, StateFile, "State", "Strategy")

    MainGui.Hide()
    RunningStrategy := true
    SetMacroPhase("strategy-starting", stratFile, 180000)

    time := FormatTime(, "HH:mm:ss")
    SplitPath(stratFile, &fileName)
    startInfo := "[" time "] Started strategy: " fileName "`n"
    startInfo .= "Map = " gamemap "`nMode = " difficulty "`nTimescale = " TimeScaleMode "`nRequired Towers: " requiredTowers
    if (modifiers != "")
        startInfo .= "`nModifiers: " modifiers
    SendToWebhookInstant(startInfo,, flush := false)

    CheckOcrLanguage()

    MultiInstanceTools := "RobloxAccountManager.exe,Roblox Account Manager.exe,RAM.exe,RobloxMulti.exe,MultiRoblox.exe,MultipleRoblox.exe,Multiple Roblox.exe"
    Loop Parse, MultiInstanceTools, "," {
        if ProcessExist(A_LoopField) {
            MsgBox("Conflicting program detected:`n" A_LoopField "`n`nFor this script to work properly, please close all Roblox multi-client utilities.`nPlease close them and try again.", "Error", 0x1030)
            ExitApp()
        }
    }

    CurrentStratStartTime := A_TickCount
    IniWrite(A_TickCount, StateFile, "State", "CurrentStratStartTime")
    CurrentRunCount := 0
    IniWrite(0, StateFile, "State", "CurrentRunCount")
    KronoxBudgetResetSession(StateFile)

    RunStrategy("", true, AutoEquip)
}

StopStrategy(ctrl, *) {
    global RunningStrategy, AutorunStartTime, Recording, MacroRecording, InputHookObj, StateFile

    SuspendAutomationInput("manual-stop")
    KillSubmacros()

    if (RunningStrategy) {
        SetMacroPhase("strategy-stopping", "manual-stop", 0)
        ResolveActiveRunWithoutResult("Aborted", "manual-stop")
        if (AutorunStartTime > 0) {
            runtime := FormatRuntime(AutorunStartTime)
            Coins := IniRead(StateFile, "State", "Coins", "0")
            Gems  := IniRead(StateFile, "State", "Gems",  "0")
            Timescales  := IniRead(StateFile, "State", "Timescale",  "0")
            LogToConsole("Strategy stopped. Runtime: " runtime)
            time := FormatTime(, "HH:mm:ss")
            SendToWebhookInstant("[" time "] Strategy stopped. Runtime: " runtime)
            IniDelete(StateFile, "State", "StartTime")
            AutorunStartTime := 0
        }
        DeleteAllIndicators()
        IniWrite(0, StateFile, "State", "Running")
        IniWrite(0, StateFile, "State", "Strategy")
        IniDelete(StateFile, "State", "Coins")
        IniDelete(StateFile, "State", "Gems")
        IniDelete(StateFile, "State", "EXP")
        IniDelete(StateFile, "State", "TotalTriumphs")
        IniDelete(StateFile, "State", "TotalLosses")
        IniDelete(StateFile, "State", "TotalTimeSeconds")
        IniDelete(StateFile, "State", "RunStarts")
        IniDelete(StateFile, "State", "RunUnconfirmed")
        IniDelete(StateFile, "State", "RunAborted")
        IniDelete(StateFile, "State", "Timescale")
        IniDelete(StateFile, "State", "CurrentStratStartTime")
        IniDelete(StateFile, "State", "CurrentRotationIndex")
        IniDelete(StateFile, "State", "CurrentRunCount")
        IniDelete(StateFile, "State", "TimeWhenStartedPlaying")
        KronoxClearRemoteSessionRequests()
        RunningStrategy := false
        SafeReload()
    }

    if (Recording) {
        StopRecord(0)
    }
}

StartRecording(ctrl, *) {
    global Recording, gamemap, difficulty, requiredTowers, modifiers, autoChain, autoCaravan
    global autoDropTheBeat, AutoSkip, AbilitySpam, MoveEnabled, MoveDirection, MoveDuration
    global Commander, RecordedSteps, Towers, MacroRecording, GuiTitleCtrl, AbstractTowerSlots, AbstractTowerSlot
    global Tab2_Btn1, Tab2_Btn2, HoverEffect_btns, RecTowerCtrls, RecAbstractSlotEnabledCtrl

    if (Recording)
        return

    v := MainGui.Submit(false)

    if (!v.RecMaps or !v.RecDifficulty) {
        MsgBox("Failed to start recording!`nMake sure you have entered the towers, the map, and the difficulty, then try again.", "Error", 0x1010)
        return
    }

    towerSlots := CollectTowerSlotValues(RecTowerCtrls)
    if (!towerSlots.ok) {
        MsgBox(towerSlots.message, "Tower Hotbar", 0x1030)
        return
    }

    selectedAbstractSlots := CollectRecAbstractSlots()
    if (RecAbstractSlotEnabledCtrl.Value = 1 && selectedAbstractSlots.Length = 0) {
        MsgBox("Select at least one abstract hotbar slot, or turn Abstract XP towers off.", "Abstract XP towers", 0x1030)
        return
    }
    if (selectedAbstractSlots.Length > 4) {
        MsgBox("A strategy can use at most four abstract XP tower slots.", "Abstract XP towers", 0x1030)
        return
    }
    abstractTowerList := BuildAbstractRequiredTowers(towerSlots.value, selectedAbstractSlots)
    if (!abstractTowerList.ok) {
        MsgBox(abstractTowerList.message, "Abstract XP tower", 0x1030)
        return
    }

    if (A_ScreenWidth != 1920 || A_ScreenHeight != 1080) {
        if (MsgBox("Your screen resolution is not 1920x1080.`nThe recording system is highly recommended for 1920x1080. Do you want to continue?", "Warning", 0x1034) = "No") {
            return
        }
    }

    if (IsSet(GuiTitleCtrl) && GuiTitleCtrl) {
        GuiTitleCtrl.SetFont("cFF4545")
    }

    if (IsSet(Tab2_Btn1) && Tab2_Btn1) {
        Tab2_Btn1.SetFont("c808080 norm")
        Tab2_Btn1.Opt("Background120B0D")
        if (IsSet(HoverEffect_btns) && IsObject(HoverEffect_btns)) {
            for index, element in HoverEffect_btns {
                if (element = Tab2_Btn1) {
                    HoverEffect_btns.RemoveAt(index)
                    break
                }
            }
        }
    }

    if (IsSet(Tab2_Btn2) && Tab2_Btn2) {
        ApplyButtonRestStyle(Tab2_Btn2)
        if (IsSet(HoverEffect_btns) && IsObject(HoverEffect_btns)) {
            hasElement := false
            for element in HoverEffect_btns {
                if (element = Tab2_Btn2) {
                    hasElement := true
                    break
                }
            }
            if (!hasElement) {
                HoverEffect_btns.Push(Tab2_Btn2)
            }
        }
    }

    gamemap := v.RecMaps
    difficulty := v.RecDifficulty
    requiredTowers := abstractTowerList.value
    SetAbstractTowerSlots(selectedAbstractSlots)
    modifiers := v.RecModifiers
    autoChain := v.RecAutoChain ? "ON" : "OFF"
    autoCaravan := v.RecAutoCaravan ? "ON" : "OFF"
    autoDropTheBeat := v.RecAutoDropTheBeat ? "ON" : "OFF"
    AutoSkip := v.RecAutoSkip ? "ON" : "OFF"
    AbilitySpam := v.RecAbilitySpam ? "ON" : "OFF"
    MoveEnabled := v.RecMoveEnabled ? true : false
    MoveDirection := v.RecMoveDirection
    MoveDuration := IsNumber(v.RecMoveDuration) ? Integer(v.RecMoveDuration) : 750

    Commander := false
    Recording := true
    RecordedSteps := []
    Towers := Map()
    DeleteAllIndicators()

    LogToConsole("Recording started.")
    
    ActivateRoblox()
}

StopRecord(ctrl, *) {
    global Recording, MacroRecording, InputHookObj, MacroSteps, RecordedSteps
    global gamemap, difficulty, requiredTowers, modifiers
    global autoChain, autoCaravan, autoDropTheBeat, AutoSkip, AbilitySpam, MoveEnabled, MoveDirection, MoveDuration
    global AbstractTowerSlots, AbstractTowerSlot
    global GuiTitleCtrl, Strategy1Ctrl, RecordingsDir
    global Tab2_Btn1, Tab2_Btn2, HoverEffect_btns

    if (MacroRecording) {
        MacroRecording := false
        if (InputHookObj != "")
            InputHookObj.Stop()
        LogToConsole("Macro recording auto-stopped")
        if (ModernMsgBox("Add to Strategy?", "Add recorded actions to current strategy?", "YES|NO") = "YES") {
            for i, step in MacroSteps
                RecordedSteps.Push(step)
            LogToConsole("Added " MacroSteps.Length " macro steps to strategy")
        }
    }

    if (!Recording)
        return
    Recording := false
    DeleteAllIndicators()

    if (IsSet(GuiTitleCtrl) && GuiTitleCtrl) {
        GuiTitleCtrl.SetFont("cWhite")
    }

    if (IsSet(Tab2_Btn1) && Tab2_Btn1) {
        ApplyButtonRestStyle(Tab2_Btn1)
        if (IsSet(HoverEffect_btns) && IsObject(HoverEffect_btns)) {
            hasElement := false
            for element in HoverEffect_btns {
                if (element = Tab2_Btn1) {
                    hasElement := true
                    break
                }
            }
            if (!hasElement) {
                HoverEffect_btns.Push(Tab2_Btn1)
            }
        }
    }

    if (IsSet(Tab2_Btn2) && Tab2_Btn2) {
        Tab2_Btn2.SetFont("c808080 norm")
        Tab2_Btn2.Opt("Background120B0D")
        if (IsSet(HoverEffect_btns) && IsObject(HoverEffect_btns)) {
            for index, element in HoverEffect_btns {
                if (element = Tab2_Btn2) {
                    HoverEffect_btns.RemoveAt(index)
                    break
                }
            }
        }
    }

    if (ModernMsgBox("Save", "Save the recorded strategy?", "YES|NO") = "YES") {
        box := InputBox("File name (without .strat):", "Save", "w300 h130", "MyStrategy")
        if (box.Result = "Cancel")
            return
        filePath := RecordingsDir "\" box.Value ".strat"
        if FileExist(filePath)
            FileDelete(filePath)
        getRobloxPos(&pX, &pY, &currentWidth, &currentHeight)

        Join(arr, delim := ", ") {
            if !IsObject(arr)
                return String(arr)

            str := ""
            for index, value in arr
                str .= (index = 1 ? "" : delim) . value
            return str
        }

        FileAppend("[Settings]`nmap=" gamemap "`ndifficulty=" difficulty "`nrequiredTowers=" requiredTowers
            . "`nabstractSlot=" AbstractTowerSlot
            . "`nabstractSlots=" AbstractTowerSlotsToText(AbstractTowerSlots)
            . "`nmodifiers=" Join(modifiers)
            . "`nautoChain=" autoChain "`nautoCaravan=" autoCaravan "`nautoDropTheBeat=" autoDropTheBeat
            . "`nautoSkip=" AutoSkip "`nabilitySpam=" AbilitySpam "`nmoveEnabled=" MoveEnabled "`nmoveDirection=" MoveDirection
            . "`nmoveDuration=" MoveDuration "`n`n[DO NOT EDIT]`nwidth=" currentWidth "`nheight=" currentHeight "`n`n[Steps]`n", filePath)
        for i, step in RecordedSteps
            FileAppend(step "`n", filePath)
        LogToConsole("Strategy saved: " filePath)
        Strategy1Ctrl.Value := filePath
    } else {
        LogToConsole("Recording cancelled, strategy not saved")
    }
}

PlaceTowerHK(*) {
    global Recording, Towers, RecordedSteps, ActiveRTowerID, CachedMenuUI, isUiPositionSaved, UseNumbersForHotbar, Slots

    if (!Recording) {
        if BlockUnsafeRecordingHotkeyPassthrough(PlaceTowerKey, "Place Tower hotkey")
            return
        pureKey := RegExReplace(PlaceTowerKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(PlaceTowerKey, "^([\^+!#]+)", &match) ? match[1] : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }
    
    towersStringBackup := Towers 

    MouseGetPos(&mx, &my)
    loop {
        slotBox := InputBox("Enter the tower slot number (1-5):", "Slot (1-5)", "w300 h130", "1")

        if (slotBox.Result = "Cancel")
            return

        try {
            sllot := Integer(slotBox.Value)
            
            if (sllot >= 1 && sllot <= 5) {
                break
            } else {
                continue
            }
        } 
        catch Error {
            continue
        }
    }
    slot := slotBox.Value
    
    suggestedID := GetNextTowerID(slot)
    
    idBox := InputBox("Enter a specific tower id:", "Tower ID", "w300 h130", suggestedID)
    if (idBox.Result = "Cancel")
        return
    towerID := idBox.Value
    ActivateRoblox()

    LogToConsole("Recording: placing tower " towerID " (slot " slot ") at x:" mx " y:" my "...")

    getRobloxPos(,,&w,&h)

    ActivateRoblox()
    
    if UseNumbersForHotbar {
        Send("{" slot "}")
    } else {
        Click(Slots[slot])
    }

    Sleep(30)
    

    MouseMove(mx, my, A_DefaultMouseSpeed)
    Sleep((PotatoMode = 1) ? 100 : 40)
    Click()
    Sleep(100)
    SendGameplayKey(CancelPlacementKey, "Cancel placement")

    Towers[towerID] := {x: mx, y: my, slot: slot, level: 0, path: 0, pathLevel: 0, target: "First Enemy"}
    UpdateTowerIndicator(towerID)
    LogToConsole("Recorded tower " towerID " (slot " slot ")")

    RecordedSteps.Push("SpawnTower(" mx ", " my ", " slot ", " towerID ")")

    if (towerID = "" || RegExMatch(towerID, "i)(Juggernaut|Hacker|Pursuit|Kingpin)")) {
        ShowTowerPathDialog(towerID)
    }

    ActiveRTowerID := towerID
    
    openedSuccessfully := false
    Loop 10 {
        getRobloxPos(,,&w,&h)
        resV2 := AdvImageSearch("Resources\TowerUI\Variant2.png", 0, Round(h / 2), Round(w * 0.3), Round(h * 0.9) - Round(h / 2), 0.5, 1.5)
        
        if (resV2.status == "success" && resV2.score > 0.6) {
            
            if (!isUiPositionSaved) {
                Sleep(300) 
                
                getRobloxPos(,,&w,&h)
                resV2Final := AdvImageSearch("Resources\TowerUI\Variant2.png", 0, Round(h / 2), Round(w * 0.3), Round(h * 0.9) - Round(h / 2), 0.5, 1.5)
                
                if (resV2Final.status == "success") {
                    CachedMenuUI := {x: resV2Final.x, y: resV2Final.y}
                    isUiPositionSaved := true 
                    openedSuccessfully := true
                } else {
                    CachedMenuUI := {x: resV2.x, y: resV2.y}
                    isUiPositionSaved := true
                    openedSuccessfully := true
                }
            } 
            else {
                openedSuccessfully := true
            }
            break
        }
        Sleep(150)
    }
    
    if (!openedSuccessfully) {
        ActiveRTowerID := ""
    }
}

UpgradeTowerHK(*) {
    global Recording, Towers, RecordedSteps, Commander
    if (!Recording) {
        if BlockUnsafeRecordingHotkeyPassthrough(UpgradeTowerKey, "Upgrade Tower hotkey")
            return
        pureKey := RegExReplace(UpgradeTowerKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(UpgradeTowerKey, "^([\^+!#]+)", &match) ? match[1] : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }

    MouseGetPos(&mx, &my)

    closestID := ""
    for id, t in Towers {
        ix1 := t.x - 12
        iy1 := t.y - 12
        ix2 := ix1 + 24
        iy2 := iy1 + 24
        
        if (mx >= ix1 && mx <= ix2 && my >= iy1 && my <= iy2) {
            closestID := id
            break
        }
    }

    if (closestID != "") {
        Towers[closestID].level += 1
        UpdateTowerIndicator(closestID)
        if (Towers[closestID].path != 0 && Towers[closestID].path != "") {
            RecordedSteps.Push("UpgradeTower(" closestID ", false, 1, " Towers[closestID].path ", " Towers[closestID].pathLevel ")")
        } else {
            RecordedSteps.Push("UpgradeTower(" closestID ")")
        }
        if (Towers[closestID].level >= 2 && RegExMatch(closestID, "i)^Commander\d*$") && !Commander) {
            Commander := true
            if (!HasStep("Commander := true"))
                RecordedSteps.Push("Commander := true")
        }
    }
}

ChangeDJTrackHK(*) {
    global Recording, RecordedSteps
    if (!Recording) {
        if BlockUnsafeRecordingHotkeyPassthrough(ChangeDJTrackKey, "DJ Track hotkey")
            return
        pureKey := RegExReplace(ChangeDJTrackKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(ChangeDJTrackKey, "^([\^+!#]+)", &match) ? match[1] : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }
    box := InputBox("Enter Track Color (Purple/Red/Green):", "DJ Track", "w300 h130", "Green")
    if (box.Result != "Cancel") {
        RecordedSteps.Push('SetDJTrack("' box.Value '")')
        LogToConsole("Recorded DJ-track " box.Value)
    }
}

RecordToggleAutoskip(*) {
    global Recording, RecordedSteps, RecAutoSkipCtrl
    if !Recording
        return

    RecordedSteps.Push("ToggleAutoskip()")
    state := RecAutoSkipCtrl.Value ? "ON" : "OFF"
    LogToConsole("Recorded auto-skip toggle: " state)
}

ToggleAutoskip() {
    global AutoSkip
    AutoSkip := (AutoSkip = "ON") ? "OFF" : "ON"
    LogToConsole("Toggled auto-skip: " AutoSkip)
}

TowerTargetNames() {
    return ["First Enemy", "Last Enemy", "Strongest", "Weakest", "Closest", "Farthest", "Random"]
}

NormalizeTowerTarget(value) {
    normalized := StrLower(Trim(value))
    for target in TowerTargetNames() {
        if (StrLower(target) = normalized)
            return target
    }
    return ""
}

TowerTargetImagePath(target) {
    return "Resources\TowerUI\" StrLower(target) ".png"
}

ChangeTargetsHK(*) {
    global Recording, ActiveRTowerID, LastOpenedTowerID, RecordedSteps, ChangeTargetsKey

    if !Recording {
        if BlockUnsafeRecordingHotkeyPassthrough(ChangeTargetsKey, "Change Target hotkey")
            return
        return
    }

    towerID := ActiveRTowerID
    if (towerID = "") {
        idBox := InputBox("Enter the tower ID:", "Change Targets", "w340 h130", "")
        if (idBox.Result = "Cancel")
            return
        towerID := Trim(idBox.Value)
        if (towerID = "")
            return
    } else {
        LastOpenedTowerID := towerID
    }

    targetBox := InputBox("Target: First Enemy, Last Enemy, Strongest, Weakest, Closest, Farthest, or Random", "Change Targets", "w500 h130", "First Enemy")
    if (targetBox.Result = "Cancel")
        return
    target := NormalizeTowerTarget(targetBox.Value)
    if (target = "") {
        MsgBox("Choose one of the supported target names shown in this dialog.", "Change Targets", 0x1030)
        return
    }

    if ChangeTargets(towerID, target) {
        RecordedSteps.Push("ChangeTargets(" towerID ", " target ")")
        LogToConsole("Recorded ChangeTargets(" towerID ", " target ")")
    }
}

LegacyModeInfo(*) {
    global LegacyModeCtrl
    if LegacyModeCtrl.Value {
        MsgBox("Legacy image mode uses basic 1920x1080 ImageSearch. Keep it off unless advanced image detection does not work on your setup.`n`nAuto Equip and Change Targets use advanced detection, so those features are disabled in Legacy mode.", "Legacy image mode", 0x1030)
    }
}

FindTowerTargetSelector(&leftButton, &rightButton, timeoutMs := 5000) {
    leftButton := 0
    rightButton := 0
    started := A_TickCount
    Loop {
        getRobloxPos(,, &w, &h)
        left := AdvImageSearch("Resources\TowerUI\left.png", 0, 0, Round(w / 2), Round(h / 1.3))
        if (left.status = "success" && left.score > 0.66) {
            right := AdvImageSearch("Resources\TowerUI\right.png", left.x + ScaleX(20), 0, Round(w / 2), Round(h / 1.3))
            if (right.status = "success" && right.score > 0.66) {
                leftButton := left
                rightButton := right
                return true
            }
        }
        if (A_TickCount - started >= timeoutMs)
            return false
        Sleep(150)
    }
}

DetectTowerTarget() {
    getRobloxPos(,, &w, &h)
    bestScore := 0
    detected := ""
    for target in TowerTargetNames() {
        probe := AdvImageSearch(TowerTargetImagePath(target), 0, 0, Round(w / 2), Round(h / 1.3))
        if (probe.status = "success" && probe.score > bestScore) {
            bestScore := probe.score
            detected := target
        }
    }
    return (bestScore >= 0.66) ? detected : ""
}

ChangeTargets(towerID, requestedTarget) {
    global Towers, LastOpenedTowerID, canUseAbility, LegacyMode, unfocusX, unfocusY

    target := NormalizeTowerTarget(requestedTarget)
    if (target = "") {
        LogToConsole("Unsupported tower target: " requestedTarget, true, false)
        return false
    }
    if (LegacyMode = 1 || LegacyMode = "1") {
        LogToConsole("Change Targets is unavailable while Legacy image mode is enabled.", true, false)
        return false
    }
    if !Towers.Has(towerID) {
        LogToConsole("Tower " towerID " not found for changing targets.", true, false)
        return false
    }

    canUseAbility := false
    try {
        tower := Towers[towerID]
        if (!tower.HasProp("target"))
            tower.target := "First Enemy"

        if (LastOpenedTowerID != towerID) {
            Click(tower.x, tower.y)
            Sleep(250)
        } else {
            MouseMove(0, ScaleY(50),, "R")
        }
        LastOpenedTowerID := towerID

        if !waitForTowerUI(,,2500) {
            LogToConsole("Could not open the tower menu for target change: " towerID, true, false)
            return false
        }
        if !FindTowerTargetSelector(&leftButton, &rightButton) {
            LogToConsole("Could not find target arrows for " towerID "; no click was sent.", true, false)
            return false
        }

        currentTarget := DetectTowerTarget()
        if (currentTarget = "")
            currentTarget := tower.target
        if (currentTarget = "")
            currentTarget := "First Enemy"

        targets := TowerTargetNames()
        currentIndex := 1
        targetIndex := 1
        for index, item in targets {
            if (item = currentTarget)
                currentIndex := index
            if (item = target)
                targetIndex := index
        }

        rightSteps := targetIndex - currentIndex
        if (rightSteps < 0)
            rightSteps += targets.Length
        leftSteps := currentIndex - targetIndex
        if (leftSteps < 0)
            leftSteps += targets.Length
        button := (rightSteps <= leftSteps) ? rightButton : leftButton
        clicks := (rightSteps <= leftSteps) ? rightSteps : leftSteps

        Loop clicks {
            Click(button.x, button.y)
            Sleep(500)
        }

        Click(ScaleX(unfocusX), ScaleY(unfocusY))
        Sleep(250)
        LastOpenedTowerID := ""
        Click(tower.x, tower.y)
        Sleep(250)
        LastOpenedTowerID := towerID
        if !waitForTowerUI(,,2500) {
            LogToConsole("Target change could not re-open " towerID " for verification.", true, false)
            return false
        }

        verifiedTarget := DetectTowerTarget()
        if (verifiedTarget != target) {
            LogToConsole("Target change for " towerID " could not be verified (wanted " target ", saw " (verifiedTarget = "" ? "nothing" : verifiedTarget) ").", true, false)
            return false
        }
        tower.target := target
        Towers[towerID] := tower
        LogToConsole("Changed " towerID " target to " target ".")
        return true
    } finally {
        canUseAbility := true
    }
}

DeleteTowerRecordingHK(*) {
    global Recording, Towers, RecordedSteps
    if (!Recording) {
        if BlockUnsafeRecordingHotkeyPassthrough(DeleteTowerRecordingKey, "Delete Recording hotkey")
            return
        pureKey := RegExReplace(DeleteTowerRecordingKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(DeleteTowerRecordingKey, "^([\^+!#]+)", &match) ? match[1] : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }

    MouseGetPos(&mx, &my)

    closestID := ""
    for id, t in Towers {
        if (!HasProp(t, "x") || !HasProp(t, "y"))
            continue

        ix1 := t.x - 12
        iy1 := t.y - 12
        ix2 := ix1 + 24
        iy2 := iy1 + 24
        
        if (mx >= ix1 && mx <= ix2 && my >= iy1 && my <= iy2) {
            closestID := id
            break
        }
    }

    if (closestID != "") {
        if (HasProp(Towers[closestID], "hwnd") && Towers[closestID].hwnd) {
            try WinClose("ahk_id " Towers[closestID].hwnd)
        }

        newSteps := []
        
        escapedID := RegExReplace(closestID, "([\.\ \+\*\?\^\$\(\)\[\]\{\}\|])", "\$1")

        for i, step in RecordedSteps {
            if (RegExMatch(step, "i)^SpawnTower\s*\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*" escapedID "\s*\)$"))
                continue
            if (RegExMatch(step, "i)^UpgradeTower\s*\(\s*" escapedID "\s*(?:,.*)?\s*\)$"))
                continue
            if (RegExMatch(step, "i)^SellTower\s*\(\s*" escapedID "\s*\)$"))
                continue
            newSteps.Push(step)
        }
        RecordedSteps := newSteps

        try {
            if Towers.Has(closestID) {
                Towers.Delete(closestID)
            }
        } catch {
        }

        LogToConsole("Recorded sell tower " closestID)
    }
}


SellTowerHK(*) {
    global Recording, Towers, RecordedSteps
    if (!Recording) {
        if BlockUnsafeRecordingHotkeyPassthrough(SellTowerKey, "Sell Tower hotkey")
            return
        pureKey := RegExReplace(SellTowerKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(SellTowerKey, "^([\^+!#]+)", &match) ? match[1] : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }

    MouseGetPos(&mx, &my)

    closestID := ""
    for id, t in Towers {
        ix1 := t.x - 12
        iy1 := t.y - 12
        ix2 := ix1 + 24
        iy2 := iy1 + 24
        
        if (mx >= ix1 && mx <= ix2 && my >= iy1 && my <= iy2) {
            closestID := id
            break
        }
    }
    if (closestID != "") {
        if (Towers[closestID].hwnd) {
            WinClose("ahk_id " Towers[closestID].hwnd)
            Towers[closestID].hwnd := ""
        }
        RecordedSteps.Push("SellTower(" closestID ")")
        SellTower(closestID)
        newSteps := []
        for i, step in RecordedSteps {
            if (RegExMatch(step, "i)^SpawnTower\s*\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*" closestID "\s*\)$"))
                continue
            if (RegExMatch(step, "i)^UpgradeTower\s*\(\s*" closestID "\s*\)$"))
                continue
            newSteps.Push(step)
        }
        RecordedSteps := newSteps
        Towers.Delete(closestID)
        LogToConsole("Recorded sell tower " closestID)
    }
}

AlignCameraHK(*) {
    if (!Recording) {
        if BlockUnsafeRecordingHotkeyPassthrough(AlignCameraKey, "Align Camera hotkey")
            return
        pureKey := RegExReplace(AlignCameraKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(AlignCameraKey, "^([\^+!#]+)", &match) ? match[1] : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }

    if (InArray(SpecialMaps, gamemap)) {
        functionName := gamemap . "Path"

        %functionName%() 
    } else {
        AlignCamera()
    }
}

RecordInputsHK(*) {
    global MacroRecording, InputHookObj, MacroSteps, MacroStartTime, RecordedSteps, Recording, KeyDownTimes
    if (!Recording) {
        if BlockUnsafeRecordingHotkeyPassthrough(RecordInputsKey, "Record Inputs hotkey")
            return
        pureKey := RegExReplace(RecordInputsKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(RecordInputsKey, "^([\^+!#]+)", &match) ? match[1] : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }
    if (MacroRecording) {
        MacroRecording := false
        if (InputHookObj != "")
            InputHookObj.Stop()
        LogToConsole("Recording ALL clicks and keys STOPPED. Steps: " MacroSteps.Length)
        if (ModernMsgBox("Add to Strategy?", "Add recorded actions to current strategy?", "YES|NO") = "YES") {
            for i, step in MacroSteps
                RecordedSteps.Push(step)
            LogToConsole("Added " MacroSteps.Length " steps to strategy")
        }
    } else {
        LogToConsole("Recording ALL clicks and keys...!")
        MacroRecording := true
        MacroSteps     := []
        KeyDownTimes   := Map() 
        MacroStartTime := A_TickCount
        InputHookObj := InputHook("V")
        InputHookObj.KeyOpt("{All}", "N")
        InputHookObj.OnKeyDown := OnKeyDown
        InputHookObj.OnKeyUp := OnKeyUp 
        InputHookObj.Start()
    }
}

CloneTowerHK(*) {
    global Recording, RecordedSteps
    static LastCallTime := 0

    if (!Recording) {
        if BlockUnsafeRecordingHotkeyPassthrough(HoloKey, "Clone Tower hotkey")
            return
        pureKey := RegExReplace(HoloKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(HoloKey, "^([\^+!#]+)", &match) ? match : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }

    CoordMode("Mouse", "Client")
    ActivateRoblox()
    MouseGetPos(&mx, &my)

    idBox := InputBox("Enter the tower ID to clone:", "Clone Tower", "w300 h130", "")
    if (idBox.Result = "Cancel")
        return

    towerID := Trim(idBox.Value)
    if (towerID = "") {
        return
    }

    CloneTower(towerID, mx, my)

    RecordedSteps.Push("CloneTower(" towerID ", " mx ", " my ")")
}

BrawlerRepositionHK(*) {
    global Recording, RecordedSteps, ActiveRTowerID
    static LastCallTime := 0

    if (!Recording) {
        if BlockUnsafeRecordingHotkeyPassthrough(HoloKey, "Brawler Reposition hotkey")
            return
        pureKey := RegExReplace(HoloKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(HoloKey, "^([\^+!#]+)", &match) ? match : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }

    CoordMode("Mouse", "Client")
    MouseGetPos(&mx, &my)

    if (ActiveRTowerID = "") {
        idBox := InputBox("Enter the tower ID to reposition:", "Repo Brawler", "w300 h130", "")
        if (idBox.Result = "Cancel")
            return

        towerID := Trim(idBox.Value)
        if (towerID = "") {
            return
        }
        BrawlerReposition(towerID, mx, my)
    } else {
        towerID := ActiveRTowerID

        Hotkey("~LButton", "Off")
        g := KeyWait("LButton", "D")
        Hotkey("~LButton", "On")
        LogToConsole(g)

        MouseGetPos(&mx, &my)

        Towers[towerId].x := mx
        Towers[towerId].y := my
        UpdateTowerIndicator(towerId)
    }

    RecordedSteps.Push("BrawlerReposition(" towerID ", " mx ", " my ")")
    LogToConsole("Recorded BrawlerReposition(" towerID ", " mx ", " my ")")
}

ActivateRaiseTheDeadHK(*) {
    global Recording, RecordedSteps
    static LastCallTime := 0

    if (!Recording) {
        if BlockUnsafeRecordingHotkeyPassthrough(UseRaiseDeadKey, "Raise the Dead hotkey")
            return
        pureKey := RegExReplace(UseRaiseDeadKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(UseRaiseDeadKey, "^([\^+!#]+)", &match) ? match : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }

    waitTime := 0
    currentTime := A_TickCount

    if (RecordedSteps.Length > 0) {
        lastStep := RecordedSteps[RecordedSteps.Length]
        
        if (InStr(lastStep, "ActivateRaiseTheDead") && LastCallTime > 0) {
            waitTime := currentTime - LastCallTime
        }
    }

    LastCallTime := currentTime
    ActivateRaiseTheDead(waitTime)

    RecordedSteps.Push("ActivateRaiseTheDead(" waitTime ")")
}

;PATHS

CataclysmPath() {
    AlignCamera(true, false)

    SendEvent("{WheelDown}")
    HyperSleep(100)
    SendEvent("{WheelUp}")
}

SimplicityPath() {
    attempts := 0
    Loop {
        AlignCamera(false, false)
        SendEvent("{sc01f Down}") 
        HyperSleep(2500)
        SendEvent("{sc01f Up}")
        HyperSleep(300)
        SendEvent("{sc01f Down}")
        SendEvent("{sc020 Down}")
        HyperSleep(2000)
        SendEvent("{sc01f Up}")
        SendEvent("{sc020 Up}")
        HyperSleep(300)
        SendEvent("{sc01e Down}")
        HyperSleep(125)
        SendEvent("{sc01e Up}")
        HyperSleep(300)
        SendEvent("{sc01f Down}")
        SendEvent("{sc020 Down}")
        HyperSleep(2000)
        SendEvent("{sc01f Up}")
        SendEvent("{sc020 Up}")
        HyperSleep(300)
        Send("{sc011 Down}")
        HyperSleep(1300)
        Send("{sc011 Up}")
        
        Join(arr, delim := ", ") {
            if !IsObject(arr)
                return String(arr)

            str := ""
            for index, value in arr
                str .= (index = 1 ? "" : delim) . value
            return str
        }

        modifiers_str := (modifiers is Array) ? Join(modifiers) : String(modifiers)

        if (FileExist("Resources\Maps\Simplicity.png") && CheckTheMap = 1 && !RegExMatch(modifiers_str, "i)fog"))
        {
            getRobloxPos(,,&w,&h)
            FoundMap := false
            Loop 5 {
                res := AdvImageSearch("Resources\Maps\Simplicity.png", 0, 0, w, h, 0.5, 2)
                
                if (res.score > 0.65) {
                    FoundMap := true
                    LogToConsole("break " res.score )
                    break
                }
                
                Sleep(300)
            }

            if (!FoundMap) {
                if (attempts > 3)
                    SafeReload()
                LogToConsole("Can't detect the correct position! Resetting..", true)
                resetCharacter()
                Sleep(7500)
                attempts++
                continue
            }
        }
        break
    }
}

;=====

CloneTower(towerId, x, y, wait := 0, maxAttempts := 0) {
    global Towers, unfocusX, unfocusY, LastOpenedTowerID, CancelPlacementKey, HologramKey, Recording,canUseAbility

    if (!Towers.Has(towerID)) {
        LogToConsole("Tower " towerID " not found!")
        return false
    }

    if (wait > 0 && !Recording) {
        Sleep(wait)
    }

    canUseAbility := false

    SendGameplayKey(CancelPlacementKey, "Cancel placement")
    Sleep 50
    if (LastOpenedTowerID != "" || Recording) {
        Click(ScaleX(unfocusX), ScaleY(unfocusY))
        Sleep(120)
    }

    attempts := 0

    loop {
        attempts++
        SendGameplayKey(HologramKey, "Hologram ability")
        Sleep 300

        getRobloxPos(,,&w,&h)
        x1 := Round(w * 0.2)
        y1 := Round(h * 0.18)
        x2 := Round(w * 0.7)
        y2 := Round(h * 0.3)

        if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/hologram_tower_cooldown.png") || ReadMessage(["hologram", "ability", "is on", "cooldown", "hol%ram%", "ility"])) {
            LogToConsole("Failed to clone " towerId "! (hologram cooldown) Retrying again in 5 seconds...")
            KronoxProfilerRetry("CloneTower " towerId, "hologram cooldown")
            if (maxAttempts > 0 && attempts >= maxAttempts) {
                LogToConsole("Clone " towerId " reached its " maxAttempts "-attempt limit; deferring this step.", true)
                canUseAbility := true
                return false
            }
            canUseAbility := true
            Sleep 4650
            canUseAbility := false
            continue
        }
        
        if !ClickCloneSourceTowerSafely(towerId) {
            LogToConsole("Clone source " towerId " was not visually verified; retrying without a blind click...", true, false)
            KronoxProfilerRetry("CloneTower " towerId, "source tower hover was not verified")
            SendGameplayKey(CancelPlacementKey, "Cancel unverified clone")
            if (maxAttempts > 0 && attempts >= maxAttempts) {
                LogToConsole("Clone " towerId " reached its " maxAttempts "-attempt limit; deferring this step.", true)
                canUseAbility := true
                return false
            }
            canUseAbility := true
            Sleep(700)
            canUseAbility := false
            continue
        }

        Sleep 350

        if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/no_cash_cloning.png") || ReadMessage(["don't", "have", "enough", "cash", "clone", "this"])) {
            LogToConsole("Failed to clone " towerId "! (no cash) Retrying again in 5 seconds...")
            KronoxProfilerRetry("CloneTower " towerId, "not enough cash")
            if (maxAttempts > 0 && attempts >= maxAttempts) {
                LogToConsole("Clone " towerId " reached its " maxAttempts "-attempt limit; deferring this step.", true)
                canUseAbility := true
                return false
            }
            canUseAbility := true
            Sleep 4650
            canUseAbility := false
            continue
        }
        
        openedUI := waitForTowerUI(,,500)
        if (openedUI) {
            LogToConsole("Failed to clone tower: accidentally opened upgrade ui! Retrying again..")
            KronoxProfilerRetry("CloneTower " towerId, "upgrade UI opened")
            Click(ScaleX(unfocusX), ScaleY(unfocusY))
            if (maxAttempts > 0 && attempts >= maxAttempts) {
                LogToConsole("Clone " towerId " reached its " maxAttempts "-attempt limit; deferring this step.", true)
                canUseAbility := true
                return false
            }
            Sleep(500)
            continue
        }

        MouseMove(x,y)
        Sleep 100
        MouseClick()
        if !VerifyTowerHotbarAfterRiskyClick("clone placement for " towerId)
            return false

        Sleep 50
        SendGameplayKey(CancelPlacementKey, "Cancel placement")

        Sleep 350

        MouseMove(ScaleX(unfocusX), ScaleY(unfocusY))

        Sleep 100

        if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/stunned.png") || ReadMessage(["error", "that", "cannot", "cann", "activated", "while", "stunned"],,["need", "more", "to"],"\$|\d")) {
            LogToConsole("Failed to clone " towerId "! (hacker is stunned) Retrying again in 5 seconds...")
            KronoxProfilerRetry("CloneTower " towerId, "hacker stunned")
            if (maxAttempts > 0 && attempts >= maxAttempts) {
                LogToConsole("Clone " towerId " reached its " maxAttempts "-attempt limit; deferring this step.", true)
                canUseAbility := true
                return false
            }
            canUseAbility := true
            Sleep 4650
            canUseAbility := false
            continue
        }

        if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/cannot_place_here.png") || ReadMessage(["cannot", "here", "hereg", "herd", "her", "here!", "cann", "cannd", "he", "h", "hed"],,["need", "more", "to"],"\$|\d")) {
            LogToConsole("Failed to clone " towerId "! (cannot place here!) Retrying again in 5 seconds...")
            KronoxProfilerRetry("CloneTower " towerId, "cannot place here")
            if (maxAttempts > 0 && attempts >= maxAttempts) {
                LogToConsole("Clone " towerId " reached its " maxAttempts "-attempt limit; deferring this step.", true)
                canUseAbility := true
                return false
            }
            canUseAbility := true
            Sleep 4650
            canUseAbility := false
            continue
        } else {
            LogToConsole("Successfully cloned tower " towerId ".")
            canUseAbility := true
            return true
        }
    }
}

BrawlerReposition(towerId, x, y) {
    global Towers, unfocusX, unfocusY, LastOpenedTowerID, CancelPlacementKey, RepoKey, Recording

    canUseAbility := false

    loop {

        if (!Towers.Has(towerID)) {
            LogToConsole("Tower " towerID " not found!")
            return false
        }

        SendGameplayKey(CancelPlacementKey, "Cancel placement")
        Sleep 20

        if (LastOpenedTowerID != towerId && LastOpenedTowerID != "") {
            click(ScaleX(unfocusX), ScaleY(unfocusY))
        }

        Sleep 50

        if (LastOpenedTowerID != towerId) {
            click(Towers[towerId].x, Towers[towerId].y)
        }

        attempts := 0
        
        Loop {
            opened := waitForTowerUI()
            if opened {
                attempts := 0
                break
            } else {
                attempts++
                if (attempts > 30) {
                    LogToConsole("Tower " towerID " menu not found after 30 attempts, reloading...", true)
                    SafeReload()
                }
                variation := Random(-4, 4)
                Click(Towers[towerId].x, Towers[towerId].y + ScaleY(variation))
                Sleep(100)
                continue
            }

        }

        getRobloxPos(,,&w,&h)
        SendGameplayKey(RepoKey, "Reposition ability")

        x1 := Round(w * 0.2)
        y1 := Round(h * 0.18)
        x2 := Round(w * 0.7)
        y2 := Round(h * 0.3)

        Sleep 300

        if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/reposition_cooldown.png") || ReadMessage(["reposition", "ability", "is on", "cooldown", "ility"])) {
            LogToConsole("Failed to reposition brawler! Retrying again in 4.5 seconds...")
            Sleep 4500
            continue
        }

        placeattempts := 0
        px := x, py := y
        Loop {
            placeattempts++

            if (placeattempts > 5) {
                SendGameplayKey(CancelPlacementKey, "Cancel placement")
                LogToConsole("Failed to reposition brawler :( ")
                return false
            }

            MouseMove(px,py)
            Sleep 20
            MouseClick

            sleep 400

            if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/cannot_place_here.png") || ReadMessage(["cannot", "here", "hereg", "herd", "her", "here!", "cann", "cannd", "he", "h", "hed"],,["need", "more", "to"],"\$|\d")) {
                LogToConsole("Failed to reposition brawler: cannot place here! Retrying..")
                Sleep 4400
                variation := Random(-3, 3)
                py := y + variation
                continue
            } else {
                break
            }
        }

        if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/stunned.png") || ReadMessage(["error", "that", "cannot", "cann", "activated", "while", "tower", "tmeer", "stunned"],,["need", "more", "to"],"\$|\d")) {
            LogToConsole("Failed to reposition brawler! Retrying again in 4.5 seconds...")
            Sleep 4400
            continue
        }

        Towers[towerId].x := x
        Towers[towerId].y := y
        UpdateTowerIndicator(towerId)
        LogToConsole("Successfully reposited " towerId " to " x ", " y ".")
        break
    }

    canUseAbility := true
}

ActivateRaiseTheDead(wait := 0) {
    global CancelPlacementKey, LastOpenedTowerID, unfocusX, unfocusY, RaiseDeadKey, Recording

    if (wait > 0 && !Recording) {
        Sleep(wait)
    }

    SendGameplayKey(CancelPlacementKey, "Cancel placement")
    if (LastOpenedTowerID != "") {
        Click(ScaleX(unfocusX), ScaleY(unfocusY))
        Sleep(450)
    }

    SendGameplayKey(RaiseDeadKey, "Raise the Dead ability")
    LogToConsole("Successfully activated 'Raise the Dead'")
}

ActivateSwatVan(wait := 0) {
    global CancelPlacementKey, LastOpenedTowerID, unfocusX, unfocusY, SwatVanKey, Recording
    global InputAutomationSuspended

    if (InputAutomationSuspended)
        return false
    if (wait > 0 && !Recording)
        Sleep(wait)

    SendGameplayKey(CancelPlacementKey, "Cancel placement")
    if (LastOpenedTowerID != "") {
        Click(ScaleX(unfocusX), ScaleY(unfocusY))
        Sleep(450)
    }

    SendGameplayKey(SwatVanKey, "SWAT Van ability")
    LogToConsole("Activated Enforcer's SWAT Van ability")
    TouchMacroProgress("SWAT Van ability")
    return true
}


OnKeyDown(ih, vk, sc) {
    global MacroSteps, MacroStartTime, MacroRecording, KeyDownTimes
    if (!MacroRecording)
        return
        
    if (vk = 0xA0 || vk = 0xA1 || vk = 0xA2 || vk = 0xA3
        || vk = 0xA4 || vk = 0xA5 || vk = 0x5B || vk = 0x5C
        || vk = 0x11 || vk = 0x12 || vk = 0x41)
        return
        
    keyId := vk "-" sc
    
    if (KeyDownTimes.Has(keyId))
        return
        
    currentTime := A_TickCount
    elapsed := currentTime - MacroStartTime
    MacroStartTime := currentTime
    
    KeyDownTimes[keyId] := currentTime
    MacroSteps.Push("Sleep(" elapsed ")")
}

OnKeyUp(ih, vk, sc) {
    global MacroSteps, MacroStartTime, MacroRecording, KeyDownTimes
    if (!MacroRecording)
        return
        
    if (vk = 0xA0 || vk = 0xA1 || vk = 0xA2 || vk = 0xA3
        || vk = 0xA4 || vk = 0xA5 || vk = 0x5B || vk = 0x5C
        || vk = 0x11 || vk = 0x12 || vk = 0x41)
        return
        
    currentTime := A_TickCount
    keyId := vk "-" sc
    
    holdDuration := 50
    if (KeyDownTimes.Has(keyId)) {
        holdDuration := currentTime - KeyDownTimes[keyId]
        KeyDownTimes.Delete(keyId) 
    }

    elapsed := currentTime - MacroStartTime
    MacroStartTime := currentTime
    
    keyName := GetKeyName(Format("vk{:02X}sc{:03X}", vk, sc))
    if (keyName = "")
        keyName := "VK" Format("{:02X}", vk)
        
    MacroSteps.Push('Send("' keyName '", hold:=' holdDuration ')')
    
    if (elapsed > 0) {
        MacroSteps.Push("Sleep(" elapsed ")")
    }
}

^SC02C:: {
    global RecordedSteps, Towers, Recording, Commander
    
    if (!Recording) {
        Send("^{SC02C}")
        return
    }
    if (RecordedSteps.Length == 0) {
        return
    }

    lastStep := RecordedSteps.Pop()
    LogToConsole("Undo: Reverting step -> " lastStep)

    if RegExMatch(lastStep, "i)UpgradeTower\s*\(\s*([^\n,\)]+)", &matchUpgrade) {
        towerID := Trim(matchUpgrade[1]) 
        
        if (Towers.Has(towerID)) {
            Towers[towerID].level := Max(0, Towers[towerID].level - 1)
            UpdateTowerIndicator(towerID)
        }
        return
    }

    if RegExMatch(lastStep, "i)SpawnTower\s*\(\s*[^,]+\s*,\s*[^,]+\s*,\s*[^,]+\s*,\s*(.*?)\s*\)", &matchPlace)
    {
        towerID := matchPlace[1] 
        
        if (Towers.Has(towerID)) {
            if (Towers[towerID].HasProp("hwnd") && Towers[towerID].hwnd && WinExist("ahk_id " Towers[towerID].hwnd)) {
                WinClose("ahk_id " Towers[towerID].hwnd)
            }
            Towers.Delete(towerID)

        }
        return
    }

    if (lastStep = "Commander := true") {
        Commander := false
        return
    }
}

~RButton:: {
    global MacroRecording, MacroSteps, MacroStartTime, Towers
    if (!Recording) {
        return
    }

    if (MacroRecording) {
        MouseGetPos(&mx, &my)
        elapsed := A_TickCount - MacroStartTime
        MacroStartTime := A_TickCount
        MacroSteps.Push("Sleep(" elapsed ")")
        MacroSteps.Push("Click(" mx ", " my ", Right)")
        return
    }

    MouseGetPos(&mx, &my)

    towerID := ""

    for id, t in Towers {
        ix1 := t.x - 16
        iy1 := t.y - 16
        ix2 := ix1 + 32
        iy2 := iy1 + 32
        
        if (mx >= ix1 && mx <= ix2 && my >= iy1 && my <= iy2) {
            towerID := id
            break
        }
    }

    if (towerID != "")
        ShowTowerPathDialog(towerID)
}

global ActivePathSelectTowerID := ""

ShowTowerPathDialog(towerID) {
    global Towers, ActivePathSelectTowerID
    if (!Towers.Has(towerID) || Towers[towerID].path = 0 || Towers[towerID].path = "") {
        ActivePathSelectTowerID := towerID
        PathGui := Gui("+AlwaysOnTop +Border", "Path Selection")
        PathGui.SetFont("s12 Bold c000000", "Segoe UI")
        PathGui.Add("Text", "x25 y20 w350", "Tower " towerID)
        PathGui.SetFont("s11 w400 c000000", "Segoe UI")
        PathGui.Add("Text", "x25 y+10 w350", "Choose an upgrade path")
        PathGui.Add("Text", "x25 y+10 w350", "Rigth click on the tower indicator to make this appear.`nNote: enter 3 for Pursuit, Juggernaut, and Kingpin, 4 for Hacker")
        PathGui.SetFont("s10 w600 c000000")
        b1 := PathGui.Add("Button", "x25 y+25 w165 h40", "Path 1 (Top)")
        b1.OnEvent("Click", (*) => SelectPath(PathGui, 1))
        b2 := PathGui.Add("Button", "x+10 w165 h40", "Path 2 (Bottom)")
        b2.OnEvent("Click", (*) => SelectPath(PathGui, 2))
        bc := PathGui.Add("Button", "x25 y+10 w340 h35", "Cancel")
        bc.OnEvent("Click", (*) => PathGui.Destroy())
        PathGui.Show("w390 h280")
        WinWaitClose("ahk_id " PathGui.Hwnd)
    }
}

SelectPath(pathGui, pathNum) {
    global Towers, ActivePathSelectTowerID
    pathGui.Destroy()
    towerID := ActivePathSelectTowerID
    if (towerID = "")
        return
    box := InputBox("Enter the level where the paths appear:", "Level", "w300 h130", "")
    if (box.Result = "Cancel" || !IsInteger(box.Value))
        return
    Towers[towerID].path      := pathNum
    Towers[towerID].pathLevel := Integer(box.Value)
    UpdateTowerIndicator(towerID)
    LogToConsole("Tower " towerID " set to path " pathNum " from level " box.Value)
}

SwitchDiscordRemoteView(*) {
    global DiscordRemoteView
    DiscordRemoteView := (DiscordRemoteView = "Webhook") ? "Bot" : "Webhook"
    ShowDiscordRemoteView()
}

ShowDiscordRemoteView() {
    global DiscordRemoteView, DiscordWebhookTabCtrls, DiscordBotTabCtrls
    global Tab4_Title, Tab4_Line1, Tab4_ModeSwitch, Tab4_BotEnabledCtrl, Tab4_BotTokenCtrl
    global Tab4_BotApplicationCtrl, Tab4_BotChannelCtrl, Tab4_BotGuildCtrl, Tab4_BotOwnerCtrl
    global KronoxBotEnabled, KronoxBotToken, KronoxBotApplicationID, KronoxBotChannelID, KronoxBotGuildID, KronoxBotOwnerUserID

    for ctrl in DiscordWebhookTabCtrls
        ctrl.Visible := false
    for ctrl in DiscordBotTabCtrls
        ctrl.Visible := false

    Tab4_Title.Visible := true
    Tab4_Line1.Visible := true
    Tab4_ModeSwitch.Visible := true
    if (DiscordRemoteView = "Bot") {
        Tab4_Title.Value := "Discord Remote Bot"
        Tab4_ModeSwitch.Value := "Webhook"
        Tab4_BotEnabledCtrl.Value := KronoxBotEnabled
        Tab4_BotTokenCtrl.Value := KronoxBotToken
        Tab4_BotApplicationCtrl.Value := KronoxBotApplicationID
        Tab4_BotChannelCtrl.Value := KronoxBotChannelID
        Tab4_BotGuildCtrl.Value := KronoxBotGuildID
        Tab4_BotOwnerCtrl.Value := KronoxBotOwnerUserID
        for ctrl in DiscordBotTabCtrls
            ctrl.Visible := true
    } else {
        Tab4_Title.Value := "Discord Webhook"
        Tab4_ModeSwitch.Value := "Remote Bot"
        for ctrl in DiscordWebhookTabCtrls
            ctrl.Visible := true
        EnableWebhookLink2()
    }
}

KronoxBotConfigFromUi() {
    values := MainGui.Submit(false)
    return {
        enabled: values.KronoxBotEnabled ? 1 : 0,
        token: Trim(values.KronoxBotToken),
        applicationId: Trim(values.KronoxBotApplicationID),
        channelId: Trim(values.KronoxBotChannelID),
        guildId: Trim(values.KronoxBotGuildID),
        ownerId: Trim(values.KronoxBotOwnerUserID)
    }
}

ValidateKronoxBotConfig(config, requireEnabled := true) {
    if (requireEnabled && !config.enabled)
        return {ok: false, message: "Enable the remote bot before saving or testing it."}
    if (config.token = "")
        return {ok: false, message: "Enter a Discord bot token first."}
    for label, value in Map("Application ID", config.applicationId, "Channel ID", config.channelId, "Owner user ID", config.ownerId) {
        if !RegExMatch(value, "^\d{16,22}$")
            return {ok: false, message: label " must be a valid Discord ID."}
    }
    if (config.guildId != "" && !RegExMatch(config.guildId, "^\d{16,22}$"))
        return {ok: false, message: "Guild/server ID must be blank or a valid Discord ID."}
    return {ok: true, message: ""}
}

SaveKronoxDiscordBotSettings(ctrl, *) {
    global KronoxBotEnabled, KronoxBotToken, KronoxBotApplicationID, KronoxBotChannelID, KronoxBotGuildID, KronoxBotOwnerUserID, KronoxBotSettingsFile, KronoxBotCommandQueueDir

    config := KronoxBotConfigFromUi()
    if config.enabled {
        validation := ValidateKronoxBotConfig(config)
        if !validation.ok {
            ModernMsgBox("Remote Bot", validation.message, "OK", "WARNING")
            return
        }
    }

    KronoxBotEnabled := config.enabled
    KronoxBotToken := config.token
    KronoxBotApplicationID := config.applicationId
    KronoxBotChannelID := config.channelId
    KronoxBotGuildID := config.guildId
    KronoxBotOwnerUserID := config.ownerId
    IniWrite(KronoxBotEnabled, KronoxBotSettingsFile, "Settings", "Enabled")
    IniWrite(KronoxBotApplicationID, KronoxBotSettingsFile, "Settings", "ApplicationID")
    IniWrite(KronoxBotChannelID, KronoxBotSettingsFile, "Settings", "ChannelID")
    IniWrite(KronoxBotGuildID, KronoxBotSettingsFile, "Settings", "GuildID")
    IniWrite(KronoxBotOwnerUserID, KronoxBotSettingsFile, "Settings", "OwnerUserID")
    IniWrite(KronoxBotToken, KronoxBotSettingsFile, "Token", "BotToken")
    ; A saved configuration may have a new app, guild, or owner. Force the
    ; sidecar to refresh its slash-command registration exactly once.
    try FileDelete(KronoxBotCommandQueueDir "\.registration-v1")

    if !KronoxBotEnabled {
        StopKronoxDiscordBot()
        ModernMsgBox("Remote Bot", "Saved with the remote bot disabled. No Discord connection will be made.", "OK")
        return
    }

    StartKronoxDiscordBot()
    ModernMsgBox("Remote Bot", "Saved. The bot is registering /help, /status, /screenshot, /start, and /stop.`n`nUse the Guild ID for immediate command registration.", "OK")
}

TestKronoxDiscordBot(ctrl, *) {
    config := KronoxBotConfigFromUi()
    ; Testing credentials must be possible before the optional bot is enabled.
    validation := ValidateKronoxBotConfig(config, false)
    if !validation.ok {
        ModernMsgBox("Remote Bot", validation.message, "OK", "WARNING")
        return
    }

    probe := KronoxDiscordBotApiRequest("GET", "users/@me", config.token)
    if !probe.ok {
        ModernMsgBox("Remote Bot", "Discord rejected the bot credentials (HTTP " probe.status "). Check the token and try again.", "OK", "WARNING")
        return
    }
    sent := KronoxDiscordBotApiRequest("POST", "channels/" config.channelId "/messages", config.token,
        '{"content":"✅ Kronox Edition slash-command bot test succeeded."}')
    if sent.ok
        ModernMsgBox("Remote Bot", "Bot token accepted and the test message was sent.", "OK")
    else
        ModernMsgBox("Remote Bot", "The token is valid, but Discord could not send to that channel (HTTP " sent.status "). Check the channel ID and bot permissions.", "OK", "WARNING")
}

KronoxDiscordBotApiRequest(method, endpoint, token, body := "", contentType := "application/json") {
    result := {ok: false, status: 0, response: ""}
    try {
        request := ComObject("WinHttp.WinHttpRequest.5.1")
        request.Option[9] := 2720
        request.Open(method, "https://discord.com/api/v10/" endpoint, false)
        request.SetRequestHeader("User-Agent", "KronoxUltimateMacro/1.3.3")
        request.SetRequestHeader("Authorization", "Bot " token)
        hasBody := IsObject(body) || (body != "")
        if hasBody
            request.SetRequestHeader("Content-Type", contentType)
        request.SetTimeouts(5000, 5000, 15000, 15000)
        if !hasBody
            request.Send()
        else
            request.Send(body)
        result.status := request.Status
        result.response := request.ResponseText
        result.ok := (result.status >= 200 && result.status < 300)
    } catch Error as err {
        result.response := err.Message
    }
    return result
}

StartKronoxDiscordBot(*) {
    global KronoxBotEnabled, KronoxBotToken, KronoxBotApplicationID, KronoxBotChannelID, KronoxBotOwnerUserID
    global KronoxBotGatewayScript, KronoxBotSettingsFile, KronoxBotCommandQueueDir, KronoxBotRuntimeLogFile, KronoxBotGatewayPID

    StopKronoxDiscordBot()
    if (!KronoxBotEnabled)
        return false
    if (KronoxBotToken = "" || KronoxBotApplicationID = "" || KronoxBotChannelID = "" || KronoxBotOwnerUserID = "") {
        WriteRuntimeLog("DISCORD", "Remote bot remains disabled at runtime because its configuration is incomplete.", "WARN")
        return false
    }
    if !FileExist(KronoxBotGatewayScript) {
        WriteRuntimeLog("DISCORD", "Remote bot sidecar is missing: " KronoxBotGatewayScript, "ERROR")
        return false
    }

    ; Never execute a command left in the queue by a crashed/reloaded macro.
    Loop Files, KronoxBotCommandQueueDir "\*.cmd", "F"
        try FileDelete(A_LoopFileFullPath)

    command := 'powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' KronoxBotGatewayScript '" -SettingsPath "' KronoxBotSettingsFile '" -CommandQueuePath "' KronoxBotCommandQueueDir '" -LogPath "' KronoxBotRuntimeLogFile '"'
    try {
        Run(command, A_ScriptDir, "Hide", &KronoxBotGatewayPID)
        WriteRuntimeLog("DISCORD", "Started local slash-command gateway (PID " KronoxBotGatewayPID ").")
        SetTimer(ProcessKronoxDiscordCommands, 500)
        return true
    } catch Error as err {
        KronoxBotGatewayPID := 0
        WriteRuntimeLog("DISCORD", "Could not start slash-command gateway: " err.Message, "ERROR")
        return false
    }
}

StopKronoxDiscordBot(*) {
    global KronoxBotGatewayPID
    SetTimer(ProcessKronoxDiscordCommands, 0)
    if (KronoxBotGatewayPID && ProcessExist(KronoxBotGatewayPID)) {
        try ProcessClose(KronoxBotGatewayPID)
    }
    KronoxBotGatewayPID := 0
}

; The PowerShell gateway only acknowledges Discord interactions.  Commands are
; queued locally so every actual macro action stays in this process and follows
; the same input-safety / lifecycle rules as a GUI action.
ProcessKronoxDiscordCommands(*) {
    global KronoxBotEnabled, KronoxBotCommandQueueDir, KronoxBotSettingsFile

    if !KronoxBotEnabled
        return

    Loop Files, KronoxBotCommandQueueDir "\*.cmd", "F" {
        commandFile := A_LoopFileFullPath
        try payload := Trim(FileRead(commandFile, "UTF-8"), " `t`r`n")
        catch Error
            continue

        ; Deleting immediately prevents a sidecar reconnect from replaying a
        ; command. The interaction id below supplies a second durable guard.
        try FileDelete(commandFile)
        if (payload = "")
            continue

        parts := StrSplit(payload, "|")
        if (parts.Length < 2)
            continue
        interactionId := Trim(parts[1])
        action := StrLower(Trim(parts[2]))
        argument := (parts.Length >= 3) ? Trim(parts[3]) : ""
        argument2 := (parts.Length >= 4) ? Trim(parts[4]) : ""
        previousId := IniRead(KronoxBotSettingsFile, "Runtime", "LastInteraction", "")
        if (interactionId = "" || interactionId = previousId)
            continue

        IniWrite(interactionId, KronoxBotSettingsFile, "Runtime", "LastInteraction")
        KronoxDispatchDiscordCommand(action, argument, argument2)
    }
}

KronoxDispatchDiscordCommand(action, argument := "", argument2 := "") {
    global RunningStrategy

    switch action {
        case "help":
            KronoxBotSendChannel("**Kronox Remote Bot**`n`/status — state and this-run stats`n`/health — macro phase and recovery health`n`/screenshot — current desktop view`n`/start and /stop — start or immediately stop`n`/safe-stop — finish the current match, then stop`n`/switch slot:1|2 — safely swap strategy and standard loadout`n`/queue — pending remote actions`n`/timescale mode:off|1.5x|2x — next-match session override`n`/modifiers action:set|add|remove|clear|reset names:Exploding,Speedy — next-match session override`n`/loadout — selected strategy loadout`n`/best — best recorded coin/XP map and modifier set")
        case "status":
            KronoxBotSendChannel(KronoxBotStatusMessage())
        case "health":
            KronoxBotSendChannel(KronoxBotHealthMessage())
        case "screenshot":
            KronoxBotSendScreenshot("Kronox remote screenshot")
        case "start":
            if RunningStrategy
                KronoxBotSendChannel("The macro is already running.")
            else {
                KronoxBotSendChannel("Remote start accepted. Starting the selected strategy…")
                SetTimer(KronoxRemoteStart, -10)
            }
        case "stop":
            if !RunningStrategy
                KronoxBotSendChannel("The macro is already stopped.")
            else {
                KronoxBotSendChannel("Remote stop accepted. Releasing inputs and stopping safely…")
                SetTimer(KronoxRemoteStop, -10)
            }
        case "safe-stop":
            if !RunningStrategy {
                KronoxBotSendChannel("The macro is already stopped; there is no active match to finish.")
                return
            }
            KronoxQueueRemoteSafeStop()
            KronoxBotSendChannel("Safe stop queued. The macro will finish the current match, then stop before another match begins.")
        case "queue":
            KronoxBotSendChannel(KronoxRemoteQueueMessage())
        case "switch":
            if !RegExMatch(argument, "^[12]$") {
                KronoxBotSendChannel("Choose a configured strategy slot: /switch slot:1 or /switch slot:2.")
                return
            }
            switchRequest := KronoxQueueRemoteStrategySwitch(Integer(argument))
            if !switchRequest.ok {
                KronoxBotSendChannel("Strategy switch was not queued: " switchRequest.message)
                return
            }
            timing := RunningStrategy ? "after the current match reaches a safe restart point" : "for the next /start"
            KronoxBotSendChannel("Queued **Strategy " switchRequest.slot "** (" switchRequest.name ") " timing ". Standard loadouts will auto-equip; Abstract XP slots remain protected.")
        case "timescale":
            timeScaleRequest := KronoxQueueRemoteTimeScale(argument)
            if !timeScaleRequest.ok {
                KronoxBotSendChannel(timeScaleRequest.message)
                return
            }
            timing := RunningStrategy ? "the next match" : "the next /start"
            KronoxBotSendChannel("Queued temporary **" timeScaleRequest.mode "** timescale for " timing ". The saved Settings value and strategy file are unchanged.")
        case "modifiers":
            modifierRequest := KronoxQueueRemoteModifiers(argument, argument2)
            if !modifierRequest.ok {
                KronoxBotSendChannel(modifierRequest.message)
                return
            }
            if (modifierRequest.action = "reset") {
                KronoxBotSendChannel("Cleared the temporary modifier override. The next match will use the strategy file's modifiers.")
            } else {
                timing := RunningStrategy ? "the next match" : "the next /start"
                detail := modifierRequest.action = "clear" ? "no modifiers" : modifierRequest.names
                KronoxBotSendChannel("Queued temporary modifiers for " timing ": **" detail "** (" modifierRequest.action "). The strategy file is unchanged.")
            }
        case "loadout":
            KronoxBotSendChannel(KronoxBotLoadoutMessage())
        case "best":
            KronoxBotSendChannel(KronoxBotBestMessage())
        default:
            KronoxBotSendChannel("Unknown remote command was ignored.")
    }
}

KronoxRemoteStart(*) {
    global RunningStrategy
    if !RunningStrategy
        StartStrategy(0)
}

KronoxRemoteStop(*) {
    global RunningStrategy
    if RunningStrategy
        StopStrategy(0)
}

KronoxQueueRemoteSafeStop() {
    global StateFile

    IniWrite(1, StateFile, "Remote", "SafeStop")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), StateFile, "Remote", "SafeStopRequestedAt")
    WriteRuntimeLog("DISCORD", "Queued remote safe stop at the next run boundary.")
}

KronoxConsumeRemoteSafeStop() {
    global StateFile

    if (Integer(IniRead(StateFile, "Remote", "SafeStop", 0)) != 1)
        return false
    IniDelete(StateFile, "Remote", "SafeStop")
    IniDelete(StateFile, "Remote", "SafeStopRequestedAt")
    KronoxClearRemoteSessionRequests()
    WriteRuntimeLog("DISCORD", "Applied remote safe stop at a run boundary.")
    return true
}

KronoxClearRemoteRunOverrides() {
    global StateFile

    for key in ["RunTimeScaleMode", "RunModifierAction", "RunModifierNames", "RunOverrideRequestedAt"]
        try IniDelete(StateFile, "Remote", key)
}

KronoxClearRemoteSessionRequests() {
    global StateFile

    KronoxClearRemoteRunOverrides()
    for key in ["SafeStop", "SafeStopRequestedAt", "PendingStrategySlot", "PendingStrategyPath", "PendingStrategyRequestedAt", "ForceEquip"]
        try IniDelete(StateFile, "Remote", key)
}

KronoxRemoteModifierCatalog() {
    static catalog := Map(
        "broke", "Broke", "exploding", "Exploding", "flying", "Flying", "fog", "Fog", "glass", "Glass",
        "healthy", "Healthy", "hidden", "Hidden", "inflation", "Inflation", "jailed", "Jailed", "limitation", "Limitation",
        "committed", "Committed", "quarantine", "Quarantine", "speedy", "Speedy",
        "explosive", "Exploding", "exploding enemy", "Exploding", "exploding enemies", "Exploding",
        "speedy enemy", "Speedy", "speedy enemies", "Speedy", "flying enemy", "Flying", "flying enemies", "Flying",
        "hidden enemy", "Hidden", "hidden enemies", "Hidden", "healthy enemy", "Healthy", "healthy enemies", "Healthy",
        "limitations", "Limitation")
    return catalog
}

KronoxRemoteModifierList(text, requireNames := true) {
    catalog := KronoxRemoteModifierCatalog()
    names := []
    seen := Map()
    normalizedText := StrReplace(StrReplace(StrReplace(String(text), "`r`n", ","), "`n", ","), ";", ",")
    for rawName in StrSplit(normalizedText, ",") {
        key := RegExReplace(StrLower(Trim(rawName)), "\s+", " ")
        if (key = "")
            continue
        if !catalog.Has(key)
            return {ok: false, message: "Unknown modifier: " Trim(rawName) ". Use the exact TDS names, for example Exploding or Speedy."}
        canonical := catalog[key]
        canonicalKey := StrLower(canonical)
        if !seen.Has(canonicalKey) {
            seen[canonicalKey] := true
            names.Push(canonical)
        }
    }
    if (requireNames && names.Length = 0)
        return {ok: false, message: "Provide one or more modifiers separated by commas, or choose the clear/reset action."}
    return {ok: true, names: names, text: KronoxJoin(names)}
}

KronoxMergeRemoteModifiers(baseText, action, requestedNames := []) {
    base := KronoxRemoteModifierList(baseText, false)
    if !base.ok
        return base
    if (action = "set")
        return {ok: true, text: KronoxJoin(requestedNames)}
    if (action = "clear")
        return {ok: true, text: ""}

    requested := Map()
    for name in requestedNames
        requested[StrLower(name)] := true

    merged := []
    existing := Map()
    for name in base.names {
        key := StrLower(name)
        if (action = "remove" && requested.Has(key))
            continue
        if !existing.Has(key) {
            existing[key] := true
            merged.Push(name)
        }
    }
    if (action = "add") {
        for name in requestedNames {
            key := StrLower(name)
            if !existing.Has(key) {
                existing[key] := true
                merged.Push(name)
            }
        }
    }
    return {ok: true, text: KronoxJoin(merged)}
}

KronoxSetRuntimeTimeScale(mode) {
    global TimeScaleMode, UseTimeScale, TimeScaleMultiplier

    mode := StrLower(Trim(mode))
    if (mode = "off")
        TimeScaleMode := "OFF", UseTimeScale := false, TimeScaleMultiplier := 1
    else if (mode = "1.5x")
        TimeScaleMode := "1.5x", UseTimeScale := true, TimeScaleMultiplier := 1.5
    else if (mode = "2x")
        TimeScaleMode := "2x", UseTimeScale := true, TimeScaleMultiplier := 2
    else
        return false
    return true
}

KronoxQueueRemoteTimeScale(mode) {
    global StateFile

    normalized := StrLower(Trim(mode))
    if (normalized = "off")
        normalized := "OFF"
    else if !(normalized = "1.5x" || normalized = "2x")
        return {ok: false, message: "Choose /timescale mode:off, mode:1.5x, or mode:2x."}
    IniWrite(normalized, StateFile, "Remote", "RunTimeScaleMode")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), StateFile, "Remote", "RunOverrideRequestedAt")
    WriteRuntimeLog("DISCORD", "Queued temporary timescale override: " normalized)
    return {ok: true, mode: normalized}
}

KronoxQueueRemoteModifiers(action, names) {
    global StateFile

    normalizedAction := StrLower(Trim(action))
    if !(normalizedAction = "set" || normalizedAction = "add" || normalizedAction = "remove" || normalizedAction = "clear" || normalizedAction = "reset")
        return {ok: false, message: "Choose a modifier action: set, add, remove, clear, or reset."}
    if (normalizedAction = "reset") {
        for key in ["RunModifierAction", "RunModifierNames"]
            try IniDelete(StateFile, "Remote", key)
        WriteRuntimeLog("DISCORD", "Cleared temporary modifier override.")
        return {ok: true, action: "reset", names: ""}
    }
    parsed := (normalizedAction = "clear") ? {ok: true, text: ""} : KronoxRemoteModifierList(names)
    if !parsed.ok
        return parsed
    IniWrite(normalizedAction, StateFile, "Remote", "RunModifierAction")
    IniWrite(parsed.text, StateFile, "Remote", "RunModifierNames")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), StateFile, "Remote", "RunOverrideRequestedAt")
    WriteRuntimeLog("DISCORD", "Queued temporary modifier override: " normalizedAction " " parsed.text)
    return {ok: true, action: normalizedAction, names: parsed.text}
}

KronoxApplyRemoteRunOverrides() {
    global StateFile, modifiers

    remoteTimeScale := Trim(IniRead(StateFile, "Remote", "RunTimeScaleMode", ""))
    if (remoteTimeScale != "")
        KronoxSetRuntimeTimeScale(remoteTimeScale)

    action := StrLower(Trim(IniRead(StateFile, "Remote", "RunModifierAction", "")))
    if (action = "")
        return
    names := IniRead(StateFile, "Remote", "RunModifierNames", "")
    parsed := (action = "clear") ? {ok: true, names: []} : KronoxRemoteModifierList(names)
    if !parsed.ok {
        WriteRuntimeLog("DISCORD", "Ignored invalid temporary modifier override: " parsed.message, "WARN")
        return
    }
    merged := KronoxMergeRemoteModifiers(modifiers, action, parsed.names)
    if !merged.ok {
        WriteRuntimeLog("DISCORD", "Could not apply temporary modifier override: " merged.message, "WARN")
        return
    }
    modifiers := merged.text
    WriteRuntimeLog("DISCORD", "Applied temporary modifier override for this macro session: " (modifiers = "" ? "no modifiers" : modifiers))
}

KronoxQueueRemoteStrategySwitch(slot) {
    global Strategy1Path, Strategy2Path, StateFile

    if !(slot = 1 || slot = 2)
        return {ok: false, message: "Only strategy slots 1 and 2 can be selected."}
    strategyPath := (slot = 1) ? Trim(Strategy1Path) : Trim(Strategy2Path)
    if (strategyPath = "" || !FileExist(strategyPath))
        return {ok: false, message: "Strategy " slot " is empty or its file no longer exists."}

    SplitPath(strategyPath, &strategyName)
    IniWrite(slot, StateFile, "Remote", "PendingStrategySlot")
    IniWrite(strategyPath, StateFile, "Remote", "PendingStrategyPath")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), StateFile, "Remote", "PendingStrategyRequestedAt")
    WriteRuntimeLog("DISCORD", "Queued remote strategy switch to slot " slot ": " strategyName)
    return {ok: true, slot: slot, name: strategyName}
}

; Consume a remote request only at a run boundary. The selected path is saved
; with the request, so a later UI edit cannot silently redirect the command.
ConsumeKronoxRemoteStrategySwitch(&targetPath) {
    global StateFile, Strategy1Path, Strategy2Path, CurrentRotationIndex, CurrentStratStartTime, CurrentRunCount

    targetPath := ""
    slotText := IniRead(StateFile, "Remote", "PendingStrategySlot", "")
    if !RegExMatch(slotText, "^[12]$")
        return false
    slot := Integer(slotText)
    requestedPath := Trim(IniRead(StateFile, "Remote", "PendingStrategyPath", ""))
    fallbackPath := (slot = 1) ? Trim(Strategy1Path) : Trim(Strategy2Path)
    strategyPath := (requestedPath != "") ? requestedPath : fallbackPath

    if (strategyPath = "" || !FileExist(strategyPath)) {
        WriteRuntimeLog("DISCORD", "Discarded queued strategy switch because the requested file is unavailable.", "WARN")
        IniDelete(StateFile, "Remote", "PendingStrategySlot")
        IniDelete(StateFile, "Remote", "PendingStrategyPath")
        IniDelete(StateFile, "Remote", "PendingStrategyRequestedAt")
        return false
    }

    CurrentRotationIndex := slot
    CurrentStratStartTime := A_TickCount
    CurrentRunCount := 0
    IniWrite(slot, StateFile, "State", "CurrentRotationIndex")
    IniWrite(A_TickCount, StateFile, "State", "CurrentStratStartTime")
    IniWrite(0, StateFile, "State", "CurrentRunCount")
    IniWrite(strategyPath, StateFile, "State", "Strategy")
    IniWrite(1, StateFile, "Remote", "ForceEquip")
    IniDelete(StateFile, "Remote", "PendingStrategySlot")
    IniDelete(StateFile, "Remote", "PendingStrategyPath")
    IniDelete(StateFile, "Remote", "PendingStrategyRequestedAt")
    targetPath := strategyPath
    SplitPath(strategyPath, &strategyName)
    WriteRuntimeLog("DISCORD", "Applied queued remote strategy switch to slot " slot ": " strategyName)
    return true
}

KronoxBotStatusMessage() {
    global StateFile, AutorunStartTime, RunningStrategy

    strategyPath := IniRead(StateFile, "State", "ActiveStrategyPath", IniRead(StateFile, "State", "Strategy", ""))
    strategyName := IniRead(StateFile, "State", "ActiveStrategyName", "")
    if (strategyName = "" && strategyPath != "")
        SplitPath(strategyPath, &strategyName)
    if (strategyName = "")
        strategyName := "No strategy selected"

    queueText := KronoxRemoteQueueSummary()
    pendingText := (queueText != "") ? "`n**Remote queue:** " queueText : ""

    if !RunningStrategy
        return "**Kronox Macro:** stopped`n**Strategy:** " strategyName pendingText

    wins := Integer(IniRead(StateFile, "State", "TotalTriumphs", 0))
    losses := Integer(IniRead(StateFile, "State", "TotalLosses", 0))
    coins := Integer(IniRead(StateFile, "State", "Coins", 0))
    gems := Integer(IniRead(StateFile, "State", "Gems", 0))
    xp := Integer(IniRead(StateFile, "State", "EXP", 0))
    runtime := (AutorunStartTime > 0) ? FormatRuntime(AutorunStartTime) : "00:00"
    phase := IniRead(StateFile, "Health", "Phase", "working")
    detail := IniRead(StateFile, "Health", "Detail", "")
    message := "**Kronox Macro:** running`n**Strategy:** " strategyName "`n**Phase:** " phase
    if (detail != "")
        message .= " — " detail
    return message "`n**This run:** W " wins " | L " losses " | Coins " FormatStatsNumber(coins) " | Gems " FormatStatsNumber(gems) " | XP " FormatStatsNumber(xp) "`n**Runtime:** " runtime pendingText
}

KronoxRemoteQueueSummary() {
    global StateFile

    parts := []
    pendingSlot := IniRead(StateFile, "Remote", "PendingStrategySlot", "")
    if RegExMatch(pendingSlot, "^[12]$")
        parts.Push("switch to Strategy " pendingSlot)
    if (Integer(IniRead(StateFile, "Remote", "SafeStop", 0)) = 1)
        parts.Push("safe stop after current match")
    timeScale := Trim(IniRead(StateFile, "Remote", "RunTimeScaleMode", ""))
    if (timeScale != "")
        parts.Push("timescale " timeScale)
    modifierAction := StrLower(Trim(IniRead(StateFile, "Remote", "RunModifierAction", "")))
    if (modifierAction != "") {
        modifierNames := Trim(IniRead(StateFile, "Remote", "RunModifierNames", ""))
        modifierText := (modifierAction = "clear") ? "no modifiers" : modifierAction " " modifierNames
        parts.Push("modifiers " modifierText)
    }
    return parts.Length > 0 ? KronoxJoin(parts, " • ") : ""
}

KronoxRemoteQueueMessage() {
    summary := KronoxRemoteQueueSummary()
    return "**Kronox remote queue:** " (summary != "" ? summary : "No pending remote actions.")
}

KronoxBotHealthMessage() {
    global StateFile, RunningStrategy, KronoxBotGatewayPID

    phase := IniRead(StateFile, "Health", "Phase", "idle")
    detail := IniRead(StateFile, "Health", "Detail", "")
    ownerPid := IniRead(StateFile, "Health", "OwnerPID", "unknown")
    updatedAt := IniRead(StateFile, "Health", "UpdatedAt", "not reported")
    gatewayState := (KronoxBotGatewayPID && ProcessExist(KronoxBotGatewayPID)) ? "connected" : "not running"
    message := "**Kronox health:** " (RunningStrategy ? "running" : "stopped") "`n**Phase:** " phase
    if (detail != "")
        message .= " — " detail
    return message "`n**Last health update:** " updatedAt "`n**Macro PID:** " ownerPid " | **Remote gateway:** " gatewayState
}

KronoxBotLoadoutMessage() {
    global StateFile, Strategy1Path

    strategyPath := IniRead(StateFile, "State", "ActiveStrategyPath", IniRead(StateFile, "State", "Strategy", ""))
    if (strategyPath = "" || !FileExist(strategyPath))
        strategyPath := Strategy1Path
    if (strategyPath = "" || !FileExist(strategyPath))
        return "No readable strategy is selected, so no loadout can be previewed."
    SplitPath(strategyPath, &strategyName)
    mapName := IniRead(strategyPath, "Settings", "map", "Unknown")
    modeName := IniRead(strategyPath, "Settings", "difficulty", "Unknown")
    towers := Trim(IniRead(strategyPath, "Settings", "requiredTowers", ""))
    abstractSlots := Trim(IniRead(strategyPath, "Settings", "abstractSlots", IniRead(strategyPath, "Settings", "abstractSlot", "")))
    message := "**Loadout:** " strategyName "`n**Map / mode:** " mapName " / " modeName "`n**Towers:** " (towers != "" ? towers : "Not listed")
    if (abstractSlots != "")
        message .= "`n**Abstract slots:** " abstractSlots " (protected from ordinary auto-equip)"
    return message
}

KronoxBotBestMessage() {
    return "**Kronox best recorded efficiency**`n**Coins:** " FindBestStatsBreakdown("Map_", "Coins") "`n**XP:** " FindBestStatsBreakdown("Map_", "EXP") "`n**Modifier set:** " FindBestModifierROI()
}

KronoxBotEscapeJson(text) {
    escaped := StrReplace(String(text), "\", "\\")
    escaped := StrReplace(escaped, "`r`n", "\n")
    escaped := StrReplace(escaped, "`n", "\n")
    escaped := StrReplace(escaped, "`r", "\n")
    return StrReplace(escaped, Chr(34), "\" Chr(34))
}

KronoxBotSendChannel(text) {
    global KronoxBotToken, KronoxBotChannelID

    if (KronoxBotToken = "" || KronoxBotChannelID = "")
        return false
    q := Chr(34)
    payload := "{" q "content" q ":" q KronoxBotEscapeJson(text) q "," q "allowed_mentions" q ":{" q "parse" q ":[]}}"
    result := KronoxDiscordBotApiRequest("POST", "channels/" KronoxBotChannelID "/messages", KronoxBotToken, payload)
    if !result.ok
        WriteRuntimeLog("DISCORD", "Could not send remote reply (HTTP " result.status ").", "WARN")
    return result.ok
}

KronoxBotSendScreenshot(description := "Kronox remote screenshot") {
    global KronoxBotToken, KronoxBotChannelID

    if (KronoxBotToken = "" || KronoxBotChannelID = "")
        return false
    pBitmap := 0
    try {
        pBitmap := Gdip_BitmapFromScreen()
        q := Chr(34)
        payload := "{" q "content" q ":" q KronoxBotEscapeJson(description) q "," q "attachments" q ":[{" q "id" q ":0," q "filename" q ":" q "screenshot.png" q "}]}"
        fields := [
            Map("name", "payload_json", "content-type", "application/json", "content", payload),
            Map("name", "files[0]", "filename", "screenshot.png", "content-type", "image/png", "pBitmap", pBitmap)
        ]
        CreateFormData(&postdata, &contentType, fields)
        result := KronoxDiscordBotApiRequest("POST", "channels/" KronoxBotChannelID "/messages", KronoxBotToken, postdata, contentType)
        if !result.ok
            WriteRuntimeLog("DISCORD", "Could not send remote screenshot (HTTP " result.status ").", "WARN")
        return result.ok
    } catch Error as err {
        WriteRuntimeLog("DISCORD", "Remote screenshot failed: " err.Message, "WARN")
        return false
    } finally {
        if pBitmap
            try Gdip_DisposeImage(pBitmap)
    }
}

TestWebhook(ctrl, *) {
    global WebhookLink
    v := MainGui.Submit(false)
    if (v.WebhookLink = "") {
        ModernMsgBox("Error", "Enter a webhook URL first!", "OK", "WARNING")
        return
    }
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", v.WebhookLink, false)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send("{`"content`": `"✅ Webhook test successful! Ultimate Macro Kronox's Edition is connected.`"}")
        if (whr.Status = 200 || whr.Status = 204)
            ModernMsgBox("Success", "Webhook test successful!", "OK")
        else
            ModernMsgBox("Error", "Webhook test failed! Status: " whr.Status, "OK", "WARNING")
    } catch {
        ModernMsgBox("Error", "Failed to send test message. Check your internet and webhook URL.", "OK", "WARNING")
    }
}

SaveWebhookSettings(ctrl, *) {
    global WebhookLink, WebhookLink2, WebhookEnabled, SendCurrenciesEnabled, WebhookDebugLogs, WebhookScreenshots, WebhookTriumphScreenshots, WebhookSepatateTriumphScreenshots
    v := MainGui.Submit(false)
    WebhookLink := v.WebhookLink
    WebhookLink2 := v.WebhookLink2
    WebhookEnabled := v.WebhookEnabled
    SendCurrenciesEnabled := v.SendCurrenciesEnabled
    WebhookDebugLogs := v.WebhookDebugLogs
    WebhookScreenshots := v.WebhookScreenshots
    WebhookTriumphScreenshots := v.WebhookTriumphScreenshots
    WebhookSepatateTriumphScreenshots := v.WebhookSepatateTriumphScreenshots
    IniWrite(WebhookLink, SettingsFile, "Webhook", "Link")
    IniWrite(WebhookLink2, SettingsFile, "Webhook", "Link2")
    IniWrite(WebhookEnabled, SettingsFile, "Webhook", "Enabled")
    IniWrite(SendCurrenciesEnabled, SettingsFile, "Webhook", "SendCurrencies")
    IniWrite(WebhookDebugLogs, SettingsFile, "Webhook", "WebhookDebugLogs")
    IniWrite(WebhookScreenshots, SettingsFile, "Webhook", "WebhookScreenshots")
    IniWrite(WebhookTriumphScreenshots, SettingsFile, "Webhook", "WebhookTriumphScreenshots")
    IniWrite(WebhookSepatateTriumphScreenshots, SettingsFile, "Webhook", "WebhookSepatateTriumphScreenshots")

    MsgBox("All webhook settings have been successfully saved!", "Ultimate Macro Kronox's Edition", 0x1040)
}


NormalizeKey(keyName) {
    if (keyName = "")
        return ""

    if !RegExMatch(keyName, "^([~!#^+<>*]*)(.*)$", &Match)
        return keyName
        
    modifiers := Match[1]
    pureKey   := Match[2]

    if (StrLen(pureKey) > 1)
        return keyName
    
    res := DllCall("User32.dll\VkKeyScanW", "UShort", Ord(pureKey), "Short")
    vk := res & 0xFF
    
    if (vk = 0xFF || vk = 0)
        return keyName
    
    sc := DllCall("User32.dll\MapVirtualKeyW", "UInt", vk, "UInt", 0, "UInt")
    
    if (!sc)
        return keyName
    
    return modifiers . Format("sc{:03X}", sc)
}


SaveAllSettings(ctrl, *) {
    global ChainKey, BeatKey, CaravanKey, SwatVanKey, CancelPlacementKey, TimeScaleMode, UseTimeScale
    global TimeScaleMultiplier, VipLink, UseVipServer, AlwaysOnTop, DebugConsole
    global PotatoMode, LegacyMode, UpgradeDelay, UseRestartBtn, UsePlayAgainBtn, CheckTheMap
    global PlaceTowerKey, UpgradeTowerKey, AlignCameraKey, ChangeDJTrackKey, ChangeTargetsKey
    global SellTowerKey, DeleteTowerRecordingKey, RecordInputsKey
    global SettingsFile
    global DefaultMouseSpeed, MouseDelay, KeyDelay
    global HoloKey, RaiseDeadKey, UseRaiseDeadKey, HologramKey, RepoKey, CollectPlaytimeRewards, UpgradeTowerGKey, UpgradeTowerGBKey, UseHForUpgrade, UseNumbersForHotbar

    towerXPConfig := CollectTowerXPSettings()
    if (!IsObject(towerXPConfig))
        return
    featureConfig := CollectKronoxFeatureSettings()
    if (!IsObject(featureConfig))
        return
    if (featureConfig.evolutionEnabled) {
        towerXPConfig.enabled := true
        for entry in towerXPConfig.entries {
            if (KronoxArrayContains(StrSplit(featureConfig.evolutionTowers, ","), entry.definition.name))
                entry.tracked := true
        }
    }

    tempChainKey := SubStr(RegExReplace(ChainKeyCtrl.Value, "\s", ""), 1, 1)
    tempBeatKey := SubStr(RegExReplace(BeatKeyCtrl.Value, "\s", ""), 1, 1)
    tempCaravanKey := SubStr(RegExReplace(CaravanKeyCtrl.Value, "\s", ""), 1, 1)
    tempSwatVanKey := SubStr(RegExReplace(SwatVanKeyCtrl.Value, "\s", ""), 1, 1)
    tempRaiseDeadKey := SubStr(RegExReplace(RaiseDeadKeyCtrl.Value, "\s", ""), 1, 1)
    tempHologramKey := SubStr(RegExReplace(HologramKeyCtrl.Value, "\s", ""), 1, 1)
    tempRepoKey := SubStr(RegExReplace(RepoKeyCtrl.Value, "\s", ""), 1, 1)
    tempCancelPlacementKey := SubStr(RegExReplace(CancelPlacementKeyCtrl.Value, "\s", ""), 1, 1)
    tempUpgradeTowerGKey := SubStr(RegExReplace(UpgradeTowerGCtrl.Value, "\s", ""), 1, 1)
    tempUpgradeTowerGBKey := SubStr(RegExReplace(UpgradeTowerGBCtrl.Value, "\s", ""), 1, 1)
    
    if (tempChainKey = "")           
        tempChainKey := "C"
    if (tempBeatKey = "")            
        tempBeatKey  := "B"
    if (tempCaravanKey = "")         
        tempCaravanKey := "J"
    if (tempSwatVanKey = "")
        tempSwatVanKey := "N"
    if (tempRaiseDeadKey = "")
        tempRaiseDeadKey := "V"
    if (tempHologramKey = "")
        tempHologramKey := "K"
    if (tempRepoKey = "")
        tempRepoKey := "L"
    if (tempCancelPlacementKey = "") 
        tempCancelPlacementKey := "Q"
    if (tempUpgradeTowerGKey = "")
        tempUpgradeTowerGKey := "E"
    if (tempUpgradeTowerGBKey = "")
        tempUpgradeTowerGBKey := "Z"

    tempPlaceTowerKey := NormalizeKey(PlaceTowerKeyCtrl.Value)
    tempUpgradeTowerKey := NormalizeKey(UpgradeTowerKeyCtrl.Value)
    tempAlignCameraKey := NormalizeKey(AlignCameraKeyCtrl.Value)
    tempChangeDJTrackKey := NormalizeKey(ChangeDJTrackKeyCtrl.Value)
    tempSellTowerKey := NormalizeKey(SellTowerKeyCtrl.Value)
    tempDeleteTowerRecordingKey := NormalizeKey(DeleteTowerRecordingKeyCtrl.Value)
    tempRecordInputsKey := NormalizeKey(RecordInputsKeyCtrl.Value)
    tempHoloKey := NormalizeKey(HoloKeyCtrl.Value)
    tempUseRaiseDeadKey := NormalizeKey(UseRaiseDeadKeyCtrl.Value)
    tempChangeTargetsKey := NormalizeKey(ChangeTargetsKeyCtrl.Value)

    UsedKeys := Map()
    
    KeysToCheck := [
        {val: NormalizeKey(tempChainKey), name: "Call of Arms Ability"},
        {val: NormalizeKey(tempBeatKey), name: "Drop the Beat Ability"},
        {val: NormalizeKey(tempCaravanKey), name: "Support Caravan Ability"},
        {val: NormalizeKey(tempSwatVanKey), name: "SWAT Van Ability"},
        {val: NormalizeKey(tempRaiseDeadKey), name: "Raise the Dead Ability"},
        {val: NormalizeKey(tempHologramKey), name: "Hologram Ability"},
        {val: NormalizeKey(tempRepoKey), name: "Reposition Ability"},
        {val: NormalizeKey(tempCancelPlacementKey), name: "Cancel Placement"},
        {val: NormalizeKey(tempUpgradeTowerGKey), name: "Upgrade Tower (TDS keybind)"},
        {val: NormalizeKey(tempUpgradeTowerGBKey), name: "Upgrade Bottom Path (TDS keybind)"},
        {val: tempPlaceTowerKey, name: "Place Tower"},
        {val: tempUpgradeTowerKey, name: "Upgrade Tower"},
        {val: tempAlignCameraKey, name: "Align Camera"},
        {val: tempChangeDJTrackKey, name: "Change DJ Track"},
        {val: tempSellTowerKey, name: "Sell Tower"},
        {val: tempDeleteTowerRecordingKey, name: "Delete Tower Recording"},
        {val: tempRecordInputsKey, name: "Record Inputs"},
        {val: tempHoloKey, name: "Hologram Tower"},
        {val: tempChangeTargetsKey, name: "Change Targets"},
        {val: tempUseRaiseDeadKey, name: "Raise the Dead"}
    ]

    for item in KeysToCheck {
        if (item.val = "") {
            MsgBox("Error: Empty hotkey detected!`n`n" 
            . "The hotkey is assigned to: `"" item.name "`"`n"
            . "Please change it before saving.", "Empty Hotkey", 0x10)
            return
        }
        if IsTowerHotbarToggleKeySpec(item.val) {
            MsgBox("Error: T is reserved by TDS for switching to the consumables hotbar.`n`n"
                . "The key is assigned to: `"" item.name "`"`n"
                . "Choose a key that does not use T, including modified shortcuts such as Ctrl+T.",
                "Unsafe T Hotkey", 0x10)
            return
        }
        if UsedKeys.Has(item.val) {
            MsgBox("Error: Duplicate hotkey detected!`n`n" 
                 . "The hotkey is assigned to: `"" UsedKeys[item.val] "`"`n"
                 . "And also that hotkey is assigned to: `"" item.name "`"`n`n"
                 . "Please change it before saving.", "Duplicate Hotkey", 0x10)
            return 
        }
        UsedKeys[item.val] := item.name
    }

    ChainKey := tempChainKey
    BeatKey := tempBeatKey
    CaravanKey := tempCaravanKey
    SwatVanKey := tempSwatVanKey
    RaiseDeadKey := tempRaiseDeadKey
    HologramKey := tempHologramKey
    RepoKey := tempRepoKey
    CancelPlacementKey := tempCancelPlacementKey
    UpgradeTowerGKey := tempUpgradeTowerGKey
    UpgradeTowerGBKey := tempUpgradeTowerGBKey

    oldRecordingKeys := [PlaceTowerKey, UpgradeTowerKey, AlignCameraKey, ChangeDJTrackKey,
        SellTowerKey, DeleteTowerRecordingKey, RecordInputsKey, HoloKey, ChangeTargetsKey, UseRaiseDeadKey]

    
    PlaceTowerKey := tempPlaceTowerKey
    UpgradeTowerKey := tempUpgradeTowerKey
    AlignCameraKey := tempAlignCameraKey
    ChangeDJTrackKey := tempChangeDJTrackKey
    SellTowerKey := tempSellTowerKey
    DeleteTowerRecordingKey := tempDeleteTowerRecordingKey
    RecordInputsKey := tempRecordInputsKey
    HoloKey := tempHoloKey
    ChangeTargetsKey := tempChangeTargetsKey
    UseRaiseDeadKey := tempUseRaiseDeadKey
    RegisterRecordingHotkeys(oldRecordingKeys)

    TimeScaleMode := (TimeScaleModeCtrl.Text = "") ? "OFF" : TimeScaleModeCtrl.Text
    VipLink := VipLinkCtrl.Value
    UseVipServer := UseVipServerCtrl.Value
    AlwaysOnTop := AlwaysOnTopCtrl.Value
    DebugConsole := DebugConsoleCtrl.Value
    PotatoMode := PotatoModeCtrl.Value
    LegacyMode := LegacyModeCtrl.Value
    try enteredUpgradeDelay := Integer(UpgradeDelayCtrl.Value)
    catch Error
        enteredUpgradeDelay := 190
    UpgradeDelay := Max(50, Min(2000, enteredUpgradeDelay))
    UpgradeDelayCtrl.Value := UpgradeDelay
    UseRestartBtn := UseRestartBtnCtrl.Value
    UsePlayAgainBtn := UsePlayAgainBtnCtrl.Value
    CheckTheMap := CheckTheMapCtrl.Value
    UseNumbersForHotbar := UseNumbersForHotbarCtrl.Value
    CollectPlaytimeRewards := CollectPlaytimeRewardsCtrl.Value
    UseHForUpgrade := UseUpgradeHCtrl.Value
    
    DefaultMouseSpeed := MouseSpeedUpDown.Value
    MouseDelay := MouseDelayUpDown.Value
    KeyDelay := KeyDelayUpDown.Value
    
    IniWrite(ChainKey, SettingsFile, "Hotkeys", "Chain")
    IniWrite(BeatKey, SettingsFile, "Hotkeys", "Beat")
    IniWrite(CaravanKey, SettingsFile, "Hotkeys", "Caravan")
    IniWrite(SwatVanKey, SettingsFile, "Hotkeys", "SwatVan")
    IniWrite(CancelPlacementKey, SettingsFile, "Hotkeys", "CancelPlacement")
    IniWrite(UpgradeTowerGKey, SettingsFile, "Hotkeys", "UpgradeTower")
    IniWrite(UpgradeTowerGBKey, SettingsFile, "Hotkeys", "UpgradeBottom")
    IniWrite(RaiseDeadKey, SettingsFile, "Hotkeys", "RaiseTheDead")
    IniWrite(HologramKey, SettingsFile, "Hotkeys", "Hologram")
    IniWrite(RepoKey, SettingsFile, "Hotkeys", "Repo")
    IniWrite(TimeScaleMode, SettingsFile, "Options", "TimeScaleMode")
    IniWrite(VipLink, SettingsFile, "Options", "VipLink")
    IniWrite(UseVipServer, SettingsFile, "Options", "UseVipServer")
    IniWrite(DebugConsole, SettingsFile, "Options", "DebugConsole")
    IniWrite(PotatoMode, SettingsFile, "Options", "PotatoMode")
    IniWrite(LegacyMode, SettingsFile, "Options", "LegacyMode")
    IniWrite(UpgradeDelay, SettingsFile, "Options", "UpgradeDelay")
    IniWrite(AlwaysOnTop, SettingsFile, "Options", "AlwaysOnTop")
    IniWrite(UseRestartBtn, SettingsFile, "Options", "UseRestartBtn")
    IniWrite(UsePlayAgainBtn, SettingsFile, "Options", "UsePlayAgainBtn")
    IniWrite(CheckTheMap, SettingsFile, "Options", "CheckTheMap")
    IniWrite(UseNumbersForHotbar, SettingsFile, "Options", "UseNumbers")
    IniWrite(CollectPlaytimeRewards, SettingsFile, "Options", "CollectPlaytimeRewards")
    IniWrite(UseHForUpgrade, SettingsFile, "Options", "UseHotkeyForUpgrade")
    IniWrite(DefaultMouseSpeed, SettingsFile, "Options", "DefaultMouseSpeed")
    IniWrite(MouseDelay, SettingsFile, "Options", "MouseDelay")
    IniWrite(KeyDelay, SettingsFile, "Options", "KeyDelay")

    IniWrite(PlaceTowerKey, SettingsFile, "RecordingHotkeys", "PlaceTowerKey")
    IniWrite(UpgradeTowerKey, SettingsFile, "RecordingHotkeys", "UpgradeTowerKey")
    IniWrite(AlignCameraKey, SettingsFile, "RecordingHotkeys", "AlignCameraKey")
    IniWrite(ChangeDJTrackKey, SettingsFile, "RecordingHotkeys", "ChangeDJTrackKey")
    IniWrite(SellTowerKey, SettingsFile, "RecordingHotkeys", "SellTowerKey")
    IniWrite(DeleteTowerRecordingKey, SettingsFile, "RecordingHotkeys", "DeleteTowerRecordingKey")
    IniWrite(RecordInputsKey, SettingsFile, "RecordingHotkeys", "RecordInputsKey")
    IniWrite(ChangeTargetsKey, SettingsFile, "RecordingHotkeys", "ChangeTargetsKey")
    IniWrite(UseRaiseDeadKey, SettingsFile, "RecordingHotkeys", "RaiseDeadKey")
    IniWrite(HoloKey, SettingsFile, "RecordingHotkeys", "HoloKey")

    PersistTowerXPSettings(towerXPConfig)
    PersistKronoxFeatureSettings(featureConfig, towerXPConfig)

    if (TimeScaleMode = "1.5x") {
        UseTimeScale := true
        TimeScaleMultiplier := 1.5
    } else if (TimeScaleMode = "2x") {
        UseTimeScale := true
        TimeScaleMultiplier := 2
    } else {
        UseTimeScale := false
        TimeScaleMultiplier := 1
    }

    if (DebugConsole = "1" || DebugConsole = 1) {
        ShowDebugConsole()
    } else {
        HideDebugConsole()
    }

    if (AlwaysOnTop = 1) {
        MainGui.Opt("+AlwaysOnTop")
    } else {
        MainGui.Opt("-AlwaysOnTop")
    }
    
    SetDefaultMouseSpeed(DefaultMouseSpeed)
    SetMouseDelay(MouseDelay)
    SetKeyDelay(KeyDelay)

    MsgBox("All settings have been successfully saved!", "Ultimate Macro Kronox's Edition", 0x1040)
}

SaveAllSettingsMULTIPLAYER(ctrl, *) {
    global HostName, PartyMembersStr, MultiplayerEnabled, PlayerRole, LeaveCondition
    global SettingsFile

    s := MainGui.Submit(false)

    HostName := Trim(Tab3_HostNm_EDIT.Value)
    PartyMembersStr := RegExReplace(Tab3_PartyMemb_Edit.Value, "\s*,\s*", ",")
    MultiplayerEnabled := MultiplayerEnabledTGL.Value
    PlayerRole := (s.PlayerRole == 2) ? "Member" : "Host"
    LeaveCondition := (s.LeaveCondition == 1) ? "All" : "Any"

    IniWrite(HostName, SettingsFile, "Multiplayer", "HostName")
    IniWrite(PartyMembersStr, SettingsFile, "Multiplayer", "PartyMembers")
    IniWrite(MultiplayerEnabled, SettingsFile, "Multiplayer", "MultiplayerEnabled")
    IniWrite(PlayerRole, SettingsFile, "Multiplayer", "PlayerRole")
    IniWrite(LeaveCondition, SettingsFile, "Multiplayer", "LeaveCondition")

    global PartyMembers := IniRead(SettingsFile, "Multiplayer", "PartyMembers", "someone, someone...")
    global PlayerRole := IniRead(SettingsFile, "Multiplayer", "PlayerRole", "Host")
    global HostName := IniRead(SettingsFile, "Multiplayer", "HostName", "...")
    global LeaveCondition := IniRead(SettingsFile, "Multiplayer", "LeaveCondition", "Any")
    global MultiplayerEnabled := IniRead(SettingsFile, "Multiplayer", "MultiplayerEnabled", 0)

    MsgBox("Multiplayer settings saved!", "Success", 0x1040)
}


CheckVipLink(ctrl, *) {
    
    str := Trim(VipLinkCtrl.Value)
    
    if (RegExMatch(str, "i)roblox\.com\/(?:[a-z]{2}\/)?games\/3260590327\/[^\/]*\?privateServerLinkCode=(?<code>[a-z0-9]{32})", &m)) {
        UseVipServerCtrl.Value := 1
        return
    }
    if (RegExMatch(str, "i)roblox\.com\/share\?code=(?<code>[a-f0-9]{32})", &m)) {
        try {
            wr := ComObject("WinHttp.WinHttpRequest.5.1")
            wr.Open("GET", "https://www.roblox.com/share?code=" m["code"] "&type=Server", true)
            wr.Send()
            if (wr.WaitForResponse(3) && wr.Status = 200 && InStr(wr.ResponseText, "3260590327")) {
                return
            }
        } catch Error {
            
        }
    }
    UseVipServerCtrl.Value := 0
}

CheckWebhookLink(ctrl, *) {
    v := MainGui.Submit(false)
    link := v.WebhookLink
    if (link = "" || (!InStr(link, "discord.com/api/webhooks/") && !InStr(link, "discordapp.com/api/webhooks/"))) {
        WebhookEnabledCtrl.Value   := 0
        return
    }
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", link, false)
        whr.SetTimeouts(3000, 3000, 4000, 4000)
        whr.Send()
        WebhookEnabledCtrl.Enabled := (whr.Status = 200)
        if (whr.Status != 200)
            WebhookEnabledCtrl.Value := 0
    } catch {
        WebhookEnabledCtrl.Value := 0
    }
}

EnableWebhookLink2(*) {
    v := MainGui.Submit(false)
    toggle := v.WebhookSepatateTriumphScreenshots
    if toggle = 1 {
        WebhookLinkCtrl2.Visible := true
    } else {
        WebhookLinkCtrl2.Visible := false
    }
}

CheckWebhookLink2(ctrl, *) {
    v := MainGui.Submit(false)
    link := v.WebhookLink2
    if (link = "" || (!InStr(link, "discord.com/api/webhooks/") && !InStr(link, "discordapp.com/api/webhooks/"))) {
        WebhookSepatateTriumphScreenshotsCtrl.Value := 0
        return
    }
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", link, false)
        whr.Send()
        WebhookSepatateTriumphScreenshotsCtrl.Enabled := (whr.Status = 200)
        if (whr.Status != 200)
            WebhookSepatateTriumphScreenshotsCtrl.Value := 0
    } catch {
        WebhookSepatateTriumphScreenshotsCtrl.Value := 0
    }
}


ShowFAQ(*) {
    ModernMsgBox("FAQ",
        "[SCREEN AND SYSTEM SETTINGS]`n" .
        "- Screen Resolution: Works strictly in 1920x1080.`n" .
        "- Windows Scale: Must be set to 100%.`n" .
        "- Taskbar: Must be visible.`n`n" .
        "[ROBLOX AND GAME SETTINGS]`n" .
        "- UI Scale: Set to Large.`n" .
        "- Screen Shake: Must be DISABLED.`n" .
        "- Roblox Chat: Close the chat before starting the macro.`n" .
        "- Set 'Prefer Vertical Upgrades' to Disabled.`n" .
        "- Fonts: Do not use custom fonts.`n`n" .
        "[COMMANDER ISSUES]`n" .
        "- Auto Chain: Enter 'Commander1', 'Commander2', etc., when placing them.", "OK")
}
HelpChain(*) {
    ModernMsgBox("Info", "Configure hotkey for Commander's 'Call of Arms'.", "OK")
}
HelpBeat(*) {
    ModernMsgBox("Info", "Configure hotkey for DJ's 'Drop The Beat'.", "OK")
}
HelpCaravan(*) {
    ModernMsgBox("Info", "Configure hotkey for the 'Support Caravan'.", "OK")
}
HelpCancelPlacement(*) {
    ModernMsgBox("Info", "Configure hotkey for the 'Cancel Placement'.", "OK")
}
HelpTimeScale(*) {
    ModernMsgBox("Timescale Info", "1.5x — more stable and recommended for most cases.`n2x — requires special strategies but is much more effective.`n`nThis will automatically turn off if you run out of timescale tickets.", "OK")
}
HelpPotatoMode(*) {
    ModernMsgBox("Info", "Turn this on if your macro acts inconsistently or if you have lags.", "OK")
}
HelpSendCurrencies(*) {
    ModernMsgBox("Info", "If you enable the 'Send currencies' toggle, the macro will send you information about your coins, gems, total matches, triumphs, and losses.`n`nMay be buggy.", "OK")
}
HelpRestartBtn(*) {
    ModernMsgBox("Info", "If this setting is ON, the macro will use the restart button when you lose.`n`nIt's recommended to turn it OFF if you are using a win strategy and your macro sometimes appears on the wrong map.", "OK")
}
HelpPlayAgainBtn(*) {
    ModernMsgBox("Info", "If this setting is ON, the macro will use the play again button when you win.", "OK")
}
HelpAutoCameraCorrection(*) {
    ModernMsgBox("Info", "The macro will use tds keybind when upgrading the tower.`n`nIt's recommended to turn it ON.", "OK")
}
HelpBrawler(*) {
    ModernMsgBox("Info", "To record brawler reposition, press CTRL+your keybind", "OK")
}
HelpCheckTheMap(*) {
    ModernMsgBox("Info", "When you join the map, the macro will check is it in the correct map or not. If no, it reloads.`n`nIt's recommended to turn it ON.", "OK")
}


LoadStrategyFile(file) {
    global Towers, RecordedSteps, gamemap, difficulty, requiredTowers, autoChain, autoCaravan
    global autoDropTheBeat, AutoSkip, AutoSkipStopWave, AbilitySpam, MoveEnabled, MoveDirection, MoveDuration
    global AdvancedAutoSkip, AdvancedSkipWaves, AdvancedSkipWaveSet
    global StrategyHotbarSlotMap, StrategyHotbarRemapSummary
    global modifiers, Commander, StrategyWidth, StrategyHeight
    global CloneFailurePolicy, EngineerCloneMaxAttempts
    global AbstractTowerSlots, AbstractTowerSlot, AbstractPlacementMax, AbstractPlacementLimit

    Towers := Map()
    RecordedSteps := []
    DeleteAllIndicators()

    gamemap := IniRead(file, "Settings", "map", "")
    difficulty := IniRead(file, "Settings", "difficulty", "")
    requiredTowers  := IniRead(file, "Settings", "requiredTowers",  "")
    recordedTowersSetting := IniRead(file, "Settings", "recordedTowers", requiredTowers)
    arrangedTowersSetting := IniRead(file, "Settings", "arrangedTowers", "")
    StrategyHotbarSlotMap := Map()
    StrategyHotbarRemapSummary := ""
    if EditorSettingIsOn(IniRead(file, "Settings", "hotbarRemap", "OFF")) {
        if (Trim(arrangedTowersSetting) = "") {
            legacyRemap := BuildTowerHotbarRemap(recordedTowersSetting, requiredTowers)
            arrangedTowersSetting := legacyRemap.valid ? requiredTowers : recordedTowersSetting
        }
        hotbarRemap := BuildTowerHotbarRemap(recordedTowersSetting, arrangedTowersSetting)
        if (hotbarRemap.valid && hotbarRemap.changed) {
            StrategyHotbarSlotMap := hotbarRemap.slots
            StrategyHotbarRemapSummary := hotbarRemap.summary
        } else if (!hotbarRemap.valid) {
            LogToConsole("Hotbar swap disabled: " hotbarRemap.message, true)
        }
    }
    LoadAbstractPlacementProfile(file)
    autoChain := IniRead(file, "Settings", "autoChain", "OFF")
    autoCaravan := IniRead(file, "Settings", "autoCaravan", "OFF")
    autoDropTheBeat := IniRead(file, "Settings", "autoDropTheBeat", "OFF")
    AutoSkip := IniRead(file, "Settings", "autoSkip", "ON")
    AdvancedAutoSkip := EditorSettingIsOn(IniRead(file, "Settings", "advancedAutoSkip", "OFF")) ? "ON" : "OFF"
    AdvancedSkipWaves := IniRead(file, "Settings", "advancedSkipWaves", "")
    AdvancedSkipWaveSet := Map()
    if (AdvancedAutoSkip = "ON") {
        parsedAdvancedWaves := ParseAdvancedWaveSelection(AdvancedSkipWaves)
        if (parsedAdvancedWaves.ok) {
            AdvancedSkipWaves := parsedAdvancedWaves.canonical
            AdvancedSkipWaveSet := parsedAdvancedWaves.waves
            ; Advanced mode owns the skip button and must never run beside normal Auto Skip.
            AutoSkip := "OFF"
        } else {
            AdvancedAutoSkip := "OFF"
            LogToConsole("Advanced Wave Skip disabled: " parsedAdvancedWaves.message, true)
        }
    }
    autoSkipStopSetting := IniRead(file, "Settings", "autoSkipStopWave", "0")
    AutoSkipStopWave := IsNumber(autoSkipStopSetting) ? Max(0, Integer(autoSkipStopSetting)) : 0
    AbilitySpam := IniRead(file, "Settings", "abilitySpam", "ON")
    modifiers := IniRead(file, "Settings", "modifiers", "")
    ; Remote overrides deliberately live only in state.ini. They are reapplied
    ; after every strategy load so they survive safe reloads without ever
    ; changing the source .strat file or the user's saved Settings choice.
    KronoxApplyRemoteRunOverrides()
    CloneFailurePolicy := IniRead(file, "Settings", "cloneFailurePolicy", "")
    cloneAttemptsSetting := IniRead(file, "Settings", "engineerCloneMaxAttempts", "3")
    EngineerCloneMaxAttempts := IsNumber(cloneAttemptsSetting) ? Max(1, Integer(cloneAttemptsSetting)) : 3

    moveDown := IniRead(file, "Settings", "moveDown", "false")
    tempEnabled := IniRead(file, "Settings", "moveEnabled",   "")
    tempDir := IniRead(file, "Settings", "moveDirection", "")
    tempDur := IniRead(file, "Settings", "moveDuration",  "")

    if (tempEnabled != "") {
        MoveEnabled := (tempEnabled = "true" || tempEnabled = "1") ? true : false
        MoveDirection := (tempDir != "" && (tempDir = "W" || tempDir = "A" || tempDir = "S" || tempDir = "D")) ? tempDir : "W"
        MoveDuration := IsNumber(tempDur) ? Integer(tempDur) : 750
    } else {
        if (moveDown = "true") {
            MoveEnabled := true, MoveDirection := "S", MoveDuration := 750
        } else {
            MoveEnabled := false, MoveDirection := "W", MoveDuration := 750
        }
    }

    Commander := false

    StrategyWidth  := Integer(IniRead(file, "DO NOT EDIT", "width",  "1920"))
    StrategyHeight := Integer(IniRead(file, "DO NOT EDIT", "height", "1090"))

    inSteps := false
    Loop Read, file {
        line := Trim(A_LoopReadLine)
        if (line ~= "i)^\[Settings\]") { 
            inSteps := false
        }
        if (line ~= "i)^\[Steps\]")    { 
            inSteps := true
        }
        if (inSteps && line != "") {
            RecordedSteps.Push(line)
        }
    }

    
    for i, step in RecordedSteps {
        if RegExMatch(step, "i)SpawnTower\s*\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*(.*?)\s*\)", &m) {
            towerID := Trim(m[1])
            Towers[towerID] := {x: 0, y: 0, slot: 0, level: 0, path: 0, pathLevel: 0, target: "First Enemy"}
        }
        if RegExMatch(step, "i)UpgradeTower\s*\(\s*([^,]+?)\s*(?:,\s*(?:false|true)\s*)?(?:,\s*\d+\s*)?(?:,\s*(\d+)\s*)?(?:,\s*(\d+)\s*)?\s*\)", &m) {
            tid := Trim(m[1])
            if (Towers.Has(tid) && m[2] != "") {
                Towers[tid].path := m[2]
                Towers[tid].pathLevel := (m[3] != "") ? m[3] : 4
            }
        }
    }
}

PrepareEvolutionQueueForRun() {
    global SettingsFile, StateFile, requiredTowers, AbstractTowerSlots

    result := {enabled: false, valid: false, pending: false, complete: false, text: "", message: ""}
    if (!KronoxFeatureBool(IniRead(SettingsFile, "EvolutionQueue", "Enabled", 0)))
        return result
    result.enabled := true
    activeSlots := ActiveAbstractTowerSlots()
    if (activeSlots.Length = 0) {
        result.message := "Evolution Queue requires a strategy with at least one active Abstract slot."
        return result
    }
    loadout := KronoxEvolutionBuildLoadout(requiredTowers, activeSlots, SettingsFile, StateFile)
    result.complete := loadout.prepared.complete
    result.valid := loadout.valid
    result.text := loadout.text
    result.message := loadout.message
    result.pending := loadout.prepared.changed || KronoxFeatureBool(IniRead(StateFile, "State", "EvolutionQueuePendingEquip", 0))
    return result
}

DetectTDSVersion() {
    global SettingsFile
    versionOverride := Trim(IniRead(SettingsFile, "UpdateCanary", "VersionOverride", ""))
    if (versionOverride != "")
        return KronoxExtractTDSVersion(versionOverride ~= "i)^v" ? versionOverride : "v" versionOverride)

    hwnd := GetRobloxHWND()
    if (!hwnd)
        return ""
    getRobloxPos(,, &w, &h, hwnd)
    if (w < 300 || h < 200)
        return ""
    regionX := Round(w * 0.72)
    regionY := Round(h * 0.82)
    regionW := Max(120, w - regionX)
    regionH := Max(80, h - regionY)
    try {
        hBitmap := OCR.CreateHBitmap(regionX, regionY, regionW, regionH,
            {hWnd: hwnd, onlyClientArea: 1, mode: 2}, 3)
        text := OCR.FromBitmap(hBitmap, {lang: "en-US", grayscale: true}).Text
        return KronoxExtractTDSVersion(text)
    } catch Error as err {
        WriteRuntimeLog("CANARY", "TDS version OCR failed: " err.Message, "WARN")
        return ""
    }
}

PrepareUpdateCanary() {
    global SettingsFile, StateFile
    strategyPath := IniRead(StateFile, "State", "Strategy", "")
    fingerprint := GetStrategyFingerprint(strategyPath)
    version := DetectTDSVersion()
    canary := KronoxCanaryPrepare(SettingsFile, StateFile, fingerprint, version)
    if (canary.message != "")
        LogToConsole("Update canary: " canary.message, canary.active, false)
    if (canary.changed)
        SendToWebhookInstant("TDS UPDATE CANARY`n" canary.message "`nThe first run will stop on a loss or watchdog recovery.", 15150117, false)
    return canary
}

RunStrategy(stratFile := "", skipRestart := false, equip := false) {
    global RunningStrategy, difficulty, MoveEnabled, MoveDirection, MoveDuration
    global unfocusX, unfocusY, UseTimeScale, TimeScaleMultiplier, TimeScaleMode
    global SettingsFile, requiredTowers, modifiers, LastOpenedTowerID
    global LastSkipCheck, SKIP_CHECK_INTERVAL, AutorunStartTime, StateFile
    global WebhookEnabled, CurrentStratStartTime, CurrentRunCount, gamemap, AbstractTowerSlots, AbstractTowerSlot
    global StrategyHotbarRemapSummary, EvolutionQueueAutoEquip, HotbarSafetyMisses, HotbarSafetyRecoveryActive, TimescaleActive

    if (RunningStrategy != true)
        return

    if KronoxConsumeRemoteSafeStop() {
        KronoxBotSendChannel("Remote safe stop reached a run boundary. The macro is stopping before a new match begins.")
        SetTimer(KronoxRemoteStop, -10)
        return
    }

    ; A new match has not activated its ticket yet, even if the prior match did.
    TimescaleActive := false

    If (!skiprestart)
    	isDisconnected()

    switched := false
    remoteSwitchPath := ""
    if ConsumeKronoxRemoteStrategySwitch(&remoteSwitchPath) {
        LoadStrategyFile(remoteSwitchPath)
        stratName := remoteSwitchPath
        switched := true
    } else if (Integer(IniRead(StateFile, "Remote", "ForceEquip", 0)) = 1) {
        stratName := IniRead(StateFile, "State", "Strategy", "")
        switched := true
    }
    if (RotateStrategies && !switched) {
        SwapAmount := Integer(IniRead(SettingsFile, "Options", "SwapAmount", 4))
        SwapUnit := IniRead(SettingsFile, "Options", "SwapUnit", "Runs")
        
        timeToSwitch := false
        if (SwapUnit = "Minutes") {
            if (A_TickCount - CurrentStratStartTime > SwapAmount * 60000)
                timeToSwitch := true
        } else {
            if (CurrentRunCount >= SwapAmount)
                timeToSwitch := true
        }
        
        if (timeToSwitch) {
            SwitchToNextStrategy(&stratName)
            switched := true

            Sleep(100)
        }
    }

    CurrentRunCount++
    IniWrite(CurrentRunCount, StateFile, "State", "CurrentRunCount")
    SetMacroPhase("strategy-preparing", difficulty, 180000)

    KillSubmacros()
    startWatchdog()

    LastOpenedTowerID := ""

    LogToConsole("Starting strategy... Press F2 to STOP!!!")
    LogToConsole("Map = " gamemap)
    LogToConsole("Mode = " difficulty)
    LogToConsole("Timescale = " TimeScaleMode)
    LogToConsole("Required Towers: " requiredTowers)
    if (AbstractTowerSlots.Length > 0)
        LogToConsole("Abstract XP towers: active slots " AbstractTowerSlotsToText(ActiveAbstractTowerSlots()) " of " AbstractTowerSlots.Length " configured (Auto Equip protected)")
    if (StrategyHotbarRemapSummary != "")
        LogToConsole("Hotbar swap: " StrategyHotbarRemapSummary)
    if (AdvancedAutoSkip = "ON")
        LogToConsole("Advanced Wave Skip: " AdvancedSkipWaves)
    else
        LogToConsole("Auto Skip: " AutoSkip)
    if (modifiers != "")
        LogToConsole("Modifiers: " modifiers)

    if (switched) {
        IniDelete(StateFile, "Remote", "ForceEquip")
        time := FormatTime(, "HH:mm:ss")
        SplitPath(stratName, &fileName)
        startInfo := "[" time "] Switched strategy to: " fileName "`n"
        startInfo .= "Map = " gamemap "`nMode = " difficulty "`nTimescale = " TimeScaleMode "`nRequired Towers: " requiredTowers
        if (modifiers != "")
            startInfo .= "`nModifiers: " modifiers
        SendToWebhookInstant(startInfo,, flush := false)
    }

    checkStart := IniRead(StateFile, "State", "StartTime", 0)
    if (checkStart = 0) {
        IniWrite(A_TickCount, StateFile, "State", "StartTime")
        AutorunStartTime := A_TickCount
    } else {
        AutorunStartTime := checkStart
    }

    if (!switched) {
        evolutionRun := PrepareEvolutionQueueForRun()
        if (evolutionRun.enabled && !evolutionRun.valid && !evolutionRun.complete) {
            LogToConsole("Evolution Queue stopped: " evolutionRun.message, true, false)
            IniWrite(0, StateFile, "State", "Running")
            return
        }
        shouldEquipEvolution := evolutionRun.enabled && evolutionRun.valid
            && KronoxFeatureBool(IniRead(SettingsFile, "EvolutionQueue", "AutoEquip", EvolutionQueueAutoEquip))
            && evolutionRun.pending

        if (shouldEquipEvolution) {
            LogToConsole("Evolution Queue equipping: " evolutionRun.text, true, false)
            CloseRoblox()
            RunRoblox()
            EquipTowers(evolutionRun.text, true)
            IniWrite(0, StateFile, "State", "EvolutionQueuePendingEquip")
            JoinGame()
        } else if (!skipRestart) {
            CheckRestart()
        } else {
            CloseRoblox()
            RunRoblox()
            if (equip || shouldEquipEvolution) {
                EquipTowers(shouldEquipEvolution ? evolutionRun.text : RequiredTowers, shouldEquipEvolution)
            }
            JoinGame()
        }
    } else {
        CloseRoblox()
        RunRoblox()
        EquipTowers(RequiredTowers)

        JoinGame()
    }

    if (readyX = 0 && readyY = 0) {
        waitReady()
    }

    PrepareUpdateCanary()

    if (!IsRestarting) {
        if (!InArray(SpecialMaps, gamemap)) {
            AlignCamera()
        }
        CheckTheMapF()
    }

    activateTimescale()

    ClickReady()
    
    PlayStrategy()
}

PlayStrategy() {
    global canUseAbility, MultiplayerEnabled, StateFile, gamemap, InputAutomationSuspended
    global CloneFailurePolicy, EngineerCloneMaxAttempts
    global AutoSkipSuccessfulCount, AutoSkipLastDetectedWave, AutoSkipBlockLogged, AdvancedLastSkippedWave

    activeRunId := BeginTrackedRun()
    ResumeAutomationInput("strategy-playback")
    HotbarSafetyMisses := 0
    HotbarSafetyRecoveryActive := false
    SetMacroPhase("strategy-playback", "recorded-steps", 0)
    IniWrite(A_TickCount, StateFile, "State", "TimeWhenStartedPlaying")
    AutoSkipSuccessfulCount := 0
    AutoSkipLastDetectedWave := 0
    AutoSkipBlockLogged := false
    AdvancedLastSkippedWave := 0
    SetTimer(UseAbilities, 750)
    if (MultiplayerEnabled) {
        SetTimer(checkCondition, 15000)
    }

    executionSteps := RecordedSteps.Clone()
    useDeferredCloneQueue := (CloneFailurePolicy = "deferEngineerRequireJuggernaut")

    i := 1
    while (i <= executionSteps.Length) {
        step := executionSteps[i]
        TouchMacroProgress("step " i "/" executionSteps.Length)
        isMacroStep := RegExMatch(step, "i)^(Click|Send|Sleep)\s*\(")
        profileIndex := i
        profileStart := KronoxProfilerStepStart(profileIndex, step)

        if (useDeferredCloneQueue && RegExMatch(step, "i)^CloneTower\s*\(\s*([^,]+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d+)\s*)?\)$", &cloneMatch)) {
            cloneTowerId := Trim(cloneMatch[1])
            cloneX := Integer(cloneMatch[2])
            cloneY := Integer(cloneMatch[3])
            cloneWait := (cloneMatch[4] != "") ? Integer(cloneMatch[4]) : 0

            if RegExMatch(cloneTowerId, "i)^Engineer") {
                cloneSucceeded := CloneTower(cloneTowerId, cloneX, cloneY, cloneWait, EngineerCloneMaxAttempts)
                if (!cloneSucceeded) {
                    executionSteps.Push(step)
                    KronoxProfilerRetry(step, "Engineer clone deferred after " EngineerCloneMaxAttempts " attempts")
                    LogToConsole("Deferred Engineer clone moved to the back of the strategy queue: " step, true)
                }
                KronoxProfilerStepEnd(profileIndex, step, profileStart, cloneSucceeded ? "OK" : "DEFERRED")
            } else if RegExMatch(cloneTowerId, "i)^Juggernaut") {
                Loop {
                    if CloneTower(cloneTowerId, cloneX, cloneY, cloneWait, 0) {
                        break
                    }
                    KronoxProfilerRetry(step, "Required Juggernaut clone retry")
                    LogToConsole("Required Juggernaut clone did not complete; retrying in 5 seconds...", true)
                    Sleep(5000)
                }
                KronoxProfilerStepEnd(profileIndex, step, profileStart)
            } else {
                try {
                    ExecuteStep(step)
                    KronoxProfilerStepEnd(profileIndex, step, profileStart)
                } catch Error as err {
                    KronoxProfilerStepEnd(profileIndex, step, profileStart, "ERROR", err.Message)
                    LogToConsole("ERROR executing step " profileIndex ": " step " '" err.Message "' ")
                }
            }

            i++
            continue
        }

        if RegExMatch(step, "i)UpgradeTower\s*\(\s*([^,]+?)\s*(?:,\s*(false|true)\s*)?(?:,\s*(\d+)\s*)?(?:,\s*(\d+)\s*)?(?:,\s*(\d+)\s*)?\s*\)", &m) {
            currentID    := Trim(m[1])
            countUpgrades := (m[3] != "") ? Integer(m[3]) : 1
            currentPath   := (m[4] != "") ? Integer(m[4]) : 0
            currentpathLevel := (m[5] != "") ? Integer(m[5]) : 4

            lookAhead := i + 1
            while (lookAhead <= executionSteps.Length) {
                nextStep := executionSteps[lookAhead]
                if RegExMatch(nextStep, "i)UpgradeTower\s*\(\s*" currentID "\s*(?:,\s*(?:false|true)\s*)?(?:,\s*(\d+)\s*)?(?:,\s*(\d+)\s*)?(?:,\s*(\d+)\s*)?\s*\)", &mN) {
                    countUpgrades += (mN[1] != "") ? Integer(mN[1]) : 1
                    lookAhead++
                } else {
                    break
                }
            }

            success := UpgradeTower(currentID, false, countUpgrades, currentPath, currentpathLevel)
            KronoxProfilerStepEnd(profileIndex, step, profileStart, success ? "OK" : "FAILED",
                "Grouped upgrades: " countUpgrades)
            i := success ? lookAhead : i + 1
        } else if RegExMatch(step, "i)SetDJTrack\s*\(\s*([^\s,)]+)\s*\)", &t) {
            SetDJTrack(t[1])
            KronoxProfilerStepEnd(profileIndex, step, profileStart)
            i++
        } else if RegExMatch(step, "i)SpawnTower\s*\(.*\)") {
            try {
                ExecuteStep(step)
                KronoxProfilerStepEnd(profileIndex, step, profileStart)
            } catch Error as err {
                KronoxProfilerStepEnd(profileIndex, step, profileStart, "ERROR", err.Message)
                LogToConsole("ERROR executing step " profileIndex ": " step " '" err.Message "' ")
            }
            i++
        } else {
            try {
                ExecuteStep(step)
                KronoxProfilerStepEnd(profileIndex, step, profileStart)
            } catch Error as e { 
                KronoxProfilerStepEnd(profileIndex, step, profileStart, "ERROR", e.Message)
                LogToConsole("ERROR executing step " . i . ": " . step . " '" . e.Message . "' ")
            }
            i++
        }
    }

    Click(ScaleX(unfocusX), ScaleY(unfocusY))
    LogToConsole("All strategy steps completed, entering maintenance loop...")
    SetMacroPhase("strategy-maintenance", gamemap, 0)
    Loop {
        if (InputAutomationSuspended)
            return
        canUseAbility := true
        LastOpenedTowerID := ""
        Sleep 2000
    }
}

ExecuteStep(step) {
    global Commander, unfocusX, unfocusY
    step := RegExReplace(step, "\s*;.*$", "")
    step := Trim(step)
    if (step = "")
        return
    if RegExMatch(step, "i)SpawnTower\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d)\s*,\s*(.*?)\s*\)", &m) {
        SpawnTower(m[1], m[2], ResolveStrategyHotbarSlot(m[3]), Trim(m[4]))
        return
    }
    if RegExMatch(step, "i)UpgradeTower\s*\(\s*([^,]+?)\s*(?:,\s*(false|true)\s*)?(?:,\s*(\d+)\s*)?(?:,\s*(\d+)\s*)?(?:,\s*(\d+)\s*)?\s*\)", &m) {
        UpgradeTower(Trim(m[1]), (m[2]="true"), (m[3]!="") ? Integer(m[3]) : 1, (m[4]!="") ? Integer(m[4]) : 0, (m[5]!="") ? Integer(m[5]) : 4)
        return
    }
    if RegExMatch(step, "i)^ToggleAutoskip\s*\(\s*\)$") {
        ToggleAutoskip()
        return
    }
    if RegExMatch(step, "i)^ChangeTargets\s*\(\s*([^,]+?)\s*,\s*([^)]+?)\s*\)$", &m) {
        ChangeTargets(Trim(m[1]), Trim(m[2], ' "'))
        return
    }
    
    if RegExMatch(step, "i)CloneTower\s*\(\s*([^,]+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)", &m) {
        CloneTower(Trim(m[1]), Integer(m[2]), Integer(m[3]), Integer(m[4]))
        return
    }

    if RegExMatch(step, "i)CloneTower\s*\(\s*([^,]+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)", &m) {
        CloneTower(Trim(m[1]), Integer(m[2]), Integer(m[3]), 0)
        return
    }
    if RegExMatch(step, "i)ActivateSwatVan\s*\(\s*(\d+)\s*\)", &m) {
        ActivateSwatVan(Integer(m[1]))
        return
    }
    if RegExMatch(step, "i)ActivateSwatVan\s*\(\s*\)", &m) {
        ActivateSwatVan(0)
        return
    }
    if RegExMatch(step, "i)ActivateRaiseTheDead\s*\(\s*(\d+)\s*\)", &m) {
        ActivateRaiseTheDead(Integer(m[1]))
        return
    }
    if RegExMatch(step, "i)ActivateRaiseTheDead\s*\(\s*\)", &m) {
        ActivateRaiseTheDead(0)
        return
    }

    if RegExMatch(step, "i)BrawlerReposition\s*\(\s*([^,]+?)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)", &m) {
        BrawlerReposition(Trim(m[1]), Integer(m[2]), Integer(m[3]))
        return
    }

    if RegExMatch(step, "i)SetDJTrack\s*\(\s*(.+?)\s*\)", &m) {
        track := Trim(m[1], ' "')
        if (track != "")
            SetDJTrack(track)
        return
    }
    if RegExMatch(step, "i)^Click\s*\(\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(.+?))?\s*\)$", &m) {
        button := InStr(m[3], "Right") ? "Right" : "Left"
        Click(ScaleX(m[1]) " " ScaleY(m[2]) " " button)
        VerifyTowerHotbarAfterRiskyClick("recorded raw click step")
        return
    }
    if RegExMatch(step, 'i)^Send\s*\(\s*"([^"]+)"\s*,\s*hold:=(\d+)\s*\)$', &m) {
        if IsTowerHotbarToggleKeySpec(m[1]) {
            WriteRuntimeLog("HOTBAR", "Blocked recorded strategy input '" m[1] "' because it can switch to consumables.", "ERROR")
            LogToConsole("Recorded T input blocked by strict hotbar safety.", true, false)
            return
        }
        SendEvent("{" m[1] " down}")
        HyperSleep(Integer(m[2]))
        SendEvent("{" m[1] " up}")
        return
    }
    if RegExMatch(step, "i)^Sleep\s*\(\s*(\d+)\s*\)$", &m) {
        Sleep(Integer(m[1]))
        return
    }
    if RegExMatch(step, 'i)^UseConsumable\s*\(\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*"([^"]+)")?\s*\)$', &m) {
        UseBudgetedConsumable(Integer(m[1]), Integer(m[2]), m[3] != "" ? m[3] : "Consumable")
        return
    }
    if RegExMatch(step, "i)Commander\s*:=\s*true") {
        Commander := true
        return
    }
    if RegExMatch(step, "i)SellTower\s*\(\s*([^)]+?)\s*\)", &m) {
        SellTower(Trim(m[1]))
        return
    }
}

UseBudgetedConsumable(x, y, name := "Consumable") {
    WriteRuntimeLog("HOTBAR", "Blocked automated consumable step '" name "'.", "ERROR")
    LogToConsole("Consumable step blocked by strict hotbar safety: " name ".", true, false)
    return false
}

LowerGraphics() {
    ActivateRoblox()
    SendEvent("{SC02A down}")
    Loop 10 {
        SendEvent("{SC044}")
        Sleep(20)
    }
    SendEvent("{SC02A up}")
}

EquipTowers(towers, allowAbstractQueue := false) {
    global AbstractTowerSlots, AbstractTowerSlot, LegacyMode

    if (LegacyMode = 1 || LegacyMode = "1") {
        LogToConsole("Auto Equip skipped: Legacy image mode does not support this advanced detection path.", true, false)
        return false
    }

    if (AbstractTowerSlots.Length > 0 && !allowAbstractQueue) {
        LogToConsole("Auto Equip skipped: abstract hotbar slots " AbstractTowerSlotsToText(AbstractTowerSlots) " must keep the player's chosen XP towers equipped.", true, false)
        return true
    }

    getRobloxPos(,,&rw,&rh)

    savedCloseX := 0
    savedCloseY := 0

    closeChat()
    Sleep(600)

    StartTime := A_TickCount
    Loop {
        W := Round(rw * 0.3)
        H := rh - 0

        resItems := AdvImageSearch("Resources\items.png", 0, 0, W, H)
        if (resItems.status == "success" && resItems.score > 0.56) {
            fx := resItems.x
            fy := resItems.y
            MouseMove(fx, fy+ScaleY(7), A_DefaultMouseSpeed+1)
            Sleep(100)
            MouseClick()
            break
        } 
        if (A_TickCount - StartTime > 6000) {
            break
        }
        Sleep(500)
    }

    Sleep(800)

    openedMenu := false
    StartTime := A_TickCount
    Loop {
        X1 := Round(rw * 0.2)
        Y1 := 0
        W := Round(rw * 1) - X1
        H := Round(rh * 0.4) - Y1
        resclose := AdvImageSearch("Resources\close_items.png", X1, Y1, W, H)

        If (resclose.status = "success" && resclose.score >= 0.85) {
            openedMenu := true
            savedCloseX := resclose.x
            savedCloseY := resclose.y
            break
        } 
        if (A_TickCount - StartTime > 6000)
            break
        Sleep(500)
    }

    if (!openedMenu) {
        resItems := AdvImageSearch("Resources\items.png", 0, 0, W, H)
        if (resItems.status == "success" && resItems.score > 0.56) {
            fx := resItems.x
            fy := resItems.y
            MouseMove(fx, fy+ScaleY(7), A_DefaultMouseSpeed+1)
            Sleep(100)
            MouseClick()
        } 

        openedMenu := false
        StartTime := A_TickCount
        Loop {
            X1 := Round(rw * 0.2)
            Y1 := 0
            W := Round(rw * 1) - X1
            H := Round(rh * 0.4) - Y1
            resclose := AdvImageSearch("Resources\close_items.png", X1, Y1, W, H)

            If (resclose.status = "success" && resclose.score >= 0.85) {
                openedMenu := true
                savedCloseX := resclose.x
                savedCloseY := resclose.y
                break
            } 

            if (A_TickCount - StartTime > 6000)
                break
            Sleep(500)
        }

        if (!openedMenu) {
            LogToConsole("Failed to equip towers! The macro can't see the towers menu! Reloading...", true, false)
            Sleep 400
            SafeReload()
            return
        }
    }

    sX := ScaleX(484)
    sY := ScaleY(229)

    StartTime := A_TickCount
    Loop {
        resBar := AdvImageSearch("Resources\searchbar_items.png", 0,0,Round(rh*0.5),Round(rh*0.5))
        if (resBar.status == "success" && resBar.score > 0.67) {
            sX := resBar.x+30
            sY := resBar.y
            break
        }
        if (A_TickCount - StartTime > 4000)
            break
        Sleep(400)
    }

    Click(sX, sY)
    Sleep(150)

    SendText("Sniper")
    Sleep(400)
    Click(sX+10, ScaleY(409))
    Sleep(500)

    X := Round(rw * 0.61)
    Y := ScaleY(830)
    X1 := Round(rw * 0.4)
    Y1 := Round(rh * 0.4)
    W := Round(rw * 0.9) - X1
    H := rh - Y1

    StartTime := A_TickCount
    Loop {
        getRobloxPos(,,&w,&h)
        baseScale := h / 1009

        resAlign := AdvImageSearch("Resources\equip.png", X1, Y1, W, H, 0.5 * baseScale, 2, 0.025)

        if (resAlign.status == "success" && resAlign.score > 0.4) {
            Y := resAlign.y+ScaleY(110)
        }

        offset := -30
        baseY := Y

        MouseMove(X, Y+ ScaleY(offset))

        oldMode := A_SendMode
        oldDelay := A_MouseDelay
        SendMode("Input")
        SetMouseDelay(0)

        while (offset <= 30) {
            cY := baseY + ScaleY(offset)

            MouseClick("Left", X, cY)

            offset += 5
            Sleep 5
        }
        SendMode(oldMode)
        SetMouseDelay(oldDelay)

        Sleep(600)
        failCount := 0
        
        InnerStart := A_TickCount
        Loop {
            X1 := Round(rw * 0.4)
            Y1 := Round(rh * 0.5)
            W := Round(rw * 0.9) - X1
            H := rh - Y1

            getRobloxPos(,,&w,&h)
            baseScale := Round(h / 1009)

            resUnequip := AdvImageSearch("Resources\unequip.png", X1, Y1, W, H, 0.3 * baseScale, 1.4, 0.025)
            if (resUnequip.status == "success" && resUnequip.score > 0.63) {
                if (PixelSearch(&uX, &uY, resUnequip.x-ScaleX(40), resUnequip.y-ScaleY(25), resUnequip.x+ScaleX(40), resUnequip.y+ScaleY(25), 0x7A797A, 5)) {
                    Click(resUnequip.x, resUnequip.y)
		    MouseMove(resUnequip.x, resUnequip.y-ScaleY(80))
                    failCount := 0
                    break
                } else {
                    failCount++
                    if (failCount >= 5) {
                        break 2
                    }
                    Sleep(200)
                    continue
                }
            } else {
                failCount++
                if (failCount >= 3) {
                    break 2
                }
            }
            if (A_TickCount - InnerStart > 3000)
                break
            Sleep(200)
        }
        Sleep(400)
    }
    
    Loop Parse, towers, ","
    {
        ActivateRoblox()
        tower := Trim(A_LoopField)

        goldtower := RegExMatch(tower, "i)\b(Golden|G\.|G)\b") ? true : false
        regulartower := RegExMatch(tower, "i)\b(Regular|R\.|R)\b") ? true : false

        towerToEnter := RegExReplace(tower, "i)\b(Golden|G\.|G|Regular|R\.|R)\b\s*|\.")
        towerToEnter := Trim(towerToEnter) 

        Click(sX, sY)
        Sleep(150)

        SendText(towerToEnter)
        Sleep(500)
        Click(sX+10, ScaleY(409))
        Sleep(500)

        X1 := Round(rw * 0.4)
        Y1 := Round(rh * 0.5)
        W := Round(rw * 0.9) - X1
        H := rh - Y1

        TowerStart := A_TickCount
        Loop {
            getRobloxPos(,,&w,&h)
            baseScale := h / 1009

            resEquip := AdvImageSearch("Resources\equip.png", X1, Y1, W, H, 0.5 * baseScale, 1.4, 0.025)

            if (resEquip.status == "success" && resEquip.score > 0.4) {
                If (PixelSearch(&eX, &eY, resEquip.x-40, resEquip.y-25, resEquip.x+40, resEquip.y+25, 0x45DC4A, 7)) {
                    Click(resEquip.x, resEquip.y)
                    
                    if (goldtower) {
                        GoldStart := A_TickCount
                        Loop {
                            resGolden := AdvImageSearch("Resources\notgolden.png", X1, Y1, W, H) 
                            if (resGolden.status == "success" && resGolden.score > 0.55) {
                                If (PixelSearch(&eX, &eY, resGolden.x-40, resGolden.y-25, resGolden.x+40, resGolden.y+25, 0x1E1E1E, 4)) {
                                    Click(resGolden.x, resGolden.y)
                                    Sleep(300)
                                    break
                                }
                            }
                            if (A_TickCount - GoldStart > 1000)
                                break
                            Sleep(400)
                        }
                    }
                    
                    if (regulartower) {
                        RegStart := A_TickCount
                        Loop {
                            resGolden := AdvImageSearch("Resources\golden.png", X1, Y1, W, H, 0.4, 2) 
                            if (resGolden.status == "success" && resGolden.score > 0.55) {
                                If (PixelSearch(&eX, &eY, resGolden.x-40, resGolden.y-25, resGolden.x+40, resGolden.y+25, 0xFFC11F, 8)) {
                                    Click(resGolden.x, resGolden.y)
                                    Sleep(300)
                                    break
                                }
                            }
                            if (A_TickCount - RegStart > 1000)
                                break
                            Sleep(400)
                        }
                    }
                    break
                }
                Sleep(100)
            }
            if (A_TickCount - TowerStart > 5000)
                break
            Sleep(400)
        }
        Sleep(400)
    }
    X1 := Round(rw * 0.2)
    Y1 := 0
    W := Round(rw * 1) - X1
    H := Round(rh * 0.4) - Y1
    resclose := AdvImageSearch("Resources\close_items.png", X1, Y1, W, H)

    If (resclose.status = "success" && resclose.score >= 0.85) {
        Click(resclose.x, resclose.y)
    } else if (savedCloseX != 0 && savedCloseY != 0) {
        Click(savedCloseX, savedCloseY)
    }
    
    LogToConsole("Successfully equipped towers: " towers, true, false)
}

CheckRestart() {
    global IsRestarting, difficulty, UseRestartBtn, UsePlayAgainBtn, CollectPlaytimeRewards

    shouldCollectRewards := (CollectPlaytimeRewards = "1" || CollectPlaytimeRewards = 1) && CheckDailyRewardTime() && (AutorunStartTime = 0 || (A_TickCount - AutorunStartTime) > 300000)
    
    if (shouldCollectRewards && !MultiplayerEnabled) {
        LogToConsole("Navigating to lobby to check playtime rewards...", true, false)
        IsRestarting := false
        CloseRoblox()
        RunRoblox()
        JoinGame()
        return
    }

    KillSubmacros()

    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        ActivateRoblox()
        Sleep(1500)
        ActivateRoblox()
        SendGameplayKey(CancelPlacementKey, "Cancel placement")
        getRobloxPos(,, &w, &h)
        
        resRevive := AdvImageSearch("Resources\use_revive_ticket.png", w * 0.2, h * 0.2, w * 0.6, h * 0.7)

        if (resRevive.status == "success" && resRevive.score > 0.7) {
            resCancel := AdvImageSearch("Resources\cancel.png", w * 0.2, h * 0.2, w * 0.6, h * 0.7)
            
            if (resCancel.status == "success" && resCancel.score > 0.7) {
                WinActivate("ahk_exe RobloxPlayerBeta.exe")
                WinWaitActive("ahk_exe RobloxPlayerBeta.exe", , 1)
                Click(resCancel.x, resCancel.y)
                Sleep 250
            }
        }

        if (UseRestartBtn = "1" || UseRestartBtn = 1) {
            resRestart := AdvImageSearch("Resources\Restart.png", 0, h * 0.5, w, h * 0.5, 0.5, 1.5)
            resRestart2 := AdvImageSearch("Resources\Restart2.png", 0, h * 0.5, w, h * 0.5, 0.5, 1.5)

            if ((resRestart.status == "success" && resRestart.score > 0.64) || (resRestart2.status == "success" && resRestart2.score > 0.64)) {
                if (MultiplayerEnabled && PlayerRole = "Host") {
                    Sleep 5000
                }

                res := resRestart.score > resRestart2.score ? resRestart : resRestart2
                IsRestarting := true
                LogToConsole("Restarting the match")
                if !(MultiplayerEnabled) { 
                    Click(res.x, res.y)
                } else {
                    totalPartyMembers := 0
                    Loop Parse, PartyMembers, "," {
                        member := Trim(A_LoopField)
                        if (member = "") {
                            continue
                        }
                        totalPartyMembers++
                    }
                    if totalPartyMembers = 2 || totalPartyMembers = 3 {
                        if PlayerRole != "Host" {
                            Click(res.x, res.y)
                        }
                    } else {
                        if PlayerRole = "Host" {
                            Click(res.x, res.y)
                        }
                    }
                }
                Sleep(150)
                startWatchdog()
                return
            }
        }

        if (UsePlayAgainBtn = "1" || UsePlayAgainBtn = 1) {

            resReplay := AdvImageSearch("Resources\PlayAgain.png", 0, h * 0.5, w, h*0.5, 0.5, 1.5, 0.025)
            
            if (resReplay.status == "success" && resReplay.score > 0.64) {
                if (MultiplayerEnabled && PlayerRole = "Host") {
                    Sleep 5000
                }
                if (!MultiplayerEnabled || PlayerRole = "Host") {
                    Click(resReplay.x, resReplay.y)
                }
                Sleep(150)
                WaitForLobbyLoad()
                startWatchdog()
                return
            }
        }
    }

    startWatchdog()
    IsRestarting := false
    CloseRoblox()
    RunRoblox()
    JoinGame()
}

RunRoblox(doReload := true) {
    global VipLink, UseVipServer
    PlaceID := "3260590327"
    SetMacroPhase("roblox-launch", "opening-lobby", 90000)

    Loop {
        if ((UseVipServer = "1" || UseVipServer = 1) && VipLink != "") {
            if InStr(VipLink, "privateServerLinkCode=") {
                RegExMatch(VipLink, "privateServerLinkCode=([a-fA-F0-9]+)", &f)
                DeepLink := "roblox://placeID=" PlaceID "&linkcode=" f[1]
            } else if InStr(VipLink, "share?code=") {
                RegExMatch(VipLink, "code=([a-fA-F0-9]+)", &f)
                DeepLink := "roblox://navigation/share_links?code=" f[1] "&type=Server"
            } else {
                DeepLink := "roblox://placeID=" PlaceID
            }
        } else {
            DeepLink := "roblox://placeID=" PlaceID
        }

        Run(DeepLink)
        if !WinWait("ahk_exe RobloxPlayerBeta.exe", , 60) {
            LogToConsole("Roblox not started, retrying again...", true, false)
            TouchMacroHeartbeat("deep-link-retry")
            continue
        }
        ActivateRoblox()
        ExitFullScreen()
        WinMinimize("ahk_exe RobloxPlayerBeta.exe")
        WinMaximize("ahk_exe RobloxPlayerBeta.exe")
        ActivateRoblox()

        SetTimer(CheckPopups, 5000)

        startTime := A_TickCount
        getRobloxPos(,,&w,&h)
        Loop {
            ActivateRoblox()

            if (A_TickCount - startTime > 60000) {
                if (doReload) {
                    SafeReload("roblox-lobby-load-timeout")
                    return false
                } else {
                    return false
                }
            }

            res0 := AdvImageSearch("Resources/Play.png", Round(w * 0.25), Round(h * 0.66), Round(w * 0.75), Round(h * 0.34))
            if (res0.status = "success" && res0.score > 0.65) {
                SetMacroPhase("roblox-lobby-ready", "play-button-visible", 0)
                break
            } 
            Sleep(1500)
        }
        SendEvent("{sc00F}")
        return true 
    }
}

ExitFullScreen() {
    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        ActivateRoblox()
        style := WinGetStyle("ahk_exe RobloxPlayerBeta.exe")
        if !(style & 0xC00000) {
            SendEvent("{F11}")
            Sleep(500)
        }
        WinRestore("ahk_exe RobloxPlayerBeta.exe")
        ActivateRoblox()
    }
}

CloseRoblox() {
	
	if (hwnd := GetRobloxHWND())
	{
        getRobloxPos(,,,&windowHeight)
		GetRobloxClientPos(hwnd)
		if (windowHeight >= 500) 
		{
			ActivateRoblox()
			PrevKeyDelay := A_KeyDelay
			SetKeyDelay 500
			send "{" SC_Esc "}{" SC_L "}{" SC_Enter "}"
			SetKeyDelay PrevKeyDelay
		}
		try WinClose "Roblox"
		Sleep 500
		try WinClose "Roblox"
		Sleep 4500 
	}
	
	for p in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM Win32_Process WHERE Name LIKE '%Roblox%' OR CommandLine LIKE '%ROBLOXCORPORATION%'")
		ProcessClose p.ProcessID
}

resetCharacter() {
	if (hwnd := GetRobloxHWND())
	{
        getRobloxPos(,,,&windowHeight)
		GetRobloxClientPos(hwnd)
		if (windowHeight >= 500) 
		{
			ActivateRoblox()
			PrevKeyDelay := A_KeyDelay
			SetKeyDelay 500
			send "{" SC_Esc "}{" SC_R "}{" SC_Enter "}"
			SetKeyDelay PrevKeyDelay
		}
	}
}

SwitchToNextStrategy(&stratName) {
    global CurrentRotationIndex, Strategy1Path, Strategy2Path, requiredTowers
    global CurrentStratStartTime, CurrentRunCount, StateFile, RunningStrategy, difficulty

    if (CurrentRotationIndex = 1) {
        LoadStrategyFile(Strategy2Path)
        CurrentRotationIndex := 2
        IniWrite(2, StateFile, "State", "CurrentRotationIndex")
        stratName := Strategy2Path 
    } else {
        LoadStrategyFile(Strategy1Path)
        CurrentRotationIndex := 1
        IniWrite(1, StateFile, "State", "CurrentRotationIndex")
        stratName := Strategy1Path
    }

    CurrentStratStartTime := A_TickCount
    CurrentRunCount := 0
    IniWrite(A_TickCount, StateFile, "State", "CurrentStratStartTime")
    IniWrite(0, StateFile, "State", "CurrentRunCount")

    IniWrite(1, StateFile, "State", "Running")
    IniWrite(stratName, StateFile, "State", "Strategy")

    return true
}

IsJoinedVoteLobbyVisible() {
    getRobloxPos(,, &w, &h)
    if (w < 100 || h < 100)
        return false

    ready := AdvImageSearch("Resources/Ready.png", Round(w * 0.25), Round(h * 0.66), Round(w * 0.5), Round(h * 0.34), 0.6, 1.7)
    return (ready.status = "success" && ready.score >= 0.7)
}

WaitForJoinOption(imageFile, threshold, phaseName, x1, y1, x2, y2, timeoutMs := 60000) {
    global difficulty

    SetMacroPhase(phaseName, difficulty, timeoutMs)
    startedAt := A_TickCount
    lastPlayRetry := 0

    Loop {
        if IsJoinedVoteLobbyVisible() {
            LogToConsole("The " difficulty " voting lobby is already joined; skipping the remaining mode buttons.", true, false)
            SetMacroPhase("join-already-complete", difficulty, 0)
            return "joined"
        }

        elapsed := A_TickCount - startedAt
        if (elapsed >= timeoutMs) {
            LogToConsole("Timed out during " phaseName " after " Round(elapsed / 1000) " seconds; recovering...", true, false)
            return "timeout"
        }

        if (elapsed >= 15000 && (lastPlayRetry = 0 || A_TickCount - lastPlayRetry >= 8000)) {
            playButton := AdvImageSearch("Resources\Play.png", x1, y1, x2, y2)
            if (playButton.status = "success" && playButton.score > 0.65) {
                Click(playButton.x, playButton.y)
                WriteRuntimeLog("MAIN", "Retried the Play button during " phaseName ".", "WARN")
            }
            lastPlayRetry := A_TickCount
        }

        getRobloxPos(,, &w, &h)
        option := AdvImageSearch("Resources/" imageFile, 0, 0, w, h)
        if (option.status = "success" && option.score >= threshold) {
            Click(option.x, option.y)
            SetMacroPhase(phaseName "-selected", imageFile, 0)
            return "selected"
        }
        Sleep(150)
    }
}

WaitForLobbyLoad() {
    global difficulty, MultiplayerEnabled, PlayerRole, modifiers, gamemap

    SetTimer(CheckPopups, 0)
    SetMacroPhase("join-wait-vote-lobby", difficulty, 75000)

    startTime := A_TickCount
    if (difficulty != "Pizza Party" && difficulty != "Badlands II" && difficulty != "Polluted Wasteland II") {
        Sleep(6000)
        Loop {
            if (A_TickCount - startTime > 60000) {
                LogToConsole("The Frost voting lobby did not finish loading; restarting safely...", true, false)
                CloseRoblox()
                SafeReload("vote-lobby-load-timeout")
                return false
            }
            getRobloxPos(,,&w,&h)
            res := AdvImageSearch("Resources/Ready.png", Round(w * 0.25), Round(h * 0.66), Round(w * 0.5), Round(h * 0.34), 0.6, 1.7)
            if (res.status = "success" && res.score >= 0.7) {
                break
            }
            Sleep(150)
        }

        SetMacroPhase("map-voting", gamemap, 180000)
        if (!MultiplayerEnabled || PlayerRole = "Host") {
            SelectMap(res.x, res.y)
        } else {
            Click(Round(w*0.5), res.y)
            Sleep 250
            Click(Round(w*0.6), res.y)
            if (modifiers != "")
                ApplyModifiers()
        }
    }

    SetMacroPhase("match-setup", gamemap, 180000)
    return true
}

JoinGame() {
    global SendCurrenciesEnabled, WebhookEnabled, difficulty, CollectPlaytimeRewards, PlayerRole, MultiplayerEnabled, PartyMembers
    getRobloxPos(,, &w, &h)

    isHardcore := (difficulty = "Hardcore" || difficulty = "Voidcore")
    SetMacroPhase("join-wait-play", difficulty, 90000)

    startTime := A_TickCount
    lastJoinedCheck := 0
    Loop {
        if (A_TickCount - startTime > 80000) {
            LogToConsole("The Play button did not appear within 80 seconds; recovering...", true, false)
            SafeReload("join-play-button-timeout")
            return
        }

        if (lastJoinedCheck = 0 || A_TickCount - lastJoinedCheck >= 500) {
            if IsJoinedVoteLobbyVisible() {
                LogToConsole("The " difficulty " lobby is already open; continuing from its current state.", true, false)
                WaitForLobbyLoad()
                return
            }
            lastJoinedCheck := A_TickCount
        }

        getRobloxPos(,, &w, &h)
        x1 := Round(w * 0.25)
        y1 := Round(h * 0.66)
        x2 := Round(w * 0.75)
        y2 := Round(h * 0.34)

        res := AdvImageSearch("Resources\Play.png", x1, y1, x2, y2)
        if (res.status == "success" && res.score > 0.65) {
            if (!isHardcore)
                ActivateRoblox()
            if (CollectPlaytimeRewards = "1" || CollectPlaytimeRewards = 1)
                claimPlaytimeRewards()

            LowerGraphics()
            Sleep(50)

            if (MultiplayerEnabled) {
                if (PlayerRole = "Member") {
                    AcceptInvite(res.x, res.y)
                    WaitForLobbyLoad()
                    return
                } else {
                    CreateParty(res.x, res.y)
                }
            }

            LogToConsole("Joining " difficulty "...", true, false)
            Click(res.x, res.y)
            break
        }
        Sleep(100)
    }
    Sleep(300)

    modeImg := ""
    if (difficulty = "Pizza Party" || difficulty = "Badlands II" || difficulty = "Polluted Wasteland II")
        modeImg := "SpecialMode.png"

    if (modeImg != "") {
        outcome := WaitForJoinOption(modeImg, 0.67, "join-select-special-mode", x1, y1, x2, y2)
        if (outcome = "joined") {
            WaitForLobbyLoad()
            return
        }
        if (outcome = "timeout") {
            SafeReload("join-special-mode-timeout")
            return
        }
        Sleep(300)
    }

    outcome := WaitForJoinOption(difficulty ".png", 0.7, "join-select-difficulty", x1, y1, x2, y2)
    if (outcome = "joined") {
        WaitForLobbyLoad()
        return
    }
    if (outcome = "timeout") {
        SafeReload("join-difficulty-timeout")
        return
    }
    Sleep(300)

    SetMacroPhase("join-select-party-size", difficulty, 50000)
    startTime := A_TickCount
    lastJoinedCheck := 0
    Loop {
        if (A_TickCount - startTime > 40000) {
            LogToConsole("The party-size button did not appear; recovering...", true, false)
            SafeReload("join-party-size-timeout")
            return
        }

        if (lastJoinedCheck = 0 || A_TickCount - lastJoinedCheck >= 500) {
            if IsJoinedVoteLobbyVisible() {
                LogToConsole("The voting lobby loaded before party-size confirmation; continuing.", true, false)
                WaitForLobbyLoad()
                return
            }
            lastJoinedCheck := A_TickCount
        }

        getRobloxPos(,, &w, &h)
        if (!MultiplayerEnabled) {
            res := AdvImageSearch("Resources/Solo.png", 0, Round(h * 0.2), Round(w * 0.7), Round(h * 0.55))
            if (res.status = "success" && res.score >= 0.7) {
                Click(res.x, res.y)
                break
            }
        } else {
            totalPartyMembers := 0
            Loop Parse, PartyMembers, "," {
                member := Trim(A_LoopField)
                if (member != "")
                    totalPartyMembers++
            }

            if (totalPartyMembers = 1)
                res := AdvImageSearch("Resources/duo.png", Round(w * 0.2), Round(h * 0.2), Round(w * 0.6), Round(h * 0.6))
            else if (totalPartyMembers = 2)
                res := AdvImageSearch("Resources/trio.png", Round(w * 0.2), Round(h * 0.2), Round(w * 0.6), Round(h * 0.6))
            else if (totalPartyMembers = 3)
                res := AdvImageSearch("Resources/quad.png", Round(w * 0.2), Round(h * 0.2), Round(w * 0.6), Round(h * 0.6))
            else
                res := AdvImageSearch("Resources/Solo.png", 0, Round(h * 0.2), Round(w * 0.7), Round(h * 0.55))

            if (res.status = "success" && res.score >= 0.7) {
                Click(res.x, res.y)
                break
            }
        }
        Sleep(100)
    }
    WaitForLobbyLoad()
}

CreateParty(x, y) {
    global PartyMembers
    StartTime := A_TickCount
    CloseX := 0
    CloseY := 0

    Loop {
        Click(x+200, y)

        InnerStartTime := A_TickCount

        if (A_TickCount - StartTime > 10000) {
            LogToConsole("Failed to Create Party: The macro can't see the menu!", true)
            SafeReload()
        }

        getRobloxPos(,,&w,&h)
        Loop {
            resclose := AdvImageSearch("Resources\close.png", Round(w*0.25), Round(h*0.1), Round(w*0.5), Round(h*0.4))

            If (resclose.status = "success" && resclose.score >= 0.7) {
                openedMenu := true
                CloseX := resclose.x
                CloseY := resclose.y
                break 2
            } 
            if (A_TickCount - InnerStartTime > 5000)
                break
            Sleep(500)
        }
    }

    Sleep 150

    create_btn := AdvImageSearch("Resources\create_party.png", Round(w*0.25), Round(h*0.5), Round(w*0.5), Round(h*0.5))
    Sleep 500
    if (create_btn.score > 0.58) {
        Click(create_btn.x, create_btn.y)
        LogToConsole("Successfully created the party")
    } else {
        LogToConsole("Failed to Create Party: The macro can't see the create party button!", true)
        SafeReload()
    }

    Sleep 300

    invited := false

    SetTimer(CancelInviteIfAppeared, 7500)

    Loop 3 {
        search_bar := AdvImageSearch("Resources\type_to_search.png", Round(w*0.25), Round(h*0.1), Round(w*0.5), Round(h*0.3))
        if (search_bar.score > 0.58) {
            Loop Parse, PartyMembers, "," {
                member := Trim(A_LoopField)
                if (member = "") {
                    continue
                }
                Click(search_bar.x, search_bar.y)
                Sleep(100)
                SendText(member)
                Sleep(100)
                Click(search_bar.x + ScaleX(75), search_bar.y + ScaleY(92))
                Sleep(50)

                LogToConsole("Successfully invited " member)
            }
            invited := true
            break
        }
        Sleep 1500
    }

    if (!invited) {
        LogToConsole("Failed to Create Party: The macro can't see the search_bar!", true)
        SafeReload()
    }

    Sleep 300

    totalPartyMembers := 0
    Loop Parse, PartyMembers, "," {
        member := Trim(A_LoopField)
        if (member = "") {
            continue
        }
        totalPartyMembers++
    }

    xs := 0
    sy := Round(h*0.1)

    waitStartTime := A_TickCount

    Loop {
        x_btn := AdvImageSearch("Resources\x.png", Round(w*0.25), sy, Round(w*0.25), Round(h*0.75) - sy)
        if (x_btn.score > 0.7) {

            xs++
            sy := x_btn.y+x_btn.h/2
        }
        LogToConsole("Waiting for " totalPartyMembers " players... (" xs "/"  totalPartyMembers ")")
        if (xs >= totalPartyMembers) {
            LogToConsole("All players: " PartyMembers " have joined!")
            break
        }
        if (A_TickCount - waitStartTime > 30000) { 
            sy := Round(h*0.1)
            xs := 0
            Loop Parse, PartyMembers, "," {
                member := Trim(A_LoopField)
                if (member = "") {
                    continue
                }
                Click(search_bar.x, search_bar.y)
                Sleep(100)
                SendText(member)
                Sleep(100)
                Click(search_bar.x + ScaleX(75), search_bar.y + ScaleY(92))
                Sleep(50)

                LogToConsole("Successfully invited " member)
            }
            waitStartTime := A_TickCount
        }
        Sleep 5000
    }

    SetTimer(CancelInviteIfAppeared, 0)

    resclose := AdvImageSearch("Resources\close.png", Round(w*0.25), Round(h*0.1), Round(w*0.5), Round(h*0.4))

    If (resclose.status = "success" && resclose.score >= 0.7) {
        Click(resclose.x, resclose.y)
    } 
    Sleep 200
}

CancelInviteIfAppeared(*) {
    global InputAutomationSuspended
    if (InputAutomationSuspended)
        return
    getRobloxPos(,,&w,&h)

    cancel_btn := AdvImageSearch("Resources/cancel_invite.png", Round(w * 0.2), Round(h * 0.2), Round(w * 0.6), Round(h * 0.65))
    if (cancel_btn.status = "success" && cancel_btn.score >= 0.65) {
        Click(cancel_btn.x, cancel_btn.y)
    }
}

AcceptInvite(x, y) {

    StartTime := A_TickCount
    CloseX := 0
    CloseY := 0
    Loop {
        Click(x+200, y)

        InnerStartTime := A_TickCount

        if (A_TickCount - StartTime > 15000) {
            LogToConsole("Failed to Create Party: The macro can't see the menu!", true)
            SafeReload()
        }

        getRobloxPos(,,&w,&h)
        Loop {
            resclose := AdvImageSearch("Resources\close.png", Round(w*0.25), Round(h*0.1), Round(w*0.5), Round(h*0.4))

            If (resclose.status = "success" && resclose.score >= 0.7) {
                openedMenu := true
                CloseX := resclose.x
                CloseY := resclose.y
                break 2
            } 
            if (A_TickCount - InnerStartTime > 5000)
                break
            Sleep(500)
        }
    }


    Sleep 150

    clickedInviteBtn := false

    search_bar_X := 0
    search_bar_Y := 0

    Loop 5 {
        create_btn := AdvImageSearch("Resources\invites_btn.png", Round(w*0.25), 0, Round(w*0.5), Round(h*0.4))
        if (create_btn.score > 0.58) {
            clickedInviteBtn := true
            Click(create_btn.x, create_btn.y)
            search_bar_X := create_btn.x - 250
            search_bar_Y := create_btn.y + 50
            break
        }
        Sleep 200
    }

    if (!clickedInviteBtn) {
        LogToConsole("Failed to Accept Invite: The macro can't see the invites button!", true)
        Sleep 300
        SafeReload()
    }

    invited := false

    Sleep 200

    Click(search_bar_X, search_bar_Y)
    Sleep(100)
    SendText(HostName)
    Sleep 100

    InnerStartTime := A_TickCount
    Loop {
        LogToConsole("Waiting for an invite from host: " HostName "...")
        accept_btn := AdvImageSearch("Resources\accept_invite.png", Round(w*0.25), Round(h*0.1), Round(w*0.5), Round(h*0.3))
        if (accept_btn.score > 0.66) {
            Click(accept_btn.x, accept_btn.y)
            if !(ReadMessage(["Error", "Party", "not", "found"])) {
                LogToConsole("Successfully accepted an invitation from " HostName)
                break
            }
        }
        if (A_TickCount - InnerStartTime > 180000) { 
            LogToConsole("Didn't receive an invite from the host within 3 minutes! Reloading the script and rejoining...", true)
            SafeReload()
        }
        Sleep 5000
    }

    resclose := AdvImageSearch("Resources\close.png", Round(w*0.25), Round(h*0.1), Round(w*0.5), Round(h*0.4))

    If (resclose.status = "success" && resclose.score >= 0.7) {
        Click(resclose.x, resclose.y)
    }
}

checkCondition(*) {
    global LeaveCondition, PartyMembers, InputAutomationSuspended

    if (InputAutomationSuspended)
        return

    totalPartyMembers := 0
    Loop Parse, PartyMembers, "," {
        member := Trim(A_LoopField)
        if (member = "") {
            continue
        }
        totalPartyMembers++
    }

    ActivateRoblox()
    getRobloxPos(&rX, &rY, &w,&h)

    img := ""
    if (LeaveCondition = "All") {
        img := "Resources/(1"
    } else {
        if (totalPartyMembers = 1) {
            img := "Resources/(2"
        } else if (totalPartyMembers = 2) {
            img := "Resources/(3"
        } else if (totalPartyMembers = 3) {
            img := "Resources/(4"
        }
    }

    if (img = "")
        return

    result := AdvImageSearch(img ".png", Round(w*0.5), rY, w, h)
    if (result.score > 0.8) {
        if (LeaveCondition = "All") {
            LogToConsole("All players are gone! Closing roblox and reloading the macro...", true)
            CloseRoblox()
            SafeReload()
        }
    } else {
        LogToConsole("Someone has just left! Closing roblox and reloading the macro...", true)
        CloseRoblox()
        SafeReload()
    }

}

SelectMap(readyX := ScaleX(963), readyY := ScaleY(838)) {
    global gamemap, difficulty, modifiers, CheckTheMap

    getRobloxPos(,,&w,&h)
    readyX := Round(w*0.5)

    LogToConsole("Selecting map: " gamemap, true, false)
    Sleep(100)
    closeChat()

    if (difficulty = "Hardcore" || difficulty = "Voidcore") {
        image := A_WorkingDir "/Resources/map_selection.png"

        foundObject := false

        Loop 3 {
            getRobloxPos(&x, &y, &w, &h)
            res := AdvImageSearch(image, 0,0,Round(w/2),h)
            if (res.status == "success" && res.score >= 0.51) { 
                foundObject := true
                break 
            }
            Sleep(500)
        }

        if (!foundObject) {
            LogToConsole("Wrong camera position!")
            SendEvent("{Left down}")
            Sleep(1500) 
            SendEvent("{Left up}")
            Sleep(50)
        }
    } else {
        ActivateRoblox()
        resetCharacter()
        Sleep(7500)
        AlignCamera(false, false)
    }
    
    if (difficulty = "Hardcore" || difficulty = "Voidcore") {
        attempts := 0

        Sleep(300)
        SendEvent("{o down}")
        HyperSleep(100)
        SendEvent("{o up}")

        Loop {
            Sleep(200)
            ActivateRoblox()
            Sleep(600)
            SendEvent("{sc011 down}")  
            Sleep(3550)
            SendEvent("{sc011 up}")
            Sleep(300)

            LogToConsole("Trying to find: " gamemap ". Please wait..")

            getRobloxPos(,,&w,&h)
            FoundSlot := 0
            regions := [[0, 0, Floor(w * 0.3307), Floor(h * 0.6)],
            [Floor(w * 0.3307), 0, Floor(w * 0.1729), Floor(h * 0.6)],
            [Floor(w * 0.5036), 0, Floor(w * 0.1729), Floor(h * 0.6)],
            [Floor(w * 0.6765), 0, w - Floor(w * 0.6765), Floor(h * 0.6)]]

            langCode := "en-US"
            for availableLang in StrSplit(OCR.GetAvailableLanguages(), "`n", "`r") {
                if (availableLang != "" && SubStr(availableLang, 1, 2) = "en") {
                    langCode := availableLang
                    break
                }
            }

            Loop 4 {
                r := regions[A_Index]
                pBmp := Gdip_BitmapFromScreen(r[1] "|" r[2] "|" r[3] "|" r[4])
                result := OCR.FromBitmap(pBmp, {lang:langCode, scale:1.5, grayscale: 1}).Text
                Gdip_DisposeImage(pBmp)
                if RegExMatch(result, "i)\b" . gamemap . "\b") {
                    FoundSlot := A_Index
                    break
                }
            }
            
            if (attempts >= 5) {
                LogToConsole("Map is not found after 5 attempts! Reloading...", true)
                SafeReload()
            }

            if (FoundSlot = 0) {
                LogToConsole("Map is not found! Resetting...", true, false)
                resetCharacter()
                Sleep(8000)
                attempts++
                SendEvent("{Left down}")
                Sleep(1500) 
                SendEvent("{Left up}")
                Sleep(50)
                continue
            } else {
                LogToConsole(gamemap " found in slot " FoundSlot,true,false)
                break
            }
        }

        Sleep(300)
        ActivateRoblox()
        Sleep(100)

        SendEvent("{sc011 down}")  
        Sleep(500)
        SendEvent("{sc011 up}")
        Sleep(200)

        if (FoundSlot = 1) { 
            SendEvent("{sc01e down}")
            Sleep(1400)
            SendEvent("{sc01e up}")
            Sleep(600) 
        } else if (FoundSlot = 2) { 
            SendEvent("{sc01e down}")
            Sleep(500)
            SendEvent("{sc01e up}")
            Sleep(600) 
        } else if (FoundSlot = 3) { 
            SendEvent("{sc020 down}")
            Sleep(500)
            SendEvent("{sc020 up}")
            Sleep(600) 
        } else if (FoundSlot = 4) { 
            SendEvent("{sc020 down}")
            Sleep(1400)
            SendEvent("{sc020 up}")
            Sleep(600) 
        }

        if (modifiers != "")
            ApplyModifiers()

        SendEvent("{sc012 down}")  
        Sleep(1000)
        SendEvent("{sc012 up}")
        Sleep(100)
    } else {
        ActivateRoblox()
        Sleep(150)
        SendEvent("{sc01f down}") 
        Sleep(1900)
        SendEvent("{sc01f up}")
        Sleep(700)
        SendEvent("{sc01e down}") 
        Sleep(1800)
        SendEvent("{sc01e up}")
        Sleep(700)

        Loop 3 {
            e_pr := AdvImageSearch("Resources\e_prompt.png", 0, 0, w, h,1,1)

            if (e_pr.score >= 0.75) {
                break
            } else {
                Sleep(150)
            }
        }

        if !(e_pr.score >= 0.75) {
            LogToConsole("The macro can't see the E prompt (" e_pr.score "), retrying again... ", true) 
            SelectMap(readyX, readyY)
            return
        }

        SendEvent("{sc012 down}") 
        Sleep(1000)
        SendEvent("{sc012 up}")
        Sleep(500)

        foundsearchbar := false
        getRobloxPos(&x, &y, &w, &h)
        Loop 2 {
            res := AdvImageSearch("Resources/searchbar.png", Round(w*0.1),0,Round(w*0.6),h,0.5,1.5)
            
            if (res.status = "success" && res.score >= 0.6)  { 
                Click(res.x, res.y)
                foundsearchbar := true 
                break
            } 
            Sleep(500)
        }

        if (!foundsearchbar) {
            LogToConsole("Can not found the search bar in the override map menu! Retrying..", true)
            SelectMap(readyX, readyY, )
            return 
        }        

        Sleep(100)
        SendText(gamemap)
        Loop {
            Sleep(300)
            if (InArray(SpecialMaps, gamemap)) {
                SelectionICON := AdvImageSearch("Resources/Maps/" gamemap "_Selection.png", Round(w*0.1),0,Round(w*0.7),h,0.5,1.5)
            
                if (SelectionICON.score >= 0.65)  { 
                    Click(SelectionICON.x, SelectionICON.y)
                } else {
                    Click(res.x - ScaleX(90), res.y + 80)
                }
            } else {
                Click(res.x - ScaleX(90), res.y + 80)
            }
            Sleep(400)

            changedMap := false
            alrinRotation := false
            Loop 2 {
                if PixelSearch(&gx, &gy, Round(w*0.2), Round(h*0.24), Round(w*0.7), Round(h*0.3), 0x00EC00, 3) {
                    LogToConsole("Successfully changed the map to " gamemap,true,false)
                    changedMap := true
                    break
                }

                Sleep(200)
            }

            if (changedMap) {
                break
            }

            if (ReadMessage(["already", "current", "rotation"])) {
                LogToConsole(gamemap " is already in the current rotation. Clicking veto..", true)
                resVeto := AdvImageSearch("Resources\Veto.png", 0, 0, w, h,0.5,1.5)
                if (resVeto.status == "success" && resVeto.score > 0.65) {
                    MouseMove(resVeto.x, resVeto.y)
                    Sleep(30)
                    MouseClick
                } else {
                    MouseMove(ScaleX(1152), ScaleY(834))
                    Sleep(30)
                    MouseClick
                }
                Sleep(300)
                Send("{" SC_E " down}")
                Sleep(760)
                Send("{" SC_E " up}")

                alrinRotation := false
                Sleep(400)
                continue
            }

            if (!changedMap) {
                LogToConsole("Failed to change the map to " gamemap, true)
                SafeReload()
            } else {
                break
            }
        }

        if (modifiers != "")
            ApplyModifiers()

        Sleep(200)
        ActivateRoblox()
        Sleep(100)
        SendEvent("{sc020 down}") 
        Sleep(1800)
        SendEvent("{sc020 up}")
        Sleep(200)
        SendEvent("{sc01f down}") 
        Sleep(1680)
        SendEvent("{sc01f up}")
        Sleep(300)
        SendEvent("{sc020 down}") 
        Sleep(1500)
        SendEvent("{sc020 up}")
        Sleep(600)
        Loop 3 {
            e_pr := AdvImageSearch("Resources\e_prompt.png", 0, 0, w, h,0.6,1.5)

            if (e_pr.score >= 0.65) {
                break
            } else {
                Sleep(150)
            }
        }

        if !(e_pr.score >= 0.7) {
            LogToConsole("The macro can't see the E prompt (" e_pr.score "), moving slightly to the left... ", true) 
            SendEvent("{sc01e down}") 
            Sleep 300
            SendEvent("{sc01e up}") 
            Loop 3 {
                e_pr := AdvImageSearch("Resources\e_prompt.png", 0, 0, w, h,0.6,1.5)

                if (e_pr.score >= 0.65) {
                    break
                } else {
                    Sleep(150)
                }
            }
            if !(e_pr.score >= 0.7) {
                LogToConsole("The macro can't see the E prompt (" e_pr.score "), reloading... ", true) 
                SafeReload()
            }
        }

        SendEvent("{sc012 down}") 
        Sleep(800)
        SendEvent("{sc012 up}")
    }
    Sleep(100)

    Click(readyX, readyY)
    waitReady()
}

CheckTheMapF() {
    global gamemap, CheckTheMap, modifiers

    Join(arr, delim := ", ") {
        if !IsObject(arr)
            return String(arr)

        str := ""
        for index, value in arr
            str .= (index = 1 ? "" : delim) . value
        return str
    }

    modifiers_str := (modifiers is Array) ? Join(modifiers) : String(modifiers)

    if (FileExist("Resources\Maps\" . gamemap . ".png") && CheckTheMap = 1 && !InArray(SpecialMaps, gamemap) && !RegExMatch(modifiers_str, "i)fog"))
    {
        getRobloxPos(,,&w,&h)
        FoundMap := false
        Loop 2 {
            res := AdvImageSearch("Resources\Maps\" gamemap ".png", 0, 0, w, h, 0.5, 2)

            if (res.score > 0.7) {
                FoundMap := true
                break
            }
            
            Sleep(1250)
        }

        if (!FoundMap) {
            LogToConsole("Can't detect the map! Reloading script...", true)
            SafeReload()
        }
    }

    if (InArray(SpecialMaps, gamemap)) {
        functionName := gamemap . "Path"

        %functionName%() 
    }
}

ApplyModifiers() {
    global modifiers
    LogToConsole("Setting up modifiers: " modifiers)
    Click(56, ScaleY(930))

    Sleep(300)

    searchX := ScaleX(951)
    searchY := ScaleY(262)

    foundsearchbar := false
    getRobloxPos(&x, &y, &w, &h)
    Loop 2 {
        res := AdvImageSearch("Resources/searchbar_modifiers.png", Round(w*0.1),0,Round(w*0.7),Round(h*0.6), 0.5, 1.5)
        
        if (res.status = "success" && res.score >= 0.7)  { 
            searchX := res.x
            searchY := res.y
            foundsearchbar := true 
            break
          } 
        Sleep(500)
    }

    Loop Parse, modifiers, "," {
        modifier := Trim(A_LoopField)
        if (modifier = "") {
            continue
        }
        Click(searchX, searchY)
        Sleep(100)
        SendText(modifier)
        Sleep(100)
        Click(Round(w/2), searchY+ScaleY(80))
        Sleep(50)
        LogToConsole("Modifier added: " modifier)
    }
    Sleep(100)
    Click(ScaleX(1122), ScaleY(853))
    LogToConsole("All modifiers configured")
}

ClickReady() {
    global readyX, readyY

    Loop {
        MouseMove(readyX, readyY)
        Sleep 50
        MouseClick()
        Sleep 200

        getRobloxPos(,,&w,&h)
        readyc := AdvImageSearch("Resources/ready_gs.png",Round(w * 0.25), Round(h * 0.08), Round(w * 0.5), Round(h * 0.34))
        if !(readyc.score > 0.7) {
            LogToConsole("Successfully started the match by clicking the ready button.")
            break
        } else {
            LogToConsole("Failed to press the ready button, retrying...")
            if PixelSearch(&fx, &fy, Round(w*0.4),Round(h*0.05), Round(w*0.7), Round(h*0.35), 0x2BEB00, 2) {
                readyX := fx
                readyY := fy
                continue
            } else {
                break
            }
        }
    }
}

waitReady() {
    global readyX, readyY, MultiplayerEnabled, PlayerRole
    start := A_TickCount
    getRobloxPos(&x, &y, &w, &h)
    KillSubmacros()
    Loop {
        wt := 40000
        if (MultiplayerEnabled && PlayerRole = "Member") {
            wt := 90000
        }
        If (A_TickCount - start > wt) {
            LogToConsole("The ready button hasn't appeared for too long! Reloading the script...", true)
            CloseRoblox()
            SafeReload()
        }
        if PixelSearch(&fx, &fy, Round(w*0.4),Round(h*0.05), Round(w*0.7), Round(h*0.35), 0x2BEB00, 2) {
            readyX := fx
            readyY := fy
            break
        } else {
            Sleep(50)
        }
    }
    startWatchdog()
}

activateTimescale() {
    global UseTimeScale, TimeScaleMode, TimeScaleMultiplier, difficulty, SettingsFile, StateFile, AutorunStartTime, MultiplayerEnabled, TimescaleActive
    if (MultiplayerEnabled) {
        return
    }

    budget := KronoxBudgetCheckTimeScale(SettingsFile, StateFile)
    if (UseTimeScale && !budget.allowed) {
        TimescaleActive := false
        LogToConsole("Timescale budget guard: using 1x because " budget.reason ".", true, false)
        SendToWebhookInstant("Timescale budget guard used 1x: " budget.reason ".", 15114812, false)
        return
    }

    getRobloxPos(&x, &y, &w, &h)
    if (UseTimeScale && difficulty != "Pizza Party" && difficulty != "Badlands II" && difficulty != "Polluted Wasteland II") { 
        LogToConsole("Applying timescale: " TimeScaleMode ". Please, enable UI Navigation Toggle.")
        Click(Round(w*0.5), Round(h*0.5))

        Send("#")
        Send("{sc02B}")
        Sleep 50
        Loop 10 {
            Send("{Down}")
            Sleep 10
        }
        Loop 20 {
            Send("{Left}")
            Sleep 10
        }
        Send("{Right}")
        Sleep 10
        Send("{Enter}")

        Sleep(250)

        res := AdvImageSearch("Resources/GetMore.png", Round(w * 0.25), Round(h * 0.45), Round(w * 0.50), Round(h * 0.55))
        if (res.status = "success" && res.score >= 0.67) {
            Click(res.x, res.y+55)
            LogToConsole("Failed to activate timescale! You are out of tickets.", true, false)

        } else {
            res := AdvImageSearch("Resources/confirm.png", Round(w * 0.25), Round(h * 0.45), Round(w * 0.50), Round(h * 0.55))
            if (res.status = "success" && res.score >= 0.67) {
                Click(res.x, res.y)
            } else {
                LogToConsole("failed to activate timescale. the macro can't see the confirm/get more button... (" res.score ")", true)
                SafeReload()
            }

            timescales := IniRead(StateFile, "State", "Timescale", 0)
            timescales := timescales+1
            LogToConsole("-1 Timescale ticket. Total Timescale Tickets Used: " timescales)
            SendToWebhookInstant("[" runtime := FormatRuntime(AutorunStartTime) "] -1 Timescale ticket. `n-# Total Timescale Tickets Used: " . timescales, 12370112, false)
            IniWrite(timescales, StateFile, "State", "Timescale")
            KronoxBudgetRecordTimeScale(SettingsFile, StateFile, 1)
            TimescaleActive := true

            Sleep(250)
            if (TimeScaleMode = "2x") {
                Loop 2 {
                    Sleep(20)
                    Send("{Enter}")
                }
            } else if (TimeScaleMode = "1.5x") {
                Sleep(20)
                Send("{Enter}")
            }
        }

        Send("{sc02B}")
        Send("#")
    }
}

AlignCamera(move := true, skipZoom := false, log := true) {
    global MoveEnabled, MoveDirection, MoveDuration, IsRestarting, MouseDelay
    if (IsRestarting)
        return
    if (log) {
        LogToConsole("Aligning camera")
    }
    closeChat()

    getRobloxPos(&rx, &ry, &rw, &rh)

    MouseMove(rw/2, rh/2, 0)
    Click("Right Down")
    Sleep(50)
    MouseMove(0, rh, 3+MouseDelay, "R")
    Sleep(10)
    Click("Right Up")
    If (!skipZoom) {
        Sleep(200)
        SendEvent("{o down}")
        HyperSleep(750)
        SendEvent("{o up}")
        Sleep(200)
    }
    Sleep(200)
    if (MoveEnabled && !IsRestarting && move) {
        SendEvent("{" MoveDirection " down}")
        HyperSleep(MoveDuration)
        SendEvent("{" MoveDirection " up}")
    }
}

getSlots() {
    static cachedSlotsState := ""
    
    if (cachedSlotsState != "") {
        return cachedSlotsState
    }
    
    numbers := Map(
        1, A_WorkingDir "\Resources\1.png",
        2, A_WorkingDir "\Resources\2.png",
        3, A_WorkingDir "\Resources\3.png",
        4, A_WorkingDir "\Resources\4.png",
        5, A_WorkingDir "\Resources\5.png"
    )
    
    Ys := ScaleY(960)
    x1 := ScaleX(800)
    x2 := ScaleX(880)
    x3 := ScaleX(960)
    x4 := ScaleX(1040)
    x5 := ScaleX(1120)

    currentSlotsState := Map(
        1, [x1, Ys], 
        2, [x2, Ys], 
        3, [x3, Ys], 
        4, [x4, Ys], 
        5, [x5, Ys]
    )

    getRobloxPos(&x, &y, &w, &h)
    offsetY := Integer(h * 0.8)
    endY := Integer(h * 0.17)
    endX := Integer(w* 0.75)

    startX := Integer(w*0.15)
    
    for digit, Image in numbers {
        if (!Image)
            continue
            
        Variation := 10 

        Result := AdvImageSearch(Image, startX, offsetY, endX, endY, 0.75, 2)
        
        if (Result.status == "success" && Result.score >= 0.84) {
            startX := Result.x+ScaleX(70)
            endY := Result.y+ScaleY(40)-offsetY
            endX := Integer(w* 0.1)

            currentSlotsState[digit] := [Result.x+ScaleX(15), Result.y+ScaleY(20)]
        }
    }

    cachedSlotsState := currentSlotsState
    return cachedSlotsState
}


InspectTowerHotbarBeforeSlotInput() {
    hwnd := GetRobloxHWND()
    if (!hwnd)
        return {safe: false, reason: "Roblox window is missing", text: ""}

    try WinGetClientPos(&clientX, &clientY, &clientW, &clientH, "ahk_id " hwnd)
    catch Error as err
        return {safe: false, reason: "Could not read Roblox client position: " err.Message, text: ""}

    if (clientW < 400 || clientH < 300)
        return {safe: false, reason: "Roblox client is too small for hotbar verification", text: ""}

    slotPoints := getSlots()
    if (!IsObject(slotPoints) || !slotPoints.Has(1) || !slotPoints.Has(2))
        return {safe: false, reason: "Tower slot anchors were not found", text: ""}

    firstSlot := slotPoints[1]
    secondSlot := slotPoints[2]
    padX := Max(28, Round(clientW * 0.022))
    left := Max(0, Min(firstSlot[1], secondSlot[1]) - padX)
    right := Min(clientW - 1, Max(firstSlot[1], secondSlot[1]) + padX)
    top := Min(clientH - 12, Min(firstSlot[2], secondSlot[2]) + Max(8, Round(clientH * 0.01)))
    regionW := Max(40, right - left)
    regionH := Max(12, clientH - top - 2)
    screenX := clientX + left
    screenY := clientY + top
    observedText := ""

    Loop 2 {
        try observedText := OCR.FromRect(screenX, screenY, regionW, regionH,
            {lang: "en-US", scale: A_Index = 1 ? 3 : 4, grayscale: A_Index = 2}).Text
        catch Error
            observedText := ""

        if (KronoxHotbarTowerPriceCount(observedText) > 0)
            return {safe: true, reason: "tower price confirmed", text: observedText,
                region: screenX "," screenY "," regionW "," regionH}
        Sleep(120)
    }

    return {safe: false, reason: "no tower price was visible in slots 1-2", text: observedText,
        region: screenX "," screenY "," regionW "," regionH}
}

EnsureTowerHotbarBeforeSlotInput(slotNumber, towerID := "") {
    global TowerHotbarVerifiedOnce

    inspection := InspectTowerHotbarBeforeSlotInput()
    if (inspection.safe) {
        if (!TowerHotbarVerifiedOnce) {
            TowerHotbarVerifiedOnce := true
            WriteRuntimeLog("HOTBAR", "Tower hotbar visually confirmed before slot input.")
        }
        return true
    }

    detail := inspection.reason " before slot " slotNumber
    if (towerID != "")
        detail .= " (" towerID ")"

    TriggerUnsafeHotbarRecovery(detail, inspection)
    return false
}

VerifyTowerHotbarAfterRiskyClick(actionName) {
    inspection := InspectTowerHotbarBeforeSlotInput()
    if inspection.safe
        return true

    WriteRuntimeLog("HOTBAR", "Unsafe hotbar state after " actionName ": " inspection.reason ".", "ERROR")
    TriggerUnsafeHotbarRecovery("unsafe hotbar state after " actionName, inspection)
    return false
}

ClickCloneSourceTowerSafely(towerID) {
    global Towers

    if !Towers.Has(towerID)
        return false

    tower := Towers[towerID]
    sourceX := tower.x
    sourceY := tower.y
    offsets := [0, -2, 2, -4, 4, -7, 7]
    started := A_TickCount

    while (A_TickCount - started < 6000) {
        for offsetY in offsets {
            probeY := sourceY + ScaleY(offsetY)
            MouseMove(sourceX, probeY)
            Sleep(220)

            tooltipX := sourceX + ScaleX(69)
            tooltipY := probeY - ScaleY(59)
            try towerHovered := PixelSearch(&foundX, &foundY,
                tooltipX - ScaleX(20), tooltipY - ScaleY(5),
                tooltipX + ScaleX(10), tooltipY + ScaleY(5), 0x99BFD4, 8)
            catch Error
                towerHovered := false

            if towerHovered {
                MouseClick()
                Sleep(80)
                if !VerifyTowerHotbarAfterRiskyClick("validated clone source click for " towerID)
                    return false
                return true
            }
        }
        Sleep(100)
    }

    WriteRuntimeLog("CLONE", "Skipped an unverified clone-source click for " towerID ".", "WARN")
    return false
}


SpawnTower(X, Y, slotNumber, towerID) {
    global Towers, LastOpenedTowerID, CancelPlacementKey, canUseAbility, UseNumbersForHotbar, Slots
    global AbstractTowerSlots, AbstractTowerSlot
    if (IsAbstractTowerSlot(slotNumber) && !IsActiveAbstractTowerSlot(slotNumber)) {
        LogToConsole("Skipping inactive abstract tower " towerID " in hotbar slot " slotNumber ".")
        return true
    }
    LogToConsole("Placing tower " towerID " (slot " slotNumber ") at x:" X " y:" Y "...")

    X := sX(X, StrategyWidth)
    Y := sY(Y, StrategyHeight)
    
    getRobloxPos(,,,&h)
    TowerY := Y
    if (Y < h * 0.5) {
        TowerY := Y - ScaleY(5)
    }

    placeAttempts := 0
    attemptMultiplier := 1
    startTime := A_TickCount
    canUseAbility := false
    isAbstractPlacement := IsActiveAbstractTowerSlot(slotNumber)
    placementTimeout := isAbstractPlacement ? 900000 : 300000

    if (isAbstractPlacement)
        LogToConsole("Abstract placement uses extended retries for expensive towers (up to 15 minutes).")

    Loop {
        placeAttempts++

        if (A_TickCount - startTime > placementTimeout) {
            timeoutMinutes := Round(placementTimeout / 60000)
            LogToConsole("Tower placement timed out (" timeoutMinutes "+ minutes). Reloading the macro...")
            SafeReload()
            return
        }

        ActivateRoblox()

        if !EnsureTowerHotbarBeforeSlotInput(slotNumber, towerID)
            return false
        
        if UseNumbersForHotbar {
            Send("{" slotNumber "}")
        } else {
            Click(Slots[slotNumber])
        }

        Sleep((PotatoMode = 1) ? 100 : 30)
        
        MouseMove(X, Y, A_DefaultMouseSpeed)
        Sleep((PotatoMode = 1) ? 100 : 40)
        MouseClick()
        if !VerifyTowerHotbarAfterRiskyClick("tower placement for " towerID)
            return false
        Sleep(100)
        SendGameplayKey(CancelPlacementKey, "Cancel placement")

        placedSuccessfully := waitForTowerUI(&resV2)

        if (placedSuccessfully) {
            Towers[towerID] := {x: X, y: TowerY, slot: Integer(slotNumber), level: 0, path: 0, pathLevel: 0, target: "First Enemy"}
            LogToConsole("Tower " towerID " placed successfully")
            LastOpenedTowerID := towerID
            break
        } else {
            KronoxProfilerRetry("SpawnTower " towerID, "placement attempt " placeAttempts " failed")
            if (!isAbstractPlacement || placeAttempts <= 3 || Mod(placeAttempts, 10) = 0)
                LogToConsole("Tower " towerID " placement failed, retrying" (isAbstractPlacement ? " while waiting for enough cash" : "") "...")
            if (placeAttempts = 1) {
                if (isAbstractPlacement)
                    Sleep(750)
                continue
            }

            getRobloxPos(,,&w,&h)
            x1 := Round(w * 0.2)
            y1 := Round(h * 0.18)
            x2 := Round(w * 0.7)
            y2 := Round(h * 0.3)
            if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/cannot_place_here.png") || ReadMessage(["cannot", "here", "hereg", "herd", "her", "here!", "cann", "cannd", "he", "h", "hed"],,["need", "more", "to"],"\$|\d")) {
                MouseClick()

                placedSuccessfully := waitForTowerUI(&resV2)
                if (placedSuccessfully) {
                    Towers[towerID] := {x: X, y: TowerY, slot: Integer(slotNumber), level: 0, path: 0, pathLevel: 0, target: "First Enemy"}
                    LogToConsole("Tower " towerID " placed successfully")
                    LastOpenedTowerID := towerID
                    break
                }

                offsets := [[0, -5 * attemptMultiplier], [5 * attemptMultiplier, 0], [0, 5 * attemptMultiplier], [-5 * attemptMultiplier, 0]]
                placedSuccessfully := false

                ActivateRoblox()

                if !EnsureTowerHotbarBeforeSlotInput(slotNumber, towerID)
                    return false
        
                Send("{" slotNumber "}")
                Sleep(30)

                LogToConsole("Cannot place here! Trying to place tower in different spots...")
                
                for index, offset in offsets {
                    if (A_TickCount - startTime > placementTimeout) {
                        LogToConsole("Tower placement timed out during offset retry. Executing safereload()...")
                        safeReload()
                        return
                    }

                    newX := X + offset[1]
                    newY := Y + offset[2]
                    
                    MouseMove(newX, newY, A_DefaultMouseSpeed)
                    Sleep((PotatoMode = 1) ? 100 : 40)
                    MouseClick()
                    if !VerifyTowerHotbarAfterRiskyClick("tower placement offset retry for " towerID)
                        return false
                    Sleep(100)

                    placedSuccessfully := waitForTowerUI(&resV2)
                    if (placedSuccessfully) {
                        Towers[towerID] := {x: newX, y: newY, slot: Integer(slotNumber), level: 0, path: 0, pathLevel: 0, target: "First Enemy"}
                        LogToConsole("Tower " towerID " placed successfully")
                        LastOpenedTowerID := towerID
                        break 2
                    }
                }
                
                if (!placedSuccessfully) {
                    SendGameplayKey(CancelPlacementKey, "Cancel placement")
                    attemptMultiplier := attemptMultiplier * 2
                }
            }

            if (isAbstractPlacement)
                Sleep(Min(2500, 650 + (placeAttempts * 75)))
        }
    }
    canUseAbility := true
}

SellTower(towerID) {
    global Towers, unfocusX, unfocusY

    if (!Towers.Has(towerID)) {
        LogToConsole("Tower " towerID " not found for selling!")
        return false
    }

    LogToConsole("Selling tower " towerID "...")
    targetX := Towers[towerID].x
    targetY := Towers[towerID].y
    Click(targetX, targetY)
    Sleep(400)

    attempts := 0
    Loop {
        menuFound := waitForTowerUI()
        
        if (!menuFound) {
            attempts++
            if (attempts > 15) {
                LogToConsole("Tower " towerID " menu not found for selling")
                return false
            }
            variation := Random(-10, 10)
            Click(Towers[towerID].x, Towers[towerID].y + variation)
            Sleep(400)
            continue
        }
        getRobloxPos(&rx, &ry, &w, &h)
        X1_v2 := 0
        Y1_v2 := Round(h/2)
        W_v2 := Round(w * 0.3) - X1_v2
        H_v2 := Round(h) - Y1_v2

        resV2 := AdvImageSearch("Resources\TowerUI\Variant2.png", X1_v2, Y1_v2, W_v2, H_v2, ,,0.05)

        if (resV2.score > 0.55) {
            Click(resV2.x, resV2.y)
        }

        LogToConsole("Tower " towerID " sold successfully")
        if (Towers[towerID].hwnd) {
            WinClose("ahk_id " Towers[towerID].hwnd)
        }
        Towers.Delete(towerID)
        return true
    }
    return false
}

UpgradeTower(towerID, skipOpen := false, totalUpgrades := 1, path := 0, pathLevel := 0) {
    global Towers, unfocusX, unfocusY, LastOpenedTowerID, needtocheckTowerUI
    global PotatoMode, UpgradeDelay, Recording, RecordedSteps, Commander, canUseAbility

    static resV2 := 0
    static resV1 := 0

    needtocheckTowerUI := true

    if (!Towers.Has(towerID)) {
        LogToConsole("Tower " towerID " not found!")
        return false
    }

    targetX := Towers[towerID].x
    targetY := Towers[towerID].y

    if (!skipOpen && LastOpenedTowerID != towerID) {
        canUseAbility := false
        Click(targetX, targetY)
        Sleep 250
        canUseAbility := true
    }

    LastOpenedTowerID := towerID
    upgradesDone := 0
    attempts := 0

    upgTime := A_TickCount

    Sleep(20)

    Loop {
        openedSuccessfully := false
        StartTime := A_TickCount

        if (PotatoMode) {
            if (A_TickCount - upgTime > 600) {
                needtocheckTowerUI := true
                upgTime := A_TickCount
            }
        } else {
            needtocheckTowerUI := true
        }

        if (needtocheckTowerUI || (!IsObject(ResV2) && !IsObject(ResV1))) {
            openedSuccessfully := waitForTowerUI(&ResV2, &ResV1)

            if (!openedSuccessfully && canBeUpgraded) {
                attempts++
                if (attempts > 30) {
                    LogToConsole("Tower " towerID " menu not found after 30 attempts, reloading...", true)
                    SafeReload()
                }
                variation := Random(-4, 4)
                Click(targetX, targetY + ScaleY(variation))
                Sleep(100)
                continue
            } else {
                attempts := 0
                needtocheckTowerUI := false
            }
        }
        
        doResV2 := (IsObject(resV2) && resV2.HasProp("score") && resV2.score > 0.55)

        if (doResV2) {
            UpgradeX := resV2.x+ScaleX(50)
            UpgradeY := resV2.y-ScaleY(220)

            upgAX := resV2.x + ScaleX(20)
            upgAY := resV2.y - ScaleY(240)
            upgAW := ScaleX(80)
            upgAH := ScaleY(70)
        } else {
            if (!IsObject(ResV1)) {
                needtocheckTowerUI := true
                Sleep(50)
                continue
            }
    
            UpgradeX := resV1.x-ScaleX(164)
            UpgradeY := resV1.y+ScaleY(383)

            upgAX := resV1.x - ScaleX(194)
            upgAY := resV1.y + ScaleY(363)
            upgAW := ScaleX(80)
            upgAH := ScaleY(70)
        }
        
        nextLevel := Towers[towerID].level + 1

        region := [upgAX, upgAY, upgAW, upgAH]

        if (path != 0 && nextLevel > pathLevel && pathLevel != 0) {
            if (path = 2) { 
                if (doResV2) {
                    region := [resV2.x+ScaleX(20), resV2.y-ScaleY(95), ScaleX(80), ScaleY(70)]
                    UpgradeY := resV2.y-ScaleY(120)
                } else {
                    region := [resV1.x - ScaleX(194), resV1.y + ScaleY(508), ScaleX(80), ScaleY(70)]
                    UpgradeY := resV1.y + ScaleY(483)
                }
            }
        } 

        XA := region[1]
        YA := region[2]
        WA := region[3]
        HA := region[4]

        X2 := XA + WA
        Y2 := YA + HA

        searchArea := XA "|" YA "|" X2 "|" Y2

        try {
            isGreen := PixelSearch(&gx, &gy, XA, YA, X2, Y2, 0x206235, 12)
        } catch Error {
            isGreen := false
        }
        if (isGreen && canBeUpgraded) {
            canUseAbility := false
            if (UseHForUpgrade) {
                if (path != 0 && nextLevel > pathLevel && pathLevel != 0) {
                    if (path = 1) { 
                        SendGameplayKey(UpgradeTowerGKey, "Upgrade tower keybind")
                    } else if (path = 2) {
                    SendGameplayKey(UpgradeTowerGBKey, "Upgrade bottom path keybind")
                    } 
                } else {
                    SendGameplayKey(UpgradeTowerGKey, "Upgrade tower keybind")
                }
            } else {
                Click(UpgradeX, UpgradeY)
            }

            Sleep(Max(UpgradeDelay, (PotatoMode = 1) ? 250 : 50))

            Towers[towerID].level += 1
            upgradesDone++
            LogToConsole("Tower " towerID " upgraded to level " Towers[towerID].level " (" upgradesDone "/" totalUpgrades ")")
            UpdateTowerIndicator(towerID)

            if (Towers[towerID].level >= 2 && RegExMatch(towerID, "i)^Commander\d*$") && !Commander) {
                Commander := true
                if (Recording && !HasStep("Commander := true"))
                    RecordedSteps.Push("Commander := true")
            }

            canUseAbility := true

            if (upgradesDone >= totalUpgrades) 
                return true

            continue
        }
    }
}

isDisconnected() {
    w := A_ScreenWidth
    h := A_ScreenHeight
    
    getRobloxPos(,, &w, &h)
    ActivateRoblox()

    if (!w || !h || w <= 0 || h <= 0) {
        w := A_ScreenWidth
        h := A_ScreenHeight
    }

    oldMode := A_CoordModePixel
    CoordMode("Pixel", "Screen")
    
    try {
        if ImageSearch(&FoundX, &FoundY, 0, 0, w, h, "*26 " "Resources\Disconnected.png") {
            CoordMode("Pixel", oldMode)
            TryReconnect()
        } else if ImageSearch(&FoundX, &FoundY, 0, 0, w, h, "*26 " "Resources\disconnected2.png") {
            CoordMode("Pixel", oldMode)
            TryReconnect()
        }
    } catch Error as err {
        CoordMode("Pixel", oldMode)
    }
    
    CoordMode("Pixel", oldMode)
}

TryReconnect() {
    attempts := 0
    Loop {
        attempts++
        LogToConsole("Reconnecting... Attempt " attempts ".", true, false)
        KillSubmacros()
        CloseRoblox()
        if (RunRoblox(false) == false) {
            continue
        } else {
            LogToConsole("Reconnect successful after " attempts " attempts!", true, false)
            startWatchdog()
            break
        }
    }
}

CheckPopups(*) {
    global InputAutomationSuspended
    static clickedNotNow := false

    if (InputAutomationSuspended)
        return

    getRobloxPos(,,&w,&h)

    res := AdvImageSearch("Resources/Claim.png", Round(w * 0.25), Round(h * 0.4), Round(w * 0.5), Round(h * 0.5))
    if (res.status = "success" && res.score >= 0.65) {
        LogToConsole("Claimed daily reward.")
        Click(res.x, res.y)
    }

    res := AdvImageSearch("Resources/cancel_rejoin.png", Round(w * 0.25), Round(h * 0.4), Round(w * 0.5), Round(h * 0.3))
    if (res.status = "success" && res.score >= 0.65) {
        LogToConsole("Claimed daily reward.")
        Click(res.x, res.y)
    }

    if (!clickedNotNow) {
        res2 := AdvImageSearch("Resources/notnow.png", Round(w * 0.25), Round(h * 0.4), Round(w * 0.5), Round(h * 0.5))
        if (res2.status = "success" && res2.score >= 0.65) {
            clickedNotNow := true
            Click(res2.x, res2.y)
        }
    }
}

UseAbilities(*) {
    global ChainKey, BeatKey, CaravanKey, CancelPlacementKey, TimeScaleMultiplier, AutoSkip, AbilitySpam
    global AdvancedAutoSkip
    global AutoSkipSuccessfulCount
    global autoChain, autoCaravan, autoDropTheBeat, Commander, unfocusX, unfocusY, canUseAbility
    global LastOpenedTowerID, Towers, TimescaleActive, needtocheckTowerUI
    global InputAutomationSuspended, AbsoluteModeEnabled
    static LastChainTime := 0, LastDropTime := 0, LastCaravanTime := 0
    static LastProgressProbe := 0, LastObservedWave := 0

    if (InputAutomationSuspended || !canUseAbility) {
        return
    }

    if (AbsoluteModeEnabled && A_TickCount - LastProgressProbe >= 15000) {
        LastProgressProbe := A_TickCount
        observedWave := DetectCurrentWaveNumber()
        if (observedWave > 0 && observedWave != LastObservedWave) {
            LastObservedWave := observedWave
            TouchMacroProgress("wave " observedWave)
        }
    }

    multiplier := 1
    if (TimescaleActive) {
    multiplier := TimescaleMultiplier
    } 

    caravanInterval := 26
    chainInterval := 14

    if (AbilitySpam = "ON") {
        caravanInterval := 20
        chainInterval := 10
    }

    if (AutoSkip = "ON" || AdvancedAutoSkip = "ON") {
        res := AdvImageSearch("Resources/Skip.png", Round(A_ScreenWidth * 0.3), 0, Round(A_ScreenWidth * 0.7), Round(A_ScreenHeight * 0.35), 0.5, 1.5)
        if (res.status = "success" && res.score >= 0.65) {
            Sleep(200)
            res := AdvImageSearch("Resources/Skip.png", Round(A_ScreenWidth * 0.3), 0, Round(A_ScreenWidth * 0.7), Round(A_ScreenHeight * 0.35), 0.5, 1.5)
            if (res.status = "success" && res.score >= 0.65 && ShouldAutoSkipWave()) {
                SendGameplayKey(CancelPlacementKey, "Cancel placement")
                MouseGetPos(&cx, &cy)
                Click(res.x, res.y)
                AutoSkipSuccessfulCount++
                Sleep(30)
                MouseMove(cx, cy)
                Sleep(20)
                LogToConsole("skipped wave")
                TouchMacroProgress("wave skipped")
            }
        }
    }


    if (autoChain = "ON" && Commander && (A_TickCount - LastChainTime > chainInterval * 1000 / multiplier)) {
        canUseAbility := false
        canBeUpgraded := false
        if (LastOpenedTowerID != "") {
            Click(ScaleX(unfocusX), ScaleY(unfocusY))
            Sleep(100)
        }
        LastChainTime := A_TickCount
        SendGameplayKey(ChainKey, "Call of Arms ability")
        LogToConsole("Activated Call of Arms")
        TouchMacroProgress("Call of Arms")
        canUseAbility := true
        if (LastOpenedTowerID != "") {
            Click(Towers[LastOpenedTowerID].x, Towers[LastOpenedTowerID].y)
            Sleep 250
        }
        canBeUpgraded := true
        needtocheckTowerUI := true
    }

    if (autoCaravan = "ON" && (A_TickCount - LastCaravanTime > caravanInterval * 1000 / multiplier)) {

        foundCommander := false
        for name, towerID in Towers {
            if towerID.level >= 4 && RegExMatch(name, "i)^Commander\d*$") {
                foundCommander := true
                break
            }
        }

        if (!foundCommander) {
            return
        }

        canBeUpgraded := false
        
        canUseAbility := false
        SendGameplayKey(CancelPlacementKey, "Cancel placement")
        if (LastOpenedTowerID != "") {
            Click(ScaleX(unfocusX), ScaleY(unfocusY))
            Sleep(300)
        }
        LastCaravanTime := A_TickCount
        SendGameplayKey(CaravanKey, "Support Caravan ability")
        LogToConsole("Activated Support Caravan")
        TouchMacroProgress("Support Caravan")
        if (LastOpenedTowerID != "") {
            Click(Towers[LastOpenedTowerID].x, Towers[LastOpenedTowerID].y)
            Sleep 400
        }
        canUseAbility := true
        canBeUpgraded := true
        needtocheckTowerUI := true
    }

    if (autoDropTheBeat = "ON" && Towers.Has("DJ") && Towers["DJ"].level >= 3 && (A_TickCount - LastDropTime > 28000 / multiplier)) {

        canBeUpgraded := false

        SendGameplayKey(CancelPlacementKey, "Cancel placement")
        if (LastOpenedTowerID != "DJ" && LastOpenedTowerID != "") {
            Click(ScaleX(unfocusX), ScaleY(unfocusY))
            Sleep(100)
        }

        Loop {
            if (InputAutomationSuspended)
                return
            LastDropTime := A_TickCount
            SendGameplayKey(BeatKey, "Drop the Beat ability")

            Sleep 350
            getRobloxPos(,,&w,&h)
            x1 := Round(w * 0.2)
            y1 := Round(h * 0.18)
            x2 := Round(w * 0.7)
            y2 := Round(h * 0.3)
            if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/stunned.png") || ReadMessage(["error", "that", "cannot", "cann", "activated", "while", "stunned"],,["need", "more", "to"],"\$|\d")) {
                LogToConsole("Failed to use Drop the Beat! The tower is stunned! Retrying...")
                Sleep 4400
            } else {    
                LogToConsole("Successfully used Drop the Beat")
                TouchMacroProgress("Drop the Beat")
                break
            }
        }

        if (LastOpenedTowerID != "" && LastOpenedTowerID != "DJ") {
            Click(Towers[LastOpenedTowerID].x, Towers[LastOpenedTowerID].y)
            Sleep 250
        }
        canBeUpgraded := true
        canUseAbility := true
        needtocheckTowerUI := true
    }
}

ShouldAutoSkipWave() {
    global AutoSkipStopWave, AutoSkipSuccessfulCount
    global AutoSkipLastDetectedWave, AutoSkipBlockLogged
    global AdvancedAutoSkip, AdvancedSkipWaveSet, AdvancedLastSkippedWave

    if (AdvancedAutoSkip = "ON") {
        detectedWave := DetectCurrentWaveNumber()
        if (detectedWave <= 0 || !AdvancedSkipWaveSet.Has(detectedWave))
            return false

        ; The timer checks several times per wave. Allow each selected wave only once.
        if (AdvancedLastSkippedWave = detectedWave)
            return false

        AdvancedLastSkippedWave := detectedWave
        LogToConsole("Advanced Wave Skip matched wave " detectedWave ".")
        return true
    }

    if (AutoSkipStopWave <= 0)
        return true

    detectedWave := DetectCurrentWaveNumber()
    if (detectedWave > AutoSkipLastDetectedWave)
        AutoSkipLastDetectedWave := detectedWave

    reachedProtectedWave := (AutoSkipLastDetectedWave >= AutoSkipStopWave)
    reachedSkipLimit := (AutoSkipSuccessfulCount >= Max(0, AutoSkipStopWave - 1))
    if (!reachedProtectedWave && !reachedSkipLimit)
        return true

    if (!AutoSkipBlockLogged) {
        reason := reachedProtectedWave
            ? "detected wave " AutoSkipLastDetectedWave
            : "completed " AutoSkipSuccessfulCount " earlier wave skips"
        LogToConsole("Auto Skip paused from wave " AutoSkipStopWave " onward (" reason ").", true)
        AutoSkipBlockLogged := true
    }
    return false
}

DetectCurrentWaveNumber() {
    hwnd := GetRobloxHWND()
    if (!hwnd)
        return 0

    try WinGetClientPos(&clientX, &clientY, &clientW, &clientH, "ahk_id " hwnd)
    catch
        return 0

    if (clientW <= 0 || clientH <= 0)
        return 0

    regionX := clientX + Round(clientW * 0.28)
    regionY := clientY
    regionW := Round(clientW * 0.44)
    regionH := Round(clientH * 0.24)

    try waveText := OCR.FromRect(regionX, regionY, regionW, regionH, {lang: "en-US", scale: 2, grayscale: 1}).Text
    catch
        return 0

    ; The HUD normally renders "Wave 39" or "Wave 39/40". Requiring the
    ; word Wave avoids confusing the nearby base-health and timer numbers.
    if RegExMatch(waveText, "i)\bW[A4]V[E3]\D{0,12}(\d{1,3})\b", &waveMatch)
        return Integer(waveMatch[1])

    return 0
}

SetDJTrack(track) {
    global Towers, unfocusX, unfocusY, LastOpenedTowerID, UseTimeScale, TimeScaleMode
    if (!Towers.Has("DJ")) {
        LogToConsole("DJ tower not found!")
        return
    }
    LogToConsole("Setting DJ track to " track "...")
    canUseAbility := false
    
    cleanTrack := StrReplace(track, '"', '')
    cleanTrack := StrReplace(cleanTrack, "'", "")
    trackName  := Format("{:L}", cleanTrack)

    if (LastOpenedTowerID != "DJ") {
        Click(Towers["DJ"].x, Towers["DJ"].y)
        LastOpenedTowerID := "DJ"
    }

    Sleep(200)

    Loop {
        getRobloxPos(&rx, &ry, &w, &h)
        startTime := A_TickCount

        openedSuccessfully := waitForTowerUI(&resv2, &resv1)

        if (!openedSuccessfully) {
            variation := Random(-10, 10)
            Click(Towers["DJ"].x, Towers["DJ"].y + ScaleY(variation))
            Sleep(400)
            continue
        }

        Sleep(250)

        DJTrack := resV2 := AdvImageSearch("Resources\" trackName ".png", 0, 0, w, h, 0.5, 1.5, 0.03)
        if (DJTrack.score > 0.6) {
            MouseGetPos(&cx, &cy)
            MouseMove(DJTrack.x, DJTrack.y)
            Sleep(20)
            MouseClick

            getRobloxPos(,,&w,&h)
            x1 := Round(w * 0.2)
            y1 := Round(h * 0.18)
            x2 := Round(w * 0.7)
            y2 := Round(h * 0.3)
            If (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/please_wait.png") || ReadMessage(["please", "wait"])) {
                LogToConsole("Need to wait before swithcing the track. Waiting 3 seconds...")
                if (UseTimeScale && TimeScaleMode = "2x") {
                    Sleep(1500)
                } else {
                    Sleep(3000)
                }
                continue
            }

            Sleep 10
            MouseMove(cx, cy)
        }
        break
    }
    canUseAbility := true
}

UpdateTowerIndicator(towerID) {
    global Towers, Recording, ShowIndicators, MainGui
    if (!Recording || !ShowIndicators || !Towers.Has(towerID))
        return
        
    Critical

    level := Towers[towerID].level
    MultiplePaths := (Towers[towerID].path != 0 && Towers[towerID].path != "")

    DetectHiddenWindows True
    
    oldMatchMode := A_TitleMatchMode
    SetTitleMatchMode 3 

    tTitle := "TowerIndicator_" towerID

    mainHwnd := 0
    try mainHwnd := MainGui.Hwnd

    If (Towers[towerID].HasProp("hwnd") && Towers[towerID].hwnd) {
        currentHwnd := Towers[towerID].hwnd
        if (currentHwnd != mainHwnd && WinExist("ahk_id " currentHwnd)) {
            try GuiFromHwnd(currentHwnd).Destroy()
        }
        Towers[towerID].hwnd := 0
    }

    if (oldHwnd := WinExist(tTitle " ahk_class AutoHotkeyGUI")) {
        if (oldHwnd != mainHwnd) {
            try GuiFromHwnd(oldHwnd).Destroy()
        }
    }

    clientLeft := 0
    clientTop := 0
    
    getRobloxPos(,, &clientLeft, &clientTop)
    
    hwnd := GetRobloxHWND()
    pt := Buffer(8, 0)
    DllCall("ClientToScreen", "UPtr", hwnd, "Ptr", pt)
    
    x := NumGet(pt, 0, "Int") + Towers[towerID].x - 16
    y := NumGet(pt, 4, "Int") + Towers[towerID].y - 16

    styleStr := "+ToolWindow +AlwaysOnTop -Caption +Disabled +Border +E0x20 +E0x08000000"

    tg := Gui(styleStr, tTitle)
    tg.BackColor := MultiplePaths ? "1A1A1A" : "FFFFFF"
    
    if (MultiplePaths)
        tg.SetFont("s12 w600 cFFFFFF", "Bahnschrift")
    else
        tg.SetFont("s10 c000000", "Arial")
    
    idLen := StrLen(towerID)

    if (idLen <= 3) {
        fontSize := "s12"
    } else if (idLen <= 5) {
        fontSize := "s8"
    } else if (idLen <= 8) {
        fontSize := "s6"
    } else if (idLen <= 11) {
        fontSize := "s4"
    } else {
        fontSize := "s3"
    }

    tg.SetFont("Bold " fontSize)

    tg.Add("Text", "x0 y0 w32 h24 Center BackgroundTrans 0x200", towerID)

    tg.SetFont("s8 norm")
    tg.Add("Text", "x0 y22 w32 h8 Center BackgroundTrans 0x200", level)
    
    tg.Show("x" x " y" y " w32 h32 NoActivate")
    
    WinSetTransparent(128, "ahk_id " tg.Hwnd)
    
    Towers[towerID].hwnd := tg.Hwnd

    SetTitleMatchMode oldMatchMode
    Critical("Off")
}



DeleteAllIndicators() {
    global Towers
    Critical("On")
    SetWinDelay(-1) 
    for id, t in Towers {
        if (t.HasProp("hwnd") && t.hwnd) {
            WinClose("ahk_id " t.hwnd)
            t.hwnd := ""
        }
    }
    SetWinDelay(10) 
    Critical("Off")
}

FindClosestTower(mx, my) {
    global Towers
    closestID := "", minDist := 20
    for id, t in Towers {
        dist := Sqrt((t.x - mx)**2 + (t.y - my)**2)
        if (dist < minDist) {
            minDist := dist
            closestID := id
        }
    }
    return closestID
}

HasStep(searchStep) {
    global RecordedSteps
    for i, s in RecordedSteps {
        if (s = searchStep) {
            return true
        }
    }
    return false
}


GetNextTowerID(slot) {
    global requiredTowers, Towers, AbstractTowerSlots, AbstractTowerSlot

    slotArray := StrSplit(requiredTowers, ",")
    for index, name in slotArray {
        slotArray[index] := Trim(name)
    }

    targetSlot := Integer(slot)
    if (IsAbstractTowerSlot(targetSlot)) {
        baseName := "Abstract"
    } else if (targetSlot > slotArray.Length || targetSlot < 1) {
        baseName := ""
    } else {
        baseName := slotArray[targetSlot]
    }
    
    if (InStr(baseName, "DJ") || InStr(baseName, "DJ Booth")) {
        baseName := "DJ"
    }
    
    count := 0

    if (IsObject(Towers)) {
        for id, t in Towers {
            if (RegExMatch(id, "i)^" baseName "(\d+)$", &match)) {
                num := Integer(match[1])
                if (num > count) {
                    count := num
                }
            }
        }
    }

    if (InStr(baseName, "DJ")) {
        return baseName
    } else {
        return baseName (count + 1)
    }
}

ModernMsgBox(Title, Text, Buttons := "OK", type := "") {
    boxType := (Buttons = "OK") ? 0 : 4
    If (type = "WARNING") {
        boxType += 48
    } Else {
        boxType += 64
    }
    if (AlwaysOnTop = 1) {
        boxType += 4096
    }
    result := MsgBox(Text, Title, boxType)
    return (result = "OK" || result = "Yes") ? "YES" : "NO"
}

MapToString(inputMap) {
    result := ""
    for k, v in inputMap
        result .= k " => " v "`n"
    return RTrim(result, "`n")
}


ShowDebugConsole() {
    global DebugConsole, OverlayHWND, OverlayBitmap, OverlayGraphics, OverlayPicHWND
    global OverlayX, OverlayY, OverlayWidth, OverlayHeight
    
    if (DebugConsole != "1" && DebugConsole != 1) {
        return
    }
    if (OverlayHWND && WinExist("ahk_id " OverlayHWND)) {
        return
    }

    OverlayWidth  := Round(A_ScreenWidth  * 0.26)
    OverlayHeight := Round(A_ScreenHeight * 0.185)
    OverlayX      := Round(A_ScreenWidth  * 0.73)
    OverlayY      := Round(A_ScreenHeight * 0.76)

    og := Gui("+AlwaysOnTop +ToolWindow -Caption +E0x20 +E0x08000000 +E0x00000008 +LastFound")
    og.BackColor := "000000"
    og.Title     := "DebugOverlay"
    
    global OverlayPicCtrl := og.Add("Picture", "x0 y0 w" OverlayWidth " h" OverlayHeight " +0xE")
    OverlayPicHWND := OverlayPicCtrl.Hwnd
    OverlayHWND    := og.Hwnd
    
    og.Show("x" OverlayX " y" OverlayY " w" OverlayWidth " h" OverlayHeight " NA")
    
    WinSetTransColor("0x000000", "ahk_id " OverlayHWND)

    OverlayBitmap   := Gdip_CreateBitmap(OverlayWidth, OverlayHeight)
    OverlayGraphics := Gdip_GraphicsFromImage(OverlayBitmap)
    Gdip_SetSmoothingMode(OverlayGraphics, 4)
    
}

HideDebugConsole() {
    global OverlayHWND, OverlayBitmap, OverlayGraphics, OverlayPicHWND
    
    if (OverlayBitmap) { 
        Gdip_DisposeImage(OverlayBitmap)
        OverlayBitmap := 0 
    }
    if (OverlayGraphics) { 
        Gdip_DeleteGraphics(OverlayGraphics)
        OverlayGraphics := 0 
    }
    if (OverlayHWND) {
        WinClose("ahk_id " OverlayHWND)
    }
    OverlayHWND    := 0
    OverlayPicHWND := 0
}

TowerXPOverlayName(name) {
    aliases := Map("Minigunner", "Mini", "Crook Boss", "Crook", "Shotgunner", "Shotgun",
        "Juggernaut", "Jugg", "Operator", "Operator", "Kingpin", "Kingpin",
        "Enforcer", "Enforcer", "Scout", "Scout")
    return aliases.Has(name) ? aliases[name] : name
}

GetTowerXPOverlayLine() {
    global SettingsFile
    if (Integer(IniRead(SettingsFile, "TowerXP", "Enabled", 0)) != 1)
        return ""

    parts := []
    trackedCount := 0
    for definition in TowerXPDefinitions() {
        section := TowerXPSectionName(definition.name)
        if (Integer(IniRead(SettingsFile, section, "Tracked", 0)) != 1)
            continue
        trackedCount += 1
        if (parts.Length >= 3)
            continue
        level := Integer(IniRead(SettingsFile, section, "Level", 0))
        xp := Integer(IniRead(SettingsFile, section, "XP", 0))
        progress := TowerXPAdvance(definition, level, xp)
        status := progress.isMax ? "MAX" : progress.xp "/" progress.nextRequired
        parts.Push(TowerXPOverlayName(definition.name) " L" progress.level " " status)
    }

    if (parts.Length = 0)
        return "Tower XP  enabled - no towers selected"
    line := "Tower XP  "
    for index, part in parts
        line .= (index > 1 ? " | " : "") part
    if (trackedCount > parts.Length)
        line .= " | +" (trackedCount - parts.Length) " more"
    return line
}

GetKronoxFeatureOverlayLine() {
    global SettingsFile, StateFile

    parts := []
    if (KronoxFeatureBool(IniRead(SettingsFile, "Reliability", "AbsoluteMode", 0)))
        parts.Push("ABSOLUTE")
    if (KronoxFeatureBool(IniRead(SettingsFile, "EvolutionQueue", "Enabled", 0))) {
        assignment := KronoxEvolutionAssignmentText(SettingsFile)
        if (assignment != "Waiting for an Abstract strategy")
            parts.Push("Queue " assignment)
        else
            parts.Push("Queue waiting")
    }

    boostFactor := Number(IniRead(StateFile, "State", "ActiveXPBoostFactor", 1))
    boostProfile := IniRead(StateFile, "State", "ActiveXPBoostProfile", "")
    if (boostProfile != "" && boostFactor > 1)
        parts.Push("XP " boostFactor "x")

    if (KronoxFeatureBool(IniRead(SettingsFile, "ResourceBudget", "TimeScaleEnabled", 0))) {
        used := Max(0, Integer(IniRead(StateFile, "State", "BudgetTimescaleUsed", 0)))
        balance := Max(0, Integer(IniRead(SettingsFile, "ResourceBudget", "TicketBalance", 0)))
        parts.Push("TS " used " used / " balance " left")
    }

    if (KronoxFeatureBool(IniRead(SettingsFile, "ResourceBudget", "ConsumableEnabled", 0))) {
        runUsed := Max(0, Integer(IniRead(StateFile, "State", "BudgetConsumablesRun", 0)))
        sessionUsed := Max(0, Integer(IniRead(StateFile, "State", "BudgetConsumablesSession", 0)))
        parts.Push("Items " runUsed " run / " sessionUsed " session")
    }

    if (KronoxFeatureBool(IniRead(StateFile, "State", "CanaryActive", 0)))
        parts.Push("CANARY")
    if (parts.Length = 0)
        return ""
    return "Automation  " KronoxJoin(parts, " | ")
}

UpdateOverlay() {
    global OverlayBitmap, OverlayGraphics, OverlayPicHWND, LogLines, OverlayWidth, OverlayHeight
    global StateFile, AutorunStartTime
    if (!OverlayGraphics) {
        return
    }

    if (IsSet(OverlayGraphics) && OverlayGraphics) {
        if (OverlayGraphics != 0 && OverlayGraphics != "") {
            try {
                Gdip_GraphicsClear(OverlayGraphics, 0x00000000)
            } catch Error as err {
                OverlayGraphics := 0 
                return
            }
        }
    }
    
    fontSize := 12
    fontName := "Consolas", style := 1
    textColor := 0xFFFFFFFF

    runWins := Integer(IniRead(StateFile, "State", "TotalTriumphs", 0))
    runLosses := Integer(IniRead(StateFile, "State", "TotalLosses", 0))
    runCoins := Integer(IniRead(StateFile, "State", "Coins", 0))
    runGems := Integer(IniRead(StateFile, "State", "Gems", 0))
    runExp := Integer(IniRead(StateFile, "State", "EXP", 0))
    runTimeSeconds := Integer(IniRead(StateFile, "State", "TotalTimeSeconds", 0))
    runMatches := runWins + runLosses
    runStarts := Max(runMatches, Integer(IniRead(StateFile, "State", "RunStarts", runMatches)))
    runUnconfirmed := Integer(IniRead(StateFile, "State", "RunUnconfirmed", 0))
    runAborted := Integer(IniRead(StateFile, "State", "RunAborted", 0))
    runActive := (IniRead(StateFile, "State", "ActiveRunId", "") != "") ? 1 : 0
    runResolvedAttempts := Max(runMatches + runUnconfirmed + runAborted, runStarts - runActive)
    runCoverage := (runResolvedAttempts > 0) ? Round((runMatches / runResolvedAttempts) * 100) : 0
    runWinRate := (runMatches > 0) ? Round((runWins / runMatches) * 100) : 0
    runAverageSeconds := (runMatches > 0) ? Round(runTimeSeconds / runMatches) : 0
    runElapsedHours := (AutorunStartTime > 0) ? ((A_TickCount - AutorunStartTime) / 3600000) : 0
    runCoinsPerHour := (runElapsedHours > 0.001) ? Round(runCoins / runElapsedHours) : 0
    runGemsPerHour := (runElapsedHours > 0.001) ? Round(runGems / runElapsedHours) : 0
    runExpPerHour := (runElapsedHours > 0.001) ? Round(runExp / runElapsedHours) : 0
    runRuntime := (AutorunStartTime > 0) ? FormatRuntime(AutorunStartTime) : "00:00"

    statsText := "THIS RUN  Started " runStarts " | W " runWins " | L " runLosses " | WR " runWinRate "% | Coverage " runCoverage "%"
        . "`nCoins " FormatStatsNumber(runCoins) " | Gems " FormatStatsNumber(runGems) " | XP " FormatStatsNumber(runExp)
        . "`nRuntime " runRuntime " | Avg " FormatStatsDuration(runAverageSeconds)
        . " | " FormatStatsNumber(runCoinsPerHour) " C/h | " FormatStatsNumber(runGemsPerHour) " G/h | " FormatStatsNumber(runExpPerHour) " XP/h"
    towerXPLine := GetTowerXPOverlayLine()
    if (towerXPLine != "")
        statsText .= "`n" towerXPLine
    automationLine := GetKronoxFeatureOverlayLine()
    if (automationLine != "")
        statsText .= "`n" automationLine

    hFamilyOverlay := Gdip_FontFamilyCreate(fontName)
    hFontOverlay   := Gdip_FontCreate(hFamilyOverlay, fontSize, style)
    hFormatOverlay := Gdip_StringFormatCreate(0x0000)

    if (!hFormatOverlay || hFormatOverlay == 0 || !hFontOverlay || hFontOverlay == 0) {
        if (hFormatOverlay) => Gdip_DeleteStringFormat(hFormatOverlay)
        if (hFontOverlay) => Gdip_DeleteFont(hFontOverlay)
        if (hFamilyOverlay) => Gdip_DeleteFontFamily(hFamilyOverlay)
        return
    }

    try {
        Gdip_SetStringFormatAlign(hFormatOverlay, 0)
    } catch {
        Gdip_DeleteStringFormat(hFormatOverlay)
        Gdip_DeleteFont(hFontOverlay)
        Gdip_DeleteFontFamily(hFamilyOverlay)
        return
    }

    pBrushTextOverlay := Gdip_BrushCreateSolid(textColor)
    pBrushBgOverlay  := Gdip_BrushCreateSolid(0xE80F0D0E)
    pBrushStatsBg := Gdip_BrushCreateSolid(0xE0180E11)
    pBrushStatsAccent := Gdip_BrushCreateSolid(0xFFEF2B2D)

    if (!pBrushTextOverlay || !pBrushBgOverlay || !pBrushStatsBg || !pBrushStatsAccent) {
        if (pBrushTextOverlay) => Gdip_DeleteBrush(pBrushTextOverlay)
        if (pBrushBgOverlay) => Gdip_DeleteBrush(pBrushBgOverlay)
        if (pBrushStatsBg) => Gdip_DeleteBrush(pBrushStatsBg)
        if (pBrushStatsAccent) => Gdip_DeleteBrush(pBrushStatsAccent)
        Gdip_DeleteStringFormat(hFormatOverlay)
        Gdip_DeleteFont(hFontOverlay)
        Gdip_DeleteFontFamily(hFamilyOverlay)
        return
    }

    statsLineCount := 3 + (towerXPLine != "" ? 1 : 0) + (automationLine != "" ? 1 : 0)
    statsHeight := Round(fontSize * (statsLineCount + 1.45))
    Gdip_FillRectangle(OverlayGraphics, pBrushStatsBg, 5, 3, OverlayWidth - 10, statsHeight)
    Gdip_FillRectangle(OverlayGraphics, pBrushStatsAccent, 5, 3, 4, statsHeight)
    CreateRectF(&StatsRC, 16, 5, OverlayWidth - 24, statsHeight - 4)
    try Gdip_DrawString(OverlayGraphics, statsText, hFontOverlay, hFormatOverlay, pBrushTextOverlay, &StatsRC)

    lineHeight := fontSize * 1.4
    maxLines   := Max(1, Floor((OverlayHeight - statsHeight - 10) / lineHeight))
    startIndex := Max(1, LogLines.Length - maxLines + 1)
    yPos := statsHeight + 8, maxWidth := OverlayWidth - 20

    wrappedLines := []
    Loop maxLines {
        idx := startIndex + A_Index - 1
        if (idx > LogLines.Length)
            break
        line := LogLines[idx]
        while (StrLen(line) > 0) {
            if (StrLen(line) * fontSize * 0.6 <= maxWidth) { 
                wrappedLines.Push(line)
                break 
            }
            cutPos := Floor(maxWidth / (fontSize * 0.6))
            wrappedLines.Push(SubStr(line, 1, cutPos))
            line := SubStr(line, cutPos + 1)
        }
    }
    while (wrappedLines.Length > maxLines)
        wrappedLines.RemoveAt(1)

    for i, line in wrappedLines {
        Gdip_FillRectangle(OverlayGraphics, pBrushBgOverlay, 5, yPos, OverlayWidth-10, fontSize * 1.4)
        CreateRectF(&RC, 5, yPos, OverlayWidth-5, fontSize * 1.4)
        try {
            Gdip_DrawString(OverlayGraphics, line, hFontOverlay, hFormatOverlay, pBrushTextOverlay, &RC)
        }
        yPos += fontSize * 1.4
    }

    Gdip_DeleteBrush(pBrushTextOverlay)
    Gdip_DeleteBrush(pBrushBgOverlay)
    Gdip_DeleteBrush(pBrushStatsBg)
    Gdip_DeleteBrush(pBrushStatsAccent)
    Gdip_DeleteStringFormat(hFormatOverlay)
    Gdip_DeleteFont(hFontOverlay)
    Gdip_DeleteFontFamily(hFamilyOverlay)

    if (IsSet(OverlayBitmap) && OverlayBitmap) {
        try {
            hBitmap := Gdip_CreateHBITMAPFromBitmap(OverlayBitmap)
            SetImage(OverlayPicHWND, hBitmap)
            DeleteObject(hBitmap)
        }
    }
}

WriteRuntimeLog(source, text, level := "INFO") {
    global RuntimeLogDir

    try {
        if !DirExist(RuntimeLogDir)
            DirCreate(RuntimeLogDir)

        cleanText := StrReplace(String(text), "`r", "")
        cleanText := StrReplace(cleanText, "`n", " | ")
        logPath := RuntimeLogDir "\macro-" FormatTime(, "yyyy-MM-dd") ".log"
        line := FormatTime(, "yyyy-MM-dd HH:mm:ss") " [" level "] [" source "] " cleanText "`n"
        FileAppend(line, logPath, "UTF-8")
    }
}

SetMacroPhase(phase, detail := "", timeoutMs := 0) {
    global StateFile, CurrentMacroPhase

    CurrentMacroPhase := phase
    detail := StrReplace(String(detail), "`r", "")
    detail := StrReplace(detail, "`n", " | ")
    previousPhase := ""
    previousDetail := ""
    try previousPhase := IniRead(StateFile, "Health", "Phase", "")
    try previousDetail := IniRead(StateFile, "Health", "Detail", "")

    ownerPid := DllCall("GetCurrentProcessId")
    nowTick := A_TickCount
    IniWrite(ownerPid, StateFile, "Health", "OwnerPID")
    IniWrite(phase, StateFile, "Health", "Phase")
    IniWrite(detail, StateFile, "Health", "Detail")
    IniWrite(nowTick, StateFile, "Health", "PhaseStartedTick")
    IniWrite(nowTick, StateFile, "Health", "HeartbeatTick")
    IniWrite(nowTick, StateFile, "Health", "ProgressTick")
    IniWrite(Max(0, Integer(timeoutMs)), StateFile, "Health", "TimeoutMs")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), StateFile, "Health", "UpdatedAt")

    if (phase != previousPhase || detail != previousDetail)
        WriteRuntimeLog("MAIN", "Phase -> " phase (detail != "" ? " (" detail ")" : ""))
}

TouchMacroHeartbeat(detail := "") {
    global StateFile

    IniWrite(A_TickCount, StateFile, "Health", "HeartbeatTick")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), StateFile, "Health", "UpdatedAt")
    if (detail != "")
        IniWrite(detail, StateFile, "Health", "Detail")
}

TouchMacroProgress(detail := "") {
    global StateFile

    nowTick := A_TickCount
    IniWrite(nowTick, StateFile, "Health", "HeartbeatTick")
    IniWrite(nowTick, StateFile, "Health", "ProgressTick")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), StateFile, "Health", "UpdatedAt")
    if (detail != "")
        IniWrite(detail, StateFile, "Health", "ProgressDetail")
}

ReleaseAutomationInputs() {
    global KeyDownTimes

    ; Release both the known movement/interaction keys and any ordinary key a
    ; recorded Send(... down) step could have left latched. Key-up events do
    ; not invoke Roblox actions, but immediately stop movement and mouse drags.
    keys := ["LButton", "RButton", "MButton", "Shift", "LShift", "RShift", "Ctrl", "LCtrl", "RCtrl",
        "Alt", "LAlt", "RAlt", "Space", "Left", "Right", "Up", "Down", "Tab", "Enter", "Escape"]
    Loop 26
        keys.Push(Chr(96 + A_Index))
    Loop 10
        keys.Push(String(Mod(A_Index, 10)))
    for keyName in keys {
        try SendEvent("{" keyName " up}")
    }
    try KeyDownTimes.Clear()
}

SuspendAutomationInput(reason := "") {
    global InputAutomationSuspended, canUseAbility

    InputAutomationSuspended := true
    canUseAbility := false
    for timerCallback in [UseAbilities, checkCondition, CheckPopups, CancelInviteIfAppeared] {
        try SetTimer(timerCallback, 0)
    }
    ReleaseAutomationInputs()
    if (reason != "")
        WriteRuntimeLog("INPUT", "Automation input suspended: " reason ".", "WARN")
}

ResumeAutomationInput(reason := "") {
    global InputAutomationSuspended, canUseAbility

    InputAutomationSuspended := false
    canUseAbility := true
    if (reason != "")
        WriteRuntimeLog("INPUT", "Automation input enabled: " reason ".")
}

HandleRuntimeError(err, mode) {
    global RunningStrategy, FatalRecoveryScheduled
    message := "Unhandled error"
    try message := err.Message
    location := ""
    try location := err.File (err.Line ? ":" err.Line : "")
    detail := message (location != "" ? " at " location : "") " [mode " mode "]"
    try WriteRuntimeLog("MAIN", detail, "ERROR")
    ; A failed worker thread used to leave ability/click timers alive while a
    ; modal AHK error dialog blocked the main flow. Stop all input immediately;
    ; the watchdog then owns the restart.
    if (RunningStrategy)
        try SuspendAutomationInput("fatal-error")
    try SetMacroPhase("fatal-error", detail, 15000)
    if (RunningStrategy && !FatalRecoveryScheduled) {
        FatalRecoveryScheduled := true
        ; Do not reload from inside AutoHotkey's error callback. Queue recovery
        ; on a clean thread so OCR/COM failures cannot strand the last UI status.
        try SetTimer(RecoverFromRuntimeError.Bind(detail), -1000)
    }
    return RunningStrategy
}

RecoverFromRuntimeError(detail, *) {
    global RunningStrategy
    if (RunningStrategy)
        SafeReload("fatal-error")
}

LogToConsole(text, SendWebhookInstantly := false, flush := true) {
    global DebugConsole, LogLines, OverlayHWND, WebhookEnabled, WebhookLink, RunningStrategy, AutorunStartTime

    time := FormatTime(, "HH:mm:ss")
    formattedText := "[" time "] " text
    WriteRuntimeLog("MAIN", text)
    LogLines.Push(formattedText)
    while (LogLines.Length > 500)
        LogLines.RemoveAt(1)

    if (OverlayHWND && WinExist("ahk_id " OverlayHWND))
        UpdateOverlay()

    if (WebhookEnabled && WebhookLink != "" && RunningStrategy) {
        runtime := (AutorunStartTime > 0) ? FormatRuntime(AutorunStartTime) : "00:00"
        wText := "[" runtime "] " text
        if (!SendWebhookInstantly && WebhookDebugLogs) {
            SendToWebhook(wText)
        } else if (SendWebhookInstantly) {
            SendToWebhookInstant(wText,,flush)
        }
    }
}

FormatRuntime(StartTicks) {
    if (StartTicks = 0) {
        return "00:00"
    }
    elapsed := Floor((A_TickCount - StartTicks) / 1000)
    h := Floor(elapsed / 3600)
    m := Floor(Mod(elapsed, 3600) / 60)
    s := Mod(elapsed, 60)
    return (h > 0) ? Format("{:d}:{:02d}:{:02d}", h, m, s) : Format("{:d}:{:02d}", m, s)
}

claimPlaytimeRewards() { 
    global CollectPlaytimeRewards, NextCheckInterval
    
    if (CollectPlaytimeRewards != "1" && CollectPlaytimeRewards != 1) {
        return
    }
    Sleep(2000) ; load
    
    getRobloxPos(&pX, &pY, &w, &h)
    popupColor := PixelGetColor(w - 268, pY + 5, "RGB")
    r1 := (popupColor >> 16) & 0xFF, g1 := (popupColor >> 8) & 0xFF, b1 := popupColor & 0xFF
    r2 := 0xEE, g2 := 0x18, b2 := 0x18
    diff := Sqrt((r1-r2)**2 + (g1-g2)**2 + (b1-b2)**2)

    
    if (diff < 3) {
        LogToConsole("Claiming playtime rewards..")
        Click(w - 290, pY + 32)
        
        Sleep(1000)

        openedMenu := false
        Loop 15 {
            getRobloxPos(&pX, &pY, &w, &h)
            X1 := Round(w * 0.2)
            Y1 := Round(h * 0.15)
            W := Round(w * 1) - X1
            H := Round(h * 0.4) - Y1
            resclose := AdvImageSearch("Resources\close_freerewards.png", X1, Y1, W, H)

            If (resclose.status = "success" && resclose.score >= 0.86) {
                openedMenu := true
                break
            } 
            Sleep(300)
        }

        if (!openedMenu) {
            getRobloxPos(&pX, &pY, &w, &h)
            MouseMove(w - 290, pY + 32, A_DefaultMouseSpeed+1)
            Sleep(50)
            MouseClick()

            openedMenu := false
            Loop 25 {
                getRobloxPos(&pX, &pY, &w, &h)
                X1 := Round(w * 0.2)
                Y1 := Round(h * 0.15)
                W := Round(w * 1) - X1
                H := Round(h * 0.4) - Y1
                resclose := AdvImageSearch("Resources\close_freerewards.png", X1, Y1, W, H)

                If (resclose.status = "success" && resclose.score >= 0.86) {
                    openedMenu := true
                    break
                } 

                res := AdvImageSearch("Resources/Claim.png", Round(w * 0.25), Round(h * 0.4), Round(w * 0.5), Round(h * 0.5), 0.5, 2)
                if (res.status = "success" && res.score >= 0.65) {
                    Click(res.x, res.y)
                }

                Sleep(300)
            }

            if (!openedMenu) {
                LogToConsole("Failed to claim rewards!", true, false)
                return
            }
        }

        rewardsCollected := false
        
        Loop {
            getRobloxPos(&pX, &pY, &w, &h)
            
            Loop 10 {
                if (PixelSearch(&cx, &cy, Round(w*0.25), Round(h*0.2), Round(w*0.55), Round(h*0.76), 0x64F711, 5)) 
                    break
                else 
                    Sleep(100)
            }

            if (!PixelSearch(&cx, &cy, Round(w*0.25), Round(h*0.2), Round(w*0.55), Round(h*0.76), 0x64F711, 5)) {
                break
            }
            
            Click(cx, cy)
            rewardsCollected := true
            Sleep(500)

            Loop {
                resConfirm := AdvImageSearch("Resources/claimreward.png", Round(w*0.25), Round(h*0.5), Round(w*0.5), Round(h*0.5),,1.5)
                
                if (resConfirm.status == "success" && resConfirm.score > 0.65) {
                    Click(resConfirm.x, resConfirm.y)
                    MouseMove(ScaleX(unfocusX), ScaleY(unfocusY))
                    Sleep(800)
                } else {
                    Sleep(300)
                    resConfirm := AdvImageSearch("Resources/claimreward.png", Round(w*0.25), Round(h*0.5), Round(w*0.5), Round(h*0.5),,1.5)
                    if (resConfirm.status == "success" && resConfirm.score > 0.65) {
                        continue
                    }
                    break
                }
            }
        }

        Sleep(800) 
 
        getRobloxPos(&pX, &pY, &w, &h)
    
        x1 := Round(w*0.39)
        y1 := Round(h*0.36)
        x2 := Round(w*0.22)
        y2 := Round(h*0.4)

        langCode := "en-US"
        for availableLang in StrSplit(OCR.GetAvailableLanguages(), "`n", "`r") {
            if (availableLang != "" && SubStr(availableLang, 1, 2) = "en") {
                langCode := availableLang
                break
            }
        }
        
        ocrResult := OCR.FromRect(x1, y1, x2, y2, {lang: langCode, invertcolors: 1, scale: 2})
        textOnScreen := ocrResult.Text

        claimedCount := 0
        StrReplace(textOnScreen, "CLAIMED", , , &claimedCount)
        
        if (claimedCount != 0) {
            LogToConsole("Claimed free rewards (" . claimedCount . "/6)")   
        }

        if (claimedCount >= 6) {
            LogToConsole("All rewards collected! Next check in 24 hours.")
            NextCheckInterval := 86400000 
        } else {
            LogToConsole("Not all rewards collected. Next check in 2 hours.")
            NextCheckInterval := 7200000  
        }

        X1 := Round(w * 0.2)
        Y1 := Round(h * 0.15)
        W := Round(w * 1) - X1
        H := Round(h * 0.4) - Y1
        resclose := AdvImageSearch("Resources\close_freerewards.png", X1, Y1, W, H)

        If (resclose.status = "success" && resclose.score >= 0.86) {
            Click(resclose.x, resclose.y)
        } else {
            Click(ScaleX(1126), ScaleY(307))
        }
    }
    UpdateDailyRewardTime()
}

UpdateDailyRewardTime() {
    global StateFile, NextCheckInterval
    
    
    if (!HasGlobal("NextCheckInterval") || NextCheckInterval == "") {
        NextCheckInterval := 7200000
    }
    
    
    IniWrite(A_Now, StateFile, "State", "LastDailyCheck")
    IniWrite(NextCheckInterval, StateFile, "State", "NextCheckInterval")
}

CheckDailyRewardTime() {
    global StateFile
    
    lastCheckTime := IniRead(StateFile, "State", "LastDailyCheck", "")
    
    currentIntervalMs := Integer(IniRead(StateFile, "State", "NextCheckInterval", "7200000"))
    
    if (lastCheckTime == "") {
        return true
    }

    intervalSeconds := currentIntervalMs / 1000
    
    try {
        timeDiffSeconds := DateDiff(A_Now, lastCheckTime, "Seconds")
        
        if (timeDiffSeconds >= intervalSeconds) {
            return true
        }
    } catch {
        return true
    }
    
    return false
}



HasGlobal(varName) {
    try {
        return %varName% !== ""
    } catch {
        return false
    }
}

closeChat() {
    getRobloxPos(&pX, &pY, &w, &h)
    chatColor := PixelGetColor(pX + 140, pY + 29, "RGB")
    r1 := (chatColor >> 16) & 0xFF, g1 := (chatColor >> 8) & 0xFF, b1 := chatColor & 0xFF
    r2 := 0xF4, g2 := 0xF5, b2 := 0xF8
    diff := Sqrt((r1-r2)**2 + (g1-g2)**2 + (b1-b2)**2)
    if (diff < 12) {
        MouseGetPos(&cx, &cy)
        MouseMove(pX + 140, pY + 35, 2)
        Sleep(100)
        Click()
        Sleep(100)
        MouseMove(cx, cy)
        LogToConsole("Closed chat")
    }
}


SendToWebhook(message) {
    global WebhookQueue, WebhookTimerActive
    if (message = "" || Trim(message) = "") {
        return
    }
    WebhookQueue.Push(message)
    if (!WebhookTimerActive) {
        WebhookTimerActive := true
        SetTimer(ProcessWebhookQueue, -100)
    }
}

SendToWebhookInstant(message, embedColor := 3447003, flush := true) {
    global WebhookInstantQueue, WebhookInstantTimerActive, WebhookEnabled
    if (!WebhookEnabled || message = "" || Trim(message) = "") { 
        return
    }
    if (flush) {
        FlushWebhookQueue()
    }

    WebhookInstantQueue.Push({msg: message, color: embedColor})
    
    if (!WebhookInstantTimerActive) {
        WebhookInstantTimerActive := true
        SetTimer(ProcessWebhookInstantQueue, -100)
    }
}

ProcessWebhookInstantQueue() { 
    global WebhookInstantQueue, WebhookInstantTimerActive, WebhookLink

    static whr := ComObject("WinHttp.WinHttpRequest.5.1")

    if (WebhookInstantQueue.Length = 0) { 
        WebhookInstantTimerActive := false 
        return 
    }
    
    allMessages := ""
    finalColor := 3447003
    hasCustomColor := false
    
    while (WebhookInstantQueue.Length > 0) {
        item := WebhookInstantQueue.RemoveAt(1)
        if (Trim(item.msg) = "") 
            continue
            
        allMessages .= (allMessages != "") ? "`n" item.msg : item.msg
        
        if (item.color != 3447003) {
            finalColor := item.color
            hasCustomColor := true
        }
    }
    
    WebhookInstantTimerActive := false
    if (allMessages = "") 
        return
        
    if (!hasCustomColor) {
        lower := Format("{:L}", allMessages)
        if (InStr(lower, "error") || InStr(lower, "failed") || InStr(lower, "reloading")) {
            finalColor := 15158332
        } else if (InStr(lower, "success") || InStr(lower, "completed")) {
            finalColor := 3066993
        } else if (InStr(lower, "warning")) {
            finalColor := 16776960
        }
    }
    
    escaped := StrReplace(StrReplace(StrReplace(allMessages, "\", "\\"), '"', '\"'), "`n", "\n")
    payload := '{"embeds":[{"description":"' escaped '","color":' finalColor '}]}'
    
    try {
        whr.Open("POST", WebhookLink, true)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.SetTimeouts(5000, 5000, 8000, 8000)
        whr.Send(payload)
    } catch Error as err {
        LogToConsole("Webhook send failed: " err.Message)
    }
}


ProcessWebhookQueue() {
    global WebhookQueue, WebhookTimerActive, WebhookLink
    static whr := ComObject("WinHttp.WinHttpRequest.5.1")
    
    if (WebhookQueue.Length = 0) { 
        WebhookTimerActive := false 
        return 
    }
    if (WebhookQueue.Length < 20) { 
        SetTimer(ProcessWebhookQueue, -2000) 
        return 
    }
    
    allMessages := ""
    Loop 20 {
        if (WebhookQueue.Length = 0) 
            break
        
        msg := WebhookQueue.RemoveAt(1)
        if (Trim(msg) = "") 
            continue
            
        escaped := StrReplace(msg, "\", "\\")
        escaped := StrReplace(escaped, '"', '\"')
        escaped := StrReplace(escaped, "`n", "\n")
        escaped := StrReplace(escaped, "`r", "")
        
        if (Trim(escaped) = "") 
            continue
            
        allMessages .= escaped "\n"
    }
    
    if (allMessages = "") { 
        WebhookTimerActive := false 
        return 
    }
    
    allMessages := RTrim(allMessages, "\n")
    
    embedColor := 9868950
    payload := '{"embeds":[{"description":"``````\n' allMessages '\n``````","color":' embedColor '}]}'
    
    try {
        whr.Open("POST", WebhookLink, true)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(payload)
    } catch Error {
    }
    
    if (WebhookQueue.Length > 0)
        SetTimer(ProcessWebhookQueue, -1000)
    else
        WebhookTimerActive := false
}


FlushWebhookQueue() {
    global WebhookQueue, WebhookTimerActive, WebhookLink
    
    if (WebhookQueue.Length = 0) 
        return
        
    WebhookTimerActive := false
    SetTimer(ProcessWebhookQueue, 0)
    
    allMessages := ""
    while (WebhookQueue.Length > 0) {
        msg := WebhookQueue.RemoveAt(1)
        if (Trim(msg) = "") 
            continue

        escaped := StrReplace(msg, "\", "\\")
        escaped := StrReplace(escaped, '"', '\"')
        escaped := StrReplace(escaped, "`n", "\n")
        escaped := StrReplace(escaped, "`r", "")
        
        if (Trim(escaped) = "") 
            continue
            
        allMessages .= escaped "\n"
    }
    
    if (allMessages = "") 
        return
        
    allMessages := RTrim(allMessages, "\n")
    
    embedColor := 9868950
    payload := '{"embeds":[{"description":"``````\n' allMessages '\n``````","color":' embedColor '}]}'
    
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", WebhookLink, false)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.SetTimeouts(5000, 5000, 8000, 8000)
        whr.Send(payload)
    } catch Error as err {
        LogToConsole("Webhook send failed: " err.Message)
    }
}

SafeReload(reason := "automatic-recovery") {
    global RestartLock, StateFile, RunningStrategy, OverlayHWND, MainGui
    if (RestartLock) {
        return
    }
    RestartLock := true
    WriteRuntimeLog("MAIN", "Safe reload requested: " reason, "WARN")
    SuspendAutomationInput("reload:" reason)
    SetMacroPhase("reloading", reason, 0)
    KillSubmacros()
    if (OverlayHWND) {
        WinClose("ahk_id " OverlayHWND)
    }
    
    if (IsSet(MainGui) && MainGui) {
        MainGui.Destroy()
    }
    
    DeleteAllIndicators()
    if (RunningStrategy) {
        currentStrat := IniRead(StateFile, "State", "Strategy", "")
        if (currentStrat != "") {
            IniWrite(1, StateFile, "State", "Running")
        }
    } 

    FlushWebhookQueue()

    Reload()
}

startWatchdog() {
    global watchdogPID

    if (watchdogPID != "" && ProcessExist(watchdogPID))
        return

    currentPID := DllCall("GetCurrentProcessId")
    if (A_PtrSize == 4) {
    Run('"' A_ScriptDir '\submacros\AutoHotkey32.exe" "' A_ScriptDir '\submacros\watchdog.ahk" ' currentPID, , , &watchdogPID)
    } else {
    Run('"' A_ScriptDir '\submacros\AutoHotkey64.exe" "' A_ScriptDir '\submacros\watchdog.ahk" ' currentPID, , , &watchdogPID)
    }
}

KillSubmacros() {
    global watchdogPID
    
    if (watchdogPID != "") {
        try {
            RunWait(A_ComSpec " /c taskkill /PID " watchdogPID " /F /T", , "Hide")
        } catch Error {
        }
        watchdogPID := ""
    }
    
    try {
        for process in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'AutoHotkey64.exe' OR Name = 'AutoHotkey.exe' OR Name = 'AutoHotkey32.exe'") {
            try {
                cmd := process.CommandLine
                if (InStr(cmd, "watchdog.ahk")) {
                    try {
                        process.Terminate()
                    } catch Error {
                        continue
                    }
                }
            } catch Error {
                continue
            }
        }
    } catch Error {
        return
    }
}

HandleExit(ExitReason, ExitCode) {
    global StateFile, SettingsFile, RunningStrategy

    try SuspendAutomationInput("process-exit:" ExitReason)
    try StopKronoxDiscordBot()

    if (RunningStrategy) {
        KillSubmacros()
        if (ExitReason = "Close" || ExitReason = "Menu" || ExitReason = "Shutdown" || ExitReason = "Logoff") {
            IniWrite(0, StateFile, "State", "Running")
            IniDelete(StateFile, "State", "Strategy")
            IniDelete(StateFile, "State", "StartTime")
            IniDelete(StateFile, "State", "CurrentStratStartTime")
            IniDelete(StateFile, "State", "CurrentRotationIndex")
            IniDelete(StateFile, "State", "CurrentRunCount")
            IniDelete(StateFile, "State", "Coins")
            IniDelete(StateFile, "State", "Gems")
            IniDelete(StateFile, "State", "EXP")
            IniDelete(StateFile, "State", "TotalTriumphs")
            IniDelete(StateFile, "State", "TotalLosses")
            IniDelete(StateFile, "State", "TotalTimeSeconds")
            IniDelete(StateFile, "State", "RunStarts")
            IniDelete(StateFile, "State", "RunUnconfirmed")
            IniDelete(StateFile, "State", "RunAborted")
            IniDelete(StateFile, "State", "Timescale")
            IniDelete(StateFile, "State", "TimeWhenStartedPlaying")
            KronoxClearRemoteSessionRequests()
        }
    }
}

CleanupGdip(exitReason, exitCode) {
    global pToken
    Gdip_Shutdown(pToken)
}

MainGui.OnEvent("Close", (*) => ExitApp())

CheckOcrLanguage() {
    try {
        rawLangs := OCR.GetAvailableLanguages()
        hasEnglish := false
        
        availableLangs := StrSplit(rawLangs, ["`n", "`r", ",", " "])
        
        for lang in availableLangs {
            if (lang = "")
                continue
                
            if InStr(lang, "en") {
                hasEnglish := true
                break
            }
        }
        
        if (!hasEnglish) {
            msgText := "English language pack for OCR (text detection) is not installed on your system!`n`n"
                    . "Without it, the script cannot read text from the screen properly.`n`n"
                    . "Would you like to open Windows Settings to download the Language?"
            
            result := MsgBox(msgText, "Missing OCR Language", 48 + 4)
            
            if (result = "Yes") {
                Run("ms-settings:regionlanguage")
            }
            
            ExitApp()
        }
    }
}

SendScreenshot(pBitmap := Gdip_BitmapFromScreen(), description := "", color := 12434877, screenshot := WebhookScreenshots) {
    global WebhookLink

    escapedDescription := StrReplace(description, "\", "\\")
    escapedDescription := StrReplace(escapedDescription, '"', '\"')
    escapedDescription := StrReplace(escapedDescription, "`n", "\n")

    fields := []

    if (screenshot == "0" || screenshot == 0) {
        payload_json := '{"embeds": [{"description": "' escapedDescription '", "color": ' color '}]}'
        fields.Push(Map("name", "payload_json", "content-type", "application/json", "content", payload_json))
    } 
    else {
        payload_json := '{"embeds": [{"description": "' escapedDescription '", "color": ' color ', "image": {"url": "attachment://screenshot.png"}}]}'
        fields.Push(Map("name", "payload_json", "content-type", "application/json", "content", payload_json))
        fields.Push(Map("name", "files[0]", "filename", "screenshot.png", "content-type", "image/png", "pBitmap", pBitmap))
    }
    
    CreateFormData(&postdata, &contentType, fields)

    if (screenshot != "0" && screenshot != 0) {
        try Gdip_DisposeImage(pBitmap)
    }

    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", WebhookLink "?wait=true", false)
        whr.SetRequestHeader("Content-Type", contentType)
        whr.SetTimeouts(5000, 5000, 15000, 15000)
        whr.Send(postdata)
    } catch Error as err {
        LogToConsole("Screenshot webhook failed: " err.Message)
    }
}

CreateFormData(&retData, &contentType, fields) {
    chars := "0123456789abcdefghijklmnopqrstuvwxyz"
    boundary := ""
    Loop 12 {
        boundary .= SubStr(chars, Random(1, StrLen(chars)), 1)
    }

    hData := DllCall("GlobalAlloc", "UInt", 0x2, "UPtr", 0, "Ptr")
    DllCall("ole32\CreateStreamOnHGlobal", "Ptr", hData, "Int", 0, "PtrP", &pStream)

    for index, field in fields {
        str := "`r`n------------------------------" boundary "`r`n"
        str .= 'Content-Disposition: form-data; name="' field["name"] '"'
        if (field.Has("filename"))
            str .= '; filename="' field["filename"] '"'
        str .= "`r`nContent-Type: " field["content-type"] "`r`n`r`n"
        if (field.Has("content"))
            str .= field["content"] "`r`n"

        length := StrPut(str, "UTF-8") - 1
        utf8 := Buffer(length)
        StrPut(str, utf8, length, "UTF-8")
        DllCall("shlwapi\IStream_Write", "Ptr", pStream, "Ptr", utf8, "UInt", length, "UInt")

        if (field.Has("pBitmap")) {
            try {
                pFileStream := Gdip_SaveBitmapToStream(field["pBitmap"])
                DllCall("shlwapi\IStream_Size",  "Ptr", pFileStream, "UInt64*", &size := 0, "UInt")
                DllCall("shlwapi\IStream_Reset", "Ptr", pFileStream, "UInt")
                DllCall("shlwapi\IStream_Copy",  "Ptr", pFileStream, "Ptr", pStream, "UInt", size, "UInt")
                ObjRelease(pFileStream)
            } catch Error as err {
                LogToConsole("Failed to attach screenshot to webhook: " err.Message)
            }
        }
    }

    str := "`r`n------------------------------" boundary "--`r`n"
    length := StrPut(str, "UTF-8") - 1
    utf8 := Buffer(length)
    StrPut(str, utf8, length, "UTF-8")
    DllCall("shlwapi\IStream_Write", "Ptr", pStream, "Ptr", utf8, "UInt", length, "UInt")
    ObjRelease(pStream)

    pData := DllCall("GlobalLock", "Ptr", hData, "Ptr")
    size  := DllCall("GlobalSize", "Ptr", pData, "UPtr")
    retData := ComObjArray(0x11, size)
    pvData  := NumGet(ComObjValue(retData), 8 + A_PtrSize, "Ptr")
    DllCall("RtlMoveMemory", "Ptr", pvData, "Ptr", pData, "Ptr", size)
    DllCall("GlobalUnlock", "Ptr", hData)
    DllCall("GlobalFree",   "Ptr", hData, "Ptr")
    contentType := "multipart/form-data; boundary=----------------------------" boundary
}

InArray(arr, value) {
    for item in arr
        if (item = value)
            return true
    return false
}

CreateGradientButton(w, h, r, colorStart, colorEnd, shadowColor, strokeColor, btnText := "...", textFont := "Segoe UI", textSize := 12, gradientDirection := 0) {
    hdc := GetDC(0)
    hbm := CreateDIBSection(w, h)
    hdcMem := CreateCompatibleDC()
    obm := SelectObject(hdcMem, hbm)
    G := Gdip_GraphicsFromHDC(hdcMem)
    
    DllCall("gdiplus\GdipSetInterpolationMode", "ptr", G, "int", 7)
    
    pad := 6
    bx := pad, by := pad, bw := w - (pad * 2), bh := h - (pad * 2)

    Gdip_SetSmoothingMode(G, 4)
    Gdip_SetTextRenderingHint(G, 4) 

    Loop 6 {
        alpha := Format("{:02X}", Integer(25 / A_Index))
        currentShadow := "0x" alpha SubStr(shadowColor, -6)
        pBrushShadow := Gdip_BrushCreateSolid(currentShadow)
        
        offset := A_Index * 0.7
        pPathShadow := Gdip_CreateRoundRectanglePath(bx - (offset*0.5), by + offset, bw + offset, bh, r)
        Gdip_FillPath(G, pBrushShadow, pPathShadow)
        Gdip_DeletePath(pPathShadow)
        Gdip_DeleteBrush(pBrushShadow)
    }

    pBrushGrad := Gdip_CreateLineBrushFromRect(bx, by, bw, bh, colorStart, colorEnd, gradientDirection, 1)
    pPathMain := Gdip_CreateRoundRectanglePath(bx, by, bw, bh, r)
    Gdip_FillPath(G, pBrushGrad, pPathMain)

    pPathStroke := Gdip_CreateRoundRectanglePath(bx + 0.5, by + 0.5, bw - 1, bh - 1, r)
    pPenStroke := Gdip_CreatePen(strokeColor, 1)
    Gdip_DrawPath(G, pPenStroke, pPathStroke)
    Gdip_DeletePath(pPathStroke)
    Gdip_DeletePen(pPenStroke)
    
    hFormat := Gdip_StringFormatCreate(0x4000) 
    Gdip_SetStringFormatAlign(hFormat, 1)     
    DllCall("gdiplus\GdipSetStringFormatLineAlign", "ptr", hFormat, "int", 1) 
    
    Gdip_SetSmoothingMode(G, 0)
    Gdip_SetTextRenderingHint(G, 0) 

    hFontfamily := Gdip_FontFamilyCreate(textFont)
    hFont := Gdip_FontCreate(hFontfamily, textSize, 1) 
    RC := Buffer(16, 0)
    
    NumPut("float", bx, "float", by + 1, "float", bw, "float", bh, RC)
    pBrushTxtShadow := Gdip_BrushCreateSolid("0x99000000")
    
    Gdip_DrawString(G, btnText, hFont, hFormat, pBrushTxtShadow, &RC)
    Gdip_DeleteBrush(pBrushTxtShadow)
    
    NumPut("float", bx, "float", by, "float", bw, "float", bh, RC)
    pBrushTxtMain := Gdip_BrushCreateSolid("0xFFFFFFFF")
    
    Gdip_DrawString(G, btnText, hFont, hFormat, pBrushTxtMain, &RC)
    Gdip_DeleteBrush(pBrushTxtMain)

    Gdip_DeleteFont(hFont)
    Gdip_DeleteFontFamily(hFontfamily)
    Gdip_DeleteStringFormat(hFormat)
    Gdip_DeletePath(pPathMain)
    Gdip_DeleteBrush(pBrushGrad)
    
    SelectObject(hdcMem, obm)
    DeleteDC(hdcMem)
    ReleaseDC(0, hdc)
    Gdip_DeleteGraphics(G)
    
    return hbm
}

CreateFrame(w, h, r, bgColor, strokeOuter, strokeInner) {
    hbm := CreateDIBSection(w, h), hdcMem := CreateCompatibleDC()
    obm := SelectObject(hdcMem, hbm), G := Gdip_GraphicsFromHDC(hdcMem)
    Gdip_SetSmoothingMode(G, 4)

    pBrushBg := Gdip_BrushCreateSolid(bgColor)
    pPathMain := Gdip_CreateRoundRectanglePath(0, 0, w, h, r)
    Gdip_FillPath(G, pBrushBg, pPathMain)

    pPathOuter := Gdip_CreateRoundRectanglePath(0.5, 0.5, w - 1, h - 1, r)
    pPenOuter := Gdip_CreatePen(strokeOuter, 1)
    Gdip_DrawPath(G, pPenOuter, pPathOuter)

    pPathInner := Gdip_CreateRoundRectanglePath(1.5, 1.5, w - 3, h - 3, r - 1)
    pPenInner := Gdip_CreatePen(strokeInner, 1)
    Gdip_DrawPath(G, pPenInner, pPathInner)

    Gdip_DeletePen(pPenInner), Gdip_DeletePath(pPathInner)
    Gdip_DeletePen(pPenOuter), Gdip_DeletePath(pPathOuter)
    Gdip_DeletePath(pPathMain), Gdip_DeleteBrush(pBrushBg)
    SelectObject(hdcMem, obm), DeleteDC(hdcMem), Gdip_DeleteGraphics(G)
    return hbm
}


CreateScrollThumb(w, h, r, colorStart, colorEnd, glowColor) {
    hbm := CreateDIBSection(w, h), hdcMem := CreateCompatibleDC()
    obm := SelectObject(hdcMem, hbm), G := Gdip_GraphicsFromHDC(hdcMem)
    Gdip_SetSmoothingMode(G, 4)

    Loop 3 {
        alpha := Format("{:02X}", Integer(30 / A_Index))
        pBrush := Gdip_BrushCreateSolid("0x" alpha SubStr(glowColor, -6))
        pPath := Gdip_CreateRoundRectanglePath(0, A_Index*0.5, w, h, r)
        Gdip_FillPath(G, pBrush, pPath), Gdip_DeletePath(pPath), Gdip_DeleteBrush(pBrush)
    }
    
    pBrushGrad := Gdip_CreateLineBrushFromRect(0, 0, w, h, colorStart, colorEnd, 1, 1)
    pPathMain := Gdip_CreateRoundRectanglePath(0, 0, w, h, r)
    Gdip_FillPath(G, pBrushGrad, pPathMain)
    
    Gdip_DeletePath(pPathMain), Gdip_DeleteBrush(pBrushGrad)
    SelectObject(hdcMem, obm), DeleteDC(hdcMem), Gdip_DeleteGraphics(G)
    return hbm
}


CreateGlowButton(w, h, r, colorStart, colorEnd, glowColor) {
    hdc := GetDC(0)
    hbm := CreateDIBSection(w, h)
    hdcMem := CreateCompatibleDC()
    obm := SelectObject(hdcMem, hbm)
    G := Gdip_GraphicsFromHDC(hdcMem)
    Gdip_SetSmoothingMode(G, 4)

    pad := 5
    bx := pad, by := pad, bw := w - (pad * 2), bh := h - (pad * 2)

    Loop 5 {
        alpha := Format("{:02X}", Integer(15 - (A_Index * 2)))
        currentGlow := SubStr(glowColor, 1, 4) . alpha . SubStr(glowColor, 7)
        
        pBrushGlow := Gdip_BrushCreateSolid(currentGlow)
        pPathGlow := Gdip_CreateRoundRectanglePath(bx - A_Index, by - A_Index, bw + (A_Index * 2), bh + (A_Index * 2), r)
        Gdip_FillPath(G, pBrushGlow, pPathGlow)
        Gdip_DeletePath(pPathGlow)
        Gdip_DeleteBrush(pBrushGlow)
    }

    pBrushGrad := Gdip_CreateLineBrushFromRect(bx, by, bw, bh, colorStart, colorEnd, 1, 1)
    pPathMain := Gdip_CreateRoundRectanglePath(bx, by, bw, bh, r)
    Gdip_FillPath(G, pBrushGrad, pPathMain)

    pPenStroke := Gdip_CreatePen("0x60FFFFFF", 1)
    Gdip_DrawPath(G, pPenStroke, pPathMain)

    Gdip_DeletePen(pPenStroke)
    Gdip_DeletePath(pPathMain)
    Gdip_DeleteBrush(pBrushGrad)
    SelectObject(hdcMem, obm)
    DeleteDC(hdcMem)
    ReleaseDC(0, hdc)
    Gdip_DeleteGraphics(G)
    
    return hbm
}

Gdip_CreateRoundRectanglePath(x, y, w, h, r) {
    DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &pPath := 0)
    DllCall("gdiplus\GdipAddPathArc", "ptr", pPath, "float", x, "float", y, "float", r*2, "float", r*2, "float", 180, "float", 90)
    DllCall("gdiplus\GdipAddPathArc", "ptr", pPath, "float", x+w-r*2, "float", y, "float", r*2, "float", r*2, "float", 270, "float", 90)
    DllCall("gdiplus\GdipAddPathArc", "ptr", pPath, "float", x+w-r*2, "float", y+h-r*2, "float", r*2, "float", r*2, "float", 0, "float", 90)
    DllCall("gdiplus\GdipAddPathArc", "ptr", pPath, "float", x, "float", y+h-r*2, "float", r*2, "float", r*2, "float", 90, "float", 90)
    DllCall("gdiplus\GdipClosePathFigure", "ptr", pPath)
    return pPath
}

StratInfo(title := "unknown strat", author := "darksen", RequiredTowrs := "error", modifs := "none", desc := "") {
    text := title " by " author "`n"
    text .= "-----------------------------------------`n`n"
    text .= "Required towers:`t" RequiredTowrs "`n"
    text .= "Modifiers:`t" modifs "`n`n"
    
    if (desc != "")
        text .= desc "`n`n"
        
    text .= "-----------------------------------------`n"
    text .= "* To edit the strategy, open the strat file in the notepad.`n"

    MsgBox(text, "Strategy Info | " title, 0x1040)
}

; reads tds message (e.g., "You cannot place here")
; returns 1 if the given text is found, 0 if not
; ReadMessage(["already", "current", "rotation"]), for example
; works only with red color
ReadMessage(includeStr := "", includeRx := "", excludeStr := "", excludeRx := "") {
    langCode := "en-US"
    for availableLang in StrSplit(OCR.GetAvailableLanguages(), "`n", "`r") {
        if (availableLang != "" && SubStr(availableLang, 1, 2) = "en") {
            langCode := availableLang
            break
        }
    }

    getRobloxPos(,,&w,&h)
    x := Round(w * 0.2), y := Round(h * 0.18)
    width := Round(w * 0.7) - x, height := Round(h * 0.35) - y

    if (width <= 0 || height <= 0)
        return false

    pBitmap := Gdip_BitmapFromScreen(x "|" y "|" width "|" height)
    pGraphics := Gdip_GraphicsFromImage(pBitmap)
    Matrix := "
    (
    5.0|0.0|0.0|0.0|0.0|
    0.0|-5.0|0.0|0.0|0.0|
    0.0|0.0|-5.0|0.0|0.0|
    0.0|0.0|0.0|1.0|0.0|
    -2.5|1.0|1.0|0.0|1.0
    )"
    pBitmapFiltered := Gdip_CreateBitmap(width, height)
    pGraphicsFiltered := Gdip_GraphicsFromImage(pBitmapFiltered)
    Gdip_DrawImage(pGraphicsFiltered, pBitmap, 0, 0, width, height, 0, 0, width, height, Matrix)
    hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmapFiltered)

    ocrResult := OCR.FromBitmap(hBitmap, {lang: langCode, scale: 3, grayscale: 1})

    DeleteObject(hBitmap)
    Gdip_DisposeImage(pBitmapFiltered), Gdip_DeleteGraphics(pGraphicsFiltered)
    Gdip_DeleteGraphics(pGraphics), Gdip_DisposeImage(pBitmap)

    ocrText := ocrResult.Text

    for s in (HasMethod(excludeStr, "__Enum") ? excludeStr : [excludeStr]) {
        if (s != "" && RegExMatch(ocrText, "i)\b" . s . "\b"))
            return false
    }
    for rx in (HasMethod(excludeRx, "__Enum") ? excludeRx : [excludeRx]) {
        if (rx != "" && RegExMatch(ocrText, "i)" . rx))
            return false
    }

    matchStr := (includeStr == "")
    for s in (HasMethod(includeStr, "__Enum") ? includeStr : [includeStr]) {
        if (s != "" && RegExMatch(ocrText, "i)\b" . s . "\b")) {
            matchStr := true
            break
        }
    }

    matchRx := (includeRx == "")
    for rx in (HasMethod(includeRx, "__Enum") ? includeRx : [includeRx]) {
        if (rx != "" && RegExMatch(ocrText, "i)" . rx)) {
            matchRx := true
            break
        }
    }

    return matchStr && matchRx
}

waitForTowerUI(&resV2 := "", &resV1 := "", timeout := 0) {
    global PotatoMode
    StartTime := A_TickCount
    Loop {
        getRobloxPos(&rx, &ry, &w, &h)
        X1_v2 := Round(w * 0.02)
        Y1_v2 := Round(h/2.5)
        W_v2 := Round(w * 0.22) - X1_v2
        H_v2 := Round(w * 0.95) - Y1_v2

        resV2 := AdvImageSearch("Resources\TowerUI\Variant2.png", X1_v2, Y1_v2, W_v2, H_v2, ,,0.05)

        if (resV2.status == "success" && resV2.score > 0.55) {
            return true
        }

        Sleep(30)

        X1_v1 := Round(w * 0.16)
        Y1_v1 := Round(h * 0.05)
        W_v1  := Round(w * 0.2) - X1_v1
        H_v1 := Round(h * 0.3) - Y1_v1
        resV1 := AdvImageSearch("Resources\TowerUI\Variant1.png", X1_v1, Y1_v1, W_v1, H_v1, ,,0.05)

        if (resV1.status == "success" && resV1.score > 0.68) {
            return true
        }
        Sleep(30)

        if (timeout != 0) {
            if (A_TickCount - StartTime > timeout) {
                return false
            }
        }

        if (A_TickCount - StartTime > (PotatoMode == 1 ? 3500 : 2200)) {
            return false
        }

    }
}

RunAutoAbTool(*) {
    if (A_PtrSize == 4) {
    Run('"' A_ScriptDir '\submacros\AutoHotkey32.exe" "' A_ScriptDir '\submacros\auto_coa.ahk" ')
    } else {
        Run('"' A_ScriptDir '\submacros\AutoHotkey64.exe" "' A_ScriptDir '\submacros\auto_coa.ahk" ')
    }
}

RunAutoSpinTool(*) {
    if (A_PtrSize == 4) {
    Run('"' A_ScriptDir '\submacros\AutoHotkey32.exe" "' A_ScriptDir '\submacros\auto_spin.ahk" ')
    } else {
        Run('"' A_ScriptDir '\submacros\AutoHotkey64.exe" "' A_ScriptDir '\submacros\auto_spin.ahk" ')
    }
}


RunAutoConsumableTool(*) {
    WriteRuntimeLog("HOTBAR", "Blocked the legacy Auto Consumable tool under strict tower-hotbar safety.", "WARN")
    MsgBox("The Auto Consumable tool is disabled in Kronox's Edition.`n`n"
        . "The macro will not open or use the consumables hotbar.",
        "Strict Tower Hotbar Safety", 0x40)
}
