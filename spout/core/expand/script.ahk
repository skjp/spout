#Requires AutoHotkey v2.0

#include "..\..\Shared\BaseGui.ahk"


SpoutGrow(*) {
    expander := SpoutFunctionNoGUI("Expand")
    expander.Run()
}

SpoutFill(*) {
    filler := SpoutFunctionNoGUI("Expand", "fill")
    filler.Run()
}





SpoutExpand(auto := false, text := "") {
    expander := SpoutFunction(auto)
    expander.originalContent := (text != "") ? text : A_Clipboard
    expander.InitializeGUI("Expand", "Expanded")

}