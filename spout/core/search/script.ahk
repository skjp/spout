#Requires AutoHotkey v2.0
global soundEffects


SpoutSearch() {
    ; Create GUI
    global SpoutGui
    resetGui()
    Sleep(50)
    originalContent := A_Clipboard
    static progress := 0
    urlMatches := []
    browserPath := ReadSetting("General", "BrowserLocation", "")
    colorScheme := GetCurrentColorScheme()
    
    ; Create a GUI to display original content and enhanced prompt
    SpoutGui := Gui("+ToolWindow", "Spout Search")
    SpoutGui.BackColor := colorScheme.Background
    
    SpoutGui.SetFont("s16", "Arial") 
    SpoutGui.Add("Text", "x10 w600 c" . colorScheme.Text, "Topic or Task:")

    ; Add Spoutlets dropdown
    spoutlets := LoadSpoutlets()
    if (spoutlets.Length > 1) {
        SpoutGui.SetFont("s12", "Arial")
        SpoutGui.Add("Text", "x403 y14 w100 c" . colorScheme.Text, "Spoutlet:")
        preferredSpoutlet := IniRead(A_ScriptDir . "\config\settings.ini", "Search", "PreferredSpoutlet", "default")
        spoutletDropdown := SpoutGui.Add("DropDownList", "x480 y10 w140 vSpoutlet c" . colorScheme.Text . " Background" . colorScheme.EditBackground, spoutlets)
        spoutletDropdown.Value := GetSpoutletIndex(preferredSpoutlet, spoutlets)
    }
    
    SpoutGui.SetFont("norm s15", "Arial")  ; Reset font to default
    SpoutGui.Add("Edit", "x10 r5 w610 vSearchTopic c" . colorScheme.Text . " Background" . colorScheme.EditBackground, originalContent)
    SpoutGui.SetFont("s16", "Arial")
    SpoutGui.Add("Text", "x10 w290 vWaitingText c" . colorScheme.Text, "Ready to Search")
    SpoutGui.SetFont("norm s15", "Arial")  ; Reset font to default
    SpoutGui.Add("Progress", "w270 r1 x+2 vProgressBar Range0-100 c" . colorScheme.Text . " Background" . colorScheme.EditBackground)
    SpoutGui.Add("ListView", "x10 r10 w610 vSites c" . colorScheme.Text . " Background" . colorScheme.EditBackground, [" Recommended Links ▼"])
    SpoutGui["Sites"].OnEvent("Click", OnListViewClick)

    ; Add buttons for clipboard actions
    buttonsRow := SpoutGui.Add("Text", "x10 w610")  ; Invisible text control to anchor buttons
    SpoutGui.Add("Button", "w220 yp+2 vNewSearchButton", "New Search").OnEvent("Click", NewSearch)
    SpoutGui.Add("Button", "w190 x+10 vOpenSitesButton", "Open All Sites").OnEvent("Click", OpenSites)
    SpoutGui.Add("Button", "w160 x+10 vCancelButton", "Cancel").OnEvent("Click", ExitApp)

    SpoutGui.OnEvent("Escape", ExitApp)
    SpoutGui.OnEvent("Close", ExitApp)

    NewSearch(*) {
        A_Clipboard := SpoutGui["SearchTopic"].Value
        SearchForLinks()
    }

    SearchForLinks() {
        urlMatches := []
        SpoutGui["Sites"].Delete()
        SpoutGui["ProgressBar"].visible := true
        progress := 0
        SpoutGui["WaitingText"].Text := "Finding references..."
        SetTimer(UpdateProgressBar, 100)
        
        ; Get selected spoutlet or default and search topic
        try {
            escapedSpoutlet := StrReplace(SpoutGui["Spoutlet"].Text, '"', '``"')
        } catch {
            escapedSpoutlet := "default"
        }
        
        ; Get the search topic from the GUI
        searchTopic := SpoutGui["SearchTopic"].Value
        escapedTopic := StrReplace(searchTopic, '"', '``"')
        
        ; Run the Python script with all required parameters
        scriptPath := A_LineFile . "\..\..\..\shared\spout_base_functions.py"
        RunWait('pythonw.exe "' . scriptPath . '" "Search" "' . escapedSpoutlet . '" "' . escapedTopic . '"', , "Hide", &OutputVar)
        
        ; Stop the timer and hide the progress bar

        if (OutputVar != "") {
            sitesArray := A_Clipboard  ; Get the updated clipboard content
                        
            ; Parse the JSON string from the clipboard
            

            try {
                ; Extract URLs from the sitesArray string
                
                urlPattern := '"(https?://[^"]+)"'
                pos := 1
                while (pos := RegExMatch(sitesArray, urlPattern, &match, pos)) {
                    urlMatches.Push(match[1])
                    pos += StrLen(match[0])
                }

                ; Display the contents of urlMatches using MsgBox
                urlMatchesString := ""
                for index, url in urlMatches {
                    urlMatchesString .= url . "`n"
                }

                if (urlMatches.Length = 0) {
                    MsgBox("No URLs found in the parsed data.")
                    return
                } else {
                ; Check each URL for validity and remove invalid ones
                validUrls := []
                SpoutGui["WaitingText"].Text := "Checking " . urlMatches.Length . " URLs:"

                for index, url in urlMatches {
                    if (IsValidUrl(url)) {
                        validUrls.Push(url)
                    }
                }
                urlMatches := validUrls

                ; Function to check if a URL is valid
                IsValidUrl(url) {
                    try {
                        whr := ComObject("WinHttp.WinHttpRequest.5.1")
                        whr.Open("HEAD", url, true)
                        whr.Send()
                        whr.WaitForResponse(3)  ; Wait up to 3 seconds for a response
                        return whr.Status >= 200 and whr.Status < 400
                    } catch {
                        return false
                    }
                }
                }

            } catch Error as err {
                MsgBox("Error extracting URLs: " . err.Message)
                return
            }
                
            try {
                progress := 0 
                SetTimer(UpdateProgressBar, 0)
                SpoutGui["ProgressBar"].visible := false
                if (soundEffects) {
                    SoundPlay(A_WinDir . "\Media\Windows Print complete.wav")
                }
            } catch{
                return
            }
            ; Update GUI with enhanced content
            SpoutGui["WaitingText"].Value := "Found " . urlMatches.Length . " Useful Links:"
            ; Create a string with each URL on a new line
            urlList := ""
            for index, url in urlMatches {
                urlList .= url . "`n"
            }
            urlList := RTrim(urlList, "`n")  ; Remove the trailing newline
            for index, url in urlMatches {
                trimmedUrl := RegExReplace(url, "^https?://", "")
                listItem := SpoutGui["Sites"].Add("", trimmedUrl)
            }
            A_Clipboard := originalContent
        } else {
            if (soundEffects) {
                SoundPlay(A_WinDir . "\Media\Windows Exclamation.wav")
            }
            SpoutGui["WaitingText"].Value := "Error: Unable to fetch URLs"

        }
    }

    ; Set clipboard back to original content
    A_Clipboard := originalContent

    pos := GetGuiPosition()
    if (pos.x = "center") {
        SpoutGui.Show("w630")
    } else {
        SpoutGui.Show("x" pos.x " y" pos.y " w630")
    }

    SpoutGui["SearchTopic"].Focus()
    ; if (originalContent != "") {
    ;     NewSearch()
    ; }
    ; Function: Updates the progress bar in the GUI
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
            return
        }
    }

    ;Function: Closes the GUI
    ExitApp(*)
        {
        SaveGuiPosition(SpoutGui.Hwnd)
        SetTimer(UpdateProgressBar, 0)
        SpoutGui.Destroy()
        }


        ; Function: Opens a single URL in Firefox
        OpenSingleSite(url)
        {
            ; Path to Firefox executable
            ; Open the URL in a new Firefox tab
            Run(browserPath " " url)
        }
    
        ; Function: Opens Firefox browser tabs for each URL in the JSON array
        OpenSites(*)
        {
            ; Path to Firefox executable
            ; Open each URL in a new Firefox tab
            for url in urlMatches {
                    ; Open the first URL in a new window
                    Run(browserPath " " url)
                ; Small delay to prevent overwhelming the system
                Sleep(200)
            }
            ; Close the GUI after opening all URLs
            SpoutGui.Destroy()
        }
            ; Function to handle ListView clicks
    OnListViewClick(LV, RowNumber) {
        if (RowNumber > 0) {
            url := LV.GetText(RowNumber, 1)
            OpenSingleSite(url)
        }
    }

    LoadSpoutlets() {
        spoutlets := ["default"]  ; Always start with default
        basePluginPath := A_ScriptDir . "\core\search"
        
        ; Define plugin directories with precedence (local > pro > base)
        pluginDirs := [
            basePluginPath . "\search_plugins",    ; base plugins
            basePluginPath . "\search_pro",        ; pro plugins
            basePluginPath . "\search_local"       ; local plugins
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
