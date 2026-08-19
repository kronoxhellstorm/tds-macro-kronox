#Requires AutoHotkey v2.0.19+
#SingleInstance Force

if (VerCompare(A_AhkVersion, "2.0.19") < 0)
    throw Error("The embedded AutoHotkey runtime is too old: " A_AhkVersion)

strategyFile := A_ScriptDir "\..\Resources\Strats\Menz's Frosted heaven.strat"
if !FileExist(strategyFile)
    throw Error("Strategy loader fixture is missing: " strategyFile)

steps := []
inSteps := false
Loop Read, strategyFile {
    line := Trim(A_LoopReadLine)
    if (line ~= "i)^\[Settings\]")
        inSteps := false
    if (line ~= "i)^\[Steps\]")
        inSteps := true
    if (inSteps && line != "")
        steps.Push(line)
}

if (steps.Length < 100)
    throw Error("Strategy fixture did not provide the expected step volume: " steps.Length)

; Reproduce the regex-heavy portion of LoadStrategyFile repeatedly. The bundled
; 2.0.12 runtime could corrupt its native heap while compiling these expressions.
Loop 1000 {
    towers := Map()
    for step in steps {
        if RegExMatch(step, "i)SpawnTower\s*\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*(.*?)\s*\)", &m) {
            towerID := Trim(m[1])
            towers[towerID] := {path: 0, pathLevel: 0}
        }
        if RegExMatch(step, "i)UpgradeTower\s*\(\s*([^,]+?)\s*(?:,\s*(?:false|true)\s*)?(?:,\s*\d+\s*)?(?:,\s*(\d+)\s*)?(?:,\s*(\d+)\s*)?\s*\)", &m) {
            towerID := Trim(m[1])
            if (towers.Has(towerID) && m[2] != "") {
                towers[towerID].path := m[2]
                towers[towerID].pathLevel := (m[3] != "") ? m[3] : 4
            }
        }
    }
}

FileAppend("PASS strategy loader runtime smoke (AutoHotkey " A_AhkVersion ")`n", "*")
ExitApp(0)
