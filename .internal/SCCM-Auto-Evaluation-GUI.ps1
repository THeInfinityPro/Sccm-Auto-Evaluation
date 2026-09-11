# ============================================================
# SCCM AUTO EVALUATION GUI
# Configuration Manager Client Automation Tool
# v1.3.0 release UI based on the working v1.2.0 WinForms baseline
#
# Author  : Jagadish V
# Version : 1.3.0
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
$NotepadVerifyScript = Join-Path $BackendDirectory "Verify-Microsoft-Notepad-Targeted.ps1"
$NotepadRemoveScript = Join-Path $BackendDirectory "Remove-Microsoft-Notepad.ps1"

# Manual fallback only: update Microsoft Defender Security Intelligence via MMPC.
$DefenderSecurityIntelligenceScript = Join-Path $BackendDirectory "Update-Defender-SecurityIntelligence-Force-MMPC.ps1"
$DefenderSecurityIntelligenceNormalScript = Join-Path $BackendDirectory "Update-Defender-SecurityIntelligence-Normal.ps1"

# ------------------------------------------------------------
# Main Form - Modern Dashboard Layout
# ------------------------------------------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "SCCM Auto Evaluation - Jagadish V"
$form.Size = New-Object System.Drawing.Size(1280,820)
$form.MinimumSize = New-Object System.Drawing.Size(1100,720)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "Sizable"
$form.MaximizeBox = $true
$form.MinimizeBox = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(15,20,27)

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0,0)
$header.Size = New-Object System.Drawing.Size(1280,128)
$header.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$header.BackColor = [System.Drawing.Color]::FromArgb(10,14,20)
$form.Controls.Add($header)

