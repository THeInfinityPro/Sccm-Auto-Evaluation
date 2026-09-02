# 🚀 SCCM Auto Evaluation

PowerShell and batch automation for triggering Microsoft Configuration Manager client actions, evaluating configuration baselines, performing client health checks, and troubleshooting common SCCM/MECM issues.

## 🔎 Keywords

`sccm` `mecm` `configuration-manager` `powershell` `powershell-script` `windows` `endpoint-management` `system-administration` `it-automation` `sccm-automation`

## 📌 Version

**v1.2.0 — Latest Release**

**Author:** Jagadish V

---

## 🆕 What's New in v1.2.0

### 🖥️ Modern Dashboard GUI

The SCCM Auto Evaluation GUI has been redesigned with a modern dashboard layout.

- 📊 Dashboard status cards
- 🧭 Category-based navigation
- ⚙️ Core Actions
- 📋 Evaluation
- 🔧 Troubleshooting
- 🛠️ Utilities
- 📜 Improved activity log
- 📈 Progress and current-status information

### 🔄 Restart SCCM Services

A dedicated **Restart SCCM Services** option has been added.

The tool checks the SCCM client service and restarts/starts it when required.

### 🌐 Enable Client Always On Internet

Administrators can now enable the SCCM:

`ClientAlwaysOnInternet`

registry configuration directly from the GUI.

The tool:

- Checks the registry path
- Reads the existing value
- Changes `0` → `1`
- Verifies the updated value
- Reports the result in the activity log

### 📝 ClientAlwaysOnInternet Registry Shortcut

A utility has been added to open the relevant registry location directly for administrators.

### 🩺 SCCM Client Health

The dashboard provides SCCM client health verification, including service and WMI status checks.

### 🎨 GUI Themes

The GUI supports three themes:

- ☀️ **Light Mode**
- 🌙 **Dark Mode**
- 🪟 **Transparent Mode**

### 🧭 Category Navigation

The GUI now organizes functionality into:

- **Dashboard**
- **Core Actions**
- **Evaluation**
- **Troubleshooting**
- **Utilities**

This makes the tool easier to use and maintain.

---

## 📖 Overview

SCCM Auto Evaluation is a Windows automation tool designed to simplify common Microsoft Configuration Manager (SCCM/MECM) client troubleshooting and evaluation tasks.

The tool provides a graphical user interface (GUI) that allows administrators to run SCCM client actions, evaluate configuration baselines, perform client health checks, troubleshoot common Configuration Manager issues, restart SCCM services, and manage ClientAlwaysOnInternet configuration.

The tool is designed so administrators do not need to manually open PowerShell, navigate to the project directory, or configure the PowerShell execution policy.

---

## ✨ Features

- 🖥️ Modern Graphical User Interface
- 🚀 One-click SCCM automation launcher
- 🔐 Automatic Administrator elevation
- ⚙️ Run SCCM client actions
- 📋 Evaluate Configuration Manager baselines
- 🔧 Fix Configuration Manager Configuration Tab issues
- 🛠️ SCCM client stuck troubleshooting
- ❤️ SCCM client health verification
- 🔄 Restart SCCM Client Services
- 🌐 Enable Client Always On Internet
- 📝 Open ClientAlwaysOnInternet Registry
- 👤 User Policy Retrieval & Evaluation status information
- 📊 Activity log
- 📈 Evaluation progress indicator
- 🖥️ Automatically open Configuration Manager after full evaluation
- ⚙️ Open Configuration Manager directly from the GUI
- 🧭 Category-based navigation
- ☀️ Light Mode
- 🌙 Dark Mode
- 🪟 Transparent Mode
- 📁 Organized backend scripts
- 👻 Hidden internal GUI implementation

---

## 🚀 Quick Start

### 1. Download or Clone

Download or clone this repository to the Windows system where Configuration Manager client troubleshooting is required.

### 2. Launch the Tool

Double-click:

```text
SCCM-Auto-Evaluation.bat