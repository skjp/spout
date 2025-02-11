#Requires AutoHotkey v2.0

#include "..\..\Shared\BaseGui.ahk"



SpoutMend(*) {
    enhancer := SpoutFunctionNoGUI("Enhance")
    enhancer.Run()
}

SpoutJazz(*) {
    enhancer := SpoutFunctionNoGUI("Enhance", "jazz")
    enhancer.Run()
}




SpoutEnhance(auto := false, text := "") {
    enhancer := SpoutFunction(auto)
    enhancer.originalContent := (text != "") ? text : A_Clipboard
    enhancer.InitializeGUI("Enhance", "Enhanced")

}

