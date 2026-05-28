# 2>NUL & @echo off
# 2>NUL & set "SELF_PATH=%~f0"
# 2>NUL & powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF_PATH)))"
# 2>NUL & exit /b
if (-not (Test-Path "HKCU:\SOFTWARE\AutoDM")) { New-Item "HKCU:\SOFTWARE\AutoDM" -Force | Out-Null }
Set-ItemProperty -Path "HKCU:\SOFTWARE\AutoDM" -Name "OverrideTime" -Value ([datetime]::Now.Ticks) -Force
$reg = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$current = (Get-ItemProperty -Path $reg -Name AppsUseLightTheme).AppsUseLightTheme
$newVal = if ($current -eq 1) { 0 } else { 1 }
Set-ItemProperty -Path $reg -Name AppsUseLightTheme -Value $newVal -Force
Set-ItemProperty -Path $reg -Name SystemUsesLightTheme -Value $newVal -Force
$code = @"
using System; using System.Runtime.InteropServices;
public class Theme { 
    [DllImport("uxtheme.dll", EntryPoint = "#104")] public static extern void RefreshImmersiveColorPolicyState(); 
    [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult); 
    public static void Refresh() { 
        try { RefreshImmersiveColorPolicyState(); } catch {} 
        IntPtr res; 
        SendMessageTimeout((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "ImmersiveColorSet", 2, 100, out res); 
        SendMessageTimeout((IntPtr)0xFFFF, 0x031A, IntPtr.Zero, null, 2, 100, out res); 
    } 
}
"@
if (-not ("Theme" -as [type])) { Add-Type -TypeDefinition $code }
[Theme]::Refresh()
Stop-Process -Name SearchHost -Force -ErrorAction SilentlyContinue
$tm = Get-Process Taskmgr -ErrorAction SilentlyContinue | Select-Object -First 1
if ($tm) { Stop-Process -Name Taskmgr -Force -ErrorAction SilentlyContinue; Start-Process taskmgr -WindowStyle Minimized }
exit
