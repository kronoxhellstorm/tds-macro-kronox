#Requires AutoHotkey v2.0
#SingleInstance Force

if (A_LineFile = A_ScriptFullPath) {
    ExitApp()
}

NormalizeUpdateVersion(version) {
    return RegExReplace(Trim(version), "i)^v", "")
}

IsNewerUpdateVersion(latestVersion, currentVersion) {
    latestVersion := NormalizeUpdateVersion(latestVersion)
    currentVersion := NormalizeUpdateVersion(currentVersion)
    if (latestVersion = currentVersion)
        return false

    ; A branded build accepts only branded releases. For the same upstream base,
    ; compare the numeric Kronox revision so an older release cannot be offered.
    if RegExMatch(currentVersion, "i)^(.*)-kronox\.(\d+)$", &currentParts) {
        if !RegExMatch(latestVersion, "i)^(.*)-kronox\.(\d+)$", &latestParts)
            return false
        if (StrLower(latestParts[1]) = StrLower(currentParts[1]))
            return Integer(latestParts[2]) > Integer(currentParts[2])
    }

    return true
}

CheckForUpdate(currentVer, repository := "") {
    ; A fork must never install releases from the original project over itself.
    ; Leave repository blank until Kronox's Edition has its own GitHub releases.
    repository := Trim(repository)
    if (repository = "")
        return 0

    if !RegExMatch(repository, "^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
        return 0

    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", "https://api.github.com/repos/" repository "/releases/latest", false)
        whr.SetRequestHeader("User-Agent", "Ultimate-Macro-Kronox-Edition")
        whr.Send()
        
        if (whr.Status = 200) {
            json := whr.ResponseText
            
            latestVer := ""
            if RegExMatch(json, '"tag_name":"([^"]+)"', &tag)
                latestVer := tag[1]
            
            downloadURL := ""
            if RegExMatch(json, '"browser_download_url":"([^"]+)"', &download)
                downloadURL := download[1]
            
            releaseBody := ""
            if RegExMatch(json, '"body":"([^"]+)"', &body)
                releaseBody := body[1]
            
            releaseBody := StrReplace(releaseBody, "\r\n", "`n")
            releaseBody := StrReplace(releaseBody, "\n", "`n")
            releaseBody := StrReplace(releaseBody, "\r", "")
            releaseBody := StrReplace(releaseBody, '\"', '"')
            releaseBody := StrReplace(releaseBody, "\\", "\")
            releaseBody := RegExReplace(releaseBody, "\\/", "/")
            
            if (latestVer != "" && IsNewerUpdateVersion(latestVer, currentVer) && downloadURL != "") {
                updateMsg := "New version " latestVer " is available!`n"
                updateMsg .= "Current version: " currentVer "`n`n"
                
                if (releaseBody != "") {
                    updateMsg .= "Changelog:`n--------------------------------`n"
                    if (StrLen(releaseBody) > 500) {
                        releaseBody := SubStr(releaseBody, 1, 500) . "...`n(Full changelog on GitHub)"
                    }
                    updateMsg .= releaseBody . "`n--------------------------------`n`n"
                }
                updateMsg .= "Do you want to update now?"
                
                if (MsgBox(updateMsg, "Update Available", 4) = "Yes") {
                    updateBat := A_ScriptDir "\submacros\update.bat"
                    tempBat := A_Temp "\TDSMacro_update.bat"
                    
                    if !FileExist(updateBat) {
                        MsgBox("update.bat not found!`n" updateBat, "Error", 16)
                        return 0
                    }
                    
                    FileCopy(updateBat, tempBat, 1)
                    
                    Run('"' tempBat '" "' downloadURL '" "' A_ScriptDir '"')
                    ExitApp()
                }
            }
        }
    } catch {
    }
    return 0
}
