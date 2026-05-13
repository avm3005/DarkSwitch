# ◑ detaroxzAutoDM

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
    Download the latest release .zip from this repository.
    Extract the folder, right-click setup.cmd, and select Run as Administrator.

---


## ⚙️ Usage
Once installed, AutoDM runs entirely automaticly with the help of task scheduler. You can manage your settings using either the Command Line Interface or the standard Start Menu shortcuts.
### 🖥️ Command Line Interface (CLI)
AutoDM automatically registers a global system command. Open any Command Prompt or Windows Terminal window and type:
    autodm -qt : Instantly toggles the current theme (Light/Dark).
    autodm -settings : Opens the AutoDM Settings Dashboard directly in your terminal.
    autodm -reset : Deletes and re-creates the Task Scheduler tasks back to default (07:00 / 19:00). Useful for troubleshooting.
    autodm -uninstall : Instantly uninstalls AutoDM from your system.
    autodm -help : Displays the CLI help menu.
    
### 🖱️ Start Menu Shortcuts
    Search for AutoDM Settings to open the interactive dashboard.
    Search for Quick Toggle to instantly flip your current theme without opening a menu.
    
### The Dashboard Features:
    Change Times: Update your scheduled Light or Dark mode triggers.
    Toggle Log-on Trigger: Ensure your PC wakes up in the correct theme if you log in after a scheduled switch.
    Toggle Start Menu Items: Hide or show the AutoDM shortcuts in your Start Menu.
    Developer Links: Quick access to support and updates.
---


## 🗑️ Uninstallation
AutoDM cleans up after itself perfectly. This operation will automatically unregister all scheduled tasks, delete the registry keys, remove the Start Menu shortcuts, and wipe the directory from Program Files.
### Method 1: Command Line (Fastest)
    Open any terminal window and type autodm -uninstall.

### Method 2: Windows settings    
    Open Windows Settings.
    Go to Apps > Installed apps.
    Search for AutoDM.
    Click the three dots ... and select Uninstall.
---


## 📱Issues and suggestion
If you want to raise a concern or suggest a feature, you know where to find me:)
    Insta: its_avm
    Reddit: its_avm_05
