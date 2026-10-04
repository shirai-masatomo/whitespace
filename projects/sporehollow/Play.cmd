@echo off
chcp 65001 >nul
if not exist "%~dp0build\WhistleRanch.exe" (
  echo ゲーム本体がありません。dev.ps1 build で作成してください。
  pause
  exit /b 1
)
start "" /D "%~dp0build" "%~dp0build\WhistleRanch.exe"
