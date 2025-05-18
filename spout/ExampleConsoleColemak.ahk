#Requires AutoHotkey v2.0
#SingleInstance

; This script is designed for the SPOUT platform used with a Colemak keyboard layout lacking a hardware number pad and using the Capslock key as a modifier.



;Include primary script for Spout: 
;Synergistic Plugins Optimizing Usability of Transformers. 
#Include .\SpoutMain.ahk

; Add a custom tip to the tray icon
A_IconTip := A_IconTip . "Schuyler's Colemak Hotkey Map`n Capslock + Backspace to restart"

; Hotkey: CapsLock disabled for use as a modifier
; Function: Placeholder for CapsLock functionality
CapsLock::return

; Empty hotkeys to prevent accidental changes to keyboard layout, etc. (anti-annoyingness measure)
+Ctrl::{ 
}
^Shift::{ 
}
#Space::{
}
#^Space::{
}
#+Space::{
}
#+^Space::{
}

;-----------------------------------Keyboard Lock States-----------------------------------

; Hotkey: Shift + CapsLock
; Function: Toggles CapsLock state
+CapsLock:: {
    ; Prevent the default Capslock key behavior
    KeyWait "Capslock"
    SetCapsLockState(!GetKeyState("CapsLock", "T"))
    ToolTip("CapsLock " . (GetKeyState("CapsLock", "T") ? "ON" : "OFF"))
    SetTimer () => ToolTip(), -1000
}

; Hotkey: Ctrl + CapsLock (Capslock)
; Function: Toggles NumLock state and displays a tooltip
^CapsLock:: {
    SetNumLockState(!GetKeyState("NumLock", "T"))
    ToolTip("NumLock " . (GetKeyState("NumLock", "T") ? "ON" : "OFF"))
    SetTimer () => ToolTip(), -1000
}

; Hotkey: Alt + CapsLock (Capitalization)
; Function: Toggles ScrollLock state and displays a tooltip
!CapsLock:: {
    SetScrollLockState(!GetKeyState("ScrollLock", "T"))
    ToolTip("ScrollLock " . (GetKeyState("ScrollLock", "T") ? "ON" : "OFF"))
    SetTimer () => ToolTip(), -1000
}

; Hotkey: Win + CapsLock
; Function: Checks and displays the current state of NumLock, ScrollLock, and CapsLock
#Capslock::CheckLockState()

; Hotkey: CapsLock + Escape
;Function: Reloads this script
Capslock & Escape::SpoutReload()

;-----------------------------------Basic Spout Utilities-----------------------------------
; Hotkey: CapsLock + Space
; Function: Show Spout Context Menu
Capslock & Space:: {
    SpoutContextMenu().Show()
}

; Hotkey: CapsLock + ` (backtick)
; Function: Opens the settings GUI for the script
Capslock & `::SpoutSettings()

; Hotkey: CapsLock + Tab
; Function: Displays clipboard content using SpoutClipboard() function
CapsLock & Tab::SpoutClipboard()

;Hotkey: Capslock + Backspace
; Function: Sends "# " to switch keyboard layout
; Windows key must be non-disabled to use this function
Capslock & Backspace::{
  Send "# "
}  

;-----------------------------Spout Core GUI functions number keys;-----------------------------

Capslock & 1::SpoutReduce()
Capslock & 2::SpoutExpand()
Capslock & 3::SpoutEnhance()
Capslock & 4::SpoutTranslate()
Capslock & 5::SpoutMutate()
Capslock & 6::SpoutGenerate()
Capslock & 7::SpoutIterate()
Capslock & 8::SpoutConverse()
Capslock & 9::SpoutSearch()
Capslock & 0::SpoutEvaluate()
Capslock & [::SpoutParse()
Capslock & ]::SpoutImagine()

;-----------------------------F-key rows: Spout Add-ons;-----------------------------

Capslock & F1::IfAddon("SpoutAddon_Prompt_Booster_gui")
Capslock & F2::IfAddon("SpoutAddon_Analytics") 
Capslock & F3::IfAddon("SpoutAddon_Dialog")
Capslock & F4::return   
Capslock & F5::return
Capslock & F6::return
Capslock & F7::return
Capslock & F8::return
Capslock & F9::return
Capslock & F10::return
Capslock & F11::return
Capslock & F12::return


