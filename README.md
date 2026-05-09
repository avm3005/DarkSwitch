# detaroxzAutoDM

**detaroxzAutoDM** (also known as AutoDM) is a lightweight, zero-bloat, fully automated Light/Dark mode switcher for Windows 11. Built entirely using native Windows tools, it seamlessly transitions your system and app themes based on your preferred schedule without leaving a footprint.

Created by **[detaroxz](https://github.com/avm3005/)** • [knowaboutarchit.xo.je](https://knowaboutarchit.xo.je/)
---

## ✨ Features

* **Flawless UI Sync:** Utilizes undocumented native Win32 APIs (`uxtheme.dll`) to instantly refresh File Explorer, Task Manager, and the Desktop Window Manager. No more "half-painted" windows or desynced title bars.
* **100% CMD Polyglot Engine:** Written using an advanced hybrid Polyglot architecture. It looks and runs like a standard `.cmd` batch file but secretly executes high-powered PowerShell logic in memory—leaving zero `.ps1` files on your disk.
* **Invisible Background Engine:** Relies on native Windows Scheduled Tasks and silent VBScript wrappers. It takes virtually 0% CPU/RAM and stays completely hidden from your Task Manager Startup tab.
* **Native Integration:** Installs to `C:\Program Files\Detaroxz\AutoDM` and registers perfectly in your Windows **Settings > Apps > Installed apps** list with a clean uninstaller.
* **Interactive CLI Dashboard:** A modern, ANSI-colored command-line dashboard allows you to change times, force-toggle themes, or manage startup triggers on the fly.
* **Smart Time Detection:** Automatically adapts to your system's clock settings (12-hour AM/PM vs. 24-hour time).
---

## 🚀 Installation

Because AutoDM is a powerful system script, downloading it via a web browser may trigger a "Windows Smart App Control" warning due to the *Mark of the Web*. 

Choose one of the methods below to install safely:
### Method 1: Manual Download (Recommended)
If you prefer to download the .zip file manually:

    Download the latest release .zip from this repository.
    Extract the folder, right-click Setup.cmd, and select Run as Administrator.


### Method 2: The Terminal Fast-Track 
This method installs the tool directly via your terminal, bypassing the browser block completely.
1. Open your Windows Start menu, type **`cmd`**, and select **Run as Administrator**.
2. Paste the following command and press Enter:
   ```cmd
   git clone [https://github.com/avm3005/detaroxzAutoDM.git](https://github.com/avm3005/detaroxzAutoDM.git) && cd detaroxzAutoDM && Setup.cmd
---

## ⚙️ Usage

Once installed, AutoDM runs entirely in the background. If you need to change your settings or force a theme toggle:

    Open your Windows Start Menu.
    Search for AutoDM Settings to open the interactive dashboard.
    Search for Quick Mode Toggle to instantly flip your current theme without opening a menu.

The Dashboard Features:

    Change Times: Update your scheduled Light or Dark mode triggers.
    Toggle Log-on Trigger: Ensure your PC wakes up in the correct theme if you log in after a scheduled switch.
    Toggle Start Menu Visibility: Hide or show the AutoDM shortcuts in your Start Menu.
    Developer Links: Quick access to support and updates.
---

## 🗑️ Uninstallation

AutoDM cleans up after itself perfectly.

    Open Windows Settings.
    Go to Apps > Installed apps.
    Search for AutoDM.
    Click the three dots ... and select Uninstall.

This will automatically unregister all scheduled tasks, delete the registry keys, remove the Start Menu shortcuts, and wipe the directory from Program Files.
