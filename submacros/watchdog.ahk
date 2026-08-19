#Requires AutoHotkey v2.0.19+
#SingleInstance Force
#NoTrayIcon

ListLines(False)
KeyHistory(0)

CoordMode("Mouse", "Client")
CoordMode("Pixel", "Client")

SetWorkingDir(A_ScriptDir "\..\")

#Include  "%A_LineFile%\..\..\lib\ImageSearch\ImageSearch.ahk"
#Include "%A_LineFile%\..\..\lib\Gdip_All.ahk"
#Include "%A_LineFile%\..\..\lib\OCR.ahk"
#Include "%A_LineFile%\..\..\lib\Roblox.ahk"
#Include "%A_LineFile%\..\..\lib\TowerXP.ahk"
#Include "%A_LineFile%\..\..\lib\KronoxFeatures.ahk"

Opt := A_AppData "\Ultimate_Macro\Options"
SettingsFile := Opt "\Settings.tds"
StateFile := A_AppData "\Ultimate_Macro\state.ini"
OverallStatsFile := A_AppData "\Ultimate_Macro\overall_stats.ini"
StatsHistoryFile := A_AppData "\Ultimate_Macro\stats_history.csv"
RunLedgerFile := A_AppData "\Ultimate_Macro\run_ledger.csv"
RunContextFile := A_AppData "\Ultimate_Macro\run_context.csv"
StrategyProfileFile := A_AppData "\Ultimate_Macro\strategy_profiles.csv"
RuntimeLogDir := A_AppData "\Ultimate_Macro\Logs"

global WebhookLink := IniRead(SettingsFile, "Webhook", "Link", "")
tempWebhook := IniRead(SettingsFile, "Webhook", "Enabled", "OFF")
WebhookEnabled := (tempWebhook = "ON" || tempWebhook = "1") ? true : false
SendCurrenciesEnabled := IniRead(SettingsFile, "Webhook", "SendCurrencies", "1")
global WebhookScreenshots := IniRead(SettingsFile, "Webhook", "WebhookScreenshots", "1")
global WebhookTriumphScreenshots := IniRead(SettingsFile, "Webhook", "WebhookTriumphScreenshots", 1)
global WebhookSepatateTriumphScreenshots := IniRead(SettingsFile, "Webhook", "WebhookSepatateTriumphScreenshots", 0)
global WebhookLink2 := IniRead(SettingsFile, "Webhook", "Link2", "")

global ResourcesDir := A_WorkingDir "\Resources"
global TowerXPResourcesDir := ResourcesDir "\TowerXP"
global TowerXPTemplateDir := A_AppData "\Ultimate_Macro\TowerXPTemplates"
global TriumphImg1 := ResourcesDir "\triumph.png"
global TriumphImg2 := ResourcesDir "\PlayAgain.png"
global YouLostImg := ResourcesDir "\YouLost.png"
global ReviveIMG := ResourcesDir "\use_revive_ticket.png"
global RestartImg := ResourcesDir "\Restart.png"
global RestartImg2 := ResourcesDir "\Restart2.png"
global cancel := ResourcesDir "\cancel.png"

pToken := Gdip_Startup()

OnExit(CleanupGdip)
 
if (A_Args.Length < 1) {
    MsgBox("You are not supposed to run it manually!")
    ExitApp()
}

MainPID := A_Args[1]
global RecoveryStarted := false

if !DirExist(RuntimeLogDir)
    DirCreate(RuntimeLogDir)
OnError(HandleWatchdogError)
WriteRuntimeLog("WATCHDOG", "Watchdog started for main PID " MainPID ".")

if (WebhookEnabled && WebhookLink != "" && WebhookScreenshots = "1") {
    screenshotDelay := Random(25000, 300000)
    SetTimer(TakeRandomScreenshot, screenshotDelay)
}

Sleep(15000)
WinWait("ahk_exe RobloxPlayerBeta.exe", , 30)

loopCounter := 0

Loop {
    getRobloxPos(,,&w,&h)

    w := Max(1, w)
    h := Max(1, h)

    loopCounter++ 
     
    if (MainPID != "" && !ProcessExist(MainPID)) {
        ; Intentional stops and reloads terminate this watchdog first. Reaching
        ; this branch means the owner vanished unexpectedly (for example, a
        ; native AutoHotkey or OCR crash). Preserve unattended recovery instead
        ; of silently abandoning Roblox while State.Running remains set.
        if KronoxFeatureBool(IniRead(StateFile, "State", "Running", 0)) {
            WriteRuntimeLog("WATCHDOG", "Main PID " MainPID
                " vanished unexpectedly; performing a clean crash recovery.", "ERROR")
            RestartMain("main-process-crash", true)
            return
        }
        ReleaseAutomationInputs()
        ExitApp()
    }

    if (Mod(loopCounter, 15) == 0) {
        DetectHiddenWindows(True) 

        if !WinExist("Main.ahk ahk_class AutoHotkey") {
            ExitApp()
        }

        DetectHiddenWindows(false) 
    }

    if (Mod(loopCounter, 5) == 0) {
        absoluteReason := KronoxAbsoluteStallReason(SettingsFile, StateFile, MainPID)
        if (absoluteReason != "") {
            QuiesceMainForRecovery(absoluteReason)
            if (WebhookEnabled && WebhookLink != "") {
                SendScreenshot(, "Absolute Mode recovery: " absoluteReason)
            }
            RestartMain("absolute-mode:" absoluteReason, true)
            return
        }

        stalledPhase := GetStalledMainPhase()
        if (stalledPhase != "") {
            QuiesceMainForRecovery("stalled-phase:" stalledPhase)
            if (WebhookEnabled && WebhookLink != "") {
                SendScreenshot(, "Macro stalled during " stalledPhase "; recovering")
            }
            RestartMain("stalled-phase:" stalledPhase,
                KronoxFeatureBool(IniRead(SettingsFile, "Reliability", "AbsoluteMode", 0)))
            return
        }
    }

    if WinExist("Roblox Crash") {
        QuiesceMainForRecovery("roblox-crash-window")
        if (WebhookEnabled && WebhookLink != "") {
            SendScreenshot(,"Roblox has crashed!")
        }
        RestartMain("roblox-crash-window")
        return
    }

    if !WinExist("ahk_exe RobloxPlayerBeta.exe") {
        QuiesceMainForRecovery("roblox-window-missing")
        if (WebhookEnabled && WebhookLink != "") {
            SendScreenshot(,"Roblox is not running!")
        }
        RestartMain("roblox-window-missing")
        return
    }

    if (Mod(loopCounter, 3) == 0) {
        CoordMode("Pixel", "Screen")
        
        sw := A_ScreenWidth
        sh := A_ScreenHeight
        
        try {
            if ImageSearch(&FoundX, &FoundY, 0, 0, sw, sh, "*26 Resources/Disconnected.png") {
                CoordMode("Pixel", "Client")
                QuiesceMainForRecovery("disconnect-dialog-primary")
                if (WebhookEnabled && WebhookLink != "") {
                    SendScreenshot(, "Disconnected, rejoining")
                }
                RestartMain("disconnect-dialog-primary")
                ExitApp()
            } else if ImageSearch(&FoundX, &FoundY, 0, 0, sw, sh, "*26 Resources/disconnected2.png") {
                CoordMode("Pixel", "Client")
                QuiesceMainForRecovery("disconnect-dialog-secondary")
                if (WebhookEnabled && WebhookLink != "") {
                    SendScreenshot(, "Disconnected, rejoining")
                }
                RestartMain("disconnect-dialog-secondary")
                ExitApp()
            }
        } catch Error as err {
            CoordMode("Pixel", "Client")
        }
        
        CoordMode("Pixel", "Client")
    }


    if (Mod(loopCounter, 2) == 0) {
        resTriumph1 := AdvImageSearch(TriumphImg1, Integer(w * 0.2), Integer(h * 0.2), Integer(w * 0.6), Integer(h * 0.7), 0.5, 1.5)
        
        if (resTriumph1.status == "success" && resTriumph1.score > 0.7) {
            CloseMain()
            Sleep 1300
            resultStatus := SendInfo("Triumph", "triumph-title")
            if (resultStatus != "duplicate" && resultStatus != "tower-xp-stop" && resultStatus != "automation-stop")
                RestartMain("result-triumph-title")
            ExitApp()
        }
    } else {
        resTriumph2 := AdvImageSearch(TriumphImg2, Integer(w * 0.2), Integer(h * 0.2), Integer(w * 0.6), Integer(h * 0.7), 0.5, 1.5)
        Sleep 200
        resLost := AdvImageSearch(YouLostImg, Integer(w * 0.2), Integer(h * 0.2), Integer(w * 0.6), Integer(h * 0.7), 0.5, 1.5)

        if (resTriumph2.status == "success" && resTriumph2.score > 0.7) {
            CloseMain()
            Sleep 1300
            resultStatus := SendInfo("Triumph", "play-again-button")
            if (resultStatus != "duplicate" && resultStatus != "tower-xp-stop" && resultStatus != "automation-stop")
                RestartMain("result-play-again-button")
            ExitApp()
        }
        
        lossByTitle := (resLost.status == "success" && resLost.score > 0.7)
        lossByRestart := false

        ; The Restart button is the stable distinction between a loss and a
        ; victory. The "You Lost" heading can be obscured or fail to match.
        if (!lossByTitle) {
            lossByRestart := IsLossRestartVisible(w, h)
            if (lossByRestart) {
                Sleep 250
                lossByRestart := IsLossRestartVisible(w, h)
            }
        }

        if (lossByTitle || lossByRestart) {
            CloseMain()
            Sleep 1300
            detection := lossByTitle ? "you-lost-title" : "restart-button"
            resultStatus := SendInfo("Loss", detection)
            if (resultStatus != "duplicate" && resultStatus != "automation-stop")
                RestartMain("result-" detection)
            ExitApp()
        }
    }

    if (Mod(loopCounter, 6) == 0) {
        resRevive := AdvImageSearch(ReviveIMG, Integer(w * 0.2), Integer(h * 0.2), Integer(w * 0.6), Integer(h * 0.7))

        if (resRevive.status == "success" && resRevive.score > 0.7) {
            resCancel := AdvImageSearch(cancel, Integer(w * 0.2), Integer(h * 0.2), Integer(w * 0.6), Integer(h * 0.7))
            
            if (resCancel.status == "success" && resCancel.score > 0.7) {
                WinActivate("ahk_exe RobloxPlayerBeta.exe")
                WinWaitActive("ahk_exe RobloxPlayerBeta.exe", , 1)
                Click(resCancel.x, resCancel.y)
            }
        }
    }
    Sleep(300)
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

HandleWatchdogError(err, mode) {
    global MainPID, StateFile
    message := "Unhandled watchdog error"
    try message := err.Message
    location := ""
    try location := err.File (err.Line ? ":" err.Line : "")
    try WriteRuntimeLog("WATCHDOG", message (location != "" ? " at " location : "") " [mode " mode "]", "ERROR")
    try ReleaseAutomationInputs()
    try IniWrite("watchdog-error", StateFile, "Health", "Phase")
    try IniWrite(message, StateFile, "Health", "Detail")
    if (MainPID != "" && ProcessExist(MainPID)
        && KronoxFeatureBool(IniRead(StateFile, "State", "Running", 0))) {
        try SetTimer(RecoverFromWatchdogError.Bind(message), -50)
    }
    ; Suppress the modal AHK dialog. It previously stranded the main process
    ; while its input timers continued to move the cursor.
    return true
}

RecoverFromWatchdogError(message, *) {
    global SettingsFile
    hardReset := KronoxFeatureBool(IniRead(SettingsFile, "Reliability", "AbsoluteMode", 0))
    RestartMain("watchdog-error:" message, hardReset)
}

GetStalledMainPhase() {
    global StateFile, MainPID

    ownerPid := IniRead(StateFile, "Health", "OwnerPID", "")
    if (String(ownerPid) != String(MainPID))
        return ""

    timeoutMs := Integer(IniRead(StateFile, "Health", "TimeoutMs", 0))
    startedTick := Integer(IniRead(StateFile, "Health", "PhaseStartedTick", 0))
    if (timeoutMs <= 0 || startedTick <= 0 || A_TickCount < startedTick)
        return ""

    ; Main enforces its own deadline. This ten-second grace makes the watchdog
    ; the independent fallback when the main thread is hung or image search fails.
    elapsed := A_TickCount - startedTick
    if (elapsed <= timeoutMs + 10000)
        return ""

    phase := IniRead(StateFile, "Health", "Phase", "unknown")
    detail := IniRead(StateFile, "Health", "Detail", "")
    WriteRuntimeLog("WATCHDOG", "Stalled phase detected: " phase " after " Round(elapsed / 1000) " seconds" (detail != "" ? " (" detail ")" : "") ".", "WARN")
    return phase
}

sX(baseX, Width := 1920) {
    getRobloxPos(&pX, &pY, &currentWidth, &currentHeight)
    return Round(baseX * (currentWidth / Width))
}

sY(baseY, Height := 1009) {
    getRobloxPos(&pX, &pY, &currentWidth, &currentHeight)
    return Round(baseY * (currentHeight / Height))
}

IsLossRestartVisible(w, h) {
    global RestartImg, RestartImg2

    restart := AdvImageSearch(RestartImg, 0, Integer(h * 0.5), w, Integer(h * 0.5), 0.5, 1.5)
    if (restart.status = "success" && restart.score > 0.7)
        return true

    restart2 := AdvImageSearch(RestartImg2, 0, Integer(h * 0.5), w, Integer(h * 0.5), 0.5, 1.5)
    return (restart2.status = "success" && restart2.score > 0.7)
}

SendInfo(matchResult := "", detectionSource := "result-screen") {
    global WebhookLink, StateFile, SettingsFile, OverallStatsFile, StatsHistoryFile, RunLedgerFile
    global RunContextFile, StrategyProfileFile, SendCurrenciesEnabled, WebhookEnabled, WebhookSepatateTriumphScreenshots, WebhookLink2

    shouldSendWebhook := (WebhookEnabled && WebhookLink != "")
    originalWebhookLink := WebhookLink
    usingSeparateWebhook := false

    if (shouldSendWebhook && WebhookSepatateTriumphScreenshots = 1 && WebhookLink2 != "") {
        WebhookLink := WebhookLink2
        usingSeparateWebhook := true
    }

    mapName := "Unknown"
    timeInSeconds := 0
    coinVal := 0
    gemVal := 0
    expVal := 0
    towerXPResult := {summary: "", detected: 0, stopTriggered: false, stopMessage: ""}
    queueResult := {enabled: false, changed: false, complete: false, advanced: [], message: ""}
    canaryResult := {active: false, stop: false, message: ""}
    strategyFile := IniRead(StateFile, "State", "Strategy", "")
    activeRunId := IniRead(StateFile, "State", "ActiveRunId", "")
    lastCompletedRunId := IniRead(StateFile, "State", "LastCompletedRunId", "")
    if (activeRunId != "" && activeRunId = lastCompletedRunId) {
        WriteRuntimeLog("WATCHDOG", "Skipped duplicate result for completed run " activeRunId ".", "WARN")
        if (usingSeparateWebhook)
            WebhookLink := originalWebhookLink
        return "duplicate"
    }
    activeStrategyName := IniRead(StateFile, "State", "ActiveStrategyName", "")
    activeStrategyFingerprint := IniRead(StateFile, "State", "ActiveStrategyFingerprint", "legacy")
    activeStrategyDisplay := IniRead(StateFile, "State", "ActiveStrategyDisplay", "")
    activeModifiers := IniRead(StateFile, "State", "ActiveModifiers", "")
    activeModifierDisplay := IniRead(StateFile, "State", "ActiveModifierDisplay", KronoxCanonicalModifierSet(activeModifiers))
    activeXPBoostProfile := IniRead(StateFile, "State", "ActiveXPBoostProfile", "Base XP")
    activeXPBoostFactorText := IniRead(StateFile, "State", "ActiveXPBoostFactor", "1")
    activeXPBoostFactor := IsNumber(activeXPBoostFactorText) ? Max(0.1, Number(activeXPBoostFactorText)) : 1.0
    activeTDSVersion := IniRead(StateFile, "State", "ActiveTDSVersion", "Unknown")
    activeCanaryStatus := KronoxFeatureBool(IniRead(StateFile, "State", "CanaryActive", 0)) ? "Canary" : "Normal"
    activeMapName := IniRead(StateFile, "State", "ActiveMap", "")
    activeModeName := IniRead(StateFile, "State", "ActiveMode", "")
    strategyMapName := ""
    modeName := "Unknown"

    if (strategyFile != "" && FileExist(strategyFile)) {
        strategyMapName := IniRead(strategyFile, "Settings", "map", "")
        modeName := IniRead(strategyFile, "Settings", "difficulty", "Unknown")
        if (activeStrategyName = "") {
            SplitPath(strategyFile, , , , &activeStrategyName)
        }
    }
    if (activeStrategyName = "")
        activeStrategyName := "Unknown strategy"
    if (activeStrategyDisplay = "")
        activeStrategyDisplay := activeStrategyName " [" activeStrategyFingerprint "]"
    if (activeMapName != "")
        strategyMapName := activeMapName
    if (activeModeName != "")
        modeName := activeModeName

    timeCompleted_T := IniRead(StateFile, "State", "TimeWhenStartedPlaying", "Failed")

    if (timeCompleted_T != "Failed") {
        ms := A_TickCount - timeCompleted_T

        total_seconds := ms // 1000
        timeInSeconds := total_seconds
        hours := total_seconds // 3600
        minutes := (total_seconds // 60) - (hours * 60)
        seconds := Mod(total_seconds, 60)
        
        timeCompleted := ""
        if (hours > 0)
            timeCompleted .= hours "h "
        if (minutes > 0 || hours > 0)
            timeCompleted .= minutes "m "
        timeCompleted .= seconds "s"
    } else {
        timeCompleted := "Failed"
        WriteRuntimeLog("WATCHDOG", "Result screen was detected without an active run timer; result was not recorded.", "WARN")
        if (usingSeparateWebhook)
            WebhookLink := originalWebhookLink
        return "failed"
    }

    if (activeRunId = "")
        activeRunId := "legacy-" timeCompleted_T

    claimStatus := TryClaimRunResult(activeRunId, timeCompleted_T, matchResult)
    if (claimStatus != "claimed") {
        WriteRuntimeLog("WATCHDOG", (claimStatus = "duplicate" ? "Another watchdog already claimed this " matchResult " result; duplicate processing stopped." : "The " matchResult " result could not be claimed safely; restarting without recording it."), claimStatus = "duplicate" ? "WARN" : "ERROR")
        if (usingSeparateWebhook)
            WebhookLink := originalWebhookLink
        return claimStatus
    }

    getRobloxPos(&pX, &pY, &w, &h)

    MouseMove(Round(w*0.5), Round(h*0.1))

    Play_Again := AdvImageSearch(TriumphImg2, Integer(w * 0.2), Integer(h * 0.2), Integer(w * 0.6), Integer(h * 0.7))
    Restart := AdvImageSearch(RestartImg, Integer(w * 0.2), Integer(h * 0.2), Integer(w * 0.6), Integer(h * 0.7))
    Restart2 := AdvImageSearch(RestartImg2, Integer(w * 0.2), Integer(h * 0.2), Integer(w * 0.6), Integer(h * 0.7))

    FoundX := 0
    FoundY := 0

    if (Play_Again.status = "success" && Play_Again.score > 0.7) {
        FoundX := Play_Again.x
        FoundY := Play_Again.y
    } else if (Restart.status = "success" && Restart.score > 0.7) {
        FoundX := Restart.x
        FoundY := Restart.y
    } else if (Restart2.status = "success" && Restart2.score > 0.7) {
        FoundX := Restart2.x
        FoundY := Restart2.y
    }

    ; Result OCR is always collected for local session and lifetime statistics
    ; when an action button gives us a reliable anchor point.
    if (FoundX > 0 && FoundY > 0) {
        targetX := FoundX - sX(180)
        targetY := FoundY - sY(250)
        AreaW := sX(340)
        AreaH := sY(230)

        ocrTarget := ""
        pBitmapArea := Gdip_BitmapFromScreen(targetX . "|" . targetY . "|" . AreaW . "|" . AreaH)
        if (pBitmapArea) {
            pBitmapResized := Gdip_CreateBitmap(AreaW * 3, AreaH * 3)
            if (pBitmapResized) {
                G1 := Gdip_GraphicsFromImage(pBitmapResized)
                if (G1) {
                    DllCall("gdiplus\GdipSetInterpolationMode", "Ptr", G1, "Int", 7)
                    Gdip_DrawImage(G1, pBitmapArea, 0, 0, AreaW * 3, AreaH * 3, 0, 0, AreaW, AreaH)
                    BinarizeTargetBitmap(pBitmapResized)
                    try ocrTarget := OCR.FromBitmap(pBitmapResized, {lang:"en-US"}).Text
                    Gdip_DeleteGraphics(G1)
                }
                Gdip_DisposeImage(pBitmapResized)
            }
            Gdip_DisposeImage(pBitmapArea)
        }

        infoX := FoundX + sX(200)
        infoY := FoundY - sY(350) 
        InfoW := sX(320)
        InfoH := sY(240)

        ocrInfo := ""
        pBitmapInfo := Gdip_BitmapFromScreen(infoX . "|" . infoY . "|" . InfoW . "|" . InfoH)
        if (pBitmapInfo) {
            pBitmapInfoResized := Gdip_CreateBitmap(InfoW * 3, InfoH * 3)
            if (pBitmapInfoResized) {
                G2 := Gdip_GraphicsFromImage(pBitmapInfoResized)
                if (G2) {
                    DllCall("gdiplus\GdipSetInterpolationMode", "Ptr", G2, "Int", 7)
                    Gdip_DrawImage(G2, pBitmapInfo, 0, 0, InfoW * 3, InfoH * 3, 0, 0, InfoW, InfoH)
                    try ocrInfo := OCR.FromBitmap(pBitmapInfoResized, {lang:"en-US", scale:1.5}).Text
                    Gdip_DeleteGraphics(G2)
                }
                Gdip_DisposeImage(pBitmapInfoResized)
            }
        }

        xpX := FoundX - sX(180)
        xpY := FoundY - sY(250)
        xpW := sX(340)
        xpH := sY(230)

        if RegExMatch(ocrTarget, "i)(\d[\d,]*)\s*c[o0]ins?", &coinsMatch)
            coinVal := Integer(StrReplace(coinsMatch[1], ",", ""))
        
        if RegExMatch(ocrTarget, "i)(\d[\d,]*)\s*(?:[g6c]\s*[e30c]ms?|[c]\s*[c]\s*ms?)", &gemsMatch)
            gemVal := Integer(StrReplace(gemsMatch[1], ",", ""))

        if RegExMatch(ocrTarget, "i)(?<![\+\d])(\d[\d,]*)\s*xp", &expMatch)
            expVal := Integer(StrReplace(expMatch[1], ",", ""))

        mapName := "Unknown"

        mapList := [
        "Abandoned City", "Area 52", "Autumn Falling", 
        "Badlands II", "Black Spot Exchange", "Candy Valley", "Cataclysm", "Chess Board", 
        "Construction Crazy", "Coral Deep", "Crossroads", "Crystal Cave", 
        "Cyber City", "Dead Ahead", "Derelict Outpost", "Deserted Village", "Dusty Bridges", 
        "Enchanted Forest", "Farm Lands", "Forest Camp", "Forgetten Docks", "Four Seasons", 
        "Fungi Island", "Grass Isle", "Simplicity", "Happy Home of Robloxia", "Harbor", "Honey Valley", 
        "Hot Spot", "Iceville", "Infernal Abyss", "Lay By", "Lighthaos", "Marshlands", "Mason Arch", "Medieval Times", "Meltdown", 
        "Midnight Issue", "Moon Base", "Musaceae Kingdom", "Necropolis", "Nether", "Night Station", 
        "Northern Lights", "Outskirts Commune", "Pier Pressure", "Pizza Party", "Polluted Wasteland II", 
        "Portland", "Retro Crossroads", "Retro Lighthouse", "Retro Rocket Arena", "Retro Stained Temple", 
        "Retro The Heights", "Retro Zone", "Rocket Arena", "Ruby Escort", "Sacred Mountains", 
        "Sky Islands", "Space City", "Spring Fever", "Stained Temple", "Sugar Rush", 
        "The Heavens", "The Heights", "Toyboard", "Tropical Industries", "Tropical Isles", "U-Turn", 
        "Unknown Garden", "Winter Abyss", "Winter Bridges", "Winter Stronghold", "Wrecked Battlefield", 
        "Wrecked Battlefield II", "Wretched Front"
    ]

        for currentMap in mapList {
            if InStr(ocrInfo, currentMap) {
                mapName := currentMap
                break
            }
        }

    }

    if (strategyMapName != "")
        mapName := strategyMapName
    if (modeName = "")
        modeName := "Unknown"

    if (matchResult = "Triumph") {
        if (FoundX > 0 && FoundY > 0)
            towerXPResult := ProcessTowerXPRewards(FoundX, FoundY, w, h)
        else if (Integer(IniRead(SettingsFile, "TowerXP", "Enabled", 0)) = 1)
            WriteRuntimeLog("TOWERXP", "Triumph was recorded without a stable result anchor; tower XP was not changed.", "WARN")
        queueResult := KronoxEvolutionAdvanceCompleted(SettingsFile, StateFile)
        if (queueResult.enabled && queueResult.changed && queueResult.message != "")
            towerXPResult.summary .= (towerXPResult.summary != "" ? " | " : "") "Queue: " queueResult.message
        if (queueResult.enabled && queueResult.complete) {
            towerXPResult.stopTriggered := true
            towerXPResult.stopMessage := queueResult.message
        } else if (queueResult.enabled && queueResult.changed
            && !KronoxFeatureBool(IniRead(SettingsFile, "EvolutionQueue", "AutoEquip", 1))) {
            towerXPResult.stopTriggered := true
            towerXPResult.stopMessage := "Evolution Queue advanced; equip " KronoxEvolutionAssignmentText(SettingsFile) " and resume manually"
        } else if (queueResult.enabled && !queueResult.complete) {
            ; A per-tower stop target must not interrupt an active queue. The
            ; queue owns the stop decision until every queued tower is done.
            towerXPResult.stopTriggered := false
            towerXPResult.stopMessage := ""
        }
    }

    totalTriumphs := IniRead(StateFile, "State", "TotalTriumphs", 0)
    totalLosses := IniRead(StateFile, "State", "TotalLosses", 0)
    
    if (matchResult = "Triumph") {
        totalTriumphs += 1
        IniWrite(totalTriumphs, StateFile, "State", "TotalTriumphs")
    } else if (matchResult = "Loss") {
        totalLosses += 1
        IniWrite(totalLosses, StateFile, "State", "TotalLosses")
    }
    
    savedCoins := IniRead(StateFile, "State", "Coins", 0)
    savedGems := IniRead(StateFile, "State", "Gems", 0)
    savedExp := IniRead(StateFile, "State", "EXP", 0)
    savedTime := IniRead(StateFile, "State", "TotalTimeSeconds", 0)
    
    totalCoins := savedCoins + coinVal
    totalGems := savedGems + gemVal
    totalExp := savedExp + expVal
    totalTime := savedTime + timeInSeconds
    
    IniWrite(totalCoins, StateFile, "State", "Coins")
    IniWrite(totalGems, StateFile, "State", "Gems")
    IniWrite(totalExp, StateFile, "State", "EXP")
    IniWrite(totalTime, StateFile, "State", "TotalTimeSeconds")

    overallTriumphs := Integer(IniRead(OverallStatsFile, "Overall", "TotalTriumphs", 0))
    overallLosses := Integer(IniRead(OverallStatsFile, "Overall", "TotalLosses", 0))
    overallCoins := Integer(IniRead(OverallStatsFile, "Overall", "Coins", 0))
    overallGems := Integer(IniRead(OverallStatsFile, "Overall", "Gems", 0))
    overallExp := Integer(IniRead(OverallStatsFile, "Overall", "EXP", 0))
    overallNormalizedExp := Integer(IniRead(OverallStatsFile, "Overall", "NormalizedEXP", 0))
    overallBoostTrackedRuns := Integer(IniRead(OverallStatsFile, "Overall", "BoostTrackedRuns", 0))
    overallBoostTrackedSeconds := Integer(IniRead(OverallStatsFile, "Overall", "BoostTrackedSeconds", 0))
    overallTime := Integer(IniRead(OverallStatsFile, "Overall", "TotalTimeSeconds", 0))
    normalizedExpVal := Round(expVal / activeXPBoostFactor)

    if (matchResult = "Triumph")
        overallTriumphs += 1
    else if (matchResult = "Loss")
        overallLosses += 1

    overallCoins += coinVal
    overallGems += gemVal
    overallExp += expVal
    overallNormalizedExp += normalizedExpVal
    overallBoostTrackedRuns += 1
    overallBoostTrackedSeconds += timeInSeconds
    overallTime += timeInSeconds
    overallMatches := overallTriumphs + overallLosses
    overallRunStarts := Max(overallMatches, Integer(IniRead(OverallStatsFile, "Overall", "TotalRunStarts", overallMatches)))

    IniWrite(overallTriumphs, OverallStatsFile, "Overall", "TotalTriumphs")
    IniWrite(overallLosses, OverallStatsFile, "Overall", "TotalLosses")
    IniWrite(overallRunStarts, OverallStatsFile, "Overall", "TotalRunStarts")
    IniWrite(overallCoins, OverallStatsFile, "Overall", "Coins")
    IniWrite(overallGems, OverallStatsFile, "Overall", "Gems")
    IniWrite(overallExp, OverallStatsFile, "Overall", "EXP")
    IniWrite(overallNormalizedExp, OverallStatsFile, "Overall", "NormalizedEXP")
    IniWrite(overallBoostTrackedRuns, OverallStatsFile, "Overall", "BoostTrackedRuns")
    IniWrite(overallBoostTrackedSeconds, OverallStatsFile, "Overall", "BoostTrackedSeconds")
    IniWrite(overallTime, OverallStatsFile, "Overall", "TotalTimeSeconds")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), OverallStatsFile, "Overall", "LastUpdated")
    IniWrite(matchResult, OverallStatsFile, "Overall", "LastResult")
    IniWrite(detectionSource, OverallStatsFile, "Overall", "LastResultDetection")

    UpdateBreakdownStats(OverallStatsFile, "Map", mapName, matchResult, coinVal, gemVal, expVal, timeInSeconds, activeXPBoostFactor)
    UpdateBreakdownStats(OverallStatsFile, "Mode", modeName, matchResult, coinVal, gemVal, expVal, timeInSeconds, activeXPBoostFactor)
    UpdateBreakdownStats(OverallStatsFile, "Strategy", activeStrategyDisplay, matchResult, coinVal, gemVal, expVal, timeInSeconds, activeXPBoostFactor)
    UpdateBreakdownStats(OverallStatsFile, "Modifier", activeModifierDisplay, matchResult, coinVal, gemVal, expVal,
        timeInSeconds, activeXPBoostFactor, KronoxModifierMultiplier(activeModifiers))
    UpdateBreakdownStats(OverallStatsFile, "Boost", activeXPBoostProfile, matchResult, coinVal, gemVal, expVal,
        timeInSeconds, activeXPBoostFactor)
    try AppendStatsHistory(StatsHistoryFile, matchResult, detectionSource, mapName, modeName, timeInSeconds, coinVal, gemVal, expVal)
    try AppendRunLedgerResult(RunLedgerFile, activeRunId, matchResult, detectionSource, activeStrategyName,
        activeStrategyFingerprint, mapName, modeName, activeModifiers, timeInSeconds, coinVal, gemVal, expVal)
    try UpdateRecentRuns(OverallStatsFile, matchResult, detectionSource, mapName, timeInSeconds, coinVal)
    try KronoxProfilerRecordResult(StrategyProfileFile, StateFile, activeRunId, matchResult)
    try KronoxAppendRunContextEvent(RunContextFile, activeRunId, "RESULT", activeXPBoostProfile,
        activeXPBoostFactor, activeModifierDisplay, KronoxModifierMultiplier(activeModifiers),
        IniRead(SettingsFile, "Options", "TimeScaleMode", "OFF"), activeTDSVersion, activeCanaryStatus)
    canaryResult := KronoxCanaryRecordResult(SettingsFile, StateFile, matchResult)

    IniWrite(matchResult, StateFile, "State", "LastResult")
    IniWrite(detectionSource, StateFile, "State", "LastResultDetection")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), StateFile, "State", "LastResultAt")
    IniWrite(activeRunId, StateFile, "State", "LastCompletedRunId")

    ; Clear the run marker only after all local counters are safely persisted.
    ; If OCR or file work fails before here, the result can still be retried.
    IniDelete(StateFile, "State", "TimeWhenStartedPlaying")
    for key in ["ActiveRunId", "ActiveRunStartedAt", "ActiveRunStartedTick", "ActiveStrategyPath",
        "ActiveStrategyName", "ActiveStrategyFingerprint", "ActiveStrategyDisplay", "ActiveMap",
        "ActiveMode", "ActiveModifiers", "ActiveModifierDisplay", "ActiveXPBoostProfile", "ActiveXPBoostFactor"]
        try IniDelete(StateFile, "State", key)
    try IniDelete(StateFile, "State", "ResultClaimedRunId")
    try IniDelete(StateFile, "State", "ResultClaimedAt")

    autorunStart := IniRead(StateFile, "State", "StartTime", 0)
    coinsPerHour := 0, gemsPerHour := 0, expPerHour := 0
    if (autorunStart > 0) {
        elapsedMs := A_TickCount - autorunStart
        elapsedHours := elapsedMs / 3600000
        if (elapsedHours > 0.001) {
            coinsPerHour := Round(totalCoins / elapsedHours)
            gemsPerHour := Round(totalGems / elapsedHours)
            expPerHour := Round(totalExp / elapsedHours)
        }
    }
    
    totalMatches := totalTriumphs + totalLosses
    winrate := (totalMatches > 0) ? Round((totalTriumphs / totalMatches) * 100) : 0
    wlRatio := (totalLosses > 0) ? Round(totalTriumphs / totalLosses, 1) : totalTriumphs
    wlRatioStr := StrReplace(String(wlRatio), ".", ".")

    avgTimeStr := "0s"
    if (totalMatches > 0 && totalTime > 0) {
        avgSeconds := Round(totalTime / totalMatches)
        avgMinutes := Floor(avgSeconds / 60)
        avgRemSeconds := Mod(avgSeconds, 60)
        avgTimeStr := (avgMinutes > 0) ? avgMinutes "m " avgRemSeconds "s" : avgRemSeconds "s"
    }

    description := ""
    color := 12434877

    if (matchResult = "Triumph") {
        description := "### :trophy: TRIUMPH!"
        color := 3066993
    } else {
        description := "### :skull: YOU LOST!"
        color := 0xFF322E
    }

    if (SendCurrenciesEnabled = "1") {
        description .= "`n"
        description .= "Map: **" mapName "**  Mode: **" modeName "**  Time Completed: **" timeCompleted "**`n"
        description .= "+" expVal " EXP (+" totalExp ")`n"
        description .= "+" coinVal " Coins (+" totalCoins ")  +" gemVal " Gems (+" totalGems ")`n"
        description .= "-# Total Matches: " totalMatches ", wins: " totalTriumphs ", losses: " totalLosses ", W/R: " winrate "%, W/L ratio: " wlRatioStr ", " coinsPerHour " coins/h, " gemsPerHour " gems/h, " expPerHour " exp/h, avg. time: " avgTimeStr
    }

    if (towerXPResult.summary != "")
        description .= "`nTower XP: **" towerXPResult.summary "**"
    if (towerXPResult.stopTriggered)
        description .= "`n### :dart: Automation target reached`nMacro stopped automatically: **" towerXPResult.stopMessage "**"
    if (canaryResult.active)
        description .= "`nUpdate canary: **" canaryResult.message "**"

    ; Emit exactly one result webhook. The old missing-anchor fallback sent a
    ; header here early and then this full report, producing duplicate posts.
    if (shouldSendWebhook) {
        pBitmap := Gdip_BitmapFromScreen()
        if (pBitmap) {
            SendScreenshot(pBitmap, description, color, WebhookTriumphScreenshots)
            Gdip_DisposeImage(pBitmap)
        }
    }

    if IsSet(pBitmapInfo)
        Gdip_DisposeImage(pBitmapInfo)

    if (usingSeparateWebhook)
        WebhookLink := originalWebhookLink

    WriteRuntimeLog("WATCHDOG", "Recorded " matchResult " for run " (activeRunId != "" ? activeRunId : "legacy") " via " detectionSource ".")
    if (towerXPResult.stopTriggered) {
        IniWrite(0, StateFile, "State", "Running")
        IniWrite("tower-xp-target-complete", StateFile, "State", "LastStopReason")
        IniWrite("stopped", StateFile, "Health", "Phase")
        IniWrite("tower-xp-target-complete", StateFile, "Health", "Detail")
        IniWrite(0, StateFile, "Health", "TimeoutMs")
        IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), StateFile, "Health", "UpdatedAt")
        WriteRuntimeLog("TOWERXP", "Macro stopped: " towerXPResult.stopMessage ".")
        return "tower-xp-stop"
    }
    if (canaryResult.stop) {
        IniWrite(0, StateFile, "State", "Running")
        IniWrite("update-canary-failed", StateFile, "State", "LastStopReason")
        IniWrite("stopped", StateFile, "Health", "Phase")
        IniWrite(canaryResult.message, StateFile, "Health", "Detail")
        IniWrite(0, StateFile, "Health", "TimeoutMs")
        WriteRuntimeLog("CANARY", canaryResult.message ".", "WARN")
        return "automation-stop"
    }
    return "recorded"
}

