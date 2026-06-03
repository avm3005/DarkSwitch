# 2>NUL & @cls & @echo off
# 2>NUL & set "SELF_PATH=%~f0"
# 2>NUL & set "MODE_FLAG=%~1"
# 2>NUL & set "C=iex (Get-Content -LiteralPath '%~f0' -Raw)"
# 2>NUL & net session >nul 2>&1 || (powershell -NoProfile -WindowStyle Hidden -Command "Start-Process cmd -ArgumentList '/c \"\"%SELF_PATH%\"\" %MODE_FLAG%' -Verb RunAs" & exit /b)
# 2>NUL & if not defined WT_SESSION (where wt >nul 2>&1 && (wt powershell -NoProfile -ExecutionPolicy Bypass -Command "%C%" 2>nul & exit /b))
# 2>NUL & powershell -NoProfile -ExecutionPolicy Bypass -Command "%C%"
# 2>NUL & exit /b

$isUpgrade = ($env:MODE_FLAG -eq 'UPGRADE')

if (-not $isUpgrade) {
    $regDM = "HKCU:\SOFTWARE\AutoDM"
    $regData = Get-ItemProperty $regDM -ErrorAction SilentlyContinue
    if ($regData -and $regData.WallpaperEnabled -eq 1) {
        Write-Host "`nRestoring Default Wallpaper before uninstalling..." -ForegroundColor Yellow
        Set-ItemProperty -Path $regDM -Name "WallpaperEnabled" -Value 0 -Type DWord -Force
        
        $wpDir = "C:\Program Files\Detaroxz\AutoDM\Wallpapers"
        $bWp = (Get-ChildItem "$wpDir\Default_WP.*" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
        if ($bWp -and (Test-Path $bWp)) {
            $code = @"
            using System; using System.Runtime.InteropServices;
            public class WPTheme {
                [ComImport, Guid("C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD")] public class DesktopWallpaper { }
                [ComImport, Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] public interface IDesktopWallpaper { void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] string wallpaper); }
                [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
                
                public static void Apply(string wp) {
                    try { ((IDesktopWallpaper)new DesktopWallpaper()).SetWallpaper(null, wp); } 
                    catch { SystemParametersInfo(20, 0, wp, 3); }
                }
            }
"@
            if (-not ("WPTheme" -as [type])) { Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue }
            [WPTheme]::Apply($bWp)
        }
    }
}

Write-Host "`nRemoving AutoDM..." -ForegroundColor Red
Get-ScheduledTask -TaskName "AutoDM*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

$startMenu = [Environment]::GetFolderPath("CommonApplicationData") + "\Microsoft\Windows\Start Menu\Programs\AutoDM"
$legacyStartMenu = [Environment]::GetFolderPath("ApplicationData") + "\Microsoft\Windows\Start Menu\Programs\AutoDM"
if (Test-Path $startMenu) { Remove-Item -Path $startMenu -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path $legacyStartMenu) { Remove-Item -Path $legacyStartMenu -Recurse -Force -ErrorAction SilentlyContinue }

Start-Sleep -Seconds 2
$sig = '[DllImport("shell32.dll", CharSet=CharSet.Auto)] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);'
if (-not ("Shell.WinAPI" -as [type])) { Add-Type -MemberDefinition $sig -Name WinAPI -Namespace Shell -PassThru | Out-Null }
[Shell.WinAPI]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
Stop-Process -Name "SearchHost" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "StartMenuExperienceHost" -Force -ErrorAction SilentlyContinue

$uninstallRegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AutoDM"
if (Test-Path $uninstallRegKey) { Remove-Item -Path $uninstallRegKey -Force -Recurse -ErrorAction SilentlyContinue }

$userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
if ($userPath -match [regex]::Escape("C:\Program Files\Detaroxz\AutoDM")) {
    $newPath = ($userPath -split ';' | Where-Object { $_ -ne "C:\Program Files\Detaroxz\AutoDM" -and $_ -ne "" }) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)
    $code = '[DllImport("user32.dll",CharSet=CharSet.Auto)]public static extern IntPtr SendMessageTimeout(IntPtr h,uint m,IntPtr w,string l,uint f,uint t,out IntPtr r);'
    if (-not ("Win32.EnvRefresher" -as [type])) { Add-Type -MemberDefinition $code -Name "EnvRefresher" -Namespace "Win32" -PassThru | Out-Null }
    $res = [IntPtr]::Zero; [Win32.EnvRefresher]::SendMessageTimeout([IntPtr]0xFFFF, 0x001A, [IntPtr]0, "Environment", 2, 1000, [ref]$res) | Out-Null
}

Write-Host "Queuing directory deletion..."
$cmdArgs = "/c timeout /t 2 >nul & rmdir /s /q `"C:\Program Files\Detaroxz\AutoDM`""
Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -WindowStyle Hidden

exit 0
