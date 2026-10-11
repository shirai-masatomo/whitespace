@echo off
rem Keep CRLF line endings.
chcp 65001 >nul
if not exist "%~dp0artifacts\autonomy-entry-01\bundle\WhistleRanch-Autonomy-Partial.exe" (
  echo 最新のゲーム本体がありません。dev.ps1 build で作成してください。
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\launch_current.ps1"
