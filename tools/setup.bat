@echo off
setlocal EnableExtensions
color 0A

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo [*] Requesting administrator rights...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "INSTALL_DIR=%USERPROFILE%\GoosePrank"
set "GOOSE_DIR=%INSTALL_DIR%\DesktopGoose-Prank"
set "SOURCE_GOOSE=%~dp0.."
set "TASK_NAME=GooseWatchdog"

echo.
echo ==========================================
echo       Desktop Goose - Prank Edition
echo ==========================================
echo.
echo Choose a mode:
echo   [1] Normal - silent background watchdog
echo   [2] Debug  - messages and a log file
choice /c 12 /n /m "Choice: "
if errorlevel 2 (set "DEBUG_MODE=1") else (set "DEBUG_MODE=0")

if not exist "%SOURCE_GOOSE%\GooseDesktop.exe" (
    echo [ERROR] GooseDesktop.exe was not found in "%SOURCE_GOOSE%".
    echo Run this copy of setup.bat from the tools folder inside the distribution.
    pause
    exit /b 1
)
if not exist "%SOURCE_GOOSE%\Assets" (
    echo [ERROR] The Assets folder is missing.
    pause
    exit /b 1
)
if not exist "%~dp0watchdog.vbs" (
    echo [ERROR] watchdog.vbs is missing next to setup.bat.
    pause
    exit /b 1
)

echo [*] Stopping the previous prank task and Goose process...
taskkill /f /im GooseDesktop.exe >nul 2>&1
schtasks /end /tn "%TASK_NAME%" >nul 2>&1
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

if exist "%GOOSE_DIR%" (
    echo [*] Backing up the previous installed files...
    robocopy "%GOOSE_DIR%" "%INSTALL_DIR%\DesktopGoose-Prank.backup" /E /COPY:DAT /R:2 /W:1 >nul
)

mkdir "%GOOSE_DIR%" >nul 2>&1
echo [*] Copying Desktop Goose...
robocopy "%SOURCE_GOOSE%" "%GOOSE_DIR%" /E /COPY:DAT /R:2 /W:1 /XD tools >nul
set "ROBOCOPY_RESULT=%errorlevel%"
if %ROBOCOPY_RESULT% GEQ 8 (
    echo [ERROR] Copy failed with Robocopy code %ROBOCOPY_RESULT%.
    pause
    exit /b 1
)

copy /Y "%~dp0watchdog.vbs" "%INSTALL_DIR%\watchdog.vbs" >nul
if "%DEBUG_MODE%"=="1" (
    >"%INSTALL_DIR%\debug.enabled" echo enabled
) else (
    del /q "%INSTALL_DIR%\debug.enabled" >nul 2>&1
)

echo [*] Creating the visible GooseWatchdog task at logon...
schtasks /create /tn "%TASK_NAME%" /tr "wscript.exe \"%INSTALL_DIR%\watchdog.vbs\"" /sc ONLOGON /delay 0005:00 /rl HIGHEST /ru "%USERDOMAIN%\%USERNAME%" /it /f
if errorlevel 1 (
    echo [ERROR] The scheduled task could not be created.
    pause
    exit /b 1
)

schtasks /run /tn "%TASK_NAME%" >nul
echo [OK] Installed at "%INSTALL_DIR%".
echo Run tools\cleanup.bat from the distribution to remove it.
pause
endlocal
