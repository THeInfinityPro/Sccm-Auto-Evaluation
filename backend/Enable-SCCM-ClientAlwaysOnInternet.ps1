# Enable SCCM ClientAlwaysOnInternet
# Requires Administrator privileges

$ErrorActionPreference = "Stop"

$RegistryPath = "HKLM:\SOFTWARE\Microsoft\CCM\Security"
$ValueName = "ClientAlwaysOnInternet"

Write-Host "=========================================="
Write-Host " SCCM CLIENT ALWAYS ON INTERNET"
Write-Host "=========================================="
Write-Host ""

try {
    if (-not (Test-Path $RegistryPath)) {
        Write-Host "[ERROR] Registry path was not found:"
        Write-Host "        $RegistryPath"
        exit 1
    }

    $property = Get-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction SilentlyContinue

    if ($null -eq $property) {
        Write-Host "[ERROR] Registry value '$ValueName' was not found."
        Write-Host "        No registry value was created or changed."
        exit 1
    }

    $currentValue = [int]$property.$ValueName
    Write-Host "[INFO] Current value: $ValueName = $currentValue"

    if ($currentValue -eq 1) {
        Write-Host "[SUCCESS] ClientAlwaysOnInternet is already enabled (1)."
        exit 0
    }

    if ($currentValue -ne 0) {
        Write-Host "[WARNING] Unexpected value detected: $currentValue"
        Write-Host "[INFO] This script only changes 0 to 1."
        exit 1
    }

    Write-Host "[INFO] Changing ClientAlwaysOnInternet from 0 to 1..."
    Set-ItemProperty -Path $RegistryPath -Name $ValueName -Value 1 -Type DWord -ErrorAction Stop

    $verifiedValue = [int](Get-ItemPropertyValue -Path $RegistryPath -Name $ValueName -ErrorAction Stop)

    if ($verifiedValue -eq 1) {
        Write-Host "[SUCCESS] ClientAlwaysOnInternet changed from 0 to 1."
        Write-Host "[SUCCESS] Registry value verified: $verifiedValue"
        exit 0
    }

    Write-Host "[ERROR] Registry verification failed. Current value: $verifiedValue"
    exit 1
}
catch {
    Write-Host "[ERROR] Failed to update ClientAlwaysOnInternet: $($_.Exception.Message)"
    exit 1
}
