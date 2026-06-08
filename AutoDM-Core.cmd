# 2>NUL & @echo off
# 2>NUL & set "SELF_PATH=%~f0"
# 2>NUL & set "C=iex (Get-Content -LiteralPath '%SELF_PATH%' -Raw)"
# 2>NUL & net session >nul 2>&1 || (powershell -NoProfile -WindowStyle Hidden -Command "Start-Process cmd -ArgumentList '/c \"\"%SELF_PATH%\"\"' -Verb RunAs" & exit /b)
# 2>NUL & if not defined WT_SESSION (where wt >nul 2>&1 && (wt powershell -NoProfile -ExecutionPolicy Bypass -Command "%C%" 2>nul & exit /b))
# 2>NUL & powershell -NoProfile -ExecutionPolicy Bypass -Command "%C%"
# 2>NUL & exit /b

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$e = [char]27
$smPath = [Environment]::GetFolderPath("CommonApplicationData") + "\Microsoft\Windows\Start Menu\Programs\AutoDM"
$wpDir = "C:\Program Files\Detaroxz\AutoDM\Wallpapers"
$engineDir = "C:\Program Files\Detaroxz\AutoDM\Engine"
$vbs = "$engineDir\RunSilent.vbs"
$p = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 1) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$tPath = "\Detaroxz\AutoDM\"
$appVersion = "1.4.2"

$is24Hour = (Get-Culture).DateTimeFormat.ShortTimePattern -cmatch 'H'
$timeFormat = if ($is24Hour) { "HH:mm" } else { "h:mm tt" }
$timeHint = if ($is24Hour) { "HH:MM (e.g., 07:00, 19:30)" } else { "HH:MM AM/PM" }
$defLight = if ($is24Hour) { "07:00" } else { "7:00 AM" }
$defDark = if ($is24Hour) { "19:00" } else { "7:00 PM" }
$defSun1 = if ($is24Hour) { "00:00" } else { "12:00 AM" }

$WshShell = New-Object -ComObject WScript.Shell
$scTogglePath = "$smPath\Quick Toggle.lnk"

# Color Palette Setup
$cMain = "$e[38;5;51m"; $cAccent = "$e[38;5;213m"; $cText = "$e[97m"; $cDim = "$e[90m"; $cGreen = "$e[38;5;46m"; $cRed = "$e[38;5;196m"; $cYellow = "$e[38;5;226m"; $cReset = "$e[0m"; $cHeading = "$e[38;5;205m"

$csharpCode = @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using Microsoft.Win32;

namespace AutoDM {
    public class SunCalc {
        public static DateTime[] GetSunTimes(double lat, double lon, DateTime date) {
            try {
                int N = date.DayOfYear;
                double lngHour = lon / 15.0;
                double t_rise = N + ((6.0 - lngHour) / 24.0);
                double t_set = N + ((18.0 - lngHour) / 24.0);

                double M_rise = (0.9856 * t_rise) - 3.289;
                double M_set = (0.9856 * t_set) - 3.289;

                double L_rise = (M_rise + (1.916 * Math.Sin(M_rise * Math.PI/180.0)) + (0.020 * Math.Sin(2 * M_rise * Math.PI/180.0)) + 282.634) % 360.0;
                double L_set = (M_set + (1.916 * Math.Sin(M_set * Math.PI/180.0)) + (0.020 * Math.Sin(2 * M_set * Math.PI/180.0)) + 282.634) % 360.0;
                if(L_rise < 0) L_rise += 360.0; if(L_set < 0) L_set += 360.0;

                double RA_rise = (180.0/Math.PI) * Math.Atan(0.91764 * Math.Tan(L_rise * Math.PI/180.0));
                double RA_set = (180.0/Math.PI) * Math.Atan(0.91764 * Math.Tan(L_set * Math.PI/180.0));
                RA_rise = (RA_rise % 360.0); if(RA_rise < 0) RA_rise += 360.0;
                RA_set = (RA_set % 360.0); if(RA_set < 0) RA_set += 360.0;

                double Lquadrant_rise  = (Math.Floor( L_rise/90.0)) * 90.0;
                double RAquadrant_rise = (Math.Floor(RA_rise/90.0)) * 90.0;
                RA_rise = RA_rise + (Lquadrant_rise - RAquadrant_rise);
                RA_rise = RA_rise / 15.0;

                double Lquadrant_set  = (Math.Floor( L_set/90.0)) * 90.0;
                double RAquadrant_set = (Math.Floor(RA_set/90.0)) * 90.0;
                RA_set = RA_set + (Lquadrant_set - RAquadrant_set);
                RA_set = RA_set / 15.0;

                double sinDec_rise = 0.39782 * Math.Sin(L_rise * Math.PI/180.0);
                double cosDec_rise = Math.Cos(Math.Asin(sinDec_rise));
                double sinDec_set = 0.39782 * Math.Sin(L_set * Math.PI/180.0);
                double cosDec_set = Math.Cos(Math.Asin(sinDec_set));

                double cosH_rise = (Math.Cos(90.833 * Math.PI/180.0) - (sinDec_rise * Math.Sin(lat * Math.PI/180.0))) / (cosDec_rise * Math.Cos(lat * Math.PI/180.0));
                double cosH_set = (Math.Cos(90.833 * Math.PI/180.0) - (sinDec_set * Math.Sin(lat * Math.PI/180.0))) / (cosDec_set * Math.Cos(lat * Math.PI/180.0));

                if (cosH_rise > 1 || cosH_rise < -1) return new DateTime[] { DateTime.MinValue, DateTime.MinValue };

                double H_rise = (360.0 - (180.0/Math.PI) * Math.Acos(cosH_rise)) / 15.0;
                double H_set = ((180.0/Math.PI) * Math.Acos(cosH_set)) / 15.0;

                double T_rise = H_rise + RA_rise - (0.06571 * t_rise) - 6.622;
                double T_set = H_set + RA_set - (0.06571 * t_set) - 6.622;

                double UT_rise = (T_rise - lngHour) % 24.0; if(UT_rise < 0) UT_rise += 24.0;
                double UT_set = (T_set - lngHour) % 24.0; if(UT_set < 0) UT_set += 24.0;

                DateTime rise = new DateTime(date.Year, date.Month, date.Day, 0, 0, 0, DateTimeKind.Utc).AddHours(UT_rise).ToLocalTime();
                DateTime set = new DateTime(date.Year, date.Month, date.Day, 0, 0, 0, DateTimeKind.Utc).AddHours(UT_set).ToLocalTime();

                return new DateTime[] { rise, set };
            } catch { return new DateTime[] { DateTime.MinValue, DateTime.MinValue }; }
        }
    }

