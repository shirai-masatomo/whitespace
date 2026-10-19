@echo off
chcp 65001 >nul
set "DIU_BUILD=%~dp0..\..\build\releases\aa7e81397dd3140bcf899cdd904d7754bb5d82a3-warehouse-preview"
if not exist "%DIU_BUILD%\DiveInUnder.exe" exit /b 1
if not exist "%DIU_BUILD%\DiveInUnder.pck" exit /b 1
set "APPDATA=%DIU_BUILD%\preview-user-data"
set "LOCALAPPDATA=%DIU_BUILD%\preview-local-data"
set "DIU_SAVE=%APPDATA%\Godot\app_userdata\Dive In Under — 戦闘基盤"
if not exist "%DIU_SAVE%" mkdir "%DIU_SAVE%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
if not exist "%DIU_SAVE%\campaign-v1.json" copy "%~dp0campaign-smoke.json" "%DIU_SAVE%\campaign-v1.json" >nul
start "" /D "%DIU_BUILD%" "%DIU_BUILD%\DiveInUnder.exe"
