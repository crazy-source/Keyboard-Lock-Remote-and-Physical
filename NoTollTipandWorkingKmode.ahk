#SingleInstance force
Persistent
#include Lib\AutoHotInterception.ahk

A_IconTip := "Keyboard Toggle Script (Ctrl+Alt+K)"

; Initialize AutoHotInterception
global AHI := AutoHotInterception()

; Use Handle method for your keyboard
; Replace with YOUR keyboard's handle from Monitor.ahk
global keyboardId := AHI.GetKeyboardIdFromHandle("ACPI\VEN_DLLK&DEV_0B23", 1)

; Track key states for the toggle combination
global ctrlPressed := false
global altPressed := false
global keyboard_locked := false

; Start by subscribing to the entire keyboard in block mode
AHI.SubscribeKeyboard(keyboardId, true, KeyboardEvent)

; Main keyboard event handler - handles ALL keys
KeyboardEvent(code, state) {
    global ctrlPressed, altPressed, keyboard_locked, AHI, keyboardId
    
    ; Track Ctrl key state (29 = Left Ctrl, 157 = Right Ctrl with E0)
    if (code = 29 || code = 157) {
        ctrlPressed := state
    }
    
    ; Track Alt key state (56 = Left Alt, 184 = Right Alt with E0)
    if (code = 56 || code = 184) {
        altPressed := state
    }
    
    ; Track K key (37) and check for toggle combination
    if (code = 37 && state = 1) {  ; K key pressed down
        if (ctrlPressed && altPressed) {
            ; Toggle the keyboard lock state
            keyboard_locked := !keyboard_locked
            
            if (keyboard_locked) {
                ; Release all modifier keys to prevent stuck keys
                ReleaseAllModifiers()
                ToolTip("Keyboard Disabled")
            } else {
                ToolTip("Keyboard Enabled")
            }
            
            SetTimer(RemoveToolTip, -1)
            return  ; Block this keypress
        }
    }
    
    ; When keyboard is locked, block all keys
    if (keyboard_locked) {
        return  ; Block the key
    }
    
    ; When keyboard is unlocked, send the key through
    ; Use try-catch to prevent script from breaking on errors
    try {
        AHI.SendKeyEvent(keyboardId, code, state)
    } catch as err {
        ; If SendKeyEvent fails, just ignore and continue
        ; This prevents the script from crashing on certain keys
    }
}

; Release all modifier keys to prevent them from getting stuck
ReleaseAllModifiers() {
    ; List of all modifier keys to release
    modifiers := ["LControl", "RControl", "LAlt", "RAlt", "LShift", "RShift", "LWin", "RWin"]
    
    for index, key in modifiers {
        ; Check if the key is logically down
        if GetKeyState(key) {
            ; Send the key up event to release it
            Send("{" key " up}")
        }
    }
}

; Remove tooltip
RemoveToolTip() {
    ToolTip()
}
