# 2>NUL & @echo off
# 2>NUL & set "SELF_PATH=%~f0"
# 2>NUL & set "C=iex (Get-Content -LiteralPath '%SELF_PATH%' -Raw)"
# 2>NUL & powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "%C%"
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

$regTheme = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$currApp = (Get-ItemProperty -Path $regTheme -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
$currSys = (Get-ItemProperty -Path $regTheme -Name SystemUsesLightTheme -ErrorAction SilentlyContinue).SystemUsesLightTheme

$regData = Get-ItemProperty $regDM -ErrorAction SilentlyContinue
$wp = ""; $acc = ""
if ($regData.WallpaperEnabled -eq 1) { $wp = if ($newVal -eq 1) { $regData.LightWallpaper } else { $regData.DarkWallpaper } }
if ($regData.AccentEnabled -eq 1) { $acc = if ($newVal -eq 1) { $regData.LightAccent } else { $regData.DarkAccent } }

[Reflection.Assembly]::LoadFile("C:\Program Files\Detaroxz\AutoDM\Engine\AutoDMEngine.dll") | Out-Null

if ($currApp -eq $newVal -and $currSys -eq $newVal) { 
    [AutoDM.Engine]::Execute(-1, $wp, $acc)
} else {
    [AutoDM.Engine]::Execute($newVal, $wp, $acc)
}
exit
