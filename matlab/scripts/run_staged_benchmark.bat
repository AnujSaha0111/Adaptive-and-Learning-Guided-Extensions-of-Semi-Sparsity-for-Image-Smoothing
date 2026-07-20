@echo off
REM ====================================================
REM  Staged Benchmark Runner for MATLAB
REM  Usage: run_staged_benchmark.bat
REM ====================================================

echo.
echo ============================================
echo  Staged Benchmark Pipeline
echo ============================================
echo.
echo This script runs all 4 stages of the
echo experimental benchmark in MATLAB.
echo.
echo Prerequisites:
echo   - MATLAB R2018b or later on PATH
echo   - All required toolboxes
echo.
echo Press any key to start, or close this window to cancel.
pause >nul

echo.
echo Starting MATLAB batch execution...
echo.

matlab -batch "run_staged_benchmark"

if %ERRORLEVEL% NEQ 0 (
    echo.
echo MATLAB exited with error code %ERRORLEVEL%.
    echo Check the MATLAB console for details.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ============================================
echo  Pipeline completed successfully!
echo ============================================
echo.
echo Reports generated:
echo   STAGE1_REPORT.md
echo   STAGE2_REPORT.md
echo   STAGE3_REPORT.md
echo   FULL_BENCHMARK_REPORT.md
echo.
pause
