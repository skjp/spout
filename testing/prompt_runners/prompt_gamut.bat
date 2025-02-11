@echo off
setlocal EnableDelayedExpansion

:: Check if models.ini exists in parent directory
set "MODELS_INI=..\..\spout\config\models.ini"
if not exist "%MODELS_INI%" (
    echo Error: Cannot find models.ini at %MODELS_INI%
    echo Please ensure you're running this script from the testing directory
    goto :eof
)

:: Directory paths
set "PROMPTS_DIR=..\prompts"
set "TESTS_DIR=..\tests"

:: Create tests directory if it doesn't exist
if not exist "%TESTS_DIR%" mkdir "%TESTS_DIR%"

:: Get active models from models.ini
set "model_count=0"
for /f "usebackq tokens=1,2 delims==" %%a in ("%MODELS_INI%") do (
    set "line=%%a"
    set "status=%%b"
    if not "!line:~0,1!"=="[" if not "!line:~0,1!"=="#" if not "!line!"=="" (
        if "!status!"=="1" (
            set /a "model_count+=1"
            set "models[!model_count!]=!line!"
        )
    )
)

:: Check if we found any active models
if %model_count% equ 0 (
    echo Error: No active models found in %MODELS_INI%
    goto :eof
)

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
set "results_file=%TESTS_DIR%\prompt_gamut-%timestamp%.txt"

:: Initialize results file
echo Prompt Gamut Results - %timestamp% > "%results_file%"
echo =================== >> "%results_file%"
echo Testing across %model_count% models >> "%results_file%"
echo. >> "%results_file%"

:: Initialize total duration
set "total_duration=0"

:: Test each model
for /l %%m in (1,1,%model_count%) do (
    set "model=!models[%%m]!"
    set "model_duration=0"
    echo.
    echo Testing model: !model!
    echo ----------------------------------------
    
    :: Switch to the model
    spout -p "!model!"
    
    :: Add model header to results
    echo Model: !model! >> "%results_file%"
    echo ---------------------------------------- >> "%results_file%"
    echo. >> "%results_file%"
    
    if "!process_all!"=="1" (
        for /l %%i in (1,1,!dir_count!) do (
            echo Processing file: !dir_files[%%i]!
            echo. >> "%results_file%"
            echo File: !dir_files[%%i]! >> "%results_file%"
            echo =================== >> "%results_file%"
            
            for /f "usebackq tokens=*" %%p in ("!dir_files[%%i]!") do (
                echo Processing prompt: %%p
                echo. >> "%results_file%"
                echo Prompt: >> "%results_file%"
                echo %%p >> "%results_file%"
                
                :: Get start time in milliseconds
                for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set start_time=%%I
                set /a "start_ms=(1!start_time:~8,2!*3600 + 1!start_time:~10,2!*60 + 1!start_time:~12,2!)*1000 + 1!start_time:~15,3!"
                set /a "start_ms-=111111000"
                
                :: Run the prompt
                for /f "tokens=*" %%o in ('spout -m converse --primer "You are a helpful assistant" --history-file "_" --recent-message "%%p" 2^>^&1') do (
                    echo. >> "%results_file%"
                    echo %%o >> "%results_file%"
                )
                
                :: Get end time in milliseconds
                for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set end_time=%%I
                set /a "end_ms=(1!end_time:~8,2!*3600 + 1!end_time:~10,2!*60 + 1!end_time:~12,2!)*1000 + 1!end_time:~15,3!"
                set /a "end_ms-=111111000"
                
                :: Calculate duration
                set /a "prompt_duration=end_ms-start_ms"
                if !prompt_duration! lss 0 set /a "prompt_duration+=86400000"
                
                :: Add prompt duration to model duration
                set /a "model_duration+=prompt_duration"
                
                echo. >> "%results_file%"
                echo ------------------- >> "%results_file%"
                echo. >> "%results_file%"
            )
            
            echo =================== >> "%results_file%"
        )
    ) else (
        echo Processing file: !selected_file!
        for /f "usebackq tokens=*" %%p in ("!selected_file!") do (
            echo Processing prompt: %%p
            echo. >> "%results_file%"
            echo Prompt: >> "%results_file%"
            echo %%p >> "%results_file%"
            
            :: Get start time in milliseconds
            for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set start_time=%%I
            set /a "start_ms=(1!start_time:~8,2!*3600 + 1!start_time:~10,2!*60 + 1!start_time:~12,2!)*1000 + 1!start_time:~15,3!"
            set /a "start_ms-=111111000"
            
            :: Run the prompt
            for /f "tokens=*" %%o in ('spout -m converse --primer "You are a helpful assistant" --history-file "_" --recent-message "%%p" 2^>^&1') do (
                echo. >> "%results_file%"
                echo %%o >> "%results_file%"
            )
            
            :: Get end time in milliseconds
            for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set end_time=%%I
            set /a "end_ms=(1!end_time:~8,2!*3600 + 1!end_time:~10,2!*60 + 1!end_time:~12,2!)*1000 + 1!end_time:~15,3!"
            set /a "end_ms-=111111000"
            
            :: Calculate duration
            set /a "prompt_duration=end_ms-start_ms"
            if !prompt_duration! lss 0 set /a "prompt_duration+=86400000"
            
            :: Add prompt duration to model duration
            set /a "model_duration+=prompt_duration"
            
            echo. >> "%results_file%"
            echo ------------------- >> "%results_file%"
            echo. >> "%results_file%"
        )
    )
    
    :: Calculate minutes and seconds from model duration
    set /a "duration_seconds=model_duration/1000"
    set /a "minutes=duration_seconds/60"
    set /a "seconds=duration_seconds%%60"
    
    :: Add separator to results
    echo ========================================= >> "%results_file%"
    echo. >> "%results_file%"
    
    :: Add to total duration
    set /a "total_duration+=model_duration"
    
    echo Completed in: !minutes!m !seconds!s
    echo ----------------------------------------
)

