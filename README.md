# Keyboard Toggle Script - README

## Overview

This AutoHotkey v2 script allows you to toggle your physical keyboard input on/off using **Ctrl+Alt+K**. When disabled, all keyboard input is blocked (except the toggle combination itself), making it useful for remote desktop sessions or preventing accidental key presses.

## Prerequisites

- AutoHotkey v2
- AutoHotInterception library
- The `AutoHotInterception.ahk` file must be located in `Lib\` folder relative to the script

## Setup Instructions

### 1. Install AutoHotInterception

Download and extract AutoHotInterception, ensuring the following structure:
```
YourScriptFolder/
├── KeyboardToggle.ahk (your script)
└── Lib/
    └── AutoHotInterception.ahk
```

### 2. Find Your Keyboard Handle

Run the `Monitor.ahk` script included with AutoHotInterception to identify your keyboard's handle. Look for an entry like:
```
ACPI\VEN_DLLK&DEV_0B23
```

### 3. Update the Script

Replace the keyboard handle in line 11:
```ahk
global keyboardId := AHI.GetKeyboardIdFromHandle("YOUR_KEYBOARD_HANDLE_HERE", 1)
```

## Usage

1. **Run the script** - A system tray icon appears with tooltip "Keyboard Toggle Script (Ctrl+Alt+K)"
2. **Press Ctrl+Alt+K** to disable the keyboard
   - A tooltip appears: "Keyboard Disabled"
   - All keyboard input is now blocked
3. **Press Ctrl+Alt+K again** to enable the keyboard
   - A tooltip appears: "Keyboard Enabled"

## Features

- **Complete keyboard blocking** when disabled (including modifier keys)
- **Automatic modifier key release** when toggling to prevent stuck keys
- **Visual feedback** via tooltips
- **Error handling** to prevent script crashes
- **Single instance** - only one copy runs at a time

## Troubleshooting

**Script doesn't block keyboard:**
- Verify your keyboard handle is correct using `Monitor.ahk`
- Ensure AutoHotInterception drivers are properly installed
- Try running the script as Administrator

**Keys get stuck:**
- The script automatically releases all modifier keys when toggling
- If issues persist, manually press and release stuck keys

**Toggle combination doesn't work:**
- Ensure both Ctrl and Alt are pressed before pressing K
- Check if another program is intercepting the hotkey

## Technical Details

- Uses blocking mode subscription to intercept all keyboard events
- Tracks modifier key states (Ctrl/Alt) to detect toggle combination
- Scan code 37 = K key, 29 = Left Ctrl, 56 = Left Alt
- Implements `SendKeyEvent()` passthrough when keyboard is unlocked
