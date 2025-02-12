#Requires AutoHotkey v2.0
#SingleInstance
;Spout: Synergistic Plugins Optimizing Usability of Transformers

#Include "./core/reduce/script.ahk"
#Include "./core/search/script.ahk"
#Include "./core/enhance/script.ahk"
#Include "./core/expand/script.ahk"
#Include "./core/mutate/script.ahk"
#Include "./core/translate/script.ahk"
#Include "./core/generate/script.ahk"
#Include "./core/iterate/script.ahk"
#Include "./core/converse/script.ahk"
#Include "./core/evaluate/script.ahk"
#Include "./core/imagine/script.ahk"
#Include "./core/parse/script.ahk"
#Include "./shared/Includes.ahk"

;make sure this script is not run directly
if (A_ScriptFullPath = A_LineFile) {
    MsgBox("Please import this file in your customized hotkey script using:`n#Include SpoutMain.ahk", "Spout - Include Only", "Icon!")
    ExitApp
}

; Note to users: Include this file in your main AHK script using:
; #Include SpoutCoreScript.ahk
; Then set your preferred key combinations to launch the functions in this library.
; For example:
; ^!c::SpoutClipboardMngr()  ; Ctrl+Alt+C to display clipboard contents
; #l::CheckLockState()     ; Win+L to check lock states

; Set the try Icon for Spout
TraySetIcon("./shared/favicon.ico")
A_IconTip := "Spout: "

; Define the path to the INI file
global settingsFile := A_ScriptDir . "\config\settings.ini"

; Define the path to the models INI file
global modelsFile := A_ScriptDir . "\config\models.ini"

; Define the path to the themes INI file
global themesFile := A_ScriptDir . "\config\themes.ini"

global soundEffects := ReadSetting("General", "SoundEffects", "1")

; Global variables for the tea timer
global timerRunning := false
global endTime := 0
global timerGui := ""
global timerText := ""

global processHandle := 0

;global variables for Tally
global tempTally := 0
global incrementValue := 1
global SpoutGui := ""

global chatHistory := ""


; Function to load available models based on API keys
LoadAvailableModels() {
    models := ["No models available - Enter API key(s)"]  ; Default entry when no keys are valid
    hasValidKey := false
    
    ; Check OpenAI models - only require API key, org ID is optional
    if (StrLen(IniRead(settingsFile, "OpenAI", "ApiKey", "")) > 12) {
        try {
            section := IniRead(modelsFile, "OpenAI")
            Loop Parse, section, "`n", "`r" {
                parts := StrSplit(A_LoopField, "=")
                if (parts[2] = "1") {
                    if (models[1] = "No models available - Enter API key(s)") {
                        models := [] ; Clear default message if we find valid models
                    }
                    models.Push(parts[1])
                    hasValidKey := true
                }
            }
        }
    }
    
    ; Check Meta models  
    if (StrLen(IniRead(settingsFile, "Replicate", "ApiKey", "")) > 12) {
        try {
            section := IniRead(modelsFile, "Replicate")
            Loop Parse, section, "`n", "`r" {
                parts := StrSplit(A_LoopField, "=")
                if (parts[2] = "1") {
                    if (models[1] = "No models available - Enter API key(s)") {
                        models := [] ; Clear default message if we find valid models
                    }
                    models.Push(parts[1])
                    hasValidKey := true
                }
            }
        }
    }
    
    ; Check Google models
    if (StrLen(IniRead(settingsFile, "Google", "ApiKey", "")) > 12) {
        try {
            section := IniRead(modelsFile, "Google")
            Loop Parse, section, "`n", "`r" {
                parts := StrSplit(A_LoopField, "=")
                if (parts[2] = "1") {
                    if (models[1] = "No models available - Enter API key(s)") {
                        models := [] ; Clear default message if we find valid models
                    }
                    models.Push(parts[1])
                    hasValidKey := true
                }
            }
        }
    }
    
    ; Check Anthropic models
    if (StrLen(IniRead(settingsFile, "Anthropic", "ApiKey", "")) > 12) {
        try {
            section := IniRead(modelsFile, "Anthropic")
            Loop Parse, section, "`n", "`r" {
                parts := StrSplit(A_LoopField, "=")
                if (parts[2] = "1") {
                    if (models[1] = "No models available - Enter API key(s)") {
                        models := [] ; Clear default message if we find valid models
                    }
                    models.Push(parts[1])
                    hasValidKey := true
                }
            }
        }
    }

    ; Check DeepSeek models
    if (StrLen(IniRead(settingsFile, "DeepSeek", "ApiKey", "")) > 12) {
        try {
            section := IniRead(modelsFile, "DeepSeek")
            Loop Parse, section, "`n", "`r" {
                parts := StrSplit(A_LoopField, "=")
                if (parts[2] = "1") {
                    if (models[1] = "No models available - Enter API key(s)") {
                        models := [] ; Clear default message if we find valid models
                    }
                    models.Push(parts[1])
                    hasValidKey := true
                }
            }
        }
    }

    return models
}

; Replace the static modelOptions with dynamic loading
global modelOptions := LoadAvailableModels()


; Function to cycle through model options and set preferred model
SpoutModel(model := '') {
    global modelOptions
    
    if (model != '' && HasVal(modelOptions, model)) {
        ; If valid model provided, set it directly
        WriteSetting("General", "PreferredModel", model)
        ToolTip("Model set to: " . model)
    } else {
        ; Otherwise cycle through models
        currentModel := ReadSetting("General", "PreferredModel", "gpt-4o-mini")
        
        ; Find current index in modelOptions
        currentIndex := 1
        for index, mdl in modelOptions {
            if (mdl = currentModel) {
                currentIndex := index
                break
            }
        }
        
        ; Determine direction and get next model
        if (model = "back" || model = "b") {
            ; Go backwards (loop to end if at start)
            nextIndex := currentIndex = 1 ? modelOptions.Length : currentIndex - 1
        } else {
            ; Go forwards (loop to start if at end) 
            nextIndex := currentIndex = modelOptions.Length ? 1 : currentIndex + 1
        }
        nextModel := modelOptions[nextIndex]
        
        ; Save new default model
        WriteSetting("General", "PreferredModel", nextModel)
        
        ; Show tooltip with new model name
        ToolTip("Model set to: " . nextModel)
    }
    
    SetTimer () => ToolTip(), -2000  ; Hide tooltip after 2 seconds
}


; Array to hold function metadata
global Functions

if !IsSet(Functions) {
    Functions := []
}

; Add all functions in this file to the Functions array
Functions.Push(

    {Name: "Reduce", Description: "Reduces the clipboard content using a Python script", FuncObj: SpoutReduce},
    {Name: "Search", Description: "Displays browser-related information based on clipboard content", FuncObj: SpoutSearch},
    {Name: "Enhance", Description: "Enhances the clipboard content using AI", FuncObj: SpoutEnhance},
    {Name: "Expand", Description: "Expands the clipboard content using AI", FuncObj: SpoutExpand},
    {Name: "Mutate", Description: "Mutates the clipboard content using AI", FuncObj: SpoutMutate},
    {Name: "Generate", Description: "Generate multiple items based on example or description using AI", FuncObj: SpoutGenerate},
    {Name: "Iterate", Description: "Iteratively modify multiple lines of a file", FuncObj: SpoutIterate},
    {Name: "Converse", Description: "Send clipboard content to multi-llm chat dialog", FuncObj: SpoutConverse},
    {Name: "Translate", Description: "Translate clipboard content to voice of choice", FuncObj: SpoutTranslate},
    {Name: "Imagine", Description: "Generate a step-by-step plan based on an objective", FuncObj: SpoutImagine},
    {Name: "Evaluate", Description: "Evaluate and compare multiple inputs based on criteria", FuncObj: SpoutEvaluate},
    {Name: "Parse", Description: "Parse and structure clipboard content", FuncObj: SpoutParse},

)

; Function to save window position
SaveGuiPosition(hwnd) {
    WinGetPos(&x, &y, , , "ahk_id " hwnd)
    WriteSetting("General", "LastX", x)
    WriteSetting("General", "LastY", y)
}

; Function to get saved position 
GetGuiPosition() {
    x := ReadSetting("General", "LastX", "center")
    y := ReadSetting("General", "LastY", "center")
    return { x: x, y: y }
}


CenterGui() {
    WriteSetting("General", "LastX", "center")
    WriteSetting("General", "LastY", "center")
}

