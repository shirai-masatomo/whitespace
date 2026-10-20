@echo off
chcp 65001 >nul
set "DIU_REL=windows"
if exist "%~dp0..\..\build\current.txt" set /p DIU_REL=<"%~dp0..\..\build\current.txt"
set "DIU_BUILD=%~dp0..\..\build\%DIU_REL%"
if not exist "%DIU_BUILD%\DiveInUnder.exe" (
  echo Windows EXEがありません。確認ページのCI ZIPを同じ構成で展開してください。
  pause
  exit /b 1
)
if not exist "%DIU_BUILD%\DiveInUnder.pck" (
  echo EXEと同じ場所のPCKがありません。起動を中止します。
  pause
  exit /b 1
)
start "" /D "%DIU_BUILD%" "%DIU_BUILD%\DiveInUnder.exe" -- --debug-run
