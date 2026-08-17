#Requires AutoHotkey v2.0
#Include "%A_LineFile%\..\..\lib\Gdip_All.ahk"
#Include "%A_LineFile%\..\..\lib\Gdip_ImageSearch.ahk"
#Include "%A_LineFile%\..\..\lib\OCR.ahk"
#Include "%A_LineFile%\..\..\lib\TowerXP.ahk"

ReadTowerXPFromBitmap(bitmap, candidate) {
    for region in TowerXPCropRegions(candidate) {
        crop := Gdip_CloneBitmapArea(bitmap, region.x, region.y, region.w, region.h)
        rewardText := OCR.FromBitmap(crop, {lang: "en-US", scale: 4, grayscale: true}).Text
        Gdip_DisposeImage(crop)
        if (RegExMatch(rewardText, "i)(\d[\d,.]*)\s*[xX*][pP]", &rewardMatch))
            return Integer(StrReplace(StrReplace(rewardMatch[1], ",", ""), ".", ""))
    }
    return 0
}

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
        topLeftCandidate := {x: Integer(point[1]), y: Integer(point[2]), w: sourceW, h: portraitH}
        rewardAmount := ReadTowerXPFromBitmap(resultBitmap, topLeftCandidate)
        if (rewardAmount > 0) {
            successfulRewardAmounts.Push(rewardAmount)
        }
        if (definition.name = "Juggernaut") {
            centerCandidate := {x: Integer(point[1]) + Round(sourceW / 2),
                y: Integer(point[2]) + Round(portraitH / 2), w: sourceW, h: portraitH}
            if (ReadTowerXPFromBitmap(resultBitmap, centerCandidate) <= 0)
                failures.Push("Juggernaut direct OCR failed with a center-anchored match")
        }
        recognizedRewards.Push({name: definition.name, amount: rewardAmount})
    }
    Gdip_DisposeImage(resultBitmap)
    sharedRewardAmount := TowerXPConsensusAmount(successfulRewardAmounts)
    effectiveRewards := 0
    recognizedNames := ""
    juggernautDirect := false
    for reward in recognizedRewards {
        recognizedNames .= (recognizedNames != "" ? ", " : "") reward.name
        if (reward.amount > 0 || sharedRewardAmount > 0)
            effectiveRewards += 1
        if (reward.name = "Juggernaut" && reward.amount > 0)
            juggernautDirect := true
    }
    ; The exact-size offline matcher does not scale like the runtime OpenCV
    ; matcher, but it must identify the failing Juggernaut card and prove that
    ; the same-screen consensus recovers its amount.
    if (effectiveRewards < 3)
        failures.Push("expected at least three exact-size cards after shared-reward recovery, read " effectiveRewards " (portraits: " recognizedNames ")")
    if (!juggernautDirect)
        failures.Push("Juggernaut's own XP text was not directly readable in the supplied Triumph screenshot")
}

Gdip_Shutdown(token)
if (failures.Length > 0) {
    for failure in failures
        FileAppend("FAIL " failure "`n", "*")
    ExitApp(1)
}
FileAppend("PASS Tower XP formulas, reward OCR samples, and optional result screenshot`n", "*")
ExitApp(0)