;-----------------------------Arrow key navigation with CapsLock;-----------------------------
; Up arrow - Expand and grow the selected text with more details and examples
Capslock & Up:: {
    if (KeyWait("up", "T.4")) {
        if (GetKeyState("Shift", "P")) {
            TallyDown()
        } else {
            TallyUp()
        }
    } else {
        KeyWait("up")
        ShowTallyUI()
    }
}

Capslock & Down::TallyDown()

Capslock & Left:: {
    if (KeyWait("left", "T.4")) {
        AddTimerMinutes(1)
    } else {
        KeyWait("left")
        CancelTimer()
    }
}

; Right arrow - Fix grammar, spelling and improve the writing quality
Capslock & Right:: {
    if (KeyWait("right", "T.4")) {
        AddTimerMinutes(5)
    } else {
        KeyWait("right")
        CancelTimer()
    }
}
;Enter key: toggle Spout Model
Capslock & Enter::SpoutModel()


;-----------------------------First five keys on top row Q, W, F, P, G;-----------------------------

; Hotkey: CapsLock (Capslock) + Q
; Function: Copies the current selection and appends it to the clipboard
Capslock & q::SpoutGist()

; Hotkey: CapsLock (Capslock) + W
; Function: Cuts the current selection and appends it to the existing clipboard content
Capslock & w::SpoutGrow()

; Hotkey: CapsLock (Capslock) + F (qwerty: E)
; Function: selects line or paragraph under the cursor and copies it to the clipboard.
Capslock & f:: {
    Click 3
    Send "^c"
    Sleep 510
    Click
    clipText := SubStr(A_Clipboard, 1, 9)
    ToolTip "copied " . clipText . "... "
    SetTimer () => ToolTip(), -500  
}

; Hotkey: CapsLock (Capslock) + P (qwerty: R)
; Function: Selects the word under the cursor and copies it to the clipboard.
Capslock & p::SpoutMend()

; Hotkey: CapsLock (Capslock) + G (qwerty: T)
; Function: Varies the selected text, nui function for SpoutMutate()
Capslock & g::SpoutVary()

;-----------------------------first five keys on middle row: A, R, S, T, D;-----------------------------

; Hotkey: CapsLock (Capslock) + A
; Function: Sends Ctrl+C (Copy)
Capslock & a:: {
    if (KeyWait("a", "T0.5")) {
        Send("^c")
    } else {
        KeyWait("a")
        AppendCopy()
    }
}

; Hotkey: CapsLock (Capslock) + R (qwerty: S)
; Function: Sends Ctrl+V (Paste), or replace the current selection with the clipboard content and press enter on hold.
Capslock & r:: {
    if (KeyWait("r", "T0.5")) {
        Send("^v")
    } else {
        KeyWait("r")
        Send("^a")
        Sleep 100
        Send("^v") 
        Sleep 100
        Send("{Enter}")
    }
}

; Hotkey: CapsLock (Capslock) + S (qwerty: D)
; Function: Sends Ctrl+X (Cut)
Capslock & s:: {
    if (KeyWait("s", "T0.5")) {
        Send("^x")
    } else {
        KeyWait("s")
        AppendCut()
    }
}

; Hotkey: CapsLock (Capslock) + T (qwerty: F)
; Function: Pastes the clipboard content and presses enter
Capslock & t:: {
    Send("^v")
    Sleep 150
    Send("{Enter}")
}

; Hotkey: CapsLock (Capslock) + D (qwerty: G)
; Function: Retrieves the pixel color under the cursor and copies it
Capslock & d::GetPixel()

;-------------------------First five keys on bottom row: Z, X, C, V, B--------------------------

