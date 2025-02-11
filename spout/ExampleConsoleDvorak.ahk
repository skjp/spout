#Requires AutoHotkey v2.0
#SingleInstance

; This script is designed for the SPOUT platform used with a DVORAK keyboard layout lacking a hardware number pad and using the Capslock key as a modifier.



;Include primary script for Spout: 
;Synergistic Plugins Optimizing Usability of Transformers. 
#Include .\SpoutMain.ahk

; Add a custom tip to the tray icon
A_IconTip := A_IconTip . "Schuyler's Original Dvorak Hotkey Map`n Capslock + Backspace to restart"

; Helper function to check premium feature availability
IfAddon(funcName, params := "") {
    if (IsSet(%funcName%)) {
        if (params = "") {
            %funcName%()
        } else {
            %funcName%(params)
        }
    } else {
        MsgBox("This feature requires an addon made available to Supporters of the project. Please visit Spout.dev to learn more.", "Addon Required", "Icon!")
    }
}

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

; Hotkey: Shift + CapsLock (Capslock)
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

; Hotkey: Win + CapsLock (Capslock)
; Function: Checks and displays the current state of NumLock, ScrollLock, and CapsLock
#Capslock::CheckLockState()

; Hotkey: CapsLock (Capslock) + Escape
; Function: Sends "# " to switch keyboard layout
Capslock & Escape::SpoutReload()

;-----------------------------------Basic Spout Utilities-----------------------------------
; Hotkey: CapsLock (Capslock) + Space
; Function: Show Spout Context Menu
Capslock & Space:: {
    SpoutContextMenu().Show()
}

; Hotkey: CapsLock (Capslock) + ` (backtick)
; Function: Opens the settings GUI for the script
Capslock & `::SpoutSettings()

; Hotkey: CapsLock (Capslock) + Tab
; Function: Displays clipboard content using SpoutClipboard() function
CapsLock & Tab::SpoutClipboard()

;Hotkey: Capslock + Backspace
;Function: Reloads this script
Capslock & BackSpace::{
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


;-----------------------------First five keys on top row ', ,, ., p;-----------------------------

; Hotkey: CapsLock (Capslock) + ' (qwerty: q)
; Function: Copies the current selection and appends it to the clipboard
Capslock & ':: {
    SpoutGist()
}

; Hotkey: CapsLock (Capslock) + , (qwerty: w)
; Function: Cuts the current selection and appends it to the existing clipboard content
Capslock & ,:: {
    SpoutGrow()
}

; Hotkey: CapsLock (Capslock) + . (qwerty: e)
; Function: selects line or paragraph under the cursor and copies it to the cilpboard.
Capslock & .:: {
    Click 3
    Send "^c"
    Sleep 510
    Click
    clipText := SubStr(A_Clipboard, 1, 9)
    ToolTip "copied " . clipText . "... "
    SetTimer () => ToolTip(), -500  
}


; Hotkey: CapsLock (Capslock) + p (qwerty: r)
; Function: Selects the word under the cursor and copies it to the clipboard.
Capslock & p::SpoutMend()

;Hotkey: CapsLock (Capslock) + y (qwerty: t)
; Function: Varies the selected text, nui function for SpoutMutate()
Capslock & y::SpoutVary()


;-----------------------------first five keys on middle row: a, o, e, u;-----------------------------
 
; Hotkey: CapsLock (Capslock) + A (qwerty: A)
; Function: Sends Ctrl+C (Copy)
Capslock & a:: {
    if (KeyWait("a", "T0.5")) {
        Send("^c")
    } else {
        KeyWait("a")
        AppendCopy()
    }
}

; Hotkey: CapsLock (Capslock) + O (qwerty: S)
; Function: Sends Ctrl+V (Paste), or replace the current selection with the clipboard content and press ender on hold. 
Capslock & o:: {
    if (KeyWait("o", "T0.5")) {
        Send("^v")
    } else {
        KeyWait("o")
        Send("^a")
        Sleep 100
        Send("^v") 
        Sleep 100
        Send("{Enter}")
    }
}

; Hotkey: CapsLock (Capslock) + E (qwerty: D)
; Function: Sends Ctrl+X (Cut)
Capslock & e:: {
    if (KeyWait("e", "T0.5")) {
        Send("^x")
    } else {
        KeyWait("e")
        AppendCut()
    }
}


; Hotkey: CapsLock (Capslock) + U (qwerty: f)
; Function: Pastes the clipboard content and presses enter
Capslock & u:: {
    Send("^v")
    Sleep 150
    Send("{Enter}")
}

; Hotkey: CapsLock (Capslock) + I (qwerty: g)
; Function: Retrieves the pixel color under the cursor and copies it
Capslock & i::GetPixel()

;-------------------------First five keys on bottom row: ;, q, j, k--------------------------

