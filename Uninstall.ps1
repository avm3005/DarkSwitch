param([string]$MODE_FLAG)

$isUpgrade = ($MODE_FLAG -eq 'UPGRADE')
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $argsStr = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $MODE_FLAG"
    if ($isUpgrade) {
        Start-Process powershell.exe -Verb RunAs -ArgumentList $argsStr -WindowStyle Hidden
    } else {
        $hasWT = (Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe") -or [bool](Get-Item "$env:windir\System32\wt.exe" -ErrorAction SilentlyContinue)
        if ($hasWT) {
            Start-Process wt.exe -Verb RunAs -ArgumentList "powershell.exe $argsStr"
        } else {
            Start-Process powershell.exe -Verb RunAs -ArgumentList $argsStr
        }
    }
    exit
}

if (-not $isUpgrade) {
    $inWT = $null -ne $env:WT_SESSION
    if (-not $inWT -and $MODE_FLAG -ne 'WT_LAUNCHED') {
        $hasWT = (Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe") -or [bool](Get-Item "$env:windir\System32\wt.exe" -ErrorAction SilentlyContinue)
        if ($hasWT) {
            Start-Process wt.exe -ArgumentList "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" WT_LAUNCHED"
            exit
        }
    }

    Clear-Host
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Write-Host "`n===========================================================================" -ForegroundColor Cyan
    Write-Host " DARK SWITCH UNINSTALLER" -ForegroundColor Magenta
    Write-Host "===========================================================================`n" -ForegroundColor Cyan
    
    $delReg = Read-Host " -> Do you want to completely delete all saved preferences and settings? (Y/N) [Default: N]"
    
    Write-Host "`n Removing Dark Switch and restoring system settings..." -ForegroundColor Yellow

    $regDM = "HKCU:\SOFTWARE\DarkSwitch"
    $regData = Get-ItemProperty $regDM -ErrorAction SilentlyContinue
    
    if ($regData -and $regData.WallpaperEnabled -eq 1) {
        Write-Host " -> Restoring Backup Wallpaper settings before uninstalling..." -ForegroundColor DarkGray
        Set-ItemProperty -Path $regDM -Name "WallpaperEnabled" -Value 0 -Type DWord -Force
        
        $codeWP = @"
        using System; using System.Runtime.InteropServices; using Microsoft.Win32;
        public class WPTheme {
            [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
            [DllImport("shell32.dll", CharSet = CharSet.Unicode, PreserveSig = false)] public static extern void SHCreateItemFromParsingName([In][MarshalAs(UnmanagedType.LPWStr)] string pszPath, [In] IntPtr pbc, [In] ref Guid riid, out IntPtr ppv);
            [DllImport("shell32.dll", PreserveSig = false)] public static extern void SHCreateShellItemArrayFromShellItem([In] IntPtr psi, [In] ref Guid riid, out IntPtr ppv);

            [ComImport, Guid("43826d1e-e718-42ee-bc55-a1e261c37bfe"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] public interface IShellItem { }
            [ComImport, Guid("b63ea76d-1f85-456f-a19c-48159efa858b"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] public interface IShellItemArray { }

            [ComImport, Guid("C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD")] public class DesktopWallpaper { }
            
            [ComImport, Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] 
            public interface IDesktopWallpaper {
                void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] string wallpaper);
                void GetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] out string wallpaper);
                void GetMonitorDevicePathAt(uint monitorIndex, [MarshalAs(UnmanagedType.LPWStr)] out string monitorID);
                void GetMonitorDevicePathCount(out uint count);
                void GetMonitorRECT([MarshalAs(UnmanagedType.LPWStr)] string monitorID, out IntPtr displayRect);
                void SetBackgroundColor(uint color);
                void GetBackgroundColor(out uint color);
                void SetPosition(uint position);
                void GetPosition(out uint position);
                void SetSlideshow(IntPtr items);
                void GetSlideshow(out IntPtr items);
                void SetSlideshowOptions(uint options, uint slideshowTick);
            }
            
            public static void ApplyWpMode(int mode, string file, string colorHex, string folder, int tick) {
                using (RegistryKey expWp = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers"))
                using (RegistryKey cpColors = Registry.CurrentUser.CreateSubKey(@"Control Panel\Colors")) {
                    if (mode == 2 && string.IsNullOrEmpty(folder)) { mode = 0; }
                    if (expWp != null) expWp.SetValue("BackgroundType", mode, RegistryValueKind.DWord);
                    
                    IDesktopWallpaper dw = null;
                    try { dw = (IDesktopWallpaper)new DesktopWallpaper(); } catch {}

                    if (mode == 0 && !string.IsNullOrEmpty(file)) {
                        try { if(dw != null) dw.SetWallpaper(null, file); } 
                        catch { SystemParametersInfo(20, 0, file, 3); }
                    }
                    else if (mode == 1 && !string.IsNullOrEmpty(colorHex)) {
                        string rgb = "0 0 0";
                        try {
                            string h = colorHex.StartsWith("#") ? colorHex.Substring(1) : colorHex;
                            int r = 0, g = 0, b = 0;
                            if(h.Length == 6) {
                                r = Convert.ToInt32(h.Substring(0,2), 16);
                                g = Convert.ToInt32(h.Substring(2,2), 16);
                                b = Convert.ToInt32(h.Substring(4,2), 16);
                            }
                            rgb = r + " " + g + " " + b;
                            uint color = (uint)(r | (g << 8) | (b << 16));
                            if(dw != null) { dw.SetWallpaper(null, ""); dw.SetBackgroundColor(color); }
                        } catch {}
                        if (cpColors != null) cpColors.SetValue("Background", rgb, RegistryValueKind.String);
                        SystemParametersInfo(20, 0, "", 3);
                    }
                    else if (mode == 2 && !string.IsNullOrEmpty(folder)) {
                        if (expWp != null) {
                            expWp.SetValue("SlideshowDirectoryPath1", folder, RegistryValueKind.String);
                            expWp.SetValue("SlideshowTick", tick, RegistryValueKind.DWord);
                        }
                        try {
                            if (dw != null) {
                                Guid iidShellItem = new Guid("43826d1e-e718-42ee-bc55-a1e261c37bfe");
                                IntPtr pItem = IntPtr.Zero;
                                SHCreateItemFromParsingName(folder, IntPtr.Zero, ref iidShellItem, out pItem);
                                
                                if (pItem != IntPtr.Zero) {
                                    Guid iidShellItemArray = new Guid("b63ea76d-1f85-456f-a19c-48159efa858b");
                                    IntPtr pArray = IntPtr.Zero;
                                    SHCreateShellItemArrayFromShellItem(pItem, ref iidShellItemArray, out pArray);

                                    if (pArray != IntPtr.Zero) {
                                        dw.SetSlideshow(pArray);
                                        dw.SetSlideshowOptions(0, (uint)tick);
                                        Marshal.Release(pArray);
                                    }
                                    Marshal.Release(pItem);
                                }
                            }
                        } catch { SystemParametersInfo(20, 0, "", 3); }
                    }
                }
            }

            public static void ApplyCursor() {
                using (RegistryKey cursors = Registry.CurrentUser.CreateSubKey(@"Control Panel\Cursors")) {
                    if (cursors != null) {
                        cursors.SetValue("", "Windows Default");
                        string[] keys = { "Arrow", "Help", "AppStarting", "Wait", "Crosshair", "IBeam", "NWPen", "No", "SizeNS", "SizeWE", "SizeNWSE", "SizeNESW", "SizeAll", "UpArrow", "Hand" };
                        foreach(string k in keys) cursors.DeleteValue(k, false);
                    }
                }
                SystemParametersInfo(0x0057, 0, null, 0x01 | 0x02);
            }
        }
"@
        if (-not ("WPTheme" -as [type])) { Add-Type -TypeDefinition $codeWP -ErrorAction SilentlyContinue }
        
        $bMode = $regData.BackupWpMode
        if ($null -ne $bMode) {
            $bFile = $regData.BackupWpFile
            $bColor = $regData.BackupWpColor
            $bFolder = $regData.BackupWpFolder
            $bTick = $regData.BackupWpInterval
            [WPTheme]::ApplyWpMode([int]$bMode, "$bFile", "$bColor", "$bFolder", [int]$bTick)
        } else {
            $wpDir = "C:\Program Files\Detaroxz\DarkSwitch\Wallpapers"
            $bWp = (Get-ChildItem "$wpDir\Default_WP.*" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
            if ($bWp -and (Test-Path $bWp)) { [WPTheme]::ApplyWpMode(0, $bWp, "", "", 600000) }
        }
    }

    if ($regData -and $regData.CursorEnabled -eq 1) {
        Write-Host " -> Restoring original Cursor settings before uninstalling..." -ForegroundColor DarkGray
        Set-ItemProperty -Path $regDM -Name "CursorEnabled" -Value 0 -Type DWord -Force
        if ("WPTheme" -as [type]) { [WPTheme]::ApplyCursor() }
    }
    
    if ($regData -and $regData.AccentEnabled -eq 1) {
        Write-Host " -> Restoring original Accent settings before uninstalling..." -ForegroundColor DarkGray
        Set-ItemProperty -Path $regDM -Name "AccentEnabled" -Value 0 -Type DWord -Force
        
        $codeAcc = @"
        using System; using System.Runtime.InteropServices; using Microsoft.Win32;
        public class AccTheme {
            [StructLayout(LayoutKind.Sequential)]
            public struct IMMERSIVE_COLOR_PREFERENCE {
                public uint dwColorSpace;
                public uint dwColor;
            }

            [DllImport("uxtheme.dll", EntryPoint = "#122")]
            public static extern int SetUserColorPreference(ref IMMERSIVE_COLOR_PREFERENCE pcpPreference, bool fForceCommit);

            [DllImport("uxtheme.dll", EntryPoint = "#104")] public static extern void RefreshImmersiveColorPolicyState();
            [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
            [DllImport("shell32.dll", CharSet = CharSet.Auto)] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
            
            public static void Restore(int autoCol, long accColLong) {
                int accCol = unchecked((int)accColLong);

                try {
                    if (autoCol == 0) {
                        IMMERSIVE_COLOR_PREFERENCE pref = new IMMERSIVE_COLOR_PREFERENCE();
                        pref.dwColorSpace = 0;
                        pref.dwColor = unchecked((uint)accCol);
                        SetUserColorPreference(ref pref, true);
                    }
                } catch {}

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
                using (RegistryKey accent = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Explorer\Accent")) {
                    if (accent != null) {
                        accent.SetValue("AccentColorMenu", accCol, RegistryValueKind.DWord);
                        accent.SetValue("StartColorMenu", accCol, RegistryValueKind.DWord);

                        int r = accCol & 0xFF; int g = (accCol >> 8) & 0xFF; int b = (accCol >> 16) & 0xFF;
                        byte[] palette = new byte[32];
                        for (int i = 0; i < 8; i++) {
                            palette[i * 4] = (byte)r; palette[i * 4 + 1] = (byte)g; palette[i * 4 + 2] = (byte)b; palette[i * 4 + 3] = 0;
                        }
                        accent.SetValue("AccentPalette", palette, RegistryValueKind.Binary);
                        accent.Flush();
                    }
                }
                RefreshImmersiveColorPolicyState();
                IntPtr res;
                SendMessageTimeout((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "ImmersiveColorSet", 0x0000, 500, out res);
                try { SHChangeNotify(0x08000000, 0x0000, IntPtr.Zero, IntPtr.Zero); } catch {}
            }
        }
"@
        if (-not ("AccTheme" -as [type])) { Add-Type -TypeDefinition $codeAcc -ErrorAction SilentlyContinue }
        
        $bAuto = $regData.BackupAutoCol
        $bAcc = $regData.BackupAccCol
        if ($null -ne $bAuto -and $null -ne $bAcc) {
            try { [AccTheme]::Restore([int]$bAuto, [long]$bAcc) } catch {}
        }
    }

    Write-Host " -> Unregistering scheduled tasks..." -ForegroundColor DarkGray
    Get-ScheduledTask -TaskName "DarkSwitch*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

    Write-Host " -> Removing Start Menu shortcuts..." -ForegroundColor DarkGray
    $startMenu = [Environment]::GetFolderPath("CommonApplicationData") + "\Microsoft\Windows\Start Menu\Programs\DarkSwitch"
    $legacyStartMenu = [Environment]::GetFolderPath("ApplicationData") + "\Microsoft\Windows\Start Menu\Programs\DarkSwitch"
    if (Test-Path $startMenu) { Remove-Item -Path $startMenu -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $legacyStartMenu) { Remove-Item -Path $legacyStartMenu -Recurse -Force -ErrorAction SilentlyContinue }

    Start-Sleep -Seconds 1
    $sig = '[DllImport("shell32.dll", CharSet=CharSet.Auto)] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);'
    if (-not ("Shell.WinAPI" -as [type])) { Add-Type -MemberDefinition $sig -Name WinAPI -Namespace Shell -PassThru | Out-Null }
    [Shell.WinAPI]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
    
    Write-Host " -> Cleaning up Registry entries..." -ForegroundColor DarkGray
    $uninstallRegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\DarkSwitch"
    if (Test-Path $uninstallRegKey) { Remove-Item -Path $uninstallRegKey -Force -Recurse -ErrorAction SilentlyContinue }

    if ($delReg -match '^[Yy]') {
        Write-Host " -> Cleaning up User Preferences..." -ForegroundColor DarkGray
        if (Test-Path $regDM) { Remove-Item $regDM -Force -Recurse -ErrorAction SilentlyContinue }
    }

    Write-Host " -> Removing Environment Path variables..." -ForegroundColor DarkGray
    $userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    if ($userPath -match [regex]::Escape("C:\Program Files\Detaroxz\DarkSwitch")) {
        $newPath = ($userPath -split ';' | Where-Object { $_ -ne "C:\Program Files\Detaroxz\DarkSwitch" -and $_ -ne "" }) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)
        $code = '[DllImport("user32.dll",CharSet=CharSet.Auto)]public static extern IntPtr SendMessageTimeout(IntPtr h,uint m,IntPtr w,string l,uint f,uint t,out IntPtr r);'
        if (-not ("Win32.EnvRefresher" -as [type])) { Add-Type -MemberDefinition $code -Name "EnvRefresher" -Namespace "Win32" -PassThru | Out-Null }
        $res = [IntPtr]::Zero; [Win32.EnvRefresher]::SendMessageTimeout([IntPtr]0xFFFF, 0x001A, [IntPtr]0, "Environment", 2, 1000, [ref]$res) | Out-Null
    }

    Write-Host " -> Queuing final directory deletion..." -ForegroundColor DarkGray
    $targetDir = "C:\Program Files\Detaroxz\DarkSwitch"
    $parentDir = "C:\Program Files\Detaroxz"
    $pidToWait = $PID
    
    # Clean the directory, and if the parent Detaroxz is empty, remove that too
    $cmdCleanup = "Wait-Process -Id $pidToWait -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2; Remove-Item -Path '$targetDir' -Recurse -Force -ErrorAction SilentlyContinue; if ((Get-ChildItem '$parentDir' -ErrorAction SilentlyContinue).Count -eq 0) { Remove-Item -Path '$parentDir' -Force -ErrorAction SilentlyContinue }"
    Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -Command `"$cmdCleanup`"" -WindowStyle Hidden

    Write-Host "`n===========================================================================" -ForegroundColor Cyan
    Write-Host " Dark Switch has been successfully uninstalled from your system." -ForegroundColor Green
    Write-Host "===========================================================================`n" -ForegroundColor Cyan
    
    Write-Host "Press ENTER to exit..." -ForegroundColor Yellow
    Read-Host
}

exit 0
