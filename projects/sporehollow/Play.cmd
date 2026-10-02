@echo off
if exist "%~dp0build\WhistleRanch.exe" (
  start "" "%~dp0build\WhistleRanch.exe"
) else if exist "%~dp0.tools\Godot_v4.7.2-stable_win64.exe" (
  start "" "%~dp0.tools\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
) else (
  echo Run tools\setup.ps1 and dev.ps1 build first. See README.md.
  pause
)
