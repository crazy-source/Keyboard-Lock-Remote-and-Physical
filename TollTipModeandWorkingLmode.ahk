#SingleInstance force
Persistent
#include Lib\AutoHotInterception.ahk

A_IconTip := "Keyboard/Remote Toggle Script"

global AHI := AutoHotInterception()
global keyboardId := AHI.GetKeyboardIdFromHandle("ACPI\VEN_DLLK&DEV_0B23", 1)

global k_mode := false
global l_mode := false
global ctrlPressed := false
global altPressed := false
global mouseHook := 0
global keyboardHook := 0

AHI.SubscribeKeyboard(keyboardId, true, KeyboardEvent)

LWin::return
RWin::return
~LWin Up::return
~RWin Up::return

KeyboardEvent(code, state) {
    global ctrlPressed, altPressed, k_mode, l_mode, AHI, keyboardId
    
    if (code = 29 || code = 157) {
        ctrlPressed := state
    }
    
    if (code = 56 || code = 184) {
        altPressed := state
    }
    
    ; K key (37) - Toggle K mode
    if (code = 37 && state = 1) {
        if (ctrlPressed && altPressed) {
            if (l_mode) {
                l_mode := false
                StopRemoteBlock()
            }
            k_mode := !k_mode
            
            if (k_mode) {
                SetTimer(() => ForceReleaseModifiers(), -50)
            }
            
            ToolTip(k_mode ? "K Mode: Physical Keyboard Blocked" : "K Mode: Off")
            SetTimer(RemoveToolTip, -2000)
            return
        }
    }
    
    ; L key (38) - Toggle L mode
    if (code = 38 && state = 1) {
        if (ctrlPressed && altPressed) {
            if (k_mode) {
                k_mode := false
            }
            l_mode := !l_mode
            
            SetTimer(() => ForceReleaseModifiers(), -50)
            
            if (l_mode) {
                StartRemoteBlock()
                ToolTip("L Mode: Remote Inputs Blocked")
            } else {
                StopRemoteBlock()
                ToolTip("L Mode: Off")
            }
            SetTimer(RemoveToolTip, -2000)
            return
        }
    }
    
    ; S key (31) - Show status
    if (code = 31 && state = 1) {
        if (ctrlPressed && altPressed) {
            ShowStatus()
            return
        }
    }
    
    if (k_mode) {
        if ((code = 29 || code = 157 || code = 56 || code = 184) && state = 0) {
            try {
                AHI.SendKeyEvent(keyboardId, code, state)
            }
        }
        return
    }
    
    try {
        AHI.SendKeyEvent(keyboardId, code, state)
    }
}

; Show current status of all 4 input methods
ShowStatus() {
    global k_mode, l_mode
    
    ; Determine status for each input method
    homeKbd := k_mode ? "🔒 BLOCKED" : "✓ Working"
    homeMouse := "✓ Working"  ; Physical mouse always works
    remoteKbd := l_mode ? "🔒 BLOCKED" : "✓ Working"
    remoteMouse := l_mode ? "🔒 BLOCKED" : "✓ Working"
    
    ; Build status message
    statusMsg := "═══════════════════════════════`n"
    statusMsg .= "        INPUT STATUS`n"
    statusMsg .= "═══════════════════════════════`n`n"
    statusMsg .= "HOME COMPUTER (Physical):`n"
    statusMsg .= "  Keyboard:  " . homeKbd . "`n"
    statusMsg .= "  Mouse:     " . homeMouse . "`n`n"
    statusMsg .= "REMOTE COMPUTER (Work PC):`n"
    statusMsg .= "  Keyboard:  " . remoteKbd . "`n"
    statusMsg .= "  Mouse:     " . remoteMouse . "`n`n"
    statusMsg .= "═══════════════════════════════`n"
    statusMsg .= "Current Mode: " . (k_mode ? "K Mode" : (l_mode ? "L Mode" : "Normal")) . "`n"
    statusMsg .= "═══════════════════════════════"
    
    ; Show in tooltip for 5 seconds
    ToolTip(statusMsg)
    SetTimer(RemoveToolTip, -5000)
}

ForceReleaseModifiers() {
    global AHI, keyboardId
    
    modifierCodes := [29, 157, 56, 184, 42, 54]
    
    for index, code in modifierCodes {
        try {
            AHI.SendKeyEvent(keyboardId, code, 0)
        }
    }
    
    Send("{LControl up}{RControl up}{LAlt up}{RAlt up}{LShift up}{RShift up}")
}

StartRemoteBlock() {
    global mouseHook, keyboardHook
    
    mouseHook := DllCall("SetWindowsHookEx", "Int", 14, "Ptr", CallbackCreate(MouseHookProc), 
                         "Ptr", DllCall("GetModuleHandle", "Ptr", 0, "Ptr"), "UInt", 0, "Ptr")
    
    keyboardHook := DllCall("SetWindowsHookEx", "Int", 13, "Ptr", CallbackCreate(KeyboardHookProc),
                           "Ptr", DllCall("GetModuleHandle", "Ptr", 0, "Ptr"), "UInt", 0, "Ptr")
}

StopRemoteBlock() {
    global mouseHook, keyboardHook
    
    if (mouseHook) {
        DllCall("UnhookWindowsHookEx", "Ptr", mouseHook)
        mouseHook := 0
    }
    
    if (keyboardHook) {
        DllCall("UnhookWindowsHookEx", "Ptr", keyboardHook)
        keyboardHook := 0
    }
}

MouseHookProc(nCode, wParam, lParam) {
    global l_mode
    
    if (nCode >= 0 && l_mode) {
        flags := NumGet(lParam + 12, "UInt")
        dwExtraInfo := NumGet(lParam + 20, "UPtr")
        
        if (flags & 0x01 || dwExtraInfo != 0) {
            return 1
        }
    }
    
    return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "UInt", wParam, "UInt", lParam)
}

KeyboardHookProc(nCode, wParam, lParam) {
    global l_mode
    
    if (nCode >= 0 && l_mode) {
        vkCode := NumGet(lParam, "UInt")
        flags := NumGet(lParam + 8, "UInt")
        dwExtraInfo := NumGet(lParam + 16, "UPtr")
        
        if ((vkCode = 0x4B || vkCode = 0x4C) && GetKeyState("Ctrl") && GetKeyState("Alt")) {
            ; Allow Ctrl+Alt+K and Ctrl+Alt+L
        } else if (flags & 0x10) {
            return 1
        } else if (dwExtraInfo != 0) {
            return 1
        }
    }
    
    return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "UInt", wParam, "UInt", lParam)
}

RemoveToolTip() {
    ToolTip()
}

OnExit(ExitCleanup)

ExitCleanup(*) {
    StopRemoteBlock()
}
