# ==========================================================
# Configuration Manager Baseline Evaluation
# Author  : Jagadish V
# Version : 1.0.0
# Purpose : Evaluate Configuration Manager baselines and
#           monitor evaluation status for 10 minutes
# ==========================================================

Clear-Host

$Namespace = "root\ccm\dcm"
$ClassName = "SMS_DesiredConfiguration"
$Today = (Get-Date).Date

# ==========================================================
# ADMINISTRATOR CHECK
# ==========================================================

$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentUser)

if (-not $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Write-Host ""
    Write-Host "ERROR: Run this script as Administrator." -ForegroundColor Red
    Read-Host "Press ENTER to exit"
    exit
}

# ==========================================================
# CHECK CCMEXEC
# ==========================================================

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " CONFIGURATION MANAGER BASELINE EVALUATION" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Current Date : $(Get-Date -Format 'dd-MM-yyyy HH:mm:ss')"
Write-Host "Maximum Time : 10 Minutes"
Write-Host ""

$CCMService = Get-Service -Name "CcmExec" -ErrorAction SilentlyContinue

if (-not $CCMService) {
    Write-Host "ERROR: CcmExec service not found." -ForegroundColor Red
    Read-Host "Press ENTER to exit"
    exit
}

if ($CCMService.Status -ne "Running") {

    Write-Host "CcmExec is not running. Starting service..." -ForegroundColor Yellow

    try {
        Start-Service -Name "CcmExec" -ErrorAction Stop
        Start-Sleep -Seconds 10

        Write-Host "CcmExec started successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Unable to start CcmExec." -ForegroundColor Red
        Write-Host $_.Exception.Message
        Read-Host "Press ENTER to exit"
        exit
    }
}
else {
    Write-Host "CcmExec Status : Running" -ForegroundColor Green
}

# ==========================================================
# FUNCTION - GET BASELINES NOT EVALUATED TODAY
# ==========================================================

function Get-OldBaselines {

    $CurrentDate = (Get-Date).Date

    try {

        $Baselines = Get-CimInstance `
            -Namespace $Namespace `
            -ClassName $ClassName `
            -ErrorAction Stop

        $OldBaselines = @()

        foreach ($Baseline in $Baselines) {

            if (-not $Baseline.LastEvalTime) {

                $OldBaselines += $Baseline
                continue
            }

            try {

                $LastEval = [datetime]$Baseline.LastEvalTime

                if ($LastEval.Date -ne $CurrentDate) {
                    $OldBaselines += $Baseline
                }
            }
            catch {
                $OldBaselines += $Baseline
            }
        }

        return $OldBaselines
    }
    catch {

        Write-Host "ERROR reading Configuration Manager WMI." -ForegroundColor Red
        Write-Host $_.Exception.Message

        return @()
    }
}

# ==========================================================
# FUNCTION - TRIGGER ONE BASELINE
# ==========================================================

function Invoke-BaselineEvaluation {

    param(
        $Baseline
    )

    Write-Host ""
    Write-Host "----------------------------------------------"
    Write-Host "Baseline : $($Baseline.DisplayName)" -ForegroundColor Yellow

    if ($Baseline.LastEvalTime) {
        Write-Host "Previous : $($Baseline.LastEvalTime)"
    }
    else {
        Write-Host "Previous : Never"
    }

    $Requested = $false

    # Try both values because different Configuration
    # Manager policies may require different enforcement mode.
    foreach ($EnforcedValue in @($true, $false)) {

        try {

            $Arguments = @{
                IsEnforced      = [bool]$EnforcedValue
                IsMachineTarget = [bool]$Baseline.IsMachineTarget
                Name            = [string]$Baseline.Name
                PolicyType      = [uint32]$Baseline.PolicyType
                Version         = [string]$Baseline.Version
            }

            Invoke-CimMethod `
                -Namespace $Namespace `
                -ClassName $ClassName `
                -MethodName "TriggerEvaluation" `
                -Arguments $Arguments `
                -ErrorAction Stop | Out-Null

            Write-Host "Requested with IsEnforced=$EnforcedValue" `
                -ForegroundColor Green

            $Requested = $true
        }
        catch {

            Write-Host "Not accepted with IsEnforced=$EnforcedValue" `
                -ForegroundColor DarkYellow
        }
    }

    if (-not $Requested) {
        Write-Host "WARNING: Evaluation request failed." -ForegroundColor Red
    }
}

# ==========================================================
# INITIAL CHECK
# ==========================================================

Write-Host ""
Write-Host "Reading Configuration Manager baselines..." -ForegroundColor Yellow

