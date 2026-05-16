@echo off
title Disable Windows SmartScreen

echo Deaktiviere Windows Defender SmartScreen...

reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer" ^
/v "SmartScreenEnabled" ^
/t REG_SZ ^
/d "Off" ^
/f

echo.
echo Fertig.
pause