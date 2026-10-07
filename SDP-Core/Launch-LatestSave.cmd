@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Launch-LatestSave.ps1"
if errorlevel 1 pause
