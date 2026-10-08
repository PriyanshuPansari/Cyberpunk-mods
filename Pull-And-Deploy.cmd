@echo off
cd /d "%~dp0"
python tools\Pull-And-Deploy.py
set "sdpDeployExit=%ERRORLEVEL%"
if not "%sdpDeployExit%"=="0" echo Pull/deploy failed. Read the error above; do not launch with a partial update.
pause
exit /b %sdpDeployExit%
