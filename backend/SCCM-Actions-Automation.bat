@echo off
setlocal EnableExtensions

:: ==========================================================
:: Configuration Manager - Actions Automation
:: Author  : Jagadish V
:: Version : 1.0.0
:: Purpose : Automate Configuration Manager client actions
:: ==========================================================

title Configuration Manager - Actions Automation

echo ==================================================
echo  Configuration Manager Actions Automation
echo  Author: Jagadish V
echo  Version: 1.0.0
echo ==================================================
echo.

set "PSFILE=%TEMP%\ConfigMgr_Full_Evaluation_%RANDOM%%RANDOM%.ps1"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$src='%~f0'; $out='%PSFILE%'; Get-Content -LiteralPath $src | Where-Object { $_.StartsWith('::PS:') } | ForEach-Object { $_.Substring(5) } | Set-Content -LiteralPath $out -Encoding UTF8"

if not exist "%PSFILE%" (
    echo ERROR: Unable to create PowerShell script.
    pause
    exit /b 1
)

echo Starting Configuration Manager evaluation...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PSFILE%"

del "%PSFILE%" >nul 2>&1

echo.
echo ==================================================
echo Script finished.
echo ==================================================
pause
exit /b


::PS:# ==========================================================
::PS:# CONFIGURATION MANAGER FULL EVALUATION
::PS:# ACTIONS TAB + CONFIGURATIONS TAB
::PS:# ==========================================================
::PS:
::PS:Clear-Host
::PS:
::PS:$Today = (Get-Date).Date
::PS:$Namespace = "root\ccm\dcm"
::PS:$ClassName = "SMS_DesiredConfiguration"
::PS:
::PS:# ==========================================================
::PS:# ADMINISTRATOR CHECK
::PS:# ==========================================================
::PS:
::PS:$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
::PS:$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
::PS:
::PS:if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
::PS:    Write-Host ""
::PS:    Write-Host "ERROR: Please run this BAT file as Administrator." -ForegroundColor Red
::PS:    exit 1
::PS:}
::PS:
::PS:Write-Host "==================================================" -ForegroundColor Cyan
::PS:Write-Host " CONFIGURATION MANAGER FULL EVALUATION TOOL" -ForegroundColor Cyan
::PS:Write-Host "==================================================" -ForegroundColor Cyan
::PS:Write-Host ""
::PS:Write-Host "Started: $(Get-Date)"
::PS:
::PS:# ==========================================================
::PS:# CHECK CONFIGURATION MANAGER SERVICE
::PS:# ==========================================================
::PS:
::PS:$CCMService = Get-Service -Name "CcmExec" -ErrorAction SilentlyContinue
::PS:
::PS:if (-not $CCMService) {
::PS:    Write-Host ""
::PS:    Write-Host "ERROR: Configuration Manager client (CcmExec) not found." -ForegroundColor Red
::PS:    exit 1
::PS:}
::PS:
::PS:if ($CCMService.Status -ne "Running") {
::PS:
::PS:    Write-Host ""
::PS:    Write-Host "CcmExec is not running. Starting service..." -ForegroundColor Yellow
::PS:
::PS:    try {
::PS:        Start-Service -Name CcmExec -ErrorAction Stop
::PS:        Start-Sleep -Seconds 10
::PS:    }
::PS:    catch {
::PS:        Write-Host "ERROR: Unable to start CcmExec." -ForegroundColor Red
::PS:        exit 1
::PS:    }
::PS:}
::PS:
::PS:Write-Host ""
::PS:Write-Host "CcmExec Status: $((Get-Service CcmExec).Status)" -ForegroundColor Green
::PS:
::PS:# ==========================================================
::PS:# ACTIONS TAB
::PS:# EXACT ACTIONS FROM CONFIGURATION MANAGER
::PS:# EACH ACTION RUNS 2 TIMES
::PS:# ==========================================================
::PS:
::PS:Write-Host ""
::PS:Write-Host "==================================================" -ForegroundColor Cyan
::PS:Write-Host " CONFIGURATION MANAGER - ACTIONS TAB" -ForegroundColor Cyan
::PS:Write-Host " EACH ACTION WILL RUN 2 TIMES" -ForegroundColor Cyan
::PS:Write-Host "==================================================" -ForegroundColor Cyan
::PS:
::PS:$Actions = @(
::PS:    @{
::PS:        Name = "Application Deployment Evaluation Cycle"
::PS:        IDs = @("{00000000-0000-0000-0000-000000000121}")
::PS:    },
::PS:    @{
::PS:        Name = "Discovery Data Collection Cycle"
::PS:        IDs = @("{00000000-0000-0000-0000-000000000003}")
::PS:    },
::PS:    @{
::PS:        Name = "File Collection Cycle"
::PS:        IDs = @("{00000000-0000-0000-0000-000000000010}")
::PS:    },
::PS:    @{
::PS:        Name = "Hardware Inventory Cycle"
::PS:        IDs = @("{00000000-0000-0000-0000-000000000001}")
::PS:    },
::PS:    @{
::PS:        Name = "Machine Policy Retrieval & Evaluation Cycle"
::PS:        IDs = @(
::PS:            "{00000000-0000-0000-0000-000000000021}",
::PS:            "{00000000-0000-0000-0000-000000000022}"
::PS:        )
::PS:    },
::PS:    @{
::PS:        Name = "Software Inventory Cycle"
::PS:        IDs = @("{00000000-0000-0000-0000-000000000002}")
::PS:    },
::PS:    @{
::PS:        Name = "Software Metering Usage Report Cycle"
::PS:        IDs = @("{00000000-0000-0000-0000-000000000031}")
::PS:    },
::PS:    @{
::PS:        Name = "Software Updates Deployment Evaluation Cycle"
::PS:        IDs = @("{00000000-0000-0000-0000-000000000108}")
::PS:    },
::PS:    @{
::PS:        Name = "Software Updates Scan Cycle"
::PS:        IDs = @("{00000000-0000-0000-0000-000000000113}")
::PS:    },
::PS:    @{
::PS:        Name = "User Policy Retrieval & Evaluation Cycle"
::PS:        IDs = @(
::PS:            "{00000000-0000-0000-0000-000000000026}",
::PS:            "{00000000-0000-0000-0000-000000000027}"
::PS:        )
::PS:    },
::PS:    @{
::PS:        Name = "Windows Installer Source List Update Cycle"
::PS:        IDs = @("{00000000-0000-0000-0000-000000000032}")
::PS:    }
::PS:)
::PS:
::PS:$ActionSuccess = 0
::PS:$ActionFail = 0
::PS:
::PS:foreach ($Action in $Actions) {
::PS:
::PS:    Write-Host ""
::PS:    Write-Host "--------------------------------------------------" -ForegroundColor Yellow
::PS:    Write-Host "ACTION: $($Action.Name)" -ForegroundColor Yellow
::PS:    Write-Host "--------------------------------------------------" -ForegroundColor Yellow
::PS:
::PS:    for ($Run = 1; $Run -le 2; $Run++) {
::PS:
::PS:        Write-Host ""
::PS:        Write-Host "Run $Run of 2" -ForegroundColor Cyan
::PS:
::PS:        foreach ($ScheduleID in $Action.IDs) {
::PS:
::PS:            try {
::PS:
::PS:                Invoke-CimMethod `
::PS:                    -Namespace "root\ccm" `
::PS:                    -ClassName "SMS_Client" `
::PS:                    -MethodName "TriggerSchedule" `
::PS:                    -Arguments @{sScheduleID = $ScheduleID} `
::PS:                    -ErrorAction Stop | Out-Null
::PS:
::PS:                Write-Host "SUCCESS - $ScheduleID" -ForegroundColor Green
::PS:                $ActionSuccess++
::PS:            }
::PS:            catch {
::PS:                Write-Host "FAILED - $ScheduleID" -ForegroundColor Red
::PS:                Write-Host $_.Exception.Message -ForegroundColor DarkYellow
::PS:                $ActionFail++
::PS:            }
::PS:
::PS:            Start-Sleep -Seconds 3
::PS:        }
::PS:
::PS:        if ($Run -eq 1) {
::PS:            Write-Host ""
::PS:            Write-Host "Waiting 10 seconds before second run..." -ForegroundColor DarkGray
::PS:            Start-Sleep -Seconds 10
::PS:        }
::PS:    }
::PS:
::PS:    Write-Host "Waiting 5 seconds before next action..." -ForegroundColor DarkGray
::PS:    Start-Sleep -Seconds 5
::PS:}
::PS:
::PS:Write-Host ""
::PS:Write-Host "==================================================" -ForegroundColor Cyan
::PS:Write-Host " ACTIONS TAB COMPLETED" -ForegroundColor Cyan
::PS:Write-Host "==================================================" -ForegroundColor Cyan
::PS:Write-Host "Successful requests: $ActionSuccess" -ForegroundColor Green
::PS:Write-Host "Failed requests    : $ActionFail" -ForegroundColor Yellow
::PS:
::PS:# ==========================================================
::PS:# WAIT FOR CLIENT PROCESSING
::PS:# ==========================================================
::PS:
::PS:Write-Host ""
::PS:Write-Host "Waiting 30 seconds for Configuration Manager processing..." -ForegroundColor Cyan
::PS:Start-Sleep -Seconds 30
::PS:
::PS:# ==========================================================
::PS:# FUNCTION - GET BASELINES NOT EVALUATED TODAY
::PS:# ==========================================================
::PS:
::PS:function Get-OldBaselines {
::PS:
::PS:    $CurrentDate = (Get-Date).Date
::PS:
::PS:    try {
::PS:
::PS:        $Baselines = Get-CimInstance `
::PS:            -Namespace $Namespace `
::PS:            -ClassName $ClassName `
::PS:            -ErrorAction Stop
::PS:
::PS:        $OldBaselines = @()
::PS:
::PS:        foreach ($Baseline in $Baselines) {
::PS:
::PS:            if (-not $Baseline.LastEvalTime) {
::PS:                $OldBaselines += $Baseline
::PS:                continue
::PS:            }
::PS:
::PS:            try {
::PS:
::PS:                $LastEval = [datetime]$Baseline.LastEvalTime
::PS:
::PS:                if ($LastEval.Date -ne $CurrentDate) {
::PS:                    $OldBaselines += $Baseline
::PS:                }
::PS:            }
::PS:            catch {
::PS:                $OldBaselines += $Baseline
::PS:            }
::PS:        }
::PS:
::PS:        return $OldBaselines
::PS:    }
::PS:    catch {
::PS:        Write-Host "ERROR: Unable to read Configuration baselines." -ForegroundColor Red
::PS:        return @()
::PS:    }
::PS:}
::PS:
::PS:# ==========================================================
::PS:# FUNCTION - EVALUATE BASELINE
::PS:# ==========================================================
::PS:
::PS:function Invoke-BaselineEvaluation {
::PS:
::PS:    param($Baseline)
::PS:
::PS:    Write-Host ""
::PS:    Write-Host "Evaluating: $($Baseline.DisplayName)" -ForegroundColor Yellow
::PS:    Write-Host "Previous : $($Baseline.LastEvalTime)"
::PS:
::PS:    try {
::PS:
::PS:        $Arguments = @{
::PS:            IsEnforced      = $false
::PS:            IsMachineTarget = [bool]$Baseline.IsMachineTarget
::PS:            Name            = [string]$Baseline.Name
::PS:            PolicyType      = [uint32]$Baseline.PolicyType
::PS:            Version         = [string]$Baseline.Version
::PS:        }
::PS:
::PS:        Invoke-CimMethod `
::PS:            -Namespace $Namespace `
::PS:            -ClassName $ClassName `
::PS:            -MethodName "TriggerEvaluation" `
::PS:            -Arguments $Arguments `
::PS:            -ErrorAction Stop | Out-Null
::PS:
::PS:        Write-Host "SUCCESS - Evaluation requested" -ForegroundColor Green
::PS:        return $true
::PS:    }
::PS:    catch {
::PS:
::PS:        Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
::PS:        return $false
::PS:    }
::PS:}
::PS:
::PS:# ==========================================================
::PS:# CONFIGURATIONS TAB
::PS:# ==========================================================
::PS:
::PS:Write-Host ""
::PS:Write-Host "==================================================" -ForegroundColor Cyan
::PS:Write-Host " CONFIGURATION BASELINE EVALUATION" -ForegroundColor Cyan
::PS:Write-Host "==================================================" -ForegroundColor Cyan
::PS:
::PS:$AllBaselines = @(Get-CimInstance -Namespace $Namespace -ClassName $ClassName -ErrorAction SilentlyContinue)
::PS:$OldBaselines = @(Get-OldBaselines)
::PS:
::PS:Write-Host ""
::PS:Write-Host "Total Baselines : $($AllBaselines.Count)"
::PS:Write-Host "Need Evaluation : $($OldBaselines.Count)" -ForegroundColor Yellow
::PS:
::PS:if ($OldBaselines.Count -gt 0) {
::PS:
::PS:    Write-Host ""
::PS:    Write-Host "Starting baseline evaluation..." -ForegroundColor Cyan
::PS:
::PS:    foreach ($Baseline in $OldBaselines) {
::PS:
::PS:        Invoke-BaselineEvaluation -Baseline $Baseline | Out-Null
::PS:        Start-Sleep -Seconds 3
::PS:    }
::PS:}
::PS:else {
::PS:    Write-Host ""
::PS:    Write-Host "All baselines are already evaluated today." -ForegroundColor Green
::PS:}
::PS:
::PS:# ==========================================================
::PS:# MONITOR FOR 10 MINUTES
::PS:# ==========================================================
::PS:
::PS:Write-Host ""
::PS:Write-Host "==================================================" -ForegroundColor Cyan
::PS:Write-Host " MONITORING CONFIGURATION BASELINES - 10 MINUTES" -ForegroundColor Cyan
::PS:Write-Host "==================================================" -ForegroundColor Cyan
::PS:
::PS:$MaxChecks = 20
::PS:
::PS:for ($Check = 1; $Check -le $MaxChecks; $Check++) {
::PS:
::PS:    Start-Sleep -Seconds 30
::PS:
::PS:    $Remaining = @(Get-OldBaselines)
::PS:
::PS:    Write-Host ""
::PS:    Write-Host "Check $Check / $MaxChecks" -ForegroundColor Cyan
::PS:    Write-Host "Baselines still waiting: $($Remaining.Count)" -ForegroundColor Yellow
::PS:
::PS:    if ($Remaining.Count -eq 0) {
::PS:        Write-Host ""
::PS:        Write-Host "SUCCESS - ALL BASELINES EVALUATED TODAY!" -ForegroundColor Green
::PS:        break
::PS:    }
::PS:
::PS:    # Retry remaining baselines every 2 minutes
::PS:    if (($Check % 4) -eq 0 -and $Check -lt $MaxChecks) {
::PS:
::PS:        Write-Host ""
::PS:        Write-Host "Retrying remaining baselines..." -ForegroundColor Yellow
::PS:
::PS:        foreach ($Baseline in $Remaining) {
::PS:            Invoke-BaselineEvaluation -Baseline $Baseline | Out-Null
::PS:            Start-Sleep -Seconds 3
::PS:        }
::PS:    }
::PS:}
::PS:
::PS:# ==========================================================
::PS:# FINAL RESULTS
::PS:# ==========================================================
::PS:
::PS:Write-Host ""
::PS:Write-Host "==================================================" -ForegroundColor Cyan
::PS:Write-Host " FINAL CONFIGURATION RESULTS" -ForegroundColor Cyan
::PS:Write-Host "==================================================" -ForegroundColor Cyan
::PS:
::PS:$FinalBaselines = @(Get-CimInstance -Namespace $Namespace -ClassName $ClassName -ErrorAction SilentlyContinue)
::PS:$FinalToday = (Get-Date).Date
::PS:
::PS:$Results = foreach ($Baseline in $FinalBaselines) {
::PS:
::PS:    $Status = "FAIL"
::PS:    $LastEvaluation = $Baseline.LastEvalTime
::PS:
::PS:    if ($Baseline.LastEvalTime) {
::PS:        try {
::PS:            $EvalDate = [datetime]$Baseline.LastEvalTime
::PS:
::PS:            if ($EvalDate.Date -eq $FinalToday) {
::PS:                $Status = "PASS"
::PS:            }
::PS:        }
::PS:        catch {}
::PS:    }
::PS:
::PS:    [PSCustomObject]@{
::PS:        BaselineName     = $Baseline.DisplayName
::PS:        LastEvaluation   = $LastEvaluation
::PS:        ComplianceStatus = $Baseline.LastComplianceStatus
::PS:        EvaluationStatus = $Status
::PS:    }
::PS:}
::PS:
::PS:$Results |
::PS:    Sort-Object EvaluationStatus, BaselineName |
::PS:    Format-Table -AutoSize -Wrap
::PS:
::PS:# ==========================================================
::PS:# FINAL SUMMARY
::PS:# ==========================================================
::PS:
::PS:$PassCount = @($Results | Where-Object {$_.EvaluationStatus -eq "PASS"}).Count
::PS:$FailCount = @($Results | Where-Object {$_.EvaluationStatus -eq "FAIL"}).Count
::PS:
::PS:Write-Host ""
::PS:Write-Host "==================================================" -ForegroundColor Cyan
::PS:Write-Host " FINAL SUMMARY" -ForegroundColor Cyan
::PS:Write-Host "==================================================" -ForegroundColor Cyan
::PS:
::PS:Write-Host ""
::PS:Write-Host "ACTIONS TAB" -ForegroundColor Yellow
::PS:Write-Host "Successful schedule requests : $ActionSuccess" -ForegroundColor Green
::PS:Write-Host "Failed schedule requests     : $ActionFail" -ForegroundColor Red
::PS:
::PS:Write-Host ""
::PS:Write-Host "CONFIGURATIONS TAB" -ForegroundColor Yellow
::PS:Write-Host "Total Baselines : $($Results.Count)"
::PS:Write-Host "PASS Today      : $PassCount" -ForegroundColor Green
::PS:Write-Host "FAIL Old Date   : $FailCount" -ForegroundColor Red
::PS:
::PS:Write-Host ""
::PS:Write-Host "==================================================" -ForegroundColor Cyan
::PS:Write-Host "Completed: $(Get-Date)" -ForegroundColor Cyan
::PS:Write-Host "==================================================" -ForegroundColor Cyan