$title = New-Object System.Windows.Forms.Label
$title.Text = "SCCM AUTO EVALUATION"
$title.Font = New-Object System.Drawing.Font("Segoe UI Semibold",22,[System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::White
$title.Location = New-Object System.Drawing.Point(30,14)
$title.AutoSize = $true
$header.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "Configuration Manager Client Management & Automation"
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI",10)
$subtitle.ForeColor = [System.Drawing.Color]::FromArgb(160,171,188)
$subtitle.Location = New-Object System.Drawing.Point(32,70)
$subtitle.AutoSize = $true
$header.Controls.Add($subtitle)

$version = New-Object System.Windows.Forms.Label
$version.Text = "v1.3.0  |  Jagadish V"
$version.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$version.ForeColor = [System.Drawing.Color]::White
$version.Location = New-Object System.Drawing.Point(1060,18)
$version.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$version.AutoSize = $true
$header.Controls.Add($version)

# Version label stays on the right side of the fixed dark header.
$version.Left = 0
$version.Top = 16
$version.AutoSize = $true
$version.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right



# ------------------------------------------------------------
# Responsive Header Layout
# ------------------------------------------------------------
function Update-HeaderLayout {
    $version.Left = [Math]::Max(20, $header.ClientSize.Width - $version.Width - 25)
    $version.Top = 16
}
$header.Add_Resize({
    try { Update-HeaderLayout } catch {}
})
# ------------------------------------------------------------
# Sidebar Navigation
# ------------------------------------------------------------

$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Location = New-Object System.Drawing.Point(15,142)
$leftPanel.Size = New-Object System.Drawing.Size(250,600)
$leftPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
$leftPanel.BackColor = [System.Drawing.Color]::FromArgb(25,32,42)
$form.Controls.Add($leftPanel)

$section = New-Object System.Windows.Forms.Label
$section.Text = "SCCM NAVIGATION"
$section.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
$section.ForeColor = [System.Drawing.Color]::White
$section.Location = New-Object System.Drawing.Point(18,16)
$section.AutoSize = $true
$leftPanel.Controls.Add($section)

$sectionHint = New-Object System.Windows.Forms.Label
$sectionHint.Text = ""
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
    $button.Size = New-Object System.Drawing.Size(220,46)
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

$navDashboard = New-NavigationButton "Dashboard" 82
$navCore = New-NavigationButton "Core Actions" 136
$navEvaluation = New-NavigationButton "Evaluation" 190
$navTroubleshooting = New-NavigationButton "Troubleshooting" 244
$navUtilities = New-NavigationButton "Utilities" 298
$navSecurity = New-NavigationButton "Security" 352

$sidebarSeparator = New-Object System.Windows.Forms.Label
$sidebarSeparator.Text = "________________________________"
$sidebarSeparator.Font = New-Object System.Drawing.Font("Segoe UI",8)
$sidebarSeparator.ForeColor = [System.Drawing.Color]::FromArgb(90,100,112)
$sidebarSeparator.Location = New-Object System.Drawing.Point(18,420)
$sidebarSeparator.AutoSize = $true
$leftPanel.Controls.Add($sidebarSeparator)

$sidebarFooter = New-Object System.Windows.Forms.Label
$sidebarFooter.Text = "Administrator mode required"
$sidebarFooter.Font = New-Object System.Drawing.Font("Segoe UI",8)
$sidebarFooter.ForeColor = [System.Drawing.Color]::LightGray
$sidebarFooter.Location = New-Object System.Drawing.Point(19,449)
$sidebarFooter.AutoSize = $true
$leftPanel.Controls.Add($sidebarFooter)

$sidebarVersion = New-Object System.Windows.Forms.Label
$sidebarVersion.Text = "SCCM Auto Evaluation  |  v1.3.0"
$sidebarVersion.Font = New-Object System.Drawing.Font("Segoe UI",7.5)
$sidebarVersion.ForeColor = [System.Drawing.Color]::FromArgb(150,160,175)
$sidebarVersion.Location = New-Object System.Drawing.Point(19,473)
$sidebarVersion.AutoSize = $true
$leftPanel.Controls.Add($sidebarVersion)

# Existing tested action controls.
$btnFull = New-ActionButton "Full SCCM Evaluation" 86 44
$btnRestart = New-ActionButton "Restart SCCM Services" 136 42
$btnHealth = New-ActionButton "Verify SCCM Client Health" 184 42
$btnClientOnline = New-ActionButton "Enable Client Always On Internet" 232 42
$btnNotepadVerify = New-ActionButton "Verify Microsoft Notepad" 280 42
$btnNotepadRemove = New-ActionButton "Remove Microsoft Notepad" 326 42
$btnDefenderNormal = New-ActionButton "Check and Update Defender Security Intelligence" 280 42
$btnDefenderUpdate = New-ActionButton "Force-MMPC Defender Fallback" 326 42

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
$rightPanel.Location = New-Object System.Drawing.Point(280,142)
$rightPanel.Size = New-Object System.Drawing.Size(975,600)
$rightPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$rightPanel.BackColor = [System.Drawing.Color]::FromArgb(25,32,42)
$form.Controls.Add($rightPanel)

$contentTitle = New-Object System.Windows.Forms.Label
$contentTitle.Text = "Dashboard"
$contentTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold",19,[System.Drawing.FontStyle]::Bold)
$contentTitle.ForeColor = [System.Drawing.Color]::White
$contentTitle.Location = New-Object System.Drawing.Point(22,10)
$contentTitle.AutoSize = $true
$rightPanel.Controls.Add($contentTitle)

$contentHint = New-Object System.Windows.Forms.Label
$contentHint.Text = "Monitor the SCCM client and run maintenance actions."
$contentHint.Font = New-Object System.Drawing.Font("Segoe UI",8.5)
$contentHint.ForeColor = [System.Drawing.Color]::LightGray
$contentHint.Location = New-Object System.Drawing.Point(24,58)
$contentHint.AutoSize = $true
$rightPanel.Controls.Add($contentHint)

# ------------------------------------------------------------
# Status Cards
# ------------------------------------------------------------

function New-StatusCard {
    param([int]$Left,[string]$Heading,[string]$InitialValue)
    $card = New-Object System.Windows.Forms.Panel
    $card.Location = New-Object System.Drawing.Point($Left,92)
    $card.Size = New-Object System.Drawing.Size(285,72)
    $card.BackColor = [System.Drawing.Color]::FromArgb(32,42,54)
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
$wmiCard = New-StatusCard 325 "SCCM WMI" "Not checked"
$baselineCard = New-StatusCard 630 "BASELINE PROVIDER" "Not checked"

$serviceStatusLabel = $serviceCard.Value
$wmiStatusLabel = $wmiCard.Value
$baselineStatusLabel = $baselineCard.Value

# ------------------------------------------------------------
# Action Workspace
# ------------------------------------------------------------

$actionWorkspace = New-Object System.Windows.Forms.Panel
$actionWorkspace.Location = New-Object System.Drawing.Point(20,188)
$actionWorkspace.Size = New-Object System.Drawing.Size(935,228)
$actionWorkspace.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$actionWorkspace.BackColor = [System.Drawing.Color]::FromArgb(28,37,48)
$rightPanel.Controls.Add($actionWorkspace)

$workspaceTitle = New-Object System.Windows.Forms.Label
$workspaceTitle.Text = "QUICK ACTIONS"
$workspaceTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold",12,[System.Drawing.FontStyle]::Bold)
$workspaceTitle.ForeColor = [System.Drawing.Color]::White
$workspaceTitle.Location = New-Object System.Drawing.Point(15,11)
$workspaceTitle.AutoSize = $true
$actionWorkspace.Controls.Add($workspaceTitle)

$workspaceHint = New-Object System.Windows.Forms.Label
$workspaceHint.Text = "Choose a category from the left."
$workspaceHint.Font = New-Object System.Drawing.Font("Segoe UI",9)
$workspaceHint.ForeColor = [System.Drawing.Color]::LightGray
$workspaceHint.Location = New-Object System.Drawing.Point(15,40)
$workspaceHint.AutoSize = $true
$actionWorkspace.Controls.Add($workspaceHint)

$actionButtons = @(
    $btnFull, $btnRestart, $btnHealth, $btnClientOnline, $btnNotepadVerify, $btnNotepadRemove, $btnDefenderNormal, $btnDefenderUpdate,
    $btnBaselines, $btnActions,
    $btnConfig, $btnStuck, $btnUserPolicy,
    $btnOpenConfigMgr, $btnOpenRegistry, $btnClear
)

foreach ($button in $actionButtons) {
    $leftPanel.Controls.Remove($button)
    $actionWorkspace.Controls.Add($button)
    $button.Size = New-Object System.Drawing.Size(285,42)
    $button.Font = New-Object System.Drawing.Font("Segoe UI",9.5)
}

$btnFull.Location = New-Object System.Drawing.Point(15,66)
$btnRestart.Location = New-Object System.Drawing.Point(330,66)
$btnHealth.Location = New-Object System.Drawing.Point(15,115)
$btnClientOnline.Location = New-Object System.Drawing.Point(330,115)
$btnDefenderNormal.Location = New-Object System.Drawing.Point(15,78)
$btnDefenderUpdate.Location = New-Object System.Drawing.Point(15,126)

$btnBaselines.Location = New-Object System.Drawing.Point(15,66)
$btnActions.Location = New-Object System.Drawing.Point(330,66)

$btnConfig.Location = New-Object System.Drawing.Point(15,66)
$btnStuck.Location = New-Object System.Drawing.Point(330,66)
$btnUserPolicy.Location = New-Object System.Drawing.Point(645,66)

$btnOpenConfigMgr.Location = New-Object System.Drawing.Point(15,66)
$btnOpenRegistry.Location = New-Object System.Drawing.Point(330,66)
$btnClear.Location = New-Object System.Drawing.Point(645,66)



# ------------------------------------------------------------
# Responsive Content Widths
# ------------------------------------------------------------
function Update-ContentLayout {
    $available = [Math]::Max(500, $rightPanel.ClientSize.Width - 40)

    # Three status cards with proportional spacing.
    $gap = 14
    $cardWidth = [Math]::Max(220, [int](($available - ($gap * 2)) / 3))
    $serviceCard.Panel.Width = $cardWidth
    $wmiCard.Panel.Width = $cardWidth
    $baselineCard.Panel.Width = $cardWidth

    $serviceCard.Panel.Left = 20
    $wmiCard.Panel.Left = 20 + $cardWidth + $gap
    $baselineCard.Panel.Left = 20 + (($cardWidth + $gap) * 2)

    $actionWorkspace.Width = $available
    $logBox.Width = $available
    Update-HeaderLayout
}

$rightPanel.Add_Resize({
    try { Update-ContentLayout } catch {}
})

# ------------------------------------------------------------
# Activity Log
# ------------------------------------------------------------

$logTitle = New-Object System.Windows.Forms.Label
$logTitle.Text = "ACTIVITY LOG"
$logTitle.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
$logTitle.ForeColor = [System.Drawing.Color]::White
$logTitle.Location = New-Object System.Drawing.Point(20,430)
$logTitle.AutoSize = $true
$rightPanel.Controls.Add($logTitle)

$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(20,457)
$logBox.Size = New-Object System.Drawing.Size(935,220)
$logBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$logBox.ReadOnly = $true
$logBox.BackColor = [System.Drawing.Color]::FromArgb(15,18,22)
$logBox.ForeColor = [System.Drawing.Color]::White
$logBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$logBox.Font = New-Object System.Drawing.Font("Consolas",9)
$logBox.DetectUrls = $false
$rightPanel.Controls.Add($logBox)


# ------------------------------------------------------------
# Responsive Action Button Layout
# ------------------------------------------------------------
function Update-ActionButtonLayout {
    $workspaceWidth = $actionWorkspace.ClientSize.Width

    if ($workspaceWidth -lt 650) {
        $leftWidth = [Math]::Max(240, $workspaceWidth - 30)
        $column2 = 15
        $rightWidth = $leftWidth
    }
    else {
        $gap = 20
        $leftWidth = [int](($workspaceWidth - 45) / 2)
        $rightWidth = $leftWidth
        $column2 = 15 + $leftWidth + $gap
    }

    foreach ($button in @(
        $btnFull,$btnRestart,$btnHealth,$btnClientOnline,$btnNotepadVerify,$btnNotepadRemove,$btnDefenderNormal,$btnDefenderUpdate,
        $btnBaselines,$btnActions,$btnConfig,$btnStuck,
        $btnUserPolicy,$btnOpenConfigMgr,$btnOpenRegistry,$btnClear
    )) {
        $button.Width = $leftWidth
    }

    $btnFull.Left = 15
    $btnRestart.Left = $column2
    $btnHealth.Left = 15
    $btnClientOnline.Left = $column2
    # Security page: keep both Defender actions centered and stacked.
    if ($script:ActiveCategory -eq "Security") {
        $btnDefenderNormal.Left = [Math]::Max(15, [int](($workspaceWidth - $btnDefenderNormal.Width) / 2))
        $btnDefenderNormal.Top = 78
        $btnDefenderUpdate.Left = [Math]::Max(15, [int](($workspaceWidth - $btnDefenderUpdate.Width) / 2))
        $btnDefenderUpdate.Top = 126
    }
    else {
        $btnDefenderNormal.Left = 15
        $btnDefenderNormal.Top = 164
        $btnDefenderUpdate.Left = 15
        $btnDefenderUpdate.Top = 210
    }

    $btnBaselines.Left = 15
    $btnActions.Left = $column2
    $btnConfig.Left = 15
    $btnStuck.Left = $column2
    $btnUserPolicy.Left = 15
    $btnOpenConfigMgr.Left = 15
    $btnOpenConfigMgr.Top = 66
    $btnOpenRegistry.Left = $column2
    $btnOpenRegistry.Top = 66
    $btnNotepadVerify.Left = 15
    $btnNotepadVerify.Top = 115
    $btnNotepadRemove.Left = $column2
    $btnNotepadRemove.Top = 115
    $btnClear.Left = 15
    $btnClear.Top = 164
}

$actionWorkspace.Add_Resize({
    try { Update-ActionButtonLayout } catch {}
})

# ------------------------------------------------------------
# Stable Bottom Progress Footer
# ------------------------------------------------------------
# The footer is a real Dock=Bottom child of the right panel. It never depends
# on manual bottom calculations, so it stays visible in normal/maximized states.
$progressFooter = New-Object System.Windows.Forms.Panel
$progressFooter.Height = 48
$progressFooter.Dock = [System.Windows.Forms.DockStyle]::Bottom
$progressFooter.BackColor = [System.Drawing.Color]::FromArgb(25,32,42)
$rightPanel.Controls.Add($progressFooter)
$progressFooter.BringToFront()

$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Text = "Ready"
$progressLabel.Font = New-Object System.Drawing.Font("Segoe UI",9)
$progressLabel.ForeColor = [System.Drawing.Color]::LightGray
$progressLabel.AutoSize = $false
$progressLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$progressLabel.Dock = [System.Windows.Forms.DockStyle]::Top
$progressLabel.Height = 22
$progressFooter.Controls.Add($progressLabel)

$progressTrack = New-Object System.Windows.Forms.Panel
$progressTrack.BackColor = [System.Drawing.Color]::FromArgb(58,70,86)
$progressTrack.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$progressTrack.Dock = [System.Windows.Forms.DockStyle]::Fill
$progressTrack.Padding = New-Object System.Windows.Forms.Padding(0)
$progressFooter.Controls.Add($progressTrack)

$progressFill = New-Object System.Windows.Forms.Panel
$progressFill.BackColor = [System.Drawing.Color]::FromArgb(0,122,204)
$progressFill.Dock = [System.Windows.Forms.DockStyle]::Left
$progressFill.Width = 0
$progressTrack.Controls.Add($progressFill)

$script:ProgressValue = 0

function Set-ProgressValue {
    param([int]$Value)

    $Value = [Math]::Min(100, [Math]::Max(0, $Value))
    $script:ProgressValue = $Value

    $innerWidth = [Math]::Max(0, $progressTrack.ClientSize.Width)
    $progressFill.Width = [int][Math]::Round($innerWidth * ($Value / 100.0))
    $progressTrack.Visible = $true
}

Set-ProgressValue 0

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$statusLabel.ForeColor = [System.Drawing.Color]::White
$statusLabel.AutoSize = $true
$statusLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$rightPanel.Controls.Add($statusLabel)



# ------------------------------------------------------------
# Responsive Layout
# ------------------------------------------------------------
# Keep the UI clean when the window is resized or maximized.
function Update-ResponsiveLayout {

    $padding = 20
    $contentWidth = [Math]::Max(500, $rightPanel.ClientSize.Width - ($padding * 2))

    # Top-right status.
    $statusLabel.Left = [Math]::Max(300, $rightPanel.ClientSize.Width - $statusLabel.Width - $padding)
    $statusLabel.Top = 15

    # Main workspace.
    $actionWorkspace.Left = $padding
    $actionWorkspace.Width = $contentWidth

    # Activity heading and log.
    $logTitle.Left = $padding
    if ($script:ActiveCategory -eq "Dashboard") {
        $logTitle.Top = 190
        $logBox.Top = 220
    }
    else {
        $logTitle.Top = 430
        $logBox.Top = 457
    }

    $logBox.Left = $padding
    $logBox.Width = $contentWidth

    # Footer is docked inside a bounded rightPanel.
    $progressFooter.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $progressFooter.Height = 48

    # Compute the exact visible top of the footer after layout.
    $rightPanel.PerformLayout()
    $safeBottom = $rightPanel.ClientSize.Height - $progressFooter.Height - 8

    # Never allow the activity console to consume the footer area.
    $logBox.Height = [Math]::Max(140, $safeBottom - $logBox.Top)

    Set-ProgressValue $script:ProgressValue

    $progressFooter.BringToFront()
    $progressLabel.BringToFront()
    $progressTrack.BringToFront()
    $progressFill.BringToFront()

    $rightPanel.PerformLayout()
} 
$rightPanel.Add_Resize({
    try { Update-ResponsiveLayout } catch {}
})

$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.AutoPopDelay = 8000
$toolTip.InitialDelay = 400
$toolTip.ReshowDelay = 200
$toolTip.ShowAlways = $true
$toolTip.SetToolTip($btnFull, "Run the complete SCCM automation. The existing action script also performs baseline evaluation.")
$toolTip.SetToolTip($btnRestart, "Restart the SMS Agent Host (CcmExec) service and verify that it returns to Running.")
$toolTip.SetToolTip($btnHealth, "Check CcmExec, SCCM WMI, and the DCM baseline provider.")
$toolTip.SetToolTip($btnClientOnline, "Set ClientAlwaysOnInternet to 1 in HKLM\SOFTWARE\Microsoft\CCM\Security.")
$toolTip.SetToolTip($btnNotepadVerify, "Deep verification: checks the Microsoft.WindowsNotepad AppX package, provisioned package, and searches local fixed drives for notepad.exe.")
$toolTip.SetToolTip($btnNotepadRemove, "Remove Microsoft Notepad from Windows. Requires confirmation before running.")
$toolTip.SetToolTip($btnDefenderNormal, "Normal update: checks the current Defender Security Intelligence status and runs Update-MpSignature using the configured update source. This respects the endpoint's normal update path.")
$toolTip.SetToolTip($btnDefenderUpdate, "Manual fallback only: force a Defender Security Intelligence update through MMPC when the normal update does not bring the endpoint current.")
$toolTip.SetToolTip($btnBaselines, "Run the standalone Configuration Baseline evaluation script.")
$toolTip.SetToolTip($btnActions, "Run the existing SCCM automation script.")
$toolTip.SetToolTip($btnConfig, "Run the Configuration Manager configuration tab fix.")
$toolTip.SetToolTip($btnStuck, "Run the SCCM client stuck troubleshooting script.")
$toolTip.SetToolTip($btnUserPolicy, "Show information about the current user policy evaluation behavior.")
$toolTip.SetToolTip($btnOpenConfigMgr, "Open the local Configuration Manager control panel.")
$toolTip.SetToolTip($btnOpenRegistry, "Open HKLM\SOFTWARE\Microsoft\CCM\Security and show ClientAlwaysOnInternet.")
$toolTip.SetToolTip($btnClear, "Clear the activity log and reset the progress indicator.")

# ------------------------------------------------------------
# Dark Theme (Default and Only Theme)
# ------------------------------------------------------------
function Set-ControlTheme {
    param(
        [System.Windows.Forms.Control]$Control,
        [string]$Theme = "Dark"
    )

    $form.BackColor = [System.Drawing.Color]::FromArgb(15,20,27)
    $header.BackColor = [System.Drawing.Color]::FromArgb(9,13,18)
    $leftPanel.BackColor = [System.Drawing.Color]::FromArgb(25,32,42)
    $rightPanel.BackColor = [System.Drawing.Color]::FromArgb(25,32,42)
    $actionWorkspace.BackColor = [System.Drawing.Color]::FromArgb(30,40,52)
    $logBox.BackColor = [System.Drawing.Color]::FromArgb(8,12,17)
    $logBox.ForeColor = [System.Drawing.Color]::White
    $progressTrack.BackColor = [System.Drawing.Color]::FromArgb(58,70,86)
    $progressFill.BackColor = [System.Drawing.Color]::FromArgb(0,122,204)
    $progressLabel.ForeColor = [System.Drawing.Color]::LightGray

    foreach ($button in @(
        $btnFull,$btnRestart,$btnHealth,$btnClientOnline,$btnNotepadVerify,$btnNotepadRemove,$btnDefenderNormal,$btnDefenderUpdate,
        $btnBaselines,$btnActions,$btnConfig,$btnStuck,
        $btnUserPolicy,$btnOpenConfigMgr,$btnOpenRegistry,$btnClear
    )) {
        $button.BackColor = [System.Drawing.Color]::FromArgb(31,42,55)
        $button.ForeColor = [System.Drawing.Color]::White
    }

    foreach ($nav in @($navDashboard,$navCore,$navEvaluation,$navTroubleshooting,$navUtilities,$navSecurity)) {
        $nav.BackColor = [System.Drawing.Color]::FromArgb(31,42,55)
        $nav.ForeColor = [System.Drawing.Color]::White
    }

    foreach ($card in @($serviceCard.Panel,$wmiCard.Panel,$baselineCard.Panel)) {
        $card.BackColor = [System.Drawing.Color]::FromArgb(31,42,55)
    }

    $contentTitle.ForeColor = [System.Drawing.Color]::White
    $contentHint.ForeColor = [System.Drawing.Color]::LightGray
    $logTitle.ForeColor = [System.Drawing.Color]::White
    $workspaceTitle.ForeColor = [System.Drawing.Color]::White
    $workspaceHint.ForeColor = [System.Drawing.Color]::LightGray
    $section.ForeColor = [System.Drawing.Color]::White
    $sectionHint.ForeColor = [System.Drawing.Color]::LightGray
    $sidebarFooter.ForeColor = [System.Drawing.Color]::LightGray
    $sidebarVersion.ForeColor = [System.Drawing.Color]::FromArgb(150,160,175)
    $statusLabel.ForeColor = [System.Drawing.Color]::White
    $serviceStatusLabel.ForeColor = [System.Drawing.Color]::White
    $wmiStatusLabel.ForeColor = [System.Drawing.Color]::White
    $baselineStatusLabel.ForeColor = [System.Drawing.Color]::White
}

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

    Update-ResponsiveLayout
    [System.Windows.Forms.Application]::DoEvents()
}
function Set-Category {
    param([string]$Category)

    $script:ActiveCategory = $Category

    foreach ($button in @(
        $btnFull,$btnRestart,$btnHealth,$btnClientOnline,$btnNotepadVerify,$btnNotepadRemove,$btnDefenderNormal,$btnDefenderUpdate,
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
        "Security" {
            $actionWorkspace.Visible = $true
            Set-ActivityLogLayout $false

            $contentTitle.Text = "Security"
            $contentHint.Text = "Defender security intelligence maintenance and verification."
            $workspaceTitle.Text = "DEFENDER SECURITY"
            $workspaceHint.Text = "Run the normal Defender update first. Use Force-MMPC only when the normal update cannot bring the endpoint current."
            $btnDefenderNormal.Visible = $true
            $btnDefenderUpdate.Visible = $true
            Update-ActionButtonLayout
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
            $btnNotepadVerify.Visible = $true
            $btnNotepadRemove.Visible = $true
            $btnClear.Visible = $true
            Update-ActionButtonLayout
        }
    }

    foreach ($nav in @($navDashboard,$navCore,$navEvaluation,$navTroubleshooting,$navUtilities,$navSecurity)) {
        $nav.FlatAppearance.BorderSize = 1
    }

    foreach ($nav in @($navDashboard,$navCore,$navEvaluation,$navTroubleshooting,$navUtilities,$navSecurity)) {
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
$navSecurity.Add_Click({ Set-Category "Security" })

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

    $statusLabel.Text = "Opening ClientAlwaysOnInternet Registry"
    Set-ProgressValue 20

    Open-ClientAlwaysOnInternetRegistry

    Set-ProgressValue 100
    $progressLabel.Text = "Registry location opened"
    $statusLabel.Text = "Registry Opened"
})

# ------------------------------------------------------------
# Open Configuration Manager Button
# ------------------------------------------------------------

$btnOpenConfigMgr.Add_Click({

    $statusLabel.Text = "Opening Configuration Manager"

    Set-ProgressValue 0

    Open-ConfigurationManager

    Set-ProgressValue 100

    $statusLabel.Text = "Configuration Manager Opened"
})

# ------------------------------------------------------------
# Run All SCCM Actions
# ------------------------------------------------------------

$btnActions.Add_Click({

    $statusLabel.Text = "Running Actions"

    Set-ProgressValue 10

    Write-Log "=========================================="

    Write-Log "RUNNING ALL SCCM ACTIONS"

    Write-Log "=========================================="

    Run-BatchFile $ActionScript

    Set-ProgressValue 100

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

    $statusLabel.Text = "Actions Completed"
})

# ------------------------------------------------------------
# Verify Microsoft Notepad
# ------------------------------------------------------------
$btnNotepadVerify.Add_Click({

    $statusLabel.Text = "Verifying Microsoft Notepad"
    $progressLabel.Text = "Checking targeted Notepad locations..."
    Set-ProgressValue 10

    Write-Log "=========================================="
    Write-Log "VERIFY MICROSOFT NOTEPAD"
    Write-Log "=========================================="
    Write-Log "Mode: TARGETED CHECK"
    Write-Log "No full C:\ drive scan is performed."
    Write-Log "Checking AppX, provisioning, WindowsApps, Packages, TEMP, and PATH."
    Write-Log ""

    if (-not (Test-Path $NotepadVerifyScript)) {
        Write-Log "ERROR: Targeted Notepad verification helper was not found:"
        Write-Log $NotepadVerifyScript
        $statusLabel.Text = "Notepad Verify Helper Missing"
        $progressLabel.Text = "Verification helper script not found."
        Set-ProgressValue 0

        [System.Windows.Forms.MessageBox]::Show(
            "The Notepad verification helper was not found.`r`n`r`n$NotepadVerifyScript",
            "Notepad Verification Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return
    }

    Write-Log "Starting: $(Split-Path $NotepadVerifyScript -Leaf)"
    Write-Log ""

    # Run the targeted helper.
    Run-PowerShellScript $NotepadVerifyScript

    # Determine the user-facing result directly from the AppX state.
    $installedPackages = @(Get-AppxPackage -AllUsers -Name "Microsoft.WindowsNotepad" -ErrorAction SilentlyContinue)
    $provisionedPackages = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -eq "Microsoft.WindowsNotepad" })

    $windowsAppsPath = Join-Path $env:ProgramFiles "WindowsApps"
    $packageFolders = @()
    if (Test-Path -LiteralPath $windowsAppsPath -PathType Container) {
        $packageFolders = @(Get-ChildItem -LiteralPath $windowsAppsPath -Directory -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "Microsoft.WindowsNotepad_*" })
    }

    Set-ProgressValue 100

    if ($installedPackages.Count -gt 0 -or
        $provisionedPackages.Count -gt 0 -or
        $packageFolders.Count -gt 0) {

        $details = "Microsoft Notepad is FOUND on this computer.`r`n`r`n"
        $details += "Installed AppX package: " + ($(if ($installedPackages.Count -gt 0) { "FOUND" } else { "NOT FOUND" })) + "`r`n"
        $details += "Provisioned package: " + ($(if ($provisionedPackages.Count -gt 0) { "FOUND" } else { "NOT FOUND" })) + "`r`n"
        $details += "WindowsApps package folder: " + ($(if ($packageFolders.Count -gt 0) { "FOUND" } else { "NOT FOUND" })) + "`r`n`r`n"
        $details += "STATUS: NOT REMOVED / INSTALLED"

        $statusLabel.Text = "Notepad Found"
        $progressLabel.Text = "Microsoft Notepad is installed."
        Write-Log "FINAL GUI RESULT: MICROSOFT NOTEPAD FOUND / INSTALLED"

        [System.Windows.Forms.MessageBox]::Show(
            $details,
            "Microsoft Notepad Found",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    }
    else {
        $details = "Microsoft Notepad was not found in the targeted package locations.`r`n`r`n"
        $details += "Installed AppX package: NOT FOUND`r`n"
        $details += "Provisioned package: NOT FOUND`r`n"
        $details += "WindowsApps package folder: NOT FOUND`r`n`r`n"
        $details += "STATUS: REMOVED / NOT INSTALLED"

        $statusLabel.Text = "Notepad Not Installed"
        $progressLabel.Text = "Microsoft Notepad is not installed."
        Write-Log "FINAL GUI RESULT: MICROSOFT NOTEPAD NOT FOUND / NOT INSTALLED"

        [System.Windows.Forms.MessageBox]::Show(
            $details,
            "Microsoft Notepad Not Found",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }

    Write-Log "=========================================="
})

# ------------------------------------------------------------
# Remove Microsoft Notepad
# ------------------------------------------------------------
$btnNotepadRemove.Add_Click({

    $warningText = @"
WARNING - REMOVE MICROSOFT NOTEPAD

This action will attempt to remove the Microsoft.WindowsNotepad
AppX package for all users and remove its provisioned package.

Notepad will not be available until it is installed again.

You can reinstall Microsoft Notepad later from Microsoft Store.

This is a destructive Windows application-management action.

Do you want to continue?
"@

    $confirmation = [System.Windows.Forms.MessageBox]::Show(
        $warningText,
        "Remove Microsoft Notepad",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning,
        [System.Windows.Forms.MessageBoxDefaultButton]::Button2
    )

    if ($confirmation -ne [System.Windows.Forms.DialogResult]::Yes) {
        Write-Log "Microsoft Notepad removal cancelled by user."
        $statusLabel.Text = "Notepad Removal Cancelled"
        $progressLabel.Text = "Removal cancelled."
        Set-ProgressValue 0
        return
    }

    Write-Log "=========================================="
    Write-Log "REMOVE MICROSOFT NOTEPAD"
    Write-Log "=========================================="
    Write-Log "User confirmed Notepad removal."
    Write-Log ""

    if (-not (Test-Path $NotepadRemoveScript)) {
        Write-Log "ERROR: Notepad removal helper was not found:"
        Write-Log $NotepadRemoveScript
        $statusLabel.Text = "Notepad Remove Helper Missing"
        $progressLabel.Text = "Removal helper script not found."
        Set-ProgressValue 0
        return
    }

    $statusLabel.Text = "Removing Microsoft Notepad"
    $progressLabel.Text = "Removing installed and provisioned Notepad packages..."
    Set-ProgressValue 15

    Write-Log "Starting: $(Split-Path $NotepadRemoveScript -Leaf)"
    Write-Log ""

    Run-PowerShellScript $NotepadRemoveScript

    Set-ProgressValue 100
    $progressLabel.Text = "Microsoft Notepad removal completed"
    $statusLabel.Text = "Notepad Removal Completed"

    Write-Log ""
    Write-Log "Notepad removal process completed."
    Write-Log "Run Verify Microsoft Notepad to confirm the final state."
    Write-Log "=========================================="
})

# ------------------------------------------------------------
# Normal Defender Security Intelligence Check & Update
# ------------------------------------------------------------
$btnDefenderNormal.Add_Click({

    $statusLabel.Text = "Checking Defender Security Intelligence"
    $progressLabel.Text = "Checking current version and running the normal Defender update..."
    Set-ProgressValue 10

    Write-Log "=========================================="
    Write-Log "NORMAL DEFENDER SECURITY INTELLIGENCE UPDATE"
    Write-Log "=========================================="
    Write-Log "Mode: NORMAL / CONFIGURED UPDATE SOURCE"
    Write-Log "No MMPC force is requested by this action."
    Write-Log ""

    if (-not (Test-Path $DefenderSecurityIntelligenceNormalScript)) {
        Write-Log "ERROR: Normal Defender update helper was not found:"
        Write-Log $DefenderSecurityIntelligenceNormalScript
        $statusLabel.Text = "Normal Defender Helper Missing"
        $progressLabel.Text = "Normal update helper script not found."
        Set-ProgressValue 0
        return
    }

    Write-Log "Starting: $(Split-Path $DefenderSecurityIntelligenceNormalScript -Leaf)"
    Write-Log ""
    Run-PowerShellScript $DefenderSecurityIntelligenceNormalScript

    Set-ProgressValue 100
    $progressLabel.Text = "Normal Defender update check completed"
    $statusLabel.Text = "Normal Defender Update Completed"

    Write-Log ""
    Write-Log "Normal Defender Security Intelligence update check completed."
    Write-Log "If the version remains outdated, use Force-MMPC Fallback after reviewing the warning."
    Write-Log "=========================================="
})

# ------------------------------------------------------------
# Update Defender Security Intelligence - MMPC Fallback
# ------------------------------------------------------------
$btnDefenderUpdate.Add_Click({

    $warningText = @"
WARNING - MANUAL DEFENDER FALLBACK

This action is intended ONLY as a fallback when the normal Microsoft Defender Security Intelligence update does not make the endpoint current.

It uses the Microsoft Update (MMPC) source directly and may operate outside your normal SCCM/WSUS update path. Do not use this routinely on managed endpoints.

Before continuing, confirm that: 
• The normal Defender update was already attempted.
• You are authorized to perform an out-of-band update.
• You understand this does NOT change SCCM, WSUS, GPO, or Defender policy settings.

Do you want to continue?
"@

    $confirmation = [System.Windows.Forms.MessageBox]::Show(
        $warningText,
        "Defender Security Intelligence - Manual Fallback",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning,
        [System.Windows.Forms.MessageBoxDefaultButton]::Button2
    )

    if ($confirmation -ne [System.Windows.Forms.DialogResult]::Yes) {
        Write-Log "Defender manual fallback cancelled by user."
        $statusLabel.Text = "Defender Update Cancelled"
        $progressLabel.Text = "Manual Defender fallback was cancelled."
        Set-ProgressValue 0
        return
    }

    $statusLabel.Text = "Updating Defender Security Intelligence"
    $progressLabel.Text = "Manual fallback: requesting the latest Security Intelligence from MMPC..."
    Set-ProgressValue 10

    Write-Log "=========================================="
    Write-Log "DEFENDER SECURITY INTELLIGENCE UPDATE"
    Write-Log "=========================================="
    Write-Log "Mode: MANUAL FALLBACK"
    Write-Log "Normal Defender update should be tried first."
    Write-Log "This action runs the Force-MMPC helper only when required."
    Write-Log ""

    if (-not (Test-Path $DefenderSecurityIntelligenceScript)) {

        Write-Log "ERROR: Defender update helper was not found:"
        Write-Log $DefenderSecurityIntelligenceScript
        $statusLabel.Text = "Defender Update Helper Missing"
        $progressLabel.Text = "Helper script not found."
        Set-ProgressValue 0
        return
    }

    Write-Log "Starting: $(Split-Path $DefenderSecurityIntelligenceScript -Leaf)"
    Write-Log ""

    Run-PowerShellScript $DefenderSecurityIntelligenceScript

    Set-ProgressValue 100
    $progressLabel.Text = "Defender Security Intelligence update check completed"
    $statusLabel.Text = "Defender Update Completed"

    Write-Log ""
    Write-Log "Defender Security Intelligence update check completed."
    Write-Log "Verify the reported version before expecting Qualys status to change."
    Write-Log "=========================================="
})

# ------------------------------------------------------------
# Evaluate All Baselines
# ------------------------------------------------------------

$btnBaselines.Add_Click({

    $statusLabel.Text = "Evaluating Baselines"

    Set-ProgressValue 10

    Write-Log "=========================================="

    Write-Log "CONFIGURATION BASELINE EVALUATION"

    Write-Log "=========================================="

    Run-PowerShellScript $BaselineScript

    Set-ProgressValue 100

    Write-Log ""

    Write-Log "Baseline evaluation process completed."

    $statusLabel.Text = "Baseline Evaluation Completed"
})

# ------------------------------------------------------------
# Full SCCM Evaluation
# ------------------------------------------------------------

$btnFull.Add_Click({

    $statusLabel.Text = "Full Evaluation Running"
    $progressLabel.Text = "Running complete SCCM automation..."
    Set-ProgressValue 10

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

    Set-ProgressValue 25
    Run-BatchFile $ActionScript

    Set-ProgressValue 90
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

    Set-ProgressValue 100
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
    Set-ProgressValue 15

    Write-Log "=========================================="
    Write-Log "ENABLE CLIENT ALWAYS ON INTERNET"
    Write-Log "=========================================="
    Write-Log "Registry: HKLM\SOFTWARE\Microsoft\CCM\Security"
    Write-Log "Value: ClientAlwaysOnInternet"
    Write-Log "Target: 1"
    Write-Log ""

    Run-PowerShellScript $ClientAlwaysOnInternetScript

    Set-ProgressValue 100
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
    Set-ProgressValue 15

    Write-Log "=========================================="
    Write-Log "RESTART SCCM SERVICES"
    Write-Log "=========================================="
    Write-Log "Starting: Restart-SCCM-Services.ps1"
    Write-Log ""

    Run-PowerShellScript $RestartServicesScript

    Set-ProgressValue 100
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

    $statusLabel.Text = " Running Configuration Fix"

    Set-ProgressValue 20

    Write-Log "=========================================="

    Write-Log "CONFIGURATION TAB FIX"

    Write-Log "=========================================="

    Run-PowerShellScript $ConfigFixScript

    Set-ProgressValue 100

    Write-Log ""

    Write-Log "Configuration Tab fix completed."

    $statusLabel.Text = " Configuration Fix Completed"
})

# ------------------------------------------------------------
# SCCM Client Stuck Fix
# ------------------------------------------------------------

$btnStuck.Add_Click({

    $statusLabel.Text = " Running SCCM Fix"

    Set-ProgressValue 20

    Write-Log "=========================================="

    Write-Log "SCCM CLIENT STUCK FIX"

    Write-Log "=========================================="

    Run-BatchFile $SccmFixScript

    Set-ProgressValue 100

    Write-Log ""

    Write-Log "SCCM Client Stuck Fix completed."

    $statusLabel.Text = " SCCM Fix Completed"
})

# ------------------------------------------------------------
# User Policy Information
# ------------------------------------------------------------

$btnUserPolicy.Add_Click({

    $statusLabel.Text = " User Policy Information"

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

    $statusLabel.Text = " User Policy: Skipped"
})

# ------------------------------------------------------------
# SCCM Client Health Check
# ------------------------------------------------------------

$btnHealth.Add_Click({

    $statusLabel.Text = " Checking Client"

    Set-ProgressValue 10

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

    Set-ProgressValue 35

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

    Set-ProgressValue 60

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

    Set-ProgressValue 100

    Write-Log ""

    Write-Log "=========================================="

    Write-Log "CLIENT HEALTH CHECK COMPLETED"

    Write-Log "=========================================="

    $statusLabel.Text = " Health Check Completed"
})

# ------------------------------------------------------------
# Clear Activity Log
# ------------------------------------------------------------

$btnClear.Add_Click({

    $logBox.Clear()

    Set-ProgressValue 0

    $statusLabel.Text = " Ready"

    Write-Log "Activity log cleared."
})

# ------------------------------------------------------------
# Initial Log
# ------------------------------------------------------------

Write-Log "=========================================="

Write-Log "SCCM AUTO EVALUATION"

Write-Log "=========================================="

Write-Log "Author  : Jagadish V"

Write-Log "Version : 1.3.0"

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
# Stable Window Bounds / Resize
# ------------------------------------------------------------
# The right panel previously had a fixed 660px height. On a normal-sized
# window that placed its bottom below the actual client area, hiding the
# progress footer. Keep the content panel inside the current window bounds.
function Update-WindowBounds {

    $clientWidth  = $form.ClientSize.Width
    $clientHeight = $form.ClientSize.Height

    # Keep the existing top header and left navigation positions.
    $contentTop = 142
    $rightLeft  = 280

    $rightWidth = [Math]::Max(500, $clientWidth - $rightLeft - 8)
    $rightHeight = [Math]::Max(400, $clientHeight - $contentTop - 8)
    $leftHeight = [Math]::Max(400, $clientHeight - $contentTop - 8)

    $rightPanel.Left = $rightLeft
    $rightPanel.Top = $contentTop
    $rightPanel.Width = $rightWidth
    $rightPanel.Height = $rightHeight

    $leftPanel.Left = 15
    $leftPanel.Top = $contentTop
    $leftPanel.Height = $leftHeight

    Update-ResponsiveLayout
    Update-ContentLayout
    Update-ActionButtonLayout
}

$form.Add_Resize({
    try { Update-WindowBounds } catch {}
})

$form.Add_Shown({
    try {
        Update-WindowBounds
        $form.Refresh()
        [System.Windows.Forms.Application]::DoEvents()
    } catch {}
})

# ------------------------------------------------------------
# Start GUI
# ------------------------------------------------------------

Set-Category "Dashboard"
Update-ResponsiveLayout
Update-ContentLayout
Update-ActionButtonLayout
Update-WindowBounds

[void]$form.ShowDialog()