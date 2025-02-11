#Requires AutoHotkey v2.0

#include "..\..\Shared\BaseGui.ahk"



SpoutGist(*) {
    reducer := SpoutFunctionNoGUI("Reduce")
    reducer.Run()
}


SpoutReduce(auto := false, text := "", nui := false) {
    if (nui) {
        reducer := SpoutFunction(auto)
        return
    } 
    reducer := SpoutFunction(auto)
    reducer.originalContent := (text != "") ? text : A_Clipboard
    reducer.InitializeGUI("Reduce", "Reduced")

}

SpoutName(*) {
    reducer := SpoutFunctionNoGUI("Reduce", "namer")
    reducer.Run()
}
