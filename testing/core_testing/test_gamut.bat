@echo off
setlocal EnableDelayedExpansion

:: Check if models.ini exists in parent directory
set "MODELS_INI=..\..\spout\config\models.ini"
if not exist "%MODELS_INI%" (
    echo Error: Cannot find models.ini at %MODELS_INI%
    echo Please ensure you're running this script from the testing directory
    goto :eof
)

:: Create tests directory if it doesn't exist
if not exist "..\tests" mkdir "..\tests"

:: Generate timestamp for test files
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set "timestamp=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%_%datetime:~8,2%-%datetime:~10,2%-%datetime:~12,2%"
set "SUMMARY_FILE=..\tests\gamut_summary-%timestamp%.txt"

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

:: Initialize summary file
(
    echo Model Performance Summary - %timestamp%
    echo =================================
    echo.
    echo Models to be tested:
    echo -----------------
    for /l %%i in (1,1,%model_count%) do echo - !models[%%i]!
    echo.
    echo Test Results:
    echo ============
    echo.
) > "%SUMMARY_FILE%"

echo Starting comprehensive model testing across %model_count% models...
echo Results will be saved to: %SUMMARY_FILE%
echo.

:: Initialize total duration
set "total_duration=0"

:: Test each model
for /l %%i in (1,1,%model_count%) do (
    set "model=!models[%%i]!"
    echo Testing model: !model!
    echo ----------------------------------------
    
    :: Record start time
    set "start_time=%time%"
    
    :: Switch to the model
    spout -p "!model!"
    
    :: Run core tests and capture the output
    for /f "tokens=*" %%o in ('call test_core.bat') do (
        set "core_test_output=!core_test_output!%%o^

"
    )
    
    :: Extract test file path and pass rate
    for /f "tokens=* delims=" %%a in ('echo !core_test_output! ^| findstr /C:"Results saved to"') do (
        set "test_file=%%a"
        set "test_file=!test_file:* =!"
    )
    
    :: Extract pass rate from the output
    for /f "tokens=3 delims=: " %%a in ('echo !core_test_output! ^| findstr /C:"Overall Pass Rate"') do (
        set "pass_rate=%%a"
    )
    
    :: Record end time and calculate duration
    set "end_time=%time%"
    call :calculate_duration "!start_time!" "!end_time!"
    set /a "total_duration+=duration_seconds"
    
    :: Format duration
    set /a "minutes=duration_seconds/60"
    set /a "seconds=duration_seconds%%60"
    set "duration_formatted=!minutes!m !seconds!s"
    
    :: Add to summary file
    (
        echo Model: !model!
        echo Pass Rate: !pass_rate!
        echo Duration: !duration_formatted!
        echo Core Test Results: !core_test_output!
        echo ----------------------------------------
        echo.
    ) >> "%SUMMARY_FILE%"
    
    :: Print progress to terminal
    echo !core_test_output!
    echo Pass Rate: !pass_rate!
    echo Duration: !duration_formatted!
    echo ----------------------------------------
    echo.
)

:: Calculate average statistics
set "total_pass_rate=0"
for /l %%i in (1,1,%model_count%) do (
    for /f "tokens=2 delims=:" %%a in ('findstr /C:"Pass Rate:" "%SUMMARY_FILE%"') do (
        set "pass_rate=%%a"
        set "pass_rate=!pass_rate:~1!"
        set "pass_rate=!pass_rate:%%=!"
        set /a "total_pass_rate+=pass_rate"
    )
)

:: Calculate averages and format total time
set /a "avg_pass_rate=total_pass_rate/model_count"
set /a "total_hours=total_duration/3600"
set /a "total_minutes=(total_duration%%3600)/60"
set /a "total_seconds=total_duration%%60"
set /a "avg_duration=total_duration/model_count"
set /a "avg_minutes=avg_duration/60"
set /a "avg_seconds=avg_duration%%60"

:: Add summary statistics to file
(
    echo Summary Statistics
    echo ==================
    echo Total Models Tested: %model_count%
    echo Total Duration: %total_hours%h %total_minutes%m %total_seconds%s
    echo Average Duration: %avg_minutes%m %avg_seconds%s
    echo Average Pass Rate: %avg_pass_rate%%%
    echo.
    echo Models Tested Successfully:
    echo -------------------------
    for /l %%i in (1,1,%model_count%) do (
        for /f "tokens=1,* delims=:" %%a in ('findstr /C:"Pass Rate:" "%SUMMARY_FILE%"') do (
            echo - !models[%%i]! ^(%%b^)
        )
    )
    echo.
) >> "%SUMMARY_FILE%"

:: Print final summary to terminal
echo Testing completed!
echo Total Models Tested: %model_count%
echo Total Duration: %total_hours%h %total_minutes%m %total_seconds%s
echo Average Duration: %avg_minutes%m %avg_seconds%s
echo Average Pass Rate: %avg_pass_rate%%%
echo Full results saved to: %SUMMARY_FILE%
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
