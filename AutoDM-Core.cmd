# 2>NUL & @echo off
# 2>NUL & set "SELF_PATH=%~f0"
# 2>NUL & set "LAUNCH_MODE=%~1"
# 2>NUL & net session >nul 2>&1 || (powershell -NoProfile -WindowStyle Hidden -Command "Start-Process cmd -ArgumentList '/c \"\"%SELF_PATH%\"\" %LAUNCH_MODE%' -Verb RunAs" & exit /b)
# 2>NUL & if /I "%LAUNCH_MODE%"=="UI" if not defined WT_SESSION (wt powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF_PATH)))" & exit /b)
# 2>NUL & powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF_PATH)))"
# 2>NUL & exit /b

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$e = [char]27
$smPath = [Environment]::GetFolderPath("CommonApplicationData") + "\Microsoft\Windows\Start Menu\Programs\AutoDM"
$wpDir = "C:\Program Files\Detaroxz\AutoDM\Wallpapers"
$engineDir = "C:\Program Files\Detaroxz\AutoDM\Engine"
$vbs = "$engineDir\RunSilent.vbs"
$p = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
$tPath = "\Detaroxz\AutoDM\"
$appVersion = "1.4.1"

$is24Hour = (Get-Culture).DateTimeFormat.ShortTimePattern -cmatch 'H'
$timeFormat = if ($is24Hour) { "HH:mm" } else { "h:mm tt" }
$timeHint = if ($is24Hour) { "HH:MM (e.g., 07:00, 19:30)" } else { "HH:MM AM/PM" }
$isCLI = ($env:LAUNCH_MODE -eq "CLI")

$WshShell = New-Object -ComObject WScript.Shell
$scTogglePath = "$smPath\Quick Toggle.lnk"

# Color Palette Setup
$cMain = "$e[38;5;51m"; $cAccent = "$e[38;5;213m"; $cText = "$e[97m"; $cDim = "$e[90m"; $cGreen = "$e[38;5;46m"; $cRed = "$e[38;5;196m"; $cYellow = "$e[38;5;226m"; $cReset = "$e[0m"

$dashCode = @'
using System; using System.Runtime.InteropServices; using Microsoft.Win32;
public class DashTheme {
    [ComImport, Guid("C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD")] public class DesktopWallpaper { }
    [ComImport, Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] public interface IDesktopWallpaper { void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] string wallpaper); }
    [DllImport("uxtheme.dll", EntryPoint = "#104")] public static extern void RefreshImmersiveColorPolicyState();
    [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
    
    public static void SetWP(string path) { 
        try { ((IDesktopWallpaper)new DesktopWallpaper()).SetWallpaper(null, path); } 
        catch { SystemParametersInfo(20, 0, path, 3); }
    }
    public static void SetAccent(string acc) {
        if (acc.ToLower() == "auto") {
            using (RegistryKey desk = Registry.CurrentUser.CreateSubKey(@"Control Panel\Desktop")) { desk.SetValue("AutoColorization", 1, RegistryValueKind.DWord); }
        } else {
            using (RegistryKey desk = Registry.CurrentUser.CreateSubKey(@"Control Panel\Desktop")) { desk.SetValue("AutoColorization", 0, RegistryValueKind.DWord); }
            try {
                int color = 0; if(acc.StartsWith("#")) acc = acc.Substring(1);
                if(acc.Length == 6) {
                    int r = Convert.ToInt32(acc.Substring(0,2), 16); int g = Convert.ToInt32(acc.Substring(2,2), 16); int b = Convert.ToInt32(acc.Substring(4,2), 16);
                    color = (b << 16) | (g << 8) | r;
                }
                using (RegistryKey dwm = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\DWM")) { dwm.SetValue("AccentColor", color, RegistryValueKind.DWord); dwm.SetValue("ColorizationColor", color | unchecked((int)0xFF000000), RegistryValueKind.DWord); }
            } catch {}
        }
        try { RefreshImmersiveColorPolicyState(); } catch {}
        IntPtr res; SendMessageTimeout((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "ImmersiveColorSet", 2, 100, out res);
    }
    public static void RestoreAccent(int autoCol, int accCol) {
        using (RegistryKey desk = Registry.CurrentUser.CreateSubKey(@"Control Panel\Desktop")) { desk.SetValue("AutoColorization", autoCol, RegistryValueKind.DWord); }
        using (RegistryKey dwm = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\DWM")) { dwm.SetValue("AccentColor", accCol, RegistryValueKind.DWord); dwm.SetValue("ColorizationColor", accCol | unchecked((int)0xFF000000), RegistryValueKind.DWord); }
        try { RefreshImmersiveColorPolicyState(); } catch {}
        IntPtr res; SendMessageTimeout((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "ImmersiveColorSet", 2, 100, out res);
    }
}
'@
if (-not ("DashTheme" -as [type])) { Add-Type -TypeDefinition $dashCode -ErrorAction SilentlyContinue }

# Universal Sync Engines
function Set-ConfigValue {
    param($key, $value, $regType = "String")
    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\AutoDM" -Name $key -Value $value -Type $regType -Force -ErrorAction Stop
        
        $cfgPath = "C:\Program Files\Detaroxz\AutoDM\config.ini"
        $cfg = @{}
        if (Test-Path $cfgPath) {
            Get-Content $cfgPath -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_ -match "^(.*?)=(.*)$") { $cfg[$matches[1].Trim()] = $matches[2].Trim() }
            }
        }
        $cfg[$key] = $value
        $out = @()
        foreach ($k in $cfg.Keys) { $out += "$k=" + $cfg[$k] }
        $out | Set-Content $cfgPath -Force -ErrorAction Stop
    } catch {
        Write-Host "
 [!] Config update failed: $($_.Exception.Message)" -ForegroundColor Red
        Start-Sleep 2
    }
}

function Remove-ConfigValue {
    param($key)
    try {
        Remove-ItemProperty -Path "HKCU:\SOFTWARE\AutoDM" -Name $key -ErrorAction SilentlyContinue
        $cfgPath = "C:\Program Files\Detaroxz\AutoDM\config.ini"
        if (Test-Path $cfgPath) {
            $cfg = @{}
            Get-Content $cfgPath -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_ -match "^(.*?)=(.*)$") { $cfg[$matches[1].Trim()] = $matches[2].Trim() }
            }
            $cfg.Remove($key)
            $out = @()
            foreach ($k in $cfg.Keys) { $out += "$k=" + $cfg[$k] }
            $out | Set-Content $cfgPath -Force -ErrorAction Stop
        }
    } catch {}
}

