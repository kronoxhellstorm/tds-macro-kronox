#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "%A_ScriptDir%\..\lib\OCR.ahk"

GetCurrentGdiCount() {
    processHandle := DllCall("GetCurrentProcess", "Ptr")
    return DllCall("GetGuiResources", "Ptr", processHandle, "UInt", 0, "UInt")
}

testGui := Gui("-Caption +ToolWindow")
testGui.BackColor := "202020"
testGui.Add("Text", "x10 y10 w180 h30 cFFFFFF", "OCR resource smoke test")
testGui.Show("x20 y20 w220 h100 NoActivate")

before := GetCurrentGdiCount()
Loop 80 {
    bitmap := 0
    result := 0
    try {
        bitmap := OCR.CreateHBitmap(0, 0, 180, 70,
            {hWnd: testGui.Hwnd, onlyClientArea: 1, mode: 2}, 2)
        result := OCR.FromBitmap(bitmap, {lang: "en-US", grayscale: true})
    } finally {
        result := 0
        bitmap := 0
    }
}
Sleep(100)
after := GetCurrentGdiCount()
delta := after - before
testGui.Destroy()

if (delta > 8) {
    FileAppend("FAIL scaled OCR leaked " delta " GDI objects`n", "*")
    ExitApp(1)
}

FileAppend("PASS scaled OCR GDI resource ownership (delta " delta ")`n", "*")
ExitApp(0)
