#Requires AutoHotkey v2.0
global soundEffects

SpoutParse() {
    ; Create GUI
    global SpoutGui
    resetGui()
    Sleep(50)
    colorScheme := GetCurrentColorScheme()
    SpoutGui := Gui("+ToolWindow", "Spout Parse")
    SpoutGui.SetFont("s14")
    SpoutGui.BackColor := colorScheme.Background

    ; Add Spoutlets dropdown in top right
    spoutlets := LoadSpoutlets()
    if (spoutlets.Length > 1) {
        SpoutGui.SetFont("s12", "Arial")
        SpoutGui.Add("Text", "x380 y14 w80 c" . colorScheme.Text, "Spoutlet:")
        preferredSpoutlet := IniRead(A_ScriptDir . "\config\settings.ini", "Parse", "PreferredSpoutlet", "default")
        spoutletDropdown := SpoutGui.Add("DropDownList", "x+5 y10 w140 vSpoutlet c" . colorScheme.Text . " Background" . colorScheme.EditBackground, spoutlets)
        spoutletDropdown.Value := GetSpoutletIndex(preferredSpoutlet, spoutlets)
    }
    SpoutGui.SetFont("s14")  ; Reset font size

    ; Get clipboard content
    clipboardContent := A_Clipboard

    ; Add Edit control to display and allow editing of input text
    SpoutGui.Add("Text", "x10 y10 w300 c" . colorScheme.Text, "Text to Parse:")
    inputTextEdit := SpoutGui.Add("Edit", "x10 y40 w600 h150 vInputText c" . colorScheme.Text . " Background" . colorScheme.EditBackground, clipboardContent)

    ; Add input for categories
    SpoutGui.Add("Text", "x10 y200 w100 c" . colorScheme.Text, "Categories:")
    categoriesInput := SpoutGui.Add("Edit", "x120 y195 w490 vCategories c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "")

    ; Add ListView for displaying results (adjusted y position)
    resultListView := SpoutGui.Add("ListView", "x10 y235 w600 h200 vResultList c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ["Category", "Value"])
    resultListView.Opt("+Grid +Report")
    resultListView.ModifyCol(1, 200)
    resultListView.ModifyCol(2, 370)

    ; Add progress bar
    progressBar := SpoutGui.Add("Progress", "x10 y445 w600 h20 vProgressBar Range0-100 c" . colorScheme.Text . " Background" . colorScheme.EditBackground, 0)

    ; Modify bottom buttons layout (adjusted y position)
    buttonY := 475
    buttonWidth := 190
    buttonSpacing := 15
    buttonHeight := 40

    parseButton := SpoutGui.Add("Button", "x10 y" . buttonY . " w" . buttonWidth . " h" . buttonHeight . " c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Parse")
    parseButton.OnEvent("Click", ParseContent)

    copyResultsButton := SpoutGui.Add("Button", "x" . (10 + buttonWidth + buttonSpacing) . " y" . buttonY . " w" . buttonWidth . " h" . buttonHeight . " c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Copy Results")
    copyResultsButton.OnEvent("Click", CopyResults)

    cancelButton := SpoutGui.Add("Button", "x" . (10 + (buttonWidth + buttonSpacing) * 2) . " y" . buttonY . " w" . buttonWidth . " h" . buttonHeight . " c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Cancel")
    cancelButton.OnEvent("Click", (*) => ExitApp())

    ; Show the GUI
    pos := GetGuiPosition()
    if (pos.x = "center") {
        SpoutGui.Show("w620")
    } else {
        SpoutGui.Show("x" pos.x " y" pos.y " w620")
    }
    inputTextEdit.Focus()

    ; Variable to track progress
    progress := 0

    ParseContent(*) {
        inputText := SpoutGui["InputText"].Text
        categories := SpoutGui["Categories"].Text

        ; Escape any quotation marks in the content
        escapedInputText := StrReplace(inputText, '"', '``"')
        escapedCategories := StrReplace(categories, '"', '``"')
        
        ; Start progress bar animation
        SetTimer(UpdateProgressBar, 50)

        ; Get selected spoutlet or default - matching the search script's approach
        try {
            escapedSpoutlet := StrReplace(SpoutGui["Spoutlet"].Text, '"', '``"')
        } catch {
            escapedSpoutlet := "default"
        }
        ; Run Python script with spoutlet parameter
        scriptPath := A_LineFile . "\..\spout_parse.py"
        cmd := '"' . A_ComSpec . '" /c pythonw.exe "'
            . scriptPath . '" "'
            . escapedCategories . '" "'
            . escapedInputText . '" "'
            . escapedSpoutlet . '"'
        RunWait(cmd, , "Hide", &OutputVar)

        try {
            ; Stop progress bar animation
            SetTimer(UpdateProgressBar, 0)
            ; Reset progress bar
            progressBar.Value := 0
        } catch {
            ; Handle the case where the GUI is closed while this is still running
            return
        }

        if (OutputVar != "") {
            Sleep(100)  ; Wait for 100 milliseconds
            resultString := A_Clipboard
            progressBar.Value := 0

            ; Parse and display the results
            resultListView.Delete()
            
            ; Extract the content after "ParsedParts":
            if (RegExMatch(resultString, '"ParsedParts":\s*(\{[\s\S]*\})', &match)) {
                parsedPartsString := match[1]
                
                ; Use regex to extract categories and their values (arrays or strings)
                categoryPattern := '"([^"]+)":\s*((?:\[(?:[^"\[\]]|"[^"]*")+\])|"[^"]*"|(?:\{[^{}]*\}))'
                pos := 1
                categoriesFound := false
                while (pos := RegExMatch(parsedPartsString, categoryPattern, &catMatch, pos)) {
                    category := catMatch[1]
                    categoryContent := catMatch[2]
                    
                    ; Handle both array and single string/object values
                    if (SubStr(categoryContent, 1, 1) = "[") {
                        ; Extract array items
                        itemPattern := '"([^"]+)"'
                        itemPos := 1
                        items := []
                        while (itemPos := RegExMatch(categoryContent, itemPattern, &itemMatch, itemPos)) {
                            items.Push(itemMatch[1])
                            itemPos += StrLen(itemMatch[0])
                        }
                        itemsString := ""
                        for index, item in items {
                            if (index > 1) {
                                itemsString .= ", "
                            }
                            itemsString .= item
                        }
                    } else {
                        ; Handle single string value (remove quotes)
                        itemsString := RegExReplace(categoryContent, '^"|"$')
                    }
                    
                    ; Add to ListView
                    resultListView.Add(, category, itemsString)
                    
                    pos += StrLen(catMatch[0])
                    categoriesFound := true
                }

                if (!categoriesFound) {
                    MsgBox("Debug: No categories found. ParsedParts content:`n" . parsedPartsString)
                } else {
                    ; Adjust column widths
                    resultListView.ModifyCol(1, 150)  ; Set a fixed width for the category column
                    resultListView.ModifyCol(2, "AutoHdr")  ; Auto-size the items column

                    if (soundEffects) {
                        SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
                    }
                }
            } else {
                MsgBox("Error: Unexpected result format. Full content:`n" . resultString)
            }
        } else {
            MsgBox("Error: Failed to run the parsing script.")
        }
    }

    CopyResults(*) {
        results := ""
        Loop resultListView.GetCount() {
            row := A_Index
            category := resultListView.GetText(row, 1)
            value := resultListView.GetText(row, 2)
            results .= category . ": " . value . "`n"
        }
        A_Clipboard := RTrim(results, "`n")
        ToolTip("Results copied to clipboard")
        SetTimer () => ToolTip(), -2000
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


    ; Handle GUI close
    SpoutGui.OnEvent("Close", (*) => ExitApp())

    SpoutGui.OnEvent("Escape", (*) => ExitApp())

    ExitApp(*) {
        SaveGuiPosition(SpoutGui.Hwnd)
        ; Reset progress bar
        progressBar.Value := 0
        SpoutGui.Destroy()
        SpoutGui := ""
    }

    ; Add these helper functions at the end
    LoadSpoutlets() {
        spoutlets := ["default"]  ; Always start with default
        basePluginPath := A_LineFile . "\.."  ; Get the directory of the current script
        
        ; Define plugin directories with precedence (local > pro > base)
        pluginDirs := [
            basePluginPath . "\parse_plugins",    ; base plugins
            basePluginPath . "\parse_pro",        ; pro plugins
            basePluginPath . "\parse_local"       ; local plugins
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

class SpoutParser {
    __New(spoutlet := "default", categories := "summary") {
        this.spoutlet := spoutlet
        this.categories := categories
    }

    Parse(input := "", target := "") {
        ; Validate input parameters
        if (input = "" || this.categories = "") {
            return ""
        }

        ; Escape any quotation marks in the content
        escapedInput := StrReplace(input, '"', '``"')
        escapedCategories := StrReplace(this.categories, '"', '``"')
        escapedSpoutlet := StrReplace(this.spoutlet, '"', '``"')

        ; Run Python script with spoutlet parameter
        scriptPath := A_LineFile . "\..\spout_parse.py"
        cmd := '"' . A_ComSpec . '" /c pythonw.exe "'
            . scriptPath . '" "'
            . escapedCategories . '" "'
            . escapedInput . '" "'
            . escapedSpoutlet . '"'
        RunWait(cmd, , "Hide", &OutputVar)

        if (OutputVar != "") {
            Sleep(100)  ; Wait for 100 milliseconds
            resultString := A_Clipboard
            
            ; Parse the results
            if (RegExMatch(resultString, '"ParsedParts":\s*(\{[\s\S]*\})', &match)) {
                parsedPartsString := match[1]
                results := Map()
                
                ; Extract categories and their values
                categoryPattern := '"([^"]+)":\s*((?:\[(?:[^"\[\]]|"[^"]*")+\])|"[^"]*"|(?:\{[^{}]*\}))'
                pos := 1
                
                while (pos := RegExMatch(parsedPartsString, categoryPattern, &catMatch, pos)) {
                    category := catMatch[1]
                    categoryContent := catMatch[2]
                    
                    ; Handle both array and single string/object values
                    if (SubStr(categoryContent, 1, 1) = "[") {
                        ; Extract array items
                        itemPattern := '"([^"]+)"'
                        itemPos := 1
                        items := []
                        while (itemPos := RegExMatch(categoryContent, itemPattern, &itemMatch, itemPos)) {
                            items.Push(itemMatch[1])
                            itemPos += StrLen(itemMatch[0])
                        }
                        results[category] := items
                    } else {
                        ; Handle single string value (remove quotes)
                        results[category] := RegExReplace(categoryContent, '^"|"$')
                    }
                    
                    pos += StrLen(catMatch[0])
                }
                
                ; If target is specified, return only that category (case insensitive)
                if (target != "") {
                    for key, value in results {
                        if (StrLower(key) = StrLower(target))
                            return value
                    }
                    return ""
                }
                
                ; Otherwise return all results
                return results
            }
        }
        
        return ""
    }
}


SpoutPull(categories := "ImportantPoints, OtherDetails", target := "ImportantPoints", filename := "parsed_notes.txt") {
    ; Store original clipboard content
    originalClip := A_Clipboard
    
    ; Show animated tooltip
    tooltipDots := "... \"
    ToolTip("Parsing" tooltipDots)
    SetTimer(UpdateTooltip, 100)

    parser := SpoutParser("default", categories)
    
    ; Parse the input and get result
    result := parser.Parse(originalClip, target)
    
    ; Stop tooltip animation
    SetTimer(UpdateTooltip, 0)
    ToolTip()

    ; Show result in SpoutNoter if not empty
    if (result != "") {
        ; Format and set clipboard to just the target content
        if Type(result) = "Array" {
            targetContent := ""
            for item in result
                targetContent .= item . "`n"
            A_Clipboard := RTrim(targetContent, "`n")
        } else {
            A_Clipboard := String(result)
        }
        
        SpoutNoter("", false, filename)

        if (soundEffects) {
            SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
        }
    } else {
        if (soundEffects) {
            SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
        }
        MsgBox("Error: No results found")
        ; Restore original clipboard
        A_Clipboard := originalClip
    }

    UpdateTooltip() {
        ; Toggle between animation frames
        tooltipDots := (tooltipDots == "... ○") ? "... ◔" : (tooltipDots == "... ◔") ? "... ◑" : (tooltipDots == "... ◑") ? "... ◕" : "... ○"
        ToolTip("Parsing" tooltipDots)
    }
}

SpoutSave(filename := "saves.json", categories := "Style, Subject, Setting, Composition, Lighting, Other", spoutlet := "genimg", gui := true) {
    ; Check file extension
    fileExt := StrLower(StrSplit(filename, ".").Pop())
    if (fileExt != "json" && fileExt != "jsonl") {
        MsgBox("Error: SpoutSave requires a .json or .jsonl file extension.`nCurrent file: " . filename, "Invalid File Type")
        return
    }

    ; Save original clipboard
    originalClip := A_Clipboard

    ; Triple click to select paragraph and copy
    Click 3
    Sleep(50)
    Send("^c")
    Sleep(100)

    ; If clipboard is empty after copy, use original content
    inputContent := A_Clipboard ? A_Clipboard : originalClip

    ; Show animated tooltip
    tooltipDots := "... \"
    ToolTip("Parsing" tooltipDots)
    SetTimer(UpdateTooltip, 100)

    ; Initialize parser with specified spoutlet and categories
    parser := SpoutParser(spoutlet, categories)
    
    ; Parse the input and get result
    result := parser.Parse(inputContent)
    
    ; Stop tooltip animation
    SetTimer(UpdateTooltip, 0)
    ToolTip()

    if (result != "") {
        ; Convert Map to properly formatted JSON string
        if (result is Map) {
            if (result.Count) {
                ; Start building JSON parts
                jsonParts := []
                formattedDate := FormatTime(, "yyyy-MM-dd HH:mm:ss")
                jsonParts.Push('"Date": "' . formattedDate . '"')
                
                for key, value in result {
                    ; Handle empty values
                    if (value = "") {
                        value := '""'
                    } else if (Type(value) = "Array") {
                        ; Handle array values
                        arrayStr := "["
                        for i, item in value {
                            if (i > 1) {
                                arrayStr .= ", "
                            }
                            arrayStr .= '"' . StrReplace(item, '"', '\"') . '"'
                        }
                        arrayStr .= "]"
                        value := arrayStr
                    } else {
                        ; Ensure value is properly quoted if it's not already
                        if (!RegExMatch(value, '^\s*[{\[""]')) {
                            value := '"' . StrReplace(value, '"', '\"') . '"'
                        }
                    }
                    jsonParts.Push('"' . key . '": ' . value)
                }
                finalJson := "{" . StrJoin(jsonParts, ", ") . "}"
            } else {
                formattedDate := FormatTime(, "yyyy-MM-dd HH:mm:ss")
                finalJson := '{"Date": "' . formattedDate . '"}'
            }
        } else {
            ; If result is already a string, clean it up
            parsedContent := RegExReplace(result, "^\s*```json\s*", "") ; Remove leading ```json
            parsedContent := RegExReplace(parsedContent, "\s*```\s*$", "") ; Remove trailing ```
            
            ; Extract content between ParsedParts brackets if present
            if (RegExMatch(parsedContent, 'i)"ParsedParts"\s*:\s*({[^}]+})', &match)) {
                parsedContent := match[1]
            }
            
            ; Remove outer braces and combine with date
            parsedContent := RegExReplace(parsedContent, "^\{|\}$", "")
            formattedDate := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            finalJson := '{"Date": "' . formattedDate . '", ' . parsedContent . '}'
        }

        ; Set clipboard to formatted content
        A_Clipboard := finalJson
        
        ; Show result in SpoutNoter
        SpoutNoter(finalJson, !gui, note := filename)

        if (soundEffects) {
            SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
        }
    } else {
        if (soundEffects) {
            SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
        }
        MsgBox("Error: No results found")
        ; Restore original clipboard
        A_Clipboard := originalClip
    }

    UpdateTooltip() {
        ; Toggle between animation frames
        tooltipDots := (tooltipDots == "... ○") ? "... ◔" : (tooltipDots == "... ◔") ? "... ◑" : (tooltipDots == "... ◑") ? "... ◕" : "... ○"
        ToolTip("Parsing" tooltipDots)
    }
}
