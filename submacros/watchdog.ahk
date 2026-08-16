#Requires AutoHotkey v2.0
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

Opt := A_AppData "\Ultimate_Macro\Options"
SettingsFile := Opt "\Settings.tds"
StateFile := A_AppData "\Ultimate_Macro\state.ini"
OverallStatsFile := A_AppData "\Ultimate_Macro\overall_stats.ini"
StatsHistoryFile := A_AppData "\Ultimate_Macro\stats_history.csv"
RunLedgerFile := A_AppData "\Ultimate_Macro\run_ledger.csv"

global WebhookLink := IniRead(SettingsFile, "Webhook", "Link", "")
tempWebhook := IniRead(SettingsFile, "Webhook", "Enabled", "OFF")
WebhookEnabled := (tempWebhook = "ON" || tempWebhook = "1") ? true : false
SendCurrenciesEnabled := IniRead(SettingsFile, "Webhook", "SendCurrencies", "1")
global WebhookScreenshots := IniRead(SettingsFile, "Webhook", "WebhookScreenshots", "1")
global WebhookTriumphScreenshots := IniRead(SettingsFile, "Webhook", "WebhookTriumphScreenshots", 1)
global WebhookSepatateTriumphScreenshots := IniRead(SettingsFile, "Webhook", "WebhookSepatateTriumphScreenshots", 0)
global WebhookLink2 := IniRead(SettingsFile, "Webhook", "Link2", "")

global ResourcesDir := A_WorkingDir "\Resources"
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
        ExitApp()
    }

    if (Mod(loopCounter, 15) == 0) {
        DetectHiddenWindows(True) 

        if !WinExist("Main.ahk ahk_class AutoHotkey") {
            ExitApp()
        }

        DetectHiddenWindows(false) 
    }

    if WinExist("Roblox Crash") {
        if (WebhookEnabled && WebhookLink != "") {
            SendScreenshot(,"Roblox has crashed!")
        }
        RestartMain()
        return
    }

    if !WinExist("ahk_exe RobloxPlayerBeta.exe") {
        if (WebhookEnabled && WebhookLink != "") {
            SendScreenshot(,"Roblox is not running!")
        }
        RestartMain()
        return
    }

    if (Mod(loopCounter, 3) == 0) {
        CoordMode("Pixel", "Screen")
        
        sw := A_ScreenWidth
        sh := A_ScreenHeight
        
        try {
            if ImageSearch(&FoundX, &FoundY, 0, 0, sw, sh, "*26 Resources/Disconnected.png") {
                CoordMode("Pixel", "Client")
                if (WebhookEnabled && WebhookLink != "") {
                    SendScreenshot(, "Disconnected, rejoining")
                }
                RestartMain()
                ExitApp()
            } else if ImageSearch(&FoundX, &FoundY, 0, 0, sw, sh, "*26 Resources/disconnected2.png") {
                CoordMode("Pixel", "Client")
                if (WebhookEnabled && WebhookLink != "") {
                    SendScreenshot(, "Disconnected, rejoining")
                }
                RestartMain()
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
            SendInfo("Triumph", "triumph-title")
            RestartMain()
            ExitApp()
        }
    } else {
        resTriumph2 := AdvImageSearch(TriumphImg2, Integer(w * 0.2), Integer(h * 0.2), Integer(w * 0.6), Integer(h * 0.7), 0.5, 1.5)
        Sleep 200
        resLost := AdvImageSearch(YouLostImg, Integer(w * 0.2), Integer(h * 0.2), Integer(w * 0.6), Integer(h * 0.7), 0.5, 1.5)

        if (resTriumph2.status == "success" && resTriumph2.score > 0.7) {
            CloseMain()
            Sleep 1300
            SendInfo("Triumph", "play-again-button")
            RestartMain()
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
            SendInfo("Loss", lossByTitle ? "you-lost-title" : "restart-button")
            RestartMain()
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
    global WebhookLink, StateFile, OverallStatsFile, StatsHistoryFile, RunLedgerFile, SendCurrenciesEnabled, WebhookEnabled, WebhookSepatateTriumphScreenshots, WebhookLink2

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
    strategyFile := IniRead(StateFile, "State", "Strategy", "")
    activeRunId := IniRead(StateFile, "State", "ActiveRunId", "")
    lastCompletedRunId := IniRead(StateFile, "State", "LastCompletedRunId", "")
    if (activeRunId != "" && activeRunId = lastCompletedRunId)
        return
    activeStrategyName := IniRead(StateFile, "State", "ActiveStrategyName", "")
    activeStrategyFingerprint := IniRead(StateFile, "State", "ActiveStrategyFingerprint", "legacy")
    activeStrategyDisplay := IniRead(StateFile, "State", "ActiveStrategyDisplay", "")
    activeModifiers := IniRead(StateFile, "State", "ActiveModifiers", "")
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
        return
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
    overallTime := Integer(IniRead(OverallStatsFile, "Overall", "TotalTimeSeconds", 0))

    if (matchResult = "Triumph")
        overallTriumphs += 1
    else if (matchResult = "Loss")
        overallLosses += 1

    overallCoins += coinVal
    overallGems += gemVal
    overallExp += expVal
    overallTime += timeInSeconds
    overallMatches := overallTriumphs + overallLosses
    overallRunStarts := Max(overallMatches, Integer(IniRead(OverallStatsFile, "Overall", "TotalRunStarts", overallMatches)))

    IniWrite(overallTriumphs, OverallStatsFile, "Overall", "TotalTriumphs")
    IniWrite(overallLosses, OverallStatsFile, "Overall", "TotalLosses")
    IniWrite(overallRunStarts, OverallStatsFile, "Overall", "TotalRunStarts")
    IniWrite(overallCoins, OverallStatsFile, "Overall", "Coins")
    IniWrite(overallGems, OverallStatsFile, "Overall", "Gems")
    IniWrite(overallExp, OverallStatsFile, "Overall", "EXP")
    IniWrite(overallTime, OverallStatsFile, "Overall", "TotalTimeSeconds")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), OverallStatsFile, "Overall", "LastUpdated")
    IniWrite(matchResult, OverallStatsFile, "Overall", "LastResult")
    IniWrite(detectionSource, OverallStatsFile, "Overall", "LastResultDetection")

    UpdateBreakdownStats(OverallStatsFile, "Map", mapName, matchResult, coinVal, gemVal, expVal, timeInSeconds)
    UpdateBreakdownStats(OverallStatsFile, "Mode", modeName, matchResult, coinVal, gemVal, expVal, timeInSeconds)
    UpdateBreakdownStats(OverallStatsFile, "Strategy", activeStrategyDisplay, matchResult, coinVal, gemVal, expVal, timeInSeconds)
    try AppendStatsHistory(StatsHistoryFile, matchResult, detectionSource, mapName, modeName, timeInSeconds, coinVal, gemVal, expVal)
    try AppendRunLedgerResult(RunLedgerFile, activeRunId, matchResult, detectionSource, activeStrategyName,
        activeStrategyFingerprint, mapName, modeName, activeModifiers, timeInSeconds, coinVal, gemVal, expVal)
    try UpdateRecentRuns(OverallStatsFile, matchResult, detectionSource, mapName, timeInSeconds, coinVal)

    IniWrite(matchResult, StateFile, "State", "LastResult")
    IniWrite(detectionSource, StateFile, "State", "LastResultDetection")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), StateFile, "State", "LastResultAt")
    if (activeRunId != "")
        IniWrite(activeRunId, StateFile, "State", "LastCompletedRunId")

    ; Clear the run marker only after all local counters are safely persisted.
    ; If OCR or file work fails before here, the result can still be retried.
    IniDelete(StateFile, "State", "TimeWhenStartedPlaying")
    for key in ["ActiveRunId", "ActiveRunStartedAt", "ActiveRunStartedTick", "ActiveStrategyPath",
        "ActiveStrategyName", "ActiveStrategyFingerprint", "ActiveStrategyDisplay", "ActiveMap",
        "ActiveMode", "ActiveModifiers"]
        try IniDelete(StateFile, "State", key)

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
}

