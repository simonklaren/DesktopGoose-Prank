@echo off
setlocal EnableExtensions
color 0C

:: Vraag automatisch administratorrechten aan.
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo [*] Administratorrechten worden aangevraagd...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "INSTALL_DIR=%USERPROFILE%\GoosePrank"
set "TASK_NAME=GooseWatchdog"

echo.
echo [*] Desktop Goose wordt verwijderd...

taskkill /f /im GooseDesktop.exe >nul 2>&1

:: Stop alleen de watchdog via de geplande taak voordat deze wordt verwijderd.
schtasks /end /tn "%TASK_NAME%" >nul 2>&1
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

:: Een eventueel achtergebleven watchdog-proces stopt uiterlijk bij afmelden.
:: We doden niet blind alle wscript-processen, omdat andere scripts kunnen draaien.

if exist "%INSTALL_DIR%" (
    rmdir /s /q "%INSTALL_DIR%"
    if exist "%INSTALL_DIR%" (
        echo [FOUT] De installatiemap kon niet volledig worden verwijderd:
        echo   "%INSTALL_DIR%"
        echo Sluit eventueel Goose of Windows Script Host en probeer opnieuw.
        pause
        exit /b 1
    )
)

echo [OK] Desktop Goose en de geplande taak zijn verwijderd.
pause
endlocal
