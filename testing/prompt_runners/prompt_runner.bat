@echo off
setlocal EnableDelayedExpansion

:: Directory paths
set "PROMPTS_DIR=..\prompts"
set "TESTS_DIR=..\tests"

:: Create tests directory if it doesn't exist
if not exist "%TESTS_DIR%" mkdir "%TESTS_DIR%"

:: Get list of files and directories
set "file_count=0"
:: First, get text files in root
for /f "delims=" %%F in ('dir /b /a-d "%PROMPTS_DIR%\*.txt" 2^>nul') do (
    set /a "file_count+=1"
    set "files[!file_count!]=%PROMPTS_DIR%\%%F"
    set "isdir[!file_count!]=0"
)
:: Then, get directories
for /f "delims=" %%D in ('dir /b /ad "%PROMPTS_DIR%" 2^>nul') do (
    set /a "file_count+=1"
    set "files[!file_count!]=%PROMPTS_DIR%\%%D"
    set "isdir[!file_count!]=1"
)

:: Display available files
echo.
echo Available prompt files:
for /l %%i in (1,1,%file_count%) do (
    for %%F in ("!files[%%i]!") do echo %%i. %%~nxF
)

:: Get user selection
:select_file
echo.
set /p "selection=Select a file number: "
if "!selection!"=="" goto select_file
if !selection! lss 1 goto invalid_selection
if !selection! gtr %file_count% goto invalid_selection

set "selected_path=!files[%selection%]!"
set "is_directory=!isdir[%selection%]!"

:: Handle directory selection
if "!is_directory!"=="1" (
    set "dir_count=0"
    for /f "delims=" %%F in ('dir /b /a-d "!selected_path!\*.txt" 2^>nul') do (
        set /a "dir_count+=1"
        set "dir_files[!dir_count!]=!selected_path!\%%F"
    )

    if !dir_count! equ 0 (
        echo No text files found in selected directory.
        goto select_file
    )

    echo.
    echo Files in selected directory:
    echo 0. All files
    for /l %%i in (1,1,!dir_count!) do (
        for %%F in ("!dir_files[%%i]!") do echo %%i. %%~nxF
    )

    :select_subfile
    echo.
    set /p "sub_selection=Select a file number (0 for all): "
    if "!sub_selection!"=="" goto select_subfile
    if !sub_selection! lss 0 goto invalid_sub_selection
    if !sub_selection! gtr !dir_count! goto invalid_sub_selection

    if !sub_selection! equ 0 (
        set "process_all=1"
    ) else (
        set "process_all=0"
        :: Get the correct array element
        for /l %%i in (1,1,!dir_count!) do (
            if %%i equ !sub_selection! (
                set "selected_file=!dir_files[%%i]!"
            )
        )
    )
) else (
    set "process_all=0"
    set "selected_file=!selected_path!"
)

:: Create results file with timestamp
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set "timestamp=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%_%datetime:~8,2%-%datetime:~10,2%-%datetime:~12,2%"
set "results_file=%TESTS_DIR%\conversation_test-%timestamp%.txt"

:: Determine the base name for the title (file or directory)
set "title_subject_name="
if "!process_all!"=="1" (
    for %%F in ("!selected_path!") do set "title_subject_name=%%~nxF (All files)"
) else (
    for %%F in ("!selected_file!") do set "title_subject_name=%%~nxF"
)

:: Get model information from settings.ini for the title
set "SETTINGS_FILE=..\spout\config\settings.ini"
set "model_name_for_title_segment="
if exist "%SETTINGS_FILE%" (
    for /f "tokens=1,* delims==" %%a in ('type "%SETTINGS_FILE%" ^| findstr /B /C:"PreferredModel"') do (
        set "model_line_value=%%b"
        REM Trim leading spaces
        for /f "tokens=*" %%t in ("!model_line_value!") do set "model_line_value=%%t"
        REM Trim trailing spaces (more complex in batch, simple removal here)
        REM Basic trailing space removal, may not cover all cases perfectly
        if defined model_line_value (
            for /l %%z in (1 1 32) do (
                if "!model_line_value:~-1!"==" " set "model_line_value=!model_line_value:~0,-1!"
            )
            if defined model_line_value set "model_name_for_title_segment= using !model_line_value!"
        )
    )
)

:: Construct and write the title line to the results file (overwrite)
echo Prompting Results for !title_subject_name!!model_name_for_title_segment! - !timestamp! > "%results_file%"
echo =================== >> "%results_file%"
echo. >> "%results_file%"

:: Process files
if "!process_all!"=="1" (
    for /l %%i in (1,1,!dir_count!) do (
        echo Processing file: !dir_files[%%i]!
        for /f "usebackq tokens=*" %%p in ("!dir_files[%%i]!") do (
            echo Processing prompt: %%p
            echo. >> "%results_file%"
            echo Prompt: >> "%results_file%"
            echo %%p >> "%results_file%"
            
            set "temp_output_file=%TESTS_DIR%\spout_temp_output.txt"
            spout -m converse --primer "You are a helpful assistant" --history-file "_" --recent-message "%%p" > "%temp_output_file%" 2>&1
            
            REM Filter out the unwanted line and append to results
            findstr /V /C:"Binary file (standard input) matches" "%temp_output_file%" >> "%results_file%"
            del "%temp_output_file%"
            
            echo. >> "%results_file%"
            echo ------------------- >> "%results_file%"
            echo. >> "%results_file%"
        )
    )
) else (
    echo Processing file: !selected_file!
    for /f "usebackq tokens=*" %%p in ("!selected_file!") do (
        echo Processing prompt: %%p
        echo. >> "%results_file%"
        echo Prompt: >> "%results_file%"
        echo %%p >> "%results_file%"
        
        set "temp_output_file=%TESTS_DIR%\spout_temp_output.txt"
        spout -m converse --primer "You are a helpful assistant" --history-file "_" --recent-message "%%p" > "%temp_output_file%" 2>&1
        
        REM Filter out the unwanted line and append to results
        findstr /V /C:"Binary file (standard input) matches" "%temp_output_file%" >> "%results_file%"
        del "%temp_output_file%"
        
        echo. >> "%results_file%"
        echo ------------------- >> "%results_file%"
        echo. >> "%results_file%"
    )
)

echo.
echo Results saved to: %results_file%
goto :eof

:invalid_selection
echo Invalid selection. Please try again.
goto select_file

:invalid_sub_selection
echo Invalid selection. Please try again.
goto select_subfile
