#Requires AutoHotkey v2.0
global soundEffects

SpoutEvaluate() {
    ; Create GUI
    global SpoutGui
    resetGui()
    Sleep(50)
    colorScheme := GetCurrentColorScheme()
    SpoutGui := Gui("+ToolWindow", "Spout Evaluate")
    SpoutGui.SetFont("s14")
    SpoutGui.BackColor := colorScheme.Background

    ; Add Spoutlets dropdown in top right
    spoutlets := LoadSpoutlets()
    if (spoutlets.Length > 1) {
        SpoutGui.SetFont("s12", "Arial")
        SpoutGui.Add("Text", "x380 y14 w80 c" . colorScheme.Text, "Spoutlet:")
        preferredSpoutlet := IniRead(A_ScriptDir . "\config\settings.ini", "Evaluate", "PreferredSpoutlet", "default")
        spoutletDropdown := SpoutGui.Add("DropDownList", "x+5 y10 w140 vSpoutlet c" . colorScheme.Text . " Background" . colorScheme.EditBackground, spoutlets)
        spoutletDropdown.Value := GetSpoutletIndex(preferredSpoutlet, spoutlets)
    }
    SpoutGui.SetFont("s14")  ; Reset font size

    ; Get clipboard content
    clipboardContent := A_Clipboard

    ; Add Edit control to display and allow editing of clipboard content
    SpoutGui.Add("Text", "x10 y10 w300 c" . colorScheme.Text, "Content to Evaluate:")
    contentEdit := SpoutGui.Add("Edit", "x10 y40 w600 h150 vContent c" . colorScheme.Text . " Background" . colorScheme.EditBackground, clipboardContent)

    ; Add input for separator and explanation checkbox on the same line
    SpoutGui.Add("Text", "x10 y200 w100 c" . colorScheme.Text, "Separator:")
    separatorInput := SpoutGui.Add("Edit", "x120 y195 w100 vSeparator c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "@@")
    explanationCheckbox := SpoutGui.Add("Checkbox", "x290 y200 w200 vExplanation c" . colorScheme.Text, "Include Explanations")

    ; Add input for judging criteria
    SpoutGui.Add("Text", "x10 y240 w150 c" . colorScheme.Text, "Judging Criteria:")
    criteriaInput := SpoutGui.Add("Edit", "x160 y235 w450 vCriteria c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Quality:0.4, Relevance:0.3, Impact:0.3")

    ; Add ListView for displaying results
    resultListView := SpoutGui.Add("ListView", "x10 y280 w600 h240 vResultList c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ["Rank", "Input", "Score", "Explanation"])
    resultListView.Opt("+Grid +Report")
    resultListView.ModifyCol(1, 50)
    resultListView.ModifyCol(2, 250)
    resultListView.ModifyCol(3, 70)
    resultListView.ModifyCol(4, 200)

    ; Add progress bar
    progressBar := SpoutGui.Add("Progress", "x10 y530 w600 h20 vProgressBar Range0-100 c" . colorScheme.Text . " Background" . colorScheme.EditBackground, 0)

    ; Add buttons at the bottom
    buttonY := 560
    buttonWidth := 145  ; Made buttons slightly smaller
    buttonHeight := 45
    buttonSpacing := 7  ; Reduced spacing between buttons

    evaluateButton := SpoutGui.Add("Button", "x10 y" . buttonY . " w" . buttonWidth . " h" . buttonHeight . " c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Evaluate")
    evaluateButton.OnEvent("Click", EvaluateContent)

    copyResultsButton := SpoutGui.Add("Button", "x" . (10 + buttonWidth + buttonSpacing) . " y" . buttonY . " w" . buttonWidth . " h" . buttonHeight . " c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Copy Results")
    copyResultsButton.OnEvent("Click", CopyResults)

    copyTopRankedButton := SpoutGui.Add("Button", "x" . (10 + (buttonWidth + buttonSpacing) * 2) . " y" . buttonY . " w" . buttonWidth . " h" . buttonHeight . " c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Copy Top Ranked")
    copyTopRankedButton.OnEvent("Click", CopyTopRanked)

    cancelButton := SpoutGui.Add("Button", "x" . (10 + (buttonWidth + buttonSpacing) * 3) . " y" . buttonY . " w" . buttonWidth . " h" . buttonHeight . " c" . colorScheme.Text . " Background" . colorScheme.EditBackground, "Cancel")
    cancelButton.OnEvent("Click", (*) => ExitApp())

    ; Show the GUI
    pos := GetGuiPosition()
    if (pos.x = "center") {
        SpoutGui.Show("w620")
    } else {
        SpoutGui.Show("x" pos.x " y" pos.y " w620")
    }
    contentEdit.Focus()

    ; Variable to track progress
    progress := 0

    EvaluateContent(*) {
        content := SpoutGui["Content"].Text
        separator := SpoutGui["Separator"].Text
        criteria := SpoutGui["Criteria"].Text
        explanation := SpoutGui["Explanation"].Value

        ; Escape any quotation marks in the content
        escapedContent := StrReplace(content, '"', '``"')
        
        ; Get selected spoutlet or default - matching the search script's approach
        try {
            escapedSpoutlet := StrReplace(SpoutGui["Spoutlet"].Text, '"', '``"')
        } catch {
            escapedSpoutlet := "default"
        }

        ; Start progress bar animation
        SetTimer(UpdateProgressBar, 50)

        ; Run Python script with spoutlet parameter
        scriptPath := A_LineFile . "\..\spout_evaluate.py"
        RunWait('pythonw.exe "' . scriptPath . '" "' . escapedContent . '" "' . separator . '" "' . criteria . '" "' . (explanation ? "true" : "false") . '" "' . escapedSpoutlet . '"', , "Hide", &OutputVar)

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
            resultString := A_Clipboard  ; Get the updated clipboard content
            progressBar.Value := 0

            ; Parse and display the results
            resultListView.Delete()

            ; Clean up the JSON string by removing whitespace and newlines
            resultString := RegExReplace(resultString, "[\s\r\n]+", " ")
            
            ; Use regex to extract the Rankings array with a more flexible pattern
            if (RegExMatch(resultString, 'i){\s*"Rankings":\s*\[(.*)\]\s*}', &match)) {
                rankingsJson := match[1]
                
                ; Split the rankings into individual objects with a more flexible pattern
                ; Make the Explanation field optional
                rankingPattern := '{\s*"Rank":\s*(\d+)\s*,\s*"Name":\s*"([^"]+)"\s*,\s*"Score":\s*([\d.]+)(?:\s*,\s*"Explanation":\s*"([^"]+)")?\s*}'
                pos := 1
                
                while (pos := RegExMatch(rankingsJson, rankingPattern, &rankMatch, pos)) {
                    rank := Trim(rankMatch[1])
                    name := Trim(rankMatch[2])
                    score := Trim(rankMatch[3])
                    explanation := rankMatch.Count >= 4 ? Trim(rankMatch[4]) : ""
                    
                    resultListView.Add(, rank, name, score, explanation)
                    
                    pos += StrLen(rankMatch[0])
                }

                ; Adjust column widths
                resultListView.ModifyCol(2, "AutoHdr")
                resultListView.ModifyCol(4, "AutoHdr")

                if (soundEffects) {
                    SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
                }
            } else {
                MsgBox("Error: Failed to parse the evaluation results. Please check the JSON format.")
            }
        } else {
            MsgBox("Error: Failed to run the evaluation script.")
        }
    }

     ; Handle GUI close
     SpoutGui.OnEvent("Close", (*) => ExitApp())

     SpoutGui.OnEvent("Escape", (*) => ExitApp())

    ExitApp(*) {
        SaveGuiPosition(SpoutGui.Hwnd)
        SpoutGui.Destroy()
        SpoutGui := ""
    }
 

    CopyResults(*) {
        results := ""
        Loop resultListView.GetCount() {
            row := A_Index
            rank := resultListView.GetText(row, 1)
            input := resultListView.GetText(row, 2)
            score := resultListView.GetText(row, 3)
            explanation := resultListView.GetText(row, 4)
            results .= rank . ": " . input . " | Score: " . score
            if (explanation != "") {
                results .= " | " . explanation
            }
            results .= "`n"
        }
        A_Clipboard := RTrim(results, "`n")
        ToolTip("Results copied to clipboard")
        SetTimer () => ToolTip(), -2000
    }

    CopyTopRanked(*) {
        if (resultListView.GetCount() > 0) {
            topRanked := resultListView.GetText(1, 2)
            A_Clipboard := topRanked
            ToolTip("Top ranked input copied to clipboard")
            SetTimer () => ToolTip(), -2000
        } else {
            ToolTip("No results available")
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

    ; Add these helper functions at the end
    LoadSpoutlets() {
        spoutlets := ["default"]  ; Always start with default
        basePluginPath := A_LineFile . "\.."  ; Get the directory of the current script
        
        ; Define plugin directories with precedence (local > pro > base)
        pluginDirs := [
            basePluginPath . "\evaluate_plugins",    ; base plugins
            basePluginPath . "\evaluate_pro",        ; pro plugins
            basePluginPath . "\evaluate_local"       ; local plugins
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