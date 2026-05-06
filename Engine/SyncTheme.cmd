# 2>NUL & @cls & @echo off
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
$code = '[DllImport("user32.dll",CharSet=CharSet.Auto)]public static extern IntPtr SendMessageTimeout(IntPtr h,uint m,IntPtr w,string l,uint f,uint t,out IntPtr r);'
if (-not ("Win32.ThemeRefresher" -as [type])) { Add-Type -MemberDefinition $code -Name "ThemeRefresher" -Namespace "Win32" }
$res = [IntPtr]::Zero; [Win32.ThemeRefresher]::SendMessageTimeout([IntPtr]0xFFFF, 0x001A, [IntPtr]0, "ImmersiveColorSet", 2, 2000, [ref]$res) | Out-Null
exit
