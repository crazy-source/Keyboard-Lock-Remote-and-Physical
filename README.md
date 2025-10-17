# Keyboard & Remote Input Control Script (about the Final version)

A script to selectively block physical keyboard and remote desktop inputs when using Chrome Remote Desktop.

## Usage

Run the script on your **home computer** (the physical Dell laptop being accessed remotely).

## Modes

### K Mode - `Ctrl + Alt + K`
**Blocks:** Home computer physical keyboard  
**Allows:** Remote computer (work PC) keyboard and mouse

When K mode is active:
- Physical laptop keyboard is disabled
- Remote inputs from work computer work normally
- Physical mouse on home computer works normally
- Brief "K" tooltip appears

### L Mode - `Ctrl + Alt + L`
**Blocks:** Remote computer (work PC) keyboard and mouse  
**Allows:** Home computer physical keyboard and mouse

When L mode is active:
- All remote inputs are blocked
- Physical keyboard and mouse work normally
- Brief "L" tooltip appears

### Normal Mode
**Allows:** Everything works normally

When both modes are off:
- Brief empty tooltip appears
- All inputs work as expected

## Mode Switching Behavior

| Current State | Press K Combo | Press L Combo |
|--------------|---------------|---------------|
| Normal (both off) | Activates K Mode | Activates L Mode |
| K Mode ON | Toggles OFF (to Normal) | Switches to L Mode |
| L Mode ON | Switches to K Mode | Toggles OFF (to Normal) |

## Special Features

### Windows Key
The Windows key is **permanently disabled** in all modes (including Normal mode) on both physical and remote keyboards to prevent accidental Start menu activation.

### Key Release Protection
When switching between modes, all modifier keys (Ctrl, Alt, Shift) are automatically released to prevent stuck keys and typing errors.

### Function Keys & Insert
F1-F12 and Insert keys work properly in all modes with automatic fallback handling.

## Quick Reference

- `Ctrl + Alt + K` = Toggle/Switch to K Mode (block physical keyboard)
- `Ctrl + Alt + L` = Toggle/Switch to L Mode (block remote inputs)
- **These combinations always work** regardless of current mode
- Tooltips display current mode briefly (0.8 seconds)
- Windows key is always blocked

## Use Cases

**Working remotely, want to lock physical keyboard:** Press `Ctrl + Alt + K`

**Need to prevent accidental remote inputs:** Press `Ctrl + Alt + L`

**Switch from remote work back to physical use:** From K mode, press `Ctrl + Alt + L`

**Return to normal operation:** Press the same combination again to toggle off
