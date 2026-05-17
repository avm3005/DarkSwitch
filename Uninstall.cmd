# 2>NUL & @cls & @echo off
# 2>NUL & set "SELF_PATH=%~f0"
# 2>NUL & net session >nul 2>&1 || (powershell -NoProfile -WindowStyle Hidden -Command "Start-Process cmd -ArgumentList '/c \"\"%SELF_PATH%\"\"' -Verb RunAs" & exit /b)
# 2>NUL & if not defined WT_SESSION (wt powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF_PATH)))" & exit /b)
# 2>NUL & powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF_PATH)))"
# 2>NUL & exit /b

Write-Host "`nRemoving AutoDM..." -ForegroundColor Red
$tasks = @("AutoDM - Light Mode", "AutoDM - Dark Mode", "AutoDM - Boot Sync", "AutoDM - Quick Toggle")
foreach ($task in $tasks) { if (Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue) { Unregister-ScheduledTask -TaskName $task -Confirm:$false } }
$startMenu = [Environment]::GetFolderPath("CommonApplicationData") + "\Microsoft\Windows\Start Menu\Programs\AutoDM"
$legacyStartMenu = [Environment]::GetFolderPath("ApplicationData") + "\Microsoft\Windows\Start Menu\Programs\AutoDM"
if (Test-Path $startMenu) { Remove-Item -Path $startMenu -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path $legacyStartMenu) { Remove-Item -Path $legacyStartMenu -Recurse -Force -ErrorAction SilentlyContinue }

# Give Indexer time to catch deletion
Start-Sleep -Seconds 2

$sig = '[DllImport("shell32.dll", CharSet=CharSet.Auto)] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);'
if (-not ("Shell.WinAPI" -as [type])) { Add-Type -MemberDefinition $sig -Name WinAPI -Namespace Shell -PassThru | Out-Null }
[Shell.WinAPI]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
Stop-Process -Name "SearchHost" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "StartMenuExperienceHost" -Force -ErrorAction SilentlyContinue

$uninstallRegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AutoDM"
if (Test-Path $uninstallRegKey) { Remove-Item -Path $uninstallRegKey -Force -Recurse -ErrorAction SilentlyContinue }
Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "AutoDM" -ErrorAction SilentlyContinue
if (Test-Path "HKCU:\SOFTWARE\AutoDM") { Remove-Item "HKCU:\SOFTWARE\AutoDM" -Force -Recurse -ErrorAction SilentlyContinue }

# Clean up Environment PATH
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
exit