function Update-TaskActions {
    try {
        $engDir = "C:\Program Files\Detaroxz\AutoDM\Engine"
        $runner = "$engDir\RunSilent.vbs"
        $p = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

        $regPath = "HKCU:\SOFTWARE\AutoDM"
        $regData = Get-ItemProperty $regPath -ErrorAction SilentlyContinue
        $wEn = if ($regData.WallpaperEnabled) { $regData.WallpaperEnabled } else { 0 }
        $aEn = if ($regData.AccentEnabled) { $regData.AccentEnabled } else { 0 }

        $tasks = @("AutoDM - Light Mode", "AutoDM - Dark Mode", "AutoDM - Boot Sync", "AutoDM - Quick Toggle")
        foreach ($t in $tasks) {
            if (Get-ScheduledTask -TaskName $t -TaskPath "\Detaroxz\AutoDM\" -ErrorAction SilentlyContinue) {
                $actList = New-Object System.Collections.Generic.List[Microsoft.Management.Infrastructure.CimInstance]
                if ($t -eq "AutoDM - Quick Toggle") {
                    $actList.Add((New-ScheduledTaskAction -Execute "wscript.exe" -Argument ('"{0}" "{1}\ToggleMode.cmd"' -f $runner, $engDir)))
                } else {
                    $actList.Add((New-ScheduledTaskAction -Execute "wscript.exe" -Argument ('"{0}" "{1}\SyncMode.cmd"' -f $runner, $engDir)))
                }
                if ($wEn -eq 1) { $actList.Add((New-ScheduledTaskAction -Execute "wscript.exe" -Argument ('"{0}" "{1}\ApplyWP.cmd"' -f $runner, $engDir))) }
                if ($aEn -eq 1) { $actList.Add((New-ScheduledTaskAction -Execute "wscript.exe" -Argument ('"{0}" "{1}\ApplyAcc.cmd"' -f $runner, $engDir))) }
                
                Set-ScheduledTask -TaskName $t -TaskPath "\Detaroxz\AutoDM\" -Action $actList.ToArray() -Principal $p -ErrorAction Stop | Out-Null
            }
        }
    } catch {}
}

if (-not ("Shell.WinAPI" -as [type])) {
    $sig = '[DllImport("shell32.dll", CharSet=CharSet.Auto)] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);'
    Add-Type -MemberDefinition $sig -Name WinAPI -Namespace Shell -PassThru | Out-Null
}

