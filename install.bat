@echo off
setlocal
set "DEST_DIR=C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\KwaKillCounter"
if not exist "%DEST_DIR%" (
    mkdir "%DEST_DIR%"
)
copy "%~dp0KwaKillCounter.lua" "%DEST_DIR%\"
copy "%~dp0KwaKillCounter.toc" "%DEST_DIR%\"

echo Files copied successfully to %DEST_DIR%
sleep 2