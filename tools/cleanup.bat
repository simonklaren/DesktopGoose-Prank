@echo off
setlocal EnableExtensions
color 0C

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo [*] Requesting administrator rights...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "INSTALL_DIR=%USERPROFILE%\GoosePrank"
set "TASK_NAME=GooseWatchdog"

echo [*] Removing Desktop Goose and its scheduled watchdog...
taskkill /f /im GooseDesktop.exe >nul 2>&1
schtasks /end /tn "%TASK_NAME%" >nul 2>&1
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
if exist "%INSTALL_DIR%" (
    echo [ERROR] Could not completely remove "%INSTALL_DIR%".
    pause
    exit /b 1
)

echo [OK] Desktop Goose and GooseWatchdog were removed.
pause
endlocal