:: Format total time and add summary
set /a "total_ms=total_duration"
set /a "total_seconds=total_ms/1000"
set /a "total_minutes=total_seconds/60"
set /a "total_hours=total_minutes/60"
set /a "total_minutes%%=60"
set /a "total_seconds%%=60"

set /a "avg_ms=total_duration/model_count"
set /a "avg_seconds=avg_ms/1000"
set /a "avg_minutes=avg_seconds/60"
set /a "avg_seconds%%=60"

:: Add summary to results file
echo. >> "%results_file%"
echo Summary >> "%results_file%"
echo ======= >> "%results_file%"
echo Total Models Tested: !model_count! >> "%results_file%"
echo Total Duration: !total_hours!h !total_minutes!m !total_seconds!s >> "%results_file%"
echo Average Duration: !avg_minutes!m !avg_seconds!s >> "%results_file%"
echo. >> "%results_file%"

echo.
echo Testing completed!
echo Total Duration: !total_hours!h !total_minutes!m !total_seconds!s
echo Results saved to: %results_file%
goto :eof

:calculate_duration
:: Convert times to seconds
for /f "tokens=1-4 delims=:." %%a in ("%~1") do (
    set /a "start_seconds=(((%%a*60)+1%%b%%100)*60)+1%%c%%100"
)
for /f "tokens=1-4 delims=:." %%a in ("%~2") do (
    set /a "end_seconds=(((%%a*60)+1%%b%%100)*60)+1%%c%%100"
)
set /a "duration_seconds=end_seconds-start_seconds"
if %duration_seconds% lss 0 set /a "duration_seconds+=86400"
goto :eof

:invalid_selection
echo Invalid selection. Please try again.
goto select_file

:invalid_sub_selection
echo Invalid selection. Please try again.
goto select_subfile
