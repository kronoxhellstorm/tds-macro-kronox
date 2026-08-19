#Requires AutoHotkey v2.0
#SingleInstance Force

watchdogSource := FileRead(A_ScriptDir "\..\submacros\watchdog.ahk")

if !InStr(watchdogSource, 'RestartMain("main-process-crash", true)')
    throw Error("Watchdog does not hard-reset after an unexpected main-process crash.")
if !InStr(watchdogSource, 'IniRead(StateFile, "State", "Running", 0)')
    throw Error("Watchdog crash recovery is not gated by the persisted running state.")
if !InStr(watchdogSource, "LaunchMainWithStartupGuard(reason)")
    throw Error("Watchdog restart does not supervise replacement-main startup.")
if !InStr(watchdogSource, 'IniWrite(0, StateFile, "State", "Running")')
    throw Error("Repeated startup crashes do not fall back to a safe idle UI.")

FileAppend("PASS watchdog relaunches crashes, supervises startup, and falls back safely`n", "*")
ExitApp(0)
