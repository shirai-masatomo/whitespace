@echo off
chcp 65001 >nul
set "DIU_BUILD=%~dp0..\..\build\releases\629e5d0ad7237fe140fa1bd1db568334d32d568c-equipment-preview"
if not exist "%DIU_BUILD%\DiveInUnder.exe" exit /b 1
if not exist "%DIU_BUILD%\DiveInUnder.pck" exit /b 1
set "APPDATA=%DIU_BUILD%\preview-user-data"
set "LOCALAPPDATA=%DIU_BUILD%\preview-local-data"
if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
start "" /D "%DIU_BUILD%" "%DIU_BUILD%\DiveInUnder.exe"
