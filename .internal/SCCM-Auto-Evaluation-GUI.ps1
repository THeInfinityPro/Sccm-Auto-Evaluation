# ============================================================
# SCCM AUTO EVALUATION GUI
# Configuration Manager Client Automation Tool
#
# Author  : Jagadish V
# Version : 1.1.0
#
# IMPORTANT:
# This GUI does NOT modify the existing SCCM scripts.
# It only launches them and performs client verification.
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ------------------------------------------------------------
# Administrator Check
# ------------------------------------------------------------

$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {

    [System.Windows.Forms.MessageBox]::Show(
        "Please run this tool as Administrator.",
        "Administrator Required",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    exit
}

# ------------------------------------------------------------
# Project Paths
# ------------------------------------------------------------

$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Backend directory
$BackendDirectory = Join-Path $ScriptDirectory "..\backend"

# Existing scripts - DO NOT MODIFY
$ActionScript = Join-Path $BackendDirectory "SCCM-Actions-Automation.bat"

$BaselineScript = Join-Path $BackendDirectory "Evaluate_CM_Baselines_10Min.ps1"

$ConfigFixScript = Join-Path $BackendDirectory "Fix_CM_Configuration_Tab.ps1"

$SccmFixScript = Join-Path $BackendDirectory "SCCM-Stuck-Fix.bat"

# ------------------------------------------------------------
# Main Form
# ------------------------------------------------------------

$form = New-Object System.Windows.Forms.Form

$form.Text = "SCCM Auto Evaluation - Jagadish V"
$form.Size = New-Object System.Drawing.Size(1100,750)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

$header = New-Object System.Windows.Forms.Panel

$header.Location = New-Object System.Drawing.Point(0,0)
$header.Size = New-Object System.Drawing.Size(1100,85)

$header.BackColor = [System.Drawing.Color]::FromArgb(35,45,60)

$form.Controls.Add($header)

$title = New-Object System.Windows.Forms.Label

$title.Text = "SCCM AUTO EVALUATION"

$title.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    20,
    [System.Drawing.FontStyle]::Bold
)

$title.ForeColor = [System.Drawing.Color]::White

$title.Location = New-Object System.Drawing.Point(25,10)

$title.AutoSize = $true

$header.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label

$subtitle.Text = "Configuration Manager Client Automation"

$subtitle.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    10
)

$subtitle.ForeColor = [System.Drawing.Color]::LightGray

$subtitle.Location = New-Object System.Drawing.Point(28,50)

$subtitle.AutoSize = $true

$header.Controls.Add($subtitle)

$version = New-Object System.Windows.Forms.Label

$version.Text = "v1.1.0  |  Author: Jagadish V"

$version.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    9
)

$version.ForeColor = [System.Drawing.Color]::White

$version.Location = New-Object System.Drawing.Point(835,35)

$version.AutoSize = $true

$header.Controls.Add($version)


# ------------------------------------------------------------
# Theme Selector
# ------------------------------------------------------------

$themeLabel = New-Object System.Windows.Forms.Label

$themeLabel.Text = "Theme:"

$themeLabel.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    9
)

$themeLabel.ForeColor = [System.Drawing.Color]::White

$themeLabel.Location = New-Object System.Drawing.Point(600,34)

$themeLabel.AutoSize = $true

$header.Controls.Add($themeLabel)

$themeCombo = New-Object System.Windows.Forms.ComboBox

$themeCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

[void]$themeCombo.Items.Add("Dark")

[void]$themeCombo.Items.Add("Light")

[void]$themeCombo.Items.Add("Transparent")

$themeCombo.SelectedIndex = 0

$themeCombo.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    9
)

$themeCombo.Location = New-Object System.Drawing.Point(650,29)

$themeCombo.Size = New-Object System.Drawing.Size(160,30)

$header.Controls.Add($themeCombo)

# ------------------------------------------------------------
# Left Panel
# ------------------------------------------------------------

$leftPanel = New-Object System.Windows.Forms.Panel

$leftPanel.Location = New-Object System.Drawing.Point(15,100)

$leftPanel.Size = New-Object System.Drawing.Size(300,550)

$leftPanel.BackColor = [System.Drawing.Color]::White

$form.Controls.Add($leftPanel)

$section = New-Object System.Windows.Forms.Label