; Hotkey: CapsLock (Capslock) + Z
; Function: Make sure cursor is open, then open edit window for press, or run dialog for long
Capslock & z:: {
    if !WinActive("ahk_exe cursor.exe") {
        if !WinExist("ahk_exe cursor.exe") {
            Send("#8")
            WinWait "ahk_exe cursor.exe"
        }
        WinActivate "ahk_exe cursor.exe"
    } else {   
        if (KeyWait("z", "T.4")) {
            Send("^k")
        } else {
            Send("^+p") 
        }
    }
}

; Hotkey: CapsLock (Capslock) + X
; Function: Saves the current clipboard content to a note file
Capslock & x:: {
    if (KeyWait("x", "T.4")) {
        savedClip := A_Clipboard
        Send("^c")
        Sleep(100)
        if (A_Clipboard != savedClip && StrLen(A_Clipboard) > 1) {
            SpoutNoter(content := A_Clipboard, true)
            Sleep 100
            A_Clipboard := savedClip
        } else {
            A_Clipboard := savedClip
            Sleep 100
            SpoutNoter()
        }
    } else {
        KeyWait("x")
        SpoutNoter()
    }
}

; Hotkey: CapsLock (Capslock) + C
; Function: SpoutNoter Secondary custom function
Capslock & c::{
    if (KeyWait("c", "T.4")) {
        savedClip := A_Clipboard
        Send("^c")
        Sleep(100)
        if (A_Clipboard != savedClip && StrLen(A_Clipboard) > 1) {
            SpoutNoter(content := A_Clipboard, auto := true, file := "other_notes.csv")
            Sleep 100
            A_Clipboard := savedClip
        } else {
            A_Clipboard := savedClip
            Sleep 100
            SpoutNoter("", auto := true, file := "other_notes.csv")
        }
    } else {
        KeyWait("c")
        SpoutNoter("", false, "other_notes.csv")
    }
}

; Hotkey: CapsLock (Capslock) + V
; Function: SpoutPull() default behavior
Capslock & v::SpoutPull()

; Hotkey: CapsLock (Capslock) + B
; Function: SpoutSave() default behavior
Capslock & b:: {
    if (KeyWait("b", "T.4")) {
        SpoutSave()
    } else {
        KeyWait("b")
        SpoutSave( , , ,gui := false)
    }
}

;-----------------------------------Right side of keyboard -----------------------------------
; Changed to Colemak layout for right-side keys

Capslock & j::SpoutVary(2)
Capslock & l::SpoutName()
Capslock & u::SpoutFill()
Capslock & y::SpoutJazz()
Capslock & `;::SpoutCast("as technical documentation")
Capslock & [::SpoutCast("as a polite and friendly message")
Capslock & ]::SpoutCast("as a professional slack message")
Capslock & \::SpoutCast("with absurd silly humor")

;--------Middle row of the Right side of the keyboard in Colemak:---------

Capslock & h::SpoutQuip("an appropriate and thought provoking response to: @clipboard")
Capslock & n::SpoutQuip("a 3 sentence long short story based on: @clipboard")
Capslock & e::SpoutQuip("a constructive response to: @clipboard")
Capslock & i::SpoutQuips("short sarcastic response to: @clipboard")
Capslock & o::SpoutQuips("1 sentence constructive response to: @clipboard")
Capslock & '::SpoutQuips("witty response to: @clipboard")

;---------Bottom row of the Right side of the keyboard in Colemak:---------

Capslock & k::IfAddon("SpoutAddon_Pipeline", "emphasize key points>add more detail>add more examples>add more examples")
Capslock & m::IfAddon("SpoutAddon_Pipeline", "rewrite this with a more casual tone>use a more casual friendly voice>add Jokes and friendly comments")
Capslock & ,::IfAddon("SpoutAddon_Pipeline", "add more colorful descriptive language>add some rhyming words>add some puns>add some idioms>add humorous anecdote>add some pop culture references")
Capslock & .::IfAddon("SpoutAddon_Pipelines", "add metaphors>add similes>use alliteration>use assonance>add puns")
Capslock & /::IfAddon("SpoutAddon_Pipelines", "add sentence structure variety>use more complex sentence structures>use more simple sentence structure>use more varied sentence lengths")



;----------------------------------Number Pad-----------------------------------
;numpad not used in this script


;-----------------------------------End of Script-----------------------------------