# SCCM Local-Only Health Check GUI
# Version 1.4.0
# Local diagnostic only: no remote WMI/CIM, no MP tests, no policy/update scans,
# no SCCM client actions, no service/registry changes, and no automatic repair.
# Reports and optional bundle are written to C:\Temp\SCCM Health Check.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$ExpectedVersion = '5.00.9135.1013'
$ReportDirectory = 'C:\Temp\SCCM Health Check'
$LogRoot = Join-Path $env:windir 'CCM\Logs'
$CcmSetupLogRoot = Join-Path $env:windir 'CCMSetup\Logs'
$script:Results = @()
$script:LastReport = $null

function Add-CheckResult {
    param([string]$Category,[string]$Check,[string]$Status,[string]$Detail,[int]$Weight=0)
    $script:Results += [pscustomobject]@{Category=$Category;Check=$Check;Status=$Status;Detail=$Detail;Weight=$Weight}
}
function Get-RegistryValueSafe {
    param([string]$Path,[string]$Name)
    try { return (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop).$Name } catch { return $null }
}
function Run-LocalHealthScan {
    $script:Results = @()
    $expectedServiceChecks = @()
    # Service state and startup type: local service database only.
    try {
        $svc = Get-CimInstance -ClassName Win32_Service -Filter "Name='CcmExec'" -ErrorAction Stop
        if ($null -eq $svc) {
            Add-CheckResult 'Client service & startup' 'CcmExec service exists' 'FAIL' 'SMS Agent Host (CcmExec) service was not found.' 20
        } else {
            $state = [string]$svc.State
            $startMode = [string]$svc.StartMode
            $svcStatus = if ($state -eq 'Running') {'PASS'} else {'FAIL'}
            Add-CheckResult 'Client service & startup' 'CcmExec running' $svcStatus "State: $state" 15
            $startupStatus = if ($startMode -eq 'Auto') {'PASS'} else {'REVIEW'}
            Add-CheckResult 'Client service & startup' 'CcmExec startup type' $startupStatus "Startup mode: $startMode (expected Automatic in the standard client configuration)." 5
        }
    } catch { Add-CheckResult 'Client service & startup' 'CcmExec service query' 'UNKNOWN' "Local service query unavailable: $($_.Exception.Message)" 0 }

    # WMI service is queried locally. No -ComputerName and no remote namespace.
    try {
        $wmiSvc = Get-CimInstance -ClassName Win32_Service -Filter "Name='Winmgmt'" -ErrorAction Stop
        if ($null -eq $wmiSvc) { Add-CheckResult 'WMI & client database' 'Winmgmt service' 'FAIL' 'Windows Management Instrumentation service was not found.' 10 }
        else {
            $wmiStatus = if ([string]$wmiSvc.State -eq 'Running') {'PASS'} else {'FAIL'}
            Add-CheckResult 'WMI & client database' 'Winmgmt service' $wmiStatus "State: $($wmiSvc.State); startup: $($wmiSvc.StartMode)." 10
        }
    } catch { Add-CheckResult 'WMI & client database' 'Winmgmt service query' 'UNKNOWN' "Local service query unavailable: $($_.Exception.Message)" 0 }

    # Local SCCM provider availability only. This does not target a remote machine.
    try {
        $null = Get-CimClass -Namespace 'root\ccm' -ClassName 'SMS_Client' -ErrorAction Stop
        Add-CheckResult 'WMI & client database' 'Local SCCM WMI provider' 'PASS' 'Local root\ccm:SMS_Client class is accessible. This is not a full WMI repository integrity test.' 15
    } catch { Add-CheckResult 'WMI & client database' 'Local SCCM WMI provider' 'FAIL' "Local root\ccm:SMS_Client class could not be queried: $($_.Exception.Message)" 15 }

    # SQL CE client database is not opened or repaired. Existing CcmEval evidence only.
    $ccmEval = Join-Path $LogRoot 'CcmEval.log'
    $sqlCeLog = Join-Path $LogRoot 'ccmsqlce.log'
    $dbLogPaths = @($ccmEval, $sqlCeLog) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
    if ($dbLogPaths.Count -gt 0) {
        try {
            $dbMatches = @()
            foreach ($dbLogPath in $dbLogPaths) { $dbMatches += @(Select-String -LiteralPath $dbLogPath -Pattern '(?i)(SQL.?CE|client database|database.*(fail|error|corrupt)|corrupt.*database|exception|error)' -ErrorAction Stop | Select-Object -Last 10) }
            if (@($dbMatches).Count -gt 0) {
                $refs = (@($dbMatches) | ForEach-Object { "line $($_.LineNumber)" }) -join ', '
                Add-CheckResult 'WMI & client database' 'Client database log indicators' 'REVIEW' "Database-related indicators found in local client health/database logs at $refs. Review locally; no database was opened or repaired." 0
            } else {
                Add-CheckResult 'WMI & client database' 'Client database log indicators' 'INFO' 'No matching indicators found in available local CcmEval/ccmsqlce logs. This is not a definitive database integrity test.' 0
            }
        } catch { Add-CheckResult 'WMI & client database' 'Client database log indicators' 'UNKNOWN' 'Could not read CcmEval.log.' 0 }
    } else { Add-CheckResult 'WMI & client database' 'Client database log indicators' 'UNKNOWN' 'Neither CcmEval.log nor ccmsqlce.log was available; database integrity was not directly tested.' 0 }

    # Client installation/prerequisite checks: registry, local files, disk space.
    $version = Get-RegistryValueSafe 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client' 'Version'
    if (-not $version) { $version = Get-RegistryValueSafe 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\SMS\Mobile Client' 'Version' }
    if ($version) {
        $vStatus = if ([string]$version -eq $ExpectedVersion) {'PASS'} else {'REVIEW'}
        Add-CheckResult 'Client installation & prerequisites' 'Installed client version' $vStatus "Installed: $version; expected: $ExpectedVersion." 15
    } else { Add-CheckResult 'Client installation & prerequisites' 'Installed client version' 'UNKNOWN' 'Version not found in local registry.' 0 }

    $ccmExe = Join-Path $env:windir 'CCM\CcmExec.exe'
    $ccmSetupLog = Join-Path $CcmSetupLogRoot 'ccmsetup.log'
    if (Test-Path -LiteralPath $ccmExe -PathType Leaf) {
        Add-CheckResult 'Client installation & prerequisites' 'Client binary' 'PASS' "Found $ccmExe" 10
    } else { Add-CheckResult 'Client installation & prerequisites' 'Client binary' 'FAIL' "Client binary not found at $ccmExe" 10 }
    if (Test-Path -LiteralPath $ccmSetupLog -PathType Leaf) {
        try {
            $setupErrors = Select-String -LiteralPath $ccmSetupLog -Pattern '(?i)(installation failed|failed to install|return code\s*\(0x[0-9a-f]+\))' -ErrorAction Stop | Select-Object -Last 5
            if (@($setupErrors).Count) {
                $refs = (@($setupErrors) | ForEach-Object { "line $($_.LineNumber)" }) -join ', '
                Add-CheckResult 'Client installation & prerequisites' 'ccmsetup.log indicators' 'REVIEW' "Potential setup failure indicators at $refs. Review original log; matching text alone is not proof of current failure." 0
            } else { Add-CheckResult 'Client installation & prerequisites' 'ccmsetup.log indicators' 'PASS' 'No selected installation-failure indicators found in the local setup log.' 0 }
        } catch { Add-CheckResult 'Client installation & prerequisites' 'ccmsetup.log indicators' 'UNKNOWN' 'Unable to read ccmsetup.log.' 0 }
    } else { Add-CheckResult 'Client installation & prerequisites' 'ccmsetup.log' 'INFO' 'Local ccmsetup.log not found; it may have been cleaned up.' 0 }
    try {
        $sysDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'" -ErrorAction Stop
        if ($sysDrive -and $sysDrive.Size -gt 0) {
            $freePct = [math]::Round(($sysDrive.FreeSpace / $sysDrive.Size) * 100, 2)
            $diskStatus = if ($freePct -gt 1) {'PASS'} else {'REVIEW'}
            Add-CheckResult 'Client installation & prerequisites' 'System drive free space' $diskStatus "$($env:SystemDrive) free space: $freePct%." 5
        } else { Add-CheckResult 'Client installation & prerequisites' 'System drive free space' 'UNKNOWN' 'Unable to determine system drive capacity.' 0 }
    } catch { Add-CheckResult 'Client installation & prerequisites' 'System drive free space' 'UNKNOWN' "Local disk query unavailable: $($_.Exception.Message)" 0 }

    # Local logs scan: filenames and line numbers only. No remote connectivity tests.
    $scanLogs = @('CcmEval.log','CcmExec.log','ClientIDManagerStartup.log','LocationServices.log','PolicyAgent.log','CcmMessaging.log','WUAHandler.log','UpdatesDeployment.log')
    foreach ($name in $scanLogs) {
        $path = Join-Path $LogRoot $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Add-CheckResult 'Local log review' $name 'INFO' 'Local log not found; not automatically a failure.' 0; continue }
        try {
            $hits = @(Select-String -LiteralPath $path -Pattern '(?i)(\bERROR\b|\bFAILED\b|0x800[0-9a-f]{4,8}|0x87d[0-9a-f]{4,8}|exception|timed?\s*out)' -ErrorAction Stop | Select-Object -Last 20)
            if ($hits.Count) {
                $refs = ($hits | ForEach-Object { "line $($_.LineNumber)" }) -join ', '
                Add-CheckResult 'Local log review' $name 'REVIEW' "$($hits.Count) possible indicator(s); line references: $refs. Pattern matches require manual review." 0
            } else { Add-CheckResult 'Local log review' $name 'PASS' 'No selected error indicators found in this local log.' 0 }
        } catch { Add-CheckResult 'Local log review' $name 'UNKNOWN' 'Could not read this local log.' 0 }
    }

    # Explicitly classified as network/server-dependent and never executed.
    Add-CheckResult 'Network / server-dependent (not executed)' 'Policy retrieval & software-update scans' 'NOT EXECUTED' 'Excluded by Local-Only mode. No policy retrieval, update scan, or deployment evaluation was triggered.' 0
    Add-CheckResult 'Network / server-dependent (not executed)' 'Remote WMI / remote database queries' 'NOT EXECUTED' 'Excluded by Local-Only mode. No remote WMI/CIM query or SCCM site database connection was attempted.' 0

    return $script:Results
}