EnsureTowerXPTemplate(definition) {
    global TowerXPResourcesDir, TowerXPTemplateDir

    sourcePath := TowerXPResourcesDir "\" definition.file
    if (!FileExist(sourcePath))
        return ""
    if (!DirExist(TowerXPTemplateDir))
        DirCreate(TowerXPTemplateDir)
    targetPath := TowerXPTemplateDir "\" RegExReplace(definition.name, "[^A-Za-z0-9]+", "_") "_portrait.png"

    rebuild := !FileExist(targetPath)
    if (!rebuild) {
        try rebuild := FileGetTime(sourcePath, "M") > FileGetTime(targetPath, "M")
    }
    if (!rebuild)
        return targetPath

    sourceBitmap := Gdip_CreateBitmapFromFile(sourcePath)
    if (!sourceBitmap)
        return ""
    Gdip_GetImageDimensions(sourceBitmap, &sourceW, &sourceH)
    portraitH := Max(1, Round(sourceH * 0.72))
    portraitBitmap := Gdip_CloneBitmapArea(sourceBitmap, 0, 0, sourceW, portraitH)
    Gdip_DisposeImage(sourceBitmap)
    if (!portraitBitmap)
        return ""
    try Gdip_SaveBitmapToFile(portraitBitmap, targetPath, 100)
    Gdip_DisposeImage(portraitBitmap)
    return FileExist(targetPath) ? targetPath : ""
}

