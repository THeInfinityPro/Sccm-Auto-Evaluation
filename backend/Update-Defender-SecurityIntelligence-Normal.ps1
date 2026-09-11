# Normal Microsoft Defender Security Intelligence Check & Update
# Uses the endpoint's normal/configured Defender update source.
# Requires Administrator privileges.

$ErrorActionPreference = "Stop"

function Get-DefenderStatus {
    try {
        return Get-MpComputerStatus -ErrorAction Stop
    }
    catch {
        throw "Unable to read Microsoft Defender status: $($_.Exception.Message)"
    }
}

Write-Host "=========================================="
Write-Host " DEFENDER SECURITY INTELLIGENCE"
Write-Host " NORMAL CHECK & UPDATE"
Write-Host "=========================================="
Write-Host ""

$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Administrator privileges are required."
    exit 1
}

try {
    $before = Get-DefenderStatus

    $beforeVersion = [string]$before.AntivirusSignatureVersion
    $beforeAge = $before.AntivirusSignatureAge
    $beforeLastUpdated = $before.AntivirusSignatureLastUpdated
    $beforeOutOfDate = [bool]$before.DefenderSignaturesOutOfDate

    Write-Host "[INFO] Current Security Intelligence version : $beforeVersion"
    Write-Host "[INFO] Signature age                         : $beforeAge day(s)"
    Write-Host "[INFO] Last updated                          : $beforeLastUpdated"
    Write-Host "[INFO] DefenderSignaturesOutOfDate           : $beforeOutOfDate"
    Write-Host ""
    Write-Host "[INFO] Running Update-MpSignature using the normal/configured update source..."
    Write-Host ""

    Update-MpSignature -ErrorAction Stop

    Write-Host "[INFO] Normal Defender update request completed."
    Start-Sleep -Seconds 5

    $after = Get-DefenderStatus
    $afterVersion = [string]$after.AntivirusSignatureVersion
    $afterAge = $after.AntivirusSignatureAge
    $afterLastUpdated = $after.AntivirusSignatureLastUpdated
    $afterOutOfDate = [bool]$after.DefenderSignaturesOutOfDate

    Write-Host ""
    Write-Host "[INFO] Post-update Security Intelligence version : $afterVersion"
    Write-Host "[INFO] Post-update signature age                 : $afterAge day(s)"
    Write-Host "[INFO] Post-update last updated                  : $afterLastUpdated"
    Write-Host "[INFO] Post-update DefenderSignaturesOutOfDate   : $afterOutOfDate"
    Write-Host ""

    if ($beforeVersion -ne $afterVersion) {
        Write-Host "[SUCCESS] Security Intelligence updated."
        Write-Host "[SUCCESS] Version changed from $beforeVersion to $afterVersion."
        exit 0
    }

    if (-not $afterOutOfDate) {
        Write-Host "[SUCCESS] Security Intelligence is current according to Defender."
        Write-Host "[INFO] No newer signature version was applied because the endpoint is not reporting signatures as out of date."
        exit 0
    }

    Write-Host "[WARNING] Normal update completed, but the Security Intelligence version did not change."
    Write-Host "[WARNING] The endpoint still reports Defender signatures as OUT OF DATE."
    Write-Host "[INFO] Review SCCM/WSUS/Defender update-source health before using the Force-MMPC fallback."
    exit 3
}
catch {
    Write-Host "[ERROR] Normal Defender Security Intelligence update failed: $($_.Exception.Message)"
    exit 1
}
