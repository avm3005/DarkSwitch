# 2>NUL & @echo off
# 2>NUL & set "SELF_PATH=%~f0"
# 2>NUL & powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF_PATH)))"
# 2>NUL & exit /b
$regDM = "HKCU:\SOFTWARE\AutoDM"
$regData = Get-ItemProperty $regDM -ErrorAction SilentlyContinue
if ($regData.WallpaperEnabled -ne 1) { exit }

$regTheme = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$isLight = (Get-ItemProperty $regTheme -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
if ($null -eq $isLight) { $isLight = 1 }

$wpToSet = if ($isLight -eq 1) { $regData.LightWallpaper } else { $regData.DarkWallpaper }
if (-not $wpToSet -or -not (Test-Path $wpToSet)) { exit }

# Prevent flashing/refreshing if wallpaper is already exactly what it should be
$curWp = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallPaper -ErrorAction SilentlyContinue).WallPaper
if ($curWp -eq $wpToSet) { exit }

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
if (-not ("WPTheme" -as [type])) { Add-Type -TypeDefinition $code }
[WPTheme]::Apply($wpToSet)
exit