; Hotkey: CapsLock (Capslock) + ; (qwerty: z)
; Function: Make sure cursor is open, then open edit window for press, or run dialog for long
Capslock & `;:: {
    if !WinActive("ahk_exe cursor.exe") {
        ; Try to activate cursor.exe, or start it if not running
        if !WinExist("ahk_exe cursor.exe") {
            Send("#8")
            WinWait "ahk_exe cursor.exe"
        }
        WinActivate "ahk_exe cursor.exe"

    } else {
           
        if (KeyWait(";", "T.4")) {
            Send("^k")
        } else {
            ;KeyWait(";")
            Send("^+p") 
        }
        
    }
}

; Hotkey: CapsLock (Capslock) + Q (qwerty: x)
; Function: Saves the current clipboard content to a note file if it has changed and is longer than 1 character
Capslock & q:: {
    if (KeyWait("q", "T.4")) {
        ; Save current clipboard
        savedClip := A_Clipboard
        ; Try to copy selected text
        Send("^c")
        Sleep(100) ; Give time for clipboard to update
        if (A_Clipboard != savedClip && StrLen(A_Clipboard) > 1) {
            ; New text was copied
            SpoutNoter(content := A_Clipboard, true)
            Sleep 100
            A_Clipboard := savedClip
        } else {
            ; No new text, restore clipboard and run without content
            A_Clipboard := savedClip
            Sleep 100
            SpoutNoter()
        }
    } else {
        KeyWait("q")
        SpoutNoter()
    }
}

; Hotkey: CapsLock (Capslock) + J (qwerty: c)
; Function:SpoutNoter Secondary custom function
Capslock & j::{
    if (KeyWait("j", "T.4")) {
        ; Save current clipboard
        savedClip := A_Clipboard
        ; Try to copy selected text
        Send("^c")
        Sleep(100) ; Give time for clipboard to update
        if (A_Clipboard != savedClip && StrLen(A_Clipboard) > 1) {
            ; New text was copied
            SpoutNoter(content := A_Clipboard, auto := true, file := "other_notes.csv")
            Sleep 100
            A_Clipboard := savedClip

        } else {
            ; No new text, restore clipboard and run without content
            A_Clipboard := savedClip
            Sleep 100
            SpoutNoter("", auto := true, file := "other_notes.csv")
        }
    } else {
        KeyWait("j")
        SpoutNoter("", false, "other_notes.csv")
    }


}

; Hotkey: CapsLock (Capslock) + K (qwerty: v)
; Function: SpoutPull() default behavior uses the Parse function to extract main points from a text prompt and open in SpoutNoter
Capslock & k::SpoutPull()

; Hotkey: CapsLock (Capslock) + X (qwerty: b)
; Function: SpoutSave() default behavior uses the Parse function to extract parts of a generative AI image prompt using a custom Spoutlet
Capslock & x:: {
    if (KeyWait("x", "T.4")) {
        SpoutSave()
    } else {
        KeyWait("x")
        SpoutSave( , , ,gui := false)
    }
}


;-----------------------------------Right side of keyboard -----------------------------------
; ----------Top row of the Right side of the keyboard in dvorak-------
;Two top row keys to the right of the center on the dvorak keyboard.
; utilize vary function for generating text and the cast function for changing the text

Capslock & f::SpoutVary(2)
Capslock & g::SpoutName()
Capslock & c::SpoutFill()
Capslock & r::SpoutJazz()
Capslock & l::SpoutCast("as technical documentation")
Capslock & /::SpoutCast("as a polite and friendly message")
Capslock & =::SpoutCast("as a professional slack message")
Capslock & \::SpoutCast("with absurd silly humor")


;--------Middle row of the Right side of the keyboard in dvorak:---------
;Two middle row keys to the right of the center on the dvorak keyboard.
; utilize quip and quips functions for generating text

Capslock & d::SpoutQuip("an appropriate and thought provoking response to: @clipboard")
Capslock & h::SpoutQuip("a 3 sentence long short story based on: @clipboard")
Capslock & t::SpoutQuip("a constructive response to: @clipboard")
Capslock & n::SpoutQuips("short sarcastic response to: @clipboard")
Capslock & S::SpoutQuips("1 sentence constructive response to: @clipboard")
Capslock & -::SpoutQuips("witty response to: @clipboard")


;---------Bottom row of the Right side of the keyboard in dvorak:---------
;Two bottom row keys to the right of the center on the dvorak keyboard.
; utilize pipeline functions for modifying text



; Pipeline hotkeys for text transformation
Capslock & b::IfAddon("SpoutAddon_Pipeline", "emphasize key points>add more detail>add more examples>add more examples")
Capslock & m::IfAddon("SpoutAddon_Pipeline", "rewrite this with a more casual tone>use a more casual friendly voice>add Jokes and friendly comments")
Capslock & w::IfAddon("SpoutAddon_Pipeline", "add more colorful descriptive language>add some rhyming words>add some puns>add some idioms>add humorous anecdote>add some pop culture references")
Capslock & v::IfAddon("SpoutAddon_Pipelines", "add metaphors>add similes>use alliteration>use assonance>add puns")
Capslock & z::IfAddon("SpoutAddon_Pipelines", "add sentence structure variety>use more complex sentence structures>use more simple sentence structure>use more varied sentence lengths")



;----------------------------------Number Pad-----------------------------------
;numpad not used in this script


;-----------------------------------End of Script-----------------------------------