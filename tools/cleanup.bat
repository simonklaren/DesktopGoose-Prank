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
set "GOOSE_DIR=%INSTALL_DIR%\DesktopGoose-Prank"
set "BACKUP_DIR=%INSTALL_DIR%\DesktopGoose-Prank.backup"
set "TASK_NAME=GooseWatchdog"

echo [*] Removing Desktop Goose and its scheduled watchdog...
taskkill /f /im GooseDesktop.exe >nul 2>&1
schtasks /end /tn "%TASK_NAME%" >nul 2>&1
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

if exist "%GOOSE_DIR%" rmdir /s /q "%GOOSE_DIR%"
if exist "%BACKUP_DIR%" rmdir /s /q "%BACKUP_DIR%"
del /q "%INSTALL_DIR%\watchdog.vbs" "%INSTALL_DIR%\debug.enabled" "%INSTALL_DIR%\watchdog.log" >nul 2>&1

if exist "%GOOSE_DIR%" (
    echo [ERROR] Could not completely remove "%GOOSE_DIR%".
    pause
    exit /b 1
)

:: Remove the parent only when it is empty; preserve unrelated/legacy prank files.
rmdir "%INSTALL_DIR%" >nul 2>&1

echo [OK] Desktop Goose - Prank Edition and GooseWatchdog were removed.
pause
endlocal
