@echo off
chcp 65001 >nul
title Discord Fake Mute / Deafen Installer
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
if %errorlevel% neq 0 (
    pause
)
exit