UpdateBreakdownStats(file, kind, displayName, matchResult, coinVal, gemVal, expVal, timeInSeconds) {
    if (displayName = "" || displayName = "Unknown")
        return

    section := kind "_" SanitizeStatsSectionName(displayName)
    wins := Integer(IniRead(file, section, "TotalTriumphs", 0))
    losses := Integer(IniRead(file, section, "TotalLosses", 0))
    coins := Integer(IniRead(file, section, "Coins", 0))
    gems := Integer(IniRead(file, section, "Gems", 0))
    exp := Integer(IniRead(file, section, "EXP", 0))
    totalTime := Integer(IniRead(file, section, "TotalTimeSeconds", 0))

    if (matchResult = "Triumph")
        wins += 1
    else if (matchResult = "Loss")
        losses += 1

    coins += coinVal
    gems += gemVal
    exp += expVal
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
    IniWrite(totalTime, file, section, "TotalTimeSeconds")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), file, section, "LastUpdated")
}

SanitizeStatsSectionName(name) {
    cleanName := RegExReplace(Trim(name), "[^A-Za-z0-9 _-]", "_")
    cleanName := RegExReplace(cleanName, "\s+", "_")
    return (cleanName != "") ? cleanName : "Unknown"
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

RestartMain() {
    global MainPID, SettingsFile

    try ProcessClose(MainPID)

    wmi := ComObjGet("winmgmts:")
    query := "SELECT * FROM Win32_Process WHERE Name = 'AutoHotkey.exe' OR Name = 'AutoHotkeyU64.exe' OR Name = 'AutoHotkeyU32.exe' OR Name = 'AutoHotkey64.exe' OR Name = 'AutoHotkey32.exe'"
    for process in wmi.ExecQuery(query) {
        cmd := process.CommandLine
        if (InStr(cmd, "Main.ahk")) {
            try ProcessClose(process.ProcessId)
        }
    }
    WebhookLink := IniRead(SettingsFile, "Webhook", "Link", "")
    tempWebhook := IniRead(SettingsFile, "Webhook", "Enabled", "OFF")
    WebhookEnabled := (tempWebhook = "1") ? true : false

    if (A_PtrSize == 4) {
    Run('"' A_WorkingDir '\submacros\AutoHotkey32.exe" "' A_WorkingDir '\Main.ahk"')
    } else {
        Run('"' A_WorkingDir '\submacros\AutoHotkey64.exe" "' A_WorkingDir '\Main.ahk"')
    }

    ExitApp()
}

CleanupGdip(exitReason, exitCode) {
    global pToken
    Gdip_Shutdown(pToken)
}