; Function to get the current color scheme
GetCurrentColorScheme() {
    currentTheme := ReadSetting("General", "Theme", "Light")
    
    ; Read theme colors from INI file
    try {
        return {
            Background: IniRead(themesFile, currentTheme, "Background", "FFFFFF"),
            Text: IniRead(themesFile, currentTheme, "Text", "000000"),
            EditBackground: IniRead(themesFile, currentTheme, "EditBackground", "EEEEEE")
        }
    } catch Error as e {
        ; Return default light theme if there's an error
        return {
            Background: "FFFFFF",
            Text: "000000",
            EditBackground: "EEEEEE"
        }
    }
}

resetGui() {

    global SpoutGui
    try {
        SaveGuiPosition(SpoutGui.Hwnd)
    } catch Error as e {
        ; Continue even if saving position fails
    }
    try {
        Hotkey("Enter", "Off")
    }
    Sleep(75)
    try {
        SpoutGui.Destroy()
    }
    SpoutGui := ""
}

SpoutReload() {
    ToolTip("Restarting Spout...")
    SetTimer () => ToolTip(), -1000
    CenterGui()
    Sleep(1000)
    Reload
    Sleep(1000) ; Give time for reload to complete
    MsgBox("Failed to reload script. Please check for errors and try again.", "Reload Failed", "Icon!")
}

HasVal(collection, targetValue) {
    for index, element in collection {
        if (element == targetValue)
            return index
    }
    if (!IsObject(collection))
        return 0
    return 0  
}


if (!FileExist(settingsFile)) {
    FileAppend("", settingsFile, "UTF-8")
}

ReadSetting(section, key, defaultValue := "") {
    return IniRead(settingsFile, section, key, defaultValue)
}

; Function to write a setting to the INI file in UTF-8 encoding without BOM
WriteSetting(section, key, value) {
    try {
        IniWrite(value, settingsFile, section, key)
    } catch as err {
        MsgBox("Error writing setting: " . err.Message)
    }
}

; Function to read a setting and initialize with default if not found
ReadOrInitializeSetting(section, key, defaultValue := "") {
    value := IniRead(settingsFile, section, key, "")
    if (value == "") {
        WriteSetting(section, key, defaultValue)
        return defaultValue
    }
    return value
}

; Example usage with default initialization
theme := ReadOrInitializeSetting("General", "Theme", "Light")
browserLocation := ReadOrInitializeSetting("General", "BrowserLocation", "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe")
qwiknotesPath := ReadOrInitializeSetting("General", "NotesFolder", A_ScriptDir . "\..\notes")
preferredModel := ReadOrInitializeSetting("General", "PreferredModel", "gpt-4o-mini")
tokenCountModel := ReadOrInitializeSetting("General", "TokenCountModel", "gpt-3.5-turbo")
OpenAIorgId := ReadOrInitializeSetting("OpenAI", "OrgId", "*********")
OpenAIApiKey := ReadOrInitializeSetting("OpenAI", "ApiKey", "*********")
ReplicateApiKey := ReadOrInitializeSetting("Replicate", "ApiKey", "*********")
GoogleApiKey := ReadOrInitializeSetting("Google", "ApiKey", "********")
AnthropicApiKey := ReadOrInitializeSetting("Anthropic", "ApiKey", "********")

; Initialize core module Spoutlet settings
reduceSpoutlet := ReadOrInitializeSetting("Reduce", "PreferredSpoutlet", "default")
searchSpoutlet := ReadOrInitializeSetting("Search", "PreferredSpoutlet", "default") 
enhanceSpoutlet := ReadOrInitializeSetting("Enhance", "PreferredSpoutlet", "default")
expandSpoutlet := ReadOrInitializeSetting("Expand", "PreferredSpoutlet", "default")
mutateSpoutlet := ReadOrInitializeSetting("Mutate", "PreferredSpoutlet", "default")
translateSpoutlet := ReadOrInitializeSetting("Translate", "PreferredSpoutlet", "default")
generateSpoutlet := ReadOrInitializeSetting("Generate", "PreferredSpoutlet", "default")
iterateSpoutlet := ReadOrInitializeSetting("Iterate", "PreferredSpoutlet", "default")
converseSpoutlet := ReadOrInitializeSetting("Converse", "PreferredSpoutlet", "default")
evaluateSpoutlet := ReadOrInitializeSetting("Evaluate", "PreferredSpoutlet", "default")
imagineSpoutlet := ReadOrInitializeSetting("Imagine", "PreferredSpoutlet", "default")
parseSpoutlet := ReadOrInitializeSetting("Parse", "PreferredSpoutlet", "default")



