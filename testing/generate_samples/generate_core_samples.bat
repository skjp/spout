@echo off
setlocal EnableDelayedExpansion

:: Get current date and time for filename
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set datetime=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%_%datetime:~8,2%-%datetime:~10,2%-%datetime:~12,2%

:: Set output file path
set "script_dir=%~dp0"
set "outfile=%script_dir%\..\tests\test_%datetime%.txt"

:: Array of core modules to test
set modules=reduce expand enhance search mutate generate iterate translate converse parse evaluate imagine

:: Create initial output file
echo Test Results - %datetime% > "%outfile%"
echo =================== >> "%outfile%"
echo. >> "%outfile%"

:: Initialize counters
set "total_passes=0"
set "total_tests=0"
set "summary="

:: Run tests for each module
for %%m in (%modules%) do (
    echo Testing %%m...
    echo ## %%m ## >> "%outfile%"
    echo. >> "%outfile%"
    
    :: Get initial counts
    set "initial_passes=0"
    set "initial_fails=0"
    for /f %%A in ('findstr /C:"[PASS]" "%outfile%" ^| find /C /V ""') do set "initial_passes=%%A"
    for /f %%A in ('findstr /C:"[FAIL]" "%outfile%" ^| find /C /V ""') do set "initial_fails=%%A"
    
    :: Run tests and capture output
    spout "%%m" -x >> "%outfile%"
    
    :: Get current counts
    set "current_passes=0"
    set "current_fails=0"
    for /f %%A in ('findstr /C:"[PASS]" "%outfile%" ^| find /C /V ""') do set "current_passes=%%A"
    for /f %%A in ('findstr /C:"[FAIL]" "%outfile%" ^| find /C /V ""') do set "current_fails=%%A"
    
    :: Calculate module results
    set /a "module_pass=current_passes-initial_passes"
    set /a "module_fail=current_fails-initial_fails"
    set /a "module_total=module_pass+module_fail"
    
    :: Update totals
    set /a "total_passes+=module_pass"
    set /a "total_tests+=module_total"
    
    :: Calculate percentage
    if !module_total! equ 0 (
        set "percent=0.0"
    ) else (
        set /a "percent=(module_pass*100)/module_total"
    )
    
    :: Add to summary
    set "summary=!summary!%%m: !percent!%% (!module_pass!/!module_total!)"
    echo !summary! >> "%outfile%"
    
    echo. >> "%outfile%"
    echo ------------------- >> "%outfile%"
    echo. >> "%outfile%"
)

:: Calculate overall percentage
if %total_tests% equ 0 (
    set "overall_percent=0.0"
) else (
    set /a "overall_percent=(total_passes*100)/total_tests"
)

:: Create final summary at the beginning
set "temp_file=%TEMP%\test_temp_%RANDOM%.txt"
type "%outfile%" > "%temp_file%"
(
    echo Test Results - %datetime%
    echo ===================
    echo.
    echo Overall Pass Rate: %overall_percent%%% (%total_passes%/%total_tests%^)
    echo.
    echo Module Results:
    echo %summary%
    echo.
    echo ===================
    echo.
    type "%temp_file%"
) > "%outfile%"
del "%temp_file%"

echo Tests completed. Results saved to %outfile%
echo Overall Pass Rate: %overall_percent%%% (%total_passes%/%total_tests% tests passed^)

endlocal
