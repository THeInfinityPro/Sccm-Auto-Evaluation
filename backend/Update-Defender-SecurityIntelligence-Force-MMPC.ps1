# ============================================================
# Microsoft Defender Security Intelligence Update - Force MMPC
#
# Purpose:
#   Try the normal Defender update source first, then explicitly
#   request the latest security intelligence from Microsoft Malware
#   Protection Center (MMPC).
#
# IMPORTANT:
#   - Does not hard-code a signature version.
#   - Does not disable Defender.
#   - Does not change WSUS/SCCM policies automatically.
#   - Reports configured update-source policy if the update fails.
#   - Requires Administrator privileges.
# ============================================================

$ErrorActionPreference = "Stop"

function Write-Status {
    param([string]$Message)

    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$time] $Message"
}

function Get-DefenderStatus {
    return Get-MpComputerStatus -ErrorAction Stop
}

function Find-MpCmdRun {
    $candidates = @(
        "$env:ProgramFiles\Windows Defender\MpCmdRun.exe"
    )

    $platformRoot = Join-Path $env:ProgramData "Microsoft\Windows Defender\Platform"

    if (Test-Path $platformRoot) {
        $latestPlatform = Get-ChildItem `
            -Path $platformRoot `
            -Directory `
            -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            Select-Object -First 1

        if ($latestPlatform) {
            $candidates += Join-Path $latestPlatform.FullName "MpCmdRun.exe"
        }
    }

    return $candidates |
        Where-Object { Test-Path $_ } |
        Select-Object -First 1
}

Write-Host ""
Write-Host "============================================================"
Write-Host " MICROSOFT DEFENDER SECURITY INTELLIGENCE UPDATE"
Write-Host " NORMAL SOURCE + FORCED MMPC FALLBACK"
Write-Host "============================================================"
Write-Host ""

# Administrator check
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Write-Status "ERROR: Run this script as Administrator."
    exit 1
}

Write-Status "Privilege: Administrator"

# Current status
try {
    $before = Get-DefenderStatus
}
catch {
    Write-Status "ERROR: Unable to query Microsoft Defender status."
    Write-Status $_.Exception.Message
    exit 1
}

$oldVersion = [string]$before.AntivirusSignatureVersion
$oldDate    = $before.AntivirusSignatureLastUpdated

Write-Status "Installed Security Intelligence: $oldVersion"

if ($oldDate) {
    Write-Status "Installed Last Update: $oldDate"
}

# Show current update-source configuration.
try {
    $preference = Get-MpPreference -ErrorAction Stop

    Write-Host ""
    Write-Status "Configured signature update fallback order:"

    if ($preference.SignatureFallbackOrder) {
        Write-Status ([string]$preference.SignatureFallbackOrder)
    }
    else {
        Write-Status "(not explicitly configured)"
    }
}
catch {
    Write-Status "WARNING: Could not read Defender update-source policy."
}

Write-Host ""
Write-Status "Step 1: Running normal Update-MpSignature..."

$normalSucceeded = $false

try {
    Update-MpSignature -ErrorAction Stop
    $normalSucceeded = $true
    Write-Status "Update-MpSignature completed."
}
catch {
    Write-Status "Update-MpSignature failed:"
    Write-Status $_.Exception.Message
}

Start-Sleep -Seconds 5

try {
    $afterNormal = Get-DefenderStatus
    $normalVersion = [string]$afterNormal.AntivirusSignatureVersion
}
catch {
    $afterNormal = $null
    $normalVersion = $oldVersion
}

Write-Status "Security Intelligence after normal update: $normalVersion"

if ($normalVersion -ne $oldVersion) {
    Write-Status "SUCCESS: Security Intelligence updated through the normal source."
    exit 0
}

Write-Host ""
Write-Status "The version did not change."
Write-Status "Step 2: Forcing MMPC as the update source..."

$mpCmdPath = Find-MpCmdRun

if (-not $mpCmdPath) {
    Write-Status "ERROR: MpCmdRun.exe was not found."
    exit 1
}

Write-Status "MpCmdRun path: $mpCmdPath"

$mmPCSucceeded = $false

try {
    # Microsoft documents -SignatureUpdate -MMPC for requesting an update
    # directly from the Microsoft Malware Protection Center source.
    $process = Start-Process `
        -FilePath $mpCmdPath `
        -ArgumentList "-SignatureUpdate -MMPC" `
        -Wait `
        -PassThru `
        -NoNewWindow

    Write-Status "MpCmdRun exit code: $($process.ExitCode)"

    if ($process.ExitCode -eq 0) {
        $mmPCSucceeded = $true
    }
}
catch {
    Write-Status "MMPC update command failed:"
    Write-Status $_.Exception.Message
}

Write-Host ""
Write-Status "Waiting for Defender status refresh..."
Start-Sleep -Seconds 10

try {
    $after = Get-DefenderStatus
}
catch {
    Write-Status "ERROR: Defender status could not be read after the update attempt."
    Write-Status $_.Exception.Message
    exit 2
}

$newVersion = [string]$after.AntivirusSignatureVersion
$newDate    = $after.AntivirusSignatureLastUpdated

Write-Status "Final Security Intelligence: $newVersion"

if ($newDate) {
    Write-Status "Final Last Update: $newDate"
}

Write-Host ""

if ($newVersion -ne $oldVersion) {
    Write-Status "SUCCESS: Security Intelligence updated from $oldVersion to $newVersion."
    exit 0
}

Write-Status "WARNING: Security Intelligence version still did not change."

# Diagnose common managed-environment cause.
try {
    $wuPolicy = Get-ItemProperty `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
        -ErrorAction SilentlyContinue

    if ($wuPolicy.WUServer) {
        Write-Status "WSUS server configured: $($wuPolicy.WUServer)"
    }
}
catch {}

Write-Status "This usually means the device is receiving Defender updates"
Write-Status "from a managed source such as WSUS/Configuration Manager,"
Write-Status "or direct MMPC connectivity is blocked by policy/network."

Write-Host ""
Write-Status "Microsoft documents these update sources:"
Write-Status "InternalDefinitionUpdateServer"
Write-Status "MicrosoftUpdateServer"
Write-Status "MMPC"
Write-Status "FileShares"

Write-Host ""
Write-Host "============================================================"
Write-Host " DEFENDER SECURITY INTELLIGENCE UPDATE CHECK COMPLETED"
Write-Host "============================================================"
Write-Host ""

if (-not $mmPCSucceeded) {
    exit 1
}

exit 3
