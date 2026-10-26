# ==========================================================
# SCCM / Configuration Manager Automation
# Author  : Jagadish V
# Version : 1.0.0
# ==========================================================

Clear-Host

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " CONFIGURATION MANAGER CLIENT RECOVERY" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------
# Check Administrator
# ----------------------------------------------------------

$Admin = [Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()

if (-not $Admin.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Write-Host "ERROR: Please run this script as Administrator." -ForegroundColor Red
    Write-Host ""
    Read-Host "Press ENTER to exit"
    exit
}

Write-Host "Administrator check: PASS" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------
# Check SCCM Service
# ----------------------------------------------------------

Write-Host "Checking Configuration Manager service..." -ForegroundColor Yellow

$Service = Get-Service -Name "CcmExec" -ErrorAction SilentlyContinue

if (-not $Service) {

    Write-Host "ERROR: CcmExec service not found." -ForegroundColor Red
    Write-Host "Configuration Manager client may not be installed."
    Write-Host ""

    Read-Host "Press ENTER to exit"
    exit
}

Write-Host "Service found: CcmExec" -ForegroundColor Green
Write-Host "Current Status: $($Service.Status)"
Write-Host ""

# ----------------------------------------------------------
# Stop SCClient processes if running
# ----------------------------------------------------------

Write-Host "Closing Configuration Manager related processes..." -ForegroundColor Yellow

$Processes = @(
    "SCClient",
    "CcmExec"
)

foreach ($ProcessName in $Processes) {

    $Process = Get-Process `
        -Name $ProcessName `
        -ErrorAction SilentlyContinue

    if ($Process) {

        Write-Host "Found: $ProcessName"

        # Only close SCClient directly
        if ($ProcessName -eq "SCClient") {

            try {
                Stop-Process `
                    -Name "SCClient" `
                    -Force `
                    -ErrorAction Stop

                Write-Host "SCClient closed successfully." -ForegroundColor Green
            }
            catch {
                Write-Host "Could not close SCClient." -ForegroundColor Yellow
            }
        }
    }
    else {

        Write-Host "$ProcessName not currently running."

    }
}

Write-Host ""

# ----------------------------------------------------------
# Restart SCCM Client Service
# ----------------------------------------------------------

Write-Host "Restarting Configuration Manager Client (CcmExec)..." -ForegroundColor Yellow

try {

    $CurrentService = Get-Service -Name "CcmExec"

    if ($CurrentService.Status -eq "Running") {

        Stop-Service `
            -Name "CcmExec" `
            -Force `
            -ErrorAction Stop

        Write-Host "CcmExec stopped successfully." -ForegroundColor Green

        Start-Sleep -Seconds 5
    }

    Start-Service `
        -Name "CcmExec" `
        -ErrorAction Stop

    Write-Host "CcmExec started successfully." -ForegroundColor Green

}
catch {

    Write-Host "ERROR restarting CcmExec." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    Write-Host ""
    Read-Host "Press ENTER to exit"
    exit
}

Write-Host ""

# ----------------------------------------------------------
# Wait for SCCM Client
# ----------------------------------------------------------

Write-Host "Waiting for Configuration Manager client..." -ForegroundColor Yellow

$MaxAttempts = 12
$Attempt = 1

while ($Attempt -le $MaxAttempts) {

    Start-Sleep -Seconds 5

    $ServiceStatus = (Get-Service -Name "CcmExec").Status

    Write-Host "Check $Attempt/$MaxAttempts - CcmExec: $ServiceStatus"

    if ($ServiceStatus -eq "Running") {

        Write-Host ""
        Write-Host "Configuration Manager service is running." -ForegroundColor Green

        break
    }

    $Attempt++
}

Write-Host ""

# ----------------------------------------------------------
# Check WMI Namespace
# ----------------------------------------------------------

Write-Host "Checking Configuration Manager WMI..." -ForegroundColor Yellow

try {

    $Baselines = Get-CimInstance `
        -Namespace "root\ccm\dcm" `
        -ClassName "SMS_DesiredConfiguration" `
        -ErrorAction Stop

    Write-Host "WMI Check: PASS" -ForegroundColor Green
    Write-Host "Configuration Baselines Found: $($Baselines.Count)"

}
catch {

    Write-Host "WMI Check: FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

}

Write-Host ""

# ----------------------------------------------------------
# Check Current Evaluation Queue
# ----------------------------------------------------------

Write-Host "Checking current Configuration Manager processes..." -ForegroundColor Yellow
Write-Host ""

Get-Process `
    -Name "CcmExec","SCClient" `
    -ErrorAction SilentlyContinue |
Select-Object `
    Name,
    Id,
    CPU,
    WorkingSet |
Format-Table -AutoSize

# ----------------------------------------------------------
# Final Result
# ----------------------------------------------------------

$FinalService = Get-Service -Name "CcmExec"

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " FINAL STATUS" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Write-Host "CcmExec Status : $($FinalService.Status)"

if ($FinalService.Status -eq "Running") {

    Write-Host "RESULT: PASS - SCCM Client is running normally." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Step:"
    Write-Host "1. Close Control Panel"
    Write-Host "2. Wait 1-2 minutes"
    Write-Host "3. Open Control Panel"
    Write-Host "4. Open Configuration Manager"
    Write-Host "5. Click the Configurations tab"

}
else {

    Write-Host "RESULT: FAIL - SCCM Client service is not running." -ForegroundColor Red

}

Write-Host ""
Write-Host "=================================================="
Write-Host "Script completed."
Write-Host "=================================================="

Read-Host "Press ENTER to exit"