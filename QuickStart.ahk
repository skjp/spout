#Requires AutoHotkey v2.0
#SingleInstance

; Generate includes file
Run A_ScriptDir "\spout\shared\IncludesGenerator.ahk"

; Check and create config files if they don't exist
configFiles := Map(
    "models.ini", "example_models.ini",
    "themes.ini", "example_themes.ini",
    "settings.ini", "example_settings.ini"
)

configDir := A_ScriptDir "\spout\config"
if !DirExist(configDir)
    DirCreate(configDir)

for targetFile, sourceFile in configFiles {
    targetPath := configDir "\" targetFile
    if !FileExist(targetPath) {
        sourcePath := configDir "\example_" targetFile
        if FileExist(sourcePath)
            FileCopy(sourcePath, targetPath)
    }
}

; Check for running console scripts first
DetectHiddenWindows(true)
SetTitleMatchMode(2)  ; More flexible title matching
runningScripts := []
ids := WinGetList("ahk_class AutoHotkey")
for id in ids {
    title := WinGetTitle(id)
    processPath := WinGetProcessPath(id)
    ; Look specifically for SpoutConsole pattern
    if (InStr(title, "SpoutConsole") || InStr(processPath, "SpoutConsole")) {
        runningScripts.Push(title)  ; Store the window title instead of process path
    }
}

; If scripts are running, show warning dialog
if runningScripts.Length > 0 {
    scriptList := ""
    for script in runningScripts {
        scriptList .= script "`n"
    }
    
    result := MsgBox(
        "The following console scripts are already running:`n`n" scriptList "`nWould you like to close them?",
        "Running Scripts Detected",
        4 + 48  ; Yes/No + Warning icon
    )
    
    if (result = "Yes") {
        for id in ids {
            title := WinGetTitle(id)
            processPath := WinGetProcessPath(id)
            if (InStr(title, "SpoutConsole") || InStr(processPath, "SpoutConsole")) {
                pid := WinGetPID(id)
                ProcessClose(pid)
                ProcessWaitClose(pid, 2)
            }
        }
    } else {
        ExitApp  ; Exit if user chooses not to close existing scripts
    }
}

; Create the main GUI window
MainGui := Gui()
MainGui.Title := "Script Selector"

; Set larger font for GUI elements
MainGui.SetFont("s12")  ; s12 means size 12, you can adjust this number as needed

; Add instructions text
MainGui.Add("Text",, "Select the desired console layout:")

; Get all *Script.ahk files in the current directory
scriptFiles := []
Loop Files A_ScriptDir "\spout\*.ahk" {
    if (A_LoopFileName != "SpoutMain.ahk") {
        scriptFiles.Push(A_LoopFileName)
    }
}

; Create a ListBox with the script files
lb := MainGui.Add("ListBox", "w250 h200", scriptFiles)  ; Made the control slightly larger to accommodate bigger font

; Add a Run button
MainGui.Add("Button", "Default w100", "Run").OnEvent("Click", RunSelected)  ; Made button slightly wider

; Show the GUI
MainGui.Show()

; Function to handle the Run button click
RunSelected(*)
{
    selected := lb.Text
    if selected
    {
        Run A_ScriptDir "\spout\" selected
        ExitApp
    }
}
