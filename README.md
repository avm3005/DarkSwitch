# DarkSwitch
<img width="1920" height="1080" alt="Screenshot (69)" src="https://github.com/user-attachments/assets/9d886585-d65b-4835-b159-d1bcc4756e61" />

**DarkSwitch** (also known as AutoDM) is a lightweight, zero-bloat, fully automated Light/Dark mode switcher for Windows 11. Built entirely using native Windows tools, it seamlessly transitions your system and app themes based on your preferred schedule without leaving a footprint.

## Created by **[detaroxz](https://github.com/avm3005/)** • [Visit website](https://avm3005.github.io/portfolio/)

## ✨ Features

* **Light weight UI:** DarkSwitch has a very light user interface (`Dashboard`) and switching mechanism (`Quick Toggle`) 
* **Global Keyboard Shortcut:** DarkSwitch also has a hotkey (default: `CTRL+ALT+T`) to instantly and silently toggle your theme from any app or screen.
* **Mode switch:** DarkSwitch has a very sharp theme toggling that cycles between light mode and dark mode, it has two triggers - on your scheduled time and when windows logs on to ensure that you are on the correct theme no matter what.
* **Quick toggle:** It is a function designed to switch your theme when you want, also it disables the log on trigger till the next scheduled trigger so that your theme stays the way you like it.
* **Wallpaper switch:** DarkSwitch intigrates a wallpaper switching mechanism with the toggles so that you can enjoy different wallpaper with different modes just like _MAC OS_.
* **Accent color switch:** DarkSwitch also intigrates an accent color switching mechanism with the quick toggle so that you can enjoy different accent colors during different times of day
* **No Background resource consuming Engine:** Relies on native Windows Scheduled Tasks. It takes uses 0% CPU/RAM when idle so that your apps and games can work at maximum speed.
* **Lightning-Fast Interactive Dashboard:** A modern, memory-cached dashboard allows you to change times, force-toggle themes, or manage startup triggers on the fly, complete with a dynamic session log.
* **Setting importing engine:** Automatically detects older installations and seamlessly imports your previous schedules, triggers, and custom hotkeys without overwriting them.
* **Check for updates:** We add things which provide great value during each update, but comming to website every time just to check if a new version is released is not good, so therefore we have a `Check for updates` section in dashboard, which will only check the updates when you want it to. 
* **Native Integration:** DarkSwitch has a cli interface that let's you use DarkSwitch without start menu shortcuts. Usefull for NERDS I guess!

---

## 🚀 Installation
### Method 1: Command Line (Fastest)
Open powershell as admin and paste the following command:
```
irm https://raw.githubusercontent.com/avm3005/DarkSwitch/main/Setup/main.ps1 | iex
```

### Method 2: Manual installation
Download the latest release [DarkSwitch.Setup.v1.4.2.zip](https://github.com/avm3005/DarkSwitch/releases/tag/v1.5.1) from this repository.

Extract the folder, right-click `setup.vbs`, and select **Run as Administrator**.

> Because DarkSwitch is a powerful system script, downloading it via a web browser may trigger a "Windows Smart App Control" warning due to the *Mark of the Web*.

---

## ⚙️ Usage

Once installed, DarkSwitch runs entirely automatically with the help of the Task Scheduler. You can manage your settings using either the Command Line Interface or the standard Start Menu shortcuts.

### 🖱️ Start Menu & Keyboard Shortcuts

* **Dashboard:** Search for this in the Start Menu to open the interactive settings menu.
* **Quick Toggle:** Search for this to instantly flip your current theme without opening a menu.
* **Keyboard Shortcut:** Press `CTRL+ALT+T` (or your custom key) to toggle the theme silently.

### The Dashboard Features:

* **Change Times:** Update your scheduled Light or Dark mode triggers.
* **Toggle Boot Trigger:** Ensures your PC instantly applies the correct theme upon Log-on or Workstation Unlock.
* **Toggle Auto Switching:** Temporarily pause the daily automatic schedule.
* **Toggle Wallpaper switch:** Turn on changing of wallpaper with this switch.
* **Toggle Accent color switch:** Turn on changing of accent color with this switch.
* **Toggle Start Menu Items:** Hide or show the DarkSwitch shortcuts in your Windows Start Menu.
* **Toggle / Change Keyboard Shortcut:** Enable, disable, or assign a new letter/number to the `CTRL+ALT` toggle hotkey.
* **Check for updates:** Download the newest version if you want


---

## 🗑️ Uninstallation

DarkSwitch cleans up after itself perfectly. This operation will automatically unregister all scheduled tasks, delete the registry footprints, remove the Start Menu shortcuts, and wipe the directory from Program Files.
1. Open Windows Settings.
2. Go to **Apps > Installed apps**.
3. Search for **DarkSwitch**.
4. Click the three dots `...` and select **Uninstall**.

---

## 📱 Issues and Suggestions
If you want to raise a concern or suggest a feature, you know where to find me:)

* **Insta:** `its_avm`
* **Reddit:** `its_avm_05`

## 💵 Credits
* **Main icon**:      Sites google window website Icon by Chameleon Design on <a href="https://icon-icons.com/authors/231-chameleon-design">Icon-Icons.com</a>
* **Quick toggle icon**:  Energy power thunderbolt weather Icon by Yaicon on <a href="https://icon-icons.com/authors/1220-yaicon">Icon-Icons.com</a>
