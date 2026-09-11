# ============================================================
# Verify Microsoft Notepad - Targeted Check
# Requires Administrator privileges
#
# IMPORTANT:
# This script intentionally performs NO full-drive recursive scan.
#
# It checks only:
#   1. Microsoft.WindowsNotepad AppX package
#   2. Microsoft.WindowsNotepad provisioned package
#   3. WindowsApps immediate Notepad package folders
#   4. Current user's Notepad package folder
#   5. Current user's TEMP root for Notepad-named files/folders
#   6. PATH-resolved notepad.exe
#   7. Standard Windows notepad.exe paths (reported separately)
#
# Exit codes:
#   0 = No Microsoft Store Notepad package/provisioning and no
#       targeted Notepad files found
#   1 = Notepad package/provisioning or targeted Notepad items found
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=========================================="
Write-Host " MICROSOFT NOTEPAD TARGETED VERIFICATION"
Write-Host "=========================================="
Write-Host ""

$foundItems = New-Object System.Collections.Generic.List[string]
$storeNotepadFound = $false
$targetedFileFound = $false

# 1. AppX
Write-Host "[CHECK] AppX: Microsoft.WindowsNotepad"
$installed = @(Get-AppxPackage -AllUsers -Name "Microsoft.WindowsNotepad")

if ($installed.Count -gt 0) {
    $storeNotepadFound = $true
    foreach ($pkg in $installed) {
        Write-Host "[FOUND] Installed AppX"
        Write-Host "  Version      : $($pkg.Version)"
        Write-Host "  Package      : $($pkg.PackageFullName)"
        Write-Host "  Install Path : $($pkg.InstallLocation)"
        $foundItems.Add("AppX: $($pkg.PackageFullName)")
    }
}
else {
    Write-Host "[PASS] AppX package not installed."
}

Write-Host ""

# 2. Provisioned
Write-Host "[CHECK] Provisioned package: Microsoft.WindowsNotepad"
$provisioned = @(Get-AppxProvisionedPackage -Online |
    Where-Object { $_.DisplayName -eq "Microsoft.WindowsNotepad" })

if ($provisioned.Count -gt 0) {
    $storeNotepadFound = $true
    foreach ($pkg in $provisioned) {
        Write-Host "[FOUND] Provisioned Notepad package"
        Write-Host "  Version : $($pkg.Version)"
        Write-Host "  Package : $($pkg.PackageName)"
        $foundItems.Add("Provisioned: $($pkg.PackageName)")
    }
}
else {
    Write-Host "[PASS] Notepad is not provisioned."
}

Write-Host ""

# 3. WindowsApps - immediate children only
Write-Host "[CHECK] WindowsApps Notepad package folders"
$windowsApps = Join-Path $env:ProgramFiles "WindowsApps"

if (Test-Path -LiteralPath $windowsApps -PathType Container) {
    $dirs = @(Get-ChildItem -LiteralPath $windowsApps -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "Microsoft.WindowsNotepad_*" })

    if ($dirs.Count -gt 0) {
        foreach ($dir in $dirs) {
            $storeNotepadFound = $true
            Write-Host "[FOUND] $($dir.FullName)"
            $foundItems.Add("WindowsApps: $($dir.FullName)")
        }
    }
    else {
        Write-Host "[PASS] No Notepad package folder found."
    }
}
else {
    Write-Host "[INFO] WindowsApps path is inaccessible."
}

Write-Host ""

# 4. Current user's package folder - exact known path only
Write-Host "[CHECK] Current user's Notepad package folder"
$userPackage = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe"

if (Test-Path -LiteralPath $userPackage -PathType Container) {
    $targetedFileFound = $true
    Write-Host "[FOUND] $userPackage"
    $foundItems.Add("User package: $userPackage")
}
else {
    Write-Host "[PASS] Current user's Notepad package folder not found."
}

Write-Host ""

# 5. TEMP - root only, names containing "notepad"
Write-Host "[CHECK] TEMP root for Notepad-named files/folders"
$temp = $env:TEMP

if (Test-Path -LiteralPath $temp -PathType Container) {
    $tempFiles = @(Get-ChildItem -LiteralPath $temp -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*notepad*" })

    $tempDirs = @(Get-ChildItem -LiteralPath $temp -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*notepad*" })

    if ($tempFiles.Count -eq 0 -and $tempDirs.Count -eq 0) {
        Write-Host "[PASS] No Notepad-named items in TEMP root."
    }
    else {
        foreach ($item in ($tempFiles + $tempDirs)) {
            $targetedFileFound = $true
            Write-Host "[FOUND] $($item.FullName)"
            $foundItems.Add("TEMP: $($item.FullName)")
        }
    }
}
else {
    Write-Host "[INFO] TEMP path is inaccessible."
}

Write-Host ""

# 6. PATH resolution
Write-Host "[CHECK] PATH-resolved notepad.exe"
$command = Get-Command notepad.exe -ErrorAction SilentlyContinue

if ($command -and $command.Source) {
    Write-Host "[FOUND] $($command.Source)"
    $targetedFileFound = $true
    $foundItems.Add("PATH: $($command.Source)")
}
else {
    Write-Host "[PASS] notepad.exe not resolved from PATH."
}

Write-Host ""

# 7. Standard OS copies - informational only
Write-Host "[CHECK] Standard Windows notepad.exe paths (informational)"
$systemPaths = @(
    (Join-Path $env:WINDIR "System32\notepad.exe"),
    (Join-Path $env:WINDIR "SysWOW64\notepad.exe")
)

foreach ($path in $systemPaths) {
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Write-Host "[INFO] Present: $path"
        Write-Host "       This may be part of Windows and is not used alone"
        Write-Host "       to determine Microsoft Store Notepad installation."
    }
    else {
        Write-Host "[INFO] Not present: $path"
    }
}

Write-Host ""
Write-Host "=========================================="

if (-not $storeNotepadFound -and -not $targetedFileFound) {
    Write-Host "FINAL RESULT: MICROSOFT STORE NOTEPAD NOT FOUND"
    Write-Host "AppX/provisioned package and targeted Notepad locations are clean."
    Write-Host "STATUS: REMOVED / NOT INSTALLED"
    Write-Host "=========================================="
    exit 0
}

Write-Host "FINAL RESULT: NOTEPAD-RELATED ITEM(S) FOUND"
Write-Host "STATUS: NOT COMPLETELY CLEAN"
Write-Host ""
foreach ($item in ($foundItems | Sort-Object -Unique)) {
    Write-Host "  - $item"
}
Write-Host "=========================================="
exit 1
