@echo off
setlocal EnableDelayedExpansion

:: Create tests directory if it doesn't exist
if not exist "..\tests" mkdir "..\tests"

:: Generate timestamp for the test file
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set "timestamp=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%_%datetime:~8,2%-%datetime:~10,2%-%datetime:~12,2%"
set "TEST_OUTPUT_FILE=..\tests\core_test-%timestamp%.txt"

:: Array of core modules to test
set "modules[1]=reduce"
set "modules[2]=expand"
set "modules[3]=enhance"
set "modules[4]=search"
set "modules[5]=mutate"
set "modules[6]=generate"
set "modules[7]=iterate"
set "modules[8]=translate"
set "modules[9]=converse"
set "modules[10]=parse"
set "modules[11]=evaluate"
set "modules[12]=imagine"
set "module_count=12"

:: Create initial output file
echo Test Results - %timestamp% > "%TEST_OUTPUT_FILE%"
echo =================== >> "%TEST_OUTPUT_FILE%"
echo. >> "%TEST_OUTPUT_FILE%"

:: Initialize counters
set "total_passes=0"
set "total_tests=0"

:: Run tests for each module
for /l %%i in (1,1,%module_count%) do (
    set "module=!modules[%%i]!"
    echo Testing !module!...
    echo ## !module! ## >> "%TEST_OUTPUT_FILE%"
    echo. >> "%TEST_OUTPUT_FILE%"
    
    :: Get initial counts
    set "initial_passes=0"
    set "initial_fails=0"
    for /f %%a in ('findstr /c:"[PASS]" "%TEST_OUTPUT_FILE%" ^| find /c /v ""') do set "initial_passes=%%a"
    for /f %%a in ('findstr /c:"[FAIL]" "%TEST_OUTPUT_FILE%" ^| find /c /v ""') do set "initial_fails=%%a"
    
    :: Run tests and capture output
    spout "!module!" -t >> "%TEST_OUTPUT_FILE%"
    
    :: Get current counts
    set "current_passes=0"
    set "current_fails=0"
    for /f %%a in ('findstr /c:"[PASS]" "%TEST_OUTPUT_FILE%" ^| find /c /v ""') do set "current_passes=%%a"
    for /f %%a in ('findstr /c:"[FAIL]" "%TEST_OUTPUT_FILE%" ^| find /c /v ""') do set "current_fails=%%a"
    
    :: Calculate module results
    set /a "module_pass=current_passes-initial_passes"
    set /a "module_fail=current_fails-initial_fails"
    set /a "module_total=module_pass+module_fail"
    
    :: Store results
    set "module_passes[%%i]=!module_pass!"
    set "module_fails[%%i]=!module_fail!"
    set "module_totals[%%i]=!module_total!"
    
    :: Update totals
    set /a "total_passes+=module_pass"
    set /a "total_tests+=module_total"
    
    echo. >> "%TEST_OUTPUT_FILE%"
    echo ------------------- >> "%TEST_OUTPUT_FILE%"
    echo. >> "%TEST_OUTPUT_FILE%"
)

:: Create summary
set "summary="
for /l %%i in (1,1,%module_count%) do (
    set "module=!modules[%%i]!"
    set /a "passes=module_passes[%%i]"
    set /a "total=module_totals[%%i]"
    
    :: Calculate percentage
    if !total! equ 0 (
        set "percent=0.0"
    ) else (
        set /a "percent=(passes*100)/total"
    )
    
    set "summary=!summary!!module!: !percent!%% (!passes!/!total!)"
    if not %%i equ %module_count% set "summary=!summary!^

"
)

:: Calculate overall percentage
if %total_tests% equ 0 (
    set "overall_percent=0.0"
) else (
    set /a "overall_percent=(total_passes*100)/total_tests"
)

:: Create temporary file for summary
set "temp_file=%temp%\test_core_temp.txt"
type "%TEST_OUTPUT_FILE%" > "%temp_file%"

:: Write final output with summary
(
    echo Test Results - %timestamp%
    echo ===================
    echo.
    echo Overall Pass Rate: %overall_percent%%% (%total_passes%/%total_tests%^)
    echo.
    echo Module Results:
    echo !summary!
    echo.
    echo ===================
    echo.
    type "%temp_file%"
) > "%TEST_OUTPUT_FILE%"

del "%temp_file%"

echo Tests completed. Results saved to %TEST_OUTPUT_FILE%
echo Overall Pass Rate: %overall_percent%%% (%total_passes%/%total_tests% tests passed)