function Get-HealthScore {
    $scored = @($script:Results | Where-Object { $_.Weight -gt 0 -and $_.Status -in @('PASS','FAIL','REVIEW') })
    if (-not $scored.Count) { return [pscustomobject]@{Score='N/A';Earned=0;Possible=0;Label='Not enough evidence'} }
    $possible = ($scored | Measure-Object -Property Weight -Sum).Sum
    $earned = 0
    foreach ($item in $scored) {
        if ($item.Status -eq 'PASS') { $earned += $item.Weight }
        elseif ($item.Status -eq 'REVIEW') { $earned += [math]::Floor($item.Weight * 0.5) }
    }
    $score = [math]::Round(($earned / $possible) * 100)
    $label = if ($score -ge 90) {'Healthy'} elseif ($score -ge 75) {'Needs review'} else {'Attention required'}
    return [pscustomobject]@{Score=$score;Earned=$earned;Possible=$possible;Label=$label}
}
function Save-Report {
    New-Item -ItemType Directory -Path $ReportDirectory -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $path = Join-Path $ReportDirectory ("SCCM-Local-Health-{0}-{1}.txt" -f $env:COMPUTERNAME,$stamp)
    $score = Get-HealthScore
    $lines = @(
        'SCCM LOCAL-ONLY HEALTH CHECK',
        "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "Computer: $env:COMPUTERNAME",
        'Mode: LOCAL ONLY; NO SERVER CHECKS OR REPAIRS',
        "Health score: $($score.Score) ($($score.Label)); scored evidence: $($score.Earned)/$($score.Possible)",
        'Note: score is a custom diagnostic indicator, not a Microsoft-defined score.',
        'Network-dependent checks below are intentionally not executed.',
        ''
    )
    foreach ($r in $script:Results) { $lines += ('[{0}] [{1}] {2} - {3}' -f $r.Status,$r.Category,$r.Check,$r.Detail) }
    $lines += @('', 'No remote WMI/CIM, remote database, MP connectivity, policy retrieval, update scan, service restart, configuration change, or repair was initiated by this GUI.')
    Set-Content -LiteralPath $path -Value $lines -Encoding UTF8
    $script:LastReport = $path
    return $path
}
function Create-LocalBundle {
    if (-not $script:Results.Count) { [void](Run-LocalHealthScan) }
    $report = Save-Report
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $stage = Join-Path $env:TEMP ("SCCM-LocalBundle-{0}-{1}" -f $env:COMPUTERNAME,$stamp)
    $bundle = Join-Path $ReportDirectory ("SCCM-Local-Diagnostic-Bundle-{0}-{1}.zip" -f $env:COMPUTERNAME,$stamp)
    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    Copy-Item -LiteralPath $report -Destination $stage -Force
    $manifest = @('Local-only SCCM diagnostic bundle',"Computer: $env:COMPUTERNAME","Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",'No upload or remote query was performed.','Log files can contain sensitive machine or user information; handle according to company policy.','')
    foreach ($pair in @(@{Path=$LogRoot;Name='CCM-Logs'},@{Path=$CcmSetupLogRoot;Name='CCMSetup-Logs'})) {
        if (Test-Path -LiteralPath $pair.Path -PathType Container) {
            $dest = Join-Path $stage $pair.Name
            New-Item -ItemType Directory -Path $dest -Force | Out-Null
            Get-ChildItem -LiteralPath $pair.Path -File -ErrorAction SilentlyContinue | ForEach-Object {
                try { Copy-Item -LiteralPath $_.FullName -Destination $dest -Force -ErrorAction Stop }
                catch { $manifest += "Skipped locked/unreadable file: $($_.Name)" }
            }
        } else { $manifest += "Log directory not found: $($pair.Path)" }
    }
    Set-Content -LiteralPath (Join-Path $stage 'MANIFEST.txt') -Value $manifest -Encoding UTF8
    try { Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $bundle -CompressionLevel Optimal -ErrorAction Stop }
    finally { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue }
    return $bundle
}

