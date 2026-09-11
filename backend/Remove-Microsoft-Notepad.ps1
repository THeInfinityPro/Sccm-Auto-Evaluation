# ============================================================
# Remove Microsoft Notepad
# Requires Administrator privileges
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host "=========================================="
Write-Host " REMOVE MICROSOFT NOTEPAD"
Write-Host "=========================================="
Write-Host ""

try {
    $appx = Get-AppxPackage -AllUsers -Name "Microsoft.WindowsNotepad" -ErrorAction SilentlyContinue

    if ($appx) {
        Write-Host "[INFO] Removing installed AppX package..."
        $appx | ForEach-Object {
            Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop
        }
        Write-Host "[SUCCESS] Installed Notepad AppX package removal requested."
    } else {
        Write-Host "[INFO] Microsoft.WindowsNotepad AppX package was not installed."
    }

    $prov = Get-AppxProvisionedPackage -Online |
        Where-Object { $_.DisplayName -eq "Microsoft.WindowsNotepad" }

    if ($prov) {
        Write-Host "[INFO] Removing provisioned Notepad package..."
        $prov | ForEach-Object {
            Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop | Out-Null
        }
        Write-Host "[SUCCESS] Provisioned Notepad package removed."
    } else {
        Write-Host "[INFO] Microsoft.WindowsNotepad was not provisioned."
    }

    Write-Host ""
    Write-Host "[INFO] Verifying AppX state..."

    $verify = Get-AppxPackage -AllUsers -Name "Microsoft.WindowsNotepad" -ErrorAction SilentlyContinue
    $verifyProv = Get-AppxProvisionedPackage -Online |
        Where-Object { $_.DisplayName -eq "Microsoft.WindowsNotepad" }

    if (-not $verify -and -not $verifyProv) {
        Write-Host "[SUCCESS] Microsoft Notepad AppX package is no longer installed or provisioned."
        exit 0
    }

    Write-Host "[WARNING] Microsoft Notepad is still present in AppX/provisioned state."
    exit 1
}
catch {
    Write-Host "[ERROR] Notepad removal failed: $($_.Exception.Message)"
    exit 1
}
