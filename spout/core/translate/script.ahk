#Requires AutoHotkey v2.0


global soundEffects

class SpoutTranslator {
    processHandle := 0
    currentFileDir := SubStr(A_LineFile, 1, InStr(A_LineFile, "\", , -1) - 1)
    optionsFile := "specification"
    __New(specification := "", gui := true) {
        this.specification := specification
        this.gui := gui
    }

    Translate(specification := "") {
        this.specification := specification
        if (specification != "" && !this.gui) {
            this.RunTranslation(specification)
            return
        } else if (this.gui) {
            this.ShowGui()
        }
    }

    ShowGui() {
        global SpoutGui
        resetGui()
        Sleep(50)
        colorScheme := GetCurrentColorScheme()
        SpoutGui := Gui("+ToolWindow", "Spout Translate")
        SpoutGui.BackColor := colorScheme.Background
        ; Clipboard content preview
        SpoutGui.SetFont("s16", "Arial")
        SpoutGui.Add("Text", "w600 c" . colorScheme.Text, "Original Text:")
        SpoutGui.SetFont("norm s15", "Arial")
        clipboardPreview := SpoutGui.Add("Edit", "x10 y+3 w630 h130 vClipboardPreview c" . colorScheme.Text . " Background" . colorScheme.EditBackground, A_Clipboard)
        ; Specification dropdowns and progress bar
        SpoutGui.SetFont("s16", "Arial")
        SpoutGui.Add("Text", "x10 y+10 w17 c" . colorScheme.Text, "Spec:")
        SpoutGui.SetFont("norm s15", "Arial")
        ; File selection dropdown
        optionsFiles := this.GetOptionsFiles()
        optionsFiles.InsertAt(1, "Select options file")
        fileDropdown := SpoutGui.Add("DropDownList", "x+10 yp w210 vOptionsFile c" . colorScheme.Text . " Background" . colorScheme.EditBackground, optionsFiles)
        fileDropdown.Value := 1
        fileDropdown.OnEvent("Change", (*) => this.HandleFileChange())

        ; Specification dropdown
        specOptions := this.LoadOptionsFromFile("default")
        specDropdown := SpoutGui.Add("DropDownList", "x+10 yp w340 vSpecification c" . colorScheme.Text . " Background" . colorScheme.EditBackground, specOptions)
        specDropdown.Value := 1
        specDropdown.OnEvent("Change", (*) => this.HandleSpecificationChange())

        if (this.specification != "") {
            index := 0
            for i, value in specOptions {
                if (value == this.specification) {
                    index := i
                    break
                }
            }
            if (index > 0) {
                specDropdown.Value := index
            } else {
                this.AddNewSpecification(this.specification)
                this.RefreshSpecificationDropdown()
                specDropdown.Value := specOptions.Length
            }
        }
        ; Output text view box
        SpoutGui.SetFont("s16", "Arial")
        SpoutGui.Add("Text", "x10 y+10 w200 c" . colorScheme.Text, "Translation Output:")
        SpoutGui.Add("Progress", "x+70 yp w330 h24 vProgressBar Range0-100 c" . colorScheme.Text . " Background" . colorScheme.EditBackground)
        SpoutGui.SetFont("norm s15", "Arial")
        outputEdit := SpoutGui.Add("Edit", "x10 y+5 w630 h180 vOutputEdit c" . colorScheme.Text . " Background" . colorScheme.EditBackground)

        ; Buttons
        buttonsRow := SpoutGui.Add("Text", "x10 y+10 w600 h0")
        translateButton := SpoutGui.Add("Button", "w140 yp+5 vTranslateButton", "Translate")
        translateButton.OnEvent("Click", (*) => this.RunTranslation(SpoutGui["Specification"].Text))

        copyOriginalButton := SpoutGui.Add("Button", "w140 x+10 vCopyOriginalButton", "Copy Original")
        copyOriginalButton.OnEvent("Click", (*) => this.CopyOriginal())

        copyTranslationButton := SpoutGui.Add("Button", "w180 x+10 vCopyTranslationButton", "Copy Translation")
        copyTranslationButton.OnEvent("Click", (*) => this.CopyAndClose())

        cancelButton := SpoutGui.Add("Button", "w140 x+10 vCancelButton", "Cancel")
        cancelButton.OnEvent("Click", (*) => this.ExitApp())

        SpoutGui.OnEvent("Close", (*) => this.ExitApp())
        SpoutGui.OnEvent("Escape", (*) => this.ExitApp())

        ; Add Spoutlets dropdown
        spoutlets := this.LoadSpoutlets()
        if (spoutlets.Length > 1) {
            SpoutGui.SetFont("s12", "Arial")
            SpoutGui.Add("Text", "x423 y14 w100 c" . colorScheme.Text, "Spoutlet:")
            preferredSpoutlet := IniRead(A_ScriptDir . "\config\settings.ini", "Translate", "PreferredSpoutlet", "default")
            spoutletDropdown := SpoutGui.Add("DropDownList", "x500 y10 w140 vSpoutlet c" . colorScheme.Text . " Background" . colorScheme.EditBackground, spoutlets)
            spoutletDropdown.Value := this.GetSpoutletIndex(preferredSpoutlet, spoutlets)
        }
        SpoutGui.SetFont("s16", "Arial")  ; Reset font size

        
        pos := GetGuiPosition()
        if (pos.x = "center") {
            SpoutGui.Show("w650")
        } else {
            SpoutGui.Show("x" pos.x " y" pos.y " w650")
        }


    }

    ExitApp(*) {
        SaveGuiPosition(SpoutGui.Hwnd)
        SpoutGui.Destroy()
    }

    HandleSpecificationChange() {
        if (SpoutGui["Specification"].Text == "Add New Specification...") {
            newSpec := InputBox("Enter a new translation specification here:", "Add Custom Specification", "W300 H100")
            if (newSpec.Result == "OK" && newSpec.Value != "") {
                this.specification := newSpec.Value
                this.AddNewSpecification(newSpec.Value)
                this.RefreshSpecificationDropdown()
            } else {
                SpoutGui["Specification"].Value := 1
            }
        } else {
            this.specification := SpoutGui["Specification"].Text
        }
    }

    AddNewSpecification(newSpec) {
        optionsFile := this.GetOptionsFile()
        FileAppend("`n" . newSpec, optionsFile)
    }

    RefreshSpecificationDropdown() {
        specOptions := this.LoadOptionsFromFile()
        specOptions.Push("Add New Specification...")
        SpoutGui["Specification"].Delete()
        SpoutGui["Specification"].Add(specOptions)
        SpoutGui["Specification"].Choose(specOptions.Length - 1)  ; Select the newly added option
    }

    GetOptionsFiles() {
        optionsFiles := []
        optionsPath := this.currentFileDir . "\Options"

        ; Create Options directory if it doesn't exist
        if (!DirExist(optionsPath)) {
            DirCreate(optionsPath)
        }

        ; Create Default.txt if no txt files exist
        if (!FileExist(optionsPath . "\*.txt")) {
            defaultContent := "formal english`ncasual english`nlegalese`nmore emojis`npig latin`nmarkdown checklist`nShakespearean style`npoem format`nlaymen terms`ntext message abbreviations`ninternet slang`ncorporate jargon`ntechnical terminology`nsarcasm"
            FileAppend(defaultContent, optionsPath . "\Default.txt")
        }

        ; Recursively scan for txt files in Options directory and subdirectories
        ScanForTxtFiles(dir, &files) {
            Loop Files, dir . "\*.txt" {
                optionFile := StrReplace(A_LoopFilePath, optionsPath . "\", "")  ; Get relative path
                optionFile := StrReplace(optionFile, ".txt", "")  ; Remove .txt extension
                files.Push(optionFile)
            }
            Loop Files, dir . "\*.*", "D" {
                ScanForTxtFiles(A_LoopFilePath, &files)
            }
        }

        ScanForTxtFiles(optionsPath, &optionsFiles)

        ; Ensure Default is first in the list if it exists
        if (HasVal(optionsFiles, "Default")) {
            defaultIndex := 0
            for index, value in optionsFiles {
                if (value = "Default") {
                    defaultIndex := index
                    break
                }
            }
            optionsFiles.RemoveAt(defaultIndex)
            optionsFiles.InsertAt(1, "Default")
        }

        return optionsFiles
    }

    GetOptionsFile() {
        return this.currentFileDir . "\Options\" . this.optionsFile . ".txt"
    }
        

    HandleFileChange(*) {
        if (SpoutGui["OptionsFile"].Text != "Select options file") {
            this.optionsFile := SpoutGui["OptionsFile"].Text
            specOptions := this.LoadOptionsFromFile(this.optionsFile)
            specOptions.Push("Add New Specification...")
            SpoutGui["Specification"].Delete()
            SpoutGui["Specification"].Add(specOptions)
            SpoutGui["Specification"].Value := 1
        }
    }

    LoadOptionsFromFile(optionsFile := "") {
        if (optionsFile == "") {
            optionsFile := "Default"
        }
        optionsFilePath := this.currentFileDir . "\Options\" . optionsFile . ".txt"
        if (FileExist(optionsFilePath)) {
            fileContent := FileRead(optionsFilePath)
            options := StrSplit(fileContent, "`n", "`r")
            ; Remove empty lines
            filteredOptions := []
            for option in options {
                if (Trim(option) != "") {
                    filteredOptions.Push(Trim(option))
                }
            }
            return filteredOptions
        } else {
            MsgBox("Options file not found: " . optionsFilePath)
            return ["Translate to Spanish", "Translate to French"] ; Default options
        }
    }

    RunTranslation(specification) {
        if (specification == "Select a translation specification") {
            MsgBox("Please select a valid translation specification.")
            return
        }
        this.tooltipDots := "... \"
        if (!this.gui && SpoutGui) {
            SpoutGui.Destroy()
        }

        if (this.gui) {
            inputText := SpoutGui["ClipboardPreview"].Value
            SpoutGui["ProgressBar"].Value := 0
            SpoutGui["ProgressBar"].Visible := true
        }

        try {
            scriptPath := this.currentFileDir . "\spout_translate.py"
            
            ; Get selected spoutlet or default - matching the search script's approach
            try {
                escapedSpoutlet := StrReplace(SpoutGui["Spoutlet"].Text, '"', '``"')
            } catch {
                escapedSpoutlet := "default"
            }

            Run("pythonw.exe `"" . scriptPath . "`" `"" . this.EscapeQuotes(specification) . "`" `"" . escapedSpoutlet . "`" `"" . this.EscapeQuotes(inputText) . "`"", , "Hide", &processHandle)
            this.processHandle := processHandle

            Sleep(50)
            SetTimer(() => this.CheckProcessCompletion(), 100)
        } catch as err {
            ToolTip()
            if (soundEffects) {
                SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
            }
            MsgBox("Error running spout_translate.py script: " . err.Message)
        }
    }

    CheckProcessCompletion() {
        if (!ProcessExist(this.processHandle)) {
            try {
                SetTimer(, 0) ; Turn off the timer
                ToolTip()
                this.ProcessOutput()
            } catch {
                ; Handle any exceptions that occur
            }
        } else {
           
            try {
                if (this.gui) {
                    progress := SpoutGui["ProgressBar"].Value
                    SpoutGui["ProgressBar"].Value := (progress < 90) ? progress + 2 : 90
                } else {
                    this.tooltipDots := (this.tooltipDots == "... ○") ? "... ◔" : (this.tooltipDots == "... ◔") ? "... ◑" : (this.tooltipDots == "... ◑") ? "... ◕" : "... ○"
                    specDisplay := (StrLen(this.specification) > 9) ? SubStr(this.specification, 1, 7) : this.specification
                    ToolTip("Translating to " . specDisplay . this.tooltipDots)
                }
            } catch {
                ; Handle any exceptions that occur
            }
        }
    }

    ProcessOutput() {
        Sleep(50)  ; Wait for 50 ms
        translatedText := A_Clipboard
        if (translatedText != "") {
            if (this.gui && SpoutGui) {
                SpoutGui["OutputEdit"].Value := translatedText
                SpoutGui["ProgressBar"].Value := 100
            } else {
                Send("^v")  ; Paste the result if GUI is not open
                ;Send("+{Enter}")
            }
            if (soundEffects) {
                SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
            }
        } else {
            if (soundEffects) { 
                SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
            }
            MsgBox("Error: Unable to translate the content.")
        }
        if (this.gui) {
            SetTimer(() => SpoutGui["ProgressBar"].Visible := false, -1000)
        }
    }

    EscapeQuotes(str) {
        return StrReplace(str, "`"", "\`"")
    }

    CopyAndClose() {
        outputText := SpoutGui["OutputEdit"].Value
        A_Clipboard := outputText
        SpoutGui.Destroy()
    }

    CopyOriginal() {
        A_Clipboard := SpoutGui["ClipboardPreview"].Value
        SpoutGui.Destroy()
    }

    LoadSpoutlets() {
        spoutlets := ["default"]  ; Always start with default
        basePluginPath := this.currentFileDir
        
        ; Define plugin directories with precedence (local > pro > base)
        pluginDirs := [
            basePluginPath . "\translate_plugins",    ; base plugins
            basePluginPath . "\translate_pro",        ; pro plugins
            basePluginPath . "\translate_local"       ; local plugins
        ]
        
        ; Track seen spoutlet names to handle precedence
        seenSpoutlets := Map()
        
        ; Check each plugin directory in reverse order (for precedence)
        Loop 3 {
            currentDir := pluginDirs[4 - A_Index]  ; Start from end of array for correct precedence
            if (DirExist(currentDir)) {
                loop files currentDir . "\*.*", "D" {
                    if (A_LoopFileName != "default" && !seenSpoutlets.Has(A_LoopFileName)) {
                        spoutlets.Push(A_LoopFileName)
                        seenSpoutlets[A_LoopFileName] := true
                    }
                }
            }
        }
        return spoutlets
    }

    GetSpoutletIndex(spoutletName, spoutlets) {
        for index, name in spoutlets {
            if (name = spoutletName)
                return index
        }
        return 1  ; Return first index (default) if not found
    }
}

; Usage example:
; translator := SpoutTranslate()
; translator.Translate()
; Or: translator.Translate("Translate to Spanish")

SpoutTranslate(*) { 
    SpoutTrans := SpoutTranslator()
    SpoutTrans.Translate()
}


class SpoutTranslatorNoGUI {
    __New(specification := "", spoutlet := "default") {
        this.specification := specification
        this.spoutlet := spoutlet
        this.process := 0
    }

    Translate(specification := "") {
        if (specification != "") {
            this.specification := specification
        }
        
        if (this.specification == "") {
            MsgBox("Error: No translation specification provided.")
            return
        }

        originalText := A_Clipboard
        Sleep(50)
        Send("^c")
        Sleep(50)

        if (StrLen(A_Clipboard) <= 1) {
            A_Clipboard := originalText
        }

        Sleep(50)
        this.tooltipDots := "... \"
        ToolTip("Translating" . this.tooltipDots)

        try {
            scriptPath := A_LineFile "\..\spout_translate.py"
            Run("pythonw.exe `"" . scriptPath . "`" `"" . this.EscapeQuotes(this.specification) . "`" `"" . this.EscapeQuotes(this.spoutlet) . "`" `"" . A_Clipboard . "`"", , "Hide", &processHandle)
            this.process := processHandle

            SetTimer((*) => this.CheckProcessCompletion(), 100)
        } catch as err {
            ToolTip()
            if (soundEffects) {
                SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
            }
            MsgBox("Error running spout_translate.py script: " . err.Message)
        }
    }

    CheckProcessCompletion() {
        if (!ProcessExist(this.process)) {
            SetTimer(, 0) ; Turn off the timer
            ToolTip()
            this.ProcessOutput()
        } else {
            this.tooltipDots := (this.tooltipDots == "... ○") ? "... ◔" : (this.tooltipDots == "... ◔") ? "... ◑" : (this.tooltipDots == "... ◑") ? "... ◕" : "... ○"
            specDisplay := (StrLen(this.specification) > 9) ? SubStr(this.specification, 1, 7) . "..." : this.specification
            ToolTip("Translating to " . specDisplay . this.tooltipDots)
        }
    }

    ProcessOutput() {
        Sleep(50)
        translatedText := A_Clipboard
        if (translatedText != "") {
            Send("^v")  ; Paste the result
            Send("{Enter}")
            if (soundEffects) {
                SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
            }
        } else {
            if (soundEffects) { 
                SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
            }
            MsgBox("Error: Unable to translate the content.")
        }
    }

    EscapeQuotes(str) {
        return StrReplace(str, "`"", "\`"")
    }
}

SpoutCast(specification := "") {
    translator := SpoutTranslatorNoGUI(specification)
    translator.Translate()
}

SpoutCode(specification := "python") {
    translator := SpoutTranslatorNoGUI(specification, "code")
    translator.Translate()
}