function Get-ValidTime ($Prompt) {
    while ($true) {
        Write-Host "
 $cDim> $Prompt ($timeHint):$cReset " -NoNewline
        $timeStr = Read-Host
        try { return [datetime]::Parse($timeStr).ToString($timeFormat) } 
        catch { Write-Host "  -> Invalid format.
" -ForegroundColor Red }
    }
}

$sessionLog = @()
$runLoop = $true
$menuState = "Main"
$selIndex = 0
$lastMsg = ""
$needsRefresh = $true
$renderNeeded = $true

try {
    [console]::CursorVisible = $false
    while ($runLoop) {
        if ($needsRefresh) {
            $tasks = Get-ScheduledTask -TaskPath $tPath -ErrorAction SilentlyContinue
            $tLight = $tasks | Where-Object TaskName -eq "AutoDM - Light Mode"
            $tDark = $tasks | Where-Object TaskName -eq "AutoDM - Dark Mode"
            $tBoot = $tasks | Where-Object TaskName -eq "AutoDM - Boot Sync"

            $lTime = if ($tLight) { [datetime]::Parse($tLight.Triggers[0].StartBoundary).ToString($timeFormat) } else { "N/A" }
            $dTime = if ($tDark) { [datetime]::Parse($tDark.Triggers[0].StartBoundary).ToString($timeFormat) } else { "N/A" }
            $tLightState = if ($tLight) { $tLight.State } else { 'Disabled' }
            $tBootState = if ($tBoot) { $tBoot.State } else { 'Disabled' }
            
            $xmlLight = (Export-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath -ErrorAction SilentlyContinue)
            $schPrio = if ($xmlLight -match '<Priority>(\d+)</Priority>') { $matches[1] } else { "4" }
            $xmlBoot = (Export-ScheduledTask -TaskName "AutoDM - Boot Sync" -TaskPath $tPath -ErrorAction SilentlyContinue)
            $bootPrio = if ($xmlBoot -match '<Priority>(\d+)</Priority>') { $matches[1] } else { "4" }
            
            $isSmHidden = $false
            if (Test-Path $smPath) { $isSmHidden = ((Get-Item $smPath -Force).Attributes -band [System.IO.FileAttributes]::Hidden) -eq [System.IO.FileAttributes]::Hidden }
            $scToggle = $WshShell.CreateShortcut($scTogglePath)
            $hotkey = $scToggle.Hotkey
            $hkEnabled = [bool]$hotkey

            $autoStatus = if ($tLightState -ne 'Disabled') { "$cGreen[ ACTIVE ]$cReset" } else { "$cRed[ PAUSED ]$cReset" }
            $bootStatus = if ($tBootState -ne 'Disabled') { "$cGreen[ ENABLED ]$cReset" } else { "$cRed[ DISABLED ]$cReset" }
            $smStatus = if ($isSmHidden) { "$cRed[ HIDDEN ]$cReset" } else { "$cGreen[ VISIBLE ]$cReset" }
            $hkStatus = if ($hkEnabled) { "$cGreen[ ENABLED ]$cReset" } else { "$cRed[ DISABLED ]$cReset" }

            $regPath = "HKCU:\SOFTWARE\AutoDM"
            $regData = Get-ItemProperty $regPath -ErrorAction SilentlyContinue
            
            $savedKey = if ($regData.ShortcutKey) { $regData.ShortcutKey } else { "T" }
            $wpEn = if ($regData.WallpaperEnabled) { $regData.WallpaperEnabled } else { 0 }
            $accEn = if ($regData.AccentEnabled) { $regData.AccentEnabled } else { 0 }

            $lWall = $regData.LightWallpaper
            $dWall = $regData.DarkWallpaper
            $lWallName = if ($regData.LightWallpaperName) { $regData.LightWallpaperName } elseif ($lWall) { [System.IO.Path]::GetFileName($lWall) } else { "none" }
            $dWallName = if ($regData.DarkWallpaperName) { $regData.DarkWallpaperName } elseif ($dWall) { [System.IO.Path]::GetFileName($dWall) } else { "none" }
            if ($lWallName.Length -gt 15) { $lWallName = $lWallName.Substring(0,12) + "..." }
            if ($dWallName.Length -gt 15) { $dWallName = $dWallName.Substring(0,12) + "..." }
            $lWpStatus = if ($lWall -and (Test-Path $lWall)) { "$cGreen$lWallName$cReset" } else { "$cDim[ NONE ]$cReset" }
            $dWpStatus = if ($dWall -and (Test-Path $dWall)) { "$cGreen$dWallName$cReset" } else { "$cDim[ NONE ]$cReset" }

            $lAcc = $regData.LightAccent
            $dAcc = $regData.DarkAccent
            $lAccStatus = if (-not $lAcc) { "$cDim[ NONE ]$cReset" } elseif ($lAcc.ToLower() -eq 'auto') { "$cYellow[ AUTO ]$cReset" } else { "$cGreen$lAcc$cReset" }
            $dAccStatus = if (-not $dAcc) { "$cDim[ NONE ]$cReset" } elseif ($dAcc.ToLower() -eq 'auto') { "$cYellow[ AUTO ]$cReset" } else { "$cGreen$dAcc$cReset" }

            $wpStatusStr = if ($wpEn -eq 1) { "$cGreen[ ON ]$cReset" } else { "$cRed[ OFF ]$cReset" }
            $accStatusStr = if ($accEn -eq 1) { "$cGreen[ ON ]$cReset" } else { "$cRed[ OFF ]$cReset" }
            
            $needsRefresh = $false
            $renderNeeded = $true
        }

        if ($renderNeeded) {
            $currentOptions = @()
            if ($menuState -eq "Main") {
                $currentOptions += @{ Label="Schedule Triggers"; Value=$null; Desc="Manage Light/Dark times and auto-switching"; Action="Menu_Schedule" }
                $currentOptions += @{ Label="Personalization"; Value=$null; Desc="Configure Wallpapers and Accent colors"; Action="Menu_Personalization" }
                $currentOptions += @{ Label="System Integration"; Value=$null; Desc="Boot sync and Start Menu shortcuts"; Action="Menu_System" }
                $currentOptions += @{ Label="Advanced Controls"; Value=$null; Desc="Task priorities and keyboard shortcuts"; Action="Menu_Advanced" }
                $currentOptions += @{ Label="About"; Value=$null; Desc="Updates, Dev links, and info"; Action="Menu_About" }
                $currentOptions += @{ Label="Exit"; Value=$null; Desc="Close the core"; Action="Quit" }
            } elseif ($menuState -eq "Menu_Schedule") {
                $currentOptions += @{ Label="Light Mode Time"; Value="$cYellow$lTime$cReset"; Desc="Set the time Light Mode activates"; Action="Set_Light" }
                $currentOptions += @{ Label="Dark Mode Time"; Value="$cYellow$dTime$cReset"; Desc="Set the time Dark Mode activates"; Action="Set_Dark" }
                $currentOptions += @{ Label="Auto Switching"; Value=$autoStatus; Desc="Toggle the automatic scheduled switching"; Action="Toggle_Auto" }
                $currentOptions += @{ Label="< Back"; Value=$null; Desc="Return to main menu"; Action="Menu_Main" }
            } elseif ($menuState -eq "Menu_Personalization") {
                $currentOptions += @{ Label="Toggle Wallpaper Switch"; Value=$wpStatusStr; Desc="Enable automatic wallpaper changes"; Action="Toggle_WP" }
                if ($wpEn -eq 1) {
                    $currentOptions += @{ Label="Light Wallpaper"; Value=$lWpStatus; Desc="Set wallpaper for light mode"; Action="Set_WP_L" }
                    $currentOptions += @{ Label="Dark Wallpaper"; Value=$dWpStatus; Desc="Set wallpaper for dark mode"; Action="Set_WP_D" }
                }
                $currentOptions += @{ Label="Toggle Accent Color"; Value=$accStatusStr; Desc="Enable automatic accent changes"; Action="Toggle_Acc" }
                if ($accEn -eq 1) {
                    $currentOptions += @{ Label="Light Accent"; Value=$lAccStatus; Desc="Set accent color for light mode"; Action="Set_Acc_L" }
                    $currentOptions += @{ Label="Dark Accent"; Value=$dAccStatus; Desc="Set accent color for dark mode"; Action="Set_Acc_D" }
                }
                $currentOptions += @{ Label="< Back"; Value=$null; Desc="Return to main menu"; Action="Menu_Main" }
            } elseif ($menuState -eq "Menu_System") {
                $currentOptions += @{ Label="Boot Sync State"; Value=$bootStatus; Desc="Enable/Disable theming sync upon logon"; Action="Toggle_Boot" }
                $currentOptions += @{ Label="Start Menu Icons"; Value=$smStatus; Desc="Hide or Show app shortcuts in start menu"; Action="Toggle_Sm" }
                $currentOptions += @{ Label="< Back"; Value=$null; Desc="Return to main menu"; Action="Menu_Main" }
            } elseif ($menuState -eq "Menu_Advanced") {
                $currentOptions += @{ Label="Schedule Priority"; Value="$cYellow$schPrio$cReset"; Desc="Change the process priority of schedule trigger"; Action="Set_Sch_Prio" }
                $currentOptions += @{ Label="Boot Sync Priority"; Value="$cYellow$bootPrio$cReset"; Desc="Change the process priority of logon trigger"; Action="Set_Boot_Prio" }
                $currentOptions += @{ Label="Quick Toggle Key"; Value=$hkStatus; Desc="Enable keyboard shortcut (CTRL+ALT+$savedKey)"; Action="Toggle_Hk" }
                if ($hkEnabled) { $currentOptions += @{ Label="Change Shortcut Key"; Value=$null; Desc="Bind a new key letter to CTRL+ALT+?"; Action="Change_Hk" } }
                $currentOptions += @{ Label="< Back"; Value=$null; Desc="Return to main menu"; Action="Menu_Main" }
            } elseif ($menuState -eq "Menu_About") {
                $currentOptions += @{ Label="Check for Updates"; Value=$null; Desc="Fetch the latest features from GitHub"; Action="Update_Check" }
                $currentOptions += @{ Label="Developer GitHub"; Value=$null; Desc="Open Developer profile in browser"; Action="Open_Dev" }
                $currentOptions += @{ Label="Project Repository"; Value=$null; Desc="Open Project Repo in browser"; Action="Open_Proj" }
                $currentOptions += @{ Label="< Back"; Value=$null; Desc="Return to main menu"; Action="Menu_Main" }
            }

            if ($selIndex -ge $currentOptions.Count) { $selIndex = $currentOptions.Count - 1 }
            if ($selIndex -lt 0) { $selIndex = 0 }

            Clear-Host
            Write-Host "
 $cAccent:: AUTODM CORE ::$cReset $cDim(v1.4.1)$cReset"
            if ($lastMsg) { Write-Host "
 $cGreen>> $lastMsg$cReset"; $lastMsg = "" }

            for ($i=0; $i -lt $currentOptions.Count; $i++) {
                $opt = $currentOptions[$i]
                $valStr = if ($opt.Value) { " : " + $opt.Value } else { "" }
                
                if ($i -eq $selIndex) {
                    Write-Host ("
 $cMain> " + $opt.Label + $cReset + $valStr)
                    Write-Host ("   $cDim" + $opt.Desc + $cReset)
                } else {
                    Write-Host ("
   " + $opt.Label + $valStr)
                    Write-Host ("   $cDim" + $opt.Desc + $cReset)
                }
            }
            Write-Host "
 $cDim UP/DOWN navigate | ENTER/RIGHT select | ESC/LEFT back/quit$cReset
"
            $renderNeeded = $false
        }

        while (-not [System.Console]::KeyAvailable) { Start-Sleep -Milliseconds 50 }
        $key = [System.Console]::ReadKey($true)

        if ($key.KeyChar -eq 'q' -or $key.KeyChar -eq 'Q') { $runLoop = $false; continue }

        $k = $key.Key.ToString()

        if ($k -eq 'UpArrow') { 
            $selIndex--
            if ($selIndex -lt 0) { $selIndex = $currentOptions.Count - 1 }
            $renderNeeded = $true 
        }
        elseif ($k -eq 'DownArrow') { 
            $selIndex++
            if ($selIndex -ge $currentOptions.Count) { $selIndex = 0 }
            $renderNeeded = $true 
        }
        elseif ($k -eq 'LeftArrow' -or $k -eq 'Backspace') { 
            if ($menuState -ne "Main") { $menuState = "Main"; $selIndex=0; $renderNeeded = $true } 
        }
        elseif ($k -eq 'Escape') {
            if ($menuState -eq "Main") { $runLoop = $false } else { $menuState = "Main"; $selIndex=0; $renderNeeded = $true }
        }
        elseif ($k -eq 'Enter' -or $k -eq 'RightArrow') {
            $action = $currentOptions[$selIndex].Action
            if ($action -like "Menu_*") {
                $menuState = $action
                $selIndex = 0
                $renderNeeded = $true
            } elseif ($action -eq "Quit") {
                $runLoop = $false
            } else {
                [console]::CursorVisible = $true
                Write-Host "
 $cYellow[!] Loading... Please wait...$cReset"
                switch ($action) {
                    "Set_Light" {
                        $newLight = Get-ValidTime "Enter NEW LIGHT mode time"
                        $trigger = New-ScheduledTaskTrigger -Daily -At $newLight
                        Set-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath -Trigger $trigger -Principal $p | Out-Null
                        $xmlL = (Export-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath) -replace '<Priority>\d+</Priority>', "<Priority>$schPrio</Priority>"
                        Register-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath -Xml $xmlL -Force | Out-Null
                        Set-ConfigValue "LightTime" $newLight
                        $lastMsg = "Light mode time updated to $newLight"
                        $needsRefresh = $true
                    }
                    "Set_Dark" {
                        $newDark = Get-ValidTime "Enter NEW DARK mode time"
                        $trigger = New-ScheduledTaskTrigger -Daily -At $newDark
                        Set-ScheduledTask -TaskName "AutoDM - Dark Mode" -TaskPath $tPath -Trigger $trigger -Principal $p | Out-Null
                        $xmlD = (Export-ScheduledTask -TaskName "AutoDM - Dark Mode" -TaskPath $tPath) -replace '<Priority>\d+</Priority>', "<Priority>$schPrio</Priority>"
                        Register-ScheduledTask -TaskName "AutoDM - Dark Mode" -TaskPath $tPath -Xml $xmlD -Force | Out-Null
                        Set-ConfigValue "DarkTime" $newDark
                        $lastMsg = "Dark mode time updated to $newDark"
                        $needsRefresh = $true
                    }
                    "Toggle_Auto" {
                        if ($tLightState -ne 'Disabled') {
                            Disable-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath | Out-Null
                            Disable-ScheduledTask -TaskName "AutoDM - Dark Mode" -TaskPath $tPath | Out-Null
                            $lastMsg = "Auto switching disabled"
                        } else {
                            Enable-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath | Out-Null
                            Enable-ScheduledTask -TaskName "AutoDM - Dark Mode" -TaskPath $tPath | Out-Null
                            $lastMsg = "Auto switching enabled"
                        }
                        $needsRefresh = $true
                    }
                    "Toggle_WP" {
                        $newEn = if ($wpEn -eq 1) { 0 } else { 1 }
                        if ($newEn -eq 1) {
                            $curWp = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallPaper -ErrorAction SilentlyContinue).WallPaper
                            if ($curWp -and (Test-Path $curWp)) {
                                $ext = [System.IO.Path]::GetExtension($curWp)
                                if (-not (Test-Path $wpDir)) { New-Item -ItemType Directory -Path $wpDir -Force | Out-Null }
                                $backupWp = "$wpDir\Default_WP$ext"
                                if ($curWp -ne $backupWp) { Copy-Item $curWp $backupWp -Force }
                                Set-ConfigValue "LightWallpaper" $backupWp
                                Set-ConfigValue "DarkWallpaper" $backupWp
                                Set-ConfigValue "LightWallpaperName" "Default"
                                Set-ConfigValue "DarkWallpaperName" "Default"
                                $lastMsg = "WP Switch ON: Backed up current WP as Default."
                            } else { $lastMsg = "WP Switch ON" }
                        } else {
                            $bWp = (Get-ChildItem "$wpDir\Default_WP.*" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
                            if ($bWp -and (Test-Path $bWp)) { [DashTheme]::SetWP($bWp) }
                            $lastMsg = "WP Switch OFF: Restored Default Wallpaper."
                        }
                        Set-ConfigValue "WallpaperEnabled" $newEn "DWord"
                        Update-TaskActions
                        $needsRefresh = $true
                    }
                    "Set_WP_L" {
                        Write-Host "
 $cDim> Enter path to Light Wallpaper (or type 'none' to clear):$cReset " -NoNewline
                        $wpInput = Read-Host
                        if ($wpInput -eq 'none') {
                            Remove-ConfigValue "LightWallpaper"
                            Remove-ConfigValue "LightWallpaperName"
                            Remove-Item "$wpDir\Light_*" -Force -ErrorAction SilentlyContinue
                            $lastMsg = "Light wallpaper removed"
                        } elseif (Test-Path $wpInput) {
                            if (-not (Test-Path $wpDir)) { New-Item -ItemType Directory -Path $wpDir -Force | Out-Null }
                            $ext = [System.IO.Path]::GetExtension($wpInput)
                            $dest = Join-Path $wpDir "Light_WP$ext"
                            $wpFileName = [System.IO.Path]::GetFileName($wpInput)
                            Remove-Item "$wpDir\Light_*" -Force -ErrorAction SilentlyContinue
                            Copy-Item $wpInput $dest -Force
                            Set-ConfigValue "LightWallpaper" $dest
                            Set-ConfigValue "LightWallpaperName" $wpFileName
                            $isLight = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                            if ($isLight -eq 1) { [DashTheme]::SetWP($dest) }
                            $lastMsg = "Light wallpaper successfully set to $wpFileName"
                        } else { $lastMsg = "Invalid path." }
                        $needsRefresh = $true
                    }
                    "Set_WP_D" {
                        Write-Host "
 $cDim> Enter path to Dark Wallpaper (or type 'none' to clear):$cReset " -NoNewline
                        $wpInput = Read-Host
                        if ($wpInput -eq 'none') {
                            Remove-ConfigValue "DarkWallpaper"
                            Remove-ConfigValue "DarkWallpaperName"
                            Remove-Item "$wpDir\Dark_*" -Force -ErrorAction SilentlyContinue
                            $lastMsg = "Dark wallpaper removed"
                        } elseif (Test-Path $wpInput) {
                            if (-not (Test-Path $wpDir)) { New-Item -ItemType Directory -Path $wpDir -Force | Out-Null }
                            $ext = [System.IO.Path]::GetExtension($wpInput)
                            $dest = Join-Path $wpDir "Dark_WP$ext"
                            $wpFileName = [System.IO.Path]::GetFileName($wpInput)
                            Remove-Item "$wpDir\Dark_*" -Force -ErrorAction SilentlyContinue
                            Copy-Item $wpInput $dest -Force
                            Set-ConfigValue "DarkWallpaper" $dest
                            Set-ConfigValue "DarkWallpaperName" $wpFileName
                            $isLight = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                            if ($isLight -eq 0) { [DashTheme]::SetWP($dest) }
                            $lastMsg = "Dark wallpaper successfully set to $wpFileName"
                        } else { $lastMsg = "Invalid path." }
                        $needsRefresh = $true
                    }
                    "Toggle_Acc" {
                        $newAccEn = if ($accEn -eq 1) { 0 } else { 1 }
                        if ($newAccEn -eq 1) {
                            $curAuto = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name AutoColorization -ErrorAction SilentlyContinue).AutoColorization
                            $curAcc = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\DWM' -Name AccentColor -ErrorAction SilentlyContinue).AccentColor
                            if ($null -ne $curAuto -and $null -ne $curAcc) {
                                Set-ConfigValue "BackupAutoCol" $curAuto "DWord"
                                Set-ConfigValue "BackupAccCol" $curAcc "DWord"
                                if ($curAuto -ne 1 -and $curAcc -ne $null) {
                                    $r = ($curAcc -band 0xFF).ToString("X2"); $g = (($curAcc -shr 8) -band 0xFF).ToString("X2"); $b = (($curAcc -shr 16) -band 0xFF).ToString("X2")
                                    $accStr = "#$r$g$b"
                                } else { $accStr = "auto" }
                                Set-ConfigValue "LightAccent" $accStr
                                Set-ConfigValue "DarkAccent" $accStr
                                $lastMsg = "Accent Switch ON: Backed up current Accent to be used as default."
                            } else { $lastMsg = "Accent Switch ON" }
                        } else {
                            $bAuto = (Get-ItemProperty $regPath -Name "BackupAutoCol" -ErrorAction SilentlyContinue).BackupAutoCol
                            $bAcc = (Get-ItemProperty $regPath -Name "BackupAccCol" -ErrorAction SilentlyContinue).BackupAccCol
                            if ($null -ne $bAuto -and $null -ne $bAcc) { [DashTheme]::RestoreAccent($bAuto, $bAcc) }
                            $lastMsg = "Accent Switch OFF: Restored backed-up Accent."
                        }
                        Set-ConfigValue "AccentEnabled" $newAccEn "DWord"
                        Update-TaskActions
                        $needsRefresh = $true
                    }
                    "Set_Acc_L" {
                        Write-Host "
 $cDim> Enter HEX Color (e.g., #FF5500), 'auto' to extract from wallpaper, or 'none' to clear:$cReset " -NoNewline
                        $accInput = Read-Host
                        if ($accInput -eq 'none') {
                            Remove-ConfigValue "LightAccent"
                            $lastMsg = "Light Accent color cleared"
                        } elseif ($accInput -match '^#?([a-fA-F0-9]{6})$|^auto$') {
                            Set-ConfigValue "LightAccent" $accInput.ToUpper()
                            $isLight = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                            if ($isLight -eq 1) { [DashTheme]::SetAccent($accInput) }
                            $lastMsg = "Light Accent color updated"
                        } else { $lastMsg = "Invalid input. Must be HEX or 'auto'." }
                        $needsRefresh = $true
                    }
                    "Set_Acc_D" {
                        Write-Host "
 $cDim> Enter HEX Color (e.g., #0055FF), 'auto' to extract from wallpaper, or 'none' to clear:$cReset " -NoNewline
                        $accInput = Read-Host
                        if ($accInput -eq 'none') {
                            Remove-ConfigValue "DarkAccent"
                            $lastMsg = "Dark Accent color cleared"
                        } elseif ($accInput -match '^#?([a-fA-F0-9]{6})$|^auto$') {
                            Set-ConfigValue "DarkAccent" $accInput.ToUpper()
                            $isLight = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                            if ($isLight -eq 0) { [DashTheme]::SetAccent($accInput) }
                            $lastMsg = "Dark Accent color updated"
                        } else { $lastMsg = "Invalid input. Must be HEX or 'auto'." }
                        $needsRefresh = $true
                    }
                    "Toggle_Boot" {
                        if ($tBootState -ne 'Disabled') { 
                            Disable-ScheduledTask -TaskName "AutoDM - Boot Sync" -TaskPath $tPath | Out-Null
                            $lastMsg = "Boot trigger disabled"
                            Set-ConfigValue "BootSync" "N"
                        } else { 
                            Enable-ScheduledTask -TaskName "AutoDM - Boot Sync" -TaskPath $tPath | Out-Null
                            $lastMsg = "Boot trigger enabled"
                            Set-ConfigValue "BootSync" "Y"
                        }
                        $needsRefresh = $true
                    }
                    "Toggle_Sm" {
                        if (Test-Path $smPath) {
                            $item = Get-Item $smPath -Force
                            if ($isSmHidden) { 
                                $item.Attributes = $item.Attributes -band (-bnot [System.IO.FileAttributes]::Hidden)
                                $lastMsg = "Start menu items set to Visible"
                            } else { 
                                $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
                                $lastMsg = "Start menu items set to Hidden"
                            }
                            Start-Sleep -Seconds 2
                            [Shell.WinAPI]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
                            Stop-Process -Name "SearchHost" -Force -ErrorAction SilentlyContinue
                            Stop-Process -Name "StartMenuExperienceHost" -Force -ErrorAction SilentlyContinue
                        }
                        $needsRefresh = $true
                    }
                    "Set_Sch_Prio" {
                        Write-Host "
Task Priority Levels (0 to 10):" -ForegroundColor Cyan
                        Write-Host "  0-3 : Real-time / High (Not recommended)"
                        Write-Host "  4   : Normal (Standard app priority - Fast execution)"
                        Write-Host "  5-6 : Below Normal"
                        Write-Host "  7   : Below Normal (Task Scheduler Default - Slower)"
                        Write-Host "  8-10: Low / Idle"
                        Write-Host "
 $cDim> Enter priority number (0-10) [Default: 4]:$cReset " -NoNewline
                        $newPrio = Read-Host
                        if ([string]::IsNullOrWhiteSpace($newPrio)) { $newPrio = "4" }
                        if ($newPrio -match '^(10|[0-9])$') {
                            foreach ($t in @("AutoDM - Light Mode", "AutoDM - Dark Mode")) {
                                if (Get-ScheduledTask -TaskName $t -TaskPath $tPath -ErrorAction SilentlyContinue) {
                                    $xml = (Export-ScheduledTask -TaskName $t -TaskPath $tPath) -replace '<Priority>\d+</Priority>', "<Priority>$newPrio</Priority>"
                                    Register-ScheduledTask -TaskName $t -TaskPath $tPath -Xml $xml -Force | Out-Null
                                }
                            }
                            $lastMsg = "Scheduled Sync priority updated to $newPrio"
                        } else { $lastMsg = "Invalid input." }
                        $needsRefresh = $true
                    }
                    "Set_Boot_Prio" {
                        Write-Host "
Task Priority Levels (0 to 10):" -ForegroundColor Cyan
                        Write-Host "  0-3 : Real-time / High (Not recommended)"
                        Write-Host "  4   : Normal (Standard app priority - Fast execution)"
                        Write-Host "  5-6 : Below Normal"
                        Write-Host "  7   : Below Normal (Task Scheduler Default - Slower)"
                        Write-Host "  8-10: Low / Idle"
                        Write-Host "
 $cDim> Enter priority number (0-10) [Default: 4]:$cReset " -NoNewline
                        $newPrio = Read-Host
                        if ([string]::IsNullOrWhiteSpace($newPrio)) { $newPrio = "4" }
                        if ($newPrio -match '^(10|[0-9])$') {
                            if (Get-ScheduledTask -TaskName "AutoDM - Boot Sync" -TaskPath $tPath -ErrorAction SilentlyContinue) {
                                $xml = (Export-ScheduledTask -TaskName "AutoDM - Boot Sync" -TaskPath $tPath) -replace '<Priority>\d+</Priority>', "<Priority>$newPrio</Priority>"
                                Register-ScheduledTask -TaskName "AutoDM - Boot Sync" -TaskPath $tPath -Xml $xml -Force | Out-Null
                            }
                            $lastMsg = "Boot Sync priority updated to $newPrio"
                        } else { $lastMsg = "Invalid input." }
                        $needsRefresh = $true
                    }
                    "Toggle_Hk" {
                        if ($hkEnabled) { 
                            $scToggle.Hotkey = ""; $scToggle.Save() 
                            $lastMsg = "Keyboard shortcut disabled"
                            Set-ConfigValue "Shortcut" "N"
                        } else { 
                            $scToggle.Hotkey = ""; $scToggle.Save()
                            Start-Sleep -Milliseconds 200
                            $scToggle.Hotkey = "CTRL+ALT+" + $savedKey; $scToggle.Save() 
                            $lastMsg = "Keyboard shortcut enabled (CTRL+ALT+$savedKey)"
                            Set-ConfigValue "Shortcut" "Y"
                        }
                        $needsRefresh = $true
                    }
                    "Change_Hk" {
                        while ($true) {
                            Write-Host "
 $cDim> Enter new key to use with CTRL+ALT (A-Z, 0-9):$cReset " -NoNewline
                            $newK = Read-Host
                            if ($newK -match '^[a-zA-Z0-9]$') { 
                                $nk = $newK.ToUpper()
                                $hotkey = "CTRL+ALT+" + $nk
                                $scToggle.Hotkey = ""; $scToggle.Save()
                                Start-Sleep -Milliseconds 200
                                $scToggle.Hotkey = $hotkey; $scToggle.Save()
                                Set-ConfigValue "ShortcutKey" $nk
                                $lastMsg = "Shortcut key updated to $hotkey"
                                break 
                            }
                            Write-Host "  -> Invalid key. Use a single letter or number.
" -ForegroundColor Red
                        }
                        $needsRefresh = $true
                    }
                    "Update_Check" {
                        Write-Host "
 $cDim> Checking GitHub for updates...$cReset"
                        try {
                            $remoteVer = (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/avm3005/detaroxzAutoDM/main/UpdSystem/version.txt" -UseBasicParsing).Trim() -replace '^v', ''
                            if ([version]$remoteVer -gt [version]"$appVersion") {
                                Write-Host "
 $cGreen[!] A new update is available: v$remoteVer (Current: v$appVersion)$cReset"
                                Write-Host "
 $cMain> Do you want to download and apply this update now? (Y/N):$cReset " -NoNewline
                                $ans = Read-Host
                                if ($ans -match '^[Yy]') {
                                    Write-Host "
 $cAccent Confirming download... Launching Update Engine.$cReset"
                                    $updateCmd = "irm https://raw.githubusercontent.com/avm3005/detaroxzAutoDM/main/UpdSystem/setup.ps1 | iex"
                                    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$updateCmd""
                                    exit
                                } else {
                                    $lastMsg = "Update cancelled."
                                }
                            } else {
                                $lastMsg = "You are on the latest version (v$appVersion)."
                            }
                        } catch {
                            $lastMsg = "Failed to check for updates. Check your internet connection."
                        }
                        $needsRefresh = $true
                    }
                    "Open_Dev" { Start-Process "https://github.com/avm3005/"; $lastMsg = "Opened Developer GitHub Profile" }
                    "Open_Proj" { Start-Process "https://github.com/avm3005/detaroxzAutoDM"; $lastMsg = "Opened Project GitHub Repository" }
                }
                [console]::CursorVisible = $false
            }
        }
    }
} finally {
    [console]::CursorVisible = $true
    Clear-Host
}