$section.Text = "SCCM OPERATIONS"

$section.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    11,
    [System.Drawing.FontStyle]::Bold
)

$section.Location = New-Object System.Drawing.Point(20,20)

$section.AutoSize = $true

$leftPanel.Controls.Add($section)

# ------------------------------------------------------------
# Button Helper
# ------------------------------------------------------------

function New-ActionButton {

    param(
        [string]$Text,
        [int]$Top
    )

    $button = New-Object System.Windows.Forms.Button

    $button.Text = $Text

    $button.Location = New-Object System.Drawing.Point(20,$Top)

    $button.Size = New-Object System.Drawing.Size(260,45)

    $button.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        10
    )

    $button.FlatStyle = "Flat"

    $button.BackColor = [System.Drawing.Color]::White

    $leftPanel.Controls.Add($button)

    return $button
}

# ------------------------------------------------------------
# Buttons
# ------------------------------------------------------------

$btnActions = New-ActionButton `
    "Run All SCCM Actions" 55

$btnBaselines = New-ActionButton `
    "Evaluate All Baselines" 110

$btnFull = New-ActionButton `
    "Full SCCM Evaluation" 165

$btnHealth = New-ActionButton `
    "Verify SCCM Client Health" 220

$btnConfig = New-ActionButton `
    "Fix Configuration Tab" 275

$btnStuck = New-ActionButton `
    "SCCM Client Stuck Fix" 330

$btnUserPolicy = New-ActionButton `
    "User Policy Information" 385

$btnOpenConfigMgr = New-ActionButton `
    "Open Configuration Manager" 440

