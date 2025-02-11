#Requires AutoHotkey v2.0


global soundEffects


class SpoutFunction {
    __New(auto := false, nui := false) {
        this.auto := auto
        this.nui := nui
        this.originalContent := ""
        this.progress := 0
        this.colorScheme := GetCurrentColorScheme()
        this.timerRunning := false
        this.spoutlets := []  ; Add array to store available spoutlets
    }

    InitializeGUI(title, functionName) {
        global SpoutGui
        global processHandle
        this.processHandle := 0
        resetGui()
        Sleep(50)
        this.title := title
        this.functionName := functionName
        SpoutGui := Gui("+ToolWindow", "Spout " . title)
        SpoutGui.BackColor := this.colorScheme.Background
        SpoutGui.SetFont("s16", "Arial")
        SpoutGui.Add("Text", "x10 y10 w300 c" . this.colorScheme.Text, "Original Text:")
        
        ; Add Spoutlets dropdown with better layout
        this.LoadSpoutlets(this.title)
        
        ; Only show spoutlet selector if there are multiple options
        if (this.spoutlets.Length > 1) {
            SpoutGui.SetFont("s12", "Arial")  ; Smaller font for the label
            SpoutGui.Add("Text", "x423 y14 w100 c" . this.colorScheme.Text, "Spoutlet:")
            preferredSpoutlet := IniRead(A_ScriptDir . "\config\settings.ini", this.title, "PreferredSpoutlet", "default")
            this.spoutletDropdown := SpoutGui.Add("DropDownList", "x500 y10 w140 c" . this.colorScheme.Text . " Background" . this.colorScheme.EditBackground, this.spoutlets)
            this.spoutletDropdown.Value := this.GetSpoutletIndex(preferredSpoutlet)
        }
        
        SpoutGui.SetFont("s14", "Arial")  ; Reset font size for next elements
        
        SpoutGui.Add("Edit", "x10 y40 w630 h160 vOriginalText c" . this.colorScheme.Text . " Background" . this.colorScheme.EditBackground, this.originalContent)
        
        SpoutGui.SetFont("s16", "Arial")
        SpoutGui.Add("Text", "x10 y200 w300 vWaitingText c" . this.colorScheme.Text, "Ready to " . this.title)
        SpoutGui.SetFont("norm s13", "Arial")
        SpoutGui.Add("Progress", "x320 y205 w270 h24 vProgressBar Range0-100 c" . this.colorScheme.Text . " Background" . this.colorScheme.EditBackground)
        SpoutGui.SetFont("s14", "Arial")  ; Set font size before the second Edit control
        SpoutGui.Add("Edit", "x10 y240 w630 h190 v" . "ResultText c" . this.colorScheme.Text . " Background" . this.colorScheme.EditBackground)



        ; Buttons at bottom
        buttonY := 440
        SpoutGui.Add("Button", "x10 y" . buttonY . " w140 h40 vRunAgainButton", title).OnEvent("Click", (*) => this.Run())
        SpoutGui.Add("Button", "x+10 y" . buttonY . " w140 h40 vOriginalButton", "Copy Original").OnEvent("Click", (*) => this.CopyOriginal())
        SpoutGui.Add("Button", "x+10 y" . buttonY . " w180 h40 v" . functionName . "Button", "Copy " . functionName).OnEvent("Click", (*) => this.CopyModified(functionName))
        SpoutGui.Add("Button", "x+10 y" . buttonY . " w140 h40", "Cancel").OnEvent("Click", (*) => this.ExitApp())

        SpoutGui.OnEvent("Escape", (*) => this.ExitApp())
        SpoutGui.OnEvent("Close", (*) => this.ExitApp())


        pos := GetGuiPosition()
        if (pos.x = "center") {
            SpoutGui.Show("w650")
        } else {
            SpoutGui.Show("x" pos.x " y" pos.y " w650")
        } 

        SpoutGui["OriginalText"].Focus()
        if (this.auto) {
            this.Run()
        }
    }

    CopyOriginal() {
        A_Clipboard := SpoutGui["OriginalText"].Value
        this.ExitApp()
    }

    CopyModified(functionName) {
        A_Clipboard := SpoutGui["ResultText"].Value
        this.ExitApp()
    }

    ExitApp(*) {
        SaveGuiPosition(SpoutGui.Hwnd)
        this.StopProgressBar()
        SpoutGui.Destroy()
    }

