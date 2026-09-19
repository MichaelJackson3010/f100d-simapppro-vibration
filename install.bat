@echo off
rem Double-click launcher for install.ps1.
rem Runs the script with PowerShell's script policy bypassed for this one run
rem only (nothing is changed system-wide), and keeps the window open on errors.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
if errorlevel 1 (
    echo.
    echo Setup did not finish - see the messages above.
    pause
)
