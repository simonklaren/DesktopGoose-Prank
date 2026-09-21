@echo off
setlocal EnableExtensions
color 0A

:: Vraag automatisch administratorrechten aan.
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo [*] Administratorrechten worden aangevraagd...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "INSTALL_DIR=%USERPROFILE%\GoosePrank"
set "GOOSE_DIR=%INSTALL_DIR%\DesktopGoose"
set "SOURCE_DIR=%~dp0"
set "SOURCE_GOOSE=%SOURCE_DIR%DesktopGoose"
set "TASK_NAME=GooseWatchdog"

echo.
echo ==========================================
echo        Desktop Goose prank setup
echo ==========================================
echo.
echo Kies een modus:
echo   [1] Normaal - stil op de achtergrond
echo   [2] Debug  - meldingen en logbestand
echo.
choice /c 12 /n /m "Keuze: "
if errorlevel 2 (
    set "DEBUG_MODE=1"
) else (
    set "DEBUG_MODE=0"
)

echo.
echo [*] Bestanden worden gecontroleerd...

if not exist "%SOURCE_GOOSE%\GooseDesktop.exe" (
    echo [FOUT] GooseDesktop.exe niet gevonden.
    echo Verwachte locatie:
    echo   "%SOURCE_GOOSE%\GooseDesktop.exe"
    echo.
    echo Zet setup.bat, cleanup.bat en watchdog.vbs naast de map DesktopGoose.
    pause
    exit /b 1
)

if not exist "%SOURCE_GOOSE%\Assets" (
    echo [FOUT] De map Assets ontbreekt in DesktopGoose.
    pause
    exit /b 1
)

if not exist "%SOURCE_DIR%watchdog.vbs" (
    echo [FOUT] watchdog.vbs niet gevonden naast setup.bat.
    pause
    exit /b 1
)

:: Oude installatie en taak opruimen.
echo [*] Eventuele oude installatie wordt gestopt...
taskkill /f /im GooseDesktop.exe >nul 2>&1
taskkill /f /im wscript.exe >nul 2>&1
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
mkdir "%GOOSE_DIR%" >nul 2>&1

:: Kopieer de volledige DesktopGoose-map, inclusief assets en DLL's.
echo [*] Desktop Goose wordt gekopieerd...
robocopy "%SOURCE_GOOSE%" "%GOOSE_DIR%" /E /COPY:DAT /R:2 /W:1 >nul
set "ROBOCOPY_RESULT=%errorlevel%"
if %ROBOCOPY_RESULT% GEQ 8 (
    echo [FOUT] Kopieren van DesktopGoose is mislukt. Robocopy-code: %ROBOCOPY_RESULT%
    pause
    exit /b 1
)

copy /Y "%SOURCE_DIR%watchdog.vbs" "%INSTALL_DIR%\watchdog.vbs" >nul
if errorlevel 1 (
    echo [FOUT] watchdog.vbs kon niet worden gekopieerd.
    pause
    exit /b 1
)

:: Debugmodus wordt door watchdog.vbs uit dit bestand gelezen.
if "%DEBUG_MODE%"=="1" (
    >"%INSTALL_DIR%\debug.enabled" echo enabled
    echo [*] Debugmodus staat AAN.
) else (
    del /q "%INSTALL_DIR%\debug.enabled" >nul 2>&1
    echo [*] Debugmodus staat UIT.
)

:: Maak de taak bij iedere login, vijf minuten vertraagd en met hoogste rechten.
echo [*] Geplande taak wordt aangemaakt...
schtasks /create ^
    /tn "%TASK_NAME%" ^
    /tr "wscript.exe \"%INSTALL_DIR%\watchdog.vbs\"" ^
    /sc ONLOGON ^
    /delay 0005:00 ^
    /rl HIGHEST ^
    /ru "%USERDOMAIN%\%USERNAME%" ^
    /it ^
    /f

if errorlevel 1 (
    echo.
    echo [FOUT] De geplande taak kon niet worden aangemaakt.
    echo Controleer de bovenstaande foutmelding.
    pause
    exit /b 1
)

echo.
echo [*] Installatie direct testen...
schtasks /run /tn "%TASK_NAME%"
if errorlevel 1 (
    echo [WAARSCHUWING] De taak is gemaakt, maar kon niet direct worden gestart.
    echo Controleer Taakplanner en "%INSTALL_DIR%\watchdog.log".
) else (
    echo [OK] De watchdog is gestart.
)

echo.
echo [OK] Desktop Goose is geinstalleerd.
echo Locatie: "%INSTALL_DIR%"
if "%DEBUG_MODE%"=="1" echo Debuglog: "%INSTALL_DIR%\watchdog.log"
echo.
pause
endlocal