    public class Engine {
        [DllImport("uxtheme.dll", EntryPoint = "#104")] public static extern void RefreshImmersiveColorPolicyState();
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern bool SendNotifyMessage(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam);
        [ComImport, Guid("C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD")] public class DesktopWallpaper { }
        [ComImport, Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] public interface IDesktopWallpaper { void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] string wallpaper); }

        public static void RefreshTheme() {
            try { RefreshImmersiveColorPolicyState(); } catch {}
            
            // 1. INSTANT: Queue messages asynchronously on the RealTime thread.
            // This triggers the immediate UI switch across Explorer and wakes suspended UWP apps (Settings).
            SendNotifyMessage((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "ImmersiveColorSet");
            SendNotifyMessage((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "AppsUseLightTheme");
            SendNotifyMessage((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "SystemUsesLightTheme");
            SendNotifyMessage((IntPtr)0xFFFF, 0x031A, IntPtr.Zero, null);

            // 2. BACKGROUND: Synchronous broadcasts block and cause stuttering. We offload these.
            // Ensures heavy apps eventually update without holding up the fast Quick Toggle switch.
            Task.Run(() => {
                IntPtr res;
                SendMessageTimeout((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "ImmersiveColorSet", 2, 1000, out res);
                SendMessageTimeout((IntPtr)0xFFFF, 0x031A, IntPtr.Zero, null, 2, 1000, out res);
                SendMessageTimeout((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "WindowsThemeElement", 2, 1000, out res);
            });
        }

        public static void ApplyWP(string wp) {
            if (string.IsNullOrEmpty(wp)) return;
            try { ((IDesktopWallpaper)new DesktopWallpaper()).SetWallpaper(null, wp); }
            catch { SystemParametersInfo(20, 0, wp, 3); }
        }

        public static void ApplyAcc(string acc) {
            if (string.IsNullOrEmpty(acc)) return;
            ApplyAccInternal(acc);
            RefreshTheme();
        }

        private static void ApplyAccInternal(string acc) {
            if (acc.ToLower() == "auto") {
                using (RegistryKey desk = Registry.CurrentUser.CreateSubKey(@"Control Panel\Desktop")) { 
                    if (desk != null) { desk.SetValue("AutoColorization", 1, RegistryValueKind.DWord); desk.Flush(); }
                }
            } else {
                using (RegistryKey desk = Registry.CurrentUser.CreateSubKey(@"Control Panel\Desktop")) { 
                    if (desk != null) { desk.SetValue("AutoColorization", 0, RegistryValueKind.DWord); desk.Flush(); }
                }
                try {
                    int color = 0; if(acc.StartsWith("#")) acc = acc.Substring(1);
                    if(acc.Length == 6) {
                        int r = Convert.ToInt32(acc.Substring(0,2), 16); int g = Convert.ToInt32(acc.Substring(2,2), 16); int b = Convert.ToInt32(acc.Substring(4,2), 16);
                        color = (b << 16) | (g << 8) | r;
                    }
                    using (RegistryKey dwm = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\DWM")) {
                        if (dwm != null) {
                            dwm.SetValue("AccentColor", color, RegistryValueKind.DWord);
                            dwm.SetValue("ColorizationColor", color | unchecked((int)0xFF000000), RegistryValueKind.DWord);
                            dwm.Flush();
                        }
                    }
                } catch {}
            }
        }

        public static void RestoreAccent(int autoCol, int accCol) {
            using (RegistryKey desk = Registry.CurrentUser.CreateSubKey(@"Control Panel\Desktop")) { 
                if (desk != null) { desk.SetValue("AutoColorization", autoCol, RegistryValueKind.DWord); desk.Flush(); }
            }
            using (RegistryKey dwm = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\DWM")) { 
                if (dwm != null) {
                    dwm.SetValue("AccentColor", accCol, RegistryValueKind.DWord); 
                    dwm.SetValue("ColorizationColor", accCol | unchecked((int)0xFF000000), RegistryValueKind.DWord);
                    dwm.Flush();
                }
            }
            RefreshTheme();
        }

        public static void Execute(int isLight, string wp, string acc) {
            try {
                Process.GetCurrentProcess().PriorityClass = ProcessPriorityClass.RealTime;
                System.Threading.Thread.CurrentThread.Priority = System.Threading.ThreadPriority.Highest;
            } catch {}

            // Sequential atomic execution eliminates threading overhead and lock contention.
            if (isLight != -1) {
                using (RegistryKey reg = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", true)) {
                    if (reg != null) {
                        reg.SetValue("AppsUseLightTheme", isLight, RegistryValueKind.DWord);
                        reg.SetValue("SystemUsesLightTheme", isLight, RegistryValueKind.DWord);
                        reg.Flush();
                    }
                }
            }

            if (!string.IsNullOrEmpty(acc)) {
                ApplyAccInternal(acc);
            }

            // Fire the theme refresh IMMEDIATELY on this RealTime thread.
            // (The fast non-blocking signals run instantly, while slow ones are backgrounded)
            if (isLight != -1 || !string.IsNullOrEmpty(acc)) {
                RefreshTheme();
            }

            // Wallpaper switching hits the GPU/Disk, keep it in the background
            if (!string.IsNullOrEmpty(wp)) {
                Task.Run(() => ApplyWP(wp));
            }
        }

        public static void Toggle() {
            try {
                try {
                    Process.GetCurrentProcess().PriorityClass = ProcessPriorityClass.RealTime;
                    System.Threading.Thread.CurrentThread.Priority = System.Threading.ThreadPriority.Highest;
                } catch {}

                long ticks = DateTime.Now.Ticks;
                using (RegistryKey regDM = Registry.CurrentUser.CreateSubKey(@"SOFTWARE\AutoDM")) {
                    if (regDM != null) {
                        regDM.SetValue("OverrideTime", ticks, RegistryValueKind.QWord);
                        int newVal = 1;
                        using (RegistryKey regTheme = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize")) {
                            if (regTheme != null) {
                                object val = regTheme.GetValue("AppsUseLightTheme");
                                if (val != null && Convert.ToInt32(val) == 1) newVal = 0;
                            }
                        }
                        string wp = ""; string acc = "";
                        object wpEn = regDM.GetValue("WallpaperEnabled");
                        if (wpEn != null && Convert.ToInt32(wpEn) == 1) {
                            wp = (string)regDM.GetValue(newVal == 1 ? "LightWallpaper" : "DarkWallpaper");
                        }
                        object accEn = regDM.GetValue("AccentEnabled");
                        if (accEn != null && Convert.ToInt32(accEn) == 1) {
                            acc = (string)regDM.GetValue(newVal == 1 ? "LightAccent" : "DarkAccent");
                        }
                        Execute(newVal, wp, acc);
                    }
                }
            } catch {}
        }
    }
}
'@
if (-not ('AutoDM.Engine' -as [type])) { try { Add-Type -TypeDefinition $csharpCode -ErrorAction SilentlyContinue } catch {} }
if (-not ('AutoDM.SunCalc' -as [type])) { try { Add-Type -TypeDefinition $csharpCode -ErrorAction SilentlyContinue } catch {} }

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
    } catch {}
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

if (-not ("Shell.WinAPI" -as [type])) {
    $sig = '[DllImport("shell32.dll", CharSet=CharSet.Auto)] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);'
    Add-Type -MemberDefinition $sig -Name WinAPI -Namespace Shell -PassThru | Out-Null
}

$global:logFile = Join-Path $env:TEMP "autodm_core_log.txt"
if (-not (Test-Path $global:logFile)) { New-Item $global:logFile -ItemType File -Force | Out-Null }
$global:sectionLogs = @(Get-Content $global:logFile -ErrorAction SilentlyContinue)
if ($global:sectionLogs.Count -gt 5) { $global:sectionLogs = $global:sectionLogs[-5..-1] }

$global:menuState = "Main"
$global:selIndex = 0
$global:currentOptions = @()
$global:breadcrumb = "Core"
$global:isLoading = $false

$syncHash = [hashtable]::Synchronized(@{ Run = $false; Msg = ""; Top = 0 })
$rs = [runspacefactory]::CreateRunspace()
$rs.Open()
$rs.SessionStateProxy.SetVariable("syncHash", $syncHash)
$psCmd = [powershell]::Create().AddScript({
    $cYellow = [char]27 + "[38;5;226m"
    $cReset = [char]27 + "[0m"
    $chars = @('-', '\', '|', '/')
    $i = 0
    while ($true) {
        if ($syncHash.Run) {
            try {
                [Console]::SetCursorPosition(0, $syncHash.Top)
                [Console]::Write("  $cYellow$($chars[$i % 4]) $($syncHash.Msg)...$cReset                    ")
            } catch {}
            $i++
            [System.Threading.Thread]::Sleep(80)
        } else {
            [System.Threading.Thread]::Sleep(50)
        }
    }
})
$psCmd.Runspace = $rs
$rsHandle = $psCmd.BeginInvoke()

function Get-Breadcrumb {
    switch ($global:menuState) {
        "Main" { return "Core" }
        "Menu_General" { return "Core > General Settings" }
        "Menu_Mode" { return "Core > General Settings > Mode switch" }
        "Select_Mode_SubMenu" { return "Core > General Settings > Mode switch > Method of switch" }
        "Menu_Theme" { return "Core > General Settings > Theme switch" }
        "Menu_Advanced" { return "Core > Advanced Controls" }
        "Menu_AdjustPriority" { return "Core > Advanced Controls > Adjust priority" }
        "Menu_SystemIntegration" { return "Core > Advanced Controls > System integration" }
        "Menu_CoreSettings" { return "Core > Advanced Controls > Core settings" }
        "Menu_Tools" { return "Core > Tools" }
        "Menu_Update" { return "Core > Updates" }
        "Menu_About" { return "Core > About" }
        default { return "Core" }
    }
}

function Get-BackState {
    param($State)
    switch ($State) {
        "Menu_Mode" { return "Menu_General" }
        "Select_Mode_SubMenu" { return "Menu_Mode" }
        "Menu_Theme" { return "Menu_General" }
        "Menu_AdjustPriority" { return "Menu_Advanced" }
        "Menu_SystemIntegration" { return "Menu_Advanced" }
        "Menu_CoreSettings" { return "Menu_Advanced" }
        "Menu_Advanced" { return "Main" }
        "Menu_Tools" { return "Main" }
        "Menu_Update" { return "Main" }
        "Menu_About" { return "Main" }
        "Menu_General" { return "Main" }
        default { return "Main" }
    }
}

function Add-Log {
    param($Msg)
    if ($global:logEn -ne 1) { 
        $global:lastMsg = $Msg
        return 
    }
    $time = (Get-Date).ToString("HH:mm:ss")
    $global:sectionLogs += "[$time] $Msg"
    if ($global:sectionLogs.Count -gt 5) { $global:sectionLogs = $global:sectionLogs[-5..-1] }
    try { $global:sectionLogs | Set-Content $global:logFile -Force } catch {}
}

function Draw-Screen {
    Clear-Host
    Write-Host "
  $e[1m${cHeading}:: AutoDM CORE ::$cReset $cDim(v1.4.2)$cReset
"
    
    Write-Host "   $cDim> $global:breadcrumb >$cReset
"

    if ($global:lastMsg) { 
        Write-Host "   $cGreen>> $global:lastMsg$cReset
"
        $global:lastMsg = "" 
    }

    if ($global:menuState -eq "Menu_Mode" -and $global:currentMode -eq "Dynamic Sunrise/sunset sync") {
        Write-Host "   Location:          $cYellow$global:locLat, $global:locLon$cReset"
        Write-Host "   Today's Sunrise:   $cYellow$global:lTime$cReset"
        Write-Host "   Today's Sunset:    $cYellow$global:dTime$cReset
"
    }

    for ($i=0; $i -lt $global:currentOptions.Count; $i++) {
        $opt = $global:currentOptions[$i]
        $valStr = if ($opt.Value) { " $cDim=$cReset " + $opt.Value } else { "" }
        
        if ($i -eq $global:selIndex) {
            Write-Host ("  $cMain> $cMain" + $opt.Label + "$cReset" + $valStr)
            Write-Host ("    $cDim" + $opt.Desc + "$cReset")
        } else {
            Write-Host ("    $cText" + $opt.Label + "$cReset" + $valStr)
            Write-Host ("    $cDim" + $opt.Desc + "$cReset")
        }
        if ($i -ne $global:currentOptions.Count - 1) { Write-Host "" }
    }
    
    Write-Host ""
    $global:StatusLineY = [Console]::CursorTop
    if ($global:isLoading) {
        Write-Host "" 
    }

    Write-Host "
  $cDim UP/DOWN navigate | ENTER/RIGHT select | ESC/LEFT back/quit $cReset
"

    if ($global:sectionLogs.Count -gt 0 -and $global:logEn -eq 1) {
        foreach ($msg in $global:sectionLogs) { Write-Host "   $cDim>> $msg$cReset" }
    }
}

function Show-Loading {
    param($Msg = "Applying changes")
    $syncHash.Run = $false
    [System.Threading.Thread]::Sleep(60)
    $global:isLoading = $true
    [console]::CursorVisible = $false
    Draw-Screen
    $syncHash.Top = $global:StatusLineY
    $syncHash.Msg = $Msg
    $syncHash.Run = $true
}

function Hide-Loading {
    $syncHash.Run = $false
    $global:isLoading = $false
    [System.Threading.Thread]::Sleep(60)
}

function Get-ValidTime ($Prompt, $Default) {
    while ($true) {
        $defStr = if ($Default) { " [Default: $Default]" } else { "" }
        Write-Host "
   $cDim> $Prompt$defStr ($timeHint) (or 'back' to cancel):$cReset " -NoNewline
        $timeStr = Read-Host
        if ($timeStr.ToLower() -eq 'back') { return 'BACK' }
        if ([string]::IsNullOrWhiteSpace($timeStr) -and $Default) { return $Default }
        try { return [datetime]::Parse($timeStr).ToString($timeFormat) } 
        catch { Write-Host "     -> Invalid format.
" -ForegroundColor Red }
    }
}

$runLoop = $true
$needsRefresh = $true
$renderNeeded = $true

try {
    Show-Loading "Initializing Core and verifying tasks"

    [console]::CursorVisible = $false
    while ($runLoop) {
        if ($needsRefresh) {
            $tasks = Get-ScheduledTask -TaskPath $tPath -ErrorAction SilentlyContinue
            $tLight = $tasks | Where-Object TaskName -eq "AutoDM - Light Mode"
            $tDark = $tasks | Where-Object TaskName -eq "AutoDM - Dark Mode"
            $tBoot = $tasks | Where-Object TaskName -eq "AutoDM - Boot Sync"

            $global:lTime = if ($tLight) { try { [datetime]::Parse($tLight.Triggers[0].StartBoundary).ToString($timeFormat) } catch { "N/A" } } else { "N/A" }
            $global:dTime = if ($tDark) { try { [datetime]::Parse($tDark.Triggers[0].StartBoundary).ToString($timeFormat) } catch { "N/A" } } else { "N/A" }
            $tLightState = if ($tLight) { $tLight.State } else { 'Disabled' }
            $tBootState = if ($tBoot) { $tBoot.State } else { 'Disabled' }
            
            $xmlLight = try { Export-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath -ErrorAction Stop } catch { $null }
            $schPrio = if ($xmlLight -match '<Priority>(\d+)</Priority>') { $matches[1] } else { "2" }
            $xmlBoot = try { Export-ScheduledTask -TaskName "AutoDM - Boot Sync" -TaskPath $tPath -ErrorAction Stop } catch { $null }
            $bootPrio = if ($xmlBoot -match '<Priority>(\d+)</Priority>') { $matches[1] } else { "2" }
            $xmlSun = try { Export-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -ErrorAction Stop } catch { $null }
            $sunPrio = if ($xmlSun -match '<Priority>(\d+)</Priority>') { $matches[1] } else { "2" }
            
            $isSmHidden = $false
            if (Test-Path $smPath) { $isSmHidden = ((Get-Item $smPath -Force).Attributes -band [System.IO.FileAttributes]::Hidden) -eq [System.IO.FileAttributes]::Hidden }
            $scToggle = $WshShell.CreateShortcut($scTogglePath)
            $hotkey = $scToggle.Hotkey
            $hkEnabled = [bool]$hotkey

            $bootStatus = if ($tBootState -ne 'Disabled') { "$cGreen[ ENABLED ]$cReset" } else { "$cRed[ DISABLED ]$cReset" }
            $smStatus = if ($isSmHidden) { "$cRed[ HIDDEN ]$cReset" } else { "$cGreen[ VISIBLE ]$cReset" }
            $hkStatus = if ($hkEnabled) { "$cGreen[ ENABLED ]$cReset" } else { "$cRed[ DISABLED ]$cReset" }

            $regPath = "HKCU:\SOFTWARE\AutoDM"
            $regData = Get-ItemProperty $regPath -ErrorAction SilentlyContinue
            
            $global:logEn = if ($regData.LoggingEnabled -ne $null) { $regData.LoggingEnabled } else { 1 }
            $logStatusStr = if ($global:logEn -eq 1) { "$cGreen[ ON ]$cReset" } else { "$cRed[ OFF ]$cReset" }
            
            $dynSun = if ($regData.DynamicSun) { $regData.DynamicSun } else { "N" }
            $sunTimeVal = if ($regData.SunTime) { $regData.SunTime } else { "$defSun1" }
            $sunSyncBoot = if ($regData.SunSyncBoot) { $regData.SunSyncBoot } else { "Y" }
            $sunBootStatus = if ($sunSyncBoot -eq "Y") { "$cGreen[ ON ]$cReset" } else { "$cRed[ OFF ]$cReset" }
            $global:locLat = if ($regData.LastLat) { $regData.LastLat } else { "Unknown" }
            $global:locLon = if ($regData.LastLon) { $regData.LastLon } else { "Unknown" }

            $global:currentMode = "Off"
            if ($tLightState -ne 'Disabled') {
                if ($dynSun -eq "Y") { $global:currentMode = "Dynamic Sunrise/sunset sync" }
                else { $global:currentMode = "Scheduled" }
            }
            $modeColor = if ($global:currentMode -eq "Off") { $cRed } elseif ($global:currentMode -eq "Scheduled") { $cYellow } else { $cGreen }
            $modeDisplay = "$modeColor[ $global:currentMode ]$cReset"

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
            Hide-Loading
            $global:breadcrumb = Get-Breadcrumb
            $global:currentOptions = @()

            if ($global:menuState -eq "Main") {
                $global:currentOptions += @{ Label="Tools"; Value=$null; Desc="Toggle theme now, Reset AutoDM, Uninstall AutoDM"; Action="Menu_Tools" }
                $global:currentOptions += @{ Label="General Settings"; Value=$null; Desc="Mode scheduling, Wallpapers, Accent colors"; Action="Menu_General" }
                $global:currentOptions += @{ Label="Advanced Controls"; Value=$null; Desc="Priorities, System integrations, Core tweaks"; Action="Menu_Advanced" }
                $global:currentOptions += @{ Label="Updates"; Value=$null; Desc="Check for app updates"; Action="Menu_Update" }
                $global:currentOptions += @{ Label="About"; Value=$null; Desc="Dev links and info"; Action="Menu_About" }
                $global:currentOptions += @{ Label="Exit"; Value=$null; Desc="Close the core"; Action="Quit" }
            } elseif ($global:menuState -eq "Menu_General") {
                $global:currentOptions += @{ Label="Mode switch"; Value=$null; Desc="Method of switch and scheduling settings"; Action="Menu_Mode" }
                $global:currentOptions += @{ Label="Theme switch"; Value=$null; Desc="Configure Wallpapers and Accent colors"; Action="Menu_Theme" }
                $global:currentOptions += @{ Label="< Back"; Value=$null; Desc="Return to main menu"; Action="Main" }
            } elseif ($global:menuState -eq "Menu_Mode") {
                $global:currentOptions += @{ Label="Method of Switch"; Value=$modeDisplay; Desc="Select how AutoDM schedules themes"; Action="Select_Mode_SubMenu" }
                if ($global:currentMode -eq "Scheduled") {
                    $global:currentOptions += @{ Label="Light Mode Time"; Value="$cYellow$global:lTime$cReset"; Desc="Set the time Light Mode activates"; Action="Set_Light" }
                    $global:currentOptions += @{ Label="Dark Mode Time"; Value="$cYellow$global:dTime$cReset"; Desc="Set the time Dark Mode activates"; Action="Set_Dark" }
                } elseif ($global:currentMode -eq "Dynamic Sunrise/sunset sync") {
                    $global:currentOptions += @{ Label="Calculation Time"; Value="$cYellow$sunTimeVal$cReset"; Desc="Time to run the daily sun calculation"; Action="Set_SunTime" }
                    $global:currentOptions += @{ Label="Sync Sun Times on Boot"; Value=$sunBootStatus; Desc="Calculate missing sun times at logon"; Action="Toggle_SunBoot" }
                    $global:currentOptions += @{ Label="Force Update Now"; Value=$null; Desc="Immediately recalculate and apply sun times"; Action="Force_SunUpdate" }
                }
                $global:currentOptions += @{ Label="< Back"; Value=$null; Desc="Return to previous menu"; Action="Menu_General" }
            } elseif ($global:menuState -eq "Select_Mode_SubMenu") {
                $global:currentOptions += @{ Label="Off"; Value=$null; Desc="Disable all automatic scheduling"; Action="Set_Mode_Off" }
                $global:currentOptions += @{ Label="Scheduled"; Value=$null; Desc="Switch themes based on static times"; Action="Set_Mode_Scheduled" }
                $global:currentOptions += @{ Label="Dynamic Sunrise/sunset sync"; Value=$null; Desc="Automatically switch based on local sun times"; Action="Set_Mode_Dynamic" }
                $global:currentOptions += @{ Label="< Cancel"; Value=$null; Desc="Go back without changing"; Action="Menu_Mode" }
            } elseif ($global:menuState -eq "Menu_Theme") {
                $global:currentOptions += @{ Label="Toggle Wallpaper Switch"; Value=$wpStatusStr; Desc="Enable automatic wallpaper changes"; Action="Toggle_WP" }
                if ($wpEn -eq 1) {
                    $global:currentOptions += @{ Label="Light Wallpaper"; Value=$lWpStatus; Desc="Set wallpaper for light mode"; Action="Set_WP_L" }
                    $global:currentOptions += @{ Label="Dark Wallpaper"; Value=$dWpStatus; Desc="Set wallpaper for dark mode"; Action="Set_WP_D" }
                }
                $global:currentOptions += @{ Label="Toggle Accent Color"; Value=$accStatusStr; Desc="Enable automatic accent changes"; Action="Toggle_Acc" }
                if ($accEn -eq 1) {
                    $global:currentOptions += @{ Label="Light Accent"; Value=$lAccStatus; Desc="Set accent color for light mode"; Action="Set_Acc_L" }
                    $global:currentOptions += @{ Label="Dark Accent"; Value=$dAccStatus; Desc="Set accent color for dark mode"; Action="Set_Acc_D" }
                }
                $global:currentOptions += @{ Label="< Back"; Value=$null; Desc="Return to previous menu"; Action="Menu_General" }
            } elseif ($global:menuState -eq "Menu_Advanced") {
                $global:currentOptions += @{ Label="Adjust priority"; Value=$null; Desc="Settings related to execution priority"; Action="Menu_AdjustPriority" }
                $global:currentOptions += @{ Label="System integration"; Value=$null; Desc="Boot sync, start menu icons, toggle key"; Action="Menu_SystemIntegration" }
                $global:currentOptions += @{ Label="Core settings"; Value=$null; Desc="Turn on/off logging and other core features"; Action="Menu_CoreSettings" }
                $global:currentOptions += @{ Label="< Back"; Value=$null; Desc="Return to main menu"; Action="Main" }
            } elseif ($global:menuState -eq "Menu_AdjustPriority") {
                $global:currentOptions += @{ Label="Schedule Priority"; Value="$cYellow$schPrio$cReset"; Desc="Change the process priority of schedule trigger"; Action="Set_Sch_Prio" }
                $global:currentOptions += @{ Label="Boot Sync Priority"; Value="$cYellow$bootPrio$cReset"; Desc="Change the process priority of logon trigger"; Action="Set_Boot_Prio" }
                if ($global:currentMode -eq "Dynamic Sunrise/sunset sync") {
                    $global:currentOptions += @{ Label="Dynamic Calculator Priority"; Value="$cYellow$sunPrio$cReset"; Desc="Change the priority of the Sun update task"; Action="Set_Sun_Prio" }
                }
                $global:currentOptions += @{ Label="< Back"; Value=$null; Desc="Return to previous menu"; Action="Menu_Advanced" }
            } elseif ($global:menuState -eq "Menu_SystemIntegration") {
                $global:currentOptions += @{ Label="Boot Sync State"; Value=$bootStatus; Desc="Enable/Disable theming sync upon logon"; Action="Toggle_Boot" }
                $global:currentOptions += @{ Label="Start Menu Icons"; Value=$smStatus; Desc="Hide or Show app shortcuts in start menu"; Action="Toggle_Sm" }
                $global:currentOptions += @{ Label="Quick Toggle Key"; Value=$hkStatus; Desc="Enable keyboard shortcut (CTRL+ALT+$savedKey)"; Action="Toggle_Hk" }
                if ($hkEnabled) { $global:currentOptions += @{ Label="Change Shortcut Key"; Value=$null; Desc="Bind a new key letter to CTRL+ALT+?"; Action="Change_Hk" } }
                $global:currentOptions += @{ Label="< Back"; Value=$null; Desc="Return to previous menu"; Action="Menu_Advanced" }
            } elseif ($global:menuState -eq "Menu_CoreSettings") {
                $global:currentOptions += @{ Label="Toggle Session Logging"; Value=$logStatusStr; Desc="Enable or disable the core session logs"; Action="Toggle_Logging" }
                $global:currentOptions += @{ Label="< Back"; Value=$null; Desc="Return to previous menu"; Action="Menu_Advanced" }
            } elseif ($global:menuState -eq "Menu_Tools") {
                $global:currentOptions += @{ Label="Toggle Theme Now"; Value=$null; Desc="Instantly switch between Light and Dark mode"; Action="Do_Toggle" }
                $global:currentOptions += @{ Label="Reset AutoDM"; Value=$null; Desc="Restore settings to default and recreate tasks"; Action="Reset_AutoDM" }
                $global:currentOptions += @{ Label="Uninstall AutoDM"; Value=$null; Desc="Completely remove AutoDM from your system"; Action="Uninstall_AutoDM" }
                $global:currentOptions += @{ Label="< Back"; Value=$null; Desc="Return to main menu"; Action="Main" }
            } elseif ($global:menuState -eq "Menu_Update") {
                $global:currentOptions += @{ Label="Check for Updates"; Value=$null; Desc="Fetch the latest features from GitHub"; Action="Update_Check" }
                $global:currentOptions += @{ Label="< Back"; Value=$null; Desc="Return to main menu"; Action="Main" }
            } elseif ($global:menuState -eq "Menu_About") {
                $global:currentOptions += @{ Label="Developer GitHub"; Value=$null; Desc="Open Developer profile in browser"; Action="Open_Dev" }
                $global:currentOptions += @{ Label="Developer Website"; Value=$null; Desc="Visit the Developer's Portfolio Website"; Action="Open_DevWeb" }
                $global:currentOptions += @{ Label="Project Repository"; Value=$null; Desc="Open Project Repo in browser"; Action="Open_Proj" }
                $global:currentOptions += @{ Label="< Back"; Value=$null; Desc="Return to main menu"; Action="Main" }
            }

            if ($global:selIndex -ge $global:currentOptions.Count) { $global:selIndex = $global:currentOptions.Count - 1 }
            if ($global:selIndex -lt 0) { $global:selIndex = 0 }

            Draw-Screen
            $renderNeeded = $false
        }

        while (-not [System.Console]::KeyAvailable) { Start-Sleep -Milliseconds 50 }
        $key = [System.Console]::ReadKey($true)

        if ($key.KeyChar -eq 'q' -or $key.KeyChar -eq 'Q') { $runLoop = $false; continue }

        $k = $key.Key.ToString()

        if ($k -eq 'UpArrow') { 
            $global:selIndex--
            if ($global:selIndex -lt 0) { $global:selIndex = $global:currentOptions.Count - 1 }
            $renderNeeded = $true 
        }
        elseif ($k -eq 'DownArrow') { 
            $global:selIndex++
            if ($global:selIndex -ge $global:currentOptions.Count) { $global:selIndex = 0 }
            $renderNeeded = $true 
        }
        elseif ($k -eq 'LeftArrow' -or $k -eq 'Backspace' -or $k -eq 'Escape') { 
            if ($global:menuState -eq "Main") {
                if ($k -eq 'Escape') { $runLoop = $false }
            } else { 
                $global:menuState = Get-BackState $global:menuState
                $global:selIndex = 0
                $renderNeeded = $true 
            } 
        }
        elseif ($k -eq 'Enter' -or $k -eq 'RightArrow') {
            $action = $global:currentOptions[$global:selIndex].Action
            if ($action -like "Menu_*" -or $action -like "Select_*" -or $action -eq "Main") {
                $global:menuState = $action
                $global:selIndex = 0
                $renderNeeded = $true
            } elseif ($action -eq "Quit") {
                $runLoop = $false
            } else {
                [console]::CursorVisible = $true
                switch ($action) {
                    "Set_Mode_Off" {
                        Show-Loading "Disabling automation"
                        try { Disable-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath -ErrorAction Stop | Out-Null } catch {}
                        try { Disable-ScheduledTask -TaskName "AutoDM - Dark Mode" -TaskPath $tPath -ErrorAction Stop | Out-Null } catch {}
                        try { Disable-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -ErrorAction Stop | Out-Null } catch {}
                        Set-ConfigValue "DynamicSun" "N"
                        Add-Log "Auto switching disabled (Off)."
                        $global:menuState = "Menu_Mode"
                        $global:selIndex = 0
                        $needsRefresh = $true
                    }
                    "Set_Mode_Scheduled" {
                        Show-Loading "Enabling scheduled mode"
                        try { Disable-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -ErrorAction Stop | Out-Null } catch {}
                        Set-ConfigValue "DynamicSun" "N"
                        
                        $lTimeConf = if ($regData.LightTime) { $regData.LightTime } else { $defLight }
                        $dTimeConf = if ($regData.DarkTime) { $regData.DarkTime } else { $defDark }

                        try { $ptL = Get-Date $lTimeConf } catch { $ptL = (Get-Date).Date.AddHours(7) }
                        try {
                            $tL = Get-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath -ErrorAction Stop
                            $tL.Triggers[0].StartBoundary = $ptL.ToString("yyyy-MM-ddTHH:mm:ss")
                            $tL | Set-ScheduledTask -User $env:USERNAME -ErrorAction Stop | Out-Null
                        } catch {
                            $trigL = New-ScheduledTaskTrigger -Daily -At $ptL
                            try { Set-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath -Trigger $trigL -Principal $p -ErrorAction SilentlyContinue | Out-Null } catch {}
                        }

                        try { $ptD = Get-Date $dTimeConf } catch { $ptD = (Get-Date).Date.AddHours(19) }
                        try {
                            $tD = Get-ScheduledTask -TaskName "AutoDM - Dark Mode" -TaskPath $tPath -ErrorAction Stop
                            $tD.Triggers[0].StartBoundary = $ptD.ToString("yyyy-MM-ddTHH:mm:ss")
                            $tD | Set-ScheduledTask -User $env:USERNAME -ErrorAction Stop | Out-Null
                        } catch {
                            $trigD = New-ScheduledTaskTrigger -Daily -At $ptD
                            try { Set-ScheduledTask -TaskName "AutoDM - Dark Mode" -TaskPath $tPath -Trigger $trigD -Principal $p -ErrorAction SilentlyContinue | Out-Null } catch {}
                        }

                        try { Enable-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath -ErrorAction Stop | Out-Null } catch {}
                        try { Enable-ScheduledTask -TaskName "AutoDM - Dark Mode" -TaskPath $tPath -ErrorAction Stop | Out-Null } catch {}
                        
                        Add-Log "Mode set to Scheduled. Original times restored."
                        $global:menuState = "Menu_Mode"
                        $global:selIndex = 0
                        $needsRefresh = $true
                    }
                    "Set_Light" {
                        Hide-Loading
                        $newTime = Get-ValidTime "Enter Light Mode Time" $global:lTime
                        if ($newTime -eq 'BACK') { Add-Log "Cancelled."; $needsRefresh = $true; break }
                        Show-Loading "Updating Light Time"
                        Set-ConfigValue "LightTime" $newTime
                        try {
                            $pt = Get-Date $newTime
                            $tLight = Get-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath -ErrorAction Stop
                            $tLight.Triggers[0].StartBoundary = $pt.ToString("yyyy-MM-ddTHH:mm:ss")
                            $tLight | Set-ScheduledTask -User $env:USERNAME -ErrorAction Stop | Out-Null
                            Add-Log "Light Mode time updated to $newTime"
                        } catch { Add-Log "Failed to update Light Mode trigger." }
                        $needsRefresh = $true
                    }
                    "Set_Dark" {
                        Hide-Loading
                        $newTime = Get-ValidTime "Enter Dark Mode Time" $global:dTime
                        if ($newTime -eq 'BACK') { Add-Log "Cancelled."; $needsRefresh = $true; break }
                        Show-Loading "Updating Dark Time"
                        Set-ConfigValue "DarkTime" $newTime
                        try {
                            $pt = Get-Date $newTime
                            $tDark = Get-ScheduledTask -TaskName "AutoDM - Dark Mode" -TaskPath $tPath -ErrorAction Stop
                            $tDark.Triggers[0].StartBoundary = $pt.ToString("yyyy-MM-ddTHH:mm:ss")
                            $tDark | Set-ScheduledTask -User $env:USERNAME -ErrorAction Stop | Out-Null
                            Add-Log "Dark Mode time updated to $newTime"
                        } catch { Add-Log "Failed to update Dark Mode trigger." }
                        $needsRefresh = $true
                    }
                    "Set_Mode_Dynamic" {
                        Hide-Loading
                        $locErr = $false
                        if (-not $regData.LastLat -or -not $regData.LastLon) {
                            Add-Type -AssemblyName System.Device -ErrorAction SilentlyContinue
                            try {
                                $w = New-Object System.Device.Location.GeoCoordinateWatcher([System.Device.Location.GeoPositionAccuracy]::High)
                                $w.Start()
                                $t = 15; while (($w.Status -ne 'Ready' -or $w.Position.Location.IsUnknown) -and ($t -gt 0)) { Start-Sleep -Seconds 1; $t-- }
                                if (-not $w.Position.Location.IsUnknown) {
                                    Set-ConfigValue "LastLat" $w.Position.Location.Latitude.ToString([System.Globalization.CultureInfo]::InvariantCulture)
                                    Set-ConfigValue "LastLon" $w.Position.Location.Longitude.ToString([System.Globalization.CultureInfo]::InvariantCulture)
                                } else {
                                    [console]::CursorVisible = $true
                                    Clear-Host
                                    Write-Host "
   $cYellow[!] Windows Location Services failed to auto-detect your location.$cReset"
                                    Write-Host "   $cDim> Please enter your coordinates manually to enable Sun Sync.$cReset"
                                    Write-Host "   $cDim> (You can find these on Google Maps by right-clicking your location)$cReset
"
                                    Write-Host "   $cMain> Enter Latitude (e.g., 40.7128) :$cReset " -NoNewline
                                    $latIn = Read-Host
                                    Write-Host "   $cMain> Enter Longitude (e.g., -74.0060):$cReset " -NoNewline
                                    $lonIn = Read-Host
                                    try {
                                        $parsedLat = [double]::Parse(($latIn -replace ',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
                                        $parsedLon = [double]::Parse(($lonIn -replace ',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
                                        Set-ConfigValue "LastLat" $parsedLat.ToString([System.Globalization.CultureInfo]::InvariantCulture)
                                        Set-ConfigValue "LastLon" $parsedLon.ToString([System.Globalization.CultureInfo]::InvariantCulture)
                                    } catch { $locErr = $true }
                                    [console]::CursorVisible = $false
                                }
                                $w.Stop()
                            } catch { $locErr = $true }
                        }
                        
                        if ($locErr) {
                            Add-Log "Failed to fetch Location Services offline. Reverting to Scheduled Mode."
                            try { Enable-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath -ErrorAction Stop | Out-Null } catch {}
                            try { Enable-ScheduledTask -TaskName "AutoDM - Dark Mode" -TaskPath $tPath -ErrorAction Stop | Out-Null } catch {}
                            try { Disable-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -ErrorAction Stop | Out-Null } catch {}
                            Set-ConfigValue "DynamicSun" "N"
                        } else {
                            Show-Loading "Enabling Sun Sync"
                            try { Enable-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath -ErrorAction Stop | Out-Null } catch {}
                            try { Enable-ScheduledTask -TaskName "AutoDM - Dark Mode" -TaskPath $tPath -ErrorAction Stop | Out-Null } catch {}
                            
                            $sunTaskExists = $false
                            try { $null = Get-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -ErrorAction Stop; $sunTaskExists = $true } catch {}

                            if (-not $sunTaskExists) {
                                $safeTime = if ([string]::IsNullOrWhiteSpace($regData.SunTime)) { $defSun1 } else { $regData.SunTime.Trim() }
                                try { $pt = Get-Date $safeTime } catch { $pt = (Get-Date).Date }
                                $trigs = @(New-ScheduledTaskTrigger -Daily -At $pt)
                                if ($sunSyncBoot -eq "Y") { $trigs += New-ScheduledTaskTrigger -AtLogOn }
                                
                                try {
                                    $actSun = New-ScheduledTaskAction -Execute "wscript.exe" -Argument ('"{0}" "{1}\CoreEngine.cmd" SUN' -f $vbs, $engineDir)
                                    $taskSun = New-ScheduledTask -Action $actSun -Principal $p -Trigger $trigs -Settings $settings
                                    Register-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -InputObject $taskSun -Force -ErrorAction Stop | Out-Null
                                    if ($sunSyncBoot -eq "Y") {
                                        $xmlSun = try { (Export-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -ErrorAction Stop) -replace '</Triggers>', '<SessionStateChangeTrigger><StateChange>SessionUnlock</StateChange></SessionStateChangeTrigger></Triggers>' } catch { $null }
                                        if ($xmlSun) { try { Register-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -Xml $xmlSun -Force -User $env:USERNAME -ErrorAction Stop | Out-Null } catch {} }
                                    }
                                } catch {}
                            } else {
                                try { Enable-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -ErrorAction Stop | Out-Null } catch {}
                            }

                            Set-ConfigValue "DynamicSun" "Y"
                            
                            try {
                                $lat = (Get-ItemProperty $regPath -ErrorAction SilentlyContinue).LastLat
                                $lon = (Get-ItemProperty $regPath -ErrorAction SilentlyContinue).LastLon
                                if ($lat -ne $null -and $lon -ne $null) {
                                    $latStr = $lat.ToString()
                                    $lonStr = $lon.ToString()
                                    $latD = [double]::Parse($latStr.Replace(',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
                                    $lonD = [double]::Parse($lonStr.Replace(',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
                                    $now = [datetime]::Now
                                    $times = [AutoDM.SunCalc]::GetSunTimes($latD, $lonD, $now)
                                    
                                    if ($times[0] -ne [datetime]::MinValue) {
                                        try {
                                            $tL = Get-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath -ErrorAction Stop
                                            $tL.Triggers[0].StartBoundary = $times[0].ToString("yyyy-MM-ddTHH:mm:ss")
                                            $tL | Set-ScheduledTask -User $env:USERNAME -ErrorAction Stop | Out-Null
                                        } catch {}
                                        
                                        try {
                                            $tD = Get-ScheduledTask -TaskName "AutoDM - Dark Mode" -TaskPath $tPath -ErrorAction Stop
                                            $tD.Triggers[0].StartBoundary = $times[1].ToString("yyyy-MM-ddTHH:mm:ss")
                                            $tD | Set-ScheduledTask -User $env:USERNAME -ErrorAction Stop | Out-Null
                                        } catch {}
                                        
                                        $shouldBeLight = ($now.TimeOfDay -ge $times[0].TimeOfDay -and $now.TimeOfDay -lt $times[1].TimeOfDay)
                                        $expectedVal = if ($shouldBeLight) { 1 } else { 0 }
                                        $currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                                        
                                        if ($currApp -ne $expectedVal) {
                                            $wp = ""; $acc = ""
                                            if ($regData.WallpaperEnabled -eq 1) { $wp = if ($expectedVal -eq 1) { $regData.LightWallpaper } else { $regData.DarkWallpaper } }
                                            if ($regData.AccentEnabled -eq 1) { $acc = if ($expectedVal -eq 1) { $regData.LightAccent } else { $regData.DarkAccent } }
                                            [AutoDM.Engine]::Execute($expectedVal, $wp, $acc)
                                        }
                                        Add-Log "Sun times successfully calculated and applied!"
                                    } else { Add-Log "Calculation returned invalid times." }
                                } else { Add-Log "Location missing. Please re-enable Dynamic Mode." }
                            } catch { Add-Log "Error during calculation: $($_.Exception.Message)" }
                        }
                        
                        $global:menuState = "Menu_Mode"
                        $global:selIndex = 0
                        $needsRefresh = $true
                    }
                    "Set_SunTime" {
                        Hide-Loading
                        $newTime = Get-ValidTime "Enter new Calculation Time" $sunTimeVal
                        if ($newTime -eq 'BACK') { Add-Log "Cancelled."; $needsRefresh = $true; break }
                        Show-Loading "Updating Sun Time"
                        Set-ConfigValue "SunTime" $newTime
                        try {
                            $pt = Get-Date $newTime
                            $tSun = Get-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -ErrorAction Stop
                            $trigs = @(New-ScheduledTaskTrigger -Daily -At $pt)
                            if ($sunSyncBoot -eq "Y") { $trigs += New-ScheduledTaskTrigger -AtLogOn }
                            $tSun.Triggers = $trigs
                            $tSun | Set-ScheduledTask -User $env:USERNAME -ErrorAction Stop | Out-Null
                            if ($sunSyncBoot -eq "Y") {
                                $xmlSun = try { (Export-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -ErrorAction Stop) -replace '</Triggers>', '<SessionStateChangeTrigger><StateChange>SessionUnlock</StateChange></SessionStateChangeTrigger></Triggers>' } catch { $null }
                                if ($xmlSun) { try { Register-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -Xml $xmlSun -Force -User $env:USERNAME -ErrorAction Stop | Out-Null } catch {} }
                            }
                            Add-Log "Sun calculation time updated to $newTime"
                        } catch { Add-Log "Failed to update Sun calculation time trigger." }
                        $needsRefresh = $true
                    }
                    "Toggle_SunBoot" {
                        Show-Loading "Updating Boot Sync"
                        $newSunBoot = if ($sunSyncBoot -eq "Y") { "N" } else { "Y" }
                        Set-ConfigValue "SunSyncBoot" $newSunBoot
                        try {
                            $safeTime = if ([string]::IsNullOrWhiteSpace($sunTimeVal)) { $defSun1 } else { $sunTimeVal }
                            $pt = Get-Date $safeTime
                            $tSun = Get-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -ErrorAction Stop
                            $trigs = @(New-ScheduledTaskTrigger -Daily -At $pt)
                            if ($newSunBoot -eq "Y") { $trigs += New-ScheduledTaskTrigger -AtLogOn }
                            $tSun.Triggers = $trigs
                            $tSun | Set-ScheduledTask -User $env:USERNAME -ErrorAction Stop | Out-Null
                            if ($newSunBoot -eq "Y") {
                                $xmlSun = try { (Export-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -ErrorAction Stop) -replace '</Triggers>', '<SessionStateChangeTrigger><StateChange>SessionUnlock</StateChange></SessionStateChangeTrigger></Triggers>' } catch { $null }
                                if ($xmlSun) { try { Register-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -Xml $xmlSun -Force -User $env:USERNAME -ErrorAction Stop | Out-Null } catch {} }
                            }
                            Add-Log "Sun Boot Sync set to $newSunBoot"
                        } catch { Add-Log "Failed to update Sun Boot Sync." }
                        $needsRefresh = $true
                    }
                    "Force_SunUpdate" {
                        Show-Loading "Calculating Sun Times & Applying"
                        try {
                            $lat = (Get-ItemProperty $regPath -ErrorAction SilentlyContinue).LastLat
                            $lon = (Get-ItemProperty $regPath -ErrorAction SilentlyContinue).LastLon
                            $latStr = if ($lat) { $lat.ToString() } else { "0" }
                            $lonStr = if ($lon) { $lon.ToString() } else { "0" }
                            $latD = [double]::Parse($latStr.Replace(',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
                            $lonD = [double]::Parse($lonStr.Replace(',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
                            $now = [datetime]::Now
                            $times = [AutoDM.SunCalc]::GetSunTimes($latD, $lonD, $now)
                            
                            if ($times[0] -ne [datetime]::MinValue) {
                                try {
                                    $tL = Get-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath -ErrorAction Stop
                                    $tL.Triggers[0].StartBoundary = $times[0].ToString("yyyy-MM-ddTHH:mm:ss")
                                    $tL | Set-ScheduledTask -User $env:USERNAME -ErrorAction Stop | Out-Null
                                } catch {}
                                try {
                                    $tD = Get-ScheduledTask -TaskName "AutoDM - Dark Mode" -TaskPath $tPath -ErrorAction Stop
                                    $tD.Triggers[0].StartBoundary = $times[1].ToString("yyyy-MM-ddTHH:mm:ss")
                                    $tD | Set-ScheduledTask -User $env:USERNAME -ErrorAction Stop | Out-Null
                                } catch {}
                                
                                $shouldBeLight = ($now.TimeOfDay -ge $times[0].TimeOfDay -and $now.TimeOfDay -lt $times[1].TimeOfDay)
                                $expectedVal = if ($shouldBeLight) { 1 } else { 0 }
                                
                                $wp = ""; $acc = ""
                                if ($regData.WallpaperEnabled -eq 1) { $wp = if ($expectedVal -eq 1) { $regData.LightWallpaper } else { $regData.DarkWallpaper } }
                                if ($regData.AccentEnabled -eq 1) { $acc = if ($expectedVal -eq 1) { $regData.LightAccent } else { $regData.DarkAccent } }
                                [AutoDM.Engine]::Execute($expectedVal, $wp, $acc)
                                
                                Add-Log "Sun times forced & instantly applied successfully!"
                            } else { Add-Log "Calculation returned invalid times." }
                        } catch { Add-Log "Error during calculation: $($_.Exception.Message)" }
                        $needsRefresh = $true
                    }
                    "Toggle_WP" {
                        Show-Loading "Updating Wallpaper settings"
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
                                Add-Log "WP Switch ON: Backed up current WP as Default."
                            } else { Add-Log "WP Switch ON" }
                        } else {
                            $bWp = (Get-ChildItem "$wpDir\Default_WP.*" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
                            if ($bWp -and (Test-Path $bWp)) { [AutoDM.Engine]::ApplyWP($bWp) }
                            Add-Log "WP Switch OFF: Restored Default Wallpaper."
                        }
                        Set-ConfigValue "WallpaperEnabled" $newEn "DWord"
                        $needsRefresh = $true
                    }
                    "Set_WP_L" {
                        Hide-Loading
                        Write-Host "
   $cDim> Enter path to Light Wallpaper (type 'none' to clear, 'back' to cancel):$cReset " -NoNewline
                        $wpInput = Read-Host
                        if ($wpInput.ToLower() -eq 'back') { Add-Log "Cancelled."; $needsRefresh = $true; break }
                        Show-Loading "Updating light wallpaper"
                        if ($wpInput -eq 'none') {
                            Remove-ConfigValue "LightWallpaper"
                            Remove-ConfigValue "LightWallpaperName"
                            Remove-Item "$wpDir\Light_*" -Force -ErrorAction SilentlyContinue
                            Add-Log "Light wallpaper removed"
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
                            if ($isLight -eq 1) { [AutoDM.Engine]::ApplyWP($dest) }
                            Add-Log "Light wallpaper successfully set to $wpFileName"
                        } else { Add-Log "Invalid path." }
                        $needsRefresh = $true
                    }
                    "Set_WP_D" {
                        Hide-Loading
                        Write-Host "
   $cDim> Enter path to Dark Wallpaper (type 'none' to clear, 'back' to cancel):$cReset " -NoNewline
                        $wpInput = Read-Host
                        if ($wpInput.ToLower() -eq 'back') { Add-Log "Cancelled."; $needsRefresh = $true; break }
                        Show-Loading "Updating dark wallpaper"
                        if ($wpInput -eq 'none') {
                            Remove-ConfigValue "DarkWallpaper"
                            Remove-ConfigValue "DarkWallpaperName"
                            Remove-Item "$wpDir\Dark_*" -Force -ErrorAction SilentlyContinue
                            Add-Log "Dark wallpaper removed"
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
                            if ($isLight -eq 0) { [AutoDM.Engine]::ApplyWP($dest) }
                            Add-Log "Dark wallpaper successfully set to $wpFileName"
                        } else { Add-Log "Invalid path." }
                        $needsRefresh = $true
                    }
                    "Toggle_Acc" {
                        Show-Loading "Updating Accent settings"
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
                                Add-Log "Accent Switch ON: Backed up current Accent to be used as default."
                            } else { Add-Log "Accent Switch ON" }
                        } else {
                            [AutoDM.Engine]::ApplyAcc("auto")
                            Add-Log "Accent Switch OFF: Restored Accent to Auto."
                        }
                        Set-ConfigValue "AccentEnabled" $newAccEn "DWord"
                        $needsRefresh = $true
                    }
                    "Set_Acc_L" {
                        Hide-Loading
                        Write-Host "
   $cDim> Enter HEX Color (e.g., #FF5500), 'auto' to extract, 'none' to clear, 'back' to cancel:$cReset " -NoNewline
                        $accInput = Read-Host
                        if ($accInput.ToLower() -eq 'back') { Add-Log "Cancelled."; $needsRefresh = $true; break }
                        Show-Loading "Updating light accent"
                        if ($accInput -eq 'none') {
                            Remove-ConfigValue "LightAccent"
                            Add-Log "Light Accent color cleared"
                        } elseif ($accInput -match '^#?([a-fA-F0-9]{6})$|^auto$') {
                            Set-ConfigValue "LightAccent" $accInput.ToUpper()
                            $isLight = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                            if ($isLight -eq 1) { [AutoDM.Engine]::ApplyAcc($accInput) }
                            Add-Log "Light Accent color updated"
                        } else { Add-Log "Invalid input. Must be HEX or 'auto'." }
                        $needsRefresh = $true
                    }
                    "Set_Acc_D" {
                        Hide-Loading
                        Write-Host "
   $cDim> Enter HEX Color (e.g., #0055FF), 'auto' to extract, 'none' to clear, 'back' to cancel:$cReset " -NoNewline
                        $accInput = Read-Host
                        if ($accInput.ToLower() -eq 'back') { Add-Log "Cancelled."; $needsRefresh = $true; break }
                        Show-Loading "Updating dark accent"
                        if ($accInput -eq 'none') {
                            Remove-ConfigValue "DarkAccent"
                            Add-Log "Dark Accent color cleared"
                        } elseif ($accInput -match '^#?([a-fA-F0-9]{6})$|^auto$') {
                            Set-ConfigValue "DarkAccent" $accInput.ToUpper()
                            $isLight = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                            if ($isLight -eq 0) { [AutoDM.Engine]::ApplyAcc($accInput) }
                            Add-Log "Dark Accent color updated"
                        } else { Add-Log "Invalid input. Must be HEX or 'auto'." }
                        $needsRefresh = $true
                    }
                    "Toggle_Boot" {
                        Show-Loading "Updating boot settings"
                        if ($tBootState -ne 'Disabled') { 
                            try { Disable-ScheduledTask -TaskName "AutoDM - Boot Sync" -TaskPath $tPath -ErrorAction Stop | Out-Null } catch {}
                            Add-Log "Boot trigger disabled"
                            Set-ConfigValue "BootSync" "N"
                        } else { 
                            try { Enable-ScheduledTask -TaskName "AutoDM - Boot Sync" -TaskPath $tPath -ErrorAction Stop | Out-Null } catch {}
                            Add-Log "Boot trigger enabled"
                            Set-ConfigValue "BootSync" "Y"
                        }
                        $needsRefresh = $true
                    }
                    "Toggle_Sm" {
                        Show-Loading "Updating Start Menu"
                        if (Test-Path $smPath) {
                            $item = Get-Item $smPath -Force
                            if ($isSmHidden) { 
                                $item.Attributes = $item.Attributes -band (-bnot [System.IO.FileAttributes]::Hidden)
                                Add-Log "Start menu items set to Visible"
                            } else { 
                                $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
                                Add-Log "Start menu items set to Hidden"
                            }
                            Start-Sleep -Seconds 2
                            [Shell.WinAPI]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
                            Stop-Process -Name "SearchHost" -Force -ErrorAction SilentlyContinue
                            Stop-Process -Name "StartMenuExperienceHost" -Force -ErrorAction SilentlyContinue
                        }
                        $needsRefresh = $true
                    }
                    "Toggle_Hk" {
                        Show-Loading "Updating shortcut"
                        if ($hkEnabled) { 
                            $scToggle.Hotkey = ""; $scToggle.Save() 
                            Add-Log "Keyboard shortcut disabled"
                            Set-ConfigValue "Shortcut" "N"
                        } else { 
                            $scToggle.Hotkey = ""; $scToggle.Save()
                            Start-Sleep -Milliseconds 200
                            $scToggle.Hotkey = "CTRL+ALT+" + $savedKey; $scToggle.Save() 
                            Add-Log "Keyboard shortcut enabled (CTRL+ALT+$savedKey)"
                            Set-ConfigValue "Shortcut" "Y"
                        }
                        $needsRefresh = $true
                    }
                    "Change_Hk" {
                        Hide-Loading
                        while ($true) {
                            Write-Host "
   $cDim> Enter new key to use with CTRL+ALT (A-Z, 0-9) or 'back' to cancel:$cReset " -NoNewline
                            $newK = Read-Host
                            if ($newK.ToLower() -eq 'back') { Add-Log "Cancelled."; break }
                            if ($newK -match '^[a-zA-Z0-9]$') { 
                                Show-Loading "Updating shortcut"
                                $nk = $newK.ToUpper()
                                $hotkey = "CTRL+ALT+" + $nk
                                $scToggle.Hotkey = ""; $scToggle.Save()
                                Start-Sleep -Milliseconds 200
                                $scToggle.Hotkey = $hotkey; $scToggle.Save()
                                Set-ConfigValue "ShortcutKey" $nk
                                Add-Log "Shortcut key updated to $hotkey"
                                break 
                            }
                            Write-Host "     -> Invalid key. Use a single letter or number.
" -ForegroundColor Red
                        }
                        $needsRefresh = $true
                    }
                    "Toggle_Logging" {
                        Show-Loading "Updating core settings"
                        $newLogEn = if ($global:logEn -eq 1) { 0 } else { 1 }
                        Set-ConfigValue "LoggingEnabled" $newLogEn "DWord"
                        $global:logEn = $newLogEn
                        if ($newLogEn -eq 0) {
                            $global:sectionLogs = @()
                            try { Remove-Item $global:logFile -Force -ErrorAction SilentlyContinue } catch {}
                            $global:lastMsg = "Session logging disabled and file deleted."
                        } else {
                            Add-Log "Session logging enabled."
                        }
                        $needsRefresh = $true
                    }
                    "Do_Toggle" {
                        Show-Loading "Toggling Theme"
                        [AutoDM.Engine]::Toggle()
                        Add-Log "Theme toggled instantly."
                        $needsRefresh = $true
                    }
                    "Reset_AutoDM" {
                        Hide-Loading
                        Write-Host "
   $cRed[!] This will reset all AutoDM settings and recreate tasks.$cReset"
                        Write-Host "   $cMain> Are you sure? (Y/N):$cReset " -NoNewline
                        $ans = Read-Host
                        if ($ans -match '^[Yy]') {
                            Show-Loading "Resetting AutoDM"
                            
                            # Clean Registry and Config file
                            if (Test-Path "HKCU:\SOFTWARE\AutoDM") { Remove-Item "HKCU:\SOFTWARE\AutoDM" -Recurse -Force -ErrorAction SilentlyContinue }
                            New-Item -Path "HKCU:\SOFTWARE\AutoDM" -Force | Out-Null
                            
                            $cfgPath = "C:\Program Files\Detaroxz\AutoDM\config.ini"
                            if (Test-Path $cfgPath) { Remove-Item $cfgPath -Force -ErrorAction SilentlyContinue }
                            
                            # Setup Default config keys
                            Set-ConfigValue "LightTime" $defLight
                            Set-ConfigValue "DarkTime" $defDark
                            Set-ConfigValue "BootSync" "Y"
                            Set-ConfigValue "Shortcut" "Y"
                            Set-ConfigValue "ShortcutKey" "T"
                            Set-ConfigValue "WallpaperEnabled" 0 "DWord"
                            Set-ConfigValue "AccentEnabled" 0 "DWord"
                            Set-ConfigValue "DynamicSun" "N"
                            Set-ConfigValue "SunSyncBoot" "Y"
                            Set-ConfigValue "LoggingEnabled" 1 "DWord"
                            
                            # Recreate Task Actions and Details
                            $tPath = "\Detaroxz\AutoDM\"
                            $engDir = "C:\Program Files\Detaroxz\AutoDM\Engine"
                            $vbsRunner = "$engDir\RunSilent.vbs"
                            
                            try { Get-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -ErrorAction Stop | Unregister-ScheduledTask -Confirm:$false -ErrorAction Stop } catch {}
                            
                            $actSync = New-ScheduledTaskAction -Execute "wscript.exe" -Argument ('"{0}" "{1}\CoreEngine.cmd" SYNC' -f $vbsRunner, $engDir)
                            $actBoot = New-ScheduledTaskAction -Execute "wscript.exe" -Argument ('"{0}" "{1}\CoreEngine.cmd" BOOT' -f $vbsRunner, $engDir)
                            
                            # Light Mode Trigger
                            try { $ptL = Get-Date $defLight } catch { $ptL = (Get-Date).Date.AddHours(7) }
                            $trigL = New-ScheduledTaskTrigger -Daily -At $ptL
                            try { Set-ScheduledTask -TaskName "AutoDM - Light Mode" -TaskPath $tPath -Trigger $trigL -Principal $p -ErrorAction Stop | Out-Null } catch {}
                            
                            # Dark Mode Trigger
                            try { $ptD = Get-Date $defDark } catch { $ptD = (Get-Date).Date.AddHours(19) }
                            $trigD = New-ScheduledTaskTrigger -Daily -At $ptD
                            try { Set-ScheduledTask -TaskName "AutoDM - Dark Mode" -TaskPath $tPath -Trigger $trigD -Principal $p -ErrorAction Stop | Out-Null } catch {}
                            
                            # Boot Sync Trigger
                            $taskB = New-ScheduledTask -Action $actBoot -Principal $p -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Settings $settings
                            try { Set-ScheduledTask -TaskName "AutoDM - Boot Sync" -TaskPath $tPath -InputObject $taskB -Force -ErrorAction Stop | Out-Null } catch {}
                            
                            # Toggle Task
                            $actTog = New-ScheduledTaskAction -Execute "wscript.exe" -Argument ('"{0}" "{1}\Toggle.cmd"' -f $vbsRunner, $engDir)
                            $taskT = New-ScheduledTask -Action $actTog -Principal $p -Settings $settings
                            try { Set-ScheduledTask -TaskName "AutoDM - Quick Toggle" -TaskPath $tPath -InputObject $taskT -Force -ErrorAction Stop | Out-Null } catch {}
                            
                            # Restoring Keyboard Shortcut
                            $scToggle.Hotkey = ""; $scToggle.Save()
                            Start-Sleep -Milliseconds 200
                            $scToggle.Hotkey = "CTRL+ALT+T"; $scToggle.Save()
                            
                            Add-Log "AutoDM successfully reset to defaults."
                        } else {
                            Add-Log "Reset cancelled."
                        }
                        $needsRefresh = $true
                    }
                    "Uninstall_AutoDM" {
                        Hide-Loading
                        Write-Host "
   $cRed[!] This will completely remove AutoDM from your system.$cReset"
                        Write-Host "   $cMain> Are you sure? (Y/N):$cReset " -NoNewline
                        $ans = Read-Host
                        if ($ans -match '^[Yy]') {
                            $uninst = "C:\Program Files\Detaroxz\AutoDM\Uninstall.cmd"
                            if (Test-Path $uninst) {
                                Start-Process cmd.exe -ArgumentList "/c ""$uninst"""
                                exit
                            } else {
                                Add-Log "Uninstaller not found!"
                            }
                        } else {
                            Add-Log "Uninstall cancelled."
                        }
                        $needsRefresh = $true
                    }
                    "Set_Sch_Prio" {
                        Hide-Loading
                        Write-Host "
   Task Priority Levels (0 to 10):" -ForegroundColor Cyan
                        Write-Host "   0-3 : Real-time / High (Not recommended)"
                        Write-Host "   4   : Normal (Standard app priority - Fast execution)"
                        Write-Host "   5-6 : Below Normal"
                        Write-Host "   7   : Below Normal (Task Scheduler Default - Slower)"
                        Write-Host "   8-10: Low / Idle"
                        Write-Host "
   $cDim> Enter priority number (0-10) [Default: 2] (or 'back' to cancel):$cReset " -NoNewline
                        $newPrio = Read-Host
                        if ($newPrio.ToLower() -eq 'back') { Add-Log "Cancelled."; $needsRefresh = $true; break }
                        Show-Loading "Updating priorities"
                        if ([string]::IsNullOrWhiteSpace($newPrio)) { $newPrio = "2" }
                        if ($newPrio -match '^(10|[0-9])$') {
                            foreach ($t in @("AutoDM - Light Mode", "AutoDM - Dark Mode")) {
                                $xml = try { (Export-ScheduledTask -TaskName $t -TaskPath $tPath -ErrorAction Stop) -replace '<Priority>\d+</Priority>', "<Priority>$newPrio</Priority>" } catch { $null }
                                if ($xml) { try { Register-ScheduledTask -TaskName $t -TaskPath $tPath -Xml $xml -Force -User $env:USERNAME -ErrorAction Stop | Out-Null } catch {} }
                            }
                            Add-Log "Scheduled Sync priority updated to $newPrio"
                        } else { Add-Log "Invalid input." }
                        $needsRefresh = $true
                    }
                    "Set_Boot_Prio" {
                        Hide-Loading
                        Write-Host "
   Task Priority Levels (0 to 10):" -ForegroundColor Cyan
                        Write-Host "   0-3 : Real-time / High (Not recommended)"
                        Write-Host "   4   : Normal (Standard app priority - Fast execution)"
                        Write-Host "   5-6 : Below Normal"
                        Write-Host "   7   : Below Normal (Task Scheduler Default - Slower)"
                        Write-Host "   8-10: Low / Idle"
                        Write-Host "
   $cDim> Enter priority number (0-10) [Default: 2] (or 'back' to cancel):$cReset " -NoNewline
                        $newPrio = Read-Host
                        if ($newPrio.ToLower() -eq 'back') { Add-Log "Cancelled."; $needsRefresh = $true; break }
                        Show-Loading "Updating priorities"
                        if ([string]::IsNullOrWhiteSpace($newPrio)) { $newPrio = "2" }
                        if ($newPrio -match '^(10|[0-9])$') {
                            $xml = try { (Export-ScheduledTask -TaskName "AutoDM - Boot Sync" -TaskPath $tPath -ErrorAction Stop) -replace '<Priority>\d+</Priority>', "<Priority>$newPrio</Priority>" } catch { $null }
                            if ($xml) { try { Register-ScheduledTask -TaskName "AutoDM - Boot Sync" -TaskPath $tPath -Xml $xml -Force -User $env:USERNAME -ErrorAction Stop | Out-Null } catch {} }
                            Add-Log "Boot Sync priority updated to $newPrio"
                        } else { Add-Log "Invalid input." }
                        $needsRefresh = $true
                    }
                    "Set_Sun_Prio" {
                        Hide-Loading
                        Write-Host "
   Task Priority Levels (0 to 10):" -ForegroundColor Cyan
                        Write-Host "   0-3 : Real-time / High (Not recommended)"
                        Write-Host "   4   : Normal (Standard app priority - Fast execution)"
                        Write-Host "   5-6 : Below Normal"
                        Write-Host "   7   : Below Normal (Task Scheduler Default - Slower)"
                        Write-Host "   8-10: Low / Idle"
                        Write-Host "
   $cDim> Enter priority number (0-10) [Default: 2] (or 'back' to cancel):$cReset " -NoNewline
                        $newPrio = Read-Host
                        if ($newPrio.ToLower() -eq 'back') { Add-Log "Cancelled."; $needsRefresh = $true; break }
                        Show-Loading "Updating priorities"
                        if ([string]::IsNullOrWhiteSpace($newPrio)) { $newPrio = "2" }
                        if ($newPrio -match '^(10|[0-9])$') {
                            $xml = try { (Export-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -ErrorAction Stop) -replace '<Priority>\d+</Priority>', "<Priority>$newPrio</Priority>" } catch { $null }
                            if ($xml) { try { Register-ScheduledTask -TaskName "AutoDM - Sun Update" -TaskPath $tPath -Xml $xml -Force -User $env:USERNAME -ErrorAction Stop | Out-Null } catch {} }
                            Add-Log "Dynamic Calculator priority updated to $newPrio"
                        } else { Add-Log "Invalid input." }
                        $needsRefresh = $true
                    }
                    "Update_Check" {
                        Hide-Loading
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
                                    Add-Log "Update cancelled."
                                }
                            } elseif ([version]"$appVersion" -gt [version]$remoteVer) {
                                Write-Host "
   $cRed[!] You shouldn't have this version, this is developer exclusive, FUCK OFF from here!!!$cReset"
                                Start-Sleep -Seconds 3
                                Add-Log "Developer exclusive version detected."
                            } else {
                                Add-Log "You are on the latest version (v$appVersion)."
                            }
                        } catch {
                            Add-Log "Failed to check for updates. Check your internet connection."
                        }
                        $needsRefresh = $true
                    }
                    "Open_Dev" { Start-Process "https://github.com/avm3005/"; Add-Log "Opened Developer GitHub Profile" }
                    "Open_DevWeb" { Start-Process "https://avm3005.github.io/portfolio/"; Add-Log "Opened Developer Website" }
                    "Open_Proj" { Start-Process "https://github.com/avm3005/detaroxzAutoDM"; Add-Log "Opened Project GitHub Repository" }
                }
                [console]::CursorVisible = $false
            }
        }
    }
} finally {
    Hide-Loading
    try { $psCmd.Dispose(); $rs.Dispose() } catch {}
    [console]::CursorVisible = $true
    Clear-Host
}
