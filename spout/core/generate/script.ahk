#Requires AutoHotkey v2.0
global SoundEffects


SpoutGenerate(example := "") {
    ; Create GUI
    global SpoutGui
    global processHandle := 0
    global cancelled := false
    resetGui()
    Sleep(50)
    colorScheme := GetCurrentColorScheme()
    SpoutGui := Gui("+ToolWindow", "Spout Generate")
    SpoutGui.BackColor := colorScheme.Background
    SpoutGui.SetFont("s14")

    ; Add Spoutlets dropdown
    spoutlets := LoadSpoutlets()
    if (spoutlets.Length > 1) {
        SpoutGui.SetFont("s12", "Arial")
        SpoutGui.Add("Text", "x383 y14 w100 c" . colorScheme.Text, "Spoutlet:")
        preferredSpoutlet := IniRead(A_ScriptDir . "\config\settings.ini", "Generate", "PreferredSpoutlet", "default")
        spoutletDropdown := SpoutGui.Add("DropDownList", "x460 y10 w140 vSpoutlet c" . colorScheme.Text . " Background" . colorScheme.EditBackground, spoutlets)
        spoutletDropdown.Value := GetSpoutletIndex(preferredSpoutlet, spoutlets)
    }
    SpoutGui.SetFont("s14")  ; Reset font size

    ; Description input
    SpoutGui.Add("Text", "x10 y10 w300 c" . colorScheme.Text, "Description:")
    descriptionEdit := SpoutGui.Add("Edit", "x10 y40 w600 h100 vDescription c" . colorScheme.Text . " Background" . colorScheme.EditBackground)

    ; Example input
    SpoutGui.Add("Text", "x10 y150 w300 c" . colorScheme.Text, "Example(s):")
    exampleEdit := SpoutGui.Add("Edit", "x10 y180 w600 h60 vExample c" . colorScheme.Text . " Background" . colorScheme.EditBackground, example)

    ; Input fields for batch size and maximum items
    SpoutGui.Add("Text", "x10 y255 w150 c" . colorScheme.Text, "Items per batch:")
    batchSizeInput := SpoutGui.Add("DropDownList", "x160 y250 w80 vBatchSize c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16"])
    batchSizeInput.Choose("4")  ; Set default value to 4
    SpoutGui.Add("Text", "x270 y255 w140 c" . colorScheme.Text, "Maximum items:")
    maxItemsInput := SpoutGui.Add("Edit", "x420 y250 w60 vMaxItems c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "32")
    clearButton := SpoutGui.Add("Button", "x510 y248 w100 vClearButton c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Clear")
    clearButton.OnEvent("Click", (*) => clear())

    ; ListView for generated items
    listView := SpoutGui.Add("ListView", "x10 y295 w600 h255 vGeneratedItems c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ["Generated Items - (Doubleclick an item to copy)"])
    ; Add double-click event handler for the ListView
    listView.OnEvent("DoubleClick", OnListViewDoubleClick)



    ; Progress bar
    progressBar := SpoutGui.Add("Progress", "x10 y560 w600 h20 vProgressBar Range0-100 c" . colorScheme.Text . " Background" . colorScheme.EditBackground)

    ; Buttons
    generateButton := SpoutGui.Add("Button", "x10 y590 w140 h40 vGenerateButton c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Generate")
    generateButton.OnEvent("Click", GenerateItems)

    saveJsonlButton := SpoutGui.Add("Button", "x160 y590 w140 h40 vSaveJsonlButton c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Save(JSONL)")
    saveJsonlButton.OnEvent("Click", SaveAsJSONL)

    saveTxtButton := SpoutGui.Add("Button", "x310 y590 w140 h40 vSaveTxtButton c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Save(TXT)")
    saveTxtButton.OnEvent("Click", SaveAsTXT)

    cancelButton := SpoutGui.Add("Button", "x460 y590 w140 h40 vCancelButton c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Cancel")
    cancelButton.OnEvent("Click", (*) => cancel())

    SpoutGui.OnEvent("Escape", (*) => ExitApp())
    SpoutGui.OnEvent("Close", (*) => ExitApp())
    
    cancel(*) {
        if (processHandle) {
            cancelled := true
            ProcessClose(processHandle)
            SetTimer(UpdateProgressBars, 0) ; Turn off the progress bar update timer
            ; Reset progress bars
            progressBar.Value := 0
            MsgBox("Process cancelled.")
            processHandle := 0

        } else {
            SaveGuiPosition(SpoutGui.Hwnd)
            SpoutGui.Destroy()
        }
        
    }


    ExitApp(*) {
        SaveGuiPosition(SpoutGui.Hwnd)
        cancel()
        
        SpoutGui.Destroy()
    }

    clear(*) {
    if (processHandle) {
        cancelled := true
        ProcessClose(processHandle)
        SetTimer(UpdateProgressBars, 0) ; Turn off the progress bar update timer
        ; Reset progress bars
        progressBar.Value := 0
        processHandle := 0

    } 
    ; Clear the ListView
    SpoutGui["GeneratedItems"].Delete()

    ; Reset the progress bar
    progressBar.Value := 0

    ; Clear the duplicates array and list
    duplicates := []
    duplicatesList := ""

    ; Update the first item in the listview with the count of generated items
    SpoutGui["GeneratedItems"].ModifyCol(1, "Text", "Generated Items - 0/" . SpoutGui["MaxItems"].Value)

    ; Re-enable the generate button
    SpoutGui["GenerateButton"].Enabled := true
    SpoutGui["GenerateButton"].Text := "Generate"

    }

    
    OnListViewDoubleClick(LV, RowNumber) {
        if (RowNumber > 0) {
            selectedItem := LV.GetText(RowNumber)
            A_Clipboard := selectedItem
            ToolTip("Copied to clipboard: " . selectedItem)
            SetTimer () => ToolTip(), -1000  ; Hide tooltip after 1 second
        }
    }


    pos := GetGuiPosition()
    if (pos.x = "center") {
        SpoutGui.Show("w620")
    } else {
        SpoutGui.Show("x" pos.x " y" pos.y " w620")
    }

    descriptionEdit.Focus()
    maxItems := SpoutGui["MaxItems"].Value
    ; Function to generate items
    GenerateItems(*) {

        ; Check if the number of generated items is equal to or higher than the maximum items value
        if (SpoutGui["GeneratedItems"].GetCount() >= Integer(SpoutGui["MaxItems"].Value)) {
            MsgBox("The number of generated items has reached or exceeded the maximum items value. Please increase the 'Maximum items' value to generate more items.")
            return
        }

        originalClipboard := A_Clipboard
        description := SpoutGui["Description"].Value
        example := SpoutGui["Example"].Value
        batchSize := SpoutGui["BatchSize"].Value
        duplicates := []
        duplicatesList := ""
  
        prevGen := ""
        count := SpoutGui["GeneratedItems"].GetCount()
        Loop count
        {
            prevGen .= SpoutGui["GeneratedItems"].GetText(A_Index) . "`n"
        }
        prevGen := RTrim(prevGen, "`n")  ; Remove the trailing newline

        if (description = "" && example = "") {
            MsgBox("Please provide a description or example(s)")
            return
            }

        SpoutGui["GenerateButton"].Text := "Generating..." 

        ; Disable generate button while processing
        SpoutGui["GenerateButton"].Enabled := false

        ; Initialize progress bars
        progressBar.Value := 0
         ; Set up a timer to update the progress bars
        SetTimer(UpdateProgressBars, 100)
        ; Calculate total items to generate
        maxItems := Integer(SpoutGui["MaxItems"].Value)
        totalItemsToGenerate := maxItems-count
        ; Adjust batchSize if it's greater than the remaining items to generate
        if (totalItemsToGenerate < batchSize) {
            batchSize := maxItems-count
        }
        

        ; Get selected spoutlet or default
        try {
            escapedSpoutlet := StrReplace(SpoutGui["Spoutlet"].Text, '"', '``"')
        } catch {
            escapedSpoutlet := "default"
        }

        ; Run spout_generate.py script with spoutlet parameter
        Run("pythonw.exe " A_LineFile "\..\spout_generate.py `"" . description . "`" `"" . example . "`" `"" . batchSize . "`" `"" . prevGen . "`" `"" . escapedSpoutlet . "`"", , "Hide", &processHandle)

        ; Set up a timer to check for process completion
        SetTimer(CheckProcessCompletion, 100)
        
        ; Function to check if the process has completed
        CheckProcessCompletion() {
            if (!ProcessExist(processHandle)) {
                SetTimer(, 0) ; Turn off the timer
                ProcessOutput()
            }
        }
        ; Function to process output and update ListView
        ProcessOutput() {
            Sleep(200)  ; Wait for 200 ms
            generatedItems := A_Clipboard  ; Get text from clipboard to a new variable
            A_Clipboard := originalClipboard  ; Return originalClipboard to clipboard
            ; Extract items from the JSON string
            ; Create an array with all existing items in the GeneratedItems list
            existingItems := []
            duplicates := []
            duplicatesList := ""
            Loop SpoutGui["GeneratedItems"].GetCount()
            {
                existingItems.Push(SpoutGui["GeneratedItems"].GetText(A_Index))
            }
            ; Remove code block formatting if present
           
            ; Remove code block formatting if present
            generatedItems := RegExReplace(generatedItems, "^```.*\n|\n```$")
            if (InStr(generatedItems, "generated_items", true)) {
                variantPattern := '"([^"]+)"'
                pos := 1
                firstItem := true
                while (pos := RegExMatch(generatedItems, variantPattern, &match, pos)) {
                    if (firstItem) {
                        firstItem := false
                    } else {
                        item := match[1]
                        if (!HasVal(existingItems, item)) {
                            SpoutGui["GeneratedItems"].Add("", item)
                            existingItems.Push(item)
                        } else {
                            duplicates.Push(item)
                        }
                    }
                    pos += StrLen(match[0])
                }
                ; Scroll to the bottom of the GeneratedItems list
                lastIndex := SpoutGui["GeneratedItems"].GetCount()
                if (lastIndex > 0) {
                    SpoutGui["GeneratedItems"].Modify(lastIndex, "Vis")
                    SpoutGui["GeneratedItems"].Modify(lastIndex, "Focus")
                    SpoutGui["GeneratedItems"].ModifyCol(1, "AutoHdr")
                }
                if (SpoutGui["GeneratedItems"].GetCount() == 0) {
                    MsgBox("No items found in the generated output.")
                }
                if (duplicates.Length > 0) {
                    for index, item in duplicates {
                        if (index > 1) {
                            duplicateList .= "`n"
                        }
                        duplicateList .= item
                    }
                    if (soundEffects) {
                        SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
                    }
                    MsgBox("The model is repeating itself, so it may have provided all known answers.`n`nDuplicates:`n" . duplicateList)
                }
                ; Update progress bars to show completion
                progressBar.Value := 100
                currentTotal := SpoutGui["GeneratedItems"].GetCount()
                if (currentTotal < maxItems && duplicates.Length == 0) {
                    tryAgain()
                } else {
                    SpoutGui["GenerateButton"].Enabled := true
                    ProcessClose(processHandle)
                    processHandle := 0
                    SpoutGui["GenerateButton"].Text := "Generate"
                    SetTimer(UpdateProgressBars, 0)
                    if (soundEffects) {
                        SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
                    }
                    progressBar.Value := 100
                }
            } else {
                if (cancelled) {
                    SpoutGui["GenerateButton"].Enabled := true
                    SpoutGui["GenerateButton"].Text := "Generate"
                    return
                }
                MsgBox("Invalid JSON format: " . generatedItems)
                if (soundEffects) {
                    SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
                }
                ; Update progress bars to show failure
                progressBar.Value := 0

            }
        ; Update the first item in the listview with the count of generated items
        currentItemCount := SpoutGui["GeneratedItems"].GetCount()
        maxItems := SpoutGui["MaxItems"].Value
        
        SpoutGui["GeneratedItems"].ModifyCol(1, "Text", "Generated Items - " . currentItemCount . "/" . maxItems)
        ; Re-enable generate button
        }

        
    }

    tryAgain() {
        progressBar.Value := 0
        SetTimer(UpdateProgressBars, 100)
        sleep(400)
        ; Call generate function again
        GenerateItems()
    }


    
        ; Function to update progress bars
        UpdateProgressBars() {
            
            ; Update current process progress bar

                try {
                    if (progressBar.Value < 50) {
                        progressBar.Value := Mod(progressBar.Value + 2, 100)  ; Faster progress below 50%
                        Sleep(100)  ; Shorter delay for faster progress
                    } else {
                        progressBar.Value := Mod(progressBar.Value + 1, 100) 
                        Sleep(200 + (progressBar.Value - 50) * 3)  ; Gradually increase delay
                    }
                } catch as err {
                    ; Handle the error silently
                }

        }

    ; Function to save as JSONL
    SaveAsJSONL(*) {
        saveFile := FileSelect("S16", A_Desktop . "\generated_items.jsonl", "Save Generated Items", "JSONL Files (*.jsonl)")
        if (saveFile != "") {
            fileContent := ""
            Loop SpoutGui["GeneratedItems"].GetCount() {
                item := SpoutGui["GeneratedItems"].GetText(A_Index)
                fileContent .= '{"item_' . A_Index . '": "' . StrReplace(item, '"', '\"') . '"}' . "`n"
            }
            FileAppend(fileContent, saveFile)
            MsgBox("Items saved successfully.")
        }
    }

    ; Function to save as TXT
    SaveAsTXT(*) {
        saveFile := FileSelect("S16", A_Desktop . "\generated_items.txt", "Save Generated Items", "Text Files (*.txt)")
        if (saveFile != "") {
            fileContent := ""
            Loop SpoutGui["GeneratedItems"].GetCount() {
                item := SpoutGui["GeneratedItems"].GetText(A_Index)
                fileContent .= item . "`n"
            }
            FileAppend(fileContent, saveFile)
            MsgBox("Items saved successfully.")
        }
    }

    ; Add these helper functions at the end of SpoutGenerate
    LoadSpoutlets() {
        spoutlets := ["default"]  ; Always start with default
        basePluginPath := A_ScriptDir . "\core\generate"
        
        ; Define plugin directories with precedence (local > pro > base)
        pluginDirs := [
            basePluginPath . "\generate_plugins",    ; base plugins
            basePluginPath . "\generate_pro",        ; pro plugins
            basePluginPath . "\generate_local"       ; local plugins
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



SpoutQuips(input := "a funny and constructive reply to: @clipboard", number := 6, spoutlet := "default")
{
    global SpoutGui, processHandle, isGenerating, soundEffects

    resetGui()
    Sleep(50)
    colorScheme := GetCurrentColorScheme()
    SpoutGui := Gui("+ToolWindow") 
    SpoutGui.Title := "Generated Items"
    SpoutGui.BackColor := colorScheme.Background
    SpoutGui.SetFont("s10")

    inputText := SpoutGui.Add("Text", "x10 y10 w380 vInputText c" . colorScheme.Text, 
                              SubStr(input, 1, 30) . (StrLen(input) > 30 ? "..." : "") . ": Generating...")
    progressBar := SpoutGui.Add("Progress", "x400 y10 w190 h20 vProgressBar Range0-100 c" . colorScheme.Text . " Background" . colorScheme.EditBackground)

    listView := SpoutGui.Add("ListView", "x10 y40 w580 h120 vGeneratedItems -Multi +Grid c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ["Generated Items"])
    listView.OnEvent("Click", OnListViewClick)
    listView.OnEvent("DoubleClick", OnListViewDoubleClick)

    editBox := SpoutGui.Add("Edit", "x10 y170 w580 h100 vEditBox c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Select an item from the list to view and edit.")
    
    regenerateButton := SpoutGui.Add("Button", "x10 y280 w140 h30 vRegenerateButton c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Try Again")
    regenerateButton.OnEvent("Click", (*) => RegenerateItems())
    regenerateButton.Visible := false

    copyButton := SpoutGui.Add("Button", "x460 y280 w130 h30 vCopyButton c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Copy")
    copyButton.OnEvent("Click", OnCopyButtonClick)
    copyButton.Enabled := false

    SpoutGui.Show("w600 h320")

    SpoutGui.OnEvent("Close", (*) => SpoutGui.Destroy())
    SpoutGui.OnEvent("Escape", (*) => SpoutGui.Destroy())

    processHandle := 0
    isGenerating := true
    originalClipboard := A_Clipboard
    SetTimer(UpdateProgressBar, 100)
    SetTimer(GenerateItems, -10)

    GenerateItems() {
        originalClipboard := A_Clipboard
        progressBar.Value := 0
        progressBar.Visible := true
        regenerateButton.Visible := false
        processedInput := ProcessInput(input)
        Run("pythonw.exe " A_LineFile "\..\spout_generate.py `"" . processedInput . "`" `"`" `"" . number . "`" `"`" `"" . spoutlet . "`"", , "Hide", &processHandle)
        SetTimer(CheckProcessCompletion, 100)
    }

    ProcessInput(input) {
    ; Replace @clipboard or @clip with the current clipboard content
    processedInput := RegExReplace(input, "i)@clip(board)?", A_Clipboard)
    return processedInput
    }

    RegenerateItems() {

        listView.Delete()
        isGenerating := true
        progressBar.Value := 0
        progressBar.Visible := true
        regenerateButton.Visible := false
        inputText.Value := input . ": Generating..."
        editBox.Value := "Select an item from the list to view and edit."
        copyButton.Enabled := false
        GenerateItems()
    }

    CheckProcessCompletion() {
        if (!ProcessExist(processHandle)) {
            SetTimer(, 0)
            ProcessOutput()
        }
    }

    ProcessOutput() {
        isGenerating := false
        inputText.Value := "Double-click an item to copy and close."
        progressBar.Visible := false
        regenerateButton.Visible := true

        generatedItems := A_Clipboard
        A_Clipboard := originalClipboard

        items := []
        variantPattern := '"([^"]+)"'
        pos := 1
        firstItem := true
        while (pos := RegExMatch(generatedItems, variantPattern, &match, pos)) {
            if (!firstItem) {
                items.Push(match[1])
            }
            firstItem := false
            pos += StrLen(match[0])
        }

        listView.Delete()
        for index, item in items {
            listView.Add("", item)
        }

        listView.ModifyCol(1, "AutoHdr")
        listView.ModifyCol(1, 560)

        if (items.Length > 0) {
            if (soundEffects) {
                SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
            }
        } else {
            if (soundEffects) {
                SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
            }
            MsgBox("Error: Unable to generate content.")
        }
    }

    UpdateProgressBar() {
        if (isGenerating) {
            try {
                if (progressBar.Value >= 100) {
                    progressBar.Value := 0
                } else {
                    progressBar.Value += 1
                }
            }
        }
    }

    OnListViewClick(LV, RowNumber) {
        if (RowNumber > 0) {
            selectedItem := LV.GetText(RowNumber)
            editBox.Value := selectedItem
            copyButton.Enabled := true
        }
    }

    OnListViewDoubleClick(LV, RowNumber) {
        if (RowNumber > 0) {
            selectedItem := LV.GetText(RowNumber)
            A_Clipboard := selectedItem
            if (soundEffects) {
                SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
            }
            SpoutGui.Destroy()
        }
    }

    OnCopyButtonClick(*) {
        A_Clipboard := editBox.Value
        if (soundEffects) {
            SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
        }
        SpoutGui.Destroy()
    }

    LoadSpoutlets() {
        spoutlets := ["default"]  ; Always start with default
        basePluginPath := A_ScriptDir . "\core\generate"
        
        ; Define plugin directories with precedence (local > pro > base)
        pluginDirs := [
            basePluginPath . "\generate_plugins",    ; base plugins
            basePluginPath . "\generate_pro",        ; pro plugins
            basePluginPath . "\generate_local"       ; local plugins
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

SpoutQuip(input := "a constructive response to @clipboard", spoutlet := "default") {
    originalClipboard := A_Clipboard
    processedInput := ProcessInput(input)
    A_Clipboard := processedInput
    Sleep(100)

    Run("pythonw.exe " A_LineFile "\..\spout_generate.py `"" . processedInput . "`" `"`" `"1`" `"`" `"" . spoutlet . "`"", , "Hide", &processHandle)

    tooltipDots := "... ○"  ; Initialize tooltipDots
    SetTimer(CheckProcessCompletion, 100)

    CheckProcessCompletion() {
        if (!ProcessExist(processHandle)) {
            SetTimer(, 0)
            ToolTip
            ProcessOutput()
        } else {
            tooltipDots := (tooltipDots == "... ○") ? "... ◔" : (tooltipDots == "... ◔") ? "... ◑" : (tooltipDots == "... ◑") ? "... ◕" : "... ○"
            ToolTip("Generating" tooltipDots)
        }
    }

    ProcessOutput() {
        Sleep(100)
        generatedContent := A_Clipboard
        if (generatedContent != "") {
            items := []
            variantPattern := '"([^"]+)"'
            pos := 1
            firstItem := true
            while (pos := RegExMatch(generatedContent, variantPattern, &match, pos)) {
                if (!firstItem) {
                    items.Push(match[1])
                }
                firstItem := false
                pos += StrLen(match[0])
            }
            if (items.Length > 0) {
                A_Clipboard := items[1]
                Send "^v"
                Sleep(50)
                if (soundEffects) {
                    SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
                }
            } else {
                if (soundEffects) {
                    SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
                }
                MsgBox("Error: Unable to generate content.")
            }
        } else {
            if (soundEffects) {
                SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
            }
            MsgBox("Error: Unable to generate content.")
        }
        A_Clipboard := originalClipboard
    }

    ProcessInput(input) {
        ; Replace @clipboard or @clip with the current clipboard content
        processedInput := RegExReplace(input, "i)@clip(board)?", originalClipboard)
        return processedInput
    }
}