; Function: Opens a GUI for modifying settings
SpoutSettings() {
    ; Create GUI
    global SpoutGui
    global modelOptions
    global soundEffects
    resetGui()
    colorScheme := GetCurrentColorScheme()
    SpoutGui := Gui("+ToolWindow", "Spout Settings")
    SpoutGui.SetFont("s10", "Arial")
    SpoutGui.BackColor := colorScheme.Background

    ; Notes Folder (adjusted y-position since we removed SpoutPro section)
    SpoutGui.Add("Text", "x10 y10 w100 c" . colorScheme.Text, "Notes Folder:")
    qwiknotesEdit := SpoutGui.Add("Edit", "x170 y10 w350 h20 vNotesFolder c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ReadSetting("General", "NotesFolder", A_MyDocuments . "\Notes"))
    SpoutGui.Add("Button", "x530 y10 w80", "Browse").OnEvent("Click", (*) => BrowseQwiknotes(qwiknotesEdit))

    ; Browser Location (adjusted subsequent y-positions)
    SpoutGui.Add("Text", "x10 y40 w100 c" . colorScheme.Text, "Default Browser:")
    browserEdit := SpoutGui.Add("Edit", "x170 y40 w350 h20 vBrowserLocation c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ReadSetting("General", "BrowserLocation", "C:\")) 
    SpoutGui.Add("Button", "x530 y40 w80", "Browse").OnEvent("Click", (*) => BrowseBrowser(browserEdit))

    ; OpenAI API Key (adjusted y-position to add more space)
    SpoutGui.Add("Text", "x10 y70 w100 c" . colorScheme.Text, "OpenAI Key:")
    apiKeyEdit := SpoutGui.Add("Edit", "x170 y70 w450 vOpenAIApiKey c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ReadSetting("OpenAI", "ApiKey"))

    ; Organization ID
    SpoutGui.Add("Text", "x10 y100 w100 c" . colorScheme.Text, "OpenAI Org ID:")
    orgIdEdit := SpoutGui.Add("Edit", "x170 y100 w450 vOpenAIOrgId c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ReadSetting("OpenAI", "OrgId"))

    ; Replicate API Key
    SpoutGui.Add("Text", "x10 y130 w130 c" . colorScheme.Text, "Replicate API Key:")
    replicateKeyEdit := SpoutGui.Add("Edit", "x170 y130 w450 vReplicateApiKey c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ReadSetting("Replicate", "ApiKey"))

    ; Google API Key
    SpoutGui.Add("Text", "x10 y160 w130 c" . colorScheme.Text, "Google API Key:")
    googleKeyEdit := SpoutGui.Add("Edit", "x170 y160 w450 vGoogleApiKey c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ReadSetting("Google", "ApiKey"))

    ; Anthropic API Key
    SpoutGui.Add("Text", "x10 y190 w130 c" . colorScheme.Text, "Anthropic API Key:")
    anthropicKeyEdit := SpoutGui.Add("Edit", "x170 y190 w450 h20 vAnthropicApiKey c" . colorScheme.Text . " Background" . colorScheme.EditBackground . " -Wrap", ReadSetting("Anthropic", "ApiKey"))

    ; DeepSeek API Key
    SpoutGui.Add("Text", "x10 y220 w150 c" . colorScheme.Text, "DeepSeek API Key:")
    deepseekApiKeyEdit := SpoutGui.Add("Edit", "x170 y220 w450 vDeepSeekApiKey c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ReadSetting("DeepSeek", "ApiKey", "*********"))

    ; Preferred Model
    SpoutGui.Add("Text", "x10 y250 w100 c" . colorScheme.Text, "Preferred Model:")
    modelDropdown := SpoutGui.Add("DropDownList", "x170 y250 w450 vPreferredModel c" . colorScheme.Text . " Background" . colorScheme.EditBackground, modelOptions)
    if (modelOptions[1] != "No models available - Enter API key(s)") {
        currentModel := ReadSetting("General", "PreferredModel", modelOptions[1])
        if (HasVal(modelOptions, currentModel)) {
            modelDropdown.Choose(currentModel)
        } else {
            modelDropdown.Choose(1)
        }
    } else {
        modelDropdown.Choose(1)
    }

    ; Token Count Model
    SpoutGui.Add("Text", "x10 y280 w130 c" . colorScheme.Text, "Token Count Model:")
    tokenCountOptions := ["gpt-3.5-turbo", "gpt-4o", "text-davinci-003", "curie", "gpt-2"]
    tokenCountDropdown := SpoutGui.Add("DropDownList", "x170 y280 w450 vTokenCountModel c" . colorScheme.Text . " Background" . colorScheme.EditBackground, tokenCountOptions)
    tokenCountDropdown.Choose(ReadSetting("General", "TokenCountModel", "gpt-3.5-turbo"))

    ; Theme and Sound Effects on same line
    yPos := 310
    SpoutGui.Add("Text", "x10 y" . yPos . " w100 c" . colorScheme.Text, "Color Theme:")
    
    ; Get theme names from INI file
    themeList := []
    try {
        sections := IniRead(themesFile)
        Loop Parse, sections, "`n", "`r" {
            themeList.Push(A_LoopField)
        }
    } catch Error as e {
        themeList := ["Light", "Dark"]  ; Fallback themes if INI read fails
    }

    themeDropdown := SpoutGui.Add("DropDownList", "x170 y" . yPos . " w200 vTheme c" . colorScheme.Text . " Background" . colorScheme.EditBackground, themeList)
    themeDropdown.Choose(ReadSetting("General", "Theme", "Light"))
    themeDropdown.OnEvent("Change", (*) => ReloadSettingsGui(SpoutGui))
    
    ; Sound Effects aligned with theme dropdown
    SpoutGui.Add("Text", "x405 y" . yPos . " w100 c" . colorScheme.Text, "Sound Effects:")
    soundEffectsCheckbox := SpoutGui.Add("Checkbox", "x500 y" . yPos . " w120 vSoundEffects c" . colorScheme.Text, "Enable")
    soundEffectsCheckbox.Value := ReadSetting("General", "SoundEffects", "1")

    ; Core Module Spoutlet Settings - Compact Grid Layout
    yPos += 30

    modules := ["Reduce", "Search", "Enhance", "Expand", "Mutate", "Translate", 
                "Generate", "Iterate", "Converse", "Evaluate", "Imagine", "Parse"]
    
    ; Create a grid layout with 3 columns
    colWidth := 200
    rowHeight := 30
    for index, module in modules {
        col := Mod(index - 1, 3)
        row := Floor((index - 1) / 3)
        xPos := 10 + (col * colWidth)
        currentY := yPos + (row * rowHeight)

        SpoutGui.Add("Text", "x" . xPos . " y" . currentY . " w70 c" . colorScheme.Text, module . ":")
        
        ; Initialize spoutlet options array with default
        spoutletOptions := ["default"]
        
        ; Define plugin folder paths
        pluginFolders := [
            A_ScriptDir . "\core\" . StrLower(module) . "\" . StrLower(module) . "_plugins\*",
            A_ScriptDir . "\core\" . StrLower(module) . "\" . StrLower(module) . "_local\*",
            A_ScriptDir . "\core\" . StrLower(module) . "\" . StrLower(module) . "_pro\*"
        ]
        
        ; Loop through each plugin folder
        for folderPath in pluginFolders {
            Loop Files, folderPath, "D" {
                if (SubStr(A_LoopFileName, 1) != "default")
                    spoutletOptions.Push(SubStr(A_LoopFileName, 1))
            }
        }
        
        spoutletDropdown := SpoutGui.Add("DropDownList", "x" . (xPos + 75) . " y" . currentY . " w120 v" . module . "Spoutlet c" . colorScheme.Text . " Background" . colorScheme.EditBackground, spoutletOptions)
        spoutletDropdown.Choose(ReadSetting(module, "PreferredSpoutlet", "default"))
    }

    yPos += 120 ; Adjust based on grid height (4 rows * 30 pixels)

    ; Buttons - Centered with more visibility
    yPos += 10 ; Reduced spacing
    buttonWidth := 130
    buttonSpacing := 15
    totalButtonWidth := (buttonWidth * 3) + (buttonSpacing * 2)
    startX := (620 - totalButtonWidth) / 2 ; Center the button group

    ; Set a darker text color for buttons
    buttonTextColor := (colorScheme.Text = "Black") ? "000000" : "202020"
    
    SpoutGui.SetFont("s13", "Arial") ; Less bold font for buttons
    SpoutGui.Add("Button", "x" . startX . " y" . yPos . " w" . buttonWidth . " h40 c" . buttonTextColor . " Background" . colorScheme.EditBackground, "Save").OnEvent("Click", (*) => SaveSettings(SpoutGui))
    SpoutGui.Add("Button", "x" . (startX + buttonWidth + buttonSpacing) . " y" . yPos . " w" . buttonWidth . " h40 c" . buttonTextColor . " Background" . colorScheme.EditBackground, "Cancel").OnEvent("Click", (*) => SpoutGui.Destroy())
    SpoutGui.Add("Button", "x" . (startX + (buttonWidth + buttonSpacing) * 2) . " y" . yPos . " w" . buttonWidth . " h40 c" . buttonTextColor . " Background" . colorScheme.EditBackground, "Add to Startup").OnEvent("Click", (*) => SetStartupScript())
    SpoutGui.SetFont("s10", "Arial") ; Reset font for rest of GUI

    SpoutGui.OnEvent("Escape", (*) => exit())
    SpoutGui.OnEvent("Close", (*) => exit())

    exit(*) {
        try {
            SaveGuiPosition(SpoutGui.Hwnd)
        } catch Error as e {
            ; Continue even if saving position fails
        }
        Sleep(100)
        SpoutGui.Destroy()
        SpoutGui := ""
    }

    ; Get saved position
    pos := GetGuiPosition()
    if (pos.x = "center") {
        SpoutGui.Show("w630")  ; Default centered position with width
    } else {
        SpoutGui.Show("x" pos.x " y" pos.y " w630")  ; Saved position with width
    }

    BrowseBrowser(control) {
        selectedFile := FileSelect("3", , "Select Browser Executable", "Executables (*.exe)")
        if (selectedFile != "") {
            control.Value := selectedFile
        }
    }
    BrowseQwiknotes(control) {
        selectedFolder := DirSelect(, 3, "Select Notes Folder Location")
        if (selectedFolder != "") {
            control.Value := selectedFolder
        }
    }
    ValidateApiKey(key, type) {
        if (key = "*********" || key = "")
            return true

        switch type {
            case "OpenAI":
                return RegExMatch(key, "^sk-[A-Za-z0-9-_]{30,}$")
            case "Replicate": 
                return RegExMatch(key, "^r8_[A-Za-z0-9-_]{30,}$") 
            case "Google":
                return RegExMatch(key, "^AIza[A-Za-z0-9_-]{20,}$")
            case "Anthropic":
                return RegExMatch(key, "^sk-[A-Za-z0-9-_]{20,}|.*-ant-[A-Za-z0-9-_]{20,}$")
            case "DeepSeek":
                return RegExMatch(key, "^sk-[A-Za-z0-9]{32}$")
        }
        return false
    }

    SaveSettings(gui) {
        try {
            SaveGuiPosition(gui.Hwnd)
        } catch Error as e {
            ; Continue even if saving position fails
        }
        savedValues := gui.Submit()
        WriteSetting("General", "Theme", savedValues.Theme)
        WriteSetting("General", "BrowserLocation", savedValues.BrowserLocation)
        WriteSetting("General", "NotesFolder", savedValues.NotesFolder)
        WriteSetting("General", "PreferredModel", savedValues.PreferredModel)
        WriteSetting("OpenAI", "OrgId", savedValues.OpenAIOrgId)
        WriteSetting("General", "TokenCountModel", savedValues.TokenCountModel)
        WriteSetting("General", "SoundEffects", savedValues.SoundEffects)


        ; Validate API keys
        invalidKeys := []

        ; OpenAI
        if (!ValidateApiKey(savedValues.OpenAIApiKey, "OpenAI")) {
            invalidKeys.Push("OpenAI")
            WriteSetting("OpenAI", "ApiKey", "*********")
        } else {
            WriteSetting("OpenAI", "ApiKey", savedValues.OpenAIApiKey)
        }

        ; Replicate
        if (!ValidateApiKey(savedValues.ReplicateApiKey, "Replicate")) {
            invalidKeys.Push("Replicate")
            WriteSetting("Replicate", "ApiKey", "*********")
        } else {
            WriteSetting("Replicate", "ApiKey", savedValues.ReplicateApiKey)
        }

        ; Google
        if (!ValidateApiKey(savedValues.GoogleApiKey, "Google")) {
            invalidKeys.Push("Google")
            WriteSetting("Google", "ApiKey", "*********")
        } else {
            WriteSetting("Google", "ApiKey", savedValues.GoogleApiKey)
        }

        ; Anthropic
        if (!ValidateApiKey(savedValues.AnthropicApiKey, "Anthropic")) {
            invalidKeys.Push("Anthropic")
            WriteSetting("Anthropic", "ApiKey", "*********")
        } else {
            WriteSetting("Anthropic", "ApiKey", savedValues.AnthropicApiKey)
        }

        ; DeepSeek
        if (!ValidateApiKey(savedValues.DeepSeekApiKey, "DeepSeek")) {
            invalidKeys.Push("DeepSeek")
            WriteSetting("DeepSeek", "ApiKey", "*********")
        } else {
            WriteSetting("DeepSeek", "ApiKey", savedValues.DeepSeekApiKey)
        }
        
        ; Save core module spoutlet settings
        for module in ["Reduce", "Search", "Enhance", "Expand", "Mutate", "Translate", 
                      "Generate", "Iterate", "Converse", "Evaluate", "Imagine", "Parse"] {
            WriteSetting(module, "PreferredSpoutlet", savedValues.%module%Spoutlet)
        }
        
        soundEffects := savedValues.SoundEffects

        ; Show message if any keys were invalid
        if (invalidKeys.Length > 0) {
            MsgBox("The following API keys were invalid and have been reset:`n`n" . 
                   StrReplace(StrJoin(invalidKeys, ", "), ",", "`n"), "Invalid API Keys")
        }
        exit()

    }

    ReloadSettingsGui(gui) {
        savedValues := gui.Submit()
        WriteSetting("General", "Theme", savedValues.Theme)
        Sleep(100)  ; Wait a short moment for the setting to be written
        SpoutGui.Destroy()
        SetTimer(() => SpoutSettings(), -200)  ; Schedule SpoutSettings to run after a slight delay
    }
}
; Check if the OpenAI API key is less than 12 characters
if (modelOptions.Length < 1 || modelOptions[1] = "No models available - Enter API key(s)") {
    MsgBox("Please provide at least one valid API key in Settings to enable language model services.")
    SpoutSettings()
} else {
    ; Initialize core module Spoutlet settings
    reduceSpoutlet := ReadOrInitializeSetting("Reduce", "PreferredSpoutlet", "default")
    searchSpoutlet := ReadOrInitializeSetting("Search", "PreferredSpoutlet", "default") 
    enhanceSpoutlet := ReadOrInitializeSetting("Enhance", "PreferredSpoutlet", "default")
    expandSpoutlet := ReadOrInitializeSetting("Expand", "PreferredSpoutlet", "default")
    mutateSpoutlet := ReadOrInitializeSetting("Mutate", "PreferredSpoutlet", "default")
    translateSpoutlet := ReadOrInitializeSetting("Translate", "PreferredSpoutlet", "default")
    generateSpoutlet := ReadOrInitializeSetting("Generate", "PreferredSpoutlet", "default")
    iterateSpoutlet := ReadOrInitializeSetting("Iterate", "PreferredSpoutlet", "default")
    converseSpoutlet := ReadOrInitializeSetting("Converse", "PreferredSpoutlet", "default")
    evaluateSpoutlet := ReadOrInitializeSetting("Evaluate", "PreferredSpoutlet", "default")
    imagineSpoutlet := ReadOrInitializeSetting("Imagine", "PreferredSpoutlet", "default")
    parseSpoutlet := ReadOrInitializeSetting("Parse", "PreferredSpoutlet", "default")
}

; Function to create and populate the context menu
SpoutContextMenu() {
    colorScheme := GetCurrentColorScheme()
    contextMenu := Menu()
    capsLockState := GetKeyState("CapsLock", "T") ? "ON" : "OFF"
    scrollLockState := GetKeyState("ScrollLock", "T") ? "ON" : "OFF"
    numLockState := GetKeyState("NumLock", "T") ? "ON" : "OFF"
    ; Add menu items
    
    ; Create a submenu for AI-related options
    aiSubmenu := Menu()

    aiSubmenu.Add("Reduce Selection", ReduceSelection)
    aiSubmenu.Add("Expand Selection", ExpandSelection)
    aiSubmenu.Add("Enhance Selection", EnhanceSelection)
    aiSubmenu.Add("Mutate Selection", MutateSelection)
    aiSubmenu.Add("Find References", FindLinks)
    aiSubmenu.Add("Translate Selection", SpoutTranslate)
    aiSubmenu.Add("Imagine Selection", ImagineSelection)
    aiSubmenu.Add("Evaluate Selection", EvaluateSelection)
    aiSubmenu.Add("Parse Selection", ParseSelection)    
    ; Add the AI submenu to the main context menu
    contextMenu.Add("GUI Functions", aiSubmenu)
    nuiSubmenu := Menu()
    nuiSubmenu.Add("Reduce Selection", SpoutGist)
    nuiSubmenu.Add("Enhance Selection", SpoutMend)
    nuiSubmenu.Add("Expand Selection", SpoutGrow)
    nuiSubmenu.Add("Legalese Selection", SpoutLegalese)
    contextMenu.Add("NUI Functions", nuiSubmenu)

    ; Create a submenu for text conversion options
    textConversionSubmenu := Menu()
    textConversionSubmenu.Add("Convert to All Caps", ConvertToAllCaps)
    textConversionSubmenu.Add("Convert to Lower Case", ConvertToLowerCase)
    textConversionSubmenu.Add("Convert to Sentence Case", ConvertToSentenceCase)
    textConversionSubmenu.Add("Convert to Studly Caps", ConvertToStudlyCaps)
    textConversionSubmenu.Add("Reverse Text", ReverseText)    
    
    ; Add the text conversion submenu to the main context menu
    contextMenu.Add("Text Conversion", textConversionSubmenu)

    ; Add remaining items to the main context menu
    contextMenu.Add("Send to Quick Note", SentSelectionToSpoutNoter)
    contextMenu.Add("Manage Selection", ShowClipboardManager)
    contextMenu.Add("Open Settings", ShowSettings)
    contextMenu.Add("Count Tokens", CountTokensSelection)
    contextMenu.Add("Append Copy", AppendCopy)
    contextMenu.Add("Append Cut", AppendCut)
    contextMenu.Add()  ; Add a separator
    contextMenu.Add("Toggle Caps Lock (→" . capsLockState . ")", ToggleCapsLock)
    contextMenu.Add("Toggle Scroll Lock (→" . scrollLockState . ")", ToggleScrollLock)
    contextMenu.Add("Toggle Num Lock (→" . numLockState . ")", ToggleNumLock)

    return contextMenu
}


SpoutLegalese(*) {
    SpoutCast("Legalese")
}

ToggleCapsLock(*) {
    SetCapsLockState(!GetKeyState("CapsLock", "T"))
    ToolTip("CapsLock " . (GetKeyState("CapsLock", "T") ? "ON" : "OFF"))
    SetTimer () => ToolTip(), -1000

}

; Hotkey: Ctrl + CapsLock (vkC1)
; Function: Toggles NumLock state and displays a tooltip
ToggleNumLock(*) {
    SetNumLockState(!GetKeyState("NumLock", "T"))
    ToolTip("NumLock " . (GetKeyState("NumLock", "T") ? "ON" : "OFF"))
    SetTimer () => ToolTip(), -1000
}

; Hotkey: Alt + CapsLock (vkC1)
; Function: Toggles ScrollLock state and displays a tooltip
ToggleScrollLock(*) {
    SetScrollLockState(!GetKeyState("ScrollLock", "T"))
    ToolTip("ScrollLock " . (GetKeyState("ScrollLock", "T") ? "ON" : "OFF"))
    SetTimer () => ToolTip(), -1000
}

CountTokensSelection(*) {
    originalClipboard := ClipboardAll()
    Send("^c")  ; Copy selected text
    Sleep 50  ; Wait for clipboard to update
    Run("pythonw.exe " . A_ScriptDir . "\shared\token_count.pyw `"" . A_Clipboard . "`"")
    A_Clipboard := originalClipboard
}

SentSelectionToSpoutNoter(*) {
    original := ClipboardAll()
    Send("^c")  ; Copy selected text
    Sleep 50  ; Wait for clipboard to update
    SpoutNoter(A_Clipboard)
    Sleep 50
    A_Clipboard := original
}

FindLinks(*) {
    original := ClipboardAll()
    Send("^c")  ; Copy selected text
    Sleep 50  ; Wait for clipboard to update
    SpoutSearch()
    A_Clipboard := original
}

ReduceSelection(*) {
    original := ClipboardAll()
    Send("^c")  ; Copy selected text
    Sleep 50  ; Wait for clipboard to update
    SpoutReduce(auto := true, text := A_Clipboard)
    A_Clipboard := original
}

ExpandSelection(*) {
    original := ClipboardAll()
    Send("^c")  ; Copy selected text
    Sleep 50  ; Wait for clipboard to update
    SpoutExpand(auto := true, text := A_Clipboard)
    A_Clipboard := original
}

ParseSelection(*) {
    original := ClipboardAll()
    Send("^c")  ; Copy selected text
    Sleep 50  ; Wait for clipboard to update
    SpoutParse()
    A_Clipboard := original
}

EvaluateSelection(*) {
    original := ClipboardAll()
    Send("^c")  ; Copy selected text
    Sleep 50  ; Wait for clipboard to update
    SpoutEvaluate()
    A_Clipboard := original
}

ImagineSelection(*) {
    original := ClipboardAll()
    Send("^c")  ; Copy selected text
    Sleep 50  ; Wait for clipboard to update
    SpoutImagine()
    A_Clipboard := original
}

ShowClipboardManager(*) {
    original := ClipboardAll()
    Send("^c")  ; Copy selected text
    Sleep 50  ; Wait for clipboard to update
    SpoutClipboard()
    A_Clipboard := original
}

ShowSettings(*) {
    SpoutSettings()
}

EnhanceSelection(*) {
    original := ClipboardAll()
    Send("^c")  ; Copy selected text
    Sleep 50  ; Wait for clipboard to update
    SpoutEnhance(auto := true, text := A_Clipboard)
    A_Clipboard := original
}

MutateSelection(*) {
    original := ClipboardAll()
    Send("^c")  ; Copy selected text
    Sleep 50  ; Wait for clipboard to update
    SpoutMutate()
    A_Clipboard := original
}


ConvertToSentenceCase(*) {
    ; Save the original clipboard content
    originalClipboard := ClipboardAll()
    Send("^c")  ; Copy selected text
    Sleep 50  ; Wait for clipboard to update
    text := A_Clipboard

    ; Convert text to sentence case
    sentenceCase := ""
    capitalizeNext := true
    for i, char in StrSplit(text) {
        if (capitalizeNext && IsAlpha(char)) {
            sentenceCase .= StrUpper(char)
            capitalizeNext := false
        } else {
            sentenceCase .= StrLower(char)
        }
        if (char == "." || char == "!" || char == "?") {
            capitalizeNext := true
        }
    }

    ; Replace the selected text with the sentence case version
    A_Clipboard := sentenceCase
    Send("^v")
    ; Wait for a short period to ensure the clipboard operation is complete
    Sleep 100
    ; Restore the original clipboard content
    A_Clipboard := originalClipboard
}


ConvertToStudlyCaps(*) {
    ; Save the original clipboard content
    originalClipboard := ClipboardAll()
    Send("^c")  ; Copy selected text
    Sleep 50  ; Wait for clipboard to update
    text := A_Clipboard
    studlyCaps := ""
    capitalizeNext := true
    for i, char in StrSplit(text) {
        if (IsAlpha(char)) {
            studlyCaps .= capitalizeNext ? StrUpper(char) : StrLower(char)
            capitalizeNext := !capitalizeNext
        } else {
            studlyCaps .= char
            capitalizeNext := true
        }
    }

    ; Replace the selected text with the StudlyCaps version
    A_Clipboard := studlyCaps
    Send("^v")
    ; Wait for a short period to ensure the clipboard operation is complete
    Sleep 100
    ; Restore the original clipboard content
    A_Clipboard := originalClipboard
}

ConvertToAllCaps(*) {
    ; Save the original clipboard content
    originalClipboard := ClipboardAll()
    
    ; Copy selected text
    Send("^c")
    Sleep 50  ; Wait for clipboard to update
    
    ; Convert text to all caps
    text := A_Clipboard
    allCapsText := StrUpper(text)
    
    ; Replace the selected text with the all caps version
    A_Clipboard := allCapsText
    Send("^v")
    
    ; Wait for a short period to ensure the clipboard operation is complete
    Sleep 100
    
    ; Restore the original clipboard content
    A_Clipboard := originalClipboard
}

ConvertToLowerCase(*) {
    ; Save the original clipboard content
    originalClipboard := ClipboardAll()
    
    ; Copy selected text
    Send("^c")
    Sleep 50  ; Wait for clipboard to update
    
    ; Convert text to lower case
    text := A_Clipboard
    lowerCaseText := StrLower(text)
    
    ; Replace the selected text with the lower case version
    A_Clipboard := lowerCaseText
    Send("^v")
    
    ; Wait for a short period to ensure the clipboard operation is complete
    Sleep 100
    
    ; Restore the original clipboard content
    A_Clipboard := originalClipboard
}


ReverseText(*) {
    ; Save the original clipboard content
    originalClipboard := ClipboardAll()
    Send("^c")  ; Copy selected text
    Sleep 50  ; Wait for clipboard to update
    
    ; Reverse the clipboard content
    reversedText := ""
    text := A_Clipboard
    for i in StrSplit(text) {
        reversedText := i . reversedText
    }
    
    ; Replace the selected text with the reversed version
    A_Clipboard := reversedText
    Send("^v")
    ; Restore the original clipboard content
    A_Clipboard := originalClipboard
}


; Function to append copied content to clipboard
AppendCopy(*) {
    originalContent := A_Clipboard
    Send("^c")  ; Copy
    Sleep 100
    newContent := A_Clipboard
    appendedContent := originalContent . "`n" . newContent
    A_Clipboard := appendedContent
    ToolTip "copied and appended"
    SetTimer () => ToolTip(), -500
}

; Function to append cut content to clipboard
AppendCut(*) {
    originalContent := A_Clipboard
    Send("^x")  ; Cut
    Sleep 100
    newContent := A_Clipboard
    appendedContent := originalContent . "`n" . newContent
    A_Clipboard := appendedContent
    ToolTip "cut and appended"
    SetTimer () => ToolTip(), -500
}



CheckLockState()
{
    numLockState := GetKeyState("NumLock", "T")
    scrollLockState := GetKeyState("ScrollLock", "T")
    capsLockState := GetKeyState("CapsLock", "T")

    if (numLockState) {
        numLockStatus := "Num Lock is ON"
    } else {
        numLockStatus := "Num Lock is OFF"
    }

    if (scrollLockState) {
        scrollLockStatus := "Scroll Lock is ON"
    } else {
        scrollLockStatus := "Scroll Lock is OFF"
    }

    if (capsLockState) {
        capsLockStatus := "Caps Lock is ON"
    } else {
        capsLockStatus := "Caps Lock is OFF"
    }

    MsgBox(numLockStatus "`n" scrollLockStatus "`n" capsLockStatus)
}


; Function: Places or replaces a link to an AHK script in the Windows startup folder
SetStartupScript() {
    ; Get startup folder path
    startupFolder := A_Startup

    ; Look for existing .ahk shortcuts in startup folder
    Loop Files, startupFolder "\*.lnk" {
        FileGetShortcut(A_LoopFileFullPath, &target)
        if (InStr(target, ".ahk")) {
            result := MsgBox("An AutoHotkey script shortcut already exists in startup:`n" target "`n`nDo you want to remove it and add a new one?", "Startup Script", "YesNo")
            if (result = "Yes") {
                FileDelete(A_LoopFileFullPath)
            } else {
                return
            }
        }
    }

    ; Show file selection dialog
    selectedFile := FileSelect(3, A_ScriptDir, "Select AutoHotkey Script", "AutoHotkey Scripts (*.ahk)")
    if (selectedFile = "") {
        return  ; User cancelled
    }

    ; Create shortcut in startup folder
    shortcutPath := startupFolder "\" RegExReplace(selectedFile, ".*\\") ".lnk"
    FileCreateShortcut(selectedFile, shortcutPath)
    
    ; Show confirmation
    ToolTip("Startup script set to: " selectedFile)
    SetTimer () => ToolTip(), -2000
}




; Function: Displays the current clipboard content in a custom GUI
SpoutClipboard() {
    ; Create GUI
    global SpoutGui
    resetGui()
    clipboardContent := A_Clipboard  ; Store clipboard content in a local

    colorScheme := GetCurrentColorScheme()
    SpoutGui := Gui("+ToolWindow", "Spout Clipboard Manager")  
    SpoutGui.SetFont("s12", "Arial")
    SpoutGui.BackColor := colorScheme.Background
    
    displayContent := clipboardContent

    charCount := StrLen(clipboardContent)
    wordCount := 0
    if (StrLen(clipboardContent)) {
        for each, word in StrSplit(clipboardContent, " ") {
            wordCount++
        }
    }

    OnClipboardChange(ClipChanged)

    ClipChanged(*) {
        try {
            refreshButton.Enabled := true
        } catch {
            return
        }
    }
    
    ; Add label and refresh button on the same row
    SpoutGui.Add("Text", "c" . colorScheme.Text . " w220 h20", "Clipboard Contents:").SetFont("s15")
    
    refreshButton := SpoutGui.Add("Button", "x+10 w80 h30 vRefreshButton", "Refresh")
    countTokensButton := SpoutGui.Add("Button", "x+10 w100 h30", "Count Tokens")
    countTokensButton.OnEvent("Click", CountTokens)
    refreshButton.OnEvent("Click", RefreshContent)
    refreshButton.Enabled := false

    editContent := SpoutGui.Add("Edit", "xm c" . colorScheme.Text . " Background" . colorScheme.EditBackground . " w420 r18 vEditContent", displayContent)
    editContent.SetFont("s12", "Arial")

    

    RefreshContent(*) {
        SpoutGui["EditContent"].Value := A_Clipboard
        UpdateCountDisplay(countDisplay)
        refreshButton.Enabled := false
    }

    CountTokens(*) {
        Run("pythonw.exe shared/token_count.pyw `"" . SpoutGui["EditContent"].Value . "`"")
    }

    copyButton := SpoutGui.Add("Button", "h60 w80 y+10", "Copy")
    copyButton.Enabled := false
    copyButton.OnEvent("Click", (*) => (A_Clipboard := SpoutGui["EditContent"].Value, ToolTip("Changes copied to clipboard"), SetTimer(() => ToolTip(), -2000)))
    
    SpoutGui.Add("Button", "h60 w80 x+10", "Cancel").OnEvent("Click", (*) => exit())
    
    ; Create a function to update character and word count
    UpdateCountDisplay(guiCtrl) {
        try {
            text := SpoutGui["EditContent"].Value
            charCount := StrLen(text)
            wordCount := StrSplit(text, [" ", "`n"]).Length
            guiCtrl.Value := "Words: " . wordCount . " Chars: " . charCount
        }
    }

    ; Add the text control and store a reference to it
    countDisplay := SpoutGui.Add("Text", "c" . colorScheme.Text . " w240 x+10 yp", "Words: " . wordCount . " Chars: " . charCount)

    ; Add a DropDownList with functions from the Functions array
    functionNames := []
    for index, func in Functions {
        functionNames.Push(func.Name)
    }
    dropDown := SpoutGui.Add("DropDownList", "w220 x+10 y+10 xm+185 c" . colorScheme.Text . " Background" . colorScheme.EditBackground, ["Apply Lexical Functions:", functionNames*])
    dropDown.Choose(1)  ; Select the default "Run Function" option
    dropDown.OnEvent("Change", OnDropDownChange)

    OnDropDownChange(*) {
        selectedIndex := dropDown.Value
        ; Remove the OnClipboardChange function
        OnClipboardChange(ClipChanged, 0)
        if (selectedIndex > 1) {
            A_Clipboard := SpoutGui["EditContent"].Value
            selectedFunction := Functions[selectedIndex - 1]
            if (selectedFunction) {
                selectedFunction.FuncObj.call()
            }

        }
    }
    SpoutGui["EditContent"].OnEvent("Change", (*) => UpdateCountDisplay(countDisplay))

    SpoutGui.OnEvent("Escape", (*) => exit())
    SpoutGui.OnEvent("Close", (*) => exit())

    exit(*) {
        Hotkey("+Enter", "Off")
        SaveGuiPosition(SpoutGui.Hwnd)
        OnClipboardChange(ClipChanged, 0)
        SpoutGui.Destroy()
        SpoutGui := ""
    }
    
    ; Enable Copy button only if text has been altered
    SpoutGui["EditContent"].OnEvent("Change", (*) => copyButton.Enabled := true)

    ; Add a hotkey for Shift+Enter
    Hotkey("+Enter", CopyEditContent)
    Hotkey("+Enter", "On")


    CopyEditContent(*) {
        
        try {
            refreshButton.Enabled := false
            if (WinActive("ahk_id " . SpoutGui.Hwnd) && SpoutGui["EditContent"].Focused) {
                A_Clipboard := SpoutGui["EditContent"].Value
                ToolTip("Changes copied to clipboard")
                SetTimer(() => ToolTip(), -2000)
            }
        } catch {
            Hotkey("+Enter", "Off")
        }
    }
    
    ; Get saved position
    pos := GetGuiPosition()
    if (pos.x = "center") {
        SpoutGui.Show("w450")  ; Default centered position with width
    } else {
        SpoutGui.Show("x" pos.x " y" pos.y " w450")  ; Saved position with width
    }
    ; Move cursor to the end of the text
    SendInput "{Right}"
}




AddTimerMinutes(durationMinutes) {
    global timerRunning, endTime, timerGui, timerText
    if (timerRunning) {
        ; Add one minute to the existing timer
        endTime += 60 * 1000 * durationMinutes
        return
    }

    duration := durationMinutes * 60 ; Convert minutes to seconds
    endTime := A_TickCount + (duration * 1000)
    timerRunning := true

    ; Create GUI
    timerGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
    timerText := timerGui.Add("Text", "w153 h44 Center", "00:00")  
    timerText.SetFont("s28 cWhite")
    timerGui.BackColor := "0x00990F"  
    
    ; Position GUI above the taskbar in bottom right corner
    screenWidth := A_ScreenWidth
    screenHeight := A_ScreenHeight
    taskbarHeight := 40  ; Assuming taskbar height is 40 pixels
    timerGui.Show("x" . (screenWidth - 205) . " y" . (screenHeight - taskbarHeight - 90) . " NoActivate")
    
    ; Start the timer
    SetTimer UpdateTimer, 1000

    ; Add OnEvent for left mouse click to cancel the timer
    timerText.OnEvent("Click", (*) => CancelTimer())
}




UpdateTimer() {
    remaining := (endTime - A_TickCount) / 1000
    if (remaining > 0) {
        hours := Floor(remaining / 3600)
        minutes := Floor(Mod(remaining, 3600) / 60)
        seconds := Mod(remaining, 60)
            timerText.Value := Format("{:02d}:{:02d}:{:02d}", hours, minutes, seconds)

    } else {
        CancelTimer()
        SoundPlay A_WinDir "\Media\Alarm05.wav"
        teaReadyGui := Gui("+AlwaysOnTop -Caption +ToolWindow")

        teaReadyText := teaReadyGui.Add("Text", "w175 h50 Center", "Time's Up!")
        teaReadyText.SetFont("s25 bold cWhite")
        teaReadyGui.BackColor := "0x00990F"  ; Green color
        
        ; Position GUI in the center of the screen
        screenWidth := A_ScreenWidth
        screenHeight := A_ScreenHeight
        teaReadyGui.Show("x" . (screenWidth/2 - 100) . " y" . (screenHeight/2 - 30))
        
        ; Play sound
        SoundPlay A_WinDir "\Media\Alarm05.wav"
        
        ; Set up hotkeys to close the GUI
        teaReadyGui.OnEvent("Close", (*) => teaReadyGui.Destroy())
        teaReadyGui.OnEvent("Escape", (*) => teaReadyGui.Destroy())
        ; Set up click events to close the GUI
        teaReadyText.OnEvent("Click", (*) => teaReadyGui.Destroy())
        ; Set up hotkey to close the GUI when Escape is pressed

        SetTimer(() => teaReadyGui.Destroy(), -10000)
    }
}

CancelTimer() {
    global timerRunning, endTime, timerGui
    if (timerRunning) {
        SetTimer UpdateTimer, 0
        timerGui.Destroy()
        timerRunning := false
        endTime := 0
    }
}




; Function: Copies the RGB color of the pixel at the current mouse position to the clipboard, adds it to the clipboard if it already holds one or more RGB colors
GetPixel() {
    ; Get the current mouse position
    MouseGetPos &mouseX, &mouseY

    ; Get the color of the pixel at the mouse position
    color := PixelGetColor(mouseX, mouseY, "RGB")

    ; Convert the color to a readable format (remove 0x prefix)
    rgbColor := "#" . Format("{:06X}", color)

    ; Check if the current clipboard contents are one or more RGB colors of format '#FFFFFF', separated by commas
    if (RegExMatch(A_Clipboard, "^(#[0-9A-Fa-f]{6})(, #[0-9A-Fa-f]{6})*$")) {
        ; Check if the new color is already in the list
        if InStr(A_Clipboard, rgbColor) {
            ToolTip rgbColor " is already in list"
        } else {
            ; Add the new color to the existing list after a comma
            A_Clipboard := A_Clipboard . ", " . rgbColor
            ToolTip "color added: " rgbColor
        }
    } else {
        ; Clear the clipboard and replace it with the new color string
        A_Clipboard := rgbColor
        ToolTip "color copied to clipboard: " rgbColor
    }

    Sleep 2000
    ToolTip ""
}


; Function: Creates a GUI for tallying numbers
ShowTallyUI() {
    global tempTally, incrementValue, SpoutGui
    
    ; Initialize tempTally from settings if it exists
    tempTally := ReadSetting("Tallies", "TempTally", "0")
    
    resetGui()
    colorScheme := GetCurrentColorScheme()
    SpoutGui := Gui("+ToolWindow", "Tally Counter")
    SpoutGui.SetFont("s12", "Arial")
    SpoutGui.BackColor := colorScheme.Background

    ; Display the current tally
    SpoutGui.Add("Text", "x10 y35 c" . colorScheme.Text, "Current Tally:")
    SpoutGui.SetFont("S16", "Arial")
    tallyText := SpoutGui.Add("Text", "x+20 y+-20 w100 h25 vTallyDisplay c" . colorScheme.Text, tempTally)
    SpoutGui.SetFont("S12", "Arial")

    ; Increment input
    SpoutGui.Add("Text", "x10 y+20 c" . colorScheme.Text, "Increment:")
    incrementInput := SpoutGui.Add("Edit", "x+5 y+-25 w50 vIncrementValue c" . colorScheme.Text . " Background" . colorScheme.EditBackground, incrementValue)
    incrementInput.OnEvent("Change", (*) => updateIncrementValue())

    ; Increase button
    increaseButton := SpoutGui.Add("Button", "x+10 w50", "+")
    increaseButton.OnEvent("Click", (*) => UpdateTally(1))

    ; Decrease button
    decreaseButton := SpoutGui.Add("Button", "x+10 w50", "-")
    decreaseButton.OnEvent("Click", (*) => UpdateTally(-1))

    ; Reset button
    SpoutGui.Add("Button", "x10 y+10 w80", "Reset").OnEvent("Click", (*) => ResetTally())
    SpoutGui.Add("Button", "x+10 y+-30 w140", "Close").OnEvent("Click", (*) => exit())

    SpoutGui.OnEvent("Escape", (*) => exit())
    SpoutGui.OnEvent("Close", (*) => exit())

    SpoutGui.Show()

    exit(*) {
        ; Save current tally before exiting
        WriteSetting("Tallies", "TempTally", tempTally)
        SpoutGui.Destroy()
        SpoutGui := ""
    }

    UpdateTally(change := 0) {
        tempTally += change * incrementValue
        tallyText.Value := tempTally
        ; Save after each update
        WriteSetting("Tallies", "TempTally", tempTally)
    }

    UpdateIncrementValue() {
        if (incrementInput.Text == "" or !IsInteger(incrementInput.Text)) {
            incrementValue := 1
        } else {
            incrementValue := Max(1, Integer(incrementInput.Text))
        }
        incrementInput.Text := incrementValue
    }
    

    ResetTally() {
        tempTally := 0
        tallyText.Value := tempTally
        WriteSetting("Tallies", "TempTally", "0")
    }
}

TallyUp(tallyName := "TempTally", increment := 1) {
    ; Read current value from settings
    currentValue := Integer(ReadSetting("Tallies", tallyName, "0"))
    
    ; Increment value
    currentValue += increment
    
    ; Save new value
    WriteSetting("Tallies", tallyName, currentValue)

    ToolTip(tallyName . ": " . currentValue)
    SetTimer () => ToolTip(), -1000
}

TallyDown(tallyName := "TempTally", increment := 1) {
    ; Read current value from settings
    currentValue := Integer(ReadSetting("Tallies", tallyName, "0"))
    
    ; Decrement value
    currentValue -= increment
    
    ; Save new value
    WriteSetting("Tallies", tallyName, currentValue)

    ToolTip(tallyName . ": " . currentValue)
    SetTimer () => ToolTip(), -1000
}


; Function: Creates a GUI for taking quick notes
SpoutNoter(content := "", auto := false, file := "Default.txt") {
    global SpoutGui
    
    resetGui()
    colorScheme := GetCurrentColorScheme()
    
    defaultFilename := file

    ; Get the base notes location from settings
    baseNotesLocation := ReadSetting("General", "NotesFolder", A_MyDocuments . "\Notes")
    
    ; Ensure the notes folder exists with a Notes subdirectory
    quickNotesFolder := baseNotesLocation . "\Notes"
    if (!DirExist(quickNotesFolder)) {
        DirCreate(quickNotesFolder)
    }

    ; If content is provided and auto is true, save directly without showing GUI
    if (auto) {
        filePath := quickNotesFolder . "\" . defaultFilename
        fileExt := StrLower(StrSplit(defaultFilename, ".").Pop())
        formattedDate := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        
        ; Handle different file types
        switch fileExt {
            case "json", "jsonl":
                ; For JSON/JSONL files, append the content directly
                if (fileExt = "json") {
                    ; For JSON, handle the array structure
                    if (FileExist(filePath)) {
                        ; Read existing content and remove the closing bracket
                        fileContent := RegExReplace(FileRead(filePath), "\s*\]\s*$", "")
                        ; Add comma if there's existing content
                        if (StrLen(fileContent) > 1) {
                            FileDelete(filePath)
                            FileAppend(fileContent . ",`n" . content . "`n]", filePath)
                        }
                    } else {
                        ; Create new JSON file with array structure
                        FileAppend("[`n" . content . "`n]", filePath)
                    }
                } else {
                    ; For JSONL, append directly
                    FileAppend(content . "`n", filePath)
                }
            case "csv":
                ; For CSV, just append content without headers
                FileAppend(formattedDate . "," . StrReplace(content, ",", ";") . "`n", filePath)
            default:
                ; For txt files, use the header format
                FileAppend("`n-------------------" . formattedDate . "-------------------`n" . content . "`n", filePath)
        }
        
        ToolTip("Note Saved to " . defaultFilename)
        SetTimer () => ToolTip(), -1000
        return
    }
    
    resetGui()
    colorScheme := GetCurrentColorScheme()
    SpoutGui := Gui("+ToolWindow", "SpoutNoter")

    SpoutGui.BackColor := colorScheme.Background

    SpoutGui.SetFont("s14", "Arial")  ; Set a larger font size

    noteEdit := SpoutGui.Add("Edit", "x10 y10 w500 h200 vNoteContent c" . colorScheme.Text . " Background" . colorScheme.EditBackground)
    if (A_Clipboard != "") {
        noteEdit.Value := A_Clipboard
    }

    ; Add editable window for current file contents
    fileEdit := SpoutGui.Add("Edit", "x10 y+10 w500 h150 Multi VScroll c" . colorScheme.Text . " Background" . colorScheme.EditBackground)
    fileEdit.SetFont("s10", "Consolas")  ; Use Consolas for better monospace display
    
    ; Track if file content has been modified
    fileEdit.origContent := ""
    fileEdit.isModified := false
    fileEdit.OnEvent("Change", (*) => fileEdit.isModified := true)

    ; Add dropdown menu for file selection (half width)
    fileList := ["<Create New File>"]
    Loop Files, quickNotesFolder . "\*.*"
    {
        fileList.Push(A_LoopFileName)
    }
    if (!HasVal(fileList, defaultFilename)) {
        fileList.InsertAt(2, defaultFilename)
    }
    fileDropdown := SpoutGui.Add("DropDownList", "x10 y+10 w245 vSelectedFile Choose" . HasVal(fileList, defaultFilename), fileList)

    ; Add dropdown menu for format selection (smaller width)
    formatList := ["txt", "json", "jsonl", "csv"]
    formatDropdown := SpoutGui.Add("DropDownList", "x+10 y+-25 w100 vSelectedFormat Choose1", formatList)

    ; Add line count display with theme color
    lineCountText := SpoutGui.Add("Text", "x+3 y+-27 w115 Center c" . colorScheme.Text, "Lines: 0")

    ; Set initial format based on the default filename
    SetFormatBasedOnFile(defaultFilename)
    UpdateFilePreview(quickNotesFolder . "\" . defaultFilename)
    ; Force an additional scroll to bottom on initial load
    SetTimer(ScrollToBottom, -100)

    ScrollToBottom() {
        totalLines := SendMessage(0xBA, 0, 0, 0, , "ahk_id " . fileEdit.Hwnd)
        SendMessage(0xB6, totalLines * 2, 0, , "ahk_id " . fileEdit.Hwnd) 
        ControlSend("{Ctrl down}{End}{Ctrl up}", , fileEdit)
        noteEdit.Focus()
    }

    saveButton := SpoutGui.Add("Button", "x15 y+10 w160 h40", "Save")
    copyButton := SpoutGui.Add("Button", "x+5 y+-40 w160 h40", "Copy to Clipboard")
    cancelButton := SpoutGui.Add("Button", "x+5 y+-40 w160 h40", "Cancel")

    copyButton.OnEvent("Click", (*) => (A_Clipboard := noteEdit.Text, ToolTip("Copied to clipboard"), SetTimer(() => ToolTip(), -1000)))
    SpoutGui.OnEvent("Escape", (*) => exit())

    exit(*) {
        SaveGuiPosition(SpoutGui.Hwnd)
        Hotkey("~+Enter", "Off")
        SpoutGui.Destroy()
        SpoutGui := ""
    }

   
    ; Create a temporary hotkey for Shift+Enter
    Hotkey("~+Enter", SaveNote, "On")

    ; Remove the temporary hotkey when the GUI is destroyed
    SpoutGui.OnEvent("Close", (*) => exit())
    SpoutGui.OnEvent("Escape", (*) => exit())
    saveButton.OnEvent("Click", SaveNote)
    cancelButton.OnEvent("Click", (*) => exit())

    ; Update format and preview when file is changed
    fileDropdown.OnEvent("Change", HandleFileDropdownChange)

    ; Update line count when text changes or file changes
    UpdateLineCount() {
        if (FileExist(quickNotesFolder . "\" . fileDropdown.Text)) {
            fileContent := FileRead(quickNotesFolder . "\" . fileDropdown.Text)
            lineCountText.Value := "Lines: " . StrSplit(fileContent, "`n").Length
        } else {
            lineCountText.Value := "Lines: 0"
        }
    }

    noteEdit.OnEvent("Change", (*) => UpdateLineCount())
    fileDropdown.OnEvent("Change", (*) => UpdateLineCount())

    ; Get saved position
    pos := GetGuiPosition()
    if (pos.x = "center") {
        SpoutGui.Show("w520 h470")  ; Default centered position with dimensions
    } else {
        SpoutGui.Show("x" pos.x " y" pos.y " w520 h470")  ; Saved position with dimensions
    }

    SetFormatBasedOnFile(filename) {
        extension := StrSplit(filename, ".").Pop()
        if (HasVal(formatList, extension)) {
            formatDropdown.Value := HasVal(formatList, extension)
        } else {
            formatDropdown.Value := 1  ; Default to txt if extension not recognized
        }
    }
    
    UpdateFilePreview(filepath) {
        if (FileExist(filepath)) {
            ; Read file content
            fileContent := FileRead(filepath)
            
            ; Store original content and reset modified flag
            fileEdit.origContent := fileContent
            fileEdit.isModified := false
            
            ; Update preview with proper line endings preserved
            fileEdit.Value := fileContent
            
            ; Wait briefly for the control to update
            Sleep(50)
            
            ; Get total number of lines
            totalLines := SendMessage(0xBA, 0, 0,, "ahk_id " . fileEdit.Hwnd)  
            
            ; Scroll to bottom using multiple methods to ensure it works
            SendMessage(0xB7, 0, 0,, "ahk_id " . fileEdit.Hwnd)      
            SendMessage(0xB6, totalLines, 0,, "ahk_id " . fileEdit.Hwnd)  
            
            ; Force scroll to absolute bottom
            ControlSend("{Ctrl down}{End}{Ctrl up}", fileEdit)
            Sleep(10)
            SendMessage(0xB6, totalLines * 2, 0,, "ahk_id " . fileEdit.Hwnd)  
            
            ; Return focus to the note edit control
            noteEdit.Focus()
        } else {
            fileEdit.Value := "<New File>"
            fileEdit.origContent := ""
            fileEdit.isModified := false
            noteEdit.Focus()
        }
        UpdateLineCount()
    }

    HandleFileDropdownChange(*) {
        ; Check if there are unsaved changes
        if (fileEdit.isModified) {
            if (MsgBox("Discard changes to current file?", , "YesNo") = "No") {
                return
            }
        }
        
        if (fileDropdown.Text == "<Create New File>") {
            newFileName := InputBox("Enter new file name:", "Create New File", "w300 h100").Value
            if (newFileName != "") {
                if (!InStr(newFileName, ".")) {
                    newFileName .= "." . formatList[formatDropdown.Value]
                }
                fileDropdown.Add([newFileName])
                fileDropdown.Text := newFileName
                fileDropdown.Choose(newFileName)
            } else {
                fileDropdown.Value := 2  ; Select the default file if no name is entered
            }
        }
        SetFormatBasedOnFile(fileDropdown.Text)
        UpdateFilePreview(quickNotesFolder . "\" . fileDropdown.Text)
    }

    SaveNote(*) {
        ; Check if noteEdit has non-whitespace content or file was modified
        if (RegExMatch(Trim(noteEdit.Text), "\S") || fileEdit.isModified) {
            selectedFile := fileDropdown.Text
            selectedFormat := formatDropdown.Text
            filePath := quickNotesFolder . "\" . selectedFile
            formattedDate := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            
            ; Special handling for JSON files
            if (selectedFormat = "json") {
                ; Read existing content
                fileContent := FileExist(filePath) ? FileRead(filePath) : ""
                
                ; Check if file is empty or doesn't start with [
                if (fileContent = "" || !RegExMatch(fileContent, "^\s*\[")) {
                    fileContent := "["
                }
                
                ; Remove trailing ] if it exists
                fileContent := RegExReplace(fileContent, "\s*\]\s*$", "")
                
                ; Remove trailing comma if it exists
                fileContent := RegExReplace(fileContent, ",\s*$", "")
                
                ; Write the opening content
                try {
                    FileDelete(filePath)
                } catch Error {
                    ; File doesn't exist yet, that's ok
                }
                FileAppend(fileContent, filePath)
                ; Add comma if there's existing content
                if (StrLen(fileContent) > 1) {
                    FileAppend(",`n", filePath)
                }
            }
            
            ; If file content was modified (for non-JSON files)
            if (fileEdit.isModified && selectedFormat != "json") {
                FileDelete(filePath)
                FileAppend(fileEdit.Value, filePath)
                fileEdit.isModified := false
                fileEdit.origContent := fileEdit.Value
            }
            
            ; Only append new note content if noteEdit has content
            noteContent := noteEdit.Text
            if (RegExMatch(Trim(noteContent), "\S")) {
                switch selectedFormat {
                    case "txt":
                        FileAppend "`n-------------------" . formattedDate . "-------------------`n" . noteContent . "`n", filePath
                    case "json":
                        ; Check if content is already a JSON object with a date field
                        if RegExMatch(noteContent, '^\s*{\s*"date":\s*"[^"]+"\s*,') {
                            ; Content is already a properly formatted JSON object with date
                            FileAppend(noteContent, filePath)
                        } else {
                            ; Wrap content in date and content fields
                            jsonContent := '{"Date": "' . formattedDate . '", "content": "' . StrReplace(noteContent, '"', '\"') . '"}'
                            FileAppend(jsonContent, filePath)
                        }
                        ; Add the closing bracket
                        FileAppend("`n]", filePath)
                    case "jsonl":
                        ; Similar check for JSONL format
                        if RegExMatch(noteContent, '^\s*{\s*"date":\s*"[^"]+"\s*,') {
                            FileAppend(noteContent . "`n", filePath)
                        } else {
                            jsonlContent := '{"Date": "' . formattedDate . '", "content": "' . StrReplace(noteContent, '"', '\"') . '"}'
                            FileAppend(jsonlContent . "`n", filePath)
                        }
                    case "csv":
                        ; For CSV, just append date and content in a simple format
                        csvContent := formattedDate . "," . StrReplace(noteContent, ",", ";") . "`n"
                        FileAppend(csvContent, filePath)
                }
            }
            
            ToolTip("Note Saved to " . selectedFile)
            SetTimer () => ToolTip(), -1000
            UpdateFilePreview(filePath)
            exit()
        } else {
            MsgBox("No content to save")
        }
    }
}
