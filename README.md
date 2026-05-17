# detaroxzAutoDM

**detaroxzAutoDM** (also known as AutoDM) is a lightweight, zero-bloat, fully automated Light/Dark mode switcher for Windows 11. Built entirely using native Windows tools, it seamlessly transitions your system and app themes based on your preferred schedule without leaving a footprint.

## Created by **[detaroxz](https://github.com/avm3005/)** • [knowaboutarchit.xo.je](https://knowaboutarchit.xo.je/)

## ✨ Features

* **Flawless UI Sync:** Utilizes undocumented native Win32 APIs (`uxtheme.dll`) and aggressive indexer cache clearing to instantly refresh File Explorer, Task Manager, and the Start Menu. No more "half-painted" windows or desynced title bars.
* **Global Keyboard Shortcut:** Bind a custom hotkey (default: `CTRL+ALT+T`) to instantly and silently toggle your theme from any app or screen.
* **100% CMD Polyglot Engine:** Written using an advanced hybrid Polyglot architecture. It looks and runs like a standard `.cmd` batch file but secretly executes high-powered PowerShell logic in memory—leaving zero `.ps1` files on your disk.
* **Invisible Background Engine:** Relies on native Windows Scheduled Tasks and silent VBScript wrappers. It takes virtually 0% CPU/RAM and stays completely hidden from your Task Manager Startup tab.
* **Lightning-Fast Interactive Dashboard:** A modern, memory-cached CLI dashboard allows you to change times, force-toggle themes, or manage startup triggers on the fly, complete with a dynamic session log.
* **Smart Update Engine:** Automatically detects older installations and seamlessly imports your previous schedules, triggers, and custom hotkeys without overwriting them.
* **Native Integration:** Installs to machine-wide `ProgramData` and `Program Files` directories and registers perfectly in your Windows **Settings > Apps > Installed apps** list with a clean uninstaller.

---

## 🚀 Installation

Download the latest release [AutoDM.Setup.v1.3.1.zip](https://www.google.com/search?q=https://github.com/avm3005/detaroxzAutoDM/releases/tag/v1.3.1/) from this repository.

Extract the folder, right-click `setup.cmd`, and select **Run as Administrator**.

> Because AutoDM is a powerful system script, downloading it via a web browser may trigger a "Windows Smart App Control" warning due to the *Mark of the Web*.

---

## ⚙️ Usage

Once installed, AutoDM runs entirely automatically with the help of the Task Scheduler. You can manage your settings using either the Command Line Interface or the standard Start Menu shortcuts.

### 🖥️ Command Line Interface (CLI)

AutoDM automatically registers a global system command. Open any Command Prompt or Windows Terminal window and type:

* `autodm -qt` : Instantly toggles the current theme (Light/Dark).
* `autodm -dashboard` : Opens the AutoDM Settings Dashboard directly in your terminal.
* `autodm -reset` : Deletes and re-creates the Task Scheduler tasks back to default (07:00 / 19:00). Useful for troubleshooting.
* `autodm -uninstall` : Instantly uninstalls AutoDM from your system.
* `autodm -ver` : Displays the current AutoDM version.
* `autodm -help` : Displays the CLI help menu.

### 🖱️ Start Menu & Keyboard Shortcuts

* **AutoDM Dashboard:** Search for this in the Start Menu to open the interactive settings menu.
* **Quick Toggle:** Search for this to instantly flip your current theme without opening a menu.
* **Keyboard Shortcut:** Press `CTRL+ALT+T` (or your custom key) to toggle the theme silently.

### The Dashboard Features:

* **Change Times:** Update your scheduled Light or Dark mode triggers.
* **Toggle Boot Trigger:** Ensures your PC instantly applies the correct theme upon Log-on or Workstation Unlock.
* **Toggle Auto Switching:** Temporarily pause the daily automatic schedule.
* **Toggle Start Menu Items:** Hide or show the AutoDM shortcuts in your Windows Start Menu.
* **Toggle / Change Keyboard Shortcut:** Enable, disable, or assign a new letter/number to the `CTRL+ALT` toggle hotkey.

---

## 🗑️ Uninstallation

AutoDM cleans up after itself perfectly. This operation will automatically unregister all scheduled tasks, delete the registry footprints, remove the Start Menu shortcuts, and wipe the directory from Program Files.

### Method 1: Command Line (Fastest)

Open any terminal window and type `autodm -uninstall`.

### Method 2: Windows Settings

1. Open Windows Settings.
2. Go to **Apps > Installed apps**.
3. Search for **AutoDM**.
4. Click the three dots `...` and select **Uninstall**.

---

## 📱 Issues and Suggestions
If you want to raise a concern or suggest a feature, you know where to find me:)

* **Insta:** `its_avm`
* **Reddit:** `its_avm_05`

## 💵 Credits
* **Main icon**:      Pie chart in a Icon by OCHA on <a href="https://icon-icons.com/authors/354-ocha">Icon-Icons.com</a>
* **Settings icon**:  Cog gear machine office Icon by Settings cog options config Icon by Squarecup LTD on <a href="https://icon-icons.com/authors/817-squarecup-ltd">Icon-Icons.com</a>