ReadTowerXPAmount(candidate) {
    robloxHwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if (!robloxHwnd)
        return 0

    ; OpenCV and the GDI fallback have historically disagreed on whether x/y
    ; describe a match center or its top-left corner. Try both interpretations,
    ; and use wider/lower crops so bottom-row cards such as Juggernaut keep the
    ; complete '+NN XP' baseline inside the OCR bitmap.
    cropRegions := TowerXPCropRegions(candidate)
    ocrSamples := []
    lastError := ""

    for region in cropRegions {
        hBitmap := 0
        ocrText := ""
        try {
            hBitmap := OCR.CreateHBitmap(region.x, region.y, region.w, region.h,
                {hWnd: robloxHwnd, onlyClientArea: 1, mode: 2}, 4)
            ocrText := OCR.FromBitmap(hBitmap, {lang: "en-US", grayscale: true}).Text
        } catch Error as err {
            lastError := err.Message
        } finally {
            ; OCR.CreateHBitmap returns OCR.IBase, whose destructor owns both
            ; the HBITMAP and DC. Passing that wrapper to GDI DeleteObject is
            ; invalid and caused the watchdog popup fixed in kronox.7.
            hBitmap := 0
        }

        if RegExMatch(ocrText, "i)[+t]?\s*(\d[\d,.]*)\s*[xX*][pP]", &xpMatch) {
            amount := Integer(StrReplace(StrReplace(xpMatch[1], ",", ""), ".", ""))
            if (region.anchor != "center" || region.profile != "focused")
                WriteRuntimeLog("TOWERXP", "Read " candidate.definition.name " directly with the " region.anchor "/" region.profile " XP crop.")
            return amount
        }

        cleanOCR := Trim(StrReplace(StrReplace(ocrText, "`r", " "), "`n", " "))
        if (cleanOCR != "")
            ocrSamples.Push(cleanOCR)
    }

    sampleText := ""
    for index, sample in ocrSamples
        sampleText .= (index > 1 ? " | " : "") sample
    if (sampleText = "")
        sampleText := lastError != "" ? "error: " lastError : "empty"
    WriteRuntimeLog("TOWERXP", "Recognized " candidate.definition.name " portrait but could not directly read its XP text after " cropRegions.Length " crops (OCR: " sampleText ").", "WARN")
    return 0
}

