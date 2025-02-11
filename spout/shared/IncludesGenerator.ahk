#Requires AutoHotkey v2.0

includesFile := A_ScriptDir . "\Includes.ahk"
pluginsPath := A_ScriptDir . "\..\addons\"  ; Added trailing backslash

try FileDelete includesFile

; Add the #Requires directive at the start of the includes file
FileAppend "#Requires AutoHotkey v2.0`n`n", includesFile

functionNames := []

; Function to process .ahk files
ProcessAhkFile(filePath) {
    FileAppend '#Include "' . filePath . '"' . "`n", includesFile
    
    fileContent := FileRead(filePath)
    lines := StrSplit(fileContent, "`n", "`r")
    
    for line in lines {
        if (RegExMatch(line, "^(SpoutAddon_\w+)\s*\([^)]*\)\s*{?", &match)) {
            functionNames.Push(match[1])
        }
    }
}

; Process files in the root of the Plugins folder
Loop Files, pluginsPath . "*.ahk"
{
    ProcessAhkFile(A_LoopFilePath)
}

; Process files in subfolders of the Plugins folder
Loop Files, pluginsPath . "*", "D"
{
    subfolderPath := A_LoopFilePath . "\"
    Loop Files, subfolderPath . "*.ahk", "R"
    {
        ProcessAhkFile(A_LoopFilePath)
    }
}

; Add the array of function names to the includes file
FileAppend "`n; Available functions:`n", includesFile
FileAppend "availableFunctions := [", includesFile
for index, funcName in functionNames {
    if (index > 1) {
        FileAppend ", ", includesFile
    }
    FileAppend '"' . funcName . '"', includesFile
}
FileAppend "]`n", includesFile
