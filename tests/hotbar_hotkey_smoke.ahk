#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "%A_ScriptDir%\..\lib\TowerXP.ahk"
#Include "%A_ScriptDir%\..\lib\KronoxFeatures.ahk"

try {
    message := RunHotbarHotkeySmoke()
    FileAppend("PASS " message "`n", "*")
    ExitApp(0)
} catch Error as err {
    FileAppend("FAIL " err.Message "`n", "*")
    ExitApp(1)
}

RunHotbarHotkeySmoke() {
mainSource := FileRead(A_ScriptDir "\..\Main.ahk")
for forbidden in ["DetectTDSHotbarMode", "SendControlledHotbarToggle"] {
    if InStr(mainSource, forbidden)
        throw Error("Unsafe automatic hotbar recovery remains in Main.ahk: " forbidden)
    }

if (KronoxHotbarTowerPriceCount("$450  $3,000  $10,000") != 3)
    throw Error("Tower price classifier did not recognize tower hotbar prices.")
if (KronoxHotbarTowerPriceCount("38  1/1  3/3  5/5") != 0)
    throw Error("Consumable quantities were misclassified as tower prices.")

spawnStart := InStr(mainSource, "SpawnTower(X, Y, slotNumber, towerID)")
if (!spawnStart)
    throw Error("SpawnTower was not found.")
spawnSource := SubStr(mainSource, spawnStart, 8000)
guardPos := InStr(spawnSource, "EnsureTowerHotbarBeforeSlotInput(slotNumber, towerID)")
slotSendPos := InStr(spawnSource, 'Send("{" slotNumber "}")')
if (!guardPos || !slotSendPos || guardPos > slotSendPos)
    throw Error("SpawnTower can send a slot key before visual tower-hotbar verification.")

if !InStr(mainSource, 'BlockUnsafeRecordingHotkeyPassthrough(AlignCameraKey, "Align Camera hotkey")')
    throw Error("The Ctrl+T recording shortcut can still pass T through during playback.")
if !InStr(mainSource, 'AlignCameraKey := "^g"')
    throw Error("The legacy Ctrl+T Align Camera shortcut is not migrated to a safe key.")
if !InStr(mainSource, 'Blocked recorded strategy input')
    throw Error("Recorded Send(T) steps are not blocked.")
if !InStr(mainSource, 'SetTimer(HotbarSafetyWatchdog, 12000)')
    throw Error("Continuous hotbar safety watchdog is not registered.")
if !InStr(mainSource, 'HotbarSafetyWatchdog(*)')
    throw Error("Continuous hotbar safety watchdog is not implemented.")
if !InStr(mainSource, 'TriggerUnsafeHotbarRecovery(detail, inspection := "")')
    throw Error("Unsafe-hotbar recovery is not centralized.")
if !InStr(mainSource, 'SendGameplayKey(keySpec, actionName := "gameplay action")')
    throw Error("Configured gameplay key sends bypass strict hotbar validation.")
if !InStr(mainSource, 'SanitizeGameplayKeyBinding(keySpec, fallback, iniName)')
    throw Error("Persisted TDS keybinds are not migrated away from T.")
if !InStr(mainSource, 'ClickCloneSourceTowerSafely(towerID)')
    throw Error("Clone source clicks are not hover-validated.")
if !InStr(mainSource, 'Skipped an unverified clone-source click')
    throw Error("Clone source validation still allows a silent blind-click fallback.")
if !InStr(mainSource, 'VerifyTowerHotbarAfterRiskyClick(actionName)')
    throw Error("Late-game mouse clicks do not immediately verify the tower hotbar.")
if !InStr(mainSource, 'Hotkey("$*t", BlockTowerHotbarToggle, "On")')
    throw Error("The direct T hotbar-toggle blocker is missing.")

consumableStart := InStr(mainSource, 'UseBudgetedConsumable(x, y, name := "Consumable")')
consumableEnd := InStr(mainSource, "LowerGraphics()",, consumableStart)
consumableSource := SubStr(mainSource, consumableStart, consumableEnd - consumableStart)
if InStr(consumableSource, "Click(")
    throw Error("Automated UseConsumable still contains a click path.")
if !InStr(consumableSource, "Consumable step blocked by strict hotbar safety")
    throw Error("Automated UseConsumable is not fail-closed.")

toolStart := InStr(mainSource, "RunAutoConsumableTool(*)")
toolSource := SubStr(mainSource, toolStart, 700)
if InStr(toolSource, "auto_open_consumable.ahk")
    throw Error("The legacy Auto Consumable tool can still be launched.")

return "strict hotbar preflight, all T paths blocked, and no automated consumable path"
}
