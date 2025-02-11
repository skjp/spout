#Requires AutoHotkey v2.0
global soundEffects
global qwiknotesPath

SpoutConverse() {
    ; Create the main GUI
    global SpoutGui
    global modelOptions
    global chatHistory
    global primerText
    global selectedPrimerPreset  ; Change from static to global
    
    ; Get the notes path from settings and create Converse subfolder
    notesPath := ReadSetting("General", "NotesFolder", A_MyDocuments . "\Notes")
    conversePath := notesPath . "\Converse"
    if (!DirExist(conversePath)) {
        DirCreate(conversePath)
    }
    
    ; Initialize values from ini file - only store the selected preset name
    selectedPrimerPreset := ReadOrInitializeSetting("Converse", "SelectedPrimerPreset", "default")
    
    ; Ensure primers directory exists
    primersPath := A_ScriptDir . "\core\converse\options\primers"
    if (!DirExist(primersPath)) {
        DirCreate(primersPath)
    }

    ; Create default.txt if primers folder is empty
    if (!FileExist(primersPath . "\*.txt")) {
        defaultContent := "You are a helpful assistant that can help with tasks and topics. Your role is to contribute to a chat conversation based on the provided history and recent message."
        FileAppend(defaultContent, primersPath . "\default.txt")
    }

    ; Load the primer text from the corresponding file
    selectedFile := primersPath . "\" . selectedPrimerPreset . ".txt"
    if FileExist(selectedFile) {
        primerText := FileRead(selectedFile)
    } else {
        ; Fallback to default if selected file doesn't exist
        primerText := FileRead(primersPath . "\default.txt")
        selectedPrimerPreset := "default"
    }

    resetGui()
    Sleep(50)

    colorScheme := GetCurrentColorScheme()
    SpoutGui := Gui("+ToolWindow")
    SpoutGui.Title := "Spout Converse"
    SpoutGui.BackColor := colorScheme.Background
    chatHistoryFile := conversePath . "\chatHistory.txt"

    ; Add Spoutlets dropdown in top right
    spoutlets := LoadSpoutlets()
    if (spoutlets.Length > 1) {
        SpoutGui.SetFont("s12", "Arial")
        SpoutGui.Add("Text", "x420 y14 w80 c" . colorScheme.Text, "Spoutlet:")
        preferredSpoutlet := IniRead(A_ScriptDir . "\config\settings.ini", "Converse", "PreferredSpoutlet", "default")
        spoutletDropdown := SpoutGui.Add("DropDownList", "x+5 y10 w140 vSpoutlet c" . colorScheme.Text . " Background" . colorScheme.EditBackground, spoutlets)
        spoutletDropdown.Value := GetSpoutletIndex(preferredSpoutlet, spoutlets)
    }

    ; Add text view for chat history
    SpoutGui.SetFont("s16")
    ; Add label for chat history
    SpoutGui.Add("Text", "x10 y10 w150 c" . colorScheme.Text, "Chat History:")
    ; Add buttons with reduced width and adjusted spacing
    SpoutGui.SetFont("norm s15")
    SpoutGui.Add("Button", "x+5 yp+5 w70 h30", "Load").OnEvent("Click", LoadChatHistory)
    SpoutGui.Add("Button", "x+5 yp w70 h30", "Save").OnEvent("Click", SaveChatHistory)
    SpoutGui.Add("Button", "x+5 yp w70 h30", "Clear").OnEvent("Click", ClearChatHistory)

    SpoutGui.Add("Edit", "x10 w630 h420 vChatHistory ReadOnly c" . colorScheme.Text . " Background" . colorScheme.EditBackground, chatHistory)
    
    ; Add primer and model selection controls with consistent styling
    SpoutGui.SetFont("s12", "Arial")
    
    ; Create a row for dropdowns with consistent spacing and alignment
    SpoutGui.Add("Text", "x10 y+15 w50 c" . colorScheme.Text, "Primer:")
    
    ; Load primers from files
    primerFiles := ["default"]  ; Start with default
    primerDisplayNames := ["Default"]  ; Start with Default (capitalized)
    
    ; Recursively get all .txt files from primers directory and its subdirectories
    Loop Files, A_ScriptDir . "\core\converse\options\primers\*.txt", "R" {
        ; Get relative path from primers folder
        relativePath := SubStr(A_LoopFileFullPath, StrLen(A_ScriptDir . "\core\converse\options\primers\") + 1)
        primerName := StrReplace(relativePath, ".txt")  ; Remove .txt extension
        
        if (primerName != "default") {  ; Skip default as we already added it
            primerFiles.Push(primerName)
            ; Convert file name to display name (replace underscores with spaces and title case)
            ; For subfolders, replace backslash with arrow
            displayName := StrReplace(primerName, "_", " ")
            displayName := StrReplace(displayName, "\", " → ")
            displayName := Format("{:T}", displayName)  ; Title case
            primerDisplayNames.Push(displayName)
        }
    }
    
    ; Add dropdown for primer selection with display names
    primerDropdown := SpoutGui.Add("DropDownList", "x+5 yp-5 w220 vSelectedPrimer c" . colorScheme.Text . " Background" . colorScheme.EditBackground, primerDisplayNames)
    primerDropdown.OnEvent("Change", LoadSelectedPrimer)
    
    ; Add New Primer button
    SpoutGui.Add("Button", "x+5 yp w60 h24", "New").OnEvent("Click", CreateNewPrimer)
    
    ; Find and select the current preset in the display names
    currentPresetIndex := 1  ; Default to first item if not found
    for index, name in primerFiles {
        if (StrLower(name) = StrLower(selectedPrimerPreset)) {  ; Case-insensitive comparison
            currentPresetIndex := index
            break
        }
    }
    primerDropdown.Choose(currentPresetIndex)
    
    ; Add model selection with consistent spacing
    SpoutGui.Add("Text", "x+30 yp+5 w50 c" . colorScheme.Text, "Model:")
    SpoutGui.Add("DropDownList", "x+5 yp-5 w210 vSelectedLLM c" . colorScheme.Text . " Background" . colorScheme.EditBackground, modelOptions).Choose(ReadSetting("General", "PreferredModel", "gpt-3.5-turbo"))

    ; Add progress bar on its own line
    SpoutGui.Add("Progress", "x10 y+15 w630 h24 vProgressBar Range0-100")

    ; Add input field
    inputField := SpoutGui.Add("Edit", "x10 y+10 w520 h60 vUserInput c" . colorScheme.Text . " Background" . colorScheme.EditBackground)

    ; Add send button
    SpoutGui.Add("Button", "x+10 yp w100 h60", "Send").OnEvent("Click", SendMessage)

    ; Function to get chat history from file
    GetChatHistoryFromFile() {
        
        if FileExist(chatHistoryFile) {
            chatHistory := FileRead(chatHistoryFile)
            return chatHistory
        } else {
            FileAppend("", chatHistoryFile)
            return ""
        }
    }

    ; Function to save chat history to file
    SaveChatHistoryToFile(*) {
        FileDelete(chatHistoryFile)
        FileOpen(chatHistoryFile, "w").Write(SpoutGui["ChatHistory"].Value)
    }


    ; Load chat history from file when initializing
    chatHistory := GetChatHistoryFromFile()
    SpoutGui["ChatHistory"].Value := chatHistory


    ; Function to save chat history
    SaveChatHistory(*) {
        timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
        defaultFileName := "chat_history_" . timestamp . ".txt"
        saveFile := FileSelect("S16", conversePath . "\" . defaultFileName, "Save Chat History", "Text Files (*.txt)")
        if (saveFile != "") {
            FileAppend(SpoutGui["ChatHistory"].Value, saveFile)
            MsgBox("Chat history saved successfully.")
        }
    }

    ; Function to load chat history
    LoadChatHistory(*) {
        fileToLoad := FileSelect("3", conversePath, "Load Chat History", "Text Files (*.txt)")
        if (fileToLoad != "") {
            loadedContent := FileRead(fileToLoad)
            if (loadedContent != "") {
                chatHistory := loadedContent
                SpoutGui["ChatHistory"].Value := chatHistory
                MsgBox("Chat history loaded successfully.")
            } else {
                MsgBox("Error loading file: " . A_LastError)
            }
        }
    }

    ClearChatHistory(*) {
        result := MsgBox("Are you sure you want to erase the chat history?", "Confirm Clear History", 4)
        if (result == "Yes") {
            chatHistory := ""
            SpoutGui["ChatHistory"].Value := ""
        }
    }

    ; Add focus/defocus event handlers for Enter hotkey
    inputField.OnEvent("Focus", (*) => (Hotkey("Enter", SendMessage), Hotkey("Enter", "On")))
    inputField.OnEvent("LoseFocus", (*) => Hotkey("Enter", "Off"))

    ; Show the GUI and set focus to the input field
    pos := GetGuiPosition()
    if (pos.x = "center") {
        SpoutGui.Show("w650")
    } else {
        SpoutGui.Show("x" pos.x " y" pos.y " w650")
    }

    inputField.Focus()

    SendMessage(*) {
        try {
            if !SpoutGui["Send"].Enabled {
                return
            }
        } catch {
            return
        }
        userInput := SpoutGui["UserInput"].Value
        selectedLLM := SpoutGui["SelectedLLM"].Text
    
        if (userInput != "") {
            ; Disable the send button
            SpoutGui["Send"].Enabled := false
            ; Clear input field
            SpoutGui["UserInput"].Value := ""
            ; Append user message to chat history with highlighted label
            chatHistory .= "<USER>" . "  " . userInput . "`n`n"

            selectedModel := SpoutGui["SelectedLLM"].Text

            SpoutGui["ChatHistory"].Value := chatHistory
            SaveChatHistoryToFile()
            ScrollChatToBottom()
            ; Save original clipboard content
            originalClipboard := A_Clipboard
            ; Run SpoutChat.py script
            scriptPath := A_LineFile . "\..\spout_converse.py"

            EscapeQuotes(text) {
                return StrReplace(text, '"', '``"')
            }

            ; Get selected spoutlet or default
            try {
                escapedSpoutlet := StrReplace(SpoutGui["Spoutlet"].Text, '"', '``"')
            } catch {
                escapedSpoutlet := "default"
            }

            ; Run the Python script with spoutlet parameter
            Run("pythonw.exe `"" . scriptPath . "`" `"" . EscapeQuotes(primerText) . "`" `"" . chatHistoryFile . "`" `"" . EscapeQuotes(userInput) . "`" `"" . EscapeQuotes(selectedModel) . "`" `"" . escapedSpoutlet . "`"", , "Hide", &processHandle)
    
            ; Start progress bar animation
            SetTimer(UpdateProgressBar, 100)
    
            ; Set up a timer to check for process completion
            SetTimer(CheckProcessCompletion, 100)
    
            ; Function to check if the process has completed
            CheckProcessCompletion() {
                if (!ProcessExist(processHandle) && (processHandle != 0)) {
                    SetTimer(, 0) ; Turn off the timer
                    if (soundEffects) {
                        SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
                    }
                    SetTimer(UpdateProgressBar, 0) ; Turn off progress bar animation
                    try {
                        SpoutGui["ProgressBar"].Value := 0 ; Reset progress bar
                        ProcessOutput()
                        ; Re-enable the send button
                        SpoutGui["Send"].Enabled := true
                    } catch as err {
                        if (soundEffects) {
                            SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
                        }
                    }
                }
            }
    
            ; Function to update progress bar
            UpdateProgressBar() {
                try {
                    if (SpoutGui["ProgressBar"].Value >= 100) {
                        SpoutGui["ProgressBar"].Value := 0
                    } else {
                        SpoutGui["ProgressBar"].Value += 1
                    }
                } catch as err {
                    ; Handle the error silently
                }
            }
    
            ; Function to process output and update chat history
            ProcessOutput() {
                Sleep(200)  ; Wait for 200 ms
                response := A_Clipboard  ; Get text from clipboard
    
                ; Get the selected model name
                selectedModel := SpoutGui["SelectedLLM"].Text
    
                ; Append LLM response to chat history with highlighted model name
                selectedModelName := StrSplit(selectedModel, "/").Pop()
                chatHistory .= "<" . StrUpper(selectedModelName) . ">" . "  " . response . "`n`n"
                SpoutGui["ChatHistory"].Value := chatHistory
                SaveChatHistoryToFile()
                ; Scroll to the bottom of the chat history
                ScrollChatToBottom()
    
                ; Restore original clipboard content
                A_Clipboard := originalClipboard

                ; Set focus back to the input field
                SpoutGui["UserInput"].Focus()
            }
        }
    }
    
    ScrollChatToBottom() {
        chatHistoryView := SpoutGui["ChatHistory"]
    
        ; Use PostMessage to scroll to the bottom
        PostMessage(0x115, 7, 0, chatHistoryView)
        
        ; Force the control to redraw
        chatHistoryView.Redraw()
    }

    ; Handle GUI close
    SpoutGui.OnEvent("Close", (*) => ExitApp())

    SpoutGui.OnEvent("Escape", (*) => ExitApp())

    ExitApp(*) {
        SaveGuiPosition(SpoutGui.Hwnd)
        try {
            ; Stop all timers
            SetTimer(UpdateTimer, 0)
            if (IsSet(UpdateProgressBar) && UpdateProgressBar != "") {
                SetTimer(UpdateProgressBar, 0)
            }
            if (IsSet(CheckProcessCompletion) && CheckProcessCompletion != "") {
                SetTimer(CheckProcessCompletion, 0)
            }

            ; Reset the process handle if it exists
            processHandle := 0

        } catch as err {
            ; Handle any errors silently
        }

        Hotkey("Enter", "Off")
        SpoutGui.Destroy()
        SpoutGui := ""
    }

    ; Add these helper functions at the end
    LoadSpoutlets() {
        spoutlets := ["default"]  ; Always start with default
        basePluginPath := A_ScriptDir . "\core\converse"
        
        ; Define plugin directories with precedence (local > pro > base)
        pluginDirs := [
            basePluginPath . "\converse_plugins",    ; base plugins
            basePluginPath . "\converse_pro",        ; pro plugins
            basePluginPath . "\converse_local"       ; local plugins
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

    LoadSelectedPrimer(*) {
        global primerText, selectedPrimerPreset
        ; Convert display name back to filename format
        selectedDisplay := primerDropdown.Text
        ; Convert display format back to file path format
        selectedFile := StrReplace(StrLower(selectedDisplay), " → ", "\")  ; Convert arrows back to backslashes
        selectedFile := StrReplace(selectedFile, " ", "_")  ; Convert spaces to underscores
        selectedFile := A_ScriptDir . "\core\converse\options\primers\" . selectedFile . ".txt"
        
        if FileExist(selectedFile) {
            primerText := FileRead(selectedFile)
            selectedPrimerPreset := StrReplace(StrLower(selectedDisplay), " ", "_")
            WriteSetting("Converse", "SelectedPrimerPreset", selectedPrimerPreset)
        }
    }

    CreateNewPrimer(*) {
        newPrimerGui := Gui("+ToolWindow")
        newPrimerGui.Title := "Create New Primer"
        newPrimerGui.BackColor := colorScheme.Background
        newPrimerGui.SetFont("s12", "Arial")
        
        ; Add name input
        newPrimerGui.Add("Text", "x10 y15 w100 c" . colorScheme.Text, "Primer Name:")
        nameInput := newPrimerGui.Add("Edit", "x+5 yp-5 w300 c" . colorScheme.Text . " Background" . colorScheme.EditBackground)
        
        ; Add content input
        newPrimerGui.Add("Text", "x10 y+15 w100 c" . colorScheme.Text, "Primer Text:")
        contentInput := newPrimerGui.Add("Edit", "x10 y+5 w400 h200 c" . colorScheme.Text . " Background" . colorScheme.EditBackground)
        
        ; Add buttons
        newPrimerGui.Add("Button", "x240 y+10 w80", "Save").OnEvent("Click", SaveNewPrimer)
        newPrimerGui.Add("Button", "x+10 yp w80", "Cancel").OnEvent("Click", (*) => newPrimerGui.Destroy())
        
        newPrimerGui.Show()
        
        SaveNewPrimer(*) {
            primerName := nameInput.Value
            primerContent := contentInput.Value
            
            ; Validate inputs
            if (primerName = "") {
                MsgBox("Please enter a name for the primer.", "Missing Name", 48)
                return
            }
            if (primerContent = "") {
                MsgBox("Please enter content for the primer.", "Missing Content", 48)
                return
            }
            
            ; Convert spaces to underscores and ensure lowercase
            fileName := StrReplace(StrLower(primerName), " ", "_")
            filePath := A_ScriptDir . "\core\converse\options\primers\" . fileName . ".txt"
            
            ; Check if file already exists
            if FileExist(filePath) {
                MsgBox("A primer with this name already exists. Please choose a different name.", "Name Taken", 48)
                return
            }
            
            ; Save the new primer
            try {
                FileAppend(primerContent, filePath)
                
                ; Refresh the dropdown list
                primerFiles := []
                primerDisplayNames := []
                Loop Files, A_ScriptDir . "\core\converse\options\primers\*.txt" {
                    primerName := StrReplace(A_LoopFileName, ".txt")
                    primerFiles.Push(primerName)
                    displayName := StrReplace(primerName, "_", " ")
                    displayName := Format("{:T}", displayName)
                    primerDisplayNames.Push(displayName)
                }
                
                ; Update dropdown and select new primer
                primerDropdown.Delete()
                primerDropdown.Add(primerDisplayNames)
                for index, name in primerFiles {
                    if (name = fileName) {
                        primerDropdown.Choose(index)
                        break
                    }
                }
                
                newPrimerGui.Destroy()
                MsgBox("New primer created successfully!", "Success")
            } catch as err {
                MsgBox("Error creating primer: " . err.Message, "Error", 16)
            }
        }
    }
}


