@echo off
chcp 65001 >nul
set "DIU_BUILD=%~dp0..\..\build\releases\49824a2f90694ef11d393461d711fc82474fbd72-enemy-art"
if not exist "%DIU_BUILD%\DiveInUnder.exe" exit /b 1
if not exist "%DIU_BUILD%\DiveInUnder.pck" exit /b 1
set "APPDATA=%DIU_BUILD%\preview-user-data"
set "LOCALAPPDATA=%DIU_BUILD%\preview-local-data"
if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
start "" /D "%DIU_BUILD%" "%DIU_BUILD%\DiveInUnder.exe"