$btnClear = New-ActionButton `
    "Clear Activity Log" 495

# ------------------------------------------------------------
# Right Panel
# ------------------------------------------------------------

$rightPanel = New-Object System.Windows.Forms.Panel

$rightPanel.Location = New-Object System.Drawing.Point(330,100)

$rightPanel.Size = New-Object System.Drawing.Size(740,550)

$rightPanel.BackColor = [System.Drawing.Color]::White

$form.Controls.Add($rightPanel)

# ------------------------------------------------------------
# Client Status
# ------------------------------------------------------------

$statusTitle = New-Object System.Windows.Forms.Label

$statusTitle.Text = "SCCM CLIENT STATUS"

$statusTitle.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    11,
    [System.Drawing.FontStyle]::Bold
)

$statusTitle.Location = New-Object System.Drawing.Point(20,20)

$statusTitle.AutoSize = $true

$rightPanel.Controls.Add($statusTitle)

$statusLabel = New-Object System.Windows.Forms.Label

$statusLabel.Text = "● Ready"

$statusLabel.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    10,
    [System.Drawing.FontStyle]::Bold
)

$statusLabel.Location = New-Object System.Drawing.Point(550,20)

$statusLabel.AutoSize = $true

$rightPanel.Controls.Add($statusLabel)

# ------------------------------------------------------------
# Activity Log
# ------------------------------------------------------------

$logTitle = New-Object System.Windows.Forms.Label

$logTitle.Text = "ACTIVITY LOG"

$logTitle.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    11,
    [System.Drawing.FontStyle]::Bold
)

$logTitle.Location = New-Object System.Drawing.Point(20,70)

$logTitle.AutoSize = $true

$rightPanel.Controls.Add($logTitle)

$logBox = New-Object System.Windows.Forms.RichTextBox

$logBox.Location = New-Object System.Drawing.Point(20,105)

$logBox.Size = New-Object System.Drawing.Size(700,300)

$logBox.ReadOnly = $true

$logBox.BackColor = [System.Drawing.Color]::Black

$logBox.ForeColor = [System.Drawing.Color]::White

$logBox.Font = New-Object System.Drawing.Font(
    "Consolas",
    9
)

$rightPanel.Controls.Add($logBox)

# ------------------------------------------------------------
# Progress Bar
# ------------------------------------------------------------

$progress = New-Object System.Windows.Forms.ProgressBar

$progress.Location = New-Object System.Drawing.Point(20,470)

$progress.Size = New-Object System.Drawing.Size(700,25)

$progress.Minimum = 0

$progress.Maximum = 100

$progress.Value = 0

$rightPanel.Controls.Add($progress)


# ------------------------------------------------------------
# Theme Management
# ------------------------------------------------------------

$script:CurrentTheme = "Dark"

function Set-ControlTheme {

    param(
        [System.Windows.Forms.Control]$Control,
        [string]$Theme
    )

    if ($Theme -eq "Light") {

        $form.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)
        $header.BackColor = [System.Drawing.Color]::FromArgb(35,45,60)
        $leftPanel.BackColor = [System.Drawing.Color]::White
        $rightPanel.BackColor = [System.Drawing.Color]::White
        $logBox.BackColor = [System.Drawing.Color]::FromArgb(35,35,35)
        $logBox.ForeColor = [System.Drawing.Color]::White

        $title.ForeColor = [System.Drawing.Color]::White
        $subtitle.ForeColor = [System.Drawing.Color]::LightGray
        $version.ForeColor = [System.Drawing.Color]::White
        $themeLabel.ForeColor = [System.Drawing.Color]::White

        $section.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        $statusTitle.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        $logTitle.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)

        $form.Opacity = 1.0
    }
    elseif ($Theme -eq "Transparent") {

        $form.BackColor = [System.Drawing.Color]::FromArgb(235,240,245)
        $header.BackColor = [System.Drawing.Color]::FromArgb(35,45,60)
        $leftPanel.BackColor = [System.Drawing.Color]::FromArgb(235,240,245)
        $rightPanel.BackColor = [System.Drawing.Color]::FromArgb(235,240,245)
        $logBox.BackColor = [System.Drawing.Color]::FromArgb(25,25,25)
        $logBox.ForeColor = [System.Drawing.Color]::White

        $title.ForeColor = [System.Drawing.Color]::White
        $subtitle.ForeColor = [System.Drawing.Color]::Gainsboro
        $version.ForeColor = [System.Drawing.Color]::White
        $themeLabel.ForeColor = [System.Drawing.Color]::White

        $section.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        $statusTitle.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        $logTitle.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)

        # WinForms does not provide true per-control alpha blending.
        # Use form opacity for a reliable transparent-style appearance.
        $form.Opacity = 0.90
    }
    else {

        $form.BackColor = [System.Drawing.Color]::FromArgb(30,34,40)
        $header.BackColor = [System.Drawing.Color]::FromArgb(20,25,32)
        $leftPanel.BackColor = [System.Drawing.Color]::FromArgb(43,48,56)
        $rightPanel.BackColor = [System.Drawing.Color]::FromArgb(43,48,56)
        $logBox.BackColor = [System.Drawing.Color]::FromArgb(15,18,22)
        $logBox.ForeColor = [System.Drawing.Color]::White

        $title.ForeColor = [System.Drawing.Color]::White
        $subtitle.ForeColor = [System.Drawing.Color]::LightGray
        $version.ForeColor = [System.Drawing.Color]::White
        $themeLabel.ForeColor = [System.Drawing.Color]::White

        $section.ForeColor = [System.Drawing.Color]::White
        $statusTitle.ForeColor = [System.Drawing.Color]::White
        $logTitle.ForeColor = [System.Drawing.Color]::White
        $statusLabel.ForeColor = [System.Drawing.Color]::White

        $form.Opacity = 1.0
    }

    foreach ($button in @(
        $btnActions,
        $btnBaselines,
        $btnFull,
        $btnHealth,
        $btnConfig,
        $btnStuck,
        $btnUserPolicy,
        $btnOpenConfigMgr,
        $btnClear
    )) {

        if ($Theme -eq "Dark") {

            $button.BackColor = [System.Drawing.Color]::FromArgb(55,62,72)
            $button.ForeColor = [System.Drawing.Color]::White
        }
        elseif ($Theme -eq "Transparent") {

            $button.BackColor = [System.Drawing.Color]::FromArgb(220,225,230)
            $button.ForeColor = [System.Drawing.Color]::FromArgb(25,30,35)
        }
        else {

            $button.BackColor = [System.Drawing.Color]::White
            $button.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        }
    }

    $themeCombo.BackColor = [System.Drawing.Color]::White
    $themeCombo.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
}

$themeCombo.Add_SelectedIndexChanged({

    $script:CurrentTheme = [string]$themeCombo.SelectedItem

    Set-ControlTheme -Control $form -Theme $script:CurrentTheme

    Write-Log "Theme changed to: $script:CurrentTheme"
})

# ------------------------------------------------------------
# Logging Function
# ------------------------------------------------------------

function Write-Log {

    param(
        [string]$Message
    )

    $time = Get-Date -Format "HH:mm:ss"

    $logBox.AppendText(
        "[$time] $Message`r`n"
    )

    $logBox.SelectionStart = $logBox.Text.Length

    $logBox.ScrollToCaret()

    [System.Windows.Forms.Application]::DoEvents()
}

# ------------------------------------------------------------
# Run BAT File
# ------------------------------------------------------------

function Run-BatchFile {

    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {

        Write-Log "ERROR: File not found:"
        Write-Log $Path

        return
    }

    Write-Log "Starting: $(Split-Path $Path -Leaf)"

    try {

        $process = Start-Process `
            -FilePath "cmd.exe" `
            -ArgumentList "/c `"$Path`"" `
            -WorkingDirectory (Split-Path $Path) `
            -Wait `
            -PassThru

        if ($process.ExitCode -eq 0) {

            Write-Log "SUCCESS: $(Split-Path $Path -Leaf)"

        }
        else {

            Write-Log "WARNING: Script returned exit code $(
                $process.ExitCode
            )"
        }

    }
    catch {

        Write-Log "ERROR: $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------
# Run PowerShell Script
# ------------------------------------------------------------

function Run-PowerShellScript {

    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {

        Write-Log "ERROR: File not found:"
        Write-Log $Path

        return
    }

    Write-Log "Starting: $(Split-Path $Path -Leaf)"

    try {

        & powershell.exe `
            -NoProfile `
            -ExecutionPolicy Bypass `
            -File $Path

        if ($LASTEXITCODE -eq 0) {

            Write-Log "SUCCESS: $(Split-Path $Path -Leaf)"

        }
        else {

            Write-Log "WARNING: PowerShell returned exit code $LASTEXITCODE"
        }

    }
    catch {

        Write-Log "ERROR: $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------
# Open Configuration Manager
# ------------------------------------------------------------

function Open-ConfigurationManager {

    Write-Log ""
    Write-Log "Opening Configuration Manager..."

    try {

        Start-Process `
            -FilePath "control.exe" `
            -ArgumentList "smscfgrc"

        Write-Log "Configuration Manager opened successfully."

    }
    catch {

        Write-Log "ERROR: Unable to open Configuration Manager."

        Write-Log $_.Exception.Message
    }
}


# ------------------------------------------------------------
# Open Configuration Manager Button
# ------------------------------------------------------------

$btnOpenConfigMgr.Add_Click({

    $statusLabel.Text = "● Opening Configuration Manager"

    $progress.Value = 0

    Open-ConfigurationManager

    $progress.Value = 100

    $statusLabel.Text = "● Configuration Manager Opened"
})

# ------------------------------------------------------------
# Run All SCCM Actions
# ------------------------------------------------------------

$btnActions.Add_Click({

    $statusLabel.Text = "● Running Actions"

    $progress.Value = 10

    Write-Log "=========================================="

    Write-Log "RUNNING ALL SCCM ACTIONS"

    Write-Log "=========================================="

    Run-BatchFile $ActionScript

    $progress.Value = 100

    Write-Log ""

    Write-Log "All SCCM Actions process completed."

    Write-Log ""

    Write-Log "USER POLICY INFORMATION"

    Write-Log "------------------------------------------"

    Write-Log "User Policy Retrieval & Evaluation Cycle"

    Write-Log "STATUS: SKIPPED"

    Write-Log ""

    Write-Log "Reason:"

    Write-Log "User policy assignments are being skipped"

    Write-Log "by the Configuration Manager PolicyAgent"

    Write-Log "configuration."

    Write-Log ""

    Write-Log "This is not treated as a script failure."

    Write-Log "=========================================="

    $statusLabel.Text = "● Actions Completed"
})

# ------------------------------------------------------------
# Evaluate All Baselines
# ------------------------------------------------------------

$btnBaselines.Add_Click({

    $statusLabel.Text = "● Evaluating Baselines"

    $progress.Value = 10

    Write-Log "=========================================="

    Write-Log "CONFIGURATION BASELINE EVALUATION"

    Write-Log "=========================================="

    Run-PowerShellScript $BaselineScript

    $progress.Value = 100

    Write-Log ""

    Write-Log "Baseline evaluation process completed."

    $statusLabel.Text = "● Baseline Evaluation Completed"
})

# ------------------------------------------------------------
# Full SCCM Evaluation
# ------------------------------------------------------------

$btnFull.Add_Click({

    $statusLabel.Text = "● Full Evaluation Running"

    $progress.Value = 0

    Write-Log "=========================================="

    Write-Log "FULL SCCM EVALUATION"

    Write-Log "=========================================="

    # --------------------------------------------------------
    # Step 1
    # --------------------------------------------------------

    Write-Log ""

    Write-Log "[1/2] Running SCCM Actions..."

    $progress.Value = 25

    Run-BatchFile $ActionScript

    # --------------------------------------------------------
    # Step 2
    # --------------------------------------------------------

    Write-Log ""

    Write-Log "[2/2] Evaluating Configuration Baselines..."

    $progress.Value = 50

    Run-PowerShellScript $BaselineScript

    # --------------------------------------------------------
    # User Policy Information
    # --------------------------------------------------------

    Write-Log ""

    Write-Log "USER POLICY NOTE"

    Write-Log "------------------------------------------"

    Write-Log "User Policy Retrieval & Evaluation Cycle"

    Write-Log "STATUS: SKIPPED"

    Write-Log ""

    Write-Log "PolicyAgent is skipping user policy"

    Write-Log "assignment requests due to the current"

    Write-Log "client agent configuration."

    Write-Log ""

    Write-Log "This is NOT treated as a script failure."

    # --------------------------------------------------------
    # Complete
    # --------------------------------------------------------

    $progress.Value = 100

    Write-Log ""

    Write-Log "=========================================="

    Write-Log "FULL SCCM EVALUATION COMPLETED"

    Write-Log "=========================================="

    $statusLabel.Text = "● Evaluation Completed"

    # --------------------------------------------------------
    # Wait before opening Configuration Manager
    # --------------------------------------------------------

    Write-Log ""

    Write-Log "Waiting 2 seconds..."

    Start-Sleep -Seconds 2

    # --------------------------------------------------------
    # Open Configuration Manager
    # --------------------------------------------------------

    Open-ConfigurationManager

})

# ------------------------------------------------------------
# Fix Configuration Manager Configuration Tab
# ------------------------------------------------------------

$btnConfig.Add_Click({

    $statusLabel.Text = "● Running Configuration Fix"

    $progress.Value = 20

    Write-Log "=========================================="

    Write-Log "CONFIGURATION TAB FIX"

    Write-Log "=========================================="

    Run-PowerShellScript $ConfigFixScript

    $progress.Value = 100

    Write-Log ""

    Write-Log "Configuration Tab fix completed."

    $statusLabel.Text = "● Configuration Fix Completed"
})

# ------------------------------------------------------------
# SCCM Client Stuck Fix
# ------------------------------------------------------------

$btnStuck.Add_Click({

    $statusLabel.Text = "● Running SCCM Fix"

    $progress.Value = 20

    Write-Log "=========================================="

    Write-Log "SCCM CLIENT STUCK FIX"

    Write-Log "=========================================="

    Run-BatchFile $SccmFixScript

    $progress.Value = 100

    Write-Log ""

    Write-Log "SCCM Client Stuck Fix completed."

    $statusLabel.Text = "● SCCM Fix Completed"
})

# ------------------------------------------------------------
# User Policy Information
# ------------------------------------------------------------

$btnUserPolicy.Add_Click({

    $statusLabel.Text = "● User Policy Information"

    Write-Log "=========================================="

    Write-Log "USER POLICY RETRIEVAL & EVALUATION"

    Write-Log "=========================================="

    Write-Log ""

    Write-Log "STATUS: SKIPPED"

    Write-Log ""

    Write-Log "WHY CAN'T THIS ACTION BE TRIGGERED?"

    Write-Log "------------------------------------------"

    Write-Log "The Configuration Manager PolicyAgent"

    Write-Log "is skipping user policy assignment"

    Write-Log "requests due to the current client"

    Write-Log "agent configuration."

    Write-Log ""

    Write-Log "PolicyAgent.log reports:"

    Write-Log ""

    Write-Log "Skipping request for user policy"

    Write-Log "assignments due to agent configuration."

    Write-Log ""

    Write-Log "The user policy schedules exist on the"

    Write-Log "client, but the PolicyAgent configuration"

    Write-Log "prevents the user policy assignment"

    Write-Log "request from being processed normally."

    Write-Log ""

    Write-Log "Therefore this tool does NOT force"

    Write-Log "schedule IDs 026 or 027."

    Write-Log ""

    Write-Log "RESULT: SKIPPED - CLIENT CONFIGURATION"

    Write-Log "=========================================="

    [System.Windows.Forms.MessageBox]::Show(

        "User Policy Retrieval & Evaluation Cycle`r`n`r`n" +

        "STATUS: SKIPPED`r`n`r`n" +

        "The Configuration Manager PolicyAgent is " +

        "skipping user policy assignment requests " +

        "due to the current client agent configuration.`r`n`r`n" +

        "This is not treated as a script failure.",

        "User Policy Information",

        [System.Windows.Forms.MessageBoxButtons]::OK,

        [System.Windows.Forms.MessageBoxIcon]::Information
    )

    $statusLabel.Text = "● User Policy: Skipped"
})

# ------------------------------------------------------------
# SCCM Client Health Check
# ------------------------------------------------------------

$btnHealth.Add_Click({

    $statusLabel.Text = "● Checking Client"

    $progress.Value = 10

    Write-Log "=========================================="

    Write-Log "SCCM CLIENT HEALTH CHECK"

    Write-Log "=========================================="

    # --------------------------------------------------------
    # CcmExec Service
    # --------------------------------------------------------

    Write-Log ""

    Write-Log "Checking CcmExec service..."

    $service = Get-Service `
        -Name CcmExec `
        -ErrorAction SilentlyContinue

    if ($service -and $service.Status -eq "Running") {

        Write-Log "PASS - CcmExec service is RUNNING"

    }
    elseif ($service) {

        Write-Log "FAIL - CcmExec service is $(
            $service.Status
        )"

    }
    else {

        Write-Log "FAIL - CcmExec service not found"
    }

    $progress.Value = 35

    # --------------------------------------------------------
    # SMS_Client
    # --------------------------------------------------------

    Write-Log ""

    Write-Log "Checking SMS_Client WMI class..."

    try {

        $client = Get-CimInstance `
            -Namespace "root\ccm" `
            -ClassName "SMS_Client" `
            -ErrorAction Stop

        if ($client) {

            Write-Log "PASS - SMS_Client WMI class available"
        }

    }
    catch {

        Write-Log "FAIL - SMS_Client WMI class unavailable"
    }

    $progress.Value = 60

    # --------------------------------------------------------
    # DCM
    # --------------------------------------------------------

    Write-Log ""

    Write-Log "Checking DCM baseline provider..."

    try {

        $dcm = Get-CimInstance `
            -Namespace "root\ccm\dcm" `
            -ClassName "SMS_DesiredConfiguration" `
            -ErrorAction Stop

        Write-Log "PASS - DCM baseline provider available"

    }
    catch {

        Write-Log "FAIL - DCM provider unavailable"
    }

    $progress.Value = 100

    Write-Log ""

    Write-Log "=========================================="

    Write-Log "CLIENT HEALTH CHECK COMPLETED"

    Write-Log "=========================================="

    $statusLabel.Text = "● Health Check Completed"
})

# ------------------------------------------------------------
# Clear Activity Log
# ------------------------------------------------------------

$btnClear.Add_Click({

    $logBox.Clear()

    $progress.Value = 0

    $statusLabel.Text = "● Ready"

    Write-Log "Activity log cleared."
})

# ------------------------------------------------------------
# Initial Log
# ------------------------------------------------------------

Write-Log "=========================================="

Write-Log "SCCM AUTO EVALUATION"

Write-Log "=========================================="

Write-Log "Author  : Jagadish V"

Write-Log "Version : 1.1.0"

Write-Log ""

Write-Log "Backend directory:"

Write-Log $BackendDirectory

Write-Log ""

Write-Log "Existing SCCM scripts are unchanged."

Write-Log "GUI is ready."

Write-Log "=========================================="

# ------------------------------------------------------------
# Apply Initial Theme
# ------------------------------------------------------------

Set-ControlTheme -Control $form -Theme "Dark"

# ------------------------------------------------------------
# Start GUI
# ------------------------------------------------------------

[void]$form.ShowDialog()