# UI
$form = New-Object System.Windows.Forms.Form
$form.Text = 'SCCM Local-Only Health Check'
$form.Size = New-Object System.Drawing.Size(1180,780)
$form.MinimumSize = New-Object System.Drawing.Size(1000,650)
$form.StartPosition = 'CenterScreen'
$form.BackColor = [System.Drawing.Color]::FromArgb(20,25,34)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font('Segoe UI',9)

$header = New-Object System.Windows.Forms.Panel
$header.Dock = 'Top'; $header.Height = 112; $header.BackColor = [System.Drawing.Color]::FromArgb(13,18,26)
$form.Controls.Add($header)
$title = New-Object System.Windows.Forms.Label
$title.Text = 'SCCM CLIENT HEALTH CHECK'; $title.Font = New-Object System.Drawing.Font('Segoe UI Semibold',20,[System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::White; $title.Location = New-Object System.Drawing.Point(22,16); $title.AutoSize = $true; $header.Controls.Add($title)
$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = 'LOCAL-ONLY MODE  |  No MP checks • No policy/update scans • No remote WMI/SQL • No repairs'
$subtitle.ForeColor = [System.Drawing.Color]::FromArgb(139,210,183); $subtitle.Location = New-Object System.Drawing.Point(25,58); $subtitle.AutoSize = $true; $header.Controls.Add($subtitle)

$scorePanel = New-Object System.Windows.Forms.Panel
$scorePanel.Location = New-Object System.Drawing.Point(18,126); $scorePanel.Size = New-Object System.Drawing.Size(320,125); $scorePanel.BackColor = [System.Drawing.Color]::FromArgb(31,40,53); $form.Controls.Add($scorePanel)
$scoreCaption = New-Object System.Windows.Forms.Label
$scoreCaption.Text = 'LOCAL HEALTH SCORE'; $scoreCaption.Location = New-Object System.Drawing.Point(16,12); $scoreCaption.AutoSize = $true; $scoreCaption.ForeColor = [System.Drawing.Color]::LightGray; $scorePanel.Controls.Add($scoreCaption)
$scoreValue = New-Object System.Windows.Forms.Label
$scoreValue.Text = '-- / 100'; $scoreValue.Font = New-Object System.Drawing.Font('Segoe UI Semibold',25,[System.Drawing.FontStyle]::Bold); $scoreValue.Location = New-Object System.Drawing.Point(14,32); $scoreValue.AutoSize = $true; $scorePanel.Controls.Add($scoreValue)
$scoreStatus = New-Object System.Windows.Forms.Label
$scoreStatus.Text = 'Run a scan to begin'; $scoreStatus.Location = New-Object System.Drawing.Point(17,92); $scoreStatus.AutoSize = $true; $scoreStatus.ForeColor = [System.Drawing.Color]::LightGray; $scorePanel.Controls.Add($scoreStatus)

$info = New-Object System.Windows.Forms.Label
$info.Text = "Computer: $env:COMPUTERNAME`r`nExpected client version: $ExpectedVersion`r`nReports: $ReportDirectory"
$info.Location = New-Object System.Drawing.Point(360,140); $info.Size = New-Object System.Drawing.Size(800,68); $info.ForeColor = [System.Drawing.Color]::Gainsboro; $form.Controls.Add($info)

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(18,266); $grid.Size = New-Object System.Drawing.Size(1125,370)
$grid.Anchor = 'Top,Bottom,Left,Right'; $grid.BackgroundColor = [System.Drawing.Color]::FromArgb(24,30,40)
$grid.BorderStyle = 'None'; $grid.ReadOnly = $true; $grid.AllowUserToAddRows = $false; $grid.AllowUserToDeleteRows = $false
$grid.AutoSizeRowsMode = 'AllCells'; $grid.RowHeadersVisible = $false; $grid.SelectionMode = 'FullRowSelect'; $grid.MultiSelect = $false
$grid.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(28,35,47); $grid.DefaultCellStyle.ForeColor = [System.Drawing.Color]::White
$grid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(55,75,96); $grid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
$grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(42,52,68); $grid.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::White
$grid.EnableHeadersVisualStyles = $false
[void]$grid.Columns.Add('Category','Category'); [void]$grid.Columns.Add('Check','Check'); [void]$grid.Columns.Add('Status','Status'); [void]$grid.Columns.Add('Detail','Details')
$grid.Columns['Category'].Width=210; $grid.Columns['Check'].Width=205; $grid.Columns['Status'].Width=115; $grid.Columns['Detail'].AutoSizeMode='Fill'
$form.Controls.Add($grid)

$footer = New-Object System.Windows.Forms.Panel
$footer.Dock = 'Bottom'; $footer.Height = 92; $footer.BackColor = [System.Drawing.Color]::FromArgb(13,18,26); $form.Controls.Add($footer)
function New-UiButton([string]$Text,[int]$X,[int]$Width) {
    $b = New-Object System.Windows.Forms.Button; $b.Text=$Text; $b.Location=New-Object System.Drawing.Point($X,18); $b.Size=New-Object System.Drawing.Size($Width,38)
    $b.FlatStyle='Flat'; $b.FlatAppearance.BorderSize=0; $b.BackColor=[System.Drawing.Color]::FromArgb(48,110,150); $b.ForeColor=[System.Drawing.Color]::White
    $b.Font=New-Object System.Drawing.Font('Segoe UI Semibold',9); $footer.Controls.Add($b); return $b
}
$runButton = New-UiButton 'Run Local Checks' 18 155
$reportButton = New-UiButton 'Save / Open Report' 184 170
$bundleButton = New-UiButton 'Create Diagnostic ZIP' 365 190
$folderButton = New-UiButton 'Open Report Folder' 566 170
$closeButton = New-UiButton 'Close' 747 100
$footerNote = New-Object System.Windows.Forms.Label
$footerNote.Text='Diagnostic bundle contains local SCCM logs; review before sharing.'; $footerNote.Location=New-Object System.Drawing.Point(18,62); $footerNote.AutoSize=$true; $footerNote.ForeColor=[System.Drawing.Color]::FromArgb(255,204,120); $footer.Controls.Add($footerNote)

function Refresh-Grid {
    $grid.Rows.Clear()
    foreach ($r in $script:Results) {
        $i = $grid.Rows.Add($r.Category,$r.Check,$r.Status,$r.Detail)
        switch ($r.Status) {
            'PASS' { $grid.Rows[$i].Cells['Status'].Style.ForeColor=[System.Drawing.Color]::LightGreen }
            'FAIL' { $grid.Rows[$i].Cells['Status'].Style.ForeColor=[System.Drawing.Color]::Salmon }
            'REVIEW' { $grid.Rows[$i].Cells['Status'].Style.ForeColor=[System.Drawing.Color]::Khaki }
            'NOT EXECUTED' { $grid.Rows[$i].Cells['Status'].Style.ForeColor=[System.Drawing.Color]::LightSkyBlue }
            default { $grid.Rows[$i].Cells['Status'].Style.ForeColor=[System.Drawing.Color]::LightGray }
        }
    }
}
$runButton.Add_Click({
    $runButton.Enabled=$false; $form.Cursor=[System.Windows.Forms.Cursors]::WaitCursor
    try {
        [void](Run-LocalHealthScan); Refresh-Grid
        $s=Get-HealthScore; $scoreValue.Text= if ($s.Score -eq 'N/A') {'N/A'} else {"$($s.Score) / 100"}; $scoreStatus.Text=$s.Label
        $scoreStatus.ForeColor=if ($s.Score -is [int] -and $s.Score -lt 75) {[System.Drawing.Color]::Salmon} elseif ($s.Score -is [int] -and $s.Score -lt 90) {[System.Drawing.Color]::Khaki} else {[System.Drawing.Color]::LightGreen}
        $footerNote.Text='Local scan complete. Network/server-dependent checks were intentionally skipped.'
    } catch { [System.Windows.Forms.MessageBox]::Show("Local scan failed: $($_.Exception.Message)",'Health Check Error','OK','Error') | Out-Null }
    finally { $runButton.Enabled=$true; $form.Cursor=[System.Windows.Forms.Cursors]::Default }
})
$reportButton.Add_Click({
    try { if (-not $script:Results.Count) {[void](Run-LocalHealthScan); Refresh-Grid}; $p=Save-Report; Start-Process -FilePath notepad.exe -ArgumentList @($p) }
    catch { [System.Windows.Forms.MessageBox]::Show("Could not save/open report: $($_.Exception.Message)",'Report Error','OK','Error') | Out-Null }
})
$bundleButton.Add_Click({
    $bundleButton.Enabled=$false; $form.Cursor=[System.Windows.Forms.Cursors]::WaitCursor
    try { $p=Create-LocalBundle; [System.Windows.Forms.MessageBox]::Show("Local diagnostic ZIP created:`r`n$p`r`n`r`nNo upload was performed. Review contents before sharing.",'Bundle Created','OK','Information') | Out-Null }
    catch { [System.Windows.Forms.MessageBox]::Show("Could not create diagnostic ZIP: $($_.Exception.Message)",'Bundle Error','OK','Error') | Out-Null }
    finally { $bundleButton.Enabled=$true; $form.Cursor=[System.Windows.Forms.Cursors]::Default }
})
$folderButton.Add_Click({ New-Item -ItemType Directory -Path $ReportDirectory -Force | Out-Null; Start-Process -FilePath explorer.exe -ArgumentList @($ReportDirectory) })
$closeButton.Add_Click({ $form.Close() })
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
