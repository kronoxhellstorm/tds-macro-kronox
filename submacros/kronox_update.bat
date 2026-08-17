@echo off
setlocal DisableDelayedExpansion
chcp 65001 >nul

set "DOWNLOAD_URL=%~1"
set "MACRO_DIR=%~2"
set "TARGET_VERSION=%~3"
set "NO_LAUNCH=%~4"

if "%DOWNLOAD_URL%"=="" exit /b 1
if "%MACRO_DIR%"=="" exit /b 1
if "%TARGET_VERSION%"=="" set "TARGET_VERSION=unknown"

if not exist "%MACRO_DIR%\Main.ahk" (
    echo Macro installation not found: %MACRO_DIR%
    pause
    exit /b 1
)

if exist "%MACRO_DIR%\.git" (
    echo Automatic updates are disabled for Git working copies.
    echo Open the GitHub release page and update with Git instead.
    pause
    exit /b 1
)

set "UPDATE_ROOT=%TEMP%\KronoxMacroUpdate_%RANDOM%_%RANDOM%"
set "ZIP_PATH=%UPDATE_ROOT%\release.zip"
set "STAGE_DIR=%UPDATE_ROOT%\stage"
set "BACKUP_ROOT=%LOCALAPPDATA%\Ultimate_Macro\UpdateBackups"
set "BACKUP_DIR=%BACKUP_ROOT%\%TARGET_VERSION%_%RANDOM%_%RANDOM%"
set "LOG_FILE=%LOCALAPPDATA%\Ultimate_Macro\last_update.log"

mkdir "%UPDATE_ROOT%" >nul 2>&1
mkdir "%STAGE_DIR%" >nul 2>&1
mkdir "%BACKUP_DIR%" >nul 2>&1

>"%LOG_FILE%" echo Updating to %TARGET_VERSION%
>>"%LOG_FILE%" echo Source: %DOWNLOAD_URL%
>>"%LOG_FILE%" echo Install: %MACRO_DIR%
>>"%LOG_FILE%" echo Backup: %BACKUP_DIR%

echo Downloading Kronox Edition %TARGET_VERSION%...
if exist "%DOWNLOAD_URL%" (
    copy /y "%DOWNLOAD_URL%" "%ZIP_PATH%" >nul
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_PATH%'"
)
if errorlevel 1 goto :download_failed
if not exist "%ZIP_PATH%" goto :download_failed

echo Extracting release into a staging folder...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Expand-Archive -LiteralPath '%ZIP_PATH%' -DestinationPath '%STAGE_DIR%' -Force"
if errorlevel 1 goto :extract_failed

set "PACKAGE_DIR="
if exist "%STAGE_DIR%\Main.ahk" set "PACKAGE_DIR=%STAGE_DIR%"
if not defined PACKAGE_DIR (
    for /d %%D in ("%STAGE_DIR%\*") do (
        if exist "%%~fD\Main.ahk" if not defined PACKAGE_DIR set "PACKAGE_DIR=%%~fD"
    )
)

if not defined PACKAGE_DIR goto :invalid_package
if not exist "%PACKAGE_DIR%\submacros\updater.ahk" goto :invalid_package
if not exist "%PACKAGE_DIR%\Resources" goto :invalid_package

echo Backing up the current installation...
robocopy "%MACRO_DIR%" "%BACKUP_DIR%" /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /XD "%MACRO_DIR%\.git" >nul
if errorlevel 8 goto :backup_failed

echo Installing the update without deleting custom files...
robocopy "%PACKAGE_DIR%" "%MACRO_DIR%" /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /XD "%PACKAGE_DIR%\.git" "%PACKAGE_DIR%\.github" >nul
if errorlevel 8 goto :install_failed

>>"%LOG_FILE%" echo Update completed successfully.
echo Update completed successfully.
echo Backup saved to: %BACKUP_DIR%

rmdir /s /q "%UPDATE_ROOT%" >nul 2>&1
timeout /t 2 >nul

if /i "%NO_LAUNCH%"=="--no-launch" exit /b 0

if exist "%MACRO_DIR%\Main.ahk" (
    start "" "%MACRO_DIR%\Main.ahk"
) else if exist "%MACRO_DIR%\ultimate_macro.exe" (
    start "" "%MACRO_DIR%\ultimate_macro.exe"
)
exit /b 0

:download_failed
>>"%LOG_FILE%" echo ERROR: Download failed.
echo Download failed. Your current installation was not changed.
goto :failed

:extract_failed
>>"%LOG_FILE%" echo ERROR: Extraction failed.
echo Extraction failed. Your current installation was not changed.
goto :failed

:invalid_package
>>"%LOG_FILE%" echo ERROR: Package validation failed.
echo The downloaded package is missing required Kronox Edition files.
echo Your current installation was not changed.
goto :failed

:backup_failed
>>"%LOG_FILE%" echo ERROR: Backup failed.
echo The updater could not create a complete backup, so installation was cancelled.
goto :failed

:install_failed
>>"%LOG_FILE%" echo ERROR: Installation failed. Restoring backup.
echo Installation failed. Restoring the previous installation...
robocopy "%BACKUP_DIR%" "%MACRO_DIR%" /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 >nul
echo Restore attempt completed. See %LOG_FILE% for details.
goto :failed

:failed
rmdir /s /q "%UPDATE_ROOT%" >nul 2>&1
pause
exit /b 1
