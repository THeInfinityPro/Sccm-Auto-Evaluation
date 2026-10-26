# Restart SCCM / Microsoft Configuration Manager Client Services
# Requires Administrator privileges

$ErrorActionPreference = "Stop"

Write-Host "==========================================" 
Write-Host " SCCM CLIENT SERVICE RESTART"
Write-Host "=========================================="
Write-Host ""

$services = @(
    "CcmExec"
)

foreach ($serviceName in $services) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    if (-not $service) {
        Write-Host "[ERROR] Service '$serviceName' was not found."
        exit 1
    }

    Write-Host "[INFO] Current status: $($service.DisplayName) = $($service.Status)"

    try {
        if ($service.Status -eq "Running") {
            Write-Host "[INFO] Restarting $($service.DisplayName)..."
            Restart-Service -Name $serviceName -Force -ErrorAction Stop
        }
        else {
            Write-Host "[INFO] Service is not running. Starting $($service.DisplayName)..."
            Start-Service -Name $serviceName -ErrorAction Stop
        }

        $service.WaitForStatus(
            [System.ServiceProcess.ServiceControllerStatus]::Running,
            (New-TimeSpan -Seconds 30)
        )

        $service.Refresh()

        if ($service.Status -eq "Running") {
            Write-Host "[SUCCESS] $($service.DisplayName) is RUNNING."
        }
        else {
            Write-Host "[ERROR] $($service.DisplayName) did not reach RUNNING state."
            exit 1
        }
    }
    catch {
        Write-Host "[ERROR] Failed to restart/start $($service.DisplayName): $($_.Exception.Message)"
        exit 1
    }
}

Write-Host ""
Write-Host "=========================================="
Write-Host " SCCM SERVICE RESTART COMPLETED"
Write-Host "=========================================="
exit 0
