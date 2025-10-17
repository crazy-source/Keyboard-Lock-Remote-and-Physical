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

; Map scan codes to key names for fallback
global scanCodeToKey := Map(
    59, "F1", 60, "F2", 61, "F3", 62, "F4", 63, "F5", 
    64, "F6", 65, "F7", 66, "F8", 67, "F9", 68, "F10",
    87, "F11", 88, "F12", 338, "Insert"
)

AHI.SubscribeKeyboard(keyboardId, true, KeyboardEvent)

LWin::return
RWin::return
~LWin Up::return
~RWin Up::return

KeyboardEvent(code, state) {
    global ctrlPressed, altPressed, k_mode, l_mode, AHI, keyboardId, scanCodeToKey
    
    if (code = 29 || code = 157) {
        ctrlPressed := state
    }
    
    if (code = 56 || code = 184) {
        altPressed := state
    }
    
    ; K key (37) - K mode toggle
    if (code = 37 && state = 1) {
        if (ctrlPressed && altPressed) {
            if (l_mode) {
                l_mode := false
                StopRemoteBlock()
                k_mode := true
                SetTimer(() => ForceReleaseModifiers(), -50)
            } else if (k_mode) {
                k_mode := false
            } else {
                k_mode := true
                SetTimer(() => ForceReleaseModifiers(), -50)
            }
            return
        }
    }
    
    ; L key (38) - L mode toggle
    if (code = 38 && state = 1) {
        if (ctrlPressed && altPressed) {
            if (k_mode) {
                k_mode := false
                l_mode := true
                StartRemoteBlock()
                SetTimer(() => ForceReleaseModifiers(), -50)
            } else if (l_mode) {
                l_mode := false
                StopRemoteBlock()
            } else {
                l_mode := true
                StartRemoteBlock()
                SetTimer(() => ForceReleaseModifiers(), -50)
            }
            return
        }
    }
    
    ; K mode: Block home keyboard
    if (k_mode) {
        if ((code = 29 || code = 157 || code = 56 || code = 184) && state = 0) {
            try {
                AHI.SendKeyEvent(keyboardId, code, state)
            }
        }
        return
    }
    
    ; Send key through - with fallback for problematic keys
    try {
        AHI.SendKeyEvent(keyboardId, code, state)
    } catch {
        ; If SendKeyEvent fails, use regular Send as fallback
        if (scanCodeToKey.Has(code)) {
            keyName := scanCodeToKey[code]
            if (state = 1) {
                Send("{" . keyName . " down}")
            } else {
                Send("{" . keyName . " up}")
            }
        }
    }
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

OnExit(ExitCleanup)

ExitCleanup(*) {
    StopRemoteBlock()
}