ProcessTowerXPRewards(foundX, foundY, clientW, clientH) {
    global SettingsFile

    result := {summary: "", detected: 0, stopTriggered: false, stopMessage: ""}
    if (Integer(IniRead(SettingsFile, "TowerXP", "Enabled", 0)) != 1)
        return result

    searchX := Max(0, Round(foundX - sX(520)))
    searchY := Max(0, Round(foundY - sY(430)))
    searchRight := Min(clientW, Round(foundX + sX(520)))
    searchBottom := Min(clientH, Round(foundY - sY(20)))
    searchW := Max(1, searchRight - searchX)
    searchH := Max(1, searchBottom - searchY)
    candidates := []

    for definition in TowerXPDefinitions() {
        section := TowerXPSectionName(definition.name)
        if (Integer(IniRead(SettingsFile, section, "Tracked", 0)) != 1)
            continue
        templatePath := EnsureTowerXPTemplate(definition)
        if (templatePath = "") {
            WriteRuntimeLog("TOWERXP", "Missing or invalid default-skin template for " definition.name ".", "WARN")
            continue
        }
        match := AdvImageSearch(templatePath, searchX, searchY, searchW, searchH, 0.65, 1.6, 0.025)
        if (match.status = "success" && match.score >= 0.80)
            candidates.Push({definition: definition, x: match.x, y: match.y, w: match.w, h: match.h, score: match.score})
        else if (match.status = "success" && match.score >= 0.68)
            WriteRuntimeLog("TOWERXP", "Ignored uncertain " definition.name " reward portrait (confidence " Round(match.score * 100) "%). Default skins are required.", "WARN")
    }

    ; Different tower templates share the card border. Keep only the strongest
    ; candidate when two templates resolve to the same reward-card position.
    accepted := []
    while (candidates.Length > 0) {
        bestIndex := 1
        Loop candidates.Length {
            if (candidates[A_Index].score > candidates[bestIndex].score)
                bestIndex := A_Index
        }
        candidate := candidates.RemoveAt(bestIndex)
        overlaps := false
        for existing in accepted {
            distance := Sqrt(((candidate.x - existing.x) ** 2) + ((candidate.y - existing.y) ** 2))
            if (distance < Max(candidate.w, existing.w) * 0.65) {
                overlaps := true
                break
            }
        }
        if (!overlaps)
            accepted.Push(candidate)
    }

    readings := []
    successfulAmounts := []
    for candidate in accepted {
        gainedXP := ReadTowerXPAmount(candidate)
        readings.Push({candidate: candidate, gainedXP: gainedXP})
        if (gainedXP > 0)
            successfulAmounts.Push(gainedXP)
    }

    sharedRewardXP := TowerXPConsensusAmount(successfulAmounts)
    summaries := []
    for reading in readings {
        candidate := reading.candidate
        gainedXP := reading.gainedXP
        usedSharedReward := false
        if (gainedXP <= 0 && sharedRewardXP > 0) {
            gainedXP := sharedRewardXP
            usedSharedReward := true
            WriteRuntimeLog("TOWERXP", "Recovered " candidate.definition.name " reward as " gainedXP " XP from the matching rewards on the same Triumph screen.", "WARN")
        }
        if (gainedXP <= 0)
            continue
        definition := candidate.definition
        section := TowerXPSectionName(definition.name)
        oldLevel := Integer(IniRead(SettingsFile, section, "Level", 0))
        oldXP := Integer(IniRead(SettingsFile, section, "XP", 0))
        progress := TowerXPAdvance(definition, oldLevel, oldXP, gainedXP)
        IniWrite(progress.level, SettingsFile, section, "Level")
        IniWrite(progress.xp, SettingsFile, section, "XP")
        IniWrite(gainedXP, SettingsFile, section, "LastGainedXP")
        IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), SettingsFile, section, "LastUpdated")
        status := progress.isMax ? "MAX" : progress.xp "/" progress.nextRequired
        summaries.Push(definition.name " +" gainedXP (usedSharedReward ? " (shared)" : "") " -> L" progress.level " " status)
        result.detected += 1
        WriteRuntimeLog("TOWERXP", definition.name " gained " gainedXP " XP; now level " progress.level (progress.isMax ? " (MAX)." : " with " progress.xp "/" progress.nextRequired " XP."))
    }

    for index, summary in summaries
        result.summary .= (index > 1 ? " | " : "") summary
    if (result.detected = 0)
        WriteRuntimeLog("TOWERXP", "No confident tracked-tower reward cards were read. Tracked towers must use default skins; progression was left unchanged.", "WARN")

    stopEvaluation := EvaluateTowerXPStopRule()
    result.stopTriggered := stopEvaluation.triggered
    result.stopMessage := stopEvaluation.message
    return result
}

