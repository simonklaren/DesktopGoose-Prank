@echo off
setlocal EnableExtensions
set "TASK_NAME=GooseWatchdog"

schtasks /end /tn "%TASK_NAME%" >nul 2>&1
schtasks /change /tn "%TASK_NAME%" /disable
if errorlevel 1 (
    echo [ERROR] Could not disable GooseWatchdog. Try running this file as administrator.
    pause
    exit /b 1
)

echo [OK] GooseWatchdog is disabled. The installed files were left in place.
pause
endlocal
