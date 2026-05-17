# 2>NUL & @echo off
# 2>NUL & set "SELF_PATH=%~f0"
# 2>NUL & powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF_PATH)))"
# 2>NUL & exit /b
$tLight = Get-ScheduledTask -TaskName "AutoDM - Light Mode" -ErrorAction SilentlyContinue
$tDark = Get-ScheduledTask -TaskName "AutoDM - Dark Mode" -ErrorAction SilentlyContinue
if (-not $tLight -or -not $tDark -or $tLight.State -eq 'Disabled') { exit }
$lTime = [datetime]($tLight.Triggers[0].StartBoundary)
$dTime = [datetime]($tDark.Triggers[0].StartBoundary)
$now = [datetime]::Now.TimeOfDay
if ($lTime.TimeOfDay -lt $dTime.TimeOfDay) { $isLight = ($now -ge $lTime.TimeOfDay) -and ($now -lt $dTime.TimeOfDay) } 
else { $isLight = ($now -ge $lTime.TimeOfDay) -or ($now -lt $dTime.TimeOfDay) }
$newVal = if ($isLight) { 1 } else { 0 }
$reg = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
Set-ItemProperty -Path $reg -Name AppsUseLightTheme -Value $newVal -Force
Set-ItemProperty -Path $reg -Name SystemUsesLightTheme -Value $newVal -Force
$code = 'using System; using System.Runtime.InteropServices; public class Theme { [DllImport("uxtheme.dll", EntryPoint = "#104")] public static extern void RefreshImmersiveColorPolicyState(); [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult); [DllImport("shell32.dll")] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2); [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd); public static void Refresh() { try { RefreshImmersiveColorPolicyState(); } catch {} IntPtr res; SendMessageTimeout((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "ImmersiveColorSet", 2, 100, out res); SendMessageTimeout((IntPtr)0xFFFF, 0x031A, IntPtr.Zero, null, 2, 100, out res); SHChangeNotify(0x08000000, 0, IntPtr.Zero, IntPtr.Zero); } public static bool IsMin(IntPtr h) { return IsIconic(h); } }'
if (-not ("Theme" -as [type])) { Add-Type -TypeDefinition $code }
[Theme]::Refresh()
Stop-Process -Name SearchHost -Force -ErrorAction SilentlyContinue
$tm = Get-Process Taskmgr -ErrorAction SilentlyContinue | Select-Object -First 1
if ($tm) { Stop-Process -Name Taskmgr -Force -ErrorAction SilentlyContinue; Start-Process taskmgr -WindowStyle Minimized }
exit