EvaluateTowerXPStopRule() {
    global SettingsFile

    stopMode := TowerXPStoredStopMode(IniRead(SettingsFile, "TowerXP", "StopMode", "Never"))
    if (stopMode = "Never")
        return {triggered: false, message: ""}

    targets := []
    maxTargets := []
    for definition in TowerXPDefinitions() {
        section := TowerXPSectionName(definition.name)
        if (Integer(IniRead(SettingsFile, section, "Tracked", 0)) != 1
            || Integer(IniRead(SettingsFile, section, "StopTarget", 0)) != 1)
            continue
        targets.Push(definition.name)
        if (Integer(IniRead(SettingsFile, section, "Level", 0)) >= definition.maxLevel)
            maxTargets.Push(definition.name)
    }
    if (targets.Length = 0)
        return {triggered: false, message: ""}

    triggered := stopMode = "Any" ? maxTargets.Length > 0 : maxTargets.Length = targets.Length
    if (!triggered)
        return {triggered: false, message: ""}

    names := ""
    source := stopMode = "Any" ? maxTargets : targets
    for index, name in source
        names .= (index > 1 ? ", " : "") name
    message := stopMode = "Any" ? names " reached level 20" : "all selected towers reached level 20 (" names ")"
    return {triggered: true, message: message}
}

