@echo off
title Configuration Manager Evaluation
@echo off

:: ==========================================================
:: SCCM / Configuration Manager Automation
:: Author  : Jagadish V
:: Version : 1.0.0
:: ==========================================================

PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Evaluate_CM_Baselines_10Min.ps1"

echo.
echo ==========================================
echo Script completed.
echo ==========================================
pause