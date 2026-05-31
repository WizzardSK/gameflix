@echo off
REM gameflix Windows installer — double-click counterpart of mount.sh.
REM Runs webflix.ps1 (registers the play:// handler) via PowerShell, bypassing
REM execution policy without changing any machine setting.
echo === gameflix: installing play:// handler ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/WizzardSK/gameflix/main/webflix.ps1 | iex"
echo.
pause