UpdateBreakdownStats(file, kind, displayName, matchResult, coinVal, gemVal, expVal, timeInSeconds,
    xpBoostFactor := 1.0, modifierMultiplier := 1.0) {
    if (displayName = "" || displayName = "Unknown")
        return

    section := kind "_" SanitizeStatsSectionName(displayName)
    wins := Integer(IniRead(file, section, "TotalTriumphs", 0))
    losses := Integer(IniRead(file, section, "TotalLosses", 0))
    coins := Integer(IniRead(file, section, "Coins", 0))
    gems := Integer(IniRead(file, section, "Gems", 0))
    exp := Integer(IniRead(file, section, "EXP", 0))
    normalizedExp := Integer(IniRead(file, section, "NormalizedEXP", 0))
    boostTrackedRuns := Integer(IniRead(file, section, "BoostTrackedRuns", 0))
    boostTrackedSeconds := Integer(IniRead(file, section, "BoostTrackedSeconds", 0))
    totalTime := Integer(IniRead(file, section, "TotalTimeSeconds", 0))

    if (matchResult = "Triumph")
        wins += 1
    else if (matchResult = "Loss")
        losses += 1

    coins += coinVal
    gems += gemVal
    exp += expVal
    normalizedExp += Round(expVal / Max(0.1, xpBoostFactor))
    boostTrackedRuns += 1
    boostTrackedSeconds += timeInSeconds
    totalTime += timeInSeconds
    matches := wins + losses
    runStarts := Max(matches, Integer(IniRead(file, section, "TotalRunStarts", matches)))

    IniWrite(kind, file, section, "Kind")
    IniWrite(displayName, file, section, "DisplayName")
    IniWrite(wins, file, section, "TotalTriumphs")
    IniWrite(losses, file, section, "TotalLosses")
    IniWrite(runStarts, file, section, "TotalRunStarts")
    IniWrite(coins, file, section, "Coins")
    IniWrite(gems, file, section, "Gems")
    IniWrite(exp, file, section, "EXP")
    IniWrite(normalizedExp, file, section, "NormalizedEXP")
    IniWrite(boostTrackedRuns, file, section, "BoostTrackedRuns")
    IniWrite(boostTrackedSeconds, file, section, "BoostTrackedSeconds")
    if (kind = "Modifier")
        IniWrite(modifierMultiplier, file, section, "ModifierMultiplier")
    IniWrite(totalTime, file, section, "TotalTimeSeconds")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), file, section, "LastUpdated")
}

SanitizeStatsSectionName(name) {
    cleanName := RegExReplace(Trim(name), "[^A-Za-z0-9 _-]", "_")
    cleanName := RegExReplace(cleanName, "\s+", "_")
    return (cleanName != "") ? cleanName : "Unknown"
}

