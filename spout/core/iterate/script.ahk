#Requires AutoHotkey v2.0
global soundEffects

SpoutIterate() {
    global SpoutGui, processHandle := 0, isPaused := false
    static sourceFile := ""
    resetGui()
    Sleep(50)
    colorScheme := GetCurrentColorScheme()
    SpoutGui := Gui("+ToolWindow", "Spout Iterate")
    SpoutGui.BackColor := colorScheme.Background
    SpoutGui.SetFont("s14")

    ; Add Spoutlets dropdown in top right
    spoutlets := LoadSpoutlets()
    if (spoutlets.Length > 1) {
        SpoutGui.SetFont("s12", "Arial")
        SpoutGui.Add("Text", "x393 y14 w100 c" . colorScheme.Text, "Spoutlet:")
        preferredSpoutlet := IniRead(A_ScriptDir . "\config\settings.ini", "Iterate", "PreferredSpoutlet", "default")
        spoutletDropdown := SpoutGui.Add("DropDownList", "x460 y10 w140 vSpoutlet c" . colorScheme.Text . " Background" . colorScheme.EditBackground, spoutlets)
        spoutletDropdown.Value := GetSpoutletIndex(preferredSpoutlet, spoutlets)
    }
    SpoutGui.SetFont("s14")  ; Reset font size

    ; File selection row - adjusted positions
    SpoutGui.Add("Text", "x10 y10 w120 c" . colorScheme.Text, "Source File:")
    filePathEdit := SpoutGui.Add("Edit", "x125 y10 w180 vFilePath c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "")
    
    browseButton := SpoutGui.Add("Button", "x310 y8 w70 vBrowse c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Browse")
    browseButton.OnEvent("Click", BrowseFile)
    
    skipFirstLineCheckbox := SpoutGui.Add("Checkbox", "x420 y50 w130 vSkipFirstLine c" . colorScheme.Text, "Skip first line")
    skipFirstLineCheckbox.Value := false
    skipFirstLineCheckbox.OnEvent("Click", UpdatePreview)

    ; First line preview
    SpoutGui.Add("Text", "x10 y50 w300 c" . colorScheme.Text, "Preprocessed First Line:")
    firstLinePreview := SpoutGui.Add("Edit", "x10 y80 w590 vFirstLine c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "")
    firstLinePreview.Opt("+ReadOnly")

    ; Example input
    SpoutGui.Add("Text", "x10 y120 w300 c" . colorScheme.Text, "Example of Processed Line:")
    exampleEdit := SpoutGui.Add("Edit", "x10 y150 w590 h60 vExample c" . colorScheme.Text . " Background" . colorScheme.EditBackground, A_Clipboard)

    ; Description input
    SpoutGui.Add("Text", "x10 y220 w300 c" . colorScheme.Text, "Processing Description:")
    descriptionEdit := SpoutGui.Add("Edit", "x10 y250 w590 h60 vDescription c" . colorScheme.Text . " Background" . colorScheme.EditBackground)

    ; Lines per API call
    SpoutGui.Add("Text", "x10 y320 w200 c" . colorScheme.Text, "Batch Size:")
    linesPerCallDropdown := SpoutGui.Add("DropDownList", "x160 y315 w80 vLinesPerCall c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20"])
    linesPerCallDropdown.Choose("1")

    ; ListView for processed items
    listView := SpoutGui.Add("ListView", "x10 y350 w590 h200 vProcessedItems c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ["Original", "Processed"])

    ; Progress bar
    progressBar := SpoutGui.Add("Progress", "x10 y560 w590 h20 vProgressBar Range0-100 c" . colorScheme.Text . " Background" . colorScheme.EditBackground)

    ; Buttons
    startButton := SpoutGui.Add("Button", "x10 y590 w140 h40 vStartButton c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Start")
    startButton.OnEvent("Click", StartProcessing)

    pauseButton := SpoutGui.Add("Button", "x160 y590 w140 h40 vPauseButton c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Pause")
    pauseButton.OnEvent("Click", TogglePause)

    saveButton := SpoutGui.Add("Button", "x310 y590 w140 h40 vSaveButton c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Save Results")
    saveButton.OnEvent("Click", SaveResults)

    cancelButton := SpoutGui.Add("Button", "x460 y590 w140 h40 vCancelButton c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Cancel")
    cancelButton.OnEvent("Click", (*) => cancel())

    SpoutGui.OnEvent("Close", (*) => ExitApp())

    SpoutGui.OnEvent("Escape", (*) => ExitApp())


    ExitApp(*) {
        SaveGuiPosition(SpoutGui.Hwnd)
        cancel()
        SpoutGui.Destroy()
    }

    cancel(*) {
        if (processHandle) {
            isPaused := true
            ProcessClose(processHandle)
            progressBar.Value := 0
            MsgBox("Process cancelled.")
            processHandle := 0

        } else {
            SaveGuiPosition(SpoutGui.Hwnd)
            SpoutGui.Destroy()
        }
        
    }

    pos := GetGuiPosition()
    if (pos.x = "center") {
        SpoutGui.Show("w610")
    } else {
        SpoutGui.Show("x" pos.x " y" pos.y " w610")
    }

    filePathEdit.Focus()

    BrowseFile(*) {
        selectedFile := FileSelect("3", , "Source File", "Text Files (*.txt; *.jsonl; *.json; *.csv)")
        if (selectedFile != "") {
            SpoutGui["FilePath"].Value := selectedFile
            sourceFile := selectedFile
            
            ; Check if the file is CSV and set the checkbox accordingly
            SplitPath(selectedFile, , , &ext)
            if (ext = "csv") {
                SpoutGui["SkipFirstLine"].Value := true
            } else {
                SpoutGui["SkipFirstLine"].Value := false
            }
            
            UpdatePreview()
        }
    }

    UpdatePreview(*) {
        filePath := SpoutGui["FilePath"].Value
        if (filePath != "") {
            try {
                fileContent := FileRead(filePath, "UTF-8")
                lines := StrSplit(fileContent, "`n", "`r")
                
                if (SpoutGui["SkipFirstLine"].Value && lines.Length > 1) {
                    SpoutGui["FirstLine"].Value := lines[2]
                    SpoutGui["Example"].Value := lines[2]
                } else {
                    SpoutGui["FirstLine"].Value := lines[1]
                    SpoutGui["Example"].Value := lines[1]
                }
            } catch as err {
                MsgBox("Error reading file: " . err.Message)
            }
        }
    }

    StartProcessing(*) {
        filePath := SpoutGui["FilePath"].Value
        if (filePath == "") {
            MsgBox("Please select a file first.")
            return
        }

        firstLine := SpoutGui["FirstLine"].Value
        example := SpoutGui["Example"].Value
        description := SpoutGui["Description"].Value
        linesPerCall := SpoutGui["LinesPerCall"].Value
        
        if (description == "" && example == "") || (example == firstLine) {
            MsgBox("Please provide a description or an example of how to process the lines.")
            return
        }

        SpoutGui["StartButton"].Text := "Processing..."
        SpoutGui["StartButton"].Enabled := false

        ; Initialize progress bar
        SpoutGui["ProgressBar"].Value := 0
        SetTimer(UpdateProgressBar, 100)

        ; Read the file content
        try {
            fileContent := FileRead(filePath, "UTF-8")
            lines := StrSplit(fileContent, "`n", "`r")
            totalLines := lines.Length

            ; Skip first line if checkbox is checked
            if (SpoutGui["SkipFirstLine"].Value) {
                lines.RemoveAt(1)
                totalLines--
            }
        } catch as err {
            MsgBox("Error reading file: " . err.Message)
            return
        }

        processedLines := 0
        batchStart := 1

        ; Get selected spoutlet or default
        try {
            escapedSpoutlet := StrReplace(SpoutGui["Spoutlet"].Text, '"', '``"')
        } catch {
            escapedSpoutlet := "default"
        }

        ProcessBatch()

        ProcessBatch() {
            if (processedLines >= totalLines - 1 || isPaused) {
                FinishProcessing()
                return
            }

            batchEnd := Min(batchStart + Integer(linesPerCall) - 1, totalLines)
            batchLines := []
            Loop batchEnd - batchStart + 1 {
                batchLines.Push(lines[A_Index + batchStart - 1])
            }
            batchContent := ""
            for line in batchLines {
                batchContent .= line . "`n"
            }
            batchContent := RTrim(batchContent, "`n")

            ; Run SpoutIterate.py script with spoutlet parameter
            try {
                
                scriptPath := A_LineFile . "\..\spout_iterate.py"
                EscapeQuotes(str) {
                    return StrReplace(str, "`"", "\`"")
                }
                Run("pythonw.exe `"" . scriptPath . "`" `"" . EscapeQuotes(firstLine) . "`" `"" . EscapeQuotes(example) . "`" `"" . EscapeQuotes(description) . "`" `"" . linesPerCall . "`" `"" . EscapeQuotes(batchContent) . "`" `"" . escapedSpoutlet . "`"", , "Hide", &processHandle)
                ; Set up a timer to check for process completion only if the script runs successfully
                SetTimer(CheckProcessCompletion, 100)
            } catch as err {
                if (soundEffects) {
                    SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
                }
                MsgBox("Error running SpoutIterate.py script: " . err.Message)
                FinishProcessing()
            }
        }

        CheckProcessCompletion() {
            if (!ProcessExist(processHandle)) {
                SetTimer(, 0) ; Turn off the timer
                ProcessOutput()
            }
        }
        ProcessOutput() {
            Sleep(200)  ; Wait for 200 ms
            processedBatch := ExtractJsonArray(A_Clipboard)

            ; Update ListView with original and processed lines
            batchSize := Min(processedBatch.Length, SpoutGui["LinesPerCall"].Value)
            Loop batchSize {
                index := A_Index
                if (batchStart + index - 1 < lines.Length) {
                    originalLine := lines[batchStart + index - 1]
                    processedLine := processedBatch[index]
                    SpoutGui["ProcessedItems"].Add(, originalLine, processedLine)
                }
            }

            processedLines += batchSize
            batchStart += batchSize

            ; Update progress bar
            progress := (processedLines / lines.Length) * 100
            SpoutGui["ProgressBar"].Value := progress

            ; Process next batch or finish
            if (processedLines >= totalLines - 1 || isPaused) {
                FinishProcessing()
            } else {
                ProcessBatch()
            }
        }

        FinishProcessing() {
            if (soundEffects) {
                SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
            }
            SetTimer(UpdateProgressBar, 0)
            SpoutGui["StartButton"].Text := "Start"
            SpoutGui["StartButton"].Enabled := true

            if (isPaused) {
                MsgBox("Processing paused. Click 'Resume' to continue.")
            } else {
                MsgBox("File processing completed.")
            }
        }
    }
    ExtractJsonArray(jsonString) {
        result := []
        startPos := InStr(jsonString, "[")
        if (startPos > 0) {
            endPos := InStr(jsonString, "]", , startPos)
            if (endPos > 0) {
                arrayContent := SubStr(jsonString, startPos + 1, endPos - startPos - 1)
                if (SubStr(Trim(arrayContent), 1, 1) != '"') {
                    Loop Parse, arrayContent, ","
                    {
                        item := Trim(A_LoopField)
                        item := StrReplace(item, '\"', '"')  ; Convert escaped quotes back to normal
                        result.Push(item)
                    }
                } else {
                    pattern := '"((?:[^"\\]|\\.)*)"'
                    pos := 1
                    while (pos := RegExMatch(arrayContent, pattern, &match, pos)) {
                        unescapedItem := StrReplace(match[1], '\"', '"') 
                        result.Push(unescapedItem)
                        pos += match.Len
                    }
                }
            }
        }
        return result
    }

    UpdateProgressBar() {
        try {
            if (SpoutGui["ProgressBar"].Value < 100) {
                SpoutGui["ProgressBar"].Value += 1
            } else {
                SpoutGui["ProgressBar"].Value := 0
            }
        } catch {
            return
        }
    }

    TogglePause(*) {
        isPaused := !isPaused
        if (isPaused) {
            SpoutGui["PauseButton"].Text := "Resume"
        } else {
            SpoutGui["PauseButton"].Text := "Pause"
        }
        ; ... (implement pause/resume logic)
    }

    SaveResults(*) {
        ; Check if sourceFile is defined
        if (!IsSet(sourceFile) || sourceFile == "") {
            ; If sourceFile is not defined, use a default path
            defaultSavePath := A_Desktop . "\processed_results.txt"
        } else {
            ; Get the source file name and path
            SplitPath(sourceFile, &sourceName, &sourceDir, &sourceExt, &sourceNameNoExt)
            
            ; Create the new file name with "(processed)" added
            newFileName := sourceNameNoExt . "(processed)." . sourceExt
            
            ; Set the default save path to the same directory as the source file
            defaultSavePath := sourceDir . "\" . newFileName
        }
        
        saveFile := FileSelect("S16", defaultSavePath, "Save Processed Results", "Data Files (*.txt, *.csv, *.jsonl, *.json)")
        if (saveFile != "") {
            fileContent := ""
            
            ; Add the first line if 'Skip first line' is checked
            if (SpoutGui["SkipFirstLine"].Value) {
                try {
                    originalContent := FileRead(sourceFile, "UTF-8")
                    originalLines := StrSplit(originalContent, "`n", "`r")
                    if (originalLines.Length > 0) {
                        fileContent .= originalLines[1] . "`n"
                    }
                } catch as err {
                    MsgBox("Error reading original file: " . err.Message)
                }
            }
            
            ; Add processed items
            Loop SpoutGui["ProcessedItems"].GetCount() {
                processedItem := SpoutGui["ProcessedItems"].GetText(A_Index, 2)
                fileContent .= processedItem . "`n"
            }
            
            FileAppend(fileContent, saveFile)
            MsgBox("Results saved successfully.")
        }
    }

    ; Add these helper functions at the end
    LoadSpoutlets() {
        spoutlets := ["default"]  ; Always start with default
        basePluginPath := A_ScriptDir . "\core\iterate"
        
        ; Define plugin directories with precedence (local > pro > base)
        pluginDirs := [
            basePluginPath . "\iterate_plugins",    ; base plugins
            basePluginPath . "\iterate_pro",        ; pro plugins
            basePluginPath . "\iterate_local"       ; local plugins
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