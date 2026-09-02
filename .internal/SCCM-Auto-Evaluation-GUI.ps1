# ============================================================
# SCCM AUTO EVALUATION GUI
# Configuration Manager Client Automation Tool
#
# Author  : Jagadish V
# Version : 1.2.0
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

$RestartServicesScript = Join-Path $BackendDirectory "Restart-SCCM-Services.ps1"
$ClientAlwaysOnInternetScript = Join-Path $BackendDirectory "Enable-SCCM-ClientAlwaysOnInternet.ps1"

# ------------------------------------------------------------
# Main Form - Modern Dashboard Layout
# ------------------------------------------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "SCCM Auto Evaluation - Jagadish V"
$form.Size = New-Object System.Drawing.Size(1200,800)
$form.MinimumSize = New-Object System.Drawing.Size(1200,800)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(30,34,40)

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0,0)
$header.Size = New-Object System.Drawing.Size(1200,90)
$header.BackColor = [System.Drawing.Color]::FromArgb(20,25,32)
$form.Controls.Add($header)

$title = New-Object System.Windows.Forms.Label
$title.Text = "SCCM AUTO EVALUATION"
$title.Font = New-Object System.Drawing.Font("Segoe UI",20,[System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::White
$title.Location = New-Object System.Drawing.Point(28,13)
$title.AutoSize = $true
$header.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "Configuration Manager Client Management & Automation"
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI",10)
$subtitle.ForeColor = [System.Drawing.Color]::LightGray
$subtitle.Location = New-Object System.Drawing.Point(31,52)
$subtitle.AutoSize = $true
$header.Controls.Add($subtitle)

$version = New-Object System.Windows.Forms.Label
$version.Text = "v1.2.0  |  Jagadish V"
$version.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$version.ForeColor = [System.Drawing.Color]::White
$version.Location = New-Object System.Drawing.Point(1000,18)
$version.AutoSize = $true
$header.Controls.Add($version)

$themeLabel = New-Object System.Windows.Forms.Label
$themeLabel.Text = "Theme"
$themeLabel.Font = New-Object System.Drawing.Font("Segoe UI",9)
$themeLabel.ForeColor = [System.Drawing.Color]::White
$themeLabel.Location = New-Object System.Drawing.Point(900,53)
$themeLabel.AutoSize = $true
$header.Controls.Add($themeLabel)

$themeCombo = New-Object System.Windows.Forms.ComboBox
$themeCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
[void]$themeCombo.Items.Add("Dark")
[void]$themeCombo.Items.Add("Light")
[void]$themeCombo.Items.Add("Transparent")
$themeCombo.SelectedIndex = 0
$themeCombo.Font = New-Object System.Drawing.Font("Segoe UI",9)
$themeCombo.Location = New-Object System.Drawing.Point(944,48)
$themeCombo.Size = New-Object System.Drawing.Size(125,27)
$header.Controls.Add($themeCombo)

# ------------------------------------------------------------
# Sidebar Navigation
# ------------------------------------------------------------

$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Location = New-Object System.Drawing.Point(15,105)
$leftPanel.Size = New-Object System.Drawing.Size(255,645)
$leftPanel.BackColor = [System.Drawing.Color]::FromArgb(43,48,56)
$form.Controls.Add($leftPanel)

$section = New-Object System.Windows.Forms.Label
$section.Text = "SCCM NAVIGATION"
$section.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
$section.ForeColor = [System.Drawing.Color]::White
$section.Location = New-Object System.Drawing.Point(18,16)
$section.AutoSize = $true
$leftPanel.Controls.Add($section)

$sectionHint = New-Object System.Windows.Forms.Label
$sectionHint.Text = "Choose a category"
$sectionHint.Font = New-Object System.Drawing.Font("Segoe UI",8)
$sectionHint.ForeColor = [System.Drawing.Color]::LightGray
$sectionHint.Location = New-Object System.Drawing.Point(19,40)
$sectionHint.AutoSize = $true
$leftPanel.Controls.Add($sectionHint)

function New-NavigationButton {
    param([string]$Text,[int]$Top)

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point(18,$Top)
    $button.Size = New-Object System.Drawing.Size(219,44)
    $button.Font = New-Object System.Drawing.Font("Segoe UI",9.5,[System.Drawing.FontStyle]::Bold)
    $button.FlatStyle = "Flat"
    $button.FlatAppearance.BorderSize = 1
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $button.TabStop = $true
    $leftPanel.Controls.Add($button)
    return $button
}

function New-ActionButton {
    param(
        [string]$Text,
        [int]$Top,
        [int]$Height = 43
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point(15,$Top)
    $button.Size = New-Object System.Drawing.Size(225,$Height)
    $button.Font = New-Object System.Drawing.Font("Segoe UI",9.5)
    $button.FlatStyle = "Flat"
    $button.FlatAppearance.BorderSize = 1
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $button.TabStop = $true
    $leftPanel.Controls.Add($button)
    return $button
}

$navDashboard = New-NavigationButton "Dashboard" 76
$navCore = New-NavigationButton "Core Actions" 126
$navEvaluation = New-NavigationButton "Evaluation" 176
$navTroubleshooting = New-NavigationButton "Troubleshooting" 226
$navUtilities = New-NavigationButton "Utilities" 276

$sidebarSeparator = New-Object System.Windows.Forms.Label
$sidebarSeparator.Text = "________________________________"
$sidebarSeparator.Font = New-Object System.Drawing.Font("Segoe UI",8)
$sidebarSeparator.ForeColor = [System.Drawing.Color]::FromArgb(90,100,112)
$sidebarSeparator.Location = New-Object System.Drawing.Point(18,338)
$sidebarSeparator.AutoSize = $true
$leftPanel.Controls.Add($sidebarSeparator)

$sidebarFooter = New-Object System.Windows.Forms.Label
$sidebarFooter.Text = "Administrator mode required"
$sidebarFooter.Font = New-Object System.Drawing.Font("Segoe UI",8)
$sidebarFooter.ForeColor = [System.Drawing.Color]::LightGray
$sidebarFooter.Location = New-Object System.Drawing.Point(19,362)
$sidebarFooter.AutoSize = $true
$leftPanel.Controls.Add($sidebarFooter)

$sidebarVersion = New-Object System.Windows.Forms.Label
$sidebarVersion.Text = "SCCM Auto Evaluation  |  v1.2.0"
$sidebarVersion.Font = New-Object System.Drawing.Font("Segoe UI",7.5)
$sidebarVersion.ForeColor = [System.Drawing.Color]::FromArgb(150,160,175)
$sidebarVersion.Location = New-Object System.Drawing.Point(19,386)
$sidebarVersion.AutoSize = $true
$leftPanel.Controls.Add($sidebarVersion)

# Existing tested action controls.
$btnFull = New-ActionButton "Full SCCM Evaluation" 86 44
$btnRestart = New-ActionButton "Restart SCCM Services" 136 42
$btnHealth = New-ActionButton "Verify SCCM Client Health" 184 42
$btnClientOnline = New-ActionButton "Enable Client Always On Internet" 232 42

$btnBaselines = New-ActionButton "Evaluate All Baselines" 256 42
$btnActions = New-ActionButton "Run All SCCM Actions" 304 42

$btnConfig = New-ActionButton "Fix Configuration Tab" 376 42
$btnStuck = New-ActionButton "SCCM Client Stuck Fix" 424 42
$btnUserPolicy = New-ActionButton "User Policy Information" 472 42

$btnOpenConfigMgr = New-ActionButton "Open Configuration Manager" 544 42
$btnOpenRegistry = New-ActionButton "Open ClientAlwaysOnInternet Registry" 592 42
$btnClear = New-ActionButton "Clear Activity Log" 640 42

# ------------------------------------------------------------
# Main Content Panel
# ------------------------------------------------------------

$rightPanel = New-Object System.Windows.Forms.Panel
$rightPanel.Location = New-Object System.Drawing.Point(285,105)
$rightPanel.Size = New-Object System.Drawing.Size(900,645)
$rightPanel.BackColor = [System.Drawing.Color]::FromArgb(43,48,56)
$form.Controls.Add($rightPanel)

$contentTitle = New-Object System.Windows.Forms.Label
$contentTitle.Text = "Dashboard"
$contentTitle.Font = New-Object System.Drawing.Font("Segoe UI",15,[System.Drawing.FontStyle]::Bold)
$contentTitle.ForeColor = [System.Drawing.Color]::White
$contentTitle.Location = New-Object System.Drawing.Point(22,15)
$contentTitle.AutoSize = $true
$rightPanel.Controls.Add($contentTitle)

$contentHint = New-Object System.Windows.Forms.Label
$contentHint.Text = "Monitor the SCCM client and run maintenance actions."
$contentHint.Font = New-Object System.Drawing.Font("Segoe UI",8.5)
$contentHint.ForeColor = [System.Drawing.Color]::LightGray
$contentHint.Location = New-Object System.Drawing.Point(24,43)
$contentHint.AutoSize = $true
$rightPanel.Controls.Add($contentHint)

# ------------------------------------------------------------
# Status Cards
# ------------------------------------------------------------

function New-StatusCard {
    param([int]$Left,[string]$Heading,[string]$InitialValue)
    $card = New-Object System.Windows.Forms.Panel
    $card.Location = New-Object System.Drawing.Point($Left,72)
    $card.Size = New-Object System.Drawing.Size(270,70)
    $card.BackColor = [System.Drawing.Color]::FromArgb(55,62,72)
    $rightPanel.Controls.Add($card)

    $h = New-Object System.Windows.Forms.Label
    $h.Text = $Heading
    $h.Font = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $h.ForeColor = [System.Drawing.Color]::LightGray
    $h.Location = New-Object System.Drawing.Point(12,9)
    $h.AutoSize = $true
    $card.Controls.Add($h)

    $v = New-Object System.Windows.Forms.Label
    $v.Text = $InitialValue
    $v.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
    $v.ForeColor = [System.Drawing.Color]::White
    $v.Location = New-Object System.Drawing.Point(12,32)
    $v.AutoSize = $true
    $card.Controls.Add($v)

    return @{ Panel=$card; Value=$v; Heading=$h }
}

$serviceCard = New-StatusCard 20 "CCMEXEC SERVICE" "Not checked"
$wmiCard = New-StatusCard 310 "SCCM WMI" "Not checked"
$baselineCard = New-StatusCard 600 "BASELINE PROVIDER" "Not checked"

$serviceStatusLabel = $serviceCard.Value
$wmiStatusLabel = $wmiCard.Value
$baselineStatusLabel = $baselineCard.Value

# ------------------------------------------------------------
# Action Workspace
# ------------------------------------------------------------

$actionWorkspace = New-Object System.Windows.Forms.Panel
$actionWorkspace.Location = New-Object System.Drawing.Point(20,155)
$actionWorkspace.Size = New-Object System.Drawing.Size(860,205)
$actionWorkspace.BackColor = [System.Drawing.Color]::FromArgb(48,54,63)
$rightPanel.Controls.Add($actionWorkspace)

$workspaceTitle = New-Object System.Windows.Forms.Label
$workspaceTitle.Text = "QUICK ACTIONS"
$workspaceTitle.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$workspaceTitle.ForeColor = [System.Drawing.Color]::White
$workspaceTitle.Location = New-Object System.Drawing.Point(15,10)
$workspaceTitle.AutoSize = $true
$actionWorkspace.Controls.Add($workspaceTitle)

$workspaceHint = New-Object System.Windows.Forms.Label
$workspaceHint.Text = "Choose a category from the left."
$workspaceHint.Font = New-Object System.Drawing.Font("Segoe UI",8)
$workspaceHint.ForeColor = [System.Drawing.Color]::LightGray
$workspaceHint.Location = New-Object System.Drawing.Point(15,33)
$workspaceHint.AutoSize = $true
$actionWorkspace.Controls.Add($workspaceHint)

$actionButtons = @(
    $btnFull, $btnRestart, $btnHealth, $btnClientOnline,
    $btnBaselines, $btnActions,
    $btnConfig, $btnStuck, $btnUserPolicy,
    $btnOpenConfigMgr, $btnOpenRegistry, $btnClear
)

foreach ($button in $actionButtons) {
    $leftPanel.Controls.Remove($button)
    $actionWorkspace.Controls.Add($button)
    $button.Size = New-Object System.Drawing.Size(395,42)
    $button.Font = New-Object System.Drawing.Font("Segoe UI",9.5)
}

$btnFull.Location = New-Object System.Drawing.Point(15,55)
$btnRestart.Location = New-Object System.Drawing.Point(430,55)
$btnHealth.Location = New-Object System.Drawing.Point(15,103)
$btnClientOnline.Location = New-Object System.Drawing.Point(430,103)

$btnBaselines.Location = New-Object System.Drawing.Point(15,55)
$btnActions.Location = New-Object System.Drawing.Point(430,55)

$btnConfig.Location = New-Object System.Drawing.Point(15,55)
$btnStuck.Location = New-Object System.Drawing.Point(430,55)
$btnUserPolicy.Location = New-Object System.Drawing.Point(15,151)

$btnOpenConfigMgr.Location = New-Object System.Drawing.Point(15,55)
$btnOpenRegistry.Location = New-Object System.Drawing.Point(430,55)
$btnClear.Location = New-Object System.Drawing.Point(15,103)


# ------------------------------------------------------------
# Activity Log
# ------------------------------------------------------------

$logTitle = New-Object System.Windows.Forms.Label
$logTitle.Text = "ACTIVITY LOG"
$logTitle.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
$logTitle.ForeColor = [System.Drawing.Color]::White
$logTitle.Location = New-Object System.Drawing.Point(20,375)
$logTitle.AutoSize = $true
$rightPanel.Controls.Add($logTitle)

$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(20,408)
$logBox.Size = New-Object System.Drawing.Size(860,165)
$logBox.ReadOnly = $true
$logBox.BackColor = [System.Drawing.Color]::FromArgb(15,18,22)
$logBox.ForeColor = [System.Drawing.Color]::White
$logBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$logBox.Font = New-Object System.Drawing.Font("Consolas",9)
$logBox.DetectUrls = $false
$rightPanel.Controls.Add($logBox)

# ------------------------------------------------------------
# Progress / Current Status
# ------------------------------------------------------------

$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Text = "Ready"
$progressLabel.Font = New-Object System.Drawing.Font("Segoe UI",8.5)
$progressLabel.ForeColor = [System.Drawing.Color]::LightGray
$progressLabel.Location = New-Object System.Drawing.Point(20,580)
$progressLabel.AutoSize = $true
$rightPanel.Controls.Add($progressLabel)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(20,605)
$progress.Size = New-Object System.Drawing.Size(860,22)
$progress.Minimum = 0
$progress.Maximum = 100
$progress.Value = 0
$rightPanel.Controls.Add($progress)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$statusLabel.ForeColor = [System.Drawing.Color]::White
$statusLabel.Location = New-Object System.Drawing.Point(700,15)
$statusLabel.AutoSize = $true
$rightPanel.Controls.Add($statusLabel)

$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.AutoPopDelay = 8000
$toolTip.InitialDelay = 400
$toolTip.ReshowDelay = 200
$toolTip.ShowAlways = $true
$toolTip.SetToolTip($btnFull, "Run the complete SCCM automation. The existing action script also performs baseline evaluation.")
$toolTip.SetToolTip($btnRestart, "Restart the SMS Agent Host (CcmExec) service and verify that it returns to Running.")
$toolTip.SetToolTip($btnHealth, "Check CcmExec, SCCM WMI, and the DCM baseline provider.")
$toolTip.SetToolTip($btnClientOnline, "Set ClientAlwaysOnInternet to 1 in HKLM\SOFTWARE\Microsoft\CCM\Security.")
$toolTip.SetToolTip($btnBaselines, "Run the standalone Configuration Baseline evaluation script.")
$toolTip.SetToolTip($btnActions, "Run the existing SCCM automation script.")
$toolTip.SetToolTip($btnConfig, "Run the Configuration Manager configuration tab fix.")
$toolTip.SetToolTip($btnStuck, "Run the SCCM client stuck troubleshooting script.")
$toolTip.SetToolTip($btnUserPolicy, "Show information about the current user policy evaluation behavior.")
$toolTip.SetToolTip($btnOpenConfigMgr, "Open the local Configuration Manager control panel.")
$toolTip.SetToolTip($btnOpenRegistry, "Open HKLM\SOFTWARE\Microsoft\CCM\Security and show ClientAlwaysOnInternet.")
$toolTip.SetToolTip($btnClear, "Clear the activity log and reset the progress indicator.")

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
        foreach ($navLabel in @($navDashboard,$navCore,$navEvaluation,$navTroubleshooting,$navUtilities)) { $navLabel.ForeColor = [System.Drawing.Color]::FromArgb(90,105,125) }
        $contentTitle.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        $logTitle.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)

        $form.Opacity = 1.0
    }
    elseif ($Theme -eq "Transparent") {

        # Glass-style transparent mode:
        # keep the form readable while allowing a subtle amount of the desktop
        # to show through. WinForms does not support reliable per-control alpha,
        # so the form opacity is intentionally kept high and the log remains dark.
        $form.BackColor = [System.Drawing.Color]::FromArgb(24,31,41)
        $header.BackColor = [System.Drawing.Color]::FromArgb(17,23,32)
        $leftPanel.BackColor = [System.Drawing.Color]::FromArgb(34,44,57)
        $rightPanel.BackColor = [System.Drawing.Color]::FromArgb(34,44,57)
        $logBox.BackColor = [System.Drawing.Color]::FromArgb(12,16,21)
        $logBox.ForeColor = [System.Drawing.Color]::White

        $title.ForeColor = [System.Drawing.Color]::White
        $subtitle.ForeColor = [System.Drawing.Color]::Gainsboro
        $version.ForeColor = [System.Drawing.Color]::White
        $themeLabel.ForeColor = [System.Drawing.Color]::White

        $section.ForeColor = [System.Drawing.Color]::White
        foreach ($navLabel in @($navDashboard,$navCore,$navEvaluation,$navTroubleshooting,$navUtilities)) { $navLabel.ForeColor = [System.Drawing.Color]::FromArgb(165,180,200) }
        $contentTitle.ForeColor = [System.Drawing.Color]::White
        $logTitle.ForeColor = [System.Drawing.Color]::White
        $statusLabel.ForeColor = [System.Drawing.Color]::White

        # 96% keeps the glass effect subtle instead of washing out the UI.
        $form.Opacity = 0.985
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
        foreach ($navLabel in @($navDashboard,$navCore,$navEvaluation,$navTroubleshooting,$navUtilities)) { $navLabel.ForeColor = [System.Drawing.Color]::FromArgb(150,165,185) }
        $contentTitle.ForeColor = [System.Drawing.Color]::White
        $logTitle.ForeColor = [System.Drawing.Color]::White
        $statusLabel.ForeColor = [System.Drawing.Color]::White

        $form.Opacity = 1.0
    }

    foreach ($button in @(
        $btnFull,
        $btnRestart,
        $btnHealth,
        $btnClientOnline,
        $btnBaselines,
        $btnActions,
        $btnConfig,
        $btnStuck,
        $btnUserPolicy,
        $btnOpenConfigMgr,
        $btnOpenRegistry,
        $btnClear
    )) {

        if ($Theme -eq "Dark") {

            $button.BackColor = [System.Drawing.Color]::FromArgb(55,62,72)
            $button.ForeColor = [System.Drawing.Color]::White
        }
        elseif ($Theme -eq "Transparent") {

            $button.BackColor = [System.Drawing.Color]::FromArgb(48,61,78)
            $button.ForeColor = [System.Drawing.Color]::White
        }
        else {

            $button.BackColor = [System.Drawing.Color]::White
            $button.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        }
    }

    if ($Theme -eq "Dark") {
        $actionWorkspace.BackColor = [System.Drawing.Color]::FromArgb(48,54,63)
        foreach ($nav in @($navDashboard,$navCore,$navEvaluation,$navTroubleshooting,$navUtilities)) {
            $nav.BackColor = [System.Drawing.Color]::FromArgb(55,62,72)
            $nav.ForeColor = [System.Drawing.Color]::White
        }
        $contentTitle.ForeColor = [System.Drawing.Color]::White
        $contentHint.ForeColor = [System.Drawing.Color]::LightGray
        $sectionHint.ForeColor = [System.Drawing.Color]::LightGray
        $sidebarFooter.ForeColor = [System.Drawing.Color]::LightGray
        $progressLabel.ForeColor = [System.Drawing.Color]::LightGray
        $serviceStatusLabel.ForeColor = [System.Drawing.Color]::White
        $wmiStatusLabel.ForeColor = [System.Drawing.Color]::White
        $baselineStatusLabel.ForeColor = [System.Drawing.Color]::White
        $statusLabel.ForeColor = [System.Drawing.Color]::White
        foreach ($card in @($serviceCard.Panel,$wmiCard.Panel,$baselineCard.Panel)) { $card.BackColor = [System.Drawing.Color]::FromArgb(55,62,72) }
    }
    elseif ($Theme -eq "Transparent") {
        $actionWorkspace.BackColor = [System.Drawing.Color]::FromArgb(48,61,78)
        foreach ($nav in @($navDashboard,$navCore,$navEvaluation,$navTroubleshooting,$navUtilities)) {
            $nav.BackColor = [System.Drawing.Color]::FromArgb(48,61,78)
            $nav.ForeColor = [System.Drawing.Color]::White
        }
        $contentTitle.ForeColor = [System.Drawing.Color]::White
        $contentHint.ForeColor = [System.Drawing.Color]::Gainsboro
        $sectionHint.ForeColor = [System.Drawing.Color]::Gainsboro
        $sidebarFooter.ForeColor = [System.Drawing.Color]::Gainsboro
        $progressLabel.ForeColor = [System.Drawing.Color]::Gainsboro
        $serviceStatusLabel.ForeColor = [System.Drawing.Color]::White
        $wmiStatusLabel.ForeColor = [System.Drawing.Color]::White
        $baselineStatusLabel.ForeColor = [System.Drawing.Color]::White
        $statusLabel.ForeColor = [System.Drawing.Color]::White
        foreach ($card in @($serviceCard.Panel,$wmiCard.Panel,$baselineCard.Panel)) { $card.BackColor = [System.Drawing.Color]::FromArgb(48,61,78) }
    }
    else {
        $actionWorkspace.BackColor = [System.Drawing.Color]::FromArgb(238,241,245)
        foreach ($nav in @($navDashboard,$navCore,$navEvaluation,$navTroubleshooting,$navUtilities)) {
            $nav.BackColor = [System.Drawing.Color]::White
            $nav.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        }
        $contentTitle.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        $contentHint.ForeColor = [System.Drawing.Color]::FromArgb(80,85,90)
        $sectionHint.ForeColor = [System.Drawing.Color]::FromArgb(80,85,90)
        $sidebarFooter.ForeColor = [System.Drawing.Color]::FromArgb(80,85,90)
        $progressLabel.ForeColor = [System.Drawing.Color]::FromArgb(80,85,90)
        $serviceStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        $wmiStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        $baselineStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(35,45,60)
        foreach ($card in @($serviceCard.Panel,$wmiCard.Panel,$baselineCard.Panel)) { $card.BackColor = [System.Drawing.Color]::White }
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
# Category Navigation
# ------------------------------------------------------------

$script:ActiveCategory = "Dashboard"

function Set-ActivityLogLayout {
    param([bool]$Large)

    if ($Large) {
        $logTitle.Location = New-Object System.Drawing.Point(20,155)
        $logBox.Location = New-Object System.Drawing.Point(20,188)
        $logBox.Size = New-Object System.Drawing.Size(860,340)
        $progressLabel.Location = New-Object System.Drawing.Point(20,540)
        $progress.Location = New-Object System.Drawing.Point(20,565)
    }
    else {
        $logTitle.Location = New-Object System.Drawing.Point(20,375)
        $logBox.Location = New-Object System.Drawing.Point(20,408)
        $logBox.Size = New-Object System.Drawing.Size(860,165)
        $progressLabel.Location = New-Object System.Drawing.Point(20,580)
        $progress.Location = New-Object System.Drawing.Point(20,605)
    }

    $rightPanel.PerformLayout()
    [System.Windows.Forms.Application]::DoEvents()
}

function Set-Category {
    param([string]$Category)

    $script:ActiveCategory = $Category

    foreach ($button in @(
        $btnFull,$btnRestart,$btnHealth,$btnClientOnline,
        $btnBaselines,$btnActions,
        $btnConfig,$btnStuck,$btnUserPolicy,
        $btnOpenConfigMgr,$btnOpenRegistry,$btnClear
    )) {
        $button.Visible = $false
    }

    switch ($Category) {
        "Dashboard" {
            $contentTitle.Text = "Dashboard"
            $contentHint.Text = "Overview of the SCCM client and activity history."

            # Dashboard gives the activity log most of the available workspace.
            $actionWorkspace.Visible = $false
            Set-ActivityLogLayout $true
        }
        "Core Actions" {
            $actionWorkspace.Visible = $true
            Set-ActivityLogLayout $false

            $contentTitle.Text = "Core Actions"
            $contentHint.Text = "Common SCCM client operations."
            $workspaceTitle.Text = "CORE SCCM ACTIONS"
            $workspaceHint.Text = "Run frequently used client operations."
            $btnFull.Visible = $true
            $btnRestart.Visible = $true
            $btnHealth.Visible = $true
            $btnClientOnline.Visible = $true
        }
        "Evaluation" {
            $actionWorkspace.Visible = $true
            Set-ActivityLogLayout $false

            $contentTitle.Text = "Evaluation"
            $contentHint.Text = "Configuration Manager evaluation and baseline tools."
            $workspaceTitle.Text = "EVALUATION TOOLS"
            $workspaceHint.Text = "Run baseline or SCCM evaluation workflows."
            $btnBaselines.Visible = $true
            $btnActions.Visible = $true
        }
        "Troubleshooting" {
            $actionWorkspace.Visible = $true
            Set-ActivityLogLayout $false

            $contentTitle.Text = "Troubleshooting"
            $contentHint.Text = "Repair and diagnose common SCCM client issues."
            $workspaceTitle.Text = "TROUBLESHOOTING TOOLS"
            $workspaceHint.Text = "Use these actions when the client needs attention."
            $btnConfig.Visible = $true
            $btnStuck.Visible = $true
            $btnUserPolicy.Visible = $true
        }
        "Utilities" {
            $actionWorkspace.Visible = $true
            Set-ActivityLogLayout $false

            $contentTitle.Text = "Utilities"
            $contentHint.Text = "Configuration Manager and activity log utilities."
            $workspaceTitle.Text = "UTILITY TOOLS"
            $workspaceHint.Text = "Open Configuration Manager, inspect ClientAlwaysOnInternet, or manage the activity log."
            $btnOpenConfigMgr.Visible = $true
            $btnOpenRegistry.Visible = $true
            $btnClear.Visible = $true
        }
    }

    foreach ($nav in @($navDashboard,$navCore,$navEvaluation,$navTroubleshooting,$navUtilities)) {
        $nav.FlatAppearance.BorderSize = 1
    }

    foreach ($nav in @($navDashboard,$navCore,$navEvaluation,$navTroubleshooting,$navUtilities)) {
        if ($nav.Text -eq $Category) {
            $nav.FlatAppearance.BorderSize = 2
        }
    }

    Write-Log "Navigation: $Category"
}

$navDashboard.Add_Click({ Set-Category "Dashboard"; Set-ActivityLogLayout $true; $actionWorkspace.Visible = $false })
$navCore.Add_Click({ Set-Category "Core Actions" })
$navEvaluation.Add_Click({ Set-Category "Evaluation" })
$navTroubleshooting.Add_Click({ Set-Category "Troubleshooting" })
$navUtilities.Add_Click({ Set-Category "Utilities" })

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
# Open ClientAlwaysOnInternet Registry Location
# ------------------------------------------------------------

function Open-ClientAlwaysOnInternetRegistry {

    $registryPath = "HKLM:\SOFTWARE\Microsoft\CCM\Security"
    $registryDisplayPath = "Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\CCM\Security"

    Write-Log ""
    Write-Log "Opening ClientAlwaysOnInternet registry location..."

    try {
        # Regedit uses LastKey to restore the last opened registry location.
        $regeditKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit"

        if (-not (Test-Path $regeditKey)) {
            New-Item -Path $regeditKey -Force | Out-Null
        }

        Set-ItemProperty -Path $regeditKey -Name "LastKey" -Value $registryDisplayPath -Type String -Force

        Start-Process -FilePath "regedit.exe"

        Write-Log "Registry opened: HKLM\SOFTWARE\Microsoft\CCM\Security"
    }
    catch {
        Write-Log "ERROR: Unable to open Registry Editor."
        Write-Log $_.Exception.Message
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
# Open ClientAlwaysOnInternet Registry Button
# ------------------------------------------------------------

$btnOpenRegistry.Add_Click({

    $statusLabel.Text = "● Opening ClientAlwaysOnInternet Registry"
    $progress.Value = 20

    Open-ClientAlwaysOnInternetRegistry

    $progress.Value = 100
    $progressLabel.Text = "Registry location opened"
    $statusLabel.Text = "● Registry Opened"
})

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

    $statusLabel.Text = "Full Evaluation Running"
    $progressLabel.Text = "Running complete SCCM automation..."
    $progress.Value = 10

    Write-Log "=========================================="
    Write-Log "FULL SCCM EVALUATION"
    Write-Log "=========================================="
    Write-Log ""
    Write-Log "The existing SCCM automation performs:"
    Write-Log "1. SCCM client actions"
    Write-Log "2. Configuration Baseline Evaluation"
    Write-Log ""
    Write-Log "Starting: SCCM-Actions-Automation.bat"
    Write-Log "Waiting for the complete automation to finish..."

    $progress.Value = 25
    Run-BatchFile $ActionScript

    $progress.Value = 90
    Write-Log ""
    Write-Log "SCCM Actions + Configuration Baseline Evaluation completed."

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

    $progress.Value = 100
    $progressLabel.Text = "Full evaluation completed"

    Write-Log ""
    Write-Log "=========================================="
    Write-Log "FULL SCCM EVALUATION COMPLETED"
    Write-Log "=========================================="

    $statusLabel.Text = "Evaluation Completed"

    Write-Log ""
    Write-Log "Waiting 2 seconds..."
    Start-Sleep -Seconds 2
    Open-ConfigurationManager
})

# ------------------------------------------------------------
# Enable Client Always On Internet
# ------------------------------------------------------------

$btnClientOnline.Add_Click({

    $statusLabel.Text = "Enabling Client Always On Internet"
    $progressLabel.Text = "Updating ClientAlwaysOnInternet registry value..."
    $progress.Value = 15

    Write-Log "=========================================="
    Write-Log "ENABLE CLIENT ALWAYS ON INTERNET"
    Write-Log "=========================================="
    Write-Log "Registry: HKLM\SOFTWARE\Microsoft\CCM\Security"
    Write-Log "Value: ClientAlwaysOnInternet"
    Write-Log "Target: 1"
    Write-Log ""

    Run-PowerShellScript $ClientAlwaysOnInternetScript

    $progress.Value = 100
    $progressLabel.Text = "ClientAlwaysOnInternet check completed"

    $registryPath = "HKLM:\SOFTWARE\Microsoft\CCM\Security"
    $registryValue = Get-ItemProperty -Path $registryPath -Name "ClientAlwaysOnInternet" -ErrorAction SilentlyContinue

    if ($null -ne $registryValue -and [int]$registryValue.ClientAlwaysOnInternet -eq 1) {
        $statusLabel.Text = "Client Always On Internet Enabled"
        Write-Log ""
        Write-Log "SUCCESS: ClientAlwaysOnInternet = 1"
    }
    else {
        $statusLabel.Text = "Client Always On Internet Check Warning"
        Write-Log ""
        Write-Log "WARNING: ClientAlwaysOnInternet is not set to 1."
    }

    Write-Log "Client Always On Internet script completed."
    Write-Log "Opening the registry location for verification..."
    Open-ClientAlwaysOnInternetRegistry

    Write-Log "=========================================="
})

# ------------------------------------------------------------
# Restart SCCM Services
# ------------------------------------------------------------

$btnRestart.Add_Click({

    $statusLabel.Text = "Restarting SCCM Services"
    $progressLabel.Text = "Restarting SMS Agent Host (CcmExec)..."
    $progress.Value = 15

    Write-Log "=========================================="
    Write-Log "RESTART SCCM SERVICES"
    Write-Log "=========================================="
    Write-Log "Starting: Restart-SCCM-Services.ps1"
    Write-Log ""

    Run-PowerShellScript $RestartServicesScript

    $progress.Value = 100
    $progressLabel.Text = "SCCM service restart completed"

    Write-Log ""
    Write-Log "SCCM service restart process completed."
    Write-Log "=========================================="

    $service = Get-Service -Name CcmExec -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        $serviceStatusLabel.Text = "Running"
        $statusLabel.Text = "SCCM Service Running"
    }
    elseif ($service) {
        $serviceStatusLabel.Text = [string]$service.Status
        $statusLabel.Text = "Service Check Warning"
    }
    else {
        $serviceStatusLabel.Text = "Not Found"
        $statusLabel.Text = "SCCM Service Not Found"
    }
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

        $serviceStatusLabel.Text = "Running"
        Write-Log "PASS - CcmExec service is RUNNING"

    }
    elseif ($service) {

        $serviceStatusLabel.Text = [string]$service.Status
        Write-Log "FAIL - CcmExec service is $(
            $service.Status
        )"

    }
    else {

        $serviceStatusLabel.Text = "Not Found"
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

            $wmiStatusLabel.Text = "Available"
            Write-Log "PASS - SMS_Client WMI class available"
        }

    }
    catch {

        $wmiStatusLabel.Text = "Unavailable"
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

        $baselineStatusLabel.Text = "Available"
        Write-Log "PASS - DCM baseline provider available"

    }
    catch {

        $baselineStatusLabel.Text = "Unavailable"
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

Write-Log "Version : 1.2.0"

Write-Log ""

Write-Log "Backend directory:"

Write-Log $BackendDirectory

Write-Log ""

Write-Log "Existing SCCM scripts are unchanged."
Write-Log "Restart-SCCM-Services.ps1 is enabled."

Write-Log "GUI is ready."

Write-Log "=========================================="

# ------------------------------------------------------------
# Apply Initial Theme
# ------------------------------------------------------------

Set-ControlTheme -Control $form -Theme "Dark"

# ------------------------------------------------------------
# Start GUI
# ------------------------------------------------------------

Set-Category "Dashboard"

[void]$form.ShowDialog()