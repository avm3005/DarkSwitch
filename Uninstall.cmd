# 2>NUL & @cls & @echo off
# 2>NUL & set "SELF_PATH=%~f0"
# 2>NUL & net session >nul 2>&1 || (powershell -NoProfile -WindowStyle Hidden -Command "Start-Process cmd -ArgumentList '/c \"\"%SELF_PATH%\"\"' -Verb RunAs" & exit /b)
# 2>NUL & if not defined WT_SESSION (wt powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF_PATH)))" & exit /b)
# 2>NUL & powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF_PATH)))"
# 2>NUL & exit /b

Clear-Host
Write-Host "Removing AutoDM..." -ForegroundColor Red
$tasks = @("AutoDM - Light Mode", "AutoDM - Dark Mode")
foreach ($task in $tasks) { if (Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue) { Unregister-ScheduledTask -TaskName $task -Confirm:$false } }
$startMenu = [Environment]::GetFolderPath("ApplicationData") + "\Microsoft\Windows\Start Menu\Programs\AutoDM"
if (Test-Path $startMenu) { Remove-Item -Path $startMenu -Recurse -Force -ErrorAction SilentlyContinue }
$uninstallRegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AutoDM"
if (Test-Path $uninstallRegKey) { Remove-Item -Path $uninstallRegKey -Force -Recurse -ErrorAction SilentlyContinue }
Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "AutoDM" -ErrorAction SilentlyContinue
Write-Host "Queuing directory deletion..."
$cmdArgs = "/c timeout /t 2 >nul & rmdir /s /q `"C:\Program Files\Detaroxz\AutoDM`""
Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -WindowStyle Hidden
exit