TryClaimRunResult(runId, startedTick, matchResult) {
    global StateFile

    mutex := DllCall("Kernel32\CreateMutex", "Ptr", 0, "Int", false, "Str", "Local\UltimateMacroKronoxResultWriter", "Ptr")
    if !mutex {
        WriteRuntimeLog("WATCHDOG", "Could not create the result-writer mutex.", "ERROR")
        return "failed"
    }

    waitResult := DllCall("Kernel32\WaitForSingleObject", "Ptr", mutex, "UInt", 5000, "UInt")
    if (waitResult != 0 && waitResult != 0x80) {
        DllCall("Kernel32\CloseHandle", "Ptr", mutex)
        WriteRuntimeLog("WATCHDOG", "Timed out waiting for the result-writer mutex.", "ERROR")
        return "failed"
    }

    try {
        currentActiveRunId := IniRead(StateFile, "State", "ActiveRunId", "")
        lastCompletedRunId := IniRead(StateFile, "State", "LastCompletedRunId", "")
        claimedRunId := IniRead(StateFile, "State", "ResultClaimedRunId", "")

        if (lastCompletedRunId = runId || claimedRunId = runId)
            return "duplicate"

        isLegacyRun := (SubStr(runId, 1, 7) = "legacy-")
        if (!isLegacyRun && currentActiveRunId != runId)
            return "duplicate"

        IniWrite(runId, StateFile, "State", "ResultClaimedRunId")
        IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), StateFile, "State", "ResultClaimedAt")
        WriteRuntimeLog("WATCHDOG", "Claimed " matchResult " result for run " runId " (start tick " startedTick ").")
        return "claimed"
    } finally {
        DllCall("Kernel32\ReleaseMutex", "Ptr", mutex)
        DllCall("Kernel32\CloseHandle", "Ptr", mutex)
    }
}

AppendStatsHistory(file, matchResult, detectionSource, mapName, modeName, timeInSeconds, coinVal, gemVal, expVal) {
    if (!FileExist(file))
        FileAppend("Timestamp,Result,Detection,Map,Mode,DurationSeconds,Coins,Gems,XP`n", file, "UTF-8")

    row := CsvStatsField(FormatTime(, "yyyy-MM-dd HH:mm:ss")) ","
        . CsvStatsField(matchResult) ","
        . CsvStatsField(detectionSource) ","
        . CsvStatsField(mapName) ","
        . CsvStatsField(modeName) ","
        . Integer(timeInSeconds) ","
        . Integer(coinVal) ","
        . Integer(gemVal) ","
        . Integer(expVal) "`n"
    FileAppend(row, file, "UTF-8")
}

CsvStatsField(value) {
    return '"' StrReplace(String(value), '"', '""') '"'
}

AppendRunLedgerResult(file, runId, matchResult, detectionSource, strategyName, fingerprint,
    mapName, modeName, modifiersText, timeInSeconds, coinVal, gemVal, expVal) {
    if (!FileExist(file))
        FileAppend("Timestamp,RunId,Event,Status,Detection,Strategy,StrategyFingerprint,Map,Mode,Modifiers,DurationSeconds,Coins,Gems,XP`n", file, "UTF-8")

    if (runId = "")
        runId := "legacy-" FormatTime(, "yyyyMMdd-HHmmss") "-" Format("{:03}", A_MSec)

    row := CsvStatsField(FormatTime(, "yyyy-MM-dd HH:mm:ss")) ","
        . CsvStatsField(runId) "," . CsvStatsField("RESULT") "," . CsvStatsField(matchResult) ","
        . CsvStatsField(detectionSource) "," . CsvStatsField(strategyName) "," . CsvStatsField(fingerprint) ","
        . CsvStatsField(mapName) "," . CsvStatsField(modeName) "," . CsvStatsField(modifiersText) ","
        . Integer(timeInSeconds) "," . Integer(coinVal) "," . Integer(gemVal) "," . Integer(expVal) "`n"
    FileAppend(row, file, "UTF-8")
}

UpdateRecentRuns(file, matchResult, detectionSource, mapName, timeInSeconds, coinVal) {
    Loop 2 {
        sourceIndex := 3 - A_Index
        targetIndex := sourceIndex + 1
        previous := IniRead(file, "Overall", "RecentRun" sourceIndex, "")
        if (previous != "")
            IniWrite(previous, file, "Overall", "RecentRun" targetIndex)
    }

    evidence := detectionSource
    evidence := StrReplace(evidence, "triumph-title", "title")
    evidence := StrReplace(evidence, "play-again-button", "replay")
    evidence := StrReplace(evidence, "you-lost-title", "loss title")
    evidence := StrReplace(evidence, "restart-button", "restart")
    resultLabel := (matchResult = "Triumph") ? "WIN" : "LOSS"
    durationLabel := (timeInSeconds >= 60) ? Floor(timeInSeconds / 60) "m" : timeInSeconds "s"
    summary := FormatTime(, "HH:mm") "  " resultLabel " · " mapName " · " durationLabel " · +" coinVal "C · " evidence
    IniWrite(summary, file, "Overall", "RecentRun1")
}

BinarizeTargetBitmap(pBitmap) {
    Gdip_GetImageDimensions(pBitmap, &w, &h)
    Rect := Buffer(16, 0)
    NumPut("int", 0, Rect, 0), NumPut("int", 0, Rect, 4)
    NumPut("int", w, Rect, 8), NumPut("int", h, Rect, 12)
    
    BitmapData := Buffer(A_PtrSize = 8 ? 32 : 24, 0)
    if DllCall("gdiplus\GdipBitmapLockBits", "Ptr", pBitmap, "Ptr", Rect, "UInt", 3, "Int", 0x26200A, "Ptr", BitmapData)
        return
        
    Scan0 := NumGet(BitmapData, A_PtrSize = 8 ? 16 : 12, "Ptr")
    Stride := NumGet(BitmapData, 8, "Int")
    
    Loop h {
        y := A_Index - 1
        Loop w {
            x := A_Index - 1
            offset := (y * Stride) + (x * 4)
            b := NumGet(Scan0 + offset, 0, "UChar")
            g := NumGet(Scan0 + offset, 1, "UChar")
            r := NumGet(Scan0 + offset, 2, "UChar")
            
            brightness := (r + g + b) / 3
            if (brightness > 200) { 
                NumPut("UChar", 255, Scan0 + offset, 0)
                NumPut("UChar", 255, Scan0 + offset, 1)
                NumPut("UChar", 255, Scan0 + offset, 2)
            } else {
                NumPut("UChar", 0, Scan0 + offset, 0)
                NumPut("UChar", 0, Scan0 + offset, 1)
                NumPut("UChar", 0, Scan0 + offset, 2)
            }
        }
    }
    DllCall("gdiplus\GdipBitmapUnlockBits", "Ptr", pBitmap, "Ptr", BitmapData)
}


TakeRandomScreenshot() {
    global WebhookEnabled, WebhookLink
    if (!WebhookEnabled || WebhookLink = "")
        return
    
    if (WebhookLink = WebhookLink2)
        WebhookLink := IniRead(SettingsFile, "Webhook", "Link", "")
    
    pBitmap := Gdip_BitmapFromScreen()
    if (pBitmap > 0) {
        SendScreenshot(pBitmap, "Automatic screenshot", 3447003)
        Gdip_DisposeImage(pBitmap)
    }
    
    screenshotDelay := Random(180000, 360000)
    SetTimer(TakeRandomScreenshot, screenshotDelay)
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
        whr.SetTimeouts(5000, 5000, 60000, 60000) 
        whr.Send(postdata)
    }
}