    Run(*) {
        this.progress := 0
        originalText := SpoutGui["OriginalText"].Value
        Sleep(200)
        SpoutGui["ProgressBar"].visible := true
        SpoutGui["WaitingText"].Value := "Processing..."
        this.StartProgressBar()
        ; Update the escaping logic
        escapedContent := originalText
        escapedContent := StrReplace(escapedContent, "\", "\\")
        escapedContent := StrReplace(escapedContent, "`"", "\`"")
        escapedContent := StrReplace(escapedContent, "`n", "\n") 
        escapedContent := StrReplace(escapedContent, "`r", "\r")
        try {
            escapedSpoutlet := StrReplace(this.spoutlets[this.spoutletDropdown.Value], '"', '\"')
        } catch {
            escapedSpoutlet := "default"
        }

        scriptPath := A_ScriptDir . "\shared\spout_base_functions.py"
        cmd := Format('pythonw.exe "{1}" "{2}" "{3}" "{4}"',
            scriptPath,
            this.title,
            escapedSpoutlet,
            escapedContent)

        Run(cmd, , "Hide", &processHandle)
        this.process := processHandle

        ; Set up a timer to check for process completion
        SetTimer((*) => this.CheckProcessCompletion(), 100)
    }
    


    CheckProcessCompletion() {
        if (!ProcessExist(this.process)) {

            SetTimer , 0 ; Turn off the timer
            this.ProcessOutput()
        }
    }


    ProcessOutput() {
        
        Sleep(50)  ; Wait for 200 ms
        this.modifiedContent := A_Clipboard
        try {
            this.timerRunning := false
            SpoutGui["ProgressBar"].visible := false
            this.progress := 0
        } catch {

        }
    
        
        if (this.modifiedContent != "") {
            SpoutGui["WaitingText"].Value := this.functionName . " Text:"
            SpoutGui["ResultText"].Value := this.modifiedContent
            if (soundEffects) {
                SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
            }
        } else {
            SpoutGui["WaitingText"].Value := "Error: Unable to " . this.title . " the content."
            if (soundEffects) {
                SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
            }
        }
        A_Clipboard := this.originalContent
    }
    

    StartProgressBar() {
        if (!this.timerRunning) {
            this.timerRunning := true
            SetTimer((*) => this.UpdateProgressBar(), 100)
            
        }
    }

    StopProgressBar() {
        if (this.timerRunning) {
            SetTImer , 0
            this.timerRunning := false
            try {
                SpoutGui["ProgressBar"].Visible := false
                this.progress := 0
            } catch {
                ; Handle the case where the GUI might have been closed
            }
        }
    }

    UpdateProgressBar() {
        if (this.timerRunning == false) {
            SetTimer , 0 
            return
        }
        try {
            if (this.progress > 50) {
                this.progress += (100 - this.progress) / 200
            } else {
                this.progress += .5
            }
            if (this.progress > 100) {
                this.progress := 0
            }
            SpoutGui["ProgressBar"].Value := this.progress
        } catch {
            this.progress := 0
            return
        }
    }

    LoadSpoutlets(title) {
        this.spoutlets := ["default"]  ; Always start with default
        basePluginPath := (title = "reduce" || title = "expand" || title = "enhance" || title = "title") 
            ? A_ScriptDir . "\core\" . StrLower(title)
            : A_ScriptDir . "\addons\" . StrLower(title)
        
        ; Define plugin directories with precedence (local > pro > base)
        pluginDirs := [
            basePluginPath . "\" . StrLower(title) . "_plugins",  ; base plugins
            basePluginPath . "\" . StrLower(title) . "_pro",      ; pro plugins
            basePluginPath . "\" . StrLower(title) . "_local"     ; local plugins
        ]
        
        ; Track seen spoutlet names to handle precedence
        seenSpoutlets := Map()
        
        ; Check each plugin directory in reverse order (for precedence)
        Loop 3 {
            currentDir := pluginDirs[4 - A_Index]  ; Start from end of array for correct precedence
            if (DirExist(currentDir)) {
                loop files currentDir . "\*.*", "D" {
                    if (A_LoopFileName != "default" && !seenSpoutlets.Has(A_LoopFileName)) {
                        this.spoutlets.Push(A_LoopFileName)
                        seenSpoutlets[A_LoopFileName] := true
                    }
                }
            }
        }
    }

    GetSpoutletIndex(spoutletName) {
        for index, name in this.spoutlets {
            if (name = spoutletName)
                return index
        }
        return 1  ; Return first index (default) if not found
    }
}

class SpoutFunctionNoGUI {
    __New(functionName, spoutlet := "default") {
        this.functionName := functionName
        this.spoutlet := spoutlet
        this.process := 0
    }

    Run(text := "") {
        Send "^c"
        this.originalContent := (text != "") ? text : A_Clipboard
        Sleep(100)
        
        ; Show tooltip with the function name
        this.tooltipDots := "... \"
        ToolTip("Running " this.functionName this.tooltipDots)

        ; Run the Python script and get the process handle
        escapedTitle := StrReplace(this.functionName, '"', '``"')
        escapedSpoutlet := StrReplace(this.spoutlet, '"', '``"')
        escapedContent := StrReplace(this.originalContent, '"', '``"')

        ; Changed: Updated parameter order to match Python script
        Run("pythonw.exe " A_ScriptDir "\shared\spout_base_functions.py `"" 
            . escapedTitle . "`" `"" 
            . escapedSpoutlet . "`" `""
            . escapedContent . "`"", , "Hide", &processHandle)
        this.process := processHandle

        ; Set up a timer to check for process completion
        SetTimer((*) => this.CheckProcessCompletion(), 100)
    }

    CheckProcessCompletion() {
        if (!ProcessExist(this.process)) {
            SetTimer , 0 ; Turn off the timer
            ToolTip  ; Hide the tooltip
            this.ProcessOutput()
        } else {
            ; Toggle between "..." and ".." for the tooltip
            this.tooltipDots := (this.tooltipDots == "... ○") ? "... ◔" : (this.tooltipDots == "... ◔") ? "... ◑" : (this.tooltipDots == "... ◑") ? "... ◕" : "... ○"
            ToolTip("Running " this.functionName this.tooltipDots)
        }
    }

    ProcessOutput() {
        Sleep(20)  ; Wait for 100 ms
        this.modifiedContent := A_Clipboard
        Sleep(50)
        if (this.modifiedContent != "") {
        Send "^v"  ; Send paste command (Ctrl+V)
        Sleep(50)  ; Brief pause to ensure the paste command is processed
        Send "+{ENTER}"
        A_Clipboard := this.originalContent  ; Set clipboard back to original content
        if (soundEffects) {
            SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
        }

        } else {
            if (soundEffects) {
            SoundPlay A_WinDir "\Media\Windows Exclamation.wav"
            }
            MsgBox("Error: Unable to " . this.functionName . " the content.")
        }
    }
}
