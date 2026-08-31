@echo off
title Configuration Manager Recovery

@echo off

:: ==========================================================
:: SCCM /    Recovery Configuration Manager 
:: Author  : Jagadish V
:: Version : 1.0.0
:: ==========================================================

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Fix_CM_Configuration_Tab.ps1"

echo.
pause