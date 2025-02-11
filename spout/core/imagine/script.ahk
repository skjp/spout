#Requires AutoHotkey v2.0
global soundEffects

SpoutImagine() {
    ; Create GUI
    global SpoutGui
    resetGui()
    Sleep(50)
    colorScheme := GetCurrentColorScheme()
    SpoutGui := Gui("+ToolWindow", "Spout Imagine")
    SpoutGui.BackColor := colorScheme.Background

    ; Add Spoutlets dropdown in top right
    spoutlets := LoadSpoutlets()
    if (spoutlets.Length > 1) {
        SpoutGui.SetFont("s12", "Arial")
        SpoutGui.Add("Text", "x380 y14 w80 c" . colorScheme.Text, "Spoutlet:")
        preferredSpoutlet := IniRead(A_ScriptDir . "\config\settings.ini", "Imagine", "PreferredSpoutlet", "default")
        spoutletDropdown := SpoutGui.Add("DropDownList", "x+5 y10 w140 vSpoutlet c" . colorScheme.Text . " Background" . colorScheme.EditBackground, spoutlets)
        spoutletDropdown.Value := GetSpoutletIndex(preferredSpoutlet, spoutlets)
    }

    ; Main input areas
    SpoutGui.SetFont("s14", "Arial")
    SpoutGui.Add("Text", "x10 y10 w300 c" . colorScheme.Text, "Objective:")
    SpoutGui.SetFont("s12", "Arial")
    objectiveEdit := SpoutGui.Add("Edit", "x10 y40 w600 h60 vObjective c" . colorScheme.Text . " Background" . colorScheme.EditBackground)

    ; Context section with inline controls
    SpoutGui.SetFont("s14", "Arial")
    SpoutGui.Add("Text", "x10 y110 w100 c" . colorScheme.Text, "Context:")
    SpoutGui.SetFont("s12", "Arial")
    moduleSelect := SpoutGui.Add("DropDownList", "x120 y110 w150 vModuleSelect c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ["All Core Modules", "Imagine", "Parse", "Search", "Translate"])
    addSamplesButton := SpoutGui.Add("Button", "x+10 y110 w120 h24 c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Add @Context")
    addSamplesButton.OnEvent("Click", AddSamples)

    contextEdit := SpoutGui.Add("Edit", "x10 y140 w600 h80 vContext c" . colorScheme.Text . " Background" . colorScheme.EditBackground)

    ; Add Output Format field - moved up from y260 to y230
    SpoutGui.SetFont("s14", "Arial")
    SpoutGui.Add("Text", "x10 y230 w300 c" . colorScheme.Text, "Output Format:")
    SpoutGui.SetFont("s12", "Arial")
    outputFormatEdit := SpoutGui.Add("Edit", "x10 y260 w600 h40 vOutputFormat c" . colorScheme.Text . " Background" . colorScheme.EditBackground, 
        "JSON with each step defined in an array; each step has a Description and a list of Details")

    SpoutGui.SetFont("s14", "Arial")
    SpoutGui.Add("Text", "x10 y310 w300 c" . colorScheme.Text, "Stipulations:")  ; Adjusted y position
    SpoutGui.SetFont("s12", "Arial")
    stipulationsEdit := SpoutGui.Add("Edit", "x10 y340 w600 h40 vStipulations c" . colorScheme.Text . " Background" . colorScheme.EditBackground)  ; Adjusted y position

    ; Results area - adjusted y positions
    SpoutGui.SetFont("s14", "Arial")
    SpoutGui.Add("Text", "x10 y390 w300 c" . colorScheme.Text, "Generated Plan:")  ; Adjusted from y420
    progressBar := SpoutGui.Add("Progress", "x320 y390 w290 h24 vProgressBar Range0-100 c" . colorScheme.Text . " Background" . colorScheme.EditBackground)  ; Adjusted from y420

    resultListView := SpoutGui.Add("ListView", "x10 y420 w600 h160 vResultList c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ["Step", "Description", "Details"])  ; Adjusted from y450
    resultListView.Opt("+Grid +Report")

    ; Add buttons at the bottom - adjusted y position
    buttonY := 590
    buttonWidth := 145
    buttonHeight := 40
    buttonSpacing := 7

    generateButton := SpoutGui.Add("Button", "x10 y" . buttonY . " w" . buttonWidth . " h" . buttonHeight . " c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Generate Plan")
    generateButton.OnEvent("Click", GeneratePlan)

    copyButton := SpoutGui.Add("Button", "x" . (10 + buttonWidth + buttonSpacing) . " y" . buttonY . " w" . buttonWidth . " h" . buttonHeight . " c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Copy Results")
    copyButton.OnEvent("Click", CopyResults)

    cancelButton := SpoutGui.Add("Button", "x" . (10 + (buttonWidth + buttonSpacing) * 2) . " y" . buttonY . " w" . buttonWidth . " h" . buttonHeight . " c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Cancel")
    cancelButton.OnEvent("Click", (*) => ExitApp())

    ; Show the GUI with reduced height
    pos := GetGuiPosition()
    if (pos.x = "center") {
        SpoutGui.Show("w620 h640")
    } else {
        SpoutGui.Show("x" pos.x " y" pos.y " w620 h640")
    }
    objectiveEdit.Focus()

    GeneratePlan(*) {
        static progress := 0

        objective := SpoutGui["Objective"].Text
        context := SpoutGui["Context"].Text
        outputFormat := SpoutGui["OutputFormat"].Text
        stipulations := SpoutGui["Stipulations"].Text
        
        ; Escape any quotation marks in the content
        escapedObjective := StrReplace(objective, '"', '``"')
        escapedContext := StrReplace(context, '"', '``"')
        escapedOutputFormat := StrReplace(outputFormat, '"', '``"')
        escapedStipulations := StrReplace(stipulations, '"', '``"')
        
        ; Get selected spoutlet or default
        try {
            escapedSpoutlet := StrReplace(SpoutGui["Spoutlet"].Text, '"', '``"')
        } catch {
            escapedSpoutlet := "default"
        }

        ; Start progress bar animation
        SetTimer(UpdateProgressBar, 50)
        SpoutGui["ProgressBar"].Value := 0

        ; Run Python script
        scriptPath := A_LineFile . "\..\spout_imagine.py"
        RunWait("pythonw.exe `"" . scriptPath . "`" `"" . escapedObjective . "`" `"" . escapedContext . "`" `"" . escapedOutputFormat . "`" `"" . escapedStipulations . "`" `"" . escapedSpoutlet . "`"", , "Hide", &OutputVar)

        try {
            ; Stop progress bar animation
            SetTimer(UpdateProgressBar, 0)
            SpoutGui["ProgressBar"].Value := 0
        } catch {
            return
        }

        if (OutputVar != "") {
            Sleep(100)
            resultString := A_Clipboard
            
            ; Parse and display the results
            resultListView.Delete()
            
            ; Extract the content after "Plan":
            if (RegExMatch(resultString, '"Plan":\s*(\[[\s\S]*\])', &match)) {
                planString := match[1]
                
                ; Use regex to extract steps and their details
                stepPattern := '\{\s*"Step":\s*(\d+),\s*"Description":\s*"([^"]+)",\s*"Details":\s*(\[[^\]]+\]|\{[^\}]+\}|"[^"]+")'
                pos := 1
                stepsFound := false
                while (pos := RegExMatch(planString, stepPattern, &stepMatch, pos)) {
                    stepNumber := stepMatch[1]
                    description := stepMatch[2]
                    details := stepMatch[3]
                    
                    ; Process details based on its format
                    if (SubStr(details, 1, 1) == "[") {
                        ; It's an array, join the items with newlines
                        details := ProcessArray(details)
                    } else if (SubStr(details, 1, 1) == "{") {
                        ; It's an object, process it
                        details := ProcessObject(details)
                    } else {
                        ; It's a string, remove the quotes
                        details := SubStr(details, 2, -1)
                    }
                    
                    ; Add to ListView
                    resultListView.Add(, stepNumber, description, details)
                    
                    pos += StrLen(stepMatch[0])
                    stepsFound := true
                }

                if (!stepsFound) {
                    MsgBox("Debug: No steps found. Plan content:`n" . planString)
                } else {
                    ; Auto-size columns
                    resultListView.ModifyCol(1, 50)
                    resultListView.ModifyCol(2, 250)
                    resultListView.ModifyCol(3, "AutoHdr")

                    if (soundEffects) {
                        SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
                    }
                }
            } else {
                MsgBox("Error: Unexpected result format. Full content:`n" . resultString)
            }
        }
    }

    CopyResults(*) {
        results := ""
        Loop resultListView.GetCount() {
            row := A_Index
            step := resultListView.GetText(row, 1)
            description := resultListView.GetText(row, 2)
            details := resultListView.GetText(row, 3)
            results .= "Step " . step . ":`n" . description . "`n" . details . "`n`n"
        }
        A_Clipboard := RTrim(results, "`n")
        ToolTip("Results copied to clipboard")
        SetTimer () => ToolTip(), -2000
    }

    ; Function to update progress bar
    UpdateProgressBar() {
        static progress := 0
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
        SpoutGui["ProgressBar"].Value := 0  

        SpoutGui.Destroy()
        SpoutGui := ""
    }

    ; Add function to handle Add Samples button click
    AddSamples(*) {
        selectedModule := SpoutGui["ModuleSelect"].Text
        contextEdit := SpoutGui["Context"]
        currentText := contextEdit.Text
        
        ; Determine tag to add based on selection
        tag := selectedModule = "All Core Modules" ? "@spoutcli" : "@spout" . selectedModule
        
        ; Add tag to the context
        if (currentText = "") {
            contextEdit.Text := tag
        } else {
            contextEdit.Text := currentText . "`n" . tag
        }
    }
 
}

; Helper function to process array details
ProcessArray(arrayString) {
    itemPattern := '"([^"]+)"'
    itemPos := 1
    items := []
    while (itemPos := RegExMatch(arrayString, itemPattern, &itemMatch, itemPos)) {
        items.Push(itemMatch[1])
        itemPos += StrLen(itemMatch[0])
    }
    return StrJoin(items, "`n")
}

; Helper function to process object details (implement as needed)
ProcessObject(objectString) {
    ; For now, just return the object string as-is
    return objectString
}

; Helper function to join array elements into a string
StrJoin(arr, delimiter := ", ") {
    result := ""
    for index, element in arr {
        if (index > 1) {
            result .= delimiter
        }
        result .= element
    }
    return result
}

; Add these helper functions at the end
LoadSpoutlets() {
    spoutlets := ["default"]  ; Always start with default
    basePluginPath := A_LineFile . "\.."  ; Get the directory of the current script
        
    ; Define plugin directories with precedence (local > pro > base)
    pluginDirs := [
        basePluginPath . "\imagine_plugins",    ; base plugins
        basePluginPath . "\imagine_pro",        ; pro plugins
        basePluginPath . "\imagine_local"       ; local plugins
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