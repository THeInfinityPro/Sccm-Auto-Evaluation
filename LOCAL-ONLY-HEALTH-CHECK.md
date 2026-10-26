# Local-Only SCCM Health Check GUI

## Launch
Run the existing SCCM Auto-Evaluation GUI and select **Full SCCM Health Check**, or launch `backend\SCCM-Local-Health-Check-GUI.ps1` directly in Windows PowerShell 5.1.

## Scope
- Local service status/startup configuration (`CcmExec`, `Winmgmt`)
- Local `root\ccm:SMS_Client` class availability
- Local client version registry values and binary presence
- Local system-drive free space
- Local log review with line-number references
- Optional local-only log bundle to `C:\Temp\SCCM Health Check`

## Intentionally not executed
- Machine Policy Retrieval & Evaluation
- Software Updates Scan Cycle or Deployment Evaluation
- Management Point discovery/connectivity tests
- Remote WMI/CIM queries
- SCCM site database or any remote database connections
- Client repair, service restart, registry changes, WMI repository repair, or client reinstall

These are displayed as **NOT EXECUTED** in the GUI and are excluded from the score. The score is a custom diagnostic indicator, not a Microsoft-defined health score.

## Safety notes
The GUI performs local reads and writes report/ZIP files only. It does not intentionally initiate network connections. Other Windows/SCCM services can independently communicate in the background. Diagnostic ZIPs can contain sensitive computer and user details; review the archive and follow organizational policy before sharing it.