CreateFormData(&retData, &contentType, fields) {
    charArray := StrSplit("0123456789abcdefghijklmnopqrstuvwxyz")
    boundary := ""
    Loop 12 {
        boundary .= charArray[Random(1, charArray.Length)]
    }
    
    hData := DllCall("GlobalAlloc", "UInt", 0x2, "UPtr", 0, "Ptr")
    DllCall("ole32\CreateStreamOnHGlobal", "Ptr", hData, "Int", 0, "PtrP", &pStream := 0, "UInt")
    
    for index, field in fields {
        str := "`r`n------------------------------" boundary "`r`n"
        str .= 'Content-Disposition: form-data; name="' field["name"] '"'
        
        if field.Has("filename")
            str .= '; filename="' field["filename"] '"'
        
        str .= "`r`n"
        str .= "Content-Type: " field["content-type"] "`r`n`r`n"
        
        if field.Has("content")
            str .= field["content"] "`r`n"
        
        length := StrPut(str, "UTF-8") - 1
        utf8 := Buffer(length)
        StrPut(str, utf8, "UTF-8")
        DllCall("shlwapi\IStream_Write", "Ptr", pStream, "Ptr", utf8.Ptr, "UInt", length, "UInt")
        
        if field.Has("pBitmap") {
            try {
                pFileStream := Gdip_SaveBitmapToStream(field["pBitmap"])
                DllCall("shlwapi\IStream_Size", "Ptr", pFileStream, "UInt64P", &size := 0, "UInt")
                DllCall("shlwapi\IStream_Reset", "Ptr", pFileStream, "UInt")
                DllCall("shlwapi\IStream_Copy", "Ptr", pFileStream, "Ptr", pStream, "UInt", size, "UInt")
                DllCall("ole32\IUnknown_Release", "Ptr", pFileStream)
            }
        }
    }
    
    str := "`r`n------------------------------" boundary "--`r`n"
    length := StrPut(str, "UTF-8") - 1
    utf8 := Buffer(length)
    StrPut(str, utf8, "UTF-8")
    DllCall("shlwapi\IStream_Write", "Ptr", pStream, "Ptr", utf8.Ptr, "UInt", length, "UInt")
    
    pStream := ""
    
    pData := DllCall("GlobalLock", "Ptr", hData, "Ptr")
    size := DllCall("GlobalSize", "Ptr", pData, "UPtr")
    
    retData := ComObjArray(0x11, size)  
    pvData := NumGet(ComObjValue(retData), 8 + A_PtrSize, "Ptr")
    DllCall("RtlMoveMemory", "Ptr", pvData, "Ptr", pData, "Ptr", size)
    
    DllCall("GlobalUnlock", "Ptr", hData)
    DllCall("GlobalFree", "Ptr", hData, "Ptr")
    
    contentType := "multipart/form-data; boundary=----------------------------" boundary
}

CloseMain() {
    global MainPID, SettingsFile

    WriteRuntimeLog("WATCHDOG", "Closing main PID " MainPID " for result processing.")
    ReleaseAutomationInputs()
    try ProcessClose(MainPID)

    wmi := ComObjGet("winmgmts:")
    query := "SELECT * FROM Win32_Process WHERE Name = 'AutoHotkey.exe' OR Name = 'AutoHotkeyU64.exe' OR Name = 'AutoHotkeyU32.exe' OR Name = 'AutoHotkey64.exe' OR Name = 'AutoHotkey32.exe'"
    for process in wmi.ExecQuery(query) {
        cmd := process.CommandLine
        if (InStr(cmd, "Main.ahk")) {
            try ProcessClose(process.ProcessId)
        }
    }
}

QuiesceMainForRecovery(reason := "watchdog-recovery") {
    global MainPID

    ReleaseAutomationInputs()
    if (MainPID != "" && ProcessExist(MainPID)) {
        WriteRuntimeLog("INPUT", "Stopping main PID " MainPID " before recovery: " reason ".", "WARN")
        try ProcessClose(MainPID)
    }
}

RestartMain(reason := "watchdog-recovery", forceRobloxReset := false) {
    global MainPID, SettingsFile, StateFile, RecoveryStarted

    if (RecoveryStarted)
        return
    RecoveryStarted := true

    WriteRuntimeLog("WATCHDOG", "Restarting main PID " MainPID ": " reason ".", "WARN")
    ReleaseAutomationInputs()
    if (KronoxCanaryBlockRecovery(SettingsFile, StateFile, reason)) {
        WriteRuntimeLog("CANARY", "Blocked unattended recovery after " reason "; the macro was stopped for review.", "WARN")
        try ProcessClose(MainPID)
        ExitApp()
    }
    try IniWrite("watchdog-restarting", StateFile, "Health", "Phase")
    try IniWrite(reason, StateFile, "Health", "Detail")
    try IniWrite(0, StateFile, "Health", "TimeoutMs")
    try IniWrite(Integer(IniRead(StateFile, "Reliability", "RecoveryCount", 0)) + 1,
        StateFile, "Reliability", "RecoveryCount")
    try IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), StateFile, "Reliability", "LastRecoveryAt")
    try IniWrite(reason, StateFile, "Reliability", "LastRecoveryReason")

    try ProcessClose(MainPID)

    wmi := ComObjGet("winmgmts:")
    query := "SELECT * FROM Win32_Process WHERE Name = 'AutoHotkey.exe' OR Name = 'AutoHotkeyU64.exe' OR Name = 'AutoHotkeyU32.exe' OR Name = 'AutoHotkey64.exe' OR Name = 'AutoHotkey32.exe'"
    for process in wmi.ExecQuery(query) {
        cmd := process.CommandLine
        if (InStr(cmd, "Main.ahk")) {
            try ProcessClose(process.ProcessId)
        }
    }
    if (forceRobloxReset) {
        WriteRuntimeLog("WATCHDOG", "Absolute recovery is closing Roblox before relaunch.", "WARN")
        CloseRobloxProcesses()
    }
    WebhookLink := IniRead(SettingsFile, "Webhook", "Link", "")
    tempWebhook := IniRead(SettingsFile, "Webhook", "Enabled", "OFF")
    WebhookEnabled := (tempWebhook = "1") ? true : false

    LaunchMainWithStartupGuard(reason)
}

LaunchMainWithStartupGuard(reason := "watchdog-recovery") {
    global StateFile

    maxAttempts := 3
    Loop maxAttempts {
        attempt := A_Index
        newMainPID := 0
        try {
            if (A_PtrSize == 4)
                Run('"' A_WorkingDir '\submacros\AutoHotkey32.exe" "' A_WorkingDir '\Main.ahk"',,, &newMainPID)
            else
                Run('"' A_WorkingDir '\submacros\AutoHotkey64.exe" "' A_WorkingDir '\Main.ahk"',,, &newMainPID)
        } catch Error as err {
            WriteRuntimeLog("WATCHDOG", "Failed to launch replacement main on attempt " attempt
                ": " err.Message, "ERROR")
        }

        if (newMainPID) {
            WriteRuntimeLog("WATCHDOG", "Replacement main PID " newMainPID
                " launched (startup attempt " attempt "/" maxAttempts ").")
            deadline := A_TickCount + 12000
            while (A_TickCount < deadline) {
                Sleep(250)
                if !ProcessExist(newMainPID)
                    break
            }
            if ProcessExist(newMainPID) {
                WriteRuntimeLog("WATCHDOG", "Replacement main PID " newMainPID
                    " survived startup supervision after " reason ".")
                ExitApp()
            }
            WriteRuntimeLog("WATCHDOG", "Replacement main PID " newMainPID
                " crashed during startup attempt " attempt ".", "ERROR")
        }
        ReleaseAutomationInputs()
        Sleep(750)
    }

    ; Repeated startup failure is safer as a visible idle UI than an endless
    ; crash/restart loop which continues to control Roblox unattended.
    IniWrite(0, StateFile, "State", "Running")
    IniWrite("startup-recovery-failed", StateFile, "Health", "Phase")
    IniWrite(reason, StateFile, "Health", "Detail")
    IniWrite(0, StateFile, "Health", "TimeoutMs")
    WriteRuntimeLog("WATCHDOG", "Replacement main failed " maxAttempts
        " startup attempts; autorun was disabled and an idle UI will be opened.", "ERROR")

    try {
        if (A_PtrSize == 4)
            Run('"' A_WorkingDir '\submacros\AutoHotkey32.exe" "' A_WorkingDir '\Main.ahk"')
        else
            Run('"' A_WorkingDir '\submacros\AutoHotkey64.exe" "' A_WorkingDir '\Main.ahk"')
    }
    ExitApp()
}

ReleaseAutomationInputs() {
    keys := ["LButton", "RButton", "MButton", "Shift", "LShift", "RShift", "Ctrl", "LCtrl", "RCtrl",
        "Alt", "LAlt", "RAlt", "Space", "Left", "Right", "Up", "Down", "Tab", "Enter", "Escape"]
    Loop 26
        keys.Push(Chr(96 + A_Index))
    Loop 10
        keys.Push(String(Mod(A_Index, 10)))
    for keyName in keys {
        try SendEvent("{" keyName " up}")
    }
}

CloseRobloxProcesses() {
    Loop 6 {
        pid := ProcessExist("RobloxPlayerBeta.exe")
        if (!pid)
            break
        try ProcessClose(pid)
        Sleep(500)
    }
}

CleanupGdip(exitReason, exitCode) {
    global pToken
    try ReleaseAutomationInputs()
    Gdip_Shutdown(pToken)
}
