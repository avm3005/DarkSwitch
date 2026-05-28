# 2>NUL & @echo off
# 2>NUL & set "SELF_PATH=%~f0"
# 2>NUL & powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF_PATH)))"
# 2>NUL & exit /b
$tLight = Get-ScheduledTask -TaskPath "\Detaroxz\AutoDM\" -TaskName "AutoDM - Light Mode" -ErrorAction SilentlyContinue
$tDark = Get-ScheduledTask -TaskPath "\Detaroxz\AutoDM\" -TaskName "AutoDM - Dark Mode" -ErrorAction SilentlyContinue
if (-not $tLight -or -not $tDark -or $tLight.State -eq 'Disabled') { exit }
$lTime = [datetime]($tLight.Triggers[0].StartBoundary)
$dTime = [datetime]($tDark.Triggers[0].StartBoundary)
$now = [datetime]::Now
$regDM = "HKCU:\SOFTWARE\AutoDM"
$overrideTicks = (Get-ItemProperty $regDM -Name "OverrideTime" -ErrorAction SilentlyContinue).OverrideTime

$todayL = $now.Date + $lTime.TimeOfDay
$todayD = $now.Date + $dTime.TimeOfDay
$pastL = if ($now -ge $todayL) { $todayL } else { $todayL.AddDays(-1) }
$pastD = if ($now -ge $todayD) { $todayD } else { $todayD.AddDays(-1) }
$recentB = if ($pastL -gt $pastD) { $pastL } else { $pastD }

if ($overrideTicks -and [long]$overrideTicks -gt $recentB.Ticks) { exit }

$isLight = ($recentB -eq $pastL)
$newVal = if ($isLight) { 1 } else { 0 }

$reg = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$currApp = (Get-ItemProperty -Path $reg -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
$currSys = (Get-ItemProperty -Path $reg -Name SystemUsesLightTheme -ErrorAction SilentlyContinue).SystemUsesLightTheme

# If theme is already correct upon boot, silently exit to prevent UI lag/flashes
if ($currApp -eq $newVal -and $currSys -eq $newVal) { exit }

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
