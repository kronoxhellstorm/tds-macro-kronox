#Requires AutoHotkey v2.0
#Include "%A_LineFile%\..\..\lib\Gdip_All.ahk"
#Include "%A_LineFile%\..\..\lib\Gdip_ImageSearch.ahk"
#Include "%A_LineFile%\..\..\lib\OCR.ahk"
#Include "%A_LineFile%\..\..\lib\TowerXP.ahk"

SplitPath(A_LineFile, , &testDir)
SetWorkingDir(testDir "\..")
token := Gdip_Startup()
failures := []

expectedTotals := Map(50, 2549, 75, 3238)
if (TowerXPConsensusAmount([36, 0, 36, 36]) != 36)
    failures.Push("shared Triumph reward fallback did not recover a missing tower reading")
if (TowerXPConsensusAmount([33, 36]) != 0)
    failures.Push("shared Triumph reward fallback guessed across conflicting readings")
if (TowerXPConsensusAmount([0, 0]) != 0)
    failures.Push("shared Triumph reward fallback invented XP without a successful reading")

for definition in TowerXPDefinitions() {
    progress := TowerXPAdvance(definition, 0, expectedTotals[definition.baseXP])
    if (!progress.isMax || progress.level != 20 || progress.xp != 0)
        failures.Push(definition.name " progression did not reach level 20")

    sourcePath := A_WorkingDir "\Resources\TowerXP\" definition.file
    bitmap := Gdip_CreateBitmapFromFile(sourcePath)
    if (!bitmap) {
        failures.Push(definition.name " reward image did not load")
        continue
    }
    text := ""
    try text := OCR.FromBitmap(bitmap, {lang: "en-US", scale: 4, grayscale: true}).Text
    Gdip_DisposeImage(bitmap)
    if (!RegExMatch(text, "i)\d[\d,.]*\s*[xX*][pP]"))
        failures.Push(definition.name " reward XP text was not OCR-readable: " Trim(StrReplace(text, "`n", " ")))
}

if (A_Args.Length > 0 && FileExist(A_Args[1])) {
    resultBitmap := Gdip_CreateBitmapFromFile(A_Args[1])
    recognizedRewards := []
    successfulRewardAmounts := []
    for definition in TowerXPDefinitions() {
        sourceBitmap := Gdip_CreateBitmapFromFile(A_WorkingDir "\Resources\TowerXP\" definition.file)
        Gdip_GetImageDimensions(sourceBitmap, &sourceW, &sourceH)
        portraitH := Round(sourceH * 0.72)
        portraitBitmap := Gdip_CloneBitmapArea(sourceBitmap, 0, 0, sourceW, portraitH)
        outputList := ""
        matchCount := Gdip_ImageSearch(resultBitmap, portraitBitmap, &outputList, 0, 0, 0, 0, 5)
        Gdip_DisposeImage(portraitBitmap)
        Gdip_DisposeImage(sourceBitmap)
        if (matchCount <= 0 || outputList = "")
            continue

        point := StrSplit(StrSplit(outputList, "`n")[1], ",")
        centerX := Integer(point[1]) + Round(sourceW / 2)
        centerY := Integer(point[2]) + Round(portraitH / 2)
        regionX := Max(0, Round(centerX - (sourceW * 0.55)))
        regionY := Max(0, Round(centerY + (portraitH * 0.16)))
        regionW := Max(40, Round(sourceW * 1.1))
        regionH := Max(40, Round(portraitH * 0.72))
        rewardTextBitmap := Gdip_CloneBitmapArea(resultBitmap, regionX, regionY, regionW, regionH)
        rewardText := OCR.FromBitmap(rewardTextBitmap, {lang: "en-US", scale: 4, grayscale: true}).Text
        Gdip_DisposeImage(rewardTextBitmap)
        rewardAmount := 0
        if (RegExMatch(rewardText, "i)(\d[\d,.]*)\s*[xX*][pP]", &rewardMatch)) {
            rewardAmount := Integer(StrReplace(StrReplace(rewardMatch[1], ",", ""), ".", ""))
            successfulRewardAmounts.Push(rewardAmount)
        }
        recognizedRewards.Push({name: definition.name, amount: rewardAmount})
    }
    Gdip_DisposeImage(resultBitmap)
    sharedRewardAmount := TowerXPConsensusAmount(successfulRewardAmounts)
    effectiveRewards := 0
    recognizedNames := ""
    juggernautRecoverable := false
    for reward in recognizedRewards {
        recognizedNames .= (recognizedNames != "" ? ", " : "") reward.name
        if (reward.amount > 0 || sharedRewardAmount > 0)
            effectiveRewards += 1
        if (reward.name = "Juggernaut" && (reward.amount > 0 || sharedRewardAmount > 0))
            juggernautRecoverable := true
    }
    ; The exact-size offline matcher does not scale like the runtime OpenCV
    ; matcher, but it must identify the failing Juggernaut card and prove that
    ; the same-screen consensus recovers its amount.
    if (effectiveRewards < 3)
        failures.Push("expected at least three exact-size cards after shared-reward recovery, read " effectiveRewards " (portraits: " recognizedNames ")")
    if (!juggernautRecoverable)
        failures.Push("Juggernaut was not recoverable from the supplied Triumph screenshot")
}

Gdip_Shutdown(token)
if (failures.Length > 0) {
    for failure in failures
        FileAppend("FAIL " failure "`n", "*")
    ExitApp(1)
}
FileAppend("PASS Tower XP formulas, reward OCR samples, and optional result screenshot`n", "*")
ExitApp(0)
