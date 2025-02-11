#Requires AutoHotkey v2.0
global soundEffects

SpoutMutate() {
    ; Create GUI
    global SpoutGui
    resetGui()
    Sleep(50)
    colorScheme := GetCurrentColorScheme()
    SpoutGui := Gui("+ToolWindow", "Spout Mutate")
    checkedVariants := [] 
    SpoutGui.SetFont("s14")  ; Set default font size to 12
    SpoutGui.BackColor := colorScheme.Background
    SpoutGui.Add("Text", "x10 y10 w300 c" . colorScheme.Text, "Context for Mutations:")

    ; Add Spoutlets dropdown
    spoutlets := LoadSpoutlets()
    if (spoutlets.Length > 1) {
        SpoutGui.SetFont("s12", "Arial")
        SpoutGui.Add("Text", "x383 y14 w100 c" . colorScheme.Text, "Spoutlet:")
        preferredSpoutlet := IniRead(A_ScriptDir . "\config\settings.ini", "Mutate", "PreferredSpoutlet", "default")
        spoutletDropdown := SpoutGui.Add("DropDownList", "x460 y10 w140 vSpoutlet c" . colorScheme.Text . " Background" . colorScheme.EditBackground, spoutlets)
        spoutletDropdown.Value := GetSpoutletIndex(preferredSpoutlet, spoutlets)
    }
    SpoutGui.SetFont("s14")  ; Reset font size

    variants := []  ; Create an empty array for the new substring variants
    selectedText := ""
    ; Get clipboard content
    clipboardContent := A_Clipboard
    originalString := clipboardContent
    ; Add Edit control to display and allow selection of clipboard content
    textEdit := SpoutGui.Add("Edit", "x10 y40 w600 h150 vOriginalText c" . colorScheme.Text . " Background" . colorScheme.EditBackground, originalString)

   

    ; Add input for number of variants and substring selection on the same line
    SpoutGui.Add("Text", "x30 y205 w220 c" . colorScheme.Text, "Target Substring:")
    substringInput := SpoutGui.Add("Edit", "x210 y200 w380 vSubstring c" . colorScheme.Text . " Background" . colorScheme.EditBackground)
    substringInput.Value := "*"
    SpoutGui.Add("Text", "x30 y253 w120 h50 c" . colorScheme.Text, "Variants:")
    variantOptions := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16"]
    variantInput := SpoutGui.Add("DropDownList", "x110 y250 w50 vNumVariants c" . colorScheme.Text . " Background" . colorScheme.EditBackground, variantOptions)
    variantInput.Choose(3)  ; Set default selection to 3

    SpoutGui.Add("Text", "x285 y253 w220 h50 c" . colorScheme.Text, "Mutagen Strength (1-5) :")
    mutationLevels := ["1", "2", "3", "4", "5"]
    mutationLevelInput := SpoutGui.Add("DropDownList", "x500 y250 w90 vMutationLevel c" . colorScheme.Text . " Background" . colorScheme.EditBackground, mutationLevels)
    mutationLevelInput.Choose(3)  ; Set default selection to "Medium"

    ; Add buttons at the bottom
    buttonWidth := 140  ; Adjusted width to fit all 4 buttons
    buttonHeight := 40
    buttonY := 530
    
    mutateButton := SpoutGui.Add("Button", "x10 y" . buttonY . " w" . buttonWidth . " h" . buttonHeight . " c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Mutate")
    mutateButton.OnEvent("Click", MutateSelectedText)
    
    copyListButton := SpoutGui.Add("Button", "x+" . 10 . " y" . buttonY . " w" . buttonWidth . " h" . buttonHeight . " c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Copy List")
    copyListButton.OnEvent("Click", CopyList)
    copyListButton.Enabled := false

    combinedButton := SpoutGui.Add("Button", "x+" . 10 . " y" . buttonY . " w" . buttonWidth . " h" . buttonHeight . " vCombinedButton c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Copy Combined")
    combinedButton.OnEvent("Click", CopyCombined)
    combinedButton.Enabled := false

    cancelButton := SpoutGui.Add("Button", "x+" . 10 . " y" . buttonY . " w" . buttonWidth . " h" . buttonHeight . " c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Cancel")
    cancelButton.OnEvent("Click", (*) => ExitApp())

    ; Add hotkey to close the GUI when Escape is pressed
    SpoutGui.OnEvent("Escape", (*) => ExitApp())

    ; Add ListView for displaying results
    resultListView := SpoutGui.Add("ListView", "x10 y300 w600 h190 vResultList c" . colorScheme.Text . " Background" . colorScheme.EditBackground, [ "Variant", "Full Context"])
    resultListView.Opt("+Grid +Report +Checked")  ; Enable grid lines, report view, and checkboxes
    
    ; Add scrollbar to ListView
    resultListView.Opt("+VScroll")  ; Enable vertical scrollbar
    
    ; Adjust the size of the ListView columns

    resultListView.ModifyCol(1, 170)  ; Full Context column
    resultListView.ModifyCol(2,500)  ; Checkbox column
    
    ; Make the columns resizable
    resultListView.Opt("+LV0x10000")  ; Enable column resizing
    


    ; Add progress bar
    progressBar := SpoutGui.Add("Progress", "x10 y500 w600 h20 vProgressBar Range0-100 c" . colorScheme.Text . " Background" . colorScheme.EditBackground, 0)

    ; Add escape key handler to destroy the window
    SpoutGui.OnEvent("Escape", (*) => ExitApp())
    SpoutGui.OnEvent("Close", (*) => ExitApp())
    ; Show the GUI
    pos := GetGuiPosition()
    if (pos.x = "center") {
        SpoutGui.Show("w620")
    } else {
        SpoutGui.Show("x" pos.x " y" pos.y " w620")
    }
    ; Focus the text edit control
    textEdit.Focus()

    ; Variable to track progress
    progress := 0

    CopyList(*) {
    listContent := ""
    Loop resultListView.GetCount()
    {
        checkedIndex := resultListView.GetNext(A_Index - 1, "Checked")
        if (checkedIndex)
        {
            fullContext := resultListView.GetText(checkedIndex, 2)
            if (!InStr(listContent, fullContext)) {
                listContent .= fullContext . "`n`n"
            }
        }
    }

    if (listContent != "")
    {
        A_Clipboard := RTrim(listContent, "`n")  ; Remove the trailing newline
        ToolTip("List of variants in full context copied to clipboard.")
        SetTimer () => ToolTip(), -3000  ; Remove the tooltip after 3 seconds
    }
    else
    {
        MsgBox("No variants selected. Please check at least one variant.")
    }
    }

    ExitApp(*) {
        SaveGuiPosition(SpoutGui.Hwnd)
        SpoutGui.Destroy()
        SpoutGui := ""
    }


    ; Function to handle mutation
    MutateSelectedText(*) {
        checkedVariants := []
        variants := []
        progress := 0
        originalString := SpoutGui["OriginalText"].Text
        ; Escape any quotation marks in the original string
        escapedOriginalString := StrReplace(originalString, '"', '`'`'')
        
        ; Copy the escaped original string to the clipboard
        A_Clipboard := EscapedOriginalString

        selectedText := StrReplace(SpoutGui["Substring"].Text, '"', '`'`'')
        mutationLevelStr := String(mutationLevelInput.Value)

        ; Special case: if selectedText is "*", use the entire original string
        if (selectedText = "*") {
            selectedText := escapedOriginalString
        }
        ; Check if selected text is in the original string
        if (!(RegExMatch(escapedOriginalString, selectedText))) {
            MsgBox("Error: The selected text is not part of the original clipboard content. Please select text from the provided content.")
            return
        }
        if (selectedText != "") {
            ; Start progress bar animation
            SetTimer(UpdateProgressBar, 50)

            ; Get selected spoutlet or default
            try {
                escapedSpoutlet := StrReplace(SpoutGui["Spoutlet"].Text, '"', '``"')
            } catch {
                escapedSpoutlet := "default"
            }

            ; Run Python script with updated parameters including spoutlet
            scriptPath := A_LineFile . "\..\spout_mutate.py"
            numVariantsStr := String(variantInput.Value)
            RunWait("pythonw.exe `"" . scriptPath . "`" `"" . numVariantsStr . "`" `"" . selectedText . "`" `"" . mutationLevelStr . "`" `"" . escapedOriginalString . "`" `"" . escapedSpoutlet . "`"", , "Hide", &OutputVar)

            try {
                ; Stop progress bar animation
                SetTimer(UpdateProgressBar, 0)
                ; Reset progress bar
                progressBar.Value := 0
            } catch {
                ; Handle the case where the GUI is closed while this is still running
                ; We can simply return or log an error if needed
                return
            }

            if (OutputVar != "") {
                resultstring := A_Clipboard  ; Get the updated clipboard content
                progressBar.Value := 0
                A_Clipboard := clipboardContent
                copyListButton.Enabled := true
                ; Split the resultstring into individual variants
                try {
                    ; Extract URLs from the sitesArray string
                    variantPattern := '"([^"]+)"'
                    
                    pos := 1
                    while (pos := RegExMatch(resultstring, variantPattern, &match, pos)) {
                        variants.Push(match[1])
                        pos += StrLen(match[0])
                    }
                    ; Remove the first two values from variants
                    if (variants.Length >= 3) {
                        variants.RemoveAt(1)
                        variants.RemoveAt(1)
                        variants.RemoveAt(1)
                    } 

                    if (variants.Length = 0) {
                        if (soundEffects) {
                            SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
                        }
                        MsgBox("No variants found. Please try again.")
                        return
                    }
                    if (soundEffects) {
                        SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
                    }
                } catch Error as err {
                    if (soundEffects) {
                        SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
                    }
                    MsgBox("Error processing results: " . err.Message)
                    return
                }
                ; Clear existing items in the ListView
                resultListView.Delete()
                
                ; Add each variant to the ListView, with the variant in the second column and the full sentence in the third
                for index, variant in variants {
                    if (variant != "") {
                        fixedVariant := StrReplace(variant, '`'`'','"')
                        newContent := StrReplace(escapedOriginalString, selectedText, fixedVariant)
                        resultListView.Add("-Check", fixedVariant, newContent)
                    }
                }
                
                ; Add click event to copy content and update UI
                resultListView.OnEvent("DoubleClick", OnResultListViewDoubleClick)
                resultListView.OnEvent("ItemCheck", UpdateCheckItem)

                UpdateCheckItem(ctrl, item, Checked) {
                    ; Empty the checkedVariants list
                    if (Checked) {
                        checkedVariants.Push(ctrl.GetText(item, 1))
                    } else {
                        for index, variant in checkedVariants {
                            if (variant == ctrl.GetText(item, 1)) {
                                checkedVariants.RemoveAt(index)
                                break
                            }
                        }
                    }
                    UpdateCombinedButtonState()
                }



                UpdateCombinedButtonState(*) {
                    checkedCount := 0

                    Loop resultListView.GetCount() {
                        if (resultListView.GetNext(A_Index - 1, "Checked")) {
                            checkedCount++
                        }
                    }
                    combinedButton.Enabled := (checkedCount > 1)
                }

                OnResultListViewDoubleClick(ctrl, rowNumber) {
                    if (rowNumber > 0) {
                        selectedContent := ctrl.GetText(rowNumber, 2)  ; Get text from the third column
                        originalString := selectedContent
                        ; Clear the target substring edit text and selectedText
                        SpoutGui["Substring"].Value := ""
                        selectedText := ""
                        A_Clipboard := selectedContent
                        ToolTip("Copied to clipboard")
                        SetTimer(HideToolTip, -1000)  ; Hide tooltip after 1 second
                        SpoutGui["OriginalText"].Value := selectedContent
                    }
                }

                HideToolTip() {
                    ToolTip()
                }
                ; Adjust the column width to fit the content
                resultListView.ModifyCol(2, "AutoHdr")
                
                ; Enable the combined button if there are results
                combinedButton.Enabled := true
            } else {
                resultstring := A_Clipboard  ; Get the updated clipboard content
                MsgBox("Error: Failed to run the mutation script.`n`n" . resultstring)
                A_Clipboard := clipboardContent
            }
        } else {
            MsgBox("Please select some text to mutate.")
        }
    }


    
    
    CopyCombined(*)
    {
        if (checkedVariants.Length > 0) {
            combinedVariants := "{"
            for index, variant in checkedVariants {
                variantWithoutCommas := StrReplace(variant, ",", " ")
                if (!InStr(combinedVariants, variantWithoutCommas)) {
                    if (index > 1) {
                        combinedVariants .= ","
                    }
                    
                    combinedVariants .= variantWithoutCommas
                }
            }
            combinedVariants .= "}"

            ; Check if originalString is equal to the substring
            if (originalString = SpoutGui["Substring"].Value) {
                ; If they are equal, use only the combined variants
                combined := combinedVariants
            } else {
                ; If they are not equal, proceed with the original logic
                ; Find the position of the substring in the original string
                substringPos := InStr(originalString, SpoutGui["Substring"].Value)
                
                ; Extract the parts before and after the substring
                beforeSubstring := SubStr(originalString, 1, substringPos - 1)
                afterSubstring := SubStr(originalString, substringPos + StrLen(SpoutGui["Substring"].Value))
                
                ; Combine all parts to create the final string
                combined := beforeSubstring . combinedVariants . afterSubstring
            }
            A_Clipboard := combined
            combinedVariants := ""
            combined := ""
            ToolTip("Combined checked variants copied to clipboard")
            SetTimer () => ToolTip(), -2000 
        } else {
            ToolTip("No variants checked")
            SetTimer () => ToolTip(), -2000
        }
    }
    

    ; Function to update progress bar
    UpdateProgressBar() {
        try {
            if (progress > 50) {
                progress += (100 - progress) / 200
            } else {
                progress += .5
            }
            if (progress > 100) {
                progress := 0
            }
            SpoutGui["ProgressBar"].Value := progress
        } catch {
            progress := 0
            return
        }
    }

    LoadSpoutlets() {
        spoutlets := ["default"]  ; Always start with default
        basePluginPath := A_ScriptDir . "\core\mutate"
        
        ; Define plugin directories with precedence (local > pro > base)
        pluginDirs := [
            basePluginPath . "\mutate_plugins",    ; base plugins
            basePluginPath . "\mutate_pro",        ; pro plugins
            basePluginPath . "\mutate_local"       ; local plugins
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

SpoutVary(s := "1") {
    original := ClipboardAll()
    Send("^c")  ; Copy selected text
    Sleep 50  ; Wait for clipboard to update
    selectedText := A_Clipboard

    ; Validate the mutation level input
    mutationLevel := s
    if (mutationLevel < "1" || mutationLevel > "5") {
        mutationLevel := "3"
    }

    ; Run the Python script with default spoutlet for SpoutVary
    Run("pythonw.exe " A_LineFile "\..\spout_mutate.py `"1`" `"" . selectedText . "`" `"" . mutationLevel . "`" `"" . selectedText . "`" `"default`"", , "Hide", &processHandle)

    ; Set up a timer to check for process completion
    SetTimer(CheckProcessCompletion, 100)
    tooltipDots := "... ○"  ; Initialize tooltipDots

    CheckProcessCompletion(*) {
        if (!ProcessExist(processHandle)) {
            SetTimer(, 0) ; Turn off the timer
            ToolTip()
            ProcessOutput()
        } else {
            tooltipDots := (tooltipDots == "... ○") ? "... ◔" : (tooltipDots == "... ◔") ? "... ◑" : (tooltipDots == "... ◑") ? "... ◕" : "... ○"
            ToolTip("Generating variant" tooltipDots)
        }
    }

    ProcessOutput() {
        Sleep(50)  ; Wait for 50 ms
        resultstring := A_Clipboard  ; Get the updated clipboard content
        A_Clipboard := original

        ; Extract the single variant from the result
        variantPattern := '"([^"]+)"'
        pos := 1
        variant := ""
        while (pos := RegExMatch(resultstring, variantPattern, &match, pos)) {
            variant := match[1]
            pos += StrLen(match[0])
        }

        if (variant != "") {
            A_Clipboard := variant
            Send("^v")  ; Paste the variant
            if (soundEffects) {
                SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
            }
            ToolTip("Variant pasted")
            SetTimer(HideToolTip, -1000)  ; Hide tooltip after 1 second
        } else {
            if (soundEffects) {
                SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
            }
            MsgBox("No variant found. Please try again.")
        }
    }

    HideToolTip() {
        ToolTip()
    }
}