$AllBaselines = Get-CimInstance `
    -Namespace $Namespace `
    -ClassName $ClassName `
    -ErrorAction Stop

$OldBaselines = @(Get-OldBaselines)

Write-Host ""
Write-Host "Total Baselines       : $($AllBaselines.Count)"
Write-Host "Need Evaluation Today : $($OldBaselines.Count)" -ForegroundColor Yellow

# ==========================================================
# INITIAL EVALUATION
# ==========================================================

if ($OldBaselines.Count -eq 0) {

    Write-Host ""
    Write-Host "All baselines are already evaluated today!" `
        -ForegroundColor Green
}
else {

    Write-Host ""
    Write-Host "Starting evaluation requests..." -ForegroundColor Cyan

    foreach ($Baseline in $OldBaselines) {
        Invoke-BaselineEvaluation -Baseline $Baseline
    }
}

# ==========================================================
# 10 MINUTE MONITORING
# ==========================================================

Write-Host ""
Write-Host "=================================================="
Write-Host " MONITORING FOR 10 MINUTES"
Write-Host " Retry interval: Every 2 minutes"
Write-Host " Check interval: Every 30 seconds"
Write-Host "=================================================="

$MaxAttempts = 20
$Attempt = 1

while ($Attempt -le $MaxAttempts) {

    Start-Sleep -Seconds 30

    $Remaining = @(Get-OldBaselines)

    Write-Host ""
    Write-Host "----------------------------------------------"
    Write-Host "Check $Attempt / $MaxAttempts"
    Write-Host "Time elapsed: $($Attempt * 30) seconds"
    Write-Host "Remaining old baselines: $($Remaining.Count)"

    # Stop immediately when all are evaluated
    if ($Remaining.Count -eq 0) {

        Write-Host ""
        Write-Host "==================================================" -ForegroundColor Green
        Write-Host " SUCCESS - ALL BASELINES EVALUATED TODAY" -ForegroundColor Green
        Write-Host "==================================================" -ForegroundColor Green

        break
    }

    # Retry every 2 minutes
    if (($Attempt % 4) -eq 0 -and $Attempt -lt $MaxAttempts) {

        Write-Host ""
        Write-Host "Retrying only remaining baselines..." `
            -ForegroundColor Cyan

        foreach ($Baseline in $Remaining) {

            Invoke-BaselineEvaluation -Baseline $Baseline
        }
    }

    $Attempt++
}

# ==========================================================
# FINAL RESULTS
# ==========================================================

Write-Host ""
Write-Host "=================================================="
Write-Host " READING FINAL RESULTS"
Write-Host "=================================================="

$FinalBaselines = Get-CimInstance `
    -Namespace $Namespace `
    -ClassName $ClassName `
    -ErrorAction Stop

$Today = (Get-Date).Date

$Results = foreach ($Baseline in $FinalBaselines) {

    $EvaluationStatus = "FAIL"
    $LastEvaluation = $Baseline.LastEvalTime

    if ($Baseline.LastEvalTime) {

        try {

            $LastEvalDate = [datetime]$Baseline.LastEvalTime

            if ($LastEvalDate.Date -eq $Today) {
                $EvaluationStatus = "PASS"
            }
        }
        catch {
            $EvaluationStatus = "FAIL"
        }
    }
    else {
        $LastEvaluation = "Never"
    }

    [PSCustomObject]@{
        BaselineName       = $Baseline.DisplayName
        LastEvaluation     = $LastEvaluation
        ComplianceStatus   = $Baseline.LastComplianceStatus
        EvaluationStatus   = $EvaluationStatus
    }
}

# ==========================================================
# DISPLAY RESULTS
# ==========================================================

Write-Host ""
Write-Host "=================================================="
Write-Host " UPDATED CONFIGURATION RESULTS"
Write-Host "=================================================="
Write-Host ""

$Results |
    Sort-Object EvaluationStatus, BaselineName |
    Format-Table -AutoSize -Wrap

# ==========================================================
# FINAL SUMMARY
# ==========================================================

$PassCount = @(
    $Results | Where-Object {
        $_.EvaluationStatus -eq "PASS"
    }
).Count

$FailCount = @(
    $Results | Where-Object {
        $_.EvaluationStatus -eq "FAIL"
    }
).Count

Write-Host ""
Write-Host "=================================================="
Write-Host " FINAL SUMMARY"
Write-Host "=================================================="
Write-Host "Total Baselines : $($Results.Count)"
Write-Host "PASS Today      : $PassCount" -ForegroundColor Green
Write-Host "FAIL Old Date   : $FailCount" -ForegroundColor Red
Write-Host "=================================================="

if ($FailCount -eq 0) {

    Write-Host ""
    Write-Host "RESULT: SUCCESS - ALL BASELINES EVALUATED TODAY." `
        -ForegroundColor Green
}
else {

    Write-Host ""
    Write-Host "RESULT: WARNING - SOME BASELINES REMAIN OLD." `
        -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Script finished."
Write-Host ""

Read-Host "Press ENTER to exit"