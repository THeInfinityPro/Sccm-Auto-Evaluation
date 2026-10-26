
# SCCM Health & Version Verification
# Read-only diagnostic scan.
# Does not intentionally change SCCM services, policies, registry settings,
# WMI configuration, or SCCM client settings.
#
# Outputs:
#   C:\Temp\SCCM Health Check\SCCM-Health-Version-<hostname>-<timestamp>.log
#   C:\Temp\SCCM Health Check\<hostname>.zip

[CmdletBinding()]
param(
    [string]$ExpectedVersion = "5.00.9135.1013",
    [string]$ReportDirectory = "C:\Temp\SCCM Health Check",
    [string]$CMTracePath = "C:\Windows\CCM\CMTrace.exe",
    [int]$RecentLogHours = 48,
    [int]$MaxFindingsPerLog = 100
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# INITIALIZATION
# ---------------------------------------------------------------------------

$scanStarted = Get-Date
$results = New-Object 'System.Collections.Generic.List[object]'
$findings = New-Object 'System.Collections.Generic.List[object]'
$archiveSkippedFiles = New-Object 'System.Collections.Generic.List[object]'

function Add-Result {
    param(
        [string]$Check,
        [string]$Status,
        [string]$Detail
    )

    $results.Add([pscustomobject]@{
        Check  = $Check
        Status = $Status
        Detail = $Detail
    })
}

function Get-ClientVersion {
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\SMS\Mobile Client"
    )

    foreach ($key in $registryPaths) {
        try {
            $value = (Get-ItemProperty -LiteralPath $key `
                -Name Version -ErrorAction Stop).Version

            if ($value) {
                return [string]$value
            }
        }
        catch {
            # Continue to the next version source.
        }
    }

    try {
        $client = Get-CimInstance -Namespace "root\ccm" `
            -ClassName "SMS_Client" -ErrorAction Stop

        if ($client.ClientVersion) {
            return [string]$client.ClientVersion
        }
    }
    catch {
        # Version may be unavailable if WMI is inaccessible.
    }

    return $null
}

# ---------------------------------------------------------------------------
# SCCM SERVICE CHECK
# ---------------------------------------------------------------------------

try {
    $service = Get-Service -Name "CcmExec" -ErrorAction Stop

    if ($service.Status -eq "Running") {
        Add-Result "CcmExec service" "PASS" "Service is running"
    }
    else {
        Add-Result "CcmExec service" "FAIL" `
            "Service state: $($service.Status)"
    }
}
catch {
    Add-Result "CcmExec service" "FAIL" `
        "Service unavailable: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# SCCM CLIENT VERSION CHECK
# ---------------------------------------------------------------------------

$installedVersion = Get-ClientVersion

if ($installedVersion) {
    if ($installedVersion -eq $ExpectedVersion) {
        Add-Result "Client version" "PASS" `
            "Installed: $installedVersion; expected: $ExpectedVersion"
    }
    else {
        Add-Result "Client version" "MISMATCH" `
            "Installed: $installedVersion; expected: $ExpectedVersion"
    }
}
else {
    Add-Result "Client version" "UNKNOWN" `
        "Version unavailable from registry and SMS_Client WMI"
}

# ---------------------------------------------------------------------------
# SMS_CLIENT WMI CHECK
# ---------------------------------------------------------------------------

try {
    $null = Get-CimClass -Namespace "root\ccm" `
        -ClassName "SMS_Client" -ErrorAction Stop

    Add-Result "SMS_Client WMI" "PASS" `
        "root\ccm SMS_Client class is accessible"
}
catch {
    Add-Result "SMS_Client WMI" "FAIL" `
        $_.Exception.Message
}

# ---------------------------------------------------------------------------
# ASSIGNED SITE CHECK
# ---------------------------------------------------------------------------

try {
    $site = (Get-ItemProperty `
        -LiteralPath "HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client" `
        -Name "AssignedSiteCode" -ErrorAction Stop).AssignedSiteCode

    if ($site) {
        Add-Result "Assigned site" "INFO" "Site code: $site"
    }
    else {
        Add-Result "Assigned site" "UNKNOWN" `
            "AssignedSiteCode is empty"
    }
}
catch {
    Add-Result "Assigned site" "UNKNOWN" `
        "AssignedSiteCode unavailable"
}


# ---------------------------------------------------------------------------
# LOOKUPMPLIST REGISTRY CHECK (READ-ONLY)
# Registry: HKLM\SOFTWARE\Microsoft\CCM
# Value:    LookupMPList
# ---------------------------------------------------------------------------

$registryPath = "HKLM:\SOFTWARE\Microsoft\CCM"
$valueName = "LookupMPList"

try {
    if (-not (Test-Path -LiteralPath $registryPath -PathType Container)) {
        Add-Result "Registry: LookupMPList" "MISSING" `
            "Registry key not found: $registryPath"
    }
    else {
        $registryKey = Get-Item -LiteralPath $registryPath -ErrorAction Stop

        if ($registryKey.GetValueNames() -contains $valueName) {
            $value = $registryKey.GetValue(
                $valueName,
                $null,
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
            )

            if ($null -ne $value -and "$value".Length -gt 0) {
                if ($value -is [array]) {
                    $displayValue = ($value | ForEach-Object { "$_" }) -join "; "
                }
                elseif ($value -is [byte[]]) {
                    $displayValue = [BitConverter]::ToString($value)
                }
                else {
                    $displayValue = [string]$value
                }

                Add-Result "Registry: LookupMPList" "PASS" `
                    "Value found: $displayValue"
            }
            else {
                Add-Result "Registry: LookupMPList" "EMPTY" `
                    "No value is there (value exists but is empty)"
            }
        }
        else {
            Add-Result "Registry: LookupMPList" "MISSING" `
                "No value is there (LookupMPList does not exist)"
        }
    }
}
catch {
    Add-Result "Registry: LookupMPList" "UNKNOWN" `
        "Unable to read registry value: $($_.Exception.Message)"
}


# ---------------------------------------------------------------------------
# SCCM LOG SCAN
# Reports filenames and line numbers only; does not copy matched log text.
# ---------------------------------------------------------------------------

$logRoot = Join-Path $env:windir "CCM\Logs"

$logNames = @(
    "CcmEval.log",
    "CcmExec.log",
    "ClientIDManagerStartup.log",
    "LocationServices.log",
    "PolicyAgent.log",
    "CcmMessaging.log",
    "WUAHandler.log",
    "UpdatesDeployment.log",
    "CAS.log",
    "ContentTransferManager.log",
    "ClientLocation.log",
    "CoManagementHandler.log"
)

$cutoff = (Get-Date).AddHours(-[Math]::Abs($RecentLogHours))

$pattern = '(?i)(\bERROR\b|\bFAILED\b|0x800[0-9a-f]{4,8}|0x87d[0-9a-f]{4,8}|exception|timed?\s*out|cannot\s+connect)'

foreach ($name in $logNames) {
    $logPath = Join-Path $logRoot $name

    if (-not (Test-Path -LiteralPath $logPath -PathType Leaf)) {
        Add-Result "Log: $name" "MISSING" `
            "Log file not found; this is not automatically a client failure"
        continue
    }

    try {
        $file = Get-Item -LiteralPath $logPath -ErrorAction Stop

        if ($file.LastWriteTime -lt $cutoff) {
            Add-Result "Log: $name" "STALE" `
                "Last modified: $($file.LastWriteTime); outside the last $RecentLogHours hours"
            continue
        }

        $matches = @(
            Select-String -LiteralPath $logPath `
                -Pattern $pattern -ErrorAction Stop |
            Select-Object -Last ([Math]::Max(1, $MaxFindingsPerLog))
        )

        if ($matches.Count -gt 0) {
            Add-Result "Log: $name" "REVIEW" `
                "$($matches.Count) matching line(s); last modified: $($file.LastWriteTime)"

            foreach ($match in $matches) {
                $findings.Add([pscustomobject]@{
                    Log        = $name
                    LineNumber = $match.LineNumber
                })
            }
        }
        else {
            Add-Result "Log: $name" "PASS" `
                "No matching indicators; last modified: $($file.LastWriteTime)"
        }
    }
    catch {
        Add-Result "Log: $name" "UNREADABLE" `
            $_.Exception.Message
    }
}

# ---------------------------------------------------------------------------
# CREATE REPORT DIRECTORY
# ---------------------------------------------------------------------------

try {
    New-Item -ItemType Directory -Path $ReportDirectory `
        -Force -ErrorAction Stop | Out-Null
}
catch {
    throw "Cannot create report directory '$ReportDirectory': $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# ARCHIVE CCM LOGS
# Copies readable files to a temporary staging folder first.
# Files that cannot be copied are skipped and recorded.
# Only C:\Windows\CCM\Logs is archived.
# ---------------------------------------------------------------------------

$archivePath = Join-Path $ReportDirectory (
    "{0}.zip" -f $env:COMPUTERNAME
)

$logFolder = Join-Path $env:windir "CCM\Logs"
$stageFolder = $null
$archiveCreated = $false

if (Test-Path -LiteralPath $logFolder -PathType Container) {
    try {
        if (-not (Get-Command "Compress-Archive" `
            -ErrorAction SilentlyContinue)) {
            throw "Compress-Archive cmdlet is unavailable"
        }

        $stageFolder = Join-Path $env:TEMP (
            "CCMLogs_" + [guid]::NewGuid().ToString()
        )

        New-Item -Path $stageFolder -ItemType Directory `
            -Force -ErrorAction Stop | Out-Null

        $sourceFiles = @(
            Get-ChildItem -LiteralPath $logFolder `
                -File -Recurse -ErrorAction Stop
        )

        foreach ($source in $sourceFiles) {
            $sourcePath = $source.FullName
            $relativePath = $sourcePath.Substring(
                $logFolder.Length
            ).TrimStart('\')

            $destination = Join-Path $stageFolder $relativePath
            $destinationDirectory = Split-Path `
                -Path $destination -Parent

            try {
                New-Item -Path $destinationDirectory `
                    -ItemType Directory -Force `
                    -ErrorAction Stop | Out-Null

                Copy-Item -LiteralPath $sourcePath `
                    -Destination $destination -Force `
                    -ErrorAction Stop
            }
            catch {
                $archiveSkippedFiles.Add([pscustomobject]@{
                    Path  = $sourcePath
                    Error = $_.Exception.Message
                })
            }
        }

        $stagedFiles = @(
            Get-ChildItem -LiteralPath $stageFolder `
                -File -Recurse -ErrorAction Stop
        )

        if ($stagedFiles.Count -eq 0) {
            throw "No readable log files were available to archive"
        }

        # Remove an old archive only after staging has succeeded.
        # This changes only the report output, not SCCM configuration.
        if (Test-Path -LiteralPath $archivePath -PathType Leaf) {
            Remove-Item -LiteralPath $archivePath `
                -Force -ErrorAction Stop
        }

        Compress-Archive `
            -Path (Join-Path $stageFolder '*') `
            -DestinationPath $archivePath `
            -CompressionLevel Optimal `
            -ErrorAction Stop

        if (Test-Path -LiteralPath $archivePath -PathType Leaf) {
            $archiveCreated = $true

            Add-Result "CCM Logs archive" "PASS" `
                "Archive created: $archivePath; skipped files: $($archiveSkippedFiles.Count)"
        }
        else {
            throw "Archive command completed but the ZIP file was not found"
        }
    }
    catch {
        Add-Result "CCM Logs archive" "FAIL" `
            "Archive creation failed: $($_.Exception.Message)"

        Write-Warning "Could not create CCM Logs archive: $($_.Exception.Message)"
        $archiveCreated = $false
    }
    finally {
        if ($stageFolder -and
            (Test-Path -LiteralPath $stageFolder)) {

            Remove-Item -LiteralPath $stageFolder `
                -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
else {
    Add-Result "CCM Logs archive" "MISSING" `
        "CCM Logs folder not found: $logFolder"
}

# ---------------------------------------------------------------------------
# BUILD REPORT
# ---------------------------------------------------------------------------

$scanCompleted = Get-Date

$reportPath = Join-Path $ReportDirectory (
    "SCCM-Health-Version-{0}-{1}.log" -f
    $env:COMPUTERNAME,
    $scanCompleted.ToString("yyyyMMdd-HHmmss")
)

$reportLines = New-Object 'System.Collections.Generic.List[string]'

@(
    "SCCM HEALTH & VERSION VERIFICATION"
    "Computer: $env:COMPUTERNAME"
    "Started: $scanStarted"
    "Completed: $scanCompleted"
    "Expected version: $ExpectedVersion"
    "Installed version: $(if ($installedVersion) { $installedVersion } else { 'Unknown' })"
    "Log review window: $RecentLogHours hours"
    "Mode: READ-ONLY DIAGNOSTICS; no SCCM configuration or client settings intentionally changed"
    "Note: File creation, log staging, ZIP creation and report viewing are performed."
    ""
    "CHECK RESULTS"
    "-------------"
) | ForEach-Object {
    $reportLines.Add($_)
}

foreach ($result in $results) {
    $reportLines.Add(
        "[$($result.Status)] $($result.Check) - $($result.Detail)"
    )
}

$reportLines.Add("")
$reportLines.Add("LOG FINDINGS - REVIEW CANDIDATES")
$reportLines.Add("--------------------------------")
$reportLines.Add(
    "Matches require timestamp and surrounding-context review in the original log."
)

if ($findings.Count -eq 0) {
    $reportLines.Add("No matching lines found in readable, recent logs.")
}
else {
    foreach ($finding in $findings) {
        $reportLines.Add(
            "REVIEW: $($finding.Log) - line $($finding.LineNumber)"
        )
    }
}

$reportLines.Add("")
$reportLines.Add("ARCHIVE DETAILS")
$reportLines.Add("---------------")

if ($archiveCreated) {
    $reportLines.Add("Archive: $archivePath")
}
else {
    $reportLines.Add("Archive was not created successfully.")
}

$reportLines.Add(
    "Files skipped during archive staging: $($archiveSkippedFiles.Count)"
)

foreach ($skipped in $archiveSkippedFiles) {
    $reportLines.Add("SKIPPED FILE: $($skipped.Path)")
    $reportLines.Add("REASON: $($skipped.Error)")
}

$reportLines.Add("")
$reportLines.Add(
    "Interpretation: matching log patterns do not independently prove a client failure."
)
$reportLines.Add(
    "Review the original log entries and correlate them with current client state."
)

# ---------------------------------------------------------------------------
# WRITE CMTRACE-COMPATIBLE REPORT
# Each line uses report-generation time; it is not the source log timestamp.
# ---------------------------------------------------------------------------

$cmTraceLines = New-Object 'System.Collections.Generic.List[string]'

foreach ($line in $reportLines) {
    $stamp = Get-Date

    $timeText = $stamp.ToString(
        "HH:mm:ss.fff",
        [Globalization.CultureInfo]::InvariantCulture
    )

    $dateText = $stamp.ToString(
        "M-d-yyyy",
        [Globalization.CultureInfo]::InvariantCulture
    )

    # Keep each entry on one line in the CMTrace-formatted report.
    $safeLine = $line -replace '[\r\n]+', ' '
    $safeLine = $safeLine.Replace("]LOG]!", ")LOG)!")
    $safeLine = $safeLine.Replace("]", ")")

    $cmTraceLines.Add(
        ('<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="SCCM Health Check" context="" type="1" thread="0" file="">' -f
            $safeLine, $timeText, $dateText)
    )
}

try {
    $cmTraceLines | Set-Content -LiteralPath $reportPath `
        -Encoding UTF8 -ErrorAction Stop
}
catch {
    throw "Failed to write report '$reportPath': $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# OPEN REPORT IN CMTRACE OR NOTEPAD
# ---------------------------------------------------------------------------

$cmTraceCandidates = @()

if ($CMTracePath) {
    $cmTraceCandidates += $CMTracePath
}

$cmTraceCandidates += @(
    (Join-Path $env:windir "CCM\CMTrace.exe"),
    (Join-Path $env:windir "CMTrace.exe"),
    (Join-Path ${env:ProgramFiles(x86)} `
        "ConfigMgr 2012 Toolkit V5\ClientTools\CMTrace.exe"),
    (Join-Path $env:ProgramFiles `
        "Microsoft Configuration Manager\Tools\CMTrace.exe")
)

try {
    $cmTraceCommand = Get-Command "CMTrace.exe" `
        -ErrorAction SilentlyContinue

    if ($cmTraceCommand) {
        $cmTraceCandidates += $cmTraceCommand.Source
    }
}
catch {
    # Continue with the known paths.
}

$resolvedCMTrace = $cmTraceCandidates |
    Where-Object {
        $_ -and (Test-Path -LiteralPath $_ -PathType Leaf)
    } |
    Select-Object -First 1

try {
    if ($resolvedCMTrace) {
        Start-Process -FilePath $resolvedCMTrace `
            -ArgumentList ('"{0}"' -f $reportPath) `
            -ErrorAction Stop
    }
    else {
        Write-Warning "CMTrace.exe was not found. Opening the report in Notepad."
        Start-Process -FilePath "notepad.exe" `
            -ArgumentList ('"{0}"' -f $reportPath) `
            -ErrorAction Stop
    }
}
catch {
    Write-Warning "Could not open the report: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# FINAL SUMMARY
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "========== SCCM HEALTH CHECK COMPLETE =========="
Write-Host "Computer: $env:COMPUTERNAME"
Write-Host "Checks: $($results.Count)"
Write-Host "Log findings: $($findings.Count)"
Write-Host "Archive skipped files: $($archiveSkippedFiles.Count)"
Write-Host "Report: $reportPath"

if ($archiveCreated) {
    Write-Host "CCM Logs archive: $archivePath"
}
else {
    Write-Host "CCM Logs archive: NOT CREATED"
}

Write-Host "Output folder: $ReportDirectory"
Write-Host "================================================"
Write-Host ""

# ReadKey only works in a suitable interactive console.
try {
    if ($Host.Name -eq "ConsoleHost" -and
        -not [Console]::IsInputRedirected) {

        Write-Host "Press any key to close this window..."
        [void][Console]::ReadKey($true)
    }
}
catch {
    # Do not fail the completed scan if the console is unavailable.
}
