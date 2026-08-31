@echo off
title SCCM Auto Evaluation Launcher

echo ================================================
echo      SCCM Auto Evaluation Launcher v1.2.0
echo      Author : Jagadish V
echo ================================================
echo.

:: Launch GUI as Administrator with temporary execution policy
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
"Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0.internal\SCCM-Auto-Evaluation-GUI.ps1""'"

exit